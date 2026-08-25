`timescale 1ns / 1ps

module fpga_unified_memory_jtag #(
    parameter IMEM_BASE  = 32'h0000_0000,
    parameter DMEM_BASE  = 32'h2000_0000,
    parameter IMEM_BYTES = 32 * 1024,
    parameter DMEM_BYTES = 16 * 1024
) (
    input         clk,
	input         rst_n,

    input       [31:0] cpu_imem_addr,
    output wire [31:0] cpu_imem_rdata,
    input       [31:0] cpu_dmem_addr,
    output wire [31:0] cpu_dmem_rdata,
    input         cpu_dmem_wen,

	input         cpu_dmem_valid,
    input  [31:0] cpu_dmem_wdata,
    input  [3:0]  cpu_dmem_wmask,

    input         jtag_cmd_valid,
    output        jtag_cmd_ready,
    input  [31:0] jtag_cmd_addr,
    input         jtag_cmd_read,
    input  [31:0] jtag_cmd_wdata,
    input  [3:0]  jtag_cmd_wmask,
    output reg    jtag_rsp_valid,
    input         jtag_rsp_ready,
    output        jtag_rsp_err,
    output reg [31:0] jtag_rsp_rdata
);
	localparam IMEM_AW = 13;
	localparam DMEM_AW = 12;

	wire [31:0] imem_a_rdata;
	wire [31:0] imem_b_rdata;
	wire [31:0] dmem_a_rdata;
	wire [31:0] dmem_b_rdata;

	wire [12:0] imem_a_addr = (cpu_imem_addr - IMEM_BASE) >> 2;
	wire [11:0] dmem_a_addr = (cpu_dmem_addr - DMEM_BASE) >> 2;
	wire cpu_dmem_imem_range =
    (cpu_dmem_addr >= IMEM_BASE) &&
    (cpu_dmem_addr < IMEM_BASE + IMEM_BYTES);
	// JTAG操作时由JTAG占用IMEM B口；正常运行时供CPU读取.data装载镜像
	wire [12:0] imem_b_addr =
    	jtag_cmd_valid
    	? ((jtag_cmd_addr - IMEM_BASE) >> 2)
    	: ((cpu_dmem_addr - IMEM_BASE) >> 2);
	wire [11:0] dmem_b_addr = (jtag_cmd_addr - DMEM_BASE) >> 2;

	//地址选择逻辑
	wire cpu_imem_in_range = (cpu_imem_addr >= IMEM_BASE) &&
						     (cpu_imem_addr <  IMEM_BASE + IMEM_BYTES);

	wire cpu_dmem_in_range = (cpu_dmem_addr >= DMEM_BASE) &&
						     (cpu_dmem_addr < DMEM_BASE + DMEM_BYTES);

	wire jtag_imem_sel =(jtag_cmd_addr[1:0] == 2'b00) &&
	    				(jtag_cmd_addr >= IMEM_BASE)  &&
	    				(jtag_cmd_addr < IMEM_BASE + IMEM_BYTES);

	wire jtag_dmem_sel = (jtag_cmd_addr[1:0] == 2'b00) &&
	    				 (jtag_cmd_addr >= DMEM_BASE)  &&
	    				 (jtag_cmd_addr < DMEM_BASE + DMEM_BYTES);


	assign cpu_imem_rdata = cpu_imem_in_range ? imem_a_rdata : 32'h0000_0013;
	assign cpu_dmem_rdata = cpu_dmem_imem_range ? imem_b_rdata : 
						    cpu_dmem_in_range ? dmem_a_rdata : 32'b0;

	//JTAG 握手信号
	reg jtag_read_pending;
	reg jtag_pending_imem;
	reg jtag_pending_err;
	reg jtag_rsp_err_reg;

	wire jtag_cmd_fire    = jtag_cmd_valid && jtag_cmd_ready;
	wire jtag_read_fire   = jtag_cmd_fire && jtag_cmd_read;
	wire jtag_write_fire  = jtag_cmd_fire && !jtag_cmd_read;
	assign jtag_cmd_ready = rst_n && !jtag_read_pending && !jtag_rsp_valid;
	assign jtag_rsp_err = jtag_rsp_valid && jtag_rsp_err_reg;

	wire imem_b_wr_en = jtag_write_fire && jtag_imem_sel;
	wire dmem_b_wr_en = jtag_write_fire && jtag_dmem_sel;
	wire dmem_a_wr_en = cpu_dmem_valid && cpu_dmem_wen && cpu_dmem_in_range;


	imem u_imem (
		.a_addr       (imem_a_addr),
		.a_wr_data    (32'b0),
		.a_rd_data    (imem_a_rdata),
		.a_wr_en      (1'b0),
		.a_wr_byte_en (4'b0000),
		.a_clk        (clk),
		.a_rst        (1'b0),

		.b_addr       (imem_b_addr),
		.b_wr_data    (jtag_cmd_wdata),
		.b_rd_data    (imem_b_rdata),
		.b_wr_en      (imem_b_wr_en),
		.b_wr_byte_en (jtag_cmd_wmask),
		.b_clk        (clk),
		.b_rst        (1'b0)
	);

	dmem u_dmem (
	    .a_addr       (dmem_a_addr),
	    .a_wr_data    (cpu_dmem_wdata),
	    .a_rd_data    (dmem_a_rdata),
	    .a_wr_en      (dmem_a_wr_en),
	    .a_wr_byte_en (cpu_dmem_wmask),
	    .a_clk        (clk),
	    .a_rst        (1'b0),

	    .b_addr       (dmem_b_addr),
	    .b_wr_data    (jtag_cmd_wdata),
	    .b_rd_data    (dmem_b_rdata),
	    .b_wr_en      (dmem_b_wr_en),
	    .b_wr_byte_en (jtag_cmd_wmask),
	    .b_clk        (clk),
	    .b_rst        (1'b0)
	);


	//JTAG 同步读状态机
	always @(posedge clk or negedge rst_n) begin
	    if (!rst_n) begin
	        jtag_read_pending <= 1'b0;
	        jtag_pending_imem <= 1'b0;
	        jtag_pending_err  <= 1'b0;
	        jtag_rsp_valid    <= 1'b0;
	        jtag_rsp_rdata    <= 32'b0;
	        jtag_rsp_err_reg  <= 1'b0;
	    end else begin
	        if (jtag_read_fire) begin
	            jtag_read_pending <= 1'b1;
	            jtag_pending_imem <= jtag_imem_sel;
	            jtag_pending_err  <= !(jtag_imem_sel || jtag_dmem_sel);
	        end else if (jtag_read_pending) begin
	            jtag_read_pending <= 1'b0;
	            jtag_rsp_valid    <= 1'b1;
	            jtag_rsp_err_reg  <= jtag_pending_err;

	            if (jtag_pending_imem)
	                jtag_rsp_rdata <= imem_b_rdata;
	            else if (!jtag_pending_err)
	                jtag_rsp_rdata <= dmem_b_rdata;
	            else
	                jtag_rsp_rdata <= 32'b0;
	        end else if (jtag_rsp_valid && jtag_rsp_ready) begin
	            jtag_rsp_valid   <= 1'b0;
	            jtag_rsp_err_reg <= 1'b0;
	        end
	    end
	end

endmodule
