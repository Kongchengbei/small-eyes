`timescale 1ns / 1ps
`include "../soc/camera_regs.vh"

// CAM1 单路帧 DMA：DDR 域消费带标记 FIFO，并以 256-bit 单拍写入双缓冲。
module Hcamera_dma #(
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter [31:0] BUFFER0_ADDR = `SOC_CAM1_BUFFER0_BASE,
    parameter [31:0] BUFFER1_ADDR = `SOC_CAM1_BUFFER1_BASE,
    parameter [31:0] FRAME_WIDTH = 32'd640,
    parameter [31:0] FRAME_HEIGHT = 32'd480,
    parameter [31:0] TIMEOUT_CYCLES = 32'd1000000,
    parameter [7:0] AXI_ID = 8'h40
) (
    input clk, input rst_n, input enable, input ddr_ready, input clear_errors,
    input release_valid, input [1:0] release_mask,
    input fifo_empty, output wire fifo_rd_en, input fifo_rd_valid,
    input [17:0] fifo_rd_data, input fifo_fault,
    output wire busy, output reg done, output reg error,
    output reg [31:0] error_code, output reg frame_active,
    output reg [31:0] frame_count, output reg [31:0] last_pixel_count,
    output reg [31:0] last_byte_count, output reg [31:0] last_line_count,
    output reg [31:0] current_pixel_count, output reg [31:0] current_byte_count,
    output reg [31:0] current_line_count, output reg [31:0] last_frame_addr,
    output reg [31:0] current_write_buffer, output reg [31:0] last_complete_buffer,
    output reg [31:0] frame_checksum, output reg [1:0] ready_mask,
    output reg [31:0] dropped_frames,
    output wire [29:0] axi_awaddr, output wire [7:0] axi_awid,
    output wire [7:0] axi_awlen, output wire [2:0] axi_awsize,
    output wire [1:0] axi_awburst, output wire axi_awvalid,
    input axi_awready, output wire [255:0] axi_wdata,
    output wire [31:0] axi_wstrb, output wire axi_wlast,
    output wire axi_wvalid, input axi_wready, input [7:0] axi_bid,
    input [1:0] axi_bresp, input axi_bvalid, output wire axi_bready
);

localparam [2:0] ST_IDLE=3'd0, ST_FIFO_WAIT=3'd1, ST_AW=3'd2,
                 ST_W=3'd3, ST_B=3'd4, ST_FINALIZE=3'd5, ST_ABORT=3'd6;
