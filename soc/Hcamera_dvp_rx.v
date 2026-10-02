`timescale 1ns / 1ps

// CAM1 DVP 接收器。OV5640 配置为 PCLK 下降沿更新数据，因此本模块在
// 上升沿采样；VSYNC 高电平表示帧同步区，HREF 高电平表示行有效区。
module Hcamera_dvp_rx #(
    parameter integer FRAME_WIDTH  = 640,
    parameter integer FRAME_HEIGHT = 480
) (
    input             pclk,
    input             rst_n,
    input             capture_enable_async,
    input             vsync,
    input             href,
    input      [7:0]  data,

    output reg [15:0] pixel_data,
    output reg        pixel_valid,
    output reg        frame_start,
    output reg        frame_end,
    output reg        line_end,
    output reg [3:0]  frame_error_flags,
    output            frame_active_out,
    output            line_valid,

    input             snapshot_req_toggle_async,
    output reg        snapshot_ack_toggle,
    output reg [31:0] snapshot_frame_count,
    output reg [31:0] snapshot_last_frame_pixels,
    output reg [31:0] snapshot_last_frame_lines,
    output reg [31:0] snapshot_pclk_count,
    output reg [31:0] snapshot_error_flags,
    output reg [4:0]  snapshot_seen_flags
);
    localparam [31:0] FRAME_WIDTH_VALUE  = FRAME_WIDTH;
    localparam [31:0] FRAME_HEIGHT_VALUE = FRAME_HEIGHT;

    reg enable_meta;
    reg enable_sync;
    reg pclk_rst_q1;
    reg pclk_rst_q2;
    reg snapshot_req_meta;
    reg snapshot_req_sync;
    reg vsync_d;
    reg href_d;
    reg frame_active;
    reg byte_phase;
    reg [7:0] first_byte;

    reg [31:0] frame_count;
    reg [31:0] current_frame_pixels;
    reg [31:0] current_frame_lines;
    reg [31:0] current_line_pixels;
    reg [31:0] last_frame_pixels;
    reg [31:0] last_frame_lines;
    reg [31:0] pclk_count;
    reg [31:0] error_flags;
    reg [3:0] seen_flags;

    wire pclk_rst_n = pclk_rst_q2;
	//PCLK | 摄像头在下降沿更新数据，FPGA 在上升沿采样 |
	//HREF | 高电平期间，这一行的数据有效 |
	//VSYNC | 低电平期间，处于帧的数据有效区域 |
    assign line_valid = enable_sync && frame_active && !vsync && href;
    assign frame_active_out = enable_sync && frame_active;

    // 异步拉低、PCLK 域两拍同步释放，避免系统复位撤销时引入亚稳态。
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            pclk_rst_q1 <= 1'b0;
            pclk_rst_q2 <= 1'b0;
        end else begin
            pclk_rst_q1 <= 1'b1;
            pclk_rst_q2 <= pclk_rst_q1;
        end
    end

    always @(posedge pclk or negedge pclk_rst_n) begin
        if (!pclk_rst_n) begin
            enable_meta               <= 1'b0;
            enable_sync               <= 1'b0;
            snapshot_req_meta         <= 1'b0;
            snapshot_req_sync         <= 1'b0;
            snapshot_ack_toggle       <= 1'b0;
            vsync_d                   <= 1'b1;
            href_d                    <= 1'b0;
            frame_active              <= 1'b0;
            byte_phase                <= 1'b0;
            first_byte                <= 8'b0;
            pixel_data                <= 16'b0;
            pixel_valid               <= 1'b0;
            frame_start               <= 1'b0;
            frame_end                 <= 1'b0;
            line_end                  <= 1'b0;
            frame_count               <= 32'b0;
            current_frame_pixels      <= 32'b0;
            current_frame_lines       <= 32'b0;
            current_line_pixels       <= 32'b0;
            last_frame_pixels         <= 32'b0;
            last_frame_lines          <= 32'b0;
            pclk_count                <= 32'b0;
            error_flags               <= 32'b0;
            frame_error_flags        <= 4'b0;
            seen_flags                <= 4'b0;
            snapshot_frame_count      <= 32'b0;
            snapshot_last_frame_pixels<= 32'b0;
            snapshot_last_frame_lines <= 32'b0;
            snapshot_pclk_count       <= 32'b0;
            snapshot_error_flags      <= 32'b0;
            snapshot_seen_flags       <= 5'b0;
        end else begin
            enable_meta       <= capture_enable_async;
            enable_sync       <= enable_meta;
            snapshot_req_meta <= snapshot_req_toggle_async;
            snapshot_req_sync <= snapshot_req_meta;
            vsync_d           <= vsync;
            href_d            <= href;

            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_end   <= 1'b0;
            line_end    <= 1'b0;

            if (enable_sync) begin
                pclk_count     <= pclk_count + 32'd1;
                seen_flags[0]  <= 1'b1;
                if ((vsync && !vsync_d) || (!vsync && vsync_d))
                    seen_flags[1] <= 1'b1;
                if (href)
                    seen_flags[2] <= 1'b1;

                // VSYNC 同步脉冲结束后进入一帧的有效图像区。
                if (!vsync && vsync_d) begin
                    frame_active         <= 1'b1;
                    byte_phase           <= 1'b0;
                    current_frame_pixels <= 32'b0;
                    current_frame_lines  <= 32'b0;
                    current_line_pixels  <= 32'b0;
                    frame_error_flags   <= 4'b0;
                    frame_start          <= 1'b1;
                end

                if (frame_active && vsync && href) begin
                    error_flags[3] <= 1'b1;
                    frame_error_flags[3] <= 1'b1;
                end

                if (frame_active && !vsync && href && !href_d) begin
                    byte_phase          <= 1'b0;
                    current_line_pixels <= 32'b0;
                end

                if (frame_active && !vsync && href) begin
                    if (!byte_phase) begin
                        first_byte <= data;
                        byte_phase <= 1'b1;
                    end else begin
                        pixel_data           <= {first_byte, data};
                        pixel_valid          <= 1'b1;
                        byte_phase           <= 1'b0;
                        current_line_pixels  <= current_line_pixels + 32'd1;
                        current_frame_pixels <= current_frame_pixels + 32'd1;
                    end
                end

                if (frame_active && href_d && !href) begin
                    line_end <= 1'b1;
                    if (byte_phase) begin
                        error_flags[0] <= 1'b1;
                        frame_error_flags[0] <= 1'b1;
                    end
                    if (current_line_pixels != FRAME_WIDTH_VALUE) begin
                        error_flags[1] <= 1'b1;
                        frame_error_flags[1] <= 1'b1;
                    end
                    byte_phase          <= 1'b0;
                    current_frame_lines <= current_frame_lines + 32'd1;
                    current_line_pixels <= 32'b0;
                end

                // 下一次 VSYNC 同步脉冲到来时提交上一帧统计。
                if (vsync && !vsync_d && frame_active) begin
                    if (byte_phase) begin
                        error_flags[0] <= 1'b1;
                        frame_error_flags[0] <= 1'b1;
                    end
                    if (current_frame_lines != FRAME_HEIGHT_VALUE) begin
                        error_flags[2] <= 1'b1;
                        frame_error_flags[2] <= 1'b1;
                    end
                    frame_active       <= 1'b0;
                    byte_phase         <= 1'b0;
                    last_frame_pixels  <= current_frame_pixels;
                    last_frame_lines   <= current_frame_lines;
                    frame_count        <= frame_count + 32'd1;
                    seen_flags[3]      <= 1'b1;
                    // EOF 同拍发生的最后一项错误直接随 EOF 携带。
                    frame_error_flags <= frame_error_flags |
                        { (href && vsync),
                          (current_frame_lines != FRAME_HEIGHT_VALUE),
                          (href && current_line_pixels != FRAME_WIDTH_VALUE),
                          byte_phase };
                    frame_end          <= 1'b1;
                end
            end else begin
                frame_active <= 1'b0;
                byte_phase   <= 1'b0;
            end

            // CPU 请求时冻结所有统计量，并在同一拍返回应答翻转。
            if (snapshot_req_sync != snapshot_ack_toggle) begin
                snapshot_frame_count       <= frame_count;
                snapshot_last_frame_pixels <= last_frame_pixels;
                snapshot_last_frame_lines  <= last_frame_lines;
                snapshot_pclk_count        <= pclk_count;
                snapshot_error_flags       <= error_flags;
                snapshot_seen_flags        <= {seen_flags[3:0], enable_sync};
                snapshot_ack_toggle        <= snapshot_req_sync;
            end
        end
    end
endmodule
