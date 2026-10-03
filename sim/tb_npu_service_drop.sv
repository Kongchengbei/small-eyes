`timescale 1ns / 1ps

// Queue eviction regression: the oldest pending batch is dropped as a whole,
// its input bank is released, and later batches still produce complete results.
module tb_npu_service_drop;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] INPUT = 32'h8000_1000;
    localparam [31:0] WEIGHT = 32'h8000_2000;
    localparam [31:0] BIAS = 32'h8000_3000;

    reg clk = 0, rst_n = 0;
    reg enable = 1, clear_errors = 0, stop = 0;
    reg batch_valid = 0;
    wire batch_ready;
    reg [7:0] batch_camera = 0;
    reg [31:0] batch_frame = 0, batch_input_base = 0;
    reg batch_bank = 0;
    reg [31:0] batch_input_stride = 32, batch_input_bytes = 32;
    reg [15:0] batch_feature_count = 32;
    reg [31:0] batch_weight_base = WEIGHT, batch_weight_stride = 32, batch_bias_base = BIAS;
    reg [7:0] batch_count = 1, batch_class_count = 3;
    reg [5:0] batch_quant_shift = 0;
    reg [63:0] batch_boxes = 0;
    reg [2:0] batch_colors = 0;

    wire result_valid;
    wire [7:0] result_camera, result_class, result_error;
    wire [31:0] result_frame;
    wire result_bank;
    wire [7:0] result_roi;
    wire [63:0] result_box;
    wire [2:0] result_color;
    wire [15:0] result_confidence;
    wire [255:0] result_record;
    wire int8_release_valid, int8_release_bank;
    wire [31:0] int8_release_frame;
    wire busy, npu_error;
    wire [7:0] npu_error_code;
    wire [31:0] accepted_batches, completed_batches, dropped_batches;
    wire [31:0] completed_rois, error_rois, released_banks, fifo_overflows;
    wire [29:0] axi_araddr;
    wire [7:0] axi_arid, axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid, axi_rready;
    reg axi_arready = 1, axi_rvalid = 0, axi_rlast = 0;
    reg [255:0] axi_rdata = 0;
    reg [7:0] axi_rid = 0;
    reg [1:0] axi_rresp = 0;
    reg rd_active = 0;
    reg [8:0] rd_left = 0;
    reg [29:0] rd_addr = 0;
    reg [7:0] rd_id = 0;
    reg [255:0] mem [0:2047];
    integer lane, i, result_seen, release_seen;
    reg [3:0] released_mask;

    always #5 clk = ~clk;

    Hnpu_service #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(8), .MAX_ROIS(1),
        .MAX_FEATURES(32), .MAX_CLASSES(3)
    ) dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_errors(clear_errors), .stop(stop),
        .batch_valid(batch_valid), .batch_ready(batch_ready), .batch_camera(batch_camera),
        .batch_frame(batch_frame), .batch_bank(batch_bank), .batch_input_base(batch_input_base),
        .batch_input_stride(batch_input_stride), .batch_input_bytes(batch_input_bytes),
        .batch_feature_count(batch_feature_count), .batch_weight_base(batch_weight_base),
        .batch_weight_stride(batch_weight_stride), .batch_bias_base(batch_bias_base),
        .batch_count(batch_count), .batch_class_count(batch_class_count),
        .batch_quant_shift(batch_quant_shift), .batch_boxes(batch_boxes),
        .batch_colors(batch_colors), .result_valid(result_valid), .result_ready(1'b1),
        .result_camera(result_camera), .result_frame(result_frame), .result_bank(result_bank),
        .result_roi(result_roi), .result_box(result_box), .result_color(result_color),
        .result_class(result_class), .result_confidence(result_confidence),
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
            axi_rvalid <= 0; axi_rlast <= 0; rd_active <= 0;
            rd_left <= 0; rd_addr <= 0; rd_id <= 0;
        end else begin
            if (axi_arvalid && axi_arready) begin
                rd_active <= 1;
                rd_left <= axi_arlen + 1'b1;
                rd_addr <= axi_araddr;
                rd_id <= axi_arid;
            end
            if (axi_rvalid && axi_rready) begin
                axi_rvalid <= 0;
                if (rd_left == 1)
                    rd_active <= 0;
                else begin
                    rd_left <= rd_left - 1'b1;
                    rd_addr <= rd_addr + 30'd32;
                end
            end else if (rd_active && !axi_rvalid) begin
                axi_rdata <= mem[rd_addr[15:5]];
                axi_rid <= rd_id;
                axi_rresp <= 0;
                axi_rlast <= (rd_left == 1);
                axi_rvalid <= 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && result_valid) begin
            if (result_error != 0 || result_camera != 1 ||
                (result_frame != 32'h101 && result_frame != 32'h303 && result_frame != 32'h404))
                $fatal(1, "unexpected result frame=%08x error=%0d", result_frame, result_error);
            result_seen <= result_seen + 1;
        end
        if (rst_n && int8_release_valid) begin
            if (int8_release_frame == 32'h102) released_mask[0] <= 1;
            else if (int8_release_frame == 32'h101) released_mask[1] <= 1;
            else if (int8_release_frame == 32'h303) released_mask[2] <= 1;
            else if (int8_release_frame == 32'h404) released_mask[3] <= 1;
            else $fatal(1, "unexpected release frame=%08x", int8_release_frame);
            release_seen <= release_seen + 1;
        end
    end

    task send_batch;
        input [31:0] frame;
        input bank;
        begin : send_loop
            @(negedge clk);
            batch_camera = 1;
            batch_frame = frame;
            batch_bank = bank;
            batch_input_base = INPUT;
            batch_valid = 1;
            while (1) begin
                @(posedge clk);
                if (batch_ready) begin
                    @(negedge clk);
                    batch_valid = 0;
                    disable send_loop;
                end
            end
        end
    endtask

    initial begin
        for (i = 0; i < 2048; i = i + 1) mem[i] = 0;
        for (lane = 0; lane < 32; lane = lane + 1) begin
            mem[(INPUT - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[(WEIGHT - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[((WEIGHT + 32 - DDR_BASE) >> 5)][lane*8 +: 8] = 8'sd0;
            mem[((WEIGHT + 64 - DDR_BASE) >> 5)][lane*8 +: 8] = -8'sd1;
        end
        repeat (3) @(posedge clk);
        rst_n = 1;
        result_seen = 0; release_seen = 0; released_mask = 0;

        // Batch 101 starts, 102/303 fill the pending queue, and 404 causes
        // the oldest pending batch 102 to be evicted.
        send_batch(32'h101, 0);
        send_batch(32'h102, 1);
        send_batch(32'h303, 0);
        send_batch(32'h404, 1);

        begin : wait_done
            integer timeout;
            for (timeout = 0; timeout < 12000; timeout = timeout + 1) begin
                @(posedge clk);
                if (result_seen == 3 && release_seen == 4) disable wait_done;
            end
            $fatal(1, "drop regression timeout results=%0d releases=%0d", result_seen, release_seen);
        end
        if (accepted_batches != 4 || completed_batches != 3 || dropped_batches != 1 ||
            completed_rois != 3 || error_rois != 0 || released_banks != 4 ||
            fifo_overflows != 0 || npu_error || released_mask != 4'b1111)
            $fatal(1, "drop counters accepted=%0d completed=%0d dropped=%0d releases=%0d mask=%b error=%0d",
                   accepted_batches, completed_batches, dropped_batches, released_banks,
                   released_mask, npu_error);
        $display("NPU_SERVICE_DROP_PASS results=%0d releases=%0d", result_seen, release_seen);
        $finish;
    end
endmodule
