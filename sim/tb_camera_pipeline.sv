`timescale 1ns / 1ps

// CAM1 DVP 到 DDR 的完整 VGA 集成验证，CPU、DDR 与 PCLK 使用异步时钟。
module tb_camera_pipeline;
    `include "camera_regs.vh"

    localparam integer FRAME_WIDTH  = 640;
    localparam integer FRAME_HEIGHT = 480;
    localparam integer FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;
    localparam integer FRAME_WORDS  = FRAME_PIXELS / 2;
    localparam integer FRAME_BEATS  = FRAME_PIXELS / 16;
    localparam integer SLOT1_WORD   = 262144;

    reg cpu_clk = 1'b0;
    reg mem_clk = 1'b0;
    reg pclk = 1'b0;
    reg rst_n = 1'b0;
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

    integer i;
    integer old_camera_writes;
    integer fifo_pixels_written = 0;
    integer fifo_pixels_read = 0;
    integer fifo_eols_written = 0;
    integer fifo_eols_read = 0;
    reg [31:0] reg_value;
    reg [31:0] frozen_frame_count;
    reg [31:0] frozen_pixel_count;
    reg [31:0] frozen_byte_count;
    reg [31:0] frozen_line_count;
    reg [31:0] frozen_address;
    reg [31:0] frozen_checksum;
    reg [31:0] frozen_current_buffer;
    reg [31:0] frozen_ready_mask;
    reg [31:0] second_mid_current_pixels;
    reg [31:0] second_mid_fifo_level;
    reg [31:0] second_mid_fifo_max;

    // 三个时钟频率互不成整数倍，覆盖 CDC 相位变化。
    always #5.55 cpu_clk = ~cpu_clk;
    always #4.15 mem_clk = ~mem_clk;
    always #20.5 pclk = ~pclk;

    always @(posedge pclk) begin
        if (!rst_n) begin
            fifo_pixels_written <= 0;
            fifo_eols_written <= 0;
        end else if (dut.fifo_wr_en && !dut.fifo_full) begin
            if (dut.fifo_wr_data[17:16] == 2'b00)
                fifo_pixels_written <= fifo_pixels_written + 1;
            if (dut.fifo_wr_data[17:16] == 2'b11)
                fifo_eols_written <= fifo_eols_written + 1;
        end
    end

    always @(posedge mem_clk) begin
        if (!rst_n) begin
            fifo_pixels_read <= 0;
            fifo_eols_read <= 0;
        end else if (dut.fifo_rd_valid) begin
            if (dut.fifo_rd_data[17:16] == 2'b00)
                fifo_pixels_read <= fifo_pixels_read + 1;
            if (dut.fifo_rd_data[17:16] == 2'b11)
                fifo_eols_read <= fifo_eols_read + 1;
        end
    end

    Hcamera_subsystem #(
        .DDR_BASE(32'h8000_0000),
        .DDR_BYTES(32'h4000_0000),
        .BUFFER0_ADDR(32'hb800_0000),
        .BUFFER1_ADDR(32'hb810_0000),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .FIFO_ADDR_WIDTH(10),
        .DMA_TIMEOUT_CYCLES(1000000),
        .SNAPSHOT_TIMEOUT_CYCLES(1000000)
    ) dut (
        .cpu_clk(cpu_clk), .mem_clk(mem_clk), .rst_n(rst_n),
        .ddr_ready(ddr_ready), .capture_enable(capture_enable),
        .pclk(pclk), .vsync(vsync), .href(href), .data(data),
        .mmio_valid(mmio_valid), .mmio_wen(mmio_wen),
        .mmio_addr(mmio_addr), .mmio_wdata(mmio_wdata),
        .mmio_wmask(mmio_wmask), .mmio_rdata(mmio_rdata),
        .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
        .axi_bid(axi_bid), .axi_bresp(axi_bresp),
        .axi_bvalid(axi_bvalid), .axi_bready(axi_bready)
    );

    // CPU 从 DDR 模型的 frame_mem 直接核对，DDR 读口保持空闲。
    camera_ddr_model ddr (
        .clk(mem_clk), .rst_n(rst_n),
        .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
        .axi_bid(axi_bid), .axi_bresp(axi_bresp),
        .axi_bvalid(axi_bvalid), .axi_bready(axi_bready),
        .axi_araddr(30'b0), .axi_arid(8'b0), .axi_arlen(8'b0),
        .axi_arsize(3'b0), .axi_arburst(2'b0), .axi_arvalid(1'b0),
        .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
        .axi_rresp(axi_rresp), .axi_rlast(axi_rlast),
        .axi_rvalid(axi_rvalid), .axi_rready(1'b0)
    );

    function automatic [15:0] pixel_pattern(input integer frame_id,
                                             input integer pixel_index);
        begin
            if (frame_id == 0)
                pixel_pattern = 16'(pixel_index) ^ 16'h5a3c;
            else if (frame_id == 1)
                pixel_pattern = 16'(pixel_index * 3 + 32'h0000_1234);
            else if (frame_id == 2)
                pixel_pattern = 16'(pixel_index * 5 + 32'h0000_4321);
            else
                pixel_pattern = 16'(pixel_index * 7 + 32'h0000_2468);
        end
    endfunction

    task automatic mmio_write(input [7:0] address, input [31:0] value);
        begin
            @(negedge cpu_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b1;
            mmio_addr = address;
            mmio_wdata = value;
            mmio_wmask = 4'hf;
            @(posedge cpu_clk);
            #1;
            @(negedge cpu_clk);
            mmio_valid = 1'b0;
            mmio_wen = 1'b0;
            mmio_wmask = 4'b0;
        end
    endtask

    task automatic mmio_read(input [7:0] address, output [31:0] value);
        begin
            @(negedge cpu_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b0;
            mmio_addr = address;
            #1;
            value = mmio_rdata;
            @(negedge cpu_clk);
            mmio_valid = 1'b0;
        end
    endtask

    task automatic expect_reg(input [7:0] address,
                              input [31:0] expected,
                              input [8*32-1:0] label_text);
        reg [31:0] actual;
        begin
            mmio_read(address, actual);
            if (actual !== expected)
                $fatal(1, "MMIO %0s offset=%02x actual=%08x expected=%08x",
                       label_text, address, actual, expected);
        end
    endtask

    task automatic take_snapshot;
        reg [31:0] control;
        integer poll_count;
        begin
            mmio_write(`CAM_SNAPSHOT_CTRL, 32'h1);
            control = 0;
            poll_count = 0;
            while ((control[1] !== 1'b1) && (control[2] !== 1'b1) &&
                   (poll_count < 20000)) begin
                mmio_read(`CAM_SNAPSHOT_CTRL, control);
                poll_count = poll_count + 1;
            end
            if (control[2])
                $fatal(1, "快照超时 control=%08x", control);
            if (!control[1])
                $fatal(1, "快照未在轮询预算内完成 control=%08x", control);
        end
    endtask

    task automatic send_byte(input [7:0] value);
        begin
            data = value;
            @(negedge pclk);
        end
    endtask

    task automatic send_frame(input integer frame_id);
        integer row;
        integer col;
        reg [15:0] pixel;
        reg [31:0] mid_frame_checksum;
        reg [31:0] mid_frame_count;
        reg [31:0] mid_pixel_count;
        reg [31:0] mid_byte_count;
        reg [31:0] mid_line_count;
        reg [31:0] mid_address;
        reg [31:0] mid_last_complete;
        reg [31:0] mid_current_pixels;
        reg [31:0] mid_current_buffer;
        reg [31:0] mid_ready_mask;
        reg [31:0] mid_fifo_level;
        reg [31:0] mid_fifo_max;
        begin
            @(negedge pclk);
            vsync = 1'b0;
            repeat (3) @(negedge pclk);
            for (row = 0; row < FRAME_HEIGHT; row = row + 1) begin
                // MMIO 快照会按 CPU 时钟返回，重新对齐 PCLK 后再拉高 HREF。
                @(negedge pclk);
                href = 1'b1;
                for (col = 0; col < FRAME_WIDTH; col = col + 1) begin
                    pixel = pixel_pattern(frame_id, row * FRAME_WIDTH + col);
                    send_byte(pixel[15:8]);
                    send_byte(pixel[7:0]);
                end
                href = 1'b0;
                data = 8'b0;
                repeat (2) @(negedge pclk);
                if ((frame_id == 1) && (row == 5)) begin
                    // 新请求必须同时冻结上一完成帧与正在采集帧的独立元数据。
                    take_snapshot();
                    mmio_read(`CAM_FRAME_COUNT, mid_frame_count);
                    mmio_read(`CAM_PIXEL_COUNT, mid_pixel_count);
                    mmio_read(`CAM_BYTE_COUNT, mid_byte_count);
                    mmio_read(`CAM_LINE_COUNT, mid_line_count);
                    mmio_read(`CAM_LAST_FRAME_ADDR, mid_address);
                    mmio_read(`CAM_LAST_COMPLETE_BUFFER, mid_last_complete);
                    mmio_read(`CAM_FRAME_CHECKSUM, mid_frame_checksum);
                    mmio_read(`CAM_CURRENT_PIXEL_COUNT, mid_current_pixels);
                    mmio_read(`CAM_CURRENT_WRITE_BUFFER, mid_current_buffer);
                    mmio_read(`CAM_READY_MASK, mid_ready_mask);
                    mmio_read(`CAM_FIFO_LEVEL, mid_fifo_level);
                    mmio_read(`CAM_FIFO_MAX_LEVEL, mid_fifo_max);

                    if (mid_frame_count != 1 || mid_pixel_count != FRAME_PIXELS ||
                        mid_byte_count != FRAME_PIXELS * 2 || mid_line_count != FRAME_HEIGHT ||
                        mid_address != 32'hb800_0000 || mid_last_complete != 0 ||
                        mid_frame_checksum != ddr_checksum(0))
                        $fatal(1, "帧中快照的完成元数据被当前帧污染 frame=%0d pixels=%0d bytes=%0d lines=%0d addr=%08x checksum=%08x",
                               mid_frame_count, mid_pixel_count, mid_byte_count,
                               mid_line_count, mid_address, mid_frame_checksum);
                    if (mid_current_pixels == 0 || mid_current_buffer != 1 ||
                        mid_ready_mask != 1)
                        $fatal(1, "帧中快照当前帧字段错误 current_pixels=%0d current_buffer=%0d ready=%0d",
                               mid_current_pixels, mid_current_buffer, mid_ready_mask);
                    if (mid_fifo_level > 1024 || mid_fifo_max > 1024 ||
                        mid_fifo_level != dut.cpu_fifo_level ||
                        mid_fifo_max != dut.cpu_fifo_max_level)
                        $fatal(1, "FIFO 快照水位疑似截断 level=%0d max=%0d",
                               mid_fifo_level, mid_fifo_max);
                    second_mid_current_pixels = mid_current_pixels;
                    second_mid_fifo_level = mid_fifo_level;
                    second_mid_fifo_max = mid_fifo_max;
                end
                if ((frame_id == 1) && (row == 4)) begin
                    // 快照仍在冻结首帧时，第二帧正处于 DMA 活跃状态。
                    if (!dut.u_dma.frame_active)
                        $fatal(1, "第二帧中途 DMA 未处于 active");
                    expect_reg(`CAM_FRAME_COUNT, frozen_frame_count,
                               "FROZEN_FRAME_COUNT");
                    expect_reg(`CAM_PIXEL_COUNT, frozen_pixel_count,
                               "FROZEN_PIXEL_COUNT");
                    expect_reg(`CAM_BYTE_COUNT, frozen_byte_count,
                               "FROZEN_BYTE_COUNT");
                    expect_reg(`CAM_LINE_COUNT, frozen_line_count,
                               "FROZEN_LINE_COUNT");
                    expect_reg(`CAM_LAST_FRAME_ADDR, frozen_address,
                               "FROZEN_ADDRESS");
                    expect_reg(`CAM_CURRENT_WRITE_BUFFER, frozen_current_buffer,
                               "FROZEN_CURRENT_BUFFER");
                    expect_reg(`CAM_READY_MASK, frozen_ready_mask,
                               "FROZEN_READY_MASK");
                    expect_reg(`CAM_FRAME_CHECKSUM, frozen_checksum,
                               "FROZEN_CHECKSUM");
                end
            end
            vsync = 1'b1;
            href = 1'b0;
            data = 8'b0;
            repeat (5) @(negedge pclk);
        end
    endtask

    task automatic wait_dma_frames(input integer expected_frames);
        integer timeout_cycles;
        begin
            timeout_cycles = 0;
            while ((dut.u_dma.frame_count < expected_frames) &&
                   (timeout_cycles < 4000000)) begin
                @(posedge mem_clk);
                timeout_cycles = timeout_cycles + 1;
            end
            if (dut.u_dma.frame_count < expected_frames)
                $fatal(1, "DMA 帧等待超时，expected=%0d count=%0d error=%0d pixels=%0d lines=%0d line_pixels=%0d bad=%b drop=%b DVPframes=%0d DVPcurrent=%0d DVPpixels=%0d DVPerrors=%08x FIFO_wr=%0d/%0d rd=%0d/%0d",
                       expected_frames, dut.u_dma.frame_count,
                       dut.u_dma.error_code, dut.u_dma.current_pixel_count,
                       dut.u_dma.current_line_count, dut.u_dma.line_pixel_count,
                       dut.u_dma.frame_bad, dut.u_dma.dropped_current,
                       dut.u_dvp_rx.frame_count, dut.u_dvp_rx.current_frame_pixels,
                       dut.u_dvp_rx.snapshot_last_frame_pixels,
                       dut.u_dvp_rx.frame_error_flags,
                       fifo_pixels_written, fifo_eols_written,
                       fifo_pixels_read, fifo_eols_read);
            repeat (20) @(posedge mem_clk);
        end
    endtask

    task automatic verify_ddr_frame(input integer frame_id,
                                    input integer first_word);
        integer word_index;
        integer pixel_index;
        reg [31:0] packed_pixels;
        reg [31:0] expected_sum;
        reg [15:0] expected_low;
        reg [15:0] expected_high;
        begin
            expected_sum = 0;
            for (word_index = 0; word_index < FRAME_WORDS; word_index = word_index + 1) begin
                pixel_index = word_index * 2;
                expected_low = pixel_pattern(frame_id, pixel_index);
                expected_high = pixel_pattern(frame_id, pixel_index + 1);
                packed_pixels = ddr.frame_mem[first_word + word_index];
                if (packed_pixels[15:0] !== expected_low ||
                    packed_pixels[31:16] !== expected_high)
                    $fatal(1, "DDR 帧内容错误 frame=%0d pixel=%0d actual=%08x expected=%08x",
                           frame_id, pixel_index, packed_pixels,
                           {expected_high, expected_low});
                expected_sum = expected_sum + {16'b0, expected_low} +
                               {16'b0, expected_high};
            end
            if (expected_sum !== ddr_checksum(frame_id))
                $fatal(1, "testbench checksum 内部错误");
            $display("DDR_FRAME_PASS id=%0d base_word=%0d sum16=%08x",
                     frame_id, first_word, expected_sum);
        end
    endtask

    function automatic [31:0] ddr_checksum(input integer frame_id);
        integer n;
        reg [31:0] sum;
        begin
            sum = 0;
            for (n = 0; n < FRAME_PIXELS; n = n + 1)
                sum = sum + {16'b0, pixel_pattern(frame_id, n)};
            ddr_checksum = sum;
        end
    endfunction

    task automatic check_frame_snapshot(input [31:0] expected_count,
                                        input [31:0] expected_addr,
                                        input [31:0] expected_current_buffer,
                                        input [31:0] expected_ready,
                                        input integer frame_id);
        reg [31:0] expected_sum;
        begin
            expected_sum = ddr_checksum(frame_id);
            expect_reg(`CAM_FRAME_COUNT, expected_count, "FRAME_COUNT");
            expect_reg(`CAM_PIXEL_COUNT, FRAME_PIXELS, "PIXEL_COUNT");
            expect_reg(`CAM_BYTE_COUNT, FRAME_PIXELS * 2, "BYTE_COUNT");
            expect_reg(`CAM_LINE_COUNT, FRAME_HEIGHT, "LINE_COUNT");
            expect_reg(`CAM_LAST_FRAME_ADDR, expected_addr, "LAST_FRAME_ADDR");
            expect_reg(`CAM_CURRENT_WRITE_BUFFER, expected_current_buffer,
                       "CURRENT_WRITE_BUFFER");
            expect_reg(`CAM_READY_MASK, expected_ready, "READY_MASK");
            expect_reg(`CAM_FRAME_CHECKSUM, expected_sum, "FRAME_CHECKSUM");
            expect_reg(`CAM_LAST_COMPLETE_BUFFER, frame_id == 1 ? 1 : 0,
                       "LAST_COMPLETE_BUFFER");
        end
    endtask

    initial begin : test_sequence
        reg [31:0] control;
        reg [31:0] first_sum;
        reg [31:0] second_sum;
        integer wait_guard;

        repeat (8) @(negedge cpu_clk);
        rst_n = 1'b1;
        ddr_ready = 1'b1;
        repeat (8) @(negedge cpu_clk);
        mmio_write(`CAM_DMA_CONTROL, 32'h1);
        repeat (8) @(posedge mem_clk);
        capture_enable = 1'b1;
        repeat (8) @(negedge pclk);

        // 第一帧完成后冻结快照，检查固定尺寸、首槽地址与完整帧 checksum。
        send_frame(0);
        wait_dma_frames(1);
        verify_ddr_frame(0, 0);
        take_snapshot();
        $display("SNAPSHOT1 time=%0t", $time);
        check_frame_snapshot(1, 32'hb800_0000, 32'hffff_ffff, 1, 0);
        first_sum = ddr_checksum(0);
        mmio_read(`CAM_FRAME_COUNT, frozen_frame_count);
        mmio_read(`CAM_PIXEL_COUNT, frozen_pixel_count);
        mmio_read(`CAM_BYTE_COUNT, frozen_byte_count);
        mmio_read(`CAM_LINE_COUNT, frozen_line_count);
        mmio_read(`CAM_LAST_FRAME_ADDR, frozen_address);
        mmio_read(`CAM_CURRENT_WRITE_BUFFER, frozen_current_buffer);
        mmio_read(`CAM_READY_MASK, frozen_ready_mask);
        mmio_read(`CAM_FRAME_CHECKSUM, frozen_checksum);

        // 快照保持旧值时运行第二个完整帧，背后实时 DMA 元数据必须不串入 CPU 读口。
        send_frame(1);
        $display("FRAME2_SENT time=%0t", $time);
        wait_dma_frames(2);
        $display("FRAME2_DMA_DONE time=%0t", $time);
        verify_ddr_frame(1, SLOT1_WORD);
        second_sum = ddr_checksum(1);
        if (first_sum == second_sum)
            $fatal(1, "两种 VGA 图案 checksum 必须不同");
        check_frame_snapshot(1, 32'hb800_0000, 1, 1, 0);
        mmio_read(`CAM_CURRENT_PIXEL_COUNT, reg_value);
        if (reg_value != second_mid_current_pixels || reg_value == 0)
            $fatal(1, "冻结的当前帧像素计数变化/无效 mid=%0d after=%0d",
                   second_mid_current_pixels, reg_value);
        expect_reg(`CAM_FIFO_LEVEL, second_mid_fifo_level, "FROZEN_FIFO_LEVEL");
        expect_reg(`CAM_FIFO_MAX_LEVEL, second_mid_fifo_max, "FROZEN_FIFO_MAX");

        // 新快照切换到第二个完成描述，两个槽均被占用且不存在可写槽。
        take_snapshot();
        check_frame_snapshot(2, 32'hb810_0000, 32'hffff_ffff, 3, 1);
        if (dut.u_dma.ready_mask !== 2'b11)
            $fatal(1, "两槽没有同时处于 ready 状态：%b", dut.u_dma.ready_mask);

        // 两槽锁定时再发送一帧；DMA 必须丢弃它，且已存帧内容及写事务数不变。
        old_camera_writes = ddr.camera_writes;
        send_frame(2);
        repeat (50) @(posedge mem_clk);
        if (dut.u_dma.frame_count != 2 || dut.u_dma.ready_mask != 2'b11 ||
            dut.u_dma.dropped_frames == 0 || ddr.camera_writes != old_camera_writes)
            $fatal(1, "ready 双槽保护失败 frames=%0d ready=%b dropped=%0d writes=%0d/%0d",
                   dut.u_dma.frame_count, dut.u_dma.ready_mask,
                   dut.u_dma.dropped_frames, ddr.camera_writes, old_camera_writes);
        verify_ddr_frame(0, 0);
        verify_ddr_frame(1, SLOT1_WORD);

        // 释放槽 0 后验证邮箱完成，并确认 DMA 可将下一完整帧写回该槽。
        mmio_write(`CAM_BUFFER_RELEASE, 32'h1);
        wait_guard = 0;
        while ((dut.u_dma.ready_mask != 2'b10) && (wait_guard < 1000)) begin
            @(posedge mem_clk);
            wait_guard = wait_guard + 1;
        end
        if (dut.u_dma.ready_mask != 2'b10)
            $fatal(1, "release mailbox 未释放槽 0 ready=%b", dut.u_dma.ready_mask);
        send_frame(3);
        wait_dma_frames(3);
        verify_ddr_frame(3, 0);
        take_snapshot();
        check_frame_snapshot(3, 32'hb800_0000, 32'hffff_ffff, 3, 3);

        if (ddr.camera_writes != FRAME_BEATS * 3)
            $fatal(1, "AXI 写拍数错误 actual=%0d expected=%0d",
                   ddr.camera_writes, FRAME_BEATS * 3);
        mmio_read(`CAM_SNAPSHOT_CTRL, control);
        if (!control[1] || control[2])
            $fatal(1, "最终快照控制状态错误 %08x", control);

        $display("CAMERA_PIPELINE_PASS VGA=%0dx%0d frames=%0d writes=%0d sum0=%08x sum1=%08x",
                 FRAME_WIDTH, FRAME_HEIGHT, dut.u_dma.frame_count,
                 ddr.camera_writes, first_sum, second_sum);
        $finish;
    end

    initial begin
        #200000000;
        $fatal(1, "CAM1 pipeline integration test timed out");
    end
endmodule
