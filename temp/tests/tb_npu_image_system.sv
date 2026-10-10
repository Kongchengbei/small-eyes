`timescale 1ns / 1ps

module tb_npu_image_system;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT1_ADDR = 32'h8002_0000;
    localparam [31:0] INPUT2_ADDR = 32'h8002_9000;
    localparam [31:0] NPU_BASE = 32'h4000_0100;
    localparam integer MODEL_BYTES = 512;
    localparam integer INPUT_BYTES = 36864;
    localparam integer MEM_BYTES = 262144;

    reg ddr_clk = 0, cpu_clk = 0, rst_n = 0;
    reg enable = 1, clear_errors = 0, stop = 0;
    reg [1:0] image_valid = 0;
    wire [1:0] image_ready;
    reg [15:0] image_camera = {8'd2,8'd1};
    reg [63:0] image_frame = {32'h222,32'h111};
    reg [15:0] image_batch_count = {8'd1,8'd1};
    reg [15:0] image_index = {8'd1,8'd0};
    reg [127:0] image_box = {64'h2222,64'h1111};
    reg [5:0] image_color = {3'd2,3'd1};
    reg [3:0] image_block = {2'd2,2'd1};
    reg [7:0] image_position = {4'd4,4'd3};
    reg [63:0] image_generation = {32'haaaa,32'hbbbb};
    reg [63:0] image_data_addr = {INPUT2_ADDR,INPUT1_ADDR};
    reg [31:0] image_width = {16'd96,16'd96};
    reg [31:0] image_height = {16'd96,16'd96};
    reg [63:0] image_data_bytes = {32'd36864,32'd36864};
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
    integer lane, index, ddr_cycle, timeout, result_word_index;
    integer release_count, input_beat_count;
    reg [31:0] status_word, result_word [0:7];
    reg [7:0] result_camera, result_class;
    reg [31:0] result_frame, result_score;
    reg [15:0] result_confidence;
    reg result_reject_word;
    string model_hex;

    always #5 ddr_clk = ~ddr_clk;
    always #7 cpu_clk = ~cpu_clk;

    Hnpu_system #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000),
        .NPU_MMIO_BASE(NPU_BASE), .NPU_MMIO_BYTES(32'h100),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(4), .RESULT_FIFO_DEPTH(4),
        .MAX_ROIS(4), .MAX_FEATURES(1024), .MAX_CLASSES(8),
        .ENGINE_MODE(1), .MAX_MODEL_BYTES(65536), .IMAGE_MODE(1),
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
            input_beat_count <= 0;
        end else begin
            ddr_cycle <= ddr_cycle + 1;
            axi_arready <= !rd_active && !axi_rvalid && ddr_cycle[1:0] != 0;
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "image system AXI metadata mismatch");
                rd_active <= 1; rd_addr <= axi_araddr; rd_left <= axi_arlen + 1; rd_id <= axi_arid;
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
            end else if (rd_active && ddr_cycle[1:0] != 1) begin
                axi_rdata <= 0;
                for (lane = 0; lane < 32; lane = lane + 1)
                    axi_rdata[lane*8 +: 8] <= mem[rd_addr + lane];
                axi_rid <= rd_id; axi_rresp <= 0; axi_rlast <= rd_left == 1; axi_rvalid <= 1;
            end
            if (image_release_valid[0] && image_release_ready[0]) release_count <= release_count + 1;
            if (image_release_valid[1] && image_release_ready[1]) release_count <= release_count + 1;
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
                mmio_read(NPU_BASE+32'h24+result_word_index*4,result_word[result_word_index]);
            result_camera=result_word[0][7:0];
            result_frame={result_word[1][7:0],result_word[0][31:8]};
            result_class=result_word[3][27:20];
            result_confidence={result_word[4][11:0],result_word[3][31:28]};
            result_score={result_word[5][19:0],result_word[4][31:20]};
            result_reject_word=result_word[5][20];
        end
    endtask

    initial begin : test
        if (!$value$plusargs("MODEL_HEX=%s", model_hex)) $fatal(1, "MODEL_HEX is required");
        for (index=0; index<MEM_BYTES; index=index+1) mem[index]=0;
        $readmemh(model_hex, mem, MODEL_ADDR-DDR_BASE, MODEL_ADDR-DDR_BASE+MODEL_BYTES-1);
        for (index=0; index<96*96; index=index+1) begin
            if (((index / 96) % 3) == 0 && ((index % 96) % 3) == 0) begin
                mem[INPUT1_ADDR-DDR_BASE+index*4]=10; mem[INPUT1_ADDR-DDR_BASE+index*4+1]=1;
                mem[INPUT2_ADDR-DDR_BASE+index*4]=1; mem[INPUT2_ADDR-DDR_BASE+index*4+1]=20;
            end else begin
                mem[INPUT1_ADDR-DDR_BASE+index*4]=1; mem[INPUT1_ADDR-DDR_BASE+index*4+1]=20;
                mem[INPUT2_ADDR-DDR_BASE+index*4]=10; mem[INPUT2_ADDR-DDR_BASE+index*4+1]=1;
            end
        end
        release_count=0;
        repeat(4) @(posedge cpu_clk); rst_n=1;
        @(negedge ddr_clk); image_valid=2'b11;
        while (!image_ready[0]) @(posedge ddr_clk);
        @(negedge ddr_clk); image_valid[0]=0;
        while (!image_ready[1]) @(posedge ddr_clk);
        @(negedge ddr_clk); image_valid[1]=0;
        for (timeout=0; timeout<1000000 && release_count<2; timeout=timeout+1) @(posedge ddr_clk);
        if (release_count != 2 || npu_error || accepted_batches != 2 || completed_batches != 2 ||
            input_beat_count != 2304)
            $fatal(1,"image system compute mismatch releases=%0d accepted=%0d completed=%0d input_beats=%0d error=%0d code=%0d",
                   release_count,accepted_batches,completed_batches,input_beat_count,npu_error,npu_error_code);
        begin : wait_fifo
            for (timeout=0; timeout<1000; timeout=timeout+1) begin
                mmio_read(NPU_BASE+32'h20,status_word);
                if (!status_word[16]) disable wait_fifo;
            end
            if (!status_word[16]) $fatal(1,"image system result FIFO empty timeout status=%08x", status_word);
        end
        read_record;
        if (result_camera!=1 || result_frame!=32'h111 || result_class!=0 || result_score!=10)
            $fatal(1,"image system result0 mismatch camera=%0d frame=%h class=%0d score=%0d",
                   result_camera,result_frame,result_class,result_score);
        mmio_write(NPU_BASE+32'h44,1);
        begin : wait_second
            for (timeout=0; timeout<1000; timeout=timeout+1) begin
                mmio_read(NPU_BASE+32'h20,status_word);
                if (!status_word[16]) disable wait_second;
            end
            if (!status_word[16]) $fatal(1,"image system second result timeout status=%08x", status_word);
        end
        read_record;
        if (result_camera!=2 || result_frame!=32'h222 || result_class!=1 || result_score!=20)
            $fatal(1,"image system result1 mismatch camera=%0d frame=%h class=%0d score=%0d",
                   result_camera,result_frame,result_class,result_score);
        mmio_write(NPU_BASE+32'h44,1);
        $display("NPU_IMAGE_SYSTEM_PASS results=2 releases=%0d",release_count);
        $finish;
    end
endmodule
