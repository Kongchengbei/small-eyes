`timescale 1ns / 1ps

module tb_npu_quant;
    reg signed [63:0] acc;
    reg signed [31:0] multiplier;
    reg [5:0] shift;
    reg signed [7:0] output_zero_point;
    reg relu_enable;
    wire signed [7:0] q_out;
    wire saturated;

    Hnpu_quant dut (
        .acc(acc), .multiplier(multiplier), .shift(shift),
        .output_zero_point(output_zero_point), .relu_enable(relu_enable),
        .q_out(q_out), .saturated(saturated)
    );

    task expect_value;
        input signed [63:0] a;
        input signed [31:0] m;
        input [5:0] s;
        input signed [7:0] zp;
        input relu;
        input signed [7:0] expected;
        input sat;
        begin
            acc = a;
            multiplier = m;
            shift = s;
            output_zero_point = zp;
            relu_enable = relu;
            #1;
            if (q_out !== expected || saturated !== sat)
                $fatal(1, "NPU_QUANT_FAIL acc=%0d mult=%0d shift=%0d got=%0d sat=%0d expected=%0d sat=%0d",
                       a, m, s, q_out, saturated, expected, sat);
        end
    endtask

    initial begin
        expect_value(10, 1, 1, 0, 0, 5, 0);
        expect_value(11, 1, 1, 0, 0, 6, 0);
        expect_value(-10, 1, 1, 0, 0, -5, 0);
        expect_value(-11, 1, 1, 0, 0, -6, 0);
        expect_value(300, 1, 0, 0, 0, 127, 1);
        expect_value(-300, 1, 0, 0, 0, -128, 1);
        expect_value(-3, 1, 0, 5, 1, 5, 0);
        expect_value(-3, 1, 0, 5, 0, 2, 0);
        $display("NPU_QUANT_PASS");
        $finish;
    end
endmodule
