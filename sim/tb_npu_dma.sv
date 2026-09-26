`timescale 1ns / 1ps

// NPU DMA 独立验证：下方 AXI 从机故意在各请求/响应通道插入空拍，
// 同时记录 burst，以检查 256-bit copy、4 KiB 截断及错误收尾行为。
module tb_npu_dma;

reg clk;
reg rst_n;
reg start;
reg [31:0] src_addr;
reg [31:0] dst_addr;
reg [31:0] task_bytes;
wire busy;
wire done_pulse;
wire error;
wire error_pulse;

wire [29:0] axi_awaddr;
wire [7:0] axi_awid;
wire [7:0] axi_awlen;
wire [2:0] axi_awsize;
wire [1:0] axi_awburst;
wire axi_awvalid;
wire axi_awready;
wire [255:0] axi_wdata;
wire [31:0] axi_wstrb;
wire axi_wlast;
wire axi_wvalid;
wire axi_wready;
wire [7:0] axi_bid;
wire [1:0] axi_bresp;
wire axi_bvalid;
wire axi_bready;
wire [29:0] axi_araddr;
wire [7:0] axi_arid;
wire [7:0] axi_arlen;
wire [2:0] axi_arsize;
wire [1:0] axi_arburst;
wire axi_arvalid;
wire axi_arready;
wire [255:0] axi_rdata;
wire [7:0] axi_rid;
wire [1:0] axi_rresp;
wire axi_rlast;
wire axi_rvalid;
wire axi_rready;

Hnpu_dma dut (
    .clk(clk), .rst_n(rst_n), .start(start),
    .src_addr(src_addr), .dst_addr(dst_addr), .task_bytes(task_bytes),
    .busy(busy), .done_pulse(done_pulse), .error(error), .error_pulse(error_pulse),
    .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
    .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
    .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
    .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
    .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
    .axi_bid(axi_bid), .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
    .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
    .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
    .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
    .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready)
);

always #5 clk = ~clk;

// 32 KiB 的 256-bit DDR 本地窗口模型；下标即本地地址 / 32。
reg [255:0] mem [0:1023];
integer cycle_count;
integer done_count;
integer error_count;
integer ar_count;
integer aw_count;
integer r_handshake_count;
reg [29:0] ar_addr_log [0:31];
reg [7:0] ar_len_log [0:31];
reg [29:0] aw_addr_log [0:31];
reg [7:0] aw_len_log [0:31];
reg inject_r_error;
reg inject_b_error;

// 请求通道周期性 backpressure；每个 valid 在阻塞期间须保持 payload。
assign axi_arready = !rd_active && !axi_rvalid && (cycle_count[1:0] != 2'b00);
assign axi_awready = !wr_active && !b_pending && !axi_bvalid && (cycle_count[1:0] != 2'b01);
assign axi_wready  = wr_active && (cycle_count[1:0] != 2'b10);

reg rd_active;
reg [29:0] rd_addr;
reg [8:0] rd_left;
reg [7:0] rd_id;
integer rd_delay;
reg [255:0] axi_rdata_reg;
reg [7:0] axi_rid_reg;
reg [1:0] axi_rresp_reg;
reg axi_rlast_reg;
reg axi_rvalid_reg;
assign axi_rdata = axi_rdata_reg;
assign axi_rid = axi_rid_reg;
assign axi_rresp = axi_rresp_reg;
assign axi_rlast = axi_rlast_reg;
assign axi_rvalid = axi_rvalid_reg;

reg wr_active;
reg [29:0] wr_addr;
reg [8:0] wr_left;
reg [7:0] wr_id;
reg b_pending;
integer b_delay;
reg [7:0] axi_bid_reg;
reg [1:0] axi_bresp_reg;
reg axi_bvalid_reg;
assign axi_bid = axi_bid_reg;
assign axi_bresp = axi_bresp_reg;
assign axi_bvalid = axi_bvalid_reg;

integer i;
integer lane;
always @(posedge clk) begin
    if (!rst_n) begin
        cycle_count <= 0;
        done_count <= 0;
        error_count <= 0;
        ar_count <= 0;
        aw_count <= 0;
        r_handshake_count <= 0;
        rd_active <= 0;
        rd_addr <= 0;
        rd_left <= 0;
        rd_id <= 0;
        rd_delay <= 0;
        axi_rvalid_reg <= 0;
        axi_rdata_reg <= 0;
        axi_rid_reg <= 0;
        axi_rresp_reg <= 0;
        axi_rlast_reg <= 0;
        wr_active <= 0;
        wr_addr <= 0;
        wr_left <= 0;
        wr_id <= 0;
        b_pending <= 0;
        b_delay <= 0;
        axi_bvalid_reg <= 0;
        axi_bid_reg <= 0;
        axi_bresp_reg <= 0;
    end else begin
        cycle_count <= cycle_count + 1;
        if (done_pulse)
            done_count <= done_count + 1;
        if (error_pulse)
            error_count <= error_count + 1;

        if (axi_arvalid && axi_arready) begin
            if (({1'b0, axi_araddr[11:0]} + (({5'b0, axi_arlen} + 13'd1) << 5)) > 13'd4096)
                $fatal(1, "AR burst crossed 4 KiB");
            if ((axi_arid != 8'h80) || (axi_arsize != 3'b101) ||
                (axi_arburst != 2'b01))
                $fatal(1, "AR metadata wrong");
            ar_addr_log[ar_count] <= axi_araddr;
            ar_len_log[ar_count] <= axi_arlen;
            ar_count <= ar_count + 1;
            rd_active <= 1;
            rd_addr <= axi_araddr;
            rd_left <= axi_arlen + 1;
            rd_id <= axi_arid;
            rd_delay <= 2;
        end

        if (axi_rvalid_reg) begin
            if (axi_rready) begin
                r_handshake_count <= r_handshake_count + 1;
                axi_rvalid_reg <= 0;
                if (rd_left == 1) begin
                    rd_active <= 0;
                end else begin
                    rd_addr <= rd_addr + 30'd32;
                    rd_left <= rd_left - 1;
                    rd_delay <= 2;
                end
            end
        end else if (rd_active) begin
            if (rd_delay != 0) begin
                rd_delay <= rd_delay - 1;
            end else begin
                axi_rdata_reg <= mem[rd_addr[14:5]];
                axi_rid_reg <= rd_id;
                // 4 拍错误测试在第二拍（rd_left=3）注入，后续拍仍正常送至 RLAST。
                axi_rresp_reg <= (inject_r_error && (rd_left == 3)) ? 2'b10 : 2'b00;
                axi_rlast_reg <= (rd_left == 1);
                axi_rvalid_reg <= 1;
            end
        end

        if (axi_awvalid && axi_awready) begin
            if (({1'b0, axi_awaddr[11:0]} + (({5'b0, axi_awlen} + 13'd1) << 5)) > 13'd4096)
                $fatal(1, "AW burst crossed 4 KiB");
            if ((axi_awid != 8'h80) || (axi_awsize != 3'b101) ||
                (axi_awburst != 2'b01))
                $fatal(1, "AW metadata wrong");
            aw_addr_log[aw_count] <= axi_awaddr;
            aw_len_log[aw_count] <= axi_awlen;
            aw_count <= aw_count + 1;
            wr_active <= 1;
            wr_addr <= axi_awaddr;
            wr_left <= axi_awlen + 1;
            wr_id <= axi_awid;
        end

        if (axi_wvalid && axi_wready) begin
            if (axi_wlast != (wr_left == 1))
                $fatal(1, "WLAST beat mismatch");
            for (lane = 0; lane < 32; lane = lane + 1)
                if (axi_wstrb[lane])
                    mem[wr_addr[14:5]][lane*8 +: 8] <= axi_wdata[lane*8 +: 8];
            if (wr_left == 1) begin
                wr_active <= 0;
                b_pending <= 1;
                b_delay <= 3;
                axi_bid_reg <= wr_id;
                axi_bresp_reg <= inject_b_error ? 2'b10 : 2'b00;
            end else begin
                wr_addr <= wr_addr + 30'd32;
                wr_left <= wr_left - 1;
            end
        end

        if (axi_bvalid_reg) begin
            if (axi_bready)
                axi_bvalid_reg <= 0;
        end else if (b_pending) begin
            if (b_delay != 0) begin
                b_delay <= b_delay - 1;
            end else begin
                b_pending <= 0;
                axi_bvalid_reg <= 1;
            end
        end
    end
end

// master 请求在 ready 未到前不得改变任何 payload。
reg ar_hold, aw_hold, w_hold;
reg [29:0] araddr_hold, awaddr_hold;
reg [7:0] arlen_hold, awlen_hold;
reg [255:0] wdata_hold;
reg [31:0] wstrb_hold;
reg wlast_hold;
always @(posedge clk) begin
    if (!rst_n) begin
        ar_hold <= 0; aw_hold <= 0; w_hold <= 0;
    end else begin
        if (ar_hold && (!axi_arvalid || axi_araddr != araddr_hold || axi_arlen != arlen_hold ||
                        axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01))
            $fatal(1, "AR payload changed during stall");
        if (aw_hold && (!axi_awvalid || axi_awaddr != awaddr_hold || axi_awlen != awlen_hold ||
                        axi_awid != 8'h80 || axi_awsize != 3'b101 || axi_awburst != 2'b01))
            $fatal(1, "AW payload changed during stall");
        if (w_hold && (!axi_wvalid || axi_wdata != wdata_hold || axi_wstrb != wstrb_hold ||
                       axi_wlast != wlast_hold))
            $fatal(1, "W payload changed during stall");
        ar_hold <= axi_arvalid && !axi_arready;
        aw_hold <= axi_awvalid && !axi_awready;
        w_hold <= axi_wvalid && !axi_wready;
        araddr_hold <= axi_araddr;
        arlen_hold <= axi_arlen;
        awaddr_hold <= axi_awaddr;
        awlen_hold <= axi_awlen;
        wdata_hold <= axi_wdata;
        wstrb_hold <= axi_wstrb;
        wlast_hold <= axi_wlast;
    end
end

task kick_dma;
    input [31:0] source;
    input [31:0] destination;
    input [31:0] bytes;
    begin
        @(negedge clk);
        src_addr = source;
        dst_addr = destination;
        task_bytes = bytes;
        start = 1;
        @(negedge clk);
        start = 0;
    end
endtask

task wait_done;
    input integer old_count;
    integer timeout;
    begin : wait_done_block
        for (timeout = 0; timeout < 2000; timeout = timeout + 1) begin
            @(negedge clk);
            if (done_count != old_count)
                disable wait_done_block;
        end
        $fatal(1, "DMA done timeout");
    end
endtask

task wait_error;
    input integer old_count;
    integer timeout;
    begin : wait_error_block
        for (timeout = 0; timeout < 2000; timeout = timeout + 1) begin
            @(negedge clk);
            if (error_count != old_count)
                disable wait_error_block;
        end
        $fatal(1, "DMA error timeout");
    end
endtask

integer base_ar;
integer base_aw;
integer base_done;
integer base_error;
integer base_r_handshakes;
reg [255:0] sentinel;
initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    src_addr = 0;
    dst_addr = 0;
    task_bytes = 0;
    inject_r_error = 0;
    inject_b_error = 0;
    for (i = 0; i < 1024; i = i + 1)
        mem[i] = {8{32'hc000_0000 + i}};

    repeat (3) @(negedge clk);
    rst_n = 1;

    // 40 beat: 验证 16 + 16 + 8 的分段、busy 时第二次 start 被忽略和逐拍数据。
    for (i = 0; i < 40; i = i + 1) begin
        mem[256+i] = {8{32'h1234_0000 + i}};
        mem[512+i] = 256'b0;
    end
    base_ar = ar_count;
    base_aw = aw_count;
    base_done = done_count;
    kick_dma(32'h8000_2000, 32'h8000_4000, 32'd1280);
    if (!busy) $fatal(1, "DMA did not become busy");
    // 第一个任务尚在途，新的 start 不能采纳。
    kick_dma(32'h8000_6000, 32'h8000_7000, 32'd32);
    wait_done(base_done);
    if (error) $fatal(1, "normal DMA reported error");
    if ((ar_count - base_ar != 3) || (aw_count - base_aw != 3) ||
        (ar_len_log[base_ar] != 8'd15) || (ar_len_log[base_ar+1] != 8'd15) ||
        (ar_len_log[base_ar+2] != 8'd7))
        $fatal(1, "40-beat segmentation is not 16+16+8");
    for (i = 0; i < 40; i = i + 1)
        if (mem[512+i] !== {8{32'h1234_0000 + i}})
            $fatal(1, "normal copy mismatch at beat %0d", i);

    // 源地址距 4 KiB 边界只剩 8 拍，16 beat 请求必须分成 8+8。
    for (i = 0; i < 16; i = i + 1) begin
        mem[120+i] = {8{32'habcd_0000 + i}};
        mem[768+i] = 256'b0;
    end
    base_ar = ar_count;
    base_done = done_count;
    kick_dma(32'h8000_0f00, 32'h8000_6000, 32'd512);
    wait_done(base_done);
    if ((ar_count - base_ar != 2) || (ar_len_log[base_ar] != 8'd7) ||
        (ar_len_log[base_ar+1] != 8'd7))
        $fatal(1, "4 KiB source truncation missing");
    for (i = 0; i < 16; i = i + 1)
        if (mem[768+i] !== {8{32'habcd_0000 + i}})
            $fatal(1, "4 KiB copy mismatch at beat %0d", i);

    // 零长度成功完成，且不发 AXI；未对齐与非 32B 倍数均无 AXI 地拒绝。
    base_ar = ar_count; base_aw = aw_count; base_done = done_count;
    kick_dma(32'h8000_2000, 32'h8000_4000, 0);
    wait_done(base_done);
    if ((ar_count != base_ar) || (aw_count != base_aw) || error)
        $fatal(1, "zero-length semantics wrong");
    base_ar = ar_count; base_aw = aw_count; base_error = error_count;
    kick_dma(32'h8000_2004, 32'h8000_4000, 32'd32);
    wait_error(base_error);
    if ((ar_count != base_ar) || (aw_count != base_aw) || !error)
        $fatal(1, "unaligned request accessed AXI");
    base_error = error_count;
    base_ar = ar_count; base_aw = aw_count;
    kick_dma(32'h8000_2000, 32'h8000_4000, 32'd36);
    wait_error(base_error);
    if ((ar_count != base_ar) || (aw_count != base_aw) || !error)
        $fatal(1, "non-32B-multiple request accessed AXI");

    // DDR 物理窗口外的地址同样只能报错，不能向 AXI 发起任何事务。
    base_ar = ar_count; base_aw = aw_count; base_error = error_count;
    kick_dma(32'h7fff_ffe0, 32'h8000_4000, 32'd32);
    wait_error(base_error);
    if ((ar_count != base_ar) || (aw_count != base_aw) || !error)
        $fatal(1, "below-DDR request accessed AXI");
    base_ar = ar_count; base_aw = aw_count; base_error = error_count;
    kick_dma(32'h8000_2000, 32'hbfff_ffe0, 32'd64);
    wait_error(base_error);
    if ((ar_count != base_ar) || (aw_count != base_aw) || !error)
        $fatal(1, "DDR-end-crossing request accessed AXI");

    // 第二拍 RRESP 错误仍要排空完整 4 拍 burst，且不能发 AW/W。
    sentinel = 256'hdeaddead_deaddead_deaddead_deaddead_deaddead_deaddead_deaddead_deaddead;
    for (i = 0; i < 4; i = i + 1)
        mem[640+i] = sentinel;
    inject_r_error = 1;
    base_ar = ar_count; base_aw = aw_count; base_error = error_count;
    base_done = done_count; base_r_handshakes = r_handshake_count;
    kick_dma(32'h8000_3000, 32'h8000_5000, 32'd128);
    wait_error(base_error);
    inject_r_error = 0;
    if ((ar_count != base_ar + 1) || (aw_count != base_aw) ||
        (r_handshake_count != base_r_handshakes + 4) || (done_count != base_done) ||
        (mem[640] !== sentinel) || (mem[641] !== sentinel) ||
        (mem[642] !== sentinel) || (mem[643] !== sentinel))
        $fatal(1, "RRESP error was not safely stopped");

    // BRESP 错误应可观察，且不得错误报告 done。
    inject_b_error = 1;
    base_error = error_count; base_done = done_count;
    kick_dma(32'h8000_2000, 32'h8000_5000, 32'd32);
    wait_error(base_error);
    inject_b_error = 0;
    if ((done_count != base_done) || !error)
        $fatal(1, "BRESP error handling wrong");

    $display("NPU_DMA_PASS ar=%0d aw=%0d done=%0d error=%0d", ar_count, aw_count,
             done_count, error_count);
    $finish;
end

endmodule
