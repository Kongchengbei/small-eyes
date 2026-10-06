`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// Production BRAM profile startup smoke test. Code executes from the checked
// in vendor INIT parameters; no runtime RAM writes or external Flash are used.
module tb_coremark_bram_ip_uart;
    reg grs_n = 1'b0;
    GTP_GRS GRS_INST (.GRS_N(grs_n));
    initial #100 grs_n = 1'b1;

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
    wire mem_ras_n, mem_cas_n, mem_we_n;

    Hfpga_soc #(
        .CPU_MEM_BRAM(1), .UART_TX_DEFAULT_FPIOA(0)
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
        .flash_mosi(flash_mosi), .flash_miso(1'b0),
        .flash_wp_n(), .flash_hold_n(), .clk_p(1'b0), .clk_n(1'b1),
        .mem_rst_n(mem_rst_n), .mem_ck(), .mem_ck_n(), .mem_cke(mem_cke),
        .mem_cs_n(mem_cs_n), .mem_ras_n(mem_ras_n), .mem_cas_n(mem_cas_n),
        .mem_we_n(mem_we_n), .mem_odt(), .mem_a(), .mem_ba(),
        .mem_dqs(mem_dqs), .mem_dqs_n(mem_dqs_n), .mem_dq(mem_dq), .mem_dm()
    );

    wire cpu_clk = dut.g_bram_profile.u_bram_profile.cpu_clk;
    wire cpu_reset = dut.g_bram_profile.u_bram_profile.cpu_rst;
    wire [31:0] debug_pc = dut.g_bram_profile.u_bram_profile.debug_if_pc;
    wire prog_valid = dut.g_bram_profile.u_bram_profile.prog_valid;
    reg [31:0] previous_pc = 0;
    integer pc_changes = 0;
    integer cpu_cycles = 0;
    always @(posedge cpu_clk) begin
        if (!cpu_reset) begin
            cpu_cycles = cpu_cycles + 1;
            if (debug_pc != previous_pc) pc_changes = pc_changes + 1;
            previous_pc = debug_pc;
        end
        if (prog_valid !== 1'b0)
            $fatal(1, "runtime programming port active in vendor-init production profile");
    end

    string expected_line, received_line;
    reg [7:0] decoded;
    integer uart_chars = 0;
    initial begin
        expected_line = $sformatf("Start CoreMark CPU=%0d Hz UART=115200 TX_FPIOA=0", `SOC_CPU_HZ);
        received_line = "";
        $display("COREMARK_BRAM_IP_UART cpu_hz=%0d baud=115200 TX_FPIOA=0", `SOC_CPU_HZ);
        repeat (8) @(negedge clk);
        hard_rst_n = 1'b1;

        // Decode only the physical top-level FPIOA0 signal at the actual baud.
        forever begin
            @(negedge fpioa[0]);
            #(UART_BIT_NS / 2.0);
            if (fpioa[0] !== 1'b0) $fatal(1, "invalid UART start bit");
            for (integer bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                #(UART_BIT_NS);
                if (fpioa[0] !== 1'b0 && fpioa[0] !== 1'b1)
                    $fatal(1, "UART pin is X/Z during data bit");
                decoded[bit_index] = fpioa[0];
            end
            #(UART_BIT_NS);
            if (fpioa[0] !== 1'b1) $fatal(1, "invalid UART stop bit");
            uart_chars = uart_chars + 1;
            $write("%c", decoded);
            if (decoded == 8'h0a) begin
                if (received_line != expected_line)
                    $fatal(1, "startup UART mismatch: got '%s', expected '%s'", received_line, expected_line);
                if (!core_active || cpu_reset || pc_changes == 0 || cpu_cycles == 0)
                    $fatal(1, "CPU did not execute initialized code before UART output");
                if (uart_chars != expected_line.len() + 2)
                    $fatal(1, "unexpected UART character count: %0d", uart_chars);
                if (flash_cs_n !== 1'b1 || flash_cs2_n !== 1'b1 || flash_mosi !== 1'b0)
                    $fatal(1, "Flash interface was active in direct-init profile");
                if (cam1_reset_n || cam2_reset_n || mem_rst_n || !mem_cs_n || mem_cke ||
                    !mem_ras_n || !mem_cas_n || !mem_we_n)
                    $fatal(1, "disabled camera or DDR interface active");
                $display("PASS: vendor INIT boot produced %0d UART bytes at 115200 baud (CPU cycles=%0d)",
                         uart_chars, cpu_cycles);
                $finish;
            end else if (decoded != 8'h0d) begin
                received_line = {received_line, decoded};
                if (received_line.len() > expected_line.len())
                    $fatal(1, "unexpected startup UART output");
            end
        end
    end

    initial begin
        #200000000;
        $fatal(1, "UART startup timeout: active=%b reset=%b pc=%08x decoded=%0d",
               core_active, cpu_reset, previous_pc, uart_chars);
    end
endmodule
