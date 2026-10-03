`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// ============================================================================
// Hnpu_dma
//
// NPU 的 256-bit AXI4 copy/loopback DMA 骨架。每次先用一个最多 16 拍的
// 片上缓冲读完一段，再写回目标地址；因此首版不追求读写重叠，但能稳定地
// 使用 DDR 的完整 256-bit 数据宽度，并为后续计算阵列替换缓冲数据留接口。
//
// CPU 可见地址必须属于 [DDR_BASE, DDR_BASE + DDR_BYTES)。送往 DDR IP 的
// AXI 地址是“CPU 地址 - DDR_BASE”的 30-bit 本地字节地址。NPU 固定使用
// AXI ID 8'h80，避免与 CPU 现有低位 ID（取指 0、数据 1）混淆。
// ============================================================================
module Hnpu_dma #(
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter [7:0]  NPU_AXI_ID = 8'h80,
    parameter [4:0]  MAX_BURST_BEATS = 5'd16
) (
    input              clk,
    input              rst_n,

    // 来自 NPU 控制器的启动事件和已锁存任务配置。
    input              start,
    input      [31:0]  src_addr,
    input      [31:0]  dst_addr,
    input      [31:0]  task_bytes,
    output reg         busy,
    output reg         done_pulse,
    output reg         error,
    output reg         error_pulse,

    // 256-bit AXI4 写地址通道。
    output wire [29:0] axi_awaddr,
    output wire [7:0]  axi_awid,
    output wire [7:0]  axi_awlen,
    output wire [2:0]  axi_awsize,
    output wire [1:0]  axi_awburst,
    output wire        axi_awvalid,
    input              axi_awready,

    // 256-bit AXI4 写数据与写响应通道。
    output wire [255:0] axi_wdata,
    output wire [31:0]  axi_wstrb,
    output wire         axi_wlast,
    output wire         axi_wvalid,
    input              axi_wready,
    input      [7:0]   axi_bid,
    input      [1:0]   axi_bresp,
    input              axi_bvalid,
    output wire        axi_bready,

    // 256-bit AXI4 读地址与读数据通道。
    output wire [29:0] axi_araddr,
    output wire [7:0]  axi_arid,
    output wire [7:0]  axi_arlen,
    output wire [2:0]  axi_arsize,
    output wire [1:0]  axi_arburst,
    output wire        axi_arvalid,
    input              axi_arready,
    input      [255:0] axi_rdata,
    input      [7:0]   axi_rid,
    input      [1:0]   axi_rresp,
    input              axi_rlast,
    input              axi_rvalid,
    output wire        axi_rready
);

localparam [3:0] ST_IDLE     = 4'd0;
localparam [3:0] ST_READ_AR  = 4'd1;
localparam [3:0] ST_READ_R   = 4'd2;
localparam [3:0] ST_WRITE_AW = 4'd3;
localparam [3:0] ST_WRITE_W  = 4'd4;
localparam [3:0] ST_WRITE_B  = 4'd5;

localparam [2:0] AXI_SIZE_32B = 3'b101;
localparam [1:0] AXI_BURST_INCR = 2'b01;
localparam [1:0] AXI_RESP_OKAY = 2'b00;

reg [3:0] state;
reg [31:0] src_addr_reg;
reg [31:0] dst_addr_reg;
reg [31:0] remaining_beats_reg;
reg [4:0]  segment_beats_reg;
reg [8:0]  read_beat_count;
reg [4:0]  write_beat_index;
reg        read_error_seen;

// 每段最多 16 个 32 Byte beat，即 512 Byte 片上暂存。
reg [255:0] data_buffer [0:15];

wire [32:0] ddr_end_ext = {1'b0, DDR_BASE} + {1'b0, DDR_BYTES};
wire [32:0] src_end_ext = {1'b0, src_addr} + {1'b0, task_bytes};
wire [32:0] dst_end_ext = {1'b0, dst_addr} + {1'b0, task_bytes};
wire start_aligned = (src_addr[4:0] == 5'b0) &&
                     (dst_addr[4:0] == 5'b0) &&
                     (task_bytes[4:0] == 5'b0);
wire start_in_ddr = (src_addr >= DDR_BASE) && (dst_addr >= DDR_BASE) &&
                    (src_end_ext <= ddr_end_ext) && (dst_end_ext <= ddr_end_ext);
wire start_valid = start_aligned && start_in_ddr;

// 由剩余 beat 数、16 拍上限与两侧 4 KiB 边界共同决定本段长度。
function [4:0] calc_segment_beats;
    input [31:0] remaining_beats;
    input [31:0] source_address;
    input [31:0] destination_address;
    reg [31:0] source_to_4k;
    reg [31:0] destination_to_4k;
    reg [31:0] chosen;
    begin
        source_to_4k = (32'd4096 - {20'b0, source_address[11:0]}) >> 5;
        destination_to_4k = (32'd4096 - {20'b0, destination_address[11:0]}) >> 5;
        chosen = remaining_beats;
        // 缓冲物理深度固定为 16，参数即使被误设得更大也不能越界。
        if (chosen > 32'd16)
            chosen = 32'd16;
        if (chosen > {27'b0, MAX_BURST_BEATS})
            chosen = {27'b0, MAX_BURST_BEATS};
        if (chosen > source_to_4k)
            chosen = source_to_4k;
        if (chosen > destination_to_4k)
            chosen = destination_to_4k;
        calc_segment_beats = chosen[4:0];
    end
endfunction

// 本地 DDR 字节地址；输入合法性已在 start 时确认，运行中只在寄存器上递增。
wire [31:0] src_local_addr = src_addr_reg - DDR_BASE;
wire [31:0] dst_local_addr = dst_addr_reg - DDR_BASE;
wire [31:0] segment_beats_ext = {27'b0, segment_beats_reg};
wire [8:0]  segment_last_read = {4'b0, segment_beats_reg} - 9'd1;

assign axi_araddr  = src_local_addr[29:0];
assign axi_arid    = NPU_AXI_ID;
assign axi_arlen   = {3'b0, segment_beats_reg} - 8'd1;
assign axi_arsize  = AXI_SIZE_32B;
assign axi_arburst = AXI_BURST_INCR;
assign axi_arvalid = (state == ST_READ_AR);

assign axi_awaddr  = dst_local_addr[29:0];
assign axi_awid    = NPU_AXI_ID;
assign axi_awlen   = {3'b0, segment_beats_reg} - 8'd1;
assign axi_awsize  = AXI_SIZE_32B;
assign axi_awburst = AXI_BURST_INCR;
assign axi_awvalid = (state == ST_WRITE_AW);

assign axi_wdata   = data_buffer[write_beat_index[3:0]];
assign axi_wstrb   = 32'hffff_ffff;
assign axi_wlast   = (write_beat_index == (segment_beats_reg - 1'b1));
assign axi_wvalid  = (state == ST_WRITE_W);
assign axi_bready  = (state == ST_WRITE_B);
assign axi_rready  = (state == ST_READ_R);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state               <= ST_IDLE;
        src_addr_reg        <= 32'b0;
        dst_addr_reg        <= 32'b0;
        remaining_beats_reg <= 32'b0;
        segment_beats_reg   <= 5'b0;
        read_beat_count     <= 9'b0;
        write_beat_index    <= 5'b0;
        read_error_seen     <= 1'b0;
        busy                <= 1'b0;
        done_pulse          <= 1'b0;
        error               <= 1'b0;
        error_pulse         <= 1'b0;
    end else begin
        done_pulse  <= 1'b0;
        error_pulse <= 1'b0;

        case (state)
            ST_IDLE: begin
                if (start && !busy) begin
                    error <= 1'b0;
                    if (task_bytes == 32'b0) begin
                        // 零长度定义为“立即成功完成”，不产生任何 AXI 访问。
                        done_pulse <= 1'b1;
                    end else if (!start_valid) begin
                        // 未对齐、非 32 Byte 整数倍或超出 DDR 均直接拒绝。
                        error       <= 1'b1;
                        error_pulse <= 1'b1;
                    end else begin
                        busy                <= 1'b1;
                        src_addr_reg        <= src_addr;
                        dst_addr_reg        <= dst_addr;
                        remaining_beats_reg <= task_bytes >> 5;
                        segment_beats_reg   <= calc_segment_beats(task_bytes >> 5,
                                                                  src_addr, dst_addr);
                        state               <= ST_READ_AR;
                    end
                end
            end

            ST_READ_AR: begin
                // AR 的地址、长度和 ID 均来自寄存器，arready 低时保持不变。
                if (axi_arvalid && axi_arready) begin
                    read_beat_count <= 9'b0;
                    read_error_seen <= 1'b0;
                    state <= ST_READ_R;
                end
            end

            ST_READ_R: begin
                if (axi_rvalid && axi_rready) begin
                    // 即使收到错误响应也继续 rready，直至 RLAST 安全排空当前 burst。
                    if (read_beat_count < {4'b0, segment_beats_reg})
                        data_buffer[read_beat_count[3:0]] <= axi_rdata;
                    if ((axi_rid != NPU_AXI_ID) || (axi_rresp != AXI_RESP_OKAY) ||
                        (read_beat_count >= {4'b0, segment_beats_reg}))
                        read_error_seen <= 1'b1;

                    if (axi_rlast) begin
                        // RLAST 早到、ID/RESP 错误或此前读拍数错误：整段不写回。
                        if ((read_beat_count != segment_last_read) ||
                            read_error_seen || (axi_rid != NPU_AXI_ID) ||
                            (axi_rresp != AXI_RESP_OKAY)) begin
                            busy        <= 1'b0;
                            error       <= 1'b1;
                            error_pulse <= 1'b1;
                            state       <= ST_IDLE;
                        end else begin
                            state <= ST_WRITE_AW;
                        end
                    end else begin
                        // 到预期末拍仍没有 RLAST，则继续排空后报错，不写目标。
                        if (read_beat_count == segment_last_read)
                            read_error_seen <= 1'b1;
                        read_beat_count <= read_beat_count + 1'b1;
                    end
                end
            end

            ST_WRITE_AW: begin
                // AW payload 在 awready 低时同样保持稳定。
                if (axi_awvalid && axi_awready) begin
                    write_beat_index <= 5'b0;
                    state <= ST_WRITE_W;
                end
            end

            ST_WRITE_W: begin
                // 只有 W 握手后才递增索引，故 WDATA/WLAST/WSTRB 可承受 stall。
                if (axi_wvalid && axi_wready) begin
                    if (axi_wlast) begin
                        state <= ST_WRITE_B;
                    end else begin
                        write_beat_index <= write_beat_index + 1'b1;
                    end
                end
            end

            ST_WRITE_B: begin
                if (axi_bvalid && axi_bready) begin
                    if ((axi_bid != NPU_AXI_ID) || (axi_bresp != AXI_RESP_OKAY)) begin
                        busy        <= 1'b0;
                        error       <= 1'b1;
                        error_pulse <= 1'b1;
                        state       <= ST_IDLE;
                    end else if (remaining_beats_reg == segment_beats_ext) begin
                        busy       <= 1'b0;
                        done_pulse <= 1'b1;
                        state      <= ST_IDLE;
                    end else begin
                        src_addr_reg        <= src_addr_reg + ({27'b0, segment_beats_reg} << 5);
                        dst_addr_reg        <= dst_addr_reg + ({27'b0, segment_beats_reg} << 5);
                        remaining_beats_reg <= remaining_beats_reg - segment_beats_ext;
                        segment_beats_reg   <= calc_segment_beats(
                            remaining_beats_reg - segment_beats_ext,
                            src_addr_reg + ({27'b0, segment_beats_reg} << 5),
                            dst_addr_reg + ({27'b0, segment_beats_reg} << 5));
                        state <= ST_READ_AR;
                    end
                end
            end

            default: begin
                busy  <= 1'b0;
                state <= ST_IDLE;
            end
        endcase
    end
end

endmodule
