`timescale 1ns / 1ps

// CAM1 DVP → Async FIFO → 系统时钟域，只验证像素与帧事件，不涉及 DMA/DDR。
module tb_camera_dvp_fifo;
    localparam integer FRAME_PIXELS = 640 * 480;
    localparam integer FRAME_TOKENS = FRAME_PIXELS + 2;

    logic rst_n = 1'b0;
    logic pclk = 1'b0;
    logic cpu_clk = 1'b0;
    logic capture_enable = 1'b0;
    logic vsync = 1'b1;
    logic href = 1'b0;
    logic [7:0] data = 8'b0;
    logic snapshot_req = 1'b0;
    logic read_pause = 1'b0;

    wire [15:0] pixel_data;
    wire pixel_valid;
    wire frame_start;
    wire frame_end;
    wire line_valid;
    wire snapshot_ack;
    wire [31:0] snapshot_frames;
    wire [31:0] snapshot_pixels;
    wire [31:0] snapshot_lines;
    wire [31:0] snapshot_pclks;
    wire [31:0] snapshot_errors;
    wire [4:0] snapshot_seen;

    wire fifo_wr_en = pixel_valid || frame_start || frame_end;
    wire [17:0] fifo_wr_data = frame_start ? {2'b01, 16'b0} :
                               frame_end   ? {2'b10, 16'b0} :
                                             {2'b00, pixel_data};
    wire fifo_full;
    wire fifo_overflow;
    wire fifo_empty;
    wire fifo_underflow;
    wire [17:0] fifo_rd_data;
    wire fifo_rd_valid;
    wire fifo_rd_en;

    integer read_count = 0;
    integer write_count = 0;
    integer max_pending = 0;
    logic [31:0] cpu_cycles = 32'b0;

    // 约 23.8 MHz DVP 字节时钟、90 MHz 系统时钟，二者没有整数倍关系。
    always #21 pclk = ~pclk;
    always #5.556 cpu_clk = ~cpu_clk;

    Hcamera_dvp_rx u_dvp_rx (
        .pclk(pclk),
        .rst_n(rst_n),
        .capture_enable_async(capture_enable),
        .vsync(vsync),
        .href(href),
        .data(data),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_start(frame_start),
        .frame_end(frame_end),
        .line_valid(line_valid),
        .line_end(), .frame_error_flags(), .frame_active_out(),
        .snapshot_req_toggle_async(snapshot_req),
        .snapshot_ack_toggle(snapshot_ack),
        .snapshot_frame_count(snapshot_frames),
        .snapshot_last_frame_pixels(snapshot_pixels),
        .snapshot_last_frame_lines(snapshot_lines),
        .snapshot_pclk_count(snapshot_pclks),
        .snapshot_error_flags(snapshot_errors),
        .snapshot_seen_flags(snapshot_seen)
    );

    Hcamera_async_fifo #(.DATA_WIDTH(18), .ADDR_WIDTH(6)) u_fifo (
        .rst_n(rst_n),
        .wr_clk(pclk),
        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data),
        .full(fifo_full),
        .overflow(fifo_overflow),
        .rd_clk(cpu_clk),
        .rd_en(fifo_rd_en),
        .rd_data(fifo_rd_data),
        .rd_valid(fifo_rd_valid),
        .empty(fifo_empty),
        .underflow(fifo_underflow),
        .wr_level(), .rd_level(), .wr_max_level()
    );

    // 读端每四拍最多取一项，并插入一段暂停，检查跨域积压与恢复。
    always @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n)
            cpu_cycles <= 32'b0;
        else
            cpu_cycles <= cpu_cycles + 32'd1;
    end
    assign fifo_rd_en = !fifo_empty && !read_pause && (cpu_cycles[1:0] == 2'b00);

    function automatic [15:0] pixel_pattern(input integer index);
        pixel_pattern = 16'(index) ^ 16'h5a3c;
    endfunction

    task automatic send_byte(input logic [7:0] value);
        begin
            data = value;
            @(negedge pclk);
        end
    endtask

    // FIFO 读取结果按起始标记、整帧像素、结束标记逐项核对。
    always @(negedge cpu_clk) begin
        if (rst_n && fifo_rd_valid) begin
            if (read_count == 0) begin
                if (fifo_rd_data !== {2'b01, 16'b0})
                    $fatal(1, "首项不是帧开始标记：%h", fifo_rd_data);
            end else if (read_count == FRAME_TOKENS - 1) begin
                if (fifo_rd_data !== {2'b10, 16'b0})
                    $fatal(1, "末项不是帧结束标记：%h", fifo_rd_data);
            end else if (read_count < FRAME_TOKENS - 1) begin
                if (fifo_rd_data !== {2'b00, pixel_pattern(read_count - 1)})
                    $fatal(1, "跨域像素错误：序号 %0d, 实际 %h, 预期 %h",
                           read_count - 1, fifo_rd_data,
                           {2'b00, pixel_pattern(read_count - 1)});
            end else begin
                $fatal(1, "FIFO 产生多余条目");
            end
            read_count++;
        end
    end

    always @(posedge pclk) begin
        if (pixel_valid && (frame_start || frame_end))
            $fatal(1, "DVP 像素与帧事件同拍，无法编码");
        if (fifo_wr_en && fifo_full)
            $fatal(1, "正常帧传输发生 FIFO 满写");
        if (rst_n && fifo_wr_en && !fifo_full) begin
            write_count++;
            if (write_count - read_count > max_pending)
                max_pending = write_count - read_count;
        end
    end

    initial begin
        #40000000;
        $fatal(1, "DVP→FIFO 联合测试超时");
    end

    initial begin
        repeat (1000) @(posedge pclk);
        read_pause = 1'b1;
        repeat (400) @(posedge cpu_clk);
        read_pause = 1'b0;
    end

    initial begin : send_frame
        integer row;
        integer col;
        logic [15:0] value;

        repeat (5) @(negedge pclk);
        rst_n = 1'b1;
        capture_enable = 1'b1;
        repeat (5) @(negedge pclk);
        vsync = 1'b0;
        repeat (3) @(negedge pclk);

        for (row = 0; row < 480; row++) begin
            href = 1'b1;
            for (col = 0; col < 640; col++) begin
                value = pixel_pattern(row * 640 + col);
                send_byte(value[15:8]);
                send_byte(value[7:0]);
            end
            href = 1'b0;
            data = 8'b0;
            repeat (2) @(negedge pclk);
        end

        vsync = 1'b1;
        repeat (5) @(negedge pclk);
        snapshot_req = ~snapshot_req;
        wait (snapshot_ack == snapshot_req);
        wait (read_count == FRAME_TOKENS);
        repeat (5) @(posedge cpu_clk);

        if (snapshot_frames != 1 || snapshot_pixels != FRAME_PIXELS ||
            snapshot_lines != 480 || snapshot_errors != 0)
            $fatal(1, "DVP 帧统计错误：帧 %0d, 像素 %0d, 行 %0d, 错误 %h",
                   snapshot_frames, snapshot_pixels, snapshot_lines, snapshot_errors);
        if (fifo_overflow || fifo_underflow || !fifo_empty)
            $fatal(1, "FIFO 结束状态异常：溢出 %b, 下溢 %b, 空 %b",
                   fifo_overflow, fifo_underflow, fifo_empty);
        if (write_count != FRAME_TOKENS || max_pending < 40)
            $fatal(1, "联合链路未覆盖高占用：写 %0d, 峰值积压 %0d",
                   write_count, max_pending);

        $display("CAM1_DVP_FIFO_PASS: 307200 pixels, SOF/EOF, CDC, max_pending=%0d",
                 max_pending);
        $finish;
    end
endmodule
