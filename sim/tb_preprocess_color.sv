`timescale 1ns / 1ps
module tb_preprocess_color;
    reg [15:0] pixel;
    reg [3:0] enabled=15;
    reg [7:0] bright=128,red_blue_bright=128,dominance=64,black_max=32;
    wire [2:0] color;
    Hpreprocess_color dut(.pixel(pixel),.color_enable(enabled),.bright_min(bright),
        .red_blue_bright_min(red_blue_bright),
        .dominance(dominance),.black_max(black_max),.color(color));
    task automatic exhaustive_profile(input integer red_blue_threshold);
        integer pixel_index;
        integer red5, green6, blue5;
        integer red8, green8, blue8;
        reg expected_red, expected_yellow, expected_blue, expected_black;
        reg [2:0] expected_color;
        begin
            bright=64;red_blue_bright=red_blue_threshold;dominance=64;black_max=32;enabled=15;
            for(pixel_index=0;pixel_index<65536;pixel_index=pixel_index+1) begin
                pixel=pixel_index[15:0];
                red5=(pixel_index>>11)&31;green6=(pixel_index>>5)&63;blue5=pixel_index&31;
                red8=(red5<<3)|(red5>>2);green8=(green6<<2)|(green6>>4);blue8=(blue5<<3)|(blue5>>2);
                expected_red=(red8>=red_blue_threshold)&&(8*green8<=5*red8)&&(8*blue8<=5*red8);
                expected_yellow=(red8>=64)&&(green8>=64)&&(red8>=blue8+64)&&(green8>=blue8+64);
                expected_blue=(blue8>=red_blue_threshold)&&(2*red8<=blue8)&&(8*green8<=5*blue8);
                expected_black=(red8<=32)&&(green8<=32)&&(blue8<=32);
                if(expected_red)expected_color=1;
                else if(expected_yellow)expected_color=2;
                else if(expected_blue)expected_color=3;
                else if(expected_black)expected_color=4;
                else expected_color=0;
                #1;
                if(color!==expected_color)
                    $fatal(1,"red-blue threshold %0d pixel %h got %d expected %d",red_blue_threshold,pixel,color,expected_color);
            end
        end
    endtask
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
        red_blue_bright=48;
        check(16'h3000,1);check(16'h2800,0);
        check(16'h0008,3);check(16'h0005,0);
        enabled=7;check(16'h0000,0);
        enabled=0;check(16'hf800,0);
        enabled=15;dominance=255;
        check(16'hf800,1);check(16'hf820,1); // 红不用 dominance。
        check(16'hffe0,2);check(16'hffe1,0); // B非零时255+B不能8位回绕。
        exhaustive_profile(40);
        exhaustive_profile(48);
        $display("PREPROCESS_COLOR PASS red-blue thresholds 0x28/0x30, exhaustive RGB565, ratio boundaries, masks");
        $finish;
    end
endmodule
