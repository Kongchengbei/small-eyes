`timescale 1ns / 1ps

module tb_npu_cnn_service;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT1_ADDR = 32'h8002_0000;
    localparam [31:0] INPUT2_ADDR = 32'h8002_1000;
    localparam integer MODEL_BYTES = 512;
    localparam integer INPUT_BYTES = 4096;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg enable = 1'b1;
    reg clear_errors = 1'b0;
    reg stop = 1'b0;
    reg batch_valid = 1'b0;
    wire batch_ready;
    reg [7:0] batch_camera;
    reg [31:0] batch_frame;
    reg batch_bank;
    reg [31:0] batch_input_base;
    reg [31:0] batch_input_stride;
    reg [31:0] batch_input_bytes;
    reg [15:0] batch_feature_count;
    reg [31:0] batch_weight_base = 0;
    reg [31:0] batch_weight_stride = 0;
    reg [31:0] batch_bias_base = 0;
    reg [31:0] batch_model_base;
    reg [31:0] batch_model_bytes;
    reg [7:0] batch_count;
    reg [7:0] batch_class_count;
    reg [5:0] batch_quant_shift = 0;
    reg [255:0] batch_boxes;
    reg [11:0] batch_colors;

    wire result_valid;
    reg result_ready = 1'b1;
    wire [7:0] result_camera;
    wire [31:0] result_frame;
    wire result_bank;
    wire [7:0] result_roi;
    wire [63:0] result_box;
    wire [2:0] result_color;
    wire [7:0] result_class;
    wire [15:0] result_confidence;
    wire [31:0] result_score;
    wire result_reject;
    wire [7:0] result_error;
    wire [255:0] result_record;
    wire int8_release_valid;
    wire int8_release_bank;
    wire [31:0] int8_release_frame;
    wire busy;
    wire npu_error;
    wire [7:0] npu_error_code;
    wire [31:0] accepted_batches, completed_batches, dropped_batches;
    wire [31:0] completed_rois, error_rois, released_banks, fifo_overflows;

    wire [29:0] axi_araddr;
    wire [7:0] axi_arid;
    wire [7:0] axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid;
    reg axi_arready = 1'b0;
    reg [255:0] axi_rdata = 0;
    reg [7:0] axi_rid = 0;
    reg [1:0] axi_rresp = 0;
    reg axi_rlast = 0;
    reg axi_rvalid = 0;
    wire axi_rready;

    reg [7:0] mem [0:262143];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer index;
    integer lane;
    integer result_seen;
    integer release_seen;
    integer timeout;
    integer model_offset;
    integer input1_offset;
    integer input2_offset;
    string model_hex;
    string input1_hex;
    string input2_hex;

    always #5 clk = ~clk;

    Hnpu_service #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0004_0000), .AXI_ID(8'h80),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(8), .MAX_ROIS(4),
        .MAX_FEATURES(1024), .MAX_CLASSES(11), .ENGINE_MODE(1),
        .MAX_MODEL_BYTES(65536)
    ) dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_errors(clear_errors),
        .stop(stop), .batch_valid(batch_valid), .batch_ready(batch_ready),
        .batch_camera(batch_camera), .batch_frame(batch_frame), .batch_bank(batch_bank),
        .batch_input_base(batch_input_base), .batch_input_stride(batch_input_stride),
        .batch_input_bytes(batch_input_bytes), .batch_feature_count(batch_feature_count),
        .batch_weight_base(batch_weight_base), .batch_weight_stride(batch_weight_stride),
        .batch_bias_base(batch_bias_base), .batch_model_base(batch_model_base),
        .batch_model_bytes(batch_model_bytes), .batch_count(batch_count),
        .batch_class_count(batch_class_count), .batch_quant_shift(batch_quant_shift),
        .batch_boxes(batch_boxes), .batch_colors(batch_colors),
        .result_valid(result_valid), .result_ready(result_ready),
        .result_camera(result_camera), .result_frame(result_frame), .result_bank(result_bank),
        .result_roi(result_roi), .result_box(result_box), .result_color(result_color),
        .result_class(result_class), .result_confidence(result_confidence),
        .result_score(result_score), .result_reject(result_reject),
        .result_error(result_error), .result_record(result_record),
        .int8_release_valid(int8_release_valid), .int8_release_bank(int8_release_bank),
        .int8_release_frame(int8_release_frame), .busy(busy), .error(npu_error),
        .error_code(npu_error_code), .accepted_batches(accepted_batches),
        .completed_batches(completed_batches), .dropped_batches(dropped_batches),
        .completed_rois(completed_rois), .error_rois(error_rois),
        .released_banks(released_banks), .fifo_overflows(fifo_overflows),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
        .axi_rresp(axi_rresp), .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
            rd_active <= 1'b0;
            rd_addr <= 0;
            rd_left <= 0;
            rd_id <= 0;
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rdata <= 0;
            axi_rid <= 0;
            axi_rresp <= 0;
            axi_rlast <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid && (cycle_count[1:0] != 2'b00);
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "CNN service AXI metadata mismatch");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1;
                rd_id <= axi_arid;
            end
            if (axi_rvalid) begin
                if (axi_rready) begin
                    axi_rvalid <= 1'b0;
                    if (rd_left == 1)
                        rd_active <= 1'b0;
                    else begin
                        rd_left <= rd_left - 1'b1;
                        rd_addr <= rd_addr + 30'd32;
                    end
                end
            end else if (rd_active && (cycle_count[1:0] != 2'b01)) begin
                axi_rdata <= 0;
                for (lane = 0; lane < 32; lane = lane + 1)
                    axi_rdata[lane*8 +: 8] <= mem[rd_addr + lane];
                axi_rid <= rd_id;
                axi_rresp <= 2'b00;
                axi_rlast <= (rd_left == 1);
                axi_rvalid <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && result_valid && result_ready) begin
            if (result_seen == 0) begin
                if (result_camera != 1 || result_frame != 32'h101 || result_roi != 0 ||
                    result_class != 0 || result_score != 0 || result_confidence != 0 ||
                    result_reject != 0 || result_record[180] != 0 || result_error != 0 ||
                    result_box != 64'h0000_0004_0000_0003)
                    $fatal(1, "CNN CAM1 result mismatch cam=%0d frame=%x roi=%0d class=%0d score=%0d conf=%0d reject=%0d error=%0d",
                           result_camera, result_frame, result_roi, result_class,
                           result_score, result_confidence, result_reject, result_error);
            end else if (result_seen == 1) begin
                if (result_camera != 2 || result_frame != 32'h202 || result_roi != 0 ||
                    result_class != 0 || result_score != 0 || result_confidence != 0 ||
                    result_reject != 0 || result_record[180] != 0 || result_error != 0)
                    $fatal(1, "CNN CAM2 result mismatch cam=%0d frame=%x roi=%0d class=%0d score=%0d conf=%0d reject=%0d error=%0d",
                           result_camera, result_frame, result_roi, result_class,
                           result_score, result_confidence, result_reject, result_error);
            end else begin
                $fatal(1, "unexpected extra CNN result");
            end
            result_seen <= result_seen + 1;
        end
        if (rst_n && int8_release_valid) begin
            if (release_seen == 0 &&
                (int8_release_bank != 0 || int8_release_frame != 32'h101))
                $fatal(1, "CNN CAM1 release mismatch");
            if (release_seen == 1 &&
                (int8_release_bank != 1 || int8_release_frame != 32'h202))
                $fatal(1, "CNN CAM2 release mismatch");
            if (release_seen > 1)
                $fatal(1, "unexpected extra CNN release");
            release_seen <= release_seen + 1;
        end
    end

    task send_batch;
        input [7:0] cam;
        input [31:0] frame;
        input bank;
        input [31:0] input_base;
        input [7:0] count;
        input [63:0] box0;
        input [63:0] box1;
        begin
            @(negedge clk);
            batch_camera = cam;
            batch_frame = frame;
            batch_bank = bank;
            batch_input_base = input_base;
            batch_input_stride = INPUT_BYTES;
            batch_input_bytes = INPUT_BYTES;
            // CNN mode describes the complete HWC4 tensor, not the number of
            // bytes in the model's FC feature vector.
            batch_feature_count = INPUT_BYTES;
            batch_model_base = MODEL_ADDR;
            batch_model_bytes = MODEL_BYTES;
            batch_count = count;
            batch_class_count = 2;
            batch_boxes = 0;
            batch_boxes[63:0] = box0;
            batch_boxes[127:64] = box1;
            batch_colors = 0;
            batch_valid = 1'b1;
            begin : send_loop
                while (1) begin
                    @(posedge clk);
                    if (batch_ready) begin
                        @(negedge clk);
                        batch_valid = 1'b0;
                        disable send_loop;
                    end
                end
            end
        end
    endtask

    initial begin
        if (!$value$plusargs("MODEL_HEX=%s", model_hex))
            $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("INPUT1_HEX=%s", input1_hex))
            $fatal(1, "INPUT1_HEX is required");
        if (!$value$plusargs("INPUT2_HEX=%s", input2_hex))
            $fatal(1, "INPUT2_HEX is required");
        for (index = 0; index < 262144; index = index + 1)
            mem[index] = 0;
        model_offset = MODEL_ADDR - DDR_BASE;
        input1_offset = INPUT1_ADDR - DDR_BASE;
        input2_offset = INPUT2_ADDR - DDR_BASE;
        $readmemh(model_hex, mem, model_offset, model_offset + MODEL_BYTES - 1);
        $readmemh(input1_hex, mem, input1_offset, input1_offset + INPUT_BYTES - 1);
        $readmemh(input2_hex, mem, input2_offset, input2_offset + INPUT_BYTES - 1);

        batch_camera = 0; batch_frame = 0; batch_bank = 0;
        batch_input_base = 0; batch_input_stride = 0; batch_input_bytes = 0;
        batch_feature_count = 0; batch_model_base = 0; batch_model_bytes = 0;
        batch_count = 0; batch_class_count = 0; batch_boxes = 0; batch_colors = 0;
        result_seen = 0;
        release_seen = 0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        send_batch(1, 32'h101, 0, INPUT1_ADDR, 1,
                   64'h0000_0004_0000_0003, 64'd0);
        send_batch(2, 32'h202, 1, INPUT2_ADDR, 1,
                   64'h0000_0002_0000_0001, 64'd0);

        begin : wait_done
            for (timeout = 0; timeout < 20000000; timeout = timeout + 1) begin
                @(posedge clk);
                if (result_seen == 2 && release_seen == 2)
                    disable wait_done;
            end
            $fatal(1, "CNN service timeout results=%0d releases=%0d",
                   result_seen, release_seen);
        end

        if (accepted_batches != 2 || completed_batches != 2 || dropped_batches != 0 ||
            completed_rois != 2 || error_rois != 0 || released_banks != 2 ||
            fifo_overflows != 0 || npu_error)
            $fatal(1, "CNN service counters mismatch accepted=%0d completed=%0d dropped=%0d rois=%0d errors=%0d releases=%0d error=%0d",
                   accepted_batches, completed_batches, dropped_batches, completed_rois,
                   error_rois, released_banks, npu_error);

        $display("NPU_CNN_SERVICE_PASS results=%0d releases=%0d", result_seen, release_seen);
        $finish;
    end
endmodule
