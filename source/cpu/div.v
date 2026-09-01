`timescale 1ns / 1ps

module div (
    input         div_clk,
    input         reset,
    input         start,
    input         div_signed,
    input  [31:0] x,
    input  [31:0] y,
    output [31:0] s,
    output [31:0] r,
    output        done
);
    reg [31:0] dividend_work;
    reg [31:0] divisor_work;
    reg [31:0] quotient_work;
    reg [31:0] remainder_work;

    reg [31:0] quotient_reg;
    reg [31:0] remainder_reg;

    reg        quotient_negative;
    reg        remainder_negative;
    reg [5:0]  count;
    reg        busy_reg;
    reg        done_reg;

    wire [31:0] dividend_abs;
    wire [31:0] divisor_abs;
    wire [32:0] remainder_shift;
    wire        quotient_bit;
    wire [32:0] remainder_next;
    wire [31:0] quotient_next;
    wire [31:0] dividend_next;

    assign dividend_abs = (div_signed && x[31]) ? (~x + 32'd1) : x;
    assign divisor_abs  = (div_signed && y[31]) ? (~y + 32'd1) : y;

    assign remainder_shift = {remainder_work, dividend_work[31]};
    assign quotient_bit = remainder_shift >= {1'b0, divisor_work};
    assign remainder_next = quotient_bit
                          ? remainder_shift - {1'b0, divisor_work}
                          : remainder_shift;
    assign quotient_next = {quotient_work[30:0], quotient_bit};
    assign dividend_next = {dividend_work[30:0], 1'b0};

    always @(posedge div_clk) begin
        if (reset) begin
            dividend_work    <= 32'b0;
            divisor_work     <= 32'b0;
            quotient_work    <= 32'b0;
            remainder_work   <= 32'b0;
            quotient_reg     <= 32'b0;
            remainder_reg    <= 32'b0;
            quotient_negative<= 1'b0;
            remainder_negative<=1'b0;
            count            <= 6'd0;
            busy_reg         <= 1'b0;
            done_reg         <= 1'b0;
        end else begin
            done_reg <= 1'b0;


            if (busy_reg) begin
                dividend_work  <= dividend_next;
                quotient_work  <= quotient_next;
                remainder_work <= remainder_next[31:0];

                if (count == 6'd31) begin
                    quotient_reg <= quotient_negative
                                  ? (~quotient_next + 32'd1)
                                  : quotient_next;
                    remainder_reg <= remainder_negative
                                   ? (~remainder_next[31:0] + 32'd1)
                                   : remainder_next[31:0];
                    busy_reg <= 1'b0;
                    done_reg <= 1'b1;
                end else begin
                    count <= count + 6'd1;
                end
            end else if (start) begin
                quotient_negative <= div_signed && (x[31] ^ y[31]);
                remainder_negative<= div_signed && x[31];

                //两个异常结果
                if (y == 32'b0) begin
                    quotient_reg  <= 32'hffff_ffff;
                    remainder_reg <= x;
                    done_reg      <= 1'b1;
                end else if (div_signed &&
                             (x == 32'h8000_0000) &&
                             (y == 32'hffff_ffff)) begin
                    quotient_reg  <= 32'h8000_0000;
                    remainder_reg <= 32'b0;
                    done_reg      <= 1'b1;
                end else begin
                    dividend_work  <= dividend_abs;
                    divisor_work   <= divisor_abs;
                    quotient_work  <= 32'b0;
                    remainder_work <= 32'b0;
                    count          <= 6'd0;
                    busy_reg       <= 1'b1;
                end
            end
        end
    end

    assign s    = quotient_reg;
    assign r    = remainder_reg;
    assign done = done_reg;

endmodule

