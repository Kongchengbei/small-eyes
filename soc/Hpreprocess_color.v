`timescale 1ns / 1ps

// RGB565 原始颜色粗筛。优先级：红、黄、蓝、黑；0 表示非候选。
// 阈值为 RGB888 数值，不是模型类别。黑色默认可由 color_enable[3] 关闭。
// 红、蓝按比例判（2026-10-09 定）：红 8g<=5r 且 8b<=5r，蓝 2r<=b 且 8g<=5b，
// 都还要过 bright_min；黄、黑不变，dominance 只用于黄。
module Hpreprocess_color (
    input [15:0] pixel,
    input [3:0] color_enable,
    input [7:0] bright_min,
    input [7:0] dominance,
    input [7:0] black_max,
    output [2:0] color
);
    wire [7:0] r = {pixel[15:11], pixel[15:13]};
    wire [7:0] g = {pixel[10:5], pixel[10:9]};
    wire [7:0] b = {pixel[4:0], pixel[4:2]};
    // 比例项用 11 位乘常数（移位相加），黄色阈值仍用九位加法，都不会溢出。
    wire [10:0] r1 = {3'b0, r}, b1 = {3'b0, b};
    wire [10:0] r2 = {2'b0, r, 1'b0};
    wire [10:0] g8 = {g, 3'b0}, b8 = {b, 3'b0};
    wire [10:0] r5 = {1'b0, r, 2'b0} + r1, b5 = {1'b0, b, 2'b0} + b1;
    wire red = (r >= bright_min) && (g8 <= r5) && (b8 <= r5);
    wire yellow = (r >= bright_min) && (g >= bright_min) &&
                  ({1'b0,r} >= {1'b0,b}+{1'b0,dominance}) &&
                  ({1'b0,g} >= {1'b0,b}+{1'b0,dominance});
    wire blue = (b >= bright_min) && (r2 <= b1) && (g8 <= b5);
    wire black = (r <= black_max) && (g <= black_max) && (b <= black_max);
    assign color = color_enable[0] && red ? 3'd1 :
                   color_enable[1] && yellow ? 3'd2 :
                   color_enable[2] && blue ? 3'd3 :
                   color_enable[3] && black ? 3'd4 : 3'd0;
endmodule
