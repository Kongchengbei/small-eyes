`timescale 1ns / 1ps

module mul (
    input         x_signed,
    input         y_signed,
    input  [31:0] x,
    input  [31:0] y,
    output [63:0] result
);

    wire signed [63:0] x_ext;
    wire signed [63:0] y_ext;
    wire signed [63:0] product;

    assign x_ext = x_signed ? {{32{x[31]}}, x} : {32'b0, x};
    assign y_ext = y_signed ? {{32{y[31]}}, y} : {32'b0, y};
    assign product = x_ext * y_ext;
    assign result = product;

endmodule
