`timescale 1ns / 1ps

// Board-level BRAM profile smoke: the selected Hfpga_soc top loads a tiny raw
// program from serial Flash, releases the real CPU, and observes its MMIO LED
// write. The board PLL and I/O primitives are replaced by sim/stubs models.
module tb_hfpga_soc_bram_boot;
    localparam [23:0] FLASH_BASE = 24'h5A_3210;
    localparam [31:0] IMAGE_BYTES = 32'd16;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg hard_rst_n = 1'b0;
    reg JTAG_TCK = 1'b0;
    reg JTAG_TMS = 1'b0;
    reg JTAG_TDI = 1'b0;
    tri [31:0] fpioa;
    tri cam1_scl, cam1_sda, cam2_scl, cam2_sda;
    wire cam1_reset_n, cam2_reset_n;
    wire flash_cs_n, flash_cs2_n, flash_mosi, flash_wp_n, flash_hold_n;
    reg flash_miso = 1'b0;
    reg clk_p = 1'b0, clk_n = 1'b1;
    wire mem_rst_n, mem_ck, mem_ck_n, mem_cke, mem_cs_n;
    wire mem_ras_n, mem_cas_n, mem_we_n, mem_odt;
    wire [14:0] mem_a;
    wire [2:0] mem_ba;
    tri [3:0] mem_dqs, mem_dqs_n;
    tri [31:0] mem_dq;
    wire [3:0] mem_dm;
    wire JTAG_TDO, core_active;

    Hfpga_soc #(
        .CPU_MEM_BRAM(1), .FLASH_BASE(FLASH_BASE), .BOOT_IMAGE_BYTES(IMAGE_BYTES)
    ) dut (
        .clk(clk), .hard_rst_n(hard_rst_n),
        .JTAG_TCK(JTAG_TCK), .JTAG_TMS(JTAG_TMS), .JTAG_TDI(JTAG_TDI),
        .JTAG_TDO(JTAG_TDO), .core_active(core_active), .fpioa(fpioa),
        .cam1_scl(cam1_scl), .cam1_sda(cam1_sda), .cam1_reset_n(cam1_reset_n),
        .cam1_pclk(1'b0), .cam1_vsync(1'b0), .cam1_href(1'b0), .cam1_data(8'b0),
        .cam2_scl(cam2_scl), .cam2_sda(cam2_sda), .cam2_reset_n(cam2_reset_n),
        .cam2_pclk(1'b0), .cam2_vsync(1'b0), .cam2_href(1'b0),
        .cam2_data_hi(3'b0), .cam2_data3(1'b0), .cam2_data0(1'b0),
        .flash_cs_n(flash_cs_n), .flash_cs2_n(flash_cs2_n),
        .flash_mosi(flash_mosi), .flash_miso(flash_miso),
        .flash_wp_n(flash_wp_n), .flash_hold_n(flash_hold_n),
        .clk_p(clk_p), .clk_n(clk_n), .mem_rst_n(mem_rst_n),
        .mem_ck(mem_ck), .mem_ck_n(mem_ck_n), .mem_cke(mem_cke),
        .mem_cs_n(mem_cs_n), .mem_ras_n(mem_ras_n), .mem_cas_n(mem_cas_n),
        .mem_we_n(mem_we_n), .mem_odt(mem_odt), .mem_a(mem_a), .mem_ba(mem_ba),
        .mem_dqs(mem_dqs), .mem_dqs_n(mem_dqs_n), .mem_dq(mem_dq), .mem_dm(mem_dm)
    );

    wire flash_sck = dut.g_bram_profile.u_bram_profile.flash_spi_sck;
    wire cpu_reset = dut.g_bram_profile.u_bram_profile.cpu_rst;
    wire [3:0] led_value = dut.g_bram_profile.u_bram_profile.led_value;
    wire boot_error = dut.g_bram_profile.u_bram_profile.boot_error;
    wire [3:0] boot_error_code = dut.g_bram_profile.u_bram_profile.boot_error_code;

    function automatic [7:0] program_byte(input integer offset);
        reg [31:0] instruction;
        begin
            case (offset >> 2)
                0: instruction = 32'h4000_00b7; // lui x1, 0x40000
                1: instruction = 32'h0050_0113; // addi x2, x0, 5
                2: instruction = 32'h2020_a023; // sw x2, 0x200(x1)
                default: instruction = 32'h0010_0073; // ebreak
            endcase
            case (offset[1:0])
                2'd0: program_byte = instruction[7:0];
                2'd1: program_byte = instruction[15:8];
                2'd2: program_byte = instruction[23:16];
                default: program_byte = instruction[31:24];
            endcase
        end
    endfunction

    integer tx_bits = 0;
    integer rx_bits = 0;
    integer stream_bytes = 0;
    integer completed_streams = 0;
    reg [31:0] tx_shift = 32'd0;
    reg [23:0] spi_addr = 24'd0;
    reg spi_active = 1'b0;
    reg [7:0] rx_shift = 8'd0;
    wire [23:0] flash_offset = spi_addr - FLASH_BASE;
    wire [7:0] flash_byte = program_byte({8'd0, flash_offset} + stream_bytes);

    always @(negedge flash_cs_n) begin
        if (hard_rst_n) begin
            tx_bits = 0;
            rx_bits = 0;
            stream_bytes = 0;
            tx_shift = 32'd0;
            spi_addr = 24'd0;
            rx_shift = 8'd0;
            spi_active = 1'b1;
            flash_miso = 1'b0;
        end
    end
    always @(posedge flash_sck) begin
        if (!flash_cs_n) begin
            if (tx_bits < 32) begin
                tx_shift = {tx_shift[30:0], flash_mosi};
                tx_bits = tx_bits + 1;
                if (tx_bits == 32) begin
                    spi_addr = tx_shift[23:0];
                    if (tx_shift[31:24] !== 8'h03 || spi_addr !== FLASH_BASE)
                        $fatal(1, "top Flash command/address mismatch: %08x", tx_shift);
                end
            end else begin
                rx_shift = {rx_shift[6:0], flash_miso};
                rx_bits = rx_bits + 1;
                if (rx_bits == 8) begin
                    if (rx_shift !== flash_byte)
                        $fatal(1, "top Flash byte %0d=%02x expected %02x",
                               stream_bytes, rx_shift, flash_byte);
                    stream_bytes = stream_bytes + 1;
                    rx_bits = 0;
                    rx_shift = 8'd0;
                end
            end
        end
    end
    always @(negedge flash_sck) begin
        if (!flash_cs_n && spi_active && tx_bits == 32)
            flash_miso = flash_byte[7-rx_bits];
    end
    always @(posedge flash_cs_n) begin
        if (spi_active) begin
            if (flash_sck !== 1'b0) $fatal(1, "top released Flash CS while SCK high");
            if (tx_bits == 32 && rx_bits == 0 && stream_bytes == IMAGE_BYTES)
                completed_streams = completed_streams + 1;
            spi_active = 1'b0;
            flash_miso = 1'b0;
        end
    end

    integer cycles;
    initial begin
        repeat (8) @(negedge clk);
        hard_rst_n = 1'b1;
        cycles = 0;
        // Hold the real RAM programming ready low for the first attempt. The
        // production loader must time out, abort Flash, and keep CPU reset set.
        force dut.g_bram_profile.u_bram_profile.prog_ready = 1'b0;
        cycles = 0;
        while (!boot_error && cycles < 250000) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
            if (!core_active && !cpu_reset)
                $fatal(1, "CPU reset released during failed top boot");
            if (led_value != 0) $fatal(1, "CPU ran before successful boot");
        end
        if (!boot_error || boot_error_code != 4'd4)
            $fatal(1, "top boot timeout error=%0d after %0d cycles", boot_error_code, cycles);
        if (!cpu_reset) $fatal(1, "CPU reset released after top boot error");
        release dut.g_bram_profile.u_bram_profile.prog_ready;

        // A full external reset restarts Flash boot and permits a clean retry.
        hard_rst_n = 1'b0;
        repeat (8) @(negedge clk);
        hard_rst_n = 1'b1;
        cycles = 0;
        while (!core_active && cycles < 10000) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
            if (!core_active && !cpu_reset)
                $fatal(1, "CPU reset released before top boot pass");
            if (led_value != 0) $fatal(1, "CPU ran before successful boot");
        end
        if (!core_active) $fatal(1, "BRAM top failed to load Flash image");
        cycles = 0;
        while (led_value != 4'h5 && cycles < 10000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        if (led_value !== 4'h5)
            $fatal(1, "CPU did not execute loaded MMIO program, LED=%h", led_value);
        if (completed_streams != 1 || stream_bytes != IMAGE_BYTES)
            $fatal(1, "top Flash stream count=%0d bytes=%0d", completed_streams, stream_bytes);
        if (cam1_reset_n || cam2_reset_n)
            $fatal(1, "unused camera reset pins should remain asserted");
        if (mem_rst_n || !mem_cs_n || mem_cke)
            $fatal(1, "unused DDR pins were not held inactive");
        $display("PASS: Hfpga_soc BRAM profile booted and executed raw Flash program");
        $finish;
    end

    initial begin
        #5000000;
        $fatal(1, "top profile smoke timeout");
    end
endmodule
