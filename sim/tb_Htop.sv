`timescale 1ns / 1ps

module tb_Htop;

    localparam MEM_WORDS = 16384;  // 64 KiB at DDR_BASE
    localparam [31:0] DDR_BASE = 32'h8000_0000;

    reg clk = 1'b0;
    reg rst = 1'b1;

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
    wire [15:0] cam1_pixel_data;
    wire        cam1_pixel_valid;
    wire        cam1_frame_start;
    wire        cam1_frame_end;
    wire        cam1_line_valid;
    wire        cam1_snapshot_req;
    wire        cam1_snapshot_ack;
    wire [31:0] cam1_snapshot_frames;
    wire [31:0] cam1_snapshot_pixels;
    wire [31:0] cam1_snapshot_lines;
    wire [31:0] cam1_snapshot_pclks;
    wire [31:0] cam1_snapshot_errors;
    wire [4:0]  cam1_snapshot_seen;

    wire        ddr_req_valid;
    wire        ddr_req_ready = 1'b1;
    wire        ddr_req_write;
    wire [31:0] ddr_req_addr;
    wire [31:0] ddr_req_wdata;
    wire [3:0]  ddr_req_wstrb;
    wire        ddr_rsp_ready;
    reg         ddr_rsp_valid = 1'b0;
    reg         ddr_rsp_is_read = 1'b0;
    reg  [31:0] ddr_rsp_rdata = 32'b0;

    reg [31:0] mem [0:MEM_WORDS-1];
    wire [31:0] ddr_word_addr = (ddr_req_addr - DDR_BASE) >> 2;
    wire        ddr_addr_valid = (ddr_req_addr >= DDR_BASE) &&
                                 (ddr_word_addr < MEM_WORDS);

    integer i;
    integer cycle_count;
    integer timeout_cycles;
    string program_file;
    bit uart_smoke_mode;
    string uart_output;
    string uart_expected;

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

    always #5 clk = ~clk;

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
    assign mmio_req_ready = uart_mmio_sel ? uart_mmio_ready : 1'b1;
    assign mmio_req_rdata = uart_mmio_sel ? uart_mmio_rdata :
                            cam1_mmio_sel ? cam1_mmio_rdata : 32'b0;

    Huart_tx #(
        .CLK_HZ(90_000_000),
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

    Hcamera_dvp_rx u_cam1_dvp_rx (
        .pclk                       (cam1_pclk),
        .rst_n                      (!rst),
        .capture_enable_async       (cam1_capture_enable),
        .vsync                      (cam1_vsync),
        .href                       (cam1_href),
        .data                       (cam1_data),
        .pixel_data                 (cam1_pixel_data),
        .pixel_valid                (cam1_pixel_valid),
        .frame_start                (cam1_frame_start),
        .frame_end                  (cam1_frame_end),
        .line_valid                 (cam1_line_valid),
        .snapshot_req_toggle_async  (cam1_snapshot_req),
        .snapshot_ack_toggle        (cam1_snapshot_ack),
        .snapshot_frame_count       (cam1_snapshot_frames),
        .snapshot_last_frame_pixels (cam1_snapshot_pixels),
        .snapshot_last_frame_lines  (cam1_snapshot_lines),
        .snapshot_pclk_count        (cam1_snapshot_pclks),
        .snapshot_error_flags       (cam1_snapshot_errors),
        .snapshot_seen_flags        (cam1_snapshot_seen)
    );

    Hcamera_dvp_regs u_cam1_dvp_regs (
        .clk                              (clk),
        .rst_n                            (!rst),
        .mmio_valid                       (cam1_mmio_sel),
        .mmio_wen                         (mmio_req_wen),
        .mmio_addr                        (mmio_req_addr[7:0]),
        .mmio_wdata                       (mmio_req_wdata),
        .mmio_wmask                       (mmio_req_wstrb),
        .capture_enable                   (cam1_capture_enable),
        .snapshot_req_toggle              (cam1_snapshot_req),
        .snapshot_ack_toggle_async        (cam1_snapshot_ack),
        .snapshot_frame_count_async       (cam1_snapshot_frames),
        .snapshot_last_frame_pixels_async (cam1_snapshot_pixels),
        .snapshot_last_frame_lines_async  (cam1_snapshot_lines),
        .snapshot_pclk_count_async        (cam1_snapshot_pclks),
        .snapshot_error_flags_async       (cam1_snapshot_errors),
        .snapshot_seen_flags_async        (cam1_snapshot_seen),
        .mmio_rdata                       (cam1_dvp_rdata)
    );

    ov5640_sccb_model u_ov5640_model (
        .reset_n (cam1_reset_n),
        .scl     (cam1_scl),
        .sda     (cam1_sda)
    );

    // One-cycle response model for the local DDR interface.
    always @(posedge clk) begin
        if (rst) begin
            ddr_rsp_valid <= 1'b0;
        end else begin
            if (ddr_rsp_valid && ddr_rsp_ready)
                ddr_rsp_valid <= 1'b0;

            if (ddr_req_valid && ddr_req_ready) begin
                ddr_rsp_valid   <= 1'b1;
                ddr_rsp_is_read <= !ddr_req_write;
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
                        ddr_rsp_rdata <= mem[ddr_word_addr];
                    end
                end else if (!ddr_req_write) begin
                    ddr_rsp_rdata <= 32'b0;
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
        uart_output = "";
        uart_expected = {"=== Small Eyes Camera Bring-up ===\r\n\r\n",
                         "UART TEST OK\r\n",
                         "DDR INIT OK\r\n",
                         "CPU CLOCK   : 90000000 Hz\r\n",
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
                         "CAM1 START  : OK\r\n",
                         "CAM1 STATUS : 0x0000001F\r\n",
                         "CAM1 FRAMES : 1\r\n",
                         "CAM1 PIXELS : 307200\r\n",
                         "CAM1 LINES  : 480\r\n",
                         "CAM1 ERRORS : 0x00000000\r\n"};
        $display("PROGRAM=%s", program_file);
        $readmemh(program_file, mem);

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

    // 模拟一帧 640x480 RGB565。每行 1280 字节，高字节先输出。
    initial begin : cam1_dvp_source
        integer line_index;
        integer byte_index;

        #1;
        if ($test$plusargs("UART_SMOKE")) begin
            wait (cam1_capture_enable === 1'b1);
            repeat (4) @(negedge cam1_pclk);
            cam1_vsync = 1'b0;
            repeat (2) @(negedge cam1_pclk);

            for (line_index = 0; line_index < 480;
                 line_index = line_index + 1) begin
                cam1_href = 1'b1;
                for (byte_index = 0; byte_index < 1280;
                     byte_index = byte_index + 1) begin
                    cam1_data = (byte_index[0]) ? 8'h00 : 8'hf8;
                    @(negedge cam1_pclk);
                end
                cam1_href = 1'b0;
                cam1_data = 8'b0;
                repeat (2) @(negedge cam1_pclk);
            end

            cam1_vsync = 1'b1;
        end
    end

    always @(posedge cam1_pclk) begin
        if (uart_smoke_mode && cam1_frame_end)
            $display("CAM1_DVP_FRAME_END pixels=%0d lines=%0d cycle=%0d",
                     u_cam1_dvp_rx.last_frame_pixels,
                     u_cam1_dvp_rx.last_frame_lines, cycle_count);
    end

    // The ISA tests write x26/x27 and finish with `jal x0, 0`. Check the
    // result when that terminal instruction reaches the writeback stage, so
    // both result registers have passed through the pipeline.
    always @(posedge clk) begin
        if (!rst && !uart_smoke_mode && ins === 32'h0000_006f) begin
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

    // 固件冒烟测试逐字节核对 UART0 TXDATA；波特率发生器与板级引脚由
    // Huart_tx 和最终 PDS review 另行覆盖。
    always @(posedge clk) begin
        if (!rst && uart_smoke_mode && mmio_req_valid && mmio_req_wen &&
            mmio_req_ready && (mmio_req_addr == 32'h4000_000c) &&
            mmio_req_wstrb[0]) begin
            uart_output = {uart_output, byte'(mmio_req_wdata[7:0])};
            $write("%c", mmio_req_wdata[7:0]);
            if (uart_output.len() == uart_expected.len()) begin
                if (uart_output == uart_expected) begin
                    $display("UART_FIRMWARE_PASS");
                    $finish;
                end else begin
                    $display("UART_FIRMWARE_FAIL");
                    $display("EXPECTED=%s", uart_expected);
                    $display("ACTUAL=%s", uart_output);
                    $fatal(1, "UART byte stream mismatch");
                end
            end
        end
    end

    initial begin
        timeout_cycles = 1000000;
        void'($value$plusargs("TIMEOUT=%d", timeout_cycles));
        repeat (timeout_cycles) @(posedge clk);
        if (uart_smoke_mode) begin
            $display("UART_CAPTURE_LEN=%0d EXPECTED_LEN=%0d",
                     uart_output.len(), uart_expected.len());
            $display("UART_CAPTURE=%s", uart_output);
        end
        $display("TEST_TIMEOUT");
        $fatal(1, "TEST_TIMEOUT");
    end

endmodule
