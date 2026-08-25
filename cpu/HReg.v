`timescale 1ns / 1ps

module HReg #(
    parameter  WIDTH = 32,
    parameter  RESET_VAL = 32'h80000000
) (
input clk,
input rst,
input [WIDTH-1:0] pc_next,
output reg [WIDTH-1:0] pc,
input wen
);
always @(posedge clk) begin
    if (rst) begin 
        pc <= RESET_VAL;
    end
    else if (wen) begin
        pc <= pc_next;
    end
end
endmodule
