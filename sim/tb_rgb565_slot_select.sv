`timescale 1ns/1ps

module tb_rgb565_slot_select;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    reg enable = 1;
    reg desc_valid = 0;
    wire desc_ready;
    wire axi_arvalid;
    wire busy;
    reg release_valid = 0;
    reg [31:0] desc_count = 32'd8;
    reg [31:0] desc_frame = 32'h1234_5678;

    Hrgb565_int8_lane dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .clear_errors(1'b0),
        .desc_valid(desc_valid), .desc_ready(desc_ready),
        .desc_camera(8'd1), .desc_frame(desc_frame), .desc_rgb_bank(1'b0),
        .desc_rgb_base(32'hb840_0000), .desc_count(desc_count),
        .desc_width(16'd96), .desc_height(16'd96), .desc_rgb_stride(32'd32768),
        .desc_boxes(512'b0), .desc_colors(24'b0),
        .image_ready(1'b0), .busy(busy),
        .release_valid(release_valid), .release_camera(8'd1),
        .release_frame(32'h8765_4321), .release_block(2'b0),
        .release_position(4'b0), .release_generation(32'd1),
        .axi_arvalid(axi_arvalid), .axi_araddr(), .axi_arready(1'b0),
        .axi_rdata(256'b0), .axi_rid(8'b0), .axi_rresp(2'b0),
        .axi_rlast(1'b0), .axi_rvalid(1'b0),
        .axi_awready(1'b0), .axi_wready(1'b0),
        .axi_bid(8'b0), .axi_bresp(2'b0), .axi_bvalid(1'b0)
    );

    task reset_lane;
        integer slot;
        begin
            desc_valid=0;
            release_valid=0;
            rst_n=0;
            repeat (2) @(negedge clk);
            rst_n=1;
            @(negedge clk);
            for (slot=0;slot<56;slot=slot+1) begin
                dut.slot_state[slot]=2'd2;
                dut.slot_generation[slot]=0;
            end
        end
    endtask

    task check_capacity_stall;
        begin
            reset_lane();
            dut.slot_state[0]=2'd0;
            desc_count=2;
            desc_valid=1;
            #1;
            if (desc_ready || !dut.wait_slot)
                $fatal(1, "insufficient free slots must hold descriptor without accepting it");
            @(posedge clk);
            @(negedge clk);
            desc_valid=0;
            if (dut.slot_state[0]!==2'd0 || dut.slot_generation[0]!==32'd0)
                $fatal(1, "slot changed while descriptor was stalled");
        end
    endtask

    task check_release_snapshot;
        integer cycles;
        begin
            reset_lane();
            dut.slot_state[0]=2'd2;
            dut.slot_generation[0]=32'd1;
            dut.slot_frame[0]=32'h8765_4321;
            dut.slot_state[1]=2'd0;
            dut.slot_state[2]=2'd0;
            desc_count=2;
            desc_frame=desc_frame+1'b1;
            desc_valid=1;
            #1;
            if (!desc_ready) $fatal(1, "snapshot batch was not accepted");
            @(posedge clk);
            @(negedge clk);
            desc_valid=0;
            release_valid=1;
            @(posedge clk);
            @(negedge clk);
            release_valid=0;

            cycles=1;
            while (!axi_arvalid && cycles<4) begin
                @(negedge clk);
                cycles=cycles+1;
            end
            if (!axi_arvalid || cycles!=2)
                $fatal(1, "two-slot snapshot allocation latency mismatch cycles=%0d", cycles);
            if (dut.batch_slot_index[0]!==6'd1 || dut.batch_slot_index[1]!==6'd2)
                $fatal(1, "release changed accepted free-slot snapshot: got %0d,%0d",
                       dut.batch_slot_index[0], dut.batch_slot_index[1]);
            if (dut.slot_state[0]!==2'd0 || dut.slot_state[1]!==2'd1 ||
                dut.slot_state[2]!==2'd1)
                $fatal(1, "concurrent release/allocation state mismatch");
        end
    endtask

    task check_allocation;
        input [55:0] requested_free_mask;
        input [3:0] requested_count;
        input integer saturated_slot;
        integer slot;
        integer found;
        integer available_count;
        integer cycles;
        integer expected_remaining;
        reg [55:0] effective_mask;
        reg [55:0] expected_reserve;
        reg [5:0] expected [0:7];
        begin
            reset_lane();
            effective_mask=requested_free_mask;
            if (saturated_slot>=0) effective_mask[saturated_slot]=1'b0;
            for (slot=0;slot<56;slot=slot+1) begin
                if (effective_mask[slot]) dut.slot_state[slot]=2'd0;
            end
            if (saturated_slot>=0) begin
                dut.slot_state[saturated_slot]=2'd0;
                dut.slot_generation[saturated_slot]=32'hffff_ffff;
            end

            found=0;
            available_count=0;
            expected_reserve=56'b0;
            for (slot=0;slot<56;slot=slot+1) begin
                if (effective_mask[slot]) begin
                    available_count=available_count+1;
                    if (found<requested_count) begin
                        expected[found]=slot[5:0];
                        expected_reserve[slot]=1'b1;
                        found=found+1;
                    end
                end
            end
            if (available_count<requested_count)
                $fatal(1, "test vector has only %0d free slots for request %0d", available_count, requested_count);
            #1;
            if (dut.free_count!==available_count[5:0])
                $fatal(1, "free count mismatch expected=%0d got=%0d", available_count, dut.free_count);

            desc_count={28'b0,requested_count};
            desc_frame=desc_frame+1'b1;
            desc_valid=1;
            #1;
            if (!desc_ready) $fatal(1, "valid batch was not accepted");
            @(posedge clk);
            @(negedge clk);
            desc_valid=0;

            cycles=0;
            while (!axi_arvalid && cycles<10) begin
                @(negedge clk);
                cycles=cycles+1;
            end
            if (!axi_arvalid || cycles!={28'b0,requested_count})
                $fatal(1, "allocator latency mismatch request=%0d cycles=%0d",
                       requested_count, cycles);
            if (!busy) $fatal(1, "lane did not remain busy during AXI wait");

            for (slot=0;slot<requested_count;slot=slot+1) begin
                if (dut.batch_slot_index[slot]!==expected[slot])
                    $fatal(1, "first-free order mismatch item=%0d expected=%0d got=%0d",
                           slot, expected[slot], dut.batch_slot_index[slot]);
                if (dut.slot_state[expected[slot]]!==2'd1 ||
                    dut.slot_generation[expected[slot]]!==32'd1)
                    $fatal(1, "selected slot %0d was not reserved exactly once", expected[slot]);
            end
            for (slot=0;slot<56;slot=slot+1) begin
                if (expected_reserve[slot]) begin
                    if (dut.slot_state[slot]!==2'd1 || dut.slot_generation[slot]!==32'd1)
                        $fatal(1, "selected slot %0d was not reserved exactly once", slot);
                end else if (effective_mask[slot]) begin
                    if (dut.slot_state[slot]!==2'd0 || dut.slot_generation[slot]!==32'd0)
                        $fatal(1, "unselected free slot %0d was modified", slot);
                end else if (saturated_slot==slot) begin
                    if (dut.slot_state[slot]!==2'd0 || dut.slot_generation[slot]!==32'hffff_ffff)
                        $fatal(1, "generation-saturated slot %0d changed", slot);
                end else if (dut.slot_state[slot]!==2'd2) begin
                    $fatal(1, "unavailable slot %0d was modified", slot);
                end
            end
            expected_remaining=available_count-{28'b0,requested_count};
            if (dut.free_count !== expected_remaining[5:0])
                $fatal(1, "post-allocation free count mismatch expected=%0d got=%0d",
                       expected_remaining, dut.free_count);
            $display("RGB565_SELECTOR_CASE_PASS request=%0d free=%0d latency=%0d",
                     requested_count, available_count, cycles);
        end
    endtask

    initial begin : run_cases
        reg [55:0] mask;
        reg [31:0] random_state;
        integer trial;
        integer slot;
        integer request;
        reg [3:0] request_count;
        integer free_slots;

        repeat (3) @(posedge clk);
        rst_n=1;
        mask={56{1'b1}};
        check_allocation(mask,4'd8,-1);

        mask=56'b0;
        mask[0]=1; mask[8]=1; mask[16]=1; mask[24]=1;
        mask[32]=1; mask[40]=1; mask[48]=1; mask[55]=1;
        check_allocation(mask,4'd8,-1);

        mask={56{1'b1}};
        check_allocation(mask,4'd8,0);

        random_state=32'h5a17_c3e9;
        for (trial=0;trial<64;trial=trial+1) begin
            mask=56'b0;
            free_slots=0;
            for (slot=0;slot<56;slot=slot+1) begin
                random_state={random_state[30:0],
                    random_state[31]^random_state[21]^random_state[1]^random_state[0]};
                if (random_state[0] || slot<12) begin
                    mask[slot]=1'b1;
                    free_slots=free_slots+1;
                end
            end
            request=(trial%8)+1;
            if (request>free_slots) request=free_slots;
            request_count=request[3:0];
            check_allocation(mask,request_count,-1);
        end
        check_capacity_stall();
        check_release_snapshot();
        $display("RGB565_SLOT_SELECT_PASS cases=69 randomized=64 max_latency=8");
        $finish;
    end

    initial begin
        #50000;
        $fatal(1, "RGB565 free-count test timed out");
    end
endmodule
