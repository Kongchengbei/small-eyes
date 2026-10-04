`timescale 1ns / 1ps
`include "soc_addr_map.vh"
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

// ============================================================================
// Hnpu_service
//
// Shared V1 NPU service for the two independent camera paths.  It accepts one
// complete INT8 batch at a time, stores pending batches in independent CAM1 and
// CAM2 queues, schedules one ROI with round-robin fairness, and exposes one
// stable result record per ROI.  The compute engine is Hnpu_fc_engine.
//
// The input batch is already converted from RGB565 to the approved INT8
// layout.  result_ready is a DDR-domain consumer handshake; a CPU-domain
// result FIFO/CDC bridge can be placed above this service without changing the
// ownership rules.  An INT8 bank is released exactly once, after the final ROI
// of a batch has completed, and the original RGB565 bank release remains the
// responsibility of the upstream converter.
// ============================================================================
module Hnpu_service #(
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter [7:0]  AXI_ID = 8'h80,
    parameter integer QUEUE_DEPTH = 4,
    parameter integer RESULT_DEPTH = 16,
    parameter integer MAX_ROIS = 8,
    parameter integer MAX_FEATURES = 1024,
    parameter integer MAX_CLASSES = 8,
    // At most two camera queues plus one active batch can be waiting for a
    // release.  The extra entries also cover a completion arriving while a
    // drop release is being emitted.
    parameter integer RELEASE_DEPTH = (QUEUE_DEPTH * 2) + 2
) (
    input clk,
    input rst_n,
    input enable,
    input clear_errors,
    input stop,

    input        batch_valid,
    output wire  batch_ready,
    input [7:0]  batch_camera,
    input [31:0] batch_frame,
    input        batch_bank,
    input [31:0] batch_input_base,
    input [31:0] batch_input_stride,
    input [31:0] batch_input_bytes,
    input [15:0] batch_feature_count,
    input [31:0] batch_weight_base,
    input [31:0] batch_weight_stride,
    input [31:0] batch_bias_base,
    input [7:0]  batch_count,
    input [7:0]  batch_class_count,
    input [5:0]  batch_quant_shift,
    input [MAX_ROIS*64-1:0] batch_boxes,
    input [MAX_ROIS*3-1:0]  batch_colors,

    output wire result_valid,
    input        result_ready,
    output wire [7:0] result_camera,
    output wire [31:0] result_frame,
    output wire        result_bank,
    output wire [7:0] result_roi,
    output wire [63:0] result_box,
    output wire [2:0] result_color,
    output wire [7:0] result_class,
    output wire [15:0] result_confidence,
    output wire [7:0] result_error,
    // Fixed 256-bit record for the CPU-domain result FIFO.  The individual
    // fields above remain available for DDR-domain scoreboards and adapters.
    output wire [255:0] result_record,

    output reg int8_release_valid,
    output reg int8_release_bank,
    output reg [31:0] int8_release_frame,

    output reg busy,
    output reg error,
    output reg [7:0] error_code,
    output reg [31:0] accepted_batches,
    output reg [31:0] completed_batches,
    output reg [31:0] dropped_batches,
    output reg [31:0] completed_rois,
    output reg [31:0] error_rois,
    output reg [31:0] released_banks,
    output reg [31:0] fifo_overflows,

    output wire [29:0] axi_araddr,
    output wire [7:0] axi_arid,
    output wire [7:0] axi_arlen,
    output wire [2:0] axi_arsize,
    output wire [1:0] axi_arburst,
    output wire axi_arvalid,
    input axi_arready,
    input [255:0] axi_rdata,
    input [7:0] axi_rid,
    input [1:0] axi_rresp,
    input axi_rlast,
    input axi_rvalid,
    output wire axi_rready
);

    localparam integer PTR_BITS = (QUEUE_DEPTH <= 2) ? 1 : $clog2(QUEUE_DEPTH);
    localparam integer RES_PTR_BITS = (RESULT_DEPTH <= 2) ? 1 : $clog2(RESULT_DEPTH);
    reg [PTR_BITS-1:0] q_head [0:1], q_tail [0:1];
    reg [PTR_BITS:0] q_count [0:1];
    reg [31:0] q_frame [0:1][0:QUEUE_DEPTH-1];
    reg q_bank [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_input_base [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_input_stride [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_input_bytes [0:1][0:QUEUE_DEPTH-1];
    reg [15:0] q_feature_count [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_weight_base [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_weight_stride [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_bias_base [0:1][0:QUEUE_DEPTH-1];
    reg [7:0] q_count_rois [0:1][0:QUEUE_DEPTH-1];
    reg [7:0] q_class_count [0:1][0:QUEUE_DEPTH-1];
    reg [5:0] q_quant_shift [0:1][0:QUEUE_DEPTH-1];
    reg [63:0] q_boxes [0:1][0:QUEUE_DEPTH-1][0:MAX_ROIS-1];
    reg [2:0] q_colors [0:1][0:QUEUE_DEPTH-1][0:MAX_ROIS-1];

    reg active;
    reg active_cam;
    reg active_bank;
    reg [31:0] active_frame;
    reg [31:0] active_input_base, active_input_stride, active_input_bytes;
    reg [15:0] active_feature_count;
    reg [31:0] active_weight_base, active_weight_stride, active_bias_base;
    reg [7:0] active_count, active_class_count;
    reg [5:0] active_quant_shift;
    reg [63:0] active_boxes [0:MAX_ROIS-1];
    reg [2:0] active_colors [0:MAX_ROIS-1];
    reg [7:0] active_roi;
    reg engine_issued;
    reg rr_next;

    reg [7:0] result_camera_mem [0:RESULT_DEPTH-1];
    reg [31:0] result_frame_mem [0:RESULT_DEPTH-1];
    reg result_bank_mem [0:RESULT_DEPTH-1];
    reg [7:0] result_roi_mem [0:RESULT_DEPTH-1];
    reg [63:0] result_box_mem [0:RESULT_DEPTH-1];
    reg [2:0] result_color_mem [0:RESULT_DEPTH-1];
    reg [7:0] result_class_mem [0:RESULT_DEPTH-1];
    reg [15:0] result_conf_mem [0:RESULT_DEPTH-1];
    reg [7:0] result_error_mem [0:RESULT_DEPTH-1];
    reg [RES_PTR_BITS-1:0] result_rd_ptr, result_wr_ptr;
    reg [RES_PTR_BITS:0] result_count;
    reg [RES_PTR_BITS+1:0] result_reserved;

    // Release notifications are queued so a dropped pending batch and a
    // simultaneously completed active batch cannot overwrite one another.
    // The queue is in the same DDR clock domain as the service.
    localparam integer RELEASE_PTR_BITS = (RELEASE_DEPTH <= 2) ? 1 : $clog2(RELEASE_DEPTH);
    reg release_bank_mem [0:RELEASE_DEPTH-1];
    reg [31:0] release_frame_mem [0:RELEASE_DEPTH-1];
    reg [RELEASE_PTR_BITS-1:0] release_rd_ptr, release_wr_ptr;
    reg [RELEASE_PTR_BITS:0] release_count;

    wire result_pop = result_valid && result_ready;
    wire selected_cam_valid = (q_count[rr_next] != 0) || (q_count[~rr_next] != 0);
    wire selected_cam = (q_count[rr_next] != 0) ? rr_next : ~rr_next;
    wire batch_cam_valid = (batch_camera == 8'd1) || (batch_camera == 8'd2);
    wire batch_cam = (batch_camera == 8'd2);
    wire batch_shape_valid = (batch_count != 0) && (batch_count <= MAX_ROIS) &&
                             (batch_class_count != 0) && (batch_class_count <= MAX_CLASSES) &&
                             (batch_feature_count != 0) && (batch_feature_count <= MAX_FEATURES);
    wire batch_will_drop = active && (q_count[batch_cam] >= QUEUE_DEPTH);
    wire active_final_done = active && engine_done &&
                             (active_roi + 1 >= active_count);
    wire [31:0] batch_drop_slots = batch_will_drop ?
                                    q_count_rois[batch_cam][q_head[batch_cam]] : 32'd0;
    // A same-cycle result POP and an allowed whole-batch eviction both free
    // result capacity before the newly accepted batch can consume it.
    wire [31:0] result_slots_used = result_reserved + result_count;
    wire [31:0] result_slots_freed = (result_pop ? 32'd1 : 32'd0) + batch_drop_slots;
    wire batch_capacity_valid = (result_slots_used + batch_count <=
                                 RESULT_DEPTH + result_slots_freed);
    // When a queue is full, allow replacement only while another batch is
    // active.  This avoids a same-cycle scheduler/pop ambiguity and still
    // provides the required oldest-pending-batch eviction under load.
    assign batch_ready = enable && !stop && batch_cam_valid && batch_shape_valid &&
                         batch_capacity_valid &&
                         !active_final_done &&
                         ((q_count[batch_cam] < QUEUE_DEPTH) || active);

    assign result_valid = (result_count != 0);
    assign result_camera = result_camera_mem[result_rd_ptr];
    assign result_frame = result_frame_mem[result_rd_ptr];
    assign result_bank = result_bank_mem[result_rd_ptr];
    assign result_roi = result_roi_mem[result_rd_ptr];
    assign result_box = result_box_mem[result_rd_ptr];
    assign result_color = result_color_mem[result_rd_ptr];
    assign result_class = result_class_mem[result_rd_ptr];
    assign result_confidence = result_conf_mem[result_rd_ptr];
    assign result_error = result_error_mem[result_rd_ptr];
    assign result_record = {
        108'b0,
        result_error,
        result_confidence,
        result_class,
        result_color,
        result_box,
        result_roi,
        result_bank,
        result_frame,
        result_camera
    };

    wire engine_start = enable && !stop && active && !engine_issued;
    wire engine_busy;
    wire engine_done;
    wire engine_error;
    wire [7:0] engine_error_code;
    wire [7:0] engine_class;
    wire [15:0] engine_confidence;

    Hnpu_fc_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES), .AXI_ID(AXI_ID),
        .MAX_FEATURES(MAX_FEATURES), .MAX_CLASSES(MAX_CLASSES)
    ) u_fc_engine (
        .clk(clk), .rst_n(rst_n), .start(engine_start), .clear_error(clear_errors),
        .input_addr(active_input_base + active_roi * active_input_stride),
        .input_bytes(active_input_bytes), .weight_addr(active_weight_base),
        .weight_stride(active_weight_stride), .bias_addr(active_bias_base),
        .feature_count(active_feature_count), .class_count(active_class_count),
        .quant_shift(active_quant_shift), .busy(engine_busy), .done_pulse(engine_done),
        .error(engine_error), .error_code(engine_error_code), .result_class(engine_class),
        .result_confidence(engine_confidence), .result_score(),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
        .axi_rresp(axi_rresp), .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready)
    );

    integer i, j, k;
    integer cam_index;
    integer queue_index;
    integer reserve_next;
    integer result_count_next;
    integer q_count_next0;
    integer q_count_next1;
    integer release_count_next;
    reg take_queue;
    reg take_cam;
    reg accept_batch;
    reg drop_batch;
    reg enqueue_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_head[0] <= 0; q_head[1] <= 0;
            q_tail[0] <= 0; q_tail[1] <= 0;
            q_count[0] <= 0; q_count[1] <= 0;
            active <= 0; active_cam <= 0; active_bank <= 0; active_frame <= 0;
            active_input_base <= 0; active_input_stride <= 0; active_input_bytes <= 0;
            active_feature_count <= 0; active_weight_base <= 0; active_weight_stride <= 0;
            active_bias_base <= 0; active_count <= 0; active_class_count <= 0;
            active_quant_shift <= 0; active_roi <= 0; engine_issued <= 0; rr_next <= 0;
            result_rd_ptr <= 0; result_wr_ptr <= 0; result_count <= 0; result_reserved <= 0;
            release_rd_ptr <= 0; release_wr_ptr <= 0; release_count <= 0;
            int8_release_valid <= 0; int8_release_bank <= 0; int8_release_frame <= 0;
            busy <= 0; error <= 0; error_code <= 0;
            accepted_batches <= 0; completed_batches <= 0; dropped_batches <= 0;
            completed_rois <= 0; error_rois <= 0; released_banks <= 0; fifo_overflows <= 0;
            for (i = 0; i < MAX_ROIS; i = i + 1) begin
                active_boxes[i] <= 0;
                active_colors[i] <= 0;
            end
        end else begin
            int8_release_valid <= (release_count != 0);
            if (release_count != 0) begin
                int8_release_bank <= release_bank_mem[release_rd_ptr];
                int8_release_frame <= release_frame_mem[release_rd_ptr];
                release_rd_ptr <= (release_rd_ptr == RELEASE_DEPTH-1) ? 0 : release_rd_ptr + 1'b1;
                released_banks <= released_banks + 1'b1;
            end
            busy <= active || (q_count[0] != 0) || (q_count[1] != 0) || engine_busy;
            if (clear_errors) begin
                error <= 1'b0;
                error_code <= 0;
            end
	
            reserve_next = result_reserved;
            result_count_next = result_count;
            q_count_next0 = q_count[0];
            q_count_next1 = q_count[1];
            release_count_next = release_count;
            if (release_count != 0)
                release_count_next = release_count_next - 1;
            accept_batch = batch_valid && batch_ready;
            drop_batch = accept_batch && (q_count[batch_cam] >= QUEUE_DEPTH);
            enqueue_result = engine_done && active;

           /* 每个周期计算一次队列占用率。一个新的批次和一个
			调度器出队可能合法地针对同一摄像头在
			一个周期；否则，分离的非阻塞赋值将导致
			丢失两次更新中的其中一次。*/
            take_queue = !active && !engine_busy && !stop && selected_cam_valid;
            take_cam = selected_cam;

            if (result_pop) begin
                if (result_count_next != 0) begin
                    result_rd_ptr <= (result_rd_ptr == RESULT_DEPTH-1) ? 0 : result_rd_ptr + 1'b1;
                    result_count_next = result_count_next - 1;
                end
            end

            if (accept_batch) begin
                cam_index = batch_cam;
                queue_index = q_tail[cam_index];
                q_frame[cam_index][queue_index] <= batch_frame;
                q_bank[cam_index][queue_index] <= batch_bank;
                q_input_base[cam_index][queue_index] <= batch_input_base;
                q_input_stride[cam_index][queue_index] <= batch_input_stride;
                q_input_bytes[cam_index][queue_index] <= batch_input_bytes;
                q_feature_count[cam_index][queue_index] <= batch_feature_count;
                q_weight_base[cam_index][queue_index] <= batch_weight_base;
                q_weight_stride[cam_index][queue_index] <= batch_weight_stride;
                q_bias_base[cam_index][queue_index] <= batch_bias_base;
                q_count_rois[cam_index][queue_index] <= batch_count;
                q_class_count[cam_index][queue_index] <= batch_class_count;
                q_quant_shift[cam_index][queue_index] <= batch_quant_shift;
                for (j = 0; j < MAX_ROIS; j = j + 1) begin
                    q_boxes[cam_index][queue_index][j] <= batch_boxes[j*64 +: 64];
                    q_colors[cam_index][queue_index][j] <= batch_colors[j*3 +: 3];
                end
                q_tail[cam_index] <= (q_tail[cam_index] == QUEUE_DEPTH-1) ? 0 : q_tail[cam_index] + 1'b1;
                if (drop_batch) begin
                    q_head[cam_index] <= (q_head[cam_index] == QUEUE_DEPTH-1) ? 0 : q_head[cam_index] + 1'b1;
                    dropped_batches <= dropped_batches + 1'b1;
                    reserve_next = reserve_next - q_count_rois[cam_index][q_head[cam_index]];
                    if (release_count_next < RELEASE_DEPTH) begin
                        release_bank_mem[release_wr_ptr] <= q_bank[cam_index][q_head[cam_index]];
                        release_frame_mem[release_wr_ptr] <= q_frame[cam_index][q_head[cam_index]];
                        release_wr_ptr <= (release_wr_ptr == RELEASE_DEPTH-1) ? 0 : release_wr_ptr + 1'b1;
                        release_count_next = release_count_next + 1;
                    end else begin
                        error <= 1'b1;
                        error_code <= 8'd7;
                    end
                end else begin
                    if (cam_index == 0)
                        q_count_next0 = q_count_next0 + 1;
                    else
                        q_count_next1 = q_count_next1 + 1;
                end
                reserve_next = reserve_next + batch_count;
                accepted_batches <= accepted_batches + 1'b1;
            end

            if (enqueue_result) begin
                if ((result_count_next < RESULT_DEPTH) || result_pop) begin
                    result_camera_mem[result_wr_ptr] <= active_cam ? 8'd2 : 8'd1;
                    result_frame_mem[result_wr_ptr] <= active_frame;
                    result_bank_mem[result_wr_ptr] <= active_bank;
                    result_roi_mem[result_wr_ptr] <= active_roi;
                    result_box_mem[result_wr_ptr] <= active_boxes[active_roi];
                    result_color_mem[result_wr_ptr] <= active_colors[active_roi];
                    result_class_mem[result_wr_ptr] <= engine_error ? 8'hff : engine_class;
                    result_conf_mem[result_wr_ptr] <= engine_error ? 0 : engine_confidence;
                    result_error_mem[result_wr_ptr] <= engine_error ? engine_error_code : 0;
                    result_wr_ptr <= (result_wr_ptr == RESULT_DEPTH-1) ? 0 : result_wr_ptr + 1'b1;
                    result_count_next = result_count_next + 1;
                    reserve_next = reserve_next - 1;
                    if (engine_error)
                        begin
                        error_rois <= error_rois + 1'b1;
                        error <= 1'b1;
                        error_code <= engine_error_code;
                        end
                    else
                        completed_rois <= completed_rois + 1'b1;
                end else begin
                    fifo_overflows <= fifo_overflows + 1'b1;
                    error <= 1'b1;
                    error_code <= 8'd6;
                end
            end

            // Start the oldest pending batch only when the shared engine is idle.
            if (take_queue) begin
                queue_index = q_head[take_cam];
                active <= 1'b1;
                active_cam <= take_cam;
                active_bank <= q_bank[take_cam][queue_index];
                active_frame <= q_frame[take_cam][queue_index];
                active_input_base <= q_input_base[take_cam][queue_index];
                active_input_stride <= q_input_stride[take_cam][queue_index];
                active_input_bytes <= q_input_bytes[take_cam][queue_index];
                active_feature_count <= q_feature_count[take_cam][queue_index];
                active_weight_base <= q_weight_base[take_cam][queue_index];
                active_weight_stride <= q_weight_stride[take_cam][queue_index];
                active_bias_base <= q_bias_base[take_cam][queue_index];
                active_count <= q_count_rois[take_cam][queue_index];
                active_class_count <= q_class_count[take_cam][queue_index];
                active_quant_shift <= q_quant_shift[take_cam][queue_index];
                for (k = 0; k < MAX_ROIS; k = k + 1) begin
                    active_boxes[k] <= q_boxes[take_cam][queue_index][k];
                    active_colors[k] <= q_colors[take_cam][queue_index][k];
                end
                active_roi <= 0;
                engine_issued <= 0;
                q_head[take_cam] <= (q_head[take_cam] == QUEUE_DEPTH-1) ? 0 : q_head[take_cam] + 1'b1;
                if (take_cam == 0)
                    q_count_next0 = q_count_next0 - 1;
                else
                    q_count_next1 = q_count_next1 - 1;
                rr_next <= ~take_cam;
            end

            if (engine_start)
                engine_issued <= 1'b1;

            if (engine_done && active) begin
                engine_issued <= 1'b0;
                if (active_roi + 1 >= active_count) begin
                    active <= 1'b0;
                    completed_batches <= completed_batches + 1'b1;
                    if (release_count_next < RELEASE_DEPTH) begin
                        release_bank_mem[release_wr_ptr] <= active_bank;
                        release_frame_mem[release_wr_ptr] <= active_frame;
                        release_wr_ptr <= (release_wr_ptr == RELEASE_DEPTH-1) ? 0 : release_wr_ptr + 1'b1;
                        release_count_next = release_count_next + 1;
                    end else begin
                        error <= 1'b1;
                        error_code <= 8'd7;
                    end
                end else begin
                    active_roi <= active_roi + 1'b1;
                end
            end

            result_reserved <= reserve_next;
            result_count <= result_count_next;
            q_count[0] <= q_count_next0;
            q_count[1] <= q_count_next1;
            release_count <= release_count_next;
        end
    end
endmodule
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on WIDTHEXPAND */
