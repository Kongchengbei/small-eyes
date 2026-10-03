`timescale 1ns / 1ps

module tb_npu_result_mmio;
    localparam integer FIFO_DEPTH = 4;

    reg producer_clk = 1'b0;
    reg consumer_clk = 1'b0;
    reg rst_n = 1'b0;
    reg producer_valid = 1'b0;
    wire producer_ready;
    reg [255:0] producer_record = 0;

    reg mmio_valid = 1'b0;
    reg mmio_wen = 1'b0;
    reg [7:0] mmio_addr = 0;
    reg [31:0] mmio_wdata = 0;
    reg [3:0] mmio_wstrb = 0;
    wire mmio_ready;
    wire [31:0] mmio_rdata;
    wire irq;
    wire producer_overflow;
    wire [7:0] producer_error_code;

    integer pushed;
    integer popped;
    integer i;
    reg [31:0] read_value;

    always #3 producer_clk = ~producer_clk;
    always #5 consumer_clk = ~consumer_clk;

    Hnpu_result_mmio #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
        .producer_clk(producer_clk), .consumer_clk(consumer_clk), .rst_n(rst_n),
        .producer_valid(producer_valid), .producer_ready(producer_ready),
        .producer_record(producer_record),
        .mmio_valid(mmio_valid), .mmio_wen(mmio_wen), .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata), .mmio_wstrb(mmio_wstrb),
        .mmio_ready(mmio_ready), .mmio_rdata(mmio_rdata), .irq(irq),
        .producer_overflow(producer_overflow), .producer_error_code(producer_error_code)
    );

    task fail;
        input string message;
        begin
            $fatal(1, "NPU_RESULT_FAIL: %0s", message);
        end
    endtask

    task mmio_read;
        input [7:0] addr;
        output [31:0] data;
        begin
            @(negedge consumer_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b0;
            mmio_addr = addr;
            mmio_wdata = 0;
            mmio_wstrb = 0;
            #1 data = mmio_rdata;
            @(negedge consumer_clk);
            mmio_valid = 1'b0;
            mmio_addr = 0;
        end
    endtask

    task mmio_write;
        input [7:0] addr;
        input [31:0] data;
        begin
            @(negedge consumer_clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b1;
            mmio_addr = addr;
            mmio_wdata = data;
            mmio_wstrb = 4'b0001;
            @(posedge consumer_clk);
            @(negedge consumer_clk);
            mmio_valid = 1'b0;
            mmio_wen = 1'b0;
            mmio_addr = 0;
            mmio_wdata = 0;
            mmio_wstrb = 0;
        end
    endtask

    task push_record;
        input [31:0] word0;
        input [31:0] word7;
        begin
            @(negedge producer_clk);
            producer_record = 0;
            producer_record[31:0] = word0;
            producer_record[255:224] = word7;
            producer_valid = 1'b1;
            while (!producer_ready)
                @(posedge producer_clk);
            @(posedge producer_clk);
            @(negedge producer_clk);
            producer_valid = 1'b0;
            pushed = pushed + 1;
        end
    endtask

    task wait_nonempty;
        integer guard;
        begin : wait_loop
            for (guard = 0; guard < 40; guard = guard + 1) begin
                mmio_read(8'h20, read_value);
                if (!read_value[16])
                    disable wait_loop;
            end
            fail("result FIFO stayed empty");
        end
    endtask

    initial begin
        pushed = 0;
        popped = 0;
        repeat (4) @(posedge consumer_clk);
        rst_n = 1'b1;

        // The FIFO uses asynchronous assertion and per-domain synchronous
        // reset release.  Do not issue CPU MMIO until the consumer domain is
        // out of its local reset.
        repeat (3) @(posedge consumer_clk);

        // Enable result-not-empty and overflow/error interrupts.
        mmio_write(8'h48, 32'h3);

        push_record(32'h0000_0101, 32'haaaa_0001);
        push_record(32'h0000_0202, 32'hbbbb_0002);
        wait_nonempty;
        mmio_read(8'h24, read_value);
        if (read_value !== 32'h0000_0101)
            fail("first record peek mismatch");
        mmio_read(8'h40, read_value);
        if (read_value !== 32'haaaa_0001)
            fail("last record word peek mismatch");
        mmio_read(8'h24, read_value);
        if (read_value !== 32'h0000_0101)
            fail("peek changed FIFO head");
        if (!irq)
            fail("nonempty IRQ did not assert");

        mmio_write(8'h44, 32'h1);
        popped = popped + 1;
        wait_nonempty;
        mmio_read(8'h24, read_value);
        if (read_value !== 32'h0000_0202)
            fail("explicit POP did not advance FIFO");

        // Fill the remaining slots, then hold valid while full.  Full is
        // normal ready/valid backpressure: the record must remain stable and
        // no overflow/error interrupt may be synthesized by the FIFO.
        push_record(32'h0000_0303, 32'hcccc_0003);
        push_record(32'h0000_0404, 32'hdddd_0004);
        push_record(32'h0000_0505, 32'heeee_0005);
        @(negedge producer_clk);
        producer_record = 256'h1234;
        producer_valid = 1'b1;
        repeat (12) @(posedge producer_clk);
        if (producer_ready)
            fail("full FIFO unexpectedly accepted a fifth record");
        producer_valid = 1'b0;
        if (producer_overflow || producer_error_code != 8'd0)
            fail("normal FIFO backpressure reported producer overflow");
        repeat (5) @(posedge consumer_clk);
        if (!irq)
            fail("result-not-empty IRQ unexpectedly deasserted while full");
        mmio_write(8'h44, 32'h1);
        repeat (5) @(posedge producer_clk);
        if (!producer_ready)
            fail("producer did not resume after explicit POP");
        mmio_write(8'h4c, 32'h2);
        repeat (5) @(posedge consumer_clk);
        mmio_read(8'h4c, read_value);
        if (read_value[1] !== 1'b0)
            fail("unexpected error sticky bit");

        $display("NPU_RESULT_MMIO_PASS pushed=%0d popped=%0d", pushed, popped);
        $finish;
    end
endmodule
