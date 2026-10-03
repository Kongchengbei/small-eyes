`timescale 1ns / 1ps

module tb_npu_system;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] INPUT0 = 32'h8000_1000;
    localparam [31:0] INPUT1 = 32'h8000_1100;
    localparam [31:0] WEIGHT = 32'h8000_2000;
    localparam [31:0] BIAS = 32'h8000_3000;
    localparam [31:0] NPU_BASE = 32'h4000_0100;

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
    reg [7:0] batch_count;
    reg [7:0] batch_class_count;
    reg [5:0] batch_quant_shift;
    reg [255:0] batch_boxes;
    reg [11:0] batch_colors;

    wire int8_release_valid;
    wire int8_release_bank;
    wire [31:0] int8_release_frame;
    wire busy, npu_error;
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

    reg mmio_valid = 1'b0;
    reg mmio_wen = 1'b0;
    reg [31:0] mmio_addr = 0;
    reg [31:0] mmio_wdata = 0;
    reg [3:0] mmio_wstrb = 0;
    wire mmio_ready;
    wire [31:0] mmio_rdata;
    wire irq;
    wire start_pulse;
    wire [31:0] control_input_addr, control_weight_addr;
    wire [31:0] control_output_addr, control_task_bytes;

    reg [255:0] mem [0:2047];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer ddr_cycle;
    integer lane;
    integer i;
    integer result_count;
    integer release_count;
    reg [31:0] read_value;

    always #5 ddr_clk = ~ddr_clk;
    always #7 cpu_clk = ~cpu_clk;

    Hnpu_system #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000),
        .NPU_MMIO_BASE(NPU_BASE), .NPU_MMIO_BYTES(32'h100),
        .QUEUE_DEPTH(2), .RESULT_DEPTH(8), .RESULT_FIFO_DEPTH(4),
        .MAX_ROIS(4), .MAX_FEATURES(32), .MAX_CLASSES(3)
    ) dut (
        .ddr_clk(ddr_clk), .cpu_clk(cpu_clk), .rst_n(rst_n),
        .enable(enable), .clear_errors(clear_errors), .stop(stop),
        .batch_valid(batch_valid), .batch_ready(batch_ready),
        .batch_camera(batch_camera), .batch_frame(batch_frame), .batch_bank(batch_bank),
        .batch_input_base(batch_input_base), .batch_input_stride(batch_input_stride),
        .batch_input_bytes(batch_input_bytes), .batch_feature_count(batch_feature_count),
        .batch_weight_base(batch_weight_base), .batch_weight_stride(batch_weight_stride),
        .batch_bias_base(batch_bias_base), .batch_count(batch_count),
        .batch_class_count(batch_class_count), .batch_quant_shift(batch_quant_shift),
        .batch_boxes(batch_boxes), .batch_colors(batch_colors),
        .int8_release_valid(int8_release_valid), .int8_release_bank(int8_release_bank),
        .int8_release_frame(int8_release_frame), .busy(busy), .error(npu_error),
        .error_code(npu_error_code), .accepted_batches(accepted_batches),
        .completed_batches(completed_batches), .dropped_batches(dropped_batches),
        .completed_rois(completed_rois), .error_rois(error_rois),
        .released_banks(released_banks), .fifo_overflows(fifo_overflows),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
        .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready),
        .mmio_valid(mmio_valid), .mmio_wen(mmio_wen), .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata), .mmio_wstrb(mmio_wstrb),
        .mmio_ready(mmio_ready), .mmio_rdata(mmio_rdata), .irq(irq),
        .start_pulse(start_pulse), .control_engine_done(1'b0),
        .control_input_addr(control_input_addr), .control_weight_addr(control_weight_addr),
        .control_output_addr(control_output_addr), .control_task_bytes(control_task_bytes)
    );

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
                    $fatal(1, "system AXI metadata mismatch");
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
                axi_rdata <= mem[rd_addr[15:5]];
                axi_rid <= rd_id;
                axi_rresp <= 2'b00;
                axi_rlast <= (rd_left == 1);
                axi_rvalid <= 1'b1;
            end
        end
    end

    always @(posedge ddr_clk) begin
        if (rst_n && int8_release_valid) begin
            if (release_count == 0 && (int8_release_bank != 0 || int8_release_frame != 32'h101))
                $fatal(1, "system CAM1 release mismatch");
            if (release_count == 1 && (int8_release_bank != 1 || int8_release_frame != 32'h202))
                $fatal(1, "system CAM2 release mismatch");
            release_count <= release_count + 1;
        end
    end

    task send_batch;
        input [7:0] cam;
        input [31:0] frame;
        input bank;
        input [31:0] input_base;
        begin : send_batch_loop
            @(negedge ddr_clk);
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
            batch_count = 1;
            batch_class_count = 3;
            batch_quant_shift = 0;
            batch_boxes = 0;
            batch_colors = 0;
            batch_boxes[63:0] = 64'h0000_0004_0000_0003;
            batch_colors[2:0] = 3'd1;
            batch_valid = 1'b1;
            while (1) begin
                @(posedge ddr_clk);
                if (batch_ready) begin
                    @(negedge ddr_clk);
                    batch_valid = 1'b0;
                    disable send_batch_loop;
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

    integer timeout;
    initial begin : init_block
        batch_camera = 0; batch_frame = 0; batch_bank = 0;
        batch_input_base = 0; batch_input_stride = 0; batch_input_bytes = 0;
        batch_feature_count = 0; batch_weight_base = 0; batch_weight_stride = 0;
        batch_bias_base = 0; batch_count = 0; batch_class_count = 0;
        batch_quant_shift = 0; batch_boxes = 0; batch_colors = 0;
        result_count = 0; release_count = 0;
        for (i = 0; i < 2048; i = i + 1)
            mem[i] = 0;
        for (lane = 0; lane < 32; lane = lane + 1) begin
            mem[(INPUT0 - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd3;
            mem[(INPUT1 - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[(WEIGHT - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[((WEIGHT + 32 - DDR_BASE) >> 5)][lane*8 +: 8] = 8'sd0;
            mem[((WEIGHT + 64 - DDR_BASE) >> 5)][lane*8 +: 8] = -8'sd1;
        end

        repeat (4) @(posedge cpu_clk);
        rst_n = 1'b1;
        mmio_write(NPU_BASE + 32'h48, 32'h1);
        send_batch(8'd1, 32'h101, 1'b0, INPUT0);
        send_batch(8'd2, 32'h202, 1'b1, INPUT1);

        for (timeout = 0; timeout < 5000; timeout = timeout + 1) begin
            mmio_read(NPU_BASE + 32'h20, read_value);
            if (!read_value[16])
                disable init_block;
        end
        $fatal(1, "system result FIFO timeout");
    end

    initial begin
        wait (rst_n && result_count == 0);
        // Wait for two records, then verify peek/POP through the CPU clock.
        wait (release_count == 2);
        mmio_read(NPU_BASE + 32'h24, read_value);
        if (read_value !== 32'h0001_0101)
            $fatal(1, "system result 0 peek mismatch: %08x", read_value);
        mmio_write(NPU_BASE + 32'h44, 32'h1);
        mmio_read(NPU_BASE + 32'h24, read_value);
        if (read_value !== 32'h0002_0202)
            $fatal(1, "system result 1 peek mismatch: %08x", read_value);
        mmio_write(NPU_BASE + 32'h44, 32'h1);
        repeat (4) @(posedge cpu_clk);
        mmio_read(NPU_BASE + 32'h20, read_value);
        if (!read_value[16] || irq)
            $fatal(1, "system result FIFO did not empty");
        if (accepted_batches != 2 || completed_batches != 2 ||
            completed_rois != 2 || released_banks != 2 || npu_error)
            $fatal(1, "system counters mismatch accepted=%0d completed=%0d rois=%0d releases=%0d error=%0d",
                   accepted_batches, completed_batches, completed_rois, released_banks, npu_error);
        $display("NPU_SYSTEM_PASS results=2 releases=%0d", release_count);
        $finish;
    end
endmodule
