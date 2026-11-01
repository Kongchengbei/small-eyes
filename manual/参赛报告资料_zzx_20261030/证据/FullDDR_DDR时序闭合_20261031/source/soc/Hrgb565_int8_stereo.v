`timescale 1ns / 1ps
`include "soc_addr_map.vh"

//实例化两个独立的转换 lane，各自维护槽位和完成队列
module Hrgb565_int8_stereo #(
    parameter [31:0] DDR_BASE=`SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES=`SOC_DDR_BYTES
) (
    input clk, input rst_n, input enable, input clear_errors,
    input [1:0] desc_valid, output [1:0] desc_ready,
    input [15:0] desc_camera, input [63:0] desc_frame,
    input [1:0] desc_rgb_bank, input [63:0] desc_rgb_base,
    input [63:0] desc_count, input [31:0] desc_width, input [31:0] desc_height,
    input [63:0] desc_rgb_stride, input [1023:0] desc_boxes,
    input [47:0] desc_colors,
    output [1:0] roi_release_valid, output [1:0] roi_release_bank,
    output [63:0] roi_release_frame,

    output [1:0] image_valid, input [1:0] image_ready,
    output [15:0] image_camera, output [63:0] image_frame,
    output [15:0] image_batch_count, output [15:0] image_index,
    output [127:0] image_box, output [5:0] image_color,
    output [3:0] image_block, output [7:0] image_position,
    output [63:0] image_generation, output [63:0] image_data_addr,
    output [31:0] image_width, output [31:0] image_height,
    output [63:0] image_data_bytes,

    input [1:0] release_valid, output [1:0] release_ready,
    input [15:0] release_camera, input [63:0] release_frame,
    input [3:0] release_block, input [7:0] release_position,
    input [63:0] release_generation,

    output [1:0] busy, output [1:0] error,
    output [1:0] wait_slot, output [1:0] wait_ddr, output [1:0] wait_handoff,
    output [2*16*32-1:0] stats,

    output [59:0] axi_araddr, output [15:0] axi_arid,
    output [15:0] axi_arlen, output [5:0] axi_arsize,
    output [3:0] axi_arburst, output [1:0] axi_arvalid, input [1:0] axi_arready,
    input [511:0] axi_rdata, input [15:0] axi_rid, input [3:0] axi_rresp,
    input [1:0] axi_rlast, input [1:0] axi_rvalid, output [1:0] axi_rready,
    output [59:0] axi_awaddr, output [15:0] axi_awid,
    output [15:0] axi_awlen, output [5:0] axi_awsize,
    output [3:0] axi_awburst, output [1:0] axi_awvalid, input [1:0] axi_awready,
    output [511:0] axi_wdata, output [63:0] axi_wstrb,
    output [1:0] axi_wlast, output [1:0] axi_wvalid, input [1:0] axi_wready,
    input [15:0] axi_bid, input [3:0] axi_bresp,
    input [1:0] axi_bvalid, output [1:0] axi_bready
);
    wire [1:0] busy_lane, error_lane;
    assign busy=busy_lane; assign error=error_lane;
    genvar c;
    generate for (c=0;c<2;c=c+1) begin: lane
        wire [7:0] failed_index, failure_cause;
        assign stats[c*512+480+:32]={16'b0,failure_cause,failed_index};
        Hrgb565_int8_lane #(.CAMERA(c[0]),.DDR_BASE(DDR_BASE),.DDR_BYTES(DDR_BYTES)) u_lane (
            .clk(clk),.rst_n(rst_n),.enable(enable),.clear_errors(clear_errors),
            .desc_valid(desc_valid[c]),.desc_ready(desc_ready[c]),
            .desc_camera(desc_camera[c*8+:8]),.desc_frame(desc_frame[c*32+:32]),
            .desc_rgb_bank(desc_rgb_bank[c]),.desc_rgb_base(desc_rgb_base[c*32+:32]),
            .desc_count(desc_count[c*32+:32]),.desc_width(desc_width[c*16+:16]),
            .desc_height(desc_height[c*16+:16]),.desc_rgb_stride(desc_rgb_stride[c*32+:32]),
            .desc_boxes(desc_boxes[c*512+:512]),.desc_colors(desc_colors[c*24+:24]),
            .roi_release_valid(roi_release_valid[c]),.roi_release_bank(roi_release_bank[c]),
            .roi_release_frame(roi_release_frame[c*32+:32]),
            .image_valid(image_valid[c]),.image_ready(image_ready[c]),
            .image_camera(image_camera[c*8+:8]),.image_frame(image_frame[c*32+:32]),
            .image_batch_count(image_batch_count[c*8+:8]),.image_index(image_index[c*8+:8]),
            .image_box(image_box[c*64+:64]),.image_color(image_color[c*3+:3]),
            .image_block(image_block[c*2+:2]),.image_position(image_position[c*4+:4]),
            .image_generation(image_generation[c*32+:32]),.image_data_addr(image_data_addr[c*32+:32]),
            .image_width(image_width[c*16+:16]),.image_height(image_height[c*16+:16]),
            .image_data_bytes(image_data_bytes[c*32+:32]),
            .release_valid(release_valid[c]),.release_ready(release_ready[c]),
            .release_camera(release_camera[c*8+:8]),.release_frame(release_frame[c*32+:32]),
            .release_block(release_block[c*2+:2]),.release_position(release_position[c*4+:4]),
            .release_generation(release_generation[c*32+:32]),
            .busy(busy_lane[c]),.error(error_lane[c]),
            .wait_slot(wait_slot[c]),.wait_ddr(wait_ddr[c]),.wait_handoff(wait_handoff[c]),
            .images_done(stats[c*512+0+:32]),
            .batch_cycles(stats[c*512+32+:32]),
            .slot_wait_cycles(stats[c*512+64+:32]),
            .read_addr_wait_cycles(stats[c*512+96+:32]),
            .read_data_wait_cycles(stats[c*512+128+:32]),
            .write_addr_wait_cycles(stats[c*512+160+:32]),
            .write_data_wait_cycles(stats[c*512+192+:32]),
            .write_resp_wait_cycles(stats[c*512+224+:32]),
            .handoff_wait_cycles(stats[c*512+256+:32]),
            .used_slots(stats[c*512+288+:32]),.peak_slots(stats[c*512+320+:32]),
            .ddr_error_count(stats[c*512+352+:32]),
            .bad_release_count(stats[c*512+384+:32]),
            .failed_batches(stats[c*512+416+:32]),
            .last_failure_frame(stats[c*512+448+:32]),
            .last_failure_index(failed_index),.last_failure_cause(failure_cause),
            .axi_araddr(axi_araddr[c*30+:30]),.axi_arid(axi_arid[c*8+:8]),
            .axi_arlen(axi_arlen[c*8+:8]),.axi_arsize(axi_arsize[c*3+:3]),
            .axi_arburst(axi_arburst[c*2+:2]),.axi_arvalid(axi_arvalid[c]),
            .axi_arready(axi_arready[c]),.axi_rdata(axi_rdata[c*256+:256]),
            .axi_rid(axi_rid[c*8+:8]),.axi_rresp(axi_rresp[c*2+:2]),
            .axi_rlast(axi_rlast[c]),.axi_rvalid(axi_rvalid[c]),.axi_rready(axi_rready[c]),
            .axi_awaddr(axi_awaddr[c*30+:30]),.axi_awid(axi_awid[c*8+:8]),
            .axi_awlen(axi_awlen[c*8+:8]),.axi_awsize(axi_awsize[c*3+:3]),
            .axi_awburst(axi_awburst[c*2+:2]),.axi_awvalid(axi_awvalid[c]),
            .axi_awready(axi_awready[c]),.axi_wdata(axi_wdata[c*256+:256]),
            .axi_wstrb(axi_wstrb[c*32+:32]),.axi_wlast(axi_wlast[c]),
            .axi_wvalid(axi_wvalid[c]),.axi_wready(axi_wready[c]),
            .axi_bid(axi_bid[c*8+:8]),.axi_bresp(axi_bresp[c*2+:2]),
            .axi_bvalid(axi_bvalid[c]),.axi_bready(axi_bready[c])
        );
    end endgenerate
endmodule
