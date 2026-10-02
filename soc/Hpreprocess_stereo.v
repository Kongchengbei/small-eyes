`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// 两路独立实例，只有 DDR 总线仲裁共用。所有接口均在 clk（DDR）域。
// NPU 尚未实现：调用方必须保留 valid/ready + bank/frame 归还握手。
module Hpreprocess_stereo #(
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer MAX_REGIONS = 8,
    parameter integer MAX_OUTPUT_SIZE = 128,
    parameter integer TIMEOUT_CYCLES = 1000000
) (
    input clk, input rst_n, input [1:0] enable, input ddr_ready,
    input [1:0] clear_errors,
    input [3:0] source_ready_mask, input [127:0] source_frames,
    output [1:0] source_release_valid, output [3:0] source_release_mask,
    input [31:0] cfg_width, input [31:0] cfg_height,
    input [7:0] cfg_colors,
    input [15:0] cfg_bright_min, input [15:0] cfg_dominance, input [15:0] cfg_black_max,
    input [63:0] cfg_min_pixels, input [63:0] cfg_min_area, input [63:0] cfg_max_area,
    input [15:0] cfg_min_fill,
    input [31:0] cfg_min_aspect, input [31:0] cfg_max_aspect, input [31:0] cfg_margin,
    output [1:0] result_valid, input [1:0] result_ready,
    output [15:0] result_camera, output [1:0] result_bank,
    output [63:0] result_frame, output [63:0] result_addr, output [63:0] result_count,
    output [31:0] result_width, output [31:0] result_height, output [63:0] result_stride,
    output [MAX_REGIONS*128-1:0] result_boxes,
    output [MAX_REGIONS*6-1:0] result_colors,
    input [1:0] roi_release_valid, input [1:0] roi_release_bank,
    input [63:0] roi_release_frame,
    output [3:0] bank_ready_mask, output [1:0] busy,
    output [63:0] frames_processed, output [63:0] empty_frames,
    output [63:0] failed_frames, output [63:0] bad_releases,
    output [1:0] error, output [63:0] error_code, output [63:0] last_cycles,
    output [29:0] axi_araddr,
    output [7:0] axi_arid,
    output [7:0] axi_arlen,
    output [2:0] axi_arsize,
    output [1:0] axi_arburst,
    output axi_arvalid,
    input axi_arready,
    input [255:0] axi_rdata,
    input [7:0] axi_rid,
    input [1:0] axi_rresp,
    input axi_rlast,
    input axi_rvalid,
    output axi_rready,
    output [29:0] axi_awaddr,
    output [7:0] axi_awid,
    output [7:0] axi_awlen,
    output [2:0] axi_awsize,
    output [1:0] axi_awburst,
    output axi_awvalid,
    input axi_awready,
    output [255:0] axi_wdata,
    output [31:0] axi_wstrb,
    output axi_wlast,
    output axi_wvalid,
    input axi_wready,
    input [7:0] axi_bid,
    input [1:0] axi_bresp,
    input axi_bvalid,
    output axi_bready
);
    wire [29:0] c0_araddr, c1_araddr;
    wire [59:0] lanes_araddr;
    assign {c1_araddr,c0_araddr} = lanes_araddr;
    wire [7:0] c0_arid, c1_arid;
    wire [15:0] lanes_arid;
    assign {c1_arid,c0_arid} = lanes_arid;
    wire [7:0] c0_arlen, c1_arlen;
    wire [15:0] lanes_arlen;
    assign {c1_arlen,c0_arlen} = lanes_arlen;
    wire [2:0] c0_arsize, c1_arsize;
    wire [5:0] lanes_arsize;
    assign {c1_arsize,c0_arsize} = lanes_arsize;
    wire [1:0] c0_arburst, c1_arburst;
    wire [3:0] lanes_arburst;
    assign {c1_arburst,c0_arburst} = lanes_arburst;
    wire c0_arvalid, c1_arvalid;
    wire [1:0] lanes_arvalid;
    assign {c1_arvalid,c0_arvalid} = lanes_arvalid;
    wire c0_arready, c1_arready;
    wire [255:0] c0_rdata, c1_rdata;
    wire [7:0] c0_rid, c1_rid;
    wire [1:0] c0_rresp, c1_rresp;
    wire c0_rlast, c1_rlast;
    wire c0_rvalid, c1_rvalid;
    wire c0_rready, c1_rready;
    wire [1:0] lanes_rready;
    assign {c1_rready,c0_rready} = lanes_rready;
    wire [29:0] c0_awaddr, c1_awaddr;
    wire [59:0] lanes_awaddr;
    assign {c1_awaddr,c0_awaddr} = lanes_awaddr;
    wire [7:0] c0_awid, c1_awid;
    wire [15:0] lanes_awid;
    assign {c1_awid,c0_awid} = lanes_awid;
    wire [7:0] c0_awlen, c1_awlen;
    wire [15:0] lanes_awlen;
    assign {c1_awlen,c0_awlen} = lanes_awlen;
    wire [2:0] c0_awsize, c1_awsize;
    wire [5:0] lanes_awsize;
    assign {c1_awsize,c0_awsize} = lanes_awsize;
    wire [1:0] c0_awburst, c1_awburst;
    wire [3:0] lanes_awburst;
    assign {c1_awburst,c0_awburst} = lanes_awburst;
    wire c0_awvalid, c1_awvalid;
    wire [1:0] lanes_awvalid;
    assign {c1_awvalid,c0_awvalid} = lanes_awvalid;
    wire c0_awready, c1_awready;
    wire [255:0] c0_wdata, c1_wdata;
    wire [511:0] lanes_wdata;
    assign {c1_wdata,c0_wdata} = lanes_wdata;
    wire [31:0] c0_wstrb, c1_wstrb;
    wire [63:0] lanes_wstrb;
    assign {c1_wstrb,c0_wstrb} = lanes_wstrb;
    wire c0_wlast, c1_wlast;
    wire [1:0] lanes_wlast;
    assign {c1_wlast,c0_wlast} = lanes_wlast;
    wire c0_wvalid, c1_wvalid;
    wire [1:0] lanes_wvalid;
    assign {c1_wvalid,c0_wvalid} = lanes_wvalid;
    wire c0_wready, c1_wready;
    wire [7:0] c0_bid, c1_bid;
    wire [1:0] c0_bresp, c1_bresp;
    wire c0_bvalid, c1_bvalid;
    wire c0_bready, c1_bready;
    wire [1:0] lanes_bready;
    assign {c1_bready,c0_bready} = lanes_bready;
    genvar c;
    generate for(c=0;c<2;c=c+1) begin : cameras
        Hcamera_preprocess #(
            .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES),
            .SOURCE0(c==0 ? `SOC_CAM1_BUFFER0_BASE : `SOC_CAM2_BUFFER0_BASE),
            .SOURCE1(c==0 ? `SOC_CAM1_BUFFER1_BASE : `SOC_CAM2_BUFFER1_BASE),
            .OUTPUT0(c==0 ? `SOC_PRE1_BANK0_BASE : `SOC_PRE2_BANK0_BASE),
            .OUTPUT1(c==0 ? `SOC_PRE1_BANK1_BASE : `SOC_PRE2_BANK1_BASE),
            .FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT),
            .MAX_REGIONS(MAX_REGIONS), .MAX_OUTPUT_SIZE(MAX_OUTPUT_SIZE),
            .TIMEOUT_CYCLES(TIMEOUT_CYCLES), .AXI_ID(c==0 ? 8'h50 : 8'h51),
            .CAMERA_ID(c==0 ? 8'd1 : 8'd2)
        ) u_preprocess (
            .clk(clk), .rst_n(rst_n), .enable(enable[c]), .ddr_ready(ddr_ready),
            .clear_errors(clear_errors[c]),
            .source_ready_mask(source_ready_mask[c*2 +: 2]),
            .source_frame0(source_frames[c*64 +: 32]), .source_frame1(source_frames[c*64+32 +: 32]),
            .source_release_valid(source_release_valid[c]),
            .source_release_mask(source_release_mask[c*2 +: 2]),
            .cfg_width(cfg_width[c*16 +: 16]), .cfg_height(cfg_height[c*16 +: 16]),
            .cfg_colors(cfg_colors[c*4 +: 4]),
            .cfg_bright_min(cfg_bright_min[c*8 +: 8]), .cfg_dominance(cfg_dominance[c*8 +: 8]),
            .cfg_black_max(cfg_black_max[c*8 +: 8]),
            .cfg_min_pixels(cfg_min_pixels[c*32 +: 32]),
            .cfg_min_area(cfg_min_area[c*32 +: 32]), .cfg_max_area(cfg_max_area[c*32 +: 32]),
            .cfg_min_fill(cfg_min_fill[c*8 +: 8]),
            .cfg_min_aspect(cfg_min_aspect[c*16 +: 16]), .cfg_max_aspect(cfg_max_aspect[c*16 +: 16]),
            .cfg_margin(cfg_margin[c*16 +: 16]),
            .result_valid(result_valid[c]), .result_ready(result_ready[c]),
            .result_camera(result_camera[c*8 +: 8]), .result_bank(result_bank[c]),
            .result_frame(result_frame[c*32 +: 32]), .result_addr(result_addr[c*32 +: 32]),
            .result_count(result_count[c*32 +: 32]),
            .result_width(result_width[c*16 +: 16]), .result_height(result_height[c*16 +: 16]),
            .result_stride(result_stride[c*32 +: 32]),
            .result_boxes(result_boxes[c*MAX_REGIONS*64 +: MAX_REGIONS*64]),
            .result_colors(result_colors[c*MAX_REGIONS*3 +: MAX_REGIONS*3]),
            .roi_release_valid(roi_release_valid[c]), .roi_release_bank(roi_release_bank[c]),
            .roi_release_frame(roi_release_frame[c*32 +: 32]),
            .bank_ready_mask(bank_ready_mask[c*2 +: 2]), .busy(busy[c]),
            .frames_processed(frames_processed[c*32 +: 32]),
            .empty_frames(empty_frames[c*32 +: 32]),
            .failed_frames(failed_frames[c*32 +: 32]), .bad_releases(bad_releases[c*32 +: 32]),
            .error(error[c]), .error_code(error_code[c*32 +: 32]), .last_cycles(last_cycles[c*32 +: 32]),
            .axi_araddr(lanes_araddr[c*30 +: 30]),
            .axi_arid(lanes_arid[c*8 +: 8]),
            .axi_arlen(lanes_arlen[c*8 +: 8]),
            .axi_arsize(lanes_arsize[c*3 +: 3]),
            .axi_arburst(lanes_arburst[c*2 +: 2]),
            .axi_arvalid(lanes_arvalid[c]),
            .axi_arready(c==0 ? c0_arready : c1_arready),
            .axi_rdata(c==0 ? c0_rdata : c1_rdata),
            .axi_rid(c==0 ? c0_rid : c1_rid),
            .axi_rresp(c==0 ? c0_rresp : c1_rresp),
            .axi_rlast(c==0 ? c0_rlast : c1_rlast),
            .axi_rvalid(c==0 ? c0_rvalid : c1_rvalid),
            .axi_rready(lanes_rready[c]),
            .axi_awaddr(lanes_awaddr[c*30 +: 30]),
            .axi_awid(lanes_awid[c*8 +: 8]),
            .axi_awlen(lanes_awlen[c*8 +: 8]),
            .axi_awsize(lanes_awsize[c*3 +: 3]),
            .axi_awburst(lanes_awburst[c*2 +: 2]),
            .axi_awvalid(lanes_awvalid[c]),
            .axi_awready(c==0 ? c0_awready : c1_awready),
            .axi_wdata(lanes_wdata[c*256 +: 256]),
            .axi_wstrb(lanes_wstrb[c*32 +: 32]),
            .axi_wlast(lanes_wlast[c]),
            .axi_wvalid(lanes_wvalid[c]),
            .axi_wready(c==0 ? c0_wready : c1_wready),
            .axi_bid(c==0 ? c0_bid : c1_bid),
            .axi_bresp(c==0 ? c0_bresp : c1_bresp),
            .axi_bvalid(c==0 ? c0_bvalid : c1_bvalid),
            .axi_bready(lanes_bready[c])
        );
    end endgenerate
    Haxi_2m1s_arbiter u_merge (.clk(clk), .rst_n(rst_n),
        .cpu_axi_araddr(c0_araddr),
        .cpu_axi_arid(c0_arid),
        .cpu_axi_arlen(c0_arlen),
        .cpu_axi_arsize(c0_arsize),
        .cpu_axi_arburst(c0_arburst),
        .cpu_axi_arvalid(c0_arvalid),
        .cpu_axi_arready(c0_arready),
        .cpu_axi_rdata(c0_rdata),
        .cpu_axi_rid(c0_rid),
        .cpu_axi_rresp(c0_rresp),
        .cpu_axi_rlast(c0_rlast),
        .cpu_axi_rvalid(c0_rvalid),
        .cpu_axi_rready(c0_rready),
        .cpu_axi_awaddr(c0_awaddr),
        .cpu_axi_awid(c0_awid),
        .cpu_axi_awlen(c0_awlen),
        .cpu_axi_awsize(c0_awsize),
        .cpu_axi_awburst(c0_awburst),
        .cpu_axi_awvalid(c0_awvalid),
        .cpu_axi_awready(c0_awready),
        .cpu_axi_wdata(c0_wdata),
        .cpu_axi_wstrb(c0_wstrb),
        .cpu_axi_wlast(c0_wlast),
        .cpu_axi_wvalid(c0_wvalid),
        .cpu_axi_wready(c0_wready),
        .cpu_axi_bid(c0_bid),
        .cpu_axi_bresp(c0_bresp),
        .cpu_axi_bvalid(c0_bvalid),
        .cpu_axi_bready(c0_bready),
        .npu_axi_araddr(c1_araddr),
        .npu_axi_arid(c1_arid),
        .npu_axi_arlen(c1_arlen),
        .npu_axi_arsize(c1_arsize),
        .npu_axi_arburst(c1_arburst),
        .npu_axi_arvalid(c1_arvalid),
        .npu_axi_arready(c1_arready),
        .npu_axi_rdata(c1_rdata),
        .npu_axi_rid(c1_rid),
        .npu_axi_rresp(c1_rresp),
        .npu_axi_rlast(c1_rlast),
        .npu_axi_rvalid(c1_rvalid),
        .npu_axi_rready(c1_rready),
        .npu_axi_awaddr(c1_awaddr),
        .npu_axi_awid(c1_awid),
        .npu_axi_awlen(c1_awlen),
        .npu_axi_awsize(c1_awsize),
        .npu_axi_awburst(c1_awburst),
        .npu_axi_awvalid(c1_awvalid),
        .npu_axi_awready(c1_awready),
        .npu_axi_wdata(c1_wdata),
        .npu_axi_wstrb(c1_wstrb),
        .npu_axi_wlast(c1_wlast),
        .npu_axi_wvalid(c1_wvalid),
        .npu_axi_wready(c1_wready),
        .npu_axi_bid(c1_bid),
        .npu_axi_bresp(c1_bresp),
        .npu_axi_bvalid(c1_bvalid),
        .npu_axi_bready(c1_bready),
        .ddr_axi_araddr(axi_araddr),
        .ddr_axi_arid(axi_arid),
        .ddr_axi_arlen(axi_arlen),
        .ddr_axi_arsize(axi_arsize),
        .ddr_axi_arburst(axi_arburst),
        .ddr_axi_arvalid(axi_arvalid),
        .ddr_axi_arready(axi_arready),
        .ddr_axi_rdata(axi_rdata),
        .ddr_axi_rid(axi_rid),
        .ddr_axi_rresp(axi_rresp),
        .ddr_axi_rlast(axi_rlast),
        .ddr_axi_rvalid(axi_rvalid),
        .ddr_axi_rready(axi_rready),
        .ddr_axi_awaddr(axi_awaddr),
        .ddr_axi_awid(axi_awid),
        .ddr_axi_awlen(axi_awlen),
        .ddr_axi_awsize(axi_awsize),
        .ddr_axi_awburst(axi_awburst),
        .ddr_axi_awvalid(axi_awvalid),
        .ddr_axi_awready(axi_awready),
        .ddr_axi_wdata(axi_wdata),
        .ddr_axi_wstrb(axi_wstrb),
        .ddr_axi_wlast(axi_wlast),
        .ddr_axi_wvalid(axi_wvalid),
        .ddr_axi_wready(axi_wready),
        .ddr_axi_bid(axi_bid),
        .ddr_axi_bresp(axi_bresp),
        .ddr_axi_bvalid(axi_bvalid),
        .ddr_axi_bready(axi_bready)
    );
endmodule
