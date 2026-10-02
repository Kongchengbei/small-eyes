`timescale 1ns / 1ps

// 验证 CPU 快照请求在 PCLK 暂停时超时，并能排空迟到响应后重新工作。
module tb_camera_snapshot;
    reg cpu_clk = 1'b0;
    reg mem_clk = 1'b0;
    reg pclk = 1'b0;
    reg pclk_run = 1'b0;
    reg rst_n = 1'b1;
    reg ddr_ready = 1'b0;
    reg capture_enable = 1'b0;
    reg vsync = 1'b1;
    reg href = 1'b0;
    reg [7:0] data = 8'b0;
    reg mmio_valid = 1'b0;
    reg mmio_wen = 1'b0;
    reg [7:0] mmio_addr = 8'b0;
    reg [31:0] mmio_wdata = 32'b0;
    reg [3:0] mmio_wmask = 4'b0;
    wire [31:0] mmio_rdata;
    wire [29:0] axi_awaddr;
    wire [7:0] axi_awid;
    wire [7:0] axi_awlen;
    wire [2:0] axi_awsize;
    wire [1:0] axi_awburst;
    wire axi_awvalid;
    reg axi_awready = 1'b1;
    wire [255:0] axi_wdata;
    wire [31:0] axi_wstrb;
    wire axi_wlast;
    wire axi_wvalid;
    reg axi_wready = 1'b1;
    reg [7:0] axi_bid = 8'h40;
    reg [1:0] axi_bresp = 2'b0;
    reg axi_bvalid = 1'b0;
    wire axi_bready;
    reg [31:0] frozen_pclk_count;
    integer frame_wait;

    always #5 cpu_clk = ~cpu_clk;
    always #4 mem_clk = ~mem_clk;
    always begin
        #7;
        if (pclk_run) pclk = ~pclk;
    end

    Hcamera_subsystem #(
        .DDR_BASE(32'h8000_0000), .DDR_BYTES(32'h4000_0000),
        .BUFFER0_ADDR(32'hb800_0000), .BUFFER1_ADDR(32'hb810_0000),
        .FRAME_WIDTH(16), .FRAME_HEIGHT(1), .FIFO_ADDR_WIDTH(4),
        .DMA_TIMEOUT_CYCLES(1000), .SNAPSHOT_TIMEOUT_CYCLES(40)
    ) dut (
        .consumer_ready_mask(), .consumer_frame0(), .consumer_frame1(),
        .consumer_release_valid(1'b0), .consumer_release_mask(2'b0),
        .cpu_clk(cpu_clk), .mem_clk(mem_clk), .rst_n(rst_n),
        .ddr_ready(ddr_ready), .capture_enable(capture_enable),
        .pclk(pclk), .vsync(vsync), .href(href), .data(data),
        .mmio_valid(mmio_valid), .mmio_wen(mmio_wen), .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata), .mmio_wmask(mmio_wmask), .mmio_rdata(mmio_rdata),
        .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
        .axi_bid(axi_bid), .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid),
        .axi_bready(axi_bready)
    );

    task automatic write_reg(input [7:0] address, input [31:0] value);
        begin
            @(negedge cpu_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b1;
            mmio_addr = address;
            mmio_wdata = value;
            mmio_wmask = 4'hf;
            @(negedge cpu_clk);
            mmio_valid = 1'b0;
            mmio_wen = 1'b0;
            mmio_wmask = 4'b0;
        end
    endtask

    task automatic wait_snapshot(input integer limit_cycles);
        integer wait_index;
        begin
            wait_index = 0;
            while (!mmio_rdata[1] && wait_index < limit_cycles) begin
                @(negedge cpu_clk);
                mmio_addr = 8'h08;
                wait_index = wait_index + 1;
            end
            if (!mmio_rdata[1]) $fatal(1, "快照未在期限内完成 ctrl=%08x cpu_state=%0d req=%b ack=%b mem_state=%0d preq=%b pack=%b psync=%b p_run=%b", mmio_rdata, dut.cpu_snapshot_state, dut.snapshot_req_toggle, dut.cpu_ack_sync, dut.mem_snapshot_state, dut.pclk_snapshot_req_toggle, dut.dvp_snapshot_ack, dut.pclk_ack_sync, pclk_run);
        end
    endtask

    task automatic send_byte(input [7:0] value);
        begin
            data = value;
            @(negedge pclk);
        end
    endtask

    task automatic send_frame;
        integer pixel_index;
        reg [15:0] pixel_value;
        begin
            @(negedge pclk);
            vsync = 1'b0;
            repeat (3) @(negedge pclk);
            href = 1'b1;
            for (pixel_index = 0; pixel_index < 16; pixel_index = pixel_index + 1) begin
                pixel_value = 16'h1000 + 16'(pixel_index);
                send_byte(pixel_value[15:8]);
                send_byte(pixel_value[7:0]);
            end
            href = 1'b0;
            repeat (3) @(negedge pclk);
            vsync = 1'b1;
            repeat (5) @(negedge pclk);
        end
    endtask

    // DDR 写通道收到数据握手后返回成功响应。
    always @(posedge mem_clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_bvalid <= 1'b0;
            axi_bid <= 8'h40;
            axi_bresp <= 2'b0;
        end else if (axi_wvalid && axi_wready) begin
            axi_bvalid <= 1'b1;
        end else if (axi_bvalid && axi_bready) begin
            axi_bvalid <= 1'b0;
        end
    end

    initial begin
        rst_n = 1'b0;
        repeat (4) @(negedge cpu_clk);
        rst_n = 1'b1;
        repeat (4) @(negedge cpu_clk);
        write_reg(8'h64, 32'h1);

        // PCLK 停止时请求快照，CPU 必须超时并清除 valid。
        write_reg(8'h08, 32'h1);
        repeat (45) @(negedge cpu_clk);
        mmio_addr = 8'h08;
        #1;
        if (!mmio_rdata[2] || mmio_rdata[1] || mmio_rdata[0])
            $fatal(1, "无 PCLK 超时状态错误 ctrl=%08x", mmio_rdata);

        // 迟到的 PCLK 应答只用于排空旧请求，不能污染 CPU 快照。
        pclk_run = 1'b1;
        repeat (30) @(negedge cpu_clk);
        mmio_addr = 8'h08;
        #1;
        if (mmio_rdata[1]) $fatal(1, "旧快照迟到应答污染 valid 位");

        // 排空完成后再次请求，新的快照应正常返回且序号仅增加一次。
        write_reg(8'h08, 32'h1);
        mmio_addr = 8'h08;
        wait_snapshot(100);
        mmio_addr = 8'h20;
        #1;
        if (mmio_rdata[0] || mmio_rdata[1])
            $fatal(1, "仅 DMA enable 时 CAM_STATUS enable/PCLK 应为零：%08x", mmio_rdata);

        capture_enable = 1'b1;
        repeat (8) @(negedge pclk);
        write_reg(8'h08, 32'h1);
        mmio_addr = 8'h08;
        wait_snapshot(100);
        mmio_addr = 8'h20;
        #1;
        if (!mmio_rdata[0] || !mmio_rdata[1])
            $fatal(1, "capture enable 后 CAM_STATUS enable/PCLK 应置位：%08x", mmio_rdata);

        // 停止 DDR 消费使 FIFO 溢出；下一帧 SOF 应恢复对齐并允许完整帧发布。
        ddr_ready = 1'b0;
        send_frame();
        if (!dut.fifo_overflow) $fatal(1, "首帧没有触发 FIFO 溢出 level=%0d max=%0d pclk=%0d frames=%0d full=%b drop=%b en=%b cap=%b p_rst=%b d_rst=%b", dut.fifo_rd_level, dut.fifo_wr_max_level, dut.dvp_pclk_count, dut.dvp_frame_count, dut.fifo_full, dut.drop_frame_pclk, dut.dma_enable, capture_enable, dut.pclk_rst_n, dut.u_dvp_rx.pclk_rst_n);
        ddr_ready = 1'b1;
        repeat (100) @(negedge mem_clk);
        send_frame();
        frame_wait = 0;
        while ((dut.dma_frame_count == 0) && (frame_wait < 500)) begin
            @(negedge mem_clk);
            frame_wait = frame_wait + 1;
        end
        if (dut.dma_frame_count != 1 || dut.dma_ready_mask == 0)
            $fatal(1, "溢出后下一帧未恢复完成 count=%0d ready=%b err=%0d",
                   dut.dma_frame_count, dut.dma_ready_mask, dut.dma_error_code);

        write_reg(8'h08, 32'h1);
        mmio_addr = 8'h08;
        wait_snapshot(100);
        mmio_addr = 8'h0c;
        #1;
        if (mmio_rdata != 1) $fatal(1, "DMA 完成帧计数快照错误：%0d", mmio_rdata);
        mmio_addr = 8'h2c;
        #1;
        if (mmio_rdata != 16)
            $fatal(1, "FIFO 历史峰值须保留完整宽度：%0d", mmio_rdata);
        mmio_addr = 8'h30;
        #1;
        if (!mmio_rdata[0]) $fatal(1, "FIFO overflow 未进入快照");
        mmio_addr = 8'h14;
        #1;
        if (mmio_rdata == 0) $fatal(1, "PCLK 恢复后的快照未冻结计数");
        frozen_pclk_count = mmio_rdata;
        pclk_run = 1'b0;
        repeat (8) @(negedge cpu_clk);
        #1;
        if (mmio_rdata != frozen_pclk_count)
            $fatal(1, "PCLK 停止后快照字段未保持稳定");
        mmio_addr = 8'h54;
        #1;
        if (mmio_rdata != 3) $fatal(1, "快照序号错误：%0d", mmio_rdata);

        $display("CAMERA_SNAPSHOT_OVERFLOW_RECOVERY_PASS");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "快照测试超时");
    end
endmodule
