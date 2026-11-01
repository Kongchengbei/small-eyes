`timescale 1ns / 1ps

//24译码器
module decoder_2_4 (
    input  [1:0] in,
    output [3:0] out
);
    assign out = (in == 2'd0) ? 4'b0001 :
                 (in == 2'd1) ? 4'b0010 :
                 (in == 2'd2) ? 4'b0100 : 4'b1000;
endmodule

//低位优先的独热码查找器
module one_valid_n #(
    parameter N = 2
) (
    input      [N-1:0] in,
    output reg [N-1:0] out,
    output wire nozero
);
    integer i;
    always @(*) begin
        out = {N{1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            if (in[i] && (out == {N{1'b0}}))
                out = (1 << i);
        end
    end
    assign nozero = |in;
endmodule

//随机数生成
module lfsr (
    input        clk,
    input        reset,
    output [1:0] random_val
);
    reg [7:0] r_lfsr;

    always @(posedge clk) begin
        if (reset)
            r_lfsr <= 8'b1;
        else begin
            r_lfsr[0] <= r_lfsr[7];
            r_lfsr[1] <= r_lfsr[0];
            r_lfsr[2] <= r_lfsr[1];
            r_lfsr[3] <= r_lfsr[2];
            r_lfsr[4] <= r_lfsr[3] ^ r_lfsr[7];
            r_lfsr[5] <= r_lfsr[4] ^ r_lfsr[7];
            r_lfsr[6] <= r_lfsr[5] ^ r_lfsr[7];
            r_lfsr[7] <= r_lfsr[6];
        end
    end

    assign random_val = r_lfsr[7:6];
endmodule
