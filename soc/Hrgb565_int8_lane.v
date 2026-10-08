`timescale 1ns / 1ps
`include "soc_addr_map.vh"

// One camera lane of the fixed 96x96 RGB565 -> [R,G,B,0] INT8 converter.
// Instantiate once per camera.  All state and AXI ports are in ddr_core_clk.
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
    localparam [3:0] ST_IDLE=0, ST_AR=1, ST_R=2, ST_AW=3,
        ST_W0=4, ST_W1=5, ST_B=6, ST_CLEAN=7, ST_DRAIN=8;
    localparam [31:0] RGB_BYTES = 32'd18432;

    reg [3:0] state;
    reg [1:0] slot_state [0:SLOT_COUNT-1]; // 0 free, 1 reserved, 2 delivered, 3 queued
    reg [31:0] slot_generation [0:SLOT_COUNT-1];
    reg [31:0] slot_frame [0:SLOT_COUNT-1];
    reg [31:0] batch_slot_addr [0:7];
    reg [5:0] batch_slot_index [0:7];

    reg [31:0] batch_frame_reg, batch_rgb_base, batch_rgb_stride;
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
    reg [31:0] free_count;
    reg [6:0] used_count_next;
    integer i, j, candidate;
    integer found_count;

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

    function [31:0] block_base;
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
            block_base=base+(({26'b0,slot} % 32'd14)*`SOC_INT8_SLOT_BYTES);
        end
    endfunction

    wire [63:0] desc_last_end = {32'b0,desc_rgb_base} +
        (({32'b0,desc_count}-64'd1) * {32'b0,desc_rgb_stride}) + {32'b0,RGB_BYTES};
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

    always @* begin
        free_count=0;
        for (i=0;i<SLOT_COUNT;i=i+1)
            if (slot_state[i]==0 && slot_generation[i]!=32'hffff_ffff)
                free_count=free_count+1'b1;
    end
    assign desc_ready = rst_n && enable && state==ST_IDLE && fifo_count==0 &&
        (desc_count>8 || !desc_geometry_ok || desc_count==0 || free_count>=desc_count);
    assign release_ready = rst_n;
    assign busy = state!=ST_IDLE || fifo_count!=0;
    assign wait_slot = enable && desc_valid && desc_geometry_ok && desc_count!=0 &&
        desc_count<=8 && state==ST_IDLE && free_count<desc_count;
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
    assign image_block = fifo_slot[fifo_rd_ptr]/14;
    assign image_position = fifo_slot[fifo_rd_ptr]%14;
    assign image_generation = fifo_generation[fifo_rd_ptr];
    assign image_data_addr = fifo_address[fifo_rd_ptr];
    assign image_width = 16'd96;
    assign image_height = 16'd96;
    assign image_data_bytes = `SOC_INT8_IMAGE_BYTES;

    reg [29:0] read_local_addr, write_local_addr;
    always @* begin
        read_local_addr = (batch_rgb_base + image_index_reg*batch_rgb_stride +
                           input_beat*32) - DDR_BASE;
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

    always @* begin
        used_count_next=0;
        for (i=0;i<SLOT_COUNT;i=i+1)
            if (slot_state[i]!=0) used_count_next=used_count_next+1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state<=ST_IDLE; batch_frame_reg<=0; batch_rgb_base<=0; batch_rgb_stride<=0;
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
                fifo_generation[fifo_wr_ptr]<=slot_generation[batch_slot_index[image_index_reg]];
                fifo_address[fifo_wr_ptr]<=batch_slot_addr[image_index_reg];
                fifo_box[fifo_wr_ptr]<=batch_boxes_reg[image_index_reg*64 +: 64];
                fifo_color[fifo_wr_ptr]<=batch_colors_reg[image_index_reg*3 +: 3];
                fifo_frame[fifo_wr_ptr]<=batch_frame_reg;
                fifo_batch_count[fifo_wr_ptr]<=batch_count_reg;
            end

            used_slots<={25'b0,used_count_next};
            if ({25'b0,used_count_next}>peak_slots) peak_slots<={25'b0,used_count_next};

            // A release is acknowledged every cycle. Only the exact live generation/frame
            // for a published slot changes occupancy; duplicates and stale messages stick.
            if (release_valid) begin
                candidate=({30'b0,release_block}*32'd14)+{28'b0,release_position};
                if (release_camera==(CAMERA ? 8'd2 : 8'd1) &&
                    release_position<4'd14 && candidate<SLOT_COUNT) begin
                    if (slot_state[candidate]==2 && slot_generation[candidate]==release_generation &&
                        slot_frame[candidate]==release_frame) slot_state[candidate]<=0;
                    else bad_release_count<=sat_inc(bad_release_count);
                end else begin
                    bad_release_count<=sat_inc(bad_release_count);
                end
            end

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
                    found_count=0;
                    for (j=0;j<SLOT_COUNT;j=j+1) begin
                        if (slot_state[j]==0 && slot_generation[j]!=32'hffff_ffff &&
                            found_count<desc_count) begin
                            slot_state[j]<=1;
                            slot_generation[j]<=slot_generation[j]+1'b1;
                            slot_frame[j]<=desc_frame;
                            batch_slot_addr[found_count]<=block_base(j[5:0]);
                            batch_slot_index[found_count]<=j[5:0];
                            found_count=found_count+1;
                        end
                    end
                    batch_frame_reg<=desc_frame; batch_bank_reg<=desc_rgb_bank;
                    batch_rgb_base<=desc_rgb_base; batch_rgb_stride<=desc_rgb_stride;
                    batch_count_reg<=desc_count; image_index_reg<=0;
                    batch_boxes_reg<=desc_boxes; batch_colors_reg<=desc_colors;
                    input_beat<=0; image_cycles<=0; batch_timer<=0; batch_failed<=0; watchdog<=0;
                    state<=ST_AR;
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
                        for (j=0;j<8;j=j+1)
                            if (j<batch_count_reg && slot_state[batch_slot_index[j]]==1 &&
                                !(pop_image && fifo_slot[fifo_rd_ptr]==batch_slot_index[j]))
                                slot_state[batch_slot_index[j]]<=0;
                        failed_batches<=sat_inc(failed_batches);
                        roi_release_valid<=1'b1; roi_release_bank<=batch_bank_reg;
                        roi_release_frame<=batch_frame_reg; state<=ST_IDLE;
                    end
                    default: state<=ST_IDLE;
                endcase
            end

            if (image_valid && !image_ready) handoff_wait_cycles<=sat_inc(handoff_wait_cycles);

            // Count normal waiting for space without treating it as an error.
            if (enable && desc_valid && desc_geometry_ok && desc_count!=0 && desc_count<=8 &&
                state==ST_IDLE &&
                free_count<desc_count) slot_wait_cycles<=sat_inc(slot_wait_cycles);
        end
    end
endmodule
