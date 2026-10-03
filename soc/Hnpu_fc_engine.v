`timescale 1ns / 1ps
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */

// ============================================================================
// Hnpu_fc_engine
//
// V1 NPU compute engine for the current project.  It implements a static,
// signed-int8 fully-connected classifier:
//
//   score[c] = bias[c] + sum(input[i] * weight[c][i])
//   score[c] = arithmetic_shift_right(score[c], quant_shift)
//
// Input, weights and bias are read through the same 256-bit AXI4 DDR contract
// used by Hnpu_dma.  The engine intentionally processes one ROI at a time;
// Hnpu_service supplies the two-camera queues and result ownership around it.
//
// V1 restrictions are explicit and checked at start:
// - signed int8 input/weight, symmetric zero point 0;
// - input bytes and weight stride are 32-byte aligned;
// - feature_count <= MAX_FEATURES, class_count <= MAX_CLASSES;
// - bias is one aligned 256-bit line containing up to MAX_CLASSES int32 values;
// - no unapproved model parser or floating-point operation is hidden here.
// ============================================================================
module Hnpu_fc_engine #(
    parameter [31:0] DDR_BASE = 32'h8000_0000,
    parameter [31:0] DDR_BYTES = 32'h4000_0000,
    parameter [7:0]  AXI_ID = 8'h80,
    parameter [4:0]  MAX_BURST_BEATS = 5'd16,
    parameter integer R_DRAIN_TIMEOUT = 256,
    parameter integer MAX_FEATURES = 1024,
    parameter integer MAX_CLASSES = 8
) (
    input              clk,
    input              rst_n,
    input              start,
    input              clear_error,

    input      [31:0]  input_addr,
    input      [31:0]  input_bytes,
    input      [31:0]  weight_addr,
    input      [31:0]  weight_stride,
    input      [31:0]  bias_addr,
    input      [15:0]  feature_count,
    input      [7:0]   class_count,
    input      [5:0]   quant_shift,

    output reg         busy,
    output reg         done_pulse,
    output reg         error,
    output reg [7:0]   error_code,
    output reg [7:0]   result_class,
    output reg [15:0]  result_confidence,
    output reg [31:0]  result_score,

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

    localparam [3:0] ST_IDLE = 4'd0;
    localparam [3:0] ST_AR   = 4'd1;
    localparam [3:0] ST_R    = 4'd2;
    localparam [3:0] ST_MAC  = 4'd3;
    // A malformed slave may assert RLAST after the expected beat.  Keep
    // accepting the response until that burst terminator arrives so an
    // upstream AXI arbiter can release its read ownership.
    localparam [3:0] ST_R_DRAIN = 4'd4;

    localparam [1:0] PH_INPUT = 2'd0;
    localparam [1:0] PH_BIAS  = 2'd1;
    localparam [1:0] PH_WEIGHT = 2'd2;

    localparam [7:0] ERR_BAD_CONFIG = 8'd1;
    localparam [7:0] ERR_RRESP      = 8'd2;
    localparam [7:0] ERR_RID        = 8'd3;
    localparam [7:0] ERR_RLAST      = 8'd4;
    localparam [7:0] ERR_RANGE      = 8'd5;
    localparam [31:0] MAX_FEATURES_U32 = MAX_FEATURES;
    localparam [31:0] MAX_CLASSES_U32 = MAX_CLASSES;

    localparam integer MAX_FEATURE_BYTES = ((MAX_FEATURES + 31) / 32) * 32;
    localparam [31:0] MAX_FEATURE_BYTES_U32 = MAX_FEATURE_BYTES;

    initial begin
        if (MAX_FEATURES < 1)
            $fatal(1, "Hnpu_fc_engine MAX_FEATURES must be positive");
        // One 256-bit bias line contains eight int32 values.  V1 does not
        // implement a multi-line bias reader.
        if (MAX_CLASSES < 1 || MAX_CLASSES > 8)
            $fatal(1, "Hnpu_fc_engine V1 supports 1..8 classes");
        if (MAX_BURST_BEATS < 1 || MAX_BURST_BEATS > 16)
            $fatal(1, "Hnpu_fc_engine MAX_BURST_BEATS must be 1..16");
    end

    reg [3:0] state;
    reg [1:0] read_phase;
    reg [31:0] weight_addr_reg, weight_stride_reg, bias_addr_reg;
    reg [15:0] feature_count_reg;
    reg [7:0] class_count_reg, class_index;
    reg [5:0] quant_shift_reg;

    reg [31:0] read_addr_reg;
    reg [31:0] read_remaining_beats;
    reg [31:0] read_byte_offset;
    reg [4:0] burst_beats;
    reg [4:0] read_beat_index;
    reg read_error_seen;
    reg [7:0] read_error_code;
    reg [15:0] drain_wait_count;

    reg signed [7:0] input_mem [0:MAX_FEATURE_BYTES-1];
    reg signed [7:0] weight_mem [0:MAX_FEATURE_BYTES-1];
    reg signed [31:0] bias_mem [0:MAX_CLASSES-1];
    reg [31:0] feature_index;
    reg signed [63:0] accumulator;
    reg signed [31:0] best_score;
    reg signed [31:0] second_score;
    reg [7:0] best_class;

    wire [63:0] ddr_end_ext = {32'b0, DDR_BASE} + {32'b0, DDR_BYTES};
    wire [63:0] input_end_ext = {32'b0, input_addr} + {32'b0, input_bytes};
    wire [63:0] weight_end_ext = {32'b0, weight_addr} +
                                  {32'b0, weight_stride} * {56'b0, class_count};
    wire [63:0] bias_end_ext = {32'b0, bias_addr} + 64'd32;

    wire input_shape_ok = (input_bytes != 0) &&
                          (input_bytes[4:0] == 0) &&
                          (input_bytes <= MAX_FEATURE_BYTES_U32) &&
                          (input_bytes >= {16'b0, feature_count}) &&
                          (feature_count != 0) &&
                          ({16'b0, feature_count} <= MAX_FEATURES_U32);
    wire weight_shape_ok = (weight_stride != 0) &&
                           (weight_stride[4:0] == 0) &&
                           (weight_stride >= ((({16'b0, feature_count} + 32'd31) >> 5) << 5));
    wire class_shape_ok = (class_count != 0) && ({24'b0, class_count} <= MAX_CLASSES_U32);
    wire address_align_ok = (input_addr[4:0] == 0) &&
                            (weight_addr[4:0] == 0) &&
                            (weight_stride[4:0] == 0) &&
                            (bias_addr[4:0] == 0);
    // A single 32-byte bias beat must remain inside its 4 KiB AXI window.
    wire bias_boundary_ok = (bias_addr[11:0] <= 12'hfe0);
    wire address_range_ok = (input_addr >= DDR_BASE) &&
                            (weight_addr >= DDR_BASE) &&
                            (bias_addr >= DDR_BASE) &&
                            (input_end_ext <= ddr_end_ext) &&
                            (weight_end_ext <= ddr_end_ext) &&
                            (bias_end_ext <= ddr_end_ext);
    wire start_valid = input_shape_ok && weight_shape_ok && class_shape_ok &&
                       address_align_ok && bias_boundary_ok && address_range_ok &&
                       (quant_shift <= 6'd31);

    function [4:0] calc_burst;
        input [31:0] remaining;
        input [31:0] address;
        reg [31:0] to_4k;
        reg [31:0] chosen;
        begin
            to_4k = (32'd4096 - {20'b0, address[11:0]}) >> 5;
            chosen = remaining;
            if (chosen > 32'd16)
                chosen = 32'd16;
            if (chosen > {27'b0, MAX_BURST_BEATS})
                chosen = {27'b0, MAX_BURST_BEATS};
            if (chosen > to_4k)
                chosen = to_4k;
            calc_burst = chosen[4:0];
        end
    endfunction

    wire signed [63:0] product = $signed(input_mem[feature_index]) *
                                  $signed(weight_mem[feature_index]);
    wire signed [63:0] accumulator_next = accumulator + product;
    wire signed [63:0] score_wide = accumulator_next >>> quant_shift_reg;
    wire signed [31:0] score_next = score_wide[31:0];

    function [15:0] confidence16;
        input signed [31:0] top_score;
        input signed [31:0] runner_score;
        reg signed [32:0] difference;
        begin
            difference = {top_score[31], top_score} - {runner_score[31], runner_score};
            if (difference <= 0)
                confidence16 = 16'd0;
            else if (difference > 33'sd65535)
                confidence16 = 16'hffff;
            else
                confidence16 = difference[15:0];
        end
    endfunction

    wire [31:0] read_local_addr = read_addr_reg - DDR_BASE;
    assign axi_araddr  = read_local_addr[29:0];
    assign axi_arid    = AXI_ID;
    assign axi_arlen   = {3'b0, burst_beats} - 8'd1;
    assign axi_arsize  = 3'b101;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = (state == ST_AR);
    assign axi_rready  = (state == ST_R) || (state == ST_R_DRAIN);

    integer lane;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            read_phase <= PH_INPUT;
            busy <= 1'b0;
            done_pulse <= 1'b0;
            error <= 1'b0;
            error_code <= 8'd0;
            result_class <= 8'd0;
            result_confidence <= 16'd0;
            result_score <= 32'd0;
            weight_addr_reg <= 0;
            weight_stride_reg <= 0;
            bias_addr_reg <= 0;
            feature_count_reg <= 0;
            class_count_reg <= 0;
            class_index <= 0;
            quant_shift_reg <= 0;
            read_addr_reg <= 0;
            read_remaining_beats <= 0;
            read_byte_offset <= 0;
            burst_beats <= 0;
            read_beat_index <= 0;
            read_error_seen <= 0;
            read_error_code <= 0;
            drain_wait_count <= 0;
            feature_index <= 0;
            accumulator <= 0;
            best_score <= 0;
            second_score <= 0;
            best_class <= 0;
        end else begin
            done_pulse <= 1'b0;
            if (clear_error)
                error <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start && !busy) begin
                        error <= 1'b0;
                        error_code <= 8'd0;
                        result_class <= 0;
                        result_confidence <= 0;
                        result_score <= 0;
                        if (!start_valid) begin
                            error <= 1'b1;
                            error_code <= !address_range_ok ? ERR_RANGE : ERR_BAD_CONFIG;
                            done_pulse <= 1'b1;
                        end else begin
                            busy <= 1'b1;
                            weight_addr_reg <= weight_addr;
                            weight_stride_reg <= weight_stride;
                            bias_addr_reg <= bias_addr;
                            feature_count_reg <= feature_count;
                            class_count_reg <= class_count;
                            quant_shift_reg <= quant_shift;
                            read_phase <= PH_INPUT;
                            read_addr_reg <= input_addr;
                            read_remaining_beats <= input_bytes >> 5;
                            read_byte_offset <= 0;
                            burst_beats <= calc_burst(input_bytes >> 5, input_addr);
                            read_beat_index <= 0;
                            read_error_seen <= 0;
                            read_error_code <= 0;
                            drain_wait_count <= 0;
                            state <= ST_AR;
                        end
                    end
                end

                ST_AR: begin
                    if (axi_arvalid && axi_arready) begin
                        read_beat_index <= 0;
                        read_error_seen <= 0;
                        read_error_code <= 0;
                        drain_wait_count <= 0;
                        state <= ST_R;
                    end
                end

                ST_R: begin
                    if (axi_rvalid && axi_rready) begin
                        if (read_phase == PH_INPUT) begin
                            if (read_beat_index < burst_beats) begin
                                for (lane = 0; lane < 32; lane = lane + 1)
                                    if ((read_byte_offset + read_beat_index * 32 + lane) < MAX_FEATURE_BYTES)
                                        input_mem[read_byte_offset + read_beat_index * 32 + lane] <=
                                            axi_rdata[lane*8 +: 8];
                            end
                        end else if (read_phase == PH_WEIGHT) begin
                            if (read_beat_index < burst_beats) begin
                                for (lane = 0; lane < 32; lane = lane + 1)
                                    if ((read_byte_offset + read_beat_index * 32 + lane) < MAX_FEATURE_BYTES)
                                        weight_mem[read_byte_offset + read_beat_index * 32 + lane] <=
                                            axi_rdata[lane*8 +: 8];
                            end
                        end else if (read_phase == PH_BIAS) begin
                            for (lane = 0; lane < MAX_CLASSES; lane = lane + 1)
                                bias_mem[lane] <= axi_rdata[lane*32 +: 32];
                        end

                        if ((axi_rid != AXI_ID) || (axi_rresp != 2'b00))
                            read_error_seen <= 1'b1;

                        if ((axi_rid != AXI_ID) || (axi_rresp != 2'b00)) begin
                            if (!read_error_seen) begin
                                read_error_seen <= 1'b1;
                                read_error_code <= (axi_rresp != 2'b00) ? ERR_RRESP : ERR_RID;
                            end
                        end

                        // RLAST early terminates a malformed burst and can be
                        // reported immediately.  If it is late, drain the
                        // remaining response beats while keeping RREADY high;
                        // this is required for a shared AXI read channel.
                        if (axi_rlast) begin
                            if ((read_beat_index != (burst_beats - 1'b1)) ||
                                read_error_seen || (axi_rid != AXI_ID) ||
                                (axi_rresp != 2'b00)) begin
                                busy <= 1'b0;
                                error <= 1'b1;
                                error_code <= read_error_seen ? read_error_code :
                                              ((axi_rresp != 2'b00) ? ERR_RRESP :
                                               ((axi_rid != AXI_ID) ? ERR_RID : ERR_RLAST));
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else if (read_remaining_beats == {27'b0, burst_beats}) begin
                                if (read_phase == PH_INPUT) begin
                                    read_phase <= PH_BIAS;
                                    read_addr_reg <= bias_addr_reg;
                                    read_remaining_beats <= 1;
                                    read_byte_offset <= 0;
                                    burst_beats <= 1;
                                    state <= ST_AR;
                                end else if (read_phase == PH_BIAS) begin
                                    class_index <= 0;
                                    read_phase <= PH_WEIGHT;
                                    read_addr_reg <= weight_addr_reg;
                                    read_remaining_beats <= (feature_count_reg + 31) >> 5;
                                    read_byte_offset <= 0;
                                    burst_beats <= calc_burst((feature_count_reg + 31) >> 5,
                                                              weight_addr_reg);
                                state <= ST_AR;
                            end else begin
                                    feature_index <= 0;
                                    accumulator <= bias_mem[class_index];
                                    state <= ST_MAC;
                                end
                            end else begin
                                read_addr_reg <= read_addr_reg + ({27'b0, burst_beats} << 5);
                                read_remaining_beats <= read_remaining_beats - {27'b0, burst_beats};
                                read_byte_offset <= read_byte_offset + ({27'b0, burst_beats} << 5);
                                burst_beats <= calc_burst(read_remaining_beats - {27'b0, burst_beats},
                                                          read_addr_reg + ({27'b0, burst_beats} << 5));
                                state <= ST_AR;
                            end
                        end else if (read_beat_index == (burst_beats - 1'b1)) begin
                            if (!read_error_seen) begin
                                read_error_seen <= 1'b1;
                                read_error_code <= ERR_RLAST;
                            end
                            drain_wait_count <= 0;
                            state <= ST_R_DRAIN;
                        end else begin
                            read_beat_index <= read_beat_index + 1'b1;
                        end
                    end
                end

                ST_R_DRAIN: begin
                    if (axi_rvalid && axi_rready) begin
                        drain_wait_count <= 0;
                        if (!read_error_seen) begin
                            read_error_seen <= 1'b1;
                            read_error_code <= (axi_rresp != 2'b00) ? ERR_RRESP :
                                               ((axi_rid != AXI_ID) ? ERR_RID : ERR_RLAST);
                        end
                        if (axi_rlast) begin
                            busy <= 1'b0;
                            error <= 1'b1;
                            error_code <= read_error_seen ? read_error_code :
                                          ((axi_rresp != 2'b00) ? ERR_RRESP :
                                           ((axi_rid != AXI_ID) ? ERR_RID : ERR_RLAST));
                            done_pulse <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end else if (drain_wait_count >= R_DRAIN_TIMEOUT - 1) begin
                        // A permanently broken slave must not hold a shared
                        // interconnect forever.  The timeout is a local
                        // containment policy; a conforming slave completes
                        // the drain with RLAST before it expires.
                        busy <= 1'b0;
                        error <= 1'b1;
                        error_code <= read_error_seen ? read_error_code : ERR_RLAST;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        drain_wait_count <= drain_wait_count + 1'b1;
                    end
                end

                ST_MAC: begin
                    accumulator <= accumulator_next;
                    if (feature_index == feature_count_reg - 1'b1) begin
                        if (class_index == 0) begin
                            best_score <= score_next;
                            best_class <= 0;
                            second_score <= -32'sh7fff_ffff;
                            if (class_count_reg == 1) begin
                                result_class <= 0;
                                result_score <= score_next;
                                result_confidence <= 0;
                                busy <= 1'b0;
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else begin
                                class_index <= 1;
                                read_addr_reg <= weight_addr_reg + weight_stride_reg;
                                read_remaining_beats <= (feature_count_reg + 31) >> 5;
                                read_byte_offset <= 0;
                                burst_beats <= calc_burst((feature_count_reg + 31) >> 5,
                                                          weight_addr_reg + weight_stride_reg);
                                state <= ST_AR;
                            end
                        end else if (score_next > best_score) begin
                            if (class_index + 1 >= class_count_reg) begin
                                result_class <= class_index;
                                result_score <= score_next;
                                result_confidence <= confidence16(score_next, best_score);
                                busy <= 1'b0;
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else begin
                                second_score <= best_score;
                                best_score <= score_next;
                                best_class <= class_index;
                                class_index <= class_index + 1'b1;
                                read_addr_reg <= weight_addr_reg +
                                                 (class_index + 1'b1) * weight_stride_reg;
                                read_remaining_beats <= (feature_count_reg + 31) >> 5;
                                read_byte_offset <= 0;
                                burst_beats <= calc_burst((feature_count_reg + 31) >> 5,
                                    weight_addr_reg + (class_index + 1'b1) * weight_stride_reg);
                                state <= ST_AR;
                            end
                        end else if (class_index + 1 >= class_count_reg) begin
                            result_class <= best_class;
                            result_score <= best_score;
                            result_confidence <= confidence16(best_score,
                                (score_next > second_score) ? score_next : second_score);
                            busy <= 1'b0;
                            done_pulse <= 1'b1;
                            state <= ST_IDLE;
                        end else begin
                            if (score_next > second_score)
                                second_score <= score_next;
                            class_index <= class_index + 1'b1;
                            read_addr_reg <= weight_addr_reg +
                                             (class_index + 1'b1) * weight_stride_reg;
                            read_remaining_beats <= (feature_count_reg + 31) >> 5;
                            read_byte_offset <= 0;
                            burst_beats <= calc_burst((feature_count_reg + 31) >> 5,
                                weight_addr_reg + (class_index + 1'b1) * weight_stride_reg);
                            state <= ST_AR;
                        end
                    end else begin
                        feature_index <= feature_index + 1'b1;
                    end
                end

                default: begin
                    busy <= 1'b0;
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on WIDTHEXPAND */
