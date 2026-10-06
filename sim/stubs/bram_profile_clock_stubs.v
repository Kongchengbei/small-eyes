`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// Simulation-only board clock and I/O primitive substitutes for running the
// selected BRAM Hfpga_soc profile without vendor libraries.
module clk_pll #(
`ifdef BRAM_UART_REAL_CLOCK
    parameter integer CPU_HZ = `SOC_CPU_HZ
`else
    parameter integer CPU_HZ = 0
`endif
)
    (input wire clkin1, output reg clkout0, output reg lock);
    integer lock_count;
    initial begin
        clkout0 = 1'b0;
        lock = 1'b0;
        lock_count = 0;
    end
    always @(posedge clkin1) begin
        if (lock_count < 4) begin
            lock_count <= lock_count + 1;
            if (lock_count == 3) lock <= 1'b1;
        end
    end
    generate
        if (CPU_HZ == 0) begin: legacy_clock
            always @(posedge clkin1) clkout0 <= ~clkout0;
        end else begin: frequency_clock
            initial forever #(500000000.0 / CPU_HZ) clkout0 = ~clkout0;
        end
    endgenerate
endmodule

module GTP_INBUF #(parameter IOSTANDARD="DEFAULT", parameter TERM_DDR="ON")
    (output wire O, input wire I);
    assign O = I;
endmodule

module GTP_INBUFGDS #(parameter IOSTANDARD="DEFAULT", parameter TERM_DIFF="ON")
    (output wire O, input wire I, input wire IB);
    assign O = I;
endmodule

`ifndef BRAM_VENDOR_IP_SIM
module GTP_CFGCLK(input wire CLKIN, input wire CE_N);
    // The legacy Flash boot test observes the connected internal SCK.
endmodule
`endif
