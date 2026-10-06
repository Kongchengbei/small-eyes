`timescale 1ns/1ps
`include "../soc/soc_addr_map.vh"
`include "../soc/soc_timeout.vh"

// Functional/configuration regression, not a PLL model or a timing guarantee.
module tb_soc_clock_config;
    parameter integer EXPECTED_HZ = 70000000;
    parameter integer EXPECTED_BOOT_TIMEOUT = 100000;
    parameter integer EXPECTED_SNAPSHOT_TIMEOUT = 1000000;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;
    wire [31:0] csr_rdata, csr_90mhz;
    reg ddr_initialized = 1, flash_accept = 1;
    wire boot_done, boot_error;
    wire [3:0] boot_error_code;
    integer completed_cycles;
    // Production loader with prompt Flash/DDR replies: a larger error deadline
    // must not insert any wait in the normal path.
    flash_ddr_loader #(
        .IMAGE_BYTES(4), .TIMEOUT_CYCLES(`SOC_BOOT_TIMEOUT_CYCLES),
        .DDR_INIT_TIMEOUT_CYCLES(`SOC_DDR_INIT_TIMEOUT_CYCLES)
    ) loader (
        .clk(clk), .rst_n(!rst), .ddr_init_done(ddr_initialized),
        .flash_req_valid(), .flash_req_ready(flash_accept),
        .flash_req_addr(), .flash_req_length(),
        .flash_rsp_valid(1'b1), .flash_rsp_ready(), .flash_rsp_data(8'b0),
        .ddr_req_valid(), .ddr_req_ready(1'b1), .ddr_req_write(),
        .ddr_req_addr(), .ddr_req_wdata(), .ddr_req_wstrb(),
        .ddr_rsp_valid(1'b1), .ddr_rsp_ready(),
        .ddr_rsp_is_read(loader.state == loader.ST_DDR_READ_RSP),
        .ddr_rsp_rdata(32'b0), .boot_done(boot_done), .boot_error(boot_error),
        .error_code(boot_error_code), .busy()
    );
    Hcsr dut (
        .clk(clk), .rst(rst), .csr_valid(1'b0), .csr_op(3'b0),
        .csr_addr(12'hF13), .csr_rs1_data(32'b0), .csr_imm(5'b0),
        .is_ecall(1'b0), .is_ebreak(1'b0), .is_mret(1'b0),
        .interrupt_boundary(1'b0), .irq_external(1'b0), .current_pc(32'b0),
        .csr_rdata(csr_rdata), .redirect_valid(), .redirect_pc()
    );
    Hcsr #(.CPU_HZ(90000000)) overridden (
        .clk(clk), .rst(rst), .csr_valid(1'b0), .csr_op(3'b0),
        .csr_addr(12'hF13), .csr_rs1_data(32'b0), .csr_imm(5'b0),
        .is_ecall(1'b0), .is_ebreak(1'b0), .is_mret(1'b0),
        .interrupt_boundary(1'b0), .irq_external(1'b0), .current_pc(32'b0),
        .csr_rdata(csr_90mhz), .redirect_valid(), .redirect_pc()
    );
    initial begin
        repeat (3) @(negedge clk);
        rst = 0; #1;
        if (`SOC_CPU_HZ != EXPECTED_HZ) $fatal(1, "frequency source mismatch");
        if ((csr_rdata & 32'h7fff) * 10000 != EXPECTED_HZ)
            $fatal(1, "CSR frequency does not follow SOC_CPU_HZ");
        if ((csr_rdata & 32'hffff8000) != 32'h10200000 || csr_90mhz != 32'h10202328)
            $fatal(1, "CSR ABI or frequency override broken");
        if (`SOC_BOOT_TIMEOUT_CYCLES != EXPECTED_BOOT_TIMEOUT ||
            `SOC_CAM_SNAPSHOT_TIMEOUT_CYCLES != EXPECTED_SNAPSHOT_TIMEOUT ||
            `SOC_DDR_INIT_TIMEOUT_CYCLES != EXPECTED_HZ)
            $fatal(1, "CPU-domain error deadline scaling mismatch");
        completed_cycles = 0;
        while (!boot_done && completed_cycles < 16) begin
            @(negedge clk);
            completed_cycles = completed_cycles + 1;
        end
        if (!boot_done || boot_error || completed_cycles != 10)
            $fatal(1, "normal boot latency changed: cycles=%0d", completed_cycles);

        rst = 1; ddr_initialized = 0;
        repeat (2) @(negedge clk);
        rst = 0;
        repeat (2) @(negedge clk);
        // Fast-forward only the test counter, then exercise the actual boundary.
        loader.timeout_count = `SOC_DDR_INIT_TIMEOUT_CYCLES - 2;
        @(negedge clk);
        if (boot_error) $fatal(1, "DDR init timeout fired before deadline");
        @(negedge clk);
        if (!boot_error || boot_error_code != 2)
            $fatal(1, "DDR init stall no longer reports timeout");

        rst = 1; ddr_initialized = 1; flash_accept = 0;
        repeat (2) @(negedge clk);
        rst = 0;
        repeat (2) @(negedge clk);
        loader.timeout_count = `SOC_BOOT_TIMEOUT_CYCLES - 2;
        @(negedge clk);
        if (boot_error) $fatal(1, "Flash timeout fired before deadline");
        @(negedge clk);
        if (!boot_error || boot_error_code != 3)
            $fatal(1, "Flash stall no longer reports timeout");
        $display("SOC_CLOCK_RTL_PASS hz=%0d", EXPECTED_HZ);
        $finish;
    end
endmodule
