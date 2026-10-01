`timescale 1ns / 1ps

module tb_camera_dvp_rx;
    logic pclk = 1'b0;
    logic rst_n = 1'b0;
    logic enable = 1'b0;
    logic vsync = 1'b1;
    logic href = 1'b0;
    logic [7:0] data = 8'b0;
    logic snapshot_req = 1'b0;

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

    integer pixel_index = 0;

    always #7 pclk = ~pclk;

    Hcamera_dvp_rx #(
        .FRAME_WIDTH(3),
        .FRAME_HEIGHT(2)
    ) dut (
        .pclk                       (pclk),
        .rst_n                      (rst_n),
        .capture_enable_async       (enable),
        .vsync                      (vsync),
        .href                       (href),
        .data                       (data),
        .pixel_data                 (pixel_data),
        .pixel_valid                (pixel_valid),
        .frame_start                (frame_start),
        .frame_end                  (frame_end),
        .line_valid                 (line_valid),
        .snapshot_req_toggle_async  (snapshot_req),
        .snapshot_ack_toggle        (snapshot_ack),
        .snapshot_frame_count       (snapshot_frames),
        .snapshot_last_frame_pixels (snapshot_pixels),
        .snapshot_last_frame_lines  (snapshot_lines),
        .snapshot_pclk_count        (snapshot_pclks),
        .snapshot_error_flags       (snapshot_errors),
        .snapshot_seen_flags        (snapshot_seen)
    );

    task automatic send_byte(input logic [7:0] value);
        begin
            data = value;
            @(negedge pclk);
        end
    endtask

    task automatic send_good_line;
        begin
            href = 1'b1;
            send_byte(8'hf8);
            send_byte(8'h00);
            send_byte(8'h07);
            send_byte(8'he0);
            send_byte(8'h00);
            send_byte(8'h1f);
            href = 1'b0;
            data = 8'b0;
            repeat (2) @(negedge pclk);
        end
    endtask

    task automatic take_snapshot;
        begin
            snapshot_req = ~snapshot_req;
            wait (snapshot_ack == snapshot_req);
            repeat (2) @(posedge pclk);
        end
    endtask

    always @(posedge pclk) begin
        if (pixel_valid && (pixel_index < 6)) begin
            case (pixel_index % 3)
                0: if (pixel_data != 16'hf800)
                    $fatal(1, "RGB565 红色拼接错误: %04x", pixel_data);
                1: if (pixel_data != 16'h07e0)
                    $fatal(1, "RGB565 绿色拼接错误: %04x", pixel_data);
                2: if (pixel_data != 16'h001f)
                    $fatal(1, "RGB565 蓝色拼接错误: %04x", pixel_data);
            endcase
            pixel_index = pixel_index + 1;
        end
    end

    initial begin
        repeat (3) @(posedge pclk);
        rst_n = 1'b1;
        enable = 1'b1;
        repeat (4) @(negedge pclk);

        // 第一帧尺寸、字节序都正确。
        vsync = 1'b0;
        repeat (2) @(negedge pclk);
        send_good_line();
        send_good_line();
        vsync = 1'b1;
        repeat (3) @(negedge pclk);
        take_snapshot();

        if (pixel_index != 6)
            $fatal(1, "像素有效脉冲数量错误: %0d", pixel_index);
        if ((snapshot_frames != 1) || (snapshot_pixels != 6) ||
            (snapshot_lines != 2) || (snapshot_errors != 0) ||
            (snapshot_seen != 5'h1f))
            $fatal(1, "正确帧统计错误 f=%0d p=%0d l=%0d e=%08x s=%02x",
                   snapshot_frames, snapshot_pixels, snapshot_lines,
                   snapshot_errors, snapshot_seen);

        // 第二帧只有一行且为奇数字节，应同时报告三类尺寸错误。
        vsync = 1'b0;
        repeat (2) @(negedge pclk);
        href = 1'b1;
        send_byte(8'h12);
        send_byte(8'h34);
        send_byte(8'h56);
        send_byte(8'h78);
        send_byte(8'h9a);
        href = 1'b0;
        repeat (2) @(negedge pclk);
        vsync = 1'b1;
        repeat (3) @(negedge pclk);
        take_snapshot();

        if ((snapshot_frames != 2) || (snapshot_pixels != 2) ||
            (snapshot_lines != 1) || ((snapshot_errors & 32'h7) != 32'h7))
            $fatal(1, "异常帧检测错误 f=%0d p=%0d l=%0d e=%08x",
                   snapshot_frames, snapshot_pixels, snapshot_lines,
                   snapshot_errors);

        $display("CAM1_DVP_RX_PASS");
        $finish;
    end
endmodule
