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
    // A descriptor is only valid with image_bytes == SOURCE_BYTES, so the
    // end-of-DDR test reduces to a constant limit on the start address.
    localparam [31:0] SOURCE_BYTES32 = SOURCE_BYTES;
    localparam [63:0] DDR_END = {32'b0, DDR_BASE} + {32'b0, DDR_BYTES};
    localparam SOURCE_NONE = (DDR_END < {32'b0, SOURCE_BYTES32});
    localparam [63:0] SOURCE_LAST = DDR_END - {32'b0, SOURCE_BYTES32};
    localparam SOURCE_ANY = !SOURCE_NONE && (SOURCE_LAST[63:32] != 32'b0);

    // a >= b as and/or terms.  Against a constant this is a few LUTs, not a
    // carry chain.
    function ge32;
        input [31:0] a, b;
        integer k;
        reg r;
        begin
            r = 1'b1;
            for (k = 0; k < 32; k = k + 1)
                r = (a[k] & ~b[k]) | (~(a[k] ^ b[k]) & r);
            ge32 = r;
        end
    endfunction

    // x + 1 and x - 1 as xor/and terms.  The counters below form both from
    // flops and let the late handshake only pick one.
    function [7:0] up8;
        input [7:0] x;
        integer k;
        reg [7:0] r;
        reg c;
        begin
            c = 1'b1;
            for (k = 0; k < 8; k = k + 1) begin
                r[k] = x[k] ^ c;
                c = c & x[k];
            end
            up8 = r;
        end
    endfunction

    function [7:0] dn8;
        input [7:0] x;
        integer k;
        reg [7:0] r;
        reg c;
        begin
            c = 1'b1;
            for (k = 0; k < 8; k = k + 1) begin
                r[k] = x[k] ^ c;
                c = c & ~x[k];
            end
            dn8 = r;
        end
    endfunction

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
    reg release_lane_mem [0:RELEASE_DEPTH-1];  // camera 2 entry, decoded at enqueue
    reg [REL_PTR_BITS-1:0] release_rd_ptr, release_wr_ptr;
    reg [REL_PTR_BITS-1:0] release_rd_ptr1;    // entry after release_rd_ptr
    reg [REL_PTR_BITS:0] release_count;
    // Running sums behind the two capacity checks, kept as flops:
    //   result_total  = result_count + result_reserved
    //   release_total = release_count + q_count[0] + q_count[1] + active
    reg [RES_PTR_BITS:0] result_total;
    reg [REL_PTR_BITS:0] release_total;
    // Registered release port.  Each cycle it holds exactly what the head
    // entry/release_count would give combinationally, so the lane-side
    // release logic starts from flops.
    reg [1:0] release_valid_r;
    reg [15:0] release_camera_r;
    reg [63:0] release_frame_r, release_generation_r;
    reg [3:0] release_block_r;
    reg [7:0] release_position_r;

    wire engine_busy, engine_done, engine_error, engine_reject;
    wire [7:0] engine_error_code, engine_class;
    wire [15:0] engine_confidence;
    wire [31:0] engine_score;

    wire result_pop = result_valid && result_ready;
    wire release_head_pop = |(release_valid_r & release_ready);
    wire [31:0] image_addr0 = image_data_addr[31:0];
    wire [31:0] image_addr1 = image_data_addr[63:32];
    wire [31:0] image_bytes0 = image_data_bytes[31:0];
    wire [31:0] image_bytes1 = image_data_bytes[63:32];
    // addr >= DDR_BASE and addr + SOURCE_BYTES <= DDR_BASE + DDR_BYTES.
    wire image_window0 = ge32(image_addr0, DDR_BASE) && !SOURCE_NONE &&
                         (SOURCE_ANY || ge32(SOURCE_LAST[31:0], image_addr0));
    wire image_window1 = ge32(image_addr1, DDR_BASE) && !SOURCE_NONE &&
                         (SOURCE_ANY || ge32(SOURCE_LAST[31:0], image_addr1));
    wire image_format0 = (image_width[15:0] == 96) &&
                         (image_height[15:0] == 96) &&
                         (image_bytes0 == SOURCE_BYTES) &&
                         (image_addr0[4:0] == 0) && image_window0;
    wire image_format1 = (image_width[31:16] == 96) &&
                         (image_height[31:16] == 96) &&
                         (image_bytes1 == SOURCE_BYTES) &&
                         (image_addr1[4:0] == 0) && image_window1;
    wire result_capacity = !ge32(result_total, RESULT_DEPTH);
    wire release_capacity = !ge32(release_total, RELEASE_DEPTH);
    wire input_go = enable && !stop && result_capacity && release_capacity;
    wire input_ok0 = image_valid[0] && !ge32(q_count[0], QUEUE_DEPTH) && image_format0;
    wire input_ok1 = image_valid[1] && !ge32(q_count[1], QUEUE_DEPTH) && image_format1;

    // Camera 0 is taken unless camera 1 is also ready and has the turn.
    assign image_ready[0] = input_go && input_ok0 && (!input_ok1 || !rr_next);
    assign image_ready[1] = input_go && input_ok1 && (!input_ok0 || rr_next);
    wire image_accept = |image_ready;
    wire take_queue = !active && !engine_busy && !stop &&
                      ((q_count[rr_next] != 0) || (q_count[~rr_next] != 0));
    wire take_cam = (q_count[rr_next] != 0) ? rr_next : ~rr_next;
    wire [1:0] take_hit = !take_queue ? 2'b00 : (take_cam ? 2'b10 : 2'b01);

    // A finished image is stored if result_count - result_pop < RESULT_DEPTH
    // (or a pop frees a slot), and its release if
    // release_count - release_head_pop < RELEASE_DEPTH.
    wire enqueue_result = engine_done && active;
    wire result_room = result_pop || !ge32(result_count, RESULT_DEPTH);
    wire release_room = release_head_pop ? ge32(RELEASE_DEPTH, release_count) :
                                           !ge32(release_count, RELEASE_DEPTH);
    wire result_push = enqueue_result && result_room;
    wire release_push = enqueue_result && release_room;
    wire release_fail = enqueue_result && !release_room;

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

    assign release_valid = release_valid_r;
    assign release_camera = release_camera_r;
    assign release_frame = release_frame_r;
    assign release_block = release_block_r;
    assign release_position = release_position_r;
    assign release_generation = release_generation_r;

    // The head only changes when the queue is empty or the head is popped.
    // The next head is then the following queued entry, or the entry
    // enqueued this cycle when the queue is (or becomes) empty.
    wire release_head_hold = |(release_valid_r & ~release_ready);
    wire release_from_queue = release_head_pop && (release_count != 1);
    wire release_next_valid = release_push || release_from_queue;
    wire release_next_lane = release_from_queue ? release_lane_mem[release_rd_ptr1] :
                                                  (active_camera == 8'd2);
    wire [7:0] release_next_camera = release_from_queue ?
                                     release_camera_mem[release_rd_ptr1] : active_camera;
    wire [31:0] release_next_frame = release_from_queue ?
                                     release_frame_mem[release_rd_ptr1] : active_frame;
    wire [1:0] release_next_block = release_from_queue ?
                                    release_block_mem[release_rd_ptr1] : active_block;
    wire [3:0] release_next_position = release_from_queue ?
                                       release_position_mem[release_rd_ptr1] : active_position;
    wire [31:0] release_next_generation = release_from_queue ?
                                          release_generation_mem[release_rd_ptr1] : active_generation;
    assign busy = active || engine_busy || (q_count[0] != 0) || (q_count[1] != 0);

    wire engine_start = enable && !stop && active && !engine_issued;
    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES), .AXI_ID(AXI_ID),
        // v0.3's largest tensor is L1: 32x32x16 = 16 KiB. Two 16 KiB
        // banks cover input/output ping-pong without reserving 128 KiB.
        .MAX_MODEL_BYTES(MAX_MODEL_BYTES), .MAX_TENSOR_BYTES(16384),
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

    integer c;
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
            result_reserved <= 0; result_total <= 0; release_total <= 0;
            release_rd_ptr <= 0; release_wr_ptr <= 0; release_count <= 0;
            release_rd_ptr1 <= 1;
            release_valid_r <= 0; release_camera_r <= 0; release_frame_r <= 0;
            release_block_r <= 0; release_position_r <= 0; release_generation_r <= 0;
            error <= 0; error_code <= 0; accepted_images <= 0;
            completed_images <= 0; error_images <= 0; fifo_overflows <= 0;
        end else begin
            if (clear_errors) begin error <= 0; error_code <= 0; end

            if (result_pop)
                result_rd_ptr <= (result_rd_ptr == RESULT_DEPTH-1) ? 0 : result_rd_ptr + 1'b1;
            if (release_head_pop) begin
                release_rd_ptr <= (release_rd_ptr == RELEASE_DEPTH-1) ? 0 : release_rd_ptr + 1'b1;
                release_rd_ptr1 <= (release_rd_ptr1 == RELEASE_DEPTH-1) ? 0 : release_rd_ptr1 + 1'b1;
            end
            if (!release_head_hold) begin
                release_valid_r <= !release_next_valid ? 2'b00 :
                                   (release_next_lane ? 2'b10 : 2'b01);
                release_camera_r <= !release_next_valid ? 16'b0 :
                                    (release_next_lane ? {release_next_camera, 8'b0} :
                                                         {8'b0, release_next_camera});
                release_frame_r <= !release_next_valid ? 64'b0 :
                                   (release_next_lane ? {release_next_frame, 32'b0} :
                                                        {32'b0, release_next_frame});
                release_block_r <= !release_next_valid ? 4'b0 :
                                   (release_next_lane ? {release_next_block, 2'b0} :
                                                        {2'b0, release_next_block});
                release_position_r <= !release_next_valid ? 8'b0 :
                                      (release_next_lane ? {release_next_position, 4'b0} :
                                                           {4'b0, release_next_position});
                release_generation_r <= !release_next_valid ? 64'b0 :
                                        (release_next_lane ? {release_next_generation, 32'b0} :
                                                             {32'b0, release_next_generation});
            end

            // Queue c only ever takes camera c's fields, so image_ready
            // gates the write but never steers the data.
            for (c = 0; c < 2; c = c + 1)
                if (image_ready[c]) begin
                    q_camera[c][q_tail[c]] <= image_camera[c*8 +: 8];
                    q_frame[c][q_tail[c]] <= image_frame[c*32 +: 32];
                    q_roi[c][q_tail[c]] <= image_index[c*8 +: 8];
                    q_box[c][q_tail[c]] <= image_box[c*64 +: 64];
                    q_color[c][q_tail[c]] <= image_color[c*3 +: 3];
                    q_block[c][q_tail[c]] <= image_block[c*2 +: 2];
                    q_position[c][q_tail[c]] <= image_position[c*4 +: 4];
                    q_generation[c][q_tail[c]] <= image_generation[c*32 +: 32];
                    q_input_addr[c][q_tail[c]] <= image_data_addr[c*32 +: 32];
                    q_input_bytes[c][q_tail[c]] <= image_data_bytes[c*32 +: 32];
                    q_tail[c] <= (q_tail[c] == QUEUE_DEPTH-1) ? 0 : q_tail[c] + 1'b1;
                end
            if (image_accept) accepted_images <= accepted_images + 1'b1;

            if (take_queue) begin
                active <= 1'b1;
                active_cam <= take_cam;
                active_camera <= q_camera[take_cam][q_head[take_cam]];
                active_frame <= q_frame[take_cam][q_head[take_cam]];
                active_roi <= q_roi[take_cam][q_head[take_cam]];
                active_box <= q_box[take_cam][q_head[take_cam]];
                active_color <= q_color[take_cam][q_head[take_cam]];
                active_block <= q_block[take_cam][q_head[take_cam]];
                active_position <= q_position[take_cam][q_head[take_cam]];
                active_generation <= q_generation[take_cam][q_head[take_cam]];
                active_input_addr <= q_input_addr[take_cam][q_head[take_cam]];
                active_input_bytes <= q_input_bytes[take_cam][q_head[take_cam]];
                engine_issued <= 1'b0;
                q_head[take_cam] <= (q_head[take_cam] == QUEUE_DEPTH-1) ? 0 : q_head[take_cam] + 1'b1;
                rr_next <= ~take_cam;
            end
            if (engine_start) engine_issued <= 1'b1;

            if (enqueue_result) begin
                if (result_room) begin
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
                    if (engine_error) begin
                        error_images <= error_images + 1'b1;
                        error <= 1'b1; error_code <= engine_error_code;
                    end else completed_images <= completed_images + 1'b1;
                end else begin
                    fifo_overflows <= fifo_overflows + 1'b1;
                    error <= 1'b1; error_code <= 8'h06;
                end
                if (release_room) begin
                    release_camera_mem[release_wr_ptr] <= active_camera;
                    release_lane_mem[release_wr_ptr] <= (active_camera == 8'd2);
                    release_frame_mem[release_wr_ptr] <= active_frame;
                    release_block_mem[release_wr_ptr] <= active_block;
                    release_position_mem[release_wr_ptr] <= active_position;
                    release_generation_mem[release_wr_ptr] <= active_generation;
                    release_wr_ptr <= (release_wr_ptr == RELEASE_DEPTH-1) ? 0 : release_wr_ptr + 1'b1;
                end else begin
                    error <= 1'b1; error_code <= 8'h07;
                end
                active <= 1'b0;
                engine_issued <= 1'b0;
            end

            // +1/-1 come from flops; the late handshakes only select.
            q_count[0] <= image_ready[0] ? (take_hit[0] ? q_count[0] : up8(q_count[0])) :
                                           (take_hit[0] ? dn8(q_count[0]) : q_count[0]);
            q_count[1] <= image_ready[1] ? (take_hit[1] ? q_count[1] : up8(q_count[1])) :
                                           (take_hit[1] ? dn8(q_count[1]) : q_count[1]);
            result_count <= result_push ? (result_pop ? result_count : up8(result_count)) :
                                          (result_pop ? dn8(result_count) : result_count);
            result_reserved <= image_accept ? (result_push ? result_reserved : up8(result_reserved)) :
                                              (result_push ? dn8(result_reserved) : result_reserved);
            release_count <= release_push ? (release_head_pop ? release_count : up8(release_count)) :
                                            (release_head_pop ? dn8(release_count) : release_count);
            // result_total moves by +accept -pop.  release_total moves by
            // +accept -release pop -(result that found the release queue
            // full); queue moves and active cancel out.
            result_total <= image_accept ? (result_pop ? result_total : up8(result_total)) :
                                           (result_pop ? dn8(result_total) : result_total);
            release_total <= image_accept ?
                (release_head_pop ? (release_fail ? dn8(release_total) : release_total) :
                                    (release_fail ? release_total : up8(release_total))) :
                (release_head_pop ? (release_fail ? dn8(dn8(release_total)) : dn8(release_total)) :
                                    (release_fail ? dn8(release_total) : release_total));
        end
    end

`ifdef SERVICE_TB_CHECK
    // Simulation-only: the registered port must equal the original
    // combinational decode of release_count and the head entry every cycle.
    wire chk_lane = (release_camera_mem[release_rd_ptr] == 8'd2);
    wire chk_empty = (release_count == 0);
    wire [1:0] chk_valid = chk_empty ? 2'b00 : (chk_lane ? 2'b10 : 2'b01);
    wire [15:0] chk_camera = chk_empty ? 16'b0 : (chk_lane ?
        {release_camera_mem[release_rd_ptr], 8'b0} : {8'b0, release_camera_mem[release_rd_ptr]});
    wire [63:0] chk_frame = chk_empty ? 64'b0 : (chk_lane ?
        {release_frame_mem[release_rd_ptr], 32'b0} : {32'b0, release_frame_mem[release_rd_ptr]});
    wire [3:0] chk_block = chk_empty ? 4'b0 : (chk_lane ?
        {release_block_mem[release_rd_ptr], 2'b0} : {2'b0, release_block_mem[release_rd_ptr]});
    wire [7:0] chk_position = chk_empty ? 8'b0 : (chk_lane ?
        {release_position_mem[release_rd_ptr], 4'b0} : {4'b0, release_position_mem[release_rd_ptr]});
    wire [63:0] chk_generation = chk_empty ? 64'b0 : (chk_lane ?
        {release_generation_mem[release_rd_ptr], 32'b0} : {32'b0, release_generation_mem[release_rd_ptr]});
    // Original image_ready decode, for the reformulated checks above.
    wire [63:0] chk_ddr_end = {32'b0, DDR_BASE} + {32'b0, DDR_BYTES};
    wire [63:0] chk_end0 = {32'b0, image_addr0} + {32'b0, image_bytes0};
    wire [63:0] chk_end1 = {32'b0, image_addr1} + {32'b0, image_bytes1};
    wire chk_format0 = (image_width[15:0] == 96) && (image_height[15:0] == 96) &&
                       (image_bytes0 == SOURCE_BYTES) && (image_addr0[4:0] == 0) &&
                       (image_addr0 >= DDR_BASE) && (chk_end0 <= chk_ddr_end);
    wire chk_format1 = (image_width[31:16] == 96) && (image_height[31:16] == 96) &&
                       (image_bytes1 == SOURCE_BYTES) && (image_addr1[4:0] == 0) &&
                       (image_addr1 >= DDR_BASE) && (chk_end1 <= chk_ddr_end);
    wire chk_result_capacity = (result_count + result_reserved < RESULT_DEPTH);
    wire chk_release_capacity = (release_count + q_count[0] + q_count[1] + active < RELEASE_DEPTH);
    wire chk_cap0 = image_valid[0] && (q_count[0] < QUEUE_DEPTH) &&
                    chk_format0 && chk_result_capacity && chk_release_capacity;
    wire chk_cap1 = image_valid[1] && (q_count[1] < QUEUE_DEPTH) &&
                    chk_format1 && chk_result_capacity && chk_release_capacity;
    wire chk_sel = chk_cap0 && (!chk_cap1 || !rr_next) ? 1'b0 : 1'b1;
    wire [1:0] ref_image_ready = (enable && !stop && (chk_cap0 || chk_cap1)) ?
                                 ((chk_sel == 0) ? 2'b01 : 2'b10) : 2'b00;
    always @(negedge clk) if (rst_n) begin
        if (image_format0 !== chk_format0 || image_format1 !== chk_format1)
            $display("SERVICE_ASSERT_FAIL t=%0t image_format", $time);
        if (release_valid_r !== chk_valid || release_camera_r !== chk_camera ||
            release_frame_r !== chk_frame || release_block_r !== chk_block ||
            release_position_r !== chk_position || release_generation_r !== chk_generation)
            $display("SERVICE_ASSERT_FAIL t=%0t release port %h/%h count=%0d", $time,
                     release_valid_r, chk_valid, release_count);
        if (release_rd_ptr1 != ((release_rd_ptr == RELEASE_DEPTH-1) ? 0 : release_rd_ptr + 1'b1))
            $display("SERVICE_ASSERT_FAIL t=%0t release_rd_ptr1", $time);
        if (!chk_empty && release_lane_mem[release_rd_ptr] !== chk_lane)
            $display("SERVICE_ASSERT_FAIL t=%0t release_lane_mem", $time);
        if (result_total + 32'd0 != result_count + result_reserved + 32'd0)
            $display("SERVICE_ASSERT_FAIL t=%0t result_total", $time);
        if (release_total + 32'd0 != release_count + q_count[0] + q_count[1] + active + 32'd0)
            $display("SERVICE_ASSERT_FAIL t=%0t release_total", $time);
        if (image_ready !== ref_image_ready)
            $display("SERVICE_ASSERT_FAIL t=%0t image_ready", $time);
    end
`endif
endmodule
