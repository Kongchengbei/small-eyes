`timescale 1ns / 1ps
`include "soc_addr_map.vh"

// 固定96x96 RGB565的单个相机通道->[R,G,B,0]INT8转换器
//两个摄像头分别例化一次，所有状态和AXI端口均在ddr_core_clk中
module Hrgb565_int8_lane #(
    parameter [0:0] CAMERA = 1'b0,
    parameter [7:0] AXI_ID = CAMERA ? 8'h61 : 8'h60,
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter integer TIMEOUT_CYCLES = 1000000
) (
    input clk, input rst_n, input enable, input clear_errors,

    input desc_valid, output wire desc_ready,
    input [7:0] desc_camera, input [31:0] desc_frame,
    input desc_rgb_bank, input [31:0] desc_rgb_base,
    input [31:0] desc_count, input [15:0] desc_width, input [15:0] desc_height,
    input [31:0] desc_rgb_stride,
    input [8*64-1:0] desc_boxes, input [8*3-1:0] desc_colors,

    output wire image_valid, input image_ready,
    output wire [7:0] image_camera, output wire [31:0] image_frame,
    output wire [7:0] image_batch_count, output wire [7:0] image_index,
    output wire [63:0] image_box, output wire [2:0] image_color,
    output wire [1:0] image_block, output wire [3:0] image_position,
    output wire [31:0] image_generation, output wire [31:0] image_data_addr,
    output wire [15:0] image_width, output wire [15:0] image_height,
    output wire [31:0] image_data_bytes,

    input release_valid, output wire release_ready,
    input [7:0] release_camera, input [31:0] release_frame,
    input [1:0] release_block, input [3:0] release_position,
    input [31:0] release_generation,

    output reg roi_release_valid, output reg roi_release_bank,
    output reg [31:0] roi_release_frame,
    output wire busy, output reg error,
    output wire wait_slot, output wire wait_ddr, output wire wait_handoff,
    output reg [31:0] images_done, output reg [31:0] batch_cycles,
    output reg [31:0] slot_wait_cycles, output reg [31:0] read_addr_wait_cycles,
    output reg [31:0] read_data_wait_cycles, output reg [31:0] write_addr_wait_cycles,
    output reg [31:0] write_data_wait_cycles, output reg [31:0] write_resp_wait_cycles,
    output reg [31:0] handoff_wait_cycles,
    output reg [31:0] used_slots, output reg [31:0] peak_slots,
    output reg [31:0] ddr_error_count, output reg [31:0] bad_release_count,
    output reg [31:0] failed_batches, output reg [31:0] last_failure_frame,
    output reg [7:0] last_failure_index, output reg [7:0] last_failure_cause,

    output wire [29:0] axi_araddr, output wire [7:0] axi_arid,
    output wire [7:0] axi_arlen, output wire [2:0] axi_arsize,
    output wire [1:0] axi_arburst, output wire axi_arvalid, input axi_arready,
    input [255:0] axi_rdata, input [7:0] axi_rid, input [1:0] axi_rresp,
    input axi_rlast, input axi_rvalid, output wire axi_rready,
    output wire [29:0] axi_awaddr, output wire [7:0] axi_awid,
    output wire [7:0] axi_awlen, output wire [2:0] axi_awsize,
    output wire [1:0] axi_awburst, output wire axi_awvalid, input axi_awready,
    output wire [255:0] axi_wdata, output wire [31:0] axi_wstrb,
    output wire axi_wlast, output wire axi_wvalid, input axi_wready,
    input [7:0] axi_bid, input [1:0] axi_bresp, input axi_bvalid, output wire axi_bready
);
    // 时序版：分槽改成三级流水（接收拍快照 -> 组内名次 -> 组基数，第2拍末提交）；
    // 空闲数/占用数改成事件计数；状态、FIFO空满、超时比较都改成寄存标志；
    // slot 号到块号/位置/地址用常数表，入队和换下一张用提前查好的寄存值；
    // 归还按 slot 并行比对；计数类加法按位写，综合成查找表。对外逐拍不变。
    localparam integer SLOT_COUNT = 56;
    localparam [31:0] RGB_BYTES = 32'd18432;
    localparam [7:0] CAM_ID = CAMERA ? 8'd2 : 8'd1;
    localparam [31:0] PB0 = CAMERA ? `SOC_PRE2_BANK0_BASE : `SOC_PRE1_BANK0_BASE;
    localparam [31:0] PB1 = CAMERA ? `SOC_PRE2_BANK1_BASE : `SOC_PRE1_BANK1_BASE;
    localparam [31:0] STRIDE = `SOC_PRE_ROI_STRIDE_BYTES;
    localparam [31:0] LO_MAX = STRIDE - RGB_BYTES;  // 落在bank最后一个32K里时，块内偏移上限
    localparam [63:0] DDR_LIMIT = {32'b0,DDR_BASE} + {32'b0,DDR_BYTES};
    localparam [29:0] ADDR_RST = 30'd0 - DDR_BASE[29:0];

    // 几何检查化简的前提：bank按1MB对齐且落在DDR内、行距32K（块内偏移上限因此是0x3800）、超时>=1
    localparam CFG_OK = (`SOC_PRE_BANK_BYTES == 32'h0010_0000) && (STRIDE == 32'd32768) &&
        (LO_MAX == 32'h0000_3800) &&
        (PB0[19:0] == 20'd0) && (PB1[19:0] == 20'd0) &&
        (PB0 >= DDR_BASE) && ({32'b0,PB0} + 64'h0010_0000 <= DDR_LIMIT) &&
        (PB1 >= DDR_BASE) && ({32'b0,PB1} + 64'h0010_0000 <= DDR_LIMIT) &&
        (TIMEOUT_CYCLES >= 1);
    generate if (!CFG_OK) begin : g_cfg_check
        Hrgb565_int8_lane_bad_config u_bad_config();
    end endgenerate

    function [31:0] sat_inc;
        input [31:0] value;
        begin sat_inc = (&value) ? value : value + 1'b1; end
    endfunction

    function [31:0] rgb565_to_int8x4;
        input [15:0] px;
        reg [4:0] r5, b5;
        reg [5:0] g6;
        reg [7:0] r8, g8, b8;
        reg [7:0] rq, gq, bq;
        begin
            r5=px[15:11]; g6=px[10:5]; b5=px[4:0];
            r8={r5,r5[4:2]}; g8={g6,g6[5:4]}; b8={b5,b5[4:2]};
            rq={~r8[7],r8[6:0]}; gq={~g8[7],g8[6:0]}; bq={~b8[7],b8[6:0]};  // 减128即翻最高位
            rgb565_to_int8x4={8'h00,bq,gq,rq};
        end
    endfunction

    // 下面几个小加法都按位写成与或异或，综合成查找表，不走进位链
    function [2:0] pop4;  // 4 位里 1 的个数
        input [3:0] v;
        reg x0, x1;
        begin
            x0 = v[0] ^ v[1]; x1 = v[2] ^ v[3];
            pop4 = {&v, (v[0] & v[1]) ^ (v[2] & v[3]) ^ (x0 & x1), x0 ^ x1};
        end
    endfunction

    function [2:0] pop5;  // 5 位里 1 的个数
        input [4:0] v;
        reg [2:0] p;
        begin
            p = pop4(v[3:0]);
            pop5 = {p[2] | (p[1] & p[0] & v[4]), p[1] ^ (p[0] & v[4]), p[0] ^ v[4]};
        end
    endfunction

    function [3:0] add33;  // a + b，每位只看 6 个输入
        input [2:0] a, b;
        reg c0, c1;
        begin
            c0 = a[0] & b[0];
            c1 = (a[1] & b[1]) | (c0 & (a[1] ^ b[1]));
            add33 = {(a[2] & b[2]) | (c1 & (a[2] ^ b[2])), a[2] ^ b[2] ^ c1,
                a[1] ^ b[1] ^ c0, a[0] ^ b[0]};
        end
    endfunction

    // 两级查找表：先 4 位/5 位各数一遍，再相加
    function [3:0] pop8c;  // 8 位里 1 的个数 + ci（结果<=9）
        input [7:0] v;
        input ci;
        begin pop8c = add33(pop4(v[3:0]), pop5({ci, v[7:4]})); end
    endfunction

    function [3:0] pop8;
        input [7:0] v;
        begin pop8 = add33(pop4(v[3:0]), pop4(v[7:4])); end
    endfunction

    function [4:0] add44;  // a + b
        input [3:0] a, b;
        reg [3:0] c;
        integer n;
        begin
            add44[0] = a[0] ^ b[0]; c[0] = a[0] & b[0];
            for (n=1;n<4;n=n+1) begin
                add44[n] = a[n] ^ b[n] ^ c[n-1];
                c[n] = (a[n] & b[n]) | (c[n-1] & (a[n] ^ b[n]));
            end
            add44[4] = c[3];
        end
    endfunction

    function [5:0] add66;  // (a + b) 取低 6 位
        input [5:0] a, b;
        reg c;
        integer n;
        begin
            c = 1'b0;
            for (n=0;n<6;n=n+1) begin
                add66[n] = a[n] ^ b[n] ^ c;
                c = (a[n] & b[n]) | (c & (a[n] ^ b[n]));
            end
        end
    endfunction

    function ge6;  // v >= kk，kk 为常数 1..8
        input [5:0] v;
        input integer kk;
        begin
            case (kk)
                1: ge6 = |v;
                2: ge6 = |v[5:1];
                3: ge6 = |v[5:2] | (v[1] & v[0]);
                4: ge6 = |v[5:2];
                5: ge6 = |v[5:3] | (v[2] & (v[1] | v[0]));
                6: ge6 = |v[5:3] | (v[2] & v[1]);
                7: ge6 = |v[5:3] | (&v[2:0]);
                default: ge6 = |v[5:3];
            endcase
        end
    endfunction

    function [3:0] sat8;  // min(8, a+b)，a、b<=8
        input [3:0] a, b;
        reg [4:0] s;
        begin s = add44(a, b); sat8 = (s[4] | s[3]) ? 4'd8 : s[3:0]; end
    endfunction

    // 状态独热
    reg st_idle, st_ar, st_r, st_aw, st_w0, st_w1, st_b, st_clean, st_drain;
    // slot 标志：res 预约、q 排队、del 已交付、gm 代号已到ffffffff（不再分配）
    reg [SLOT_COUNT-1:0] slot_res, slot_q, slot_del, slot_gm;
    reg [31:0] slot_generation [0:SLOT_COUNT-1];
    reg [31:0] slot_frame [0:SLOT_COUNT-1];

    // batch 寄存器在 IDLE 时一直跟着描述符走，接收那拍的值留到整批结束
    reg [31:0] batch_frame_reg;
    reg batch_bank_reg;
    reg [3:0] batch_count_reg;
    reg [7:0] count_gt;  // count_gt[k] = 张数 > k
    reg [5:0] count_neg6, count_neg6_p1;  // -张数、1-张数（6 位补码）
    reg [511:0] batch_boxes_reg;
    reg [23:0] batch_colors_reg;
    reg [29:0] read_img_base, read_addr_reg, write_addr_reg;
    reg [2:0] image_index_reg;
    reg [9:0] input_beat;
    reg beat_last, image_last;
    reg [255:0] read_word;
    reg [511:0] converted_word;
    reg [31:0] image_cycles, batch_timer;
    reg timeout_flag, batch_failed;
    reg [5:0] batch_slot_index [0:7];
    reg [7:0] batch_reserved, batch_live;  // 本批还没推进FIFO的位置 / 其中代号没用尽、清理时退回空闲的
    reg [5:0] cur_slot;
    // cur_slot 只在分槽提交拍和 b_next 拍变，离下一次入队/换张至少隔一整张图，
    // 所以入队要的块号/位置/地址/代号、换张要的下一个 slot 和写地址都每拍查好打一拍
    reg [1:0] cur_blk_r;
    reg [3:0] cur_pos_r;
    reg [31:0] cur_addr_r, cur_gen_r;
    reg [5:0] next_slot_r;
    reg [29:0] next_wbase_r;

    reg [2:0] fifo_wr_ptr, fifo_rd_ptr;
    reg [8:0] fifo_level;  // 独热：fifo_level[n] 表示里面有 n 张
    reg [7:0] fifo_index [0:7];
    reg [5:0] fifo_slot [0:7];
    reg [1:0] fifo_block [0:7];
    reg [3:0] fifo_position [0:7];
    reg [31:0] fifo_generation [0:7];
    reg [31:0] fifo_address [0:7];
    reg [63:0] fifo_box [0:7];
    reg [2:0] fifo_color [0:7];
    reg [31:0] fifo_frame [0:7];
    reg [7:0] fifo_batch_count [0:7];
    wire fifo_empty = fifo_level[0];
    wire fifo_full = fifo_level[8];

    // 空闲数 = free_base + rel_free_r（上一拍释放的那个晚一拍记账）；free_ge[c] = free_base>=c
    reg [5:0] free_base;
    reg [8:0] free_ge;
    reg rel_hit_r, rel_free_r;
    // 占用数 = used_base - rel_hit_r + 上一拍接收的张数
    reg [6:0] used_base;
    reg alloc_p1, alloc_p2;
    integer i, j, k, g, m, fj;
    genvar gj, gg, gt;

    // ---- 常数表：slot 号 -> 块号、块内位置、INT8 地址、AXI 写地址（56..63 按原公式补齐）----
    wire [64*2-1:0] tab_blk;
    wire [64*4-1:0] tab_pos;
    wire [64*32-1:0] tab_addr;
    wire [64*30-1:0] tab_wbase;
    wire [SLOT_COUNT-1:0] rel_match;
    generate for (gj=0; gj<64; gj=gj+1) begin : g_tab
        localparam [31:0] TB = gj / 14;
        localparam [31:0] TP = gj % 14;
        localparam [31:0] TBASE = !CAMERA ?
            (TB == 0 ? `SOC_INT8_CAM1_BLOCK0_BASE : TB == 1 ? `SOC_INT8_CAM1_BLOCK1_BASE :
             TB == 2 ? `SOC_INT8_CAM1_BLOCK2_BASE : `SOC_INT8_CAM1_BLOCK3_BASE) :
            (TB == 0 ? `SOC_INT8_CAM2_BLOCK0_BASE : TB == 1 ? `SOC_INT8_CAM2_BLOCK1_BASE :
             TB == 2 ? `SOC_INT8_CAM2_BLOCK2_BASE : `SOC_INT8_CAM2_BLOCK3_BASE);
        localparam [31:0] TADDR = TBASE + TP * `SOC_INT8_SLOT_BYTES;
        assign tab_blk[gj*2 +: 2] = TB[1:0];
        assign tab_pos[gj*4 +: 4] = TP[3:0];
        assign tab_addr[gj*32 +: 32] = TADDR;
        assign tab_wbase[gj*30 +: 30] = TADDR[29:0] - DDR_BASE[29:0];
        // 释放：每个 slot 自己比块号、位置、代号、帧号，至多一个命中
        if (gj < SLOT_COUNT) begin : g_rel
            assign rel_match[gj] = slot_del[gj] && release_block == TB[1:0] &&
                release_position == TP[3:0] && slot_generation[gj] == release_generation &&
                slot_frame[gj] == release_frame;
        end
    end endgenerate

    // ---- 描述符检查：bank窗口在DDR内，所以只查bank窗口；末端用 H+张数 判断 ----
    wire desc_cam_ok = desc_camera == CAM_ID;
    wire desc_size_ok = desc_width == 16'd96 && desc_height == 16'd96;
    wire desc_count_hi0 = desc_count[31:4] == 28'd0;
    wire desc_count_zero = desc_count_hi0 && desc_count[3:0] == 4'd0;
    wire desc_count_in = desc_count_hi0 &&  // 1..8
        (desc_count[3] ? desc_count[2:0] == 3'd0 : desc_count[2:0] != 3'd0);
    wire [11:0] desc_bank_hi = desc_rgb_bank ? PB1[31:20] : PB0[31:20];
    wire desc_place_ok = desc_cam_ok && desc_size_ok && desc_rgb_stride == STRIDE &&
        desc_rgb_base[4:0] == 5'd0 && desc_rgb_base[31:20] == desc_bank_hi;
    // 末张结束 = base + (n-1)*32K + 18432 <= bank末：H=base[19:15]，H+n<=31 一定放得下，
    // H+n==32 时要求块内偏移 <= 32K-18432。n 按 count[2:0] 取（0 表示 8），两张 8 输入常数表
    wire [255:0] tail_le_tab, tail_eq_tab;
    generate for (gt=0; gt<256; gt=gt+1) begin : g_tail
        localparam integer TH = gt % 32;
        localparam integer TN = (gt / 32 == 0) ? 8 : gt / 32;
        assign tail_le_tab[gt] = TH + TN <= 31;
        assign tail_eq_tab[gt] = TH + TN == 32;
    end endgenerate
    wire [7:0] desc_tail_key = {desc_count[2:0], desc_rgb_base[19:15]};
    // 块内偏移 <= 0x3800：base[14]=0，且 base[13:11]!=7 或 base[10:0]==0（与或式，不走进位链）
    wire desc_lo_ok = !desc_rgb_base[14] &&
        (!(&desc_rgb_base[13:11]) || desc_rgb_base[10:0] == 11'd0);
    wire desc_tail_ok = tail_le_tab[desc_tail_key] || (tail_eq_tab[desc_tail_key] && desc_lo_ok);
    wire desc_fit = desc_count_in && desc_place_ok && desc_tail_ok;  // 1..8张且几何合法
    // desc_fit 已排除 0 张，原来按 0 张二选一等价于或
    wire desc_geometry_ok = (desc_count_zero && desc_cam_ok && desc_size_ok) || desc_fit;
    // 空闲够不够 = free_ge[n - rel_free_r]，按 count[2:0] 直接选
    wire [7:0] free_ok_vec = rel_free_r ? {free_ge[6:0], free_ge[7]} : {free_ge[7:1], free_ge[8]};
    wire desc_free_ok = free_ok_vec[desc_count[2:0]];
    wire desc_short = desc_fit && !desc_free_ok;
    wire ready_idle = rst_n && enable && st_idle && fifo_empty;
    wire desc_take = desc_valid && ready_idle;
    wire accept_batch = desc_take && desc_fit && desc_free_ok;
    wire accept_bad = desc_take && !desc_geometry_ok;
    wire accept_release = desc_take && (desc_count_zero || !desc_fit);  // 坏描述符或0张

    assign desc_ready = ready_idle && !desc_short;
    assign wait_slot = enable && desc_valid && st_idle && desc_short;

    // ---- 分槽流水 ----
    // 第0级：接收拍的空闲快照、7组x8的组内名次和组内空闲数
    wire [SLOT_COUNT-1:0] slot_free = ~(slot_res | slot_q | slot_del | slot_gm);
    reg [SLOT_COUNT-1:0] free_s0, free_s1;
    reg [3*SLOT_COUNT-1:0] rank_c, rank_s0, rank_s1;
    reg [4*7-1:0] group_cnt_c, group_cnt_s0, group_base_s1;
    reg [3:0] rank_v;
    always @* begin
        rank_c = 0; group_cnt_c = 0;
        for (g=0; g<7; g=g+1) begin
            for (m=0; m<8; m=m+1) begin
                rank_v = pop8(slot_free[g*8 +: 8] & ((8'd1 << m) - 8'd1));
                rank_c[(g*8+m)*3 +: 3] = rank_v[2:0];
            end
            group_cnt_c[g*4 +: 4] = pop8(slot_free[g*8 +: 8]);
        end
    end
    // 第1级：组基数 = 前面各组空闲数之和（到8饱和）
    wire [3:0] gc0 = group_cnt_s0[0 +: 4], gc1 = group_cnt_s0[4 +: 4];
    wire [3:0] gc2 = group_cnt_s0[8 +: 4], gc3 = group_cnt_s0[12 +: 4];
    wire [3:0] gc4 = group_cnt_s0[16 +: 4], gc5 = group_cnt_s0[20 +: 4];
    wire [3:0] gs01 = sat8(gc0, gc1), gs23 = sat8(gc2, gc3), gs45 = sat8(gc4, gc5);
    wire [3:0] gs03 = sat8(gs01, gs23);
    wire [4*7-1:0] group_base_c = {sat8(gs03, gs45), sat8(gs03, gc4), gs03,
        sat8(gs01, gc2), gs01, gc0, 4'd0};
    // 第1级顺带找名次0（第一个空闲 slot）：组内前面没有空闲、前面各组也都没有
    wire [6:0] grp_none;
    assign grp_none[0] = 1'b1;
    generate for (gg=1; gg<7; gg=gg+1) begin : g_none
        assign grp_none[gg] = grp_none[gg-1] && group_cnt_s0[(gg-1)*4 +: 4] == 4'd0;
    end endgenerate
    reg [5:0] first_idx_c, first_cand, first_idx_s1;
    always @* begin
        first_idx_c = 6'd0;
        for (fj=0; fj<SLOT_COUNT; fj=fj+1) begin
            first_cand = fj;
            first_idx_c = first_idx_c |
                ({6{free_s0[fj] && rank_s0[fj*3 +: 3] == 3'd0 && grp_none[fj/8]}} & first_cand);
        end
    end
    // 第2级：全局名次 < 张数 的空闲 slot 被选中；名次 k 的那个记进第 k 张
    wire [SLOT_COUNT-1:0] slot_gen_last;  // 代号 fffffffe，这次预约后用尽；跟空闲快照同拍打两级
    reg [SLOT_COUNT-1:0] spent_s0, spent_s1;
    generate for (gj=0; gj<SLOT_COUNT; gj=gj+1) begin : g_gen_last
        assign slot_gen_last[gj] = slot_generation[gj] == 32'hffff_fffe;
    end endgenerate
    wire [15:0] count_gt16 = {8'd0, count_gt};
    reg [SLOT_COUNT-1:0] pick_take;
    reg [6*8-1:0] pick_index;
    reg [7:0] pick_spent;
    reg [4:0] pick_rank;
    reg [5:0] pick_slot;
    always @* begin
        pick_take = 0; pick_index = 0; pick_spent = 0;
        for (j=0; j<SLOT_COUNT; j=j+1) begin
            pick_rank = add44(group_base_s1[(j/8)*4 +: 4], {1'b0, rank_s1[j*3 +: 3]});
            pick_slot = j;
            pick_take[j] = free_s1[j] && count_gt16[pick_rank[3:0]];
            for (k=0; k<8; k=k+1) begin
                pick_index[k*6 +: 6] = pick_index[k*6 +: 6] |
                    ({6{free_s1[j] && pick_rank == k}} & pick_slot);
                pick_spent[k] = pick_spent[k] | (free_s1[j] && pick_rank == k && spent_s1[j]);
            end
        end
    end
    wire [7:0] pick_mask = count_gt;

    // ---- 释放 ----
    wire release_ok = release_valid && release_camera == CAM_ID;
    wire rel_hit = release_ok && |rel_match;
    wire rel_free = release_ok && |(rel_match & ~slot_gm);
    wire [SLOT_COUNT-1:0] rel_clear = {SLOT_COUNT{release_ok}} & rel_match;

    // ---- 计数：空闲/占用都按事件记账，提交晚两拍的差只出现在非 IDLE ----
    // alloc_p1 和 st_clean 不会同拍（接收后第1拍还在 AR），连同释放的 1 合成一个加数
    wire [3:0] clean_free_r1 = pop8c(batch_live, rel_free_r);
    wire [3:0] clean_all = pop8(batch_reserved);
    wire [5:0] free_add = alloc_p1 ? (rel_free_r ? count_neg6_p1 : count_neg6) :
        st_clean ? {2'b0, clean_free_r1} : {5'b0, rel_free_r};
    // 加法和后面的 free_ge 比较都按位写：不走进位链，整锥一起映射成查找表
    wire [5:0] free_next = add66(free_base, free_add);
    wire [6:0] used_now = used_base - {6'b0,rel_hit_r} + (alloc_p1 ? {3'b0,batch_count_reg} : 7'd0);

    // ---- 握手和事件 ----
    wire timeout_hit = !st_idle && timeout_flag;
    wire r_hs = st_r && axi_rvalid;
    wire r_bad = axi_rid != AXI_ID || axi_rresp != 2'b00 || !axi_rlast;
    wire r_err = r_hs && r_bad;
    // 原写法 bready 还要 !(beat_last && fifo_full)：接收要求 FIFO 空、一批最多 8 张，
    // 第 8 张入队前 FIFO 至多 7 张，这一项恒为真
    wire b_hs = st_b && axi_bvalid;
    wire b_bad = axi_bid != AXI_ID || axi_bresp != 2'b00;
    wire b_err = b_hs && b_bad;
    wire b_ok = b_hs && !b_bad && !batch_failed && !timeout_hit;
    wire b_beat = b_ok && !beat_last;
    wire b_next = b_ok && beat_last && !image_last;
    wire b_done = b_ok && beat_last && image_last;
    wire push_image = b_hs && !b_bad && beat_last;
    wire pop_image = image_ready && !fifo_empty;
    wire [2:0] index_next = image_index_reg + 3'd1;
    wire [5:0] head_slot = fifo_slot[fifo_rd_ptr];
    wire [SLOT_COUNT-1:0] push_hit, pop_hit;
    generate for (gj=0; gj<SLOT_COUNT; gj=gj+1) begin : g_hit
        assign push_hit[gj] = push_image && cur_slot == gj;
        assign pop_hit[gj] = pop_image && head_slot == gj;
    end endgenerate

    assign release_ready = rst_n;
    assign busy = !st_idle || !fifo_empty;
    assign wait_ddr = (st_ar && !axi_arready) || (st_r && !axi_rvalid) ||
        (st_aw && !axi_awready) || ((st_w0 || st_w1) && !axi_wready) ||
        (st_b && !axi_bvalid);
    assign wait_handoff = image_valid && !image_ready;
    assign image_valid = !fifo_empty;
    assign image_camera = CAM_ID;
    assign image_frame = fifo_frame[fifo_rd_ptr];
    assign image_batch_count = fifo_batch_count[fifo_rd_ptr];
    assign image_index = fifo_index[fifo_rd_ptr];
    assign image_box = fifo_box[fifo_rd_ptr];
    assign image_color = fifo_color[fifo_rd_ptr];
    assign image_block = fifo_block[fifo_rd_ptr];
    assign image_position = fifo_position[fifo_rd_ptr];
    assign image_generation = fifo_generation[fifo_rd_ptr];
    assign image_data_addr = fifo_address[fifo_rd_ptr];
    assign image_width = 16'd96;
    assign image_height = 16'd96;
    assign image_data_bytes = `SOC_INT8_IMAGE_BYTES;

    // 读地址逐拍和原写法一致；写地址只在 AW 拍有效
    assign axi_araddr = read_addr_reg;
    assign axi_arid = AXI_ID;
    assign axi_arlen = 8'd0;
    assign axi_arsize = 3'd5;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = st_ar;
    assign axi_rready = st_r || st_drain;
    assign axi_awaddr = write_addr_reg;
    assign axi_awid = AXI_ID;
    assign axi_awlen = 8'd1;
    assign axi_awsize = 3'd5;
    assign axi_awburst = 2'b01;
    assign axi_awvalid = st_aw;
    assign axi_wdata = st_w0 ? converted_word[255:0] : converted_word[511:256];
    assign axi_wstrb = 32'hffff_ffff;
    assign axi_wlast = st_w1;
    assign axi_wvalid = st_w0 || st_w1;
    assign axi_bready = st_b;

    always @* begin
        for (i=0;i<16;i=i+1)
            converted_word[i*32 +: 32]=rgb565_to_int8x4(read_word[i*16 +: 16]);
    end

    integer sj, fk;

    // ---- 状态机和分槽流水 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st_idle<=1'b1; st_ar<=1'b0; st_r<=1'b0; st_aw<=1'b0; st_w0<=1'b0;
            st_w1<=1'b0; st_b<=1'b0; st_clean<=1'b0; st_drain<=1'b0;
            alloc_p1<=1'b0; alloc_p2<=1'b0;
            free_s0<=0; free_s1<=0; rank_s0<=0; rank_s1<=0;
            group_cnt_s0<=0; group_base_s1<=0; spent_s0<=0; spent_s1<=0; first_idx_s1<=0;
        end else begin
            st_idle <= (st_idle && !accept_batch) || st_clean || b_done;
            st_ar <= accept_batch || (st_ar && !axi_arready) || b_beat || b_next;
            st_r <= (st_ar && axi_arready) || (st_r && !axi_rvalid);
            st_aw <= (r_hs && !r_bad) || (st_aw && !axi_awready);
            st_w0 <= (st_aw && axi_awready) || (st_w0 && !axi_wready);
            st_w1 <= (st_w0 && axi_wready) || (st_w1 && !axi_wready);
            st_b <= (st_w1 && axi_wready) || (st_b && !b_hs);
            st_clean <= (r_err && axi_rlast) || (st_drain && axi_rvalid && axi_rlast) ||
                (b_hs && !b_ok);
            st_drain <= (r_err && !axi_rlast) || (st_drain && !(axi_rvalid && axi_rlast));
            alloc_p1 <= accept_batch; alloc_p2 <= alloc_p1;
            free_s0 <= slot_free; rank_s0 <= rank_c; group_cnt_s0 <= group_cnt_c;
            spent_s0 <= slot_gen_last;
            free_s1 <= free_s0; rank_s1 <= rank_s0; group_base_s1 <= group_base_c;
            spent_s1 <= spent_s0; first_idx_s1 <= first_idx_c;
        end
    end

    // ---- slot 标志和代号：预约在接收后第2拍末提交 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            slot_res<=0; slot_q<=0; slot_del<=0; slot_gm<=0;
            for (sj=0;sj<SLOT_COUNT;sj=sj+1) begin slot_generation[sj]<=0; slot_frame[sj]<=0; end
        end else begin
            slot_res <= (slot_res & ~push_hit & {SLOT_COUNT{!st_clean}}) |
                ({SLOT_COUNT{alloc_p2}} & pick_take);
            slot_q <= (slot_q & ~pop_hit) | push_hit;
            slot_del <= (slot_del & ~rel_clear) | pop_hit;
            if (alloc_p2) slot_gm <= slot_gm | (pick_take & spent_s1);
            for (sj=0;sj<SLOT_COUNT;sj=sj+1)
                if (alloc_p2 && pick_take[sj]) begin
                    slot_generation[sj] <= slot_generation[sj] + 1'b1;
                    slot_frame[sj] <= batch_frame_reg;
                end
        end
    end

    // ---- 批次寄存器、地址、拍数、超时 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            batch_frame_reg<=0; batch_bank_reg<=0; batch_count_reg<=0;
            count_gt<=0; count_neg6<=0; count_neg6_p1<=6'd1;
            batch_boxes_reg<=0; batch_colors_reg<=0;
            read_img_base<=0; read_addr_reg<=ADDR_RST; write_addr_reg<=ADDR_RST;
            image_index_reg<=0; input_beat<=0; beat_last<=0; image_last<=0;
            read_word<=0; image_cycles<=0; batch_timer<=0; timeout_flag<=0; batch_failed<=0;
            for (sj=0;sj<8;sj=sj+1) batch_slot_index[sj]<=0;
            batch_reserved<=0; batch_live<=0; cur_slot<=0;
            cur_blk_r<=0; cur_pos_r<=0; cur_addr_r<=0; cur_gen_r<=0;
            next_slot_r<=0; next_wbase_r<=0;
        end else begin
            if (accept_batch) read_addr_reg <= desc_rgb_base[29:0] - DDR_BASE[29:0];
            else if (b_beat) read_addr_reg <= read_addr_reg + 30'd32;
            else if (b_next) read_addr_reg <= read_img_base + STRIDE[29:0];
            if (r_hs) read_word <= axi_rdata;

            if (st_idle) begin
                batch_frame_reg<=desc_frame; batch_bank_reg<=desc_rgb_bank;
                batch_count_reg<=desc_count[3:0];
                for (sj=0;sj<8;sj=sj+1) count_gt[sj] <= desc_count[3:0] > sj;
                count_neg6 <= 6'd0 - {2'b0, desc_count[3:0]};
                count_neg6_p1 <= 6'd1 - {2'b0, desc_count[3:0]};
                batch_boxes_reg<=desc_boxes; batch_colors_reg<=desc_colors;
                read_img_base<=desc_rgb_base[29:0] - DDR_BASE[29:0];
                image_index_reg<=0; input_beat<=0; beat_last<=0;
                image_last<=desc_count[3:0] == 4'd1;
                image_cycles<=0; batch_timer<=0; timeout_flag<=0; batch_failed<=0;
            end else begin
                image_cycles <= b_next ? 32'd0 : sat_inc(image_cycles);
                timeout_flag <= !b_next && image_cycles == TIMEOUT_CYCLES - 1;
                batch_timer <= sat_inc(batch_timer);
                if (timeout_hit || r_err || b_err) batch_failed <= 1'b1;
                if (b_beat) begin
                    input_beat <= input_beat + 1'b1;
                    beat_last <= input_beat == 10'd574;
                end
                if (b_next) begin
                    image_index_reg <= index_next; input_beat <= 0; beat_last <= 0;
                    image_last <= {1'b0,image_index_reg} + 4'd2 == batch_count_reg;
                    read_img_base <= read_img_base + STRIDE[29:0];
                end
            end

            if (alloc_p2) begin
                for (sj=0;sj<8;sj=sj+1) batch_slot_index[sj] <= pick_index[sj*6 +: 6];
                batch_reserved <= pick_mask; batch_live <= pick_mask & ~pick_spent;
                cur_slot <= first_idx_s1;
                write_addr_reg <= tab_wbase[first_idx_s1*30 +: 30];
            end else begin
                if (st_clean) begin
                    batch_reserved <= 8'd0; batch_live <= 8'd0;
                end else if (push_image) begin
                    batch_reserved[image_index_reg] <= 1'b0; batch_live[image_index_reg] <= 1'b0;
                end
                if (b_next) begin
                    cur_slot <= next_slot_r;
                    write_addr_reg <= next_wbase_r;
                end else if (b_beat) write_addr_reg <= write_addr_reg + 30'd64;
            end
            cur_blk_r <= tab_blk[cur_slot*2 +: 2];
            cur_pos_r <= tab_pos[cur_slot*4 +: 4];
            cur_addr_r <= tab_addr[cur_slot*32 +: 32];
            cur_gen_r <= slot_generation[cur_slot];
            next_slot_r <= batch_slot_index[index_next];
            next_wbase_r <= tab_wbase[next_slot_r*30 +: 30];
        end
    end

    // ---- 交图 FIFO ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wr_ptr<=0; fifo_rd_ptr<=0; fifo_level<=9'd1;
            for (fk=0;fk<8;fk=fk+1) begin
                fifo_index[fk]<=0; fifo_slot[fk]<=0; fifo_block[fk]<=0; fifo_position[fk]<=0;
                fifo_generation[fk]<=0; fifo_address[fk]<=0; fifo_box[fk]<=0;
                fifo_color[fk]<=0; fifo_frame[fk]<=0; fifo_batch_count[fk]<=0;
            end
        end else begin
            if (push_image && !pop_image) fifo_level <= {fifo_level[7:0], 1'b0};
            else if (pop_image && !push_image) fifo_level <= {1'b0, fifo_level[8:1]};
            if (push_image) begin
                fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                fifo_index[fifo_wr_ptr] <= {5'b0, image_index_reg};
                fifo_slot[fifo_wr_ptr] <= cur_slot;
                fifo_block[fifo_wr_ptr] <= cur_blk_r;
                fifo_position[fifo_wr_ptr] <= cur_pos_r;
                fifo_generation[fifo_wr_ptr] <= cur_gen_r;
                fifo_address[fifo_wr_ptr] <= cur_addr_r;
                fifo_box[fifo_wr_ptr] <= batch_boxes_reg[image_index_reg*64 +: 64];
                fifo_color[fifo_wr_ptr] <= batch_colors_reg[image_index_reg*3 +: 3];
                fifo_frame[fifo_wr_ptr] <= batch_frame_reg;
                fifo_batch_count[fifo_wr_ptr] <= {4'b0, batch_count_reg};
            end
            if (pop_image) fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
        end
    end

    // ---- 计数、错误、归还 ROI ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            roi_release_valid<=0; roi_release_bank<=0; roi_release_frame<=0;
            error<=0; images_done<=0; batch_cycles<=0; slot_wait_cycles<=0;
            read_addr_wait_cycles<=0; read_data_wait_cycles<=0;
            write_addr_wait_cycles<=0; write_data_wait_cycles<=0;
            write_resp_wait_cycles<=0; handoff_wait_cycles<=0;
            used_slots<=0; peak_slots<=0; ddr_error_count<=0; bad_release_count<=0;
            failed_batches<=0; last_failure_frame<=0; last_failure_index<=0;
            last_failure_cause<=0;
            rel_hit_r<=1'b0; rel_free_r<=1'b0;
            free_base<=SLOT_COUNT; free_ge<=9'h1ff; used_base<=0;
        end else begin
            rel_hit_r <= rel_hit; rel_free_r <= rel_free;
            free_base <= free_next;
            free_ge[0] <= 1'b1;
            for (fk=1;fk<9;fk=fk+1) free_ge[fk] <= ge6(free_next, fk);
            used_base <= used_now - (st_clean ? {3'b0,clean_all} : 7'd0);
            used_slots <= {25'b0, used_now};
            if (used_now > peak_slots[6:0]) peak_slots <= {25'b0, used_now};

            roi_release_valid <= accept_release || b_done || st_clean;
            if (accept_release) begin
                roi_release_bank <= desc_rgb_bank; roi_release_frame <= desc_frame;
            end else if (b_done || st_clean) begin
                roi_release_bank <= batch_bank_reg; roi_release_frame <= batch_frame_reg;
            end

            if (accept_bad || timeout_hit || r_err || b_err) error <= 1'b1;
            else if (clear_errors) error <= 1'b0;
            if (accept_bad) begin
                last_failure_frame <= desc_frame; last_failure_index <= 8'hff;
                last_failure_cause <= 8'd1;
            end else if (timeout_hit || r_err || b_err) begin
                last_failure_frame <= batch_frame_reg;
                last_failure_index <= {5'b0, image_index_reg};
                last_failure_cause <= r_err ? 8'd2 : b_err ? 8'd3 : 8'd4;
            end

            if (push_image) images_done <= sat_inc(images_done);
            if (b_done) batch_cycles <= batch_timer;
            if (accept_bad || st_clean) failed_batches <= sat_inc(failed_batches);
            if (r_err || b_err) ddr_error_count <= sat_inc(ddr_error_count);
            if (release_valid && !rel_hit) bad_release_count <= sat_inc(bad_release_count);
            if (st_ar && !axi_arready) read_addr_wait_cycles <= sat_inc(read_addr_wait_cycles);
            if (st_r && !axi_rvalid) read_data_wait_cycles <= sat_inc(read_data_wait_cycles);
            if (st_aw && !axi_awready) write_addr_wait_cycles <= sat_inc(write_addr_wait_cycles);
            if ((st_w0 || st_w1) && !axi_wready)
                write_data_wait_cycles <= sat_inc(write_data_wait_cycles);
            if (st_b && !b_hs) write_resp_wait_cycles <= sat_inc(write_resp_wait_cycles);
            if (image_valid && !image_ready) handoff_wait_cycles <= sat_inc(handoff_wait_cycles);
            if (wait_slot) slot_wait_cycles <= sat_inc(slot_wait_cycles);
        end
    end

`ifdef LANE_TB_HOOKS
    // 仿真专用：预置代号后调 tb_resync 按寄存器重算空闲计数（只能在分槽流水空着时调）
    task tb_set_generation(input integer s, input [31:0] v);
        begin slot_generation[s] = v; slot_gm[s] = (v == 32'hffff_ffff); end
    endtask

    task tb_resync;
        integer n, q;
        begin
            if (alloc_p1 || alloc_p2) $display("LANE_ASSERT_FAIL t=%0t tb_resync 在分槽流水中调用", $time);
            n = 0;
            for (q=0;q<SLOT_COUNT;q=q+1)
                if (!(slot_res[q] || slot_q[q] || slot_del[q] || slot_gm[q])) n = n + 1;
            free_base = n - rel_free_r;
            for (q=0;q<9;q=q+1) free_ge[q] = (n - rel_free_r) >= q;
            for (q=0;q<8;q=q+1) batch_live[q] = batch_reserved[q] && !slot_gm[batch_slot_index[q]];
        end
    endtask

    // 原写法的块基址（只在仿真里核对常数表）
    function [31:0] tb_block_base;
        input [5:0] slot;
        reg [31:0] base;
        begin
            if (!CAMERA) begin
                case (slot / 14)
                    0: base=`SOC_INT8_CAM1_BLOCK0_BASE;
                    1: base=`SOC_INT8_CAM1_BLOCK1_BASE;
                    2: base=`SOC_INT8_CAM1_BLOCK2_BASE;
                    default: base=`SOC_INT8_CAM1_BLOCK3_BASE;
                endcase
            end else begin
                case (slot / 14)
                    0: base=`SOC_INT8_CAM2_BLOCK0_BASE;
                    1: base=`SOC_INT8_CAM2_BLOCK1_BASE;
                    2: base=`SOC_INT8_CAM2_BLOCK2_BASE;
                    default: base=`SOC_INT8_CAM2_BLOCK3_BASE;
                endcase
            end
            tb_block_base=base+(({26'b0,slot} % 32'd14)*`SOC_INT8_SLOT_BYTES);
        end
    endfunction

    integer tq;
    reg [31:0] tb_wb;
    initial begin
        #1;
        for (tq=0;tq<64;tq=tq+1) begin
            tb_wb = tb_block_base(tq);
            if (tab_addr[tq*32 +: 32] != tb_block_base(tq) || tab_blk[tq*2 +: 2] != tq / 14 % 4 ||
                tab_pos[tq*4 +: 4] != tq % 14 || tab_wbase[tq*30 +: 30] != tb_wb[29:0] - DDR_BASE[29:0])
                $display("LANE_ASSERT_FAIL 常数表第 %0d 项和原公式不符", tq);
        end
    end

    // 每拍核对记账和标志
    integer an, au, ar, ap, as, aq;
    always @(posedge clk) if (rst_n) begin
        an = 0; au = 0; ar = 0; ap = 0;
        for (aq=0;aq<SLOT_COUNT;aq=aq+1) begin
            an = an + slot_free[aq];
            au = au + (slot_res[aq] | slot_q[aq] | slot_del[aq]);
            ar = ar + slot_res[aq];
            ap = ap + pick_take[aq];
            if ((slot_res[aq] + slot_q[aq] + slot_del[aq]) > 1)
                $display("LANE_ASSERT_FAIL t=%0t slot %0d 标志不互斥", $time, aq);
            if (slot_gm[aq] != (slot_generation[aq] == 32'hffff_ffff))
                $display("LANE_ASSERT_FAIL t=%0t slot %0d gm 和代号不符", $time, aq);
        end
        if (st_idle && free_base + rel_free_r != an)
            $display("LANE_ASSERT_FAIL t=%0t 空闲数 %0d+%0d != %0d", $time, free_base, rel_free_r, an);
        for (aq=0;aq<9;aq=aq+1)
            if (free_ge[aq] != (free_base >= aq))
                $display("LANE_ASSERT_FAIL t=%0t free_ge[%0d] 和 free_base=%0d 不符", $time, aq, free_base);
        if (!alloc_p1 && !alloc_p2) begin
            if (used_now != au)
                $display("LANE_ASSERT_FAIL t=%0t 占用数 %0d != %0d", $time, used_now, au);
            if (pop8(batch_reserved) != ar)
                $display("LANE_ASSERT_FAIL t=%0t 本批预约 %0d != slot_res %0d", $time, pop8(batch_reserved), ar);
        end
        if (alloc_p2 && ap != batch_count_reg)
            $display("LANE_ASSERT_FAIL t=%0t 选中 %0d 个 != 张数 %0d", $time, ap, batch_count_reg);
        if (alloc_p2 && first_idx_s1 != pick_index[5:0])
            $display("LANE_ASSERT_FAIL t=%0t 名次0 %0d != pick_index[0] %0d", $time, first_idx_s1, pick_index[5:0]);
        if (alloc_p2 && (batch_count_reg == 4'd0 || batch_count_reg > 4'd8 ||
            pick_mask != 8'hff >> (4'd8 - batch_count_reg)))
            $display("LANE_ASSERT_FAIL t=%0t 张数/掩码不符", $time);
        if (alloc_p1 && st_clean)
            $display("LANE_ASSERT_FAIL t=%0t alloc_p1 和 st_clean 同拍", $time);
        if (st_b && beat_last && fifo_full)
            $display("LANE_ASSERT_FAIL t=%0t 最后一拍时 FIFO 已满", $time);
        if (push_image && (cur_blk_r != tab_blk[cur_slot*2 +: 2] ||
            cur_pos_r != tab_pos[cur_slot*4 +: 4] || cur_addr_r != tab_addr[cur_slot*32 +: 32] ||
            cur_gen_r != slot_generation[cur_slot]))
            $display("LANE_ASSERT_FAIL t=%0t 入队时 cur_* 寄存值没跟上", $time);
        if (b_next && (next_slot_r != batch_slot_index[index_next] ||
            next_wbase_r != tab_wbase[next_slot_r*30 +: 30]))
            $display("LANE_ASSERT_FAIL t=%0t 换张时 next_* 寄存值没跟上", $time);
        as = st_idle + st_ar + st_r + st_aw + st_w0 + st_w1 + st_b + st_clean + st_drain;
        if (as != 1) $display("LANE_ASSERT_FAIL t=%0t 状态不是独热", $time);
        as = 0;
        for (aq=0;aq<9;aq=aq+1) as = as + fifo_level[aq];
        if (as != 1) $display("LANE_ASSERT_FAIL t=%0t fifo_level 不是独热", $time);
        if (st_idle && batch_reserved != 8'd0)
            $display("LANE_ASSERT_FAIL t=%0t IDLE 时 batch_reserved 没清", $time);
        if ((batch_live & ~batch_reserved) != 8'd0)
            $display("LANE_ASSERT_FAIL t=%0t batch_live 超出 batch_reserved", $time);
        for (aq=0;aq<8;aq=aq+1)
            if (!alloc_p2 && batch_reserved[aq] && batch_live[aq] == slot_gm[batch_slot_index[aq]])
                $display("LANE_ASSERT_FAIL t=%0t batch_live[%0d] 和 slot_gm 不符", $time, aq);
        if ((st_aw || st_w0 || st_w1 || st_b) && cur_slot != batch_slot_index[image_index_reg])
            $display("LANE_ASSERT_FAIL t=%0t cur_slot 和 batch_slot_index 不符", $time);
        if (st_aw && write_addr_reg != tab_wbase[cur_slot*30 +: 30] + {input_beat, 6'b0})
            $display("LANE_ASSERT_FAIL t=%0t 写地址不符", $time);
        if (beat_last != (input_beat == 10'd575))
            $display("LANE_ASSERT_FAIL t=%0t beat_last 不符", $time);
        if (!st_idle && image_last != ({1'b0,image_index_reg} + 4'd1 == batch_count_reg))
            $display("LANE_ASSERT_FAIL t=%0t image_last 不符", $time);
    end
`endif
endmodule
