`timescale 1ns / 1ps

// End-to-end Flash boot path using the production reader, loader, ownership
// wrapper, AXI bridge, AXI memory backend, and Htop CPU. Only the SPI Flash and
// DDR-controller AXI pins are behavioral models.
module tb_flash_ddr_boot;
    localparam [23:0] FLASH_BASE = 24'hA00000;
    localparam [31:0] DDR_BASE = 32'h80000000;
    localparam integer IMAGE_WORDS = 14;
    localparam integer IMAGE_BYTES = IMAGE_WORDS * 4;

    reg cpu_clk = 1'b0;
    reg ddr_clk = 1'b0;
    always #5 cpu_clk = ~cpu_clk;
    always #7 ddr_clk = ~ddr_clk;

    reg rst_n = 1'b0;
    reg ddr_init_done = 1'b0;
    reg inject_corrupt_readback = 1'b1;
    reg [31:0] image_words [0:IMAGE_WORDS-1];

    function [7:0] image_byte;
        input [23:0] offset;
        reg [31:0] word_value;
        begin
            word_value = image_words[offset[7:2]];
            case (offset[1:0])
                2'd0: image_byte = word_value[7:0];
                2'd1: image_byte = word_value[15:8];
                2'd2: image_byte = word_value[23:16];
                default: image_byte = word_value[31:24];
            endcase
        end
    endfunction

    // SPI Flash model ------------------------------------------------------
    wire flash_cs_n;
    wire flash_cs2_n;
    wire flash_wp_n;
    wire flash_hold_n;
    wire flash_mosi;
    wire flash_sck;
    reg flash_miso = 1'b0;
    reg [31:0] spi_tx_shift;
    integer spi_tx_count = 0;
    integer spi_rx_count = 0;
    integer spi_stream_bytes = 0;
    integer flash_bytes_seen = 0;
    integer flash_byte_index_this_boot = 0;
    integer flash_transactions_seen = 0;
    integer completed_flash_transactions = 0;
    integer aborted_flash_transactions = 0;
    integer failure_bytes_seen = 0;
    reg [23:0] spi_addr;
    reg [7:0] spi_opcode;
    reg spi_active = 1'b0;
    reg [7:0] spi_rx_shift = 8'd0;
    wire [23:0] spi_base_offset = spi_addr - FLASH_BASE;
    wire [23:0] spi_byte_offset = spi_base_offset + spi_stream_bytes[23:0];
    wire [7:0] flash_model_byte = image_byte(spi_byte_offset);

    always @(negedge flash_cs_n) begin
        if (rst_n) begin
            if (flash_sck !== 1'b0)
                $fatal(1, "Flash CS asserted while SCK high");
            spi_tx_shift = 32'd0;
            spi_tx_count = 0;
            spi_rx_count = 0;
            spi_stream_bytes = 0;
            spi_rx_shift = 8'd0;
            spi_addr = 24'd0;
            spi_opcode = 8'd0;
            spi_active = 1'b1;
            flash_transactions_seen = flash_transactions_seen + 1;
            flash_miso = 1'b0;
        end
    end

    always @(posedge flash_sck) begin
        if (flash_cs_n !== 1'b0)
            $fatal(1, "Flash SCK rose while CS high");
        if (spi_tx_count < 32) begin
            spi_tx_shift = {spi_tx_shift[30:0], flash_mosi};
            spi_tx_count = spi_tx_count + 1;
            if (spi_tx_count == 32) begin
                spi_opcode = spi_tx_shift[31:24];
                spi_addr = spi_tx_shift[23:0];
                if (spi_opcode !== 8'h03)
                    $fatal(1, "expected 03h Read Data, got %02x", spi_opcode);
                if (spi_addr !== FLASH_BASE)
                    $fatal(1, "expected one stream start address %06x, got %06x", FLASH_BASE, spi_addr);
            end
        end else begin
            spi_rx_shift = {spi_rx_shift[6:0], flash_miso};
            spi_rx_count = spi_rx_count + 1;
            if (spi_rx_count == 8) begin
                if (spi_rx_shift !== flash_model_byte)
                    $fatal(1, "Flash stream byte %0d = %02x expected %02x", spi_stream_bytes, spi_rx_shift, flash_model_byte);
                spi_rx_count = 0;
                spi_rx_shift = 8'd0;
                spi_stream_bytes = spi_stream_bytes + 1;
                flash_bytes_seen = flash_bytes_seen + 1;
                flash_byte_index_this_boot = flash_byte_index_this_boot + 1;
            end
        end
    end

    always @(negedge flash_sck) begin
        if (flash_cs_n === 1'b0 && spi_active && spi_tx_count == 32) begin
            flash_miso = flash_model_byte[7-spi_rx_count];
        end
    end

    always @(posedge flash_cs_n) begin
        if (spi_active) begin
            if (flash_sck !== 1'b0)
                $fatal(1, "Flash CS released while SCK high");
            if (spi_tx_count == 32 && spi_rx_count == 0 && spi_stream_bytes == IMAGE_BYTES)
                completed_flash_transactions = completed_flash_transactions + 1;
            else
                aborted_flash_transactions = aborted_flash_transactions + 1;
            spi_active = 1'b0;
            flash_miso = 1'b0;
        end
    end

    // Boot wrapper and CPU/backend side ----------------------------------
    wire boot_done;
    wire boot_error;
    wire [3:0] boot_error_code;
    wire boot_ddr_ready_cpu;
    wire flash_clk_enable;
    wire ddr_req_valid, ddr_req_ready, ddr_req_write;
    wire [31:0] ddr_req_addr, ddr_req_wdata;
    wire [3:0] ddr_req_wstrb;
    wire ddr_rsp_valid, ddr_rsp_ready, ddr_rsp_is_read;
    wire [31:0] ddr_rsp_rdata;
    wire run_req_valid, run_req_ready, run_req_write;
    wire [31:0] run_req_addr, run_req_wdata;
    wire [3:0] run_req_wstrb;
    wire run_rsp_valid, run_rsp_ready, run_rsp_is_read;
    wire [31:0] run_rsp_rdata;

    flash_ddr_boot #(
        .FLASH_BASE(FLASH_BASE), .DDR_BASE(DDR_BASE),
        .DDR_LIMIT(33'h0_C0000000), .IMAGE_BYTES(IMAGE_BYTES),
        .SPI_CLK_DIV(4), .TIMEOUT_CYCLES(20000),
        .DDR_INIT_TIMEOUT_CYCLES(150000)
    ) boot (
        .clk(cpu_clk), .rst_n(rst_n), .ddr_init_done(ddr_init_done),
        .flash_cs_n(flash_cs_n), .flash_cs2_n(flash_cs2_n), .flash_mosi(flash_mosi),
        .flash_miso(flash_miso), .flash_wp_n(flash_wp_n), .flash_hold_n(flash_hold_n), .flash_sck(flash_sck),
        .run_req_valid(run_req_valid), .run_req_ready(run_req_ready),
        .run_req_write(run_req_write), .run_req_addr(run_req_addr),
        .run_req_wdata(run_req_wdata), .run_req_wstrb(run_req_wstrb),
        .run_rsp_valid(run_rsp_valid), .run_rsp_ready(run_rsp_ready),
        .run_rsp_is_read(run_rsp_is_read), .run_rsp_rdata(run_rsp_rdata),
        .ddr_req_valid(ddr_req_valid), .ddr_req_ready(ddr_req_ready),
        .ddr_req_write(ddr_req_write), .ddr_req_addr(ddr_req_addr),
        .ddr_req_wdata(ddr_req_wdata), .ddr_req_wstrb(ddr_req_wstrb),
        .ddr_rsp_valid(ddr_rsp_valid), .ddr_rsp_ready(ddr_rsp_ready),
        .ddr_rsp_is_read(ddr_rsp_is_read), .ddr_rsp_rdata(ddr_rsp_rdata),
        .boot_done(boot_done), .boot_error(boot_error),
        .boot_error_code(boot_error_code), .ddr_ready_cpu(boot_ddr_ready_cpu),
        .flash_clk_enable(flash_clk_enable)
    );

    reg [3:0] cpu_reset_count = 4'd0;
    always @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n) cpu_reset_count <= 4'd0;
        else if (cpu_reset_count != 4'hf) cpu_reset_count <= cpu_reset_count + 1'b1;
    end
    wire cpu_reset = !rst_n || (cpu_reset_count != 4'hf) ||
                     !boot_done || boot_error || !boot_ddr_ready_cpu;

    wire [3:0] cpu_awid, cpu_wid, cpu_bid, cpu_arid, cpu_rid;
    wire [31:0] cpu_awaddr, cpu_wdata, cpu_araddr, cpu_rdata;
    wire [7:0] cpu_awlen, cpu_arlen;
    wire [2:0] cpu_awsize, cpu_arsize;
    wire [1:0] cpu_awburst, cpu_arburst, cpu_bresp, cpu_rresp;
    wire cpu_awvalid, cpu_awready, cpu_wlast, cpu_wvalid, cpu_wready;
    wire cpu_bvalid, cpu_bready, cpu_arvalid, cpu_arready;
    wire cpu_rlast, cpu_rvalid, cpu_rready;
    wire [3:0] cpu_wstrb;
    wire [31:0] pc, instruction;
    wire is_ebreak;

    Htop #(.RESET_PC(DDR_BASE), .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h40000000)) cpu (
        .clk(cpu_clk), .rst(cpu_reset), .irq_external(1'b0),
        .bram_prog_valid(1'b0), .bram_prog_write(1'b0),
        .bram_prog_addr(32'b0), .bram_prog_wdata(32'b0), .bram_prog_wstrb(4'b0),
        .bram_prog_ready(), .bram_prog_rdata(),
        .axi_awid(cpu_awid), .axi_awaddr(cpu_awaddr), .axi_awlen(cpu_awlen),
        .axi_awsize(cpu_awsize), .axi_awburst(cpu_awburst), .axi_awvalid(cpu_awvalid),
        .axi_awready(cpu_awready), .axi_wid(cpu_wid), .axi_wdata(cpu_wdata),
        .axi_wstrb(cpu_wstrb), .axi_wlast(cpu_wlast), .axi_wvalid(cpu_wvalid),
        .axi_wready(cpu_wready), .axi_bid(cpu_bid), .axi_bresp(cpu_bresp),
        .axi_bvalid(cpu_bvalid), .axi_bready(cpu_bready), .axi_arid(cpu_arid),
        .axi_araddr(cpu_araddr), .axi_arlen(cpu_arlen), .axi_arsize(cpu_arsize),
        .axi_arburst(cpu_arburst), .axi_arvalid(cpu_arvalid), .axi_arready(cpu_arready),
        .axi_rid(cpu_rid), .axi_rdata(cpu_rdata), .axi_rresp(cpu_rresp),
        .axi_rlast(cpu_rlast), .axi_rvalid(cpu_rvalid), .axi_rready(cpu_rready),
        .pc(pc), .ins(instruction), .is_ebreak(is_ebreak),
        .icache_miss(), .dcache_miss(),
        .debug_if_pc(), .debug_id_pc(), .debug_ex_pc(), .debug_mem_pc(), .debug_wb_pc(),
        .debug_if_ins(), .debug_id_ins(), .debug_ex_ins(), .debug_mem_ins(), .debug_wb_ins(),
        .debug_dmem_addr(), .debug_dmem_wdata(), .debug_btb_predict_next_pc(),
        .debug_actual_next_pc(), .debug_flush_pc(), .debug_ctrl()
    );

    wire mmio_req_valid, mmio_req_wen;
    wire [31:0] mmio_req_addr, mmio_req_wdata;
    wire [3:0] mmio_req_wstrb;
    reg [31:0] led_value = 32'd0;
    reg [31:0] first_led_value = 32'd0;
    integer led_write_count = 0;
    assign mmio_req_ready = 1'b1;
    wire mmio_req_ready;
    assign mmio_req_rdata = 32'd0;
    wire [31:0] mmio_req_rdata;

    axi_mem_backend #(.DDR_BASE(DDR_BASE), .DDR_BYTES(32'h40000000)) backend (
        .clk(cpu_clk), .rst_n(rst_n),
        .axi_awid(cpu_awid), .axi_awaddr(cpu_awaddr), .axi_awlen(cpu_awlen),
        .axi_awsize(cpu_awsize), .axi_awburst(cpu_awburst), .axi_awvalid(cpu_awvalid),
        .axi_awready(cpu_awready), .axi_wdata(cpu_wdata), .axi_wstrb(cpu_wstrb),
        .axi_wlast(cpu_wlast), .axi_wvalid(cpu_wvalid), .axi_wready(cpu_wready),
        .axi_bid(cpu_bid), .axi_bresp(cpu_bresp), .axi_bvalid(cpu_bvalid), .axi_bready(cpu_bready),
        .axi_arid(cpu_arid), .axi_araddr(cpu_araddr), .axi_arlen(cpu_arlen),
        .axi_arsize(cpu_arsize), .axi_arburst(cpu_arburst), .axi_arvalid(cpu_arvalid),
        .axi_arready(cpu_arready), .axi_rid(cpu_rid), .axi_rdata(cpu_rdata),
        .axi_rresp(cpu_rresp), .axi_rlast(cpu_rlast), .axi_rvalid(cpu_rvalid), .axi_rready(cpu_rready),
        .mmio_req_valid(mmio_req_valid), .mmio_req_wen(mmio_req_wen),
        .mmio_req_addr(mmio_req_addr), .mmio_req_wdata(mmio_req_wdata),
        .mmio_req_wstrb(mmio_req_wstrb), .mmio_req_ready(mmio_req_ready), .mmio_req_rdata(mmio_req_rdata),
        .ddr_req_valid(run_req_valid), .ddr_req_ready(run_req_ready), .ddr_req_write(run_req_write),
        .ddr_req_addr(run_req_addr), .ddr_req_wdata(run_req_wdata), .ddr_req_wstrb(run_req_wstrb),
        .ddr_rsp_valid(run_rsp_valid), .ddr_rsp_ready(run_rsp_ready),
        .ddr_rsp_is_read(run_rsp_is_read), .ddr_rsp_rdata(run_rsp_rdata),
        .jtag_cmd_addr(32'd0), .jtag_cmd_read(1'b0), .jtag_cmd_valid(1'b0),
        .jtag_cmd_wdata(32'd0), .jtag_cmd_wmask(4'd0), .jtag_rsp_ready(1'b1),
        .jtag_cmd_ready(), .jtag_rsp_valid(), .jtag_rsp_err(), .jtag_rsp_rdata()
    );

    always @(posedge cpu_clk) begin
        if (rst_n && mmio_req_valid && mmio_req_ready && mmio_req_wen &&
            mmio_req_addr == 32'h40000200) begin
            led_value <= mmio_req_wdata;
            if (led_write_count == 0) first_led_value <= mmio_req_wdata;
            led_write_count <= led_write_count + 1;
        end
        if (rst_n && !boot_done && !boot_error) begin
            if (!cpu_reset)
                $fatal(1, "CPU reset released before successful boot");
            if (cpu_awvalid || cpu_wvalid || cpu_arvalid)
                $fatal(1, "CPU attempted AXI access before boot completed");
        end
        if (rst_n && (flash_cs2_n !== 1'b1 || flash_wp_n !== 1'b1 || flash_hold_n !== 1'b1))
            $fatal(1, "secondary CS/WP/HOLD pins must remain inactive high");
        if (rst_n && boot_error && !cpu_reset)
            $fatal(1, "CPU reset released after boot failure");
    end

    // DDR AXI bridge and an unrelated-clock, stalled AXI DDR model ----------
    wire [29:0] ddr_awaddr, ddr_araddr;
    wire [7:0] ddr_awid, ddr_awlen, ddr_bid, ddr_arid, ddr_arlen, ddr_rid;
    wire [2:0] ddr_awsize, ddr_arsize;
    wire [1:0] ddr_awburst, ddr_arburst, ddr_bresp, ddr_rresp;
    wire ddr_awvalid, ddr_awready, ddr_wlast, ddr_wvalid, ddr_wready;
    wire ddr_bvalid, ddr_bready, ddr_arvalid, ddr_arready;
    wire ddr_rlast, ddr_rvalid, ddr_rready;
    wire [255:0] ddr_wdata, ddr_rdata;
    wire [31:0] ddr_wstrb;
    ddr_axi_bridge bridge (
        .cpu_clk(cpu_clk), .ddr_clk(ddr_clk), .rst_n(rst_n), .ddr_init_done(ddr_init_done),
        .cpu_req_valid(ddr_req_valid), .cpu_req_ready(ddr_req_ready),
        .cpu_req_write(ddr_req_write), .cpu_req_addr(ddr_req_addr),
        .cpu_req_wdata(ddr_req_wdata), .cpu_req_wmask(ddr_req_wstrb),
        .cpu_rsp_rdata(ddr_rsp_rdata), .cpu_rsp_valid(ddr_rsp_valid),
        .cpu_rsp_is_read(ddr_rsp_is_read), .cpu_rsp_ready(ddr_rsp_ready),
        .axi_awaddr(ddr_awaddr), .axi_awid(ddr_awid), .axi_awlen(ddr_awlen),
        .axi_awsize(ddr_awsize), .axi_awburst(ddr_awburst), .axi_awvalid(ddr_awvalid),
        .axi_awready(ddr_awready), .axi_wdata(ddr_wdata), .axi_wstrb(ddr_wstrb),
        .axi_wlast(ddr_wlast), .axi_wvalid(ddr_wvalid), .axi_wready(ddr_wready),
        .axi_bid(ddr_bid), .axi_bresp(ddr_bresp), .axi_bvalid(ddr_bvalid), .axi_bready(ddr_bready),
        .axi_araddr(ddr_araddr), .axi_arid(ddr_arid), .axi_arlen(ddr_arlen),
        .axi_arsize(ddr_arsize), .axi_arburst(ddr_arburst), .axi_arvalid(ddr_arvalid),
        .axi_arready(ddr_arready), .axi_rdata(ddr_rdata), .axi_rid(ddr_rid),
        .axi_rresp(ddr_rresp), .axi_rlast(ddr_rlast), .axi_rvalid(ddr_rvalid), .axi_rready(ddr_rready)
    );

    reg [7:0] ddr_mem [0:4095];
    reg [31:0] ddr_cycle = 0;
    reg aw_seen = 1'b0, w_seen = 1'b0;
    reg [29:0] saved_awaddr;
    reg [255:0] saved_wdata;
    reg [31:0] saved_wstrb;
    reg bvalid_q = 1'b0;
    reg [1:0] bdelay = 2'd0;
    reg rvalid_q = 1'b0;
    reg [255:0] rdata_q;
    reg [1:0] rdelay = 2'd0;
    integer ddr_read_count = 0;
    integer ddr_write_count = 0;
    integer k;
    reg [31:0] write_base;
    reg [31:0] read_base;
    reg [7:0] corrupt_byte;

    assign ddr_awready = rst_n && !aw_seen && !bvalid_q && (ddr_cycle[1:0] != 2'b00);
    assign ddr_wready  = rst_n && !w_seen && !bvalid_q && (ddr_cycle[2:1] != 2'b00);
    assign ddr_bid = 8'd0;
    assign ddr_bresp = 2'b00;
    assign ddr_bvalid = bvalid_q;
    assign ddr_arready = rst_n && !rvalid_q && (rdelay == 0) && (ddr_cycle[1:0] != 2'b01);
    assign ddr_rdata = rdata_q;
    assign ddr_rid = 8'd0;
    assign ddr_rresp = 2'b00;
    assign ddr_rlast = 1'b1;
    assign ddr_rvalid = rvalid_q;

    always @(posedge ddr_clk or negedge rst_n) begin
        if (!rst_n) begin
            ddr_cycle <= 0;
            aw_seen <= 1'b0;
            w_seen <= 1'b0;
            bvalid_q <= 1'b0;
            bdelay <= 0;
            rvalid_q <= 1'b0;
            rdelay <= 0;
            rdata_q <= 0;
            ddr_read_count <= 0;
            ddr_write_count <= 0;
        end else begin
            ddr_cycle <= ddr_cycle + 1'b1;
            write_base = aw_seen ? {2'b00, saved_awaddr} : {2'b00, ddr_awaddr};
            read_base = {2'b00, ddr_araddr};
            if (ddr_awvalid && ddr_awready) begin
                aw_seen <= 1'b1;
                saved_awaddr <= ddr_awaddr;
            end
            if (ddr_wvalid && ddr_wready) begin
                w_seen <= 1'b1;
                saved_wdata <= ddr_wdata;
                saved_wstrb <= ddr_wstrb;
            end
            if ((aw_seen || (ddr_awvalid && ddr_awready)) &&
                (w_seen || (ddr_wvalid && ddr_wready)) && !bvalid_q && bdelay == 0) begin
                for (k = 0; k < 32; k = k + 1) begin
                    if ((w_seen ? saved_wstrb[k] : ddr_wstrb[k]) &&
                        (write_base + k < 4096))
                        ddr_mem[write_base + k] <=
                            (w_seen ? saved_wdata[k*8 +: 8] : ddr_wdata[k*8 +: 8]);
                end
                bdelay <= 2'd2;
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
                ddr_write_count <= ddr_write_count + 1;
            end else if (bdelay != 0) begin
                bdelay <= bdelay - 1'b1;
                if (bdelay == 1) bvalid_q <= 1'b1;
            end
            if (bvalid_q && ddr_bready) bvalid_q <= 1'b0;

            if (ddr_arvalid && ddr_arready) begin
                for (k = 0; k < 32; k = k + 1) begin
                    if (read_base + k < 4096)
                        rdata_q[k*8 +: 8] <= ddr_mem[read_base + k];
                    else
                        rdata_q[k*8 +: 8] <= 8'd0;
                end
                if (inject_corrupt_readback && ddr_read_count == 0) begin
                    corrupt_byte = ddr_mem[read_base];
                    rdata_q[7:0] <= corrupt_byte ^ 8'h01;
                end
                ddr_read_count <= ddr_read_count + 1;
                rdelay <= 2'd2;
            end else if (rdelay != 0) begin
                rdelay <= rdelay - 1'b1;
                if (rdelay == 1) rvalid_q <= 1'b1;
            end
            if (rvalid_q && ddr_rready) rvalid_q <= 1'b0;
        end
    end

    task restart_boot;
        begin
            @(negedge cpu_clk);
            rst_n = 1'b0;
            flash_byte_index_this_boot = 0;
            repeat (4) @(posedge cpu_clk);
            @(negedge cpu_clk);
            rst_n = 1'b1;
        end
    endtask

    integer n;
    integer wait_cycles;
    initial begin
        $readmemh("test/running_led_test.dat", image_words);
        for (n = 0; n < 4096; n = n + 1) ddr_mem[n] = 8'd0;
        repeat (5) @(posedge cpu_clk);
        @(negedge cpu_clk);
        rst_n = 1'b1;
        // Deliberately keep DDR init low beyond the former shared 100k
        // transfer/init timeout. The dedicated 150k init timeout must allow
        // the boot sequencer to continue waiting.
        repeat (100050) @(posedge cpu_clk);
        #1;
        if (boot_error || boot_done || flash_bytes_seen != 0)
            $fatal(1, "delayed DDR init incorrectly failed or started Flash reads");
        if (flash_clk_enable !== 1'b0 || flash_cs_n !== 1'b1 || flash_sck !== 1'b0)
            $fatal(1, "Flash clock enabled before DDR initialization");
        @(negedge ddr_clk);
        ddr_init_done = 1'b1;
        $display("FLASH_DDR_BOOT_INIT_WAIT_PASS delayed_cpu_cycles=100050");
        wait_cycles = 0;
        while (!flash_clk_enable && wait_cycles < 16) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (!flash_clk_enable)
            $fatal(1, "Flash clock did not enable after DDR initialization");

        wait_cycles = 0;
        while (!boot_error && wait_cycles < 200000) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (!boot_error)
            $fatal(1, "corrupt readback did not cause boot failure");
        if (boot_error_code !== 4'd6)
            $fatal(1, "expected readback error 6, got %0d", boot_error_code);
        if (!cpu_reset || led_write_count != 0)
            $fatal(1, "CPU escaped reset or wrote LED after failed boot");
        failure_bytes_seen = flash_bytes_seen;
        if (failure_bytes_seen < 4 || failure_bytes_seen > 5)
            $fatal(1, "failure path should have sampled the failed word and at most one prefetched byte, saw %0d", failure_bytes_seen);
        wait_cycles = 0;
        while ((flash_cs_n !== 1'b1 || flash_sck !== 1'b0 || flash_clk_enable !== 1'b0) && wait_cycles < 8) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (flash_cs_n !== 1'b1 || flash_sck !== 1'b0 || flash_clk_enable !== 1'b0)
            $fatal(1, "readback error did not release Flash and gate its clock");
        if (completed_flash_transactions != 0 || aborted_flash_transactions != 1)
            $fatal(1, "failed stream CS counts complete=%0d abort=%0d total=%0d bytes=%0d bits=%0d",
                   completed_flash_transactions, aborted_flash_transactions,
                   flash_transactions_seen, failure_bytes_seen, spi_rx_count);
        $display("FLASH_DDR_BOOT_FAILURE_PASS code=%0d cpu_reset=%0d", boot_error_code, cpu_reset);

        inject_corrupt_readback = 1'b0;
        restart_boot();
        wait_cycles = 0;
        while (!boot_done && !boot_error && wait_cycles < 200000) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (boot_error || !boot_done)
            $fatal(1, "boot did not recover: done=%0d error=%0d code=%0d",
                   boot_done, boot_error, boot_error_code);
        if (flash_bytes_seen != failure_bytes_seen + IMAGE_BYTES)
            $fatal(1, "recovery did not reread image, total Flash bytes=%0d", flash_bytes_seen);
        if (completed_flash_transactions != 1 || flash_transactions_seen != 2)
            $fatal(1, "recovery should use one continuous Flash transaction");
        if (ddr_write_count < (IMAGE_BYTES / 4))
            $fatal(1, "expected DDR image writes, saw %0d", ddr_write_count);
        for (n = 0; n < IMAGE_BYTES; n = n + 1) begin
            if (ddr_mem[n] !== image_byte(n))
                $fatal(1, "DDR byte %0d = %02x, expected %02x", n, ddr_mem[n], image_byte(n));
        end
        $display("FLASH_DDR_BOOT_COPY_PASS bytes=%0d flash_reads=%0d", IMAGE_BYTES, IMAGE_BYTES);

        wait_cycles = 0;
        while (led_write_count < 1 && wait_cycles < 300000) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (led_write_count < 1)
            $fatal(1, "running_led_test.dat did not write LED MMIO");
        if (first_led_value !== 32'd1)
            $fatal(1, "first LED MMIO write was %08x, expected 00000001", first_led_value);
        $display("FLASH_DDR_BOOT_CPU_PASS led_writes=%0d led=%08x pc=%08x",
                 led_write_count, led_value, pc);

        // A later DDR-init loss invalidates the booted image. The error must
        // latch, return the CPU to reset, and gate off the dedicated Flash
        // clock. Restoring init alone must not release reset or restart boot.
        @(negedge ddr_clk);
        ddr_init_done = 1'b0;
        wait_cycles = 0;
        while (!boot_error && wait_cycles < 32) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        repeat (3) @(posedge cpu_clk);
        #1;
        if (!boot_error || boot_error_code !== 4'd2 || boot_done || !cpu_reset)
            $fatal(1, "DDR ready loss was not latched as error 2 with CPU reset");
        if (flash_clk_enable !== 1'b0 || flash_cs_n !== 1'b1 || flash_sck !== 1'b0)
            $fatal(1, "Flash clock/pins were not idle after DDR-init loss");
        @(negedge ddr_clk);
        ddr_init_done = 1'b1;
        repeat (8) @(posedge cpu_clk);
        if (!boot_error || boot_error_code !== 4'd2 || boot_done || !cpu_reset)
            $fatal(1, "restoring DDR init cleared latched boot failure without reset");
        $display("FLASH_DDR_READY_DROP_PASS code=%0d cpu_reset=%0d clk_enable=%0d",
                 boot_error_code, cpu_reset, flash_clk_enable);

        // A common reset clears the latched error and performs a full copy
        // again. This recovery check stops at successful boot completion.
        restart_boot();
        wait_cycles = 0;
        while (!boot_done && !boot_error && wait_cycles < 200000) begin
            @(posedge cpu_clk);
            wait_cycles = wait_cycles + 1;
        end
        if (!boot_done || boot_error)
            $fatal(1, "common reset did not recover from DDR-init loss");
        if (flash_bytes_seen != failure_bytes_seen + IMAGE_BYTES + IMAGE_BYTES)
            $fatal(1, "common reset did not re-read all bytes, count=%0d", flash_bytes_seen);
        if (completed_flash_transactions != 2 || flash_transactions_seen != 3)
            $fatal(1, "common reset should perform exactly one more continuous transaction");
        if (ddr_write_count < (IMAGE_BYTES / 4))
            $fatal(1, "common reset did not rewrite the DDR image, writes=%0d", ddr_write_count);
        for (n = 0; n < IMAGE_BYTES; n = n + 1) begin
            if (ddr_mem[n] !== image_byte(n))
                $fatal(1, "DDR recovery byte %0d = %02x, expected %02x",
                       n, ddr_mem[n], image_byte(n));
        end
        $display("FLASH_DDR_RESET_RECOVERY_PASS bytes=%0d total_flash_reads=%0d",
                 IMAGE_BYTES, flash_bytes_seen);
        $display("FLASH_DDR_BOOT_PASS");
        $finish;
    end

    initial begin
        #100000000;
        $fatal(1, "end-to-end testbench timeout");
    end
endmodule
