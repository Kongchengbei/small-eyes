`timescale 1ns / 1ps

// CPU-level harness for the official rv32um ISA binaries.  It models the
// local BRAM response protocol used by Hfpga_soc: a load response arrives
// one clock after the EX-stage request is accepted.
module tb_Htop_rv32m;
    localparam MEM_WORDS = 16384;

    reg clk;
    reg rst;
    wire [31:0] imem_addr;
    reg  [31:0] imem_rdata;
    wire        dmem_valid;
    wire        dmem_wen;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [3:0]  dmem_wmask;
    wire        dmem_ready = 1'b1;
    reg  [31:0] dmem_rdata;
    reg         dmem_rsp_valid;
    wire [31:0] pc;
    wire [31:0] ins;
    wire        is_ebreak;
    reg [31:0] mem [0:MEM_WORDS-1];

    integer i;
    integer cycle_count;
    integer timeout_cycles;
    string program_file;

    Htop dut (
        .clk            (clk),
        .rst            (rst),
        .imem_addr      (imem_addr),
        .imem_rdata     (imem_rdata),
        .dmem_valid     (dmem_valid),
        .dmem_wen       (dmem_wen),
        .dmem_addr      (dmem_addr),
        .dmem_wdata     (dmem_wdata),
        .dmem_wmask     (dmem_wmask),
        .dmem_rdata     (dmem_rdata),
        .dmem_ready     (dmem_ready),
        .dmem_rsp_valid (dmem_rsp_valid),
        .pc             (pc),
        .ins            (ins),
        .is_ebreak      (is_ebreak)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    always @(posedge clk) begin
        if (imem_addr[31:2] < MEM_WORDS)
            imem_rdata <= mem[imem_addr[31:2]];
        else
            imem_rdata <= 32'h0000_0013;

        dmem_rsp_valid <= dmem_valid && !dmem_wen;
        if (dmem_valid && !dmem_wen) begin
            if (dmem_addr[31:2] < MEM_WORDS)
                dmem_rdata <= mem[dmem_addr[31:2]];
            else
                dmem_rdata <= 32'b0;
        end

        if (!rst && dmem_valid && dmem_wen &&
            (dmem_addr[31:2] < MEM_WORDS)) begin
            if (dmem_wmask[0]) mem[dmem_addr[31:2]][7:0]   <= dmem_wdata[7:0];
            if (dmem_wmask[1]) mem[dmem_addr[31:2]][15:8]  <= dmem_wdata[15:8];
            if (dmem_wmask[2]) mem[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_wmask[3]) mem[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
        end
    end

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'b0;
        imem_rdata    = 32'h0000_0013;
        dmem_rdata    = 32'b0;
        dmem_rsp_valid = 1'b0;
        program_file  = "inst.txt";
        if (!$value$plusargs("PROGRAM=%s", program_file)) begin end
        $display("PROGRAM=%s", program_file);
        $readmemh(program_file, mem);

        rst = 1'b1;
        cycle_count = 0;
        repeat (5) @(posedge clk);
        rst = 1'b0;
    end

    always @(posedge clk) begin
        if (!rst)
            cycle_count = cycle_count + 1;

        // RISC-V ISA binaries finish with jal x0, 0.  x27 is the pass flag,
        // while x3 holds the failing test number.
        if (!rst && ins === 32'h0000_006f) begin
            if (dut.u_idu.u_rf.rf[27] === 32'd1) begin
                $display("TEST_PASS");
                $display("cycle_count=%0d", cycle_count);
                $finish;
            end else begin
                $display("TEST_FAIL testnum=%0d", dut.u_idu.u_rf.rf[3]);
                $display("cycle_count=%0d", cycle_count);
                $fatal(1, "TEST_FAIL");
            end
        end
    end

    initial begin
        timeout_cycles = 1000000;
        if (!$value$plusargs("TIMEOUT=%d", timeout_cycles)) begin end
        repeat (timeout_cycles) @(posedge clk);
        $display("TEST_TIMEOUT");
        $fatal(1, "TEST_TIMEOUT");
    end
endmodule
