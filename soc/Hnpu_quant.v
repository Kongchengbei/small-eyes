`timescale 1ns / 1ps

// Shared signed-int8 requantization primitive.  The software model and RTL
// use round-to-nearest with exact half values rounded away from zero.
module Hnpu_quant (
    input  signed [63:0] acc,
    input  signed [31:0] multiplier,
    input         [5:0]  shift,
    input  signed [7:0]  output_zero_point,
    input                relu_enable,
    output reg signed [7:0] q_out,
    output reg             saturated
);
    reg signed [95:0] product;
    reg signed [95:0] magnitude;
    reg signed [95:0] magnitude_rounded;
    reg signed [95:0] scaled;
    reg signed [95:0] with_zero_point;
    reg signed [95:0] relu_value;
    reg signed [95:0] max_value;
    reg signed [95:0] min_value;

    always @(*) begin
        product = acc * multiplier;
        magnitude = (product < 0) ? -product : product;
        magnitude_rounded = magnitude;
        if (shift != 0)
            magnitude_rounded = magnitude + (96'sd1 <<< (shift - 1'b1));
        scaled = (shift == 0) ? product :
                 ((product < 0) ? -(magnitude_rounded >>> shift) :
                                  (magnitude_rounded >>> shift));
        with_zero_point = scaled + output_zero_point;
        // In an asymmetric activation domain, real zero is q=zero_point.
        relu_value = relu_enable && (with_zero_point < output_zero_point) ?
                     output_zero_point : with_zero_point;
        max_value = 96'sd127;
        min_value = -96'sd128;
        saturated = (relu_value > max_value) || (relu_value < min_value);
        if (relu_value > max_value)
            q_out = 8'sd127;
        else if (relu_value < min_value)
            q_out = -8'sd128;
        else
            q_out = relu_value[7:0];
    end
endmodule
