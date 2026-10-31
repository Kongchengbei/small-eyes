`timescale 1ns / 1ps

// RGB565 原始颜色粗筛。优先级：红、黄、蓝、黑；0 表示非候选。
// 阈值为 RGB888 数值，不是模型类别。黑色默认可由 color_enable[3] 关闭。
// 红、蓝按比例判（2026-10-09 定）：红 8g<=5r 且 8b<=5r，蓝 2r<=b 且 8g<=5b，
// 红、蓝使用独立 red_blue_bright_min；黄、黑不变，dominance 只用于黄。
// 10-19 时序版：判定结果与上一版逐位相同（全输入形式等价已证），只换写法、不用加法器和进位链。
// RGB565 分量扩展到 RGB888 是严格单调的，所以比例项可以直接按 565 分量查上限表
// （例如 8g<=5r 等价于 G<=gmax_58(R)）；和阈值的比较用按位与或式；
// 黄色的 r>=b+dominance 先做两级进位保留加法，再只算最高位进位。
module Hpreprocess_color (
    input [15:0] pixel,
    input [3:0] color_enable,
    input [7:0] bright_min,
    input [7:0] red_blue_bright_min,
    input [7:0] dominance,
    input [7:0] black_max,
    output [2:0] color
);
    wire [4:0] r565 = pixel[15:11];
    wire [5:0] g565 = pixel[10:5];
    wire [4:0] b565 = pixel[4:0];
    wire [7:0] r = {r565, r565[4:2]};
    wire [7:0] g = {g565, g565[5:4]};
    wire [7:0] b = {b565, b565[4:2]};

    // u >= v：按 3/3/2 位分三组各比一次再合并，写成与或式，综合不会推成进位链
    function ge8;
        input [7:0] u, v;
        reg gh, eh, gm, em, gl;
        begin
            gh = (u[7] & ~v[7]) | (~(u[7] ^ v[7]) & ((u[6] & ~v[6]) | (~(u[6] ^ v[6]) & u[5] & ~v[5])));
            eh = ~|(u[7:5] ^ v[7:5]);
            gm = (u[4] & ~v[4]) | (~(u[4] ^ v[4]) & ((u[3] & ~v[3]) | (~(u[3] ^ v[3]) & u[2] & ~v[2])));
            em = ~|(u[4:2] ^ v[4:2]);
            gl = (u[1] & ~v[1]) | (~(u[1] ^ v[1]) & (u[0] | ~v[0]));
            ge8 = gh | (eh & (gm | (em & gl)));
        end
    endfunction

    // u >= v + w（8 位无符号）：等价于 u + ~v + ~w + 514 >= 1024。
    // 两级进位保留加法压成 s、t，再用 3 位一组的先行进位只求 s + t 的第 10 位
    function ge_sum8;
        input [7:0] u, v, w;
        reg [9:0] k, x, y, s, t;
        reg [9:1] cg, cp;
        reg g1, g2, p2, g3, p3;
        begin
            k = 10'd514;
            x = {2'b0, u ^ ~v ^ ~w};
            y = {1'b0, (u & ~v) | (u & ~w) | (~v & ~w), 1'b0};
            s = x ^ y ^ k;
            t = {(x[8:0] & y[8:0]) | (x[8:0] & k[8:0]) | (y[8:0] & k[8:0]), 1'b0};
            cg = s[9:1] & t[9:1];  // t[0] 恒 0，第 0 位不产生进位
            cp = s[9:1] | t[9:1];
            g1 = cg[3] | (cp[3] & cg[2]) | (cp[3] & cp[2] & cg[1]);
            g2 = cg[6] | (cp[6] & cg[5]) | (cp[6] & cp[5] & cg[4]);
            p2 = cp[6] & cp[5] & cp[4];
            g3 = cg[9] | (cp[9] & cg[8]) | (cp[9] & cp[8] & cg[7]);
            p3 = cp[9] & cp[8] & cp[7];
            ge_sum8 = g3 | (p3 & g2) | (p3 & p2 & g1);
        end
    endfunction

    // 8*{G,G[5:4]} <= 5*{x,x[4:2]} 的最大 G（红的 8g<=5r、蓝的 8g<=5b 共用）
    // x=0..31 依次为: 0 1 2 3 5 6 7 8 10 11 12 14 15 16 17 18 20 21 22 24 25 26 28 29 30 31 32 34 35 36 38 39
    function [5:0] gmax_58;
        input [4:0] x;
        begin
            gmax_58[0] = (~x[4] & x[2] & ~x[0]) | (~x[2] & ~x[1] & x[0]) | (x[2] & ~x[1] & ~x[0]) | (x[4] & x[2] & x[1] & x[0]) | (~x[4] & ~x[3] & ~x[2] & x[0]);
            gmax_58[1] = (x[3] & x[1] & x[0]) | (x[3] & ~x[2] & ~x[1]) | (x[3] & ~x[1] & ~x[0]) | (~x[4] & ~x[3] & x[1] & ~x[0]) | (~x[3] & x[2] & ~x[1] & x[0]) | (~x[4] & ~x[2] & x[1] & x[0]) | (x[4] & x[3] & x[2] & x[1]) | (~x[3] & ~x[2] & x[1] & ~x[0]);
            gmax_58[2] = (x[4] & ~x[2] & ~x[1]) | (x[4] & x[2] & x[1]) | (~x[4] & x[3] & ~x[2] & x[1]) | (~x[4] & ~x[3] & x[2] & ~x[0]) | (x[4] & ~x[3] & x[1] & ~x[0]) | (~x[4] & x[2] & ~x[1] & ~x[0]) | (x[4] & x[3] & x[2] & x[0]) | (~x[4] & ~x[3] & x[2] & ~x[1]);
            gmax_58[3] = (~x[4] & x[3] & ~x[2]) | (x[4] & ~x[3] & x[2]) | (x[3] & ~x[2] & ~x[1]) | (x[4] & ~x[3] & x[1] & x[0]) | (~x[4] & x[3] & ~x[1] & ~x[0]) | (~x[3] & x[2] & x[1] & x[0]);
            gmax_58[4] = (x[4] & ~x[3]) | (x[4] & ~x[2] & ~x[1]) | (~x[4] & x[3] & x[2] & x[1]) | (~x[4] & x[3] & x[2] & x[0]);
            gmax_58[5] = (x[4] & x[3] & x[1]) | (x[4] & x[3] & x[2]);
        end
    endfunction
    // 8*{B,B[4:2]} <= 5*{x,x[4:2]} 的最大 B（红的 8b<=5r）
    // x=0..31 依次为: 0 0 1 1 2 3 3 4 5 5 6 6 7 8 8 9 10 10 11 11 12 13 13 14 15 15 16 16 17 18 18 19
    function [4:0] bmax_58;
        input [4:0] x;
        begin
            bmax_58[0] = (~x[3] & ~x[2] & x[1]) | (x[3] & ~x[2] & ~x[1]) | (~x[3] & x[1] & ~x[0]) | (x[3] & ~x[1] & ~x[0]) | (x[3] & x[2] & x[1] & x[0]) | (~x[3] & x[2] & ~x[1] & x[0]);
            bmax_58[1] = (x[4] & ~x[3] & ~x[2]) | (x[4] & ~x[2] & ~x[1]) | (x[4] & x[3] & x[2] & x[1]) | (~x[4] & x[3] & ~x[2] & x[1]) | (~x[4] & ~x[3] & x[2] & ~x[0]) | (x[4] & ~x[3] & x[1] & x[0]) | (~x[4] & x[2] & ~x[1] & ~x[0]) | (x[4] & x[3] & x[2] & x[0]) | (~x[4] & ~x[3] & x[2] & ~x[1]);
            bmax_58[2] = (~x[4] & x[3] & ~x[2]) | (x[4] & ~x[3] & x[2]) | (x[3] & ~x[2] & ~x[1]) | (~x[4] & x[3] & ~x[1] & ~x[0]) | (~x[3] & x[2] & x[1] & x[0]);
            bmax_58[3] = (x[4] & ~x[3]) | (x[4] & ~x[2] & ~x[1]) | (~x[4] & x[3] & x[2] & x[1]) | (~x[4] & x[3] & x[2] & x[0]);
            bmax_58[4] = (x[4] & x[3] & x[1]) | (x[4] & x[3] & x[2]);
        end
    endfunction
    // 2*{R,R[4:2]} <= {x,x[4:2]} 的最大 R（蓝的 2r<=b）
    // x=0..31 依次为: 0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 10 10 11 11 12 12 13 13 14 14 15 15
    function [4:0] rmax_21;
        input [4:0] x;
        rmax_21 = {1'b0, x[4:1]};  // 这张表化简后正好是 x>>1
    endfunction
    // 上面三张表写成与或式（由表逐位化简生成），不写成数组下标，免得综合推成 ROM 并把前级寄存器并进去

    wire r_bright = ge8(r, bright_min);
    wire g_bright = ge8(g, bright_min);
    wire b_bright = ge8(b, bright_min);
    wire rb_r_bright = ge8(r, red_blue_bright_min);
    wire rb_b_bright = ge8(b, red_blue_bright_min);
    wire red = rb_r_bright && ge8({2'b0, gmax_58(r565)}, {2'b0, g565}) &&
               ge8({3'b0, bmax_58(r565)}, {3'b0, b565});
    wire yellow = r_bright && g_bright && ge_sum8(r, b, dominance) && ge_sum8(g, b, dominance);
    wire blue = rb_b_bright && ge8({3'b0, rmax_21(b565)}, {3'b0, r565}) &&
                ge8({2'b0, gmax_58(b565)}, {2'b0, g565});
    wire black = ge8(black_max, r) && ge8(black_max, g) && ge8(black_max, b);
    assign color = color_enable[0] && red ? 3'd1 :
                   color_enable[1] && yellow ? 3'd2 :
                   color_enable[2] && blue ? 3'd3 :
                   color_enable[3] && black ? 3'd4 : 3'd0;
endmodule
