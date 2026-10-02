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
        enabled=7;check(16'h0000,0);
        enabled=0;check(16'hf800,0);
        enabled=15;dominance=255;
        check(16'hf800,1);check(16'hf820,0); // G非零时255+G不能8位回绕。
        $display("PREPROCESS_COLOR PASS red/yellow/blue/black, masks, wide thresholds");
        $finish;
    end
endmodule
