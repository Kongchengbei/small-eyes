`timescale 1ns / 1ps
module tb_flash_ddr_smoke;
    localparam integer MEM_WORDS = 4096;
    localparam integer SMOKE_BYTES = 16;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] SMOKE_JAL = 32'h0000_006f;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg ddr_init_done = 1'b0;
    reg corrupt_readback = 1'b0;
    always #5 clk = ~clk;

    wire flash_req_valid, flash_req_ready;
    wire [23:0] flash_req_addr;
    wire [31:0] flash_req_length;
    wire flash_rsp_valid, flash_rsp_ready;
    wire [7:0] flash_rsp_data;
    reg flash_rsp_valid_q = 1'b0;
    reg [7:0] flash_rsp_data_q = 8'h00;
    reg flash_stream_active = 1'b0;
    reg [31:0] flash_stream_index = 32'd0;
    reg [7:0] flash_image [0:SMOKE_BYTES-1];
    assign flash_req_ready = 1'b1;
    assign flash_rsp_valid = flash_rsp_valid_q;
    assign flash_rsp_data = flash_rsp_data_q;

    wire boot_ddr_req_valid, boot_ddr_req_ready, boot_ddr_req_write;
    wire [31:0] boot_ddr_req_addr, boot_ddr_req_wdata;
    wire [3:0] boot_ddr_req_wstrb;
    wire boot_ddr_rsp_valid, boot_ddr_rsp_ready, boot_ddr_rsp_is_read;
    wire [31:0] boot_ddr_rsp_rdata;
    wire boot_done, boot_error, boot_busy;
    wire [3:0] boot_error_code;

    flash_ddr_loader #(
        .FLASH_BASE(24'h000000),
        .DDR_BASE(DDR_BASE),
        .IMAGE_BYTES(SMOKE_BYTES),
        .TIMEOUT_CYCLES(1000)
    ) u_loader (
        .clk(clk), .rst_n(rst_n), .ddr_init_done(ddr_init_done),
        .flash_req_valid(flash_req_valid), .flash_req_ready(flash_req_ready),
        .flash_req_addr(flash_req_addr), .flash_req_length(flash_req_length),
        .flash_rsp_valid(flash_rsp_valid),
        .flash_rsp_ready(flash_rsp_ready), .flash_rsp_data(flash_rsp_data),
        .ddr_req_valid(boot_ddr_req_valid), .ddr_req_ready(boot_ddr_req_ready),
        .ddr_req_write(boot_ddr_req_write), .ddr_req_addr(boot_ddr_req_addr),
        .ddr_req_wdata(boot_ddr_req_wdata), .ddr_req_wstrb(boot_ddr_req_wstrb),
        .ddr_rsp_valid(boot_ddr_rsp_valid), .ddr_rsp_ready(boot_ddr_rsp_ready),
        .ddr_rsp_is_read(boot_ddr_rsp_is_read), .ddr_rsp_rdata(boot_ddr_rsp_rdata),
        .boot_done(boot_done), .boot_error(boot_error),
        .error_code(boot_error_code), .busy(boot_busy)
    );

    wire cpu_rst = !rst_n || !boot_done || boot_error;
    wire [3:0] axi_awid, axi_wid, axi_bid, axi_arid, axi_rid;
    wire [31:0] axi_awaddr, axi_wdata, axi_araddr, axi_rdata;
    wire [7:0] axi_awlen, axi_arlen;
    wire [2:0] axi_awsize, axi_arsize;
    wire [1:0] axi_awburst, axi_arburst, axi_bresp, axi_rresp;
    wire axi_awvalid, axi_awready, axi_wlast, axi_wvalid, axi_wready;
    wire axi_bvalid, axi_bready, axi_arvalid, axi_arready;
    wire axi_rlast, axi_rvalid, axi_rready;
    wire [3:0] axi_wstrb;
    wire [31:0] pc, ins;
    wire is_ebreak, icache_miss, dcache_miss;
    wire [31:0] debug_if_pc, debug_id_pc, debug_ex_pc, debug_mem_pc, debug_wb_pc;
    wire [31:0] debug_if_ins, debug_id_ins, debug_ex_ins, debug_mem_ins, debug_wb_ins;
    wire [31:0] debug_dmem_addr, debug_dmem_wdata, debug_btb_predict_next_pc;
    wire [31:0] debug_actual_next_pc, debug_flush_pc, debug_ctrl;

    Htop #(.RESET_PC(DDR_BASE), .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h4000_0000)) u_cpu (
        .clk(clk), .rst(cpu_rst), .irq_external(1'b0),
        .axi_awid(axi_awid), .axi_awaddr(axi_awaddr), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wid(axi_wid), .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb),
        .axi_wlast(axi_wlast), .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
        .axi_bid(axi_bid), .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid),
        .axi_bready(axi_bready), .axi_arid(axi_arid), .axi_araddr(axi_araddr),
        .axi_arlen(axi_arlen), .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready), .axi_rid(axi_rid),
        .axi_rdata(axi_rdata), .axi_rresp(axi_rresp), .axi_rlast(axi_rlast),
        .axi_rvalid(axi_rvalid), .axi_rready(axi_rready), .pc(pc), .ins(ins),
        .is_ebreak(is_ebreak), .icache_miss(icache_miss), .dcache_miss(dcache_miss),
        .debug_if_pc(debug_if_pc), .debug_id_pc(debug_id_pc), .debug_ex_pc(debug_ex_pc),
        .debug_mem_pc(debug_mem_pc), .debug_wb_pc(debug_wb_pc),
        .debug_if_ins(debug_if_ins), .debug_id_ins(debug_id_ins),
        .debug_ex_ins(debug_ex_ins), .debug_mem_ins(debug_mem_ins),
        .debug_wb_ins(debug_wb_ins), .debug_dmem_addr(debug_dmem_addr),
        .debug_dmem_wdata(debug_dmem_wdata),
        .debug_btb_predict_next_pc(debug_btb_predict_next_pc),
        .debug_actual_next_pc(debug_actual_next_pc), .debug_flush_pc(debug_flush_pc),
        .debug_ctrl(debug_ctrl)
    );

    wire mmio_req_valid, mmio_req_wen;
    wire [31:0] mmio_req_addr, mmio_req_wdata;
    wire [3:0] mmio_req_wstrb;
    wire run_req_valid, run_req_ready, run_req_write;
    wire [31:0] run_req_addr, run_req_wdata;
    wire [3:0] run_req_wstrb;
    wire run_rsp_valid, run_rsp_ready, run_rsp_is_read;
    wire [31:0] run_rsp_rdata;
    wire boot_owns_ddr = !boot_done && !boot_error;

    wire ddr_req_valid = boot_owns_ddr ? boot_ddr_req_valid : run_req_valid;
    wire ddr_req_write = boot_owns_ddr ? boot_ddr_req_write : run_req_write;
    wire [31:0] ddr_req_addr = boot_owns_ddr ? boot_ddr_req_addr : run_req_addr;
    wire [31:0] ddr_req_wdata = boot_owns_ddr ? boot_ddr_req_wdata : run_req_wdata;
    wire [3:0] ddr_req_wstrb = boot_owns_ddr ? boot_ddr_req_wstrb : run_req_wstrb;
    wire ddr_rsp_ready = boot_owns_ddr ? boot_ddr_rsp_ready : run_rsp_ready;
    wire ddr_req_ready = 1'b1;
    reg ddr_rsp_valid = 1'b0;
    reg ddr_rsp_is_read = 1'b0;
    reg [31:0] ddr_rsp_rdata = 32'd0;
    assign boot_ddr_req_ready = boot_owns_ddr && ddr_req_ready;
    assign run_req_ready = !boot_owns_ddr && ddr_req_ready;
    assign boot_ddr_rsp_valid = boot_owns_ddr && ddr_rsp_valid;
    assign run_rsp_valid = !boot_owns_ddr && ddr_rsp_valid;
    assign boot_ddr_rsp_is_read = ddr_rsp_is_read;
    assign boot_ddr_rsp_rdata = ddr_rsp_rdata;
    assign run_rsp_is_read = ddr_rsp_is_read;
    assign run_rsp_rdata = ddr_rsp_rdata;

    axi_mem_backend u_backend (
        .clk(clk), .rst_n(rst_n),
        .axi_awid(axi_awid), .axi_awaddr(axi_awaddr), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready), .axi_bid(axi_bid),
        .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid), .axi_bready(axi_bready),
        .axi_arid(axi_arid), .axi_araddr(axi_araddr), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready), .axi_rid(axi_rid),
        .axi_rdata(axi_rdata), .axi_rresp(axi_rresp), .axi_rlast(axi_rlast),
        .axi_rvalid(axi_rvalid), .axi_rready(axi_rready),
        .mmio_req_valid(mmio_req_valid), .mmio_req_wen(mmio_req_wen),
        .mmio_req_addr(mmio_req_addr), .mmio_req_wdata(mmio_req_wdata),
        .mmio_req_wstrb(mmio_req_wstrb), .mmio_req_ready(1'b1),
        .mmio_req_rdata(32'd0), .ddr_req_valid(run_req_valid),
        .ddr_req_ready(run_req_ready), .ddr_req_write(run_req_write),
        .ddr_req_addr(run_req_addr), .ddr_req_wdata(run_req_wdata),
        .ddr_req_wstrb(run_req_wstrb), .ddr_rsp_valid(run_rsp_valid),
        .ddr_rsp_ready(run_rsp_ready), .ddr_rsp_is_read(run_rsp_is_read),
        .ddr_rsp_rdata(run_rsp_rdata), .jtag_cmd_valid(1'b0),
        .jtag_cmd_ready(), .jtag_cmd_addr(32'd0), .jtag_cmd_read(1'b0),
        .jtag_cmd_wdata(32'd0), .jtag_cmd_wmask(4'd0), .jtag_rsp_valid(),
        .jtag_rsp_ready(1'b1), .jtag_rsp_err(), .jtag_rsp_rdata()
    );

    reg [31:0] ddr_mem [0:MEM_WORDS-1];
    wire [31:0] ddr_word_index = (ddr_req_addr - DDR_BASE) >> 2;
    integer i;
    integer cycles;
    integer expect_failure;
    reg led_write_seen = 1'b0;

    always @(posedge clk) begin
        if (!rst_n) begin
            flash_rsp_valid_q <= 1'b0;
            flash_stream_active <= 1'b0;
            flash_stream_index <= 32'd0;
            ddr_rsp_valid <= 1'b0;
        end else begin
            if (flash_req_valid && flash_req_ready) begin
                if (flash_req_addr !== 24'd0 || flash_req_length !== SMOKE_BYTES)
                    $fatal(1, "Bad Flash stream request addr=%h len=%0d", flash_req_addr, flash_req_length);
                flash_stream_active <= 1'b1;
                flash_stream_index <= 32'd0;
                flash_rsp_data_q <= flash_image[0];
                flash_rsp_valid_q <= 1'b1;
            end else if (flash_rsp_valid_q && flash_rsp_ready) begin
                if (flash_stream_index + 1 >= SMOKE_BYTES) begin
                    flash_rsp_valid_q <= 1'b0;
                    flash_stream_active <= 1'b0;
                end else begin
                    flash_stream_index <= flash_stream_index + 1'b1;
                    flash_rsp_data_q <= flash_image[flash_stream_index + 1'b1];
                end
            end

            if (ddr_rsp_valid && ddr_rsp_ready)
                ddr_rsp_valid <= 1'b0;
            if (ddr_req_valid && ddr_req_ready) begin
                ddr_rsp_valid <= 1'b1;
                ddr_rsp_is_read <= !ddr_req_write;
                if (ddr_word_index >= MEM_WORDS)
                    $fatal(1, "DDR address out of model: %h", ddr_req_addr);
                if (ddr_req_write) begin
                    if (ddr_req_wstrb != 4'hf)
                        $fatal(1, "Unexpected write strobe %b", ddr_req_wstrb);
                    ddr_mem[ddr_word_index] <= ddr_req_wdata;
                end else if (corrupt_readback)
                    ddr_rsp_rdata <= ddr_mem[ddr_word_index] ^ 32'h1;
                else
                    ddr_rsp_rdata <= ddr_mem[ddr_word_index];
            end
            if (mmio_req_valid && mmio_req_wen &&
                mmio_req_addr == 32'h4000_0200 &&
                mmio_req_wdata == 32'h0000_005a)
                led_write_seen <= 1'b1;
        end
    end

    initial begin
        // RV32I: lui x1,0x40000; addi x2,x0,0x5a;
        //        sw x2,512(x1); jal x0,0
        flash_image[0]  = 8'hb7;
        flash_image[1]  = 8'h00;
        flash_image[2]  = 8'h00;
        flash_image[3]  = 8'h40;
        flash_image[4]  = 8'h13;
        flash_image[5]  = 8'h01;
        flash_image[6]  = 8'ha0;
        flash_image[7]  = 8'h05;
        flash_image[8]  = 8'h23;
        flash_image[9]  = 8'ha0;
        flash_image[10] = 8'h20;
        flash_image[11] = 8'h20;
        flash_image[12] = 8'h6f;
        flash_image[13] = 8'h00;
        flash_image[14] = 8'h00;
        flash_image[15] = 8'h00;
        for (i = 0; i < MEM_WORDS; i = i + 1)
            ddr_mem[i] = 32'd0;
        expect_failure = $test$plusargs("EXPECT_FAILURE");
        corrupt_readback = expect_failure;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (8) @(posedge clk);
        if (flash_req_valid)
            $fatal(1, "Loader read Flash before DDR init");
        if (!cpu_rst || run_req_valid)
            $fatal(1, "CPU must stay reset with no DDR accesses before image validation: rst=%b", cpu_rst);
        ddr_init_done = 1'b1;

        cycles = 0;
        while (!boot_done && !boot_error && cycles < 2000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        if (expect_failure) begin
            if (!boot_error || boot_error_code != 4'd6 || !cpu_rst)
                $fatal(1, "Expected readback error with CPU held reset; err=%b code=%0d", boot_error, boot_error_code);
            $display("FLASH_DDR_FAILURE_PATH_PASS code=%0d", boot_error_code);
            $finish;
        end else begin
            if (!boot_done || boot_error)
                $fatal(1, "Boot loader failed: done=%b err=%b code=%0d", boot_done, boot_error, boot_error_code);
            cycles = 0;
            while (!led_write_seen && cycles < 2000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            repeat (30) @(posedge clk);
            if (cpu_rst || !led_write_seen || ddr_mem[0] !== 32'h4000_00b7 ||
                ddr_mem[1] !== 32'h05a0_0113 || ddr_mem[2] !== 32'h2020_a023 ||
                ddr_mem[3] !== SMOKE_JAL)
                $fatal(1, "CPU smoke failed: rst=%b led_seen=%b pc=%h ins=%h", cpu_rst, led_write_seen, pc, ins);
            $display("FLASH_DDR_CPU_SMOKE_PASS image=%08h/%08h/%08h/%08h LED=0x5a pc=%08h",
                     ddr_mem[0], ddr_mem[1], ddr_mem[2], ddr_mem[3], pc);
            $finish;
        end
    end

    initial begin
        #500000;
        $fatal(1, "Testbench global timeout");
    end
endmodule
