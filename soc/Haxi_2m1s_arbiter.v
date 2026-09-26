`timescale 1ns / 1ps

// ============================================================================
// Haxi_2m1s_arbiter
//
// DDR 时钟域内的两主一从 256-bit AXI4 仲裁器。CPU 与 NPU 的地址、数据和
// 响应字段均原样透传；模块只决定每个读 burst、写事务属于哪个上游。
// 读锁定至 RLAST 握手，写锁定从 AW 握手经 WLAST 至 B 握手，故不会把两个
// 主机的 W beat 或响应混在一起。读/写状态机完全独立，可交叉并发。
// ============================================================================
module Haxi_2m1s_arbiter (
    input clk,
    input rst_n,

    // CPU 上游 AXI4 master。
    input [29:0] cpu_axi_awaddr, input [7:0] cpu_axi_awid,
    input [7:0] cpu_axi_awlen, input [2:0] cpu_axi_awsize,
    input [1:0] cpu_axi_awburst, input cpu_axi_awvalid, output cpu_axi_awready,
    input [255:0] cpu_axi_wdata, input [31:0] cpu_axi_wstrb,
    input cpu_axi_wlast, input cpu_axi_wvalid, output cpu_axi_wready,
    output [7:0] cpu_axi_bid, output [1:0] cpu_axi_bresp,
    output cpu_axi_bvalid, input cpu_axi_bready,
    input [29:0] cpu_axi_araddr, input [7:0] cpu_axi_arid,
    input [7:0] cpu_axi_arlen, input [2:0] cpu_axi_arsize,
    input [1:0] cpu_axi_arburst, input cpu_axi_arvalid, output cpu_axi_arready,
    output [255:0] cpu_axi_rdata, output [7:0] cpu_axi_rid,
    output [1:0] cpu_axi_rresp, output cpu_axi_rlast,
    output cpu_axi_rvalid, input cpu_axi_rready,

    // NPU 上游 AXI4 master。
    input [29:0] npu_axi_awaddr, input [7:0] npu_axi_awid,
    input [7:0] npu_axi_awlen, input [2:0] npu_axi_awsize,
    input [1:0] npu_axi_awburst, input npu_axi_awvalid, output npu_axi_awready,
    input [255:0] npu_axi_wdata, input [31:0] npu_axi_wstrb,
    input npu_axi_wlast, input npu_axi_wvalid, output npu_axi_wready,
    output [7:0] npu_axi_bid, output [1:0] npu_axi_bresp,
    output npu_axi_bvalid, input npu_axi_bready,
    input [29:0] npu_axi_araddr, input [7:0] npu_axi_arid,
    input [7:0] npu_axi_arlen, input [2:0] npu_axi_arsize,
    input [1:0] npu_axi_arburst, input npu_axi_arvalid, output npu_axi_arready,
    output [255:0] npu_axi_rdata, output [7:0] npu_axi_rid,
    output [1:0] npu_axi_rresp, output npu_axi_rlast,
    output npu_axi_rvalid, input npu_axi_rready,

    // DDR IP 下游 AXI4 slave。
    output [29:0] ddr_axi_awaddr, output [7:0] ddr_axi_awid,
    output [7:0] ddr_axi_awlen, output [2:0] ddr_axi_awsize,
    output [1:0] ddr_axi_awburst, output ddr_axi_awvalid, input ddr_axi_awready,
    output [255:0] ddr_axi_wdata, output [31:0] ddr_axi_wstrb,
    output ddr_axi_wlast, output ddr_axi_wvalid, input ddr_axi_wready,
    input [7:0] ddr_axi_bid, input [1:0] ddr_axi_bresp,
    input ddr_axi_bvalid, output ddr_axi_bready,
    output [29:0] ddr_axi_araddr, output [7:0] ddr_axi_arid,
    output [7:0] ddr_axi_arlen, output [2:0] ddr_axi_arsize,
    output [1:0] ddr_axi_arburst, output ddr_axi_arvalid, input ddr_axi_arready,
    input [255:0] ddr_axi_rdata, input [7:0] ddr_axi_rid,
    input [1:0] ddr_axi_rresp, input ddr_axi_rlast,
    input ddr_axi_rvalid, output ddr_axi_rready
);

localparam OWNER_CPU = 1'b0;
localparam OWNER_NPU = 1'b1;
localparam WR_AW = 2'd0;
localparam WR_W  = 2'd1;
localparam WR_B  = 2'd2;

reg read_active;
reg read_addr_pending;
reg read_owner;
reg read_rr_next;
reg [29:0] read_addr;
reg [7:0] read_id;
reg [7:0] read_len;
reg [2:0] read_size;
reg [1:0] read_burst;
reg [1:0] write_state;
reg write_addr_pending;
reg write_owner;
reg write_rr_next;
reg [29:0] write_addr;
reg [7:0] write_id;
reg [7:0] write_len;
reg [2:0] write_size;
reg [1:0] write_burst;

// 空闲时的选择只依赖本轮优先级。首先将 Ax
// payload 寄存，再对下游握手，因而不会在 ARREADY/AWREADY stall
// 期间因另一个 master 开始请求而改变地址、ID 或 grant。
wire read_grant_npu = read_rr_next ? npu_axi_arvalid :
                      (!cpu_axi_arvalid && npu_axi_arvalid);
wire read_grant_cpu = !read_grant_npu && cpu_axi_arvalid;
wire write_grant_npu = write_rr_next ? npu_axi_awvalid :
                       (!cpu_axi_awvalid && npu_axi_awvalid);
wire write_grant_cpu = !write_grant_npu && cpu_axi_awvalid;

// 读地址通道：未锁定时先寄存仲裁结果；锁定后不再接收任何新的 AR。
assign ddr_axi_arvalid = read_addr_pending;
assign ddr_axi_araddr  = read_addr;
assign ddr_axi_arid    = read_id;
assign ddr_axi_arlen   = read_len;
assign ddr_axi_arsize  = read_size;
assign ddr_axi_arburst = read_burst;
assign cpu_axi_arready = read_addr_pending && (read_owner == OWNER_CPU) && ddr_axi_arready;
assign npu_axi_arready = read_addr_pending && (read_owner == OWNER_NPU) && ddr_axi_arready;

assign cpu_axi_rvalid = read_active && (read_owner == OWNER_CPU) && ddr_axi_rvalid;
assign npu_axi_rvalid = read_active && (read_owner == OWNER_NPU) && ddr_axi_rvalid;
assign cpu_axi_rdata  = ddr_axi_rdata;
assign npu_axi_rdata  = ddr_axi_rdata;
assign cpu_axi_rid    = ddr_axi_rid;
assign npu_axi_rid    = ddr_axi_rid;
assign cpu_axi_rresp  = ddr_axi_rresp;
assign npu_axi_rresp  = ddr_axi_rresp;
assign cpu_axi_rlast  = ddr_axi_rlast;
assign npu_axi_rlast  = ddr_axi_rlast;
assign ddr_axi_rready = read_active && ((read_owner == OWNER_CPU) ?
                        cpu_axi_rready : npu_axi_rready);

// 写地址、数据与响应：AW payload 寄存后才传给下游，确认后才允许
// 同一 owner 的 W，直至 B 完结。
assign ddr_axi_awvalid = (write_state == WR_AW) && write_addr_pending;
assign ddr_axi_awaddr  = write_addr;
assign ddr_axi_awid    = write_id;
assign ddr_axi_awlen   = write_len;
assign ddr_axi_awsize  = write_size;
assign ddr_axi_awburst = write_burst;
assign cpu_axi_awready = (write_state == WR_AW) && write_addr_pending &&
                         (write_owner == OWNER_CPU) && ddr_axi_awready;
assign npu_axi_awready = (write_state == WR_AW) && write_addr_pending &&
                         (write_owner == OWNER_NPU) && ddr_axi_awready;

assign ddr_axi_wvalid = (write_state == WR_W) && ((write_owner == OWNER_CPU) ?
                        cpu_axi_wvalid : npu_axi_wvalid);
assign ddr_axi_wdata  = (write_owner == OWNER_CPU) ? cpu_axi_wdata : npu_axi_wdata;
assign ddr_axi_wstrb  = (write_owner == OWNER_CPU) ? cpu_axi_wstrb : npu_axi_wstrb;
assign ddr_axi_wlast  = (write_owner == OWNER_CPU) ? cpu_axi_wlast : npu_axi_wlast;
assign cpu_axi_wready = (write_state == WR_W) && (write_owner == OWNER_CPU) && ddr_axi_wready;
assign npu_axi_wready = (write_state == WR_W) && (write_owner == OWNER_NPU) && ddr_axi_wready;

assign cpu_axi_bvalid = (write_state == WR_B) && (write_owner == OWNER_CPU) && ddr_axi_bvalid;
assign npu_axi_bvalid = (write_state == WR_B) && (write_owner == OWNER_NPU) && ddr_axi_bvalid;
assign cpu_axi_bid    = ddr_axi_bid;
assign npu_axi_bid    = ddr_axi_bid;
assign cpu_axi_bresp  = ddr_axi_bresp;
assign npu_axi_bresp  = ddr_axi_bresp;
assign ddr_axi_bready = (write_state == WR_B) && ((write_owner == OWNER_CPU) ?
                        cpu_axi_bready : npu_axi_bready);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_active <= 1'b0;
        read_addr_pending <= 1'b0;
        read_owner <= OWNER_CPU;
        read_rr_next <= OWNER_CPU;
        read_addr <= 30'b0;
        read_id <= 8'b0;
        read_len <= 8'b0;
        read_size <= 3'b0;
        read_burst <= 2'b0;
        write_state <= WR_AW;
        write_addr_pending <= 1'b0;
        write_owner <= OWNER_CPU;
        write_rr_next <= OWNER_CPU;
        write_addr <= 30'b0;
        write_id <= 8'b0;
        write_len <= 8'b0;
        write_size <= 3'b0;
        write_burst <= 2'b0;
    end else begin
        if (!read_active) begin
            if (!read_addr_pending && (read_grant_cpu || read_grant_npu)) begin
                read_addr_pending <= 1'b1;
                read_owner <= read_grant_npu ? OWNER_NPU : OWNER_CPU;
                read_addr <= read_grant_npu ? npu_axi_araddr : cpu_axi_araddr;
                read_id <= read_grant_npu ? npu_axi_arid : cpu_axi_arid;
                read_len <= read_grant_npu ? npu_axi_arlen : cpu_axi_arlen;
                read_size <= read_grant_npu ? npu_axi_arsize : cpu_axi_arsize;
                read_burst <= read_grant_npu ? npu_axi_arburst : cpu_axi_arburst;
            end else if (read_addr_pending && ddr_axi_arready) begin
                read_addr_pending <= 1'b0;
                read_active <= 1'b1;
                // 下一次同时竞争时让另一方优先。
                read_rr_next <= (read_owner == OWNER_NPU) ? OWNER_CPU : OWNER_NPU;
            end
        end else if (ddr_axi_rvalid && ddr_axi_rready && ddr_axi_rlast) begin
            read_active <= 1'b0;
        end

        case (write_state)
            WR_AW: begin
                if (!write_addr_pending && (write_grant_cpu || write_grant_npu)) begin
                    write_addr_pending <= 1'b1;
                    write_owner <= write_grant_npu ? OWNER_NPU : OWNER_CPU;
                    write_addr <= write_grant_npu ? npu_axi_awaddr : cpu_axi_awaddr;
                    write_id <= write_grant_npu ? npu_axi_awid : cpu_axi_awid;
                    write_len <= write_grant_npu ? npu_axi_awlen : cpu_axi_awlen;
                    write_size <= write_grant_npu ? npu_axi_awsize : cpu_axi_awsize;
                    write_burst <= write_grant_npu ? npu_axi_awburst : cpu_axi_awburst;
                end else if (write_addr_pending && ddr_axi_awready) begin
                    write_addr_pending <= 1'b0;
                    write_rr_next <= (write_owner == OWNER_NPU) ? OWNER_CPU : OWNER_NPU;
                    write_state <= WR_W;
                end
            end
            WR_W: begin
                if (ddr_axi_wvalid && ddr_axi_wready && ddr_axi_wlast)
                    write_state <= WR_B;
            end
            WR_B: begin
                if (ddr_axi_bvalid && ddr_axi_bready)
                    write_state <= WR_AW;
            end
            default: write_state <= WR_AW;
        endcase
    end
end

endmodule
