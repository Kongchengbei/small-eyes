`timescale 1ns / 1ps

// Per-ROI adapter for the RGB565->INT8 stereo front-end.  The front-end owns
// the slot until release_valid/release_ready completes.  A descriptor is
// accepted only once, is queued by camera, and is released with its original
// block/position/generation tuple after the shared CNN engine has consumed it.
module Hnpu_image_service #(
    parameter [31:0] DDR_BASE = 32'h8000_0000,
    parameter [31:0] DDR_BYTES = 32'h4000_0000,
    parameter [7:0] AXI_ID = 8'h80,
    parameter integer QUEUE_DEPTH = 8,
    parameter integer RESULT_DEPTH = 16,
    parameter integer MAX_CLASSES = 16,
    parameter [31:0] MODEL_BASE = 32'h0000_0000,
    parameter [31:0] MODEL_BYTES = 32'h0000_0000,
    parameter integer MAX_MODEL_BYTES = 65536
) (
    input clk, input rst_n, input enable, input clear_errors, input stop,

    input [1:0] image_valid, output wire [1:0] image_ready,
    input [15:0] image_camera, input [63:0] image_frame,
    input [15:0] image_batch_count, input [15:0] image_index,
    input [127:0] image_box, input [5:0] image_color,
    input [3:0] image_block, input [7:0] image_position,
    input [63:0] image_generation, input [63:0] image_data_addr,
    input [31:0] image_width, input [31:0] image_height,
    input [63:0] image_data_bytes,

    output wire [1:0] release_valid, input [1:0] release_ready,
    output wire [15:0] release_camera, output wire [63:0] release_frame,
    output wire [3:0] release_block, output wire [7:0] release_position,
    output wire [63:0] release_generation,

    output wire result_valid, input result_ready,
    output wire [7:0] result_camera, output wire [31:0] result_frame,
    output wire [7:0] result_roi, output wire [63:0] result_box,
    output wire [2:0] result_color, output wire [7:0] result_class,
    output wire [15:0] result_confidence, output wire [31:0] result_score,
    output wire result_reject, output wire [7:0] result_error,
    output wire [255:0] result_record,

    output wire busy, output reg error, output reg [7:0] error_code,
    output reg [31:0] accepted_images, output reg [31:0] completed_images,
    output reg [31:0] error_images, output reg [31:0] fifo_overflows,

    output wire [29:0] axi_araddr, output wire [7:0] axi_arid,
    output wire [7:0] axi_arlen, output wire [2:0] axi_arsize,
    output wire [1:0] axi_arburst, output wire axi_arvalid,
    input axi_arready, input [255:0] axi_rdata, input [7:0] axi_rid,
    input [1:0] axi_rresp, input axi_rlast, input axi_rvalid,
    output wire axi_rready
);
    localparam integer PTR_BITS = (QUEUE_DEPTH <= 2) ? 1 : $clog2(QUEUE_DEPTH);
    localparam integer RES_PTR_BITS = (RESULT_DEPTH <= 2) ? 1 : $clog2(RESULT_DEPTH);
    localparam integer RELEASE_DEPTH = (QUEUE_DEPTH * 2) + 2;
    localparam integer REL_PTR_BITS = (RELEASE_DEPTH <= 2) ? 1 : $clog2(RELEASE_DEPTH);
    // The descriptor describes the complete image stored by the front-end.
    // The CNN engine receives the 32x32 tensor after its 3-pixel decimator.
    localparam integer SOURCE_BYTES = 96 * 96 * 4;
    localparam integer MODEL_INPUT_BYTES = 32 * 32 * 4;

    reg [PTR_BITS-1:0] q_head [0:1], q_tail [0:1];
    reg [PTR_BITS:0] q_count [0:1];
    reg [7:0] q_camera [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_frame [0:1][0:QUEUE_DEPTH-1];
    reg [7:0] q_roi [0:1][0:QUEUE_DEPTH-1];
    reg [63:0] q_box [0:1][0:QUEUE_DEPTH-1];
    reg [2:0] q_color [0:1][0:QUEUE_DEPTH-1];
    reg [1:0] q_block [0:1][0:QUEUE_DEPTH-1];
    reg [3:0] q_position [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_generation [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_input_addr [0:1][0:QUEUE_DEPTH-1];
    reg [31:0] q_input_bytes [0:1][0:QUEUE_DEPTH-1];

    reg active, active_cam, engine_issued, rr_next;
    reg [7:0] active_camera, active_roi;
    reg [31:0] active_frame, active_input_addr, active_input_bytes;
    reg [63:0] active_box;
    reg [2:0] active_color;
    reg [1:0] active_block;
    reg [3:0] active_position;
    reg [31:0] active_generation;

    reg [7:0] result_camera_mem [0:RESULT_DEPTH-1];
    reg [31:0] result_frame_mem [0:RESULT_DEPTH-1];
    reg [7:0] result_roi_mem [0:RESULT_DEPTH-1];
    reg [63:0] result_box_mem [0:RESULT_DEPTH-1];
    reg [2:0] result_color_mem [0:RESULT_DEPTH-1];
    reg [7:0] result_class_mem [0:RESULT_DEPTH-1];
    reg [15:0] result_conf_mem [0:RESULT_DEPTH-1];
    reg [31:0] result_score_mem [0:RESULT_DEPTH-1];
    reg result_reject_mem [0:RESULT_DEPTH-1];
    reg [7:0] result_error_mem [0:RESULT_DEPTH-1];
    reg [RES_PTR_BITS-1:0] result_rd_ptr, result_wr_ptr;
    reg [RES_PTR_BITS:0] result_count;
    reg [RES_PTR_BITS+1:0] result_reserved;

    reg [7:0] release_camera_mem [0:RELEASE_DEPTH-1];
    reg [31:0] release_frame_mem [0:RELEASE_DEPTH-1];
    reg [1:0] release_block_mem [0:RELEASE_DEPTH-1];
    reg [3:0] release_position_mem [0:RELEASE_DEPTH-1];
    reg [31:0] release_generation_mem [0:RELEASE_DEPTH-1];
    reg [REL_PTR_BITS-1:0] release_rd_ptr, release_wr_ptr;
    reg [REL_PTR_BITS:0] release_count;

    wire result_pop = result_valid && result_ready;
    wire release_head_lane = (release_camera_mem[release_rd_ptr] == 8'd2);
    wire release_head_pop = (release_count != 0) &&
                            release_ready[release_head_lane];
    wire [63:0] ddr_end = {32'b0, DDR_BASE} + {32'b0, DDR_BYTES};
    wire [31:0] image_addr0 = image_data_addr[31:0];
    wire [31:0] image_addr1 = image_data_addr[63:32];
    wire [31:0] image_bytes0 = image_data_bytes[31:0];
    wire [31:0] image_bytes1 = image_data_bytes[63:32];
    wire [63:0] image_end0 = {32'b0, image_addr0} + {32'b0, image_bytes0};
    wire [63:0] image_end1 = {32'b0, image_addr1} + {32'b0, image_bytes1};
    wire image_format0 = (image_width[15:0] == 96) &&
                         (image_height[15:0] == 96) &&
                         (image_bytes0 == SOURCE_BYTES) &&
                         (image_addr0[4:0] == 0) &&
                         (image_addr0 >= DDR_BASE) && (image_end0 <= ddr_end);
    wire image_format1 = (image_width[31:16] == 96) &&
                         (image_height[31:16] == 96) &&
                         (image_bytes1 == SOURCE_BYTES) &&
                         (image_addr1[4:0] == 0) &&
                         (image_addr1 >= DDR_BASE) && (image_end1 <= ddr_end);
    wire result_capacity = (result_count + result_reserved < RESULT_DEPTH);
    wire release_capacity = (release_count + q_count[0] + q_count[1] + active < RELEASE_DEPTH);
    wire input_cap0 = image_valid[0] && (q_count[0] < QUEUE_DEPTH) &&
                      image_format0 && result_capacity && release_capacity;
    wire input_cap1 = image_valid[1] && (q_count[1] < QUEUE_DEPTH) &&
                      image_format1 && result_capacity && release_capacity;
    wire selected_input = input_cap0 && (!input_cap1 || !rr_next) ? 1'b0 : 1'b1;

    assign image_ready = (enable && !stop && (input_cap0 || input_cap1)) ?
                         ((selected_input == 0) ? 2'b01 : 2'b10) : 2'b00;
    wire image_accept = |(image_valid & image_ready);
    wire accept_cam = image_ready[1];
    wire take_queue = !active && !engine_busy && !stop &&
                      ((q_count[rr_next] != 0) || (q_count[~rr_next] != 0));
    wire take_cam = (q_count[rr_next] != 0) ? rr_next : ~rr_next;

    assign result_valid = (result_count != 0);
    assign result_camera = result_camera_mem[result_rd_ptr];
    assign result_frame = result_frame_mem[result_rd_ptr];
    assign result_roi = result_roi_mem[result_rd_ptr];
    assign result_box = result_box_mem[result_rd_ptr];
    assign result_color = result_color_mem[result_rd_ptr];
    assign result_class = result_class_mem[result_rd_ptr];
    assign result_confidence = result_conf_mem[result_rd_ptr];
    assign result_score = result_score_mem[result_rd_ptr];
    assign result_reject = result_reject_mem[result_rd_ptr];
    assign result_error = result_error_mem[result_rd_ptr];
    assign result_record = {
        75'b0, result_reject, result_score, result_error,
        result_confidence, result_class, result_color, result_box,
        result_roi, 1'b0, result_frame, result_camera
    };

    assign release_valid = (release_count == 0) ? 2'b00 :
                           (release_head_lane ? 2'b10 : 2'b01);
    assign release_camera = release_count == 0 ? 16'b0 :
                            (release_head_lane ?
                             {release_camera_mem[release_rd_ptr], 8'b0} :
                             {8'b0, release_camera_mem[release_rd_ptr]});
    assign release_frame = release_count == 0 ? 64'b0 :
                           (release_head_lane ?
                            {release_frame_mem[release_rd_ptr], 32'b0} :
                            {32'b0, release_frame_mem[release_rd_ptr]});
    assign release_block = release_count == 0 ? 4'b0 :
                           (release_head_lane ?
                            {release_block_mem[release_rd_ptr], 2'b0} :
                            {2'b0, release_block_mem[release_rd_ptr]});
    assign release_position = release_count == 0 ? 8'b0 :
                              (release_head_lane ?
                               {release_position_mem[release_rd_ptr], 4'b0} :
                               {4'b0, release_position_mem[release_rd_ptr]});
    assign release_generation = release_count == 0 ? 64'b0 :
                                (release_head_lane ?
                                 {release_generation_mem[release_rd_ptr], 32'b0} :
                                 {32'b0, release_generation_mem[release_rd_ptr]});
    assign busy = active || engine_busy || (q_count[0] != 0) || (q_count[1] != 0);

    wire engine_start = enable && !stop && active && !engine_issued;
    wire engine_busy, engine_done, engine_error, engine_reject;
    wire [7:0] engine_error_code, engine_class;
    wire [15:0] engine_confidence;
    wire [31:0] engine_score;
    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES), .AXI_ID(AXI_ID),
        .MAX_MODEL_BYTES(MAX_MODEL_BYTES), .MAX_TENSOR_BYTES(65536),
        .MAX_LAYERS(16), .MAX_CLASSES(MAX_CLASSES)
    ) u_engine (
        .clk(clk), .rst_n(rst_n), .start(engine_start), .clear_error(clear_errors),
        .model_base(MODEL_BASE), .model_bytes(MODEL_BYTES),
        .input_addr(active_input_addr), .input_bytes(MODEL_INPUT_BYTES),
        .input_source_bytes(active_input_bytes), .input_downsample3(1'b1),
        .busy(engine_busy), .done_pulse(engine_done), .error(engine_error),
        .error_code(engine_error_code), .result_class(engine_class),
        .result_confidence(engine_confidence), .result_score(engine_score),
        .result_reject(engine_reject), .model_cache_hit(), .model_cache_valid(),
        .model_load_count(), .model_load_beats(), .axi_araddr(axi_araddr),
        .axi_arid(axi_arid), .axi_arlen(axi_arlen), .axi_arsize(axi_arsize),
        .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
        .axi_rresp(axi_rresp), .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready)
    );

    integer i, j;
    integer q_index;
    integer q_count_next0, q_count_next1;
    integer result_count_next, reserve_next, release_count_next;
    reg accept_image, enqueue_result, choose_queue;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_head[0] <= 0; q_head[1] <= 0; q_tail[0] <= 0; q_tail[1] <= 0;
            q_count[0] <= 0; q_count[1] <= 0;
            active <= 0; active_cam <= 0; engine_issued <= 0; rr_next <= 0;
            active_camera <= 0; active_frame <= 0; active_roi <= 0;
            active_input_addr <= 0; active_input_bytes <= 0; active_box <= 0;
            active_color <= 0; active_block <= 0; active_position <= 0;
            active_generation <= 0;
            result_rd_ptr <= 0; result_wr_ptr <= 0; result_count <= 0;
            result_reserved <= 0;
            release_rd_ptr <= 0; release_wr_ptr <= 0; release_count <= 0;
            error <= 0; error_code <= 0; accepted_images <= 0;
            completed_images <= 0; error_images <= 0; fifo_overflows <= 0;
        end else begin
            if (clear_errors) begin error <= 0; error_code <= 0; end
            q_count_next0 = q_count[0];
            q_count_next1 = q_count[1];
            result_count_next = result_count;
            reserve_next = result_reserved;
            release_count_next = release_count;
            accept_image = image_accept;
            enqueue_result = engine_done && active;
            choose_queue = take_queue;

            if (result_pop && result_count_next != 0) begin
                result_rd_ptr <= (result_rd_ptr == RESULT_DEPTH-1) ? 0 : result_rd_ptr + 1'b1;
                result_count_next = result_count_next - 1;
            end
            if (release_head_pop) begin
                release_rd_ptr <= (release_rd_ptr == RELEASE_DEPTH-1) ? 0 : release_rd_ptr + 1'b1;
                release_count_next = release_count_next - 1;
            end

            if (accept_image) begin
                q_index = q_tail[accept_cam];
                q_camera[accept_cam][q_index] <= image_camera[accept_cam*8 +: 8];
                q_frame[accept_cam][q_index] <= image_frame[accept_cam*32 +: 32];
                q_roi[accept_cam][q_index] <= image_index[accept_cam*8 +: 8];
                q_box[accept_cam][q_index] <= image_box[accept_cam*64 +: 64];
                q_color[accept_cam][q_index] <= image_color[accept_cam*3 +: 3];
                q_block[accept_cam][q_index] <= image_block[accept_cam*2 +: 2];
                q_position[accept_cam][q_index] <= image_position[accept_cam*4 +: 4];
                q_generation[accept_cam][q_index] <= image_generation[accept_cam*32 +: 32];
                q_input_addr[accept_cam][q_index] <= image_data_addr[accept_cam*32 +: 32];
                q_input_bytes[accept_cam][q_index] <= image_data_bytes[accept_cam*32 +: 32];
                q_tail[accept_cam] <= (q_tail[accept_cam] == QUEUE_DEPTH-1) ? 0 : q_tail[accept_cam] + 1'b1;
                if (accept_cam == 0) q_count_next0 = q_count_next0 + 1;
                else q_count_next1 = q_count_next1 + 1;
                reserve_next = reserve_next + 1;
                accepted_images <= accepted_images + 1'b1;
            end

            if (choose_queue) begin
                q_index = q_head[take_cam];
                active <= 1'b1;
                active_cam <= take_cam;
                active_camera <= q_camera[take_cam][q_index];
                active_frame <= q_frame[take_cam][q_index];
                active_roi <= q_roi[take_cam][q_index];
                active_box <= q_box[take_cam][q_index];
                active_color <= q_color[take_cam][q_index];
                active_block <= q_block[take_cam][q_index];
                active_position <= q_position[take_cam][q_index];
                active_generation <= q_generation[take_cam][q_index];
                active_input_addr <= q_input_addr[take_cam][q_index];
                active_input_bytes <= q_input_bytes[take_cam][q_index];
                engine_issued <= 1'b0;
                q_head[take_cam] <= (q_head[take_cam] == QUEUE_DEPTH-1) ? 0 : q_head[take_cam] + 1'b1;
                if (take_cam == 0) q_count_next0 = q_count_next0 - 1;
                else q_count_next1 = q_count_next1 - 1;
                rr_next <= ~take_cam;
            end
            if (engine_start) engine_issued <= 1'b1;

            if (enqueue_result) begin
                if ((result_count_next < RESULT_DEPTH) || result_pop) begin
                    result_camera_mem[result_wr_ptr] <= active_camera;
                    result_frame_mem[result_wr_ptr] <= active_frame;
                    result_roi_mem[result_wr_ptr] <= active_roi;
                    result_box_mem[result_wr_ptr] <= active_box;
                    result_color_mem[result_wr_ptr] <= active_color;
                    result_class_mem[result_wr_ptr] <= engine_error ? 8'hff : engine_class;
                    result_conf_mem[result_wr_ptr] <= engine_error ? 0 : engine_confidence;
                    result_score_mem[result_wr_ptr] <= engine_error ? 0 : engine_score;
                    result_reject_mem[result_wr_ptr] <= engine_error ? 0 : engine_reject;
                    result_error_mem[result_wr_ptr] <= engine_error ? engine_error_code : 0;
                    result_wr_ptr <= (result_wr_ptr == RESULT_DEPTH-1) ? 0 : result_wr_ptr + 1'b1;
                    result_count_next = result_count_next + 1;
                    reserve_next = reserve_next - 1;
                    if (engine_error) begin
                        error_images <= error_images + 1'b1;
                        error <= 1'b1; error_code <= engine_error_code;
                    end else completed_images <= completed_images + 1'b1;
                end else begin
                    fifo_overflows <= fifo_overflows + 1'b1;
                    error <= 1'b1; error_code <= 8'h06;
                end
                if (release_count_next < RELEASE_DEPTH) begin
                    release_camera_mem[release_wr_ptr] <= active_camera;
                    release_frame_mem[release_wr_ptr] <= active_frame;
                    release_block_mem[release_wr_ptr] <= active_block;
                    release_position_mem[release_wr_ptr] <= active_position;
                    release_generation_mem[release_wr_ptr] <= active_generation;
                    release_wr_ptr <= (release_wr_ptr == RELEASE_DEPTH-1) ? 0 : release_wr_ptr + 1'b1;
                    release_count_next = release_count_next + 1;
                end else begin
                    error <= 1'b1; error_code <= 8'h07;
                end
                active <= 1'b0;
                engine_issued <= 1'b0;
            end
            result_reserved <= reserve_next;
            result_count <= result_count_next;
            q_count[0] <= q_count_next0;
            q_count[1] <= q_count_next1;
            release_count <= release_count_next;
        end
    end
endmodule
