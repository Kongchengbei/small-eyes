`timescale 1ns / 1ps

module tb_npu_image_service;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT1_ADDR = 32'h8002_0000;
    localparam [31:0] INPUT2_ADDR = 32'h8002_9000;
    localparam integer MODEL_BYTES = 512;
    localparam integer INPUT_BYTES = 96 * 96 * 4;
    localparam integer MEM_BYTES = 32'h0004_0000;

    reg clk = 1'b0, rst_n = 1'b0, enable = 1'b1, clear_errors = 1'b0, stop = 1'b0;
    reg [1:0] image_valid = 0;
    wire [1:0] image_ready;
    reg [15:0] image_camera = {8'd2, 8'd1};
    reg [63:0] image_frame = {32'h222, 32'h111};
    reg [15:0] image_batch_count = {8'd1, 8'd1};
    reg [15:0] image_index = {8'd1, 8'd0};
    reg [127:0] image_box = {64'h2222, 64'h1111};
    reg [5:0] image_color = {3'd2, 3'd1};
    reg [3:0] image_block = {2'd2, 2'd1};
    reg [7:0] image_position = {4'd4, 4'd3};
    reg [63:0] image_generation = {32'haaaa, 32'hbbbb};
    reg [63:0] image_data_addr = {INPUT2_ADDR, INPUT1_ADDR};
    reg [31:0] image_width = {16'd96, 16'd96};
    reg [31:0] image_height = {16'd96, 16'd96};
    reg [63:0] image_data_bytes = {32'd36864, 32'd36864};

    wire [1:0] release_valid;
    reg [1:0] release_ready = 2'b11;
    wire [15:0] release_camera;
    wire [63:0] release_frame, release_generation;
    wire [3:0] release_block;
    wire [7:0] release_position;
    wire result_valid;
    reg result_ready = 1'b1;
    wire [7:0] result_camera, result_roi, result_class, result_error;
    wire [31:0] result_frame, result_score;
    wire [63:0] result_box;
    wire [2:0] result_color;
    wire [15:0] result_confidence;
    wire result_reject;
    wire [255:0] result_record;
    wire busy, error;
    wire [7:0] error_code;
    wire [31:0] accepted_images, completed_images, error_images, fifo_overflows;

    wire [29:0] axi_araddr;
    wire [7:0] axi_arid, axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid, axi_rready;
    reg axi_arready = 0;
    reg [255:0] axi_rdata = 0;
    reg [7:0] axi_rid = 0;
    reg [1:0] axi_rresp = 0;
    reg axi_rlast = 0, axi_rvalid = 0;

    reg [7:0] mem [0:MEM_BYTES-1];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer lane, index, cycle_count, model_ar_count, result_seen, release_seen;
    integer input_beat_count;
    string model_hex;

    always #5 clk = ~clk;

    Hnpu_image_service #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000), .AXI_ID(8'h80),
        .QUEUE_DEPTH(4), .RESULT_DEPTH(4), .MAX_CLASSES(16),
        .MODEL_BASE(MODEL_ADDR), .MODEL_BYTES(MODEL_BYTES)
    ) dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_errors(clear_errors), .stop(stop),
        .image_valid(image_valid), .image_ready(image_ready),
        .image_camera(image_camera), .image_frame(image_frame),
        .image_batch_count(image_batch_count), .image_index(image_index),
        .image_box(image_box), .image_color(image_color), .image_block(image_block),
        .image_position(image_position), .image_generation(image_generation),
        .image_data_addr(image_data_addr), .image_width(image_width),
        .image_height(image_height), .image_data_bytes(image_data_bytes),
        .release_valid(release_valid), .release_ready(release_ready),
        .release_camera(release_camera), .release_frame(release_frame),
        .release_block(release_block), .release_position(release_position),
        .release_generation(release_generation), .result_valid(result_valid),
        .result_ready(result_ready), .result_camera(result_camera),
        .result_frame(result_frame), .result_roi(result_roi), .result_box(result_box),
        .result_color(result_color), .result_class(result_class),
        .result_confidence(result_confidence), .result_score(result_score),
        .result_reject(result_reject), .result_error(result_error),
        .result_record(result_record), .busy(busy), .error(error),
        .error_code(error_code), .accepted_images(accepted_images),
        .completed_images(completed_images), .error_images(error_images),
        .fifo_overflows(fifo_overflows), .axi_araddr(axi_araddr),
        .axi_arid(axi_arid), .axi_arlen(axi_arlen), .axi_arsize(axi_arsize),
        .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
        .axi_rresp(axi_rresp), .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0; rd_active <= 0; rd_addr <= 0; rd_left <= 0;
            rd_id <= 0; axi_arready <= 0; axi_rvalid <= 0; axi_rdata <= 0;
            axi_rid <= 0; axi_rresp <= 0; axi_rlast <= 0; model_ar_count <= 0;
            result_seen <= 0; release_seen <= 0;
            input_beat_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid;
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "image service AXI metadata mismatch");
                rd_active <= 1; rd_addr <= axi_araddr; rd_left <= axi_arlen + 1; rd_id <= axi_arid;
                if (axi_araddr >= MODEL_ADDR - DDR_BASE &&
                    axi_araddr < MODEL_ADDR - DDR_BASE + MODEL_BYTES)
                    model_ar_count <= model_ar_count + 1;
            end
            if (axi_rvalid) begin
                if (axi_rready) begin
                    if ((rd_addr >= INPUT1_ADDR - DDR_BASE &&
                         rd_addr < INPUT1_ADDR - DDR_BASE + INPUT_BYTES) ||
                        (rd_addr >= INPUT2_ADDR - DDR_BASE &&
                         rd_addr < INPUT2_ADDR - DDR_BASE + INPUT_BYTES))
                        input_beat_count <= input_beat_count + 1;
                    axi_rvalid <= 0;
                    if (rd_left == 1) rd_active <= 0;
                    else begin rd_left <= rd_left - 1; rd_addr <= rd_addr + 30'd32; end
                end
            end else if (rd_active) begin
                axi_rdata <= 0;
                for (lane = 0; lane < 32; lane = lane + 1)
                    axi_rdata[lane*8 +: 8] <= mem[rd_addr + lane];
                axi_rid <= rd_id; axi_rresp <= 0; axi_rlast <= (rd_left == 1); axi_rvalid <= 1;
            end
            if (result_valid && result_ready) begin
                result_seen <= result_seen + 1;
                if ((result_camera == 1 && result_frame != 32'h111) ||
                    (result_camera == 2 && result_frame != 32'h222) ||
                    (result_camera == 1 && result_class != 0) ||
                    (result_camera == 2 && result_class != 1) || result_error != 0)
                    $fatal(1, "bad image result camera=%0d frame=%h class=%0d error=%0d",
                           result_camera, result_frame, result_class, result_error);
            end
            if (release_valid[0] && release_ready[0]) begin
                release_seen <= release_seen + 1;
                if (release_camera[7:0] != 1 || release_block[1:0] != 1 ||
                    release_position[3:0] != 3 || release_generation[31:0] != 32'hbbbb)
                    $fatal(1, "bad CAM1 release camera=%0d block=%0d pos=%0d gen=%h",
                           release_camera[7:0], release_block[1:0], release_position[3:0],
                           release_generation[31:0]);
            end
            if (release_valid[1] && release_ready[1]) begin
                release_seen <= release_seen + 1;
                if (release_camera[15:8] != 2 || release_block[3:2] != 2 ||
                    release_position[7:4] != 4 || release_generation[63:32] != 32'haaaa)
                    $fatal(1, "bad CAM2 release camera=%0d block=%0d pos=%0d gen=%h",
                           release_camera[15:8], release_block[3:2], release_position[7:4],
                           release_generation[63:32]);
            end
        end
    end

    initial begin
        if (!$value$plusargs("MODEL_HEX=%s", model_hex)) $fatal(1, "MODEL_HEX is required");
        for (index = 0; index < MEM_BYTES; index = index + 1) mem[index] = 0;
        $readmemh(model_hex, mem, 0, MODEL_BYTES - 1);
        for (index = 0; index < MODEL_BYTES; index = index + 1)
            mem[MODEL_ADDR - DDR_BASE + index] = mem[index];
        for (index = 0; index < 96 * 96; index = index + 1) begin
            // Only the (y,x)=(0,3,6,...) samples carry the expected class
            // colour. A sequential first-4096-byte read must classify this
            // differently from the required 3-pixel decimation.
            if (((index / 96) % 3) == 0 && ((index % 96) % 3) == 0) begin
                mem[INPUT1_ADDR - DDR_BASE + index * 4] = 8'd10;
                mem[INPUT1_ADDR - DDR_BASE + index * 4 + 1] = 8'd1;
                mem[INPUT2_ADDR - DDR_BASE + index * 4] = 8'd1;
                mem[INPUT2_ADDR - DDR_BASE + index * 4 + 1] = 8'd20;
            end else begin
                mem[INPUT1_ADDR - DDR_BASE + index * 4] = 8'd1;
                mem[INPUT1_ADDR - DDR_BASE + index * 4 + 1] = 8'd20;
                mem[INPUT2_ADDR - DDR_BASE + index * 4] = 8'd10;
                mem[INPUT2_ADDR - DDR_BASE + index * 4 + 1] = 8'd1;
            end
        end
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk); image_valid = 2'b11;
        while (!image_ready[0]) @(posedge clk);
        @(negedge clk); image_valid[0] = 1'b0;
        while (!image_ready[1]) @(posedge clk);
        @(negedge clk); image_valid[1] = 1'b0;
        for (index = 0; index < 1000000 && (result_seen < 2 || release_seen < 2); index = index + 1)
            @(posedge clk);
        if (result_seen != 2 || release_seen != 2 || error || accepted_images != 2 ||
            completed_images != 2 || model_ar_count != 1 || input_beat_count != 2304)
            $fatal(1, "image service mismatch results=%0d releases=%0d accepted=%0d completed=%0d model_ar=%0d input_beats=%0d error=%0d code=%0d",
                   result_seen, release_seen, accepted_images, completed_images,
                   model_ar_count, input_beat_count, error, error_code);
        $display("NPU_IMAGE_SERVICE_PASS results=%0d releases=%0d model_ar=%0d input_beats=%0d",
                 result_seen, release_seen, model_ar_count, input_beat_count);
        $finish;
    end
endmodule
