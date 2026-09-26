`timescale 1ns / 1ps

// 双主 AXI 仲裁器专用验证。两个上游在同一 ddr_clk 域由 TB 驱动，
// 下游从机以周期性 ready 和响应空拍模拟 DDR IP 的 backpressure。
module tb_axi_2m1s_arbiter;
reg clk, rst_n;
always #5 clk = ~clk;

// CPU/NPU 上游驱动信号；两侧 ready 均保持可接收响应。
reg [29:0] cpu_awaddr, npu_awaddr, cpu_araddr, npu_araddr;
reg [7:0] cpu_awid, npu_awid, cpu_arid, npu_arid;
reg [7:0] cpu_awlen, npu_awlen, cpu_arlen, npu_arlen;
reg [2:0] cpu_awsize, npu_awsize, cpu_arsize, npu_arsize;
reg [1:0] cpu_awburst, npu_awburst, cpu_arburst, npu_arburst;
reg cpu_awvalid, npu_awvalid, cpu_wvalid, npu_wvalid, cpu_arvalid, npu_arvalid;
reg [255:0] cpu_wdata, npu_wdata;
reg [31:0] cpu_wstrb, npu_wstrb;
reg cpu_wlast, npu_wlast;
reg cpu_bready, npu_bready, cpu_rready, npu_rready;
wire cpu_awready, npu_awready, cpu_wready, npu_wready, cpu_arready, npu_arready;
wire [7:0] cpu_bid, npu_bid, cpu_rid, npu_rid;
wire [1:0] cpu_bresp, npu_bresp, cpu_rresp, npu_rresp;
wire cpu_bvalid, npu_bvalid, cpu_rvalid, npu_rvalid, cpu_rlast, npu_rlast;
wire [255:0] cpu_rdata, npu_rdata;

wire [29:0] ddr_awaddr, ddr_araddr;
wire [7:0] ddr_awid, ddr_arid, ddr_awlen, ddr_arlen;
wire [2:0] ddr_awsize, ddr_arsize;
wire [1:0] ddr_awburst, ddr_arburst;
wire ddr_awvalid, ddr_awready, ddr_wvalid, ddr_wready, ddr_wlast;
wire [255:0] ddr_wdata;
wire [31:0] ddr_wstrb;
reg [7:0] ddr_bid, ddr_rid;
reg [1:0] ddr_bresp, ddr_rresp;
reg ddr_bvalid, ddr_rvalid, ddr_rlast;
reg [255:0] ddr_rdata;
wire ddr_bready, ddr_arvalid, ddr_arready, ddr_rready;

Haxi_2m1s_arbiter dut (
    .clk(clk), .rst_n(rst_n),
    .cpu_axi_awaddr(cpu_awaddr), .cpu_axi_awid(cpu_awid), .cpu_axi_awlen(cpu_awlen),
    .cpu_axi_awsize(cpu_awsize), .cpu_axi_awburst(cpu_awburst), .cpu_axi_awvalid(cpu_awvalid), .cpu_axi_awready(cpu_awready),
    .cpu_axi_wdata(cpu_wdata), .cpu_axi_wstrb(cpu_wstrb), .cpu_axi_wlast(cpu_wlast), .cpu_axi_wvalid(cpu_wvalid), .cpu_axi_wready(cpu_wready),
    .cpu_axi_bid(cpu_bid), .cpu_axi_bresp(cpu_bresp), .cpu_axi_bvalid(cpu_bvalid), .cpu_axi_bready(cpu_bready),
    .cpu_axi_araddr(cpu_araddr), .cpu_axi_arid(cpu_arid), .cpu_axi_arlen(cpu_arlen),
    .cpu_axi_arsize(cpu_arsize), .cpu_axi_arburst(cpu_arburst), .cpu_axi_arvalid(cpu_arvalid), .cpu_axi_arready(cpu_arready),
    .cpu_axi_rdata(cpu_rdata), .cpu_axi_rid(cpu_rid), .cpu_axi_rresp(cpu_rresp), .cpu_axi_rlast(cpu_rlast), .cpu_axi_rvalid(cpu_rvalid), .cpu_axi_rready(cpu_rready),
    .npu_axi_awaddr(npu_awaddr), .npu_axi_awid(npu_awid), .npu_axi_awlen(npu_awlen),
    .npu_axi_awsize(npu_awsize), .npu_axi_awburst(npu_awburst), .npu_axi_awvalid(npu_awvalid), .npu_axi_awready(npu_awready),
    .npu_axi_wdata(npu_wdata), .npu_axi_wstrb(npu_wstrb), .npu_axi_wlast(npu_wlast), .npu_axi_wvalid(npu_wvalid), .npu_axi_wready(npu_wready),
    .npu_axi_bid(npu_bid), .npu_axi_bresp(npu_bresp), .npu_axi_bvalid(npu_bvalid), .npu_axi_bready(npu_bready),
    .npu_axi_araddr(npu_araddr), .npu_axi_arid(npu_arid), .npu_axi_arlen(npu_arlen),
    .npu_axi_arsize(npu_arsize), .npu_axi_arburst(npu_arburst), .npu_axi_arvalid(npu_arvalid), .npu_axi_arready(npu_arready),
    .npu_axi_rdata(npu_rdata), .npu_axi_rid(npu_rid), .npu_axi_rresp(npu_rresp), .npu_axi_rlast(npu_rlast), .npu_axi_rvalid(npu_rvalid), .npu_axi_rready(npu_rready),
    .ddr_axi_awaddr(ddr_awaddr), .ddr_axi_awid(ddr_awid), .ddr_axi_awlen(ddr_awlen), .ddr_axi_awsize(ddr_awsize), .ddr_axi_awburst(ddr_awburst), .ddr_axi_awvalid(ddr_awvalid), .ddr_axi_awready(ddr_awready),
    .ddr_axi_wdata(ddr_wdata), .ddr_axi_wstrb(ddr_wstrb), .ddr_axi_wlast(ddr_wlast), .ddr_axi_wvalid(ddr_wvalid), .ddr_axi_wready(ddr_wready),
    .ddr_axi_bid(ddr_bid), .ddr_axi_bresp(ddr_bresp), .ddr_axi_bvalid(ddr_bvalid), .ddr_axi_bready(ddr_bready),
    .ddr_axi_araddr(ddr_araddr), .ddr_axi_arid(ddr_arid), .ddr_axi_arlen(ddr_arlen), .ddr_axi_arsize(ddr_arsize), .ddr_axi_arburst(ddr_arburst), .ddr_axi_arvalid(ddr_arvalid), .ddr_axi_arready(ddr_arready),
    .ddr_axi_rdata(ddr_rdata), .ddr_axi_rid(ddr_rid), .ddr_axi_rresp(ddr_rresp), .ddr_axi_rlast(ddr_rlast), .ddr_axi_rvalid(ddr_rvalid), .ddr_axi_rready(ddr_rready)
);

integer cycle_count;
reg force_ar_stall, force_aw_stall;
assign ddr_arready = !force_ar_stall && (cycle_count[1:0] != 0);
assign ddr_awready = !force_aw_stall && (cycle_count[1:0] != 1);
assign ddr_wready  = (cycle_count[1:0] != 2);

// 下游读响应器：接受一个 AR 后按 length 返回，拍间故意插入空拍。
reg rd_active;
reg [7:0] rd_id;
reg [8:0] rd_left;
integer rd_delay;
// 下游写响应器：记录 AW owner，WLAST 后延迟返回 B。
reg wr_active, b_pending;
reg [7:0] wr_id;
reg [8:0] wr_left;
integer b_delay;
integer ar_count, aw_count, w_count, cpu_r_count, npu_r_count, cpu_b_count, npu_b_count;
integer npu_r_error_count, npu_b_error_count;
reg [7:0] ar_id_log [0:15];
reg [7:0] aw_id_log [0:15];
reg [255:0] wdata_log [0:31];

always @(posedge clk) begin
    if (!rst_n) begin
        cycle_count <= 0;
        rd_active <= 0; rd_id <= 0; rd_left <= 0; rd_delay <= 0;
        ddr_rvalid <= 0; ddr_rid <= 0; ddr_rresp <= 0; ddr_rlast <= 0; ddr_rdata <= 0;
        wr_active <= 0; wr_id <= 0; wr_left <= 0; b_pending <= 0; b_delay <= 0;
        ddr_bvalid <= 0; ddr_bid <= 0; ddr_bresp <= 0;
        ar_count <= 0; aw_count <= 0; w_count <= 0;
        cpu_r_count <= 0; npu_r_count <= 0; cpu_b_count <= 0; npu_b_count <= 0;
        npu_r_error_count <= 0; npu_b_error_count <= 0;
    end else begin
        cycle_count <= cycle_count + 1;
        if (cpu_rvalid && cpu_rready) cpu_r_count <= cpu_r_count + 1;
        if (npu_rvalid && npu_rready) begin
            npu_r_count <= npu_r_count + 1;
            if (npu_rresp != 2'b00) npu_r_error_count <= npu_r_error_count + 1;
        end
        if (cpu_bvalid && cpu_bready) cpu_b_count <= cpu_b_count + 1;
        if (npu_bvalid && npu_bready) begin
            npu_b_count <= npu_b_count + 1;
            if (npu_bresp != 2'b00) npu_b_error_count <= npu_b_error_count + 1;
        end

        if (ddr_arvalid && ddr_arready) begin
            if (rd_active) $fatal(1, "DDR received overlapping AR");
            ar_id_log[ar_count] <= ddr_arid;
            ar_count <= ar_count + 1;
            rd_active <= 1;
            rd_id <= ddr_arid;
            rd_left <= ddr_arlen + 1;
            rd_delay <= 1;
        end
        if (ddr_rvalid) begin
            if (ddr_rready) begin
                ddr_rvalid <= 0;
                if (rd_left == 1) rd_active <= 0;
                else begin rd_left <= rd_left - 1; rd_delay <= 1; end
            end
        end else if (rd_active) begin
            if (rd_delay != 0) rd_delay <= rd_delay - 1;
            else begin
                ddr_rvalid <= 1;
                ddr_rid <= rd_id;
                ddr_rdata <= {8{24'h0, rd_id}};
                // NPU 的第二个读拍注入错误，检查 RRESP 仍只路由至 NPU。
                ddr_rresp <= ((rd_id == 8'h81) && (rd_left == 2)) ? 2'b10 : 2'b00;
                ddr_rlast <= (rd_left == 1);
            end
        end

        if (ddr_awvalid && ddr_awready) begin
            if (wr_active) $fatal(1, "DDR received overlapping AW");
            aw_id_log[aw_count] <= ddr_awid;
            aw_count <= aw_count + 1;
            wr_active <= 1;
            wr_id <= ddr_awid;
            wr_left <= ddr_awlen + 1;
        end
        if (ddr_wvalid && ddr_wready) begin
            if (!wr_active) $fatal(1, "W without accepted AW");
            if (ddr_wlast != (wr_left == 1)) $fatal(1, "WLAST mismatch");
            wdata_log[w_count] <= ddr_wdata;
            w_count <= w_count + 1;
            if (wr_left == 1) begin
                wr_active <= 0; b_pending <= 1; b_delay <= 2;
                ddr_bid <= wr_id;
                // NPU 写响应走错误路径，CPU 的 B 保持 OKAY。
                ddr_bresp <= (wr_id == 8'h82) ? 2'b10 : 2'b00;
            end else wr_left <= wr_left - 1;
        end
        if (ddr_bvalid) begin
            if (ddr_bready) ddr_bvalid <= 0;
        end else if (b_pending) begin
            if (b_delay != 0) b_delay <= b_delay - 1;
            else begin b_pending <= 0; ddr_bvalid <= 1; end
        end
    end
end

// ddr 方向三个请求通道的 stall 期间，所有有效 payload 必须不变。
reg ar_hold, aw_hold, w_hold;
reg [29:0] araddr_hold, awaddr_hold;
reg [7:0] arid_hold, arlen_hold, awid_hold, awlen_hold;
reg [2:0] arsize_hold, awsize_hold;
reg [1:0] arburst_hold, awburst_hold;
reg [255:0] wdata_hold;
reg [31:0] wstrb_hold;
reg wlast_hold;
integer forced_ar_stall_cycles, forced_aw_stall_cycles;
reg r_hold, b_hold, r_hold_owner, b_hold_owner;
reg [255:0] rdata_hold;
reg [7:0] rid_hold, bid_hold;
reg [1:0] rresp_hold, bresp_hold;
reg rlast_hold;
integer r_stall_cycles, b_stall_cycles;
always @(posedge clk) begin
    if (!rst_n) begin
        ar_hold<=0; aw_hold<=0; w_hold<=0;
        forced_ar_stall_cycles<=0; forced_aw_stall_cycles<=0;
        r_hold<=0; b_hold<=0; r_stall_cycles<=0; b_stall_cycles<=0;
    end
    else begin
        if (ar_hold && (!ddr_arvalid || ddr_araddr != araddr_hold || ddr_arid != arid_hold || ddr_arlen != arlen_hold || ddr_arsize != arsize_hold || ddr_arburst != arburst_hold)) $fatal(1,"AR changed during stall");
        if (aw_hold && (!ddr_awvalid || ddr_awaddr != awaddr_hold || ddr_awid != awid_hold || ddr_awlen != awlen_hold || ddr_awsize != awsize_hold || ddr_awburst != awburst_hold)) $fatal(1,"AW changed during stall");
        if (w_hold && (!ddr_wvalid || ddr_wdata != wdata_hold || ddr_wstrb != wstrb_hold || ddr_wlast != wlast_hold)) $fatal(1,"W changed during stall");
        if (force_ar_stall && ddr_arvalid && !ddr_arready) forced_ar_stall_cycles <= forced_ar_stall_cycles + 1;
        if (force_aw_stall && ddr_awvalid && !ddr_awready) forced_aw_stall_cycles <= forced_aw_stall_cycles + 1;
        ar_hold <= ddr_arvalid && !ddr_arready; aw_hold <= ddr_awvalid && !ddr_awready; w_hold <= ddr_wvalid && !ddr_wready;
        araddr_hold <= ddr_araddr; arid_hold <= ddr_arid; arlen_hold <= ddr_arlen;
        awaddr_hold <= ddr_awaddr; awid_hold <= ddr_awid; awlen_hold <= ddr_awlen;
        arsize_hold <= ddr_arsize; arburst_hold <= ddr_arburst;
        awsize_hold <= ddr_awsize; awburst_hold <= ddr_awburst;
        wdata_hold <= ddr_wdata; wstrb_hold <= ddr_wstrb; wlast_hold <= ddr_wlast;

        // 响应只能送给锁定 owner；该 owner backpressure 时 payload 必须保持。
        if (cpu_rvalid && npu_rvalid) $fatal(1,"R leaked to both masters");
        if (ddr_rvalid && dut.read_active && ((dut.read_owner && (cpu_rvalid || !npu_rvalid)) || (!dut.read_owner && (npu_rvalid || !cpu_rvalid)))) $fatal(1,"R routed to non-owner");
        if (cpu_rvalid && (!ddr_rvalid || cpu_rdata != ddr_rdata || cpu_rid != ddr_rid || cpu_rresp != ddr_rresp || cpu_rlast != ddr_rlast)) $fatal(1,"CPU R route failed");
        if (npu_rvalid && (!ddr_rvalid || npu_rdata != ddr_rdata || npu_rid != ddr_rid || npu_rresp != ddr_rresp || npu_rlast != ddr_rlast)) $fatal(1,"NPU R route failed");
        if (cpu_bvalid && npu_bvalid) $fatal(1,"B leaked to both masters");
        if (ddr_bvalid && (dut.write_state == 2'd2) && ((dut.write_owner && (cpu_bvalid || !npu_bvalid)) || (!dut.write_owner && (npu_bvalid || !cpu_bvalid)))) $fatal(1,"B routed to non-owner");
        if (cpu_bvalid && (!ddr_bvalid || cpu_bid != ddr_bid || cpu_bresp != ddr_bresp)) $fatal(1,"CPU B route failed");
        if (npu_bvalid && (!ddr_bvalid || npu_bid != ddr_bid || npu_bresp != ddr_bresp)) $fatal(1,"NPU B route failed");
        if (r_hold && (!(r_hold_owner ? npu_rvalid : cpu_rvalid) ||
            (r_hold_owner ? npu_rdata : cpu_rdata) != rdata_hold ||
            (r_hold_owner ? npu_rid : cpu_rid) != rid_hold ||
            (r_hold_owner ? npu_rresp : cpu_rresp) != rresp_hold ||
            (r_hold_owner ? npu_rlast : cpu_rlast) != rlast_hold)) $fatal(1,"R changed during stall");
        if (b_hold && (!(b_hold_owner ? npu_bvalid : cpu_bvalid) ||
            (b_hold_owner ? npu_bid : cpu_bid) != bid_hold ||
            (b_hold_owner ? npu_bresp : cpu_bresp) != bresp_hold)) $fatal(1,"B changed during stall");
        r_hold <= (cpu_rvalid && !cpu_rready) || (npu_rvalid && !npu_rready);
        r_hold_owner <= npu_rvalid;
        rdata_hold <= npu_rvalid ? npu_rdata : cpu_rdata;
        rid_hold <= npu_rvalid ? npu_rid : cpu_rid;
        rresp_hold <= npu_rvalid ? npu_rresp : cpu_rresp;
        rlast_hold <= npu_rvalid ? npu_rlast : cpu_rlast;
        b_hold <= (cpu_bvalid && !cpu_bready) || (npu_bvalid && !npu_bready);
        b_hold_owner <= npu_bvalid;
        bid_hold <= npu_bvalid ? npu_bid : cpu_bid;
        bresp_hold <= npu_bvalid ? npu_bresp : cpu_bresp;
        if (cpu_rvalid && !cpu_rready) r_stall_cycles <= r_stall_cycles + 1;
        if (npu_rvalid && !npu_rready) r_stall_cycles <= r_stall_cycles + 1;
        if (cpu_bvalid && !cpu_bready) b_stall_cycles <= b_stall_cycles + 1;
        if (npu_bvalid && !npu_bready) b_stall_cycles <= b_stall_cycles + 1;
    end
end

task drive_cpu_ar; input [7:0] id; input [7:0] len; input [29:0] addr; begin
    @(negedge clk); #1; cpu_arid=id; cpu_arlen=len; cpu_araddr=addr; cpu_arvalid=1;
    begin : wait_cpu_ar
        while (1) begin @(posedge clk); if (cpu_arvalid && cpu_arready) disable wait_cpu_ar; end
    end
    @(negedge clk); #1; cpu_arvalid=0;
end endtask
task drive_npu_ar; input [7:0] id; input [7:0] len; input [29:0] addr; begin
    @(negedge clk); #1; npu_arid=id; npu_arlen=len; npu_araddr=addr; npu_arvalid=1;
    begin : wait_npu_ar
        while (1) begin @(posedge clk); if (npu_arvalid && npu_arready) disable wait_npu_ar; end
    end
    @(negedge clk); #1; npu_arvalid=0;
end endtask
task drive_cpu_aw; input [7:0] id; input [7:0] len; input [29:0] addr; begin
    @(negedge clk); #1; cpu_awid=id; cpu_awlen=len; cpu_awaddr=addr; cpu_awvalid=1;
    begin : wait_cpu_aw
        while (1) begin @(posedge clk); if (cpu_awready) disable wait_cpu_aw; end
    end
    @(negedge clk); #1; cpu_awvalid=0;
end endtask
task drive_npu_aw; input [7:0] id; input [7:0] len; input [29:0] addr; begin
    @(negedge clk); #1; npu_awid=id; npu_awlen=len; npu_awaddr=addr; npu_awvalid=1;
    begin : wait_npu_aw
        while (1) begin @(posedge clk); if (npu_awready) disable wait_npu_aw; end
    end
    @(negedge clk); #1; npu_awvalid=0;
end endtask
task drive_cpu_w; input integer beats; input [31:0] base; integer j; begin
    @(negedge clk); #1; cpu_wvalid=1;
    for (j=0;j<beats;j=j+1) begin
        cpu_wdata={8{base+j}}; cpu_wstrb=32'hffff_ffff; cpu_wlast=(j==beats-1);
        begin : wait_cpu_w
            while (1) begin @(posedge clk); if (cpu_wready) disable wait_cpu_w; end
        end
        @(negedge clk); #1;
    end
    cpu_wvalid=0; cpu_wlast=0;
end endtask
task drive_npu_w; input integer beats; input [31:0] base; integer j; begin
    @(negedge clk); #1; npu_wvalid=1;
    for (j=0;j<beats;j=j+1) begin
        npu_wdata={8{base+j}}; npu_wstrb=32'hffff_ffff; npu_wlast=(j==beats-1);
        begin : wait_npu_w
            while (1) begin @(posedge clk); if (npu_wready) disable wait_npu_w; end
        end
        @(negedge clk); #1;
    end
    npu_wvalid=0; npu_wlast=0;
end endtask
task wait_count; input integer which; input integer old_count; integer timeout; begin : wait_count_block
    for (timeout=0; timeout<1000; timeout=timeout+1) begin
        @(negedge clk);
        if ((which==0 && cpu_r_count!=old_count) || (which==1 && npu_r_count!=old_count) ||
            (which==2 && cpu_b_count!=old_count) || (which==3 && npu_b_count!=old_count)) disable wait_count_block;
    end
    $fatal(1,"response timeout");
end endtask

integer base_ar, base_aw, base_w, base_cpu_r, base_npu_r, base_cpu_b, base_npu_b;
// 避免测试驱动或仲裁逻辑的意外死锁长期占用仿真。
initial begin
    #100000;
    $fatal(1, "AXI arbiter TB global timeout");
end
initial begin
    clk=0; rst_n=0;
    cpu_awaddr=0; npu_awaddr=0; cpu_araddr=0; npu_araddr=0;
    cpu_awid=0; npu_awid=0; cpu_arid=0; npu_arid=0;
    cpu_awlen=0; npu_awlen=0; cpu_arlen=0; npu_arlen=0;
    cpu_awsize=3'd5; npu_awsize=3'd5; cpu_arsize=3'd5; npu_arsize=3'd5;
    cpu_awburst=2'b01; npu_awburst=2'b01; cpu_arburst=2'b01; npu_arburst=2'b01;
    cpu_awvalid=0; npu_awvalid=0; cpu_wvalid=0; npu_wvalid=0; cpu_arvalid=0; npu_arvalid=0;
    cpu_wdata=0; npu_wdata=0; cpu_wstrb=0; npu_wstrb=0; cpu_wlast=0; npu_wlast=0;
    cpu_bready=1; npu_bready=1; cpu_rready=1; npu_rready=1;
    force_ar_stall=0; force_aw_stall=0;
    repeat(3) @(negedge clk); rst_n=1; #1;

    // 同时 AR：初始 CPU 优先；CPU 两拍期间 NPU 不能收到响应或被插入。
    base_ar=ar_count; base_cpu_r=cpu_r_count; base_npu_r=npu_r_count;
    fork
        begin drive_cpu_ar(8'h11, 8'd1, 30'h0100); end
        begin drive_npu_ar(8'h81, 8'd2, 30'h0200); end
    join
    // NPU 的 AR task 至此已在其 burst 获授时退出，CPU 两拍与 NPU 三拍均完成前后有响应。
    repeat(20) @(negedge clk);
    if ((ar_count-base_ar != 2) || ar_id_log[base_ar] != 8'h11 || ar_id_log[base_ar+1] != 8'h81 ||
        (cpu_r_count-base_cpu_r != 2) || (npu_r_count-base_npu_r != 3) || npu_r_error_count == 0)
        $fatal(1,"read owner lock/RR/error route failed");

    // 下一轮同时竞争，上一轮最后 NPU 获授，round-robin 必须改为 CPU。
    base_ar=ar_count;
    fork
        begin drive_cpu_ar(8'h12, 8'd0, 30'h0300); end
        begin drive_npu_ar(8'h83, 8'd0, 30'h0400); end
    join
    repeat(20) @(negedge clk);
    if ((ar_count-base_ar != 2) || ar_id_log[base_ar] != 8'h12 || ar_id_log[base_ar+1] != 8'h83)
        $fatal(1,"round-robin did not alternate read winner");

    // CPU AW/W 同时到达；NPU AW 持续等待，CPU 单拍写必须完整先结束。
    base_aw=aw_count; base_w=w_count; base_cpu_b=cpu_b_count; base_npu_b=npu_b_count;
    fork
        begin drive_cpu_aw(8'h21, 8'd0, 30'h1000); end
        begin drive_cpu_w(1, 32'hca00_0000); end
        begin drive_npu_aw(8'h82, 8'd2, 30'h2000); end
    join
    // NPU 的 W 明确在其 AW 握手之后才开始，且为三拍，不得与 CPU W 交错。
    drive_npu_w(3, 32'hd000_0000);
    wait_count(2, base_cpu_b);
    wait_count(3, base_npu_b);
    if ((aw_count-base_aw != 2) || aw_id_log[base_aw] != 8'h21 || aw_id_log[base_aw+1] != 8'h82 ||
        (w_count-base_w != 4) || wdata_log[base_w] != {8{32'hca00_0000}} ||
        wdata_log[base_w+1] != {8{32'hd000_0000}} || wdata_log[base_w+2] != {8{32'hd000_0001}} ||
        wdata_log[base_w+3] != {8{32'hd000_0002}} || (cpu_b_count-base_cpu_b != 1) ||
        (npu_b_count-base_npu_b != 1) || npu_b_error_count == 0)
        $fatal(1,"write owner lock/B route failed");

    // CPU 读与 NPU 写同时启动，两个独立状态机应并行受理。
    base_ar=ar_count; base_aw=aw_count; base_cpu_r=cpu_r_count; base_npu_b=npu_b_count;
    fork
        begin drive_cpu_ar(8'h13, 8'd0, 30'h0500); end
        begin drive_npu_aw(8'h84, 8'd0, 30'h3000); end
    join
    drive_npu_w(1, 32'he000_0000);
    wait_count(0, base_cpu_r);
    wait_count(3, base_npu_b);
    if ((ar_count != base_ar+1) || (aw_count != base_aw+1) || (cpu_r_count != base_cpu_r+1))
        $fatal(1,"read/write were not independently accepted");

    // 下游 Ready 拉低期间，后发请求不能改变已选择的 Ax payload 或 owner。
    // CPU 先进入寄存器，NPU 随后发起不同字段的请求；保持数拍后才放行。
    force_ar_stall=1; base_ar=ar_count; base_cpu_r=cpu_r_count; base_npu_r=npu_r_count;
    @(negedge clk); #1;
    cpu_arid=8'h31; cpu_arlen=8'd0; cpu_araddr=30'h0600; cpu_arsize=3'd3; cpu_arburst=2'b00; cpu_arvalid=1;
    @(posedge clk); @(negedge clk); #1;
    npu_arid=8'h85; npu_arlen=8'd0; npu_araddr=30'h0700; npu_arsize=3'd4; npu_arburst=2'b10; npu_arvalid=1;
    repeat(3) @(negedge clk);
    if (!ddr_arvalid || ddr_araddr != 30'h0600 || ddr_arid != 8'h31 || ddr_arlen != 0 || ddr_arsize != 3'd3 || ddr_arburst != 2'b00)
        $fatal(1,"AR owner/payload changed while stalled");
    force_ar_stall=0;
    begin : wait_stalled_cpu_ar
        while (1) begin @(posedge clk); if (cpu_arvalid && cpu_arready) disable wait_stalled_cpu_ar; end
    end
    @(negedge clk); #1; cpu_arvalid=0; cpu_arsize=3'd5; cpu_arburst=2'b01;
    cpu_rready=0;
    begin : wait_cpu_r_backpressure
        while (1) begin @(posedge clk); if (cpu_rvalid) disable wait_cpu_r_backpressure; end
    end
    repeat(2) @(posedge clk);
    cpu_rready=1;
    begin : wait_stalled_npu_ar
        while (1) begin @(posedge clk); if (npu_arvalid && npu_arready) disable wait_stalled_npu_ar; end
    end
    @(negedge clk); #1; npu_arvalid=0; npu_arsize=3'd5; npu_arburst=2'b01;
    repeat(20) @(negedge clk);
    if ((ar_count-base_ar != 2) || (cpu_r_count-base_cpu_r != 1) || (npu_r_count-base_npu_r != 1))
        $fatal(1,"AR stall owner lock failed");

    force_aw_stall=1; base_aw=aw_count; base_cpu_b=cpu_b_count; base_npu_b=npu_b_count;
    @(negedge clk); #1;
    cpu_awid=8'h41; cpu_awlen=8'd0; cpu_awaddr=30'h4000; cpu_awsize=3'd4; cpu_awburst=2'b00; cpu_awvalid=1;
    @(posedge clk); @(negedge clk); #1;
    npu_awid=8'h86; npu_awlen=8'd0; npu_awaddr=30'h5000; npu_awsize=3'd3; npu_awburst=2'b10; npu_awvalid=1;
    repeat(3) @(negedge clk);
    if (!ddr_awvalid || ddr_awaddr != 30'h4000 || ddr_awid != 8'h41 || ddr_awlen != 0 || ddr_awsize != 3'd4 || ddr_awburst != 2'b00)
        $fatal(1,"AW owner/payload changed while stalled");
    force_aw_stall=0;
    begin : wait_stalled_cpu_aw
        while (1) begin @(posedge clk); if (cpu_awvalid && cpu_awready) disable wait_stalled_cpu_aw; end
    end
    @(negedge clk); #1; cpu_awvalid=0; cpu_awsize=3'd5; cpu_awburst=2'b01;
    drive_cpu_w(1, 32'hf000_0000);
    cpu_bready=0;
    begin : wait_cpu_b_backpressure
        while (1) begin @(posedge clk); if (cpu_bvalid) disable wait_cpu_b_backpressure; end
    end
    repeat(2) @(posedge clk);
    cpu_bready=1;
    wait_count(2, base_cpu_b);
    begin : wait_stalled_npu_aw
        while (1) begin @(posedge clk); if (npu_awvalid && npu_awready) disable wait_stalled_npu_aw; end
    end
    @(negedge clk); #1; npu_awvalid=0; npu_awsize=3'd5; npu_awburst=2'b01;
    drive_npu_w(1, 32'hf100_0000);
    wait_count(3, base_npu_b);
    if ((aw_count-base_aw != 2) || (cpu_b_count-base_cpu_b != 1) || (npu_b_count-base_npu_b != 1) ||
        forced_ar_stall_cycles < 2 || forced_aw_stall_cycles < 2 || r_stall_cycles < 2 || b_stall_cycles < 2)
        $fatal(1,"AW stall owner lock/coverage failed");

    $display("AXI_2M1S_ARBITER_PASS ar=%0d aw=%0d w=%0d forced_ar_stall=%0d forced_aw_stall=%0d r_stall=%0d b_stall=%0d", ar_count, aw_count, w_count, forced_ar_stall_cycles, forced_aw_stall_cycles, r_stall_cycles, b_stall_cycles);
    $finish;
end
endmodule
