`timescale 1ns / 1ps

// Board-accurate sim with a rigorous UART receiver: samples at bit centres and
// validates the stop bit, i.e. it sees what a real USB-serial adapter sees.
module tb_uart;
    reg clk = 1'b0;
    reg hard_rst_n = 1'b0;
    always #18.5 clk = ~clk;          // 27 MHz

    wire [31:0] fpioa;
    wire core_active, JTAG_TDO;
    reg JTAG_TCK = 1'b0, JTAG_TMS = 1'b1, JTAG_TDI = 1'b0;

    Hfpga_soc dut (
        .clk(clk), .hard_rst_n(hard_rst_n),
        .JTAG_TCK(JTAG_TCK), .JTAG_TMS(JTAG_TMS), .JTAG_TDI(JTAG_TDI),
        .JTAG_TDO(JTAG_TDO), .core_active(core_active), .fpioa(fpioa)
    );

    // ---- what software asked for ----
    integer sw_chars = 0;
    reg [7:0] sw_buf [0:255];
    always @(posedge clk) begin
        if (hard_rst_n && dut.dmem_valid && dut.dmem_wen &&
            (dut.dmem_addr == 32'h4000_000c)) begin
            sw_buf[sw_chars] = dut.dmem_wdata[7:0];
            sw_chars = sw_chars + 1;
        end
    end

    // ---- what actually leaves the pin ----
    localparam real BIT_NS = 1_000_000_000.0 / 115200.0;
    wire tx_line = fpioa[31];

    integer rx_ok = 0, rx_framing_err = 0, rx_total = 0;
    reg [7:0] rx_byte;
    reg       stop_bit;
    integer   k;
    reg [8*160:1] verdict;

    initial begin
        @(posedge hard_rst_n);
        forever begin
            // idle -> start bit
            wait (tx_line === 1'b1);
            @(negedge tx_line);
            #(BIT_NS * 0.5);
            if (tx_line !== 1'b0) begin
                $display("[RX] false start at %0t", $time);
            end else begin
                for (k = 0; k < 8; k = k + 1) begin
                    #(BIT_NS);
                    rx_byte[k] = tx_line;
                end
                #(BIT_NS);
                stop_bit = tx_line;
                rx_total = rx_total + 1;
                if (stop_bit === 1'b1) begin
                    rx_ok = rx_ok + 1;
                    $display("[RX %0d] %02x '%c'  stop=OK", rx_total, rx_byte, rx_byte);
                end else begin
                    rx_framing_err = rx_framing_err + 1;
                    $display("[RX %0d] %02x       stop=FRAMING-ERROR (line low at stop-bit centre)",
                             rx_total, rx_byte);
                end
            end
        end
    end

    // ---- measure software write spacing vs. one frame time ----
    integer cyc = 0;
    integer last_write_cyc = -1;
    always @(posedge clk) begin
        if (hard_rst_n) begin
            cyc = cyc + 1;
            if (dut.dmem_valid && dut.dmem_wen && (dut.dmem_addr == 32'h4000_000c)) begin
                if (last_write_cyc >= 0)
                    $display("   write spacing = %0d cycles (frame needs %0d)",
                             cyc - last_write_cyc,
                             10 * (dut.u_uart0_tx.baud_div + 1));
                last_write_cyc = cyc;
            end
        end
    end

    initial begin
        repeat (40) @(posedge clk);
        hard_rst_n = 1'b1;
    end

    initial begin
        #`SIM_TIME_NS;
        $display("\n================ SUMMARY ================");
        $display("chars software wrote to TXDATA : %0d", sw_chars);
        $write  ("software intended             : \"");
        for (k = 0; k < sw_chars; k = k + 1) $write("%c", sw_buf[k]);
        $display("\"");
        $display("frames seen on fpioa[31]       : %0d", rx_total);
        $display("  framing OK                   : %0d", rx_ok);
        $display("  framing ERROR                : %0d", rx_framing_err);
        $display("baud_div register              : %0d (=> %0d cycles/bit)",
                 dut.u_uart0_tx.baud_div, dut.u_uart0_tx.baud_div + 1);
        $finish;
    end
endmodule
