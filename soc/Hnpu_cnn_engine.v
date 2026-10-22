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
    localparam [31:0] MAX_SCRATCH_BYTES = MAX_TENSOR_BYTES << 1;
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
    // The final convolution MAC and requantization are separate pipeline
    // stages.  Keeping the BRAM read/MAC and the shift/clamp on different
    // cycles removes the long BRAM-to-writeback path at the DDR clock.
    localparam [5:0] ST_CONV_WRITE = 6'd29;
    localparam [5:0] ST_GAP_DIV = 6'd30;
    // Keep the multiply result out of the accumulator feedback path.  The
    // flush states retire the final product after the last issue cycle.
    localparam [5:0] ST_CONV_MAC_FLUSH = 6'd31;
    localparam [5:0] ST_FC_MAC_FLUSH = 6'd32;
    // Layer dispatch is split over three cycles so that no cycle contains a
    // multiplier chain followed by the 30-term descriptor predicate:
    //   ST_LAYER_FETCH : latch descriptor fields + first-level products
    //   ST_DISPATCH    : second-level products -> layer_* constants
    //   ST_CHECK       : predicates -> error/state only
    // Costs one clock per layer (144 clocks on the 144-layer road model,
    // 0.0038% of an inference) and adds no logic.
    localparam [5:0] ST_CHECK = 6'd33;

    reg [5:0] state;
    reg signed [7:0] model_mem [0:MAX_MODEL_BYTES-1];
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
    reg signed [7:0] tensor_a [0:MAX_TENSOR_BYTES-1];
    reg signed [7:0] tensor_b [0:MAX_TENSOR_BYTES-1];
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

    // ---- Per-layer constants and per-pixel address bases --------------------
    // Before this change the tensor address cone recomputed, on every single
    // MAC issue, all of: out_y*layer_sh, out_x*layer_sw, y*layer_in_w,
    // layer_in_h*layer_in_w, ic*layer_in_w*layer_in_h and
    // layer_kh*layer_kw*layer_in_c.  mul_u16_no_dsp expands to a four-level
    // shift/add tree, so the cone reached 24 logic levels (Logic 5.789 /
    // Route 8.724 ns) against an 8 ns clock, i.e. PDS reported
    // tensor_a_1/ADB0[14] at -6.734 ns.
    //
    // Every quantity below changes only at a layer boundary, at an output
    // pixel boundary, or (for the kernel offsets) at a kernel step, so it can
    // live in a register.  What is left in the cone is two 16-bit adds for the
    // bounds test and two 16-bit adds for the address, with no multiplier.
    // The kernel loop still issues one MAC per clock: nothing here adds a
    // pipeline stage, it only moves work out of the combinational path.
    reg [15:0] layer_in_c_m1;
    reg [7:0]  layer_kw_m1;           // layer_kw - 1
    reg [15:0] layer_out_w_m1, layer_out_h_m1, layer_out_c_m1;
    reg [15:0] layer_hw;              // layer_in_h * layer_in_w
    reg [15:0] layer_kh_kw_m1;        // layer_kh * layer_kw - 1
    reg [31:0] layer_kernel_size_m1;  // layer_kh * layer_kw * layer_in_c - 1
    reg [31:0] layer_kernel_size;     // layer_kh * layer_kw * layer_in_c
    reg [31:0] layer_elements;        // layer_in_h * layer_in_w * layer_in_c
    // Descriptor-bound products that are only read by ST_CHECK.  Holding them
    // in registers keeps the comparator tree off the multiplier output.
    reg [31:0] layer_out_elements;    // layer_out_h * layer_out_w * layer_out_c
    reg [31:0] layer_conv_weight_req; // layer_kernel_size * layer_out_c
    reg [31:0] layer_fc_weight_req;   // layer_out_c * layer_in_c
    reg [15:0] layer_out_hw;          // layer_out_h * layer_out_w
    // Address-space scaling: 1 for CHW, layer_in_c for HWC4, because
    //   CHW  addr = ic*H*W + y*W + x
    //   HWC4 addr = (y*W + x)*C + ic
    reg [15:0] layer_ic_stride;       // H*W (CHW) or 1 (HWC4)
    reg [15:0] layer_kern_step;       // kx step,  = layer_c_scale
    reg [15:0] layer_kern_wrap;       // kx wrap,  = (W - (kw-1)) * c_scale
    reg [15:0] layer_pix_step_x;      // = layer_sw * c_scale
    reg [15:0] layer_row_step;        // = W * c_scale * layer_sh
    reg [15:0] layer_row_step_padl;   // = layer_row_step - pad_left*c_scale
    reg [15:0] layer_row_a0;          // = -pad_top * W * c_scale
    reg [15:0] layer_row0_a;          // = (-pad_top*W - pad_left) * c_scale
    reg [15:0] layer_neg_pad_top;     // = -layer_pad_top
    reg [15:0] layer_neg_pad_left;    // = -layer_pad_left
    // Per output pixel: window origin in pixel space and in address space.
    reg [15:0] pix_base_y;            // out_y*sh - pad_top
    reg [15:0] pix_base_x;            // out_x*sw - pad_left
    reg [15:0] pix_row_a;             // (out_y*sh - pad_top) * W * c_scale
    reg [15:0] pix_origin_a;          // pix_row_a + (out_x*sw - pad_left)*c_scale
    // Kernel offsets within the current output pixel.
    reg [15:0] conv_kern_off;         // (ky*W + kx) * c_scale
    reg [15:0] conv_ic_off;           // conv_ic_reg * ic_stride
    reg [15:0] pool_kern_off;         // (pool_ky*W + pool_kx) * c_scale
    reg [15:0] pool_ic_off;           // out_c * ic_stride
    // The tensor BRAM latches its address one cycle before the data is
    // consumed, so the in-bounds decision made for the *addressed* element is
    // exactly the validity of the element read on the next cycle.  Holding it
    // removes a duplicate bounds cone from the mac_product path.
    reg tensor_valid_q;

    // ---- Three-stage layer dispatch ----------------------------------------
    // ST_DISPATCH used to evaluate sixteen 16x16 / 32x16 multiplier trees and
    // the thirty-term descriptor predicate in the same cycle, so that
    // predicate drove the clock enable of 143 data registers
    // (N7446, fanout 143).  PDS reported layer_in_h[3] -> gap_position[16]
    // at -5.963 ns with Logic 4.905 / Route 8.522 ns over 22 logic levels.
    //
    // The work is now spread so that no cycle holds a multiplier chain
    // followed by the comparator tree:
    //   ST_LAYER_FETCH : ds_* straight from descriptor_bits, first-level
    //                    products latched into d1_*
    //   ST_DISPATCH    : second-level products latched into layer_*
    //   ST_CHECK       : comparisons only; the result drives state/error
    //
    // Every reassociation below is unsigned mod-2^16 / mod-2^32 arithmetic,
    // where multiplication is associative and commutative, so each value is
    // bit-identical to the previous single-cycle expression.
    wire [15:0] disp_c_scale = (model_layout_reg == LAYOUT_HWC4) ?
                               layer_in_c : 16'd1;
    wire [15:0] ds_h  = desc_u16(2);
    wire [15:0] ds_w  = desc_u16(4);
    wire [15:0] ds_c  = desc_u16(6);
    wire [15:0] ds_oh = desc_u16(8);
    wire [15:0] ds_ow = desc_u16(10);
    wire [15:0] ds_oc = desc_u16(12);
    wire [7:0]  ds_kh = descriptor_bits[14*8 +: 8];
    wire [7:0]  ds_kw = descriptor_bits[15*8 +: 8];
    wire [7:0]  ds_sh = descriptor_bits[16*8 +: 8];
    wire [7:0]  ds_sw = descriptor_bits[17*8 +: 8];
    wire [7:0]  ds_pt = descriptor_bits[18*8 +: 8];
    wire [7:0]  ds_pl = descriptor_bits[19*8 +: 8];
    wire [15:0] ds_cs = (model_layout_reg == LAYOUT_HWC4) ? ds_c : 16'd1;

    // First-level products.  Eight-bit operands use the eight-bit shift/add
    // tree (three levels) instead of the sixteen-bit tree (five levels): the
    // descriptor declares kh/kw/sh/sw/pad_* as single bytes.
    wire [31:0] ds_p_hw   = mul_u16_no_dsp(ds_h, ds_w);    // exact, < 2^32
    wire [31:0] ds_p_ohw  = mul_u16_no_dsp(ds_oh, ds_ow);  // exact
    wire [23:0] ds_p_khkw24 = mul_u16_u8_no_dsp({8'b0, ds_kh}, ds_kw);
    wire [15:0] ds_p_khkw = ds_p_khkw24[15:0];
    wire [31:0] ds_p_wc32 = mul_u16_no_dsp(ds_w, ds_cs);
    wire [15:0] ds_p_wc   = ds_p_wc32[15:0];
    wire [23:0] ds_p_ptw24 = mul_u16_u8_no_dsp(ds_w, ds_pt);
    wire [15:0] ds_p_ptw  = ds_p_ptw24[15:0];
    wire [23:0] ds_p_plc24 = mul_u16_u8_no_dsp(ds_cs, ds_pl);
    wire [15:0] ds_p_plc  = ds_p_plc24[15:0];
    wire [15:0] ds_p_kw1  = (ds_w - {8'b0, ds_kw}) + 16'd1;

    reg [31:0] d1_hw;                 // in_h * in_w   (exact)
    reg [31:0] d1_ohw;                // out_h * out_w (exact)
    reg [15:0] d1_khkw;               // kh * kw
    reg [15:0] d1_wc;                 // in_w * c_scale
    reg [15:0] d1_ptw;                // pad_top * in_w
    reg [15:0] d1_plc;                // pad_left * c_scale
    reg [15:0] d1_kw1;                // in_w - kw + 1

    // Second-level products.  These are registered by ST_DISPATCH, so the
    // whole multiplier tree ends at a flip-flop instead of at a clock enable.
    wire [31:0] disp_elements = mul_u32_u16_no_dsp(d1_hw, layer_in_c);
    wire [31:0] disp_out_elements =
        mul_u32_u16_no_dsp(d1_ohw, layer_out_c);
    wire [31:0] disp_kernel_size =
        mul_u32_u16_no_dsp({16'b0, d1_khkw}, layer_in_c);
    wire [31:0] disp_conv_weight_req =
        mul_u32_u16_no_dsp(disp_kernel_size, layer_out_c);
    wire [31:0] disp_fc_weight_req = mul_u16_no_dsp(layer_out_c, layer_in_c);
    wire [23:0] disp_row_step24 = mul_u16_u8_no_dsp(d1_wc, layer_sh);
    wire [15:0] disp_row_step   = disp_row_step24[15:0];
    wire [31:0] disp_kern_wrap32 = mul_u16_no_dsp(d1_kw1, disp_c_scale);
    wire [15:0] disp_kern_wrap   = disp_kern_wrap32[15:0];
    wire [23:0] disp_pix_step24 = mul_u16_u8_no_dsp(disp_c_scale, layer_sw);
    wire [15:0] disp_pix_step_x = disp_pix_step24[15:0];
    wire [23:0] disp_row0_a24 = mul_u16_u8_no_dsp(d1_wc, layer_pad_top);
    wire [15:0] disp_row0_a   = disp_row0_a24[15:0];
    wire [31:0] disp_out_hw32 = mul_u16_no_dsp(layer_out_h, layer_out_w);
    wire [15:0] disp_out_hw   = disp_out_hw32[15:0];

    // Loop counters.  Every one of them is bounded by a 16-bit descriptor
    // dimension, so 32-bit integers only added carry chains and clock-enable
    // fanout: gap_position[16..31] were the reported end points of the
    // -5.963 ns path even though bits above 16 can never be set.
    reg [15:0] out_x, out_y, out_c;
    reg [16:0] kernel_index;          // kernel_size <= MAX_MODEL_BYTES
    reg [15:0] pool_index;
    reg [15:0] tensor_index;
    integer tensor_read_index;
    reg [15:0] fc_index, fc_output;
    reg [15:0] arg_index;
    // These counters walk the kernel/window coordinates directly.  Keeping
    // them registered avoids synthesizing variable divide/modulo operators
    // in the tensor BRAM address path.
    reg [15:0] conv_ky_reg, conv_kx_reg, conv_ic_reg;
    reg [15:0] pool_ky_reg, pool_kx_reg;
    // v0.3 bounds all convolution and FC accumulators well within signed
    // 32-bit range.  The former 64-bit accumulator also fed the generic
    // 96-bit requantizer in the same cycle and created a 575-level path.
    reg signed [31:0] accumulator;
    reg signed [31:0] mac_product;
    reg mac_product_valid;
    reg signed [7:0] pool_value;
    reg signed [31:0] gap_accumulator;
    reg signed [31:0] next_gap_accumulator;
    reg [16:0] gap_divisor, gap_remainder;
    reg [31:0] gap_dividend, gap_quotient;
    reg [5:0] gap_div_bit;
    reg gap_div_negative;
    reg signed [31:0] best_score, second_score;
    reg [7:0] best_class;

    reg [15:0] gap_channel, gap_position;
    integer fc_input_index, fc_weight_index;
    integer source_offset;
    reg [6:0] downsample_source_x;
    reg [1:0] downsample_channel;
    reg [1:0] downsample_phase_x;
    reg [1:0] downsample_phase_y;
    reg [12:0] downsample_dest_index;
    integer tensor_write_index;
    reg input_store_valid;
    reg signed [31:0] next_accumulator;
    reg signed [31:0] candidate_score;
    reg signed [7:0] pool_next;
    reg signed [31:0] new_best_score;
    reg signed [31:0] new_second_score;
    reg [7:0] new_best_class;
    reg signed [63:0] final_margin;
    reg [17:0] gap_div_trial, gap_div_subtracted;
    reg [31:0] gap_div_quotient_next;

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

    function signed [31:0] sign_extend_i8_32;
        input signed [7:0] value;
        begin
            sign_extend_i8_32 = {{24{value[7]}}, value};
        end
    endfunction

    // Shape and address arithmetic must not consume the device MAC blocks.
    // This bounded shift/add multiplier is used only for unsigned descriptor
    // dimensions and byte offsets; the two INT8 MAC operations remain real
    // multipliers.  Keeping this helper separate also makes the intent clear
    // to synthesis tools that otherwise map every '*' expression to APM.
    function [31:0] mul_u16_no_dsp;
        input [15:0] left;
        input [15:0] right;
        reg [31:0] partial [0:15];
        reg [31:0] level1 [0:7];
        reg [31:0] level2 [0:3];
        reg [31:0] level3 [0:1];
        integer mul_bit;
        begin
            for (mul_bit = 0; mul_bit < 16; mul_bit = mul_bit + 1)
                partial[mul_bit] = right[mul_bit] ?
                                   ({16'b0, left} << mul_bit) : 32'b0;
            for (mul_bit = 0; mul_bit < 8; mul_bit = mul_bit + 1)
                level1[mul_bit] = partial[mul_bit*2] + partial[mul_bit*2+1];
            for (mul_bit = 0; mul_bit < 4; mul_bit = mul_bit + 1)
                level2[mul_bit] = level1[mul_bit*2] + level1[mul_bit*2+1];
            for (mul_bit = 0; mul_bit < 2; mul_bit = mul_bit + 1)
                level3[mul_bit] = level2[mul_bit*2] + level2[mul_bit*2+1];
            mul_u16_no_dsp = level3[0] + level3[1];
        end
    endfunction

    function [31:0] mul_u32_u16_no_dsp;
        input [31:0] left;
        input [15:0] right;
        reg [31:0] partial [0:15];
        reg [31:0] level1 [0:7];
        reg [31:0] level2 [0:3];
        reg [31:0] level3 [0:1];
        integer mul_bit;
        begin
            for (mul_bit = 0; mul_bit < 16; mul_bit = mul_bit + 1)
                partial[mul_bit] = right[mul_bit] ?
                                   (left << mul_bit) : 32'b0;
            for (mul_bit = 0; mul_bit < 8; mul_bit = mul_bit + 1)
                level1[mul_bit] = partial[mul_bit*2] + partial[mul_bit*2+1];
            for (mul_bit = 0; mul_bit < 4; mul_bit = mul_bit + 1)
                level2[mul_bit] = level1[mul_bit*2] + level1[mul_bit*2+1];
            for (mul_bit = 0; mul_bit < 2; mul_bit = mul_bit + 1)
                level3[mul_bit] = level2[mul_bit*2] + level2[mul_bit*2+1];
            mul_u32_u16_no_dsp = level3[0] + level3[1];
        end
    endfunction

    function [23:0] mul_u16_u8_no_dsp;
        input [15:0] left;
        input [7:0] right;
        reg [23:0] partial [0:7];
        reg [23:0] level1 [0:3];
        reg [23:0] level2 [0:1];
        integer mul_bit;
        begin
            for (mul_bit = 0; mul_bit < 8; mul_bit = mul_bit + 1)
                partial[mul_bit] = right[mul_bit] ?
                                   ({8'b0, left} << mul_bit) : 24'b0;
            for (mul_bit = 0; mul_bit < 4; mul_bit = mul_bit + 1)
                level1[mul_bit] = partial[mul_bit*2] + partial[mul_bit*2+1];
            for (mul_bit = 0; mul_bit < 2; mul_bit = mul_bit + 1)
                level2[mul_bit] = level1[mul_bit*2] + level1[mul_bit*2+1];
            mul_u16_u8_no_dsp = level2[0] + level2[1];
        end
    endfunction

    // floor(extent / stride) + 1 equals output_dim iff
    // (output_dim - 1) * stride <= extent < output_dim * stride.
    // This avoids a variable divider in the descriptor dispatch path.
    function shape_dimension_valid;
        input [15:0] input_dim;
        input [15:0] output_dim;
        input [7:0] kernel;
        input [7:0] stride;
        input [7:0] pad_before;
        input [7:0] pad_after;
        reg [17:0] padded_extent;
        reg [17:0] kernel_extent;
        reg [17:0] extent;
        reg [15:0] output_minus_one;
        reg [23:0] lower_bound;
        reg [23:0] upper_bound;
        begin
            padded_extent = {2'b0, input_dim} + {10'b0, pad_before} +
                            {10'b0, pad_after};
            kernel_extent = {10'b0, kernel};
            extent = 18'b0;
            output_minus_one = 16'b0;
            lower_bound = 24'b0;
            upper_bound = 24'b0;
            shape_dimension_valid = 1'b0;
            if (stride != 0 && output_dim != 0 &&
                padded_extent >= kernel_extent) begin
                extent = padded_extent - kernel_extent;
                output_minus_one = output_dim - 1'b1;
                lower_bound = mul_u16_u8_no_dsp(output_minus_one, stride);
                upper_bound = lower_bound + {16'b0, stride};
                shape_dimension_valid = ({6'b0, extent} >= lower_bound) &&
                                        ({6'b0, extent} < upper_bound);
            end
        end
    endfunction

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

    // The delivered v0.3 package uses multiplier=1, zero-points=0 and
    // direct arithmetic right shift.  Keep this implementation narrow so
    // the supported model does not infer a 96-bit variable multiplier.
    function signed [7:0] requantize_direct;
        input signed [31:0] value;
        input [7:0] shift;
        input signed [7:0] zero_point;
        input relu_enable;
        reg signed [31:0] scaled;
        reg signed [31:0] result_value;
        reg signed [31:0] zero_point_32;
        begin
            zero_point_32 = {{24{zero_point[7]}}, zero_point};
            // The delivered v0.3 descriptors only use shifts 7, 8 and 10.
            // Keeping these as fixed cases avoids inferring a wide barrel
            // shifter on the DDR clock path.
            case (shift)
                8'd7: scaled = value >>> 7;
                8'd8: scaled = value >>> 8;
                8'd10: scaled = value >>> 10;
                default: scaled = (shift == 0) ? value : (value >>> shift);
            endcase
            result_value = scaled + zero_point_32;
            if (relu_enable && result_value < zero_point_32)
                result_value = zero_point_32;
            if (result_value > 32'sd127)
                requantize_direct = 8'sd127;
            else if (result_value < -32'sd128)
                requantize_direct = -8'sd128;
            else
                requantize_direct = result_value[7:0];
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
            c = crc ^ {24'b0, data};
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
    wire [31:0] model_input_hw = mul_u16_no_dsp(model_u16(12), model_u16(14));
    wire [31:0] model_input_elements_32 =
        mul_u16_no_dsp(model_input_hw[15:0], model_u16(16));
    wire [63:0] model_input_elements = {32'b0, model_input_elements_32};
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

    // One synchronous read port allows PDS to infer block RAM for the large
    // model cache.  The metadata copy is small and does not touch this port.
    always @* begin
        model_read_addr = 0;
        case (state)
            ST_CRC_PRIME: model_read_addr = HEADER_BYTES;
            ST_CRC: model_read_addr = crc_index + 1'b1;
            ST_DESC_PRIME: model_read_addr = HEADER_BYTES +
                ({24'b0, (descriptor_scan_legacy ? legacy_scan_index : layer_index)} << 6);
            ST_DESC_READ: model_read_addr = HEADER_BYTES +
                ({24'b0, (descriptor_scan_legacy ? legacy_scan_index : layer_index)} << 6) +
                descriptor_read_index + 1'b1;
            ST_BIAS_PRIME: model_read_addr = layer_bias_offset +
                (((layer_op == OP_FC) ? fc_output : out_c) << 2);
            ST_BIAS_FETCH: model_read_addr = layer_bias_offset +
                ((((layer_op == OP_FC) ? fc_output : out_c) << 2) + bias_lane + 1'b1);
            ST_WEIGHT_PRIME: begin
                if (layer_op == OP_FC)
                model_read_addr = layer_weight_offset +
                        mul_u32_u16_no_dsp(fc_output[15:0], layer_in_c);
                else
                    model_read_addr = layer_weight_offset +
                        mul_u32_u16_no_dsp(out_c[15:0], layer_kernel_size);
            end
            ST_CONV_MAC: model_read_addr = layer_weight_offset +
                mul_u32_u16_no_dsp(out_c[15:0], layer_kernel_size) +
                kernel_index + 1;
            ST_FC_MAC: model_read_addr = layer_weight_offset +
                mul_u32_u16_no_dsp(fc_output[15:0], layer_in_c) + fc_index + 1;
            default: model_read_addr = 0;
        endcase
    end

    always @(posedge clk)
        model_read_data <= model_mem[model_read_addr];

    // Each tensor bank has one synchronous read port and one serialized write
    // port.  In particular, all operators share this address mux; separate
    // asynchronous tensor_read() calls made PDS replicate the banks into
    // thousands of LUT RAMs and prevented placement.
    integer tensor_addr_index;
    reg [15:0] tensor_addr_ky, tensor_addr_kx, tensor_addr_ic;
    reg [15:0] tensor_addr_y, tensor_addr_x;
    reg [15:0] tensor_addr_kern_off, tensor_addr_ic_off;
    always @* begin
        tensor_read_addr = 0;
        tensor_addr_index = 0;
        tensor_addr_ky = 0;
        tensor_addr_kx = 0;
        tensor_addr_ic = 0;
        tensor_addr_y = 0;
        tensor_addr_x = 0;
        tensor_addr_kern_off = 0;
        tensor_addr_ic_off = 0;
        case (state)
            ST_WEIGHT_PRIME, ST_CONV_MAC: begin
                if (layer_op == OP_FC) begin
                    tensor_read_addr = (state == ST_WEIGHT_PRIME) ? fc_index : fc_index + 1;
                end else begin
                    tensor_addr_ky = conv_ky_reg;
                    tensor_addr_kx = conv_kx_reg;
                    tensor_addr_ic = conv_ic_reg;
                    tensor_addr_kern_off = conv_kern_off;
                    tensor_addr_ic_off = conv_ic_off;
                    // The synchronous tensor BRAM returns the address
                    // presented in the preceding cycle.  During MAC, point
                    // it at the next kernel element while the FSM consumes
                    // the current one.  Only precomputed strides are added
                    // here; the two products that used to be on this path
                    // (y*W and ic*H*W) are now registered offsets.
                    if (state == ST_CONV_MAC &&
                        kernel_index != layer_kernel_size_m1) begin
                        if (conv_ic_reg == layer_in_c_m1) begin
                            tensor_addr_ic = 0;
                            tensor_addr_ic_off = 0;
                            if (conv_kx_reg == layer_kw_m1) begin
                                tensor_addr_kx = 0;
                                tensor_addr_ky = conv_ky_reg + 16'd1;
                                tensor_addr_kern_off = conv_kern_off +
                                                       layer_kern_wrap;
                            end else begin
                                tensor_addr_kx = conv_kx_reg + 16'd1;
                                tensor_addr_kern_off = conv_kern_off +
                                                       layer_kern_step;
                            end
                        end else begin
                            tensor_addr_ic = conv_ic_reg + 16'd1;
                            tensor_addr_ic_off = conv_ic_off + layer_ic_stride;
                        end
                    end
                    tensor_addr_y = pix_base_y + tensor_addr_ky;
                    tensor_addr_x = pix_base_x + tensor_addr_kx;
                    // Zero padding: a tap outside the input tensor reads
                    // address 0 and its product is forced to zero.
                    if (!tensor_addr_y[15] && tensor_addr_y < layer_in_h &&
                        !tensor_addr_x[15] && tensor_addr_x < layer_in_w)
                        tensor_read_addr = pix_origin_a + tensor_addr_kern_off +
                                           tensor_addr_ic_off;
                end
            end
            ST_FC_MAC: tensor_read_addr = fc_index + 1;
            ST_RELU_PRIME: tensor_read_addr = tensor_index;
            ST_RELU: tensor_read_addr = tensor_index + 1;
            ST_POOL_PRIME, ST_POOL: begin
                tensor_addr_ky = pool_ky_reg;
                tensor_addr_kx = pool_kx_reg;
                tensor_addr_kern_off = pool_kern_off;
                tensor_addr_ic_off = pool_ic_off;
                if (state == ST_POOL && pool_index != layer_kh_kw_m1) begin
                    if (pool_kx_reg == layer_kw_m1) begin
                        tensor_addr_kx = 0;
                        tensor_addr_ky = pool_ky_reg + 16'd1;
                        tensor_addr_kern_off = pool_kern_off + layer_kern_wrap;
                    end else begin
                        tensor_addr_kx = pool_kx_reg + 16'd1;
                        tensor_addr_kern_off = pool_kern_off + layer_kern_step;
                    end
                end
                tensor_addr_y = pix_base_y + tensor_addr_ky;
                tensor_addr_x = pix_base_x + tensor_addr_kx;
                if (!tensor_addr_y[15] && tensor_addr_y < layer_in_h &&
                    !tensor_addr_x[15] && tensor_addr_x < layer_in_w)
                    tensor_read_addr = pix_origin_a + tensor_addr_kern_off +
                                       tensor_addr_ic_off;
            end
            ST_GAP_PRIME, ST_GAP: begin
                tensor_addr_index = (state == ST_GAP_PRIME) ? gap_position : gap_position + 1;
                if (model_layout_reg == LAYOUT_HWC4)
                    tensor_read_addr = mul_u16_no_dsp(tensor_addr_index[15:0],
                                                      layer_in_c) + gap_channel;
                else
                    tensor_read_addr = mul_u16_no_dsp(gap_channel[15:0],
                                                      layer_hw) + tensor_addr_index;
            end
            ST_ARGMAX_PRIME: tensor_read_addr = arg_index;
            ST_ARGMAX: tensor_read_addr = arg_index + 1;
            default: tensor_read_addr = 0;
        endcase
    end

    // The bounds decision above belongs to the element whose data appears on
    // the next cycle, which is exactly the element the MAC/pool stage consumes.
    // Registering it removes a second copy of the bounds cone from the
    // mac_product zeroing path.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tensor_valid_q <= 1'b0;
        else if (state == ST_WEIGHT_PRIME || state == ST_CONV_MAC ||
                 state == ST_POOL_PRIME || state == ST_POOL)
            tensor_valid_q <= (!tensor_addr_y[15] &&
                               tensor_addr_y < layer_in_h &&
                               !tensor_addr_x[15] &&
                               tensor_addr_x < layer_in_w);
    end

    always @(posedge clk) begin
        if (tensor_write_enable && !tensor_write_slot)
            tensor_a[tensor_write_addr] <= tensor_write_data;
        if (tensor_write_enable && tensor_write_slot)
            tensor_b[tensor_write_addr] <= tensor_write_data;
        tensor_a_read_data <= tensor_a[tensor_read_addr];
        tensor_b_read_data <= tensor_b[tensor_read_addr];
    end

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
            conv_ky_reg <= 0; conv_kx_reg <= 0; conv_ic_reg <= 0;
            pool_ky_reg <= 0; pool_kx_reg <= 0;
            layer_in_c_m1 <= 0; layer_kw_m1 <= 0;
            layer_out_w_m1 <= 0; layer_out_h_m1 <= 0; layer_out_c_m1 <= 0;
            layer_hw <= 0; layer_kh_kw_m1 <= 0;
            layer_kernel_size_m1 <= 0; layer_kernel_size <= 0;
            layer_elements <= 0;
            layer_out_elements <= 0; layer_conv_weight_req <= 0;
            layer_fc_weight_req <= 0; layer_out_hw <= 0;
            d1_hw <= 0; d1_ohw <= 0; d1_khkw <= 0;
            d1_wc <= 0; d1_ptw <= 0; d1_plc <= 0; d1_kw1 <= 0;
            layer_ic_stride <= 0;
            layer_kern_step <= 1; layer_kern_wrap <= 0;
            layer_pix_step_x <= 0; layer_row_step <= 0;
            layer_row_step_padl <= 0; layer_row0_a <= 0;
            layer_row_a0 <= 0;
            layer_neg_pad_top <= 0; layer_neg_pad_left <= 0;
            pix_base_y <= 0; pix_base_x <= 0;
            pix_row_a <= 0; pix_origin_a <= 0;
            conv_kern_off <= 0; conv_ic_off <= 0;
            pool_kern_off <= 0; pool_ic_off <= 0;
            // tensor_valid_q is reset in its own always block below.
            arg_index <= 0;
            accumulator <= 0; pool_value <= 0; gap_accumulator <= 0;
            mac_product <= 0; mac_product_valid <= 1'b0;
            gap_divisor <= 0; gap_dividend <= 0; gap_quotient <= 0;
            gap_remainder <= 0; gap_div_bit <= 0;
            gap_div_negative <= 0;
            best_score <= 0; second_score <= 0; best_class <= 0;
        end else begin
            done_pulse <= 1'b0;
            tensor_write_enable <= 1'b0;
            model_cache_hit <= 1'b0;
            model_cache_valid <= model_cache_valid_reg;
            if (clear_error) error <= 1'b0;

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
                    source_offset = read_offset + ({27'b0, read_beat_index} << 5) + unpack_lane;
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
                        if (input_store_valid) begin
                            tensor_write_enable <= 1'b1;
                            tensor_write_slot <= 1'b0;
                            tensor_write_addr <= tensor_write_index;
                            tensor_write_data <= read_beat_data[({27'b0, unpack_lane} << 3) +: 8];
                        end
                    end else if (source_offset < MAX_MODEL_BYTES) begin
                        model_mem[source_offset] <= read_beat_data[({27'b0, unpack_lane} << 3) +: 8];
                        if (source_offset < HEADER_BYTES)
                            model_header_mem[source_offset] <= read_beat_data[({27'b0, unpack_lane} << 3) +: 8];
                    end

                    if (unpack_lane == 5'd31) begin
                        if (read_beat_last) begin
                            if (read_beat_index != burst_beats - 1'b1 ||
                                read_error_seen) begin
                                busy <= 1'b0;
                                error <= 1'b1;
                                error_code <= read_error_seen ? read_error_code : ERR_AXI_RLAST;
                                done_pulse <= 1'b1;
                                state <= ST_IDLE;
                            end else if (read_remaining_beats == burst_beats) begin
                                if (read_target_input) begin
                                    state <= ST_DESC_PRIME;
                                end else begin
                                    crc_index <= HEADER_BYTES;
                                    crc_reg <= 32'hffff_ffff;
                                    state <= ST_CRC_PRIME;
                                end
                            end else begin
                                read_addr_reg <= read_addr_reg + ({27'b0, burst_beats} << 5);
                                read_remaining_beats <= read_remaining_beats - burst_beats;
                                read_offset <= read_offset + ({27'b0, burst_beats} << 5);
                                burst_beats <= calc_burst(read_remaining_beats - burst_beats,
                                                          read_addr_reg + ({27'b0, burst_beats} << 5));
                                state <= ST_READ_AR;
                            end
                        end else if (read_beat_index == burst_beats - 1'b1) begin
                            read_error_seen <= 1'b1;
                            read_error_code <= ERR_AXI_RLAST;
                            drain_wait_count <= 0;
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
                        if (axi_rlast) begin
                            busy <= 1'b0;
                            error <= 1'b1;
                            error_code <= read_error_code;
                            done_pulse <= 1'b1;
                            state <= ST_IDLE;
                        end
                    end else if (drain_wait_count >= DRAIN_TIMEOUT_LIMIT) begin
                        busy <= 1'b0;
                        error <= 1'b1;
                        error_code <= read_error_code;
                        done_pulse <= 1'b1;
                        state <= ST_IDLE;
                    end else begin
                        drain_wait_count <= drain_wait_count + 1'b1;
                    end
                end

                ST_CRC_PRIME: state <= ST_CRC;

                ST_CRC: begin
                    if (crc_index < model_bytes_reg) begin
                        // model_mem stores signed INT8 for MAC operations;
                        // CRC consumes the raw byte and must not sign-extend
                        // weights/bias bytes above 0x7f.
                        crc_reg <= crc32_byte(crc_reg, model_read_data[7:0]);
                        if (crc_index == model_bytes_reg - 1) begin
                            if (~crc32_byte(crc_reg, model_read_data[7:0]) != model_u32(64)) begin
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
                                 (model_header_mem[18] != LAYOUT_CHW && model_header_mem[18] != LAYOUT_HWC4) ||
                                 (model_header_mem[18] == LAYOUT_HWC4 && model_u16(16) != 4) ||
                                 model_header_mem[19] != 1 || model_header_mem[20] != 1 ||
                                 model_header_mem[21] == 0 || model_header_mem[22] == 0 || model_header_mem[21] > MAX_LAYERS ||
                                 model_header_mem[22] > MAX_CLASSES || model_u32(48) != model_bytes_reg ||
                                 !header_reserved_zero(1'b0) ||
                                 model_u32(24) != HEADER_BYTES ||
                                 model_u32(28) < ({24'b0, model_header_mem[21]} << 6) ||
                                 header_desc_end[32] || header_desc_end > {1'b0, model_bytes_reg} ||
                                 (model_u32(24) % 32) != 0 ||
                                 (model_u32(32) % 32) != 0 ||
                                 (model_u32(40) % 32) != 0 ||
                                 {1'b0, model_u32(32)} < header_desc_end ||
                                 {1'b0, model_u32(40)} < header_weight_end ||
                                 header_weight_end[32] || header_weight_end > {1'b0, model_bytes_reg} ||
                                 header_bias_end[32] || header_bias_end > {1'b0, model_bytes_reg} ||
                                 model_u32(52) == 0 || (model_u32(52) % 32) != 0 ||
                                 model_u32(52) > MAX_SCRATCH_BYTES ||
                                 model_u32(56) != input_bytes_reg ||
                                 model_u32(56) == 0 || (model_u32(56) % 32) != 0 ||
                                 model_u32(60) < model_u32(56) || (model_u32(60) % 32) != 0) begin
                        error <= 1'b1; error_code <= ERR_MODEL_FORMAT;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (model_input_elements > input_bytes_reg) begin
                        error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
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
                        if ((descriptor_bits[0*8 +: 8] == OP_GAP) &&
                            (legacy_expected_scratch == 0)) begin
                            legacy_expected_scratch <=
                                ((mul_u32_u16_no_dsp(
                                    mul_u16_no_dsp(desc_u16(2), desc_u16(4)),
                                    desc_u16(6)) + 31) >> 5) << 6;
                        end
                        legacy_scan_index <= legacy_scan_index + 1'b1;
                        state <= (legacy_scan_index + 1'b1 >= layer_count_reg) ?
                                 ST_LEGACY_DONE : ST_DESC_PRIME;
                    end
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
                    burst_beats <= calc_burst(input_source_bytes_reg >> 5, input_addr_reg);
                    state <= ST_READ_AR;
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
                        // Stage 1 of dispatch: the descriptor is already
                        // resident in descriptor_bits, so the first-level
                        // products cost one multiplier tree here and are
                        // consumed in ST_DISPATCH.
                        d1_hw   <= ds_p_hw;
                        d1_ohw  <= ds_p_ohw;
                        d1_khkw <= ds_p_khkw;
                        d1_wc   <= ds_p_wc;
                        d1_ptw  <= ds_p_ptw;
                        d1_plc  <= ds_p_plc;
                        d1_kw1  <= ds_p_kw1;
                        state <= ST_DISPATCH;
                    end
                end

                ST_DISPATCH: begin
                    // ---- Per-layer constants, latched once per layer --------
                    // Stage 2 of dispatch.  Every assignment below ends a
                    // multiplier tree at a flip-flop, so the tree output no
                    // longer feeds a clock enable.  The loads are
                    // unconditional: ST_CHECK decides whether the layer may
                    // run, and a rejected layer drops to ST_IDLE where the
                    // next start re-initialises every register it touches.
                    layer_in_c_m1  <= layer_in_c - 16'd1;
                    layer_kw_m1    <= layer_kw - 8'd1;
                    layer_out_w_m1 <= layer_out_w - 16'd1;
                    layer_out_h_m1 <= layer_out_h - 16'd1;
                    layer_out_c_m1 <= layer_out_c - 16'd1;
                    layer_hw       <= d1_hw[15:0];
                    layer_out_hw   <= disp_out_hw;
                    layer_kh_kw_m1 <= d1_khkw - 16'd1;
                    layer_kernel_size_m1 <= disp_kernel_size - 32'd1;
                    layer_kernel_size    <= disp_kernel_size;
                    layer_elements       <= disp_elements;
                    layer_out_elements   <= disp_out_elements;
                    layer_conv_weight_req <= disp_conv_weight_req;
                    layer_fc_weight_req   <= disp_fc_weight_req;
                    layer_ic_stride <= (model_layout_reg == LAYOUT_HWC4) ?
                                       16'd1 : d1_hw[15:0];
                    layer_kern_step <= disp_c_scale;
                    layer_kern_wrap <= disp_kern_wrap;
                    layer_pix_step_x <= disp_pix_step_x;
                    layer_row_step   <= disp_row_step;
                    layer_row_step_padl <= disp_row_step - d1_plc;
                    layer_neg_pad_top  <= 16'd0 - {8'b0, layer_pad_top};
                    layer_neg_pad_left <= 16'd0 - {8'b0, layer_pad_left};
                    layer_row_a0 <= 16'd0 - disp_row0_a;
                    layer_row0_a <= 16'd0 - (disp_row0_a + d1_plc);
                    // Restart the window at the padding origin of the layer.
                    pix_base_y   <= 16'd0 - {8'b0, layer_pad_top};
                    pix_base_x   <= 16'd0 - {8'b0, layer_pad_left};
                    pix_row_a    <= 16'd0 - disp_row0_a;
                    pix_origin_a <= 16'd0 - (disp_row0_a + d1_plc);
                    conv_kern_off <= 0; conv_ic_off <= 0;
                    pool_kern_off <= 0; pool_ic_off <= 0;
                    state <= ST_CHECK;
                end

                ST_CHECK: begin
                    // Stage 3 of dispatch.  Comparisons only: nothing here is
                    // written except control flops, so the thirty-term
                    // predicate no longer gates any data register.  The wide
                    // comparisons keep the original signedness: the products
                    // were `integer` locals before they became registers.
                    if (layer_op != OP_CONV2D && layer_op != OP_RELU &&
                        layer_op != OP_MAXPOOL && layer_op != OP_GAP &&
                        layer_op != OP_FC && layer_op != OP_ARGMAX) begin
                        error <= 1'b1; error_code <= ERR_UNSUPPORTED_OP;
                        busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                    end else if (layer_in_h == 0 || layer_in_w == 0 || layer_in_c == 0 ||
                                 layer_out_h == 0 || layer_out_w == 0 || layer_out_c == 0 ||
                                 layer_in_h != expected_in_h || layer_in_w != expected_in_w ||
                                 layer_in_c != expected_in_c ||
                                 $signed(layer_elements) > MAX_TENSOR_BYTES ||
                                 $signed(layer_out_elements) > MAX_TENSOR_BYTES ||
                                 ((!legacy_model_encoding_valid) &&
                                  model_u32(52) < (layer_out_elements << 1)) ||
                                 desc_u32(24) != 0 ||
                                 desc_u32(28) != 0 ||
                                 !descriptor_reserved_compatible(1'b0) ||
                                 layer_shift > 31 ||
                                 (layer_weight_bytes != 0 && layer_weight_offset[4:0] != 0) ||
                                 (layer_bias_bytes != 0 && layer_bias_offset[4:0] != 0) ||
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
                        if (layer_multiplier != 32'sd1 ||
                            layer_input_zp != 8'sd0 ||
                            layer_weight_zp != 8'sd0 ||
                            layer_output_zp != 8'sd0) begin
                            error <= 1'b1; error_code <= ERR_MODEL_QUANT;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else if (layer_kh == 0 || layer_kw == 0 || layer_sh == 0 || layer_sw == 0 ||
                            layer_weight_bytes < layer_conv_weight_req ||
                            layer_bias_bytes < ({16'b0, layer_out_c} << 2) ||
                            !shape_dimension_valid(layer_in_h, layer_out_h, layer_kh,
                                layer_sh, layer_pad_top, layer_pad_bottom) ||
                            !shape_dimension_valid(layer_in_w, layer_out_w, layer_kw,
                                layer_sw, layer_pad_left, layer_pad_right)) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                            out_x <= 0; out_y <= 0; out_c <= 0; kernel_index <= 0;
                            conv_ky_reg <= 0; conv_kx_reg <= 0; conv_ic_reg <= 0;
                            state <= ST_BIAS_PRIME;
                        end
                    end else if (layer_op == OP_RELU) begin
                        tensor_index <= 0;
                        state <= ST_RELU_PRIME;
                    end else if (layer_op == OP_MAXPOOL) begin
                        if (layer_kh == 0 || layer_kw == 0 || layer_sh == 0 || layer_sw == 0 ||
                            layer_out_c != layer_in_c ||
                            !shape_dimension_valid(layer_in_h, layer_out_h, layer_kh,
                                layer_sh, 8'b0, 8'b0) ||
                            !shape_dimension_valid(layer_in_w, layer_out_w, layer_kw,
                                layer_sw, 8'b0, 8'b0)) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                            out_x <= 0; out_y <= 0; out_c <= 0; pool_index <= 0;
                            pool_ky_reg <= 0; pool_kx_reg <= 0;
                            pool_value <= -8'sd128;
                            state <= ST_POOL_PRIME;
                        end
                    end else if (layer_op == OP_GAP) begin
                        if (((layer_flags & FLAG_GAP_ROUND4) != 0) &&
                            (layer_in_h != 4 || layer_in_w != 4) ||
                            layer_out_h != 1 || layer_out_w != 1 || layer_out_c != layer_in_c) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                            gap_channel <= 0; gap_position <= 0; gap_accumulator <= 0;
                            gap_divisor <= d1_hw[15:0];
                            state <= ST_GAP_PRIME;
                        end
                    end else if (layer_op == OP_FC) begin
                        if (layer_in_h != 1 || layer_in_w != 1 ||
                            layer_weight_bytes < layer_fc_weight_req ||
                            layer_bias_bytes < ({16'b0, layer_out_c} << 2)) begin
                            error <= 1'b1; error_code <= ERR_MODEL_SHAPE;
                            busy <= 1'b0; done_pulse <= 1'b1; state <= ST_IDLE;
                        end else begin
                        fc_output <= 0; fc_index <= 0;
                        state <= ST_BIAS_PRIME;
                        end
                    end else begin
                        arg_index <= 0;
                        best_score <= -32'sh7fff_ffff;
                        second_score <= -32'sh7fff_ffff;
                        best_class <= 0;
                        state <= ST_ARGMAX_PRIME;
                    end
                end

                ST_BIAS_PRIME: begin
                    bias_lane <= 0;
                    state <= ST_BIAS_FETCH;
                end

                ST_BIAS_FETCH: begin
                    if (bias_lane == 2'd3) begin
                        accumulator <= {model_read_data[7:0], bias_low_bytes};
                        state <= ST_WEIGHT_PRIME;
                    end else begin
                        bias_low_bytes[(({30'b0, bias_lane} << 3)) +: 8] <= model_read_data[7:0];
                        bias_lane <= bias_lane + 1'b1;
                    end
                end

                ST_WEIGHT_PRIME: begin
                    // The first MAC issue cycle only fills the product
                    // register.  Later issue cycles overlap multiplication
                    // with accumulation of the preceding product.
                    mac_product_valid <= 1'b0;
                    if (layer_op == OP_FC) state <= ST_FC_MAC;
                    else state <= ST_CONV_MAC;
                end

                ST_RELU_PRIME: state <= ST_RELU;
                ST_POOL_PRIME: state <= ST_POOL;
                ST_GAP_PRIME: state <= ST_GAP;
                ST_ARGMAX_PRIME: state <= ST_ARGMAX;
                ST_WRITE_DRAIN: state <= ST_LAYER_NEXT;

                ST_CONV_MAC: begin
                    next_accumulator = accumulator;
                    if (mac_product_valid)
                        next_accumulator = accumulator + mac_product;
                    accumulator <= next_accumulator;

                    // Issue the current BRAM operands into the product
                    // register.  Address generation continues to advance
                    // below, so this remains one MAC issue per clock after
                    // the one-cycle pipeline fill.  tensor_valid_q is the
                    // in-bounds decision the address stage already made when
                    // it presented this element, so the bounds cone is not
                    // duplicated here.
                    if (tensor_valid_q)
                        mac_product <=
                            (sign_extend_i8_32(tensor_read_data) -
                             sign_extend_i8_32(layer_input_zp)) *
                            (sign_extend_i8_32(model_read_data) -
                             sign_extend_i8_32(layer_weight_zp));
                    else
                        mac_product <= 0;
                    mac_product_valid <= 1'b1;

                    if (kernel_index == layer_kernel_size_m1) begin
                        kernel_index <= 0;
                        state <= ST_CONV_MAC_FLUSH;
                    end else begin
                        kernel_index <= kernel_index + 1;
                        if (conv_ic_reg == layer_in_c_m1) begin
                            conv_ic_reg <= 0;
                            conv_ic_off <= 0;
                            if (conv_kx_reg == layer_kw_m1) begin
                                conv_kx_reg <= 0;
                                conv_ky_reg <= conv_ky_reg + 1'b1;
                                conv_kern_off <= conv_kern_off +
                                                 layer_kern_wrap;
                            end else begin
                                conv_kx_reg <= conv_kx_reg + 1'b1;
                                conv_kern_off <= conv_kern_off +
                                                 layer_kern_step;
                            end
                        end else begin
                            conv_ic_reg <= conv_ic_reg + 1'b1;
                            conv_ic_off <= conv_ic_off + layer_ic_stride;
                        end
                    end
                end

                ST_CONV_MAC_FLUSH: begin
                    // Retire the product issued on the final MAC cycle.
                    accumulator <= accumulator + mac_product;
                    state <= ST_CONV_WRITE;
                end

                ST_CONV_WRITE: begin
                    if (model_layout_reg == LAYOUT_HWC4)
                        tensor_write_index = mul_u32_u16_no_dsp(
                            mul_u32_u16_no_dsp(out_y[15:0], layer_out_w) + out_x,
                            layer_out_c) + out_c;
                    else
                        tensor_write_index = mul_u32_u16_no_dsp(out_c[15:0],
                            layer_out_hw) +
                            mul_u32_u16_no_dsp(out_y[15:0], layer_out_w) + out_x;
                    tensor_write_enable <= 1'b1;
                    tensor_write_slot <= ~tensor_active;
                    tensor_write_addr <= tensor_write_index;
                    tensor_write_data <= requantize_direct(accumulator, layer_shift,
                                                           layer_output_zp, layer_flags[0]);
                    conv_ky_reg <= 0;
                    conv_kx_reg <= 0;
                    conv_ic_reg <= 0;
                    conv_kern_off <= 0;
                    conv_ic_off <= 0;
                    // Advance the window origin without any multiply: every
                    // stride involved is a per-layer constant.
                    if (out_x == layer_out_w_m1) begin
                        out_x <= 0;
                        pix_base_x <= layer_neg_pad_left;
                        if (out_y == layer_out_h_m1) begin
                            out_y <= 0;
                            pix_base_y <= layer_neg_pad_top;
                            pix_row_a <= layer_row_a0;
                            pix_origin_a <= layer_row0_a;
                            if (out_c == layer_out_c_m1)
                                state <= ST_WRITE_DRAIN;
                            else begin
                                out_c <= out_c + 1;
                                state <= ST_BIAS_PRIME;
                            end
                        end else begin
                            out_y <= out_y + 1;
                            pix_base_y <= pix_base_y + {8'b0, layer_sh};
                            pix_row_a <= pix_row_a + layer_row_step;
                            pix_origin_a <= pix_row_a + layer_row_step_padl;
                            state <= ST_BIAS_PRIME;
                        end
                    end else begin
                        out_x <= out_x + 1;
                        pix_base_x <= pix_base_x + {8'b0, layer_sw};
                        pix_origin_a <= pix_origin_a + layer_pix_step_x;
                        state <= ST_BIAS_PRIME;
                    end
                end

                ST_RELU: begin
                    if (tensor_index < layer_elements) begin
                        tensor_write_enable <= 1'b1;
                        tensor_write_slot <= ~tensor_active;
                        tensor_write_addr <= tensor_index;
                        tensor_write_data <= (tensor_read_data < layer_output_zp) ?
                                             layer_output_zp : tensor_read_data;
                        tensor_index <= tensor_index + 1;
                    end else begin
                        state <= ST_LAYER_NEXT;
                    end
                end

                ST_POOL: begin
                    pool_next = pool_value;
                    if (tensor_valid_q) begin
                        if (tensor_read_data > pool_next)
                            pool_next = tensor_read_data;
                    end
                    if (pool_index == layer_kh_kw_m1) begin
                        if (model_layout_reg == LAYOUT_HWC4)
                            tensor_write_index = mul_u32_u16_no_dsp(
                                mul_u32_u16_no_dsp(out_y[15:0], layer_out_w) + out_x,
                                layer_out_c) + out_c;
                        else
                            tensor_write_index = mul_u32_u16_no_dsp(out_c[15:0],
                                layer_out_hw) +
                                mul_u32_u16_no_dsp(out_y[15:0], layer_out_w) + out_x;
                        tensor_write_enable <= 1'b1;
                        tensor_write_slot <= ~tensor_active;
                        tensor_write_addr <= tensor_write_index;
                        tensor_write_data <= pool_next;
                        pool_index <= 0;
                        pool_ky_reg <= 0;
                        pool_kx_reg <= 0;
                        pool_kern_off <= 0;
                        pool_value <= -8'sd128;
                        if (out_x == layer_out_w_m1) begin
                            out_x <= 0;
                            pix_base_x <= layer_neg_pad_left;
                            if (out_y == layer_out_h_m1) begin
                                out_y <= 0;
                                pix_base_y <= layer_neg_pad_top;
                                pix_row_a <= layer_row_a0;
                                pix_origin_a <= layer_row0_a;
                                if (out_c == layer_out_c_m1) state <= ST_WRITE_DRAIN;
                                else begin
                                    out_c <= out_c + 1;
                                    pool_ic_off <= pool_ic_off +
                                                   layer_ic_stride;
                                    state <= ST_POOL_PRIME;
                                end
                            end else begin
                                out_y <= out_y + 1;
                                pix_base_y <= pix_base_y + {8'b0, layer_sh};
                                pix_row_a <= pix_row_a + layer_row_step;
                                pix_origin_a <= pix_row_a + layer_row_step_padl;
                                state <= ST_POOL_PRIME;
                            end
                        end else begin
                            out_x <= out_x + 1;
                            pix_base_x <= pix_base_x + {8'b0, layer_sw};
                            pix_origin_a <= pix_origin_a + layer_pix_step_x;
                            state <= ST_POOL_PRIME;
                        end
                    end else begin
                        // Keep the running maximum across all elements of
                        // this pooling window.  Without this assignment the
                        // next cycle starts from the previous window value
                        // only through the temporary pool_next, so a 2x2
                        // window can lose an earlier larger element.
                        pool_value <= pool_next;
                        pool_index <= pool_index + 1;
                        if (pool_kx_reg == layer_kw_m1) begin
                            pool_kx_reg <= 0;
                            pool_ky_reg <= pool_ky_reg + 1'b1;
                            pool_kern_off <= pool_kern_off + layer_kern_wrap;
                        end else begin
                            pool_kx_reg <= pool_kx_reg + 1'b1;
                            pool_kern_off <= pool_kern_off + layer_kern_step;
                        end
                    end
                end

                ST_GAP: begin
                    if (model_layout_reg == LAYOUT_HWC4)
                        tensor_read_index = mul_u32_u16_no_dsp(
                            gap_position[15:0], layer_in_c) + gap_channel;
                    else
                        tensor_read_index = mul_u16_no_dsp(gap_channel[15:0],
                            layer_hw) + gap_position;
                    next_gap_accumulator = gap_accumulator +
                        sign_extend_i8_32(tensor_read_data);
                    gap_accumulator <= next_gap_accumulator;
                    if (gap_position == layer_hw - 1) begin
                        gap_position <= 0;
                        gap_accumulator <= 0;
                        if ((layer_flags & FLAG_GAP_ROUND4) != 0) begin
                            tensor_write_enable <= 1'b1;
                            tensor_write_slot <= ~tensor_active;
                            tensor_write_addr <= gap_channel;
                            tensor_write_data <= clamp_i8(
                                ({{32{next_gap_accumulator[31]}}, next_gap_accumulator} +
                                 64'sd8) >>> 4);
                            if (gap_channel == layer_out_c - 1)
                                state <= ST_WRITE_DRAIN;
                            else begin
                                gap_channel <= gap_channel + 1;
                                state <= ST_GAP_PRIME;
                            end
                        end else begin
                            gap_div_negative <= next_gap_accumulator[31];
                            gap_dividend <= next_gap_accumulator[31] ?
                                (~next_gap_accumulator + 1'b1) : next_gap_accumulator;
                            gap_quotient <= 0;
                            gap_remainder <= 0;
                            gap_div_bit <= 6'd31;
                            state <= ST_GAP_DIV;
                        end
                    end else gap_position <= gap_position + 1;
                end

                ST_GAP_DIV: begin
                    gap_div_trial = {gap_remainder, gap_dividend[31]};
                    gap_div_subtracted = gap_div_trial - {1'b0, gap_divisor};
                    gap_div_quotient_next = {gap_quotient[30:0], !gap_div_subtracted[17]};
                    gap_dividend <= {gap_dividend[30:0], 1'b0};
                    gap_quotient <= gap_div_quotient_next;
                    if (!gap_div_subtracted[17])
                        gap_remainder <= gap_div_subtracted[16:0];
                    else
                        gap_remainder <= gap_div_trial[16:0];
                    if (gap_div_bit == 0) begin
                        tensor_write_enable <= 1'b1;
                        tensor_write_slot <= ~tensor_active;
                        tensor_write_addr <= gap_channel;
                        tensor_write_data <= clamp_i8(gap_div_negative ?
                            -$signed({1'b0, gap_div_quotient_next}) :
                             $signed({1'b0, gap_div_quotient_next}));
                        if (gap_channel == layer_out_c - 1) state <= ST_WRITE_DRAIN;
                        else begin
                            gap_channel <= gap_channel + 1;
                            gap_position <= 0;
                            gap_accumulator <= 0;
                            state <= ST_GAP_PRIME;
                        end
                    end else begin
                        gap_div_bit <= gap_div_bit - 1'b1;
                    end
                end

                ST_FC_MAC: begin
                    fc_input_index = fc_index;
                    fc_weight_index = mul_u32_u16_no_dsp(fc_output[15:0], layer_in_c) + fc_index;
                    next_accumulator = accumulator;
                    if (mac_product_valid)
                        next_accumulator = accumulator + mac_product;
                    accumulator <= next_accumulator;
                    mac_product <=
                        (sign_extend_i8_32(tensor_read_data) -
                         sign_extend_i8_32(layer_input_zp)) *
                        (sign_extend_i8_32(model_read_data) -
                         sign_extend_i8_32(layer_weight_zp));
                    mac_product_valid <= 1'b1;
                    if (fc_index == layer_in_c - 1) begin
                        fc_index <= 0;
                        state <= ST_FC_MAC_FLUSH;
                    end else begin
                        fc_index <= fc_index + 1;
                    end
                end

                ST_FC_MAC_FLUSH: begin
                    // Retire the last FC product before publishing the
                    // complete logit to the argmax stage.
                    next_accumulator = accumulator + mac_product;
                    accumulator <= next_accumulator;
                    fc_output_mem[fc_output] <= next_accumulator[31:0];
                    if (fc_output == layer_out_c - 1)
                        state <= ST_LAYER_NEXT;
                    else begin
                        fc_output <= fc_output + 1;
                        state <= ST_BIAS_PRIME;
                    end
                end

                ST_ARGMAX: begin
                    tensor_read_index = arg_index;
                    if (argmax_from_fc)
                        candidate_score = fc_output_mem[arg_index];
                    else
                        candidate_score = tensor_read_data;
                    new_best_score = best_score;
                    new_second_score = second_score;
                    new_best_class = best_class;
                    if (candidate_score > best_score) begin
                        new_second_score = best_score;
                        new_best_score = candidate_score;
                        new_best_class = arg_index[7:0];
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
                    state <= ST_DESC_PRIME;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
