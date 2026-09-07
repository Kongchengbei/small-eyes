`timescale 1ns / 1ps

// Two-cycle RV32M multiplier.
//
// A 33-bit signed representation covers the four RV32M signedness modes:
// sign-extend a signed operand, or prepend zero to an unsigned operand.
// The operands are split at bit 16.  Four independent 17x17 partial products
// are registered in cycle 1; their aligned sum is registered in cycle 2.
module mul (
    input         clk,
    input         rst,
    input         start,
    input         x_signed,
    input         y_signed,
    input  [31:0] x,
    input  [31:0] y,
    output [63:0] result,
    output        done
);

    wire signed [32:0] x_ext;
    wire signed [32:0] y_ext;
    wire        [15:0] x_lo;
    wire        [15:0] y_lo;
    wire signed [16:0] x_hi;
    wire signed [16:0] y_hi;
    wire signed [16:0] x_lo_signed;
    wire signed [16:0] y_lo_signed;

    // Stage 1: four independent partial products.
    wire        [31:0] p00_calc;
    wire signed [33:0] p01_calc;
    wire signed [33:0] p10_calc;
    wire signed [33:0] p11_calc;
    reg         [31:0] p00_q;
    reg signed  [33:0] p01_q;
    reg signed  [33:0] p10_q;
    reg signed  [33:0] p11_q;
    reg                 stage1_valid;

    // Stage 2: align and add the registered partial products.
    wire signed [65:0] p00_aligned;
    wire signed [65:0] p01_aligned;
    wire signed [65:0] p10_aligned;
    wire signed [65:0] p11_aligned;
    wire signed [65:0] product_next;
    reg  signed [65:0] product_q;
    reg                 done_q;

    assign x_ext       = x_signed ? {x[31], x} : {1'b0, x};
    assign y_ext       = y_signed ? {y[31], y} : {1'b0, y};
    assign x_lo        = x_ext[15:0];
    assign y_lo        = y_ext[15:0];
    assign x_hi        = x_ext[32:16];
    assign y_hi        = y_ext[32:16];
    assign x_lo_signed = {1'b0, x_lo};
    assign y_lo_signed = {1'b0, y_lo};

    assign p00_calc = x_lo * y_lo;
    assign p01_calc = x_lo_signed * y_hi;
    assign p10_calc = x_hi * y_lo_signed;
    assign p11_calc = x_hi * y_hi;

    assign p00_aligned = $signed({34'b0, p00_q});
    assign p01_aligned = $signed({{16{p01_q[33]}}, p01_q, 16'b0});
    assign p10_aligned = $signed({{16{p10_q[33]}}, p10_q, 16'b0});
    assign p11_aligned = $signed({p11_q, 32'b0});
    assign product_next = p00_aligned + p01_aligned +
                          p10_aligned + p11_aligned;

    always @(posedge clk) begin
        if (rst) begin
            p00_q        <= 32'b0;
            p01_q        <= 34'sd0;
            p10_q        <= 34'sd0;
            p11_q        <= 34'sd0;
            stage1_valid <= 1'b0;
            product_q    <= 66'sd0;
            done_q       <= 1'b0;
        end else begin
            done_q       <= stage1_valid;
            stage1_valid <= start;

            if (start) begin
                p00_q <= p00_calc;
                p01_q <= p01_calc;
                p10_q <= p10_calc;
                p11_q <= p11_calc;
            end

            if (stage1_valid) begin
                product_q <= product_next;
            end
        end
    end

    // MUL takes [31:0], and the three high-half instructions take [63:32]
    // in Hexu.  Every legal RV32M product is represented by these 64 bits.
    assign result = product_q[63:0];
    assign done   = done_q;

endmodule
