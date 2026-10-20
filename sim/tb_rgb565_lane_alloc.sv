`timescale 1ns/1ps

module tb_rgb565_lane_alloc;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg enable = 1;
    reg desc_valid = 0;
    wire desc_ready;
    wire axi_arvalid;
    wire [29:0] axi_araddr;
    wire busy;
    integer cycles;
    integer idx;

    Hrgb565_int8_lane dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_errors(1'b0),
        .desc_valid(desc_valid), .desc_ready(desc_ready),
        .desc_camera(8'd1), .desc_frame(32'h1234_5678), .desc_rgb_bank(1'b0),
        .desc_rgb_base(32'hb840_0000), .desc_count(32'd8),
        .desc_width(16'd96), .desc_height(16'd96), .desc_rgb_stride(32'd32768),
        .desc_boxes(512'b0), .desc_colors(24'b0),
        .image_ready(1'b0), .busy(busy),
        .release_valid(1'b0), .release_camera(8'b0), .release_frame(32'b0),
        .release_block(2'b0), .release_position(4'b0), .release_generation(32'b0),
        .axi_arvalid(axi_arvalid), .axi_araddr(axi_araddr), .axi_arready(1'b0),
        .axi_rdata(256'b0), .axi_rid(8'b0), .axi_rresp(2'b0),
        .axi_rlast(1'b0), .axi_rvalid(1'b0),
        .axi_awready(1'b0), .axi_wready(1'b0),
        .axi_bid(8'b0), .axi_bresp(2'b0), .axi_bvalid(1'b0)
    );

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        desc_valid = 1;
        if (!desc_ready) $fatal(1, "valid batch was not accepted");
        @(posedge clk);
        @(negedge clk);
        desc_valid = 0;

        cycles = 0;
        while (!axi_arvalid && cycles < 10) begin
            @(negedge clk);
            cycles = cycles + 1;
        end
        if (!axi_arvalid || cycles != 8)
            $fatal(1, "eight-slot allocation must start AXI after 8 cycles, cycles=%0d", cycles);

        for (idx=0; idx<8; idx=idx+1) begin
            if (dut.batch_slot_index[idx] !== idx[5:0])
                $fatal(1, "slot order mismatch index=%0d got=%0d", idx, dut.batch_slot_index[idx]);
            if (dut.slot_state[idx] !== 2'd1 || dut.slot_generation[idx] !== 32'd1)
                $fatal(1, "slot %0d was not reserved exactly once", idx);
        end
        if (!busy) $fatal(1, "lane did not remain busy during AXI wait");
        $display("RGB565_LANE_ALLOC_PASS cycles=%0d first_slot=%0d last_slot=%0d",
                 cycles, dut.batch_slot_index[0], dut.batch_slot_index[7]);

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "RGB565 lane allocation test timed out");
    end
endmodule
