`timescale 1ns / 1ps

// 双路 VGA 摄像头共享 DDR 写口验证。MMIO master 只用于直接驱动寄存器，
// 不代表 CPU 正在执行固件；真实固件端到端由独立 SoC 仿真负责。
module tb_camera_stereo;
    localparam integer W = 640;
    localparam integer H = 480;
    localparam integer PIXELS = W * H;
    localparam integer WORDS = PIXELS / 2;
    localparam integer SLOT_WORDS = 262144;

    reg cpu_clk = 1'b0;
    reg mem_clk = 1'b0;
    reg pclk1 = 1'b0;
    reg pclk2 = 1'b0;
    reg run_pclk2 = 1'b1;
    reg rst_n = 1'b0;
    reg ddr_ready = 1'b0;
    reg capture1 = 1'b0;
    reg capture2 = 1'b0;
    reg vsync1 = 1'b1, vsync2 = 1'b1;
    reg href1 = 1'b0, href2 = 1'b0;
    reg [7:0] data1 = 0, data2 = 0;

    reg mmio_valid1 = 0, mmio_wen1 = 0;
    reg [7:0] mmio_addr1 = 0;
    reg [31:0] mmio_wdata1 = 0;
    reg [3:0] mmio_wmask1 = 0;
    wire [31:0] mmio_rdata1;
    reg mmio_valid2 = 0, mmio_wen2 = 0;
    reg [7:0] mmio_addr2 = 0;
    reg [31:0] mmio_wdata2 = 0;
    reg [3:0] mmio_wmask2 = 0;
    wire [31:0] mmio_rdata2;

    wire [29:0] c1_awaddr, c2_awaddr;
    wire [7:0] c1_awid, c2_awid;
    wire [7:0] c1_awlen, c2_awlen;
    wire [2:0] c1_awsize, c2_awsize;
    wire [1:0] c1_awburst, c2_awburst;
    wire c1_awvalid, c2_awvalid, c1_awready, c2_awready;
    wire [255:0] c1_wdata, c2_wdata;
    wire [31:0] c1_wstrb, c2_wstrb;
    wire c1_wlast, c2_wlast, c1_wvalid, c2_wvalid, c1_wready, c2_wready;
    wire [7:0] c1_bid, c2_bid;
    wire [1:0] c1_bresp, c2_bresp;
    wire c1_bvalid, c2_bvalid, c1_bready, c2_bready;

    wire [29:0] d_awaddr;
    wire [7:0] d_awid, d_awlen;
    wire [2:0] d_awsize;
    wire [1:0] d_awburst;
    wire d_awvalid, d_awready;
    wire [255:0] d_wdata;
    wire [31:0] d_wstrb;
    wire d_wlast, d_wvalid, d_wready;
    wire [7:0] d_bid;
    wire [1:0] d_bresp;
    wire d_bvalid, d_bready;
    wire [29:0] d_araddr;
    wire [7:0] d_arid, d_arlen;
    wire [2:0] d_arsize;
    wire [1:0] d_arburst;
    wire d_arvalid, d_arready;
    wire [255:0] d_rdata;
    wire [7:0] d_rid;
    wire [1:0] d_rresp;
    wire d_rlast, d_rvalid, d_rready;

    integer aw_cam1 = 0;
    integer aw_cam2 = 0;
    integer w_cam1 = 0;
    integer w_cam2 = 0;
    integer b_cam1 = 0;
    integer b_cam2 = 0;
    reg frame_go1 = 0, frame_go2 = 0;
    integer frame_id1 = 0, frame_id2 = 0;

    always #5.55 cpu_clk = ~cpu_clk;
    always #4.15 mem_clk = ~mem_clk;
    always #7.15 pclk1 = ~pclk1;
    always begin
        #8.35;
        if (run_pclk2) pclk2 = ~pclk2;
    end

    // 独立 PCLK 驱动进程保持两路波形真正并发，避免跨时钟任务互相阻塞。
    initial begin
        forever begin
            wait (frame_go1);
            frame_go1 = 0;
            send_frame(1, frame_id1);
        end
    end
    initial begin
        forever begin
            wait (frame_go2);
            frame_go2 = 0;
            send_frame(2, frame_id2);
        end
    end

    Hcamera_subsystem #(
        .DDR_BASE(32'h8000_0000), .DDR_BYTES(32'h4000_0000),
        .BUFFER0_ADDR(32'hb800_0000), .BUFFER1_ADDR(32'hb810_0000),
        .FRAME_WIDTH(W), .FRAME_HEIGHT(H), .FIFO_ADDR_WIDTH(10),
        .DMA_TIMEOUT_CYCLES(1000000), .SNAPSHOT_TIMEOUT_CYCLES(3000),
        .AXI_ID(8'h40)
    ) cam1 (
        .consumer_ready_mask(), .consumer_frame0(), .consumer_frame1(),
        .consumer_release_valid(1'b0), .consumer_release_mask(2'b0),
        .cpu_clk(cpu_clk), .mem_clk(mem_clk), .rst_n(rst_n),
        .ddr_ready(ddr_ready), .capture_enable(capture1),
        .pclk(pclk1), .vsync(vsync1), .href(href1), .data(data1),
        .mmio_valid(mmio_valid1), .mmio_wen(mmio_wen1), .mmio_addr(mmio_addr1),
        .mmio_wdata(mmio_wdata1), .mmio_wmask(mmio_wmask1), .mmio_rdata(mmio_rdata1),
        .axi_awaddr(c1_awaddr), .axi_awid(c1_awid), .axi_awlen(c1_awlen),
        .axi_awsize(c1_awsize), .axi_awburst(c1_awburst), .axi_awvalid(c1_awvalid),
        .axi_awready(c1_awready), .axi_wdata(c1_wdata), .axi_wstrb(c1_wstrb),
        .axi_wlast(c1_wlast), .axi_wvalid(c1_wvalid), .axi_wready(c1_wready),
        .axi_bid(c1_bid), .axi_bresp(c1_bresp), .axi_bvalid(c1_bvalid),
        .axi_bready(c1_bready)
    );

    Hcamera_subsystem #(
        .DDR_BASE(32'h8000_0000), .DDR_BYTES(32'h4000_0000),
        .BUFFER0_ADDR(32'hb820_0000), .BUFFER1_ADDR(32'hb830_0000),
        .FRAME_WIDTH(W), .FRAME_HEIGHT(H), .FIFO_ADDR_WIDTH(10),
        .DMA_TIMEOUT_CYCLES(1000000), .SNAPSHOT_TIMEOUT_CYCLES(3000),
        .AXI_ID(8'h41)
    ) cam2 (
        .consumer_ready_mask(), .consumer_frame0(), .consumer_frame1(),
        .consumer_release_valid(1'b0), .consumer_release_mask(2'b0),
        .cpu_clk(cpu_clk), .mem_clk(mem_clk), .rst_n(rst_n),
        .ddr_ready(ddr_ready), .capture_enable(capture2),
        .pclk(pclk2), .vsync(vsync2), .href(href2), .data(data2),
        .mmio_valid(mmio_valid2), .mmio_wen(mmio_wen2), .mmio_addr(mmio_addr2),
        .mmio_wdata(mmio_wdata2), .mmio_wmask(mmio_wmask2), .mmio_rdata(mmio_rdata2),
        .axi_awaddr(c2_awaddr), .axi_awid(c2_awid), .axi_awlen(c2_awlen),
        .axi_awsize(c2_awsize), .axi_awburst(c2_awburst), .axi_awvalid(c2_awvalid),
        .axi_awready(c2_awready), .axi_wdata(c2_wdata), .axi_wstrb(c2_wstrb),
        .axi_wlast(c2_wlast), .axi_wvalid(c2_wvalid), .axi_wready(c2_wready),
        .axi_bid(c2_bid), .axi_bresp(c2_bresp), .axi_bvalid(c2_bvalid),
        .axi_bready(c2_bready)
    );

    // 复用 SoC 同级两主仲裁器，CPU/NPU 端分别接 CAM1/CAM2 写通道。
    // 本轮相机没有 DDR 读请求，两个读主机接口固定为零。
    Haxi_2m1s_arbiter cam_write_arbiter (
        .clk(mem_clk), .rst_n(rst_n),
        .cpu_axi_awaddr(c1_awaddr), .cpu_axi_awid(c1_awid), .cpu_axi_awlen(c1_awlen),
        .cpu_axi_awsize(c1_awsize), .cpu_axi_awburst(c1_awburst),
        .cpu_axi_awvalid(c1_awvalid), .cpu_axi_awready(c1_awready),
        .cpu_axi_wdata(c1_wdata), .cpu_axi_wstrb(c1_wstrb), .cpu_axi_wlast(c1_wlast),
        .cpu_axi_wvalid(c1_wvalid), .cpu_axi_wready(c1_wready),
        .cpu_axi_bid(c1_bid), .cpu_axi_bresp(c1_bresp), .cpu_axi_bvalid(c1_bvalid),
        .cpu_axi_bready(c1_bready),
        .cpu_axi_araddr(30'b0), .cpu_axi_arid(8'b0), .cpu_axi_arlen(8'b0),
        .cpu_axi_arsize(3'b0), .cpu_axi_arburst(2'b0), .cpu_axi_arvalid(1'b0),
        .cpu_axi_arready(), .cpu_axi_rdata(), .cpu_axi_rid(), .cpu_axi_rresp(),
        .cpu_axi_rlast(), .cpu_axi_rvalid(), .cpu_axi_rready(1'b0),
        .npu_axi_awaddr(c2_awaddr), .npu_axi_awid(c2_awid), .npu_axi_awlen(c2_awlen),
        .npu_axi_awsize(c2_awsize), .npu_axi_awburst(c2_awburst),
        .npu_axi_awvalid(c2_awvalid), .npu_axi_awready(c2_awready),
        .npu_axi_wdata(c2_wdata), .npu_axi_wstrb(c2_wstrb), .npu_axi_wlast(c2_wlast),
        .npu_axi_wvalid(c2_wvalid), .npu_axi_wready(c2_wready),
        .npu_axi_bid(c2_bid), .npu_axi_bresp(c2_bresp), .npu_axi_bvalid(c2_bvalid),
        .npu_axi_bready(c2_bready),
        .npu_axi_araddr(30'b0), .npu_axi_arid(8'b0), .npu_axi_arlen(8'b0),
        .npu_axi_arsize(3'b0), .npu_axi_arburst(2'b0), .npu_axi_arvalid(1'b0),
        .npu_axi_arready(), .npu_axi_rdata(), .npu_axi_rid(), .npu_axi_rresp(),
        .npu_axi_rlast(), .npu_axi_rvalid(), .npu_axi_rready(1'b0),
        .ddr_axi_awaddr(d_awaddr), .ddr_axi_awid(d_awid), .ddr_axi_awlen(d_awlen),
        .ddr_axi_awsize(d_awsize), .ddr_axi_awburst(d_awburst),
        .ddr_axi_awvalid(d_awvalid), .ddr_axi_awready(d_awready),
        .ddr_axi_wdata(d_wdata), .ddr_axi_wstrb(d_wstrb), .ddr_axi_wlast(d_wlast),
        .ddr_axi_wvalid(d_wvalid), .ddr_axi_wready(d_wready),
        .ddr_axi_bid(d_bid), .ddr_axi_bresp(d_bresp), .ddr_axi_bvalid(d_bvalid),
        .ddr_axi_bready(d_bready),
        .ddr_axi_araddr(d_araddr), .ddr_axi_arid(d_arid), .ddr_axi_arlen(d_arlen),
        .ddr_axi_arsize(d_arsize), .ddr_axi_arburst(d_arburst),
        .ddr_axi_arvalid(d_arvalid), .ddr_axi_arready(d_arready),
        .ddr_axi_rdata(d_rdata), .ddr_axi_rid(d_rid), .ddr_axi_rresp(d_rresp),
        .ddr_axi_rlast(d_rlast), .ddr_axi_rvalid(d_rvalid), .ddr_axi_rready(d_rready)
    );

    camera_ddr_model #(.FRAME_SLOTS(4)) ddr (
        .clk(mem_clk), .rst_n(rst_n),
        .axi_awaddr(d_awaddr), .axi_awid(d_awid), .axi_awlen(d_awlen),
        .axi_awsize(d_awsize), .axi_awburst(d_awburst), .axi_awvalid(d_awvalid),
        .axi_awready(d_awready), .axi_wdata(d_wdata), .axi_wstrb(d_wstrb),
        .axi_wlast(d_wlast), .axi_wvalid(d_wvalid), .axi_wready(d_wready),
        .axi_bid(d_bid), .axi_bresp(d_bresp), .axi_bvalid(d_bvalid), .axi_bready(d_bready),
        .axi_araddr(d_araddr), .axi_arid(d_arid), .axi_arlen(d_arlen),
        .axi_arsize(d_arsize), .axi_arburst(d_arburst), .axi_arvalid(d_arvalid),
        .axi_arready(d_arready), .axi_rdata(d_rdata), .axi_rid(d_rid),
        .axi_rresp(d_rresp), .axi_rlast(d_rlast), .axi_rvalid(d_rvalid),
        .axi_rready(d_rready)
    );

    always @(posedge mem_clk) begin
        if (rst_n && d_awvalid && d_awready) begin
            if (d_awid == 8'h40) aw_cam1 <= aw_cam1 + 1;
            else if (d_awid == 8'h41) aw_cam2 <= aw_cam2 + 1;
            else $fatal(1, "写事务 AXI ID 未按相机隔离：%02x", d_awid);
        end
        if (rst_n && d_wvalid && d_wready) begin
            if (ddr.saved_id == 8'h40) w_cam1 <= w_cam1 + 1;
            else if (ddr.saved_id == 8'h41) w_cam2 <= w_cam2 + 1;
        end
        if (rst_n && d_bvalid && d_bready) begin
            if (d_bid == 8'h40) b_cam1 <= b_cam1 + 1;
            else if (d_bid == 8'h41) b_cam2 <= b_cam2 + 1;
        end
    end

    function automatic [15:0] pixel_pattern(input integer camera_id,
                                             input integer frame_id,
                                             input integer pixel_index);
        reg [31:0] mixed;
        begin
            mixed = pixel_index * (camera_id == 1 ? 3 : 11) +
                    frame_id * (camera_id == 1 ? 32'h0000_1234 : 32'h0000_6b2d) +
                    (camera_id == 1 ? 32'h5a3c : 32'ha719);
            pixel_pattern = mixed[15:0] ^ (camera_id == 1 ? 16'h0000 : 16'hffff);
        end
    endfunction

    function automatic [31:0] frame_checksum(input integer camera_id,
                                             input integer frame_id);
        integer p;
        reg [31:0] sum;
        begin
            sum = 0;
            for (p = 0; p < PIXELS; p = p + 1)
                sum = sum + {16'b0, pixel_pattern(camera_id, frame_id, p)};
            frame_checksum = sum;
        end
    endfunction

    task automatic write_reg(input integer camera_id, input [7:0] addr,
                             input [31:0] value);
        begin
            @(negedge cpu_clk);
            if (camera_id == 1) begin
                mmio_valid1 = 1; mmio_wen1 = 1; mmio_addr1 = addr;
                mmio_wdata1 = value; mmio_wmask1 = 4'hf;
            end else begin
                mmio_valid2 = 1; mmio_wen2 = 1; mmio_addr2 = addr;
                mmio_wdata2 = value; mmio_wmask2 = 4'hf;
            end
            @(negedge cpu_clk);
            if (camera_id == 1) begin mmio_valid1 = 0; mmio_wen1 = 0; mmio_wmask1 = 0; end
            else begin mmio_valid2 = 0; mmio_wen2 = 0; mmio_wmask2 = 0; end
        end
    endtask

    task automatic read_reg(input integer camera_id, input [7:0] addr,
                            output [31:0] value);
        begin
            @(negedge cpu_clk);
            if (camera_id == 1) begin mmio_valid1 = 1; mmio_wen1 = 0; mmio_addr1 = addr; end
            else begin mmio_valid2 = 1; mmio_wen2 = 0; mmio_addr2 = addr; end
            #1;
            value = camera_id == 1 ? mmio_rdata1 : mmio_rdata2;
            @(negedge cpu_clk);
            if (camera_id == 1) mmio_valid1 = 0; else mmio_valid2 = 0;
        end
    endtask

    task automatic take_snapshot(input integer camera_id);
        reg [31:0] control;
        integer poll;
        begin
            write_reg(camera_id, 8'h08, 1);
            control = 0;
            poll = 0;
            while (!control[1] && !control[2] && poll < 10000) begin
                read_reg(camera_id, 8'h08, control);
                poll = poll + 1;
            end
            if (!control[1] || control[2])
                $fatal(1, "CAM%0d 快照失败 control=%08x", camera_id, control);
        end
    endtask

    task automatic send_byte(input integer camera_id, input [7:0] value);
        begin
            if (camera_id == 1) begin
                data1 = value;
                @(negedge pclk1);
            end else begin
                data2 = value;
                @(negedge pclk2);
            end
        end
    endtask

    task automatic send_frame(input integer camera_id, input integer frame_id);
        integer row, col;
        reg [15:0] pix;
        begin
            if (camera_id == 1) begin
                @(negedge pclk1);
            end else begin
                @(negedge pclk2);
            end
            if (camera_id == 1) begin vsync1 = 0; href1 = 0; end
            else begin vsync2 = 0; href2 = 0; end
            repeat (3) begin
                if (camera_id == 1) begin @(negedge pclk1); end
                else begin @(negedge pclk2); end
            end
            for (row = 0; row < H; row = row + 1) begin
                if (camera_id == 1) begin @(negedge pclk1); end
                else begin @(negedge pclk2); end
                if (camera_id == 1) href1 = 1; else href2 = 1;
                for (col = 0; col < W; col = col + 1) begin
                    pix = pixel_pattern(camera_id, frame_id, row * W + col);
                    send_byte(camera_id, pix[15:8]);
                    send_byte(camera_id, pix[7:0]);
                end
                if (camera_id == 1) begin href1 = 0; data1 = 0; end
                else begin href2 = 0; data2 = 0; end
                repeat (2) begin
                    if (camera_id == 1) begin @(negedge pclk1); end
                    else begin @(negedge pclk2); end
                end
            end
            if (camera_id == 1) begin vsync1 = 1; href1 = 0; data1 = 0; end
            else begin vsync2 = 1; href2 = 0; data2 = 0; end
            repeat (5) begin
                if (camera_id == 1) begin @(negedge pclk1); end
                else begin @(negedge pclk2); end
            end
        end
    endtask

    task automatic launch_pair(input integer frame_id);
        begin
            frame_id1 = frame_id;
            frame_id2 = frame_id;
            frame_go1 = 1;
            frame_go2 = 1;
            // VGA 图案长度固定；留出帧尾及 DDR 排空余量。
            repeat (1500000) @(posedge mem_clk);
        end
    endtask

    task automatic launch_cam1(input integer frame_id);
        begin
            frame_id1 = frame_id;
            frame_go1 = 1;
            repeat (1300000) @(posedge mem_clk);
        end
    endtask

    task automatic wait_frames(input integer camera_id, input integer count);
        integer guard;
        begin
            guard = 0;
            if (camera_id == 1) begin
                while (cam1.u_dma.frame_count < count && guard < 4000000) begin
                    @(posedge mem_clk);
                    guard = guard + 1;
                end
                if (cam1.u_dma.frame_count < count)
                    $fatal(1, "CAM1 DMA timeout count=%0d DVP=%0d pixels=%0d fifo=%0d error=%0d",
                           cam1.u_dma.frame_count, cam1.u_dvp_rx.frame_count,
                           cam1.u_dvp_rx.current_frame_pixels, cam1.fifo_rd_level,
                           cam1.u_dma.error_code);
            end else begin
                while (cam2.u_dma.frame_count < count && guard < 4000000) begin
                    @(posedge mem_clk);
                    guard = guard + 1;
                end
                if (cam2.u_dma.frame_count < count)
                    $fatal(1, "CAM2 DMA timeout count=%0d DVP=%0d pixels=%0d fifo=%0d error=%0d",
                           cam2.u_dma.frame_count, cam2.u_dvp_rx.frame_count,
                           cam2.u_dvp_rx.current_frame_pixels, cam2.fifo_rd_level,
                           cam2.u_dma.error_code);
            end
            repeat (20) @(posedge mem_clk);
        end
    endtask

    task automatic verify_frame(input integer camera_id, input integer frame_id,
                                input integer slot);
        integer word_no;
        integer pixel_no;
        integer base_word;
        reg [31:0] actual;
        reg [15:0] expected_lo, expected_hi;
        reg [31:0] sum;
        begin
            base_word = (camera_id == 1 ? 0 : 2 * SLOT_WORDS) + slot * SLOT_WORDS;
            sum = 0;
            for (word_no = 0; word_no < WORDS; word_no = word_no + 1) begin
                pixel_no = word_no * 2;
                expected_lo = pixel_pattern(camera_id, frame_id, pixel_no);
                expected_hi = pixel_pattern(camera_id, frame_id, pixel_no + 1);
                actual = ddr.frame_mem[base_word + word_no];
                if (actual !== {expected_hi, expected_lo})
                    $fatal(1, "CAM%0d DDR 内容错误 frame=%0d pixel=%0d actual=%08x expected=%08x",
                           camera_id, frame_id, pixel_no, actual, {expected_hi, expected_lo});
                sum = sum + {16'b0, expected_lo} + {16'b0, expected_hi};
            end
            if (sum !== frame_checksum(camera_id, frame_id))
                $fatal(1, "testbench checksum 计算不一致");
            $display("STEREO_DDR_FRAME_PASS camera=%0d frame=%0d slot=%0d checksum=%08x",
                     camera_id, frame_id, slot, sum);
        end
    endtask

    task automatic check_snapshot(input integer camera_id, input integer frame_count,
                                  input [31:0] addr, input [31:0] ready_mask,
                                  input integer frame_id);
        reg [31:0] got;
        begin
            read_reg(camera_id, 8'h0c, got);
            if (got !== frame_count) $fatal(1, "CAM%0d snapshot frames=%0d expected=%0d", camera_id, got, frame_count);
            read_reg(camera_id, 8'h10, got);
            if (got !== PIXELS) $fatal(1, "CAM%0d pixel_count=%0d", camera_id, got);
            read_reg(camera_id, 8'h24, got);
            if (got !== PIXELS * 2) $fatal(1, "CAM%0d byte_count=%0d", camera_id, got);
            read_reg(camera_id, 8'h1c, got);
            if (got !== H) $fatal(1, "CAM%0d line_count=%0d", camera_id, got);
            read_reg(camera_id, 8'h3c, got);
            if (got !== addr) $fatal(1, "CAM%0d frame addr=%08x expected=%08x", camera_id, got, addr);
            read_reg(camera_id, 8'h4c, got);
            if (got !== ready_mask) $fatal(1, "CAM%0d ready mask=%b expected=%b", camera_id, got, ready_mask);
            read_reg(camera_id, 8'h48, got);
            if (got !== frame_checksum(camera_id, frame_id))
                $fatal(1, "CAM%0d checksum=%08x expected=%08x", camera_id, got, frame_checksum(camera_id, frame_id));
        end
    endtask

    initial begin : test_sequence
        reg [31:0] value;
        integer before1, before2;
        repeat (8) @(negedge cpu_clk);
        rst_n = 1;
        ddr_ready = 1;
        repeat (8) @(negedge cpu_clk);
        write_reg(1, 8'h64, 1);
        write_reg(2, 8'h64, 1);
        repeat (8) @(posedge mem_clk);
        capture1 = 1;
        capture2 = 1;
        repeat (8) @(negedge pclk1);
        repeat (8) @(negedge pclk2);

        // 两个真实 640x480 DVP 流并发写入，通过不同 AXI ID 路由到独立槽。
        launch_pair(0);
        wait_frames(1, 1);
        wait_frames(2, 1);
        verify_frame(1, 0, 0);
        verify_frame(2, 0, 0);
        if (frame_checksum(1, 0) == frame_checksum(2, 0))
            $fatal(1, "CAM1/CAM2 测试图案 checksum 必须不同");
        take_snapshot(1);
        take_snapshot(2);
        check_snapshot(1, 1, 32'hb800_0000, 1, 0);
        check_snapshot(2, 1, 32'hb820_0000, 1, 0);

        // 快照被冻结时两路再并发采集下一帧，CPU 视图保持首帧描述不变。
        launch_pair(1);
        wait_frames(1, 2);
        wait_frames(2, 2);
        verify_frame(1, 1, 1);
        verify_frame(2, 1, 1);
        check_snapshot(1, 1, 32'hb800_0000, 1, 0);
        check_snapshot(2, 1, 32'hb820_0000, 1, 0);

        // 两个 READY buffer 均占用时再送帧，DMA 不得覆盖已有 DDR 内容。
        before1 = aw_cam1 + aw_cam2;
        launch_pair(2);
        repeat (100) @(posedge mem_clk);
        if (cam1.u_dma.frame_count != 2 || cam2.u_dma.frame_count != 2 ||
            cam1.u_dma.ready_mask != 2'b11 || cam2.u_dma.ready_mask != 2'b11 ||
            cam1.u_dma.dropped_frames == 0 || cam2.u_dma.dropped_frames == 0)
            $fatal(1, "READY 占用/丢帧保护错误 c1=%0d/%b c2=%0d/%b",
                   cam1.u_dma.frame_count, cam1.u_dma.ready_mask,
                   cam2.u_dma.frame_count, cam2.u_dma.ready_mask);
        if (aw_cam1 + aw_cam2 != before1)
            $fatal(1, "READY 双槽占用时仍发生 DDR 写事务");
        verify_frame(1, 0, 0);
        verify_frame(1, 1, 1);
        verify_frame(2, 0, 0);
        verify_frame(2, 1, 1);

        // 释放首槽并重新写回；CPU 快照仍显示旧帧，直到显式请求新快照。
        write_reg(1, 8'h60, 1);
        write_reg(2, 8'h60, 1);
        repeat (20) @(posedge mem_clk);
        launch_pair(3);
        wait_frames(1, 3);
        wait_frames(2, 3);
        verify_frame(1, 3, 0);
        verify_frame(2, 3, 0);
        check_snapshot(1, 1, 32'hb800_0000, 1, 0);
        check_snapshot(2, 1, 32'hb820_0000, 1, 0);
        take_snapshot(1);
        take_snapshot(2);
        check_snapshot(1, 3, 32'hb800_0000, 3, 3);
        check_snapshot(2, 3, 32'hb820_0000, 3, 3);

        // 停止 CAM2 PCLK 时其快照应超时；CAM1 仍可独立完成下一帧。
        write_reg(1, 8'h60, 2);
        run_pclk2 = 0;
        write_reg(2, 8'h08, 1);
        launch_cam1(4);
        repeat (3200) @(negedge cpu_clk);
        read_reg(2, 8'h08, value);
        if (!value[2] || value[1]) $fatal(1, "CAM2 停钟快照未超时/valid=%08x", value);
        wait_frames(1, 4);
        verify_frame(1, 4, 1);
        run_pclk2 = 1;
        repeat (30) @(negedge pclk2);
        take_snapshot(2);
        if (cam1.u_dma.frame_count != 4)
            $fatal(1, "CAM1 在 CAM2 停钟期间未完成新帧 count=%0d", cam1.u_dma.frame_count);

        if (aw_cam1 == 0 || aw_cam2 == 0 || w_cam1 == 0 || w_cam2 == 0 ||
            b_cam1 == 0 || b_cam2 == 0)
            $fatal(1, "AXI AW/W/B 路由未覆盖 CAM1=%0d/%0d/%0d CAM2=%0d/%0d/%0d",
                   aw_cam1, w_cam1, b_cam1, aw_cam2, w_cam2, b_cam2);
        $display("CAMERA_STEREO_PASS cam1_aw=%0d cam2_aw=%0d cam1_w=%0d cam2_w=%0d cam1_b=%0d cam2_b=%0d",
                 aw_cam1, aw_cam2, w_cam1, w_cam2, b_cam1, b_cam2);
        $finish;
    end

    initial begin
        #200000000;
        $fatal(1, "双路相机 VGA 集成测试超时");
    end
endmodule
