`timescale 1ns / 1ps

// End-to-end Flash-to-BRAM boot test. The production SPI reader and loader
// drive a serial Flash model and a synchronous two-bank BRAM programming port.
module tb_flash_bram_boot;
    localparam [23:0] FLASH_BASE = 24'h5A_3210;
    localparam [31:0] IRAM_BASE = 32'h8000_0000;
    localparam [31:0] IRAM_BYTES = 32'd32768;
    localparam [31:0] DRAM_BASE = 32'h8000_8000;
    localparam [31:0] IMAGE_BYTES = IRAM_BYTES + 32'd8;
    localparam integer IMAGE_WORDS = IMAGE_BYTES / 4;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst_n = 1'b0;
    reg stall_program_port = 1'b1;
    reg corrupt_readback = 1'b0;

    wire flash_cs_n, flash_cs2_n, flash_mosi, flash_wp_n, flash_hold_n, flash_sck;
    reg flash_miso = 1'b0;
    wire prog_valid, prog_write, prog_ready;
    wire [31:0] prog_addr, prog_wdata, prog_rdata;
    wire [3:0] prog_wstrb;
    wire boot_done, boot_error, flash_clk_enable;
    wire [3:0] boot_error_code;

    flash_bram_boot #(
        .FLASH_BASE(FLASH_BASE), .IMAGE_BYTES(IMAGE_BYTES),
        .MEM_BASE(IRAM_BASE), .MEM_BYTES(IRAM_BYTES + 32'd16384),
        .SPI_CLK_DIV(1), .TIMEOUT_CYCLES(512)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .flash_cs_n(flash_cs_n), .flash_cs2_n(flash_cs2_n),
        .flash_mosi(flash_mosi), .flash_miso(flash_miso),
        .flash_wp_n(flash_wp_n), .flash_hold_n(flash_hold_n), .flash_sck(flash_sck),
        .prog_valid(prog_valid), .prog_write(prog_write),
        .prog_addr(prog_addr), .prog_wdata(prog_wdata), .prog_wstrb(prog_wstrb),
        .prog_ready(prog_ready), .prog_rdata(prog_rdata),
        .boot_done(boot_done), .boot_error(boot_error),
        .boot_error_code(boot_error_code), .flash_clk_enable(flash_clk_enable)
    );

    // A serial mode-0 03h Flash model with a deterministic stream at the
    // selected non-default byte address.
    function automatic [7:0] image_byte(input integer offset);
        reg [31:0] x;
        begin
            x = 32'h6d2b79f5 ^ (offset * 32'h01010101) ^ (offset << 11);
            x = x ^ (x >> 13);
            image_byte = x[7:0];
        end
    endfunction

    integer spi_tx_bits = 0;
    integer spi_rx_bits = 0;
    integer spi_stream_bytes = 0;
    integer completed_transactions = 0;
    integer aborted_transactions = 0;
    integer transactions_started = 0;
    reg [31:0] spi_command = 32'd0;
    reg [23:0] spi_addr = 24'd0;
    reg spi_active = 1'b0;
    reg [7:0] spi_rx_shift = 8'd0;
    wire [23:0] spi_addr_offset = spi_addr - FLASH_BASE;
    wire [7:0] flash_data = image_byte({8'd0, spi_addr_offset} + spi_stream_bytes);

    always @(negedge flash_cs_n) begin
        if (rst_n) begin
            if (flash_sck !== 1'b0) $fatal(1, "Flash CS asserted with SCK high");
            spi_command = 32'd0;
            spi_tx_bits = 0;
            spi_rx_bits = 0;
            spi_stream_bytes = 0;
            spi_rx_shift = 8'd0;
            spi_addr = 24'd0;
            spi_active = 1'b1;
            transactions_started = transactions_started + 1;
            flash_miso = 1'b0;
        end
    end

    always @(posedge flash_sck) begin
        if (flash_cs_n !== 1'b0) $fatal(1, "Flash clocked while CS high");
        if (spi_tx_bits < 32) begin
            spi_command = {spi_command[30:0], flash_mosi};
            spi_tx_bits = spi_tx_bits + 1;
            if (spi_tx_bits == 32) begin
                spi_addr = spi_command[23:0];
                if (spi_command[31:24] !== 8'h03)
                    $fatal(1, "expected 03h read opcode, got %02x", spi_command[31:24]);
                if (spi_addr !== FLASH_BASE)
                    $fatal(1, "Flash address %06x differs from configured %06x", spi_addr, FLASH_BASE);
            end
        end else begin
            spi_rx_shift = {spi_rx_shift[6:0], flash_miso};
            spi_rx_bits = spi_rx_bits + 1;
            if (spi_rx_bits == 8) begin
                if (spi_rx_shift !== flash_data)
                    $fatal(1, "Flash byte %0d = %02x expected %02x",
                           spi_stream_bytes, spi_rx_shift, flash_data);
                spi_rx_bits = 0;
                spi_rx_shift = 8'd0;
                spi_stream_bytes = spi_stream_bytes + 1;
            end
        end
    end

    always @(negedge flash_sck) begin
        if (flash_cs_n === 1'b0 && spi_active && spi_tx_bits == 32)
            flash_miso = flash_data[7-spi_rx_bits];
    end

    always @(posedge flash_cs_n) begin
        if (spi_active) begin
            if (flash_sck !== 1'b0) $fatal(1, "Flash CS released with SCK high");
            if (spi_tx_bits == 32 && spi_rx_bits == 0 && spi_stream_bytes == IMAGE_BYTES)
                completed_transactions = completed_transactions + 1;
            else
                aborted_transactions = aborted_transactions + 1;
            spi_active = 1'b0;
            flash_miso = 1'b0;
        end
    end

    // Use the production two-bank memory here so the real delayed read ack,
    // byte writes, and IRAM-to-DRAM address decode are exercised by the loader.
    wire [31:0] prog_mem_addr = prog_addr;
    wire [31:0] prog_mem_wdata = prog_wdata;
    wire [3:0] prog_mem_wstrb = prog_wstrb;
    wire prog_mem_valid = prog_valid && !stall_program_port;
    wire prog_mem_ready;
    wire [31:0] prog_mem_rdata;
    integer write_count = 0;
    integer dram_write_count = 0;
    reg [31:0] first_write_addr = 32'd0;
    reg [31:0] last_write_addr = 32'd0;

    cpu_bram_mem #(
        .IRAM_BASE(IRAM_BASE), .IRAM_BYTES(IRAM_BYTES),
        .DRAM_BASE(DRAM_BASE), .DRAM_BYTES(32'd16384)
    ) bram_mem (
        .clk(clk), .rst(cpu_reset),
        .if_req_valid(1'b0), .if_req_addr(32'b0), .if_req_ready(),
        .if_rsp_valid(), .if_rsp_data(),
        .data_req_valid(1'b0), .data_req_write(1'b0), .data_req_addr(32'b0),
        .data_req_wdata(32'b0), .data_req_wstrb(4'b0), .data_req_ready(),
        .data_rsp_valid(), .data_rsp_data(), .data_addr_local(),
        .prog_valid(prog_mem_valid), .prog_write(prog_write),
        .prog_addr(prog_mem_addr), .prog_wdata(prog_mem_wdata),
        .prog_wstrb(prog_mem_wstrb), .prog_ready(prog_mem_ready),
        .prog_rdata(prog_mem_rdata)
    );
    assign prog_ready = prog_mem_ready;
    assign prog_rdata = prog_mem_rdata ^
                        ((corrupt_readback && !prog_write) ? 32'h1 : 32'b0);

    always @(posedge clk) begin
        if (!rst_n) begin
            write_count <= 0;
            dram_write_count <= 0;
            first_write_addr <= 32'd0;
            last_write_addr <= 32'd0;
        end else begin
            if (prog_valid && prog_write && prog_mem_ready) begin
                if (prog_wstrb !== 4'hf)
                    $fatal(1, "loader did not write a full aligned word");
                if (write_count == 0) first_write_addr <= prog_addr;
                last_write_addr <= prog_addr;
                write_count <= write_count + 1;
                if (prog_addr >= DRAM_BASE) dram_write_count <= dram_write_count + 1;
            end
        end
    end

    wire cpu_reset = !rst_n || !boot_done || boot_error;
    always @(posedge clk) begin
        if (rst_n && (!boot_done || boot_error) && !cpu_reset)
            $fatal(1, "CPU reset released without a successful boot");
    end

    task automatic restart_loader;
        begin
            @(negedge clk); rst_n = 1'b0;
            repeat (4) @(negedge clk);
            rst_n = 1'b1;
            repeat (3) @(negedge clk);
        end
    endtask

    task automatic wait_for_error(input [3:0] expected_code);
        integer cycles;
        begin
            cycles = 0;
            while (!boot_error && cycles < 3000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!boot_error) $fatal(1, "loader did not time out/fail in %0d cycles", cycles);
            if (boot_error_code !== expected_code)
                $fatal(1, "boot error code %0d expected %0d", boot_error_code, expected_code);
            if (!cpu_reset) $fatal(1, "CPU was released after loader error");
        end
    endtask

    task automatic wait_for_done;
        integer cycles;
        begin
            cycles = 0;
            while (!boot_done && !boot_error && cycles < 1500000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!boot_done) $fatal(1, "successful retry failed, error=%0d", boot_error_code);
        end
    endtask

    integer i;
    reg [31:0] expected_word;
    initial begin
        repeat (5) @(negedge clk);
        rst_n = 1'b1;

        // First attempt: force the first BRAM write to time out. This also
        // checks reset remains asserted while Flash is being aborted.
        wait_for_error(4'd4);
        repeat (8) @(negedge clk);
        stall_program_port = 1'b0;
        restart_loader();

        // Second attempt: corrupt the first synchronous readback and require
        // verification failure to keep the CPU held in reset.
        corrupt_readback = 1'b1;
        wait_for_error(4'd6);
        restart_loader();

        // Third attempt succeeds from the same raw byte stream.
        corrupt_readback = 1'b0;
        wait_for_done();
        if (cpu_reset) $fatal(1, "CPU did not leave reset after verified boot");
        if (completed_transactions != 1)
            $fatal(1, "expected one exact completed Flash stream, observed %0d", completed_transactions);
        if (aborted_transactions < 2)
            $fatal(1, "timeout and verification failures did not abort their Flash reads");
        if (write_count != IMAGE_WORDS)
            $fatal(1, "successful attempt wrote %0d words, expected %0d",
                   write_count, IMAGE_WORDS);
        if (first_write_addr !== IRAM_BASE)
            $fatal(1, "first BRAM write was %08x, expected IRAM base %08x", first_write_addr, IRAM_BASE);
        if (dram_write_count != 2 || last_write_addr !== (DRAM_BASE + 32'd4))
            $fatal(1, "image did not continue into DRAM (count=%0d last=%08x)",
                   dram_write_count, last_write_addr);
        for (i = 0; i < IMAGE_WORDS; i = i + 1) begin
            expected_word = {image_byte(4*i+3), image_byte(4*i+2),
                             image_byte(4*i+1), image_byte(4*i)};
            if (i < (IRAM_BYTES / 4)) begin
                if (bram_mem.iram[i] !== expected_word)
                    $fatal(1, "IRAM word %0d = %08x expected %08x", i,
                           bram_mem.iram[i], expected_word);
            end else if (bram_mem.dram[i - (IRAM_BYTES / 4)] !== expected_word) begin
                $fatal(1, "DRAM word %0d = %08x expected %08x", i,
                       bram_mem.dram[i - (IRAM_BYTES / 4)], expected_word);
            end
        end
        $display("PASS: exact %0d-byte Flash image verified from %06x through IRAM into DRAM",
                 IMAGE_BYTES, FLASH_BASE);
        $finish;
    end

    initial begin
        #100000000;
        $fatal(1, "global test timeout");
    end
endmodule
