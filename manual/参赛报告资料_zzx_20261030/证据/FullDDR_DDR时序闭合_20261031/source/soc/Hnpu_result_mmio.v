`timescale 1ns / 1ps

// ============================================================================
// Hnpu_result_mmio
//
// Dual-clock result path for the NPU service.  The producer side is the DDR
// clock domain and carries one packed 256-bit record per ROI.  The consumer
// side is the CPU/MMIO clock domain.  A Gray-pointer asynchronous FIFO keeps
// the two domains independent; the CPU observes the head without changing it
// and advances it only with an explicit RESULT_POP write.
//
// CPU-side register offsets:
//   0x20 RESULT_STATUS: [15:0] count, bit16 empty, bit17 full,
//                       bit18 overflow, bit19 error
//   0x24 RESULT_DATA0 .. 0x40 RESULT_DATA7: queue-head words (peek)
//   0x44 RESULT_POP: write bit0=1 to pop one complete record
//   0x48 IRQ_ENABLE: bit0 result-not-empty, bit1 overflow/error
//   0x4c IRQ_STATUS: bit0 result-not-empty, bit1 overflow/error, W1C sticky
//   0x50 ERROR_CODE: most recent CPU-side error code
//
// The FIFO memory is intentionally a packed register array.  FPGA BRAM
// inference can be introduced after the interface is integrated; correctness
// and explicit ownership are the V1 priority.
// ============================================================================
module Hnpu_result_mmio #(
    parameter integer FIFO_DEPTH = 8,
    parameter integer RECORD_BITS = 256
) (
    input                       producer_clk,
    input                       consumer_clk,
    input                       rst_n,

    input                       producer_valid,
    output wire                 producer_ready,
    input      [RECORD_BITS-1:0] producer_record,

    input                       mmio_valid,
    input                       mmio_wen,
    input      [7:0]            mmio_addr,
    input      [31:0]           mmio_wdata,
    input      [3:0]            mmio_wstrb,
    output wire                 mmio_ready,
    output reg [31:0]           mmio_rdata,
    output wire                 irq,

    output reg                  producer_overflow,
    output reg [7:0]            producer_error_code
);
    initial begin
        if (FIFO_DEPTH < 2 || (FIFO_DEPTH & (FIFO_DEPTH - 1)) != 0)
            $fatal(1, "Hnpu_result_mmio FIFO_DEPTH must be a power of two >= 2");
        if (RECORD_BITS != 256)
            $fatal(1, "Hnpu_result_mmio V1 requires 256-bit records");
    end
    localparam integer PTR_BITS = (FIFO_DEPTH <= 2) ? 1 : $clog2(FIFO_DEPTH);
    localparam integer PTR_TOTAL = PTR_BITS + 1;
    localparam [7:0] REG_STATUS = 8'h20;
    localparam [7:0] REG_DATA0 = 8'h24;
    localparam [7:0] REG_POP = 8'h44;
    localparam [7:0] REG_IRQ_ENABLE = 8'h48;
    localparam [7:0] REG_IRQ_STATUS = 8'h4c;
    localparam [7:0] REG_ERROR_CODE = 8'h50;

    reg [RECORD_BITS-1:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [PTR_TOTAL-1:0] wr_bin, wr_gray;
    reg [PTR_TOTAL-1:0] rd_bin, rd_gray;
    reg [PTR_TOTAL-1:0] rd_gray_sync1, rd_gray_sync2;
    reg [PTR_TOTAL-1:0] wr_gray_sync1, wr_gray_sync2;
    reg producer_error_toggle;
    reg consumer_clear_toggle;
    reg producer_clear_toggle_sync1, producer_clear_toggle_sync2;
    reg producer_clear_toggle_seen;
    reg consumer_error_toggle_sync1, consumer_error_toggle_sync2;
    reg consumer_error_toggle_seen;
    reg producer_overflow_sync1, producer_overflow_sync2;
    reg [1:0] producer_reset_sync, consumer_reset_sync;

    wire [PTR_TOTAL-1:0] wr_bin_next = wr_bin + 1'b1;
    wire [PTR_TOTAL-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [PTR_TOTAL-1:0] rd_bin_next = rd_bin + 1'b1;
    wire [PTR_TOTAL-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    wire fifo_empty = (rd_gray == wr_gray_sync2);
    // For a power-of-two asynchronous FIFO, full is the write pointer with
    // the two MSBs inverted and the remaining Gray bits equal to read pointer.
    wire [PTR_TOTAL-1:0] full_compare = rd_gray_sync2 ^
                                         {2'b11, {(PTR_TOTAL-2){1'b0}}};
    wire fifo_full = (wr_gray == full_compare);
    wire producer_push = producer_valid && producer_ready;

    function [PTR_TOTAL-1:0] gray_to_binary;
        input [PTR_TOTAL-1:0] gray_value;
        integer gray_index;
        begin
            gray_to_binary[PTR_TOTAL-1] = gray_value[PTR_TOTAL-1];
            for (gray_index = PTR_TOTAL-2; gray_index >= 0; gray_index = gray_index - 1)
                gray_to_binary[gray_index] = gray_to_binary[gray_index+1] ^ gray_value[gray_index];
        end
    endfunction
    wire [PTR_TOTAL-1:0] wr_bin_sync2 = gray_to_binary(wr_gray_sync2);
    wire [15:0] consumer_count = {{(16-PTR_TOTAL){1'b0}}, wr_bin_sync2 - rd_bin};
    wire [31:0] consumer_count_u32 = {16'b0, consumer_count};
    wire consumer_full = (consumer_count_u32 >= FIFO_DEPTH);
    wire producer_rst_n = producer_reset_sync[1];
    wire consumer_rst_n = consumer_reset_sync[1];

    wire mmio_selected = mmio_valid;
    wire mmio_write = mmio_selected && mmio_wen;
    wire pop_write = mmio_write && (mmio_addr == REG_POP) && mmio_wstrb[0] &&
                     mmio_wdata[0] && !fifo_empty;
    wire clear_error_write = mmio_write && (mmio_addr == REG_IRQ_STATUS) &&
                             mmio_wstrb[0] && mmio_wdata[1];
    reg irq_enable_result, irq_enable_error;
    reg irq_error_sticky;
    reg [7:0] consumer_error_code;
    wire irq_result = irq_enable_result && !fifo_empty;
    wire irq_error = irq_enable_error && irq_error_sticky;

    assign producer_ready = producer_rst_n && !fifo_full;
    assign mmio_ready = 1'b1;
    assign irq = irq_result || irq_error;

    // Reset assertion is shared and asynchronous; reset release is delayed
    // independently in each clock domain before pointer state is used.
    always @(posedge producer_clk or negedge rst_n) begin
        if (!rst_n)
            producer_reset_sync <= 2'b00;
        else
            producer_reset_sync <= {producer_reset_sync[0], 1'b1};
    end

    always @(posedge consumer_clk or negedge rst_n) begin
        if (!rst_n)
            consumer_reset_sync <= 2'b00;
        else
            consumer_reset_sync <= {consumer_reset_sync[0], 1'b1};
    end

    // Producer-domain pointer synchronizer and FIFO writes.
    always @(posedge producer_clk or negedge rst_n) begin
        if (!rst_n || !producer_rst_n) begin
            wr_bin <= 0;
            wr_gray <= 0;
            rd_gray_sync1 <= 0;
            rd_gray_sync2 <= 0;
            producer_overflow <= 1'b0;
            producer_error_code <= 0;
            producer_error_toggle <= 1'b0;
            producer_clear_toggle_sync1 <= 1'b0;
            producer_clear_toggle_sync2 <= 1'b0;
            producer_clear_toggle_seen <= 1'b0;
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
            producer_clear_toggle_sync1 <= consumer_clear_toggle;
            producer_clear_toggle_sync2 <= producer_clear_toggle_sync1;
            if (producer_clear_toggle_sync2 != producer_clear_toggle_seen) begin
                producer_clear_toggle_seen <= producer_clear_toggle_sync2;
                producer_overflow <= 1'b0;
                producer_error_code <= 0;
            end
            // A full FIFO is normal ready/valid backpressure.  The producer
            // must hold producer_valid and producer_record until ready returns;
            // it is not an overflow and must not raise an error interrupt.
            if (producer_push) begin
                fifo_mem[wr_bin[PTR_BITS-1:0]] <= producer_record;
                wr_bin <= wr_bin_next;
                wr_gray <= wr_gray_next;
            end
        end
    end

    // Consumer-domain pointer synchronizer and explicit MMIO pop.
    always @(posedge consumer_clk or negedge rst_n) begin
        if (!rst_n || !consumer_rst_n) begin
            rd_bin <= 0;
            rd_gray <= 0;
            wr_gray_sync1 <= 0;
            wr_gray_sync2 <= 0;
            irq_enable_result <= 1'b0;
            irq_enable_error <= 1'b0;
            irq_error_sticky <= 1'b0;
            consumer_error_code <= 0;
            consumer_clear_toggle <= 1'b0;
            consumer_error_toggle_sync1 <= 1'b0;
            consumer_error_toggle_sync2 <= 1'b0;
            consumer_error_toggle_seen <= 1'b0;
            producer_overflow_sync1 <= 1'b0;
            producer_overflow_sync2 <= 1'b0;
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
            producer_overflow_sync1 <= producer_overflow;
            producer_overflow_sync2 <= producer_overflow_sync1;
            consumer_error_toggle_sync1 <= producer_error_toggle;
            consumer_error_toggle_sync2 <= consumer_error_toggle_sync1;
            if (consumer_error_toggle_sync2 != consumer_error_toggle_seen) begin
                consumer_error_toggle_seen <= consumer_error_toggle_sync2;
                irq_error_sticky <= 1'b1;
                consumer_error_code <= producer_error_code;
            end
            if (mmio_write && (mmio_addr == REG_IRQ_ENABLE) && mmio_wstrb[0]) begin
                irq_enable_result <= mmio_wdata[0];
                irq_enable_error <= mmio_wdata[1];
            end
            if (clear_error_write)
                irq_error_sticky <= 1'b0;
            if (clear_error_write)
                consumer_clear_toggle <= ~consumer_clear_toggle;
            if (pop_write) begin
                rd_bin <= rd_bin_next;
                rd_gray <= rd_gray_next;
            end
        end
    end

    integer data_word;
    reg [RECORD_BITS-1:0] head_record;
    always @(*) begin
        head_record = fifo_mem[rd_bin[PTR_BITS-1:0]];
        data_word = 0;
        mmio_rdata = 32'b0;
        if (mmio_selected) begin
            case (mmio_addr)
                REG_STATUS:
                    mmio_rdata = {12'b0, irq_error_sticky,
                                  producer_overflow_sync2, consumer_full, fifo_empty,
                                  consumer_count};
                REG_DATA0, REG_DATA0 + 8'h04, REG_DATA0 + 8'h08,
                REG_DATA0 + 8'h0c, REG_DATA0 + 8'h10, REG_DATA0 + 8'h14,
                REG_DATA0 + 8'h18, REG_DATA0 + 8'h1c: begin
                    data_word = ({24'b0, mmio_addr} - {24'b0, REG_DATA0}) >> 2;
                    mmio_rdata = head_record[data_word*32 +: 32];
                end
                REG_IRQ_ENABLE:
                    mmio_rdata = {30'b0, irq_enable_error, irq_enable_result};
                REG_IRQ_STATUS:
                    mmio_rdata = {30'b0, irq_error_sticky, !fifo_empty};
                REG_ERROR_CODE:
                    mmio_rdata = {24'b0, consumer_error_code};
                default: mmio_rdata = 32'b0;
            endcase
        end
    end
endmodule
