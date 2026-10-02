`timescale 1ns / 1ps

// 有界的同色包围框增长/合并器，每拍接收一个像素。
// 它是候选粗筛，并非精确连通域标记：与同色框的外扩一像素范围相交即合并。
// 多框同时命中时合并全部命中框；容量不足置 overflow，调用方丢弃整次任务。
module Hpreprocess_regions #(
    parameter integer MAX_REGIONS = 8
) (
    input clk, input rst_n, input clear,
    input pixel_valid, input [15:0] x, input [15:0] y, input [2:0] color,
    input [31:0] query_index,
    output query_valid, output [2:0] query_color,
    output [15:0] query_x0, output [15:0] query_y0,
    output [15:0] query_x1, output [15:0] query_y1,
    output [31:0] query_pixels,
    output reg overflow
);
    reg valid [0:MAX_REGIONS-1];
    reg [2:0] colors [0:MAX_REGIONS-1];
    reg [15:0] xs [0:MAX_REGIONS-1], xe [0:MAX_REGIONS-1];
    reg [15:0] ys [0:MAX_REGIONS-1], ye [0:MAX_REGIONS-1];
    reg [31:0] counts [0:MAX_REGIONS-1];
    integer i, first_hit, free_index;
    reg [15:0] mx0, my0, mx1, my1;
    reg [31:0] matched_count;
    reg [MAX_REGIONS-1:0] hit;

    assign query_valid = query_index < MAX_REGIONS ? valid[query_index] : 1'b0;
    assign query_color = query_index < MAX_REGIONS ? colors[query_index] : 3'b0;
    assign query_x0 = query_index < MAX_REGIONS ? xs[query_index] : 16'b0;
    assign query_y0 = query_index < MAX_REGIONS ? ys[query_index] : 16'b0;
    assign query_x1 = query_index < MAX_REGIONS ? xe[query_index] : 16'b0;
    assign query_y1 = query_index < MAX_REGIONS ? ye[query_index] : 16'b0;
    assign query_pixels = query_index < MAX_REGIONS ? counts[query_index] : 32'b0;

    always @* begin
        first_hit = -1; free_index = -1;
        mx0 = x; mx1 = x; my0 = y; my1 = y; matched_count = 1;
        hit = 0;
        for (i=0; i<MAX_REGIONS; i=i+1) begin
            if (!valid[i] && free_index == -1) free_index = i;
            if (valid[i] && colors[i] == color && color != 0 &&
                ({1'b0,x}+17'd1 >= {1'b0,xs[i]}) &&
                ({1'b0,x} <= {1'b0,xe[i]}+17'd1) &&
                ({1'b0,y}+17'd1 >= {1'b0,ys[i]}) &&
                ({1'b0,y} <= {1'b0,ye[i]}+17'd1)) begin
                hit[i] = 1;
                if (first_hit == -1) first_hit = i;
                if (xs[i] < mx0) mx0 = xs[i];
                if (xe[i] > mx1) mx1 = xe[i];
                if (ys[i] < my0) my0 = ys[i];
                if (ye[i] > my1) my1 = ye[i];
                matched_count = matched_count + counts[i];
            end
        end
    end

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overflow <= 0;
            for (j=0; j<MAX_REGIONS; j=j+1) begin
                valid[j] <= 0; colors[j] <= 0; xs[j] <= 0; xe[j] <= 0;
                ys[j] <= 0; ye[j] <= 0; counts[j] <= 0;
            end
        end else if (clear) begin
            overflow <= 0;
            for (j=0; j<MAX_REGIONS; j=j+1) valid[j] <= 0;
        end else if (pixel_valid && color != 0) begin
            if (first_hit != -1) begin
                for (j=0; j<MAX_REGIONS; j=j+1)
                    if (hit[j]) valid[j] <= 0;
                valid[first_hit] <= 1;
                xs[first_hit] <= mx0; xe[first_hit] <= mx1;
                ys[first_hit] <= my0; ye[first_hit] <= my1;
                counts[first_hit] <= matched_count;
            end else if (free_index != -1) begin
                valid[free_index] <= 1; colors[free_index] <= color;
                xs[free_index] <= x; xe[free_index] <= x;
                ys[free_index] <= y; ye[free_index] <= y;
                counts[free_index] <= 1;
            end else overflow <= 1;
        end
    end
endmodule
