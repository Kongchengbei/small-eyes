`timescale 1ns / 1ps

// Class-count limit test for the batch path (Hnpu_service + engine).
//
// The DUT keeps its default MAX_CLASSES so the test follows the shipped
// default; -DDUT_MAX_CLASSES=n overrides it for the control run only.
//
//   +MODEL_HEX=f       model package, one hex byte per line
//   +INPUT_HEX=f       ROI_COUNT 32x32x4 tensors back to back, one hex byte per line
//   +EXPECTED_FILE=f   one "class margin reject score" row per ROI
//   +MODEL_BYTES=n     package size in bytes
//   +ROI_COUNT=n       number of ROIs (sent as batches of up to 4)
//   +CLASS_COUNT=n     value driven on batch_class_count for the real batches
//   +LIMIT=n           class limit the batch interface must enforce
//   +EXPECT=accept     every ROI classified exactly as expected
//   +EXPECT=model_error  every ROI answered with the model-format error 0x22
module tb_npu_class_limit_service;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT_ADDR = 32'h8002_0000;
    localparam integer MEM_BYTES = 1048576;
    localparam integer INPUT_BYTES = 4096;
    localparam integer MAX_CASES = 128;
    localparam integer SWEEP_MAX = 40;
    localparam [7:0] ERR_MODEL_FORMAT = 8'h22;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg enable = 1'b1;
    reg clear_errors = 1'b0;
    reg stop = 1'b0;
    reg batch_valid = 1'b0;
    wire batch_ready;
    reg [7:0] batch_camera = 0;
    reg [31:0] batch_frame = 0;
    reg batch_bank = 0;
    reg [31:0] batch_input_base = 0;
    reg [31:0] batch_input_stride = 0;
    reg [31:0] batch_input_bytes = 0;
    reg [15:0] batch_feature_count = 0;
    reg [31:0] batch_weight_base = 0;
    reg [31:0] batch_weight_stride = 0;
    reg [31:0] batch_bias_base = 0;
    reg [31:0] batch_model_base = 0;
    reg [31:0] batch_model_bytes = 0;
    reg [7:0] batch_count = 0;
    reg [7:0] batch_class_count = 0;
    reg [5:0] batch_quant_shift = 0;
    reg [255:0] batch_boxes = 0;
    reg [11:0] batch_colors = 0;

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

    reg [7:0] mem [0:MEM_BYTES-1];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer index;
    integer lane;
    integer timeout;
    integer hs_wait;
    integer model_ar_count;
    integer result_seen;
    integer release_seen;
    integer model_bytes;
    integer roi_count;
    integer class_count;
    integer class_limit;
    integer batch_total;
    integer batch_index;
    integer first_roi;
    integer batch_rois;
    integer sweep_class;
    integer sweep_min_ready;
    integer sweep_max_ready;
    integer sweep_ready_count;
    integer expected_fd;
    integer expected_extra;
    integer check_index;
    integer check_batch;
    integer expected_class [0:MAX_CASES-1];
    integer expected_margin [0:MAX_CASES-1];
    integer expected_reject [0:MAX_CASES-1];
    integer expected_score [0:MAX_CASES-1];
    reg expect_accept;
    string model_hex;
    string input_hex;
    string expected_file;
    string expect_mode;

    always #5 clk = ~clk;

    Hnpu_service #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000), .AXI_ID(8'h80),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(8), .MAX_ROIS(4),
`ifdef DUT_MAX_CLASSES
        .MAX_CLASSES(`DUT_MAX_CLASSES),
`endif
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
            model_ar_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid && (cycle_count[1:0] != 2'b00);
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "class limit service AXI metadata mismatch");
                if ((axi_araddr + ((axi_arlen + 1) << 5)) > MEM_BYTES)
                    $fatal(1, "class limit service AXI read outside test memory");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1;
                rd_id <= axi_arid;
                if (axi_araddr >= MODEL_ADDR - DDR_BASE &&
                    axi_araddr < MODEL_ADDR - DDR_BASE + model_bytes)
                    model_ar_count <= model_ar_count + 1;
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

    // Results arrive in order: batches are sent one at a time, 4 ROIs each.
    always @(posedge clk) begin
        if (rst_n && result_valid && result_ready) begin
            check_index = result_seen;
            check_batch = check_index / 4;
            if (check_index >= roi_count)
                $fatal(1, "unexpected extra result %0d", check_index);
            $display("CLASS_LIMIT_RESULT idx=%0d class=%0d margin=%0d reject=%0d score=%0d error=%0d",
                     check_index, result_class, result_confidence, result_reject,
                     $signed(result_score), result_error);
            if (result_camera != (check_batch % 2) + 1 ||
                result_frame != 32'h0000_1000 + check_batch ||
                result_bank != (check_batch % 2) ||
                result_roi != (check_index % 4) ||
                result_box != {32'(check_index), 32'hB0B0_0000 + check_index} ||
                result_color != (check_index % 8) ||
                result_record[180] != result_reject)
                $fatal(1, "result %0d metadata mismatch cam=%0d frame=%h bank=%0d roi=%0d box=%h color=%0d",
                       check_index, result_camera, result_frame, result_bank, result_roi,
                       result_box, result_color);
            if (expect_accept) begin
                if (result_error != 0 || result_class != expected_class[check_index] ||
                    result_confidence != expected_margin[check_index] ||
                    result_reject != expected_reject[check_index] ||
                    $signed(result_score) != expected_score[check_index])
                    $fatal(1, "result %0d mismatch class=%0d/%0d margin=%0d/%0d reject=%0d/%0d score=%0d/%0d error=%0d",
                           check_index, result_class, expected_class[check_index],
                           result_confidence, expected_margin[check_index],
                           result_reject, expected_reject[check_index],
                           $signed(result_score), expected_score[check_index], result_error);
            end else begin
                if (result_error != ERR_MODEL_FORMAT || result_class != 8'hff ||
                    result_confidence != 0 || result_score != 0 || result_reject != 0)
                    $fatal(1, "result %0d is not a model-format error class=%0d margin=%0d reject=%0d score=%0d error=%0d",
                           check_index, result_class, result_confidence, result_reject,
                           $signed(result_score), result_error);
            end
            result_seen <= result_seen + 1;
        end
        if (rst_n && int8_release_valid) begin
            if (release_seen >= batch_total ||
                int8_release_bank != (release_seen % 2) ||
                int8_release_frame != 32'h0000_1000 + release_seen)
                $fatal(1, "release %0d mismatch bank=%0d frame=%h",
                       release_seen, int8_release_bank, int8_release_frame);
            release_seen <= release_seen + 1;
        end
    end

    task set_batch;
        input integer batch;
        input integer first;
        input integer count;
        integer k;
        begin
            batch_camera = (batch % 2) + 1;
            batch_frame = 32'h0000_1000 + batch;
            batch_bank = batch % 2;
            batch_input_base = INPUT_ADDR + first * INPUT_BYTES;
            batch_input_stride = INPUT_BYTES;
            batch_input_bytes = INPUT_BYTES;
            batch_feature_count = INPUT_BYTES;
            batch_model_base = MODEL_ADDR;
            batch_model_bytes = model_bytes;
            batch_count = count;
            batch_class_count = class_count;
            batch_boxes = 0;
            batch_colors = 0;
            for (k = 0; k < count; k = k + 1) begin
                batch_boxes[k*64 +: 64] = {32'(first + k), 32'hB0B0_0000 + first + k};
                batch_colors[k*3 +: 3] = (first + k) % 8;
            end
        end
    endtask

    task send_batch;
        input integer batch;
        input integer first;
        input integer count;
        begin
            @(negedge clk);
            set_batch(batch, first, count);
            batch_valid = 1'b1;
            begin : send_loop
                for (hs_wait = 0; hs_wait < 1000; hs_wait = hs_wait + 1) begin
                    @(posedge clk);
                    if (batch_ready) begin
                        @(negedge clk);
                        batch_valid = 1'b0;
                        disable send_loop;
                    end
                end
                $fatal(1, "batch %0d not accepted within 1000 cycles (batch_class_count=%0d)",
                       batch, batch_class_count);
            end
        end
    endtask

    initial begin : test
        if (!$value$plusargs("MODEL_HEX=%s", model_hex)) $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("INPUT_HEX=%s", input_hex)) $fatal(1, "INPUT_HEX is required");
        if (!$value$plusargs("EXPECTED_FILE=%s", expected_file)) $fatal(1, "EXPECTED_FILE is required");
        if (!$value$plusargs("MODEL_BYTES=%d", model_bytes)) $fatal(1, "MODEL_BYTES is required");
        if (!$value$plusargs("ROI_COUNT=%d", roi_count)) $fatal(1, "ROI_COUNT is required");
        if (!$value$plusargs("CLASS_COUNT=%d", class_count)) $fatal(1, "CLASS_COUNT is required");
        if (!$value$plusargs("LIMIT=%d", class_limit)) $fatal(1, "LIMIT is required");
        if (!$value$plusargs("EXPECT=%s", expect_mode)) $fatal(1, "EXPECT is required");
        if (expect_mode == "accept") expect_accept = 1'b1;
        else if (expect_mode == "model_error") expect_accept = 1'b0;
        else $fatal(1, "EXPECT must be accept or model_error, got %s", expect_mode);
        if (roi_count < 1 || roi_count > MAX_CASES || class_limit < 1 || class_limit > SWEEP_MAX)
            $fatal(1, "bad ROI_COUNT=%0d or LIMIT=%0d", roi_count, class_limit);
        if ((MODEL_ADDR - DDR_BASE) + model_bytes > INPUT_ADDR - DDR_BASE ||
            (INPUT_ADDR - DDR_BASE) + roi_count * INPUT_BYTES > MEM_BYTES)
            $fatal(1, "memory image exceeds test memory");

        for (index = 0; index < MEM_BYTES; index = index + 1)
            mem[index] = 0;
        $readmemh(model_hex, mem, MODEL_ADDR - DDR_BASE, MODEL_ADDR - DDR_BASE + model_bytes - 1);
        $readmemh(input_hex, mem, INPUT_ADDR - DDR_BASE,
                  INPUT_ADDR - DDR_BASE + roi_count * INPUT_BYTES - 1);
        expected_fd = $fopen(expected_file, "r");
        if (!expected_fd) $fatal(1, "cannot open EXPECTED_FILE");
        for (index = 0; index < roi_count; index = index + 1) begin
            if ($fscanf(expected_fd, "%d %d %d %d\n", expected_class[index],
                        expected_margin[index], expected_reject[index],
                        expected_score[index]) != 4)
                $fatal(1, "expected file ended at ROI %0d", index);
        end
        if ($fscanf(expected_fd, "%d", expected_extra) == 1)
            $fatal(1, "expected file has more than %0d rows", roi_count);
        $fclose(expected_fd);

        batch_total = (roi_count + 3) / 4;
        result_seen = 0;
        release_seen = 0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Phase 1: the batch interface must accept exactly 1..LIMIT classes.
        // batch_ready does not depend on batch_valid, so nothing is queued.
        @(negedge clk);
        set_batch(0, 0, (roi_count < 4) ? roi_count : 4);
        sweep_min_ready = -1;
        sweep_max_ready = -1;
        sweep_ready_count = 0;
        for (sweep_class = 0; sweep_class <= SWEEP_MAX; sweep_class = sweep_class + 1) begin
            batch_class_count = sweep_class;
            #1;
            if (batch_ready !== ((sweep_class >= 1) && (sweep_class <= class_limit)))
                $fatal(1, "batch_ready=%0d for batch_class_count=%0d with limit %0d",
                       batch_ready, sweep_class, class_limit);
            if (batch_ready) begin
                if (sweep_min_ready < 0) sweep_min_ready = sweep_class;
                sweep_max_ready = sweep_class;
                sweep_ready_count = sweep_ready_count + 1;
            end
        end
        batch_class_count = 8'hff;
        #1;
        if (batch_ready)
            $fatal(1, "batch_ready=1 for batch_class_count=255");
        if (sweep_min_ready != 1 || sweep_max_ready != class_limit ||
            sweep_ready_count != class_limit)
            $fatal(1, "interface limit mismatch min=%0d max=%0d count=%0d limit=%0d",
                   sweep_min_ready, sweep_max_ready, sweep_ready_count, class_limit);
        $display("CLASS_LIMIT_INTERFACE accepts batch_class_count %0d..%0d (limit %0d, dut MAX_CLASSES=%0d)",
                 sweep_min_ready, sweep_max_ready, class_limit, dut.MAX_CLASSES);

        // Phase 2: real batches through the engine, one at a time.
        for (batch_index = 0; batch_index < batch_total; batch_index = batch_index + 1) begin
            first_roi = batch_index * 4;
            batch_rois = (roi_count - first_roi < 4) ? roi_count - first_roi : 4;
            send_batch(batch_index, first_roi, batch_rois);
            begin : wait_batch
                for (timeout = 0; timeout < 40000000; timeout = timeout + 1) begin
                    @(posedge clk);
                    if (completed_batches == batch_index + 1 &&
                        result_seen == first_roi + batch_rois &&
                        release_seen == batch_index + 1)
                        disable wait_batch;
                end
                $fatal(1, "class limit service timeout batch=%0d completed=%0d results=%0d releases=%0d",
                       batch_index, completed_batches, result_seen, release_seen);
            end
        end
        repeat (8) @(posedge clk);

        if (accepted_batches != batch_total || completed_batches != batch_total ||
            dropped_batches != 0 || released_banks != batch_total || fifo_overflows != 0 ||
            result_seen != roi_count || release_seen != batch_total)
            $fatal(1, "counters mismatch accepted=%0d completed=%0d dropped=%0d released=%0d overflows=%0d results=%0d",
                   accepted_batches, completed_batches, dropped_batches, released_banks,
                   fifo_overflows, result_seen);
        if (expect_accept) begin
            if (completed_rois != roi_count || error_rois != 0 || npu_error || npu_error_code != 0)
                $fatal(1, "accept counters mismatch rois=%0d error_rois=%0d error=%0d code=%0d",
                       completed_rois, error_rois, npu_error, npu_error_code);
            if (model_ar_count != (model_bytes / 32 + 15) / 16)
                $fatal(1, "model was fetched %0d times instead of once", model_ar_count);
        end else begin
            if (completed_rois != 0 || error_rois != roi_count || !npu_error ||
                npu_error_code != ERR_MODEL_FORMAT)
                $fatal(1, "reject counters mismatch rois=%0d error_rois=%0d error=%0d code=%h",
                       completed_rois, error_rois, npu_error, npu_error_code);
        end

        $display("NPU_CLASS_LIMIT_SERVICE_PASS expect=%s limit=%0d service_max_classes=%0d engine_max_classes=%0d rois=%0d batches=%0d model_ar=%0d",
                 expect_mode, class_limit, dut.MAX_CLASSES, dut.u_cnn_engine.MAX_CLASSES,
                 roi_count, batch_total, model_ar_count);
        $finish;
    end
endmodule
