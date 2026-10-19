`timescale 1ns / 1ps

// 有界的同色包围框增长/合并器，每拍接收一个像素。
// 它是候选粗筛，并非精确连通域标记：与同色框的外扩一像素范围相交即合并。
// 多框同时命中时合并全部命中框，合到编号最小的槽。新像素并不进任何框时取编号最小的空槽；
// 没有空槽时复用编号最小的“已封口小区域”槽（y > ye+1，已不可能再并进像素，且像素数
// < min_pixels，过不了大小筛选），原区域丢掉；再没有就只丢这个像素并置 overflow，
// 本帧照常往下做（2026-10-09 定，不再整帧作废）。
//
// 时序版（2026-10-19）：改成三级流水，每拍仍收一个像素，规则不变；区域状态（含 overflow、
// clear 的效果）整体比原版晚 2 拍，有效槽的内容与原版晚 2 拍后逐拍相同。
//   s0 输入打拍（并预算 x±1、y±1）；
//   s1 对“已提交状态 + 上一拍在途合并”判断命中、空槽、复用槽；在途合并框的外扩相交按
//      “任一成员相交”拆开算（min(...)<=c 等价于有成员 <=c），不必等 s2 的合并结果；
//   s2 合并写回：极值用两两比较选出，计数用 3:2 压缩树后只做一次进位加法。
// 使用前提（Hcamera_preprocess 的栅格扫描天然满足）：两次 clear 之间有效像素的 y 不减，
// 相邻两拍的有效像素 y 最多差 1。由此合并后的 ye 恒等于当前像素 y，在途目标框也不会被复用。
// COORD_BITS/COUNT_BITS 是坐标和计数的实际位宽，调用方保证 x、y < 2**COORD_BITS，
// 一帧像素数 < 2**COUNT_BITS；对外端口宽度不变（高位补 0）。
module Hpreprocess_regions #(
    parameter integer MAX_REGIONS = 8,
    parameter integer COORD_BITS = 16,
    parameter integer COUNT_BITS = 32
) (
    input clk, input rst_n, input clear,
    input pixel_valid, input [15:0] x, input [15:0] y, input [2:0] color,
    input [31:0] min_pixels,
    input [31:0] query_index,
    output query_valid, output [2:0] query_color,
    output [15:0] query_x0, output [15:0] query_y0,
    output [15:0] query_x1, output [15:0] query_y1,
    output [31:0] query_pixels,
    output reg overflow,
    // 全部槽位并行输出（寄存器直出），供并行筛选用
    output [MAX_REGIONS-1:0] all_valid,
    output [MAX_REGIONS*3-1:0] all_color,
    output [MAX_REGIONS*16-1:0] all_x0, output [MAX_REGIONS*16-1:0] all_y0,
    output [MAX_REGIONS*16-1:0] all_x1, output [MAX_REGIONS*16-1:0] all_y1,
    output [MAX_REGIONS*32-1:0] all_pixels
);
    localparam integer N = MAX_REGIONS;
    localparam integer CW = COORD_BITS;
    localparam integer CB = COUNT_BITS;

    // 窄位宽时坐标端口高位不用（调用方保证为 0）
    generate if (CW < 16) begin : xy_hi
        wire unused_xy_hi = &{1'b0, x[15:CW], y[15:CW]};
    end endgenerate

    // 已提交的区域状态
    reg [N-1:0] valid;
    reg [N*3-1:0] colors;
    reg [N*CW-1:0] xs, xe, ys, ye;
    reg [N*CB-1:0] counts;

    genvar g;
    generate for (g=0; g<N; g=g+1) begin : outs
        assign all_color[g*3 +: 3] = colors[g*3 +: 3];
        if (CW < 16) begin : pad_c
            assign all_x0[g*16 +: 16] = {{(16-CW){1'b0}}, xs[g*CW +: CW]};
            assign all_x1[g*16 +: 16] = {{(16-CW){1'b0}}, xe[g*CW +: CW]};
            assign all_y0[g*16 +: 16] = {{(16-CW){1'b0}}, ys[g*CW +: CW]};
            assign all_y1[g*16 +: 16] = {{(16-CW){1'b0}}, ye[g*CW +: CW]};
        end else begin : full_c
            assign all_x0[g*16 +: 16] = xs[g*CW +: CW];
            assign all_x1[g*16 +: 16] = xe[g*CW +: CW];
            assign all_y0[g*16 +: 16] = ys[g*CW +: CW];
            assign all_y1[g*16 +: 16] = ye[g*CW +: CW];
        end
        if (CB < 32) begin : pad_n
            assign all_pixels[g*32 +: 32] = {{(32-CB){1'b0}}, counts[g*CB +: CB]};
        end else begin : full_n
            assign all_pixels[g*32 +: 32] = counts[g*CB +: CB];
        end
    end endgenerate
    assign all_valid = valid;

    // 查询口：编号译码后与或选择（不按编号做乘法寻址）；编号越界全给 0
    reg qr_valid;
    reg [2:0] qr_color;
    reg [15:0] qr_x0, qr_y0, qr_x1, qr_y1;
    reg [31:0] qr_pixels;
    integer qk;
    always @* begin
        qr_valid = 1'b0; qr_color = 3'd0; qr_x0 = 16'd0; qr_y0 = 16'd0;
        qr_x1 = 16'd0; qr_y1 = 16'd0; qr_pixels = 32'd0;
        for (qk=0; qk<N; qk=qk+1)
            if (query_index == qk) begin
                qr_valid = valid[qk]; qr_color = all_color[qk*3 +: 3];
                qr_x0 = all_x0[qk*16 +: 16]; qr_y0 = all_y0[qk*16 +: 16];
                qr_x1 = all_x1[qk*16 +: 16]; qr_y1 = all_y1[qk*16 +: 16];
                qr_pixels = all_pixels[qk*32 +: 32];
            end
    end
    assign query_valid = qr_valid;
    assign query_color = qr_color;
    assign query_x0 = qr_x0; assign query_y0 = qr_y0;
    assign query_x1 = qr_x1; assign query_y1 = qr_y1;
    assign query_pixels = qr_pixels;

    // ---------------- s0：输入打拍 ----------------
    reg q_v, q_clear, q_x0, q_y0;
    reg [2:0] q_c;
    reg [CW-1:0] q_x, q_y, q_xm1, q_ym1;
    reg [CW:0] q_xp1, q_yp1;
    // min_pixels 跟像素同拍取样（原版在像素那一拍比较），截成 CB 位 + “超出计数位宽”标志
    reg q_min_hi;
    reg [CB-1:0] q_min;
    wire min_hi;
    generate if (CB < 32) begin : min_cut
        assign min_hi = |min_pixels[31:CB];
    end else begin : min_full
        assign min_hi = 1'b0;
    end endgenerate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_v <= 0; q_clear <= 0; q_x0 <= 0; q_y0 <= 0; q_c <= 0;
            q_x <= 0; q_y <= 0; q_xm1 <= 0; q_ym1 <= 0; q_xp1 <= 0; q_yp1 <= 0;
            q_min_hi <= 0; q_min <= 0;
        end else begin
            q_min_hi <= min_hi; q_min <= min_pixels[CB-1:0];
            q_clear <= clear;
            q_v <= pixel_valid && color != 0 && !clear;
            q_c <= color;
            q_x <= x[CW-1:0]; q_y <= y[CW-1:0];
            q_xp1 <= {1'b0, x[CW-1:0]} + 1'b1; q_yp1 <= {1'b0, y[CW-1:0]} + 1'b1;
            q_xm1 <= x[CW-1:0] - 1'b1; q_ym1 <= y[CW-1:0] - 1'b1;
            q_x0 <= x[CW-1:0] == 0; q_y0 <= y[CW-1:0] == 0;
        end
    end

    // ---------------- s1/s2 共用：在途合并（上一拍 s1 的结果）----------------
    reg m_v, m_clear;
    reg [2:0] m_c;
    reg [CW-1:0] m_x, m_y;
    reg [N-1:0] m_hit, m_alloc;
    reg [N-1:0] m_first, tgt;
    integer i0;
    always @* begin
        m_first = 0;
        for (i0=0; i0<N; i0=i0+1)
            if (m_hit[i0] && m_first == 0) m_first[i0] = 1'b1;
        tgt = (|m_hit) ? m_first : m_alloc;
    end

    // ---------------- s1：命中 / 空槽 / 复用判断 ----------------
    reg [N-1:0] cx0, cx1, cy0, cy1, hit_s, is_small, hit_e, ev, free, reuse;
    reg [N-1:0] free_first, reuse_first, alloc;
    reg px0, px1, py0, py1, hit_u;
    integer i;
    always @* begin
        for (i=0; i<N; i=i+1) begin
            cx0[i] = {1'b0, xs[i*CW +: CW]} <= q_xp1;
            cx1[i] = q_x0 || q_xm1 <= xe[i*CW +: CW];
            cy0[i] = {1'b0, ys[i*CW +: CW]} <= q_yp1;
            cy1[i] = q_y0 || q_ym1 <= ye[i*CW +: CW];
            hit_s[i] = valid[i] && colors[i*3 +: 3] == q_c &&
                       cx0[i] && cx1[i] && cy0[i] && cy1[i];
            is_small[i] = q_min_hi || counts[i*CB +: CB] < q_min;
        end
        px0 = {1'b0, m_x} <= q_xp1;
        px1 = q_x0 || q_xm1 <= m_x;
        py0 = {1'b0, m_y} <= q_yp1;
        py1 = q_y0 || q_ym1 <= m_y;
        // 在途目标框 = 命中框并集 + 在途像素；外扩相交拆成逐成员相交
        hit_u = m_c == q_c &&
                (px0 || |(m_hit & cx0)) && (px1 || |(m_hit & cx1)) &&
                (py0 || |(m_hit & cy0)) && (py1 || |(m_hit & cy1));
        for (i=0; i<N; i=i+1) begin
            hit_e[i] = q_v && !m_clear && (tgt[i] ? hit_u : (hit_s[i] && !m_hit[i]));
            ev[i] = !m_clear && ((valid[i] && !m_hit[i]) || tgt[i]);
            free[i] = !ev[i];
            // y > ye+1 等价于 !(y <= ye+1)；在途目标槽不会封口（见文件头前提）
            reuse[i] = ev[i] && !tgt[i] && !cy1[i] && is_small[i];
        end
        free_first = 0; reuse_first = 0;
        for (i=0; i<N; i=i+1) begin
            if (free[i] && free_first == 0) free_first[i] = 1'b1;
            if (reuse[i] && reuse_first == 0) reuse_first[i] = 1'b1;
        end
        alloc = (|free) ? free_first : reuse_first;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_v <= 0; m_clear <= 0; m_c <= 0; m_x <= 0; m_y <= 0; m_hit <= 0; m_alloc <= 0;
        end else begin
            m_v <= q_v; m_clear <= q_clear;
            m_c <= q_c; m_x <= q_x; m_y <= q_y;
            m_hit <= hit_e;
            m_alloc <= q_v ? alloc : {N{1'b0}};
        end
    end

    // ---------------- s2：合并写回 ----------------
    // 候选 0..N-1 为命中槽，N 为在途像素本身；同值时编号小的胜出（结果相同）。
    localparam integer NC = N + 1;
    wire [NC-1:0] member = {1'b1, m_hit};
    wire [NC*CW-1:0] cand_x0 = {m_x, xs};
    wire [NC*CW-1:0] cand_x1 = {m_x, xe};
    wire [NC*CW-1:0] cand_y0 = {m_y, ys};
    reg [NC*NC-1:0] le_x0, ge_x1, le_y0;
    reg [NC-1:0] win_x0, win_x1, win_y0;
    reg [CW-1:0] new_x0, new_x1, new_y0;
    integer a, b;
    always @* begin
        le_x0 = 0; ge_x1 = 0; le_y0 = 0;
        for (a=0; a<NC; a=a+1)
            for (b=a+1; b<NC; b=b+1) begin
                le_x0[a*NC+b] = cand_x0[a*CW +: CW] <= cand_x0[b*CW +: CW];
                ge_x1[a*NC+b] = cand_x1[a*CW +: CW] >= cand_x1[b*CW +: CW];
                le_y0[a*NC+b] = cand_y0[a*CW +: CW] <= cand_y0[b*CW +: CW];
            end
        for (a=0; a<NC; a=a+1) begin
            win_x0[a] = member[a]; win_x1[a] = member[a]; win_y0[a] = member[a];
            for (b=0; b<NC; b=b+1) begin
                if (b < a && member[b]) begin
                    if (le_x0[b*NC+a]) win_x0[a] = 1'b0;
                    if (ge_x1[b*NC+a]) win_x1[a] = 1'b0;
                    if (le_y0[b*NC+a]) win_y0[a] = 1'b0;
                end
                if (b > a && member[b]) begin
                    if (!le_x0[a*NC+b]) win_x0[a] = 1'b0;
                    if (!ge_x1[a*NC+b]) win_x1[a] = 1'b0;
                    if (!le_y0[a*NC+b]) win_y0[a] = 1'b0;
                end
            end
        end
        new_x0 = 0; new_x1 = 0; new_y0 = 0;
        for (a=0; a<NC; a=a+1) begin
            new_x0 = new_x0 | ({CW{win_x0[a]}} & cand_x0[a*CW +: CW]);
            new_x1 = new_x1 | ({CW{win_x1[a]}} & cand_x1[a*CW +: CW]);
            new_y0 = new_y0 | ({CW{win_y0[a]}} & cand_y0[a*CW +: CW]);
        end
    end

    // 计数：1 + 命中槽计数之和
    // 3:2 压缩：和 = a^b^c，进位 = 多数表决左移一位（最高位进位不会出现，调用方保证不溢出）
    function [2*CB-1:0] csa;
        input [CB-1:0] ca, cb, cc;
        reg [CB-2:0] maj;
        begin
            maj = (ca[CB-2:0] & cb[CB-2:0]) | (ca[CB-2:0] & cc[CB-2:0]) | (cb[CB-2:0] & cc[CB-2:0]);
            csa = {ca ^ cb ^ cc, maj, 1'b0};
        end
    endfunction
    wire [CB-1:0] new_count;
    generate if (N == 8) begin : csa8
        wire [CB-1:0] o0 = m_hit[0] ? counts[0*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o1 = m_hit[1] ? counts[1*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o2 = m_hit[2] ? counts[2*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o3 = m_hit[3] ? counts[3*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o4 = m_hit[4] ? counts[4*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o5 = m_hit[5] ? counts[5*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o6 = m_hit[6] ? counts[6*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o7 = m_hit[7] ? counts[7*CB +: CB] : {CB{1'b0}};
        wire [CB-1:0] o8 = {{(CB-1){1'b0}}, 1'b1};
        wire [CB-1:0] s0, c0, s1, c1, s2, c2, s3, c3, s4, c4, s5, c5, s6, c6;
        assign {s0, c0} = csa(o0, o1, o2);
        assign {s1, c1} = csa(o3, o4, o5);
        assign {s2, c2} = csa(o6, o7, o8);
        assign {s3, c3} = csa(s0, c0, s1);
        assign {s4, c4} = csa(c1, s2, c2);
        assign {s5, c5} = csa(s3, c3, s4);
        assign {s6, c6} = csa(s5, c5, c4);
        assign new_count = s6 + c6;
    end else begin : sum_any
        reg [CB-1:0] acc;
        integer t;
        always @* begin
            acc = 1;
            for (t=0; t<N; t=t+1) if (m_hit[t]) acc = acc + counts[t*CB +: CB];
        end
        assign new_count = acc;
    end endgenerate

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overflow <= 0; valid <= 0; colors <= 0;
            xs <= 0; xe <= 0; ys <= 0; ye <= 0; counts <= 0;
        end else if (m_clear) begin
            overflow <= 0; valid <= 0;
        end else if (m_v) begin
            for (j=0; j<N; j=j+1) begin
                if (tgt[j]) begin
                    valid[j] <= 1'b1; colors[j*3 +: 3] <= m_c;
                    xs[j*CW +: CW] <= new_x0; xe[j*CW +: CW] <= new_x1;
                    ys[j*CW +: CW] <= new_y0; ye[j*CW +: CW] <= m_y;
                    counts[j*CB +: CB] <= new_count;
                end else if (m_hit[j]) valid[j] <= 1'b0;
            end
            if (tgt == 0) overflow <= 1;
        end
    end
endmodule
