`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// DVP 统计量的 CPU 时钟域接口。PCLK 域先冻结一组快照，本模块等应答
// 同步回来后再锁存，避免异步多位计数器被逐位采样而出现撕裂。
module Hcamera_dvp_regs (
    input             clk,
    input             rst_n,
    input             mmio_valid,
    input             mmio_wen,
    input      [7:0]  mmio_addr,
    input      [31:0] mmio_wdata,
    input      [3:0]  mmio_wmask,
    input             capture_enable,

    output reg        snapshot_req_toggle,
    input             snapshot_ack_toggle_async,
    input      [31:0] snapshot_frame_count_async,
    input      [31:0] snapshot_last_frame_pixels_async,
    input      [31:0] snapshot_last_frame_lines_async,
    input      [31:0] snapshot_pclk_count_async,
    input      [31:0] snapshot_error_flags_async,
    input      [4:0]  snapshot_seen_flags_async,

    output reg [31:0] mmio_rdata
);
    reg ack_meta;
    reg ack_sync;
    reg ack_seen;
    reg snapshot_valid;

    reg [31:0] frame_meta, frame_sync, frame_latched;
    reg [31:0] pixels_meta, pixels_sync, pixels_latched;
    reg [31:0] lines_meta, lines_sync, lines_latched;
    reg [31:0] pclk_meta, pclk_sync, pclk_latched;
    reg [31:0] errors_meta, errors_sync, errors_latched;
    reg [4:0] seen_meta, seen_sync, seen_latched;

    wire snapshot_busy = snapshot_req_toggle != ack_sync;
    wire any_error = |errors_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            snapshot_req_toggle <= 1'b0;
            ack_meta             <= 1'b0;
            ack_sync             <= 1'b0;
            ack_seen             <= 1'b0;
            snapshot_valid       <= 1'b0;
            frame_meta           <= 32'b0;
            frame_sync           <= 32'b0;
            frame_latched        <= 32'b0;
            pixels_meta          <= 32'b0;
            pixels_sync          <= 32'b0;
            pixels_latched       <= 32'b0;
            lines_meta           <= 32'b0;
            lines_sync           <= 32'b0;
            lines_latched        <= 32'b0;
            pclk_meta            <= 32'b0;
            pclk_sync            <= 32'b0;
            pclk_latched         <= 32'b0;
            errors_meta          <= 32'b0;
            errors_sync          <= 32'b0;
            errors_latched       <= 32'b0;
            seen_meta            <= 5'b0;
            seen_sync            <= 5'b0;
            seen_latched         <= 5'b0;
        end else begin
            ack_meta   <= snapshot_ack_toggle_async;
            ack_sync   <= ack_meta;
            frame_meta <= snapshot_frame_count_async;
            frame_sync <= frame_meta;
            pixels_meta <= snapshot_last_frame_pixels_async;
            pixels_sync <= pixels_meta;
            lines_meta <= snapshot_last_frame_lines_async;
            lines_sync <= lines_meta;
            pclk_meta <= snapshot_pclk_count_async;
            pclk_sync <= pclk_meta;
            errors_meta <= snapshot_error_flags_async;
            errors_sync <= errors_meta;
            seen_meta <= snapshot_seen_flags_async;
            seen_sync <= seen_meta;

            if (ack_sync != ack_seen) begin
                ack_seen       <= ack_sync;
                frame_latched  <= frame_sync;
                pixels_latched <= pixels_sync;
                lines_latched  <= lines_sync;
                pclk_latched   <= pclk_sync;
                errors_latched <= errors_sync;
                seen_latched   <= seen_sync;
                snapshot_valid <= 1'b1;
            end

            if (mmio_valid && mmio_wen && mmio_wmask[0] &&
                (mmio_addr == `SOC_CAM_SNAPSHOT_CTRL) &&
                ((mmio_wdata & `SOC_CAM_SNAPSHOT_START_MASK) != 0) &&
                !snapshot_busy) begin
                snapshot_req_toggle <= ~snapshot_req_toggle;
                snapshot_valid       <= 1'b0;
            end
        end
    end

    always @(*) begin
        mmio_rdata = 32'b0;
        if (mmio_valid && !mmio_wen) begin
            case (mmio_addr)
                // 高位状态与 SCCB 的低位状态在顶层按位合并。
                `SOC_CAM_LEGACY_STATUS_OFFSET: mmio_rdata = {17'b0, any_error, snapshot_busy,
                                      seen_latched[4:1], capture_enable,
                                      8'b0};
                `SOC_CAM_SNAPSHOT_CTRL: mmio_rdata = {30'b0, snapshot_valid, snapshot_busy};
                `SOC_CAM_FRAME_COUNT: mmio_rdata = frame_latched;
                `SOC_CAM_PIXEL_COUNT: mmio_rdata = pixels_latched;
                `SOC_CAM_PCLK_COUNT: mmio_rdata = pclk_latched;
                `SOC_CAM_ERROR_FLAGS: mmio_rdata = errors_latched;
                `SOC_CAM_LINE_COUNT: mmio_rdata = lines_latched;
                default: mmio_rdata = 32'b0;
            endcase
        end
    end
endmodule
