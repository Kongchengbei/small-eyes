`timescale 1ns / 1ps

module Hled #(
    parameter WIDTH = 4
) (
    input                   clk,
    input                   rst_n,
    input                   wr_en,
    input       [31:0]      wr_data,
    input       [3:0]       wr_mask,
    output reg  [WIDTH-1:0] led
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            led <= {WIDTH{1'b0}};
        else if (wr_en && wr_mask[0])
            led <= wr_data[WIDTH-1:0];
    end
endmodule
