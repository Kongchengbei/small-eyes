`timescale 1ns / 1ps

module tb_Htop;

    localparam MEM_WORDS = 16384;  // 64 KiB at DDR_BASE
    localparam [31:0] DDR_BASE = 32'h8000_0000;

    reg clk = 1'b0;
    reg rst = 1'b1;

    // Htop exposes an AXI master. The memory backend converts it into the
    // one-word DDR-side interface provided by this testbench.
    wire [3:0]  axi_awid;
    wire [31:0] axi_awaddr;
    wire [7:0]  axi_awlen;
    wire [2:0]  axi_awsize;
    wire [1:0]  axi_awburst;
    wire        axi_awvalid;
    wire        axi_awready;

    wire [3:0]  axi_wid;
    wire [31:0] axi_wdata;
    wire [3:0]  axi_wstrb;
    wire        axi_wlast;
    wire        axi_wvalid;
    wire        axi_wready;

    wire [3:0]  axi_bid;
    wire [1:0]  axi_bresp;
    wire        axi_bvalid;
    wire        axi_bready;

    wire [3:0]  axi_arid;
    wire [31:0] axi_araddr;
    wire [7:0]  axi_arlen;
    wire [2:0]  axi_arsize;
    wire [1:0]  axi_arburst;
    wire        axi_arvalid;
    wire        axi_arready;

    wire [3:0]  axi_rid;
    wire [31:0] axi_rdata;
    wire [1:0]  axi_rresp;
    wire        axi_rlast;
    wire        axi_rvalid;
    wire        axi_rready;

    wire        mmio_req_valid;
    wire        mmio_req_wen;
    wire [31:0] mmio_req_addr;
    wire [31:0] mmio_req_wdata;
    wire [3:0]  mmio_req_wstrb;

    wire        ddr_req_valid;
    wire        ddr_req_ready = 1'b1;
    wire        ddr_req_write;
    wire [31:0] ddr_req_addr;
    wire [31:0] ddr_req_wdata;
    wire [3:0]  ddr_req_wstrb;
    wire        ddr_rsp_ready;
    reg         ddr_rsp_valid = 1'b0;
    reg         ddr_rsp_is_read = 1'b0;
    reg  [31:0] ddr_rsp_rdata = 32'b0;

    reg [31:0] mem [0:MEM_WORDS-1];
    wire [31:0] ddr_word_addr = (ddr_req_addr - DDR_BASE) >> 2;
    wire        ddr_addr_valid = (ddr_req_addr >= DDR_BASE) &&
                                 (ddr_word_addr < MEM_WORDS);

    integer i;
    integer cycle_count;
    integer timeout_cycles;
    string program_file;

    wire [31:0] pc;
    wire [31:0] ins;
    wire        is_ebreak;
    wire        icache_miss;
    wire        dcache_miss;
    wire [31:0] debug_if_pc;
    wire [31:0] debug_id_pc;
    wire [31:0] debug_ex_pc;
    wire [31:0] debug_mem_pc;
    wire [31:0] debug_wb_pc;
    wire [31:0] debug_if_ins;
    wire [31:0] debug_id_ins;
    wire [31:0] debug_ex_ins;
    wire [31:0] debug_mem_ins;
    wire [31:0] debug_wb_ins;
    wire [31:0] debug_dmem_addr;
    wire [31:0] debug_dmem_wdata;
    wire [31:0] debug_btb_predict_next_pc;
    wire [31:0] debug_actual_next_pc;
    wire [31:0] debug_flush_pc;
    wire [31:0] debug_ctrl;

    always #5 clk = ~clk;

    Htop dut (
        .clk        (clk),
        .rst        (rst),
        .axi_awid   (axi_awid),
        .axi_awaddr (axi_awaddr),
        .axi_awlen  (axi_awlen),
        .axi_awsize (axi_awsize),
        .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid),
        .axi_awready(axi_awready),
        .axi_wid    (axi_wid),
        .axi_wdata  (axi_wdata),
        .axi_wstrb  (axi_wstrb),
        .axi_wlast  (axi_wlast),
        .axi_wvalid (axi_wvalid),
        .axi_wready (axi_wready),
        .axi_bid    (axi_bid),
        .axi_bresp  (axi_bresp),
        .axi_bvalid (axi_bvalid),
        .axi_bready (axi_bready),
        .axi_arid   (axi_arid),
        .axi_araddr (axi_araddr),
        .axi_arlen  (axi_arlen),
        .axi_arsize (axi_arsize),
        .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready),
        .axi_rid    (axi_rid),
        .axi_rdata  (axi_rdata),
        .axi_rresp  (axi_rresp),
        .axi_rlast  (axi_rlast),
        .axi_rvalid (axi_rvalid),
        .axi_rready (axi_rready),
        .pc         (pc),
        .ins        (ins),
        .is_ebreak  (is_ebreak),
        .icache_miss(icache_miss),
        .dcache_miss(dcache_miss),
        .debug_if_pc(debug_if_pc),
        .debug_id_pc(debug_id_pc),
        .debug_ex_pc(debug_ex_pc),
        .debug_mem_pc(debug_mem_pc),
        .debug_wb_pc(debug_wb_pc),
        .debug_if_ins(debug_if_ins),
        .debug_id_ins(debug_id_ins),
        .debug_ex_ins(debug_ex_ins),
        .debug_mem_ins(debug_mem_ins),
        .debug_wb_ins(debug_wb_ins),
        .debug_dmem_addr(debug_dmem_addr),
        .debug_dmem_wdata(debug_dmem_wdata),
        .debug_btb_predict_next_pc(debug_btb_predict_next_pc),
        .debug_actual_next_pc(debug_actual_next_pc),
        .debug_flush_pc(debug_flush_pc),
        .debug_ctrl(debug_ctrl)
    );

    axi_mem_backend u_mem_backend (
        .clk            (clk),
        .rst_n          (!rst),
        .axi_awid       (axi_awid),
        .axi_awaddr     (axi_awaddr),
        .axi_awlen      (axi_awlen),
        .axi_awsize     (axi_awsize),
        .axi_awburst    (axi_awburst),
        .axi_awvalid    (axi_awvalid),
        .axi_awready    (axi_awready),
        .axi_wdata      (axi_wdata),
        .axi_wstrb      (axi_wstrb),
        .axi_wlast      (axi_wlast),
        .axi_wvalid     (axi_wvalid),
        .axi_wready     (axi_wready),
        .axi_bid        (axi_bid),
        .axi_bresp      (axi_bresp),
        .axi_bvalid     (axi_bvalid),
        .axi_bready     (axi_bready),
        .axi_arid       (axi_arid),
        .axi_araddr     (axi_araddr),
        .axi_arlen      (axi_arlen),
        .axi_arsize     (axi_arsize),
        .axi_arburst    (axi_arburst),
        .axi_arvalid    (axi_arvalid),
        .axi_arready    (axi_arready),
        .axi_rid        (axi_rid),
        .axi_rdata      (axi_rdata),
        .axi_rresp      (axi_rresp),
        .axi_rlast      (axi_rlast),
        .axi_rvalid     (axi_rvalid),
        .axi_rready     (axi_rready),
        .mmio_req_valid (mmio_req_valid),
        .mmio_req_wen   (mmio_req_wen),
        .mmio_req_addr  (mmio_req_addr),
        .mmio_req_wdata (mmio_req_wdata),
        .mmio_req_wstrb (mmio_req_wstrb),
        .mmio_req_ready (1'b1),
        .mmio_req_rdata (32'b0),
        .ddr_req_valid  (ddr_req_valid),
        .ddr_req_ready  (ddr_req_ready),
        .ddr_req_write  (ddr_req_write),
        .ddr_req_addr   (ddr_req_addr),
        .ddr_req_wdata  (ddr_req_wdata),
        .ddr_req_wstrb  (ddr_req_wstrb),
        .ddr_rsp_valid  (ddr_rsp_valid),
        .ddr_rsp_ready  (ddr_rsp_ready),
        .ddr_rsp_is_read(ddr_rsp_is_read),
        .ddr_rsp_rdata  (ddr_rsp_rdata),
        .jtag_cmd_addr  (32'b0),
        .jtag_cmd_read  (1'b0),
        .jtag_cmd_valid (1'b0),
        .jtag_cmd_wdata (32'b0),
        .jtag_cmd_wmask (4'b0),
        .jtag_rsp_ready (1'b1),
        .jtag_cmd_ready (),
        .jtag_rsp_valid (),
        .jtag_rsp_err   (),
        .jtag_rsp_rdata ()
    );

    // One-cycle response model for the local DDR interface.
    always @(posedge clk) begin
        if (rst) begin
            ddr_rsp_valid <= 1'b0;
        end else begin
            if (ddr_rsp_valid && ddr_rsp_ready)
                ddr_rsp_valid <= 1'b0;

            if (ddr_req_valid && ddr_req_ready) begin
                ddr_rsp_valid   <= 1'b1;
                ddr_rsp_is_read <= !ddr_req_write;
                if (ddr_addr_valid) begin
                    if (ddr_req_write) begin
                        if (ddr_req_wstrb[0])
                            mem[ddr_word_addr][7:0] <= ddr_req_wdata[7:0];
                        if (ddr_req_wstrb[1])
                            mem[ddr_word_addr][15:8] <= ddr_req_wdata[15:8];
                        if (ddr_req_wstrb[2])
                            mem[ddr_word_addr][23:16] <= ddr_req_wdata[23:16];
                        if (ddr_req_wstrb[3])
                            mem[ddr_word_addr][31:24] <= ddr_req_wdata[31:24];
                    end else begin
                        ddr_rsp_rdata <= mem[ddr_word_addr];
                    end
                end else if (!ddr_req_write) begin
                    ddr_rsp_rdata <= 32'b0;
                end
            end
        end
    end

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'b0;

        program_file = "inst.txt";
        void'($value$plusargs("PROGRAM=%s", program_file));
        $display("PROGRAM=%s", program_file);
        $readmemh(program_file, mem);

        $dumpfile("tb.vcd");
        $dumpvars(0, tb_Htop);

        cycle_count = 0;
        repeat (5) @(posedge clk);
        rst = 1'b0;
    end

    always @(posedge clk)
        if (!rst)
            cycle_count = cycle_count + 1;

    // The ISA tests write x26/x27 and finish with `jal x0, 0`. Check the
    // result when that terminal instruction reaches the writeback stage, so
    // both result registers have passed through the pipeline.
    always @(posedge clk) begin
        if (!rst && ins === 32'h0000_006f) begin
            if (dut.u_idu.u_rf.rf[27] === 32'd1) begin
                $display("TEST_PASS");
                $display("cycle_count=%0d", cycle_count);
                $finish;
            end else begin
                $display("TEST_FAIL testnum=%0d", dut.u_idu.u_rf.rf[3]);
                $fatal(1, "TEST_FAIL");
            end
        end
    end

    initial begin
        timeout_cycles = 1000000;
        void'($value$plusargs("TIMEOUT=%d", timeout_cycles));
        repeat (timeout_cycles) @(posedge clk);
        $display("TEST_TIMEOUT");
        $fatal(1, "TEST_TIMEOUT");
    end

endmodule
