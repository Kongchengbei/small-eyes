`timescale 1ns / 1ps

// Full board-level CoreMark test.
// Run from this sim directory. The matching command is documented at the end
// of this file. The test loads the official coremark.dat through the IMEM stub.
module tb_coremark_full;
    // Match the board configuration: the PLL/CPU and UART run at 70 MHz.
    // The simulation PLL stub passes this testbench clock through unchanged.
    localparam integer CPU_CLOCK_HZ = 70_000_000;
    localparam real CLK_NS = 1_000_000_000.0 / CPU_CLOCK_HZ;
    localparam real BIT_NS = 1_000_000_000.0 / 115_200.0;
    localparam integer STARTUP_LIMIT = 100_000;
    localparam integer DEFAULT_MAX_CYCLES = 2_000_000_000;
    localparam integer PROGRESS_EVERY = 1_000_000;
    localparam integer PC_STALL_LIMIT = 100_000;
    localparam [8*15-1:0] START_TEXT = {"Start Coremark", 8'h0a};
    localparam [8*27-1:0] PASS_TEXT = "Correct operation validated";

    reg clk = 1'b0;
    reg hard_rst_n = 1'b0;
    reg JTAG_TCK = 1'b0;
    reg JTAG_TMS = 1'b1;
    reg JTAG_TDI = 1'b0;
    wire JTAG_TDO;
    wire core_active;
    wire [31:0] fpioa;

    integer max_cycles;
    integer cycles;
    integer retired;
    integer mmio_writes;
    integer uart_sw_chars;
    integer uart_pin_chars;
    integer uart_frames_ok;
    integer uart_framing_errors;
    integer uart_data_errors;
    integer fpioa_uart_map_seen;
    integer baud_write_seen;
    integer ctrl_write_seen;
    integer error_seen;
    integer pass_seen;
    integer smoke_mode;
    integer last_tx_write_cycle;
    integer last_pc_change_cycle;
    integer uart_log;
    integer b;
    reg [31:0] last_pc;
    reg [7:0] rx_byte;
    reg [7:0] uart_sw_fifo [0:255];
    reg stop_bit;
    reg [8*15-1:0] start_window;
    reg [8*27-1:0] pass_window;

    always #(CLK_NS / 2.0) clk = ~clk;

    Hfpga_soc dut (
        .clk(clk),
        .hard_rst_n(hard_rst_n),
        .JTAG_TCK(JTAG_TCK),
        .JTAG_TMS(JTAG_TMS),
        .JTAG_TDI(JTAG_TDI),
        .JTAG_TDO(JTAG_TDO),
        .core_active(core_active),
        .fpioa(fpioa)
    );

    task fail;
        input [8*160-1:0] reason;
        begin
            $display("\nCOREMARK_FAIL: %0s", reason);
            $display("cycles=%0d retired=%0d pc=%08x ins=%08x uart_sw=%0d uart_pin=%0d framing_errors=%0d data_errors=%0d",
                     cycles, retired, dut.pc, dut.ins, uart_sw_chars, uart_pin_chars,
                     uart_framing_errors, uart_data_errors);
            if (uart_log != 0) $fclose(uart_log);
            $finish;
        end
    endtask

    task pass;
        begin
            $display("\nCOREMARK_PASS");
            $display("cycles=%0d retired=%0d uart_sw=%0d uart_pin=%0d framing_ok=%0d framing_errors=%0d data_errors=%0d",
                     cycles, retired, uart_sw_chars, uart_pin_chars, uart_frames_ok,
                     uart_framing_errors, uart_data_errors);
            if (uart_log != 0) $fclose(uart_log);
            $finish;
        end
    endtask

    task smoke_pass;
        begin
            $display("\nCOREMARK_SMOKE_PASS");
            $display("startup banner, MMIO setup and UART 8-N-1 transmission are correct");
            $display("cycles=%0d retired=%0d uart_sw=%0d uart_pin=%0d framing_errors=%0d data_errors=%0d",
                     cycles, retired, uart_sw_chars, uart_pin_chars,
                     uart_framing_errors, uart_data_errors);
            if (uart_log != 0) $fclose(uart_log);
            $finish;
        end
    endtask

    // CPU/MMIO observability. This is intentionally based on the exact board
    // top rather than a separate CPU-only harness.
    always @(posedge clk) begin
        if (hard_rst_n) begin
            cycles = cycles + 1;

            if (^dut.pc === 1'bx || ^dut.ins === 1'bx)
                fail("PC or instruction contains X/Z");

            if (dut.pc != last_pc) begin
                last_pc = dut.pc;
                last_pc_change_cycle = cycles;
            end else if ((cycles - last_pc_change_cycle) > PC_STALL_LIMIT) begin
                fail("PC did not change for 100000 cycles");
            end

            if (dut.u_cpu.wb_valid)
                retired = retired + 1;

            if (dut.is_ebreak)
                fail("CPU executed EBREAK");

            if (dut.dmem_valid && dut.dmem_wen && (dut.dmem_addr[31:28] == 4'h4)) begin
                mmio_writes = mmio_writes + 1;
                if (mmio_writes <= 32)
                    $display("MMIO[%0d] cycle=%0d pc=%08x addr=%08x data=%08x mask=%x",
                             mmio_writes, cycles, dut.pc, dut.dmem_addr,
                             dut.dmem_wdata, dut.dmem_wmask);

                if (dut.dmem_addr == 32'h4000_0f1f &&
                    dut.dmem_wdata[31:24] == 8'h07)
                    fpioa_uart_map_seen = 1;

                if (dut.dmem_addr == 32'h4000_0008) begin
                    baud_write_seen = 1;
                    if (dut.dmem_wdata[15:0] != 16'd607)
                        fail("UART baud divider is not 607 for 70 MHz");
                end

                if (dut.dmem_addr == 32'h4000_0000)
                    ctrl_write_seen = 1;

                if (dut.dmem_addr == 32'h4000_000c) begin
                    if (last_tx_write_cycle >= 0 &&
                        (cycles - last_tx_write_cycle) <
                        (10 * (dut.u_uart0_tx.baud_div + 1)))
                        fail("UART TXDATA write occurred before the prior frame completed");
                    last_tx_write_cycle = cycles;
                    if (uart_sw_chars < 256)
                        uart_sw_fifo[uart_sw_chars] = dut.dmem_wdata[7:0];
                    uart_sw_chars = uart_sw_chars + 1;
                end
            end

            if (cycles == STARTUP_LIMIT) begin
                if (!fpioa_uart_map_seen) fail("software did not map UART0_TX to FPIOA[31]");
                if (!baud_write_seen)      fail("software did not program UART baud divider");
                if (!ctrl_write_seen)      fail("software did not program UART control");
            end

            if ((cycles % PROGRESS_EVERY) == 0)
                $display("PROGRESS cycle=%0d retired=%0d pc=%08x ins=%08x uart=%0d",
                         cycles, retired, dut.pc, dut.ins, uart_pin_chars);

            if (cycles >= max_cycles)
                fail("maximum cycle limit reached");
        end
    end

    // Optional focused trace for the first byte loaded from "Start Coremark".
    // It follows the load at PC 0x24fc through EX/MEM/WB and also shows the
    // actual DMEM word, which separates RAM contents from pipeline alignment.
    always @(posedge clk) begin
        if (hard_rst_n && $test$plusargs("TRACE_FIRST_LOAD") &&
            ((dut.u_cpu.u_exu.ex_pc == 32'h0000_24fc) ||
             (dut.u_cpu.u_memu.mem_pc == 32'h0000_24fc) ||
             (dut.u_cpu.u_wbu.wb_pc == 32'h0000_24fc))) begin
            $strobe("LOAD_TRACE cycle=%0d ex_pc=%08x ex_addr=%08x mem_pc=%08x mem_rdata=%08x mem_wb=%08x wb_pc=%08x wb_data=%08x ram_word=%08x",
                    cycles,
                    dut.u_cpu.u_exu.ex_pc, dut.u_cpu.ex_result,
                    dut.u_cpu.u_memu.mem_pc, dut.dmem_rdata,
                    dut.u_cpu.mem_wb_data,
                    dut.u_cpu.u_wbu.wb_pc, dut.u_cpu.wb_data,
                    dut.u_memory.u_dmem.mem[12'h137]);
        end
    end

    // Receive exactly what leaves FPIOA[31], at the centre of every 8-N-1 bit.
    initial begin
        @(posedge hard_rst_n);
        forever begin
            wait (fpioa[31] === 1'b1);
            @(negedge fpioa[31]);
            #(BIT_NS * 0.5);
            if (fpioa[31] !== 1'b0) begin
                $display("UART false start at %0t", $time);
            end else begin
                for (b = 0; b < 8; b = b + 1) begin
                    #(BIT_NS);
                    rx_byte[b] = fpioa[31];
                end
                #(BIT_NS);
                stop_bit = fpioa[31];
                uart_pin_chars = uart_pin_chars + 1;
                if (stop_bit !== 1'b1) begin
                    uart_framing_errors = uart_framing_errors + 1;
                    $display("UART framing error: byte=%02x time=%0t", rx_byte, $time);
                end else begin
                    uart_frames_ok = uart_frames_ok + 1;
                end

                $write("%c", rx_byte);
                if (uart_log != 0) begin
                    $fwrite(uart_log, "%c", rx_byte);
                    $fflush(uart_log);
                end

                if ((uart_pin_chars > uart_sw_chars) ||
                    (rx_byte !== uart_sw_fifo[uart_pin_chars - 1])) begin
                    uart_data_errors = uart_data_errors + 1;
                    $display("UART data mismatch: frame=%0d expected=%02x got=%02x time=%0t",
                             uart_pin_chars, uart_sw_fifo[uart_pin_chars - 1], rx_byte, $time);
                end

                start_window = {start_window[8*14-1:0], rx_byte};
                if (uart_pin_chars == 15) begin
                    if (start_window != START_TEXT)
                        fail("startup UART text differs from official CoreMark banner");
                    if (smoke_mode)
                        smoke_pass;
                end

                pass_window = {pass_window[8*26-1:0], rx_byte};
                if (pass_window == PASS_TEXT) begin
                    pass_seen = 1;
                    if (uart_framing_errors != 0 || uart_data_errors != 0)
                        fail("CoreMark passed but UART data or framing errors occurred");
                    pass;
                end

                if (rx_byte == "E") error_seen = 1;
                if (error_seen && rx_byte == "!")
                    fail("CoreMark printed an error indication");
            end
        end
    end

    initial begin
        cycles = 0;
        retired = 0;
        mmio_writes = 0;
        uart_sw_chars = 0;
        uart_pin_chars = 0;
        uart_frames_ok = 0;
        uart_framing_errors = 0;
        uart_data_errors = 0;
        fpioa_uart_map_seen = 0;
        baud_write_seen = 0;
        ctrl_write_seen = 0;
        error_seen = 0;
        pass_seen = 0;
        smoke_mode = $test$plusargs("SMOKE");
        last_tx_write_cycle = -1;
        last_pc_change_cycle = 0;
        last_pc = 32'hffff_ffff;
        start_window = {8*15{1'b0}};
        pass_window = {8*27{1'b0}};
        max_cycles = DEFAULT_MAX_CYCLES;
        if ($value$plusargs("MAX_CYCLES=%d", max_cycles))
            $display("Using MAX_CYCLES=%0d", max_cycles);

        uart_log = $fopen("coremark_uart.log", "w");
        if (uart_log == 0)
            $display("WARNING: cannot open coremark_uart.log");

        if ($test$plusargs("VCD")) begin
            $dumpfile("tb_coremark_full.vcd");
            $dumpvars(0, tb_coremark_full);
        end

        repeat (40) @(posedge clk);
        hard_rst_n = 1'b1;
        $display("CoreMark reset released. Waiting for UART output...");
    end
endmodule

// Example Icarus command (run from sim):
// iverilog -g2012 -s tb_coremark_full -o tb_coremark_full.vvp \
//   tb_coremark_sim_stubs.v ../source/soc/config.v \
//   ../source/soc/defines.v ../source/soc/fpga_unified_memory.v \
//   ../source/soc/Hfpga_soc.v ../source/cpu/Halu.v ../source/cpu/Hexu.v \
//   ../source/cpu/Hidu.v ../source/cpu/Hifu.v ../source/cpu/Hmemu_fpga.v \
//   ../source/cpu/HReg.v ../source/cpu/Htop.v ../source/jtag/full_handshake_rx.v \
//   ../source/jtag/full_handshake_tx.v ../source/jtag/jtag_dm.v \
//   ../source/jtag/jtag_driver.v ../source/jtag/jtag_top.v \
//   ../source/source/soc/Hled.v ../source/source/cpu/HRegFile.v \
//   ../source/source/cpu/Hmemu.v ../source/source/cpu/Hwbu.v \
//   ../source/source/cpu/mul.v ../source/source/cpu/div.v ../source/source/cpu/Hcsr.v \
//   ../source/small-eyes1/source/soc/Hfpioa_simple.v \
//   ../source/small-eyes/small-eyes1/source/soc/Huart_tx.v \
//   tb_coremark_full.sv
// vvp -n tb_coremark_full.vvp +MAX_CYCLES=2000000
