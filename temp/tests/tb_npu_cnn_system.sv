`timescale 1ns / 1ps

module tb_npu_cnn_system;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT1_ADDR = 32'h8002_0000;
    localparam [31:0] INPUT2_ADDR = 32'h8002_1000;
    localparam [31:0] NPU_BASE = 32'h4000_0100;
    localparam integer MODEL_BYTES = 512;
    localparam integer INPUT_BYTES = 4096;
    localparam integer MEM_BYTES = 262144;

    reg ddr_clk = 1'b0;
    reg cpu_clk = 1'b0;
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
    reg [31:0] batch_model_base;
    reg [31:0] batch_model_bytes;
    reg [7:0] batch_count;
    reg [7:0] batch_class_count;
    reg [5:0] batch_quant_shift;
    reg [255:0] batch_boxes;
    reg [11:0] batch_colors;

    wire int8_release_valid;
    wire int8_release_bank;
    wire [31:0] int8_release_frame;
    wire busy;
    wire npu_error;
    wire [7:0] npu_error_code;
    wire [31:0] accepted_batches;
    wire [31:0] completed_batches;
    wire [31:0] dropped_batches;
    wire [31:0] completed_rois;
    wire [31:0] error_rois;
    wire [31:0] released_banks;
    wire [31:0] fifo_overflows;
    wire result_reject;

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
    reg axi_rlast = 1'b0;
    reg axi_rvalid = 1'b0;
    wire axi_rready;

    reg mmio_valid = 1'b0;
    reg mmio_wen = 1'b0;
    reg [31:0] mmio_addr = 0;
    reg [31:0] mmio_wdata = 0;
    reg [3:0] mmio_wstrb = 0;
    wire mmio_ready;
    wire [31:0] mmio_rdata;
    wire irq;
    wire start_pulse;
    wire [31:0] control_input_addr;
    wire [31:0] control_weight_addr;
    wire [31:0] control_output_addr;
    wire [31:0] control_task_bytes;

    reg [7:0] mem [0:MEM_BYTES-1];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer ddr_cycle;
    integer lane;
    integer index;
    integer release_count;
    integer timeout;
    integer model_offset;
    integer input1_offset;
    integer input2_offset;
    reg [31:0] status_word;
    reg [31:0] result_word [0:7];
    reg [7:0] result_camera;
    reg [31:0] result_frame;
    reg [7:0] result_class;
    reg [31:0] result_score;
    reg [15:0] result_confidence;
    reg result_reject_word;
    string model_hex;
    string input1_hex;
    string input2_hex;

    always #5 ddr_clk = ~ddr_clk;
    always #7 cpu_clk = ~cpu_clk;

    Hnpu_system #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000),
        .NPU_MMIO_BASE(NPU_BASE), .NPU_MMIO_BYTES(32'h100),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(8), .RESULT_FIFO_DEPTH(4),
        .MAX_ROIS(4), .MAX_FEATURES(1024), .MAX_CLASSES(11),
        .ENGINE_MODE(1), .MAX_MODEL_BYTES(65536)
    ) dut (
        .ddr_clk(ddr_clk), .cpu_clk(cpu_clk), .rst_n(rst_n),
        .enable(enable), .clear_errors(clear_errors), .stop(stop),
        .batch_valid(batch_valid), .batch_ready(batch_ready),
        .batch_camera(batch_camera), .batch_frame(batch_frame), .batch_bank(batch_bank),
        .batch_input_base(batch_input_base), .batch_input_stride(batch_input_stride),
        .batch_input_bytes(batch_input_bytes), .batch_feature_count(batch_feature_count),
        .batch_weight_base(batch_weight_base), .batch_weight_stride(batch_weight_stride),
        .batch_bias_base(batch_bias_base), .batch_model_base(batch_model_base),
        .batch_model_bytes(batch_model_bytes), .batch_count(batch_count),
        .batch_class_count(batch_class_count), .batch_quant_shift(batch_quant_shift),
        .batch_boxes(batch_boxes), .batch_colors(batch_colors),
        .int8_release_valid(int8_release_valid), .int8_release_bank(int8_release_bank),
        .int8_release_frame(int8_release_frame), .busy(busy), .error(npu_error),
        .error_code(npu_error_code), .accepted_batches(accepted_batches),
        .completed_batches(completed_batches), .dropped_batches(dropped_batches),
        .completed_rois(completed_rois), .error_rois(error_rois),
        .released_banks(released_banks), .fifo_overflows(fifo_overflows),
        .result_reject(result_reject),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
        .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready),
        .mmio_valid(mmio_valid), .mmio_wen(mmio_wen), .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata), .mmio_wstrb(mmio_wstrb), .mmio_ready(mmio_ready),
        .mmio_rdata(mmio_rdata), .irq(irq), .start_pulse(start_pulse),
        .control_engine_done(1'b0), .control_input_addr(control_input_addr),
        .control_weight_addr(control_weight_addr),
        .control_output_addr(control_output_addr),
        .control_task_bytes(control_task_bytes)
    );

    // Behavioural 256-bit DDR read slave.  It intentionally inserts both
    // AR and R stalls so the system test exercises the same backpressure as
    // the direct engine tests.
    always @(posedge ddr_clk or negedge rst_n) begin
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
            ddr_cycle <= 0;
        end else begin
            ddr_cycle <= ddr_cycle + 1;
            axi_arready <= !rd_active && !axi_rvalid && (ddr_cycle[1:0] != 2'b00);
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "CNN system AXI metadata mismatch");
                if ((axi_araddr + ((axi_arlen + 1) << 5)) > MEM_BYTES)
                    $fatal(1, "CNN system AXI address outside test memory");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1'b1;
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
            end else if (rd_active && (ddr_cycle[1:0] != 2'b01)) begin
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

    always @(posedge ddr_clk) begin
        if (rst_n && int8_release_valid) begin
            if (release_count == 0 &&
                (int8_release_bank != 0 || int8_release_frame != 32'h101))
                $fatal(1, "CNN system CAM1 release mismatch");
            if (release_count == 1 &&
                (int8_release_bank != 1 || int8_release_frame != 32'h202))
                $fatal(1, "CNN system CAM2 release mismatch");
            if (release_count > 1)
                $fatal(1, "CNN system emitted an extra release");
            release_count <= release_count + 1;
        end
    end

    task send_batch;
        input [7:0] cam;
        input [31:0] frame;
        input bank;
        input [31:0] input_base;
        input [63:0] box;
        begin : send_loop
            @(negedge ddr_clk);
            batch_camera = cam;
            batch_frame = frame;
            batch_bank = bank;
            batch_input_base = input_base;
            batch_input_stride = INPUT_BYTES;
            batch_input_bytes = INPUT_BYTES;
            batch_feature_count = INPUT_BYTES;
            batch_weight_base = 0;
            batch_weight_stride = 0;
            batch_bias_base = 0;
            batch_model_base = MODEL_ADDR;
            batch_model_bytes = MODEL_BYTES;
            batch_count = 1;
            batch_class_count = 2;
            batch_quant_shift = 0;
            batch_boxes = 0;
            batch_boxes[63:0] = box;
            batch_colors = 0;
            batch_valid = 1'b1;
            while (1) begin
                @(posedge ddr_clk);
                if (batch_ready) begin
                    @(negedge ddr_clk);
                    batch_valid = 1'b0;
                    disable send_loop;
                end
            end
        end
    endtask

    task mmio_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(negedge cpu_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b0;
            mmio_addr = addr;
            mmio_wdata = 0;
            mmio_wstrb = 0;
            #1 data = mmio_rdata;
            @(negedge cpu_clk);
            mmio_valid = 1'b0;
            mmio_addr = 0;
        end
    endtask

    task mmio_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge cpu_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b1;
            mmio_addr = addr;
            mmio_wdata = data;
            mmio_wstrb = 4'b0001;
            @(posedge cpu_clk);
            @(negedge cpu_clk);
            mmio_valid = 1'b0;
            mmio_wen = 1'b0;
            mmio_addr = 0;
            mmio_wdata = 0;
            mmio_wstrb = 0;
        end
    endtask

    task read_result_record;
        integer word_index;
        begin
            for (word_index = 0; word_index < 8; word_index = word_index + 1)
                mmio_read(NPU_BASE + 32'h24 + word_index * 4, result_word[word_index]);
            result_camera = result_word[0][7:0];
            result_frame = {result_word[1][7:0], result_word[0][31:8]};
            result_class = result_word[3][27:20];
            result_confidence = {result_word[4][11:0], result_word[3][31:28]};
            result_score = {result_word[5][19:0], result_word[4][31:20]};
            result_reject_word = result_word[5][20];
        end
    endtask

    initial begin : test
        if (!$value$plusargs("MODEL_HEX=%s", model_hex))
            $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("INPUT1_HEX=%s", input1_hex))
            $fatal(1, "INPUT1_HEX is required");
        if (!$value$plusargs("INPUT2_HEX=%s", input2_hex))
            $fatal(1, "INPUT2_HEX is required");

        model_offset = MODEL_ADDR - DDR_BASE;
        input1_offset = INPUT1_ADDR - DDR_BASE;
        input2_offset = INPUT2_ADDR - DDR_BASE;
        if (model_offset + MODEL_BYTES > MEM_BYTES ||
            input1_offset + INPUT_BYTES > MEM_BYTES ||
            input2_offset + INPUT_BYTES > MEM_BYTES)
            $fatal(1, "CNN system test memory image exceeds test memory");
        for (index = 0; index < MEM_BYTES; index = index + 1)
            mem[index] = 0;
        $readmemh(model_hex, mem, model_offset, model_offset + MODEL_BYTES - 1);
        $readmemh(input1_hex, mem, input1_offset, input1_offset + INPUT_BYTES - 1);
        $readmemh(input2_hex, mem, input2_offset, input2_offset + INPUT_BYTES - 1);

        batch_camera = 0;
        batch_frame = 0;
        batch_bank = 0;
        batch_input_base = 0;
        batch_input_stride = 0;
        batch_input_bytes = 0;
        batch_feature_count = 0;
        batch_weight_base = 0;
        batch_weight_stride = 0;
        batch_bias_base = 0;
        batch_model_base = 0;
        batch_model_bytes = 0;
        batch_count = 0;
        batch_class_count = 0;
        batch_quant_shift = 0;
        batch_boxes = 0;
        batch_colors = 0;
        release_count = 0;

        repeat (4) @(posedge cpu_clk);
        rst_n = 1'b1;
        mmio_write(NPU_BASE + 32'h48, 32'h1);
        send_batch(8'd1, 32'h101, 1'b0, INPUT1_ADDR,
                   64'h0000_0004_0000_0003);
        send_batch(8'd2, 32'h202, 1'b1, INPUT2_ADDR,
                   64'h0000_0002_0000_0001);

        begin : wait_compute
            for (timeout = 0; timeout < 20000000; timeout = timeout + 1) begin
                @(posedge ddr_clk);
                if (release_count == 2)
                    disable wait_compute;
            end
            $fatal(1, "CNN system compute timeout accepted=%0d completed=%0d busy=%0d error=%0d code=%0d",
                   accepted_batches, completed_batches, busy, npu_error, npu_error_code);
        end
        begin : wait_fifo
            for (timeout = 0; timeout < 2000; timeout = timeout + 1) begin
                mmio_read(NPU_BASE + 32'h20, status_word);
                if (!status_word[16])
                    disable wait_fifo;
            end
            $fatal(1, "CNN system result FIFO timeout status=%08x accepted=%0d completed=%0d busy=%0d batch_ready=%0d error=%0d code=%0d",
                   status_word, accepted_batches, completed_batches, busy,
                   batch_ready, npu_error, npu_error_code);
        end

        read_result_record;
        if (result_camera != 1 || result_frame != 32'h101 || result_class != 0 ||
            result_score != 0 || result_confidence != 0 ||
            result_reject_word != 0)
            $fatal(1, "CNN system result 0 mismatch cam=%0d frame=%x class=%0d score=%0d conf=%0d reject=%0d",
                   result_camera, result_frame, result_class, result_score,
                   result_confidence, result_reject_word);
        mmio_write(NPU_BASE + 32'h44, 32'h1);

        begin : wait_second
            for (timeout = 0; timeout < 200000; timeout = timeout + 1) begin
                mmio_read(NPU_BASE + 32'h20, status_word);
                if (!status_word[16])
                    disable wait_second;
            end
            $fatal(1, "CNN system second result timeout");
        end

        read_result_record;
        if (result_camera != 2 || result_frame != 32'h202 || result_class != 0 ||
            result_score != 0 || result_confidence != 0 ||
            result_reject_word != 0)
            $fatal(1, "CNN system result 1 mismatch cam=%0d frame=%x class=%0d score=%0d conf=%0d reject=%0d",
                   result_camera, result_frame, result_class, result_score,
                   result_confidence, result_reject_word);
        mmio_write(NPU_BASE + 32'h44, 32'h1);

        repeat (6) @(posedge cpu_clk);
        mmio_read(NPU_BASE + 32'h20, status_word);
        if (!status_word[16] || irq)
            $fatal(1, "CNN system result FIFO did not empty");
        if (release_count != 2 || accepted_batches != 2 || completed_batches != 2 ||
            completed_rois != 2 || released_banks != 2 || error_rois != 0 ||
            fifo_overflows != 0 || dropped_batches != 0 || npu_error)
            $fatal(1, "CNN system counters mismatch accepted=%0d completed=%0d rois=%0d releases=%0d errors=%0d fifo=%0d drop=%0d hwerr=%0d code=%0d",
                   accepted_batches, completed_batches, completed_rois, released_banks,
                   error_rois, fifo_overflows, dropped_batches, npu_error, npu_error_code);
        $display("NPU_CNN_SYSTEM_PASS results=2 releases=%0d", release_count);
        $finish;
    end
endmodule
