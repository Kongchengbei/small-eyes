`timescale 1ns / 1ps
`include "soc_addr_map.vh"

// ============================================================================
// Hnpu_system
//
// A-side integration boundary.  The service and its AXI master live in the
// DDR clock domain; the result FIFO and legacy CPU control register interface
// live in the CPU clock domain.  The batch interface is intentionally explicit:
// an upstream INT8 converter owns RGB565 conversion and presents one complete
// batch at a time.
//
// This module does not choose the final SoC AXI topology.  Its single AXI
// master is meant to connect to the future CPU/CAMERA/NPU arbiter, while the
// MMIO port is meant to connect to the existing backend decoder.
// ============================================================================
module Hnpu_system #(
    parameter [31:0] DDR_BASE = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES = `SOC_DDR_BYTES,
    parameter [31:0] NPU_MMIO_BASE = `SOC_NPU_MMIO_BASE,
    parameter [31:0] NPU_MMIO_BYTES = `SOC_NPU_MMIO_BYTES,
    parameter [7:0] AXI_ID = 8'h80,
    parameter integer QUEUE_DEPTH = 4,
    parameter integer RESULT_DEPTH = 16,
    parameter integer RESULT_FIFO_DEPTH = 8,
    parameter integer MAX_ROIS = 8,
    parameter integer MAX_FEATURES = 1024,
    parameter integer MAX_CLASSES = 11,
    parameter integer ENGINE_MODE = 0,
    parameter integer MAX_MODEL_BYTES = 65536,
    parameter integer IMAGE_MODE = 0,
    parameter [31:0] MODEL_BASE = 32'h0000_0000,
    parameter [31:0] MODEL_BYTES = 32'h0000_0000
) (
    input ddr_clk,
    input cpu_clk,
    input rst_n,

    input enable,
    input clear_errors,
    input stop,

    input batch_valid,
    output wire batch_ready,
    input [7:0] batch_camera,
    input [31:0] batch_frame,
    input batch_bank,
    input [31:0] batch_input_base,
    input [31:0] batch_input_stride,
    input [31:0] batch_input_bytes,
    input [15:0] batch_feature_count,
    input [31:0] batch_weight_base,
    input [31:0] batch_weight_stride,
    input [31:0] batch_bias_base,
    input [31:0] batch_model_base,
    input [31:0] batch_model_bytes,
    input [7:0] batch_count,
    input [7:0] batch_class_count,
    input [5:0] batch_quant_shift,
    input [MAX_ROIS*64-1:0] batch_boxes,
    input [MAX_ROIS*3-1:0] batch_colors,

    input [1:0] image_valid,
    output wire [1:0] image_ready,
    input [15:0] image_camera,
    input [63:0] image_frame,
    input [15:0] image_batch_count,
    input [15:0] image_index,
    input [127:0] image_box,
    input [5:0] image_color,
    input [3:0] image_block,
    input [7:0] image_position,
    input [63:0] image_generation,
    input [63:0] image_data_addr,
    input [31:0] image_width,
    input [31:0] image_height,
    input [63:0] image_data_bytes,

    output wire int8_release_valid,
    output wire int8_release_bank,
    output wire [31:0] int8_release_frame,
    output wire [1:0] image_release_valid,
    input [1:0] image_release_ready,
    output wire [15:0] image_release_camera,
    output wire [63:0] image_release_frame,
    output wire [3:0] image_release_block,
    output wire [7:0] image_release_position,
    output wire [63:0] image_release_generation,
    output wire busy,
    output wire error,
    output wire [7:0] error_code,
    output wire [31:0] accepted_batches,
    output wire [31:0] completed_batches,
    output wire [31:0] dropped_batches,
    output wire [31:0] completed_rois,
    output wire [31:0] error_rois,
    output wire [31:0] released_banks,
    output wire [31:0] fifo_overflows,
    output wire result_reject,

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
    output wire axi_rready,

    input mmio_valid,
    input mmio_wen,
    input [31:0] mmio_addr,
    input [31:0] mmio_wdata,
    input [3:0] mmio_wstrb,
    output wire mmio_ready,
    output wire [31:0] mmio_rdata,
    output wire irq,

    output wire start_pulse,
    input control_engine_done,
    output wire [31:0] control_input_addr,
    output wire [31:0] control_weight_addr,
    output wire [31:0] control_output_addr,
    output wire [31:0] control_task_bytes
);
    wire ctrl_addr_sel;
    wire ctrl_sel;
    wire ctrl_ready;
    wire [31:0] ctrl_rdata;
    wire ctrl_irq;
    wire result_sel = mmio_valid &&
                      (mmio_addr >= NPU_MMIO_BASE) &&
                      (mmio_addr < NPU_MMIO_BASE + NPU_MMIO_BYTES) &&
                      (mmio_addr[7:0] >= 8'h20) &&
                      (mmio_addr[7:0] <= 8'h50);
    wire ctrl_mmio_valid = mmio_valid && !result_sel;
    wire result_ready_mmio;
    wire [31:0] result_rdata;
    wire result_irq;
    wire result_overflow;
    wire [7:0] result_error_code;
    wire service_result_valid;
    wire service_result_ready;
    wire [255:0] service_result_record;

    Hnpu_ctrl #(
        .NPU_MMIO_BASE(NPU_MMIO_BASE),
        .NPU_MMIO_BYTES(NPU_MMIO_BYTES)
    ) u_ctrl (
        .clk(cpu_clk), .rst_n(rst_n),
        .mmio_valid(ctrl_mmio_valid), .mmio_wen(mmio_wen), .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata), .mmio_wstrb(mmio_wstrb),
        .mmio_addr_sel(ctrl_addr_sel), .mmio_sel(ctrl_sel),
        .mmio_ready(ctrl_ready), .mmio_rdata(ctrl_rdata),
        .start_pulse(start_pulse), .engine_done(control_engine_done),
        .engine_input_addr(control_input_addr),
        .engine_weight_addr(control_weight_addr),
        .engine_output_addr(control_output_addr),
        .engine_task_bytes(control_task_bytes), .irq(ctrl_irq)
    );

    generate
        if (IMAGE_MODE == 0) begin : g_batch_service
            Hnpu_service #(
                .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES), .AXI_ID(AXI_ID),
                .QUEUE_DEPTH(QUEUE_DEPTH), .RESULT_DEPTH(RESULT_DEPTH),
                .MAX_ROIS(MAX_ROIS), .MAX_FEATURES(MAX_FEATURES), .MAX_CLASSES(MAX_CLASSES),
                .ENGINE_MODE(ENGINE_MODE), .MAX_MODEL_BYTES(MAX_MODEL_BYTES)
            ) u_service (
                .clk(ddr_clk), .rst_n(rst_n), .enable(enable),
                .clear_errors(clear_errors), .stop(stop),
                .batch_valid(batch_valid), .batch_ready(batch_ready),
                .batch_camera(batch_camera), .batch_frame(batch_frame), .batch_bank(batch_bank),
                .batch_input_base(batch_input_base), .batch_input_stride(batch_input_stride),
                .batch_input_bytes(batch_input_bytes), .batch_feature_count(batch_feature_count),
                .batch_weight_base(batch_weight_base), .batch_weight_stride(batch_weight_stride),
                .batch_bias_base(batch_bias_base), .batch_count(batch_count),
                .batch_model_base(batch_model_base), .batch_model_bytes(batch_model_bytes),
                .batch_class_count(batch_class_count), .batch_quant_shift(batch_quant_shift),
                .batch_boxes(batch_boxes), .batch_colors(batch_colors),
                .result_valid(service_result_valid), .result_ready(service_result_ready),
                .result_camera(), .result_frame(), .result_bank(), .result_roi(),
                .result_box(), .result_color(), .result_class(), .result_confidence(),
                .result_score(), .result_reject(result_reject), .result_error(),
                .result_record(service_result_record),
                .int8_release_valid(int8_release_valid), .int8_release_bank(int8_release_bank),
                .int8_release_frame(int8_release_frame), .busy(busy), .error(error),
                .error_code(error_code), .accepted_batches(accepted_batches),
                .completed_batches(completed_batches), .dropped_batches(dropped_batches),
                .completed_rois(completed_rois), .error_rois(error_rois),
                .released_banks(released_banks), .fifo_overflows(fifo_overflows),
                .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
                .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
                .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
                .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
                .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready)
            );
            assign image_ready = 2'b00;
            assign image_release_valid = 2'b00;
            assign image_release_camera = 16'b0;
            assign image_release_frame = 64'b0;
            assign image_release_block = 4'b0;
            assign image_release_position = 8'b0;
            assign image_release_generation = 64'b0;
        end else begin : g_image_service
            Hnpu_image_service #(
                .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES), .AXI_ID(AXI_ID),
                .QUEUE_DEPTH(QUEUE_DEPTH * 2), .RESULT_DEPTH(RESULT_DEPTH),
                .MAX_CLASSES(MAX_CLASSES), .MODEL_BASE(MODEL_BASE),
                .MODEL_BYTES(MODEL_BYTES), .MAX_MODEL_BYTES(MAX_MODEL_BYTES)
            ) u_service (
                .clk(ddr_clk), .rst_n(rst_n), .enable(enable),
                .clear_errors(clear_errors), .stop(stop),
                .image_valid(image_valid), .image_ready(image_ready),
                .image_camera(image_camera), .image_frame(image_frame),
                .image_batch_count(image_batch_count), .image_index(image_index),
                .image_box(image_box), .image_color(image_color),
                .image_block(image_block), .image_position(image_position),
                .image_generation(image_generation), .image_data_addr(image_data_addr),
                .image_width(image_width), .image_height(image_height),
                .image_data_bytes(image_data_bytes),
                .release_valid(image_release_valid), .release_ready(image_release_ready),
                .release_camera(image_release_camera), .release_frame(image_release_frame),
                .release_block(image_release_block), .release_position(image_release_position),
                .release_generation(image_release_generation),
                .result_valid(service_result_valid), .result_ready(service_result_ready),
                .result_camera(), .result_frame(), .result_roi(), .result_box(),
                .result_color(), .result_class(), .result_confidence(), .result_score(),
                .result_reject(result_reject), .result_error(),
                .result_record(service_result_record), .busy(busy), .error(error),
                .error_code(error_code), .accepted_images(accepted_batches),
                .completed_images(completed_batches), .error_images(error_rois),
                .fifo_overflows(fifo_overflows), .axi_araddr(axi_araddr),
                .axi_arid(axi_arid), .axi_arlen(axi_arlen), .axi_arsize(axi_arsize),
                .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
                .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
                .axi_rresp(axi_rresp), .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
                .axi_rready(axi_rready)
            );
            assign batch_ready = 1'b0;
            assign int8_release_valid = 1'b0;
            assign int8_release_bank = 1'b0;
            assign int8_release_frame = 32'b0;
            assign dropped_batches = 0;
            assign completed_rois = completed_batches;
            assign released_banks = completed_batches;
        end
    endgenerate

    Hnpu_result_bridge #(.FIFO_DEPTH(RESULT_FIFO_DEPTH)) u_result_bridge (
        .ddr_clk(ddr_clk), .cpu_clk(cpu_clk), .rst_n(rst_n),
        .service_result_valid(service_result_valid),
        .service_result_ready(service_result_ready),
        .service_result_record(service_result_record),
        .mmio_valid(result_sel), .mmio_wen(mmio_wen),
        .mmio_addr(mmio_addr[7:0]), .mmio_wdata(mmio_wdata),
        .mmio_wstrb(mmio_wstrb), .mmio_ready(result_ready_mmio),
        .mmio_rdata(result_rdata), .irq(result_irq),
        .producer_overflow(result_overflow),
        .producer_error_code(result_error_code)
    );

    assign mmio_ready = result_sel ? result_ready_mmio :
                        ctrl_addr_sel ? ctrl_ready : 1'b1;
    assign mmio_rdata = ctrl_sel ? ctrl_rdata :
                        result_sel ? result_rdata : 32'b0;
    assign irq = ctrl_irq || result_irq;
endmodule
