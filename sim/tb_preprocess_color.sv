`timescale 1ns / 1ps
module tb_preprocess_color;
    reg [15:0] pixel;
    reg [3:0] enabled=15;
    reg [7:0] bright=128,dominance=64,black_max=32;
    wire [2:0] color;
    Hpreprocess_color dut(.pixel(pixel),.color_enable(enabled),.bright_min(bright),
        .dominance(dominance),.black_max(black_max),.color(color));
    task automatic check(input [15:0] value,input [2:0] expected);
        pixel=value;#1;
        if(color!==expected) $fatal(1,"color %h got %d expected %d",pixel,color,expected);
    endtask
    initial begin
        check(16'hf800,1);check(16'hffe0,2);check(16'h001f,3);check(16'h0000,4);
        check(16'h8410,0);check(16'hffff,0);check(16'h07e0,0);
        // 红、蓝按比例判的边界（2026-10-09 定）：红 8g<=5r 且 8b<=5r，蓝 2r<=b 且 8g<=5b。
        check(16'hfce0,1);check(16'hfd00,2); // r=255：g=158 仍是红，g=162 归黄。
        check(16'hf813,1);check(16'hf814,0); // r=255：b=156 仍是红，b=165 不是。
        check(16'h781f,3);check(16'h801f,0); // b=255：r=123 仍是蓝，r=132 不是。
        check(16'h04ff,3);check(16'h051f,0); // b=255：g=158 仍是蓝，g=162 不是。
        check(16'h8000,1);check(16'h7800,0); // bright_min=128：r=132 是红，r=123 不是。
        enabled=7;check(16'h0000,0);
        enabled=0;check(16'hf800,0);
        enabled=15;dominance=255;
        check(16'hf800,1);check(16'hf820,1); // 红不用 dominance。
        check(16'hffe0,2);check(16'hffe1,0); // B非零时255+B不能8位回绕。
        $display("PREPROCESS_COLOR PASS red/yellow/blue/black, ratio boundaries, masks, wide thresholds");
        $finish;
    end
endmodule
