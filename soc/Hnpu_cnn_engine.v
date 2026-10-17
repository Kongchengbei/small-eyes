`timescale 1ns / 1ps

/*
 * Candidate CNN execution engine for the A-side V1 contract.
 *
 * The engine deliberately keeps model bytes and intermediate tensors in
 * bounded local arrays.  It has one AXI read transaction in flight, checks
 * the model package before reading the input tensor, and executes one output
 * element per cycle (one MAC contribution per cycle).  This is a correctness
 * implementation for simulation and resource review, not a throughput claim.
 *
 * Pipelined for timing (ddr_core_clk, 125 MHz).  result, error and
 * error_code are bit-exact with the single-cycle version of this file in
 * commit 5bcce4d ("the single-cycle version" below), and total cycle counts
 * are about 0.005% higher.
 *  - MAC: four stages mac1..mac4, still one MAC per cycle; the 64-bit
 *    accumulator is split into acc_lo and acc_hi.
 *  - Requantization is done by Hnpu_requant_pipe (6 cycles, fully
 *    pipelined) and the GAP division by Hnpu_gap_unit (11 cycles,
 *    start/busy/done).  Both are at the end of this file, which holds three
 *    modules.
 *  - Read addresses are registered and incremental.  Per-layer constants and
 *    the START, VALIDATE and DISPATCH checks come from free-running
 *    pipelines, and the FSM waits for them in added states (codes 29..50;
 *    the next free code is 51, state is 6 bits).
 *  - Port timing: a start with a bad configuration raises busy for 3 cycles
 *    and reports ERR_BAD_CONFIG with done_pulse in ST_START_CHECK (the
 *    single-cycle version did this in ST_IDLE without raising busy).  A start
 *    in those cycles is ignored, a clear_error in them comes before the error
 *    is set and does not clear it, and the rejected start still overwrites
 *    the *_reg argument registers.  model_cache_hit pulses 3 cycles later.
 *    The SoC services start the engine only while their own active flag is
 *    set and take the result at done_pulse; they use busy only while active
 *    is clear or OR-ed with active, and leave model_cache_hit unconnected,
 *    so neither difference shows there.
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
    // Model residency observability.  model_cache_hit is a one-cycle pulse
    // for an accepted start that hits the model cache (set in
    // ST_START_CHECK); the counters are monotonic until reset.
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
    localparam [31:0] MAX_SCRATCH_BYTES = 2 * MAX_TENSOR_BYTES;
    localparam [15:0] DRAIN_TIMEOUT_LIMIT = (R_DRAIN_TIMEOUT > 0) ?
                                             (R_DRAIN_TIMEOUT - 1) : 0;

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
    localparam [5:0] ST_READ_UNPACK = 6'd15;
    localparam [5:0] ST_LEGACY_SCAN = 6'd16;
    localparam [5:0] ST_LEGACY_DONE = 6'd17;
    localparam [5:0] ST_BIAS_FETCH = 6'd18;
    localparam [5:0] ST_CRC_PRIME = 6'd19;
    localparam [5:0] ST_BIAS_PRIME = 6'd20;
    localparam [5:0] ST_WEIGHT_PRIME = 6'd21;
    localparam [5:0] ST_RELU_PRIME = 6'd22;
    localparam [5:0] ST_POOL_PRIME = 6'd23;
    localparam [5:0] ST_GAP_PRIME = 6'd24;
    localparam [5:0] ST_ARGMAX_PRIME = 6'd25;
    localparam [5:0] ST_WRITE_DRAIN = 6'd26;
    localparam [5:0] ST_DESC_PRIME = 6'd27;
    localparam [5:0] ST_DESC_READ = 6'd28;
    // Per-layer setup after DISPATCH (constant pipeline fill, then the
    // address generators are loaded in ST_SU3).
    localparam [5:0] ST_SU0 = 6'd29;
    localparam [5:0] ST_SU1 = 6'd30;
    localparam [5:0] ST_SU2 = 6'd31;
    localparam [5:0] ST_SU3 = 6'd32;
    // ST_VALIDATE waits VAL1..VAL4 for the header check pipeline (the
    // decision is taken in ST_VAL4); every ST_LEGACY_SCAN waits LS1..LS4
    // for the scratch estimate (taken in ST_LS4).
    localparam [5:0] ST_VAL1 = 6'd33;
    localparam [5:0] ST_VAL2 = 6'd34;
    localparam [5:0] ST_VAL3 = 6'd35;
    localparam [5:0] ST_VAL4 = 6'd36;
    localparam [5:0] ST_LS1 = 6'd37;
    localparam [5:0] ST_LS2 = 6'd38;
    localparam [5:0] ST_LS3 = 6'd39;
    localparam [5:0] ST_LS4 = 6'd40;
    // A taken start waits START_SUM/START_CMP for the config checks
    // (decision in ST_START_CHECK); every new AXI burst goes through
    // READ_CALC/READ_BURST (burst_beats loaded in ST_READ_BURST); the final
    // CRC compare is taken in ST_CRC_FIN/ST_CRC_CHECK.
    localparam [5:0] ST_START_SUM = 6'd41;
    localparam [5:0] ST_START_CMP = 6'd42;
    localparam [5:0] ST_START_CHECK = 6'd43;
    localparam [5:0] ST_READ_CALC = 6'd44;
    localparam [5:0] ST_READ_BURST = 6'd45;
    localparam [5:0] ST_CRC_FIN = 6'd46;
    localparam [5:0] ST_CRC_CHECK = 6'd47;
    // ARGMAX finish.  ST_ARG_F1: the last candidate is folded into
    // best/second; ST_ARG_F2: margin subtract; ST_ARG_F3: results, done.
    localparam [5:0] ST_ARG_F1 = 6'd48;
    localparam [5:0] ST_ARG_F2 = 6'd49;
    localparam [5:0] ST_ARG_F3 = 6'd50;

    reg [5:0] state;
    (* ram_style = "block" *) reg signed [7:0] model_mem [0:MAX_MODEL_BYTES-1];
    // Only the fixed-size header is read in parallel. Descriptors are read
    // serially from model_mem into a 64-byte shift register. Parallel dynamic
    // indexing of all descriptors made PDS replicate a 2 KiB metadata RAM
    // dozens of times and created a large routing hotspot.
    reg signed [7:0] model_header_mem [0:HEADER_BYTES-1];
    reg [DESC_BYTES*8-1:0] descriptor_bits;
    reg [5:0] descriptor_read_index;
    reg descriptor_scan_legacy;
    reg [15:0] model_read_addr;
    reg signed [7:0] model_read_data;
    (* ram_style = "block" *) reg signed [7:0] tensor_a [0:MAX_TENSOR_BYTES-1];
    (* ram_style = "block" *) reg signed [7:0] tensor_b [0:MAX_TENSOR_BYTES-1];
    reg [15:0] tensor_read_addr;
    reg signed [7:0] tensor_a_read_data, tensor_b_read_data;
    wire signed [7:0] tensor_read_data = tensor_active ? tensor_b_read_data : tensor_a_read_data;
    reg tensor_write_enable, tensor_write_slot;
    reg [15:0] tensor_write_addr;
    reg signed [7:0] tensor_write_data;

    reg [31:0] read_addr_reg;
    reg [31:0] read_remaining_beats;
    reg [31:0] read_offset;
    reg [4:0] burst_beats;
    reg [4:0] read_beat_index;
    reg [255:0] read_beat_data;
    reg read_beat_last;
    reg [4:0] unpack_lane;
    reg read_target_input;
    reg read_error_seen;
    reg [7:0] read_error_code;
    reg [15:0] drain_wait_count;
    // dw_hit == (drain_wait_count >= DRAIN_TIMEOUT_LIMIT), kept with the
    // counter: 0 gives DW_HIT0; the counter only counts up while it
    // is below the limit, so count + 1 reaches it exactly at limit - 1.
    // Every assignment to drain_wait_count has a matching assignment to
    // dw_hit in the same branch; keep them paired.
    reg dw_hit;
    localparam DW_HIT0 = (DRAIN_TIMEOUT_LIMIT == 16'd0);

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
    reg [1:0] bias_lane;
    reg [23:0] bias_low_bytes;
    reg [4:0] legacy_scan_index;
    reg legacy_duplicate_flags_seen;
    reg legacy_tail_valid;
    reg legacy_flags_consistent;
    reg [31:0] legacy_expected_scratch;
    reg legacy_model_encoding_valid;

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
    reg [7:0] layer_shift;
    reg signed [7:0] layer_input_zp, layer_weight_zp, layer_output_zp;

    integer out_x, out_y, out_c;
    integer kernel_index;
    integer pool_index;
    integer tensor_index;
    // RELU: ST_RELU registers the element (rl_x, address rl_addr, valid
    // rl_v); it is clamped and written in the next cycle (after the state
    // case).  RELU ends through ST_WRITE_DRAIN.
    reg rl_v;
    reg signed [7:0] rl_x;
    reg [15:0] rl_addr;
    integer fc_index, fc_output;
    integer arg_index;
    reg signed [7:0] pool_value;
    // POOL: ST_POOL registers the element (pp_x, in-bounds flag pp_in,
    // window end pp_last, output index pp_widx, valid pp_v); the next cycle
    // updates the running maximum / writes it (after the state case).
    reg pp_v, pp_in, pp_last;
    reg signed [7:0] pp_x;
    reg [15:0] pp_widx;
    reg signed [63:0] gap_accumulator;
    reg signed [63:0] next_gap_accumulator;
    reg signed [31:0] best_score, second_score;
    reg [7:0] best_class;

    integer gap_channel, gap_position;
    integer source_offset;
    reg [6:0] downsample_source_x;
    reg [1:0] downsample_channel;
    reg [1:0] downsample_phase_x;
    reg [1:0] downsample_phase_y;
    reg [12:0] downsample_dest_index;
    integer tensor_write_index;
    reg input_store_valid;
    // Input tensor byte of ST_READ_UNPACK (valid iw_v, address iw_addr,
    // data iw_data), written in the next cycle after the state case.
    reg iw_v;
    reg [15:0] iw_addr;
    reg signed [7:0] iw_data;
    reg signed [7:0] pool_next;
    // ARGMAX: ST_ARGMAX registers the candidate (am_cand, its class
    // am_cls, valid am_v); the next cycle folds it into best/second (after
    // the state case).  ST_ARG_F2 takes am_diff = best - second (33 bits)
    // and am_c1 = (in_c <= 1); am_margin is a temporary of ST_ARG_F3.
    reg am_v, am_c1;
    reg signed [31:0] am_cand;
    reg [7:0] am_cls;
    reg [32:0] am_diff, am_margin;

    // ------------------------------------------------------------------
    // MAC pipeline (CONV and FC).  mac1 is loaded by the CONV_MAC/FC_MAC
    // states with the RAM data of one kernel element; the 64-bit
    // accumulator is kept as acc_lo (updated in the mac3->mac4 step) and
    // acc_hi (updated one cycle later from the registered carry/sign).
    // first = element 0 of an output (accumulator starts from the bias),
    // last = final element (CONV: hand the sum to requant, FC: write
    // fc_output_mem).  idx = CONV tensor write address / FC output index.
    // ------------------------------------------------------------------
    reg mac1_v, mac1_en, mac1_first, mac1_last, mac1_fc;
    reg signed [7:0] mac1_x, mac1_w;
    reg [15:0] mac1_idx;
    reg mac2_v, mac2_en, mac2_first, mac2_last, mac2_fc;
    reg signed [8:0] mac2_dx, mac2_dw;
    reg [15:0] mac2_idx;
    reg mac3_v, mac3_first, mac3_last, mac3_fc;
    reg signed [17:0] mac3_prod;
    reg [15:0] mac3_idx;
    reg mac4_v, mac4_first, mac4_last, mac4_fc, mac4_c, mac4_s, mac4_bsign;
    reg [15:0] mac4_idx;
    reg [31:0] bias_reg;
    reg [31:0] acc_lo, acc_hi;
    reg [32:0] mac_lo_sum;
    reg [31:0] mac_hi_sum;

    // Requant (CONV only): Hnpu_requant_pipe at the end of this file,
    // bit-exact with requantize() below, 6-cycle latency, one result per
    // cycle.  It looks at layer_shift[4:0] only; DISPATCH rejects
    // layer_shift > 31.
    wire rq_out_valid, rq_busy;
    wire [15:0] rq_out_tag;
    wire signed [7:0] rq_out_q;
    // GAP output: Hnpu_gap_unit at the end of this file, one channel at a
    // time.  A finished channel sum waits in gap_sum (gap_pend) until the
    // unit is idle; gap_tag is the channel the unit is working on.
    reg gap_pend;
    reg signed [63:0] gap_sum;
    reg [15:0] gap_wch, gap_tag;
    wire gap_done, gap_busy;
    wire signed [7:0] gap_q;
    wire gap_start = gap_pend && !gap_busy;
    // Anything still on its way to the tensor RAM (WRITE_DRAIN waits for
    // it).  The input-load writes (iw_v) are not included: a layer reads the
    // tensor no earlier than about 60 cycles after the last input byte.
    wire mac_pipe_busy = mac1_v || mac2_v || mac3_v || mac4_v || rq_busy ||
                         gap_pend || gap_busy || pp_v || rl_v;

    function [15:0] model_u16;
        input integer offset;
        begin
            model_u16 = {model_header_mem[offset+1], model_header_mem[offset]};
        end
    endfunction

    function [31:0] model_u32;
        input integer offset;
        begin
            model_u32 = {model_header_mem[offset+3], model_header_mem[offset+2],
                        model_header_mem[offset+1], model_header_mem[offset]};
        end
    endfunction

    function signed [31:0] model_i32;
        input integer offset;
        begin
            model_i32 = {model_header_mem[offset+3], model_header_mem[offset+2],
                         model_header_mem[offset+1], model_header_mem[offset]};
        end
    endfunction

    function [15:0] desc_u16;
        input integer offset;
        begin
            desc_u16 = descriptor_bits[offset*8 +: 16];
        end
    endfunction

    function [31:0] desc_u32;
        input integer offset;
        begin
            desc_u32 = descriptor_bits[offset*8 +: 32];
        end
    endfunction

    function signed [31:0] desc_i32;
        input integer offset;
        begin
            desc_i32 = descriptor_bits[offset*8 +: 32];
        end
    endfunction

    function signed [63:0] sign_extend_i8;
        input signed [7:0] value;
        begin
            sign_extend_i8 = {{56{value[7]}}, value};
        end
    endfunction

    // clamp_i8 and requantize are reference models only; the datapath does
    // not call them.  Hnpu_requant_pipe must stay bit-exact with
    // requantize(), and Hnpu_gap_unit with clamp_i8() of the GAP result
    // (rounded shift or quotient, see its header).
    function signed [7:0] clamp_i8;
        input signed [63:0] value;
        begin
            if (value > 64'sd127)
                clamp_i8 = 8'sd127;
            else if (value < -64'sd128)
                clamp_i8 = -8'sd128;
            else
                clamp_i8 = value[7:0];
        end
    endfunction

    function signed [7:0] requantize;
        input signed [63:0] value;
        input signed [31:0] multiplier;
        input [7:0] shift;
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
            result_value = scaled + sign_extend_i8(zero_point);
            if (relu_enable && result_value < sign_extend_i8(zero_point))
                result_value = sign_extend_i8(zero_point);
            if (result_value > 96'sd127)
                requantize = 8'sd127;
            else if (result_value < -96'sd128)
                requantize = -8'sd128;
            else
                requantize = result_value[7:0];
        end
    endfunction

    function header_reserved_zero;
        // PDS parses this .v file as Verilog and requires a function input.
        input unused;
        integer reserved_index;
        begin
            header_reserved_zero = 1'b1;
            for (reserved_index = 80; reserved_index < HEADER_BYTES; reserved_index = reserved_index + 1)
                if (model_header_mem[reserved_index] != 0)
                    header_reserved_zero = 1'b0;
        end
    endfunction

    function descriptor_reserved_compatible;
        input unused;
        integer reserved_index;
        begin
            descriptor_reserved_compatible = 1'b1;
            if (descriptor_bits[56*8 +: 8] != 0) begin
                descriptor_reserved_compatible =
                    (descriptor_bits[56*8 +: 8] == descriptor_bits[1*8 +: 8]);
            end
            for (reserved_index = 57; reserved_index < DESC_BYTES; reserved_index = reserved_index + 1)
                if (descriptor_bits[reserved_index*8 +: 8] != 0)
                    descriptor_reserved_compatible = 1'b0;
        end
    endfunction

    function [4:0] burst_cap;
        input [31:0] remaining;
        reg [4:0] c16;
        begin
            // min(remaining, 16): remaining > 16 is bit 5 and up, or 17..31
            c16 = ((|remaining[31:5]) || (remaining[4] && (|remaining[3:0]))) ?
                  5'd16 : remaining[4:0];
            burst_cap = (c16 > MAX_BURST_BEATS) ? MAX_BURST_BEATS : c16;
        end
    endfunction

    function [31:0] crc32_byte;
        input [31:0] crc;
        input [7:0] data;
        reg [31:0] c;
        integer bit_index;
        begin
            c = crc ^ {24'b0, data};
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                c = c[0] ? ((c >> 1) ^ 32'hedb8_8320) : (c >> 1);
            crc32_byte = c;
        end
    endfunction

    wire [63:0] ddr_end = {32'b0, DDR_BASE} + {32'b0, DDR_BYTES};
    wire [32:0] header_desc_end = {1'b0, model_u32(24)} + {1'b0, model_u32(28)};
    wire [32:0] header_weight_end = {1'b0, model_u32(32)} + {1'b0, model_u32(36)};
    wire [32:0] header_bias_end = {1'b0, model_u32(40)} + {1'b0, model_u32(44)};

    wire [31:0] read_local_addr = read_addr_reg - DDR_BASE;
    assign axi_araddr = read_local_addr[29:0];
    assign axi_arid = AXI_ID;
    assign axi_arlen = {3'b0, burst_beats} - 8'd1;
    assign axi_arsize = 3'b101;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = (state == ST_READ_AR);
    assign axi_rready = (state == ST_READ_R) || (state == ST_READ_DRAIN);

    // ------------------------------------------------------------------
    // Registered, incremental read addresses.
    //
    // model_read_addr / tensor_read_addr are registers loaded one cycle
    // ahead: in every state whose RAM read is consumed by the next state,
    // the register already holds the address (mod 2^16) of that read.
    // Computing the addresses combinationally would put divides, modulos
    // and multiplies in front of the RAMs; here only additions of per-layer
    // constants are used.  The constants come from a free-running pipeline
    // over the layer registers (4 stages); ST_SU0..ST_SU3 wait for it after
    // DISPATCH and ST_SU3 loads the generators for the layer.
    //
    // When changing the FSM: an added wait cycle must hold model_read_addr
    // and tensor_read_addr and keep g_load/g_step at 0.  The g_load/g_step
    // and tra_* always @* blocks below follow the state transition
    // conditions and must be changed together with them (the GAP stall
    // !(gap_pend && gap_busy) appears both in tra_we and in ST_GAP_PRIME).
    // ------------------------------------------------------------------
    reg [5:0] su_next;                  // op state entered after ST_SU3
    reg ls_last;                        // ST_LS4 -> ST_LEGACY_DONE (else ST_DESC_PRIME)
    reg crc_go;                         // crc_d is a CRC byte: fold it into crc_reg
    reg crc_ne;                         // final CRC mismatch (ST_CRC_FIN -> ST_CRC_CHECK)
    reg model_wr_en, model_wr_hdr;      // registered model RAM write port
    reg [15:0] model_wr_addr;
    reg [7:0] model_wr_data;
    reg [15:0] w_base, b_base;          // weight / bias address of the current output channel
    // Kernel / pooling-window element generator: input coordinates of the
    // element whose address is in tensor_read_addr (cw_ix: window column 0).
    reg signed [19:0] g_iy, g_ix, cw_ix;
    reg [15:0] g_ic;
    reg [7:0] g_kx;
    reg g_ic_last, g_kx_last;
    reg c_inb;                          // the element consumed this cycle is inside the input
    // Current output pixel / pooling window: input coordinates and linear
    // address of its element 0, address of its row start and channel start,
    // and its output write index.  nx_* holds the same for the next pixel.
    reg signed [19:0] px_iy, px_ix, nx_iy, nx_ix;
    reg [15:0] px_lin, rw_lin, ch_lin, widx;
    reg [15:0] nx_lin, nx_rw, nx_ch, nx_widx;
    // Per-layer constants: a_* stage 1, b_* stage 2, c_* stage 3; k_* are
    // the values used by the FSM and generators (valid from ST_SU3 on).
    // a_khkw = kh*kw, a_hw = in_h*in_w, a_ptw = pad_top*in_w,
    // a_shw = sh*in_w, a_swc = sw*in_c, a_wmk = in_w - kw,
    // a_wmk1 = in_w - kw + 1, a_hwc4 = HWC4 layout (also used directly by
    // the tra_* block), b_K = kh*kw*in_c, b_rn_lo/b_rn_hi = a_hw[15:0]*in_c
    // and a_hw[31:16]*in_c, b_cm1hw = (in_c - 1)*a_hw[15:0],
    // k_dic/k_dkx/k_dky = address step to the next channel, next kernel
    // column and next kernel row.
    reg a_conv, a_hwc4;
    reg [15:0] a_khkw, a_ptw, a_shw, a_swc, a_wmk, a_wmk1;
    reg [31:0] a_hw;
    reg [31:0] b_K, b_rn_lo;
    reg [15:0] b_rn_hi, b_cm1hw, b_wmkc, b_wmk1c, b_ptwpl, b_shwc, b_hw16;
    reg [15:0] c_inith, c_ptwpl;
    reg [15:0] k_icm1, k_owm1, k_ohm1, k_ocm1, k_pwm1, k_gcm1, k_gcm2;
    reg [7:0] k_kwm2;
    reg k_kw1, k_c1;
    reg [31:0] k_km1, k_hwm1, k_relu_n;
    reg [15:0] k_K16, k_wstep, k_gstep, k_xstep, k_ystep, k_chstep;
    reg [15:0] k_dic, k_dkx, k_dky, k_init_lin;
    reg k_fc, k_mp, k_pw0, k_hw0;
    reg [31:0] k_pwm2, k_hwm2;
    reg signed [19:0] k_init_ix, k_init_iy;

    wire conv_last = (kernel_index == k_km1);
    wire conv_oc_wrap = (out_x == k_owm1) && (out_y == k_ohm1);
    // pool_index == k_pwm1 and gap_position == k_hwm1, kept as registers by
    // the FSM: set in ST_POOL_PRIME / ST_GAP_PRIME, where the index is
    // 0, and advanced with the index in ST_POOL / ST_GAP.  Only read there.
    reg pool_last;
    reg gp_last;
    wire fc_last = (fc_index == k_icm1);
    wire [7:0] desc_idx_now = descriptor_scan_legacy ? {3'b0, legacy_scan_index} : layer_index;
    wire g_inb = !g_iy[19] && !g_ix[19] &&
                 (g_iy[18:0] < {3'b0, layer_in_h}) && (g_ix[18:0] < {3'b0, layer_in_w});
    // Address step from the current element to the next one: next input
    // channel, next kernel column, or next kernel row.
    wire [15:0] g_delta = !g_ic_last ? k_dic : (!g_kx_last ? k_dkx : k_dky);

    // Per-layer constant pipeline.  The layer registers only change in
    // ST_LAYER_FETCH (and model_layout_reg in ST_VAL4), so stage 4 is
    // valid from ST_SU3 of the same layer on.
    always @(posedge clk) begin
        // stage 1
        a_conv <= (layer_op == OP_CONV2D);
        a_hwc4 <= (model_layout_reg == LAYOUT_HWC4);
        a_khkw <= layer_kh * layer_kw;
        a_hw <= layer_in_h * layer_in_w;
        a_ptw <= layer_pad_top * layer_in_w;
        a_shw <= layer_sh * layer_in_w;
        a_swc <= layer_sw * layer_in_c;
        a_wmk <= layer_in_w - layer_kw;
        a_wmk1 <= layer_in_w - layer_kw + 16'd1;
        k_icm1 <= layer_in_c - 16'd1;
        k_owm1 <= layer_out_w - 16'd1;
        k_ohm1 <= layer_out_h - 16'd1;
        k_ocm1 <= layer_out_c - 16'd1;
        k_kwm2 <= layer_kw - 8'd2;
        k_kw1 <= (layer_kw == 8'd1);
        k_init_iy <= 20'd0 - {12'd0, layer_pad_top};
        k_init_ix <= 20'd0 - {12'd0, layer_pad_left};
        k_wstep <= (model_layout_reg == LAYOUT_HWC4) ? layer_out_c : 16'd1;
        k_gstep <= (model_layout_reg == LAYOUT_HWC4) ? layer_in_c : 16'd1;
        // stage 2
        b_K <= a_khkw * layer_in_c;
        k_pwm1 <= a_khkw - 16'd1;
        k_hwm1 <= a_hw - 32'd1;
        b_rn_lo <= a_hw[15:0] * layer_in_c;
        b_rn_hi <= a_hw[31:16] * layer_in_c;
        b_cm1hw <= k_icm1 * a_hw[15:0];
        b_wmkc <= a_wmk * layer_in_c;
        b_wmk1c <= a_wmk1 * layer_in_c;
        b_ptwpl <= a_ptw + layer_pad_left;
        b_shwc <= a_shw * layer_in_c;
        k_xstep <= a_hwc4 ? a_swc : {8'd0, layer_sw};
        k_gcm1 <= a_conv ? k_icm1 : 16'd0;
        b_hw16 <= a_hw[15:0];
        // stage 3
        k_km1 <= b_K - 32'd1;
        k_K16 <= b_K[15:0];
        k_relu_n <= {b_rn_lo[31:16] + b_rn_hi, b_rn_lo[15:0]};
        k_gcm2 <= k_gcm1 - 16'd1;
        k_c1 <= (k_gcm1 == 16'd0);
        c_inith <= b_ptwpl * layer_in_c;
        c_ptwpl <= b_ptwpl;
        k_dic <= a_hwc4 ? 16'd1 : b_hw16;
        k_dkx <= a_conv ? (a_hwc4 ? 16'd1 : 16'd1 - b_cm1hw) :
                          (a_hwc4 ? layer_in_c : 16'd1);
        k_dky <= a_conv ? (a_hwc4 ? b_wmkc + 16'd1 : a_wmk1 - b_cm1hw) :
                          (a_hwc4 ? b_wmk1c : a_wmk1);
        k_ystep <= a_hwc4 ? b_shwc : a_shw;
        k_chstep <= a_conv ? 16'd0 : (a_hwc4 ? 16'd1 : b_hw16);
        // stage 4: linear address of input (-pad_top, -pad_left), channel 0
        k_init_lin <= a_hwc4 ? 16'd0 - c_inith : 16'd0 - c_ptwpl;
        // FC / maxpool flags for the address block
        k_fc <= (layer_op == OP_FC);
        k_mp <= (layer_op == OP_MAXPOOL);
        // pool / GAP end flags.  k_pw0 / k_hw0: the window / channel has a
        // single element, so index 0 is already the last one.  Otherwise
        // ST_POOL / ST_GAP set pool_last / gp_last when pool_index /
        // gap_position equals k_pwm2 / k_hwm2, i.e. when index + 1 is the
        // last one.  k_pwm2 / k_hwm2 are 32 bits wide, like the integer
        // indexes they are compared with.
        k_pw0 <= (k_pwm1 == 16'd0);
        k_pwm2 <= {16'd0, k_pwm1} - 32'd1;
        k_hw0 <= (k_hwm1 == 32'd0);
        k_hwm2 <= k_hwm1 - 32'd1;
    end

    // DISPATCH checks, pipelined the same way: free-running over the layer
    // registers (stable from ST_DISPATCH on), dc1_* valid in ST_SU0, dc2_*
    // in ST_SU1, dc3_* in ST_SU2.  d_opbad / d_fail are the DISPATCH error
    // decisions (ERR_UNSUPPORTED_OP, then ERR_MODEL_SHAPE), valid in ST_SU3,
    // where they are taken.  The shape and size products are 32 bits, mod
    // 2^32 (built from split products), like the integer products of the
    // single-cycle version, so a malformed package whose products overflow
    // 32 bits is accepted or rejected exactly as there.
    // The window shape check out == (in + pads - k) / s + 1 (32-bit
    // unsigned) is done as
    // (out - 1) * s <= v < out * s with v = in + pads - k, which is the same
    // for s != 0 and out != 0.  v < 0 always fails (the wrapped quotient + 1
    // is 0 or > 65535), and s == 0 or out == 0 fail through other terms with
    // the same error code.
    // Besides the layer registers, dc1..dc3 read descriptor_bits,
    // expected_in_*, header fields (model_u32(32/40/52), header_weight_end,
    // header_bias_end, legacy_model_encoding_valid) and model_bytes_reg;
    // these must not change between ST_DISPATCH and ST_SU3.  dc2_cwlo /
    // dc2_cwhi use a_khkw from stage 1 of the constant pipeline; both
    // pipelines run over the layer registers from ST_DISPATCH on, so a stage
    // added to one must be added to the other.
    reg dc1_opbad, dc1_conv, dc1_pool, dc1_gap, dc1_fc;
    reg dc1_dims, dc1_desc, dc1_offs, dc1_wnz, dc1_bnz, dc1_wlo, dc1_blo;
    reg dc1_ksz0, dc1_bbsm, dc1_ocne, dc1_gapf, dc1_fc1;
    reg [32:0] dc1_wsum, dc1_bsum, dc1_wend, dc1_bend;
    reg [31:0] dc1_ohw, dc1_ocic;
    reg [18:0] dc1_ihk_h, dc1_ihk_w;    // in - k, two's complement
    reg [8:0] dc1_pp_h, dc1_pp_w;       // CONV pads (0 for MAXPOOL)
    reg [23:0] dc1_phi_h, dc1_phi_w;    // out * s
    reg dc2_opbad, dc2_conv, dc2_cp, dc2_cmn, dc2_wover, dc2_bover, dc2_opf;
    reg [31:0] dc2_cwlo, dc2_olo;
    reg [15:0] dc2_cwhi, dc2_ohi;
    reg [18:0] dc2_vh, dc2_vw;
    reg [23:0] dc2_phi_h, dc2_phi_w, dc2_phm_h, dc2_phm_w;
    reg dc3_opbad, dc3_conv, dc3_pre;
    reg [31:0] dc3_cw, dc3_oel;         // out_c*kh*kw*in_c, out_h*out_w*out_c (mod 2^32)
    reg d_opbad, d_fail;

    always @(posedge clk) begin
        // stage 1
        dc1_opbad <= layer_op != OP_CONV2D && layer_op != OP_RELU &&
                     layer_op != OP_MAXPOOL && layer_op != OP_GAP &&
                     layer_op != OP_FC && layer_op != OP_ARGMAX;
        dc1_conv <= (layer_op == OP_CONV2D);
        dc1_pool <= (layer_op == OP_MAXPOOL);
        dc1_gap <= (layer_op == OP_GAP);
        dc1_fc <= (layer_op == OP_FC);
        dc1_dims <= layer_in_h == 0 || layer_in_w == 0 || layer_in_c == 0 ||
                    layer_out_h == 0 || layer_out_w == 0 || layer_out_c == 0 ||
                    layer_in_h != expected_in_h || layer_in_w != expected_in_w ||
                    layer_in_c != expected_in_c;
        dc1_desc <= desc_u32(24) != 0 || desc_u32(28) != 0 ||
                    !descriptor_reserved_compatible(1'b0) || layer_shift > 31;
        dc1_offs <= (layer_weight_bytes != 0 && layer_weight_offset[4:0] != 0) ||
                    (layer_bias_bytes != 0 && layer_bias_offset[4:0] != 0) ||
                    (layer_weight_bytes == 0 && layer_weight_offset != 0) ||
                    (layer_bias_bytes == 0 && layer_bias_offset != 0);
        dc1_wnz <= (layer_weight_bytes != 0);
        dc1_bnz <= (layer_bias_bytes != 0);
        dc1_wlo <= (layer_weight_offset < model_u32(32));
        dc1_blo <= (layer_bias_offset < model_u32(40));
        dc1_wsum <= {1'b0, layer_weight_offset} + {1'b0, layer_weight_bytes};
        dc1_bsum <= {1'b0, layer_bias_offset} + {1'b0, layer_bias_bytes};
        dc1_wend <= header_weight_end;
        dc1_bend <= header_bias_end;
        dc1_ohw <= layer_out_h * layer_out_w;
        dc1_ocic <= layer_out_c * layer_in_c;
        dc1_ksz0 <= layer_kh == 0 || layer_kw == 0 || layer_sh == 0 || layer_sw == 0;
        dc1_bbsm <= (layer_bias_bytes < {14'd0, layer_out_c, 2'b00});
        dc1_ocne <= (layer_out_c != layer_in_c);
        dc1_gapf <= ((layer_flags & FLAG_GAP_ROUND4) != 0) &&
                    (layer_in_h != 4 || layer_in_w != 4) ||
                    layer_out_h != 1 || layer_out_w != 1 || layer_out_c != layer_in_c;
        dc1_fc1 <= (layer_in_h != 1 || layer_in_w != 1);
        dc1_ihk_h <= {3'd0, layer_in_h} - {11'd0, layer_kh};
        dc1_ihk_w <= {3'd0, layer_in_w} - {11'd0, layer_kw};
        dc1_pp_h <= (layer_op == OP_CONV2D) ? {1'b0, layer_pad_top} + {1'b0, layer_pad_bottom} : 9'd0;
        dc1_pp_w <= (layer_op == OP_CONV2D) ? {1'b0, layer_pad_left} + {1'b0, layer_pad_right} : 9'd0;
        dc1_phi_h <= layer_out_h * layer_sh;
        dc1_phi_w <= layer_out_w * layer_sw;
        // stage 2
        dc2_opbad <= dc1_opbad;
        dc2_conv <= dc1_conv;
        dc2_cp <= dc1_conv || dc1_pool;
        dc2_cmn <= dc1_dims || dc1_desc || dc1_offs;
        dc2_wover <= (dc1_wnz && (dc1_wlo || dc1_wsum > dc1_wend)) ||
                     dc1_wsum > {1'b0, model_bytes_reg};
        dc2_bover <= (dc1_bnz && (dc1_blo || dc1_bsum > dc1_bend)) ||
                     dc1_bsum > {1'b0, model_bytes_reg};
        // per-op checks except the CONV weight size and the window shape
        dc2_opf <= (dc1_conv && (dc1_ksz0 || dc1_bbsm)) ||
                   (dc1_pool && (dc1_ksz0 || dc1_ocne)) ||
                   (dc1_gap && dc1_gapf) ||
                   (dc1_fc && (dc1_fc1 || dc1_bbsm || layer_weight_bytes < dc1_ocic));
        dc2_cwlo <= dc1_ocic[15:0] * a_khkw;
        dc2_cwhi <= dc1_ocic[31:16] * a_khkw;
        dc2_olo <= dc1_ohw[15:0] * layer_out_c;
        dc2_ohi <= dc1_ohw[31:16] * layer_out_c;
        dc2_vh <= dc1_ihk_h + {10'd0, dc1_pp_h};
        dc2_vw <= dc1_ihk_w + {10'd0, dc1_pp_w};
        dc2_phi_h <= dc1_phi_h;
        dc2_phi_w <= dc1_phi_w;
        dc2_phm_h <= dc1_phi_h - {16'd0, layer_sh};
        dc2_phm_w <= dc1_phi_w - {16'd0, layer_sw};
        // stage 3
        dc3_opbad <= dc2_opbad;
        dc3_conv <= dc2_conv;
        dc3_cw <= {dc2_cwlo[31:16] + dc2_cwhi, dc2_cwlo[15:0]};
        dc3_oel <= {dc2_olo[31:16] + dc2_ohi, dc2_olo[15:0]};
        dc3_pre <= dc2_cmn || dc2_wover || dc2_bover || dc2_opf ||
                   (dc2_cp && (dc2_vh[18] || dc2_vw[18] ||
                               {5'd0, dc2_vh} >= dc2_phi_h || {5'd0, dc2_vh} < dc2_phm_h ||
                               {5'd0, dc2_vw} >= dc2_phi_w || {5'd0, dc2_vw} < dc2_phm_w));
        // stage 4 (k_relu_n = in_h*in_w*in_c mod 2^32, valid from ST_SU2)
        d_opbad <= dc3_opbad;
        d_fail <= dc3_pre ||
                  $signed(k_relu_n) > MAX_TENSOR_BYTES ||
                  $signed(dc3_oel) > MAX_TENSOR_BYTES ||
                  // model_u32(52) (scratch_bytes) covers the two intermediate
                  // tensor banks; the initial input has its own input_bytes
                  // contract and is not counted again here.
                  (!legacy_model_encoding_valid && model_u32(52) < {dc3_oel[30:0], 1'b0}) ||
                  (dc3_conv && layer_weight_bytes < dc3_cw);
    end

    // VALIDATE checks, free-running.  The header is written only while a
    // model is read; it is final two cycles before ST_VALIDATE at the latest
    // (128-byte model: last write lands in the first ST_CRC_PRIME cycle), and
    // model_bytes_reg/input_bytes_reg are fixed since ST_IDLE, so the stage-5
    // result is valid in ST_VAL4.  The header conditions are split only at
    // '||' (every '||' operand is self-determined, so widths and signedness
    // are kept).  Element count:
    // {v3_eh, v3_el} = u16(12) * u16(14) * u16(16), exact (< 2^48).
    reg v1_magic, v1_ver, v1_fa, v1_fb, v1_fr, v1_fc, v1_fd, v1_fe, v1_fl, v1_fm;
    reg [32:0] v1_de, v1_we, v1_be;
    reg [31:0] v1_hw;
    reg [15:0] v1_c;
    reg v2_fmt;
    reg [31:0] v2_pl, v2_ph;
    reg [31:0] v3_eh;
    reg [15:0] v3_el;
    reg v4_shape;
    reg v5_err;
    reg [7:0] v5_code;
    always @(posedge clk) begin
        // stage 1
        v1_magic <= model_u32(0) != MAGIC;
        v1_ver <= model_u16(4) != 1 || model_u16(6) != 1;
        v1_fa <= model_u16(8) != HEADER_BYTES || model_u16(10) != DESC_BYTES ||
                 (model_header_mem[18] != LAYOUT_CHW && model_header_mem[18] != LAYOUT_HWC4) ||
                 (model_header_mem[18] == LAYOUT_HWC4 && model_u16(16) != 4) ||
                 model_header_mem[19] != 1 || model_header_mem[20] != 1 ||
                 model_header_mem[21] == 0 || model_header_mem[22] == 0 || model_header_mem[21] > MAX_LAYERS ||
                 model_header_mem[22] > MAX_CLASSES;
        v1_fm <= model_u32(48) != model_bytes_reg;
        v1_fb <= model_u32(24) != HEADER_BYTES ||
                 (model_u32(24) % 32) != 0 ||
                 (model_u32(32) % 32) != 0 ||
                 (model_u32(40) % 32) != 0;
        v1_fl <= model_u32(28) < model_header_mem[21] * DESC_BYTES;
        v1_fr <= !header_reserved_zero(1'b0);
        v1_fc <= model_u32(52) == 0 || (model_u32(52) % 32) != 0 ||
                 model_u32(52) > MAX_SCRATCH_BYTES;
        v1_fd <= model_u32(56) != input_bytes_reg ||
                 model_u32(56) == 0 || (model_u32(56) % 32) != 0;
        v1_fe <= model_u32(60) < model_u32(56) || (model_u32(60) % 32) != 0;
        v1_de <= header_desc_end;
        v1_we <= header_weight_end;
        v1_be <= header_bias_end;
        v1_hw <= model_u16(12) * model_u16(14);
        v1_c <= model_u16(16);
        // stage 2
        v2_fmt <= v1_fa || v1_fb || v1_fr || v1_fc || v1_fd || v1_fe || v1_fl || v1_fm ||
                  v1_de[32] || v1_de > {1'b0, model_bytes_reg} ||
                  {1'b0, model_u32(32)} < v1_de ||
                  {1'b0, model_u32(40)} < v1_we ||
                  v1_we[32] || v1_we > {1'b0, model_bytes_reg} ||
                  v1_be[32] || v1_be > {1'b0, model_bytes_reg};
        v2_pl <= v1_hw[15:0] * v1_c;
        v2_ph <= v1_hw[31:16] * v1_c;
        // stage 3
        v3_eh <= v2_ph + {16'd0, v2_pl[31:16]};
        v3_el <= v2_pl[15:0];
        // stage 4
        v4_shape <= {v3_eh, v3_el} > {16'd0, input_bytes_reg};
        // stage 5: MAGIC > VERSION > FORMAT > SHAPE (error priority)
        v5_err <= v1_magic || v1_ver || v2_fmt || v4_shape;
        v5_code <= v1_magic ? ERR_MODEL_MAGIC :
                   v1_ver ? ERR_MODEL_VERSION :
                   v2_fmt ? ERR_MODEL_FORMAT : ERR_MODEL_SHAPE;
    end

    // LEGACY_SCAN scratch estimate, free-running over descriptor_bits, which
    // does not change from ST_LEGACY_SCAN to ST_LS4.  The estimate
    // 2 * (((h*w*c + 31) / 32) * 32) is 32-bit unsigned (mod 2^32):
    // with q = (h*w*c + 31) mod 2^32 it is {q[30:5], 6'b0}.
    reg [31:0] lg1_hw;
    reg [15:0] lg1_c;
    reg [31:0] lg2_pl;
    reg [15:0] lg2_ph;
    reg [31:0] lg3_p, lg4_q;
    always @(posedge clk) begin
        lg1_hw <= desc_u16(2) * desc_u16(4);
        lg1_c <= desc_u16(6);
        lg2_pl <= lg1_hw[15:0] * lg1_c;
        lg2_ph <= lg1_hw[31:16] * lg1_c;        // low 16 bits only
        lg3_p <= {lg2_pl[31:16] + lg2_ph, lg2_pl[15:0]};
        lg4_q <= lg3_p + 32'd31;
    end

    // START checks, free-running over the start arguments latched in
    // ST_IDLE (*_reg); the cache registers and the header do not change
    // while idle.  sc_mend/sc_iend/sc_s1..3/sc_hit/sc_cc are valid in
    // ST_START_CMP, sc_ok in ST_START_CHECK, where it is taken.  sc_ok is the
    // start configuration check, sc_hit the model cache hit and sc_cc the
    // cache configuration check.
    reg [32:0] sc_mend, sc_iend;
    reg sc_s1, sc_s2, sc_s3, sc_hit, sc_cc, sc_ok;
    always @(posedge clk) begin
        sc_mend <= {1'b0, model_base_reg} + {1'b0, model_bytes_reg};
        sc_iend <= {1'b0, input_addr_reg} + {1'b0, input_source_bytes_reg};
        sc_s1 <= (model_bytes_reg >= 32'd128) &&
                 (model_bytes_reg <= MAX_MODEL_BYTES) &&
                 (model_bytes_reg[4:0] == 0) &&
                 (model_base_reg[4:0] == 0) && (model_base_reg >= DDR_BASE);
        sc_s2 <= (input_bytes_reg != 0) && (input_bytes_reg <= MAX_TENSOR_BYTES) &&
                 (input_bytes_reg[4:0] == 0) &&
                 (input_addr_reg[4:0] == 0) && (input_addr_reg >= DDR_BASE);
        sc_s3 <= (input_source_bytes_reg != 0) &&
                 (input_source_bytes_reg[4:0] == 0) &&
                 ((!input_downsample3_reg) ||
                  ((input_source_bytes_reg == 32'd36864) &&
                   (input_bytes_reg == 32'd4096)));
        sc_hit <= model_cache_valid_reg &&
                  (model_base_reg == model_cache_base_reg) &&
                  (model_bytes_reg == model_cache_bytes_reg);
        sc_cc <= (model_u32(48) == model_bytes_reg) &&
                 (model_u32(56) == input_bytes_reg);
        sc_ok <= sc_s1 && sc_s2 && sc_s3 &&
                 ({31'b0, sc_mend} <= ddr_end) && ({31'b0, sc_iend} <= ddr_end) &&
                 (!sc_hit || sc_cc);
    end

    // Burst length, free-running over read_addr_reg/read_remaining_beats.
    // Every new burst sets them and goes through ST_READ_CALC; in
    // ST_READ_BURST the burst length is min(rc_cap, rc_4k), so a burst never
    // crosses a 4 KiB boundary.
    // rc_bm1 / rc_last: burst_beats - 1 and "this burst is the last one"
    // for the end-of-burst decision in ST_READ_UNPACK (burst_beats and
    // read_remaining_beats are fixed from ST_READ_AR until then).
    reg [4:0] rc_cap, rc_bm1;
    reg [7:0] rc_4k;
    reg rc_last;
    always @(posedge clk) begin
        rc_cap <= burst_cap(read_remaining_beats);
        rc_4k <= (13'd4096 - {1'b0, read_addr_reg[11:0]}) >> 5;
        rc_bm1 <= burst_beats - 5'd1;
        rc_last <= (read_remaining_beats == {27'd0, burst_beats});
    end

    // CRC: the byte read in ST_CRC is registered (crc_d) and folded into
    // crc_reg one cycle later (crc_go); ST_CRC_FIN compares the final value.
    // crc_index runs from HEADER_BYTES to model_bytes_reg - 1 (crc_mbm1), so
    // crc_index < model_bytes_reg is !crc_none throughout.
    reg [7:0] crc_d;
    reg [31:0] crc_mbm1;
    reg crc_none;
    always @(posedge clk) begin
        crc_d <= model_read_data[7:0];
        crc_mbm1 <= model_bytes_reg - 32'd1;
        crc_none <= (model_bytes_reg <= HEADER_BYTES);
    end

    // Descriptor address for ST_LAYER_NEXT, one cycle ahead: the index
    // registers do not change in the cycle before it (ST_WRITE_DRAIN is the
    // only state that goes to ST_LAYER_NEXT).  If another state ever goes to
    // ST_LAYER_NEXT, check that this still holds there.
    // 16'd128 is HEADER_BYTES and {index, 6'b0} is index * DESC_BYTES
    // (DESC_BYTES == 64), here and in the model_read_addr block.
    reg [15:0] ln_addr;
    always @(posedge clk)
        ln_addr <= 16'd128 + {2'b0, (descriptor_scan_legacy ?
            {3'b0, legacy_scan_index} : layer_index + 8'd1), 6'b0};

    // Generator action this cycle: load element 0 of a pixel / window, or
    // step to the next element.
    // g_load / g_step (the load and step enables of the address generators)
    // are equality terms on state rather than a case: synthesis can build
    // such a case as a state-indexed shift with a subtract on state, which
    // puts the decode behind a carry chain.  Keep this form here.
    reg g_load, g_step;
    reg signed [19:0] g_ld_iy, g_ld_ix;
    wire g_s_su3 = (state == ST_SU3);
    wire g_s_pool = (state == ST_POOL);
    always @* begin
        g_load = (g_s_su3 && k_mp) ||
                 ((state == ST_BIAS_FETCH) && (bias_lane == 2'd3) && !k_fc) ||
                 (g_s_pool && pool_last);
        g_step = ((state == ST_WEIGHT_PRIME) && !k_fc) ||
                 (state == ST_CONV_MAC) || (state == ST_POOL_PRIME) ||
                 (g_s_pool && !pool_last);
        if (g_s_su3) begin
            g_ld_iy = k_init_iy;
            g_ld_ix = k_init_ix;
        end else if (g_s_pool) begin
            g_ld_iy = nx_iy;
            g_ld_ix = nx_ix;
        end else begin
            g_ld_iy = px_iy;
            g_ld_ix = px_ix;
        end
    end

    // tensor_read_addr update: one adder, tra_base + tra_inc, written
    // when tra_we.  In each state where tra_we is 1, the result is the
    // address the next state reads (see the read address notes above).
    reg tra_we;
    reg [15:0] tra_base, tra_inc;
    always @* begin
        tra_we = 1'b1;
        tra_base = tensor_read_addr;
        tra_inc = 16'd0;
        case (state)
            ST_SU3: tra_base = k_mp ? k_init_lin : 16'd0;
            ST_BIAS_FETCH: begin
                tra_we = (bias_lane == 2'd3);
                tra_base = k_fc ? 16'd0 : px_lin;
            end
            ST_WEIGHT_PRIME: tra_inc = k_fc ? 16'd1 : g_delta;
            ST_CONV_MAC, ST_POOL_PRIME: tra_inc = g_delta;
            ST_FC_MAC, ST_RELU_PRIME, ST_RELU, ST_ARGMAX_PRIME, ST_ARGMAX:
                tra_inc = 16'd1;
            ST_POOL:
                if (pool_last) tra_base = nx_lin;
                else tra_inc = g_delta;
            ST_GAP_PRIME: begin
                tra_we = !(gap_pend && gap_busy);
                tra_inc = k_gstep;
            end
            // After the last position of a CHW channel the address is
            // already the start of the next channel.
            ST_GAP:
                if (!gp_last) tra_inc = k_gstep;
                else if (a_hwc4) begin
                    tra_base = gap_channel[15:0];
                    tra_inc = 16'd1;
                end else tra_we = 1'b0;
            default: tra_we = 1'b0;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            model_read_addr <= 16'd0;
            tensor_read_addr <= 16'd0;
            w_base <= 16'd0; b_base <= 16'd0;
            g_iy <= 20'sd0; g_ix <= 20'sd0; cw_ix <= 20'sd0;
            g_ic <= 16'd0; g_kx <= 8'd0;
            g_ic_last <= 1'b0; g_kx_last <= 1'b0;
            c_inb <= 1'b0;
            px_iy <= 20'sd0; px_ix <= 20'sd0; nx_iy <= 20'sd0; nx_ix <= 20'sd0;
            px_lin <= 16'd0; rw_lin <= 16'd0; ch_lin <= 16'd0; widx <= 16'd0;
            nx_lin <= 16'd0; nx_rw <= 16'd0; nx_ch <= 16'd0; nx_widx <= 16'd0;
        end else begin
            // Element generator.  c_inb is registered with the step, so it
            // belongs to the element whose data arrives next cycle.
            if (g_load) begin
                g_iy <= g_ld_iy;
                g_ix <= g_ld_ix;
                cw_ix <= g_ld_ix;
                g_ic <= 16'd0;
                g_ic_last <= k_c1;
                g_kx <= 8'd0;
                g_kx_last <= k_kw1;
            end else if (g_step) begin
                c_inb <= g_inb;
                if (!g_ic_last) begin
                    g_ic <= g_ic + 16'd1;
                    g_ic_last <= (g_ic == k_gcm2);
                end else begin
                    g_ic <= 16'd0;
                    g_ic_last <= k_c1;
                    if (!g_kx_last) begin
                        g_kx <= g_kx + 8'd1;
                        g_kx_last <= (g_kx == k_kwm2);
                        g_ix <= g_ix + 20'sd1;
                    end else begin
                        g_kx <= 8'd0;
                        g_kx_last <= k_kw1;
                        g_ix <= cw_ix;
                        g_iy <= g_iy + 20'sd1;
                    end
                end
            end

            // Next pixel / window (out_x fastest, then out_y, then out_c).
            if (state == ST_BIAS_PRIME || state == ST_POOL_PRIME) begin
                if (out_x != k_owm1) begin
                    nx_iy <= px_iy;
                    nx_ix <= px_ix + {12'd0, layer_sw};
                    nx_lin <= px_lin + k_xstep;
                    nx_rw <= rw_lin;
                    nx_ch <= ch_lin;
                    nx_widx <= widx + k_wstep;
                end else if (out_y != k_ohm1) begin
                    nx_iy <= px_iy + {12'd0, layer_sh};
                    nx_ix <= k_init_ix;
                    nx_lin <= rw_lin + k_ystep;
                    nx_rw <= rw_lin + k_ystep;
                    nx_ch <= ch_lin;
                    nx_widx <= widx + k_wstep;
                end else begin
                    nx_iy <= k_init_iy;
                    nx_ix <= k_init_ix;
                    nx_lin <= ch_lin + k_chstep;
                    nx_rw <= ch_lin + k_chstep;
                    nx_ch <= ch_lin + k_chstep;
                    nx_widx <= a_hwc4 ? out_c[15:0] + 16'd1 : widx + 16'd1;
                end
            end
            if ((state == ST_CONV_MAC && conv_last) || (state == ST_POOL && pool_last)) begin
                px_iy <= nx_iy;
                px_ix <= nx_ix;
                px_lin <= nx_lin;
                rw_lin <= nx_rw;
                ch_lin <= nx_ch;
                widx <= nx_widx;
            end

            if (tra_we) tensor_read_addr <= tra_base + tra_inc;

            case (state)
                ST_SU3: begin
                    model_read_addr <= layer_bias_offset[15:0];
                    w_base <= layer_weight_offset[15:0];
                    b_base <= layer_bias_offset[15:0];
                    px_iy <= k_init_iy;
                    px_ix <= k_init_ix;
                    px_lin <= k_init_lin;
                    rw_lin <= k_init_lin;
                    ch_lin <= k_init_lin;
                    widx <= 16'd0;
                end
                // Descriptor address HEADER_BYTES + index * DESC_BYTES for
                // the ST_DESC_PRIME that follows; otherwise HEADER_BYTES for
                // ST_CRC_PRIME (the CRC starts at HEADER_BYTES).
                ST_READ_UNPACK:
                    model_read_addr <= read_target_input ?
                        16'd128 + {2'b0, desc_idx_now, 6'b0} : 16'd128;
                ST_VALIDATE: model_read_addr <= 16'd128;
                // ST_LS1 follows every descriptor scanned in ST_LEGACY_SCAN.
                // legacy_scan_index is already advanced, so this is the next
                // descriptor's address (unused after the last one: ST_LS4
                // then goes to ST_LEGACY_DONE).  descriptor_scan_legacy is 1
                // throughout the scan.
                ST_LS1:
                    model_read_addr <= 16'd128 + {5'b0, legacy_scan_index, 6'b0};
                ST_LAYER_NEXT: model_read_addr <= ln_addr;
                ST_CRC_PRIME:
                    if (!model_wr_en)
                        model_read_addr <= model_read_addr + 16'd1;
                ST_CRC, ST_DESC_PRIME, ST_DESC_READ, ST_BIAS_PRIME, ST_WEIGHT_PRIME:
                    model_read_addr <= model_read_addr + 16'd1;
                ST_BIAS_FETCH:
                    if (bias_lane == 2'd3)
                        model_read_addr <= w_base;
                    else
                        model_read_addr <= model_read_addr + 16'd1;
                ST_CONV_MAC: begin
                    if (!conv_last)
                        model_read_addr <= model_read_addr + 16'd1;
                    else if (conv_oc_wrap) begin
                        model_read_addr <= b_base + 16'd4;
                        w_base <= w_base + k_K16;
                        b_base <= b_base + 16'd4;
                    end else
                        model_read_addr <= b_base;
                end
                ST_FC_MAC: begin
                    if (!fc_last)
                        model_read_addr <= model_read_addr + 16'd1;
                    else begin
                        model_read_addr <= b_base + 16'd4;
                        w_base <= w_base + layer_in_c;
                        b_base <= b_base + 16'd4;
                    end
                end
                default: ;
            endcase
        end
    end

    // One synchronous read port allows PDS to infer block RAM for the large
    // model cache.  The write port is registered (ST_READ_UNPACK sets
    // model_wr_*), so the RAM is not written from the reset FSM block.
    always @(posedge clk) begin
        if (model_wr_en)
            model_mem[model_wr_addr] <= model_wr_data;
        model_read_data <= model_mem[model_read_addr];
    end

    // model_wr_addr[6:0] indexes the header, so HEADER_BYTES must be 128.
    always @(posedge clk) begin
        if (model_wr_en && model_wr_hdr)
            model_header_mem[model_wr_addr[6:0]] <= model_wr_data;
    end

    // Each tensor bank has one synchronous read port and one serialized write
    // port.  In particular, all operators share the registered read address;
    // separate asynchronous tensor_read() calls made PDS replicate the banks
    // into thousands of LUT RAMs and prevented placement.
    always @(posedge clk) begin
        if (tensor_write_enable && !tensor_write_slot)
            tensor_a[tensor_write_addr] <= tensor_write_data;
        if (tensor_write_enable && tensor_write_slot)
            tensor_b[tensor_write_addr] <= tensor_write_data;
        tensor_a_read_data <= tensor_a[tensor_read_addr];
        tensor_b_read_data <= tensor_b[tensor_read_addr];
    end

    // ------------------------------------------------------------------
    // MAC / requant pipeline datapath
    // ------------------------------------------------------------------
    // The high word adds c - s (-1, 0 or +1): c = mac4_c is the carry of the
    // low-word add and s = mac4_s the sign of the product.  For element 0 the
    // high word starts from the sign of the bias (mac4_bsign = bias_reg[31]).
    always @* begin
        mac_lo_sum = {1'b0, (mac3_first ? bias_reg : acc_lo)} +
                     {1'b0, {14{mac3_prod[17]}}, mac3_prod};
        mac_hi_sum = (mac4_first ? {32{mac4_bsign}} : acc_hi) +
                     {{31{~mac4_c & mac4_s}}, mac4_c ^ mac4_s};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mac2_v <= 1'b0; mac3_v <= 1'b0; mac4_v <= 1'b0;
        end else begin
            mac2_v <= mac1_v;
            mac3_v <= mac2_v;
            mac4_v <= mac3_v;
        end
    end

    always @(posedge clk) begin
        // mac1 -> mac2: remove the zero points (9-bit signed)
        mac2_dx <= {mac1_x[7], mac1_x} - {layer_input_zp[7], layer_input_zp};
        mac2_dw <= {mac1_w[7], mac1_w} - {layer_weight_zp[7], layer_weight_zp};
        mac2_en <= mac1_en;
        mac2_first <= mac1_first;
        mac2_last <= mac1_last;
        mac2_fc <= mac1_fc;
        mac2_idx <= mac1_idx;
        // mac2 -> mac3: 9x9 product, zero for padding taps
        mac3_prod <= mac2_en ? mac2_dx * mac2_dw : 18'sd0;
        mac3_first <= mac2_first;
        mac3_last <= mac2_last;
        mac3_fc <= mac2_fc;
        mac3_idx <= mac2_idx;
        // mac3 -> mac4: low accumulator word, carry and product sign kept
        if (mac3_v)
            acc_lo <= mac_lo_sum[31:0];
        mac4_c <= mac_lo_sum[32];
        mac4_s <= mac3_prod[17];
        mac4_first <= mac3_first;
        mac4_bsign <= bias_reg[31];
        mac4_last <= mac3_last;
        mac4_fc <= mac3_fc;
        mac4_idx <= mac3_idx;
        // mac4: high accumulator word; finished sums leave here
        if (mac4_v)
            acc_hi <= mac_hi_sum;
        // No range guard here: FC layers must have out_c <= MAX_CLASSES.
        // DISPATCH does not check this; a larger out_c writes past the end
        // of fc_output_mem (MAX_CLASSES entries).  Simulation drops such
        // writes; what synthesis builds for them is tool-dependent.
        if (mac4_v && mac4_last && mac4_fc)
            fc_output_mem[mac4_idx] <= acc_lo;
    end

    // Final CONV sums ({mac_hi_sum, acc_lo} in the mac4 cycle of the last
    // element) go to requant; results come back in order with their
    // tensor write address as the tag.
    Hnpu_requant_pipe #(.TAG_W(16)) u_requant (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(mac4_v && mac4_last && !mac4_fc),
        .in_tag(mac4_idx),
        .in_value({mac_hi_sum, acc_lo}),
        .in_multiplier(layer_multiplier),
        .in_shift(layer_shift),
        .in_zero_point(layer_output_zp),
        .in_relu(layer_flags[0]),
        .in_direct(layer_flags[1]),
        .out_valid(rq_out_valid),
        .out_tag(rq_out_tag),
        .out_q(rq_out_q),
        .busy(rq_busy)
    );

    Hnpu_gap_unit u_gap (
        .clk(clk),
        .rst_n(rst_n),
        .start(gap_start),
        .acc(gap_sum),
        .in_h(layer_in_h),
        .in_w(layer_in_w),
        .round4(layer_flags[2]),
        .done(gap_done),
        .q(gap_q),
        .busy(gap_busy)
    );

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
            descriptor_bits <= 0;
            descriptor_read_index <= 0;
            descriptor_scan_legacy <= 1'b0;
            input_addr_reg <= 0;
            input_bytes_reg <= 0;
            input_source_bytes_reg <= 0;
            input_downsample3_reg <= 1'b0;
            read_addr_reg <= 0;
            read_remaining_beats <= 0;
            read_offset <= 0;
            burst_beats <= 0;
            read_beat_index <= 0;
            read_beat_data <= 0;
            read_beat_last <= 0;
            unpack_lane <= 0;
            read_target_input <= 0;
            read_error_seen <= 0;
            read_error_code <= 0;
            drain_wait_count <= 0;
            dw_hit <= DW_HIT0;
            crc_index <= 0;
            crc_reg <= 0;
            tensor_active <= 0;
            tensor_write_enable <= 1'b0;
            tensor_write_slot <= 1'b0;
            tensor_write_addr <= 0;
            tensor_write_data <= 0;
            downsample_source_x <= 0;
            downsample_channel <= 0;
            downsample_phase_x <= 0;
            downsample_phase_y <= 0;
            downsample_dest_index <= 0;
            bias_lane <= 0;
            bias_low_bytes <= 0;
            legacy_scan_index <= 0;
            legacy_duplicate_flags_seen <= 1'b0;
            legacy_tail_valid <= 1'b1;
            legacy_flags_consistent <= 1'b1;
            legacy_expected_scratch <= 0;
            legacy_model_encoding_valid <= 1'b0;
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
            mac1_v <= 1'b0; pool_value <= 0; gap_accumulator <= 0;
            best_score <= 0; second_score <= 0; best_class <= 0;
            su_next <= ST_IDLE;
            ls_last <= 1'b0;
            crc_go <= 1'b0;
            crc_ne <= 1'b0;
            pool_last <= 1'b0;
            gp_last <= 1'b0;
            model_wr_en <= 1'b0; model_wr_hdr <= 1'b0;
            model_wr_addr <= 16'd0; model_wr_data <= 8'd0;
            gap_pend <= 1'b0; gap_sum <= 64'sd0;
            gap_wch <= 16'd0; gap_tag <= 16'd0;
            iw_v <= 1'b0; iw_addr <= 16'd0; iw_data <= 8'sd0;
            am_v <= 1'b0; am_c1 <= 1'b0; am_cand <= 0; am_cls <= 8'd0; am_diff <= 33'd0;
            pp_v <= 1'b0; pp_in <= 1'b0; pp_last <= 1'b0; pp_x <= 8'sd0; pp_widx <= 16'd0;
            rl_v <= 1'b0; rl_x <= 8'sd0; rl_addr <= 16'd0;
        end else begin
            done_pulse <= 1'b0;
            tensor_write_enable <= 1'b0;
            model_wr_en <= 1'b0;
            mac1_v <= 1'b0;
            iw_v <= 1'b0;
            am_v <= 1'b0;
            pp_v <= 1'b0;
            rl_v <= 1'b0;
            model_cache_hit <= 1'b0;
            model_cache_valid <= model_cache_valid_reg;
            if (clear_error) error <= 1'b0;
            // CRC byte read in the previous ST_CRC cycle (see crc_d).
            crc_go <= 1'b0;
            if (crc_go) crc_reg <= crc32_byte(crc_reg, crc_d);

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start && !busy) begin
                        downsample_source_x <= 0;
                        downsample_channel <= 0;
                        downsample_phase_x <= 0;
                        downsample_phase_y <= 0;
                        downsample_dest_index <= 0;
                        error <= 1'b0;
                        error_code <= 0;
                        result_class <= 0;
                        result_confidence <= 0;
                        result_reject <= 1'b0;
                        result_score <= 0;
                        // Latch the arguments now, check them in
                        // ST_START_CHECK (sc_*).  After a config error
                        // nothing reads the *_reg copies before the next
                        // start latches them again.
                        busy <= 1'b1;
                        model_base_reg <= model_base;
                        model_bytes_reg <= model_bytes;
                        input_addr_reg <= input_addr;
                        input_bytes_reg <= input_bytes;
                        input_source_bytes_reg <= input_source_bytes;
                        input_downsample3_reg <= input_downsample3;
                        state <= ST_START_SUM;
                    end
                end

                ST_START_SUM: state <= ST_START_CMP;
                ST_START_CMP: state <= ST_START_CHECK;
                ST_START_CHECK: begin
                    // A bad configuration is reported here, 3 cycles after
                    // the start, with busy 1 in between; the single-cycle
                    // version reported it in ST_IDLE without raising busy
                    // (see Port timing in the file header).
                    if (!sc_ok) begin
                        busy <= 1'b0;
                        error <= 1'b1;
                        error_code <= ERR_BAD_CONFIG;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        if (sc_hit) begin
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
                            read_addr_reg <= input_addr_reg;
                            read_remaining_beats <= input_source_bytes_reg >> 5;
                            read_target_input <= 1'b1;
                        end else begin
                            // A failed or changed model must not leave
                            // the previous package eligible for reuse.
                            // The cache becomes valid again only after the
                            // new package passes CRC/format checks and a
                            // complete inference reaches Argmax.
                            model_cache_valid_reg <= 1'b0;
                            model_cache_valid <= 1'b0;
                            read_addr_reg <= model_base_reg;
                            read_remaining_beats <= model_bytes_reg >> 5;
                            read_target_input <= 1'b0;
                            model_load_count <= model_load_count + 1'b1;
                        end
                        read_offset <= 0;
                        read_beat_index <= 0;
                        read_error_seen <= 0;
                        read_error_code <= 0;
                        drain_wait_count <= 0;
                        dw_hit <= DW_HIT0;
                        state <= ST_READ_CALC;
                    end
                end

                // rc_* follow read_addr_reg/read_remaining_beats one
                // cycle later; burst_beats is loaded in ST_READ_BURST.
                ST_READ_CALC: state <= ST_READ_BURST;
                ST_READ_BURST: begin
                    burst_beats <= ({3'b0, rc_cap} > rc_4k) ? rc_4k[4:0] : rc_cap;
                    state <= ST_READ_AR;
                end

                ST_READ_AR: begin
                    if (axi_arready) begin
                        read_beat_index <= 0;
                        read_error_seen <= 0;
                        read_error_code <= 0;
                        drain_wait_count <= 0;
                        dw_hit <= DW_HIT0;
                        state <= ST_READ_R;
                    end
                end

                ST_READ_R: begin
                    if (axi_rvalid) begin
                        if (!read_target_input)
                            model_load_beats <= model_load_beats + 1'b1;
                        // One 256-bit AXI beat is accepted here.  Serializing
                        // its bytes gives each on-chip RAM only one write port
                        // and naturally backpressures the next R beat.
                        read_beat_data <= axi_rdata;
                        read_beat_last <= axi_rlast;
                        unpack_lane <= 0;
                        if (axi_rid != AXI_ID || axi_rresp != 2'b00) begin
                            read_error_seen <= 1'b1;
                            read_error_code <= (axi_rresp != 2'b00) ? ERR_AXI_RRESP : ERR_AXI_RID;
                        end
                        state <= ST_READ_UNPACK;
                    end
                end

                ST_READ_UNPACK: begin
                    source_offset = read_offset + read_beat_index * 32 + unpack_lane;
                    if (read_target_input) begin
                        input_store_valid = 1'b0;
                        if (input_downsample3_reg) begin
                            // Source and destination are both HWC4.  Track
                            // byte, pixel and row phases instead of signed
                            // divide/modulo, which PDS cannot map here.
                            tensor_write_index = downsample_dest_index;
                            if (downsample_phase_y == 0 && downsample_phase_x == 0) begin
                                input_store_valid = downsample_dest_index < input_bytes_reg;
                                downsample_dest_index <= downsample_dest_index + 1'b1;
                            end
                            if (downsample_channel == 2'd3) begin
                                downsample_channel <= 0;
                                if (downsample_source_x == 7'd95) begin
                                    downsample_source_x <= 0;
                                    downsample_phase_x <= 0;
                                    downsample_phase_y <=
                                        (downsample_phase_y == 2'd2) ? 0 :
                                        downsample_phase_y + 1'b1;
                                end else begin
                                    downsample_source_x <= downsample_source_x + 1'b1;
                                    downsample_phase_x <=
                                        (downsample_phase_x == 2'd2) ? 0 :
                                        downsample_phase_x + 1'b1;
                                end
                            end else begin
                                downsample_channel <= downsample_channel + 1'b1;
                            end
                        end else begin
                            tensor_write_index = source_offset;
                            input_store_valid = source_offset < input_bytes_reg;
                        end
                        // Written in the next cycle (iw_v, after the state
                        // case).
                        iw_v <= input_store_valid;
                        iw_addr <= tensor_write_index[15:0];
                        iw_data <= read_beat_data[unpack_lane*8 +: 8];
                    end else if (source_offset < MAX_MODEL_BYTES) begin
                        // Registered write port; the byte lands next cycle.
                        model_wr_en <= 1'b1;
                        model_wr_hdr <= (source_offset < HEADER_BYTES);
                        model_wr_addr <= source_offset[15:0];
                        model_wr_data <= read_beat_data[unpack_lane*8 +: 8];
                    end

                    if (unpack_lane == 5'd31) begin
                        if (read_beat_last) begin
                            if (read_beat_index != rc_bm1 ||
                                read_error_seen) begin
                                busy <= 1'b0;
                                error <= 1'b1;
                                error_code <= read_error_seen ? read_error_code : ERR_AXI_RLAST;
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else if (rc_last) begin
                                if (read_target_input) begin
                                    state <= ST_DESC_PRIME;
                                end else begin
                                    crc_index <= HEADER_BYTES;
                                    crc_reg <= 32'hffff_ffff;
                                    state <= ST_CRC_PRIME;
                                end
                            end else begin
                                read_addr_reg <= read_addr_reg + (burst_beats << 5);
                                read_remaining_beats <= read_remaining_beats - burst_beats;
                                read_offset <= read_offset + (burst_beats << 5);
                                state <= ST_READ_CALC;
                            end
                        end else if (read_beat_index == rc_bm1) begin
                            read_error_seen <= 1'b1;
                            read_error_code <= ERR_AXI_RLAST;
                            drain_wait_count <= 0;
                            dw_hit <= DW_HIT0;
                            state <= ST_READ_DRAIN;
                        end else begin
                            read_beat_index <= read_beat_index + 1'b1;
                            state <= ST_READ_R;
                        end
                    end else unpack_lane <= unpack_lane + 1'b1;
                end

                ST_READ_DRAIN: begin
                    if (axi_rvalid) begin
                        drain_wait_count <= 0;
                        dw_hit <= DW_HIT0;
                        if (axi_rlast) begin
                            busy <= 1'b0;
                            error <= 1'b1;
                            error_code <= read_error_code;
                            done_pulse <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end else if (dw_hit) begin
                        busy <= 1'b0;
                        error <= 1'b1;
                        error_code <= read_error_code;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        drain_wait_count <= drain_wait_count + 1'b1;
                        dw_hit <= (drain_wait_count == DRAIN_TIMEOUT_LIMIT - 16'd1);
                    end
                end

                // The last model byte goes through the registered write
                // port and lands at the end of this cycle; if it is still in
                // flight, read byte HEADER_BYTES again next cycle.
                ST_CRC_PRIME: if (!model_wr_en) state <= ST_CRC;

                ST_CRC: begin
                    if (crc_none) begin
                        state <= ST_VALIDATE;
                    end else begin
                        // model_mem stores signed INT8 for MAC operations;
                        // CRC consumes the raw byte (crc_d, next cycle) and
                        // must not sign-extend weights/bias bytes above 0x7f.
                        crc_go <= 1'b1;
                        if (crc_index == crc_mbm1)
                            state <= ST_CRC_FIN;
                        else
                            crc_index <= crc_index + 1;
                    end
                end

                // crc_d is the last byte, crc_reg covers all bytes before it.
                ST_CRC_FIN: begin
                    crc_ne <= ~crc32_byte(crc_reg, crc_d) != model_u32(64);
                    state <= ST_CRC_CHECK;
                end

                ST_CRC_CHECK: begin
                    if (crc_ne) begin
                        busy <= 1'b0;
                        error <= 1'b1;
                        error_code <= ERR_MODEL_CRC;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        state <= ST_VALIDATE;
                    end
                end

                // The header checks run in the v1..v5 pipeline; the
                // decision is taken in ST_VAL4.  model_read_addr stays at
                // HEADER_BYTES (set in ST_VALIDATE) for ST_DESC_PRIME.
                ST_VALIDATE: state <= ST_VAL1;
                ST_VAL1: state <= ST_VAL2;
                ST_VAL2: state <= ST_VAL3;
                ST_VAL3: state <= ST_VAL4;
                ST_VAL4: begin
                    if (v5_err) begin
                        error <= 1'b1; error_code <= v5_code;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else begin
                        layer_count_reg <= model_header_mem[21];
                        class_count_reg <= model_header_mem[22];
                        model_layout_reg <= model_header_mem[18];
                        reject_threshold_reg <= model_u32(76);
                        expected_in_h <= model_u16(12);
                        expected_in_w <= model_u16(14);
                        expected_in_c <= model_u16(16);
                        model_cache_base_reg <= model_base_reg;
                        model_cache_bytes_reg <= model_bytes_reg;
                        model_cache_crc_reg <= model_u32(64);
                        layer_index <= 0;
                        tensor_active <= 0;
                        legacy_scan_index <= 0;
                        legacy_duplicate_flags_seen <= 1'b0;
                        legacy_tail_valid <= 1'b1;
                        legacy_flags_consistent <= 1'b1;
                        legacy_expected_scratch <= 0;
                        legacy_model_encoding_valid <= 1'b0;
                        descriptor_scan_legacy <= 1'b1;
                        state <= ST_DESC_PRIME;
                    end
                end

                ST_DESC_PRIME: begin
                    descriptor_read_index <= 0;
                    state <= ST_DESC_READ;
                end

                ST_DESC_READ: begin
                    descriptor_bits <= {model_read_data[7:0], descriptor_bits[DESC_BYTES*8-1:8]};
                    if (descriptor_read_index == DESC_BYTES - 1)
                        state <= descriptor_scan_legacy ? ST_LEGACY_SCAN : ST_LAYER_FETCH;
                    else
                        descriptor_read_index <= descriptor_read_index + 1'b1;
                end

                ST_LEGACY_SCAN: begin
                    if (legacy_scan_index >= layer_count_reg) begin
                        state <= ST_LEGACY_DONE;
                    end else begin
                        if (descriptor_bits[56*8 +: 8] != descriptor_bits[1*8 +: 8])
                            legacy_flags_consistent <= 1'b0;
                        if (descriptor_bits[56*8 +: 8] != 0) begin
                            legacy_duplicate_flags_seen <= 1'b1;
                            if ((descriptor_bits[56*8 +: 8] != descriptor_bits[1*8 +: 8]) ||
                                (descriptor_bits[0*8 +: 8] != OP_CONV2D &&
                                 descriptor_bits[0*8 +: 8] != OP_GAP))
                                legacy_tail_valid <= 1'b0;
                        end
                        if (!descriptor_reserved_compatible(1'b0))
                            legacy_tail_valid <= 1'b0;
                        legacy_scan_index <= legacy_scan_index + 1'b1;
                        ls_last <= (legacy_scan_index + 1'b1 >= layer_count_reg);
                        state <= ST_LS1;
                    end
                end

                // Wait for lg4_q (descriptor_bits is unchanged since
                // ST_LEGACY_SCAN).  ST_LS1 loads model_read_addr with the next
                // descriptor address (see the model_read_addr block).
                ST_LS1: state <= ST_LS2;
                ST_LS2: state <= ST_LS3;
                ST_LS3: state <= ST_LS4;
                ST_LS4: begin
                    if ((descriptor_bits[0*8 +: 8] == OP_GAP) &&
                        (legacy_expected_scratch == 0))
                        legacy_expected_scratch <= {lg4_q[30:5], 6'b0};
                    state <= ls_last ? ST_LEGACY_DONE : ST_DESC_PRIME;
                end

                ST_LEGACY_DONE: begin
                    legacy_model_encoding_valid <= legacy_duplicate_flags_seen &&
                        legacy_tail_valid && legacy_flags_consistent &&
                        (legacy_expected_scratch != 0) &&
                        (model_u32(52) == legacy_expected_scratch);
                    descriptor_scan_legacy <= 1'b0;
                    read_target_input <= 1'b1;
                    read_addr_reg <= input_addr_reg;
                    read_remaining_beats <= input_source_bytes_reg >> 5;
                    read_offset <= 0;
                    state <= ST_READ_CALC;
                end

                ST_LAYER_FETCH: begin
                    if (layer_index >= layer_count_reg) begin
                        error <= 1'b1; error_code <= ERR_MODEL_LAYER;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else begin
                        // Keep the descriptor address separate from tensor
                        // scan counters.  tensor_index is a sequential
                        // counter used only by ST_RELU.
                        layer_op <= descriptor_bits[0*8 +: 8];
                        layer_flags <= descriptor_bits[1*8 +: 8];
                        layer_in_h <= desc_u16(2);
                        layer_in_w <= desc_u16(4);
                        layer_in_c <= desc_u16(6);
                        layer_out_h <= desc_u16(8);
                        layer_out_w <= desc_u16(10);
                        layer_out_c <= desc_u16(12);
                        layer_kh <= descriptor_bits[14*8 +: 8];
                        layer_kw <= descriptor_bits[15*8 +: 8];
                        layer_sh <= descriptor_bits[16*8 +: 8];
                        layer_sw <= descriptor_bits[17*8 +: 8];
                        layer_pad_top <= descriptor_bits[18*8 +: 8];
                        layer_pad_left <= descriptor_bits[19*8 +: 8];
                        layer_pad_bottom <= descriptor_bits[20*8 +: 8];
                        layer_pad_right <= descriptor_bits[21*8 +: 8];
                        layer_weight_offset <= desc_u32(32);
                        layer_bias_offset <= desc_u32(36);
                        layer_weight_bytes <= desc_u32(40);
                        layer_bias_bytes <= desc_u32(44);
                        layer_multiplier <= desc_i32(48);
                        layer_shift <= descriptor_bits[52*8 +: 8];
                        layer_input_zp <= descriptor_bits[53*8 +: 8];
                        layer_weight_zp <= descriptor_bits[54*8 +: 8];
                        layer_output_zp <= descriptor_bits[55*8 +: 8];
                        state <= ST_DISPATCH;
                    end
                end

                ST_DISPATCH: begin
                    // The checks run in the dc*/d_* pipeline; ST_SU3 takes
                    // the decision and does the per-op initialisation.
                    case (layer_op)
                        OP_CONV2D, OP_FC: su_next <= ST_BIAS_PRIME;
                        OP_RELU: su_next <= ST_RELU_PRIME;
                        OP_MAXPOOL: su_next <= ST_POOL_PRIME;
                        OP_GAP: su_next <= ST_GAP_PRIME;
                        // OP_ARGMAX.  Unknown ops land here too; ST_SU3
                        // rejects them (d_opbad) before su_next is used.  A
                        // new op must be added here, in the ST_SU3 case and
                        // in dc1_opbad.
                        default: su_next <= ST_ARGMAX_PRIME;
                    endcase
                    state <= ST_SU0;
                end

                ST_BIAS_PRIME: begin
                    bias_lane <= 0;
                    state <= ST_BIAS_FETCH;
                end

                ST_BIAS_FETCH: begin
                    if (bias_lane == 2'd3) begin
                        bias_reg <= {model_read_data[7:0], bias_low_bytes};
                        state <= ST_WEIGHT_PRIME;
                    end else begin
                        case (bias_lane)
                            2'd0: bias_low_bytes[7:0] <= model_read_data[7:0];
                            2'd1: bias_low_bytes[15:8] <= model_read_data[7:0];
                            default: bias_low_bytes[23:16] <= model_read_data[7:0];
                        endcase
                        bias_lane <= bias_lane + 1'b1;
                    end
                end

                ST_WEIGHT_PRIME: begin
                    if (layer_op == OP_FC) state <= ST_FC_MAC;
                    else state <= ST_CONV_MAC;
                end

                ST_RELU_PRIME: state <= ST_RELU;
                ST_POOL_PRIME: begin
                    pool_last <= k_pw0;
                    state <= ST_POOL;
                end
                // Wait until the unit has taken the previous channel sum
                // (it is taken in the cycle gap_start is 1).
                ST_GAP_PRIME: begin
                    gp_last <= k_hw0;
                    if (!(gap_pend && gap_busy)) state <= ST_GAP;
                end
                ST_ARGMAX_PRIME: state <= ST_ARGMAX;
                // Wait until every MAC/requant result has been written.
                ST_WRITE_DRAIN: if (!mac_pipe_busy) state <= ST_LAYER_NEXT;
                // Wait for the per-layer constant pipeline; ST_SU3 loads
                // the address generators (see the address block).
                ST_SU0: state <= ST_SU1;
                ST_SU1: state <= ST_SU2;
                ST_SU2: state <= ST_SU3;
                ST_SU3: begin
                    if (d_opbad) begin
                        error <= 1'b1; error_code <= ERR_UNSUPPORTED_OP;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (d_fail) begin
                        error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else begin
                        state <= su_next;
                        case (layer_op)
                            OP_CONV2D: begin
                                out_x <= 0; out_y <= 0; out_c <= 0; kernel_index <= 0;
                            end
                            OP_RELU: tensor_index <= 0;
                            OP_MAXPOOL: begin
                                out_x <= 0; out_y <= 0; out_c <= 0; pool_index <= 0;
                                pool_value <= -8'sd128;
                            end
                            OP_GAP: begin
                                gap_channel <= 0; gap_position <= 0; gap_accumulator <= 0;
                            end
                            OP_FC: begin
                                fc_output <= 0; fc_index <= 0;
                            end
                            // OP_ARGMAX (unknown ops were rejected above).
                            default: begin
                                arg_index <= 0;
                                best_score <= -32'sh7fff_ffff;
                                second_score <= -32'sh7fff_ffff;
                                best_class <= 0;
                            end
                        endcase
                    end
                end

                ST_CONV_MAC: begin
                    // One kernel element per cycle into the MAC pipeline; the
                    // requantized output is written by the pipeline.  The
                    // address generator supplies the element's in-bounds flag
                    // (c_inb) and the output write index (widx).
                    mac1_v <= 1'b1;
                    mac1_x <= tensor_read_data;
                    mac1_w <= model_read_data;
                    mac1_en <= c_inb;
                    mac1_first <= (kernel_index == 0);
                    mac1_last <= conv_last;
                    mac1_fc <= 1'b0;
                    mac1_idx <= widx;
                    if (conv_last) begin
                        kernel_index <= 0;
                        if (out_x == k_owm1) begin
                            out_x <= 0;
                            if (out_y == k_ohm1) begin
                                out_y <= 0;
                                if (out_c == k_ocm1)
                                    state <= ST_WRITE_DRAIN;
                                else begin
                                    out_c <= out_c + 1;
                                    state <= ST_BIAS_PRIME;
                                end
                            end else begin
                                out_y <= out_y + 1;
                                state <= ST_BIAS_PRIME;
                            end
                        end else begin
                            out_x <= out_x + 1;
                            state <= ST_BIAS_PRIME;
                        end
                    end else begin
                        kernel_index <= kernel_index + 1;
                    end
                end

                ST_RELU: begin
                    // Clamped / written in the next cycle (rl_v, after the
                    // state case); WRITE_DRAIN waits for the last write.
                    if (tensor_index < k_relu_n) begin
                        rl_v <= 1'b1;
                        rl_x <= tensor_read_data;
                        rl_addr <= tensor_index[15:0];
                        tensor_index <= tensor_index + 1;
                    end else begin
                        state <= ST_WRITE_DRAIN;
                    end
                end

                ST_POOL: begin
                    // c_inb: this window element lies inside the input (from
                    // the address generator); widx: output write index.
                    // Compared / written in the next cycle (pp_v, after the
                    // state case).
                    pp_v <= 1'b1;
                    pp_x <= tensor_read_data;
                    pp_in <= c_inb;
                    pp_last <= pool_last;
                    pp_widx <= widx;
                    if (pool_last) begin
                        pool_index <= 0;
                        if (out_x == k_owm1) begin
                            out_x <= 0;
                            if (out_y == k_ohm1) begin
                                out_y <= 0;
                                if (out_c == k_ocm1) state <= ST_WRITE_DRAIN;
                                else begin
                                    out_c <= out_c + 1;
                                    state <= ST_POOL_PRIME;
                                end
                            end else begin
                                out_y <= out_y + 1;
                                state <= ST_POOL_PRIME;
                            end
                        end else begin
                            out_x <= out_x + 1;
                            state <= ST_POOL_PRIME;
                        end
                    end else begin
                        pool_index <= pool_index + 1;
                        pool_last <= (pool_index == k_pwm2);
                    end
                end

                ST_GAP: begin
                    next_gap_accumulator = gap_accumulator +
                        sign_extend_i8(tensor_read_data);
                    gap_accumulator <= next_gap_accumulator;
                    if (gp_last) begin
                        // Written when the GAP unit finishes (gap_done).
                        // gap_pend is 0 here: GAP_PRIME only leaves once
                        // the previous sum has been taken.
                        gap_pend <= 1'b1;
                        gap_sum <= next_gap_accumulator;
                        gap_wch <= gap_channel[15:0];
                        gap_position <= 0;
                        gap_accumulator <= 0;
                        if (gap_channel == k_ocm1) state <= ST_WRITE_DRAIN;
                        else begin
                            gap_channel <= gap_channel + 1;
                            state <= ST_GAP_PRIME;
                        end
                    end else begin
                        gap_position <= gap_position + 1;
                        gp_last <= (gap_position == k_hwm2);
                    end
                end

                ST_FC_MAC: begin
                    mac1_v <= 1'b1;
                    mac1_x <= tensor_read_data;
                    mac1_w <= model_read_data;
                    mac1_en <= 1'b1;
                    mac1_first <= (fc_index == 0);
                    mac1_last <= fc_last;
                    mac1_fc <= 1'b1;
                    mac1_idx <= fc_output[15:0];
                    if (fc_last) begin
                        fc_index <= 0;
                        // fc_output_mem is written by the MAC pipeline;
                        // WRITE_DRAIN waits for the last sum.
                        if (fc_output == k_ocm1) state <= ST_WRITE_DRAIN;
                        else begin
                            fc_output <= fc_output + 1;
                            state <= ST_BIAS_PRIME;
                        end
                    end else begin
                        fc_index <= fc_index + 1;
                    end
                end

                ST_ARGMAX: begin
                    // Folded into best/second in the next cycle (am_v,
                    // after the state case).
                    am_v <= 1'b1;
                    if (argmax_from_fc)
                        am_cand <= fc_output_mem[arg_index];
                    else
                        am_cand <= tensor_read_data;
                    am_cls <= arg_index[7:0];
                    if (arg_index == k_icm1) state <= ST_ARG_F1;
                    else arg_index <= arg_index + 1;
                end

                // The last candidate is folded in during ST_ARG_F1.
                ST_ARG_F1: state <= ST_ARG_F2;
                ST_ARG_F2: begin
                    am_diff <= {best_score[31], best_score} -
                               {second_score[31], second_score};
                    am_c1 <= (layer_in_c <= 1);
                    state <= ST_ARG_F3;
                end
                ST_ARG_F3: begin
                    // Margin: 0 when in_c <= 1 or best < second
                    // (am_diff[32]), otherwise best - second (0 .. 2^32-1).
                    am_margin = (am_c1 || am_diff[32]) ? 33'd0 : am_diff;
                    result_class <= best_class;
                    result_score <= best_score;
                    result_confidence <= (|am_margin[32:16]) ? 16'hffff :
                                         am_margin[15:0];
                    result_reject <= (am_margin < {1'b0, reject_threshold_reg});
                    // This is the first point at which every descriptor
                    // and referenced parameter range has been exercised.
                    // Keep the complete package in the local BRAM cache
                    // for later ROIs of the same model.
                    model_cache_valid_reg <= 1'b1;
                    model_cache_valid <= 1'b1;
                    busy <= 1'b0;
                    done_pulse <= 1'b1;
                    state <= ST_IDLE;
                end

                ST_LAYER_NEXT: begin
                    tensor_active <= ~tensor_active;
                    expected_in_h <= layer_out_h;
                    expected_in_w <= layer_out_w;
                    expected_in_c <= layer_out_c;
                    argmax_from_fc <= (layer_op == OP_FC);
                    layer_index <= layer_index + 1;
                    state <= ST_DESC_PRIME;
                end

                default: state <= ST_IDLE;
            endcase

            // Pipelined results: requantized CONV outputs and GAP outputs
            // (never both in one layer).
            // Tensor RAM write sources rq_out_valid, gap_done, iw_v, pp_v and
            // rl_v are never active in the same cycle; if two were, one write
            // would be lost without notice.  WRITE_DRAIN waits for all of
            // them except iw_v (see mac_pipe_busy).
            if (rq_out_valid) begin
                tensor_write_enable <= 1'b1;
                tensor_write_slot <= ~tensor_active;
                tensor_write_addr <= rq_out_tag;
                tensor_write_data <= rq_out_q;
            end else if (gap_done) begin
                tensor_write_enable <= 1'b1;
                tensor_write_slot <= ~tensor_active;
                tensor_write_addr <= gap_tag;
                tensor_write_data <= gap_q;
            end
            if (gap_start) begin
                gap_pend <= 1'b0;
                gap_tag <= gap_wch;
            end
            // Input tensor byte from ST_READ_UNPACK.
            if (iw_v) begin
                tensor_write_enable <= 1'b1;
                tensor_write_slot <= 1'b0;
                tensor_write_addr <= iw_addr;
                tensor_write_data <= iw_data;
            end
            // ARGMAX: fold the candidate of the previous cycle into
            // best/second.
            if (am_v) begin
                if (am_cand > best_score) begin
                    second_score <= best_score;
                    best_score <= am_cand;
                    best_class <= am_cls;
                end else if (am_cand > second_score)
                    second_score <= am_cand;
            end
            // POOL: running maximum of the window (kept across all of its
            // elements in pool_value); at the window end it is written and
            // the next window starts from -128.
            if (pp_v) begin
                pool_next = pool_value;
                if (pp_in && pp_x > pool_next)
                    pool_next = pp_x;
                if (pp_last) begin
                    tensor_write_enable <= 1'b1;
                    tensor_write_slot <= ~tensor_active;
                    tensor_write_addr <= pp_widx;
                    tensor_write_data <= pool_next;
                    pool_value <= -8'sd128;
                end else
                    pool_value <= pool_next;
            end
            // RELU: clamp to the output zero point and write.
            if (rl_v) begin
                tensor_write_enable <= 1'b1;
                tensor_write_slot <= ~tensor_active;
                tensor_write_addr <= rl_addr;
                tensor_write_data <= (rl_x < layer_output_zp) ? layer_output_zp : rl_x;
            end
        end
    end
endmodule

// Hnpu_requant_pipe: fully pipelined requantization, shift 0..31.
// Bit-exact with requantize() in Hnpu_cnn_engine.
//
// Timing: LATENCY = 6.  An input with in_valid = 1 in cycle t gives
// out_valid/out_tag/out_q in cycle t+6.  One new input per cycle, no
// backpressure.  Only in_shift[4:0] is used (DISPATCH in the engine
// rejects shifts above 31).  The inputs are registered in stage 0 and
// the outputs come straight from registers; busy is the OR of all stage
// valids.  out_q/out_tag are meaningful only when out_valid = 1.
//
// Derivation (V = in_value, M = in_multiplier, s = in_shift,
// P = |V|*|M|):
//   scaled = direct ? floor(V*M / 2^s)
//                   : sign(V*M) * floor((|V*M| + 2^(s-1)) / 2^s)
//   (V*M when s = 0).  With H = P >> s, rbit = P[s-1],
//   sticky = (P[s-1:0] != 0) (both 0 when s = 0) and
//   neg = sign(V) ^ sign(M) (P = 0 gives Q = 0, so neg does not matter):
//   |scaled| = Q = H + inc, inc = direct ? (neg & sticky) : rbit.
//   H >= 256 puts |scaled| beyond what zp can bring back into int8 (big):
//   the result is neg ? (relu ? zp : -128) : 127.  Otherwise
//   r = neg ? zp - Q : zp + Q (Q <= 256, 10 bits), zp when relu & neg
//   (scaled <= 0 when neg), then clamped to int8.
//   Since s <= 31, P >= 2^39 is always big, and so is V outside
//   [-2^39, 2^39-1] with M != 0.  So only the exact low 39 bits of P and
//   a "P >= 2^39" flag are needed.  All partial products are
//   non-negative, so the high part of the sum is nonzero iff some addend
//   has a nonzero high part or the low part carries out; no wide adder
//   is needed.
//
// Stages:
//   0  input registers.
//   1  |V| low 40 bits, |M| 32 bits (XOR plus sign bit);
//      vbig & (M != 0); neg.
//   2  five unsigned partial products (13x16 / 14x16); for
//      |V|[39:26] x |M|[31:16] only "both nonzero" is kept.
//   3  low 39 bits: four rows, two levels of 3:2 compression; the low
//      20 bits are added, the high 19 bits once for each carry-in 0/1;
//      high-bits-nonzero flag.
//   4  select the high half to form P[38:0]; H8 = P[s+7:s],
//      rbit/sticky; P[38:s+8] != 0 is folded into e4_big.
//   5  inc, r = zp + (H8 ^ neg) + (neg ^ inc), relu/big/saturation
//      -> out_q.
module Hnpu_requant_pipe #(parameter TAG_W = 32) (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               in_valid,
    input  wire [TAG_W-1:0]   in_tag,
    input  wire signed [63:0] in_value,
    input  wire signed [31:0] in_multiplier,
    input  wire [7:0]         in_shift,        // <= 31, checked by DISPATCH in the engine
    input  wire signed [7:0]  in_zero_point,
    input  wire               in_relu,
    input  wire               in_direct,
    output reg                out_valid,
    output reg  [TAG_W-1:0]   out_tag,
    output reg  signed [7:0]  out_q,
    output wire               busy             // any stage valid, including out_valid
);
    localparam LATENCY = 6;

    // ---------------- valid chain (asynchronous active-low reset) ----------------
    reg v0, v1, v2, v3, v4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v0 <= 1'b0;
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
            v4 <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            v0 <= in_valid;
            v1 <= v0;
            v2 <= v1;
            v3 <= v2;
            v4 <= v3;
            out_valid <= v4;
        end
    end
    assign busy = v0 | v1 | v2 | v3 | v4 | out_valid;

    // ---------------- stage 0: input registers ----------------
    reg [TAG_W-1:0] a0_tag;
    reg [63:0]      a0_value;
    reg [31:0]      a0_mult;
    reg [4:0]       a0_shift;
    reg [7:0]       a0_zp;
    reg             a0_relu;
    reg             a0_direct;
    always @(posedge clk) begin
        a0_tag    <= in_tag;
        a0_value  <= in_value;
        a0_mult   <= in_multiplier;
        a0_shift  <= in_shift[4:0];
        a0_zp     <= in_zero_point;
        a0_relu   <= in_relu;
        a0_direct <= in_direct;
    end

    // ---------------- stage 1: magnitudes, signs, out-of-range ----------------
    wire        s1_sv   = a0_value[63];
    wire        s1_sm   = a0_mult[31];
    wire [39:0] s1_absv = (a0_value[39:0] ^ {40{s1_sv}}) + {39'd0, s1_sv};
    wire [31:0] s1_absm = (a0_mult ^ {32{s1_sm}}) + {31'd0, s1_sm};
    wire        s1_vbig = ~((&a0_value[63:39]) | (~|a0_value[63:39]));
    wire        s1_mnz  = |a0_mult;

    reg [TAG_W-1:0] b1_tag;
    reg [39:0]      b1_absv;
    reg [31:0]      b1_absm;
    reg             b1_big;
    reg             b1_neg;
    reg [4:0]       b1_shift;
    reg [7:0]       b1_zp;
    reg             b1_relu;
    reg             b1_direct;
    always @(posedge clk) begin
        b1_tag    <= a0_tag;
        b1_absv   <= s1_absv;
        b1_absm   <= s1_absm;
        b1_big    <= s1_vbig & s1_mnz;
        b1_neg    <= s1_sv ^ s1_sm;   // P = 0 gives Q = 0 and a result of zp for either neg; no zero test needed
        b1_shift  <= a0_shift;
        b1_zp     <= a0_zp;
        b1_relu   <= a0_relu;
        b1_direct <= a0_direct;
    end

    // ---------------- stage 2: partial products (unsigned, at most 14x16) ----------------
    reg [TAG_W-1:0] c2_tag;
    reg [28:0]      c2_p00;   // |V|[12:0]  * |M|[15:0]   weight 2^0
    reg [28:0]      c2_p10;   // |V|[25:13] * |M|[15:0]   weight 2^13
    reg [29:0]      c2_p20;   // |V|[39:26] * |M|[15:0]   weight 2^26
    reg [28:0]      c2_p01;   // |V|[12:0]  * |M|[31:16]  weight 2^16
    reg [28:0]      c2_p11;   // |V|[25:13] * |M|[31:16]  weight 2^29
    reg             c2_big;
    reg             c2_neg;
    reg [4:0]       c2_shift;
    reg [7:0]       c2_zp;
    reg             c2_relu;
    reg             c2_direct;
    always @(posedge clk) begin
        c2_tag    <= b1_tag;
        c2_p00    <= b1_absv[12:0]  * b1_absm[15:0];
        c2_p10    <= b1_absv[25:13] * b1_absm[15:0];
        c2_p20    <= b1_absv[39:26] * b1_absm[15:0];
        c2_p01    <= b1_absv[12:0]  * b1_absm[31:16];
        c2_p11    <= b1_absv[25:13] * b1_absm[31:16];
        // |V|[39:26] * |M|[31:16] has weight 2^42: nonzero means P >= 2^42
        c2_big    <= b1_big | ((|b1_absv[39:26]) & (|b1_absm[31:16]));
        c2_neg    <= b1_neg;
        c2_shift  <= b1_shift;
        c2_zp     <= b1_zp;
        c2_relu   <= b1_relu;
        c2_direct <= b1_direct;
    end

    // ---------------- stage 3: compress the low 39 bits, split add ----------------
    // Four rows (each < 2^39); p00 and the low 10 bits of p11 do not overlap and share a row.
    wire [40:0] s3_ra = {2'd0, c2_p11[9:0], c2_p00};
    wire [40:0] s3_rb = {2'd0, c2_p10[25:0], 13'd0};
    wire [40:0] s3_rc = {2'd0, c2_p01[22:0], 16'd0};
    wire [40:0] s3_rd = {2'd0, c2_p20[12:0], 26'd0};
    wire [40:0] s3_s1 = s3_ra ^ s3_rb ^ s3_rc;
    wire [40:0] s3_c1 = ((s3_ra & s3_rb) | (s3_ra & s3_rc) | (s3_rb & s3_rc)) << 1;
    wire [40:0] s3_s2 = s3_s1 ^ s3_c1 ^ s3_rd;
    wire [40:0] s3_c2 = ((s3_s1 & s3_c1) | (s3_s1 & s3_rd) | (s3_c1 & s3_rd)) << 1;
    wire [20:0] s3_lo  = {1'b0, s3_s2[19:0]} + {1'b0, s3_c2[19:0]};
    wire [19:0] s3_hi0 = {1'b0, s3_s2[38:20]} + {1'b0, s3_c2[38:20]};
    wire [19:0] s3_hi1 = {1'b0, s3_s2[38:20]} + {1'b0, s3_c2[38:20]} + 20'd1;
    // bits at 2^39 and above that are dropped: partial products and compressor outputs
    wire        s3_ovf = (|c2_p10[28:26]) | (|c2_p20[29:13]) | (|c2_p01[28:23]) | (|c2_p11[28:10]) |
                         (|s3_s2[40:39]) | (|s3_c2[40:39]);

    reg [TAG_W-1:0] d3_tag;
    reg [19:0]      d3_lo;
    reg             d3_c20;
    reg [19:0]      d3_hi0;
    reg [19:0]      d3_hi1;
    reg             d3_big;
    reg             d3_neg;
    reg [4:0]       d3_shift;
    reg [7:0]       d3_zp;
    reg             d3_relu;
    reg             d3_direct;
    always @(posedge clk) begin
        d3_tag    <= c2_tag;
        d3_lo     <= s3_lo[19:0];
        d3_c20    <= s3_lo[20];
        d3_hi0    <= s3_hi0;
        d3_hi1    <= s3_hi1;
        d3_big    <= c2_big | s3_ovf;
        d3_neg    <= c2_neg;
        d3_shift  <= c2_shift;
        d3_zp     <= c2_zp;
        d3_relu   <= c2_relu;
        d3_direct <= c2_direct;
    end

    // ---------------- stage 4: form P[38:0], take the window at s ----------------
    wire [19:0] s4_hi = d3_c20 ? d3_hi1 : d3_hi0;   // s4_hi[19] = carry into bit 39
    wire [38:0] s4_p  = {s4_hi[18:0], d3_lo};
    wire [38:0] s4_h  = s4_p >> d3_shift;
    wire [30:0] s4_t  = s4_p[30:0] << (~d3_shift);  // shift by 31 - s: P[s-1:0] at the top, all zero when s = 0

    reg [TAG_W-1:0] e4_tag;
    reg [7:0]       e4_h8;
    reg             e4_big;
    reg             e4_rbit;
    reg             e4_sticky;
    reg             e4_neg;
    reg [7:0]       e4_zp;
    reg             e4_relu;
    reg             e4_direct;
    always @(posedge clk) begin
        e4_tag    <= d3_tag;
        e4_h8     <= s4_h[7:0];
        e4_big    <= d3_big | s4_hi[19] | (|s4_h[38:8]);
        e4_rbit   <= s4_t[30];
        e4_sticky <= |s4_t;
        e4_neg    <= d3_neg;
        e4_zp     <= d3_zp;
        e4_relu   <= d3_relu;
        e4_direct <= d3_direct;
    end

    // ---------------- stage 5: rounding increment, add zp, relu, saturation ----------------
    wire       s5_inc = e4_direct ? (e4_neg & e4_sticky) : e4_rbit;
    // If neg, zp - Q = zp + ~H8 + (1 - inc); otherwise zp + H8 + inc.
    // With H <= 255, Q <= 256 and r is in [-384, 383], so 10 bits are enough;
    // Q = 256 is handled by the saturation below.
    wire [9:0] s5_r   = {{2{e4_zp[7]}}, e4_zp} + ({2'b00, e4_h8} ^ {10{e4_neg}}) + {9'd0, e4_neg ^ s5_inc};
    wire [7:0] s5_sat = ((s5_r[9:7] == 3'b000) || (s5_r[9:7] == 3'b111)) ? s5_r[7:0] :
                        (s5_r[9] ? 8'h80 : 8'h7f);
    wire [7:0] s5_q   = (e4_relu & e4_neg) ? e4_zp :
                        e4_big ? (e4_neg ? 8'h80 : 8'h7f) : s5_sat;

    always @(posedge clk) begin
        out_tag <= e4_tag;
        out_q   <= s5_q;
    end
endmodule

// Hnpu_gap_unit: GAP output unit.  For any 64-bit acc and any in_h/in_w
// it gives the value the GAP layer writes:
//   round4 = 1: clamp_i8((acc + 64'sd8) >>> 4)
//   round4 = 0: clamp_i8(acc / (layer_in_h * layer_in_w))
// layer_in_h/w are reg [15:0] (unsigned), so in Verilog the whole
// division is unsigned and 64 bits wide: acc is taken as an
// unsigned A, hw = in_h*in_w is zero-extended (no truncation, at most
// (2^16-1)^2 < 2^32), the division is 64-bit unsigned and the quotient
// goes to clamp_i8 as a signed 64-bit value.  With D = hw:
//   D = 0:  cannot occur: DISPATCH rejects a layer whose layer_in_h or
//           layer_in_w is 0 (dc1_dims, ERR_MODEL_SHAPE).  The unit
//           returns 0 here; a plain Verilog divide by zero gives x.
//   D = 1:  the quotient is A, i.e. acc read as signed: clamp_i8(acc).
//   D >= 2: the quotient is below 2^63 and so non-negative: 127 if it
//           is 128 or more, else the quotient.  A negative acc gives
//           A >= 2^63 and a quotient of at least 128, so 127.
//   quotient >= 128  iff  A >= 128*D  iff  A[63:7] >= D
//                    iff  A[63:39] != 0 or A[38:7] >= D  (D < 2^32).
//   Otherwise A < 2^39 and the quotient has 7 bits: the remainder starts
//   as A[38:7] (< D), A[6:0] is shifted in MSB first, and each of the 7
//   restoring steps does a 33-bit compare/subtract.
//   round4: t = acc + 8 (64-bit wrap); t >>> 4 is in [-128, 127] iff
//   t[63:11] are all equal, giving t[11:4]; otherwise -128/127 by t[63].
//
// Timing: LATENCY = 11, not pipelined, one channel at a time.
// start is accepted when busy = 0 (acc/in_h/in_w/round4 are sampled in
// the same cycle); start while busy = 1 is ignored (the engine never does
// this).  Counting the accepting cycle as cycle 0, busy is 1 in cycles
// 1..11, done is a one-cycle pulse in cycle 11, and q is valid from done
// until the next done.  At most one start every 12 cycles.  The inputs
// are only sampled when a start is accepted.
//
// Per cycle (computed in cycle k, registered at the end of cycle k):
//   0     input registers a_r/h_r/w_r/r4_r.
//   1     two 16x8 partial products h*w[7:0], h*w[15:8]; low 32 bits
//         of acc + 8 with carry.
//   2     D = sum of the partial products (a 24-bit add); high 32 bits
//         of acc + 8 plus carry; the remainder registers load A[38:7]
//         and A[6:0].
//   3..9  restoring division, one quotient bit per cycle (the 33-bit
//         subtract is split into a low 16-bit part and a high 17-bit
//         part computed for borrow 0 and 1, selected by the low borrow).
//   10    select the result: round4 / D = 0 / D = 1 / quotient >= 128 /
//         quotient; register q and set done.
//   11    done = 1.
module Hnpu_gap_unit (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               start,
    input  wire signed [63:0] acc,
    input  wire        [15:0] in_h,
    input  wire        [15:0] in_w,
    input  wire               round4,
    output reg                done,
    output reg  signed [7:0]  q,
    output wire               busy
);
    localparam LATENCY = 11;
    localparam [3:0] C_LD  = 4'd2;    // load the remainder registers
    localparam [3:0] C_DV0 = 4'd3;    // first division step
    localparam [3:0] C_DV6 = 4'd9;    // last division step
    localparam [3:0] C_FIN = 4'd10;   // select the result
    localparam [3:0] C_END = 4'd11;   // done cycle

    // ---------------- control (asynchronous reset) ----------------
    reg        run_r;
    reg  [3:0] cnt_r;
    wire       go = start & ~run_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            run_r <= 1'b0;
            cnt_r <= 4'd0;
            done  <= 1'b0;
        end else begin
            done <= run_r & (cnt_r == C_FIN);
            if (go) begin
                run_r <= 1'b1;
                cnt_r <= 4'd1;
            end else if (run_r) begin
                if (cnt_r == C_END) begin
                    run_r <= 1'b0;
                    cnt_r <= 4'd0;
                end else begin
                    cnt_r <= cnt_r + 4'd1;
                end
            end
        end
    end
    assign busy = run_r;

    wire ld  = run_r & (cnt_r == C_LD);
    wire stp = run_r & (cnt_r >= C_DV0) & (cnt_r <= C_DV6);
    wire fin = run_r & (cnt_r == C_FIN);

    // ---------------- cycle 0: input registers ----------------
    reg signed [63:0] a_r;
    reg        [15:0] h_r, w_r;
    reg               r4_r;
    always @(posedge clk) begin
        if (go) begin
            a_r  <= acc;
            h_r  <= in_h;
            w_r  <= in_w;
            r4_r <= round4;
        end
    end

    // ---------------- cycles 1-2: D = h*w, t = acc + 8 ----------------
    // Recomputed from a_r/h_r/w_r every cycle; a_r etc. only change when a
    // start is accepted, so they are stable when used.
    reg [23:0] pp0_r, pp1_r;
    reg [31:0] d_r;
    reg [32:0] t1_r;
    reg [63:0] t_r;
    always @(posedge clk) begin
        pp0_r <= h_r * w_r[7:0];
        pp1_r <= h_r * w_r[15:8];
        d_r   <= {8'd0, pp0_r} + {pp1_r, 8'd0};
        t1_r  <= {1'b0, a_r[31:0]} + 33'd8;
        t_r   <= {a_r[63:32] + {31'd0, t1_r[32]}, t1_r[31:0]};
    end

    // ---------------- cycles 2-9: 7-step restoring division ----------------
    reg [31:0] p_r;      // partial remainder, < D after each step when there is no overflow
    reg [6:0]  ab_r;     // A[6:0], shifted in MSB first
    reg [6:0]  quo_r;    // quotient, MSB first
    wire [32:0] p2    = {p_r, ab_r[6]};                              // < 2D
    wire [16:0] lo_s  = {1'b0, p2[15:0]} - {1'b0, d_r[15:0]};        // [16] = low-half borrow
    wire [17:0] hi_s0 = {1'b0, p2[32:16]} - {2'b00, d_r[31:16]};     // high half, borrow-in 0; [17] = borrow
    wire [17:0] hi_s1 = {1'b0, p2[32:16]} + {2'b11, ~d_r[31:16]};    // high half, borrow-in 1 (= hi_s0 - 1)
    wire        ge    = lo_s[16] ? ~hi_s1[17] : ~hi_s0[17];          // p2 >= D
    wire [15:0] hi_d  = lo_s[16] ? hi_s1[15:0] : hi_s0[15:0];        // when ge, p2 - D < D < 2^32, so 16 high bits are enough
    always @(posedge clk) begin
        if (ld) begin
            p_r  <= a_r[38:7];
            ab_r <= a_r[6:0];
        end else if (stp) begin
            p_r   <= ge ? {hi_d, lo_s[15:0]} : p2[31:0];
            ab_r  <= {ab_r[5:0], 1'b0};
            quo_r <= {quo_r[5:0], ge};
        end
    end

    // ---------------- cycle 10: select the result ----------------
    wire       ovf = (|a_r[63:39]) | (a_r[38:7] >= d_r);          // A >= 128*D (quotient >= 128)
    wire       hw0 = (h_r == 16'd0) | (w_r == 16'd0);
    wire       hw1 = (h_r == 16'd1) & (w_r == 16'd1);
    wire       in1 = (&a_r[63:7]) | ~(|a_r[63:7]);                   // acc in [-128, 127]
    wire [7:0] q1  = in1 ? a_r[7:0] : (a_r[63] ? 8'h80 : 8'h7f);
    wire       in4 = (&t_r[63:11]) | ~(|t_r[63:11]);                 // t >>> 4 in [-128, 127]
    wire [7:0] q4  = in4 ? t_r[11:4] : (t_r[63] ? 8'h80 : 8'h7f);
    wire [7:0] qd  = ovf ? 8'h7f : {1'b0, quo_r};
    always @(posedge clk) begin
        if (fin)
            q <= r4_r ? q4 : (hw0 ? 8'h00 : (hw1 ? q1 : qd));
    end
endmodule
