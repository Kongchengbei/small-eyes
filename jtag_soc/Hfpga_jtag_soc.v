`timescale 1ns / 1ps

// Board-facing top for the official Pango JTAG flow.
// hard_rst_n is active-low, matching the supplied board constraints.
module Hfpga_jtag_soc #(
    parameter IMEM_BYTES = 32 * 1024,
    parameter DMEM_BYTES = 16 * 1024,
    parameter MEM_FILE   = `PROG_FPGA_PATH
) (
    input  clk,
    input  hard_rst_n,
    input  JTAG_TCK,
    input  JTAG_TMS,
    input  JTAG_TDI,
    output JTAG_TDO,
    output core_active,
    inout  [31:0] fpioa
);
 
	wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    // 属性必须写成 Verilog-2001 前置形式 (* ... *)。
    // 尾置的 /* synthesis ... */ 注释形式 Synplify 只对标量生效，
    // 多位向量在综合时属性会被丢掉（syn.vm 里 pc/ins/dmem_addr 就没有标记），
    // 结果是 Fabric Inserter 里这几条总线不会被自动列出来。
    (* PAP_MARK_DEBUG="<0/t5/0>" *) wire        dmem_valid;
    (* PAP_MARK_DEBUG="<0/t6/0>" *) wire        dmem_wen;
    (* PAP_MARK_DEBUG="<0/t2/0>" *) wire [31:0] dmem_addr;
    (* PAP_MARK_DEBUG="<0/t3/0>" *) wire [31:0] dmem_wdata;
    (* PAP_MARK_DEBUG="<0/t4/0>" *) wire [3:0]  dmem_wmask;
    wire [31:0] dmem_rdata;
    wire [31:0] ram_dmem_rdata;
    (* PAP_MARK_DEBUG="<0/t0/0>" *) wire [31:0] pc;
    (* PAP_MARK_DEBUG="<0/t1/0>" *) wire [31:0] ins;
    wire        is_ebreak;
