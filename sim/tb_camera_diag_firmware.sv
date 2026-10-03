`timescale 1ns / 1ps

module tb_camera_diag_firmware;
    integer cam1_report_count=0, cam2_report_count=0, running_report_count=0;
    string uart_current_line="";

    localparam MEM_WORDS = 16384;  // 64 KiB at DDR_BASE
    localparam [31:0] DDR_BASE = 32'h8000_0000;

    reg clk = 1'b0;
    reg rst = 1'b1;
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

    wire [29:0] cam1_axi_awaddr;
    wire [7:0] cam1_axi_awid;
    wire [7:0] cam1_axi_awlen;
    wire [2:0] cam1_axi_awsize;
    wire [1:0] cam1_axi_awburst;
    wire cam1_axi_awvalid;
    wire cam1_axi_awready;
    wire [255:0] cam1_axi_wdata;
    wire [31:0] cam1_axi_wstrb;
    wire cam1_axi_wlast;
    wire cam1_axi_wvalid;
    wire cam1_axi_wready;
    wire [7:0] cam1_axi_bid;
    wire [1:0] cam1_axi_bresp;
    wire cam1_axi_bvalid;
    wire cam1_axi_bready;
    wire [29:0] cam2_axi_awaddr;
    wire [7:0] cam2_axi_awid;
    wire [7:0] cam2_axi_awlen;
    wire [2:0] cam2_axi_awsize;
    wire [1:0] cam2_axi_awburst;
    wire cam2_axi_awvalid;
    wire cam2_axi_awready;
    wire [255:0] cam2_axi_wdata;
    wire [31:0] cam2_axi_wstrb;
    wire cam2_axi_wlast;
    wire cam2_axi_wvalid;
    wire cam2_axi_wready;
    wire [7:0] cam2_axi_bid;
    wire [1:0] cam2_axi_bresp;
    wire cam2_axi_bvalid;
    wire cam2_axi_bready;

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
    wire cam2_mmio_sel;
    wire [31:0] cam2_gpio_rdata, cam2_dvp_rdata;
    wire [31:0] cam2_mmio_rdata = cam2_gpio_rdata | cam2_dvp_rdata;
    tri1 cam2_scl, cam2_sda;
    wire cam2_reset_n, cam2_capture_enable;
    reg cam2_pclk = 0, cam2_vsync = 1, cam2_href = 0;
    reg [7:0] cam2_data = 0;
    // FPIOA多驱动/Z解析由Icarus保留脚测试覆盖；此Verilator平台直连DVP数据。
    integer released1 = 0, released2 = 0;
    wire cam1_mmio_sel;
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
    integer cycle_count;
    integer timeout_cycles;
    string program_file;
    bit uart_smoke_mode = 1'b1;
    bit camera_bad_frame_mode = 1'b0;
    bit gpio_smoke_mode = 1'b0;
    bit gpio_sda_stuck_low = 1'b0;
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
    integer cam1_axi_aw_count = 0;
    bit cam2_only_mode = 1'b0;
    bit cam2_input_stall = 1'b0;
    string diag_mode;
    integer cam1_dma_ever_enabled = 0;
    integer cam1_capture_ever_enabled = 0;
    bit cam1_report_fields_ok = 1'b0, cam2_report_fields_ok = 1'b0;
    bit cam1_disabled_report_seen = 1'b0, cam2_running_report_seen = 1'b0;
    bit cam1_running_report_seen = 1'b0;
    bit cam2_stalled_report_seen = 1'b0;
    bit cam2_stalled_evidence_ok = 1'b0;
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

    function automatic bit field_nonzero(input string value, input string field);
        integer offset, digit_offset, parsed;
        reg [7:0] character;
        begin
            field_nonzero = 1'b0;
            parsed = 0;
            for (offset=0; offset+field.len()<=value.len(); offset++) begin
                if (value.substr(offset,offset+field.len()-1)==field) begin
                    digit_offset=offset+field.len();
                    while (digit_offset<value.len()) begin
                        character=value[digit_offset];
                        if (character<8'd48 || character>8'd57) digit_offset=value.len();
                        else begin
                            parsed=parsed*10+integer'(character)-48;
                            digit_offset++;
                        end
                    end
                    if (parsed!=0) field_nonzero=1'b1;
                end
            end
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

    always @(posedge clk) if (!rst) begin
        if (cam1_capture_enable) cam1_capture_ever_enabled++;
        if (u_cam1.dma_enable) cam1_dma_ever_enabled++;
    end

    Htop dut (
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
		.bram_prog_valid(1'b0), .bram_prog_write(1'b0),
		.bram_prog_addr(32'b0), .bram_prog_wdata(32'b0),
		.bram_prog_wstrb(4'b0), .bram_prog_ready(), .bram_prog_rdata(),
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
    assign cam2_mmio_sel = mmio_req_valid &&
                           (mmio_req_addr >= 32'h4000_0400) &&
                           (mmio_req_addr <  32'h4000_0500);
    assign fpioa_mmio_sel = mmio_req_valid &&
                           (mmio_req_addr >= 32'h4000_0f00) &&
                           (mmio_req_addr <  32'h4000_1000);
    assign mmio_req_ready = uart_mmio_sel ? uart_mmio_ready : 1'b1;
    assign mmio_req_rdata = uart_mmio_sel ? uart_mmio_rdata :
                            cam1_mmio_sel ? cam1_mmio_rdata :
                            cam2_mmio_sel ? cam2_mmio_rdata :
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
    Hfpioa_simple #(.UART_TX_DEFAULT_FPIOA(0), .INPUT_ONLY_MASK(32'h3004_0000)) u_fpioa (
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
        .clk          (clk),
        .rst_n        (!rst),
        .mmio_valid   (cam2_mmio_sel),
        .mmio_wen     (mmio_req_wen),
        .mmio_addr    (mmio_req_addr[7:0]),
        .mmio_wdata   (mmio_req_wdata),
        .mmio_wmask   (mmio_req_wstrb),
        .mmio_rdata   (cam2_gpio_rdata),
        .cam1_scl     (cam2_scl),
        .cam1_sda     (cam2_sda),
        .cam1_reset_n (cam2_reset_n),
        .cam1_capture_enable(cam2_capture_enable)
    );

    Hcamera_subsystem #(
        .BUFFER0_ADDR(32'hb820_0000), .BUFFER1_ADDR(32'hb830_0000),
        .AXI_ID(8'h41)) u_cam2 (
        .consumer_ready_mask(), .consumer_frame0(), .consumer_frame1(),
        .consumer_release_valid(1'b0), .consumer_release_mask(2'b0),
        .cpu_clk(clk), .mem_clk(mem_clk), .rst_n(!rst),
        .ddr_ready(1'b1), .capture_enable(cam2_capture_enable),
        .pclk(cam2_pclk), .vsync(cam2_vsync), .href(cam2_href), .data(cam2_data),
        .mmio_valid(cam2_mmio_sel), .mmio_wen(mmio_req_wen),
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
    // 双Camera写事务先合并，再与CPU仲裁；响应始终按owner返回。
    Haxi_2m1s_arbiter u_stereo_merge (
        .clk(mem_clk), .rst_n(!rst),
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

    camera_ddr_model #(.FRAME_SLOTS(4)) u_camera_ddr (
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

    ov5640_sccb_model u_ov5640_model2 (
        .reset_n(cam2_reset_n), .scl(cam2_scl), .sda(cam2_sda)
    );

    initial begin
        uart_output = "";
        uart_pin_output = "";
        uart_expected_pin = 0;
        void'($value$plusargs("UART_PIN=%d", uart_expected_pin));
        if (uart_expected_pin != 0 && uart_expected_pin != 31)
            $fatal(1, "UART_PIN须为0或31");
        program_file = "";
        if (!$value$plusargs("PROGRAM=%s", program_file))
            $fatal(1, "缺少实际固件PROGRAM");
        cam2_only_mode = $test$plusargs("CAM2_ONLY");
        cam2_input_stall = $test$plusargs("CAM2_INPUT_STALL");
        diag_mode = cam2_only_mode ? "CAM2_ONLY" : "STEREO_DIAG";
        cycle_count = 0;
        repeat (5) @(posedge clk);
        rst = 0;
    end
    always @(posedge clk) if (!rst) cycle_count = cycle_count + 1;
    always #18 cam1_pclk = ~cam1_pclk;
    always #22 cam2_pclk = ~cam2_pclk;

    // 真实SCCB配置后按应用指南产生不同图案，两路PCLK互不相关。
    initial begin : source1
        integer f, y, x;
        wait(cam1_capture_enable);
        if ((u_ov5640_model.register_file[16'h4740] & 8'h23) != 8'h20)
            $fatal(1, "CAM1极性错误");
        repeat (4) @(negedge cam1_pclk);
        for (f=0; f<($test$plusargs("CAM2_INPUT_STALL") ? 150 :
                      ($test$plusargs("LONG_RUN") ? 60 : 8)); f++) begin
            cam1_vsync=0; repeat(2) @(negedge cam1_pclk);
            for(y=0;y<480;y++) begin
                cam1_href=1;
                for(x=0;x<1280;x++) begin
                    cam1_data=x[0] ? 8'h00 : 8'hf8;
                    @(negedge cam1_pclk);
                end
                cam1_href=0; cam1_data=0;
                repeat(2) @(negedge cam1_pclk);
            end
            cam1_vsync=1;
            repeat(10000) @(negedge cam1_pclk);
        end
    end
    initial begin : source2
        integer f, y, x;
        wait(cam2_capture_enable);
        if ((u_ov5640_model2.register_file[16'h4740] & 8'h23) != 8'h20)
            $fatal(1, "CAM2极性错误");
        repeat (7) @(negedge cam2_pclk);
        for (f=0; f<($test$plusargs("CAM2_INPUT_STALL") ? 3 :
                      ($test$plusargs("LONG_RUN") ? 60 : 8)); f++) begin
            cam2_vsync=0; repeat(2) @(negedge cam2_pclk);
            for(y=0;y<480;y++) begin
                cam2_href=1;
                for(x=0;x<1280;x++) begin
                    cam2_data=x[0] ? 8'he0 : 8'h07;
                    @(negedge cam2_pclk);
                end
                cam2_href=0; cam2_data=0;
                repeat(2) @(negedge cam2_pclk);
            end
            cam2_vsync=1;
            repeat(10000) @(negedge cam2_pclk);
        end
        if ($test$plusargs("CAM2_INPUT_STALL")) begin
            // 让传感器先送出一行，再停止 VSYNC/HREF；PCLK 时钟仍持续。
            cam2_vsync=0; repeat(2) @(negedge cam2_pclk);
            cam2_href=1;
            for(x=0;x<1280;x++) begin
                cam2_data=x[0] ? 8'he0 : 8'h07;
                @(negedge cam2_pclk);
            end
            cam2_href=0; cam2_data=0;
            forever @(negedge cam2_pclk);
        end
    end

    // CAM1 不会被 CAM2_ONLY 固件启用；直接统计专属 master 的地址握手，
    // 避免仅由帧计数推断没有发起 DMA。
    always @(posedge mem_clk) if (!rst && cam1_axi_awvalid && cam1_axi_awready)
        cam1_axi_aw_count++;

    // 观察真实CPU写mailbox，不伪造消费者或完成信号。
    always @(posedge clk) if (!rst && mmio_req_valid && mmio_req_wen) begin
        if (cam1_mmio_sel && mmio_req_addr[7:0]==8'h60 &&
            mmio_req_wdata[1:0]!=0) released1++;
        if (cam2_mmio_sel && mmio_req_addr[7:0]==8'h60 &&
            mmio_req_wdata[1:0]!=0) released2++;
        if (uart_mmio_sel && mmio_req_addr[7:0]==8'h0c &&
            mmio_req_ready && mmio_req_wstrb[0]) begin
            uart_output={uart_output,byte'(mmio_req_wdata[7:0])};
            $write("%c",mmio_req_wdata[7:0]);
            $fflush();
        end
    end

    initial begin : uart_pin_receiver
        reg [7:0] rx_byte;
        integer bit_index, received_index;
        wait(!rst);
        forever begin
            @(negedge fpioa_pins[uart_expected_pin]);
            repeat(UART_BIT_CYCLES/2) @(posedge clk); #1;
            if (fpioa_pins[uart_expected_pin]!==1'b0) $fatal(1,"UART起始位错误");
            for(bit_index=0;bit_index<8;bit_index++) begin
                repeat(UART_BIT_CYCLES) @(posedge clk); #1;
                rx_byte[bit_index]=fpioa_pins[uart_expected_pin];
            end
            repeat(UART_BIT_CYCLES) @(posedge clk); #1;
            if(fpioa_pins[uart_expected_pin]!==1'b1) $fatal(1,"UART停止位错误");
            received_index=uart_pin_output.len();
            if(received_index>=uart_output.len() ||
               rx_byte!=8'(uart_output[received_index])) $fatal(1,"UART物理解码不符");
            uart_pin_output={uart_pin_output,byte'(rx_byte)};
            if (rx_byte == 8'h0a) begin
                if (contains(uart_current_line,"CAM1 sec_ok=")) begin
                    cam1_report_count++;
                    if (contains(uart_current_line,"pclk_count=") &&
                        contains(uart_current_line,"pclk_delta=") &&
                        contains(uart_current_line,"seq=") &&
                        contains(uart_current_line,"seq_delta=") &&
                        contains(uart_current_line,"snap_valid=") &&
                        contains(uart_current_line,"fresh=") &&
                        contains(uart_current_line,"age_ms=") &&
                        contains(uart_current_line,"cur_dma_pixels=") &&
                        contains(uart_current_line,"cur_dma_bytes=") &&
                        contains(uart_current_line,"cur_dma_lines=") &&
                        contains(uart_current_line,"cap_en_live=") &&
                        contains(uart_current_line,"dma_en_live=") &&
                        contains(uart_current_line,"state="))
                        cam1_report_fields_ok=1'b1;
                    if (contains(uart_current_line,"state=DISABLED"))
                        cam1_disabled_report_seen=1'b1;
                    if (contains(uart_current_line,"state=RUNNING"))
                        cam1_running_report_seen=1'b1;
                end
                if (contains(uart_current_line,"CAM2 sec_ok=")) begin
                    cam2_report_count++;
                    if (contains(uart_current_line,"pclk_count=") &&
                        contains(uart_current_line,"pclk_delta=") &&
                        contains(uart_current_line,"seq=") &&
                        contains(uart_current_line,"seq_delta=") &&
                        contains(uart_current_line,"snap_valid=") &&
                        contains(uart_current_line,"fresh=") &&
                        contains(uart_current_line,"age_ms=") &&
                        contains(uart_current_line,"cur_dma_pixels=") &&
                        contains(uart_current_line,"cur_dma_bytes=") &&
                        contains(uart_current_line,"cur_dma_lines=") &&
                        contains(uart_current_line,"cap_en_live=") &&
                        contains(uart_current_line,"dma_en_live=") &&
                        contains(uart_current_line,"state="))
                        cam2_report_fields_ok=1'b1;
                    if (contains(uart_current_line,"state=RUNNING"))
                        cam2_running_report_seen=1'b1;
                    if (contains(uart_current_line,"state=STALLED")) begin
                        cam2_stalled_report_seen=1'b1;
                        if (contains(uart_current_line,"fresh=1") &&
                            field_nonzero(uart_current_line,"pclk_delta=") &&
                            field_nonzero(uart_current_line,"seq_delta=") &&
                            contains(uart_current_line,"dma_code=5"))
                            cam2_stalled_evidence_ok=1'b1;
                    end
                end
                if (contains(uart_current_line,"state=RUNNING")) running_report_count++;
                uart_current_line="";
            end else uart_current_line={uart_current_line,byte'(rx_byte)};
        end
    end

    initial begin : verify_diag
        integer word_index;
        wait(!rst);
        if (cam2_only_mode) begin
            // 不等待 CAM1 首帧：仅 CAM2 capture/DMA 应产生至少六个完成和释放。
            wait(u_cam2.u_dma.frame_count>=6 && released2>=6);
            if (cam1_capture_enable !== 1'b0 ||
                u_cam1.u_dma.frame_count != 0 || released1 != 0 ||
                cam1_axi_aw_count != 0 || cam1_dma_ever_enabled != 0 ||
                cam1_capture_ever_enabled != 0 || u_cam1.u_dma.error ||
                u_cam1.u_dma.dropped_frames != 0)
                $fatal(1,"CAM2_ONLY 下 CAM1 capture/DMA/release/AW 非零");
            // CAM1 的两个 1 MiB 槽均应保持 DDR 模型初始化值。
            for(word_index=0;word_index<524288;word_index++)
                if(u_camera_ddr.frame_mem[word_index]!==32'b0)
                    $fatal(1,"CAM2_ONLY 改写 CAM1 DDR word=%0d",word_index);
            for(word_index=0;word_index<153600;word_index++)
                if(u_camera_ddr.frame_mem[524288+word_index]!==32'h07e0_07e0)
                    $fatal(1,"CAM2_ONLY CAM2 DDR图像不符 word=%0d",word_index);
            if (u_cam2.u_dma.error || u_cam2.u_dma.dropped_frames != 0 ||
                u_cam2.u_dma.frame_checksum !== 32'h24ea_0000)
                $fatal(1,"CAM2_ONLY CAM2 DMA错误/丢帧/checksum不符");
        end else if (cam2_input_stall) begin
            wait(cam2_stalled_report_seen);
            if (!cam2_stalled_evidence_ok || u_cam2.u_dma.error_code != 32'd5 ||
                u_cam2.u_dma.frame_count != 3 || released2 != 3 ||
                u_cam2.u_dma.dropped_frames == 0 ||
                u_cam1.u_dma.frame_count < 70 || released1 < 70 ||
                u_cam1.u_dma.error || u_cam1.u_dma.dropped_frames != 0)
                $fatal(1,"CAM2输入停滞诊断证据/独立CAM1运行不符");
        end else begin
            wait(u_cam1.u_dma.frame_count>=6 && u_cam2.u_dma.frame_count>=6 &&
                 released1>=6 && released2>=6);
            // 静态图案保证即使正在写下一帧，已完成槽数据也可检查路由不串图。
            for(word_index=0;word_index<153600;word_index++) begin
                if(u_camera_ddr.frame_mem[word_index]!==32'hf800_f800)
                    $fatal(1,"CAM1完整DDR图像不符 word=%0d",word_index);
                if(u_camera_ddr.frame_mem[524288+word_index]!==32'h07e0_07e0)
                    $fatal(1,"CAM2完整DDR图像不符 word=%0d",word_index);
            end
            if(u_cam1.u_dma.error || u_cam2.u_dma.error ||
               u_cam1.u_dma.dropped_frames!=0 || u_cam2.u_dma.dropped_frames!=0)
                $fatal(1,"双路消费者仍产生DMA错误/丢帧");
            if(u_cam1.u_dma.frame_checksum!==32'h8a80_0000 ||
               u_cam2.u_dma.frame_checksum!==32'h24ea_0000)
                $fatal(1,"DMA校验和不符");
        end
        if(u_ov5640_model.write_count!=252 || u_ov5640_model2.write_count!=252)
            $fatal(1,"两路配置写入数量不符");
        wait(cam1_report_count>=1 && cam2_report_count>=1);
        if(!contains(uart_pin_output,"CAMERA_DIAG BOOT MODE=") ||
           !contains(uart_pin_output,{"CAMERA_DIAG BOOT MODE=",diag_mode}) ||
           !contains(uart_pin_output,"CAMERA_DIAG INITIAL_STATUS") ||
           !contains(uart_pin_output,"CAM1 sec_ok=") ||
           !contains(uart_pin_output,"CAM2 sec_ok="))
            $fatal(1,"诊断UART日志/启动模式缺失");
        if (!cam1_report_fields_ok || !cam2_report_fields_ok)
            $fatal(1,"诊断UART报告缺少快照/计数/实时DMA字段");
        if (cam2_only_mode) begin
            if (!contains(uart_pin_output,"CAM1 sec_ok=0") ||
                !cam1_disabled_report_seen || !cam2_running_report_seen)
                $fatal(1,"CAM2_ONLY UART状态不是 CAM1 DISABLED / CAM2 RUNNING");
            $display("\nCAMERA_DIAG_CAM2_ONLY_PASS pin=%0d CAM1_frames=0 CAM2_frames=%0d releases=0/%0d CAM2_sum=%08x bytes=%0d",
                uart_expected_pin,u_cam2.u_dma.frame_count,released2,
                u_cam2.u_dma.frame_checksum,uart_pin_output.len());
        end else if (cam2_input_stall) begin
            if (!cam1_running_report_seen || !cam2_stalled_report_seen ||
                !cam2_stalled_evidence_ok)
                $fatal(1,"CAM2停滞后UART没有报告真实STALLED及PCLK/序号进展");
            $display("\nCAMERA_DIAG_INPUT_STALL_PASS CAM2_frames=3 code=5 CAM1_frames=%0d releases=%0d pclk_seq_fresh=1",
                u_cam1.u_dma.frame_count,released1);
        end else begin
            if (!cam1_running_report_seen || !cam2_running_report_seen)
                $fatal(1,"双路诊断UART状态不是 CAM1/CAM2 RUNNING");
            $display("\nCAMERA_DIAG_STEREO_PASS pin=%0d frames=%0d/%0d releases=%0d/%0d checksums=%08x/%08x bytes=%0d",
                uart_expected_pin,u_cam1.u_dma.frame_count,u_cam2.u_dma.frame_count,
                released1,released2,u_cam1.u_dma.frame_checksum,
                u_cam2.u_dma.frame_checksum,uart_pin_output.len());
        end
        $finish;
    end


    initial begin
        timeout_cycles=120000000;
        void'($value$plusargs("TIMEOUT=%d",timeout_cycles));
        repeat(timeout_cycles) @(posedge clk);
        $display("UART_CAPTURE=%s",uart_output);
        $fatal(1,"Camera诊断固件超时");
    end
endmodule
