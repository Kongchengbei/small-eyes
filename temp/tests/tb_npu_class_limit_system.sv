`timescale 1ns / 1ps

// Class-count limit test for the production path: Hnpu_system with
// IMAGE_MODE=1 (Hnpu_image_service + engine + result bridge + MMIO).
//
// The DUT keeps its default MAX_CLASSES; -DDUT_MAX_CLASSES=n overrides it for
// the control run only.  MODEL_BYTES is a top-level parameter (-GMODEL_BYTES=n)
// because the image service checks the package header against it.
//
//   +MODEL_HEX=f       model package, one hex byte per line
//   +INPUT_HEX=f       ROI_COUNT 96x96x4 images back to back, one hex byte per line
//   +EXPECTED_FILE=f   one "class margin reject score" row per image
//   +ROI_COUNT=n       number of images (sent one at a time)
//   +EXPECT=accept     every image classified exactly as expected
//   +EXPECT=model_error  every image answered with the model-format error 0x22
module tb_npu_class_limit_system #(
    parameter integer MODEL_BYTES = 62720
);
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT_ADDR = 32'h8002_0000;
    localparam [31:0] NPU_BASE = 32'h4000_0100;
    localparam integer INPUT_BYTES = 36864;
    localparam integer MEM_BYTES = 8388608;
    localparam integer MAX_CASES = 128;
    localparam [7:0] ERR_MODEL_FORMAT = 8'h22;

    reg ddr_clk = 0, cpu_clk = 0, rst_n = 0;
    reg enable = 1, clear_errors = 0, stop = 0;
    reg [1:0] image_valid = 0;
    wire [1:0] image_ready;
    reg [15:0] image_camera = 0;
    reg [63:0] image_frame = 0;
    reg [15:0] image_batch_count = 0;
    reg [15:0] image_index = 0;
    reg [127:0] image_box = 0;
    reg [5:0] image_color = 0;
    reg [3:0] image_block = 0;
    reg [7:0] image_position = 0;
    reg [63:0] image_generation = 0;
    reg [63:0] image_data_addr = 0;
    reg [31:0] image_width = {16'd96, 16'd96};
    reg [31:0] image_height = {16'd96, 16'd96};
    reg [63:0] image_data_bytes = {32'd36864, 32'd36864};
    wire [1:0] image_release_valid;
    reg [1:0] image_release_ready = 2'b11;
    wire [15:0] image_release_camera;
    wire [63:0] image_release_frame, image_release_generation;
    wire [3:0] image_release_block;
    wire [7:0] image_release_position;

    wire batch_ready, int8_release_valid, int8_release_bank;
    wire [31:0] int8_release_frame;
    wire busy, npu_error;
    wire [7:0] npu_error_code;
    wire [31:0] accepted_batches, completed_batches, dropped_batches;
    wire [31:0] completed_rois, error_rois, released_banks, fifo_overflows;
    wire result_reject;
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

    reg mmio_valid = 0, mmio_wen = 0;
    reg [31:0] mmio_addr = 0, mmio_wdata = 0;
    reg [3:0] mmio_wstrb = 0;
    wire mmio_ready, irq;
    wire [31:0] mmio_rdata;
    wire start_pulse;
    wire [31:0] control_input_addr, control_weight_addr, control_output_addr, control_task_bytes;

    reg [7:0] mem [0:MEM_BYTES-1];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer lane, index, ddr_cycle, timeout, hs_wait, result_word_index;
    integer release_count, model_ar_count, input_ar_count;
    integer roi_count, send_lane;
    integer expected_fd, expected_extra;
    integer expected_class [0:MAX_CASES-1];
    integer expected_margin [0:MAX_CASES-1];
    integer expected_reject [0:MAX_CASES-1];
    integer expected_score [0:MAX_CASES-1];
    reg expect_accept;
    reg [31:0] status_word, result_word [0:7];
    reg [7:0] rec_camera, rec_roi, rec_class, rec_error;
    reg [31:0] rec_frame;
    reg [63:0] rec_box;
    reg [2:0] rec_color;
    reg [15:0] rec_margin;
    reg [31:0] rec_score;
    reg rec_reject;
    string model_hex;
    string input_hex;
    string expected_file;
    string expect_mode;

    always #5 ddr_clk = ~ddr_clk;
    always #7 cpu_clk = ~cpu_clk;

    Hnpu_system #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(MEM_BYTES),
        .NPU_MMIO_BASE(NPU_BASE), .NPU_MMIO_BYTES(32'h100),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(4), .RESULT_FIFO_DEPTH(4),
        .MAX_ROIS(4),
`ifdef DUT_MAX_CLASSES
        .MAX_CLASSES(`DUT_MAX_CLASSES),
`endif
        .MAX_MODEL_BYTES(65536), .IMAGE_MODE(1),
        .MODEL_BASE(MODEL_ADDR), .MODEL_BYTES(MODEL_BYTES)
    ) dut (
        .ddr_clk(ddr_clk), .cpu_clk(cpu_clk), .rst_n(rst_n),
        .enable(enable), .clear_errors(clear_errors), .stop(stop),
        .batch_valid(1'b0), .batch_ready(batch_ready), .batch_camera(0),
        .batch_frame(0), .batch_bank(0), .batch_input_base(0),
        .batch_input_stride(0), .batch_input_bytes(0), .batch_feature_count(0),
        .batch_weight_base(0), .batch_weight_stride(0), .batch_bias_base(0),
        .batch_model_base(0), .batch_model_bytes(0), .batch_count(0),
        .batch_class_count(0), .batch_quant_shift(0), .batch_boxes(0), .batch_colors(0),
        .image_valid(image_valid), .image_ready(image_ready),
        .image_camera(image_camera), .image_frame(image_frame),
        .image_batch_count(image_batch_count), .image_index(image_index),
        .image_box(image_box), .image_color(image_color), .image_block(image_block),
        .image_position(image_position), .image_generation(image_generation),
        .image_data_addr(image_data_addr), .image_width(image_width),
        .image_height(image_height), .image_data_bytes(image_data_bytes),
        .int8_release_valid(int8_release_valid), .int8_release_bank(int8_release_bank),
        .int8_release_frame(int8_release_frame), .image_release_valid(image_release_valid),
        .image_release_ready(image_release_ready), .image_release_camera(image_release_camera),
        .image_release_frame(image_release_frame), .image_release_block(image_release_block),
        .image_release_position(image_release_position),
        .image_release_generation(image_release_generation), .busy(busy), .error(npu_error),
        .error_code(npu_error_code), .accepted_batches(accepted_batches),
        .completed_batches(completed_batches), .dropped_batches(dropped_batches),
        .completed_rois(completed_rois), .error_rois(error_rois),
        .released_banks(released_banks), .fifo_overflows(fifo_overflows),
        .result_reject(result_reject), .axi_araddr(axi_araddr), .axi_arid(axi_arid),
        .axi_arlen(axi_arlen), .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready), .axi_rdata(axi_rdata),
        .axi_rid(axi_rid), .axi_rresp(axi_rresp), .axi_rlast(axi_rlast),
        .axi_rvalid(axi_rvalid), .axi_rready(axi_rready), .mmio_valid(mmio_valid),
        .mmio_wen(mmio_wen), .mmio_addr(mmio_addr), .mmio_wdata(mmio_wdata),
        .mmio_wstrb(mmio_wstrb), .mmio_ready(mmio_ready), .mmio_rdata(mmio_rdata),
        .irq(irq), .start_pulse(start_pulse), .control_engine_done(1'b0),
        .control_input_addr(control_input_addr), .control_weight_addr(control_weight_addr),
        .control_output_addr(control_output_addr), .control_task_bytes(control_task_bytes)
    );

    always @(posedge ddr_clk or negedge rst_n) begin
        if (!rst_n) begin
            ddr_cycle <= 0; axi_arready <= 0; axi_rvalid <= 0; axi_rdata <= 0;
            axi_rid <= 0; axi_rresp <= 0; axi_rlast <= 0; rd_active <= 0;
            rd_addr <= 0; rd_left <= 0; rd_id <= 0;
            model_ar_count <= 0; input_ar_count <= 0;
        end else begin
            ddr_cycle <= ddr_cycle + 1;
            axi_arready <= !rd_active && !axi_rvalid && ddr_cycle[1:0] != 0;
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "class limit system AXI metadata mismatch");
                if ((axi_araddr + ((axi_arlen + 1) << 5)) > MEM_BYTES)
                    $fatal(1, "class limit system AXI read outside test memory");
                rd_active <= 1; rd_addr <= axi_araddr; rd_left <= axi_arlen + 1; rd_id <= axi_arid;
                if (axi_araddr >= MODEL_ADDR - DDR_BASE &&
                    axi_araddr < MODEL_ADDR - DDR_BASE + MODEL_BYTES)
                    model_ar_count <= model_ar_count + 1;
                else
                    input_ar_count <= input_ar_count + 1;
            end
            if (axi_rvalid) begin
                if (axi_rready) begin
                    axi_rvalid <= 0;
                    if (rd_left == 1) rd_active <= 0;
                    else begin rd_left <= rd_left - 1; rd_addr <= rd_addr + 30'd32; end
                end
            end else if (rd_active && ddr_cycle[1:0] != 1) begin
                axi_rdata <= 0;
                for (lane = 0; lane < 32; lane = lane + 1)
                    axi_rdata[lane*8 +: 8] <= mem[rd_addr + lane];
                axi_rid <= rd_id; axi_rresp <= 0; axi_rlast <= rd_left == 1; axi_rvalid <= 1;
            end
        end
    end

    // One image is in flight at a time, so releases arrive in send order.
    always @(posedge ddr_clk) begin
        if (rst_n && |(image_release_valid & image_release_ready)) begin
            if (release_count >= roi_count ||
                image_release_valid != ((release_count % 2) ? 2'b10 : 2'b01) ||
                image_release_camera[(release_count % 2)*8 +: 8] != (release_count % 2) + 1 ||
                image_release_frame[(release_count % 2)*32 +: 32] != 32'h0000_3000 + release_count ||
                image_release_block[(release_count % 2)*2 +: 2] != release_count[1:0] ||
                image_release_position[(release_count % 2)*4 +: 4] != release_count[3:0] ||
                image_release_generation[(release_count % 2)*32 +: 32] != 32'hC0DE_0000 + release_count)
                $fatal(1, "class limit system release %0d mismatch valid=%b camera=%h frame=%h",
                       release_count, image_release_valid, image_release_camera, image_release_frame);
            release_count <= release_count + 1;
        end
    end

    task mmio_write;
        input [31:0] addr; input [31:0] data;
        begin
            @(negedge cpu_clk); mmio_valid=1; mmio_wen=1; mmio_addr=addr;
            mmio_wdata=data; mmio_wstrb=4'b0001;
            @(posedge cpu_clk); @(negedge cpu_clk);
            mmio_valid=0; mmio_wen=0; mmio_addr=0; mmio_wdata=0; mmio_wstrb=0;
        end
    endtask
    task mmio_read;
        input [31:0] addr; output [31:0] data;
        begin
            @(negedge cpu_clk); mmio_valid=1; mmio_wen=0; mmio_addr=addr; #1 data=mmio_rdata;
            @(negedge cpu_clk); mmio_valid=0; mmio_addr=0;
        end
    endtask
    task read_record;
        begin
            for (result_word_index=0; result_word_index<8; result_word_index=result_word_index+1)
                mmio_read(NPU_BASE+32'h24+result_word_index*4, result_word[result_word_index]);
            rec_camera = result_word[0][7:0];
            rec_frame = {result_word[1][7:0], result_word[0][31:8]};
            rec_roi = result_word[1][16:9];
            rec_box = {result_word[3][16:0], result_word[2], result_word[1][31:17]};
            rec_color = result_word[3][19:17];
            rec_class = result_word[3][27:20];
            rec_margin = {result_word[4][11:0], result_word[3][31:28]};
            rec_error = result_word[4][19:12];
            rec_score = {result_word[5][19:0], result_word[4][31:20]};
            rec_reject = result_word[5][20];
        end
    endtask

    task send_image;
        input integer idx;
        begin
            send_lane = idx % 2;
            @(negedge ddr_clk);
            image_camera = {8'd2, 8'd1};
            image_frame = {32'h0000_3000 + idx, 32'h0000_3000 + idx};
            image_batch_count = {8'd1, 8'd1};
            image_index = {idx[7:0], idx[7:0]};
            image_box = {32'(idx), 32'hB0B0_0000 + idx, 32'(idx), 32'hB0B0_0000 + idx};
            image_color = {idx[2:0], idx[2:0]};
            image_block = {idx[1:0], idx[1:0]};
            image_position = {idx[3:0], idx[3:0]};
            image_generation = {32'hC0DE_0000 + idx, 32'hC0DE_0000 + idx};
            image_data_addr = {INPUT_ADDR + idx * INPUT_BYTES, INPUT_ADDR + idx * INPUT_BYTES};
            image_valid = send_lane ? 2'b10 : 2'b01;
            begin : handshake
                for (hs_wait = 0; hs_wait < 1000; hs_wait = hs_wait + 1) begin
                    @(posedge ddr_clk);
                    if (image_ready[send_lane]) begin
                        @(negedge ddr_clk);
                        image_valid = 2'b00;
                        disable handshake;
                    end
                end
                $fatal(1, "image %0d not accepted within 1000 cycles", idx);
            end
        end
    endtask

    initial begin : test
        if (!$value$plusargs("MODEL_HEX=%s", model_hex)) $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("INPUT_HEX=%s", input_hex)) $fatal(1, "INPUT_HEX is required");
        if (!$value$plusargs("EXPECTED_FILE=%s", expected_file)) $fatal(1, "EXPECTED_FILE is required");
        if (!$value$plusargs("ROI_COUNT=%d", roi_count)) $fatal(1, "ROI_COUNT is required");
        if (!$value$plusargs("EXPECT=%s", expect_mode)) $fatal(1, "EXPECT is required");
        if (expect_mode == "accept") expect_accept = 1'b1;
        else if (expect_mode == "model_error") expect_accept = 1'b0;
        else $fatal(1, "EXPECT must be accept or model_error, got %s", expect_mode);
        if (roi_count < 1 || roi_count > MAX_CASES) $fatal(1, "bad ROI_COUNT=%0d", roi_count);
        if ((MODEL_ADDR - DDR_BASE) + MODEL_BYTES > INPUT_ADDR - DDR_BASE ||
            (INPUT_ADDR - DDR_BASE) + roi_count * INPUT_BYTES > MEM_BYTES)
            $fatal(1, "memory image exceeds test memory");

        for (index=0; index<MEM_BYTES; index=index+1) mem[index]=0;
        $readmemh(model_hex, mem, MODEL_ADDR-DDR_BASE, MODEL_ADDR-DDR_BASE+MODEL_BYTES-1);
        $readmemh(input_hex, mem, INPUT_ADDR-DDR_BASE,
                  INPUT_ADDR-DDR_BASE+roi_count*INPUT_BYTES-1);
        expected_fd = $fopen(expected_file, "r");
        if (!expected_fd) $fatal(1, "cannot open EXPECTED_FILE");
        for (index=0; index<roi_count; index=index+1) begin
            if ($fscanf(expected_fd, "%d %d %d %d\n", expected_class[index],
                        expected_margin[index], expected_reject[index],
                        expected_score[index]) != 4)
                $fatal(1, "expected file ended at image %0d", index);
        end
        if ($fscanf(expected_fd, "%d", expected_extra) == 1)
            $fatal(1, "expected file has more than %0d rows", roi_count);
        $fclose(expected_fd);

        release_count = 0;
        repeat(4) @(posedge cpu_clk); rst_n = 1;
        repeat(4) @(posedge ddr_clk);

        for (index=0; index<roi_count; index=index+1) begin
            send_image(index);
            begin : wait_release
                for (timeout=0; timeout<12000000; timeout=timeout+1) begin
                    @(posedge ddr_clk);
                    if (release_count == index + 1) disable wait_release;
                end
                $fatal(1, "class limit system timeout image=%0d releases=%0d accepted=%0d completed=%0d",
                       index, release_count, accepted_batches, completed_batches);
            end
            begin : wait_fifo
                for (timeout=0; timeout<1000; timeout=timeout+1) begin
                    mmio_read(NPU_BASE+32'h20, status_word);
                    if (!status_word[16]) disable wait_fifo;
                end
                if (status_word[16]) $fatal(1, "class limit system result FIFO empty timeout image=%0d status=%08x",
                                            index, status_word);
            end
            read_record;
            $display("CLASS_LIMIT_RESULT idx=%0d class=%0d margin=%0d reject=%0d score=%0d error=%0d",
                     index, rec_class, rec_margin, rec_reject, $signed(rec_score), rec_error);
            if (rec_camera != (index % 2) + 1 || rec_frame != 32'h0000_3000 + index ||
                rec_roi != index[7:0] || rec_box != {32'(index), 32'hB0B0_0000 + index} ||
                rec_color != index[2:0])
                $fatal(1, "image %0d metadata mismatch camera=%0d frame=%h roi=%0d box=%h color=%0d",
                       index, rec_camera, rec_frame, rec_roi, rec_box, rec_color);
            if (expect_accept) begin
                if (rec_error != 0 || rec_class != expected_class[index] ||
                    rec_margin != expected_margin[index] ||
                    rec_reject != expected_reject[index] ||
                    $signed(rec_score) != expected_score[index])
                    $fatal(1, "image %0d mismatch class=%0d/%0d margin=%0d/%0d reject=%0d/%0d score=%0d/%0d error=%0d",
                           index, rec_class, expected_class[index], rec_margin, expected_margin[index],
                           rec_reject, expected_reject[index], $signed(rec_score),
                           expected_score[index], rec_error);
            end else begin
                if (rec_error != ERR_MODEL_FORMAT || rec_class != 8'hff ||
                    rec_margin != 0 || rec_score != 0 || rec_reject != 0)
                    $fatal(1, "image %0d is not a model-format error class=%0d margin=%0d reject=%0d score=%0d error=%0d",
                           index, rec_class, rec_margin, rec_reject, $signed(rec_score), rec_error);
            end
            mmio_write(NPU_BASE+32'h44, 1);
        end
        repeat (8) @(posedge ddr_clk);
        begin : fifo_drained
            for (timeout=0; timeout<1000; timeout=timeout+1) begin
                mmio_read(NPU_BASE+32'h20, status_word);
                if (status_word[16]) disable fifo_drained;
            end
            $fatal(1, "class limit system result FIFO not drained status=%08x", status_word);
        end

        if (accepted_batches != roi_count || release_count != roi_count || fifo_overflows != 0 ||
            dropped_batches != 0)
            $fatal(1, "counters mismatch accepted=%0d releases=%0d overflows=%0d dropped=%0d",
                   accepted_batches, release_count, fifo_overflows, dropped_batches);
        if (expect_accept) begin
            if (completed_batches != roi_count || error_rois != 0 || npu_error || npu_error_code != 0)
                $fatal(1, "accept counters mismatch completed=%0d error_rois=%0d error=%0d code=%0d",
                       completed_batches, error_rois, npu_error, npu_error_code);
            if (model_ar_count != (MODEL_BYTES / 32 + 15) / 16)
                $fatal(1, "model was fetched %0d times instead of once", model_ar_count);
        end else begin
            if (completed_batches != 0 || error_rois != roi_count || !npu_error ||
                npu_error_code != ERR_MODEL_FORMAT)
                $fatal(1, "reject counters mismatch completed=%0d error_rois=%0d error=%0d code=%h",
                       completed_batches, error_rois, npu_error, npu_error_code);
        end

        $display("NPU_CLASS_LIMIT_SYSTEM_PASS expect=%s system_max_classes=%0d engine_max_classes=%0d model_bytes=%0d images=%0d model_ar=%0d",
                 expect_mode, dut.MAX_CLASSES,
                 dut.g_image_service.u_service.u_engine.MAX_CLASSES,
                 MODEL_BYTES, roi_count, model_ar_count);
        $finish;
    end
endmodule
