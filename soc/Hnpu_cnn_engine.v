`timescale 1ns / 1ps

/*
 * Candidate CNN execution engine for the A-side V1 contract.
 *
 * The engine deliberately keeps model bytes and intermediate tensors in
 * bounded local arrays.  It has one AXI read transaction in flight, checks
 * the model package before reading the input tensor, and executes one output
 * element per cycle (one MAC contribution per cycle).  This is a correctness
 * implementation for simulation and resource review, not a throughput claim.
 */
module Hnpu_cnn_engine #(
    parameter [31:0] DDR_BASE = 32'h8000_0000,
    parameter [31:0] DDR_BYTES = 32'h4000_0000,
    parameter [7:0] AXI_ID = 8'h80,
    parameter [4:0] MAX_BURST_BEATS = 5'd16,
    parameter integer R_DRAIN_TIMEOUT = 256,
    parameter integer MAX_MODEL_BYTES = 65536,
    parameter integer MAX_TENSOR_BYTES = 65536,
    parameter integer MAX_LAYERS = 16,
    parameter integer MAX_CLASSES = 16
) (
    input clk,
    input rst_n,
    input start,
    input clear_error,
    input [31:0] model_base,
    input [31:0] model_bytes,
    input [31:0] input_addr,
    // input_bytes is the model tensor length.  input_source_bytes is the
    // number of bytes fetched from DDR for this inference.  In image mode
    // the source is a 96x96x4 HWC4 image (36864 bytes), while the model
    // tensor is the 32x32x4 decimated image (4096 bytes).
    input [31:0] input_bytes,
    input [31:0] input_source_bytes,
    input input_downsample3,

    output reg busy,
    output reg done_pulse,
    output reg error,
    output reg [7:0] error_code,
    output reg [7:0] result_class,
    output reg [15:0] result_confidence,
    output reg result_reject,
    output reg [31:0] result_score,
    // Model residency observability.  cache_hit is a one-cycle pulse at an
    // accepted start; the counters are monotonic until reset.
    output reg model_cache_hit,
    output reg model_cache_valid,
    output reg [31:0] model_load_count,
    output reg [31:0] model_load_beats,

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
    localparam [31:0] MAGIC = 32'h3155_504e;
    localparam integer HEADER_BYTES = 128;
    localparam integer DESC_BYTES = 64;
    localparam [7:0] OP_CONV2D = 8'd1;
    localparam [7:0] OP_RELU = 8'd2;
    localparam [7:0] OP_MAXPOOL = 8'd3;
    localparam [7:0] OP_GAP = 8'd4;
    localparam [7:0] OP_FC = 8'd5;
    localparam [7:0] OP_ARGMAX = 8'd6;

    localparam [7:0] ERR_BAD_CONFIG = 8'h01;
    localparam [7:0] ERR_AXI_RRESP = 8'h02;
    localparam [7:0] ERR_AXI_RID = 8'h03;
    localparam [7:0] ERR_AXI_RLAST = 8'h04;
    localparam [7:0] ERR_RANGE = 8'h05;
    localparam [7:0] ERR_MODEL_MAGIC = 8'h20;
    localparam [7:0] ERR_MODEL_VERSION = 8'h21;
    localparam [7:0] ERR_MODEL_FORMAT = 8'h22;
    localparam [7:0] ERR_MODEL_CRC = 8'h23;
    localparam [7:0] ERR_MODEL_LAYER = 8'h24;
    localparam [7:0] ERR_MODEL_SHAPE = 8'h25;
    localparam [7:0] ERR_UNSUPPORTED_OP = 8'h26;
    localparam [7:0] ERR_TENSOR_RANGE = 8'h27;
    localparam [7:0] ERR_MODEL_QUANT = 8'h28;

    localparam [7:0] LAYOUT_CHW = 8'd1;
    localparam [7:0] LAYOUT_HWC4 = 8'd2;
    localparam [7:0] FLAG_RELU_CLAMP = 8'h01;
    localparam [7:0] FLAG_DIRECT_SHIFT = 8'h02;
    localparam [7:0] FLAG_GAP_ROUND4 = 8'h04;

    localparam [5:0] ST_IDLE = 6'd0;
    localparam [5:0] ST_READ_AR = 6'd1;
    localparam [5:0] ST_READ_R = 6'd2;
    localparam [5:0] ST_READ_DRAIN = 6'd3;
    localparam [5:0] ST_CRC = 6'd4;
    localparam [5:0] ST_VALIDATE = 6'd5;
    localparam [5:0] ST_LAYER_FETCH = 6'd6;
    localparam [5:0] ST_DISPATCH = 6'd7;
    localparam [5:0] ST_CONV_MAC = 6'd8;
    localparam [5:0] ST_RELU = 6'd9;
    localparam [5:0] ST_POOL = 6'd10;
    localparam [5:0] ST_GAP = 6'd11;
    localparam [5:0] ST_FC_MAC = 6'd12;
    localparam [5:0] ST_ARGMAX = 6'd13;
    localparam [5:0] ST_LAYER_NEXT = 6'd14;

    reg [5:0] state;
    (* ram_style = "block" *) reg signed [7:0] model_mem [0:MAX_MODEL_BYTES-1];
    reg signed [7:0] tensor_a [0:MAX_TENSOR_BYTES-1];
    reg signed [7:0] tensor_b [0:MAX_TENSOR_BYTES-1];

    reg [31:0] read_addr_reg;
    reg [31:0] read_remaining_beats;
    reg [31:0] read_offset;
    reg [4:0] burst_beats;
    reg [4:0] read_beat_index;
    reg read_target_input;
    reg read_error_seen;
    reg [7:0] read_error_code;
    reg [15:0] drain_wait_count;

    reg [31:0] model_base_reg, model_bytes_reg;
    reg model_cache_valid_reg;
    reg [31:0] model_cache_base_reg, model_cache_bytes_reg;
    reg [31:0] model_cache_crc_reg;
    reg [31:0] input_addr_reg;
    reg [31:0] input_bytes_reg;
    reg [31:0] input_source_bytes_reg;
    reg input_downsample3_reg;
    reg [31:0] crc_index;
    reg [31:0] crc_reg;
    reg tensor_active;

    reg [7:0] layer_count_reg, class_count_reg, layer_index;
    reg [7:0] model_layout_reg;
    reg [31:0] reject_threshold_reg;
    reg [15:0] expected_in_h, expected_in_w, expected_in_c;
    reg argmax_from_fc;
    reg signed [31:0] fc_output_mem [0:MAX_CLASSES-1];
    reg [7:0] layer_op, layer_flags;
    reg [15:0] layer_in_h, layer_in_w, layer_in_c;
    reg [15:0] layer_out_h, layer_out_w, layer_out_c;
    reg [7:0] layer_kh, layer_kw, layer_sh, layer_sw;
    reg [7:0] layer_pad_top, layer_pad_left, layer_pad_bottom, layer_pad_right;
    reg [31:0] layer_weight_offset, layer_bias_offset;
    reg [31:0] layer_weight_bytes, layer_bias_bytes;
    reg signed [31:0] layer_multiplier;
    reg [5:0] layer_shift;
    reg signed [7:0] layer_input_zp, layer_weight_zp, layer_output_zp;

    integer out_x, out_y, out_c;
    integer kernel_index;
    integer pool_index;
    integer tensor_index;
    integer fc_index, fc_output;
    integer arg_index;
    reg signed [63:0] accumulator;
    reg signed [7:0] pool_value;
    reg signed [63:0] gap_accumulator;
    reg signed [63:0] next_gap_accumulator;
    reg signed [31:0] best_score, second_score;
    reg [7:0] best_class;

    integer lane;
    integer conv_ic, conv_kx, conv_ky, conv_iy, conv_ix;
    integer conv_input_index, conv_weight_index;
    integer conv_kernel_size;
    integer pool_c, pool_ox, pool_oy, pool_iy, pool_ix;
    integer pool_input_index;
    integer gap_channel, gap_position;
    integer fc_input_index, fc_weight_index;
    integer layer_input_elements_int;
    integer layer_output_elements_int;
    integer conv_weight_required_int;
    integer conv_bias_required_int;
    integer fc_weight_required_int;
    integer fc_bias_required_int;
    integer source_offset;
    integer source_pixel;
    integer source_y;
    integer source_x;
    integer source_channel;
    integer tensor_write_index;
    reg signed [63:0] next_accumulator;
    reg signed [31:0] candidate_score;
    reg signed [7:0] pool_next;
    reg signed [31:0] new_best_score;
    reg signed [31:0] new_second_score;
    reg [7:0] new_best_class;
    reg signed [63:0] final_margin;

    function [15:0] model_u16;
        input integer offset;
        begin
            model_u16 = {model_mem[offset+1], model_mem[offset]};
        end
    endfunction

    function [31:0] model_u32;
        input integer offset;
        begin
            model_u32 = {model_mem[offset+3], model_mem[offset+2],
                        model_mem[offset+1], model_mem[offset]};
        end
    endfunction

    function signed [31:0] model_i32;
        input integer offset;
        begin
            model_i32 = {model_mem[offset+3], model_mem[offset+2],
                         model_mem[offset+1], model_mem[offset]};
        end
    endfunction

    function signed [7:0] tensor_read;
        input integer slot;
        input integer offset;
        begin
            tensor_read = (slot == 0) ? tensor_a[offset] : tensor_b[offset];
        end
    endfunction

    function signed [7:0] requantize;
        input signed [63:0] value;
        input signed [31:0] multiplier;
        input [5:0] shift;
        input signed [7:0] zero_point;
        input relu_enable;
        input direct_shift;
        reg signed [95:0] product;
        reg signed [95:0] magnitude;
        reg signed [95:0] rounded;
        reg signed [95:0] scaled;
        reg signed [95:0] result_value;
        begin
            product = value * multiplier;
            magnitude = (product < 0) ? -product : product;
            rounded = (shift == 0) ? magnitude :
                      magnitude + (96'sd1 <<< (shift - 1'b1));
            if (direct_shift)
                scaled = (shift == 0) ? product : (product >>> shift);
            else
                scaled = (shift == 0) ? product :
                         ((product < 0) ? -(rounded >>> shift) :
                                          (rounded >>> shift));
            result_value = scaled + zero_point;
            if (relu_enable && result_value < zero_point)
                result_value = zero_point;
            if (result_value > 96'sd127)
                requantize = 8'sd127;
            else if (result_value < -96'sd128)
                requantize = -8'sd128;
            else
                requantize = result_value[7:0];
        end
    endfunction

    function [4:0] calc_burst;
        input [31:0] remaining;
        input [31:0] address;
        reg [31:0] to_4k;
        reg [31:0] chosen;
        begin
            to_4k = (32'd4096 - {20'b0, address[11:0]}) >> 5;
            chosen = remaining;
            if (chosen > 32'd16) chosen = 32'd16;
            if (chosen > {27'b0, MAX_BURST_BEATS})
                chosen = {27'b0, MAX_BURST_BEATS};
            if (chosen > to_4k) chosen = to_4k;
            calc_burst = chosen[4:0];
        end
    endfunction

    function [31:0] crc32_byte;
        input [31:0] crc;
        input [7:0] data;
        reg [31:0] c;
        integer bit_index;
        begin
            c = crc ^ data;
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                c = c[0] ? ((c >> 1) ^ 32'hedb8_8320) : (c >> 1);
            crc32_byte = c;
        end
    endfunction

    wire [63:0] ddr_end = {32'b0, DDR_BASE} + {32'b0, DDR_BYTES};
    wire [63:0] model_end = {32'b0, model_base} + {32'b0, model_bytes};
    wire [63:0] input_source_end = {32'b0, input_addr} + {32'b0, input_source_bytes};
    wire [32:0] header_desc_end = {1'b0, model_u32(24)} + {1'b0, model_u32(28)};
    wire [32:0] header_weight_end = {1'b0, model_u32(32)} + {1'b0, model_u32(36)};
    wire [32:0] header_bias_end = {1'b0, model_u32(40)} + {1'b0, model_u32(44)};
    wire [63:0] model_input_elements = {48'b0, model_u16(12)} *
                                       {48'b0, model_u16(14)} *
                                       {48'b0, model_u16(16)};
    wire start_config_ok = (model_bytes >= 32'd128) &&
                           (model_bytes <= MAX_MODEL_BYTES) &&
                           (model_bytes[4:0] == 0) &&
                           (input_bytes != 0) && (input_bytes <= MAX_TENSOR_BYTES) &&
                           (input_bytes[4:0] == 0) &&
                           (input_source_bytes != 0) &&
                           (input_source_bytes[4:0] == 0) &&
                           (model_base[4:0] == 0) && (input_addr[4:0] == 0) &&
                           (model_base >= DDR_BASE) && (input_addr >= DDR_BASE) &&
                           (model_end <= ddr_end) && (input_source_end <= ddr_end) &&
                           ((!input_downsample3) ||
                            ((input_source_bytes == 32'd36864) &&
                             (input_bytes == 32'd4096)));
    wire start_cache_hit = model_cache_valid_reg &&
                           (model_base == model_cache_base_reg) &&
                           (model_bytes == model_cache_bytes_reg);
    wire cache_config_ok = !start_cache_hit ||
                           ((model_u32(48) == model_bytes) &&
                            (model_u32(56) == input_bytes));

    wire [31:0] read_local_addr = read_addr_reg - DDR_BASE;
    assign axi_araddr = read_local_addr[29:0];
    assign axi_arid = AXI_ID;
    assign axi_arlen = {3'b0, burst_beats} - 8'd1;
    assign axi_arsize = 3'b101;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = (state == ST_READ_AR);
    assign axi_rready = (state == ST_READ_R) || (state == ST_READ_DRAIN);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            busy <= 1'b0;
            done_pulse <= 1'b0;
            error <= 1'b0;
            error_code <= 0;
            result_class <= 0;
            result_confidence <= 0;
            result_reject <= 1'b0;
            result_score <= 0;
            model_cache_hit <= 1'b0;
            model_cache_valid <= 1'b0;
            model_load_count <= 0;
            model_load_beats <= 0;
            model_base_reg <= 0;
            model_bytes_reg <= 0;
            model_cache_valid_reg <= 1'b0;
            model_cache_base_reg <= 0;
            model_cache_bytes_reg <= 0;
            model_cache_crc_reg <= 0;
            input_addr_reg <= 0;
            input_bytes_reg <= 0;
            input_source_bytes_reg <= 0;
            input_downsample3_reg <= 1'b0;
            read_addr_reg <= 0;
            read_remaining_beats <= 0;
            read_offset <= 0;
            burst_beats <= 0;
            read_beat_index <= 0;
            read_target_input <= 0;
            read_error_seen <= 0;
            read_error_code <= 0;
            drain_wait_count <= 0;
            crc_index <= 0;
            crc_reg <= 0;
            tensor_active <= 0;
            layer_count_reg <= 0;
            class_count_reg <= 0;
            layer_index <= 0;
            model_layout_reg <= LAYOUT_CHW;
            reject_threshold_reg <= 0;
            expected_in_h <= 0; expected_in_w <= 0; expected_in_c <= 0;
            argmax_from_fc <= 1'b0;
            out_x <= 0; out_y <= 0; out_c <= 0;
            kernel_index <= 0; pool_index <= 0;
            tensor_index <= 0; fc_index <= 0; fc_output <= 0;
            arg_index <= 0;
            accumulator <= 0; pool_value <= 0; gap_accumulator <= 0;
            best_score <= 0; second_score <= 0; best_class <= 0;
        end else begin
            done_pulse <= 1'b0;
            model_cache_hit <= 1'b0;
            model_cache_valid <= model_cache_valid_reg;
            if (clear_error) error <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start && !busy) begin
                        error <= 1'b0;
                        error_code <= 0;
                        result_class <= 0;
                        result_confidence <= 0;
                        result_reject <= 1'b0;
                        result_score <= 0;
                        if (!start_config_ok || !cache_config_ok) begin
                            error <= 1'b1;
                            error_code <= ERR_BAD_CONFIG;
                            done_pulse <= 1'b1;
                        end else begin
                            busy <= 1'b1;
                            model_base_reg <= model_base;
                            model_bytes_reg <= model_bytes;
                            input_addr_reg <= input_addr;
                            input_bytes_reg <= input_bytes;
                            input_source_bytes_reg <= input_source_bytes;
                            input_downsample3_reg <= input_downsample3;
                            if (start_cache_hit) begin
                                // Header, descriptors, weights and biases
                                // are already resident in model_mem. Only the
                                // current ROI is fetched for this start.
                                model_cache_hit <= 1'b1;
                                layer_index <= 0;
                                tensor_active <= 1'b0;
                                argmax_from_fc <= 1'b0;
                                expected_in_h <= model_u16(12);
                                expected_in_w <= model_u16(14);
                                expected_in_c <= model_u16(16);
                                read_addr_reg <= input_addr;
                                read_remaining_beats <= input_source_bytes >> 5;
                                burst_beats <= calc_burst(input_source_bytes >> 5, input_addr);
                                read_target_input <= 1'b1;
                            end else begin
                                // A failed or changed model must not leave
                                // the previous package eligible for reuse.
                                // The cache becomes valid again only after the
                                // new package passes CRC/format checks and a
                                // complete inference reaches Argmax.
                                model_cache_valid_reg <= 1'b0;
                                model_cache_valid <= 1'b0;
                                read_addr_reg <= model_base;
                                read_remaining_beats <= model_bytes >> 5;
                                burst_beats <= calc_burst(model_bytes >> 5, model_base);
                                read_target_input <= 1'b0;
                                model_load_count <= model_load_count + 1'b1;
                            end
                            read_offset <= 0;
                            read_beat_index <= 0;
                            read_error_seen <= 0;
                            read_error_code <= 0;
                            drain_wait_count <= 0;
                            state <= ST_READ_AR;
                        end
                    end
                end

                ST_READ_AR: begin
                    if (axi_arready) begin
                        read_beat_index <= 0;
                        read_error_seen <= 0;
                        read_error_code <= 0;
                        drain_wait_count <= 0;
                        state <= ST_READ_R;
                    end
                end

                ST_READ_R: begin
                    if (axi_rvalid) begin
                        if (!read_target_input)
                            model_load_beats <= model_load_beats + 1'b1;
                        if (read_target_input) begin
                            for (lane = 0; lane < 32; lane = lane + 1) begin
                                source_offset = read_offset + read_beat_index * 32 + lane;
                                if (input_downsample3_reg) begin
                                    // Source and destination are both HWC4.
                                    // Keep only pixels (0,3,6,...,93) in both
                                    // dimensions; channel order R,G,B,0 is
                                    // unchanged.
                                    source_pixel = source_offset / 4;
                                    source_channel = source_offset % 4;
                                    source_y = source_pixel / 96;
                                    source_x = source_pixel % 96;
                                    if ((source_y % 3) == 0 &&
                                        (source_x % 3) == 0) begin
                                        tensor_write_index =
                                            ((source_y / 3) * 32 +
                                             (source_x / 3)) * 4 + source_channel;
                                        if (tensor_write_index < input_bytes_reg)
                                            tensor_a[tensor_write_index] <=
                                                axi_rdata[lane*8 +: 8];
                                    end
                                end else if (source_offset < input_bytes_reg) begin
                                    tensor_a[source_offset] <=
                                        axi_rdata[lane*8 +: 8];
                                end
                            end
                        end else begin
                            for (lane = 0; lane < 32; lane = lane + 1)
                                if ((read_offset + read_beat_index * 32 + lane) < MAX_MODEL_BYTES)
                                    model_mem[read_offset + read_beat_index * 32 + lane] <=
                                        axi_rdata[lane*8 +: 8];
                        end

                        if (axi_rid != AXI_ID || axi_rresp != 2'b00) begin
                            read_error_seen <= 1'b1;
                            read_error_code <= (axi_rresp != 2'b00) ? ERR_AXI_RRESP : ERR_AXI_RID;
                        end

                        if (axi_rready && axi_rlast) begin
                            if (read_beat_index != burst_beats - 1'b1 ||
                                read_error_seen || axi_rid != AXI_ID || axi_rresp != 2'b00) begin
                                busy <= 1'b0;
                                error <= 1'b1;
                                error_code <= read_error_seen ? read_error_code :
                                              ((axi_rresp != 2'b00) ? ERR_AXI_RRESP :
                                               ((axi_rid != AXI_ID) ? ERR_AXI_RID : ERR_AXI_RLAST));
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else if (read_remaining_beats == burst_beats) begin
                            if (read_target_input) begin
                                state <= ST_LAYER_FETCH;
                            end else begin
                                crc_index <= HEADER_BYTES;
                                crc_reg <= 32'hffff_ffff;
                                state <= ST_CRC;
                            end
                            end else begin
                                read_addr_reg <= read_addr_reg + (burst_beats << 5);
                                read_remaining_beats <= read_remaining_beats - burst_beats;
                                read_offset <= read_offset + (burst_beats << 5);
                                burst_beats <= calc_burst(read_remaining_beats - burst_beats,
                                                          read_addr_reg + (burst_beats << 5));
                                state <= ST_READ_AR;
                            end
                        end else if (axi_rready && read_beat_index == burst_beats - 1'b1) begin
                            read_error_seen <= 1'b1;
                            read_error_code <= ERR_AXI_RLAST;
                            drain_wait_count <= 0;
                            state <= ST_READ_DRAIN;
                        end else if (axi_rready) begin
                            read_beat_index <= read_beat_index + 1'b1;
                        end
                    end
                end

                ST_READ_DRAIN: begin
                    if (axi_rvalid) begin
                        drain_wait_count <= 0;
                        if (axi_rlast) begin
                            busy <= 1'b0;
                            error <= 1'b1;
                            error_code <= read_error_code;
                            done_pulse <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end else if (drain_wait_count >= R_DRAIN_TIMEOUT - 1) begin
                        busy <= 1'b0;
                        error <= 1'b1;
                        error_code <= read_error_code;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        drain_wait_count <= drain_wait_count + 1'b1;
                    end
                end

                ST_CRC: begin
                    if (crc_index < model_bytes_reg) begin
                        // model_mem stores signed INT8 for MAC operations;
                        // CRC consumes the raw byte and must not sign-extend
                        // weights/bias bytes above 0x7f.
                        crc_reg <= crc32_byte(crc_reg, model_mem[crc_index][7:0]);
                        if (crc_index == model_bytes_reg - 1) begin
                            if (~crc32_byte(crc_reg, model_mem[crc_index][7:0]) != model_u32(64)) begin
                                busy <= 1'b0;
                                error <= 1'b1;
                                error_code <= ERR_MODEL_CRC;
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else begin
                                state <= ST_VALIDATE;
                            end
                        end else begin
                            crc_index <= crc_index + 1;
                        end
                    end else begin
                        state <= ST_VALIDATE;
                    end
                end

                ST_VALIDATE: begin
                    if (model_u32(0) != MAGIC) begin
                        error <= 1'b1; error_code <= ERR_MODEL_MAGIC;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (model_u16(4) != 1 || model_u16(6) != 1) begin
                        error <= 1'b1; error_code <= ERR_MODEL_VERSION;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (model_u16(8) != HEADER_BYTES || model_u16(10) != DESC_BYTES ||
                                 (model_mem[18] != LAYOUT_CHW && model_mem[18] != LAYOUT_HWC4) ||
                                 (model_mem[18] == LAYOUT_HWC4 && model_u16(16) != 4) ||
                                 model_mem[19] != 1 || model_mem[20] != 1 ||
                                 model_mem[21] == 0 || model_mem[22] == 0 || model_mem[21] > MAX_LAYERS ||
                                 model_mem[22] > MAX_CLASSES || model_u32(48) != model_bytes_reg ||
                                 model_u32(24) != HEADER_BYTES ||
                                 model_u32(28) < model_mem[21] * DESC_BYTES ||
                                 header_desc_end[32] || header_desc_end > {1'b0, model_bytes_reg} ||
                                 (model_u32(24) % 32) != 0 ||
                                 (model_u32(32) % 32) != 0 ||
                                 (model_u32(40) % 32) != 0 ||
                                 {1'b0, model_u32(32)} < header_desc_end ||
                                 {1'b0, model_u32(40)} < header_weight_end ||
                                 header_weight_end[32] || header_weight_end > {1'b0, model_bytes_reg} ||
                                 header_bias_end[32] || header_bias_end > {1'b0, model_bytes_reg} ||
                                 model_u32(56) != input_bytes_reg ||
                                 model_u32(56) == 0 || (model_u32(56) % 32) != 0 ||
                                 model_u32(60) < model_u32(56) || (model_u32(60) % 32) != 0) begin
                        error <= 1'b1; error_code <= ERR_MODEL_FORMAT;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (model_input_elements > input_bytes_reg) begin
                        error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else begin
                        layer_count_reg <= model_mem[21];
                        class_count_reg <= model_mem[22];
                        model_layout_reg <= model_mem[18];
                        reject_threshold_reg <= model_u32(76);
                        expected_in_h <= model_u16(12);
                        expected_in_w <= model_u16(14);
                        expected_in_c <= model_u16(16);
                        model_cache_base_reg <= model_base_reg;
                        model_cache_bytes_reg <= model_bytes_reg;
                        model_cache_crc_reg <= model_u32(64);
                        layer_index <= 0;
                        tensor_active <= 0;
                        read_target_input <= 1'b1;
                        read_addr_reg <= input_addr_reg;
                        read_remaining_beats <= input_source_bytes_reg >> 5;
                        read_offset <= 0;
                        burst_beats <= calc_burst(input_source_bytes_reg >> 5, input_addr_reg);
                        state <= ST_READ_AR;
                    end
                end

                ST_LAYER_FETCH: begin
                    if (layer_index >= layer_count_reg) begin
                        error <= 1'b1; error_code <= ERR_MODEL_LAYER;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else begin
                        tensor_index = HEADER_BYTES + layer_index * DESC_BYTES;
                        layer_op <= model_mem[tensor_index];
                        layer_flags <= model_mem[tensor_index+1];
                        layer_in_h <= model_u16(tensor_index+2);
                        layer_in_w <= model_u16(tensor_index+4);
                        layer_in_c <= model_u16(tensor_index+6);
                        layer_out_h <= model_u16(tensor_index+8);
                        layer_out_w <= model_u16(tensor_index+10);
                        layer_out_c <= model_u16(tensor_index+12);
                        layer_kh <= model_mem[tensor_index+14];
                        layer_kw <= model_mem[tensor_index+15];
                        layer_sh <= model_mem[tensor_index+16];
                        layer_sw <= model_mem[tensor_index+17];
                        layer_pad_top <= model_mem[tensor_index+18];
                        layer_pad_left <= model_mem[tensor_index+19];
                        layer_pad_bottom <= model_mem[tensor_index+20];
                        layer_pad_right <= model_mem[tensor_index+21];
                        layer_weight_offset <= model_u32(tensor_index+32);
                        layer_bias_offset <= model_u32(tensor_index+36);
                        layer_weight_bytes <= model_u32(tensor_index+40);
                        layer_bias_bytes <= model_u32(tensor_index+44);
                        layer_multiplier <= model_i32(tensor_index+48);
                        layer_shift <= model_mem[tensor_index+52];
                        layer_input_zp <= model_mem[tensor_index+53];
                        layer_weight_zp <= model_mem[tensor_index+54];
                        layer_output_zp <= model_mem[tensor_index+55];
                        state <= ST_DISPATCH;
                    end
                end

                ST_DISPATCH: begin
                    // Widen shape/parameter arithmetic before comparison.  A
                    // descriptor field is 16/8 bits, so multiplying the raw
                    // fields can otherwise wrap before MAX_TENSOR_BYTES is
                    // consulted for a malformed package.
                    layer_input_elements_int = layer_in_h;
                    layer_input_elements_int = layer_input_elements_int * layer_in_w;
                    layer_input_elements_int = layer_input_elements_int * layer_in_c;
                    layer_output_elements_int = layer_out_h;
                    layer_output_elements_int = layer_output_elements_int * layer_out_w;
                    layer_output_elements_int = layer_output_elements_int * layer_out_c;
                    conv_weight_required_int = layer_out_c;
                    conv_weight_required_int = conv_weight_required_int * layer_kh;
                    conv_weight_required_int = conv_weight_required_int * layer_kw;
                    conv_weight_required_int = conv_weight_required_int * layer_in_c;
                    conv_bias_required_int = layer_out_c * 4;
                    fc_weight_required_int = layer_out_c * layer_in_c;
                    fc_bias_required_int = layer_out_c * 4;
                    if (layer_op != OP_CONV2D && layer_op != OP_RELU &&
                        layer_op != OP_MAXPOOL && layer_op != OP_GAP &&
                        layer_op != OP_FC && layer_op != OP_ARGMAX) begin
                        error <= 1'b1; error_code <= ERR_UNSUPPORTED_OP;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (layer_in_h == 0 || layer_in_w == 0 || layer_in_c == 0 ||
                                 layer_out_h == 0 || layer_out_w == 0 || layer_out_c == 0 ||
                                 layer_in_h != expected_in_h || layer_in_w != expected_in_w ||
                                 layer_in_c != expected_in_c ||
                                 layer_input_elements_int > MAX_TENSOR_BYTES ||
                                 layer_output_elements_int > MAX_TENSOR_BYTES ||
                                 model_mem[tensor_index+52] < 0 || model_mem[tensor_index+52] > 31 ||
                                 (layer_weight_bytes != 0 && (layer_weight_offset % 32) != 0) ||
                                 (layer_bias_bytes != 0 && (layer_bias_offset % 32) != 0) ||
                                 (layer_weight_bytes == 0 && layer_weight_offset != 0) ||
                                 (layer_bias_bytes == 0 && layer_bias_offset != 0) ||
                                 (layer_weight_bytes != 0 &&
                                  ({1'b0, layer_weight_offset} < {1'b0, model_u32(32)} ||
                                   ({1'b0, layer_weight_offset} + {1'b0, layer_weight_bytes}) > header_weight_end)) ||
                                 (layer_bias_bytes != 0 &&
                                  ({1'b0, layer_bias_offset} < {1'b0, model_u32(40)} ||
                                   ({1'b0, layer_bias_offset} + {1'b0, layer_bias_bytes}) > header_bias_end)) ||
                                 ({1'b0, layer_weight_offset} + {1'b0, layer_weight_bytes}) >
                                     {1'b0, model_bytes_reg} ||
                                 ({1'b0, layer_bias_offset} + {1'b0, layer_bias_bytes}) >
                                     {1'b0, model_bytes_reg}) begin
                        error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (layer_op == OP_CONV2D) begin
                        if (layer_kh == 0 || layer_kw == 0 || layer_sh == 0 || layer_sw == 0 ||
                            layer_weight_bytes < conv_weight_required_int ||
                            layer_bias_bytes < conv_bias_required_int ||
                            layer_out_h != ((layer_in_h + layer_pad_top + layer_pad_bottom - layer_kh) / layer_sh + 1) ||
                            layer_out_w != ((layer_in_w + layer_pad_left + layer_pad_right - layer_kw) / layer_sw + 1)) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                            out_x <= 0; out_y <= 0; out_c <= 0; kernel_index <= 0;
                            accumulator <= model_i32(layer_bias_offset);
                            state <= ST_CONV_MAC;
                        end
                    end else if (layer_op == OP_RELU) begin
                        tensor_index <= 0;
                        state <= ST_RELU;
                    end else if (layer_op == OP_MAXPOOL) begin
                        if (layer_kh == 0 || layer_kw == 0 || layer_sh == 0 || layer_sw == 0 ||
                            layer_out_c != layer_in_c ||
                            layer_out_h != ((layer_in_h - layer_kh) / layer_sh + 1) ||
                            layer_out_w != ((layer_in_w - layer_kw) / layer_sw + 1)) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                            out_x <= 0; out_y <= 0; out_c <= 0; pool_index <= 0;
                            pool_value <= -8'sd128;
                            state <= ST_POOL;
                        end
                    end else if (layer_op == OP_GAP) begin
                        if (((layer_flags & FLAG_GAP_ROUND4) != 0) &&
                            (layer_in_h != 4 || layer_in_w != 4) ||
                            layer_out_h != 1 || layer_out_w != 1 || layer_out_c != layer_in_c) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                            gap_channel <= 0; gap_position <= 0; gap_accumulator <= 0;
                            state <= ST_GAP;
                        end
                    end else if (layer_op == OP_FC) begin
                        if (layer_in_h != 1 || layer_in_w != 1 ||
                            layer_weight_bytes < fc_weight_required_int ||
                            layer_bias_bytes < fc_bias_required_int) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                        fc_output <= 0; fc_index <= 0;
                        accumulator <= model_i32(layer_bias_offset);
                        state <= ST_FC_MAC;
                        end
                    end else begin
                        arg_index <= 0;
                        best_score <= -32'sh7fff_ffff;
                        second_score <= -32'sh7fff_ffff;
                        best_class <= 0;
                        state <= ST_ARGMAX;
                    end
                end

                ST_CONV_MAC: begin
                    conv_kernel_size = layer_kh * layer_kw * layer_in_c;
                    conv_ky = kernel_index / (layer_kw * layer_in_c);
                    conv_kx = (kernel_index / layer_in_c) % layer_kw;
                    conv_ic = kernel_index % layer_in_c;
                    conv_iy = out_y * layer_sh + conv_ky - layer_pad_top;
                    conv_ix = out_x * layer_sw + conv_kx - layer_pad_left;
                    next_accumulator = accumulator;
                    if (conv_iy >= 0 && conv_iy < layer_in_h && conv_ix >= 0 && conv_ix < layer_in_w) begin
                        if (model_layout_reg == LAYOUT_HWC4)
                            conv_input_index = (conv_iy * layer_in_w + conv_ix) * layer_in_c + conv_ic;
                        else
                            conv_input_index = conv_ic * layer_in_h * layer_in_w + conv_iy * layer_in_w + conv_ix;
                        conv_weight_index = out_c * conv_kernel_size + kernel_index;
                        next_accumulator = accumulator +
                            (tensor_read(tensor_active, conv_input_index) - layer_input_zp) *
                            (model_mem[layer_weight_offset + conv_weight_index] - layer_weight_zp);
                    end
                    if (kernel_index == conv_kernel_size - 1) begin
                        if (model_layout_reg == LAYOUT_HWC4)
                            tensor_index = (out_y * layer_out_w + out_x) * layer_out_c + out_c;
                        else
                            tensor_index = out_c * layer_out_h * layer_out_w + out_y * layer_out_w + out_x;
                        if (tensor_active == 0)
                            tensor_b[tensor_index] <= requantize(next_accumulator, layer_multiplier, layer_shift, layer_output_zp, layer_flags[0], layer_flags[1]);
                        else
                            tensor_a[tensor_index] <= requantize(next_accumulator, layer_multiplier, layer_shift, layer_output_zp, layer_flags[0], layer_flags[1]);
                        kernel_index <= 0;
                        if (out_x == layer_out_w - 1) begin
                            out_x <= 0;
                            if (out_y == layer_out_h - 1) begin
                                out_y <= 0;
                                if (out_c == layer_out_c - 1)
                                    state <= ST_LAYER_NEXT;
                                else begin
                                    out_c <= out_c + 1;
                                    accumulator <= model_i32(layer_bias_offset + (out_c + 1) * 4);
                                end
                            end else begin
                                out_y <= out_y + 1;
                                accumulator <= model_i32(layer_bias_offset + out_c * 4);
                            end
                        end else begin
                            out_x <= out_x + 1;
                            accumulator <= model_i32(layer_bias_offset + out_c * 4);
                        end
                    end else begin
                        kernel_index <= kernel_index + 1;
                        accumulator <= next_accumulator;
                    end
                end

                ST_RELU: begin
                    if (tensor_index < layer_in_h * layer_in_w * layer_in_c) begin
                        if (tensor_active == 0)
                            tensor_b[tensor_index] <= (tensor_a[tensor_index] < layer_output_zp) ? layer_output_zp : tensor_a[tensor_index];
                        else
                            tensor_a[tensor_index] <= (tensor_b[tensor_index] < layer_output_zp) ? layer_output_zp : tensor_b[tensor_index];
                        tensor_index <= tensor_index + 1;
                    end else begin
                        state <= ST_LAYER_NEXT;
                    end
                end

                ST_POOL: begin
                    pool_c = out_c;
                    pool_oy = out_y; pool_ox = out_x;
                    pool_iy = out_y * layer_sh + (pool_index / layer_kw) - layer_pad_top;
                    pool_ix = out_x * layer_sw + (pool_index % layer_kw) - layer_pad_left;
                    pool_next = pool_value;
                    if (pool_iy >= 0 && pool_iy < layer_in_h && pool_ix >= 0 && pool_ix < layer_in_w) begin
                        if (model_layout_reg == LAYOUT_HWC4)
                            pool_input_index = (pool_iy * layer_in_w + pool_ix) * layer_in_c + pool_c;
                        else
                            pool_input_index = pool_c * layer_in_h * layer_in_w + pool_iy * layer_in_w + pool_ix;
                        if (tensor_read(tensor_active, pool_input_index) > pool_next)
                            pool_next = tensor_read(tensor_active, pool_input_index);
                    end
                    if (pool_index == layer_kh * layer_kw - 1) begin
                        if (model_layout_reg == LAYOUT_HWC4)
                            tensor_index = (out_y * layer_out_w + out_x) * layer_out_c + out_c;
                        else
                            tensor_index = out_c * layer_out_h * layer_out_w + out_y * layer_out_w + out_x;
                        if (tensor_active == 0) tensor_b[tensor_index] <= pool_next;
                        else tensor_a[tensor_index] <= pool_next;
                        pool_index <= 0;
                        pool_value <= -8'sd128;
                        if (out_x == layer_out_w - 1) begin
                            out_x <= 0;
                            if (out_y == layer_out_h - 1) begin
                                out_y <= 0;
                                if (out_c == layer_out_c - 1) state <= ST_LAYER_NEXT;
                                else out_c <= out_c + 1;
                            end else out_y <= out_y + 1;
                        end else out_x <= out_x + 1;
                    end else begin
                        // Keep the running maximum across all elements of
                        // this pooling window.  Without this assignment the
                        // next cycle starts from the previous window value
                        // only through the temporary pool_next, so a 2x2
                        // window can lose an earlier larger element.
                        pool_value <= pool_next;
                        pool_index <= pool_index + 1;
                    end
                end

                ST_GAP: begin
                    if (model_layout_reg == LAYOUT_HWC4)
                        tensor_index = gap_position * layer_in_c + gap_channel;
                    else
                        tensor_index = gap_channel * layer_in_h * layer_in_w + gap_position;
                    next_gap_accumulator = gap_accumulator + tensor_read(tensor_active, tensor_index);
                    gap_accumulator <= next_gap_accumulator;
                    if (gap_position == layer_in_h * layer_in_w - 1) begin
                        tensor_index = gap_channel;
                        if (tensor_active == 0) begin
                            if ((layer_flags & FLAG_GAP_ROUND4) != 0)
                                tensor_b[gap_channel] <= (next_gap_accumulator + 8) >>> 4;
                            else
                                tensor_b[gap_channel] <= next_gap_accumulator / (layer_in_h * layer_in_w);
                        end else begin
                            if ((layer_flags & FLAG_GAP_ROUND4) != 0)
                                tensor_a[gap_channel] <= (next_gap_accumulator + 8) >>> 4;
                            else
                                tensor_a[gap_channel] <= next_gap_accumulator / (layer_in_h * layer_in_w);
                        end
                        gap_position <= 0;
                        gap_accumulator <= 0;
                        if (gap_channel == layer_out_c - 1) state <= ST_LAYER_NEXT;
                        else gap_channel <= gap_channel + 1;
                    end else gap_position <= gap_position + 1;
                end

                ST_FC_MAC: begin
                    fc_input_index = fc_index;
                    fc_weight_index = fc_output * layer_in_c + fc_index;
                    next_accumulator = accumulator +
                        (tensor_read(tensor_active, fc_input_index) - layer_input_zp) *
                        (model_mem[layer_weight_offset + fc_weight_index] - layer_weight_zp);
                    if (fc_index == layer_in_c - 1) begin
                        fc_output_mem[fc_output] <= next_accumulator[31:0];
                        fc_index <= 0;
                        if (fc_output == layer_out_c - 1) state <= ST_LAYER_NEXT;
                        else begin
                            fc_output <= fc_output + 1;
                            accumulator <= model_i32(layer_bias_offset + (fc_output + 1) * 4);
                        end
                    end else begin
                        fc_index <= fc_index + 1;
                        accumulator <= next_accumulator;
                    end
                end

                ST_ARGMAX: begin
                    tensor_index = arg_index;
                    if (argmax_from_fc)
                        candidate_score = fc_output_mem[arg_index];
                    else
                        candidate_score = tensor_read(tensor_active, tensor_index);
                    new_best_score = best_score;
                    new_second_score = second_score;
                    new_best_class = best_class;
                    if (candidate_score > best_score) begin
                        new_second_score = best_score;
                        new_best_score = candidate_score;
                        new_best_class = arg_index;
                    end else if (candidate_score > second_score) begin
                        new_second_score = candidate_score;
                    end
                    if (arg_index == layer_in_c - 1) begin
                        result_class <= new_best_class;
                        result_score <= new_best_score;
                        if (layer_in_c <= 1)
                            final_margin = 0;
                        else if (new_best_score >= new_second_score)
                            final_margin = new_best_score - new_second_score;
                        else
                            final_margin = 0;
                        if (final_margin > 65535)
                            result_confidence <= 16'hffff;
                        else if (final_margin > 0)
                            result_confidence <= final_margin[15:0];
                        else result_confidence <= 0;
                        result_reject <= (final_margin < reject_threshold_reg);
                        // This is the first point at which every descriptor
                        // and referenced parameter range has been exercised.
                        // Keep the complete package in the local BRAM cache
                        // for later ROIs of the same model.
                        model_cache_valid_reg <= 1'b1;
                        model_cache_valid <= 1'b1;
                        busy <= 1'b0;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        best_score <= new_best_score;
                        second_score <= new_second_score;
                        best_class <= new_best_class;
                        arg_index <= arg_index + 1;
                    end
                end

                ST_LAYER_NEXT: begin
                    tensor_active <= ~tensor_active;
                    expected_in_h <= layer_out_h;
                    expected_in_w <= layer_out_w;
                    expected_in_c <= layer_out_c;
                    argmax_from_fc <= (layer_op == OP_FC);
                    layer_index <= layer_index + 1;
                    state <= ST_LAYER_FETCH;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
