`timescale 1ns / 1ps

// CAM1 DVP、异步 FIFO、DMA 与 CPU MMIO 子系统。
module Hcamera_subsystem #(
    parameter [31:0] DDR_BASE = 32'h8000_0000,
    parameter [31:0] DDR_BYTES = 32'h4000_0000,
    parameter [31:0] BUFFER0_ADDR = 32'hb800_0000,
    parameter [31:0] BUFFER1_ADDR = 32'hb810_0000,
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer FIFO_ADDR_WIDTH = 10,
    parameter integer DMA_TIMEOUT_CYCLES = 1000000,
    parameter integer SNAPSHOT_TIMEOUT_CYCLES = 1000000,
    parameter [7:0] AXI_ID = 8'h40
) (
    input                  cpu_clk,
    input                  mem_clk,
    input                  rst_n,
    input                  ddr_ready,
    input                  capture_enable,
    input                  pclk,
    input                  vsync,
    input                  href,
    input      [7:0]       data,
    input                  mmio_valid,
    input                  mmio_wen,
    input      [7:0]       mmio_addr,
    input      [31:0]      mmio_wdata,
    input      [3:0]       mmio_wmask,
    output reg [31:0]      mmio_rdata,
    output     [29:0]      axi_awaddr,
    output     [7:0]       axi_awid,
    output     [7:0]       axi_awlen,
    output     [2:0]       axi_awsize,
    output     [1:0]       axi_awburst,
    output                 axi_awvalid,
    input                  axi_awready,
    output     [255:0]     axi_wdata,
    output     [31:0]      axi_wstrb,
    output                 axi_wlast,
    output                 axi_wvalid,
    input                  axi_wready,
    input      [7:0]       axi_bid,
    input      [1:0]       axi_bresp,
    input                  axi_bvalid,
    output                 axi_bready
);
    `include "../soc/camera_regs.vh"

    localparam integer SNAP_COUNT_WIDTH =
        (SNAPSHOT_TIMEOUT_CYCLES < 2) ? 1 : $clog2(SNAPSHOT_TIMEOUT_CYCLES + 1);
    localparam [SNAP_COUNT_WIDTH-1:0] SNAPSHOT_TIMEOUT_LAST =
        SNAPSHOT_TIMEOUT_CYCLES[SNAP_COUNT_WIDTH-1:0] - 1'b1;

    // 各时钟域异步复位断言、两拍同步释放。
    (* ASYNC_REG = "TRUE" *) reg cpu_rst_meta, cpu_rst_sync;
    (* ASYNC_REG = "TRUE" *) reg mem_rst_meta, mem_rst_sync;
    (* ASYNC_REG = "TRUE" *) reg pclk_rst_meta, pclk_rst_sync;
    wire cpu_rst_n = cpu_rst_sync;
    wire mem_rst_n = mem_rst_sync;
    wire pclk_rst_n = pclk_rst_sync;

    always @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n) begin cpu_rst_meta <= 1'b0; cpu_rst_sync <= 1'b0; end
        else begin cpu_rst_meta <= 1'b1; cpu_rst_sync <= cpu_rst_meta; end
    end
    always @(posedge mem_clk or negedge rst_n) begin
        if (!rst_n) begin mem_rst_meta <= 1'b0; mem_rst_sync <= 1'b0; end
        else begin mem_rst_meta <= 1'b1; mem_rst_sync <= mem_rst_meta; end
    end
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin pclk_rst_meta <= 1'b0; pclk_rst_sync <= 1'b0; end
        else begin pclk_rst_meta <= 1'b1; pclk_rst_sync <= pclk_rst_meta; end
    end

    reg dma_enable;
    reg release_toggle;
    reg [1:0] release_payload;
    reg clear_toggle;
    reg clear_pending_cpu;
    (* ASYNC_REG = "TRUE" *) reg clear_ack_meta_cpu;
    (* ASYNC_REG = "TRUE" *) reg clear_ack_sync_cpu;
    reg clear_ack_toggle_mem;
    reg snapshot_req_toggle;

    wire [15:0] dvp_pixel;
    wire dvp_pixel_valid;
    wire dvp_sof;
    wire dvp_eof;
    wire dvp_eol;
    wire [3:0] dvp_frame_errors;
    wire dvp_frame_active;
    wire dvp_snapshot_ack;
    wire [31:0] dvp_frame_count;
    wire [31:0] dvp_last_pixels;
    wire [31:0] dvp_last_lines;
    wire [31:0] dvp_pclk_count;
    wire [31:0] dvp_error_flags;
    wire [4:0] dvp_seen_flags;

    wire fifo_full;
    wire fifo_overflow;
    wire fifo_empty;
    wire fifo_underflow;
    wire [17:0] fifo_rd_data;
    wire fifo_rd_valid;
    wire fifo_rd_en;
    wire [FIFO_ADDR_WIDTH:0] fifo_rd_level;
    wire [FIFO_ADDR_WIDTH:0] fifo_wr_max_level;

    reg drop_frame_pclk;
    reg fifo_fault_toggle;
    reg token_collision;
    wire fifo_token_valid = dvp_sof || dvp_eol || dvp_eof || dvp_pixel_valid;
    // SOF 始终可尝试写入，用它结束上一帧丢弃并重新对齐。
    wire fifo_wr_en = fifo_token_valid && (!drop_frame_pclk || dvp_sof);
    wire [17:0] fifo_wr_data = dvp_sof ? {2'b01, 16'b0} :
                               dvp_eol ? {2'b11, 16'b0} :
                               dvp_eof ? {2'b10, 12'b0, dvp_frame_errors} :
                                         {2'b00, dvp_pixel};

    // CPU 域到 DDR 域的独立、保持型 mailbox。
    (* ASYNC_REG = "TRUE" *) reg release_meta;
    (* ASYNC_REG = "TRUE" *) reg release_sync;
    reg release_seen;
    reg release_valid_mem;
    reg [1:0] release_mask_mem;
    (* ASYNC_REG = "TRUE" *) reg clear_meta;
    (* ASYNC_REG = "TRUE" *) reg clear_sync;
    reg clear_seen;
    reg clear_errors_mem;

    // DVP 快照请求/应答及状态同步。
    reg pclk_snapshot_req_toggle;
    (* ASYNC_REG = "TRUE" *) reg pclk_ack_meta;
    (* ASYNC_REG = "TRUE" *) reg pclk_ack_sync;
    (* ASYNC_REG = "TRUE" *) reg fault_meta;
    (* ASYNC_REG = "TRUE" *) reg fault_sync;
    reg fault_seen;
    reg fifo_fault_mem;
    (* ASYNC_REG = "TRUE" *) reg frame_active_meta;
    (* ASYNC_REG = "TRUE" *) reg frame_active_sync;
    (* ASYNC_REG = "TRUE" *) reg fifo_full_meta;
    (* ASYNC_REG = "TRUE" *) reg fifo_full_sync;
    (* ASYNC_REG = "TRUE" *) reg fifo_overflow_meta;
    (* ASYNC_REG = "TRUE" *) reg fifo_overflow_sync;
    (* ASYNC_REG = "TRUE" *) reg token_collision_meta;
    (* ASYNC_REG = "TRUE" *) reg token_collision_sync;

    reg [31:0] snapshot_dvp_frame_count_mem;
    reg [31:0] snapshot_pclk_count_mem;
    reg [31:0] snapshot_dvp_errors_mem;
    reg [FIFO_ADDR_WIDTH:0] snapshot_fifo_max_mem;
    reg [FIFO_ADDR_WIDTH:0] pclk_fifo_max_snapshot;
    reg pclk_ack_seen;
    reg pclk_combined_ack;

    // DMA 实时元数据；冻结时整组采入 mailbox 暂存寄存器。
    wire dma_busy;
    wire dma_done;
    wire dma_error;
    wire [31:0] dma_error_code;
    wire dma_frame_active;
    wire [31:0] dma_frame_count;
    wire [31:0] dma_last_pixel_count;
    wire [31:0] dma_last_byte_count;
    wire [31:0] dma_last_line_count;
    wire [31:0] dma_current_pixel_count;
    wire [31:0] dma_current_byte_count;
    wire [31:0] dma_current_line_count;
    wire [31:0] dma_last_frame_addr;
    wire [31:0] dma_current_write_buffer;
    wire [31:0] dma_last_complete_buffer;
    wire [31:0] dma_frame_checksum;
    wire [1:0] dma_ready_mask;
    wire [31:0] dma_dropped_frames;

    reg [31:0] snap_frame_count_mem;
    reg [31:0] snap_pixel_count_mem;
    reg [31:0] snap_byte_count_mem;
    reg [31:0] snap_line_count_mem;
    reg [31:0] snap_current_pixel_mem;
    reg [31:0] snap_current_byte_mem;
    reg [31:0] snap_current_line_mem;
    reg [31:0] snap_last_frame_addr_mem;
    reg [31:0] snap_current_write_buffer_mem;
    reg [31:0] snap_last_complete_buffer_mem;
    reg [31:0] snap_checksum_mem;
    reg [1:0] snap_ready_mask_mem;
    reg [31:0] snap_dropped_frames_mem;
    reg [31:0] snap_dma_error_code_mem;
    reg [3:0] snap_dma_status_mem;
    reg snap_ddr_ready_mem;
    reg [FIFO_ADDR_WIDTH:0] snap_fifo_level_mem;
    reg [31:0] snap_fifo_error_mem;
    reg [31:0] snap_status_mem;

    localparam [1:0] MEM_SNAP_IDLE = 2'd0;
    localparam [1:0] MEM_SNAP_WAIT_PCLK = 2'd1;
    localparam [1:0] MEM_SNAP_RETURN = 2'd2;
    reg [1:0] mem_snapshot_state;
    reg mem_snapshot_ack_toggle;
    (* ASYNC_REG = "TRUE" *) reg cpu_req_meta;
    (* ASYNC_REG = "TRUE" *) reg cpu_req_sync;
    reg cpu_req_seen;
    (* ASYNC_REG = "TRUE" *) reg cpu_ack_meta;
    (* ASYNC_REG = "TRUE" *) reg cpu_ack_sync;
    (* ASYNC_REG = "TRUE" *) reg dma_enable_meta_mem;
    (* ASYNC_REG = "TRUE" *) reg dma_enable_sync_mem;

    localparam [1:0] CPU_SNAP_IDLE = 2'd0;
    localparam [1:0] CPU_SNAP_WAIT = 2'd1;
    localparam [1:0] CPU_SNAP_DRAIN = 2'd2;
    reg [1:0] cpu_snapshot_state;
    reg snapshot_valid;
    reg snapshot_timeout;
    reg [SNAP_COUNT_WIDTH-1:0] snapshot_timer;
    reg [31:0] snapshot_sequence;

    // CPU 域内的稳定快照寄存器。
    reg [31:0] cpu_frame_count;
    reg [31:0] cpu_pixel_count;
    reg [31:0] cpu_byte_count;
    reg [31:0] cpu_line_count;
    reg [31:0] cpu_current_pixel_count;
    reg [31:0] cpu_current_byte_count;
    reg [31:0] cpu_current_line_count;
    reg [31:0] cpu_last_frame_addr;
    reg [31:0] cpu_current_write_buffer;
    reg [31:0] cpu_last_complete_buffer;
    reg [31:0] cpu_checksum;
    reg [1:0] cpu_ready_mask;
    reg [31:0] cpu_dropped_frames;
    reg [31:0] cpu_dma_error_code;
    reg [3:0] cpu_dma_status;
    reg cpu_ddr_ready;
    reg [31:0] cpu_pclk_count;
    reg [31:0] cpu_dvp_frame_count;
    reg [31:0] cpu_dvp_error_flags;
    reg [31:0] cpu_fifo_level;
    reg [31:0] cpu_fifo_max_level;
    reg [31:0] cpu_fifo_error;
    reg [31:0] cpu_status;

    wire [31:0] configured_frame_bytes = FRAME_WIDTH * FRAME_HEIGHT * 2;
    wire capture_active = capture_enable && dma_enable;

    Hcamera_dvp_rx #(.FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT)) u_dvp_rx (
        .pclk(pclk), .rst_n(rst_n), .capture_enable_async(capture_active),
        .vsync(vsync), .href(href), .data(data),
        .pixel_data(dvp_pixel), .pixel_valid(dvp_pixel_valid),
        .frame_start(dvp_sof), .frame_end(dvp_eof), .line_end(dvp_eol),
        .frame_error_flags(dvp_frame_errors), .frame_active_out(dvp_frame_active),
        .line_valid(),
        .snapshot_req_toggle_async(pclk_snapshot_req_toggle),
        .snapshot_ack_toggle(dvp_snapshot_ack),
        .snapshot_frame_count(dvp_frame_count),
        .snapshot_last_frame_pixels(dvp_last_pixels),
        .snapshot_last_frame_lines(dvp_last_lines),
        .snapshot_pclk_count(dvp_pclk_count),
        .snapshot_error_flags(dvp_error_flags),
        .snapshot_seen_flags(dvp_seen_flags)
    );

    Hcamera_async_fifo #(.DATA_WIDTH(18), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_fifo (
        .rst_n(rst_n), .wr_clk(pclk), .wr_en(fifo_wr_en), .wr_data(fifo_wr_data),
        .full(fifo_full), .overflow(fifo_overflow),
        .rd_clk(mem_clk), .rd_en(fifo_rd_en), .rd_data(fifo_rd_data),
        .rd_valid(fifo_rd_valid), .empty(fifo_empty), .underflow(fifo_underflow),
        .wr_level(), .rd_level(fifo_rd_level),
        .wr_max_level(fifo_wr_max_level)
    );

    Hcamera_dma #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES),
        .BUFFER0_ADDR(BUFFER0_ADDR), .BUFFER1_ADDR(BUFFER1_ADDR),
        .FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT),
        .TIMEOUT_CYCLES(DMA_TIMEOUT_CYCLES), .AXI_ID(AXI_ID)
    ) u_dma (
        .clk(mem_clk), .rst_n(mem_rst_n), .enable(dma_enable_sync_mem), .ddr_ready(ddr_ready),
        .clear_errors(clear_errors_mem), .release_valid(release_valid_mem),
        .release_mask(release_mask_mem), .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en), .fifo_rd_valid(fifo_rd_valid),
        .fifo_rd_data(fifo_rd_data), .fifo_fault(fifo_fault_mem),
        .busy(dma_busy), .done(dma_done), .error(dma_error),
        .error_code(dma_error_code), .frame_active(dma_frame_active),
        .frame_count(dma_frame_count), .last_pixel_count(dma_last_pixel_count),
        .last_byte_count(dma_last_byte_count), .last_line_count(dma_last_line_count),
        .current_pixel_count(dma_current_pixel_count),
        .current_byte_count(dma_current_byte_count),
        .current_line_count(dma_current_line_count), .last_frame_addr(dma_last_frame_addr),
        .current_write_buffer(dma_current_write_buffer),
        .last_complete_buffer(dma_last_complete_buffer),
        .frame_checksum(dma_frame_checksum), .ready_mask(dma_ready_mask),
        .dropped_frames(dma_dropped_frames),
        .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready), .axi_bid(axi_bid),
        .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid), .axi_bready(axi_bready)
    );

    // PCLK 域：检测 FIFO 溢出后丢弃到下一帧 SOF，并以翻转事件跨域。
    always @(posedge pclk or negedge pclk_rst_n) begin
        if (!pclk_rst_n) begin
            drop_frame_pclk <= 1'b0;
            fifo_fault_toggle <= 1'b0;
            token_collision <= 1'b0;
            pclk_ack_seen <= 1'b0;
            pclk_combined_ack <= 1'b0;
            pclk_fifo_max_snapshot <= {(FIFO_ADDR_WIDTH+1){1'b0}};
        end else begin
            if (dvp_sof)
                drop_frame_pclk <= 1'b0;
            if (fifo_wr_en && fifo_full) begin
                drop_frame_pclk <= 1'b1;
                fifo_fault_toggle <= ~fifo_fault_toggle;
            end
            if ((dvp_pixel_valid && (dvp_sof || dvp_eol || dvp_eof)) ||
                (dvp_sof && (dvp_eol || dvp_eof)) || (dvp_eol && dvp_eof)) begin
                token_collision <= 1'b1;
                drop_frame_pclk <= 1'b1;
                fifo_fault_toggle <= ~fifo_fault_toggle;
            end
            if (dvp_snapshot_ack != pclk_ack_seen) begin
                pclk_ack_seen <= dvp_snapshot_ack;
                pclk_fifo_max_snapshot <= fifo_wr_max_level;
                pclk_combined_ack <= dvp_snapshot_ack;
            end
        end
    end

    // CPU→DDR：控制命令以 toggle 传输，payload 在应答前保持不变。
    always @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            dma_enable <= 1'b0;
            release_toggle <= 1'b0;
            release_payload <= 2'b0;
            clear_toggle <= 1'b0;
            clear_pending_cpu <= 1'b0;
            clear_ack_meta_cpu <= 1'b0;
            clear_ack_sync_cpu <= 1'b0;
            snapshot_req_toggle <= 1'b0;
        end else begin
            clear_ack_meta_cpu <= clear_ack_toggle_mem;
            clear_ack_sync_cpu <= clear_ack_meta_cpu;
            if (clear_pending_cpu && (clear_ack_sync_cpu == clear_toggle)) begin
                clear_toggle <= ~clear_toggle;
                clear_pending_cpu <= 1'b0;
            end
            if (mmio_valid && mmio_wen) begin
                case (mmio_addr)
                    `CAM_DMA_CONTROL: if (mmio_wmask[0]) begin
                        dma_enable <= mmio_wdata[0];
                        if (mmio_wdata[1]) begin
                            if ((clear_ack_sync_cpu == clear_toggle) && !clear_pending_cpu)
                                clear_toggle <= ~clear_toggle;
                            else
                                clear_pending_cpu <= 1'b1;
                        end
                    end
                    `CAM_BUFFER_RELEASE: if (mmio_wmask[0] && !release_busy_cpu) begin
                        release_payload <= mmio_wdata[1:0];
                        release_toggle <= ~release_toggle;
                    end
                    `CAM_SNAPSHOT_CTRL: if (mmio_wmask[0] && mmio_wdata[0] &&
                                            (cpu_snapshot_state == CPU_SNAP_IDLE))
                        snapshot_req_toggle <= ~snapshot_req_toggle;
                    default: begin end
                endcase
            end
        end
    end

    (* ASYNC_REG = "TRUE" *) reg release_ack_meta;
    (* ASYNC_REG = "TRUE" *) reg release_ack_sync;
    reg release_ack_toggle_mem;
    wire release_busy_cpu = (release_ack_sync != release_toggle);
    wire clear_busy_cpu = clear_pending_cpu || (clear_ack_sync_cpu != clear_toggle);

    // DDR 域同步命令、PCLK 状态与 mailbox 请求。
    always @(posedge mem_clk or negedge mem_rst_n) begin
        if (!mem_rst_n) begin
            release_meta <= 1'b0; release_sync <= 1'b0; release_seen <= 1'b0;
            release_valid_mem <= 1'b0; release_mask_mem <= 2'b0;
            release_ack_toggle_mem <= 1'b0;
            clear_meta <= 1'b0; clear_sync <= 1'b0; clear_seen <= 1'b0;
            clear_errors_mem <= 1'b0;
            clear_ack_toggle_mem <= 1'b0;
            fault_meta <= 1'b0; fault_sync <= 1'b0; fault_seen <= 1'b0;
            fifo_fault_mem <= 1'b0;
            frame_active_meta <= 1'b0; frame_active_sync <= 1'b0;
            fifo_full_meta <= 1'b0; fifo_full_sync <= 1'b0;
            fifo_overflow_meta <= 1'b0; fifo_overflow_sync <= 1'b0;
            token_collision_meta <= 1'b0; token_collision_sync <= 1'b0;
            pclk_ack_meta <= 1'b0; pclk_ack_sync <= 1'b0;
            cpu_req_meta <= 1'b0; cpu_req_sync <= 1'b0; cpu_req_seen <= 1'b0;
            dma_enable_meta_mem <= 1'b0; dma_enable_sync_mem <= 1'b0;
            pclk_snapshot_req_toggle <= 1'b0;
            mem_snapshot_state <= MEM_SNAP_IDLE;
            mem_snapshot_ack_toggle <= 1'b0;
        end else begin
            release_meta <= release_toggle; release_sync <= release_meta;
            clear_meta <= clear_toggle; clear_sync <= clear_meta;
            fault_meta <= fifo_fault_toggle; fault_sync <= fault_meta;
            frame_active_meta <= dvp_frame_active; frame_active_sync <= frame_active_meta;
            fifo_full_meta <= fifo_full; fifo_full_sync <= fifo_full_meta;
            fifo_overflow_meta <= fifo_overflow; fifo_overflow_sync <= fifo_overflow_meta;
            token_collision_meta <= token_collision; token_collision_sync <= token_collision_meta;
            pclk_ack_meta <= pclk_combined_ack; pclk_ack_sync <= pclk_ack_meta;
            cpu_req_meta <= snapshot_req_toggle; cpu_req_sync <= cpu_req_meta;
            dma_enable_meta_mem <= dma_enable;
            dma_enable_sync_mem <= dma_enable_meta_mem;

            release_valid_mem <= 1'b0;
            clear_errors_mem <= 1'b0;
            fifo_fault_mem <= 1'b0;
            if (release_sync != release_seen) begin
                release_seen <= release_sync;
                release_mask_mem <= release_payload;
                release_valid_mem <= 1'b1;
            end
            // DMA 在下一 DDR 拍采到 release_valid 后才确认消费。
            if (release_valid_mem)
                release_ack_toggle_mem <= release_seen;
            if (clear_sync != clear_seen) begin
                clear_seen <= clear_sync;
                clear_errors_mem <= 1'b1;
            end
            if (clear_errors_mem)
                clear_ack_toggle_mem <= clear_seen;
            if (fault_sync != fault_seen) begin
                fault_seen <= fault_sync;
                fifo_fault_mem <= 1'b1;
            end

            case (mem_snapshot_state)
                MEM_SNAP_IDLE: if (cpu_req_sync != cpu_req_seen) begin
                    cpu_req_seen <= cpu_req_sync;
                    pclk_snapshot_req_toggle <= ~pclk_snapshot_req_toggle;
                    mem_snapshot_state <= MEM_SNAP_WAIT_PCLK;
                end
                MEM_SNAP_WAIT_PCLK: if (pclk_ack_sync == pclk_snapshot_req_toggle) begin
                    snapshot_dvp_frame_count_mem <= dvp_frame_count;
                    snapshot_pclk_count_mem <= dvp_pclk_count;
                    snapshot_dvp_errors_mem <= dvp_error_flags;
                    snap_frame_count_mem <= dma_frame_count;
                    snap_pixel_count_mem <= dma_last_pixel_count;
                    snap_byte_count_mem <= dma_last_byte_count;
                    snap_line_count_mem <= dma_last_line_count;
                    snap_current_pixel_mem <= dma_current_pixel_count;
                    snap_current_byte_mem <= dma_current_byte_count;
                    snap_current_line_mem <= dma_current_line_count;
                    snap_last_frame_addr_mem <= dma_last_frame_addr;
                    snap_current_write_buffer_mem <= dma_current_write_buffer;
                    snap_last_complete_buffer_mem <= dma_last_complete_buffer;
                    snap_checksum_mem <= dma_frame_checksum;
                    snap_ready_mask_mem <= dma_ready_mask;
                    snap_dropped_frames_mem <= dma_dropped_frames;
                    snap_dma_error_code_mem <= dma_error_code;
                    snap_dma_status_mem <= {dma_error, dma_done, dma_busy, dma_enable_sync_mem};
                    snap_ddr_ready_mem <= ddr_ready;
                    snap_fifo_level_mem <= fifo_rd_level;
                    snap_fifo_error_mem <= {29'b0, token_collision_sync,
                                             fifo_underflow, fifo_overflow_sync};
                    snapshot_fifo_max_mem <= pclk_fifo_max_snapshot;
                    snap_status_mem <=
                        (dvp_error_flags != 0 ? 32'h0000_4000 : 32'b0) |
                        (fifo_underflow ? 32'h0000_2000 : 32'b0) |
                        (ddr_ready ? 32'h0000_0800 : 32'b0) |
                        (dma_error ? 32'h0000_0400 : 32'b0) |
                        (dma_done ? 32'h0000_0200 : 32'b0) |
                        (dma_busy ? 32'h0000_0100 : 32'b0) |
                        (fifo_overflow_sync ? 32'h0000_0080 : 32'b0) |
                        (fifo_full_sync ? 32'h0000_0040 : 32'b0) |
                        (frame_active_sync ? 32'h0000_1000 : 32'b0) |
                        (dma_ready_mask != 0 ? 32'h0000_0020 : 32'b0) |
                        (dma_frame_active ? 32'h0000_0010 : 32'b0) |
                        (dvp_seen_flags[3] ? 32'h0000_0008 : 32'b0) |
                        (dvp_seen_flags[2] ? 32'h0000_0004 : 32'b0) |
                        (dvp_seen_flags[1] ? 32'h0000_0002 : 32'b0) |
                        (dvp_seen_flags[0] ? 32'h0000_0001 : 32'b0);
                    mem_snapshot_ack_toggle <= cpu_req_seen;
                    mem_snapshot_state <= MEM_SNAP_RETURN;
                end
                MEM_SNAP_RETURN: mem_snapshot_state <= MEM_SNAP_IDLE;
                default: mem_snapshot_state <= MEM_SNAP_IDLE;
            endcase
        end
    end

    // 单独同步 release 应答，避免控制读回跨域采样。
    always @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            release_ack_meta <= 1'b0;
            release_ack_sync <= 1'b0;
        end else begin
            release_ack_meta <= release_ack_toggle_mem;
            release_ack_sync <= release_ack_meta;
        end
    end

    // CPU 请求超时后进入排空态；迟到的 mailbox 应答只清理事务，不覆盖快照。
    always @(posedge cpu_clk or negedge cpu_rst_n) begin
        if (!cpu_rst_n) begin
            cpu_snapshot_state <= CPU_SNAP_IDLE;
            cpu_ack_meta <= 1'b0;
            cpu_ack_sync <= 1'b0;
            snapshot_valid <= 1'b0;
            snapshot_timeout <= 1'b0;
            snapshot_timer <= {SNAP_COUNT_WIDTH{1'b0}};
            snapshot_sequence <= 32'b0;
            cpu_frame_count <= 32'b0; cpu_pixel_count <= 32'b0;
            cpu_byte_count <= 32'b0; cpu_line_count <= 32'b0;
            cpu_current_pixel_count <= 32'b0; cpu_current_byte_count <= 32'b0;
            cpu_current_line_count <= 32'b0; cpu_last_frame_addr <= 32'hffff_ffff;
            cpu_current_write_buffer <= 32'hffff_ffff;
            cpu_last_complete_buffer <= 32'hffff_ffff; cpu_checksum <= 32'b0;
            cpu_ready_mask <= 2'b0; cpu_dropped_frames <= 32'b0;
            cpu_dma_error_code <= 32'b0; cpu_dma_status <= 4'b0;
            cpu_ddr_ready <= 1'b0;
            cpu_pclk_count <= 32'b0; cpu_dvp_frame_count <= 32'b0;
            cpu_dvp_error_flags <= 32'b0; cpu_fifo_level <= 32'b0;
            cpu_fifo_max_level <= 32'b0; cpu_fifo_error <= 32'b0;
            cpu_status <= 32'b0;
        end else begin
            cpu_ack_meta <= mem_snapshot_ack_toggle;
            cpu_ack_sync <= cpu_ack_meta;
            case (cpu_snapshot_state)
                CPU_SNAP_IDLE: if (mmio_valid && mmio_wen &&
                    mmio_addr == `CAM_SNAPSHOT_CTRL && mmio_wmask[0] && mmio_wdata[0]) begin
                    snapshot_valid <= 1'b0;
                    snapshot_timeout <= 1'b0;
                    snapshot_timer <= {SNAP_COUNT_WIDTH{1'b0}};
                    cpu_snapshot_state <= CPU_SNAP_WAIT;
                end
                CPU_SNAP_WAIT: begin
                    if (cpu_ack_sync == snapshot_req_toggle) begin
                        cpu_frame_count <= snap_frame_count_mem;
                        cpu_pixel_count <= snap_pixel_count_mem;
                        cpu_byte_count <= snap_byte_count_mem;
                        cpu_line_count <= snap_line_count_mem;
                        cpu_current_pixel_count <= snap_current_pixel_mem;
                        cpu_current_byte_count <= snap_current_byte_mem;
                        cpu_current_line_count <= snap_current_line_mem;
                        cpu_last_frame_addr <= snap_last_frame_addr_mem;
                        cpu_current_write_buffer <= snap_current_write_buffer_mem;
                        cpu_last_complete_buffer <= snap_last_complete_buffer_mem;
                        cpu_checksum <= snap_checksum_mem;
                        cpu_ready_mask <= snap_ready_mask_mem;
                        cpu_dropped_frames <= snap_dropped_frames_mem;
                        cpu_dma_error_code <= snap_dma_error_code_mem;
                        cpu_dma_status <= snap_dma_status_mem;
                        cpu_ddr_ready <= snap_ddr_ready_mem;
                        cpu_pclk_count <= snapshot_pclk_count_mem;
                        cpu_dvp_frame_count <= snapshot_dvp_frame_count_mem;
                        cpu_dvp_error_flags <= snapshot_dvp_errors_mem;
                        cpu_fifo_level <= {{(32-FIFO_ADDR_WIDTH-1){1'b0}}, snap_fifo_level_mem};
                        cpu_fifo_max_level <= {{(32-FIFO_ADDR_WIDTH-1){1'b0}}, snapshot_fifo_max_mem};
                        cpu_fifo_error <= snap_fifo_error_mem;
                        cpu_status <= snap_status_mem;
                        snapshot_valid <= 1'b1;
                        snapshot_sequence <= snapshot_sequence + 32'd1;
                        cpu_snapshot_state <= CPU_SNAP_IDLE;
                    end else if (snapshot_timer >= SNAPSHOT_TIMEOUT_LAST) begin
                        snapshot_timeout <= 1'b1;
                        snapshot_valid <= 1'b0;
                        cpu_snapshot_state <= CPU_SNAP_DRAIN;
                    end else begin
                        snapshot_timer <= snapshot_timer + 1'b1;
                    end
                end
                CPU_SNAP_DRAIN: if (cpu_ack_sync == snapshot_req_toggle)
                    cpu_snapshot_state <= CPU_SNAP_IDLE;
                default: cpu_snapshot_state <= CPU_SNAP_IDLE;
            endcase
        end
    end

    // MMIO 读口：动态只读字段只使用 CPU 域已锁存的同一份快照。
    always @* begin
        mmio_rdata = 32'b0;
        case (mmio_addr)
            `CAM_SNAPSHOT_CTRL: mmio_rdata = {29'b0, snapshot_timeout,
                snapshot_valid, (cpu_snapshot_state == CPU_SNAP_WAIT)};
            `CAM_FRAME_COUNT: mmio_rdata = cpu_frame_count;
            `CAM_PIXEL_COUNT: mmio_rdata = cpu_pixel_count;
            `CAM_PCLK_COUNT: mmio_rdata = cpu_pclk_count;
            `CAM_ERROR_FLAGS: mmio_rdata = cpu_dvp_error_flags;
            `CAM_LINE_COUNT: mmio_rdata = cpu_line_count;
            `CAM_STATUS: mmio_rdata = cpu_status;
            `CAM_BYTE_COUNT: mmio_rdata = cpu_byte_count;
            `CAM_FIFO_LEVEL: mmio_rdata = cpu_fifo_level;
            `CAM_FIFO_MAX_LEVEL: mmio_rdata = cpu_fifo_max_level;
            `CAM_FIFO_ERROR: mmio_rdata = cpu_fifo_error;
            `CAM_DMA_STATUS: mmio_rdata = {22'b0, cpu_ready_mask, 4'b0, cpu_dma_status};
            `CAM_DMA_ERROR_CODE: mmio_rdata = cpu_dma_error_code;
            `CAM_LAST_FRAME_ADDR: mmio_rdata = cpu_last_frame_addr;
            `CAM_CURRENT_WRITE_BUFFER: mmio_rdata = cpu_current_write_buffer;
            `CAM_LAST_COMPLETE_BUFFER: mmio_rdata = cpu_last_complete_buffer;
            `CAM_FRAME_CHECKSUM: mmio_rdata = cpu_checksum;
            `CAM_READY_MASK: mmio_rdata = {30'b0, cpu_ready_mask};
            `CAM_DROPPED_FRAMES: mmio_rdata = cpu_dropped_frames;
            `CAM_SNAPSHOT_SEQUENCE: mmio_rdata = snapshot_sequence;
            `CAM_DVP_FRAME_COUNT: mmio_rdata = cpu_dvp_frame_count;
            `CAM_DVP_ERROR_FLAGS: mmio_rdata = cpu_dvp_error_flags;
            `CAM_BUFFER_RELEASE: mmio_rdata = {31'b0, release_busy_cpu};
            `CAM_DMA_CONTROL: mmio_rdata = {30'b0, clear_busy_cpu, dma_enable};
            `CAM_BUFFER0_ADDR: mmio_rdata = BUFFER0_ADDR;
            `CAM_BUFFER1_ADDR: mmio_rdata = BUFFER1_ADDR;
            `CAM_FRAME_BYTES: mmio_rdata = configured_frame_bytes;
            `CAM_FRAME_WIDTH: mmio_rdata = FRAME_WIDTH;
            `CAM_FRAME_HEIGHT: mmio_rdata = FRAME_HEIGHT;
            `CAM_DDR_READY: mmio_rdata = {31'b0, cpu_ddr_ready};
            `CAM_CURRENT_PIXEL_COUNT: mmio_rdata = cpu_current_pixel_count;
            `CAM_CURRENT_BYTE_COUNT: mmio_rdata = cpu_current_byte_count;
            `CAM_CURRENT_LINE_COUNT: mmio_rdata = cpu_current_line_count;
            default: mmio_rdata = 32'b0;
        endcase
    end
endmodule
