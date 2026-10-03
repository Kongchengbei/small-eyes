`timescale 1ns / 1ps

module tb_Htop #(
    parameter BRAM_MODE = 1'b0
);

    localparam MEM_WORDS = 16384;  // 64 KiB at DDR_BASE
    localparam [31:0] DDR_BASE = 32'h8000_0000;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg bram_prog_valid = 1'b0;
    reg bram_prog_write = 1'b0;
    reg [31:0] bram_prog_addr = 32'b0;
    reg [31:0] bram_prog_wdata = 32'b0;
    reg [3:0] bram_prog_wstrb = 4'b0;
    wire bram_prog_ready;
    wire [31:0] bram_prog_rdata;
    reg mem_clk = 1'b0;
    always #4 mem_clk = ~mem_clk;
    wire bridge_req_ready;
    wire bridge_rsp_valid;
    wire bridge_rsp_is_read;
    wire [31:0] bridge_rsp_rdata;
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
    wire [29:0]   ddr_axi_awaddr;
    wire [7:0]    ddr_axi_awid;
    wire [7:0]    ddr_axi_awlen;
    wire [2:0]    ddr_axi_awsize;
    wire [1:0]    ddr_axi_awburst;
    wire          ddr_axi_awvalid;
    wire          ddr_axi_awready;
    wire [255:0]  ddr_axi_wdata;
    wire [31:0]   ddr_axi_wstrb;
    wire          ddr_axi_wlast;
    wire          ddr_axi_wvalid;
    wire          ddr_axi_wready;
    wire [7:0]    ddr_axi_bid;
    wire [1:0]    ddr_axi_bresp;
    wire          ddr_axi_bvalid;
    wire          ddr_axi_bready;
    wire [29:0]   ddr_axi_araddr;
    wire [7:0]    ddr_axi_arid;
    wire [7:0]    ddr_axi_arlen;
    wire [2:0]    ddr_axi_arsize;
    wire [1:0]    ddr_axi_arburst;
    wire          ddr_axi_arvalid;
    wire          ddr_axi_arready;
    wire [255:0]  ddr_axi_rdata;
    wire [7:0]    ddr_axi_rid;
    wire [1:0]    ddr_axi_rresp;
    wire          ddr_axi_rlast;
    wire          ddr_axi_rvalid;
    wire          ddr_axi_rready;
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

    // Htop exposes an AXI master. The memory backend converts it into the
    // one-word DDR-side interface provided by this testbench.
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

    wire        mmio_req_valid;
    wire        mmio_req_wen;
    wire [31:0] mmio_req_addr;
    wire [31:0] mmio_req_wdata;
    wire [3:0]  mmio_req_wstrb;
    wire        mmio_req_ready;
    wire [31:0] mmio_req_rdata;
    wire        uart_mmio_sel;
    wire        uart_mmio_ready;
    wire [31:0] uart_mmio_rdata;
    wire        uart_tx_pin;
    wire        fpioa_mmio_sel;
    wire [31:0] fpioa_mmio_rdata;
    tri1 [31:0] fpioa_pins;
    wire        cam1_mmio_sel;
    wire [31:0] cam1_gpio_rdata;
    wire [31:0] cam1_dvp_rdata;
    wire [31:0] cam1_mmio_rdata = cam1_gpio_rdata | cam1_dvp_rdata;
    tri1        cam1_scl;
    tri1        cam1_sda;
    wire        cam1_reset_n;
    wire        cam1_capture_enable;
    reg         cam1_pclk = 1'b0;
    reg         cam1_vsync = 1'b1;
    reg         cam1_href = 1'b0;
    reg  [7:0]  cam1_data = 8'b0;

    wire        ddr_req_valid;
    wire        ddr_req_ready = uart_smoke_mode ? bridge_req_ready : 1'b1;
    wire        ddr_req_write;
    wire [31:0] ddr_req_addr;
    wire [31:0] ddr_req_wdata;
    wire [3:0]  ddr_req_wstrb;
    wire        ddr_rsp_ready;
    reg         local_rsp_valid = 1'b0;
    reg         local_rsp_is_read = 1'b0;
    reg  [31:0] local_rsp_rdata = 32'b0;
    wire ddr_rsp_valid = uart_smoke_mode ? bridge_rsp_valid : local_rsp_valid;
    wire ddr_rsp_is_read = uart_smoke_mode ? bridge_rsp_is_read : local_rsp_is_read;
    wire [31:0] ddr_rsp_rdata = uart_smoke_mode ? bridge_rsp_rdata : local_rsp_rdata;

    reg [31:0] mem [0:MEM_WORDS-1];
    wire [31:0] ddr_word_addr = (ddr_req_addr - DDR_BASE) >> 2;
    wire        ddr_addr_valid = (ddr_req_addr >= DDR_BASE) &&
                                 (ddr_word_addr < MEM_WORDS);

    integer i;
    integer bram_i;
    integer cycle_count;
    integer timeout_cycles;
    string program_file;
    bit uart_smoke_mode;
    bit camera_bad_frame_mode;
    bit gpio_smoke_mode;
    bit coremark_mode;
    bit coremark_startup_only;
    bit gpio_sda_stuck_low;
    integer gpio_step_count = 0;
    integer gpio_line_start = 0;
    integer gpio_last_step_cycle = 0;
    string gpio_line;
    string gpio_expected_line;
    reg [5:0] gpio_expected_status;
    string uart_output;
    string uart_expected;
    string uart_pin_output;
    integer uart_expected_pin;
    bit uart_fw_checks_done = 1'b0;
    bit error_capture_active = 1'b0;
    bit error_snapshot_complete = 1'b0;
    integer error_title_count = 0;
    integer error_title_cycle = 0;
    integer camera_pclk_edge_count = 0;
    integer error_snapshot_start;
    string camera_error_snapshot;
    string camera_error_title = "CAM1 ERROR SNAPSHOT\r\n";
    localparam integer UART_BIT_CYCLES = 70_000_000 / 115_200;

    // 故障注入使用真实引脚拉低，不篡改 CPU 的 MMIO 应答。
    assign cam1_sda = gpio_sda_stuck_low ? 1'b0 : 1'bz;

    function automatic bit contains(input string value, input string fragment);
        integer offset;
        begin
            contains = 1'b0;
            for (offset = 0; offset + fragment.len() <= value.len(); offset++)
                if (value.substr(offset, offset + fragment.len() - 1) == fragment)
                    contains = 1'b1;
        end
    endfunction

    function automatic integer count_occurrences(input string value,
                                                  input string fragment);
        integer offset;
        begin
            count_occurrences = 0;
            for (offset = 0; offset + fragment.len() <= value.len(); offset++)
                if (value.substr(offset, offset + fragment.len() - 1) == fragment)
                    count_occurrences = count_occurrences + 1;
        end
    endfunction

    function automatic bit ends_with(input string value, input string suffix);
        begin
            ends_with = 1'b0;
            if (value.len() >= suffix.len())
                ends_with = (value.substr(value.len() - suffix.len(),
                                          value.len() - 1) == suffix);
        end
    endfunction

    wire [31:0] pc;
    wire [31:0] ins;
    wire        is_ebreak;
    wire        icache_miss;
    wire        dcache_miss;
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
    wire [31:0] debug_ctrl;

    always #7.143 clk = ~clk; // 板上 CPU 约 70 MHz；DDR 域独立运行。

    Htop #(.BRAM_MODE(BRAM_MODE)) dut (
        .clk        (clk),
        .rst        (rst),
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
		.irq_external(1'b0),
		.bram_prog_valid(bram_prog_valid), .bram_prog_write(bram_prog_write),
		.bram_prog_addr(bram_prog_addr), .bram_prog_wdata(bram_prog_wdata),
		.bram_prog_wstrb(bram_prog_wstrb), .bram_prog_ready(bram_prog_ready),
		.bram_prog_rdata(bram_prog_rdata),
        .pc         (pc),
        .ins        (ins),
        .is_ebreak  (is_ebreak),
        .icache_miss(icache_miss),
        .dcache_miss(dcache_miss),
        .debug_if_pc(debug_if_pc),
        .debug_id_pc(debug_id_pc),
        .debug_ex_pc(debug_ex_pc),
        .debug_mem_pc(debug_mem_pc),
        .debug_wb_pc(debug_wb_pc),
        .debug_if_ins(debug_if_ins),
        .debug_id_ins(debug_id_ins),
        .debug_ex_ins(debug_ex_ins),
        .debug_mem_ins(debug_mem_ins),
        .debug_wb_ins(debug_wb_ins),
        .debug_dmem_addr(debug_dmem_addr),
        .debug_dmem_wdata(debug_dmem_wdata),
        .debug_btb_predict_next_pc(debug_btb_predict_next_pc),
        .debug_actual_next_pc(debug_actual_next_pc),
        .debug_flush_pc(debug_flush_pc),
        .debug_ctrl(debug_ctrl)
    );

    axi_mem_backend u_mem_backend (
        .clk            (clk),
        .rst_n          (!rst),
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
        .ddr_req_valid  (ddr_req_valid),
        .ddr_req_ready  (ddr_req_ready),
        .ddr_req_write  (ddr_req_write),
        .ddr_req_addr   (ddr_req_addr),
        .ddr_req_wdata  (ddr_req_wdata),
        .ddr_req_wstrb  (ddr_req_wstrb),
        .ddr_rsp_valid  (ddr_rsp_valid),
        .ddr_rsp_ready  (ddr_rsp_ready),
        .ddr_rsp_is_read(ddr_rsp_is_read),
        .ddr_rsp_rdata  (ddr_rsp_rdata),
        .jtag_cmd_addr  (32'b0),
        .jtag_cmd_read  (1'b0),
        .jtag_cmd_valid (1'b0),
        .jtag_cmd_wdata (32'b0),
        .jtag_cmd_wmask (4'b0),
        .jtag_rsp_ready (1'b1),
        .jtag_cmd_ready (),
        .jtag_rsp_valid (),
        .jtag_rsp_err   (),
        .jtag_rsp_rdata ()
    );

    assign uart_mmio_sel = mmio_req_valid &&
                           (mmio_req_addr >= 32'h4000_0000) &&
                           (mmio_req_addr <  32'h4000_0100);
    assign cam1_mmio_sel = mmio_req_valid &&
                           (mmio_req_addr >= 32'h4000_0300) &&
                           (mmio_req_addr <  32'h4000_0400);
    assign fpioa_mmio_sel = mmio_req_valid &&
                           (mmio_req_addr >= 32'h4000_0f00) &&
                           (mmio_req_addr <  32'h4000_1000);
    assign mmio_req_ready = uart_mmio_sel ? uart_mmio_ready : 1'b1;
    assign mmio_req_rdata = uart_mmio_sel ? uart_mmio_rdata :
                            cam1_mmio_sel ? cam1_mmio_rdata :
                            fpioa_mmio_sel ? fpioa_mmio_rdata : 32'b0;

    Huart_tx #(
        .CLK_HZ(70_000_000),
        .BAUD(115_200)
    ) u_uart0 (
        .clk        (clk),
        .rst_n      (!rst),
        .mmio_valid (uart_mmio_sel),
        .mmio_wen   (mmio_req_wen),
        .mmio_addr  (mmio_req_addr[7:0]),
        .mmio_wdata (mmio_req_wdata),
        .mmio_wmask (mmio_req_wstrb),
        .mmio_ready (uart_mmio_ready),
        .mmio_rdata (uart_mmio_rdata),
        .tx_pin     (uart_tx_pin)
    );

    // 接入真实输出复用；不能只检查 TXDATA 而漏掉本地/远程物理出口错配。
    Hfpioa_simple #(.UART_TX_DEFAULT_FPIOA(0)) u_fpioa (
        .clk(clk), .rst_n(!rst), .mmio_valid(fpioa_mmio_sel),
        .mmio_wen(mmio_req_wen), .mmio_addr(mmio_req_addr[7:0]),
        .mmio_wdata(mmio_req_wdata), .mmio_wmask(mmio_req_wstrb),
        .mmio_rdata(fpioa_mmio_rdata), .uart0_tx(uart_tx_pin),
        .direct_led(4'b0), .fpioa(fpioa_pins)
    );

    Hcamera_sccb_gpio u_cam1_sccb_gpio (
        .clk          (clk),
        .rst_n        (!rst),
        .mmio_valid   (cam1_mmio_sel),
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

    Hcamera_subsystem u_cam1 (
        .consumer_ready_mask(), .consumer_frame0(), .consumer_frame1(),
        .consumer_release_valid(1'b0), .consumer_release_mask(2'b0),
        .cpu_clk(clk), .mem_clk(mem_clk), .rst_n(!rst),
        .ddr_ready(1'b1), .capture_enable(cam1_capture_enable),
        .pclk(cam1_pclk), .vsync(cam1_vsync), .href(cam1_href), .data(cam1_data),
        .mmio_valid(cam1_mmio_sel), .mmio_wen(mmio_req_wen),
        .mmio_addr(mmio_req_addr[7:0]), .mmio_wdata(mmio_req_wdata),
        .mmio_wmask(mmio_req_wstrb), .mmio_rdata(cam1_dvp_rdata),
        .axi_awaddr(camera_axi_awaddr), .axi_awid(camera_axi_awid),
        .axi_awlen(camera_axi_awlen), .axi_awsize(camera_axi_awsize),
        .axi_awburst(camera_axi_awburst), .axi_awvalid(camera_axi_awvalid),
        .axi_awready(camera_axi_awready), .axi_wdata(camera_axi_wdata),
        .axi_wstrb(camera_axi_wstrb), .axi_wlast(camera_axi_wlast),
        .axi_wvalid(camera_axi_wvalid), .axi_wready(camera_axi_wready),
        .axi_bid(camera_axi_bid), .axi_bresp(camera_axi_bresp),
        .axi_bvalid(camera_axi_bvalid), .axi_bready(camera_axi_bready)
    );

    ddr_axi_bridge u_camera_cpu_bridge (
        .cpu_clk(clk), .ddr_clk(mem_clk), .rst_n(!rst), .ddr_init_done(1'b1),
        .cpu_req_valid(ddr_req_valid && uart_smoke_mode), .cpu_req_ready(bridge_req_ready),
        .cpu_req_write(ddr_req_write), .cpu_req_addr(ddr_req_addr),
        .cpu_req_wdata(ddr_req_wdata), .cpu_req_wmask(ddr_req_wstrb),
        .cpu_rsp_rdata(bridge_rsp_rdata), .cpu_rsp_valid(bridge_rsp_valid),
        .cpu_rsp_is_read(bridge_rsp_is_read), .cpu_rsp_ready(ddr_rsp_ready && uart_smoke_mode),
        .axi_awaddr(bridge_axi_awaddr),
        .axi_awid(bridge_axi_awid),
        .axi_awlen(bridge_axi_awlen),
        .axi_awsize(bridge_axi_awsize),
        .axi_awburst(bridge_axi_awburst),
        .axi_awvalid(bridge_axi_awvalid),
        .axi_awready(bridge_axi_awready),
        .axi_wdata(bridge_axi_wdata),
        .axi_wstrb(bridge_axi_wstrb),
        .axi_wlast(bridge_axi_wlast),
        .axi_wvalid(bridge_axi_wvalid),
        .axi_wready(bridge_axi_wready),
        .axi_bid(bridge_axi_bid),
        .axi_bresp(bridge_axi_bresp),
        .axi_bvalid(bridge_axi_bvalid),
        .axi_bready(bridge_axi_bready),
        .axi_araddr(bridge_axi_araddr),
        .axi_arid(bridge_axi_arid),
        .axi_arlen(bridge_axi_arlen),
        .axi_arsize(bridge_axi_arsize),
        .axi_arburst(bridge_axi_arburst),
        .axi_arvalid(bridge_axi_arvalid),
        .axi_arready(bridge_axi_arready),
        .axi_rdata(bridge_axi_rdata),
        .axi_rid(bridge_axi_rid),
        .axi_rresp(bridge_axi_rresp),
        .axi_rlast(bridge_axi_rlast),
        .axi_rvalid(bridge_axi_rvalid),
        .axi_rready(bridge_axi_rready)
    );

    // 复用已有两主机仲裁器：第二个历史命名为 npu 的端口本阶段接 Camera。
    // NPU 引擎接入时需扩展主机拓扑，当前没有隐式 NPU/Camera 共用端口。
    Haxi_2m1s_arbiter u_camera_ddr_arbiter (
        .clk(mem_clk), .rst_n(!rst),
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

    camera_ddr_model u_camera_ddr (
        .clk(mem_clk), .rst_n(!rst),
        .axi_awaddr(ddr_axi_awaddr),
        .axi_awid(ddr_axi_awid),
        .axi_awlen(ddr_axi_awlen),
        .axi_awsize(ddr_axi_awsize),
        .axi_awburst(ddr_axi_awburst),
        .axi_awvalid(ddr_axi_awvalid),
        .axi_awready(ddr_axi_awready),
        .axi_wdata(ddr_axi_wdata),
        .axi_wstrb(ddr_axi_wstrb),
        .axi_wlast(ddr_axi_wlast),
        .axi_wvalid(ddr_axi_wvalid),
        .axi_wready(ddr_axi_wready),
        .axi_bid(ddr_axi_bid),
        .axi_bresp(ddr_axi_bresp),
        .axi_bvalid(ddr_axi_bvalid),
        .axi_bready(ddr_axi_bready),
        .axi_araddr(ddr_axi_araddr),
        .axi_arid(ddr_axi_arid),
        .axi_arlen(ddr_axi_arlen),
        .axi_arsize(ddr_axi_arsize),
        .axi_arburst(ddr_axi_arburst),
        .axi_arvalid(ddr_axi_arvalid),
        .axi_arready(ddr_axi_arready),
        .axi_rdata(ddr_axi_rdata),
        .axi_rid(ddr_axi_rid),
        .axi_rresp(ddr_axi_rresp),
        .axi_rlast(ddr_axi_rlast),
        .axi_rvalid(ddr_axi_rvalid),
        .axi_rready(ddr_axi_rready)
    );

    ov5640_sccb_model u_ov5640_model (
        .reset_n (cam1_reset_n),
        .scl     (cam1_scl),
        .sda     (cam1_sda)
    );

    // One-cycle response model for the local DDR interface.
    always @(posedge clk) begin
        if (rst) begin
            local_rsp_valid <= 1'b0;
        end else begin
            if (local_rsp_valid && ddr_rsp_ready)
                local_rsp_valid <= 1'b0;

            if (ddr_req_valid && ddr_req_ready && !uart_smoke_mode) begin
                local_rsp_valid   <= 1'b1;
                local_rsp_is_read <= !ddr_req_write;
                if (ddr_addr_valid) begin
                    if (ddr_req_write) begin
                        if (ddr_req_wstrb[0])
                            mem[ddr_word_addr][7:0] <= ddr_req_wdata[7:0];
                        if (ddr_req_wstrb[1])
                            mem[ddr_word_addr][15:8] <= ddr_req_wdata[15:8];
                        if (ddr_req_wstrb[2])
                            mem[ddr_word_addr][23:16] <= ddr_req_wdata[23:16];
                        if (ddr_req_wstrb[3])
                            mem[ddr_word_addr][31:24] <= ddr_req_wdata[31:24];
                    end else begin
                        local_rsp_rdata <= mem[ddr_word_addr];
                    end
                end else if (!ddr_req_write) begin
                    local_rsp_rdata <= 32'b0;
                end
            end
        end
    end

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1)
            mem[i] = 32'b0;

        program_file = "inst.txt";
        void'($value$plusargs("PROGRAM=%s", program_file));
        uart_smoke_mode = $test$plusargs("UART_SMOKE");
        camera_bad_frame_mode = $test$plusargs("CAMERA_BAD_FRAME");
        gpio_smoke_mode = $test$plusargs("GPIO_SMOKE");
        coremark_mode = $test$plusargs("COREMARK");
        coremark_startup_only = $test$plusargs("COREMARK_STARTUP_ONLY");
        if (coremark_mode && (uart_smoke_mode || gpio_smoke_mode))
            $fatal(1, "CoreMark mode cannot be combined with Camera/GPIO modes");
        gpio_sda_stuck_low = $test$plusargs("GPIO_SDA_STUCK_LOW");
        if (uart_smoke_mode && gpio_smoke_mode)
            $fatal(1, "Camera 与 GPIO 固件测试模式不能同时启用");
        if (camera_bad_frame_mode && !uart_smoke_mode)
            $fatal(1, "+CAMERA_BAD_FRAME 必须与 +UART_SMOKE 一起使用");
        uart_output = "";
        uart_pin_output = "";
        uart_expected_pin = 0;
        void'($value$plusargs("UART_PIN=%d", uart_expected_pin));
        if (uart_expected_pin != 0 && uart_expected_pin != 31)
            $fatal(1, "UART_PIN 只允许本地 0 或远程 31");
        uart_expected = {"=== Small Eyes Camera Bring-up ===\r\n\r\n",
                         "UART TEST OK\r\n",
                         "DDR INIT OK\r\n",
                         "CPU CLOCK   : 70000000 Hz\r\n",
                         "UART MMIO   : 0x40000000\r\n",
                         "SYSTEM READY\r\n",
                         "CAM1 probe...\r\n",
                         "CAM1 SCCB    : OK\r\n",
                         "CAM1 PIDH    : 0x00000056\r\n",
                         "CAM1 PIDL    : 0x00000040\r\n",
                         "CAM1 OV5640 : DETECTED\r\n",
                         "CAM1 RESET  : OK\r\n",
                         "CAM1 CONFIG : 640x480 RGB565\r\n",
                         "REG WRITE   : OK\r\n",
                         "CAM1 DMA    : ENABLED\r\n",
                         "CAM1 START  : OK\r\n"};
        if (gpio_smoke_mode)
            uart_expected = "=== CAM1 GPIO Toggle Test ===\r\n";
        if (coremark_mode)
            uart_expected = $sformatf("Start CoreMark CPU=70000000 Hz UART=115200 TX_FPIOA=%0d\r\n",
                                     uart_expected_pin);
        $display("PROGRAM=%s", program_file);
        $readmemh(program_file, mem);

        if (BRAM_MODE) begin
            // Keep CPU reset asserted while writing the program image through
            // the same synchronous port used by the flash boot controller.
            bram_prog_write = 1'b1;
            bram_prog_wstrb = 4'hf;
            for (bram_i = 0; bram_i < 8192; bram_i = bram_i + 1) begin
                @(negedge clk);
                bram_prog_valid = 1'b1;
                bram_prog_addr = 32'h8000_0000 + bram_i * 4;
                bram_prog_wdata = mem[bram_i];
                #1;
                if (!bram_prog_ready)
                    $fatal(1, "BRAM loader did not accept word %0d", bram_i);
                @(posedge clk);
            end
            @(negedge clk);
            bram_prog_valid = 1'b0;
            bram_prog_write = 1'b0;
        end

        $dumpfile("tb.vcd");
        $dumpvars(0, tb_Htop);

        cycle_count = 0;
        repeat (5) @(posedge clk);
        rst = 1'b0;
    end

    always @(posedge clk)
        if (!rst)
            cycle_count = cycle_count + 1;

    // 只在固件冒烟测试中运行 DVP 时钟，避免拖慢普通 ISA 回归。
    initial begin
        #1;
        if ($test$plusargs("UART_SMOKE")) begin
            forever #18 cam1_pclk = ~cam1_pclk;
        end
    end

    // 正例输出640x480；坏帧模式只少一行，仍按寄存器极性输出每行数据。
    initial begin : cam1_dvp_source
        integer line_index;
        integer byte_index;
        integer line_limit;
        reg [7:0] reg_4740;
        reg vsync_active_level;
        reg vsync_blank_level;
        reg href_active_level;
        reg href_blank_level;

        #1;
        if ($test$plusargs("UART_SMOKE")) begin
            wait (cam1_capture_enable === 1'b1);
            // 按本地应用指南4.2解释：bit0/bit1选择数据有效电平，bit5选择输出边沿。
            // 指南与数据手册的“active high/low”术语有冲突，故此模型只验证指南约定。
            reg_4740 = u_ov5640_model.register_file[16'h4740];
            if ((reg_4740 & 8'h23) != 8'h20)
                $fatal(1, "DVP 极性不符合应用指南4.2与接收器约定: 4740=%02x，期望mask23=20",
                       reg_4740);

            vsync_active_level = reg_4740[0];
            vsync_blank_level = ~reg_4740[0];
            href_active_level = ~reg_4740[1];
            href_blank_level = reg_4740[1];
            cam1_vsync = vsync_blank_level;
            cam1_href = href_blank_level;
            cam1_data = 8'b0;
            repeat (4) @(negedge cam1_pclk);
            cam1_vsync = vsync_active_level;
            repeat (2) @(negedge cam1_pclk);

            line_limit = camera_bad_frame_mode ? 479 : 480;

            for (line_index = 0; line_index < line_limit;
                 line_index = line_index + 1) begin
                cam1_href = href_active_level;
                for (byte_index = 0; byte_index < 1280;
                     byte_index = byte_index + 1) begin
                    cam1_data = (byte_index[0]) ? 8'h00 : 8'hf8;
                    @(negedge cam1_pclk);
                end
                cam1_href = href_blank_level;
                cam1_data = 8'b0;
                repeat (2) @(negedge cam1_pclk);
            end

            cam1_vsync = vsync_blank_level;
        end
    end

    always @(posedge cam1_pclk)
        if (!rst && uart_smoke_mode)
            camera_pclk_edge_count = camera_pclk_edge_count + 1;


    // The ISA tests write x26/x27 and finish with `jal x0, 0`. Check the
    // result when that terminal instruction reaches the writeback stage, so
    // both result registers have passed through the pipeline.
    always @(posedge clk) begin
        if (!rst && !uart_smoke_mode && !gpio_smoke_mode && !coremark_mode && ins === 32'h0000_006f) begin
            if (dut.u_idu.u_rf.rf[27] === 32'd1) begin
                $display("TEST_PASS");
                $display("cycle_count=%0d", cycle_count);
                $finish;
            end else begin
                $display("TEST_FAIL testnum=%0d", dut.u_idu.u_rf.rf[3]);
                $fatal(1, "TEST_FAIL");
            end
        end
    end

    // 先核对 TXDATA 与 Camera/DDR，再等待实际 FPIOA TX 脚接收完最后一个字节。
    always @(posedge clk) begin
        if (!rst && gpio_smoke_mode) begin
            if (cam1_reset_n || cam1_capture_enable || camera_axi_awvalid ||
                camera_axi_wvalid)
                $fatal(1, "GPIO 测试不得释放摄像头复位、采集或启动 DMA");
            if (cam1_mmio_sel && mmio_req_wen && mmio_req_ready &&
                (mmio_req_addr != 32'h4000_0300 || mmio_req_wdata[3:0] == 4'h0 ||
                 mmio_req_wdata[3] || mmio_req_wdata[0]))
                $fatal(1, "GPIO 测试出现非预期 Camera 寄存器写入");
        end
        if (!rst && uart_smoke_mode && fpioa_mmio_sel && mmio_req_wen)
            $display("FPIOA_WRITE addr=%08x data=%08x mask=%x",
                     mmio_req_addr, mmio_req_wdata, mmio_req_wstrb);
        if (!rst && (uart_smoke_mode || gpio_smoke_mode || coremark_mode) && mmio_req_valid && mmio_req_wen &&
            mmio_req_ready && (mmio_req_addr == 32'h4000_000c) &&
            mmio_req_wstrb[0]) begin
            if (u_fpioa.fpioa_ot_reg[uart_expected_pin] != 5'd7 ||
                u_fpioa.fpioa_ot_reg[31-uart_expected_pin] == 5'd7)
                $fatal(1, "UART 输出映射错误 expected=%0d local=%0d remote=%0d",
                       uart_expected_pin, u_fpioa.fpioa_ot_reg[0], u_fpioa.fpioa_ot_reg[31]);
            uart_output = {uart_output, byte'(mmio_req_wdata[7:0])};
            $write("%c", mmio_req_wdata[7:0]);
            if (uart_output.len() >= uart_expected.len() &&
                uart_output.substr(0, uart_expected.len()-1) != uart_expected)
                $fatal(1, "UART 初始化输出不符：%s", uart_output);
            if (coremark_mode && coremark_startup_only && uart_output == uart_expected)
                uart_fw_checks_done = 1'b1;
            if (coremark_mode && !coremark_startup_only && mmio_req_wdata[7:0] == 8'h0a &&
                contains(uart_output, "CoreMark/MHz\n")) begin
                // ITERATIONS=1 is an offline CRC/boot check, never a valid score.
                if (!contains(uart_output, "Iterations       : 1\n") ||
                    !contains(uart_output, "seedcrc          : 0xe9f5\n") ||
                    !contains(uart_output, "[0]crclist       : 0xe714\n") ||
                    !contains(uart_output, "[0]crcmatrix     : 0x1fd7\n") ||
                    !contains(uart_output, "[0]crcstate      : 0x8e3a\n") ||
                    !contains(uart_output, "ERROR! Must execute for at least 10 secs") ||
                    contains(uart_output, "ERROR! list crc") ||
                    contains(uart_output, "ERROR! matrix crc") ||
                    contains(uart_output, "ERROR! state crc") ||
                    contains(uart_output, "Total time (secs): 0.000000"))
                    $fatal(1, "CoreMark smoke CRC/timer check failed: %s", uart_output);
                uart_fw_checks_done = 1'b1;
            end
            if (uart_smoke_mode && !camera_bad_frame_mode &&
                mmio_req_wdata[7:0] == 8'h0a &&
                contains(uart_output, "CAM1 RELEASE MASK : 0x00000001 RELEASED\r\n")) begin
                if (!contains(uart_output, "CAM1 FRAME        : 1 (DVP 1)") ||
                    !contains(uart_output, "CAM1 LINES        : 480") ||
                    !contains(uart_output, "CAM1 PIXELS       : 307200") ||
                    !contains(uart_output, "CAM1 BYTES        : 614400") ||
                    !contains(uart_output, "CAM1 OVERFLOW     : 0 FIFO_ERROR=0x00000000 DVP_FLAGS=0x00000000") ||
                    !contains(uart_output, "CAM1 DMA DONE     : 1") ||
                    !contains(uart_output, "CAM1 DMA ERROR    : 0 CODE=0x00000000") ||
                    !contains(uart_output, "CAM1 FRAME ADDR   : 0xB8000000") ||
                    !contains(uart_output, "CAM1 CHECKSUM     : sum16 (not CRC32) 0x8A800000") ||
                    !contains(uart_output, "CAM1 DDR CHECKSUM : sum16 (not CRC32) 0x8A800000 MATCH=YES") ||
                    !contains(uart_output, "CAM1 RGB565 SAMPLES: 0x0000F800 0x0000F800 0x0000F800 0x0000F800 0x0000F800 0x0000F800 0x0000F800 0x0000F800") ||
                    u_camera_ddr.camera_writes != 19200)
                    $fatal(1, "UART/DDR 完整帧验收失败：%s", uart_output);
                uart_fw_checks_done = 1'b1;
            end

            if (camera_bad_frame_mode) begin
                if (count_occurrences(uart_output, camera_error_title) >
                    error_title_count) begin
                    error_title_count = count_occurrences(uart_output,
                                                          camera_error_title);
                    error_title_cycle = cycle_count;
                    error_snapshot_start = uart_output.len() -
                                           camera_error_title.len();
                    camera_error_snapshot = uart_output.substr(
                        error_snapshot_start, uart_output.len() - 1);
                    error_capture_active = 1'b1;
                    error_snapshot_complete = 1'b0;
                end else if (error_capture_active && !error_snapshot_complete) begin
                    camera_error_snapshot = {camera_error_snapshot,
                                             byte'(mmio_req_wdata[7:0])};
                end

                if (error_capture_active && !error_snapshot_complete &&
                    contains(camera_error_snapshot, "CAM1 FIFO ERRORS  :") &&
                    ends_with(camera_error_snapshot, "\r\n")) begin
                    error_snapshot_complete = 1'b1;
                    $display("CAMERA_BAD_FRAME_SNAPSHOT_COMPLETE titles=%0d cycle=%0d",
                             error_title_count, cycle_count);
                end
            end

            if (gpio_smoke_mode && mmio_req_wdata[7:0] == 8'h0a) begin
                gpio_line = uart_output.substr(gpio_line_start, uart_output.len()-1);
                gpio_line_start = uart_output.len();
                if (contains(gpio_line, "STEP=")) begin
                    case (gpio_step_count % 4)
                        1: begin
                            gpio_expected_status = gpio_sda_stuck_low ? 6'h10 : 6'h14;
                            gpio_expected_line = gpio_sda_stuck_low ?
                                "STEP=SCL_LOW CTRL=0x00000004 STATUS=0x00000010 RESET=0 SCL=0 SDA=0 MATCH=NO\r\n" :
                                "STEP=SCL_LOW CTRL=0x00000004 STATUS=0x00000014 RESET=0 SCL=0 SDA=1 MATCH=YES\r\n";
                        end
                        3: begin
                            gpio_expected_status = 6'h0a;
                            gpio_expected_line = "STEP=SDA_LOW CTRL=0x00000002 STATUS=0x0000000A RESET=0 SCL=1 SDA=0 MATCH=YES\r\n";
                        end
                        default: begin
                            gpio_expected_status = gpio_sda_stuck_low ? 6'h1a : 6'h1e;
                            gpio_expected_line = gpio_sda_stuck_low ?
                                "STEP=RELEASE CTRL=0x00000006 STATUS=0x0000001A RESET=0 SCL=1 SDA=0 MATCH=NO\r\n" :
                                "STEP=RELEASE CTRL=0x00000006 STATUS=0x0000001E RESET=0 SCL=1 SDA=1 MATCH=YES\r\n";
                        end
                    endcase
                    if (gpio_line != gpio_expected_line)
                        $fatal(1, "GPIO 状态行不符 expected=%s got=%s", gpio_expected_line, gpio_line);
                    if (cam1_scl !== gpio_expected_status[1] ||
                        cam1_sda !== gpio_expected_status[2])
                        $fatal(1, "GPIO 状态与实际引脚不符");
                    if (gpio_step_count > 0 &&
                        cycle_count - gpio_last_step_cycle < 35_000_000)
                        $fatal(1, "GPIO 保持时间不足 500 ms");
                    gpio_last_step_cycle = cycle_count;
                    gpio_step_count = gpio_step_count + 1;
                    if (gpio_step_count == 4) begin
                        if (!contains(uart_output, "HOLD MS     : 500\r\n"))
                            $fatal(1, "GPIO 缺少保持时间说明");
                        uart_fw_checks_done = 1'b1;
                    end
                end
            end
        end
    end

    // 让可能先到的DVP高度错误、后到的DMA像素错误都进入快照；从最后一份
    // 完整快照起静默观察至少1,000,000个CPU周期，再确认状态保持且无成功帧。
    initial begin : camera_bad_frame_report
        integer observed_title_count;
        integer pclk_edges_before;
        reg [31:0] stable_dvp_errors;
        reg [31:0] stable_dma_error_code;
        reg [31:0] stable_dma_current_pixels;
        reg [31:0] stable_dma_current_bytes;
        reg [31:0] stable_dma_current_lines;
        reg [31:0] stable_dvp_frame_count;
        reg [31:0] stable_dma_frame_count;
        reg [1:0] stable_dma_flags;
        reg [3:0] stable_fifo_flags;
        reg stable_dma_error;
        reg stable_dma_busy;
        reg [1:0] stable_ready_mask;

        wait (camera_bad_frame_mode && !rst);
        wait (error_snapshot_complete);
        forever begin
            observed_title_count = error_title_count;
            stable_dvp_errors = u_cam1.dvp_error_flags;
            stable_dma_error_code = u_cam1.dma_error_code;
            stable_dma_current_pixels = u_cam1.dma_current_pixel_count;
            stable_dma_current_bytes = u_cam1.dma_current_byte_count;
            stable_dma_current_lines = u_cam1.dma_current_line_count;
            stable_dvp_frame_count = u_cam1.dvp_frame_count;
            stable_dma_frame_count = u_cam1.dma_frame_count;
            stable_dma_flags = {u_cam1.dma_busy, u_cam1.dma_done};
            stable_fifo_flags = {u_cam1.token_collision,
                                 u_cam1.token_collision_sync,
                                 u_cam1.fifo_underflow,
                                 u_cam1.fifo_overflow_sync};
            stable_dma_error = u_cam1.dma_error;
            stable_ready_mask = u_cam1.dma_ready_mask;
            pclk_edges_before = camera_pclk_edge_count;

            repeat (1_000_000) @(posedge clk);
            if (error_title_count == observed_title_count &&
                error_snapshot_complete)
                break;
            wait (error_snapshot_complete);
        end

        if (!contains(camera_error_snapshot,
                      "CAM1 DMA ERROR    : 1 CODE=0x00000004") ||
            !contains(camera_error_snapshot,
                      "CAM1 OVERFLOW     : 0 FIFO_ERROR=0x00000000 DVP_FLAGS=0x00000004") ||
            !contains(camera_error_snapshot,
                      "CAM1 LINES        : 0 (current 479)") ||
            !contains(camera_error_snapshot,
                      "CAM1 PIXELS       : 0 (current 306560)") ||
            !contains(camera_error_snapshot,
                      "CAM1 BYTES        : 0 (current 613120)") ||
            !contains(camera_error_snapshot,
                      "CAM1 READY BUFFER : 0x00000000"))
            $fatal(1, "坏帧错误快照字段不符：%s", camera_error_snapshot);

        if (camera_pclk_edge_count - pclk_edges_before < 1000 ||
            u_cam1.dvp_error_flags !== stable_dvp_errors ||
            u_cam1.dma_error_code !== stable_dma_error_code ||
            u_cam1.dma_current_pixel_count !== stable_dma_current_pixels ||
            u_cam1.dma_current_byte_count !== stable_dma_current_bytes ||
            u_cam1.dma_current_line_count !== stable_dma_current_lines ||
            u_cam1.dvp_frame_count !== stable_dvp_frame_count ||
            u_cam1.dma_frame_count !== stable_dma_frame_count ||
            {u_cam1.dma_busy, u_cam1.dma_done} !== stable_dma_flags ||
            {u_cam1.token_collision, u_cam1.token_collision_sync,
             u_cam1.fifo_underflow, u_cam1.fifo_overflow_sync} !==
                stable_fifo_flags ||
            u_cam1.dma_error !== stable_dma_error ||
            u_cam1.dma_ready_mask !== stable_ready_mask)
            $fatal(1, "坏帧稳定观察期状态发生变化");

        if (u_cam1.dvp_error_flags !== 32'h0000_0004 ||
            u_cam1.dma_error_code !== 32'd4 ||
            u_cam1.dma_current_pixel_count !== 32'd306560 ||
            u_cam1.dma_current_byte_count !== 32'd613120 ||
            u_cam1.dma_current_line_count !== 32'd479 ||
            u_cam1.dvp_frame_count !== 32'd1 ||
            u_cam1.dma_frame_count !== 32'd0 ||
            u_cam1.dma_busy !== 1'b0 || u_cam1.dma_done !== 1'b0 ||
            u_cam1.dma_error !== 1'b1 ||
            u_cam1.dma_ready_mask !== 2'b00)
            $fatal(1, "坏帧DMA/DVP最终状态与预期不符");

        if (contains(uart_output, "CAM1 RELEASE MASK :") ||
            contains(uart_output, "CAM1 DDR CHECKSUM :") ||
            contains(uart_output, "CAM1 INVALID FRAME DESCRIPTOR"))
            $fatal(1, "坏帧被错误地当作成功帧处理");

        uart_fw_checks_done = 1'b1;
        while (uart_pin_output.len() != uart_output.len())
            @(posedge clk);
        repeat (UART_BIT_CYCLES) @(posedge clk);
        if (uart_pin_output.len() != uart_output.len())
            $fatal(1, "坏帧UART物理引脚输出未排空");
        $display("UART_PIN_PASS pin=%0d bytes=%0d",
                 uart_expected_pin, uart_pin_output.len());
        $display("CAMERA_BAD_FRAME_REPORT_PASS");
        $finish;
    end

    // 按 115200/8-N-1 从实际 TX 引脚独立解码，覆盖分频、位序和 FPIOA 路由。
    initial begin : uart_pin_receiver
        reg [7:0] rx_byte;
        integer bit_index;
        integer received_index;
        wait ((uart_smoke_mode || gpio_smoke_mode || coremark_mode) && !rst);
        forever begin
            @(negedge fpioa_pins[uart_expected_pin]);
            repeat (UART_BIT_CYCLES / 2) @(posedge clk);
            #1;
            if (fpioa_pins[uart_expected_pin] !== 1'b0)
                $fatal(1, "UART 起始位错误 pin=%0d", uart_expected_pin);
            for (bit_index=0; bit_index<8; bit_index=bit_index+1) begin
                repeat (UART_BIT_CYCLES) @(posedge clk);
                #1;
                rx_byte[bit_index] = fpioa_pins[uart_expected_pin];
            end
            repeat (UART_BIT_CYCLES) @(posedge clk);
            #1;
            if (fpioa_pins[uart_expected_pin] !== 1'b1)
                $fatal(1, "UART 停止位错误 pin=%0d", uart_expected_pin);
            received_index = uart_pin_output.len();
            if (received_index >= uart_output.len() ||
                rx_byte != 8'(uart_output[received_index]))
                $fatal(1, "UART 引脚解码不符 index=%0d byte=%02x", received_index, rx_byte);
            uart_pin_output = {uart_pin_output, byte'(rx_byte)};
            if (uart_fw_checks_done && !camera_bad_frame_mode &&
                uart_pin_output.len() == uart_output.len()) begin
                $display("UART_PIN_PASS pin=%0d bytes=%0d", uart_expected_pin, uart_pin_output.len());
                if (coremark_mode)
                    $display("COREMARK_FIRMWARE_PASS pin=%0d startup_only=%0d",
                             uart_expected_pin, coremark_startup_only);
                else if (gpio_smoke_mode)
                    $display("CAMERA_GPIO_FIRMWARE_PASS pin=%0d stuck_low=%0d steps=%0d",
                             uart_expected_pin, gpio_sda_stuck_low, gpio_step_count);
                else
                    $display("UART_FIRMWARE_PASS: Camera DMA/DDR samples/checksum/release");
                $finish;
            end
        end
    end

    initial begin
        timeout_cycles = 1000000;
        void'($value$plusargs("TIMEOUT=%d", timeout_cycles));
        repeat (timeout_cycles) @(posedge clk);
        if (uart_smoke_mode || gpio_smoke_mode || coremark_mode) begin
            $display("UART_CAPTURE_LEN=%0d EXPECTED_LEN=%0d",
                     uart_output.len(), uart_expected.len());
            $display("UART_CAPTURE=%s", uart_output);
        end
        $display("TEST_TIMEOUT");
        $fatal(1, "TEST_TIMEOUT");
    end

endmodule
