`timescale 1ns / 1ps

// ===========================================================================
// Hfpga_soc
//
// CPU + cache subsystem now talk to the outside world through one 32-bit AXI4
// master (Htop / axi_bridge).  axi_mem_backend implements the memory map:
//   MMIO (0x4000_0000): peripherals (UART/LED/FPIOA), uncached
//   DDR  (0x8000_0000): forwarded through ddr_axi_bridge to the DDR3 IP
//
// The DDR3 controller is connected through ddr_axi_bridge.  core_active still
// reports the controller's initialization-complete status.
// ===========================================================================
module Hfpga_soc #(
    parameter MEM_FILE   = `PROG_FPGA_PATH
) (
    input  clk,
    input  hard_rst_n,
    //JTAG标准接口
    input  JTAG_TCK,
    input  JTAG_TMS,
    input  JTAG_TDI,
    output JTAG_TDO,
    output core_active,
    inout  [31:0] fpioa,

    //DDR3
    input         clk_p,
    input         clk_n,
    output        mem_rst_n,
    output        mem_ck,
    output        mem_ck_n,
    output        mem_cke,
    output        mem_cs_n,
    output        mem_ras_n,
    output        mem_cas_n,
    output        mem_we_n,
    output        mem_odt,
    output [14:0] mem_a,
    output [2:0]  mem_ba,
    inout  [3:0]  mem_dqs,
    inout  [3:0]  mem_dqs_n,
    inout  [31:0] mem_dq,
    output [3:0]  mem_dm
);

    // ---------------- AXI master from the CPU / caches ----------------
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

    wire [31:0] pc;
    wire [31:0] ins;
    wire        is_ebreak;

    // ---------------- debug / status exports (unchanged) ---------------
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
    wire [31:0] cpu_debug_ctrl;

    // ============ clock / reset (unchanged) =============================
    wire cpu_clk;
    wire pll_locked;

    wire ddr_ref_clk;
    wire ddr_core_clk;
    wire ddr_init_done;

    // Backend-side 32-bit DDR request channel.  ddr_axi_bridge converts one
    // request at a time to the DDR controller's 256-bit AXI clock domain.
    wire        ddr_req_valid;
    wire        ddr_req_ready;
    wire        ddr_req_write;
    wire [31:0] ddr_req_addr;
    wire [31:0] ddr_req_wdata;
    wire [3:0]  ddr_req_wstrb;
    wire        ddr_rsp_valid;
    wire        ddr_rsp_ready;
    wire        ddr_rsp_is_read;
    wire [31:0] ddr_rsp_rdata;

    wire [29:0]  ddr_axi_awaddr;
    wire [7:0]   ddr_axi_awid;
    wire [7:0]   ddr_axi_awlen;
    wire [2:0]   ddr_axi_awsize;
    wire [1:0]   ddr_axi_awburst;
    wire         ddr_axi_awvalid;
    wire         ddr_axi_awready;
    wire [255:0] ddr_axi_wdata;
    wire [31:0]  ddr_axi_wstrb;
    wire         ddr_axi_wlast;
    wire         ddr_axi_wvalid;
    wire         ddr_axi_wready;
    wire [7:0]   ddr_axi_bid;
    wire [1:0]   ddr_axi_bresp;
    wire         ddr_axi_bvalid;
    wire         ddr_axi_bready;
    wire [29:0]  ddr_axi_araddr;
    wire [7:0]   ddr_axi_arid;
    wire [7:0]   ddr_axi_arlen;
    wire [2:0]   ddr_axi_arsize;
    wire [1:0]   ddr_axi_arburst;
    wire         ddr_axi_arvalid;
    wire         ddr_axi_arready;
    wire [255:0] ddr_axi_rdata;
    wire [7:0]   ddr_axi_rid;
    wire [1:0]   ddr_axi_rresp;
    wire         ddr_axi_rlast;
    wire         ddr_axi_rvalid;
    wire         ddr_axi_rready;

    GTP_INBUFGDS #(
        .IOSTANDARD("DEFAULT"),
        .TERM_DIFF("ON")
    ) u_ddr_refclk_buf (
        .O  (ddr_ref_clk),
        .I  (clk_p),
        .IB (clk_n)
    );

    clk_pll u_pll (
        .clkin1  (clk),
        .clkout0 (cpu_clk),
        .lock    (pll_locked)
    );

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

    reg [3:0] cpu_rst_cnt;
    always @(posedge cpu_clk) begin
        if (!sys_rst_n)               cpu_rst_cnt <= 4'd0;
        else if (cpu_rst_cnt != 4'hF) cpu_rst_cnt <= cpu_rst_cnt + 4'd1;
    end

    wire jtag_cmd_valid;
    wire jtag_cmd_ready;
    wire [31:0] jtag_cmd_addr;
    wire        jtag_cmd_read;
    wire [31:0] jtag_cmd_wdata;
    wire [3:0]  jtag_cmd_wmask;
    wire        jtag_rsp_valid;
    wire        jtag_rsp_ready;
    wire        jtag_rsp_err;
    wire [31:0] jtag_rsp_rdata;
    wire        jtag_halt_req;
    wire        jtag_reset_req;

    wire cpu_rst = !sys_rst_n || (cpu_rst_cnt != 4'hF) ||
                   jtag_reset_req || jtag_halt_req;

    // ============ CPU + caches + axi_bridge =============================
    Htop #(
        .RESET_PC  (32'h8000_0000),
        .DDR_BASE  (32'h8000_0000),
        .DDR_BYTES (32'h4000_0000)
    ) u_cpu (
        .clk        (cpu_clk),
        .rst        (cpu_rst),

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

        .debug_if_pc               (debug_if_pc),
        .debug_id_pc               (debug_id_pc),
        .debug_ex_pc               (debug_ex_pc),
        .debug_mem_pc              (debug_mem_pc),
        .debug_wb_pc               (debug_wb_pc),
        .debug_if_ins              (debug_if_ins),
        .debug_id_ins              (debug_id_ins),
        .debug_ex_ins              (debug_ex_ins),
        .debug_mem_ins             (debug_mem_ins),
        .debug_wb_ins              (debug_wb_ins),
        .debug_dmem_addr           (debug_dmem_addr),
        .debug_dmem_wdata          (debug_dmem_wdata),
        .debug_btb_predict_next_pc (debug_btb_predict_next_pc),
        .debug_actual_next_pc      (debug_actual_next_pc),
        .debug_flush_pc            (debug_flush_pc),
        .debug_ctrl                (cpu_debug_ctrl)
    );

    // ============ unified AXI memory backend =============================
    wire mmio_req_valid;
    wire mmio_req_wen;
    wire [31:0] mmio_req_addr;
    wire [31:0] mmio_req_wdata;
    wire [3:0]  mmio_req_wstrb;
    wire        mmio_req_ready;
    wire [31:0] mmio_req_rdata;

    axi_mem_backend #(
        .MMIO_BASE  (32'h4000_0000),
        .MMIO_BYTES (32'h0000_1000),
        .DDR_BASE   (32'h8000_0000),
        .DDR_BYTES  (32'h4000_0000)
    ) u_mem (
        .clk            (cpu_clk),
        .rst_n          (sys_rst_n),

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
        .mmio_req_ready (mmio_req_ready),
        .mmio_req_rdata (mmio_req_rdata),

        .ddr_req_valid (ddr_req_valid),
        .ddr_req_ready (ddr_req_ready),
        .ddr_req_write (ddr_req_write),
        .ddr_req_addr  (ddr_req_addr),
        .ddr_req_wdata (ddr_req_wdata),
        .ddr_req_wstrb (ddr_req_wstrb),
        .ddr_rsp_valid (ddr_rsp_valid),
        .ddr_rsp_ready (ddr_rsp_ready),
        .ddr_rsp_is_read(ddr_rsp_is_read),
        .ddr_rsp_rdata (ddr_rsp_rdata),

        .jtag_cmd_valid (jtag_cmd_valid),
        .jtag_cmd_ready (jtag_cmd_ready),
        .jtag_cmd_addr  (jtag_cmd_addr),
        .jtag_cmd_read  (jtag_cmd_read),
        .jtag_cmd_wdata (jtag_cmd_wdata),
        .jtag_cmd_wmask (jtag_cmd_wmask),
        .jtag_rsp_valid (jtag_rsp_valid),
        .jtag_rsp_ready (jtag_rsp_ready),
        .jtag_rsp_err   (jtag_rsp_err),
        .jtag_rsp_rdata (jtag_rsp_rdata)
    );

    // ============ JTAG =====================================================
    wire JTAG_TCK_in;
    GTP_INBUF #(
        .IOSTANDARD("DEFAULT"),
        .TERM_DDR("ON")
    ) GTP_INBUF_inst (
        .O (JTAG_TCK_in),
        .I (JTAG_TCK)
    );

    jtag_top u_jtag (
        .clk                 (cpu_clk),
        .jtag_rst_n          (sys_rst_n),
        .jtag_pin_TCK        (JTAG_TCK_in),
        .jtag_pin_TMS        (JTAG_TMS),
        .jtag_pin_TDI        (JTAG_TDI),
        .jtag_pin_TDO        (JTAG_TDO),
        .reg_we_o            (),
        .reg_addr_o          (),
        .reg_wdata_o         (),
        .reg_rdata_i         (32'b0),
        .jtag_icb_cmd_valid  (jtag_cmd_valid),
        .jtag_icb_cmd_ready  (jtag_cmd_ready),
        .jtag_icb_cmd_addr   (jtag_cmd_addr),
        .jtag_icb_cmd_read   (jtag_cmd_read),
        .jtag_icb_cmd_wdata  (jtag_cmd_wdata),
        .jtag_icb_cmd_wmask  (jtag_cmd_wmask),
        .jtag_icb_rsp_valid  (jtag_rsp_valid),
        .jtag_icb_rsp_ready  (jtag_rsp_ready),
        .jtag_icb_rsp_err    (jtag_rsp_err),
        .jtag_icb_rsp_rdata  (jtag_rsp_rdata),
        .halt_req_o          (jtag_halt_req),
        .reset_req_o         (jtag_reset_req)
    );

    // ============ MMIO peripherals ========================================
    localparam [31:0] UART0_BASE = 32'h4000_0000;
    localparam [31:0] UART0_END  = 32'h4000_0100;
    localparam [31:0] LED_ADDR   = 32'h4000_0200;

    wire uart_addr_sel = (mmio_req_addr >= UART0_BASE) &&
                         (mmio_req_addr <  UART0_END);
    wire uart_sel = mmio_req_valid && uart_addr_sel;
    wire led_sel  = mmio_req_valid && (mmio_req_addr == LED_ADDR);
    wire fpioa_sel = mmio_req_valid &&
                     (mmio_req_addr >= 32'h4000_0f00) &&
                     (mmio_req_addr <  32'h4000_1000);

    // UART TX data writes are the only peripheral access that can be busy.
    assign mmio_req_ready = uart_addr_sel ? uart_ready : 1'b1;

    wire [31:0] uart_rdata;
    wire uart_ready;
    wire uart_tx;
    wire [3:0] led_value;
    wire [31:0] fpioa_rdata;

    Huart_tx #(
        .CLK_HZ(90_000_000)
    ) u_uart0_tx (
        .clk        (cpu_clk),
        .rst_n      (sys_rst_n),
        .mmio_valid (uart_sel),
        .mmio_wen   (mmio_req_wen),
        .mmio_addr  (mmio_req_addr[7:0]),
        .mmio_wdata (mmio_req_wdata),
        .mmio_wmask (mmio_req_wstrb),
        .mmio_rdata (uart_rdata),
        .mmio_ready (uart_ready),
        .tx_pin     (uart_tx)
    );

    Hled #(.WIDTH(4)) u_led (
        .clk     (cpu_clk),
        .rst_n   (sys_rst_n),
        .wr_en   (led_sel && mmio_req_wen),
        .wr_data (mmio_req_wdata),
        .wr_mask (mmio_req_wstrb),
        .led     (led_value)
    );

    Hfpioa_simple u_fpioa (
        .clk        (cpu_clk),
        .rst_n      (sys_rst_n),
        .mmio_valid (fpioa_sel),
        .mmio_wen   (mmio_req_wen),
        .mmio_addr  (mmio_req_addr[7:0]),
        .mmio_wdata (mmio_req_wdata),
        .mmio_wmask (mmio_req_wstrb),
        .mmio_rdata (fpioa_rdata),
        .uart0_tx   (uart_tx),
        .direct_led (led_value),
        .fpioa      (fpioa)
    );

    assign mmio_req_rdata =
        uart_sel   ? uart_rdata        :
        led_sel    ? {28'b0, led_value}:
        fpioa_sel  ? fpioa_rdata       : 32'b0;

    // ============ Debug export ============================================
    // Keep the same externally-visible debug bundles (ILA/FIC) as before.
    (* PAP_MARK_DEBUG="<0/t0/0>"  *) wire [31:0] dbg_if_pc;
    (* PAP_MARK_DEBUG="<0/t1/0>"  *) wire [31:0] dbg_id_pc;
    (* PAP_MARK_DEBUG="<0/t2/0>"  *) wire [31:0] dbg_id_ins;
    (* PAP_MARK_DEBUG="<0/t3/0>"  *) wire [31:0] dbg_btb_predict_next_pc;
    (* PAP_MARK_DEBUG="<0/t4/0>"  *) wire [31:0] dbg_actual_next_pc;
    (* PAP_MARK_DEBUG="<0/t5/0>"  *) wire [31:0] dbg_flush_pc;
    (* PAP_MARK_DEBUG="<0/t6/0>"  *) wire [30:0] dbg_ctrl;

    Debug_core u_debug_core (
        .cpu_if_pc               (debug_if_pc),
        .cpu_id_pc               (debug_id_pc),
        .cpu_ex_pc               (debug_ex_pc),
        .cpu_mem_pc              (debug_mem_pc),
        .cpu_wb_pc               (debug_wb_pc),
        .cpu_if_ins              (debug_if_ins),
        .cpu_id_ins              (debug_id_ins),
        .cpu_ex_ins              (debug_ex_ins),
        .cpu_mem_ins             (debug_mem_ins),
        .cpu_wb_ins              (debug_wb_ins),
        .cpu_dmem_addr           (debug_dmem_addr),
        .cpu_dmem_wdata          (debug_dmem_wdata),
        .cpu_btb_predict_next_pc (debug_btb_predict_next_pc),
        .cpu_actual_next_pc      (debug_actual_next_pc),
        .cpu_flush_pc            (debug_flush_pc),
        .cpu_ctrl                (cpu_debug_ctrl),
        .if_pc                   (dbg_if_pc),
        .id_pc                   (dbg_id_pc),
        .ex_pc                   (dbg_ex_pc),
        .mem_pc                  (dbg_mem_pc),
        .wb_pc                   (dbg_wb_pc),
        .if_ins                  (dbg_if_ins),
        .id_ins                  (dbg_id_ins),
        .ex_ins                  (dbg_ex_ins),
        .mem_ins                 (dbg_mem_ins),
        .wb_ins                  (dbg_wb_ins),
        .dmem_addr               (dbg_dmem_addr),
        .dmem_wdata              (dbg_dmem_wdata),
        .btb_predict_next_pc     (dbg_btb_predict_next_pc),
        .actual_next_pc          (dbg_actual_next_pc),
        .flush_pc                (dbg_flush_pc),
        .ctrl                    (dbg_ctrl)
    );

    // ============ DDR3 request bridge =====================================
    // The backend is clocked by cpu_clk and emits one 32-bit request at a
    // time. This bridge waits for DDR initialization, crosses to ddr_core_clk,
    // expands writes to one 256-bit beat, and selects one word from each
    // 256-bit read response.
    ddr_axi_bridge u_ddr_axi_bridge (
        .cpu_clk          (cpu_clk),
        .ddr_clk          (ddr_core_clk),
        .rst_n            (hard_rst_n),
        .ddr_init_done    (ddr_init_done),
        .cpu_req_valid    (ddr_req_valid),
        .cpu_req_ready    (ddr_req_ready),
        .cpu_req_write    (ddr_req_write),
        .cpu_req_addr     (ddr_req_addr),
        .cpu_req_wdata    (ddr_req_wdata),
        .cpu_req_wmask    (ddr_req_wstrb),
        .cpu_rsp_rdata    (ddr_rsp_rdata),
        .cpu_rsp_valid    (ddr_rsp_valid),
        .cpu_rsp_is_read  (ddr_rsp_is_read),
        .cpu_rsp_ready    (ddr_rsp_ready),

        .axi_awaddr       (ddr_axi_awaddr),
        .axi_awid         (ddr_axi_awid),
        .axi_awlen        (ddr_axi_awlen),
        .axi_awsize       (ddr_axi_awsize),
        .axi_awburst      (ddr_axi_awburst),
        .axi_awvalid      (ddr_axi_awvalid),
        .axi_awready      (ddr_axi_awready),
        .axi_wdata        (ddr_axi_wdata),
        .axi_wstrb        (ddr_axi_wstrb),
        .axi_wlast        (ddr_axi_wlast),
        .axi_wvalid       (ddr_axi_wvalid),
        .axi_wready       (ddr_axi_wready),
        .axi_bid          (ddr_axi_bid),
        .axi_bresp        (ddr_axi_bresp),
        .axi_bvalid       (ddr_axi_bvalid),
        .axi_bready       (ddr_axi_bready),
        .axi_araddr       (ddr_axi_araddr),
        .axi_arid         (ddr_axi_arid),
        .axi_arlen        (ddr_axi_arlen),
        .axi_arsize       (ddr_axi_arsize),
        .axi_arburst      (ddr_axi_arburst),
        .axi_arvalid      (ddr_axi_arvalid),
        .axi_arready      (ddr_axi_arready),
        .axi_rdata        (ddr_axi_rdata),
        .axi_rid          (ddr_axi_rid),
        .axi_rresp        (ddr_axi_rresp),
        .axi_rlast        (ddr_axi_rlast),
        .axi_rvalid       (ddr_axi_rvalid),
        .axi_rready       (ddr_axi_rready)
    );

    ddr3_ctrl_v116 u_ddr3_ctrl (
        .ref_clk                 (ddr_ref_clk),
        .resetn                  (hard_rst_n),
        .core_clk                (ddr_core_clk),
        .pll_lock                (),
        .phy_pll_lock            (),
        .gpll_lock               (),
        .rst_gpll_lock           (),
        .ddrphy_cpd_lock         (),
        .ddr_init_done           (ddr_init_done),

        .axi_awaddr              (ddr_axi_awaddr),
        .axi_awid                (ddr_axi_awid),
        .axi_awlen               (ddr_axi_awlen),
        .axi_awsize              (ddr_axi_awsize),
        .axi_awburst             (ddr_axi_awburst),
        .axi_awready             (ddr_axi_awready),
        .axi_awvalid             (ddr_axi_awvalid),
        .axi_wdata               (ddr_axi_wdata),
        .axi_wstrb               (ddr_axi_wstrb),
        .axi_wlast               (ddr_axi_wlast),
        .axi_wvalid              (ddr_axi_wvalid),
        .axi_wready              (ddr_axi_wready),
        .axi_bready              (ddr_axi_bready),
        .axi_bid                 (ddr_axi_bid),
        .axi_bresp               (ddr_axi_bresp),
        .axi_bvalid              (ddr_axi_bvalid),
        .axi_araddr              (ddr_axi_araddr),
        .axi_arid                (ddr_axi_arid),
        .axi_arlen               (ddr_axi_arlen),
        .axi_arsize              (ddr_axi_arsize),
        .axi_arburst             (ddr_axi_arburst),
        .axi_arready             (ddr_axi_arready),
        .axi_arvalid             (ddr_axi_arvalid),
        .axi_rready              (ddr_axi_rready),
        .axi_rdata               (ddr_axi_rdata),
        .axi_rid                 (ddr_axi_rid),
        .axi_rlast               (ddr_axi_rlast),
        .axi_rvalid              (ddr_axi_rvalid),
        .axi_rresp               (ddr_axi_rresp),

        .apb_clk                 (1'b0),
        .apb_rst_n               (1'b1),
        .apb_sel                 (1'b0),
        .apb_enable              (1'b0),
        .apb_addr                (8'd0),
        .apb_write               (1'b0),
        .apb_ready               (),
        .apb_wdata               (16'd0),
        .apb_rdata               (),

        .mem_rst_n               (mem_rst_n),
        .mem_ck                  (mem_ck),
        .mem_ck_n                (mem_ck_n),
        .mem_cke                 (mem_cke),
        .mem_cs_n                (mem_cs_n),
        .mem_ras_n               (mem_ras_n),
        .mem_cas_n               (mem_cas_n),
        .mem_we_n                (mem_we_n),
        .mem_odt                 (mem_odt),
        .mem_a                   (mem_a),
        .mem_ba                  (mem_ba),
        .mem_dqs                 (mem_dqs),
        .mem_dqs_n               (mem_dqs_n),
        .mem_dq                  (mem_dq),
        .mem_dm                  (mem_dm),

        .dbg_gate_start          (1'b0),
        .dbg_cpd_start           (1'b0),
        .dbg_ddrphy_rst_n        (1'b1),
        .dbg_gpll_scan_rst       (1'b0),
        .samp_position_dyn_adj   (1'b0),
        .init_samp_position_even (32'd0),
        .wrcal_position_dyn_adj  (1'b0),
        .init_wrcal_position     (32'd0),
        .force_read_clk_ctrl     (1'b0),
        .init_slip_step          (16'd0),
        .init_read_clk_ctrl      (12'd0),
        .debug_calib_ctrl        (),
        .dbg_slice_status        (),
        .dbg_slice_state         (),
        .debug_data              (),
        .dbg_dll_upd_state       (),
        .debug_gpll_dps_phase    (),
        .dbg_rst_dps_state       (),
        .dbg_tran_err_rst_cnt    (),
        .dbg_ddrphy_init_fail    (),
        .debug_cpd_offset_adj    (1'b0),
        .debug_cpd_offset_dir    (1'b0),
        .debug_cpd_offset        (10'd0),
        .debug_dps_cnt_dir0      (),
        .debug_dps_cnt_dir1      (),
        .ck_dly_en               (1'b0),
        .init_ck_dly_step        (8'd0),
        .ck_dly_set_bin          (),
        .align_error             (),
        .debug_rst_state         (),
        .debug_cpd_state         ()
    );

    assign core_active = ddr_init_done;

endmodule
