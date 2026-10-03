`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// 单路自主前处理：READY 原图 -> 颜色包围框 -> 最近邻 ROI -> DDR。
// 与 Camera DMA 同处 mem_clk 域；不需要 CPU 逐帧启动。
// 原图唯一消费者必须是本模块；外部 CPU 不得同时释放 source_ready_mask。
// ROI 输出暂为 RGB565（16-bit little-endian），不是已冻结的 NPU INT8 张量。
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
    input [15:0] cfg_width, input [15:0] cfg_height,
    input [3:0] cfg_colors,
    input [7:0] cfg_bright_min, input [7:0] cfg_dominance, input [7:0] cfg_black_max,
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
    reg [4:0] state, read_return, write_return;
    reg source_slot, output_bank;
    reg [31:0] frame_token, source_addr, output_addr;
    reg [31:0] bank_frames [0:1];
    reg [1:0] bank_owned;
    reg frame_bad;
    reg [31:0] cycle_count, wait_count;
    reg [15:0] out_width, out_height, margin;
    reg [3:0] colors_enabled;
    reg [7:0] bright_min, dominance, black_max, min_fill;
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
    wire [REGION_INDEX_BITS-1:0] append_index=roi_count[REGION_INDEX_BITS-1:0];
    wire [REGION_INDEX_BITS-1:0] crop_index=roi_index[REGION_INDEX_BITS-1:0];
    reg [15:0] boxes_x0 [0:MAX_REGIONS-1], boxes_y0 [0:MAX_REGIONS-1];
    reg [15:0] boxes_x1 [0:MAX_REGIONS-1], boxes_y1 [0:MAX_REGIONS-1];
    reg [15:0] src_x, src_y, dst_x, dst_y;
    reg [31:0] x_remainder, y_remainder;
    reg [15:0] roi_width, roi_height;
    wire [15:0] scan_pixel = read_cache[scan_lane*16 +: 16];
    wire [2:0] pixel_color;
    wire region_valid, region_overflow;
    wire [2:0] region_color;
    wire [15:0] rx0, ry0, rx1, ry1;
    wire [31:0] region_pixels;
    wire [31:0] region_width = {16'b0,rx1}-{16'b0,rx0}+32'd1;
    wire [31:0] region_height = {16'b0,ry1}-{16'b0,ry0}+32'd1;
    wire [63:0] region_area = {32'b0,region_width}*{32'b0,region_height};
    wire [63:0] color_fraction = {32'b0,region_pixels}*64'd256;
    wire [63:0] aspect_width = {32'b0,region_width}*64'd256;
    wire region_accepted = region_valid && region_pixels >= min_pixels &&
        region_area >= {32'b0,min_area} && region_area <= {32'b0,max_area} &&
        color_fraction >= region_area*{56'b0,min_fill} &&
        aspect_width >= {32'b0,region_height}*{48'b0,min_aspect} &&
        aspect_width <= {32'b0,region_height}*{48'b0,max_aspect};
    wire [31:0] crop_byte_address = source_addr +
        (({16'b0,src_y}*FRAME_WIDTH)+{16'b0,src_x})*32'd2;
    wire [31:0] crop_beat_address = {crop_byte_address[31:5],5'b0};
    wire [15:0] crop_pixel = read_cache[crop_byte_address[4:1]*16 +: 16];
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
    wire config_valid = FRAME_WIDTH>0 && FRAME_WIDTH<=65535 &&
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
        REGION_LIMIT64*{32'b0,ROI_STRIDE_BYTES} <= {32'b0,OUTPUT_BANK_BYTES} &&
        cfg_width!=0 && cfg_height!=0 && {16'b0,cfg_width}<=MAX_OUTPUT_SIZE &&
        {16'b0,cfg_height}<=MAX_OUTPUT_SIZE &&
        {48'b0,cfg_width}*{48'b0,cfg_height}*64'd2<={32'b0,ROI_STRIDE_BYTES} &&
        cfg_min_area<=cfg_max_area && cfg_min_aspect<=cfg_max_aspect;

    Hpreprocess_color u_color (.pixel(scan_pixel), .color_enable(colors_enabled),
        .bright_min(bright_min), .dominance(dominance), .black_max(black_max), .color(pixel_color));
    Hpreprocess_regions #(.MAX_REGIONS(MAX_REGIONS)) u_regions (
        .clk(clk), .rst_n(rst_n), .clear(state==IDLE && start_allowed),
        .pixel_valid(state==SCAN && !frame_bad), .x(scan_x), .y(scan_y), .color(pixel_color),
        .query_index(region_query_index), .query_valid(region_valid), .query_color(region_color),
        .query_x0(rx0), .query_y0(ry0), .query_x1(rx1), .query_y1(ry1),
        .query_pixels(region_pixels), .overflow(region_overflow));

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
    assign axi_wstrb = 32'hffffffff >> ((16-pack_count)*2);
    assign axi_wlast = 1; assign axi_wvalid = state==W; assign axi_bready = state==B;

    task report_error;
        input [31:0] code;
        begin
            frame_bad <= 1; error <= 1;
            if (!error || clear_errors) error_code <= code;
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
            error<=0; error_code<=0; last_cycles<=0; frame_bad<=0; cycle_count<=0; wait_count<=0;
            out_width<=0; out_height<=0; colors_enabled<=0; bright_min<=0; dominance<=0;
            black_max<=0; min_fill<=0; min_pixels<=0; min_area<=0; max_area<=0;
            min_aspect<=0; max_aspect<=0; margin<=0;
            read_address<=0; write_address<=0; read_cache<=0; write_pack<=0;
            cache_address<=0; cache_valid<=0; scan_lane<=0; pack_count<=0;
            scan_offset<=0; scan_pixels<=0; scan_x<=0; scan_y<=0;
            region_index<=0; roi_count<=0; roi_index<=0; output_offset<=0;
            src_x<=0; src_y<=0; dst_x<=0; dst_y<=0; x_remainder<=0; y_remainder<=0;
            roi_width<=0; roi_height<=0;
            for (k=0;k<MAX_REGIONS;k=k+1) begin
                boxes_x0[k]<=0; boxes_y0[k]<=0; boxes_x1[k]<=0; boxes_y1[k]<=0;
            end
        end else begin
            source_release_valid<=0;
            if (clear_errors) begin error<=0; error_code<=0; end
            if (result_valid && result_ready) begin
                result_valid<=0;
                bank_owned[result_bank]<=1;
            end
            if (roi_release_valid) begin
                if (bank_ready_mask[roi_release_bank] && bank_owned[roi_release_bank] &&
                    bank_frames[roi_release_bank]==roi_release_frame) begin
                    bank_ready_mask[roi_release_bank]<=0;
                    bank_owned[roi_release_bank]<=0;
                end else bad_releases<=bad_releases+1;
            end
            if (busy) cycle_count<=cycle_count+1;
            // 超时后不撤销任何 AXI VALID，不提前归还原图；等待事务排空。
            if (!axi_waiting || axi_progress) wait_count<=0;
            else if (wait_count >= TIMEOUT_CYCLES-1) begin
                wait_count<=0; report_error(ERR_TIMEOUT);
            end else wait_count<=wait_count+1;

            case (state)
                IDLE: if (start_allowed) begin
                    source_slot<=selected_source; output_bank<=selected_bank;
                    source_addr<=selected_source ? SOURCE1 : SOURCE0;
                    frame_token<=selected_source ? source_frame1 : source_frame0;
                    output_addr<=selected_bank ? OUTPUT1 : OUTPUT0;
                    frame_bad<=!config_valid; cycle_count<=0; cache_valid<=0;
                    out_width<=cfg_width; out_height<=cfg_height; colors_enabled<=cfg_colors;
                    bright_min<=cfg_bright_min; dominance<=cfg_dominance; black_max<=cfg_black_max;
                    min_pixels<=cfg_min_pixels; min_area<=cfg_min_area; max_area<=cfg_max_area;
                    min_fill<=cfg_min_fill; min_aspect<=cfg_min_aspect; max_aspect<=cfg_max_aspect;
                    margin<=cfg_margin;
                    scan_offset<=0; scan_pixels<=0; scan_lane<=0; scan_x<=0; scan_y<=0;
                    region_index<=0; roi_count<=0; roi_index<=0; result_boxes<=0; result_colors<=0;
                    read_address<=selected_source ? SOURCE1 : SOURCE0; read_return<=SCAN;
                    state<=config_valid ? AR : RELEASE;
                    if (!config_valid) report_error(ERR_CONFIG);
                end
                AR: if (axi_arready) state<=R;
                R: if (axi_rvalid) begin
                    if (axi_rid!=AXI_ID || axi_rresp!=0 || !axi_rlast) report_error(ERR_READ);
                    if (axi_rlast) begin
                        if (frame_bad || axi_rid!=AXI_ID || axi_rresp!=0) state<=RELEASE;
                        else begin
                            read_cache<=axi_rdata; cache_address<=read_address; cache_valid<=1;
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
                        end else scan_lane<=scan_lane+1;
                    end
                end
                FILTER: begin
                    if (region_overflow) begin report_error(ERR_REGIONS); state<=RELEASE; end
                    else if (region_query_index==MAX_REGIONS) begin
                        if (roi_count==0) state<=FINISH;
                        else begin roi_index<=0; state<=ROI_START; end
                    end else begin
                        if (region_accepted) begin
                            boxes_x0[append_index]<=rx0>margin ? rx0-margin : 16'd0;
                            boxes_y0[append_index]<=ry0>margin ? ry0-margin : 16'd0;
                            boxes_x1[append_index]<=({16'b0,rx1}+{16'b0,margin}<FRAME_WIDTH) ?
                                rx1+margin : LAST_X;
                            boxes_y1[append_index]<=({16'b0,ry1}+{16'b0,margin}<FRAME_HEIGHT) ?
                                ry1+margin : LAST_Y;
                            for(k=0;k<MAX_REGIONS;k=k+1)
                                if(roi_count32==k) result_colors[k*3 +: 3]<=region_color;
                            roi_count<=roi_count+1;
                        end
                        region_index<=region_index+1;
                    end
                end
                ROI_START: begin
                    src_x<=boxes_x0[crop_index]; src_y<=boxes_y0[crop_index];
                    dst_x<=0; dst_y<=0; x_remainder<=0; y_remainder<=0;
                    roi_width<=boxes_x1[crop_index]-boxes_x0[crop_index]+1;
                    roi_height<=boxes_y1[crop_index]-boxes_y0[crop_index]+1;
                    for(k=0;k<MAX_REGIONS;k=k+1)
                        if(roi_index32==k) result_boxes[k*64 +: 64]<={boxes_y1[crop_index],boxes_x1[crop_index],
                            boxes_y0[crop_index],boxes_x0[crop_index]};
                    output_offset<=0; pack_count<=0; write_pack<=0; state<=CROP;
                end
                CROP: begin
                    if (frame_bad) state<=RELEASE;
                    else if (!cache_valid || cache_address!=crop_beat_address) begin
                        read_address<=crop_beat_address; read_return<=CROP; state<=AR;
                    end else begin
                        write_pack[pack_count*16 +: 16]<=crop_pixel;
                        pack_count<=pack_count+1;
                        if (dst_x==out_width-1) begin
                            dst_x<=0; src_x<=boxes_x0[crop_index]; x_remainder<=0;
                            y_remainder<=y_remainder+{16'b0,roi_height};
                            dst_y<=dst_y+1;
                        end else begin
                            dst_x<=dst_x+1; x_remainder<=x_remainder+{16'b0,roi_width};
                        end
                        if (pack_count==15 || (dst_x==out_width-1 && dst_y==out_height-1)) begin
                            write_address<=output_addr+roi_index32*ROI_STRIDE_BYTES+output_offset;
                            write_return<=(dst_x==out_width-1 && dst_y==out_height-1) ? ROI_START :
                                (dst_x==out_width-1 ? STEP_Y : STEP_X);
                            state<=AW;
                        end else state<=dst_x==out_width-1 ? STEP_Y : STEP_X;
                    end
                end
                // 整数 DDA 实现 floor(dst*ROI_size/output_size)，不用可变除法器。
                STEP_X: if (x_remainder>={16'b0,out_width}) begin
                    x_remainder<=x_remainder-{16'b0,out_width}; src_x<=src_x+1;
                end else state<=CROP;
                STEP_Y: if (y_remainder>={16'b0,out_height}) begin
                    y_remainder<=y_remainder-{16'b0,out_height}; src_y<=src_y+1;
                end else state<=CROP;
                AW: if (axi_awready) state<=W;
                W: if (axi_wready) state<=B;
                B: if (axi_bvalid) begin
                    if (axi_bid!=AXI_ID || axi_bresp!=0) begin report_error(ERR_WRITE); state<=RELEASE; end
                    else if (frame_bad) state<=RELEASE;
                    else begin
                        pack_count<=0; write_pack<=0; output_offset<=output_offset+32;
                        if (write_return==ROI_START) begin
                            if (roi_index+1==roi_count) state<=FINISH;
                            else begin roi_index<=roi_index+1; state<=ROI_START; end
                        end else state<=write_return;
                    end
                end
                FINISH: begin
                    frames_processed<=frames_processed+1;
                    if (roi_count==0) empty_frames<=empty_frames+1;
                    else begin
                        bank_ready_mask[output_bank]<=1;
                        bank_frames[output_bank]<=frame_token;
                        result_valid<=1; result_bank<=output_bank; result_frame<=frame_token;
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
