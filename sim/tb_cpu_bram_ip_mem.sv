`timescale 1ns / 1ps

// Exercise the production vendor-IP BRAM wrapper against its generated
// canonical image. The reference file is read only by the testbench; the
// vendor RAM itself is initialized by the packed IP parameters.
module tb_cpu_bram_ip_mem;
    reg grs_n = 1'b0;
    GTP_GRS GRS_INST (.GRS_N(grs_n));
    initial #100 grs_n = 1'b1;

    localparam [31:0] IRAM_BASE = 32'h8000_0000;
    localparam [31:0] IRAM_BYTES = 32'h0000_8000;
    localparam [31:0] DRAM_BASE = 32'h8000_8000;
    localparam [31:0] DRAM_BYTES = 32'h0000_4000;
    localparam integer IRAM_WORDS = IRAM_BYTES / 4;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b0;
    reg if_req_valid = 1'b0;
    reg [31:0] if_req_addr = 0;
    wire if_req_ready, if_rsp_valid;
    wire [31:0] if_rsp_data;
    reg data_req_valid = 1'b0;
    reg data_req_write = 1'b0;
    reg [31:0] data_req_addr = 0;
    reg [31:0] data_req_wdata = 0;
    reg [3:0] data_req_wstrb = 0;
    wire data_req_ready, data_rsp_valid, data_addr_local;
    wire [31:0] data_rsp_data;
    reg prog_valid = 1'b0;
    reg prog_write = 1'b0;
    reg [31:0] prog_addr = 0;
    reg [31:0] prog_wdata = 0;
    reg [3:0] prog_wstrb = 0;
    wire prog_ready;
    wire [31:0] prog_rdata;

    cpu_bram_ip_mem #(
        .IRAM_BASE(IRAM_BASE), .IRAM_BYTES(IRAM_BYTES),
        .DRAM_BASE(DRAM_BASE), .DRAM_BYTES(DRAM_BYTES)
    ) dut (
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

    reg [31:0] expected [0:IRAM_WORDS-1];
    string reference_path;
    integer i;

    task automatic fetch_word(input [31:0] addr, input [31:0] expected_word);
        begin
            @(negedge clk);
            if_req_valid = 1'b1;
            if_req_addr = addr;
            @(posedge clk);
            #1;
            if (!if_rsp_valid || if_rsp_data !== expected_word)
                $fatal(1, "vendor IRAM mismatch addr=%08x got=%08x expected=%08x valid=%b",
                       addr, if_rsp_data, expected_word, if_rsp_valid);
        end
    endtask

    task automatic lsu_read(input [31:0] addr, input [31:0] expected_word);
        begin
            @(negedge clk);
            data_req_valid = 1'b1;
            data_req_write = 1'b0;
            data_req_addr = addr;
            @(posedge clk);
            #1;
            if (!data_rsp_valid || data_rsp_data !== expected_word)
                $fatal(1, "vendor LSU read mismatch addr=%08x got=%08x expected=%08x",
                       addr, data_rsp_data, expected_word);
        end
    endtask

    initial begin
        reference_path = "IP/imem/rtl/imem_init_words.hex";
        if ($value$plusargs("IMEM_HEX=%s", reference_path)) begin end
        $readmemh(reference_path, expected);

        // Scan every one of the 8,192 generated initialization words through
        // the actual vendor primitive and the production wrapper's IF port.
        for (i = 0; i < IRAM_WORDS; i = i + 1)
            fetch_word(IRAM_BASE + i * 4, expected[i]);
        @(negedge clk);
        if_req_valid = 1'b0;

        // The same initialized IRAM is readable through the CPU's LSU port.
        lsu_read(IRAM_BASE, expected[0]);
        @(negedge clk);
        data_req_addr = IRAM_BASE + (IRAM_WORDS-1) * 4;
        @(posedge clk);
        #1;
        if (!data_rsp_valid || data_rsp_data !== expected[IRAM_WORDS-1])
            $fatal(1, "last-word IRAM LSU read mismatch got=%08x expected=%08x",
                   data_rsp_data, expected[IRAM_WORDS-1]);

        // Prove real vendor DMEM writes use the requested byte lane and retain
        // untouched initialized lanes. DMEM's generated contents are zero.
        @(negedge clk);
        data_req_write = 1'b1;
        data_req_addr = DRAM_BASE;
        data_req_wdata = 32'h1122_3344;
        data_req_wstrb = 4'hf;
        @(posedge clk);
        @(negedge clk);
        data_req_wdata = 32'h0000_a500;
        data_req_wstrb = 4'b0010;
        @(posedge clk);
        @(negedge clk);
        data_req_write = 1'b0;
        data_req_addr = DRAM_BASE;
        @(posedge clk);
        #1;
        if (!data_rsp_valid || data_rsp_data !== 32'h1122_a544)
            $fatal(1, "vendor DMEM byte-write mismatch got=%08x expected=1122a544", data_rsp_data);

        // Check the end of DMEM too, including the top byte lane and bank
        // selection across back-to-back IRAM/DRAM reads.
        @(negedge clk);
        data_req_write = 1'b1;
        data_req_addr = DRAM_BASE + DRAM_BYTES - 4;
        data_req_wdata = 32'hdead_beef;
        data_req_wstrb = 4'hf;
        @(posedge clk);
        @(negedge clk);
        data_req_wdata = 32'h5a00_0000;
        data_req_wstrb = 4'b1000;
        @(posedge clk);
        lsu_read(DRAM_BASE + DRAM_BYTES - 4, 32'h5aad_beef);
        lsu_read(IRAM_BASE + 4, expected[1]);
        lsu_read(DRAM_BASE, 32'h1122_a544);
        lsu_read(DRAM_BASE + DRAM_BYTES - 4, 32'h5aad_beef);

        @(negedge clk);
        data_req_valid = 1'b0;
        data_req_addr = DRAM_BASE + DRAM_BYTES;
        #1;
        if (data_addr_local || data_req_ready)
            $fatal(1, "out-of-range address decoded as local BRAM");
        $display("PASS: vendor BRAM init compared %0d words; IRAM LSU reads and DMEM byte writes", IRAM_WORDS);
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "timeout scanning vendor BRAM initialization");
    end
endmodule