/*Data channel 0~31     : pc
Data channel 32~63    : ins
Data channel 64~95    : dmem_addr
Data channel 96~127   : dmem_wdata
Data channel 128~131  : dmem_wmask
Data channel 132       : dmem_wen
Data channel 133       : dmem_valid
*/


   wire ram_dmem_valid = dmem_valid && !mmio_valid;
   wire ram_dmem_wen   = ram_dmem_valid && dmem_wen;

    wire        jtag_cmd_valid;
    wire        jtag_cmd_ready;
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

    localparam UART0_BASE = 32'h4000_0000;
    localparam UART0_END  = 32'h4000_0100;
    localparam LED_ADDR   = 32'h4000_0200;
    wire mmio_valid = dmem_valid && (dmem_addr[31:28] == 4'h4);
    wire uart_sel = mmio_valid &&
                    (dmem_addr >= UART0_BASE) && (dmem_addr < UART0_END);
	wire uart_ready;
    // RAM 和其他外设都是当拍完成，只有 UART 会反压
    wire dmem_ready = uart_sel ? uart_ready : 1'b1;
	wire led_sel = mmio_valid && (dmem_addr == LED_ADDR);
    wire fpioa_sel = mmio_valid &&
                     (dmem_addr >= 32'h4000_0f00) &&
                     (dmem_addr <  32'h4000_1000);
    wire led_wr = led_sel && dmem_wen;
    wire [31:0] uart_rdata;
    wire [31:0] fpioa_rdata;
    wire [3:0] led_value;
    wire uart_tx;

	wire cpu_clk/* synthesis PAP_MARK_DEBUG="<0/c0/0>" */;
	wire pll_locked;

	clk_pll u_pll (
	    .clkin1  (clk),
	    .clkout0(cpu_clk),
	    .lock   (pll_locked)
	);

	// ---------------- 复位控制 ----------------
	// hard_rst_n(外部按键) 与 pll_locked 都与 cpu_clk 异步。
	// 原写法 sys_rst_n = hard_rst_n && pll_locked，再由它组合出同步复位 cpu_rst，
	// 等于把一个异步信号当同步复位用：它可以在任意时刻跳变，五级流水各级的触发器
	// 可能在同一个时钟沿上采到不同的值，出现 ex_valid=1 而 id_valid=0 这类不一致
	// 状态 —— EX 里就多出一条带着旧 ex_is_store 的幽灵指令。
	// 单周期设计只有一组状态，不会暴露这个问题；流水线必须保证各级同拍复位、同拍释放。
	// 因此这里做"异步置位、同步释放"：断言不依赖时钟(PLL 未锁时同样有效)，
	// 释放沿由 cpu_clk 打两拍对齐，各级触发器必然在同一个沿上一起解除复位。
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

	// CPU 比外设多复位 16 拍：等存储器与 JTAG 的状态机先就绪，再放 CPU 去取指
	reg [3:0] cpu_rst_cnt;
	always @(posedge cpu_clk) begin
	    if (!sys_rst_n)               cpu_rst_cnt <= 4'd0;
	    else if (cpu_rst_cnt != 4'hF) cpu_rst_cnt <= cpu_rst_cnt + 4'd1;
	end

	// jtag_reset_req / jtag_halt_req 只复位 CPU，不能并进 sys_rst_n ——
	// fpga_unified_memory_jtag 的 jtag_cmd_ready 依赖 rst_n( 98 line)
	// 一旦折进全局复位，JTAG 下载器在 CPU 停住时就无法访问 imem
	// 这两个信号来自 jtag_dm，已是 cpu_clk 域的寄存器输出，无需再同步
	wire cpu_rst = !sys_rst_n || (cpu_rst_cnt != 4'hF) ||
	               jtag_reset_req || jtag_halt_req;

	// Match the board template: JTAG_TCK enters through the vendor input
    // buffer before it is used as the JTAG clock.
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


    // The CPU has no debug halt input yet. Holding it in reset during a JTAG
    // session gives the loader exclusive access to instruction memory.


    Htop u_cpu (
        .clk        (cpu_clk),
        .rst        (cpu_rst),
        .imem_addr  (imem_addr),
        .imem_rdata (imem_rdata),
        .dmem_valid (dmem_valid),
        .dmem_wen   (dmem_wen),
        .dmem_addr  (dmem_addr),
        .dmem_wdata (dmem_wdata),
        .dmem_wmask (dmem_wmask),
        .dmem_rdata (dmem_rdata),
		.dmem_ready  (dmem_ready),
        .pc         (pc),
        .ins        (ins),
        .is_ebreak  (is_ebreak)
    );

	fpga_unified_memory_jtag #(
	    .IMEM_BASE  (32'h0000_0000),
	    .DMEM_BASE  (32'h2000_0000),
	    .IMEM_BYTES (IMEM_BYTES),
	    .DMEM_BYTES (DMEM_BYTES)
	) u_memory (
	    .clk             (cpu_clk),
	    .rst_n           (sys_rst_n),
	
	    .cpu_imem_addr  (imem_addr),
	    .cpu_imem_rdata (imem_rdata),
	
	    .cpu_dmem_addr  (dmem_addr),
	    .cpu_dmem_rdata (ram_dmem_rdata),
	    .cpu_dmem_valid (ram_dmem_valid),
	    .cpu_dmem_wen   (ram_dmem_wen),
	    .cpu_dmem_wdata (dmem_wdata),
	    .cpu_dmem_wmask (dmem_wmask),
	
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

    Hled #(.WIDTH(4)) u_led (
        .clk     (cpu_clk),
        .rst_n   (sys_rst_n),
        .wr_en   (led_wr),
        .wr_data (dmem_wdata),
        .wr_mask (dmem_wmask),
        .led     (led_value)
    );

    Huart_tx #(
    	.CLK_HZ(70_000_000)
	)u_uart0_tx (
        .clk        (cpu_clk),
        .rst_n      (sys_rst_n),
        .mmio_valid (uart_sel),
        .mmio_wen   (dmem_wen),
        .mmio_addr  (dmem_addr[7:0]),
        .mmio_wdata (dmem_wdata),
        .mmio_wmask (dmem_wmask),
        .mmio_rdata (uart_rdata),
		.mmio_ready  (uart_ready),
        .tx_pin     (uart_tx)
    );

    Hfpioa_simple u_fpioa (
        .clk        (cpu_clk),
        .rst_n      (sys_rst_n),
        .mmio_valid (fpioa_sel),
        .mmio_wen   (dmem_wen),
        .mmio_addr  (dmem_addr[7:0]),
        .mmio_wdata (dmem_wdata),
        .mmio_wmask (dmem_wmask),
        .mmio_rdata (fpioa_rdata),
        .uart0_tx   (uart_tx),
        .direct_led (led_value),
        .fpioa      (fpioa)
    );

	wire mmio_read = mmio_valid && !dmem_wen;

	wire [31:0] mmio_rdata_now = uart_sel  ? uart_rdata        :
	                             led_sel   ? {28'b0, led_value}:
	                             fpioa_sel ? fpioa_rdata       :
	                			 32'b0;

	reg        mmio_read_reg;
	reg [31:0] mmio_rdata_reg;

	always @(posedge cpu_clk) begin
	    if (cpu_rst) begin
	        mmio_read_reg  <= 1'b0;
	        mmio_rdata_reg <= 32'b0;
	    end else begin
	        mmio_read_reg <= mmio_read;

	        if (mmio_read)
	            mmio_rdata_reg <= mmio_rdata_now;
	    end
	end

    assign dmem_rdata = mmio_read_reg ? mmio_rdata_reg : ram_dmem_rdata;

    assign core_active = !cpu_rst && !is_ebreak;

endmodule
