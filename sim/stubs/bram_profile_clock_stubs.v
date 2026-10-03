`timescale 1ns / 1ps

// Simulation-only board clock and I/O primitive substitutes for running the
// selected BRAM Hfpga_soc profile without vendor libraries.
module clk_pll(input wire clkin1, output reg clkout0, output reg lock);
    integer lock_count;
    initial begin
        clkout0 = 1'b0;
        lock = 1'b0;
        lock_count = 0;
    end
    always @(posedge clkin1) begin
        clkout0 <= ~clkout0;
        if (lock_count < 4) begin
            lock_count <= lock_count + 1;
            if (lock_count == 3) lock <= 1'b1;
        end
    end
endmodule

module GTP_INBUF #(parameter IOSTANDARD="DEFAULT", parameter TERM_DDR="ON")
    (output wire O, input wire I);
    assign O = I;
endmodule

module GTP_INBUFGDS #(parameter IOSTANDARD="DEFAULT", parameter TERM_DIFF="ON")
    (output wire O, input wire I, input wire IB);
    assign O = I;
endmodule

module GTP_CFGCLK(input wire CLKIN, input wire CE_N);
    // The testbench observes the connected internal SCK wire hierarchically.
endmodule
