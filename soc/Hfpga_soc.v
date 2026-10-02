`timescale 1ns / 1ps
// PDS 的工作目录为 project/，故这里显式指向唯一的 soc 地址映射头文件，
// 不依赖 PDS 是否把普通 Verilog 源目录自动加入 include 搜索路径。
`include "../soc/soc_addr_map.vh"
// 支持 IDE 单文件解析；已有外部定义时保留调用方的程序路径。
`ifndef PROG_FPGA_PATH
`include "../soc/config.v"
`endif
// ===========================================================================
// Hfpga_soc
//
// CPU + cache subsystem now talk to the outside world through one 32-bit AXI4
// master (Htop / axi_bridge).  axi_mem_backend implements the memory map:
//   MMIO (0x4000_0000): peripherals；0x4000_0100 预留给 NPU 控制器
//   DDR  (0x8000_0000): forwarded through ddr_axi_bridge to the DDR3 IP；
//                         最高 128 MiB 预留为 NPU 共享非缓存区。
//
// The DDR3 controller is connected through ddr_axi_bridge.  core_active still
// reports the controller's initialization-complete status.
// ===========================================================================
module Hfpga_soc #(
    parameter MEM_FILE                  = `PROG_FPGA_PATH,
    // 地址映射默认值集中在 soc_addr_map.vh；此处保留参数覆盖能力，便于
    // 更换 DDR 容量或重新划分 NPU 缓冲区时只改顶层实例。
    parameter [31:0] DDR_BASE           = `SOC_DDR_BASE,
    parameter [31:0] DDR_BYTES          = `SOC_DDR_BYTES,
    parameter [23:0] FLASH_BASE         = 24'hA00000,
    // 默认匹配 16 KiB camera_stereo_local/remote.bin；旧单目镜像需用旧位流
    // 或显式覆盖为其实际长度。加载器只接受完整32位字并逐字回读校验DDR。
    parameter [31:0] BOOT_IMAGE_BYTES   = 32'd16384,
    parameter integer SPI_DIV           = 4,
    // 本地主板 C24 对应 FPIOA0；远程板可覆盖为 31（AB26）。
    parameter integer UART_TX_DEFAULT_FPIOA = 0,
    parameter integer DDR_INIT_TIMEOUT_CYCLES = 70000000,
    parameter [31:0] CPU_CACHED_DDR_BASE  = `SOC_CPU_CACHED_DDR_BASE,
    parameter [31:0] CPU_CACHED_DDR_BYTES = `SOC_CPU_CACHED_DDR_BYTES,
    parameter [31:0] NPU_SHARED_BASE    = `SOC_NPU_SHARED_BASE,
    parameter [31:0] NPU_SHARED_BYTES   = `SOC_NPU_SHARED_BYTES,
    parameter [31:0] MMIO_BASE          = `SOC_MMIO_BASE,
    parameter [31:0] MMIO_BYTES         = `SOC_MMIO_BYTES,
    parameter [31:0] NPU_MMIO_BASE      = `SOC_NPU_MMIO_BASE,
    parameter [31:0] NPU_MMIO_BYTES     = `SOC_NPU_MMIO_BYTES,
    parameter [31:0] UART0_BASE         = `SOC_UART0_BASE,
    parameter [31:0] UART0_BYTES        = `SOC_UART0_BYTES,
    parameter [31:0] LED_ADDR           = `SOC_LED_ADDR,
    parameter [31:0] CAM1_MMIO_BASE     = `SOC_CAM1_MMIO_BASE,
    parameter [31:0] CAM1_MMIO_BYTES    = `SOC_CAM1_MMIO_BYTES,
    parameter [31:0] CAM2_MMIO_BASE     = `SOC_CAM2_MMIO_BASE,
    parameter [31:0] CAM2_MMIO_BYTES    = `SOC_CAM2_MMIO_BYTES,
    parameter [31:0] FPIOA_BASE         = `SOC_FPIOA_BASE,
    parameter [31:0] FPIOA_BYTES        = `SOC_FPIOA_BYTES
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

    // 双目 FMC 模块上的物理 CAM1。模块自带 24 MHz XCLK，并在模块侧处理
    // PWDN；SCCB 负责控制，DVP 接口接收 8 位 RGB565 数据。
    inout  cam1_scl,
    inout  cam1_sda,
    output cam1_reset_n,
    input  cam1_pclk,
    input  cam1_vsync,
    input  cam1_href,
    input  [7:0] cam1_data,

    // CAM2 的 D[4:1] 中三位复用 FPIOA 专用输入球位：18=D4、29=D2、28=D1。
    inout  cam2_scl,
    inout  cam2_sda,
    output cam2_reset_n,
    input  cam2_pclk,
    input  cam2_vsync,
    input  cam2_href,
    input  [2:0] cam2_data_hi,
    input  cam2_data3,
    input  cam2_data0,

    // Abstract single-bit SPI Flash pins.  The serial clock is driven through
    // the device's dedicated configuration-clock primitive below.
    output        flash_cs_n,
    output        flash_cs2_n,
    output        flash_mosi,
    input         flash_miso,
    output        flash_wp_n,
    output        flash_hold_n,

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

    // NPU 控制器仍在 cpu_clk 域。Task 4 将把这些 start/config 输出接到 DMA
    // 引擎；在此之前 engine_done 固定为零，不能在可综合顶层伪造完成事件。
    wire        npu_irq;
    wire        npu_start_pulse;
    wire [31:0] npu_engine_input_addr;
    wire [31:0] npu_engine_weight_addr;
    wire [31:0] npu_engine_output_addr;
    wire [31:0] npu_engine_task_bytes;
    wire        npu_engine_done = 1'b0;

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

    // CPU/backend request channel.  It is isolated from the DDR bridge while
    // the Flash loader owns the bridge-side channel above.
    wire        run_req_valid;
    wire        run_req_ready;
    wire        run_req_write;
    wire [31:0] run_req_addr;
    wire [31:0] run_req_wdata;
    wire [3:0]  run_req_wstrb;
    wire        run_rsp_valid;
    wire        run_rsp_ready;
    wire        run_rsp_is_read;
    wire [31:0] run_rsp_rdata;

    wire        boot_done;
    wire        boot_error;
    wire [3:0]  boot_error_code;
    wire        boot_ddr_ready_cpu;
    wire        flash_clk_enable;
    wire        flash_spi_sck;

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

    // CPU/启动桥与 Camera DMA 分别作为 DDR AXI 主机。
    wire [29:0]   bridge_axi_awaddr;
    wire [7:0]    bridge_axi_awid;
    wire [7:0]    bridge_axi_awlen;
    wire [2:0]    bridge_axi_awsize;
    wire [1:0]    bridge_axi_awburst;
    wire          bridge_axi_awvalid;
    wire          bridge_axi_awready;
    wire [255:0]  bridge_axi_wdata;
    wire [31:0]   bridge_axi_wstrb;
    wire          bridge_axi_wlast;
    wire          bridge_axi_wvalid;
    wire          bridge_axi_wready;
    wire [7:0]    bridge_axi_bid;
    wire [1:0]    bridge_axi_bresp;
    wire          bridge_axi_bvalid;
    wire          bridge_axi_bready;
    wire [29:0]   bridge_axi_araddr;
    wire [7:0]    bridge_axi_arid;
    wire [7:0]    bridge_axi_arlen;
    wire [2:0]    bridge_axi_arsize;
    wire [1:0]    bridge_axi_arburst;
    wire          bridge_axi_arvalid;
    wire          bridge_axi_arready;
    wire [255:0]  bridge_axi_rdata;
    wire [7:0]    bridge_axi_rid;
    wire [1:0]    bridge_axi_rresp;
    wire          bridge_axi_rlast;
    wire          bridge_axi_rvalid;
    wire          bridge_axi_rready;
    wire [29:0]   camera_axi_awaddr;
    wire [7:0]    camera_axi_awid;
    wire [7:0]    camera_axi_awlen;
    wire [2:0]    camera_axi_awsize;
    wire [1:0]    camera_axi_awburst;
    wire          camera_axi_awvalid;
    wire          camera_axi_awready;
    wire [255:0]  camera_axi_wdata;
    wire [31:0]   camera_axi_wstrb;
    wire          camera_axi_wlast;
    wire          camera_axi_wvalid;
    wire          camera_axi_wready;
    wire [7:0]    camera_axi_bid;
    wire [1:0]    camera_axi_bresp;
    wire          camera_axi_bvalid;
    wire          camera_axi_bready;
    wire [29:0]   cam1_axi_awaddr, cam2_axi_awaddr;
    wire [7:0]    cam1_axi_awid, cam2_axi_awid;
    wire [7:0]    cam1_axi_awlen, cam2_axi_awlen;
    wire [2:0]    cam1_axi_awsize, cam2_axi_awsize;
    wire [1:0]    cam1_axi_awburst, cam2_axi_awburst;
    wire          cam1_axi_awvalid, cam2_axi_awvalid;
    wire          cam1_axi_awready, cam2_axi_awready;
    wire [255:0]  cam1_axi_wdata, cam2_axi_wdata;
    wire [31:0]   cam1_axi_wstrb, cam2_axi_wstrb;
    wire          cam1_axi_wlast, cam2_axi_wlast;
    wire          cam1_axi_wvalid, cam2_axi_wvalid;
    wire          cam1_axi_wready, cam2_axi_wready;
    wire [7:0]    cam1_axi_bid, cam2_axi_bid;
    wire [1:0]    cam1_axi_bresp, cam2_axi_bresp;
    wire          cam1_axi_bvalid, cam2_axi_bvalid;
    wire          cam1_axi_bready, cam2_axi_bready;
    wire [7:0]    cam2_data = {cam2_data_hi, fpioa[18], cam2_data3,
                               fpioa[29], fpioa[28], cam2_data0};

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
                   !boot_done || boot_error || !boot_ddr_ready_cpu ||
                   jtag_reset_req || jtag_halt_req;

    // ============ CPU + caches + axi_bridge =============================
    Htop #(
        .RESET_PC                 (DDR_BASE),
        .DDR_BASE                 (DDR_BASE),
        .DDR_BYTES                (DDR_BYTES),
        .DCACHEABLE_DDR_BASE      (CPU_CACHED_DDR_BASE),
        .DCACHEABLE_DDR_BYTES     (CPU_CACHED_DDR_BYTES)
    ) u_cpu (
        .clk        (cpu_clk),
        .rst        (cpu_rst),
        .irq_external(npu_irq),

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
        .icache_miss(),
        .dcache_miss(),

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

    wire        npu_addr_sel;
    wire        npu_sel;
    wire        npu_mmio_ready;
    wire [31:0] npu_mmio_rdata;

    axi_mem_backend #(
        .MMIO_BASE  (MMIO_BASE),
        .MMIO_BYTES (MMIO_BYTES),
        .DDR_BASE   (DDR_BASE),
        .DDR_BYTES  (DDR_BYTES)
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

        .ddr_req_valid (run_req_valid),
        .ddr_req_ready (run_req_ready),
        .ddr_req_write (run_req_write),
        .ddr_req_addr  (run_req_addr),
        .ddr_req_wdata (run_req_wdata),
        .ddr_req_wstrb (run_req_wstrb),
        .ddr_rsp_valid (run_rsp_valid),
        .ddr_rsp_ready (run_rsp_ready),
        .ddr_rsp_is_read(run_rsp_is_read),
        .ddr_rsp_rdata (run_rsp_rdata),

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
    localparam [31:0] UART0_END  = UART0_BASE + UART0_BYTES;
    localparam [31:0] CAM1_MMIO_END = CAM1_MMIO_BASE + CAM1_MMIO_BYTES;
    localparam [31:0] CAM2_MMIO_END = CAM2_MMIO_BASE + CAM2_MMIO_BYTES;
    localparam [31:0] FPIOA_END  = FPIOA_BASE + FPIOA_BYTES;

    wire uart_addr_sel = (mmio_req_addr >= UART0_BASE) &&
                         (mmio_req_addr <  UART0_END);
    wire uart_sel = mmio_req_valid && uart_addr_sel;
    wire led_sel  = mmio_req_valid && (mmio_req_addr == LED_ADDR);
    wire cam1_sel = mmio_req_valid &&
                    (mmio_req_addr >= CAM1_MMIO_BASE) &&
                    (mmio_req_addr <  CAM1_MMIO_END);
    wire cam2_sel = mmio_req_valid &&
                    (mmio_req_addr >= CAM2_MMIO_BASE) &&
                    (mmio_req_addr <  CAM2_MMIO_END);
    wire fpioa_sel = mmio_req_valid &&
                     (mmio_req_addr >= FPIOA_BASE) &&
                     (mmio_req_addr <  FPIOA_END);

    Hnpu_ctrl #(
        .NPU_MMIO_BASE  (NPU_MMIO_BASE),
        .NPU_MMIO_BYTES (NPU_MMIO_BYTES)
    ) u_npu_ctrl (
        .clk                (cpu_clk),
        .rst_n              (sys_rst_n),
        .mmio_valid         (mmio_req_valid),
        .mmio_wen           (mmio_req_wen),
        .mmio_addr          (mmio_req_addr),
        .mmio_wdata         (mmio_req_wdata),
        .mmio_wstrb         (mmio_req_wstrb),
        .mmio_addr_sel      (npu_addr_sel),
        .mmio_sel           (npu_sel),
        .mmio_ready         (npu_mmio_ready),
        .mmio_rdata         (npu_mmio_rdata),
        .start_pulse        (npu_start_pulse),
        .engine_done        (npu_engine_done),
        .engine_input_addr  (npu_engine_input_addr),
        .engine_weight_addr (npu_engine_weight_addr),
        .engine_output_addr (npu_engine_output_addr),
        .engine_task_bytes  (npu_engine_task_bytes),
        .irq                (npu_irq)
    );

    // UART TX data writes are the only peripheral access that can be busy.
    assign mmio_req_ready = uart_addr_sel ? uart_ready :
                            npu_addr_sel  ? npu_mmio_ready : 1'b1;

    wire [31:0] uart_rdata;
    wire uart_ready;
    wire uart_tx;
    wire [3:0] led_value;
    wire [31:0] fpioa_rdata;
    wire [31:0] cam1_gpio_rdata;
    wire [31:0] cam1_dvp_rdata;
    wire [31:0] cam1_rdata = cam1_gpio_rdata | cam1_dvp_rdata;
    wire cam1_capture_enable;
    wire [31:0] cam2_gpio_rdata;
    wire [31:0] cam2_dvp_rdata;
    wire [31:0] cam2_rdata = cam2_gpio_rdata | cam2_dvp_rdata;
    wire cam2_capture_enable;


    Huart_tx #(
        .CLK_HZ(70_000_000)
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

    Hfpioa_simple #(
        .UART_TX_DEFAULT_FPIOA(UART_TX_DEFAULT_FPIOA),
        .INPUT_ONLY_MASK(32'h3004_0000)
    ) u_fpioa (
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

    Hcamera_sccb_gpio u_cam1_sccb_gpio (
        .clk          (cpu_clk),
        .rst_n        (sys_rst_n),
        .mmio_valid   (cam1_sel),
        .mmio_wen     (mmio_req_wen),
        .mmio_addr    (mmio_req_addr[7:0]),
        .mmio_wdata   (mmio_req_wdata),
        .mmio_wmask   (mmio_req_wstrb),
        .mmio_rdata   (cam1_gpio_rdata),
        .cam1_scl     (cam1_scl),
        .cam1_sda     (cam1_sda),
        .cam1_reset_n (cam1_reset_n),
        .cam1_capture_enable(cam1_capture_enable)
    );

    Hcamera_subsystem #(
        .DDR_BASE(DDR_BASE),
        .DDR_BYTES(DDR_BYTES),
        .BUFFER0_ADDR(`SOC_CAM1_BUFFER0_BASE),
        .BUFFER1_ADDR(`SOC_CAM1_BUFFER1_BASE),
        .AXI_ID(8'h40)
    ) u_cam1 (
        .cpu_clk(cpu_clk), .mem_clk(ddr_core_clk), .rst_n(sys_rst_n),
        .ddr_ready(ddr_init_done), .capture_enable(cam1_capture_enable),
        .pclk(cam1_pclk), .vsync(cam1_vsync), .href(cam1_href), .data(cam1_data),
        .mmio_valid(cam1_sel), .mmio_wen(mmio_req_wen),
        .mmio_addr(mmio_req_addr[7:0]), .mmio_wdata(mmio_req_wdata),
        .mmio_wmask(mmio_req_wstrb), .mmio_rdata(cam1_dvp_rdata),
        .axi_awaddr(cam1_axi_awaddr), .axi_awid(cam1_axi_awid),
        .axi_awlen(cam1_axi_awlen), .axi_awsize(cam1_axi_awsize),
        .axi_awburst(cam1_axi_awburst), .axi_awvalid(cam1_axi_awvalid),
        .axi_awready(cam1_axi_awready), .axi_wdata(cam1_axi_wdata),
        .axi_wstrb(cam1_axi_wstrb), .axi_wlast(cam1_axi_wlast),
        .axi_wvalid(cam1_axi_wvalid), .axi_wready(cam1_axi_wready),
        .axi_bid(cam1_axi_bid), .axi_bresp(cam1_axi_bresp),
        .axi_bvalid(cam1_axi_bvalid), .axi_bready(cam1_axi_bready)
    );

    Hcamera_sccb_gpio u_cam2_sccb_gpio (
        .clk(cpu_clk), .rst_n(sys_rst_n), .mmio_valid(cam2_sel),
        .mmio_wen(mmio_req_wen), .mmio_addr(mmio_req_addr[7:0]),
        .mmio_wdata(mmio_req_wdata), .mmio_wmask(mmio_req_wstrb),
        .mmio_rdata(cam2_gpio_rdata), .cam1_scl(cam2_scl),
        .cam1_sda(cam2_sda), .cam1_reset_n(cam2_reset_n),
        .cam1_capture_enable(cam2_capture_enable)
    );

    Hcamera_subsystem #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(DDR_BYTES),
        .BUFFER0_ADDR(`SOC_CAM2_BUFFER0_BASE),
        .BUFFER1_ADDR(`SOC_CAM2_BUFFER1_BASE), .AXI_ID(8'h41)
    ) u_cam2 (
        .cpu_clk(cpu_clk), .mem_clk(ddr_core_clk), .rst_n(sys_rst_n),
        .ddr_ready(ddr_init_done), .capture_enable(cam2_capture_enable),
        .pclk(cam2_pclk), .vsync(cam2_vsync), .href(cam2_href), .data(cam2_data),
        .mmio_valid(cam2_sel), .mmio_wen(mmio_req_wen),
        .mmio_addr(mmio_req_addr[7:0]), .mmio_wdata(mmio_req_wdata),
        .mmio_wmask(mmio_req_wstrb), .mmio_rdata(cam2_dvp_rdata),
        .axi_awaddr(cam2_axi_awaddr), .axi_awid(cam2_axi_awid),
        .axi_awlen(cam2_axi_awlen), .axi_awsize(cam2_axi_awsize),
        .axi_awburst(cam2_axi_awburst), .axi_awvalid(cam2_axi_awvalid),
        .axi_awready(cam2_axi_awready), .axi_wdata(cam2_axi_wdata),
        .axi_wstrb(cam2_axi_wstrb), .axi_wlast(cam2_axi_wlast),
        .axi_wvalid(cam2_axi_wvalid), .axi_wready(cam2_axi_wready),
        .axi_bid(cam2_axi_bid), .axi_bresp(cam2_axi_bresp),
        .axi_bvalid(cam2_axi_bvalid), .axi_bready(cam2_axi_bready)
    );

    // 复用同一个事务锁定仲裁器；此层 cpu/npu 口名称仅代表 CAM1/CAM2。
    // 两路只写 DDR，读请求关闭，AW/W/B 拥有者保持到写响应完成。
    Haxi_2m1s_arbiter u_stereo_merge (
        .clk(ddr_core_clk), .rst_n(sys_rst_n),
        .cpu_axi_awaddr(cam1_axi_awaddr),
        .cpu_axi_awid(cam1_axi_awid),
        .cpu_axi_awlen(cam1_axi_awlen),
        .cpu_axi_awsize(cam1_axi_awsize),
        .cpu_axi_awburst(cam1_axi_awburst),
        .cpu_axi_awvalid(cam1_axi_awvalid),
        .cpu_axi_awready(cam1_axi_awready),
        .cpu_axi_wdata(cam1_axi_wdata),
        .cpu_axi_wstrb(cam1_axi_wstrb),
        .cpu_axi_wlast(cam1_axi_wlast),
        .cpu_axi_wvalid(cam1_axi_wvalid),
        .cpu_axi_wready(cam1_axi_wready),
        .cpu_axi_bid(cam1_axi_bid),
        .cpu_axi_bresp(cam1_axi_bresp),
        .cpu_axi_bvalid(cam1_axi_bvalid),
        .cpu_axi_bready(cam1_axi_bready),
        .cpu_axi_araddr(30'b0),
        .cpu_axi_arid(8'b0),
        .cpu_axi_arlen(8'b0),
        .cpu_axi_arsize(3'b0),
        .cpu_axi_arburst(2'b0),
        .cpu_axi_arvalid(1'b0),
        .cpu_axi_arready(),
        .cpu_axi_rdata(),
        .cpu_axi_rid(),
        .cpu_axi_rresp(),
        .cpu_axi_rlast(),
        .cpu_axi_rvalid(),
        .cpu_axi_rready(1'b1),
        .npu_axi_awaddr(cam2_axi_awaddr),
        .npu_axi_awid(cam2_axi_awid),
        .npu_axi_awlen(cam2_axi_awlen),
        .npu_axi_awsize(cam2_axi_awsize),
        .npu_axi_awburst(cam2_axi_awburst),
        .npu_axi_awvalid(cam2_axi_awvalid),
        .npu_axi_awready(cam2_axi_awready),
        .npu_axi_wdata(cam2_axi_wdata),
        .npu_axi_wstrb(cam2_axi_wstrb),
        .npu_axi_wlast(cam2_axi_wlast),
        .npu_axi_wvalid(cam2_axi_wvalid),
        .npu_axi_wready(cam2_axi_wready),
        .npu_axi_bid(cam2_axi_bid),
        .npu_axi_bresp(cam2_axi_bresp),
        .npu_axi_bvalid(cam2_axi_bvalid),
        .npu_axi_bready(cam2_axi_bready),
        .npu_axi_araddr(30'b0),
        .npu_axi_arid(8'b0),
        .npu_axi_arlen(8'b0),
        .npu_axi_arsize(3'b0),
        .npu_axi_arburst(2'b0),
        .npu_axi_arvalid(1'b0),
        .npu_axi_arready(),
        .npu_axi_rdata(),
        .npu_axi_rid(),
        .npu_axi_rresp(),
        .npu_axi_rlast(),
        .npu_axi_rvalid(),
        .npu_axi_rready(1'b1),
        .ddr_axi_awaddr(camera_axi_awaddr),
        .ddr_axi_awid(camera_axi_awid),
        .ddr_axi_awlen(camera_axi_awlen),
        .ddr_axi_awsize(camera_axi_awsize),
        .ddr_axi_awburst(camera_axi_awburst),
        .ddr_axi_awvalid(camera_axi_awvalid),
        .ddr_axi_awready(camera_axi_awready),
        .ddr_axi_wdata(camera_axi_wdata),
        .ddr_axi_wstrb(camera_axi_wstrb),
        .ddr_axi_wlast(camera_axi_wlast),
        .ddr_axi_wvalid(camera_axi_wvalid),
        .ddr_axi_wready(camera_axi_wready),
        .ddr_axi_bid(camera_axi_bid),
        .ddr_axi_bresp(camera_axi_bresp),
        .ddr_axi_bvalid(camera_axi_bvalid),
        .ddr_axi_bready(camera_axi_bready),
        .ddr_axi_araddr(),
        .ddr_axi_arid(),
        .ddr_axi_arlen(),
        .ddr_axi_arsize(),
        .ddr_axi_arburst(),
        .ddr_axi_arvalid(),
        .ddr_axi_arready(1'b0),
        .ddr_axi_rdata(256'b0),
        .ddr_axi_rid(8'b0),
        .ddr_axi_rresp(2'b0),
        .ddr_axi_rlast(1'b0),
        .ddr_axi_rvalid(1'b0),
        .ddr_axi_rready()
    );

    assign mmio_req_rdata =
        uart_sel   ? uart_rdata        :
        npu_sel    ? npu_mmio_rdata    :
        led_sel    ? {28'b0, led_value}:
        cam1_sel   ? cam1_rdata        :
        cam2_sel   ? cam2_rdata        :
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
        .ex_pc                   (),
        .mem_pc                  (),
        .wb_pc                   (),
        .if_ins                  (),
        .id_ins                  (dbg_id_ins),
        .ex_ins                  (),
        .mem_ins                 (),
        .wb_ins                  (),
        .dmem_addr               (),
        .dmem_wdata              (),
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
    flash_ddr_boot #(
        .FLASH_BASE     (FLASH_BASE),
        .DDR_BASE       (DDR_BASE),
        .DDR_LIMIT      ({1'b0, DDR_BASE} + {1'b0, DDR_BYTES}),
        .IMAGE_BYTES    (BOOT_IMAGE_BYTES),
        .SPI_CLK_DIV    (SPI_DIV),
        .TIMEOUT_CYCLES (100000),
        .DDR_INIT_TIMEOUT_CYCLES (DDR_INIT_TIMEOUT_CYCLES)
    ) u_flash_ddr_boot (
        .clk             (cpu_clk),
        .rst_n           (sys_rst_n),
        .ddr_init_done   (ddr_init_done),
        .flash_cs_n      (flash_cs_n),
        .flash_cs2_n     (flash_cs2_n),
        .flash_mosi      (flash_mosi),
        .flash_miso      (flash_miso),
        .flash_wp_n      (flash_wp_n),
        .flash_hold_n    (flash_hold_n),
        .flash_sck       (flash_spi_sck),
        .run_req_valid   (run_req_valid),
        .run_req_ready   (run_req_ready),
        .run_req_write   (run_req_write),
        .run_req_addr    (run_req_addr),
        .run_req_wdata   (run_req_wdata),
        .run_req_wstrb   (run_req_wstrb),
        .run_rsp_valid   (run_rsp_valid),
        .run_rsp_ready   (run_rsp_ready),
        .run_rsp_is_read (run_rsp_is_read),
        .run_rsp_rdata   (run_rsp_rdata),
        .ddr_req_valid   (ddr_req_valid),
        .ddr_req_ready   (ddr_req_ready),
        .ddr_req_write   (ddr_req_write),
        .ddr_req_addr    (ddr_req_addr),
        .ddr_req_wdata   (ddr_req_wdata),
        .ddr_req_wstrb   (ddr_req_wstrb),
        .ddr_rsp_valid   (ddr_rsp_valid),
        .ddr_rsp_ready   (ddr_rsp_ready),
        .ddr_rsp_is_read (ddr_rsp_is_read),
        .ddr_rsp_rdata   (ddr_rsp_rdata),
        .boot_done       (boot_done),
        .boot_error      (boot_error),
        .boot_error_code (boot_error_code),
        .ddr_ready_cpu   (boot_ddr_ready_cpu),
        .flash_clk_enable(flash_clk_enable)
    );

    // GTP_CFGCLK drives the dedicated CFG_CLK pin; no ordinary SCK IO is
    // consumed by the board pinout.
    GTP_CFGCLK u_flash_cfgclk (
        .CLKIN (flash_spi_sck),
        .CE_N  (~flash_clk_enable)
    );

    ddr_axi_bridge u_ddr_axi_bridge (
        .cpu_clk          (cpu_clk),
        .ddr_clk          (ddr_core_clk),
        // Keep the bridge transaction state aligned with the boot wrapper's
        // sys_rst_n reset (which also asserts when the CPU PLL loses lock).
        // The DDR controller shares this PLL-aware reset below so stale AXI
        // transactions cannot survive a CPU clock relock.
        .rst_n            (sys_rst_n),
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

        .axi_awaddr       (bridge_axi_awaddr),
        .axi_awid         (bridge_axi_awid),
        .axi_awlen        (bridge_axi_awlen),
        .axi_awsize       (bridge_axi_awsize),
        .axi_awburst      (bridge_axi_awburst),
        .axi_awvalid      (bridge_axi_awvalid),
        .axi_awready      (bridge_axi_awready),
        .axi_wdata        (bridge_axi_wdata),
        .axi_wstrb        (bridge_axi_wstrb),
        .axi_wlast        (bridge_axi_wlast),
        .axi_wvalid       (bridge_axi_wvalid),
        .axi_wready       (bridge_axi_wready),
        .axi_bid          (bridge_axi_bid),
        .axi_bresp        (bridge_axi_bresp),
        .axi_bvalid       (bridge_axi_bvalid),
        .axi_bready       (bridge_axi_bready),
        .axi_araddr       (bridge_axi_araddr),
        .axi_arid         (bridge_axi_arid),
        .axi_arlen        (bridge_axi_arlen),
        .axi_arsize       (bridge_axi_arsize),
        .axi_arburst      (bridge_axi_arburst),
        .axi_arvalid      (bridge_axi_arvalid),
        .axi_arready      (bridge_axi_arready),
        .axi_rdata        (bridge_axi_rdata),
        .axi_rid          (bridge_axi_rid),
        .axi_rresp        (bridge_axi_rresp),
        .axi_rlast        (bridge_axi_rlast),
        .axi_rvalid       (bridge_axi_rvalid),
        .axi_rready       (bridge_axi_rready)
    );

    // 复用已有两主机仲裁器：第二个历史命名为 npu 的端口本阶段接 Camera。
    // NPU 引擎接入时需扩展主机拓扑，当前没有隐式 NPU/Camera 共用端口。
    Haxi_2m1s_arbiter u_camera_ddr_arbiter (
        .clk(ddr_core_clk), .rst_n(sys_rst_n),
        .cpu_axi_awaddr(bridge_axi_awaddr),
        .cpu_axi_awid(bridge_axi_awid),
        .cpu_axi_awlen(bridge_axi_awlen),
        .cpu_axi_awsize(bridge_axi_awsize),
        .cpu_axi_awburst(bridge_axi_awburst),
        .cpu_axi_awvalid(bridge_axi_awvalid),
        .cpu_axi_awready(bridge_axi_awready),
        .cpu_axi_wdata(bridge_axi_wdata),
        .cpu_axi_wstrb(bridge_axi_wstrb),
        .cpu_axi_wlast(bridge_axi_wlast),
        .cpu_axi_wvalid(bridge_axi_wvalid),
        .cpu_axi_wready(bridge_axi_wready),
        .cpu_axi_bid(bridge_axi_bid),
        .cpu_axi_bresp(bridge_axi_bresp),
        .cpu_axi_bvalid(bridge_axi_bvalid),
        .cpu_axi_bready(bridge_axi_bready),
        .cpu_axi_araddr(bridge_axi_araddr),
        .cpu_axi_arid(bridge_axi_arid),
        .cpu_axi_arlen(bridge_axi_arlen),
        .cpu_axi_arsize(bridge_axi_arsize),
        .cpu_axi_arburst(bridge_axi_arburst),
        .cpu_axi_arvalid(bridge_axi_arvalid),
        .cpu_axi_arready(bridge_axi_arready),
        .cpu_axi_rdata(bridge_axi_rdata),
        .cpu_axi_rid(bridge_axi_rid),
        .cpu_axi_rresp(bridge_axi_rresp),
        .cpu_axi_rlast(bridge_axi_rlast),
        .cpu_axi_rvalid(bridge_axi_rvalid),
        .cpu_axi_rready(bridge_axi_rready),
        .npu_axi_awaddr(camera_axi_awaddr),
        .npu_axi_awid(camera_axi_awid),
        .npu_axi_awlen(camera_axi_awlen),
        .npu_axi_awsize(camera_axi_awsize),
        .npu_axi_awburst(camera_axi_awburst),
        .npu_axi_awvalid(camera_axi_awvalid),
        .npu_axi_awready(camera_axi_awready),
        .npu_axi_wdata(camera_axi_wdata),
        .npu_axi_wstrb(camera_axi_wstrb),
        .npu_axi_wlast(camera_axi_wlast),
        .npu_axi_wvalid(camera_axi_wvalid),
        .npu_axi_wready(camera_axi_wready),
        .npu_axi_bid(camera_axi_bid),
        .npu_axi_bresp(camera_axi_bresp),
        .npu_axi_bvalid(camera_axi_bvalid),
        .npu_axi_bready(camera_axi_bready),
        .npu_axi_araddr(30'b0),
        .npu_axi_arid(8'b0),
        .npu_axi_arlen(8'b0),
        .npu_axi_arsize(3'b0),
        .npu_axi_arburst(2'b0),
        .npu_axi_arvalid(1'b0),
        .npu_axi_arready(),
        .npu_axi_rdata(),
        .npu_axi_rid(),
        .npu_axi_rresp(),
        .npu_axi_rlast(),
        .npu_axi_rvalid(),
        .npu_axi_rready(1'b1),
        .ddr_axi_awaddr(ddr_axi_awaddr),
        .ddr_axi_awid(ddr_axi_awid),
        .ddr_axi_awlen(ddr_axi_awlen),
        .ddr_axi_awsize(ddr_axi_awsize),
        .ddr_axi_awburst(ddr_axi_awburst),
        .ddr_axi_awvalid(ddr_axi_awvalid),
        .ddr_axi_awready(ddr_axi_awready),
        .ddr_axi_wdata(ddr_axi_wdata),
        .ddr_axi_wstrb(ddr_axi_wstrb),
        .ddr_axi_wlast(ddr_axi_wlast),
        .ddr_axi_wvalid(ddr_axi_wvalid),
        .ddr_axi_wready(ddr_axi_wready),
        .ddr_axi_bid(ddr_axi_bid),
        .ddr_axi_bresp(ddr_axi_bresp),
        .ddr_axi_bvalid(ddr_axi_bvalid),
        .ddr_axi_bready(ddr_axi_bready),
        .ddr_axi_araddr(ddr_axi_araddr),
        .ddr_axi_arid(ddr_axi_arid),
        .ddr_axi_arlen(ddr_axi_arlen),
        .ddr_axi_arsize(ddr_axi_arsize),
        .ddr_axi_arburst(ddr_axi_arburst),
        .ddr_axi_arvalid(ddr_axi_arvalid),
        .ddr_axi_arready(ddr_axi_arready),
        .ddr_axi_rdata(ddr_axi_rdata),
        .ddr_axi_rid(ddr_axi_rid),
        .ddr_axi_rresp(ddr_axi_rresp),
        .ddr_axi_rlast(ddr_axi_rlast),
        .ddr_axi_rvalid(ddr_axi_rvalid),
        .ddr_axi_rready(ddr_axi_rready)
    );

    ddr3_ctrl_v116 u_ddr3_ctrl (
        .ref_clk                 (ddr_ref_clk),
        .resetn                  (sys_rst_n),
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
        .dq_idly_bin             (),
        .dq_odly_bin             (),
        .align_error             (),
        .debug_rst_state         (),
        .debug_cpd_state         ()
    );

    assign core_active = ddr_init_done;

endmodule
