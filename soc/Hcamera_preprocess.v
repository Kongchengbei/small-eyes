`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// 单路自主前处理：READY 原图 -> 颜色包围框 -> 最近邻 ROI -> DDR。
// 与 Camera DMA 同处 mem_clk 域；不需要 CPU 逐帧启动。
// 原图唯一消费者必须是本模块；外部 CPU 不得同时释放 source_ready_mask。
// ROI 输出暂为 RGB565（16-bit little-endian），不是已冻结的 NPU INT8 张量。
//
// 时序版（2026-10-19）：状态机各状态的停留拍数与原版相同，对外端口除 result_colors 外逐拍一致。
//   - 扫描像素由 pix_reg 寄存给出，颜色判断前不再做 16 选 1；
//   - 区域模块换成三级流水版（状态比原版晚 2 拍）。FILTER 仍是 MAX_REGIONS+1 拍，
//     全部区域并行走 5 级筛选流水（自由运行，FILTER 第 3 拍起输入已是终值），
//     在 region_index==MAX_REGIONS-1 那拍一次写回 boxes/roi_count/result_colors。
//     result_colors 因此只在 FILTER 窗口内与原版不同，这段时间 result_valid 恒为 0；
//   - 裁剪源地址改成增量寄存（crop_addr/row_addr），ROI 写地址基址用 roi_base 增量；
//   - 配置检查里的 cfg_width*cfg_height 乘法改成按 cfg_width 查表；
//   - axi_wstrb 改成寄存器直出，result_valid 的置位改成寄存的 fin_set。
// 需要 MAX_REGIONS >= 8（FILTER 窗口要装下筛选流水）。
module Hcamera_preprocess #(
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter [31:0] SOURCE0 = `SOC_CAM1_BUFFER0_BASE,
    parameter [31:0] SOURCE1 = `SOC_CAM1_BUFFER1_BASE,
    parameter [31:0] SOURCE_SLOT_BYTES = `SOC_CAM1_BUFFER_SLOT_BYTES,
    parameter [31:0] OUTPUT0 = `SOC_PRE1_BANK0_BASE,
    parameter [31:0] OUTPUT1 = `SOC_PRE1_BANK1_BASE,
    parameter [31:0] OUTPUT_BANK_BYTES = `SOC_PRE_BANK_BYTES,
    parameter [31:0] ROI_STRIDE_BYTES = `SOC_PRE_ROI_STRIDE_BYTES,
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer MAX_REGIONS = 8,
    parameter integer MAX_OUTPUT_SIZE = 128,
    parameter integer TIMEOUT_CYCLES = 1000000,
    parameter [7:0] AXI_ID = 8'h50,
    parameter [7:0] CAMERA_ID = 8'd1
) (
    input clk, input rst_n, input enable, input ddr_ready, input clear_errors,
    input [1:0] source_ready_mask,
    input [31:0] source_frame0, input [31:0] source_frame1,
    output reg source_release_valid, output reg [1:0] source_release_mask,
    // 配置只在领取一帧时锁存，帧内改变输入不会改变正在进行的任务。
    input [15:0] cfg_width,
	input [15:0] cfg_height,
    input [3:0] cfg_colors,
    input [7:0] cfg_bright_min, input [7:0] cfg_red_blue_bright_min,
    input [7:0] cfg_dominance, input [7:0] cfg_black_max,
    input [31:0] cfg_min_pixels, input [31:0] cfg_min_area, input [31:0] cfg_max_area,
    input [7:0] cfg_min_fill,
    input [15:0] cfg_min_aspect, input [15:0] cfg_max_aspect, input [15:0] cfg_margin,
    // 描述符 valid 必须保持到 ready；握手不等于归还 ROI bank。
    output reg result_valid, input result_ready,
    output [7:0] result_camera,
    output reg result_bank, output reg [31:0] result_frame,
    output reg [31:0] result_addr, output reg [31:0] result_count,
    output reg [15:0] result_width, output reg [15:0] result_height,
    output [31:0] result_stride,
    output reg [MAX_REGIONS*64-1:0] result_boxes,
    output reg [MAX_REGIONS*3-1:0] result_colors,
    // NPU 完成最后一次读取后按 bank+frame token 归还，拒绝过期/提前归还。
    input roi_release_valid, input roi_release_bank, input [31:0] roi_release_frame,
    output reg [1:0] bank_ready_mask,
    output busy, output reg [31:0] frames_processed, output reg [31:0] empty_frames,
    output reg [31:0] failed_frames, output reg [31:0] bad_releases,
    output reg error, output reg [31:0] error_code,
    output reg [31:0] last_cycles,
    output [29:0] axi_araddr, output [7:0] axi_arid, output [7:0] axi_arlen,
    output [2:0] axi_arsize, output [1:0] axi_arburst,
    output axi_arvalid, input axi_arready,
    input [255:0] axi_rdata, input [7:0] axi_rid, input [1:0] axi_rresp,
    input axi_rlast, input axi_rvalid, output axi_rready,
    output [29:0] axi_awaddr, output [7:0] axi_awid, output [7:0] axi_awlen,
    output [2:0] axi_awsize, output [1:0] axi_awburst,
    output axi_awvalid, input axi_awready,
    output [255:0] axi_wdata, output [31:0] axi_wstrb,
    output axi_wlast, output axi_wvalid, input axi_wready,
    input [7:0] axi_bid, input [1:0] axi_bresp, input axi_bvalid, output axi_bready
);
    localparam [4:0] IDLE=0, AR=1, R=2, SCAN=3, FILTER=4, ROI_START=5,
        CROP=6, STEP_X=7, STEP_Y=8, AW=9, W=10, B=11,
        FINISH=12, RELEASE=13, WAIT_RELEASE=14;
    localparam [31:0] ERR_CONFIG=1, ERR_READ=2, ERR_WRITE=3,
        ERR_TIMEOUT=4, ERR_REGIONS=5;
    function integer count_bits;
        input integer limit;
        integer v;
        begin
            count_bits=1;
            for(v=limit;v>1;v=v>>1) count_bits=count_bits+1;
        end
    endfunction
    localparam integer REGION_BITS=count_bits(MAX_REGIONS);
    localparam integer REGION_INDEX_BITS=count_bits(MAX_REGIONS-1);
    localparam integer N = MAX_REGIONS;
    // 区域模块与筛选流水的实际位宽：宽、高能装下 FRAME_WIDTH/FRAME_HEIGHT，
    // 坐标能装下 LAST_X/LAST_Y，像素数与面积能装下 FRAME_WIDTH*FRAME_HEIGHT。
    localparam integer WB = count_bits(FRAME_WIDTH);
    localparam integer HB = count_bits(FRAME_HEIGHT);
    localparam integer XB = count_bits(FRAME_WIDTH-1);
    localparam integer YB = count_bits(FRAME_HEIGHT-1);
    localparam integer RC = XB > YB ? XB : YB;
    localparam integer AB = WB + HB;
    localparam integer RN = AB > 32 ? 32 : AB;

    generate if (MAX_REGIONS < 8) begin : need_8_regions
        Hcamera_preprocess_needs_MAX_REGIONS_at_least_8 u_unsupported();
    end endgenerate

    reg [4:0] state, read_return, write_return;
    reg source_slot, output_bank;
    reg [31:0] frame_token, source_addr, output_addr;
    reg [31:0] bank_frames [0:1];
    reg [1:0] bank_owned;
    reg frame_bad;
    reg [31:0] cycle_count, wait_count;
    reg [15:0] out_width, out_height, margin;
    reg [3:0] colors_enabled;
    reg [7:0] bright_min, red_blue_bright_min, dominance, black_max, min_fill;
    reg [31:0] min_pixels, min_area, max_area;
    reg [15:0] min_aspect, max_aspect;
    reg [31:0] read_address, write_address;
    reg [255:0] read_cache, write_pack;
    reg [31:0] cache_address;
    reg cache_valid;
    reg [4:0] scan_lane, pack_count;
    reg [31:0] scan_offset, scan_pixels;
    reg [15:0] scan_x, scan_y;
    reg [REGION_BITS-1:0] region_index, roi_count, roi_index;
    reg [31:0] output_offset;
    wire [31:0] region_query_index={{(32-REGION_BITS){1'b0}},region_index};
    wire [31:0] roi_count32={{(32-REGION_BITS){1'b0}},roi_count};
    wire [31:0] roi_index32={{(32-REGION_BITS){1'b0}},roi_index};
    wire [REGION_INDEX_BITS-1:0] crop_index=roi_index[REGION_INDEX_BITS-1:0];
    reg [15:0] boxes_x0 [0:MAX_REGIONS-1], boxes_y0 [0:MAX_REGIONS-1];
    reg [15:0] boxes_x1 [0:MAX_REGIONS-1], boxes_y1 [0:MAX_REGIONS-1];
    // 每个框左上角（加边距后）的原图字节地址，FILTER 写回 boxes 时一并写入
    reg [31:0] box_base [0:MAX_REGIONS-1];
    reg [15:0] dst_x, dst_y;
    reg [31:0] x_remainder, y_remainder;
    reg [15:0] roi_width, roi_height;
    // crop_addr = source_addr + (src_y*FRAME_WIDTH + src_x)*2，row_addr 是本行 src_x=x0 时的值；
    // 原版的 src_x/src_y 只用来算这个地址，现改为在它们变化的同一拍增量更新。
    reg [31:0] crop_addr, row_addr;
    // roi_base = output_addr + roi_index*ROI_STRIDE_BYTES
    reg [31:0] roi_base;
    // 原版 axi_wstrb = 32'hffffffff >> ((16-pack_count)*2)，随 pack_count 同拍更新
    reg [31:0] wstrb_q;
    // 恰在 FINISH 且 roi_count!=0 的那一拍为 1（只有 B->FINISH 这一路满足）
    reg fin_set;
    // CROP 的行尾、末行判断用：领帧时锁存 out_width-1、out_height-1（17 位，宽高为 0 时也不会等于 dst_x/dst_y）
    reg [16:0] out_wm1, out_hm1;
    // 每拍寄存 roi_index+1==roi_count；只在 B 里用，进 B 的前一拍两者都不会变
    reg roi_last;
    // SCAN 中恒等于 read_cache[scan_lane*16 +: 16]
    reg [15:0] pix_reg;
    wire [255:0] cache_rot = {read_cache[15:0], read_cache[255:16]};
    wire [15:0] next_lane_pixel = cache_rot[scan_lane[3:0]*16 +: 16];
    wire [2:0] pixel_color;
    wire region_overflow;
    wire [31:0] crop_beat_address = {crop_addr[31:5],5'b0};
    wire [15:0] crop_pixel = read_cache[crop_addr[4:1]*16 +: 16];
    wire start_allowed = enable && ddr_ready && !result_valid &&
        source_ready_mask != 0 && bank_ready_mask != 2'b11;
    wire selected_source = !source_ready_mask[0];
    wire selected_bank = bank_ready_mask[0];
    wire axi_progress = (axi_arvalid && axi_arready) || (axi_rvalid && axi_rready) ||
        (axi_awvalid && axi_awready) || (axi_wvalid && axi_wready) ||
        (axi_bvalid && axi_bready);
    wire axi_waiting = state==AR || state==R || state==AW || state==W || state==B;
    wire [32:0] ddr_end = {1'b0,DDR_BASE}+{1'b0,DDR_BYTES};
    function [63:0] widen;
        input [31:0] value;
        begin widen = {32'b0,value}; end
    endfunction
    localparam [63:0] WIDTH64 = widen(FRAME_WIDTH), HEIGHT64 = widen(FRAME_HEIGHT);
    localparam [63:0] REGION_LIMIT64 = widen(MAX_REGIONS);
    localparam [15:0] LAST_X = FRAME_WIDTH[15:0]-16'd1;
    localparam [15:0] LAST_Y = FRAME_HEIGHT[15:0]-16'd1;
    localparam [63:0] FRAME_BYTES = WIDTH64*HEIGHT64*64'd2;
    localparam [31:0] ROW_BYTES = FRAME_WIDTH*2;

    // 地址验证覆盖整槽；四个区间互斥，避免任何裁剪写覆盖原图或另一个 bank。
    function intervals_disjoint;
        input [31:0] a, asize, b, bsize;
        begin
            intervals_disjoint = {1'b0,a}+{1'b0,asize} <= {1'b0,b} ||
                                 {1'b0,b}+{1'b0,bsize} <= {1'b0,a};
        end
    endfunction
    function in_ddr;
        input [31:0] a, size;
        begin in_ddr = a >= DDR_BASE && {1'b0,a}+{1'b0,size} <= ddr_end; end
    endfunction
    wire config_static = FRAME_WIDTH>0 && FRAME_WIDTH<=65535 &&
        FRAME_HEIGHT>0 && FRAME_HEIGHT<=65535 && FRAME_BYTES <= {32'b0,SOURCE_SLOT_BYTES} &&
        SOURCE_SLOT_BYTES[4:0]==0 && OUTPUT_BANK_BYTES[4:0]==0 && ROI_STRIDE_BYTES[4:0]==0 &&
        SOURCE0[4:0]==0 && SOURCE1[4:0]==0 && OUTPUT0[4:0]==0 && OUTPUT1[4:0]==0 &&
        in_ddr(SOURCE0,SOURCE_SLOT_BYTES) && in_ddr(SOURCE1,SOURCE_SLOT_BYTES) &&
        in_ddr(OUTPUT0,OUTPUT_BANK_BYTES) && in_ddr(OUTPUT1,OUTPUT_BANK_BYTES) &&
        intervals_disjoint(SOURCE0,SOURCE_SLOT_BYTES,SOURCE1,SOURCE_SLOT_BYTES) &&
        intervals_disjoint(OUTPUT0,OUTPUT_BANK_BYTES,OUTPUT1,OUTPUT_BANK_BYTES) &&
        intervals_disjoint(SOURCE0,SOURCE_SLOT_BYTES,OUTPUT0,OUTPUT_BANK_BYTES) &&
        intervals_disjoint(SOURCE0,SOURCE_SLOT_BYTES,OUTPUT1,OUTPUT_BANK_BYTES) &&
        intervals_disjoint(SOURCE1,SOURCE_SLOT_BYTES,OUTPUT0,OUTPUT_BANK_BYTES) &&
        intervals_disjoint(SOURCE1,SOURCE_SLOT_BYTES,OUTPUT1,OUTPUT_BANK_BYTES) &&
        REGION_LIMIT64*{32'b0,ROI_STRIDE_BYTES} <= {32'b0,OUTPUT_BANK_BYTES};
    // cfg_width*cfg_height*2 <= ROI_STRIDE_BYTES：只在 1<=宽、高<=MAX_OUTPUT_SIZE 时有意义
    // （其余情况别的条件已判无效）。宽高都取上限也不超时恒成立；否则 MAX_OUTPUT_SIZE<=255
    // 时按宽查“允许的最大高”表，再大才保留原乘法。
    localparam [63:0] MOS64 = widen(MAX_OUTPUT_SIZE);
    localparam AREA_ALWAYS_OK = MOS64*MOS64*64'd2 <= {32'b0,ROI_STRIDE_BYTES};
    function [7:0] height_limit;
        input integer w;
        reg [63:0] q;
        begin
            if (w < 1 || w > MAX_OUTPUT_SIZE) height_limit = 8'd0;
            else begin
                q = {32'b0,ROI_STRIDE_BYTES} / (64'd2*w);
                height_limit = q >= MOS64 ? MOS64[7:0] : q[7:0];
            end
        end
    endfunction
    wire cfg_area_ok;
    genvar hw;
    generate if (AREA_ALWAYS_OK) begin : area_const
        assign cfg_area_ok = 1'b1;
    end else if (MAX_OUTPUT_SIZE <= 255) begin : area_table
        wire [256*8-1:0] limit_table;
        for (hw=0; hw<256; hw=hw+1) begin : entry
            assign limit_table[hw*8 +: 8] = height_limit(hw);
        end
        assign cfg_area_ok = cfg_height[7:0] <= limit_table[cfg_width[7:0]*8 +: 8];
    end else begin : area_mul
        assign cfg_area_ok = {48'b0,cfg_width}*{48'b0,cfg_height}*64'd2<={32'b0,ROI_STRIDE_BYTES};
    end endgenerate
    // 与常数比大小写成逐位与或（不走进位链）：返回 a<=c
    function le_const16;
        input [15:0] a;
        input [15:0] c;
        integer i;
        reg eq, lt;
        begin
            eq = 1'b1; lt = 1'b0;
            for (i=15; i>=0; i=i-1) begin
                lt = lt | (eq & ~a[i] & c[i]);
                eq = eq & ~(a[i] ^ c[i]);
            end
            le_const16 = lt | eq;
        end
    endfunction
    localparam [31:0] MOS32 = MAX_OUTPUT_SIZE;
    // 即原版 {16'b0,cfg_*}<=MAX_OUTPUT_SIZE（32 位无符号比）
    wire cfg_w_le = MOS32[31:16]!=0 || le_const16(cfg_width, MOS32[15:0]);
    wire cfg_h_le = MOS32[31:16]!=0 || le_const16(cfg_height, MOS32[15:0]);
    // keep：让配置检查成为一根线，在 error_code/state/frame_bad 的最后一级才并进去
    // 再拆成“浅的几项”和两条进位链比较三根线，error_code 的配置错判断直接拿这三根，只过一级 LUT
    (* keep *) wire cfg_basic_ok = config_static &&
        cfg_width!=0 && cfg_height!=0 && cfg_w_le && cfg_h_le && cfg_area_ok;
    (* keep *) wire cfg_area_le = cfg_min_area<=cfg_max_area;
    (* keep *) wire cfg_aspect_le = cfg_min_aspect<=cfg_max_aspect;
    (* keep *) wire config_valid = cfg_basic_ok && cfg_area_le && cfg_aspect_le;

    Hpreprocess_color u_color (.pixel(pix_reg), .color_enable(colors_enabled),
        .bright_min(bright_min), .red_blue_bright_min(red_blue_bright_min),
        .dominance(dominance), .black_max(black_max), .color(pixel_color));
    wire [N-1:0] rg_valid;
    wire [N*3-1:0] rg_color;
    wire [N*16-1:0] rg_x0, rg_y0, rg_x1, rg_y1;
    wire [N*32-1:0] rg_pixels;
    wire unused_q_valid;
    wire [2:0] unused_q_color;
    wire [15:0] unused_q_x0, unused_q_y0, unused_q_x1, unused_q_y1;
    wire [31:0] unused_q_pixels;
    Hpreprocess_regions #(.MAX_REGIONS(MAX_REGIONS), .COORD_BITS(RC), .COUNT_BITS(RN)) u_regions (
        .clk(clk), .rst_n(rst_n), .clear(state==IDLE && start_allowed),
        .pixel_valid(state==SCAN && !frame_bad), .x(scan_x), .y(scan_y), .color(pixel_color),
        .min_pixels(min_pixels),
        .query_index(32'd0), .query_valid(unused_q_valid), .query_color(unused_q_color),
        .query_x0(unused_q_x0), .query_y0(unused_q_y0), .query_x1(unused_q_x1), .query_y1(unused_q_y1),
        .query_pixels(unused_q_pixels), .overflow(region_overflow),
        .all_valid(rg_valid), .all_color(rg_color), .all_x0(rg_x0), .all_y0(rg_y0),
        .all_x1(rg_x1), .all_y1(rg_y1), .all_pixels(rg_pixels));

    // ---------------- FILTER 并行筛选流水 ----------------
    // 区域状态在 FILTER 第 0 拍（T0）后 2 拍成为终值，此后到下一次 clear 都不变；
    // 下面各级每拍都算，T0+3 起第 1 级是终值，T0+6 起 acc 是终值，T0+7 起 sel 是终值，
    // 在 region_index==MAX_REGIONS-1（>=T0+7）那拍写回。判据与原版 region_accepted 相同，
    // 位宽按帧尺寸取到恰好不溢出。
    wire [N-1:0] acc;
    wire [N*16-1:0] mb_x0, mb_y0, mb_x1, mb_y1;
    wire [N*32-1:0] mb_base;
    wire [N*3-1:0] mb_color;
    genvar g;
    generate for (g=0; g<N; g=g+1) begin : flt
        wire [15:0] rx0 = rg_x0[g*16 +: 16], ry0 = rg_y0[g*16 +: 16];
        wire [15:0] rx1 = rg_x1[g*16 +: 16], ry1 = rg_y1[g*16 +: 16];
        wire [31:0] rpix = rg_pixels[g*32 +: 32];
        // 第 1 级：宽高、像素数门限、加边距的框
        reg p1_v, p1_pix_ok;
        reg [2:0] p1_c;
        reg [WB-1:0] p1_w;
        reg [HB-1:0] p1_h;
        reg [RN-1:0] p1_pix;
        reg [15:0] p1_x0, p1_y0, p1_x1, p1_y1;
        // 第 2 级：面积、高乘长宽比门限、框左上角行偏移
        reg p2_v, p2_pix_ok;
        reg [WB-1:0] p2_w;
        reg [AB-1:0] p2_area;
        reg [HB+15:0] p2_hmin, p2_hmax;
        reg [RN-1:0] p2_pix;
        reg [31:0] p2_yoff;
        // 第 3 级：面积、长宽比比较，面积乘填充率门限
        reg p3_v, p3_pix_ok, p3_area_ok, p3_asp_ok;
        reg [AB+7:0] p3_fill;
        reg [RN-1:0] p3_pix;
        reg [31:0] p3_off;
        // 第 4 级：是否接受、框的源字节地址
        reg p4_acc;
        reg [31:0] p4_base;
        wire [63:0] p2_aw64 = {{(56-WB){1'b0}}, p2_w, 8'b0};
        wire [63:0] p2_hmin64 = {{(48-HB){1'b0}}, p2_hmin};
        wire [63:0] p2_hmax64 = {{(48-HB){1'b0}}, p2_hmax};
        wire [63:0] p2_area64 = {{(64-AB){1'b0}}, p2_area};
        // 原版地址按 32 位取模，(y*W+x)*2 的第 31 位移出不用
        wire unused_off_hi = p3_off[31];
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                p1_v<=0; p1_pix_ok<=0; p1_c<=0; p1_w<=0; p1_h<=0; p1_pix<=0;
                p1_x0<=0; p1_y0<=0; p1_x1<=0; p1_y1<=0;
                p2_v<=0; p2_pix_ok<=0; p2_w<=0; p2_area<=0; p2_hmin<=0; p2_hmax<=0;
                p2_pix<=0; p2_yoff<=0;
                p3_v<=0; p3_pix_ok<=0; p3_area_ok<=0; p3_asp_ok<=0; p3_fill<=0;
                p3_pix<=0; p3_off<=0;
                p4_acc<=0; p4_base<=0;
            end else begin
                p1_v <= rg_valid[g];
                p1_c <= rg_color[g*3 +: 3];
                p1_w <= rx1[WB-1:0] - rx0[WB-1:0] + 1'b1;
                p1_h <= ry1[HB-1:0] - ry0[HB-1:0] + 1'b1;
                p1_pix_ok <= rpix >= min_pixels;
                p1_pix <= rpix[RN-1:0];
                p1_x0 <= rx0>margin ? rx0-margin : 16'd0;
                p1_y0 <= ry0>margin ? ry0-margin : 16'd0;
                p1_x1 <= ({16'b0,rx1}+{16'b0,margin}<FRAME_WIDTH) ? rx1+margin : LAST_X;
                p1_y1 <= ({16'b0,ry1}+{16'b0,margin}<FRAME_HEIGHT) ? ry1+margin : LAST_Y;

                p2_v <= p1_v; p2_pix_ok <= p1_pix_ok; p2_pix <= p1_pix; p2_w <= p1_w;
                p2_area <= p1_w * p1_h;
                p2_hmin <= p1_h * min_aspect;
                p2_hmax <= p1_h * max_aspect;
                p2_yoff <= {16'b0,p1_y0} * FRAME_WIDTH;

                p3_v <= p2_v; p3_pix_ok <= p2_pix_ok; p3_pix <= p2_pix;
                p3_area_ok <= p2_area64 >= {32'b0,min_area} && p2_area64 <= {32'b0,max_area};
                p3_asp_ok <= p2_aw64 >= p2_hmin64 && p2_aw64 <= p2_hmax64;
                p3_fill <= p2_area * min_fill;
                p3_off <= p2_yoff + {16'b0,p1_x0};

                p4_acc <= p3_v && p3_pix_ok && p3_area_ok && p3_asp_ok && {p3_pix,8'b0} >= p3_fill;
                p4_base <= source_addr + {p3_off[30:0],1'b0};
            end
        end
        assign mb_x0[g*16 +: 16] = p1_x0; assign mb_y0[g*16 +: 16] = p1_y0;
        assign mb_x1[g*16 +: 16] = p1_x1; assign mb_y1[g*16 +: 16] = p1_y1;
        assign acc[g] = p4_acc;
        assign mb_base[g*32 +: 32] = p4_base;
        assign mb_color[g*3 +: 3] = p1_c;
    end endgenerate

    // 第 5 级：sel[d*N+k] = 区域 k 被接受，且编号比它小的被接受区域恰有 d 个（即第 d 个 ROI）。
    // 计数写成独热的逐位与或（acc 的低 k 位里恰有 d 个 1），不用加法器，免得串成多段进位链。
    function [N:0] ones_onehot;
        input [N-1:0] a;
        input integer k;
        integer j;
        reg [N:0] e;
        begin
            e = {{N{1'b0}},1'b1};
            for (j=0; j<k; j=j+1) e = a[j] ? {e[N-1:0],1'b0} : e;
            ones_onehot = e;
        end
    endfunction
    function [REGION_BITS-1:0] onehot_to_count;
        input [N:0] e;
        integer j;
        reg [REGION_BITS-1:0] c;
        begin
            c = 0;
            for (j=0; j<=N; j=j+1) c = c | ({REGION_BITS{e[j]}} & j[REGION_BITS-1:0]);
            onehot_to_count = c;
        end
    endfunction
    // ohv[k*(N+1)+d]：acc 的低 k 位里恰有 d 个 1
    wire [(N+1)*(N+1)-1:0] ohv;
    genvar og;
    generate for (og=0; og<=N; og=og+1) begin : ohk
        assign ohv[og*(N+1) +: N+1] = ones_onehot(acc, og);
    end endgenerate
    reg [N*N-1:0] sel;
    reg [REGION_BITS-1:0] acc_count;
    integer sd, sk;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel <= 0; acc_count <= 0;
        end else begin
            for (sd=0; sd<N; sd=sd+1)
                for (sk=0; sk<N; sk=sk+1)
                    sel[sd*N+sk] <= sk >= sd && acc[sk] && ohv[sk*(N+1)+sd];
            acc_count <= onehot_to_count(ohv[N*(N+1) +: N+1]);
        end
    end
    // 第 6 级的写回数据：第 d 个 ROI 的框/地址/颜色（与或选择，没有就是 0）
    reg [N*16-1:0] cmp_x0, cmp_y0, cmp_x1, cmp_y1;
    reg [N*32-1:0] cmp_base;
    reg [N*3-1:0] cmp_colors;
    reg [N-1:0] cmp_hit;
    integer cd, ck;
    always @* begin
        cmp_x0 = 0; cmp_y0 = 0; cmp_x1 = 0; cmp_y1 = 0; cmp_base = 0; cmp_colors = 0; cmp_hit = 0;
        for (cd=0; cd<N; cd=cd+1)
            for (ck=cd; ck<N; ck=ck+1) begin
                cmp_hit[cd] = cmp_hit[cd] | sel[cd*N+ck];
                cmp_x0[cd*16 +: 16] = cmp_x0[cd*16 +: 16] | ({16{sel[cd*N+ck]}} & mb_x0[ck*16 +: 16]);
                cmp_y0[cd*16 +: 16] = cmp_y0[cd*16 +: 16] | ({16{sel[cd*N+ck]}} & mb_y0[ck*16 +: 16]);
                cmp_x1[cd*16 +: 16] = cmp_x1[cd*16 +: 16] | ({16{sel[cd*N+ck]}} & mb_x1[ck*16 +: 16]);
                cmp_y1[cd*16 +: 16] = cmp_y1[cd*16 +: 16] | ({16{sel[cd*N+ck]}} & mb_y1[ck*16 +: 16]);
                cmp_base[cd*32 +: 32] = cmp_base[cd*32 +: 32] | ({32{sel[cd*N+ck]}} & mb_base[ck*32 +: 32]);
                cmp_colors[cd*3 +: 3] = cmp_colors[cd*3 +: 3] | ({3{sel[cd*N+ck]}} & mb_color[ck*3 +: 3]);
            end
    end
    wire filter_commit = state==FILTER && region_query_index==MAX_REGIONS-1;

    assign busy = state!=IDLE;
    assign result_camera = CAMERA_ID;
    assign result_stride = ROI_STRIDE_BYTES;
    wire [31:0] local_read_address = read_address-DDR_BASE;
    wire [31:0] local_write_address = write_address-DDR_BASE;
    assign axi_araddr = local_read_address[29:0];
    assign axi_arid = AXI_ID; assign axi_arlen = 0;
    assign axi_arsize = 3'b101; assign axi_arburst = 2'b01;
    assign axi_arvalid = state==AR; assign axi_rready = state==R;
    assign axi_awaddr = local_write_address[29:0];
    assign axi_awid = AXI_ID; assign axi_awlen = 0;
    assign axi_awsize = 3'b101; assign axi_awburst = 2'b01;
    assign axi_awvalid = state==AW;
    assign axi_wdata = write_pack;
    assign axi_wstrb = wstrb_q;
    assign axi_wlast = 1; assign axi_wvalid = state==W; assign axi_bready = state==B;

    // 归还比较：两个 bank 并行比，再按 roi_release_bank 选
    wire release_ok0 = bank_ready_mask[0] && bank_owned[0] && bank_frames[0]==roi_release_frame;
    wire release_ok1 = bank_ready_mask[1] && bank_owned[1] && bank_frames[1]==roi_release_frame;
    wire release_ok = roi_release_bank ? release_ok1 : release_ok0;
    // 本拍被合法归还而清掉的 bank（keep：让 result_ready 只过最后一级 LUT 进 bank_owned）
    (* keep *) wire [1:0] own_clear = {roi_release_valid && release_ok && roi_release_bank,
                                       roi_release_valid && release_ok && !roi_release_bank};
    // 有结果待取且属于 bank k（只含寄存器）；bank_owned 的下一值只剩 4 个输入，result_ready 进一个 LUT 就到 FF
    (* keep *) wire [1:0] take_bank = {result_valid && result_bank, result_valid && !result_bank};
    wire x_end = {1'b0,dst_x}==out_wm1;
    wire y_end = {1'b0,dst_y}==out_hm1;

    // 错误码单独算，等同原版 report_error：同一拍后调用的覆盖先调用的（超时在前，R/B/IDLE 里的在后）；
    // IDLE 领帧那拍不会有超时、读写错，配置检查只在最后一级选择里出现。
    wire err_timeout = axi_waiting && !axi_progress && wait_count >= TIMEOUT_CYCLES-1;
    wire err_read = state==R && axi_rvalid && (axi_rid!=AXI_ID || axi_rresp!=0 || !axi_rlast);
    wire err_write = state==B && axi_bvalid && (axi_bid!=AXI_ID || axi_bresp!=0);
    // keep：err_can_set、idle_start 单独成线，配置错判断（来自输入，最晚到）只过末级一个 LUT 就进 FF
    (* keep *) wire err_can_set = !error || clear_errors;
    wire [31:0] code_hold = clear_errors ? 32'd0 : error_code;
    (* keep *) wire idle_start = state==IDLE && start_allowed;
    (* keep *) wire [31:0] code_other = err_can_set && (err_read || err_write || err_timeout) ?
        (err_read ? ERR_READ : err_write ? ERR_WRITE : ERR_TIMEOUT) : code_hold;
    // IDLE 里 err_read/err_write/err_timeout 恒 0（都带状态条件，axi_waiting 在 IDLE 为 0），
    // 所以 IDLE 领帧那拍 code_other==code_hold，只剩配置错这一种改写
    (* keep *) wire cfg_err_now = idle_start && err_can_set && !(cfg_basic_ok && cfg_area_le && cfg_aspect_le);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) error_code <= 0;
        else error_code <= cfg_err_now ? ERR_CONFIG : code_other;

    // 原版 report_error(code)：error_code 改在上面单独的 always 里写
    task report_error;
        begin
            frame_bad <= 1; error <= 1;
        end
    endtask

    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state<=IDLE; read_return<=SCAN; write_return<=CROP;
            source_slot<=0; output_bank<=0; source_addr<=0; output_addr<=0; frame_token<=0;
            source_release_valid<=0; source_release_mask<=0;
            result_valid<=0; result_bank<=0; result_frame<=0; result_addr<=0; result_count<=0;
            result_width<=0; result_height<=0; result_boxes<=0; result_colors<=0;
            bank_ready_mask<=0; bank_owned<=0; bank_frames[0]<=0; bank_frames[1]<=0;
            frames_processed<=0; empty_frames<=0; failed_frames<=0; bad_releases<=0;
            error<=0; last_cycles<=0; frame_bad<=0; cycle_count<=0; wait_count<=0;
            out_width<=0; out_height<=0; colors_enabled<=0; bright_min<=0; red_blue_bright_min<=0; dominance<=0;
            black_max<=0; min_fill<=0; min_pixels<=0; min_area<=0; max_area<=0;
            min_aspect<=0; max_aspect<=0; margin<=0;
            read_address<=0; write_address<=0; read_cache<=0; write_pack<=0;
            cache_address<=0; cache_valid<=0; scan_lane<=0; pack_count<=0;
            scan_offset<=0; scan_pixels<=0; scan_x<=0; scan_y<=0;
            region_index<=0; roi_count<=0; roi_index<=0; output_offset<=0;
            dst_x<=0; dst_y<=0; x_remainder<=0; y_remainder<=0;
            roi_width<=0; roi_height<=0;
            crop_addr<=0; row_addr<=0; roi_base<=0; wstrb_q<=0; fin_set<=0; pix_reg<=0;
            out_wm1<=0; out_hm1<=0; roi_last<=0;
            for (k=0;k<MAX_REGIONS;k=k+1) begin
                boxes_x0[k]<=0; boxes_y0[k]<=0; boxes_x1[k]<=0; boxes_y1[k]<=0; box_base[k]<=0;
            end
        end else begin
            source_release_valid<=0;
            fin_set<=0;
            if (clear_errors) error<=0;
            roi_last <= roi_index32+1==roi_count32;
            // 原版：FINISH 且 roi_count!=0 时置 1，否则握手成功清 0
            result_valid <= fin_set || (result_valid && !result_ready);
            // 原版：握手置 1，同拍合法归还清 0 优先
            for (k=0;k<2;k=k+1)
                bank_owned[k] <= !own_clear[k] && (bank_owned[k] || (take_bank[k] && result_ready));
            if (roi_release_valid) begin
                if (release_ok) bank_ready_mask[roi_release_bank]<=0;
                else bad_releases<=bad_releases+1;
            end
            if (busy) cycle_count<=cycle_count+1;
            // 超时后不撤销任何 AXI VALID，不提前归还原图；等待事务排空。
            if (!axi_waiting || axi_progress) wait_count<=0;
            else if (wait_count >= TIMEOUT_CYCLES-1) begin
                wait_count<=0; report_error;
            end else wait_count<=wait_count+1;

            case (state)
                IDLE: if (start_allowed) begin
                    source_slot<=selected_source; output_bank<=selected_bank;
                    source_addr<=selected_source ? SOURCE1 : SOURCE0;
                    frame_token<=selected_source ? source_frame1 : source_frame0;
                    output_addr<=selected_bank ? OUTPUT1 : OUTPUT0;
                    frame_bad<=!config_valid; cycle_count<=0; cache_valid<=0;
                    out_width<=cfg_width; out_height<=cfg_height; colors_enabled<=cfg_colors;
                    out_wm1<={1'b0,cfg_width}-17'd1; out_hm1<={1'b0,cfg_height}-17'd1;
                    bright_min<=cfg_bright_min; red_blue_bright_min<=cfg_red_blue_bright_min;
                    dominance<=cfg_dominance; black_max<=cfg_black_max;
                    min_pixels<=cfg_min_pixels; min_area<=cfg_min_area; max_area<=cfg_max_area;
                    min_fill<=cfg_min_fill; min_aspect<=cfg_min_aspect; max_aspect<=cfg_max_aspect;
                    margin<=cfg_margin;
                    scan_offset<=0; scan_pixels<=0; scan_lane<=0; scan_x<=0; scan_y<=0;
                    region_index<=0; roi_count<=0; roi_index<=0; result_boxes<=0; result_colors<=0;
                    read_address<=selected_source ? SOURCE1 : SOURCE0; read_return<=SCAN;
                    state<=config_valid ? AR : RELEASE;
                    if (!config_valid) report_error;
                end
                AR: if (axi_arready) state<=R;
                R: if (axi_rvalid) begin
                    if (axi_rid!=AXI_ID || axi_rresp!=0 || !axi_rlast) report_error;
                    if (axi_rlast) begin
                        if (frame_bad || axi_rid!=AXI_ID || axi_rresp!=0) state<=RELEASE;
                        else begin
                            read_cache<=axi_rdata; cache_address<=read_address; cache_valid<=1;
                            // 回到 SCAN 时 scan_lane 必为 0
                            pix_reg<=axi_rdata[15:0];
                            state<=read_return;
                        end
                    end
                end
                SCAN: begin
                    if (frame_bad) state<=RELEASE;
                    else begin
                        scan_pixels<=scan_pixels+1;
                        if (scan_x==LAST_X) begin scan_x<=0; scan_y<=scan_y+1; end
                        else scan_x<=scan_x+1;
                        if (scan_pixels==FRAME_WIDTH*FRAME_HEIGHT-1) state<=FILTER;
                        else if (scan_lane==15) begin
                            scan_lane<=0; scan_offset<=scan_offset+32;
                            read_address<=source_addr+scan_offset+32; read_return<=SCAN; state<=AR;
                        end else begin
                            scan_lane<=scan_lane+1;
                            pix_reg<=next_lane_pixel;
                        end
                    end
                end
                FILTER: begin
                    // region_overflow 只表示本帧有像素因槽满被丢，不再作废整帧；ERR_REGIONS 保留不用。
                    if (region_query_index==MAX_REGIONS) begin
                        if (roi_count==0) state<=FINISH;
                        else begin roi_index<=0; roi_base<=output_addr; state<=ROI_START; end
                    end else begin
                        // 原版逐拍追加被接受的区域；这里在窗口最后一拍一次写入同样的结果
                        if (filter_commit) begin
                            for (k=0;k<MAX_REGIONS;k=k+1)
                                if (cmp_hit[k]) begin
                                    boxes_x0[k]<=cmp_x0[k*16 +: 16]; boxes_y0[k]<=cmp_y0[k*16 +: 16];
                                    boxes_x1[k]<=cmp_x1[k*16 +: 16]; boxes_y1[k]<=cmp_y1[k*16 +: 16];
                                    box_base[k]<=cmp_base[k*32 +: 32];
                                end
                            result_colors<=cmp_colors;
                            roi_count<=acc_count;
                        end
                        region_index<=region_index+1;
                    end
                end
                ROI_START: begin
                    crop_addr<=box_base[crop_index]; row_addr<=box_base[crop_index];
                    dst_x<=0; dst_y<=0; x_remainder<=0; y_remainder<=0;
                    roi_width<=boxes_x1[crop_index]-boxes_x0[crop_index]+1;
                    roi_height<=boxes_y1[crop_index]-boxes_y0[crop_index]+1;
                    for(k=0;k<MAX_REGIONS;k=k+1)
                        if(roi_index32==k) result_boxes[k*64 +: 64]<={boxes_y1[crop_index],boxes_x1[crop_index],
                            boxes_y0[crop_index],boxes_x0[crop_index]};
                    output_offset<=0; pack_count<=0; wstrb_q<=0; write_pack<=0; state<=CROP;
                end
                CROP: begin
                    if (frame_bad) state<=RELEASE;
                    else if (!cache_valid || cache_address!=crop_beat_address) begin
                        read_address<=crop_beat_address; read_return<=CROP; state<=AR;
                    end else begin
                        // 原版 write_pack[pack_count*16 +: 16]；命中时 pack_count<=15，按译码写
                        for (k=0;k<16;k=k+1)
                            if (pack_count==k[4:0]) write_pack[k*16 +: 16]<=crop_pixel;
                        pack_count<=pack_count+1;
                        wstrb_q<={wstrb_q[29:0],2'b11};
                        if (x_end) begin
                            dst_x<=0; crop_addr<=row_addr; x_remainder<=0;
                            y_remainder<=y_remainder+{16'b0,roi_height};
                            dst_y<=dst_y+1;
                        end else begin
                            dst_x<=dst_x+1; x_remainder<=x_remainder+{16'b0,roi_width};
                        end
                        if (pack_count==15 || (x_end && y_end)) begin
                            write_address<=roi_base+output_offset;
                            write_return<=(x_end && y_end) ? ROI_START : (x_end ? STEP_Y : STEP_X);
                            state<=AW;
                        end else state<=x_end ? STEP_Y : STEP_X;
                    end
                end
                // 整数 DDA 实现 floor(dst*ROI_size/output_size)，不用可变除法器。
                // 原版 src_x+1 / src_y+1 对应源地址 +2 / +一行字节数（STEP_Y 时 crop_addr==row_addr）。
                STEP_X: if (x_remainder>={16'b0,out_width}) begin
                    x_remainder<=x_remainder-{16'b0,out_width}; crop_addr<=crop_addr+32'd2;
                end else state<=CROP;
                STEP_Y: if (y_remainder>={16'b0,out_height}) begin
                    y_remainder<=y_remainder-{16'b0,out_height};
                    crop_addr<=row_addr+ROW_BYTES; row_addr<=row_addr+ROW_BYTES;
                end else state<=CROP;
                AW: if (axi_awready) state<=W;
                W: if (axi_wready) state<=B;
                B: if (axi_bvalid) begin
                    if (axi_bid!=AXI_ID || axi_bresp!=0) begin report_error; state<=RELEASE; end
                    else if (frame_bad) state<=RELEASE;
                    else begin
                        pack_count<=0; wstrb_q<=0; write_pack<=0; output_offset<=output_offset+32;
                        if (write_return==ROI_START) begin
                            if (roi_last) begin state<=FINISH; fin_set<=1; end
                            else begin
                                roi_index<=roi_index+1; roi_base<=roi_base+ROI_STRIDE_BYTES;
                                state<=ROI_START;
                            end
                        end else state<=write_return;
                    end
                end
                FINISH: begin
                    frames_processed<=frames_processed+1;
                    if (!fin_set) empty_frames<=empty_frames+1;
                    else begin
                        bank_ready_mask[output_bank]<=1;
                        bank_frames[output_bank]<=frame_token;
                        result_bank<=output_bank; result_frame<=frame_token;
                        result_addr<=output_addr; result_count<=roi_count32;
                        result_width<=out_width; result_height<=out_height;
                    end
                    state<=RELEASE;
                end
                RELEASE: begin
                    source_release_valid<=1;
                    source_release_mask<=source_slot ? 2'b10 : 2'b01;
                    if (frame_bad) failed_frames<=failed_frames+1;
                    last_cycles<=cycle_count; state<=WAIT_RELEASE;
                end
                WAIT_RELEASE: if (!source_ready_mask[source_slot]) state<=IDLE;
                default: state<=IDLE;
            endcase
        end
    end
endmodule
