`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"
`ifndef PROG_FPGA_PATH
`include "../soc/config.v"
`endif

// CoreMark/small-app profile. The CPU's internal IRAM/DRAM replace the caches
// and DDR path; the system clock, boot Flash, UART, FPIOA, JTAG, and debug
// interfaces stay compatible with the board-level Hfpga_soc pinout.
module Hfpga_soc_bram_profile #(
    parameter MEM_FILE = `PROG_FPGA_PATH,
    parameter [23:0] FLASH_BASE = `SOC_FLASH_BASE,
    parameter [31:0] BOOT_IMAGE_BYTES = `SOC_BOOT_IMAGE_BYTES,
    parameter integer SPI_DIV = 4,
    parameter integer UART_TX_DEFAULT_FPIOA = `SOC_UART_TX_FPIOA,
    parameter [31:0] IRAM_BASE = `SOC_IRAM_BASE,
    parameter [31:0] IRAM_BYTES = `SOC_IRAM_BYTES,
    parameter [31:0] DRAM_BASE = `SOC_DRAM_BASE,
    parameter [31:0] DRAM_BYTES = `SOC_DRAM_BYTES,
    parameter [31:0] MMIO_BASE = `SOC_MMIO_BASE,
    parameter [31:0] MMIO_BYTES = `SOC_MMIO_BYTES,
    parameter [31:0] UART0_BASE = `SOC_UART0_BASE,
    parameter [31:0] UART0_BYTES = `SOC_UART0_BYTES,
    parameter [31:0] LED_ADDR = `SOC_LED_ADDR,
    parameter [31:0] FPIOA_BASE = `SOC_FPIOA_BASE,
    parameter [31:0] FPIOA_BYTES = `SOC_FPIOA_BYTES
) (
    input clk,
    input hard_rst_n,
    input JTAG_TCK,
    input JTAG_TMS,
    input JTAG_TDI,
    output JTAG_TDO,
    output core_active,
    inout [31:0] fpioa,
    inout cam1_scl,
    inout cam1_sda,
    output cam1_reset_n,
    input cam1_pclk,
    input cam1_vsync,
    input cam1_href,
    input [7:0] cam1_data,
    inout cam2_scl,
    inout cam2_sda,
    output cam2_reset_n,
    input cam2_pclk,
    input cam2_vsync,
    input cam2_href,
    input [2:0] cam2_data_hi,
    input cam2_data3,
    input cam2_data0,
    output flash_cs_n,
    output flash_cs2_n,
    output flash_mosi,
    input flash_miso,
    output flash_wp_n,
    output flash_hold_n,
    input clk_p,
    input clk_n,
    output mem_rst_n,
    output mem_ck,
    output mem_ck_n,
    output mem_cke,
    output mem_cs_n,
    output mem_ras_n,
    output mem_cas_n,
    output mem_we_n,
    output mem_odt,
    output [14:0] mem_a,
    output [2:0] mem_ba,
    inout [3:0] mem_dqs,
    inout [3:0] mem_dqs_n,
    inout [31:0] mem_dq,
    output [3:0] mem_dm
);
    wire cpu_clk;
    wire pll_locked;
    clk_pll u_pll (.clkin1(clk), .clkout0(cpu_clk), .lock(pll_locked));

    wire rst_async_n = hard_rst_n && pll_locked;
    reg rst_sync_q1, rst_sync_q2;
    always @(posedge cpu_clk or negedge rst_async_n) begin
        if (!rst_async_n) begin
            rst_sync_q1 <= 1'b0;
            rst_sync_q2 <= 1'b0;
        end else begin
            rst_sync_q1 <= 1'b1;
            rst_sync_q2 <= rst_sync_q1;
        end
    end
    wire sys_rst_n = rst_sync_q2;

    wire boot_done, boot_error;
    wire [3:0] boot_error_code;
    wire flash_clk_enable, flash_spi_sck;
    wire prog_valid, prog_write, prog_ready;
    wire [31:0] prog_addr, prog_wdata, prog_rdata;
    wire [3:0] prog_wstrb;

    flash_bram_boot #(
        .FLASH_BASE(FLASH_BASE), .IMAGE_BYTES(BOOT_IMAGE_BYTES),
        .MEM_BASE(IRAM_BASE),
        .MEM_BYTES(IRAM_BYTES + DRAM_BYTES), .SPI_CLK_DIV(SPI_DIV)
    ) u_flash_bram_boot (
        .clk(cpu_clk), .rst_n(sys_rst_n),
        .flash_cs_n(flash_cs_n), .flash_cs2_n(flash_cs2_n),
        .flash_mosi(flash_mosi), .flash_miso(flash_miso),
        .flash_wp_n(flash_wp_n), .flash_hold_n(flash_hold_n),
        .flash_sck(flash_spi_sck),
        .prog_valid(prog_valid), .prog_write(prog_write),
        .prog_addr(prog_addr), .prog_wdata(prog_wdata),
        .prog_wstrb(prog_wstrb), .prog_ready(prog_ready),
        .prog_rdata(prog_rdata), .boot_done(boot_done),
        .boot_error(boot_error), .boot_error_code(boot_error_code),
        .flash_clk_enable(flash_clk_enable)
    );

    GTP_CFGCLK u_flash_cfgclk (.CLKIN(flash_spi_sck), .CE_N(~flash_clk_enable));
    assign core_active = boot_done && !boot_error;
    assign cam1_reset_n = 1'b0;
    assign cam2_reset_n = 1'b0;
    assign cam1_scl = 1'bz;
    assign cam1_sda = 1'bz;
    assign cam2_scl = 1'bz;
    assign cam2_sda = 1'bz;

    // Keep unused DDR pins inactive for identical top-level constraints.
    assign mem_rst_n = 1'b0;
    assign mem_ck = 1'b0;
    assign mem_ck_n = 1'b1;
    assign mem_cke = 1'b0;
    assign mem_cs_n = 1'b1;
    assign mem_ras_n = 1'b1;
    assign mem_cas_n = 1'b1;
    assign mem_we_n = 1'b1;
    assign mem_odt = 1'b0;
    assign mem_a = 15'b0;
    assign mem_ba = 3'b0;
    assign mem_dqs = 4'bzzzz;
    assign mem_dqs_n = 4'bzzzz;
    assign mem_dq = 32'bz;
    assign mem_dm = 4'b0;

    wire [3:0] axi_awid, axi_wid, axi_arid, axi_rid;
    wire [31:0] axi_awaddr, axi_wdata, axi_araddr, axi_rdata;
    wire [7:0] axi_awlen, axi_arlen;
    wire [2:0] axi_awsize, axi_arsize;
    wire [1:0] axi_awburst, axi_arburst, axi_bresp, axi_rresp;
    wire axi_awvalid, axi_awready, axi_wlast, axi_wvalid, axi_wready;
    wire [3:0] axi_wstrb;
    wire [3:0] axi_bid;
    wire axi_bvalid, axi_bready, axi_arvalid, axi_arready;
    wire axi_rlast, axi_rvalid, axi_rready;
    wire [31:0] pc, ins;
    wire is_ebreak;
    wire [31:0] debug_if_pc, debug_id_pc, debug_ex_pc, debug_mem_pc, debug_wb_pc;
    wire [31:0] debug_if_ins, debug_id_ins, debug_ex_ins, debug_mem_ins, debug_wb_ins;
    wire [31:0] debug_dmem_addr, debug_dmem_wdata, debug_btb_predict_next_pc;
    wire [31:0] debug_actual_next_pc, debug_flush_pc, cpu_debug_ctrl;
    wire jtag_cmd_valid, jtag_cmd_ready, jtag_cmd_read;
    wire [31:0] jtag_cmd_addr, jtag_cmd_wdata, jtag_rsp_rdata;
    wire [3:0] jtag_cmd_wmask;
    wire jtag_rsp_valid, jtag_rsp_ready, jtag_rsp_err;
    wire jtag_halt_req, jtag_reset_req;

    reg [3:0] cpu_rst_cnt;
    always @(posedge cpu_clk) begin
        if (!sys_rst_n) cpu_rst_cnt <= 4'd0;
        else if (cpu_rst_cnt != 4'hf) cpu_rst_cnt <= cpu_rst_cnt + 1'b1;
    end
    wire cpu_rst = !sys_rst_n || (cpu_rst_cnt != 4'hf) ||
                   !boot_done || boot_error || jtag_reset_req || jtag_halt_req;

    Htop #(
        .RESET_PC(IRAM_BASE), .DDR_BASE(IRAM_BASE),
        .DDR_BYTES(IRAM_BYTES + DRAM_BYTES), .BRAM_MODE(1'b1),
        .IRAM_BASE(IRAM_BASE), .IRAM_BYTES(IRAM_BYTES),
        .DRAM_BASE(DRAM_BASE), .DRAM_BYTES(DRAM_BYTES)
    ) u_cpu (
        .clk(cpu_clk), .rst(cpu_rst), .irq_external(1'b0),
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
        .axi_rvalid(axi_rvalid), .axi_rready(axi_rready),
        .pc(pc), .ins(ins), .is_ebreak(is_ebreak), .icache_miss(), .dcache_miss(),
        .debug_if_pc(debug_if_pc), .debug_id_pc(debug_id_pc), .debug_ex_pc(debug_ex_pc),
        .debug_mem_pc(debug_mem_pc), .debug_wb_pc(debug_wb_pc),
        .debug_if_ins(debug_if_ins), .debug_id_ins(debug_id_ins),
        .debug_ex_ins(debug_ex_ins), .debug_mem_ins(debug_mem_ins),
        .debug_wb_ins(debug_wb_ins), .debug_dmem_addr(debug_dmem_addr),
        .debug_dmem_wdata(debug_dmem_wdata),
        .debug_btb_predict_next_pc(debug_btb_predict_next_pc),
        .debug_actual_next_pc(debug_actual_next_pc), .debug_flush_pc(debug_flush_pc),
        .debug_ctrl(cpu_debug_ctrl),
        .bram_prog_valid(prog_valid), .bram_prog_write(prog_write),
        .bram_prog_addr(prog_addr), .bram_prog_wdata(prog_wdata),
        .bram_prog_wstrb(prog_wstrb), .bram_prog_ready(prog_ready),
        .bram_prog_rdata(prog_rdata)
    );

    wire mmio_req_valid, mmio_req_wen, mmio_req_ready;
    wire [31:0] mmio_req_addr, mmio_req_wdata, mmio_req_rdata;
    wire [3:0] mmio_req_wstrb;
    wire [31:0] ddr_req_addr, ddr_req_wdata, ddr_rsp_rdata;
    wire [3:0] ddr_req_wstrb;
    wire ddr_req_valid, ddr_req_ready, ddr_req_write;
    wire ddr_rsp_valid, ddr_rsp_ready, ddr_rsp_is_read;

    axi_mem_backend #(
        .MMIO_BASE(MMIO_BASE), .MMIO_BYTES(MMIO_BYTES),
        .DDR_BASE(IRAM_BASE), .DDR_BYTES(IRAM_BYTES + DRAM_BYTES)
    ) u_mem (
        .clk(cpu_clk), .rst_n(sys_rst_n),
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
        .mmio_req_wstrb(mmio_req_wstrb), .mmio_req_ready(mmio_req_ready),
        .mmio_req_rdata(mmio_req_rdata),
        .ddr_req_valid(ddr_req_valid), .ddr_req_ready(ddr_req_ready),
        .ddr_req_write(ddr_req_write), .ddr_req_addr(ddr_req_addr),
        .ddr_req_wdata(ddr_req_wdata), .ddr_req_wstrb(ddr_req_wstrb),
        .ddr_rsp_valid(ddr_rsp_valid), .ddr_rsp_ready(ddr_rsp_ready),
        .ddr_rsp_is_read(ddr_rsp_is_read), .ddr_rsp_rdata(ddr_rsp_rdata),
        .jtag_cmd_valid(jtag_cmd_valid), .jtag_cmd_ready(jtag_cmd_ready),
        .jtag_cmd_addr(jtag_cmd_addr), .jtag_cmd_read(jtag_cmd_read),
        .jtag_cmd_wdata(jtag_cmd_wdata), .jtag_cmd_wmask(jtag_cmd_wmask),
        .jtag_rsp_valid(jtag_rsp_valid), .jtag_rsp_ready(jtag_rsp_ready),
        .jtag_rsp_err(jtag_rsp_err), .jtag_rsp_rdata(jtag_rsp_rdata)
    );
    assign ddr_req_ready = 1'b0;
    assign ddr_rsp_valid = 1'b0;
    assign ddr_rsp_is_read = 1'b0;
    assign ddr_rsp_rdata = 32'b0;

    wire JTAG_TCK_in;
    GTP_INBUF #(.IOSTANDARD("DEFAULT"), .TERM_DDR("ON")) u_jtag_tck_buf
        (.O(JTAG_TCK_in), .I(JTAG_TCK));
    jtag_top u_jtag (
        .clk(cpu_clk), .jtag_rst_n(sys_rst_n), .jtag_pin_TCK(JTAG_TCK_in),
        .jtag_pin_TMS(JTAG_TMS), .jtag_pin_TDI(JTAG_TDI), .jtag_pin_TDO(JTAG_TDO),
        .reg_we_o(), .reg_addr_o(), .reg_wdata_o(), .reg_rdata_i(32'b0),
        .jtag_icb_cmd_valid(jtag_cmd_valid), .jtag_icb_cmd_ready(jtag_cmd_ready),
        .jtag_icb_cmd_addr(jtag_cmd_addr), .jtag_icb_cmd_read(jtag_cmd_read),
        .jtag_icb_cmd_wdata(jtag_cmd_wdata), .jtag_icb_cmd_wmask(jtag_cmd_wmask),
        .jtag_icb_rsp_valid(jtag_rsp_valid), .jtag_icb_rsp_ready(jtag_rsp_ready),
        .jtag_icb_rsp_err(jtag_rsp_err), .jtag_icb_rsp_rdata(jtag_rsp_rdata),
        .halt_req_o(jtag_halt_req), .reset_req_o(jtag_reset_req)
    );

    localparam [31:0] UART0_END = UART0_BASE + UART0_BYTES;
    localparam [31:0] FPIOA_END = FPIOA_BASE + FPIOA_BYTES;
    wire uart_addr_sel = (mmio_req_addr >= UART0_BASE) && (mmio_req_addr < UART0_END);
    wire uart_sel = mmio_req_valid && uart_addr_sel;
    wire led_sel = mmio_req_valid && (mmio_req_addr == LED_ADDR);
    wire fpioa_sel = mmio_req_valid && (mmio_req_addr >= FPIOA_BASE) &&
                     (mmio_req_addr < FPIOA_END);
    wire uart_ready, uart_tx;
    wire [31:0] uart_rdata, fpioa_rdata;
    wire [3:0] led_value;
    assign mmio_req_ready = uart_addr_sel ? uart_ready : 1'b1;
    assign mmio_req_rdata = uart_sel ? uart_rdata : led_sel ? {28'b0, led_value} :
                            fpioa_sel ? fpioa_rdata : 32'b0;

    Huart_tx #(.CLK_HZ(`SOC_CPU_HZ), .BAUD(`SOC_UART_BAUD)) u_uart0_tx (
        .clk(cpu_clk), .rst_n(sys_rst_n), .mmio_valid(uart_sel),
        .mmio_wen(mmio_req_wen), .mmio_addr(mmio_req_addr[7:0]),
        .mmio_wdata(mmio_req_wdata), .mmio_wmask(mmio_req_wstrb),
        .mmio_rdata(uart_rdata), .mmio_ready(uart_ready), .tx_pin(uart_tx)
    );
    Hled #(.WIDTH(4)) u_led (
        .clk(cpu_clk), .rst_n(sys_rst_n), .wr_en(led_sel && mmio_req_wen),
        .wr_data(mmio_req_wdata), .wr_mask(mmio_req_wstrb), .led(led_value)
    );
    Hfpioa_simple #(.UART_TX_DEFAULT_FPIOA(UART_TX_DEFAULT_FPIOA),
                    .INPUT_ONLY_MASK(32'h3004_0000)) u_fpioa (
        .clk(cpu_clk), .rst_n(sys_rst_n), .mmio_valid(fpioa_sel),
        .mmio_wen(mmio_req_wen), .mmio_addr(mmio_req_addr[7:0]),
        .mmio_wdata(mmio_req_wdata), .mmio_wmask(mmio_req_wstrb),
        .mmio_rdata(fpioa_rdata), .uart0_tx(uart_tx), .direct_led(led_value),
        .fpioa(fpioa)
    );

    (* PAP_MARK_DEBUG="<0/t0/0>" *) wire [31:0] dbg_if_pc;
    (* PAP_MARK_DEBUG="<0/t1/0>" *) wire [31:0] dbg_id_pc;
    (* PAP_MARK_DEBUG="<0/t2/0>" *) wire [31:0] dbg_id_ins;
    (* PAP_MARK_DEBUG="<0/t3/0>" *) wire [31:0] dbg_btb_predict_next_pc;
    (* PAP_MARK_DEBUG="<0/t4/0>" *) wire [31:0] dbg_actual_next_pc;
    (* PAP_MARK_DEBUG="<0/t5/0>" *) wire [31:0] dbg_flush_pc;
    (* PAP_MARK_DEBUG="<0/t6/0>" *) wire [30:0] dbg_ctrl;
    Debug_core u_debug_core (
        .cpu_if_pc(debug_if_pc), .cpu_id_pc(debug_id_pc), .cpu_ex_pc(debug_ex_pc),
        .cpu_mem_pc(debug_mem_pc), .cpu_wb_pc(debug_wb_pc),
        .cpu_if_ins(debug_if_ins), .cpu_id_ins(debug_id_ins), .cpu_ex_ins(debug_ex_ins),
        .cpu_mem_ins(debug_mem_ins), .cpu_wb_ins(debug_wb_ins),
        .cpu_dmem_addr(debug_dmem_addr), .cpu_dmem_wdata(debug_dmem_wdata),
        .cpu_btb_predict_next_pc(debug_btb_predict_next_pc),
        .cpu_actual_next_pc(debug_actual_next_pc), .cpu_flush_pc(debug_flush_pc),
        .cpu_ctrl(cpu_debug_ctrl), .if_pc(dbg_if_pc), .id_pc(dbg_id_pc),
        .ex_pc(), .mem_pc(), .wb_pc(), .if_ins(), .id_ins(dbg_id_ins),
        .ex_ins(), .mem_ins(), .wb_ins(), .dmem_addr(), .dmem_wdata(),
        .btb_predict_next_pc(dbg_btb_predict_next_pc),
        .actual_next_pc(dbg_actual_next_pc), .flush_pc(dbg_flush_pc), .ctrl(dbg_ctrl)
    );
endmodule
