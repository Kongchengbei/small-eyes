`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// Real BIN -> serial Flash model -> production BRAM loader/memory/CPU ->
// production UART/FPIOA -> independent 115200-baud pin receiver.
// No memory preload, forced boot_done, or intercepted printf/MMIO output.
// This is a startup-output test, not a complete CoreMark score validation.
module tb_coremark_bram_uart;
    localparam [23:0] FLASH_BASE = `SOC_FLASH_BASE;
    localparam integer IMAGE_BYTES = `SOC_BOOT_IMAGE_BYTES;
    localparam real UART_BIT_NS = 1.0e9 / 115200.0;
    reg clk = 1'b0;
    always #(500.0 / 27.0) clk = ~clk;
    reg hard_rst_n = 1'b0;
    tri [31:0] fpioa;
    tri cam1_scl, cam1_sda, cam2_scl, cam2_sda;
    tri [3:0] mem_dqs, mem_dqs_n;
    tri [31:0] mem_dq;
    wire core_active, flash_cs_n, flash_cs2_n, flash_mosi;
    wire cam1_reset_n, cam2_reset_n, mem_rst_n, mem_cs_n, mem_cke;
    reg flash_miso = 1'b0;

    Hfpga_soc #(
        .CPU_MEM_BRAM(1), .FLASH_BASE(FLASH_BASE),
        .BOOT_IMAGE_BYTES(IMAGE_BYTES), .UART_TX_DEFAULT_FPIOA(0)
    ) dut (
        .clk(clk), .hard_rst_n(hard_rst_n),
        .JTAG_TCK(1'b0), .JTAG_TMS(1'b0), .JTAG_TDI(1'b0), .JTAG_TDO(),
        .core_active(core_active), .fpioa(fpioa),
        .cam1_scl(cam1_scl), .cam1_sda(cam1_sda), .cam1_reset_n(cam1_reset_n),
        .cam1_pclk(1'b0), .cam1_vsync(1'b0), .cam1_href(1'b0), .cam1_data(8'b0),
        .cam2_scl(cam2_scl), .cam2_sda(cam2_sda), .cam2_reset_n(cam2_reset_n),
        .cam2_pclk(1'b0), .cam2_vsync(1'b0), .cam2_href(1'b0),
        .cam2_data_hi(3'b0), .cam2_data3(1'b0), .cam2_data0(1'b0),
        .flash_cs_n(flash_cs_n), .flash_cs2_n(flash_cs2_n),
        .flash_mosi(flash_mosi), .flash_miso(flash_miso),
        .flash_wp_n(), .flash_hold_n(), .clk_p(1'b0), .clk_n(1'b1),
        .mem_rst_n(mem_rst_n), .mem_ck(), .mem_ck_n(), .mem_cke(mem_cke),
        .mem_cs_n(mem_cs_n), .mem_ras_n(), .mem_cas_n(), .mem_we_n(),
        .mem_odt(), .mem_a(), .mem_ba(), .mem_dqs(mem_dqs),
        .mem_dqs_n(mem_dqs_n), .mem_dq(mem_dq), .mem_dm()
    );
    // The PLL is an ideal simulation substitute; use the configured CPU
    // frequency so the external receiver checks real baud timing in ns.
    wire cpu_clk = dut.g_bram_profile.u_bram_profile.cpu_clk;
    wire cpu_reset = dut.g_bram_profile.u_bram_profile.cpu_rst;
    wire boot_error = dut.g_bram_profile.u_bram_profile.boot_error;
    wire [3:0] boot_code = dut.g_bram_profile.u_bram_profile.boot_error_code;
    wire flash_sck = dut.g_bram_profile.u_bram_profile.flash_spi_sck;

    reg [7:0] image [0:IMAGE_BYTES-1];
    string bin_path, expected_line, received_line;
    integer fd, loaded_bytes;
    initial begin
        bin_path = "test/coremark_local.bin";
        if ($value$plusargs("BIN=%s", bin_path)) begin end
        fd = $fopen(bin_path, "rb");
        if (fd == 0) $fatal(1, "cannot open BIN: %s", bin_path);
        loaded_bytes = $fread(image, fd);
        if (loaded_bytes != IMAGE_BYTES || $fgetc(fd) != -1)
            $fatal(1, "BIN length must match loader length %0d; read %0d", IMAGE_BYTES, loaded_bytes);
        $fclose(fd);
        expected_line = $sformatf("Start CoreMark CPU=%0d Hz UART=115200 TX_FPIOA=0", `SOC_CPU_HZ);
        received_line = "";
        $display("COREMARK_BRAM_UART BIN=%s bytes=%0d flash=%06x cpu_hz=%0d TX_FPIOA=0",
                 bin_path, loaded_bytes, FLASH_BASE, `SOC_CPU_HZ);
        repeat (8) @(negedge clk);
        hard_rst_n = 1'b1;
    end

    integer tx_bits = 0, rx_bits = 0, stream_bytes = 0, transactions = 0;
    reg [31:0] command = 0;
    reg spi_active = 0;
    always @(negedge flash_cs_n) begin
        if (hard_rst_n) begin
            if (flash_sck !== 1'b0) $fatal(1, "Flash CS asserted with clock high");
            tx_bits = 0; rx_bits = 0; stream_bytes = 0; command = 0;
            spi_active = 1; flash_miso = 0;
        end
    end
    always @(posedge flash_sck) begin
        if (flash_cs_n !== 1'b0) $fatal(1, "Flash clock while deselected");
        if (tx_bits < 32) begin
            command = {command[30:0], flash_mosi};
            tx_bits = tx_bits + 1;
            if (tx_bits == 32 && command !== {8'h03, FLASH_BASE})
                $fatal(1, "unexpected Flash read command/address %08x", command);
        end else begin
            if (stream_bytes >= IMAGE_BYTES) $fatal(1, "read past BIN end");
            rx_bits = rx_bits + 1;
            if (rx_bits == 8) begin
                rx_bits = 0;
                stream_bytes = stream_bytes + 1;
            end
        end
    end
    always @(negedge flash_sck) begin
        if (!flash_cs_n && spi_active && tx_bits == 32) begin
            flash_miso = stream_bytes < IMAGE_BYTES ? image[stream_bytes][7-rx_bits] : 1'b0;
        end
    end
    always @(posedge flash_cs_n) begin
        if (spi_active) begin
            if (flash_sck !== 1'b0 || tx_bits != 32 || rx_bits != 0 || stream_bytes != IMAGE_BYTES)
                $fatal(1, "incomplete Flash transaction: bytes=%0d", stream_bytes);
            transactions = transactions + 1;
            spi_active = 0; flash_miso = 0;
        end
    end

    integer verify_words = 0, uart_requests = 0, cpu_cycles = 0;
    integer pc_changes = 0;
    reg [31:0] prev_pc = 0;
    always @(posedge cpu_clk) begin
        if (hard_rst_n && boot_error) $fatal(1, "BRAM boot error code=%0d", boot_code);
        if (hard_rst_n && !core_active && !cpu_reset)
            $fatal(1, "CPU released before boot verification");
        if (dut.g_bram_profile.u_bram_profile.prog_valid &&
            !dut.g_bram_profile.u_bram_profile.prog_write &&
            dut.g_bram_profile.u_bram_profile.prog_ready)
            verify_words = verify_words + 1;
        if (!cpu_reset) begin
            cpu_cycles = cpu_cycles + 1;
            if (dut.g_bram_profile.u_bram_profile.debug_if_pc != prev_pc)
                pc_changes = pc_changes + 1;
            prev_pc = dut.g_bram_profile.u_bram_profile.debug_if_pc;
            if (dut.g_bram_profile.u_bram_profile.u_uart0_tx.tx_start)
                uart_requests = uart_requests + 1;
        end
    end
    always @(posedge core_active)
        $display("BRAM_BOOT_OK flash_bytes=%0d verified_words=%0d", stream_bytes, verify_words);

    // Independent 8N1 receiver: observe only the actual top-level TX pin,
    // sample at bit centres using 115200 baud, and check framing/content.
    reg [7:0] decoded;
    integer uart_chars = 0;
    initial begin
        wait (hard_rst_n);
        forever begin
            @(negedge fpioa[0]);
            #(UART_BIT_NS / 2.0);
            if (fpioa[0] !== 1'b0) $fatal(1, "bad UART start bit");
            for (integer bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                #(UART_BIT_NS);
                if (fpioa[0] !== 1'b0 && fpioa[0] !== 1'b1)
                    $fatal(1, "UART pin X/Z during data bit");
                decoded[bit_index] = fpioa[0];
            end
            #(UART_BIT_NS);
            if (fpioa[0] !== 1'b1) $fatal(1, "bad UART stop bit");
            uart_chars = uart_chars + 1;
            $write("%c", decoded);
            if (decoded == 8'h0a) begin
                if (received_line != expected_line)
                    $fatal(1, "UART line mismatch: got '%s', expected '%s'", received_line, expected_line);
                if (!core_active || transactions != 1 || verify_words != IMAGE_BYTES / 4)
                    $fatal(1, "boot/Flash verification counters inconsistent");
                if (uart_chars != expected_line.len() + 2 || uart_requests != uart_chars || pc_changes == 0)
                    $fatal(1, "UART/CPU counters inconsistent");
                if (cam1_reset_n || cam2_reset_n || mem_rst_n || !mem_cs_n || mem_cke || !flash_cs2_n)
                    $fatal(1, "disabled peripherals or second Flash are active");
                $display("PASS: coremark_local.bin booted through Flash into BRAM; FPIOA0 decoded %0d UART bytes at 115200 baud (CPU cycles=%0d)", uart_chars, cpu_cycles);
                $finish;
            end else if (decoded != 8'h0d) begin
                received_line = {received_line, decoded};
                if (received_line.len() > expected_line.len()) $fatal(1, "unexpected UART output length");
            end
        end
    end
    initial begin
        // At 70 MHz this gives ample time for the unchanged SPI_DIV=4 boot
        // and startup banner. It does not wait for CoreMark's timed benchmark.
        #200000000;
        $fatal(1, "UART timeout: active=%b reset=%b error=%0d pc=%08x requests=%0d decoded=%0d",
               core_active, cpu_reset, boot_code, prev_pc, uart_requests, uart_chars);
    end
endmodule
