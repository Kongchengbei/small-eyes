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
    localparam integer SLOT_COUNT = 56;
    // ST_ALLOC 拆成三级：ST_ALLOC_G（选组）-> ST_ALLOC_L（组内选位）-> ST_ALLOC（写入）。
    // 每级只依赖寄存器，单级逻辑深度 ≤7 级；见下方 alloc_* 寄存器。
    localparam [3:0] ST_IDLE=0, ST_AR=1, ST_R=2, ST_AW=3,
        ST_W0=4, ST_W1=5, ST_B=6, ST_CLEAN=7, ST_DRAIN=8,
        ST_ALLOC=9, ST_ALLOC_G=10, ST_ALLOC_L=11;
    localparam [31:0] RGB_BYTES = 32'd18432;

    reg [3:0] state;
    reg [1:0] slot_state [0:SLOT_COUNT-1]; // 0 free, 1 reserved, 2 delivered, 3 queued
    reg [31:0] slot_generation [0:SLOT_COUNT-1];
    reg [31:0] slot_frame [0:SLOT_COUNT-1];
    reg [31:0] batch_slot_addr [0:7];
    reg [5:0] batch_slot_index [0:7];

    reg [31:0] batch_frame_reg, image_rgb_base, batch_rgb_stride;
    // One occupancy tag per accepted batch, shared by every slot taken from it.
    // (slot, generation) still identifies one occupancy uniquely, but the tag no
    // longer needs a 32-bit incrementer per slot: all slots of a batch load the
    // same value, so the whole array is just CE-controlled flops.
    reg [31:0] gen_epoch;
    // gen_epoch snapshot taken at accept time.  Every slot of a batch is loaded
    // with that same value in ST_ALLOC, and gen_epoch is only incremented when
    // the batch leaves ST_ALLOC, so this is bit-identical to
    // slot_generation[batch_slot_index[...]] but without a 56:1 32-bit mux.
    reg [31:0] batch_gen_epoch;
    reg [7:0] batch_count_reg, image_index_reg;
    reg batch_bank_reg;
    reg [511:0] batch_boxes_reg;
    reg [23:0] batch_colors_reg;
    reg [31:0] input_beat;
    reg [255:0] read_word;
    reg [511:0] converted_word;
    reg [31:0] image_cycles;
    reg [31:0] batch_timer;
    reg [31:0] watchdog;
    reg batch_failed;
    reg [2:0] fifo_wr_ptr, fifo_rd_ptr;
    reg [3:0] fifo_count;
    reg [7:0] fifo_index [0:7];
    reg [5:0] fifo_slot [0:7];
    reg [31:0] fifo_generation [0:7];
    reg [31:0] fifo_address [0:7];
    reg [63:0] fifo_box [0:7];
    reg [2:0] fifo_color [0:7];
    reg [31:0] fifo_frame [0:7];
    reg [7:0] fifo_batch_count [0:7];
    wire [5:0] free_count;
    // ---- 释放流水寄存器 ----
    // slot_state 有 5 个"变址写者"（释放/pop/push/ST_ALLOC/ST_CLEAN），且释放还要
    // 变址读 slot_state/slot_generation/slot_frame 再和消息比较。原来这几件事挤在
    // 同一拍，工具把整条锥串成 32 级、布线占比 74%，125MHz 下 slack −9.0ns。
    // 现在切成两拍：本拍只做"比较 + 寄存命中"，下一拍用 one-hot 命中写 slot_state，
    // 每个槽的写只依赖本地寄存位，不再经过 56 选 1 的优先级链。
    reg        rel_hit_q;
    reg [5:0]  rel_slot_q;
    integer i, j, rel_k;
    reg [55:0] alloc_free_mask;
    reg [2:0] alloc_position;
    // ---- 分配器三级扫描寄存器 ----
    // 原来的三级 56 位优先级链（组有效 -> 组首选 -> 组内掩码 -> 位首选 ->
    // 选中掩码）加写入合并全在一拍内，18 级逻辑、布线占 66%，125MHz 下
    // slack −4.5ns，而且是全设计最差路径。现在每一级只依赖寄存器：
    //   G: alloc_free_mask -> 组有效/组首选 -> alloc_gsel_q
    //   L: alloc_gsel_q 选字节 -> 组内最低空闲位 -> alloc_lsel_q
    //   W: 用寄存的 {alloc_gsel_q,alloc_lsel_q} 变址写入
    reg        alloc_gok_q;
    reg [2:0]  alloc_gsel_q;
    reg [2:0]  alloc_lsel_q;
    wire [5:0] alloc_sel_index = {alloc_gsel_q,alloc_lsel_q};
    wire [7:0] alloc_sel_group_mask;
    wire [7:0] alloc_sel_local_onehot;
    wire [2:0] alloc_sel_local_index;
    wire [31:0] alloc_sel_addr;
    // ---- ST_CLEAN 逐槽清理寄存器 ----
    // 原来一拍内对 batch_slot_index[0..7] 做 8 路并发"读-比较-写"56 项数组，
    // 起点还挂在 service 侧 image_ready 的组合链上。改成每拍清一个槽，
    // 命中结果寄存一拍再 one-hot 写回（和释放路径同一套打法）。
    reg        clean_hit_q;
    reg [5:0]  clean_slot_q;
    reg [3:0]  clean_index;
    wire [55:0] allocatable_mask;
    wire [6:0] alloc_group_valid;
    wire [6:0] alloc_group_first;
    wire [2:0] alloc_group_index;
    wire [27:0] alloc_group_count;
    wire [4:0] free_pair01 = {1'b0,alloc_group_count[3:0]} +
        {1'b0,alloc_group_count[7:4]};
    wire [4:0] free_pair23 = {1'b0,alloc_group_count[11:8]} +
        {1'b0,alloc_group_count[15:12]};
    wire [4:0] free_pair45 = {1'b0,alloc_group_count[19:16]} +
        {1'b0,alloc_group_count[23:20]};
    wire [5:0] free_pair0123 = {1'b0,free_pair01} + {1'b0,free_pair23};
    wire [5:0] free_pair456 = {1'b0,free_pair45} +
        {2'b0,alloc_group_count[27:24]};
    // Occupancy is the complement of the allocatable count: the former
    // 7x popcount8 + adder tree over slot_state is no longer built at all.
    // Every state==0 slot is allocatable in normal operation, so this is
    // bit-identical to counting slot_state!=0, with the same register lag.
    wire [5:0] used_count_next = 6'd56 - free_count;

    // 释放消息的解析（组合）。candidate 只有 6 位：block∈0..3、position∈0..13，
    // 3*14+13 = 55，不会溢出。命中判定只保留"活着的 generation/frame 完全一致"这一条，
    // 也就是原来的 snapshot 语义，只是结果改为寄存一拍再写回。
    wire [5:0] rel_candidate = {4'b0, release_block} * 6'd14 + {2'b0, release_position};
    wire release_hit = release_valid &&
        (release_camera == (CAMERA ? 8'd2 : 8'd1)) &&
        (release_position < 4'd14) && (rel_candidate < 6'd56) &&
        (slot_state[rel_candidate] == 2'd2) &&
        (slot_generation[rel_candidate] == release_generation) &&
        (slot_frame[rel_candidate] == release_frame);

    function [3:0] popcount8;
        input [7:0] value;
        reg [1:0] pair0, pair1, pair2, pair3;
        reg [2:0] half0, half1;
        begin
            pair0={1'b0,value[0]}+{1'b0,value[1]};
            pair1={1'b0,value[2]}+{1'b0,value[3]};
            pair2={1'b0,value[4]}+{1'b0,value[5]};
            pair3={1'b0,value[6]}+{1'b0,value[7]};
            half0={1'b0,pair0}+{1'b0,pair1};
            half1={1'b0,pair2}+{1'b0,pair3};
            popcount8={1'b0,half0}+{1'b0,half1};
        end
    endfunction

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
            rq=r8-8'd128; gq=g8-8'd128; bq=b8-8'd128;
            rgb565_to_int8x4={8'h00,bq,gq,rq};
        end
    endfunction

    // slot = 14*block + position, block in 0..3 and position in 0..13.
    // The block stride is 0x80000 and the within-block stride is 9 KiB, so the
    // address is a constant compare + shift + constant multiply.  Both the
    // address decode and the reported block/position use these helpers, so no
    // wide divider is inferred anywhere on the slot path.
    function [1:0] slot_block_of;
        input [5:0] slot;
        begin
            slot_block_of = (slot >= 6'd42) ? 2'd3 :
                            (slot >= 6'd28) ? 2'd2 :
                            (slot >= 6'd14) ? 2'd1 : 2'd0;
        end
    endfunction

    function [3:0] slot_position_of;
        input [5:0] slot;
        reg [1:0] block;
        reg [5:0] block14;
        begin
            block = slot_block_of(slot);
            // 14*block = (block<<3) + (block<<2) + (block<<1)
            block14 = {1'b0,block,3'b0} + {2'b0,block,2'b0} + {3'b0,block,1'b0};
            slot_position_of = slot - block14;
        end
    endfunction

    function [31:0] block_base;
        input [5:0] slot;
        reg [1:0] block;
        reg [5:0] position;
        begin
            block = slot_block_of(slot);
            position = {2'b0, slot_position_of(slot)};
            block_base = (CAMERA ? `SOC_INT8_CAM2_BLOCK0_BASE
                                 : `SOC_INT8_CAM1_BLOCK0_BASE) +
                         ({30'b0,block} << 19) +
                         (position * `SOC_INT8_SLOT_BYTES);
        end
    endfunction

    genvar alloc_gen;
    generate
        for (alloc_gen=0;alloc_gen<SLOT_COUNT;alloc_gen=alloc_gen+1) begin: gen_alloc_slot
            assign allocatable_mask[alloc_gen] =
                (slot_state[alloc_gen]==0) &&
                (slot_generation[alloc_gen]!=32'hffff_ffff) &&
                (gen_epoch!=32'hffff_ffff);
        end
        for (alloc_gen=0;alloc_gen<7;alloc_gen=alloc_gen+1) begin: gen_alloc_group
            assign alloc_group_valid[alloc_gen] =
                |alloc_free_mask[alloc_gen*8 +: 8];
            assign alloc_group_count[alloc_gen*4 +: 4] =
                popcount8(allocatable_mask[alloc_gen*8 +: 8]);
            if (alloc_gen==0) begin: gen_first_group
                assign alloc_group_first[alloc_gen] = alloc_group_valid[alloc_gen];
            end else begin: gen_later_group
                assign alloc_group_first[alloc_gen] = alloc_group_valid[alloc_gen] &&
                    !(|alloc_group_valid[alloc_gen-1:0]);
            end
        end
    endgenerate

    assign alloc_group_index={
        alloc_group_first[4] | alloc_group_first[5] | alloc_group_first[6],
        alloc_group_first[2] | alloc_group_first[3] | alloc_group_first[6],
        alloc_group_first[1] | alloc_group_first[3] | alloc_group_first[5]
    };
    // 组选中后只取该组的 8 位掩码，再取最低有效位，等价于原来的
    // alloc_local_mask/alloc_local_first/alloc_selected_mask 三级链。
    assign alloc_sel_group_mask = alloc_free_mask[{alloc_gsel_q,3'b000} +: 8];
    assign alloc_sel_local_onehot = alloc_sel_group_mask & (~alloc_sel_group_mask + 8'd1);
    assign alloc_sel_local_index={
        alloc_sel_local_onehot[4] | alloc_sel_local_onehot[5] |
        alloc_sel_local_onehot[6] | alloc_sel_local_onehot[7],
        alloc_sel_local_onehot[2] | alloc_sel_local_onehot[3] |
        alloc_sel_local_onehot[6] | alloc_sel_local_onehot[7],
        alloc_sel_local_onehot[1] | alloc_sel_local_onehot[3] |
        alloc_sel_local_onehot[5] | alloc_sel_local_onehot[7]
    };
    assign alloc_sel_addr=block_base(alloc_sel_index);
    assign free_count=free_pair0123+free_pair456;

    // SOC_PRE_ROI_STRIDE_BYTES == 32768 == 2^15.  desc_last_end 只在
    // desc_rgb_stride == 该常量时才被判定使用（见 desc_geometry_ok），所以这里的
    // 32x32->64 乘法退化成移位：省 4 个 APM 和一条 64 位加法链。
    wire [63:0] desc_last_end = {32'b0,desc_rgb_base} +
        (({32'b0,desc_count}-64'd1) << 15) + {32'b0,RGB_BYTES};
    wire [63:0] ddr_limit = {32'b0,DDR_BASE}+{32'b0,DDR_BYTES};
    wire [31:0] pre_bank0 = CAMERA ? `SOC_PRE2_BANK0_BASE : `SOC_PRE1_BANK0_BASE;
    wire [31:0] pre_bank1 = CAMERA ? `SOC_PRE2_BANK1_BASE : `SOC_PRE1_BANK1_BASE;
    wire [63:0] pre_bank0_end = {32'b0,pre_bank0}+{32'b0,`SOC_PRE_BANK_BYTES};
    wire [63:0] pre_bank1_end = {32'b0,pre_bank1}+{32'b0,`SOC_PRE_BANK_BYTES};
    wire source_bank_valid = desc_rgb_bank ?
        (desc_rgb_base>=pre_bank1 && desc_last_end<=pre_bank1_end) :
        (desc_rgb_base>=pre_bank0 && desc_last_end<=pre_bank0_end);
    wire desc_geometry_ok = (desc_camera == (CAMERA ? 8'd2 : 8'd1)) &&
        desc_width == 16'd96 && desc_height == 16'd96 && desc_count <= 8 &&
        (desc_count == 0 || (desc_rgb_stride == `SOC_PRE_ROI_STRIDE_BYTES &&
          desc_rgb_base[4:0]==0 && desc_rgb_base >= DDR_BASE &&
          desc_last_end <= ddr_limit && source_bank_valid));

    // desc_count 在上面的前置条件里已经被限定 <=8（>8 时直接短路判真），
    // 所以槽数比较只用低 4 位即可，没必要做 32 位宽比较。
    assign desc_ready = rst_n && enable && state==ST_IDLE && fifo_count==0 &&
        (desc_count>8 || !desc_geometry_ok || desc_count==0 ||
         free_count>=desc_count[3:0]);
    assign release_ready = rst_n;
    assign busy = state!=ST_IDLE || fifo_count!=0;
    assign wait_slot = enable && desc_valid && desc_geometry_ok && desc_count!=0 &&
        desc_count<=8 && state==ST_IDLE && free_count<desc_count[3:0];
    assign wait_ddr = (state==ST_AR && !axi_arready) ||
        (state==ST_R && !axi_rvalid) || (state==ST_AW && !axi_awready) ||
        ((state==ST_W0 || state==ST_W1) && !axi_wready) ||
        (state==ST_B && !axi_bvalid);
    assign wait_handoff = image_valid && !image_ready;
    assign image_valid = fifo_count!=0;
    assign image_camera = CAMERA ? 8'd2 : 8'd1;
    assign image_frame = fifo_frame[fifo_rd_ptr];
    assign image_batch_count = fifo_batch_count[fifo_rd_ptr];
    assign image_index = fifo_index[fifo_rd_ptr];
    assign image_box = fifo_box[fifo_rd_ptr];
    assign image_color = fifo_color[fifo_rd_ptr];
    assign image_block = slot_block_of(fifo_slot[fifo_rd_ptr]);
    assign image_position = slot_position_of(fifo_slot[fifo_rd_ptr]);
    assign image_generation = fifo_generation[fifo_rd_ptr];
    assign image_data_addr = fifo_address[fifo_rd_ptr];
    assign image_width = 16'd96;
    assign image_height = 16'd96;
    assign image_data_bytes = `SOC_INT8_IMAGE_BYTES;

    // The read base advances by one ROI stride per image, so the read address
    // never needs the previous 8x32 variable multiplier.
    reg [29:0] read_local_addr, write_local_addr;
    always @* begin
        read_local_addr = (image_rgb_base + input_beat*32) - DDR_BASE;
        write_local_addr = (batch_slot_addr[image_index_reg] + input_beat*64) - DDR_BASE;
    end
    assign axi_araddr = read_local_addr;
    assign axi_arid = AXI_ID;
    assign axi_arlen = 8'd0;
    assign axi_arsize = 3'd5;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = (state==ST_AR);
    assign axi_rready = (state==ST_R || state==ST_DRAIN);
    assign axi_awaddr = write_local_addr;
    assign axi_awid = AXI_ID;
    assign axi_awlen = 8'd1;
    assign axi_awsize = 3'd5;
    assign axi_awburst = 2'b01;
    assign axi_awvalid = (state==ST_AW);
    assign axi_wdata = state==ST_W0 ? converted_word[255:0] : converted_word[511:256];
    assign axi_wstrb = 32'hffff_ffff;
    assign axi_wlast = (state==ST_W1);
    assign axi_wvalid = (state==ST_W0 || state==ST_W1);
    assign axi_bready = (state==ST_B) && !(input_beat==575 && fifo_count==8);

    wire push_image = state==ST_B && axi_bvalid && axi_bready && axi_bid==AXI_ID &&
        axi_bresp==2'b00 && input_beat==575;
    wire pop_image = image_valid && image_ready;
    wire timeout_hit = (state!=ST_IDLE) && (image_cycles==TIMEOUT_CYCLES);

    always @* begin
        for (i=0;i<16;i=i+1)
            converted_word[i*32 +: 32]=rgb565_to_int8x4(read_word[i*16 +: 16]);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state<=ST_IDLE; batch_frame_reg<=0; image_rgb_base<=0; batch_rgb_stride<=0;
            batch_count_reg<=0; image_index_reg<=0; batch_bank_reg<=0;
            batch_boxes_reg<=0; batch_colors_reg<=0; input_beat<=0; read_word<=0;
            image_cycles<=0; watchdog<=0; batch_failed<=0;
            batch_timer<=0;
            fifo_wr_ptr<=0; fifo_rd_ptr<=0; fifo_count<=0;
            roi_release_valid<=0; roi_release_bank<=0; roi_release_frame<=0;
            error<=0; images_done<=0; batch_cycles<=0; slot_wait_cycles<=0;
            read_addr_wait_cycles<=0; read_data_wait_cycles<=0;
            write_addr_wait_cycles<=0; write_data_wait_cycles<=0;
            write_resp_wait_cycles<=0; handoff_wait_cycles<=0;
            used_slots<=0; peak_slots<=0; ddr_error_count<=0; bad_release_count<=0;
            failed_batches<=0; last_failure_frame<=0; last_failure_index<=0;
            last_failure_cause<=0;
            rel_hit_q<=1'b0; rel_slot_q<=6'd0;
            alloc_free_mask<=0; alloc_position<=0; gen_epoch<=32'd1;
            alloc_gok_q<=1'b0; alloc_gsel_q<=3'd0; alloc_lsel_q<=3'd0;
            clean_hit_q<=1'b0; clean_slot_q<=6'd0; clean_index<=4'd0;
            batch_gen_epoch<=32'd1;
            for (i=0;i<SLOT_COUNT;i=i+1) begin
                slot_state[i]<=0; slot_generation[i]<=0; slot_frame[i]<=0;
            end
            for (i=0;i<8;i=i+1) begin batch_slot_addr[i]<=0; batch_slot_index[i]<=0; end
            for (i=0;i<8;i=i+1) begin
                fifo_index[i]<=0; fifo_slot[i]<=0; fifo_generation[i]<=0;
                fifo_address[i]<=0; fifo_box[i]<=0; fifo_color[i]<=0;
                fifo_frame[i]<=0; fifo_batch_count[i]<=0;
            end
        end else begin
            roi_release_valid<=0;
            if (clear_errors) error<=0;

            case ({push_image,pop_image})
                2'b10: fifo_count<=fifo_count+1'b1;
                2'b01: fifo_count<=fifo_count-1'b1;
                default: fifo_count<=fifo_count;
            endcase
            if (push_image) fifo_wr_ptr<=fifo_wr_ptr+1'b1;
            if (pop_image) fifo_rd_ptr<=fifo_rd_ptr+1'b1;
            if (pop_image) slot_state[fifo_slot[fifo_rd_ptr]]<=2;
            if (push_image) begin
                slot_state[batch_slot_index[image_index_reg]]<=3;
                images_done<=sat_inc(images_done);
                fifo_index[fifo_wr_ptr]<=image_index_reg;
                fifo_slot[fifo_wr_ptr]<=batch_slot_index[image_index_reg];
                fifo_generation[fifo_wr_ptr]<=batch_gen_epoch;
                fifo_address[fifo_wr_ptr]<=batch_slot_addr[image_index_reg];
                fifo_box[fifo_wr_ptr]<=batch_boxes_reg[image_index_reg*64 +: 64];
                fifo_color[fifo_wr_ptr]<=batch_colors_reg[image_index_reg*3 +: 3];
                fifo_frame[fifo_wr_ptr]<=batch_frame_reg;
                fifo_batch_count[fifo_wr_ptr]<=batch_count_reg;
            end

            used_slots<={26'b0,used_count_next};
            if ({26'b0,used_count_next}>peak_slots) peak_slots<={26'b0,used_count_next};

            // 释放两拍流水（逻辑与原来等价，只是晚 1 拍生效）：
            //   拍1：解析消息 + 变址读 + 比较，命中结果寄存；
            //   拍2：把寄存后的命中按 one-hot 写回 slot_state。
            // 仍然只有"活着的 generation/frame 完全一致"的已发布槽会被释放，
            // 重复消息与过期消息照旧只累加 bad_release_count。
            rel_hit_q  <= release_hit;
            rel_slot_q <= rel_candidate;
            if (release_valid && !release_hit) bad_release_count<=sat_inc(bad_release_count);
            for (rel_k=0;rel_k<SLOT_COUNT;rel_k=rel_k+1)
                if (rel_hit_q && rel_slot_q==rel_k[5:0]) slot_state[rel_k]<=2'd0;
            if (clean_hit_q) slot_state[clean_slot_q]<=2'd0;

            if (enable && state==ST_IDLE && desc_valid && desc_ready) begin
                if (!desc_geometry_ok) begin
                    error<=1'b1;
                    failed_batches<=sat_inc(failed_batches);
                    last_failure_frame<=desc_frame; last_failure_index<=8'hff;
                    last_failure_cause<=8'd1;
                    roi_release_valid<=1'b1; roi_release_bank<=desc_rgb_bank;
                    roi_release_frame<=desc_frame;
                end else if (desc_count==0) begin
                    roi_release_valid<=1'b1; roi_release_bank<=desc_rgb_bank;
                    roi_release_frame<=desc_frame;
                end else begin
                    alloc_free_mask<=allocatable_mask;
                    batch_gen_epoch<=gen_epoch;
                    alloc_position<=0;
                    batch_frame_reg<=desc_frame; batch_bank_reg<=desc_rgb_bank;
                    image_rgb_base<=desc_rgb_base; batch_rgb_stride<=desc_rgb_stride;
                    batch_count_reg<=desc_count[7:0]; image_index_reg<=0;
                    batch_boxes_reg<=desc_boxes; batch_colors_reg<=desc_colors;
                    input_beat<=0; image_cycles<=0; batch_timer<=0; batch_failed<=0; watchdog<=0;
                    state<=ST_ALLOC_G;
                end
            end else if (state!=ST_IDLE) begin
                image_cycles<=sat_inc(image_cycles);
                batch_timer<=sat_inc(batch_timer);
                if (image_cycles<TIMEOUT_CYCLES) watchdog<=watchdog+1'b1;
                if (timeout_hit) begin
                    error<=1'b1; batch_failed<=1'b1;
                    last_failure_frame<=batch_frame_reg;
                    last_failure_index<=image_index_reg;
                    last_failure_cause<=8'd4;
                end

                case (state)
                    ST_ALLOC_G: begin
                        alloc_gok_q<=|alloc_group_valid;
                        alloc_gsel_q<=alloc_group_index;
                        state<=ST_ALLOC_L;
                    end
                    ST_ALLOC_L: begin
                        alloc_lsel_q<=alloc_sel_local_index;
                        state<=ST_ALLOC;
                    end
                    ST_ALLOC: begin
                        if (alloc_gok_q) begin
                            slot_state[alloc_sel_index]<=2'd1;
                            slot_generation[alloc_sel_index]<=gen_epoch;
                            slot_frame[alloc_sel_index]<=batch_frame_reg;
                            alloc_free_mask<=alloc_free_mask & ~(56'd1<<alloc_sel_index);
                            case (alloc_position)
                                3'd0: begin
                                    batch_slot_index[0]<=alloc_sel_index;
                                    batch_slot_addr[0]<=alloc_sel_addr;
                                end
                                3'd1: begin
                                    batch_slot_index[1]<=alloc_sel_index;
                                    batch_slot_addr[1]<=alloc_sel_addr;
                                end
                                3'd2: begin
                                    batch_slot_index[2]<=alloc_sel_index;
                                    batch_slot_addr[2]<=alloc_sel_addr;
                                end
                                3'd3: begin
                                    batch_slot_index[3]<=alloc_sel_index;
                                    batch_slot_addr[3]<=alloc_sel_addr;
                                end
                                3'd4: begin
                                    batch_slot_index[4]<=alloc_sel_index;
                                    batch_slot_addr[4]<=alloc_sel_addr;
                                end
                                3'd5: begin
                                    batch_slot_index[5]<=alloc_sel_index;
                                    batch_slot_addr[5]<=alloc_sel_addr;
                                end
                                3'd6: begin
                                    batch_slot_index[6]<=alloc_sel_index;
                                    batch_slot_addr[6]<=alloc_sel_addr;
                                end
                                default: begin
                                    batch_slot_index[7]<=alloc_sel_index;
                                    batch_slot_addr[7]<=alloc_sel_addr;
                                end
                            endcase
                            if ({1'b0,alloc_position}+4'd1 >= batch_count_reg[3:0]) begin
                                gen_epoch<=gen_epoch+1'b1;
                                state<=ST_AR;
                            end else begin
                                alloc_position<=alloc_position+1'b1;
                                state<=ST_ALLOC_G;
                            end
                        end else begin
                            error<=1'b1; batch_failed<=1'b1;
                            last_failure_frame<=batch_frame_reg;
                            last_failure_index<={5'b0,alloc_position};
                            last_failure_cause<=8'd5;
                            batch_count_reg<={5'b0,alloc_position};
                            gen_epoch<=gen_epoch+1'b1;
                            clean_index<=4'd0; clean_hit_q<=1'b0;
                            state<=ST_CLEAN;
                        end
                    end
                    ST_AR: begin
                        if (axi_arvalid && axi_arready) begin state<=ST_R; watchdog<=0; end
                        else read_addr_wait_cycles<=sat_inc(read_addr_wait_cycles);
                    end
                    ST_R: begin
                        if (axi_rvalid && axi_rready) begin
                            read_word<=axi_rdata;
                            if (axi_rid!=AXI_ID || axi_rresp!=2'b00 || !axi_rlast) begin
                                error<=1'b1; ddr_error_count<=sat_inc(ddr_error_count);
                                batch_failed<=1'b1;
                                last_failure_frame<=batch_frame_reg;
                                last_failure_index<=image_index_reg;
                                last_failure_cause<=8'd2;
                                if (axi_rlast) state<=ST_CLEAN;
                                else state<=ST_DRAIN;
                            end else state<=ST_AW;
                            watchdog<=0;
                        end else read_data_wait_cycles<=sat_inc(read_data_wait_cycles);
                    end
                    ST_AW: begin
                        if (axi_awvalid && axi_awready) begin state<=ST_W0; watchdog<=0; end
                        else write_addr_wait_cycles<=sat_inc(write_addr_wait_cycles);
                    end
                    ST_W0: begin
                        if (axi_wvalid && axi_wready) begin state<=ST_W1; watchdog<=0; end
                        else write_data_wait_cycles<=sat_inc(write_data_wait_cycles);
                    end
                    ST_W1: begin
                        if (axi_wvalid && axi_wready) begin state<=ST_B; watchdog<=0; end
                        else write_data_wait_cycles<=sat_inc(write_data_wait_cycles);
                    end
                    ST_B: begin
                        if (axi_bvalid && axi_bready) begin
                            if (axi_bid!=AXI_ID) begin
                                error<=1'b1; ddr_error_count<=sat_inc(ddr_error_count);
                                batch_failed<=1'b1; state<=ST_CLEAN;
                                last_failure_frame<=batch_frame_reg;
                                last_failure_index<=image_index_reg;
                                last_failure_cause<=8'd3;
                            end else if (axi_bresp!=2'b00) begin
                                error<=1'b1; ddr_error_count<=sat_inc(ddr_error_count);
                                batch_failed<=1'b1; state<=ST_CLEAN;
                                last_failure_frame<=batch_frame_reg;
                                last_failure_index<=image_index_reg;
                                last_failure_cause<=8'd3;
                            end else if (batch_failed || timeout_hit) begin
                                watchdog<=0; state<=ST_CLEAN;
                            end else begin
                                watchdog<=0;
                                if (input_beat==575) begin
                                    if (image_index_reg+1==batch_count_reg) begin
                                        batch_cycles<=batch_timer;
                                        roi_release_valid<=1'b1;
                                        roi_release_bank<=batch_bank_reg;
                                        roi_release_frame<=batch_frame_reg;
                                        state<=ST_IDLE;
                                    end else begin
                                        image_index_reg<=image_index_reg+1'b1;
                                        image_rgb_base<=image_rgb_base+batch_rgb_stride;
                                        input_beat<=0; image_cycles<=0; state<=ST_AR;
                                    end
                                end else begin
                                    input_beat<=input_beat+1'b1;
                                    state<=ST_AR;
                                end
                            end
                        end else write_resp_wait_cycles<=sat_inc(write_resp_wait_cycles);
                    end
                    ST_DRAIN: begin
                        if (axi_rvalid && axi_rready && axi_rlast) state<=ST_CLEAN;
                    end
                    ST_CLEAN: begin
                        // This lane has one transaction in flight at most. Reaching CLEAN
                        // follows the matching RLAST or B response, so unhanded slots are safe.
                        // 逐槽清理：一拍只处理一个槽，命中结果寄存一拍后 one-hot 写回。
                        // 原来一拍做 8 路并发"变址读-比较-写"，是 18 级 / 布线 66% 的主因。
                        // 原条件里的 !(pop_image && ...) 是冗余的：FIFO 中的槽已是状态 3，
                        // 或已弹出为状态 2，下面的 ==1 判断已经把这两种情况排除。
                        if (clean_index<batch_count_reg) begin
                            clean_slot_q<=batch_slot_index[clean_index];
                            clean_hit_q<=(slot_state[batch_slot_index[clean_index]]==2'd1);
                            clean_index<=clean_index+1'b1;
                        end else begin
                            clean_index<=4'd0; clean_hit_q<=1'b0;
                            failed_batches<=sat_inc(failed_batches);
                            roi_release_valid<=1'b1; roi_release_bank<=batch_bank_reg;
                            roi_release_frame<=batch_frame_reg; state<=ST_IDLE;
                        end
                    end
                    default: state<=ST_IDLE;
                endcase
            end

            if (image_valid && !image_ready) handoff_wait_cycles<=sat_inc(handoff_wait_cycles);

            // Count normal waiting for space without treating it as an error.
            if (enable && desc_valid && desc_geometry_ok && desc_count!=0 && desc_count<=8 &&
                state==ST_IDLE &&
                {26'b0,free_count}<desc_count) slot_wait_cycles<=sat_inc(slot_wait_cycles);
        end
    end
endmodule
