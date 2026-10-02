`timescale 1ns / 1ps
// 两个自主控制器通过真实 AXI 仲裁并发读写；无 CPU 逐帧调度。
// golden resize 直接采用整数除法，与 RTL DDA 独立实现。
module tb_preprocess_stereo #(
    parameter integer W=20,
    parameter integer H=12,
    parameter [0:0] SOURCE_FROM_CAMERA=1'b0
);
    localparam integer N=8;
    reg clk=0; always #5 clk=~clk;
    reg rst_n=0, ddr_ready=1;
    reg [1:0] enable=3, clear_errors=0;
    reg [3:0] source_ready_mask=0;
    reg [127:0] source_frames=0;
    wire [3:0] camera_ready_mask;
    wire [127:0] camera_frames;
    reg pclk0=0,pclk1=0;
    wire [1:0] pclk={pclk1,pclk0};
    always #17 pclk0=~pclk0;
    always #19 pclk1=~pclk1;
    reg [1:0] vsync=3,href=0;
    reg [15:0] camera_data=0;
    reg camera_mmio_valid=0;
    reg [7:0] camera_mmio_addr=0;
    reg [31:0] camera_mmio_data=0;
    wire [1:0] source_release_valid;
    wire [3:0] source_release_mask;
    reg [31:0] cfg_width={16'd7,16'd7}, cfg_height={16'd5,16'd5};
    reg [7:0] cfg_colors=8'h77;
    reg [15:0] cfg_bright_min=16'h8080, cfg_dominance=16'h4040, cfg_black_max=16'h2020;
    reg [63:0] cfg_min_pixels={32'd4,32'd4}, cfg_min_area={32'd4,32'd4};
    reg [63:0] cfg_max_area={32'd240,32'd240};
    reg [15:0] cfg_min_fill=16'h8080;
    reg [31:0] cfg_min_aspect={16'd64,16'd64}, cfg_max_aspect={16'd1024,16'd1024};
    reg [31:0] cfg_margin=0;
    wire [1:0] result_valid;
    reg [1:0] result_ready=0;
    wire [15:0] result_camera;
    wire [1:0] result_bank;
    wire [63:0] result_frame,result_addr,result_count,result_stride;
    wire [31:0] result_width,result_height;
    wire [N*128-1:0] result_boxes;
    wire [N*6-1:0] result_colors;
    reg [1:0] roi_release_valid=0, roi_release_bank=0;
    reg [63:0] roi_release_frame=0;
    wire [3:0] bank_ready_mask;
    wire [1:0] busy,error;
    wire [63:0] frames_processed,empty_frames,failed_frames,bad_releases,error_code,last_cycles;
    wire [29:0] axi_araddr;
    wire [7:0] axi_arid;
    wire [7:0] axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid;
    reg axi_arready=0;
    reg [255:0] axi_rdata=0;
    reg [7:0] axi_rid=0;
    reg [1:0] axi_rresp=0;
    reg axi_rlast=0;
    reg axi_rvalid=0;
    wire axi_rready;
    wire [29:0] axi_awaddr;
    wire [7:0] axi_awid;
    wire [7:0] axi_awlen;
    wire [2:0] axi_awsize;
    wire [1:0] axi_awburst;
    wire axi_awvalid;
    reg axi_awready=0;
    wire [255:0] axi_wdata;
    wire [31:0] axi_wstrb;
    wire axi_wlast;
    wire axi_wvalid;
    reg axi_wready=0;
    reg [7:0] axi_bid=0;
    reg [1:0] axi_bresp=0;
    reg axi_bvalid=0;
    wire axi_bready;
    Hpreprocess_stereo #(.FRAME_WIDTH(W),.FRAME_HEIGHT(H),.TIMEOUT_CYCLES(200)) dut(
        .clk(clk),.rst_n(rst_n),.enable(enable),.ddr_ready(ddr_ready),.clear_errors(clear_errors),
        .source_ready_mask(SOURCE_FROM_CAMERA ? camera_ready_mask : source_ready_mask),
        .source_frames(SOURCE_FROM_CAMERA ? camera_frames : source_frames),
        .source_release_valid(source_release_valid),.source_release_mask(source_release_mask),
        .cfg_width(cfg_width),.cfg_height(cfg_height),.cfg_colors(cfg_colors),
        .cfg_bright_min(cfg_bright_min),.cfg_dominance(cfg_dominance),.cfg_black_max(cfg_black_max),
        .cfg_min_pixels(cfg_min_pixels),.cfg_min_area(cfg_min_area),.cfg_max_area(cfg_max_area),
        .cfg_min_fill(cfg_min_fill),.cfg_min_aspect(cfg_min_aspect),.cfg_max_aspect(cfg_max_aspect),
        .cfg_margin(cfg_margin),.result_valid(result_valid),.result_ready(result_ready),
        .result_camera(result_camera),.result_bank(result_bank),.result_frame(result_frame),
        .result_addr(result_addr),.result_count(result_count),.result_width(result_width),
        .result_height(result_height),.result_stride(result_stride),.result_boxes(result_boxes),
        .result_colors(result_colors),.roi_release_valid(roi_release_valid),
        .roi_release_bank(roi_release_bank),.roi_release_frame(roi_release_frame),
        .bank_ready_mask(bank_ready_mask),.busy(busy),.frames_processed(frames_processed),
        .empty_frames(empty_frames),.failed_frames(failed_frames),.bad_releases(bad_releases),
        .error(error),.error_code(error_code),.last_cycles(last_cycles),
        .axi_araddr(core_axi_araddr),
        .axi_arid(core_axi_arid),
        .axi_arlen(core_axi_arlen),
        .axi_arsize(core_axi_arsize),
        .axi_arburst(core_axi_arburst),
        .axi_arvalid(core_axi_arvalid),
        .axi_arready(core_axi_arready),
        .axi_rdata(core_axi_rdata),
        .axi_rid(core_axi_rid),
        .axi_rresp(core_axi_rresp),
        .axi_rlast(core_axi_rlast),
        .axi_rvalid(core_axi_rvalid),
        .axi_rready(core_axi_rready),
        .axi_awaddr(core_axi_awaddr),
        .axi_awid(core_axi_awid),
        .axi_awlen(core_axi_awlen),
        .axi_awsize(core_axi_awsize),
        .axi_awburst(core_axi_awburst),
        .axi_awvalid(core_axi_awvalid),
        .axi_awready(core_axi_awready),
        .axi_wdata(core_axi_wdata),
        .axi_wstrb(core_axi_wstrb),
        .axi_wlast(core_axi_wlast),
        .axi_wvalid(core_axi_wvalid),
        .axi_wready(core_axi_wready),
        .axi_bid(core_axi_bid),
        .axi_bresp(core_axi_bresp),
        .axi_bvalid(core_axi_bvalid),
        .axi_bready(core_axi_bready)
    );

    wire [29:0] core_axi_araddr,cam0_araddr,cam1_araddr,cam_axi_araddr;
    wire [7:0] core_axi_arid,cam0_arid,cam1_arid,cam_axi_arid;
    wire [7:0] core_axi_arlen,cam0_arlen,cam1_arlen,cam_axi_arlen;
    wire [2:0] core_axi_arsize,cam0_arsize,cam1_arsize,cam_axi_arsize;
    wire [1:0] core_axi_arburst,cam0_arburst,cam1_arburst,cam_axi_arburst;
    wire core_axi_arvalid,cam0_arvalid,cam1_arvalid,cam_axi_arvalid;
    wire core_axi_arready,cam0_arready,cam1_arready,cam_axi_arready;
    wire [255:0] core_axi_rdata,cam0_rdata,cam1_rdata,cam_axi_rdata;
    wire [7:0] core_axi_rid,cam0_rid,cam1_rid,cam_axi_rid;
    wire [1:0] core_axi_rresp,cam0_rresp,cam1_rresp,cam_axi_rresp;
    wire core_axi_rlast,cam0_rlast,cam1_rlast,cam_axi_rlast;
    wire core_axi_rvalid,cam0_rvalid,cam1_rvalid,cam_axi_rvalid;
    wire core_axi_rready,cam0_rready,cam1_rready,cam_axi_rready;
    wire [29:0] core_axi_awaddr,cam0_awaddr,cam1_awaddr,cam_axi_awaddr;
    wire [7:0] core_axi_awid,cam0_awid,cam1_awid,cam_axi_awid;
    wire [7:0] core_axi_awlen,cam0_awlen,cam1_awlen,cam_axi_awlen;
    wire [2:0] core_axi_awsize,cam0_awsize,cam1_awsize,cam_axi_awsize;
    wire [1:0] core_axi_awburst,cam0_awburst,cam1_awburst,cam_axi_awburst;
    wire core_axi_awvalid,cam0_awvalid,cam1_awvalid,cam_axi_awvalid;
    wire core_axi_awready,cam0_awready,cam1_awready,cam_axi_awready;
    wire [255:0] core_axi_wdata,cam0_wdata,cam1_wdata,cam_axi_wdata;
    wire [31:0] core_axi_wstrb,cam0_wstrb,cam1_wstrb,cam_axi_wstrb;
    wire core_axi_wlast,cam0_wlast,cam1_wlast,cam_axi_wlast;
    wire core_axi_wvalid,cam0_wvalid,cam1_wvalid,cam_axi_wvalid;
    wire core_axi_wready,cam0_wready,cam1_wready,cam_axi_wready;
    wire [7:0] core_axi_bid,cam0_bid,cam1_bid,cam_axi_bid;
    wire [1:0] core_axi_bresp,cam0_bresp,cam1_bresp,cam_axi_bresp;
    wire core_axi_bvalid,cam0_bvalid,cam1_bvalid,cam_axi_bvalid;
    wire core_axi_bready,cam0_bready,cam1_bready,cam_axi_bready;
    generate if(!SOURCE_FROM_CAMERA) begin : direct_source
        assign axi_araddr=core_axi_araddr;
        assign axi_arid=core_axi_arid;
        assign axi_arlen=core_axi_arlen;
        assign axi_arsize=core_axi_arsize;
        assign axi_arburst=core_axi_arburst;
        assign axi_arvalid=core_axi_arvalid;
        assign core_axi_arready=axi_arready;
        assign core_axi_rdata=axi_rdata;
        assign core_axi_rid=axi_rid;
        assign core_axi_rresp=axi_rresp;
        assign core_axi_rlast=axi_rlast;
        assign core_axi_rvalid=axi_rvalid;
        assign axi_rready=core_axi_rready;
        assign axi_awaddr=core_axi_awaddr;
        assign axi_awid=core_axi_awid;
        assign axi_awlen=core_axi_awlen;
        assign axi_awsize=core_axi_awsize;
        assign axi_awburst=core_axi_awburst;
        assign axi_awvalid=core_axi_awvalid;
        assign core_axi_awready=axi_awready;
        assign axi_wdata=core_axi_wdata;
        assign axi_wstrb=core_axi_wstrb;
        assign axi_wlast=core_axi_wlast;
        assign axi_wvalid=core_axi_wvalid;
        assign core_axi_wready=axi_wready;
        assign core_axi_bid=axi_bid;
        assign core_axi_bresp=axi_bresp;
        assign core_axi_bvalid=axi_bvalid;
        assign axi_bready=core_axi_bready;
        assign camera_ready_mask=0;assign camera_frames=0;
    end else begin : live_source
        Hcamera_subsystem #(.FRAME_WIDTH(W),.FRAME_HEIGHT(H),.FIFO_ADDR_WIDTH(6),
            .BUFFER0_ADDR(32'hb8000000),
            .BUFFER1_ADDR(32'hb8100000),
            .AXI_ID(8'h40),.HARDWARE_CONSUMER(1'b1)) camera0 (
            .cpu_clk(clk),.mem_clk(clk),.rst_n(rst_n),.ddr_ready(ddr_ready),
            .capture_enable(1'b1),.pclk(pclk[0]),.vsync(vsync[0]),.href(href[0]),
            .data(camera_data[0+:8]),
            .mmio_valid(camera_mmio_valid),.mmio_wen(1'b1),.mmio_addr(camera_mmio_addr),
            .mmio_wdata(camera_mmio_data),.mmio_wmask(4'hf),.mmio_rdata(),
            .consumer_ready_mask(camera_ready_mask[0+:2]),
            .consumer_frame0(camera_frames[0+:32]),.consumer_frame1(camera_frames[32+:32]),
            .consumer_release_valid(source_release_valid[0]),
            .consumer_release_mask(source_release_mask[0+:2]),
            .axi_awaddr(cam0_awaddr),
            .axi_awid(cam0_awid),
            .axi_awlen(cam0_awlen),
            .axi_awsize(cam0_awsize),
            .axi_awburst(cam0_awburst),
            .axi_awvalid(cam0_awvalid),
            .axi_awready(cam0_awready),
            .axi_wdata(cam0_wdata),
            .axi_wstrb(cam0_wstrb),
            .axi_wlast(cam0_wlast),
            .axi_wvalid(cam0_wvalid),
            .axi_wready(cam0_wready),
            .axi_bid(cam0_bid),
            .axi_bresp(cam0_bresp),
            .axi_bvalid(cam0_bvalid),
            .axi_bready(cam0_bready)
        );
        Hcamera_subsystem #(.FRAME_WIDTH(W),.FRAME_HEIGHT(H),.FIFO_ADDR_WIDTH(6),
            .BUFFER0_ADDR(32'hb8200000),
            .BUFFER1_ADDR(32'hb8300000),
            .AXI_ID(8'h41),.HARDWARE_CONSUMER(1'b1)) camera1 (
            .cpu_clk(clk),.mem_clk(clk),.rst_n(rst_n),.ddr_ready(ddr_ready),
            .capture_enable(1'b1),.pclk(pclk[1]),.vsync(vsync[1]),.href(href[1]),
            .data(camera_data[8+:8]),
            .mmio_valid(camera_mmio_valid),.mmio_wen(1'b1),.mmio_addr(camera_mmio_addr),
            .mmio_wdata(camera_mmio_data),.mmio_wmask(4'hf),.mmio_rdata(),
            .consumer_ready_mask(camera_ready_mask[2+:2]),
            .consumer_frame0(camera_frames[64+:32]),.consumer_frame1(camera_frames[96+:32]),
            .consumer_release_valid(source_release_valid[1]),
            .consumer_release_mask(source_release_mask[2+:2]),
            .axi_awaddr(cam1_awaddr),
            .axi_awid(cam1_awid),
            .axi_awlen(cam1_awlen),
            .axi_awsize(cam1_awsize),
            .axi_awburst(cam1_awburst),
            .axi_awvalid(cam1_awvalid),
            .axi_awready(cam1_awready),
            .axi_wdata(cam1_wdata),
            .axi_wstrb(cam1_wstrb),
            .axi_wlast(cam1_wlast),
            .axi_wvalid(cam1_wvalid),
            .axi_wready(cam1_wready),
            .axi_bid(cam1_bid),
            .axi_bresp(cam1_bresp),
            .axi_bvalid(cam1_bvalid),
            .axi_bready(cam1_bready)
        );
        Haxi_2m1s_arbiter capture_merge(.clk(clk),.rst_n(rst_n),
            .cpu_axi_araddr(30'b0),
            .cpu_axi_arid(8'b0),
            .cpu_axi_arlen(8'b0),
            .cpu_axi_arsize(3'b0),
            .cpu_axi_arburst(2'b0),
            .cpu_axi_arvalid(1'b0),
            .cpu_axi_arready(),
            .cpu_axi_rdata(),
            .cpu_axi_rid(),
            .cpu_axi_rresp(),
            .cpu_axi_rlast(),
            .cpu_axi_rvalid(),
            .cpu_axi_rready(1'b1),
            .cpu_axi_awaddr(cam0_awaddr),
            .cpu_axi_awid(cam0_awid),
            .cpu_axi_awlen(cam0_awlen),
            .cpu_axi_awsize(cam0_awsize),
            .cpu_axi_awburst(cam0_awburst),
            .cpu_axi_awvalid(cam0_awvalid),
            .cpu_axi_awready(cam0_awready),
            .cpu_axi_wdata(cam0_wdata),
            .cpu_axi_wstrb(cam0_wstrb),
            .cpu_axi_wlast(cam0_wlast),
            .cpu_axi_wvalid(cam0_wvalid),
            .cpu_axi_wready(cam0_wready),
            .cpu_axi_bid(cam0_bid),
            .cpu_axi_bresp(cam0_bresp),
            .cpu_axi_bvalid(cam0_bvalid),
            .cpu_axi_bready(cam0_bready),
            .npu_axi_araddr(30'b0),
            .npu_axi_arid(8'b0),
            .npu_axi_arlen(8'b0),
            .npu_axi_arsize(3'b0),
            .npu_axi_arburst(2'b0),
            .npu_axi_arvalid(1'b0),
            .npu_axi_arready(),
            .npu_axi_rdata(),
            .npu_axi_rid(),
            .npu_axi_rresp(),
            .npu_axi_rlast(),
            .npu_axi_rvalid(),
            .npu_axi_rready(1'b1),
            .npu_axi_awaddr(cam1_awaddr),
            .npu_axi_awid(cam1_awid),
            .npu_axi_awlen(cam1_awlen),
            .npu_axi_awsize(cam1_awsize),
            .npu_axi_awburst(cam1_awburst),
            .npu_axi_awvalid(cam1_awvalid),
            .npu_axi_awready(cam1_awready),
            .npu_axi_wdata(cam1_wdata),
            .npu_axi_wstrb(cam1_wstrb),
            .npu_axi_wlast(cam1_wlast),
            .npu_axi_wvalid(cam1_wvalid),
            .npu_axi_wready(cam1_wready),
            .npu_axi_bid(cam1_bid),
            .npu_axi_bresp(cam1_bresp),
            .npu_axi_bvalid(cam1_bvalid),
            .npu_axi_bready(cam1_bready),
            .ddr_axi_araddr(cam_axi_araddr),
            .ddr_axi_arid(cam_axi_arid),
            .ddr_axi_arlen(cam_axi_arlen),
            .ddr_axi_arsize(cam_axi_arsize),
            .ddr_axi_arburst(cam_axi_arburst),
            .ddr_axi_arvalid(cam_axi_arvalid),
            .ddr_axi_arready(cam_axi_arready),
            .ddr_axi_rdata(cam_axi_rdata),
            .ddr_axi_rid(cam_axi_rid),
            .ddr_axi_rresp(cam_axi_rresp),
            .ddr_axi_rlast(cam_axi_rlast),
            .ddr_axi_rvalid(cam_axi_rvalid),
            .ddr_axi_rready(cam_axi_rready),
            .ddr_axi_awaddr(cam_axi_awaddr),
            .ddr_axi_awid(cam_axi_awid),
            .ddr_axi_awlen(cam_axi_awlen),
            .ddr_axi_awsize(cam_axi_awsize),
            .ddr_axi_awburst(cam_axi_awburst),
            .ddr_axi_awvalid(cam_axi_awvalid),
            .ddr_axi_awready(cam_axi_awready),
            .ddr_axi_wdata(cam_axi_wdata),
            .ddr_axi_wstrb(cam_axi_wstrb),
            .ddr_axi_wlast(cam_axi_wlast),
            .ddr_axi_wvalid(cam_axi_wvalid),
            .ddr_axi_wready(cam_axi_wready),
            .ddr_axi_bid(cam_axi_bid),
            .ddr_axi_bresp(cam_axi_bresp),
            .ddr_axi_bvalid(cam_axi_bvalid),
            .ddr_axi_bready(cam_axi_bready)
        );
        Haxi_2m1s_arbiter preprocess_merge(.clk(clk),.rst_n(rst_n),
            .cpu_axi_araddr(cam_axi_araddr),
            .cpu_axi_arid(cam_axi_arid),
            .cpu_axi_arlen(cam_axi_arlen),
            .cpu_axi_arsize(cam_axi_arsize),
            .cpu_axi_arburst(cam_axi_arburst),
            .cpu_axi_arvalid(cam_axi_arvalid),
            .cpu_axi_arready(cam_axi_arready),
            .cpu_axi_rdata(cam_axi_rdata),
            .cpu_axi_rid(cam_axi_rid),
            .cpu_axi_rresp(cam_axi_rresp),
            .cpu_axi_rlast(cam_axi_rlast),
            .cpu_axi_rvalid(cam_axi_rvalid),
            .cpu_axi_rready(cam_axi_rready),
            .cpu_axi_awaddr(cam_axi_awaddr),
            .cpu_axi_awid(cam_axi_awid),
            .cpu_axi_awlen(cam_axi_awlen),
            .cpu_axi_awsize(cam_axi_awsize),
            .cpu_axi_awburst(cam_axi_awburst),
            .cpu_axi_awvalid(cam_axi_awvalid),
            .cpu_axi_awready(cam_axi_awready),
            .cpu_axi_wdata(cam_axi_wdata),
            .cpu_axi_wstrb(cam_axi_wstrb),
            .cpu_axi_wlast(cam_axi_wlast),
            .cpu_axi_wvalid(cam_axi_wvalid),
            .cpu_axi_wready(cam_axi_wready),
            .cpu_axi_bid(cam_axi_bid),
            .cpu_axi_bresp(cam_axi_bresp),
            .cpu_axi_bvalid(cam_axi_bvalid),
            .cpu_axi_bready(cam_axi_bready),
            .npu_axi_araddr(core_axi_araddr),
            .npu_axi_arid(core_axi_arid),
            .npu_axi_arlen(core_axi_arlen),
            .npu_axi_arsize(core_axi_arsize),
            .npu_axi_arburst(core_axi_arburst),
            .npu_axi_arvalid(core_axi_arvalid),
            .npu_axi_arready(core_axi_arready),
            .npu_axi_rdata(core_axi_rdata),
            .npu_axi_rid(core_axi_rid),
            .npu_axi_rresp(core_axi_rresp),
            .npu_axi_rlast(core_axi_rlast),
            .npu_axi_rvalid(core_axi_rvalid),
            .npu_axi_rready(core_axi_rready),
            .npu_axi_awaddr(core_axi_awaddr),
            .npu_axi_awid(core_axi_awid),
            .npu_axi_awlen(core_axi_awlen),
            .npu_axi_awsize(core_axi_awsize),
            .npu_axi_awburst(core_axi_awburst),
            .npu_axi_awvalid(core_axi_awvalid),
            .npu_axi_awready(core_axi_awready),
            .npu_axi_wdata(core_axi_wdata),
            .npu_axi_wstrb(core_axi_wstrb),
            .npu_axi_wlast(core_axi_wlast),
            .npu_axi_wvalid(core_axi_wvalid),
            .npu_axi_wready(core_axi_wready),
            .npu_axi_bid(core_axi_bid),
            .npu_axi_bresp(core_axi_bresp),
            .npu_axi_bvalid(core_axi_bvalid),
            .npu_axi_bready(core_axi_bready),
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
    end endgenerate
    reg [255:0] mem[0:262143]; // B8000000..B87fffff，八个 1 MiB 区间。
    integer tick=0, reads=0, writes=0;
    reg [29:0] write_address=0;
    reg [7:0] write_id=0;
    reg write_active=0;
    reg block_read=0, bad_read_once=0, bad_write_once=0;
    reg read_fault_used=0, write_fault_used=0;
    function automatic integer word_index(input [29:0] address);
        if(address<30'h38000000 || address>=30'h38800000 || address[4:0]!=0)
            $fatal(1,"address outside allocated slots: %h",address);
        return int'(({2'b0,address}-32'h38000000)>>5);
    endfunction
    // 所有 AXI 响应在握手前保持，分别给 AR/AW/W/R/B 施加等待。
    always @(posedge clk) begin
        if(!rst_n) begin
            tick<=0; reads<=0; writes<=0;
            axi_arready<=0; axi_awready<=0; axi_wready<=0;
            axi_rvalid<=0; axi_bvalid<=0; write_active<=0;
            read_fault_used<=0; write_fault_used<=0;
            source_ready_mask<=0;
        end else begin
            tick<=tick+1;
            axi_arready<=!block_read && !axi_rvalid && tick%5!=0;
            axi_awready<=!write_active && !axi_bvalid && tick%3!=0;
            axi_wready<=write_active && tick%4!=0;
            if(axi_rvalid && axi_rready) axi_rvalid<=0;
            if(axi_bvalid && axi_bready) axi_bvalid<=0;
            if(axi_arvalid && axi_arready) begin
                if(axi_arlen!=0 || axi_arsize!=5 || axi_arburst!=1)
                    $fatal(1,"unexpected read burst");
                reads<=reads+1; axi_rvalid<=1; axi_rlast<=1; axi_rid<=axi_arid;
                axi_rdata<=mem[word_index(axi_araddr)];
                axi_rresp<=(bad_read_once && !read_fault_used) ? 2 : 0;
                if(bad_read_once) read_fault_used<=1;
            end
            if(axi_awvalid && axi_awready) begin
                if(axi_awlen!=0 || axi_awsize!=5 || axi_awburst!=1)
                    $fatal(1,"unexpected write burst");
                write_active<=1; write_address<=axi_awaddr; write_id<=axi_awid;
            end
            if(axi_wvalid && axi_wready) begin
                if(!write_active || !axi_wlast) $fatal(1,"unowned write");
                for(integer j=0;j<32;j++)
                    if(axi_wstrb[j]) mem[word_index(write_address)][j*8+:8]<=axi_wdata[j*8+:8];
                writes<=writes+1; write_active<=0; axi_bvalid<=1; axi_bid<=write_id;
                axi_bresp<=(bad_write_once && !write_fault_used) ? 2 : 0;
                if(bad_write_once) write_fault_used<=1;
            end
            for(integer c=0;c<2;c++) if(source_release_valid[c]) begin
                if(source_release_mask[c*2+:2]!=1 && source_release_mask[c*2+:2]!=2)
                    $fatal(1,"non-exact source release");
                if(axi_rvalid || write_active || axi_bvalid) begin
                    // 对另一相机的事务不构成违规；本路状态已排空才会 release。
                    if((axi_rvalid && axi_rid==8'(80+c)) ||
                       (write_active && write_id==8'(80+c)) ||
                       (axi_bvalid && axi_bid==8'(80+c))) $fatal(1,"early source release");
                end
                source_ready_mask[c*2+:2]<=source_ready_mask[c*2+:2]&~source_release_mask[c*2+:2];
            end
        end
    end
    // 下游 AR/AW/W 负载在 VALID && !READY 期间必须稳定。
    reg ar_stall=0,aw_stall=0,w_stall=0;
    reg [29:0] prev_ar,prev_aw;
    reg [7:0] prev_arid,prev_awid;
    reg [255:0] prev_w;
    reg [31:0] prev_strb;
    always @(posedge clk) begin
        if(rst_n) begin
            if(ar_stall && (!axi_arvalid || axi_araddr!=prev_ar || axi_arid!=prev_arid))
                $fatal(1,"AR changed under backpressure");
            if(aw_stall && (!axi_awvalid || axi_awaddr!=prev_aw || axi_awid!=prev_awid))
                $fatal(1,"AW changed under backpressure");
            if(w_stall && (!axi_wvalid || axi_wdata!=prev_w || axi_wstrb!=prev_strb))
                $fatal(1,"W changed under backpressure");
        end
        ar_stall<=rst_n && axi_arvalid && !axi_arready;
        aw_stall<=rst_n && axi_awvalid && !axi_awready;
        w_stall<=rst_n && axi_wvalid && !axi_wready;
        prev_ar<=axi_araddr;prev_aw<=axi_awaddr;prev_arid<=axi_arid;prev_awid<=axi_awid;
        prev_w<=axi_wdata;prev_strb<=axi_wstrb;
    end
    function automatic [15:0] pattern(input integer cam,input integer x,input integer y);
        if(cam==0 && x>=2 && x<=7 && y>=1 && y<=5)
            return {5'(24+x%4),6'(y),5'd0};
        if(cam==1 && x>=2 && x<=5 && y>=2 && y<=5)
            return {5'd0,6'(y),5'(24+x%4)};
        if(cam==1 && x>=12 && x<=17 && y>=3 && y<=8)
            return {5'd31,6'd63,5'(x%4)};
        return 16'h8410; // 中性灰：不是红/黄/蓝。
    endfunction
    task automatic fill_frame(input integer cam,input integer slot,input bit blank);
        integer index;
        for(integer y=0;y<H;y++) for(integer x=0;x<W;x++) begin
            index=(cam*2+slot)*32768+(y*W+x)/16;
            mem[index][((y*W+x)%16)*16+:16]=blank ? 16'h8410 : pattern(cam,x,y);
        end
    endtask
    task automatic submit(input integer slot,input integer token0,input integer token1);
        @(negedge clk);
        if(source_ready_mask[slot] || source_ready_mask[slot+2]) $fatal(1,"overwrite owned source");
        source_frames[slot*32+:32]=32'(token0);
        source_frames[(slot+2)*32+:32]=32'(token1);
        source_ready_mask[slot]=1; source_ready_mask[slot+2]=1;
    endtask
    task automatic wait_results;
        integer timeout;
        timeout=0;
        while(result_valid!=3) begin
            @(negedge clk);
            timeout=timeout+1;
            if(timeout>W*H*8+30000) $fatal(1,"result timeout busy=%b error=%h",busy,error_code);
        end
    endtask
    integer expected_margin=0;
    task automatic check_result(input integer cam,input integer bank,input integer token,
        input integer outw,input integer outh);
        integer count,x0,x1,y0,y1,sx,sy,dst_base,idx,ex0,ex1,ey0,ey1;
        reg [15:0] actual,expected;
        reg [63:0] box;
        if(result_bank[cam]!=1'(bank) || result_frame[cam*32+:32]!=32'(token) ||
           result_width[cam*16+:16]!=16'(outw) || result_height[cam*16+:16]!=16'(outh) ||
           result_camera[cam*8+:8]!=8'(cam+1)) $fatal(1,"bad descriptor camera %0d",cam+1);
        count=int'(result_count[cam*32+:32]);
        if(count!=(cam==0?1:2)) $fatal(1,"bad region count %0d",count);
        for(integer r=0;r<count;r++) begin
            box=result_boxes[(cam*N+r)*64+:64];
            x0=int'(box[15:0]);y0=int'(box[31:16]);x1=int'(box[47:32]);y1=int'(box[63:48]);
            ex0=cam==0?2:(r==0?2:12); ex1=cam==0?7:(r==0?5:17);
            ey0=cam==0?1:(r==0?2:3); ey1=cam==0?5:(r==0?5:8);
            ex0=ex0>expected_margin?ex0-expected_margin:0;
            ey0=ey0>expected_margin?ey0-expected_margin:0;
            ex1=ex1+expected_margin<W?ex1+expected_margin:W-1;
            ey1=ey1+expected_margin<H?ey1+expected_margin:H-1;
            if(x0!=ex0 || x1!=ex1 || y0!=ey0 || y1!=ey1) $fatal(1,"candidate box=%h",box);
            if(result_colors[(cam*N+r)*3+:3]!=(cam==0?3'd1:(r==0?3'd3:3'd2)))
                $fatal(1,"wrong color");
            dst_base=int'(result_addr[cam*32+:32]-32'hb8000000)+r*32768;
            for(integer dy=0;dy<outh;dy++) for(integer dx=0;dx<outw;dx++) begin
                sx=x0+dx*(x1-x0+1)/outw;sy=y0+dy*(y1-y0+1)/outh;
                idx=(dst_base+(dy*outw+dx)*2)/32;
                actual=mem[idx][((dy*outw+dx)%16)*16+:16];
                expected=pattern(cam,sx,sy);
                if(actual!==expected) $fatal(1,"resize mismatch cam=%0d roi=%0d (%0d,%0d) %h != %h",
                    cam,r,dx,dy,actual,expected);
            end
            // 最后一拍的填充字节不能被 WSTRB 写坏。
            for(integer tail=outw*outh*2;tail<((outw*outh*2+31)/32)*32;tail++)
                if(mem[(dst_base+tail)/32][((dst_base+tail)%32)*8+:8]!==8'ha5)
                    $fatal(1,"partial beat guard overwritten");
        end
    endtask
    task automatic accept_results;
        @(negedge clk);result_ready=3;
        @(negedge clk);result_ready=0;
    endtask
    task automatic release_banks(input integer bank,input integer frame0,input integer frame1);
        @(negedge clk);roi_release_valid=3;roi_release_bank=bank!=0?3:0;
        roi_release_frame={32'(frame1),32'(frame0)};
        @(negedge clk);roi_release_valid=0;
    endtask
    task automatic reset_case;
        @(negedge clk);rst_n=0;result_ready=0;roi_release_valid=0;
        block_read=0;bad_read_once=0;bad_write_once=0;
        cfg_width={16'd7,16'd7};cfg_height={16'd5,16'd5};
        repeat(5) @(negedge clk);
        rst_n=1;
        for(integer j=131072;j<262144;j++) mem[j]={32{8'ha5}};
        fill_frame(0,0,0);fill_frame(1,0,0);
    endtask
    task automatic wait_sources_clear;
        integer timeout;
        timeout=0;
        while((SOURCE_FROM_CAMERA ? camera_ready_mask : source_ready_mask)!=0 || busy!=0) begin
            @(negedge clk);timeout=timeout+1;
            if(timeout>W*H*8+30000) $fatal(1,"source release timeout");
        end
    endtask
    integer saved_reads,saved_writes;
    generate if(SOURCE_FROM_CAMERA) begin : integration_watchdog
        initial begin
            #200000;
            $fatal(1,"camera watchdog busy=%b ready=%b DMA frames=%0d/%0d err=%0d/%0d pixels=%0d/%0d DVP=%0d/%0d enabled=%b/%b sync=%b/%b vsync=%b href=%b",busy,camera_ready_mask,
                live_source.camera0.dma_frame_count,live_source.camera1.dma_frame_count,
                live_source.camera0.dma_error_code,live_source.camera1.dma_error_code,
                live_source.camera0.dma_current_pixel_count,live_source.camera1.dma_current_pixel_count,
                live_source.camera0.u_dvp_rx.current_frame_pixels,live_source.camera1.u_dvp_rx.current_frame_pixels,
                live_source.camera0.dma_enable,live_source.camera1.dma_enable,
                live_source.camera0.u_dvp_rx.enable_sync,live_source.camera1.u_dvp_rx.enable_sync,vsync,href);
        end
    end endgenerate
    reg [N*128-1:0] held_boxes;
    task automatic camera_write(input [7:0] addr,input [31:0] value);
        @(negedge clk);camera_mmio_valid=1;camera_mmio_addr=addr;camera_mmio_data=value;
        @(negedge clk);camera_mmio_valid=0;
    endtask
    task automatic send_camera(input integer c);
        reg [15:0] pixel;
        @(negedge pclk[c]);vsync[c]=0;
        repeat(4) @(negedge pclk[c]);
        for(integer y=0;y<H;y++) begin
            href[c]=1;
            for(integer x=0;x<W;x++) begin
                pixel=pattern(c,x,y);
                camera_data[c*8+:8]=pixel[15:8];@(negedge pclk[c]);
                camera_data[c*8+:8]=pixel[7:0];@(negedge pclk[c]);
            end
            href[c]=0;camera_data[c*8+:8]=0;
            repeat(4) @(negedge pclk[c]);
        end
        vsync[c]=1;repeat(8) @(negedge pclk[c]);
    endtask
    initial begin
        reset_case();
        if(SOURCE_FROM_CAMERA) begin
            // Camera CPU/MMIO 域有复位释放同步器，必须等其退出复位再写控制。
            repeat(8) @(negedge clk);
            camera_write(8'h64,1);repeat(20) @(negedge clk);
            for(integer frame=1;frame<=3;frame++) begin
                fork
                    begin send_camera(0); end
                    begin send_camera(1); end
                    begin
                        wait(busy!=0);
                        // CPU 意外释放必须被 HARDWARE_CONSUMER 模式拒绝。
                        camera_write(8'h60,3);
                    end
                join
                wait_results();wait_sources_clear();
                check_result(0,0,frame,7,5);check_result(1,0,frame,7,5);
                if(error!=0) $fatal(1,"live Camera integration error %h",error_code);
                accept_results();release_banks(0,frame,frame);
            end
            if(frames_processed!={32'd3,32'd3}) $fatal(1,"live frame count");
            $display("PREPROCESS_CAMERA PASS two DVP/FIFO/DMA streams -> autonomous ROI -> DDR, no CPU releases");
            $finish;
        end
        if($test$plusargs("RAW_640X480")) begin
            cfg_width={16'd96,16'd96};cfg_height={16'd96,16'd96};
            submit(0,51,61);wait_results();wait_sources_clear();
            check_result(0,0,51,96,96);check_result(1,0,61,96,96);
            $display("RAW 640x480 SIM cycles CAM1=%0d CAM2=%0d; estimated at 70MHz=%0d/%0d us (not board timing)",
                last_cycles[31:0],last_cycles[63:32],
                last_cycles[31:0]/70,last_cycles[63:32]/70);
            $finish;
        end
        fill_frame(0,1,0);fill_frame(1,1,0);
        submit(0,11,21);
        wait(busy==3);
        @(negedge clk);cfg_width={16'd9,16'd9};cfg_height={16'd3,16'd3};
        wait_results();wait_sources_clear();
        check_result(0,0,11,7,5);check_result(1,0,21,7,5);
        held_boxes=result_boxes;
        repeat(50) @(negedge clk);
        if(result_valid!=3 || result_boxes!=held_boxes) $fatal(1,"descriptor not held");
        // 未取得描述符前禁止归还。
        release_banks(0,11,21);
        if(bank_ready_mask!=4'b0101 || bad_releases!={32'd1,32'd1}) $fatal(1,"early release accepted");
        accept_results();
        submit(1,12,22);wait_results();wait_sources_clear();
        check_result(0,1,12,9,3);check_result(1,1,22,9,3);accept_results();
        if(bank_ready_mask!=15) $fatal(1,"both banks not protected");
        submit(0,13,23);saved_reads=reads;saved_writes=writes;
        repeat(400) @(negedge clk);
        if(reads!=saved_reads || writes!=saved_writes || source_ready_mask!=5 || busy!=0)
            $fatal(1,"full bank overwrite or unauthorized source release");
        release_banks(0,999,999);
        if(bank_ready_mask!=15 || bad_releases!={32'd2,32'd2}) $fatal(1,"stale release accepted");
        // 恢复输出哨兵，只能写已由消费者归还的 bank。
        for(integer j=131072;j<163840;j++) mem[j]={32{8'ha5}};
        for(integer j=196608;j<229376;j++) mem[j]={32{8'ha5}};
        release_banks(0,11,21);
        wait_results();wait_sources_clear();
        check_result(0,0,13,9,3);check_result(1,0,23,9,3);
        if(error!=0) $fatal(1,"normal run error");
        $display("PASS dual parallel, all ROI pixels, DDA up/downsize, partial strobes, leases/config latch");
        reset_case();
        fill_frame(0,0,1);fill_frame(1,0,1);
        submit(0,31,41);wait_sources_clear();
        if(empty_frames!={32'd1,32'd1} || result_valid!=0 || writes!=0)
            $fatal(1,"empty frame handling");
        $display("PASS no candidates");

        reset_case();cfg_margin={16'd2,16'd2};expected_margin=2;
        submit(0,63,73);wait_results();wait_sources_clear();
        check_result(0,0,63,7,5);check_result(1,0,73,7,5);
        if(error!=0) $fatal(1,"margin crop error");
        $display("PASS margin crop and boundary clipping");
        cfg_margin=0;expected_margin=0;
        reset_case();cfg_width=0;
        submit(0,32,42);wait_sources_clear();
        if(failed_frames!={32'd1,32'd1} || reads!=0 || error_code!={32'd1,32'd1})
            $fatal(1,"bad config was not rejected");
        $display("PASS invalid dimensions before AXI");
        reset_case();bad_read_once=1;
        submit(0,33,43);wait_sources_clear();
        if(failed_frames[31:0]+failed_frames[63:32]!=1 || bank_ready_mask==5)
            $fatal(1,"read error published bad ROI");
        $display("PASS RRESP fault isolation");
        reset_case();bad_write_once=1;
        submit(0,34,44);wait_sources_clear();
        if(failed_frames[31:0]+failed_frames[63:32]!=1 || bank_ready_mask==5)
            $fatal(1,"write error published bad ROI");
        $display("PASS BRESP fault isolation");
        reset_case();block_read=1;
        submit(0,35,45);
        repeat(550) @(negedge clk);
        if(source_ready_mask!=5 || result_valid!=0 || error==0)
            $fatal(1,"timeout revoked source/failed to report");
        block_read=0;wait_sources_clear();
        if(failed_frames[31:0]+failed_frames[63:32]<1) $fatal(1,"timeout not drained");
        $display("PASS timeout keeps AXI and source ownership until drain");
        reset_case();
        fill_frame(0,0,1);fill_frame(1,0,1);
        for(integer c=0;c<2;c++) for(integer j=0;j<9;j++)
            mem[c*65536+((j/7)*3*W+(j%7)*3)/16][(((j/7)*3*W+(j%7)*3)%16)*16+:16]=16'hf800;
        submit(0,36,46);wait_sources_clear();
        if(error_code!={32'd5,32'd5} || result_valid!=0 || writes!=0)
            $fatal(1,"candidate overflow not fail-closed");
        $display("PASS region capacity overflow");
        $display("PREPROCESS_STEREO ALL PASS");$finish;
    end
    initial begin #100000000;$fatal(1,"global timeout");end
endmodule
