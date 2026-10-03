`timescale 1ns / 1ps

module tb_cpu_bram_mem;
    localparam [31:0] IRAM_BASE = 32'h8000_0000;
    localparam [31:0] DRAM_BASE = 32'h8000_8000;
    localparam [31:0] DRAM_BYTES = 32'h0000_4000;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    reg if_req_valid = 1'b0;
    reg [31:0] if_req_addr = 32'b0;
    wire if_req_ready;
    wire if_rsp_valid;
    wire [31:0] if_rsp_data;
    reg data_req_valid = 1'b0;
    reg data_req_write = 1'b0;
    reg [31:0] data_req_addr = 32'b0;
    reg [31:0] data_req_wdata = 32'b0;
    reg [3:0] data_req_wstrb = 4'b0;
    wire data_req_ready;
    wire data_rsp_valid;
    wire [31:0] data_rsp_data;
    wire data_addr_local;
    reg prog_valid = 1'b0;
    reg prog_write = 1'b0;
    reg [31:0] prog_addr = 32'b0;
    reg [31:0] prog_wdata = 32'b0;
    reg [3:0] prog_wstrb = 4'b0;
    wire prog_ready;
    wire [31:0] prog_rdata;

    cpu_bram_mem dut (
        .clk(clk), .rst(rst),
        .if_req_valid(if_req_valid), .if_req_addr(if_req_addr),
        .if_req_ready(if_req_ready), .if_rsp_valid(if_rsp_valid), .if_rsp_data(if_rsp_data),
        .data_req_valid(data_req_valid), .data_req_write(data_req_write),
        .data_req_addr(data_req_addr), .data_req_wdata(data_req_wdata),
        .data_req_wstrb(data_req_wstrb), .data_req_ready(data_req_ready),
        .data_rsp_valid(data_rsp_valid), .data_rsp_data(data_rsp_data),
        .data_addr_local(data_addr_local),
        .prog_valid(prog_valid), .prog_write(prog_write), .prog_addr(prog_addr),
        .prog_wdata(prog_wdata), .prog_wstrb(prog_wstrb),
        .prog_ready(prog_ready), .prog_rdata(prog_rdata)
    );

    task automatic loader_write(input [31:0] addr, input [31:0] word, input [3:0] strobe);
        begin
            @(negedge clk);
            prog_valid = 1'b1;
            prog_write = 1'b1;
            prog_addr = addr;
            prog_wdata = word;
            prog_wstrb = strobe;
            #1;
            if (!prog_ready) $fatal(1, "loader write not immediately ready at %08x", addr);
            @(posedge clk);
            @(negedge clk);
            prog_valid = 1'b0;
            prog_write = 1'b0;
        end
    endtask

    task automatic loader_read(input [31:0] addr, input [31:0] expected);
        begin
            @(negedge clk);
            prog_valid = 1'b1;
            prog_write = 1'b0;
            prog_addr = addr;
            #1;
            if (prog_ready) $fatal(1, "loader read acknowledged before data at %08x", addr);
            @(posedge clk);
            #1;
            if (!prog_ready || prog_rdata !== expected)
                $fatal(1, "loader readback addr=%08x ready=%b data=%08x expected=%08x", addr, prog_ready, prog_rdata, expected);
            @(negedge clk);
            prog_valid = 1'b0;
        end
    endtask

    initial begin
        loader_write(IRAM_BASE, 32'h1234_5678, 4'hf);
        loader_write(IRAM_BASE + 32'd4, 32'hdead_beef, 4'hf);
        loader_write(DRAM_BASE, 32'h1122_3344, 4'hf);
        loader_write(DRAM_BASE + DRAM_BYTES - 4, 32'h89ab_cdef, 4'hf);
        loader_read(IRAM_BASE, 32'h1234_5678);
        loader_read(DRAM_BASE + DRAM_BYTES - 4, 32'h89ab_cdef);

        // The loader has no ownership once the CPU leaves reset.
        @(negedge clk) rst = 1'b0;
        prog_valid = 1'b1;
        prog_write = 1'b1;
        prog_addr = IRAM_BASE;
        prog_wdata = 32'h0;
        prog_wstrb = 4'hf;
        #1;
        if (prog_ready) $fatal(1, "loader acknowledged while CPU was running");
        @(negedge clk) prog_valid = 1'b0;

        if_req_valid = 1'b1;
        if_req_addr = IRAM_BASE;
        data_req_valid = 1'b1;
        data_req_addr = IRAM_BASE;
        data_req_write = 1'b0;
        @(posedge clk);
        #1;
        if (!if_rsp_valid || if_rsp_data !== 32'h1234_5678)
            $fatal(1, "instruction port read mismatch");
        if (!data_rsp_valid || data_rsp_data !== 32'h1234_5678)
            $fatal(1, "IRAM LSU source read mismatch");

        @(negedge clk);
        if_req_valid = 1'b0;
        data_req_addr = DRAM_BASE + DRAM_BYTES - 4;
        data_req_write = 1'b0;
        @(posedge clk);
        #1;
        if (!data_rsp_valid || data_rsp_data !== 32'h89ab_cdef)
            $fatal(1, "last DRAM word read mismatch");

        @(negedge clk);
        data_req_write = 1'b1;
        data_req_addr = DRAM_BASE;
        data_req_wdata = 32'h0000_a500;
        data_req_wstrb = 4'b0010;
        @(posedge clk);
        @(negedge clk);
        data_req_write = 1'b0;
        data_req_addr = DRAM_BASE;
        @(posedge clk);
        #1;
        if (!data_rsp_valid || data_rsp_data !== 32'h1122_a544)
            $fatal(1, "byte-strobed DRAM update mismatch %08x", data_rsp_data);

        @(negedge clk);
        data_req_valid = 1'b0;
        data_req_addr = DRAM_BASE + DRAM_BYTES;
        #1;
        if (data_addr_local || data_req_ready)
            $fatal(1, "out-of-range address incorrectly decoded as local");
        $display("PASS: BRAM loader handshake, reset retention, LSU ports, strobes, boundaries");
        $finish;
    end

    initial begin
        #3000;
        $fatal(1, "timeout");
    end
endmodule
