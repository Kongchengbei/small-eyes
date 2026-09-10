`timescale 1ns / 1ps

// Board-accurate simulation of Hfpga_soc: synchronous BRAM (1-cycle read),
// no JTAG activity, program pre-loaded into IMEM exactly like the bitstream does.
module tb_board;
    reg clk = 1'b0;
    reg hard_rst_n = 1'b0;
    always #18.5 clk = ~clk;          // 27 MHz

    wire [31:0] fpioa;
    wire        core_active;
    wire        JTAG_TDO;

    // JTAG pins idle, exactly as when nothing is plugged into the header.
    reg JTAG_TCK = 1'b0;
    reg JTAG_TMS = 1'b1;
    reg JTAG_TDI = 1'b0;

    Hfpga_soc dut (
        .clk         (clk),
        .hard_rst_n  (hard_rst_n),
        .JTAG_TCK    (JTAG_TCK),
        .JTAG_TMS    (JTAG_TMS),
        .JTAG_TDI    (JTAG_TDI),
        .JTAG_TDO    (JTAG_TDO),
        .core_active (core_active),
        .fpioa       (fpioa)
    );

    // ---------------- instrumentation ----------------
    integer cycles      = 0;
    integer uart_chars  = 0;
    integer mmio_writes = 0;
    reg [31:0] last_mcause = 32'h0;
    reg [31:0] prev_wb_pc  = 32'hffff_ffff;
    integer restart_count = 0;

    wire        dmem_valid = dut.dmem_valid;
    wire        dmem_wen   = dut.dmem_wen;
    wire [31:0] dmem_addr  = dut.dmem_addr;
    wire [31:0] dmem_wdata = dut.dmem_wdata;
    wire [3:0]  dmem_wmask = dut.dmem_wmask;
    wire [31:0] wb_pc      = dut.pc;
    wire [31:0] wb_ins     = dut.ins;

    always @(posedge clk) begin
        if (hard_rst_n) begin
            cycles = cycles + 1;

            if (dmem_valid && dmem_wen && (dmem_addr[31:28] == 4'h4)) begin
                mmio_writes = mmio_writes + 1;
                if (mmio_writes <= 40)
                    $display("MMIO[%0d] cyc=%0d wb_pc=%08x addr=%08x data=%08x mask=%x",
                             mmio_writes, cycles, wb_pc, dmem_addr, dmem_wdata, dmem_wmask);
                if (dmem_addr == 32'h4000_000c) begin
                    uart_chars = uart_chars + 1;
                    $write("%c", dmem_wdata[7:0]);
                    $fflush();
                end
                if (dmem_addr == 32'h4000_0008)
                    $display("[UART] baud_div=%0d", dmem_wdata[15:0]);
            end

            // did the core fall back to the reset vector?
            if ((wb_pc == 32'h0000_0000) && (prev_wb_pc != 32'h0000_0000) && (cycles > 50)) begin
                restart_count = restart_count + 1;
                $display("RESTART#%0d cyc=%0d prev_wb_pc=%08x", restart_count, cycles, prev_wb_pc);
                if (restart_count >= 3) begin
                    $display("=> core keeps restarting, stopping. uart_chars=%0d", uart_chars);
                    $finish;
                end
            end
            prev_wb_pc = wb_pc;

            if (dut.u_cpu.u_exu.u_csr.csr_mcause != last_mcause) begin
                $display("MCAUSE cyc=%0d wb_pc=%08x mcause=%08x mepc=%08x mtvec=%08x",
                         cycles, wb_pc, dut.u_cpu.u_exu.u_csr.csr_mcause,
                         dut.u_cpu.u_exu.u_csr.csr_mepc,
                         dut.u_cpu.u_exu.u_csr.csr_mtvec);
                last_mcause = dut.u_cpu.u_exu.u_csr.csr_mcause;
            end

            if ((cycles % 20000) == 0)
                $display("PROGRESS cyc=%0d wb_pc=%08x wb_ins=%08x chars=%0d",
                         cycles, wb_pc, wb_ins, uart_chars);
        end
    end

    // ---------------- serial line decode on the routed pin ----------------
    // 27 MHz / 115200 baud
    localparam real BIT_NS = 1_000_000_000.0 / 115200.0;
    integer tx_bytes = 0;
    reg [7:0] rx_byte;
    integer b;
    initial begin
        @(posedge hard_rst_n);
        forever begin
            @(negedge fpioa[31]);                 // start bit on the routed TX pin
            #(BIT_NS * 1.5);
            for (b = 0; b < 8; b = b + 1) begin
                rx_byte[b] = fpioa[31];
                #(BIT_NS);
            end
            tx_bytes = tx_bytes + 1;
            $display("PIN_RX[%0d] = %02x '%c'", tx_bytes, rx_byte, rx_byte);
        end
    end

    initial begin
        repeat (40) @(posedge clk);
        hard_rst_n = 1'b1;
        $display("--- reset released, cpu_rst=%b ---", dut.cpu_rst);
    end

    initial begin
        #`SIM_TIME_NS;
        $display("\nTIMEOUT cyc=%0d wb_pc=%08x wb_ins=%08x uart_chars=%0d pin_bytes=%0d",
                 cycles, wb_pc, wb_ins, uart_chars, tx_bytes);
        $finish;
    end
endmodule
