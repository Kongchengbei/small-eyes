`timescale 1ns / 1ps

// V1 shared NPU service regression.
// The DDR model is deliberately small, but keeps the production contract:
// 256-bit data, 32-byte beats, AXI ID checking, RLAST, and ready/valid stalls.
module tb_npu_service;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] INPUT0 = 32'h8000_1000;
    localparam [31:0] INPUT1 = 32'h8000_1100;
    localparam [31:0] WEIGHT = 32'h8000_2000;
    localparam [31:0] BIAS = 32'h8000_3000;

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
    reg [31:0] batch_weight_base;
    reg [31:0] batch_weight_stride;
    reg [31:0] batch_bias_base;
    reg [7:0] batch_count;
    reg [7:0] batch_class_count;
    reg [5:0] batch_quant_shift;
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

    reg [255:0] mem [0:2047];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer read_count;
    integer result_seen;
    integer release_seen;
    integer i;
    integer lane;

    always #5 clk = ~clk;

    Hnpu_service #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(8), .MAX_ROIS(4),
        .MAX_FEATURES(32), .MAX_CLASSES(3)
    ) dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_errors(clear_errors), .stop(stop),
        .batch_valid(batch_valid), .batch_ready(batch_ready),
        .batch_camera(batch_camera), .batch_frame(batch_frame), .batch_bank(batch_bank),
        .batch_input_base(batch_input_base), .batch_input_stride(batch_input_stride),
        .batch_input_bytes(batch_input_bytes), .batch_feature_count(batch_feature_count),
        .batch_weight_base(batch_weight_base), .batch_weight_stride(batch_weight_stride),
        .batch_bias_base(batch_bias_base), .batch_count(batch_count),
        .batch_class_count(batch_class_count), .batch_quant_shift(batch_quant_shift),
        .batch_boxes(batch_boxes), .batch_colors(batch_colors),
        .result_valid(result_valid), .result_ready(result_ready),
        .result_camera(result_camera), .result_frame(result_frame), .result_bank(result_bank),
        .result_roi(result_roi), .result_box(result_box), .result_color(result_color),
        .result_class(result_class), .result_confidence(result_confidence),
        .result_error(result_error), .result_record(result_record),
        .int8_release_valid(int8_release_valid),
        .int8_release_bank(int8_release_bank), .int8_release_frame(int8_release_frame),
        .busy(busy), .error(npu_error), .error_code(npu_error_code),
        .accepted_batches(accepted_batches), .completed_batches(completed_batches),
        .dropped_batches(dropped_batches), .completed_rois(completed_rois),
        .error_rois(error_rois), .released_banks(released_banks),
        .fifo_overflows(fifo_overflows),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready), .axi_rdata(axi_rdata), .axi_rid(axi_rid),
        .axi_rresp(axi_rresp), .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready)
    );

    // A one-request-in-flight AXI read slave with periodic address/data stalls.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rdata <= 0;
            axi_rid <= 0;
            axi_rresp <= 0;
            axi_rlast <= 0;
            rd_active <= 1'b0;
            rd_addr <= 0;
            rd_left <= 0;
            rd_id <= 0;
            cycle_count <= 0;
            read_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid && (cycle_count[1:0] != 2'b00);

            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "NPU AXI AR metadata incorrect");
                if (({20'd0, axi_araddr[11:0]} +
                     (({24'd0, axi_arlen} + 32'd1) << 5)) > 32'd4096)
                    $fatal(1, "NPU AXI burst crossed 4 KiB");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1;
                rd_id <= axi_arid;
                read_count <= read_count + 1;
            end

            if (axi_rvalid) begin
                if (axi_rready) begin
                    axi_rvalid <= 1'b0;
                    if (rd_left == 1) begin
                        rd_active <= 1'b0;
                    end else begin
                        rd_left <= rd_left - 1'b1;
                        rd_addr <= rd_addr + 30'd32;
                    end
                end
            end else if (rd_active && (cycle_count[1:0] != 2'b01)) begin
                axi_rdata <= mem[rd_addr[15:5]];
                axi_rid <= rd_id;
                axi_rresp <= 2'b00;
                axi_rlast <= (rd_left == 1);
                axi_rvalid <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && result_valid && result_ready) begin
            if (result_record[7:0] !== result_camera ||
                result_record[39:8] !== result_frame ||
                result_record[40] !== result_bank ||
                result_record[48:41] !== result_roi ||
                result_record[112:49] !== result_box ||
                result_record[115:113] !== result_color ||
                result_record[123:116] !== result_class ||
                result_record[139:124] !== result_confidence ||
                result_record[147:140] !== result_error)
                $fatal(1, "packed NPU result record mismatch");
            case (result_seen)
                0: begin
                    if (result_camera != 8'd1 || result_frame != 32'h0000_0101 ||
                        result_roi != 0 || result_class != 0 || result_error != 0 ||
                        result_box != 64'h0000_0004_0000_0003 || result_color != 3'd1)
                        $fatal(1, "CAM1 ROI0 result mismatch cam=%0d frame=%08x roi=%0d class=%0d box=%016x",
                               result_camera, result_frame, result_roi, result_class, result_box);
                end
                1: begin
                    if (result_camera != 8'd1 || result_frame != 32'h0000_0101 ||
                        result_roi != 1 || result_class != 2 || result_error != 0 ||
                        result_box != 64'h0000_0008_0000_0007 || result_color != 3'd2)
                        $fatal(1, "CAM1 ROI1 result mismatch");
                end
                2: begin
                    if (result_camera != 8'd2 || result_frame != 32'h0000_0202 ||
                        result_roi != 0 || result_class != 0 || result_error != 0)
                        $fatal(1, "CAM2 ROI0 result mismatch");
                end
                default: $fatal(1, "unexpected extra result");
            endcase
            result_seen <= result_seen + 1;
        end
        if (rst_n && int8_release_valid) begin
            case (release_seen)
                0: if (int8_release_bank != 1'b0 || int8_release_frame != 32'h101)
                       $fatal(1, "CAM1 release mismatch");
                1: if (int8_release_bank != 1'b1 || int8_release_frame != 32'h202)
                       $fatal(1, "CAM2 release mismatch");
                default: $fatal(1, "unexpected extra bank release");
            endcase
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
        input [2:0] color0;
        input [2:0] color1;
        @(negedge clk);
        batch_camera = cam;
        batch_frame = frame;
        batch_bank = bank;
        batch_input_base = input_base;
        batch_input_stride = 32;
        batch_input_bytes = 32;
        batch_feature_count = 32;
        batch_weight_base = WEIGHT;
        batch_weight_stride = 32;
        batch_bias_base = BIAS;
        batch_count = count;
        batch_class_count = 3;
        batch_quant_shift = 0;
        batch_boxes = 0;
        batch_colors = 0;
        batch_boxes[63:0] = box0;
        batch_boxes[127:64] = box1;
        batch_colors[2:0] = color0;
        batch_colors[5:3] = color1;
        batch_valid = 1'b1;
        // Keep valid asserted through exactly one ready/valid transfer, then
        // remove it before the following rising edge.
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
    endtask

    integer word_index;
    initial begin
        batch_camera = 0; batch_frame = 0; batch_bank = 0;
        batch_input_base = 0; batch_input_stride = 0; batch_input_bytes = 0;
        batch_feature_count = 0; batch_weight_base = 0; batch_weight_stride = 0;
        batch_bias_base = 0; batch_count = 0; batch_class_count = 0;
        batch_quant_shift = 0; batch_boxes = 0; batch_colors = 0;
        result_seen = 0; release_seen = 0; cycle_count = 0;
        for (word_index = 0; word_index < 2048; word_index = word_index + 1)
            mem[word_index] = 0;

        // CAM1 ROI0 = +3 => class 0; ROI1 = -2 => class 2.
        for (lane = 0; lane < 32; lane = lane + 1) begin
            mem[(INPUT0 - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd3;
            mem[((INPUT0 + 32'h20 - DDR_BASE) >> 5)][lane*8 +: 8] = -8'sd2;
            // CAM2 ROI0 = +1 => class 0.
            mem[(INPUT1 - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[(WEIGHT - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[((WEIGHT + 32 - DDR_BASE) >> 5)][lane*8 +: 8] = 8'sd0;
            mem[((WEIGHT + 64 - DDR_BASE) >> 5)][lane*8 +: 8] = -8'sd1;
        end
        for (lane = 0; lane < 3; lane = lane + 1)
            mem[(BIAS - DDR_BASE) >> 5][lane*32 +: 32] = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        send_batch(8'd1, 32'h101, 1'b0, INPUT0, 2,
                   64'h0000_0004_0000_0003, 64'h0000_0008_0000_0007,
                   3'd1, 3'd2);
        send_batch(8'd2, 32'h202, 1'b1, INPUT1, 1,
                   64'h0000_0002_0000_0001, 64'd0, 3'd3, 3'd0);

        begin : wait_done
            integer timeout;
            for (timeout = 0; timeout < 20000; timeout = timeout + 1) begin
                @(posedge clk);
                if (result_seen == 3 && release_seen == 2)
                    disable wait_done;
            end
            $fatal(1, "NPU service timeout results=%0d releases=%0d reads=%0d",
                   result_seen, release_seen, read_count);
        end

        if (accepted_batches != 2 || completed_batches != 2 || dropped_batches != 0 ||
            completed_rois != 3 || error_rois != 0 || released_banks != 2 ||
            fifo_overflows != 0 || npu_error)
            $fatal(1, "NPU service counters mismatch accepted=%0d completed=%0d dropped=%0d rois=%0d errors=%0d releases=%0d",
                   accepted_batches, completed_batches, dropped_batches, completed_rois,
                   error_rois, released_banks);

        $display("NPU_SERVICE_PASS results=%0d releases=%0d reads=%0d", result_seen,
                 release_seen, read_count);
        $finish;
    end
endmodule