localparam [31:0] ERR_NONE=`CAM_ERR_NONE, ERR_FIFO_OVERFLOW=`CAM_ERR_FIFO_OVERFLOW,
    ERR_UNEXPECTED_SOF=`CAM_ERR_UNEXPECTED_SOF, ERR_UNEXPECTED_EOF=`CAM_ERR_UNEXPECTED_EOF,
    ERR_BAD_PIXEL_COUNT=`CAM_ERR_BAD_PIXEL_COUNT, ERR_DDR_TIMEOUT=`CAM_ERR_DDR_TIMEOUT,
    ERR_DDR_WRITE=`CAM_ERR_DDR_WRITE, ERR_BAD_LINE_COUNT=`CAM_ERR_BAD_LINE_COUNT,
    ERR_DVP=`CAM_ERR_DVP, ERR_NO_FREE_BUFFER=`CAM_ERR_NO_FREE_BUFFER,
    ERR_BAD_CONFIG=`CAM_ERR_BAD_CONFIG;
localparam [1:0] RESP_OKAY=2'b00;

reg [2:0] state;
reg [255:0] pack_data, write_data_reg;
reg [4:0] pack_count;
reg [31:0] write_offset, line_pixel_count, timeout_count, current_checksum;
reg [31:0] selected_buffer;
reg selected_slot, frame_bad, dropped_current, discard_until_sof, pending_eof;
reg abort_after_axi;
reg [3:0] eof_error_bits;
reg [31:0] write_strobe_reg;
reg fifo_request_pending;

wire [1:0] released_mask = release_valid ? release_mask : 2'b00;
wire [1:0] available_mask = ~(ready_mask & ~released_mask);
wire [32:0] ddr_end = {1'b0, DDR_BASE} + {1'b0, DDR_BYTES};
wire [32:0] b0_end = {1'b0, BUFFER0_ADDR} + 33'h100000;
wire [32:0] b1_end = {1'b0, BUFFER1_ADDR} + 33'h100000;
wire [63:0] frame_pixels = {32'b0, FRAME_WIDTH} * {32'b0, FRAME_HEIGHT};
wire [63:0] frame_bytes = frame_pixels * 64'd2;
wire buffers_disjoint = (b0_end <= {1'b0, BUFFER1_ADDR}) ||
                        (b1_end <= {1'b0, BUFFER0_ADDR});
wire config_valid = (FRAME_WIDTH != 0) && (FRAME_HEIGHT != 0) &&
    (frame_bytes <= 64'h100000) && (BUFFER0_ADDR[4:0] == 0) &&
    (BUFFER1_ADDR[4:0] == 0) && (BUFFER0_ADDR >= DDR_BASE) &&
    (BUFFER1_ADDR >= DDR_BASE) && (b0_end <= ddr_end) &&
    (b1_end <= ddr_end) && buffers_disjoint;

wire [31:0] axi_awaddr_full = selected_buffer + write_offset - DDR_BASE;
assign fifo_rd_en = (state == ST_FIFO_WAIT) && !fifo_request_pending && !fifo_empty && enable;
assign busy = frame_active || (state == ST_AW) || (state == ST_W) ||
              (state == ST_B) || (state == ST_FINALIZE);
assign axi_awaddr = axi_awaddr_full[29:0];
assign axi_awid = AXI_ID;
assign axi_awlen = 8'd0;
assign axi_awsize = 3'b101;
assign axi_awburst = 2'b01;
assign axi_awvalid = (state == ST_AW);
assign axi_wdata = write_data_reg;
assign axi_wstrb = write_strobe_reg;
assign axi_wlast = 1'b1;
assign axi_wvalid = (state == ST_W);
assign axi_bready = (state == ST_B);
wire progress_event = (fifo_request_pending && fifo_rd_valid) ||
    (axi_awvalid && axi_awready) || (axi_wvalid && axi_wready) ||
    (axi_bvalid && axi_bready);

function [31:0] low_lanes_strobe;
    input [4:0] count;
    integer lane;
    begin
        low_lanes_strobe = 32'b0;
        for (lane=0; lane<16; lane=lane+1)
            if (lane < count) low_lanes_strobe[lane*2 +: 2] = 2'b11;
    end
endfunction

// 错误码保留首个未清除错误；帧内无效状态独立于全局错误粘滞位。
task automatic report_error;
    input [31:0] code;
    begin
        error <= 1'b1;
        if (!error) error_code <= code;
    end
endtask

task automatic start_frame;
    input [31:0] buffer_addr;
    input slot;
    begin
        selected_buffer <= buffer_addr;
        selected_slot <= slot;
        current_write_buffer <= {31'b0, slot};
        current_pixel_count <= 0;
        current_byte_count <= 0;
        current_line_count <= 0;
        line_pixel_count <= 0;
        current_checksum <= 0;
        write_offset <= 0;
        pack_count <= 0;
        pack_data <= 0;
        frame_bad <= 0;
        dropped_current <= 0;
        discard_until_sof <= 0;
        pending_eof <= 0;
        eof_error_bits <= 0;
        abort_after_axi <= 0;
        frame_active <= 1'b1;
        done <= 1'b0;
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ST_IDLE; pack_data <= 0; write_data_reg <= 0; pack_count <= 0;
        write_offset <= 0; line_pixel_count <= 0; timeout_count <= 0; current_checksum <= 0;
        selected_buffer <= 32'hffff_ffff; selected_slot <= 0;
        frame_bad <= 0; dropped_current <= 0; discard_until_sof <= 0; pending_eof <= 0;
        eof_error_bits <= 0; write_strobe_reg <= 0; fifo_request_pending <= 0;
        abort_after_axi <= 0;
        done <= 0; error <= 0; error_code <= ERR_NONE; frame_active <= 0;
        frame_count <= 0; last_pixel_count <= 0; last_byte_count <= 0; last_line_count <= 0;
        current_pixel_count <= 0; current_byte_count <= 0; current_line_count <= 0;
        last_frame_addr <= 32'hffff_ffff; current_write_buffer <= 32'hffff_ffff;
        last_complete_buffer <= 32'hffff_ffff; frame_checksum <= 0;
        ready_mask <= 0; dropped_frames <= 0;
    end else begin
        if (clear_errors) begin error <= 1'b0; error_code <= ERR_NONE; end
        if (release_valid) ready_mask <= ready_mask & ~release_mask;

        // 禁用时不可撤销 AXI VALID；先将当前帧标无效，事务响应后进入 ABORT。
        if (!enable && ((state == ST_AW) || (state == ST_W) || (state == ST_B)) &&
            !abort_after_axi) begin
            abort_after_axi <= 1'b1;
            frame_bad <= 1'b1;
            dropped_frames <= dropped_frames + 1'b1;
        end

        // 超时只使当前帧无效。AXI 事务保持原 VALID 并继续等待响应排空。
        if (progress_event) timeout_count <= 0;
        else if (frame_active || (state == ST_AW) || (state == ST_W) || (state == ST_B)) begin
            if (timeout_count >= TIMEOUT_CYCLES-1) begin
                report_error(ERR_DDR_TIMEOUT);
                timeout_count <= 0;
                if (state == ST_FIFO_WAIT) begin
                    frame_active <= 1'b0;
                    frame_bad <= 1'b1;
                    dropped_current <= 1'b1;
                    discard_until_sof <= 1'b1;
                    current_write_buffer <= 32'hffff_ffff;
                    selected_buffer <= 32'hffff_ffff;
                    pack_count <= 0;
                    dropped_frames <= dropped_frames + 1'b1;
                end else frame_bad <= 1'b1;
            end else timeout_count <= timeout_count + 1'b1;
        end else timeout_count <= 0;

        if (fifo_fault) begin
            report_error(ERR_FIFO_OVERFLOW);
            if (frame_active) frame_bad <= 1'b1;
        end

        case (state)
            ST_IDLE: begin
                fifo_request_pending <= 1'b0;
                if (enable && ddr_ready) state <= ST_FIFO_WAIT;
            end

            ST_FIFO_WAIT: begin
                if (!enable) begin
                    if (frame_active && !dropped_current)
                        dropped_frames <= dropped_frames + 1'b1;
                    frame_active <= 1'b0;
                    frame_bad <= 1'b1;
                    dropped_current <= 1'b1;
                    discard_until_sof <= 1'b1;
                    selected_buffer <= 32'hffff_ffff;
                    current_write_buffer <= 32'hffff_ffff;
                    current_pixel_count <= 0;
                    current_byte_count <= 0;
                    current_line_count <= 0;
                    current_checksum <= 0;
                    line_pixel_count <= 0;
                    pack_count <= 0;
                    pending_eof <= 0;
                    abort_after_axi <= 0;
                    if (fifo_request_pending && !fifo_rd_valid) state <= ST_ABORT;
                    else begin
                        fifo_request_pending <= 1'b0;
                        state <= ST_IDLE;
                    end
                end
                else begin
                    if (fifo_rd_en) fifo_request_pending <= 1'b1;
                    if (fifo_request_pending && fifo_rd_valid) begin
                        fifo_request_pending <= 1'b0;
                        timeout_count <= 0;
                        case (fifo_rd_data[17:16])
                            2'b00: begin
                                if (discard_until_sof) begin
                                    // 丢弃超时帧剩余内容，直到新的帧边界。
                                end else if (!frame_active) begin
                                    report_error(ERR_UNEXPECTED_EOF);
                                end else if (!frame_bad && !dropped_current) begin
                                    if ({32'b0, current_pixel_count} >= frame_pixels) begin
                                        report_error(ERR_BAD_PIXEL_COUNT);
                                        frame_bad <= 1'b1;
                                        pack_count <= 0;
                                    end else begin
                                        pack_data[pack_count*16 +: 16] <= fifo_rd_data[15:0];
                                        current_pixel_count <= current_pixel_count + 1'b1;
                                        current_byte_count <= current_byte_count + 32'd2;
                                        line_pixel_count <= line_pixel_count + 1'b1;
                                        current_checksum <= current_checksum + {16'b0, fifo_rd_data[15:0]};
                                        pack_count <= pack_count + 1'b1;
                                        if (pack_count == 15) begin
                                            write_data_reg <= {fifo_rd_data[15:0], pack_data[239:0]};
                                            write_strobe_reg <= 32'hffff_ffff;
                                            pack_count <= 0;
                                            state <= ST_AW;
                                        end
                                    end
                                end
                            end

                            2'b01: begin
                                if (!config_valid) begin
                                    report_error(ERR_BAD_CONFIG);
                                    dropped_frames <= dropped_frames + 1'b1;
                                    frame_active <= 1'b0;
                                    frame_bad <= 1'b1;
                                    dropped_current <= 1'b1;
                                    discard_until_sof <= 1'b1;
                                    selected_buffer <= 32'hffff_ffff;
                                    current_write_buffer <= 32'hffff_ffff;
                                    done <= 1'b0;
                                end else begin
                                    if (frame_active) begin
                                        report_error(ERR_UNEXPECTED_SOF);
                                        dropped_frames <= dropped_frames + 1'b1;
                                    end
                                    done <= 1'b0;
                                    if (available_mask == 2'b00) begin
                                        report_error(ERR_NO_FREE_BUFFER);
                                        dropped_frames <= dropped_frames + 1'b1;
                                        selected_buffer <= 32'hffff_ffff;
                                        current_write_buffer <= 32'hffff_ffff;
                                        selected_slot <= 0;
                                        current_pixel_count <= 0;
                                        current_byte_count <= 0;
                                        current_line_count <= 0;
                                        line_pixel_count <= 0;
                                        current_checksum <= 0;
                                        write_offset <= 0;
                                        pack_count <= 0;
                                        frame_bad <= 1'b1;
                                        dropped_current <= 1'b1;
                                        discard_until_sof <= 0;
                                        pending_eof <= 0;
                                        eof_error_bits <= 0;
                                        frame_active <= 1'b1;
                                    end else if (available_mask[0]) begin
                                        start_frame(BUFFER0_ADDR, 1'b0);
                                    end else begin
                                        start_frame(BUFFER1_ADDR, 1'b1);
                                    end
                                end
                            end

                            2'b10: begin
                                if (discard_until_sof) begin
                                    // 丢弃旧帧尾标记。
                                end else if (!frame_active) begin
                                    report_error(ERR_UNEXPECTED_EOF);
                                end else begin
                                    eof_error_bits <= fifo_rd_data[3:0];
                                    if ({32'b0, current_pixel_count} != frame_pixels) begin
                                        report_error(ERR_BAD_PIXEL_COUNT); frame_bad <= 1'b1;
                                    end else if ((current_line_count != FRAME_HEIGHT) || (line_pixel_count != 0)) begin
                                        report_error(ERR_BAD_LINE_COUNT); frame_bad <= 1'b1;
                                    end else if (fifo_rd_data[3:0] != 0) begin
                                        report_error(ERR_DVP); frame_bad <= 1'b1;
                                    end
                                    frame_active <= 1'b0;
                                    pending_eof <= 1'b1;
                                    if ((pack_count != 0) && !frame_bad && !dropped_current) begin
                                        write_data_reg <= pack_data;
                                        write_strobe_reg <= low_lanes_strobe(pack_count);
                                        pack_count <= 0;
                                        state <= ST_AW;
                                    end else if ((pack_count != 0) && ({32'b0, current_pixel_count} == frame_pixels) &&
                                                 (current_line_count == FRAME_HEIGHT) && (line_pixel_count == 0) &&
                                                 (fifo_rd_data[3:0] == 0) && !dropped_current) begin
                                        // 同周期 EOF 检出的合法末尾 partial beat 仍需提交。
                                        write_data_reg <= pack_data;
                                        write_strobe_reg <= low_lanes_strobe(pack_count);
                                        pack_count <= 0;
                                        state <= ST_AW;
                                    end else begin
                                        pack_count <= 0;
                                        state <= ST_FINALIZE;
                                    end
                                end
                            end

                            2'b11: begin
                                if (!discard_until_sof && frame_active) begin
                                    if (line_pixel_count != FRAME_WIDTH) begin
                                        report_error(ERR_BAD_LINE_COUNT); frame_bad <= 1'b1;
                                    end
                                    current_line_count <= current_line_count + 1'b1;
                                    line_pixel_count <= 0;
                                    // 跨行连续打包，不为非 16 对齐行插入 DDR 空洞。
                                end else if (!discard_until_sof) report_error(ERR_BAD_LINE_COUNT);
                            end
                        endcase
                    end
                end
            end

            ST_AW: if (axi_awvalid && axi_awready) begin
                timeout_count <= 0;
                state <= ST_W;
            end
            ST_W: if (axi_wvalid && axi_wready) begin
                timeout_count <= 0;
                state <= ST_B;
            end
            ST_B: if (axi_bvalid && axi_bready) begin
                timeout_count <= 0;
                if ((axi_bid != AXI_ID) || (axi_bresp != RESP_OKAY)) begin
                    report_error(ERR_DDR_WRITE); frame_bad <= 1'b1;
                end
                write_offset <= write_offset + 32'd32;
                if (abort_after_axi || !enable) state <= ST_ABORT;
                else if (pending_eof) state <= ST_FINALIZE;
                else state <= ST_FIFO_WAIT;
            end

            ST_FINALIZE: begin
                pending_eof <= 0;
                if (!enable) begin
                    if (!dropped_current) dropped_frames <= dropped_frames + 1'b1;
                    frame_active <= 0;
                    frame_bad <= 1;
                    dropped_current <= 1;
                    discard_until_sof <= 1;
                    selected_buffer <= 32'hffff_ffff;
                    current_write_buffer <= 32'hffff_ffff;
                    current_pixel_count <= 0;
                    current_byte_count <= 0;
                    current_line_count <= 0;
                    current_checksum <= 0;
                    line_pixel_count <= 0;
                    pack_count <= 0;
                    state <= ST_IDLE;
                end else begin
                    if (!frame_bad && !dropped_current && (eof_error_bits == 0)) begin
                        frame_count <= frame_count + 1'b1;
                        last_pixel_count <= current_pixel_count;
                        last_byte_count <= current_byte_count;
                        last_line_count <= current_line_count;
                        last_frame_addr <= selected_buffer;
                        last_complete_buffer <= {31'b0, selected_slot};
                        frame_checksum <= current_checksum;
                        ready_mask[selected_slot] <= 1'b1;
                        done <= 1'b1;
                    end else if (!dropped_current) dropped_frames <= dropped_frames + 1'b1;
                    current_write_buffer <= 32'hffff_ffff;
                    selected_buffer <= 32'hffff_ffff;
                    state <= ST_FIFO_WAIT;
                end
            end

            ST_ABORT: begin
                // 等待此前发出的同步 FIFO 读返回，再回到等待下一 SOF 的空闲态。
                frame_active <= 0;
                frame_bad <= 1;
                dropped_current <= 1;
                discard_until_sof <= 1;
                selected_buffer <= 32'hffff_ffff;
                current_write_buffer <= 32'hffff_ffff;
                current_pixel_count <= 0;
                current_byte_count <= 0;
                current_line_count <= 0;
                current_checksum <= 0;
                line_pixel_count <= 0;
                pack_count <= 0;
                pending_eof <= 0;
                abort_after_axi <= 0;
                if (!fifo_request_pending || fifo_rd_valid) begin
                    fifo_request_pending <= 0;
                    state <= ST_IDLE;
                end
            end

            default: state <= ST_IDLE;
        endcase
    end
end
endmodule
