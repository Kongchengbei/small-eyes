`timescale 1ns / 1ps

//仲裁两路转换器与摄像头/前处理的 DDR 请求。它负责总线访问次序
module Hrgb565_int8_ddr_merge (
    input clk, input rst_n,
    input [29:0] cap_araddr, input [7:0] cap_arid, input [7:0] cap_arlen,
    input [2:0] cap_arsize, input [1:0] cap_arburst, input cap_arvalid, output cap_arready,
    output [255:0] cap_rdata, output [7:0] cap_rid, output [1:0] cap_rresp,
    output cap_rlast, output cap_rvalid, input cap_rready,
    input [29:0] cap_awaddr, input [7:0] cap_awid, input [7:0] cap_awlen,
    input [2:0] cap_awsize, input [1:0] cap_awburst, input cap_awvalid, output cap_awready,
    input [255:0] cap_wdata, input [31:0] cap_wstrb, input cap_wlast,
    input cap_wvalid, output cap_wready, output [7:0] cap_bid, output [1:0] cap_bresp,
    output cap_bvalid, input cap_bready,

    input [59:0] lane_araddr, input [15:0] lane_arid, input [15:0] lane_arlen,
    input [5:0] lane_arsize, input [3:0] lane_arburst, input [1:0] lane_arvalid,
    output [1:0] lane_arready, output [511:0] lane_rdata, output [15:0] lane_rid,
    output [3:0] lane_rresp, output [1:0] lane_rlast, output [1:0] lane_rvalid,
    input [1:0] lane_rready,
    input [59:0] lane_awaddr, input [15:0] lane_awid, input [15:0] lane_awlen,
    input [5:0] lane_awsize, input [3:0] lane_awburst, input [1:0] lane_awvalid,
    output [1:0] lane_awready, input [511:0] lane_wdata, input [63:0] lane_wstrb,
    input [1:0] lane_wlast, input [1:0] lane_wvalid, output [1:0] lane_wready,
    output [15:0] lane_bid, output [3:0] lane_bresp, output [1:0] lane_bvalid,
    input [1:0] lane_bready,

    output [29:0] out_araddr, output [7:0] out_arid, output [7:0] out_arlen,
    output [2:0] out_arsize, output [1:0] out_arburst, output out_arvalid, input out_arready,
    input [255:0] out_rdata, input [7:0] out_rid, input [1:0] out_rresp,
    input out_rlast, input out_rvalid, output out_rready,
    output [29:0] out_awaddr, output [7:0] out_awid, output [7:0] out_awlen,
    output [2:0] out_awsize, output [1:0] out_awburst, output out_awvalid, input out_awready,
    output [255:0] out_wdata, output [31:0] out_wstrb, output out_wlast,
    output out_wvalid, input out_wready, input [7:0] out_bid, input [1:0] out_bresp,
    input out_bvalid, output out_bready
);
    wire [29:0] int8_araddr, int8_awaddr;
    wire [7:0] int8_arid, int8_arlen, int8_awid, int8_awlen;
    wire [2:0] int8_arsize, int8_awsize;
    wire [1:0] int8_arburst, int8_awburst;
    wire int8_arvalid, int8_arready, int8_rlast, int8_rvalid, int8_rready;
    wire [255:0] int8_rdata;
    wire [7:0] int8_rid;
    wire [1:0] int8_rresp;
    wire int8_awvalid, int8_awready, int8_wlast, int8_wvalid, int8_wready;
    wire [255:0] int8_wdata;
    wire [31:0] int8_wstrb;
    wire [7:0] int8_bid;
    wire [1:0] int8_bresp;
    wire int8_bvalid, int8_bready;

    Haxi_2m1s_arbiter u_lane_merge (
        .clk(clk),.rst_n(rst_n),
        .cpu_axi_araddr(lane_araddr[29:0]),.cpu_axi_arid(lane_arid[7:0]),
        .cpu_axi_arlen(lane_arlen[7:0]),.cpu_axi_arsize(lane_arsize[2:0]),
        .cpu_axi_arburst(lane_arburst[1:0]),.cpu_axi_arvalid(lane_arvalid[0]),
        .cpu_axi_arready(lane_arready[0]),.cpu_axi_rdata(lane_rdata[255:0]),
        .cpu_axi_rid(lane_rid[7:0]),.cpu_axi_rresp(lane_rresp[1:0]),
        .cpu_axi_rlast(lane_rlast[0]),.cpu_axi_rvalid(lane_rvalid[0]),
        .cpu_axi_rready(lane_rready[0]),
        .cpu_axi_awaddr(lane_awaddr[29:0]),.cpu_axi_awid(lane_awid[7:0]),
        .cpu_axi_awlen(lane_awlen[7:0]),.cpu_axi_awsize(lane_awsize[2:0]),
        .cpu_axi_awburst(lane_awburst[1:0]),.cpu_axi_awvalid(lane_awvalid[0]),
        .cpu_axi_awready(lane_awready[0]),.cpu_axi_wdata(lane_wdata[255:0]),
        .cpu_axi_wstrb(lane_wstrb[31:0]),.cpu_axi_wlast(lane_wlast[0]),
        .cpu_axi_wvalid(lane_wvalid[0]),.cpu_axi_wready(lane_wready[0]),
        .cpu_axi_bid(lane_bid[7:0]),.cpu_axi_bresp(lane_bresp[1:0]),
        .cpu_axi_bvalid(lane_bvalid[0]),.cpu_axi_bready(lane_bready[0]),
        .npu_axi_araddr(lane_araddr[59:30]),.npu_axi_arid(lane_arid[15:8]),
        .npu_axi_arlen(lane_arlen[15:8]),.npu_axi_arsize(lane_arsize[5:3]),
        .npu_axi_arburst(lane_arburst[3:2]),.npu_axi_arvalid(lane_arvalid[1]),
        .npu_axi_arready(lane_arready[1]),.npu_axi_rdata(lane_rdata[511:256]),
        .npu_axi_rid(lane_rid[15:8]),.npu_axi_rresp(lane_rresp[3:2]),
        .npu_axi_rlast(lane_rlast[1]),.npu_axi_rvalid(lane_rvalid[1]),
        .npu_axi_rready(lane_rready[1]),
        .npu_axi_awaddr(lane_awaddr[59:30]),.npu_axi_awid(lane_awid[15:8]),
        .npu_axi_awlen(lane_awlen[15:8]),.npu_axi_awsize(lane_awsize[5:3]),
        .npu_axi_awburst(lane_awburst[3:2]),.npu_axi_awvalid(lane_awvalid[1]),
        .npu_axi_awready(lane_awready[1]),.npu_axi_wdata(lane_wdata[511:256]),
        .npu_axi_wstrb(lane_wstrb[63:32]),.npu_axi_wlast(lane_wlast[1]),
        .npu_axi_wvalid(lane_wvalid[1]),.npu_axi_wready(lane_wready[1]),
        .npu_axi_bid(lane_bid[15:8]),.npu_axi_bresp(lane_bresp[3:2]),
        .npu_axi_bvalid(lane_bvalid[1]),.npu_axi_bready(lane_bready[1]),
        .ddr_axi_araddr(int8_araddr),.ddr_axi_arid(int8_arid),.ddr_axi_arlen(int8_arlen),
        .ddr_axi_arsize(int8_arsize),.ddr_axi_arburst(int8_arburst),
        .ddr_axi_arvalid(int8_arvalid),.ddr_axi_arready(int8_arready),
        .ddr_axi_rdata(int8_rdata),.ddr_axi_rid(int8_rid),.ddr_axi_rresp(int8_rresp),
        .ddr_axi_rlast(int8_rlast),.ddr_axi_rvalid(int8_rvalid),.ddr_axi_rready(int8_rready),
        .ddr_axi_awaddr(int8_awaddr),.ddr_axi_awid(int8_awid),.ddr_axi_awlen(int8_awlen),
        .ddr_axi_awsize(int8_awsize),.ddr_axi_awburst(int8_awburst),
        .ddr_axi_awvalid(int8_awvalid),.ddr_axi_awready(int8_awready),
        .ddr_axi_wdata(int8_wdata),.ddr_axi_wstrb(int8_wstrb),.ddr_axi_wlast(int8_wlast),
        .ddr_axi_wvalid(int8_wvalid),.ddr_axi_wready(int8_wready),
        .ddr_axi_bid(int8_bid),.ddr_axi_bresp(int8_bresp),.ddr_axi_bvalid(int8_bvalid),
        .ddr_axi_bready(int8_bready)
    );

    Haxi_2m1s_arbiter u_capture_int8_merge (
        .clk(clk),.rst_n(rst_n),
        .cpu_axi_araddr(cap_araddr),.cpu_axi_arid(cap_arid),.cpu_axi_arlen(cap_arlen),
        .cpu_axi_arsize(cap_arsize),.cpu_axi_arburst(cap_arburst),.cpu_axi_arvalid(cap_arvalid),
        .cpu_axi_arready(cap_arready),.cpu_axi_rdata(cap_rdata),.cpu_axi_rid(cap_rid),
        .cpu_axi_rresp(cap_rresp),.cpu_axi_rlast(cap_rlast),.cpu_axi_rvalid(cap_rvalid),
        .cpu_axi_rready(cap_rready),.cpu_axi_awaddr(cap_awaddr),.cpu_axi_awid(cap_awid),
        .cpu_axi_awlen(cap_awlen),.cpu_axi_awsize(cap_awsize),.cpu_axi_awburst(cap_awburst),
        .cpu_axi_awvalid(cap_awvalid),.cpu_axi_awready(cap_awready),.cpu_axi_wdata(cap_wdata),
        .cpu_axi_wstrb(cap_wstrb),.cpu_axi_wlast(cap_wlast),.cpu_axi_wvalid(cap_wvalid),
        .cpu_axi_wready(cap_wready),.cpu_axi_bid(cap_bid),.cpu_axi_bresp(cap_bresp),
        .cpu_axi_bvalid(cap_bvalid),.cpu_axi_bready(cap_bready),
        .npu_axi_araddr(int8_araddr),.npu_axi_arid(int8_arid),.npu_axi_arlen(int8_arlen),
        .npu_axi_arsize(int8_arsize),.npu_axi_arburst(int8_arburst),
        .npu_axi_arvalid(int8_arvalid),.npu_axi_arready(int8_arready),
        .npu_axi_rdata(int8_rdata),.npu_axi_rid(int8_rid),.npu_axi_rresp(int8_rresp),
        .npu_axi_rlast(int8_rlast),.npu_axi_rvalid(int8_rvalid),.npu_axi_rready(int8_rready),
        .npu_axi_awaddr(int8_awaddr),.npu_axi_awid(int8_awid),.npu_axi_awlen(int8_awlen),
        .npu_axi_awsize(int8_awsize),.npu_axi_awburst(int8_awburst),
        .npu_axi_awvalid(int8_awvalid),.npu_axi_awready(int8_awready),
        .npu_axi_wdata(int8_wdata),.npu_axi_wstrb(int8_wstrb),.npu_axi_wlast(int8_wlast),
        .npu_axi_wvalid(int8_wvalid),.npu_axi_wready(int8_wready),.npu_axi_bid(int8_bid),
        .npu_axi_bresp(int8_bresp),.npu_axi_bvalid(int8_bvalid),.npu_axi_bready(int8_bready),
        .ddr_axi_araddr(out_araddr),.ddr_axi_arid(out_arid),.ddr_axi_arlen(out_arlen),
        .ddr_axi_arsize(out_arsize),.ddr_axi_arburst(out_arburst),.ddr_axi_arvalid(out_arvalid),
        .ddr_axi_arready(out_arready),.ddr_axi_rdata(out_rdata),.ddr_axi_rid(out_rid),
        .ddr_axi_rresp(out_rresp),.ddr_axi_rlast(out_rlast),.ddr_axi_rvalid(out_rvalid),
        .ddr_axi_rready(out_rready),.ddr_axi_awaddr(out_awaddr),.ddr_axi_awid(out_awid),
        .ddr_axi_awlen(out_awlen),.ddr_axi_awsize(out_awsize),.ddr_axi_awburst(out_awburst),
        .ddr_axi_awvalid(out_awvalid),.ddr_axi_awready(out_awready),.ddr_axi_wdata(out_wdata),
        .ddr_axi_wstrb(out_wstrb),.ddr_axi_wlast(out_wlast),.ddr_axi_wvalid(out_wvalid),
        .ddr_axi_wready(out_wready),.ddr_axi_bid(out_bid),.ddr_axi_bresp(out_bresp),
        .ddr_axi_bvalid(out_bvalid),.ddr_axi_bready(out_bready)
    );
endmodule
