`timescale 1ns / 1ps

module Hcsr (
	input         clk,
	input         rst, 

	input         csr_valid,
	input  [2:0]  csr_op,
	input  [11:0] csr_addr,
	input  [31:0] csr_rs1_data,
	input  [4:0]  csr_imm,

	input         is_ecall,
	input         is_mret,
	input  [31:0] current_pc,

	output wire [31:0] csr_rdata,
	output wire        redirect_valid,
	output wire [31:0] redirect_pc
);

	reg [31:0] csr_mstatus;
	reg [31:0] csr_mie;
	reg [31:0] csr_mepc;
	reg [31:0] csr_mtvec;
	reg [31:0] csr_mcause;
	reg [63:0] csr_mtime;
	reg [63:0] csr_mtimecmp;
	reg [63:0] csr_minstret;
	reg [4:0]  csr_mcctr;

	localparam [31:0] CSR_MVENDORID_VALUE = 32'h0011_4514;
	localparam [31:0] CSR_MIMPID_VALUE    = 32'h1020_1B58; //低15位是7000
	wire timer_pending  = (csr_mtime >= csr_mtimecmp);
	wire [31:0] csr_mip = {20'b0, 1'b0, 3'b0, timer_pending, 3'b0, 1'b0, 3'b0};

	reg csr_wen;
	reg [31:0] csr_read_data;
	reg [31:0] csr_write_data;
	wire [31:0] csr_src = csr_op[2] ? {27'b0,csr_imm} : csr_rs1_data; //csr 指令的源操作数，立即数或 rs1 数据,只有funct3[2]为1的指令（csrrwi/csrrsi/csrrci）才使用立即数
	always @(*)begin
		case (csr_addr)
			12'h300: csr_read_data = csr_mstatus;
			12'h301: csr_read_data = 32'h4000_0100;
			12'h304: csr_read_data = csr_mie;
			12'h305: csr_read_data = csr_mtvec;
			12'h340: csr_read_data = 32'b0;
			12'h341: csr_read_data = csr_mepc;
			12'h342: csr_read_data = csr_mcause;
			12'h343: csr_read_data = 32'b0;
			12'h344: csr_read_data = csr_mip;
			12'h345: csr_read_data = 32'b0;
			12'hB02: csr_read_data = csr_minstret[31:0];
			12'hB82: csr_read_data = csr_minstret[63:32];
			12'hB03: csr_read_data = csr_mtime[31:0];
			12'hB83: csr_read_data = csr_mtime[63:32];
			12'hB04: csr_read_data = csr_mtimecmp[31:0];
			12'hB84: csr_read_data = csr_mtimecmp[63:32];
			12'hB88: csr_read_data = {27'b0, csr_mcctr};
			12'hF11: csr_read_data = CSR_MVENDORID_VALUE;
			12'hF12: csr_read_data = 32'b0;
			12'hF13: csr_read_data = CSR_MIMPID_VALUE;
			12'hF14: csr_read_data = 32'b0;
			default: csr_read_data = 32'b0;
		endcase
	end

	always @(posedge clk) begin
		if (rst) begin
			csr_mtime    <= 64'b0;
			csr_mtimecmp <= 64'hffff_ffff_ffff_ffff;
			csr_minstret <= 64'b0;
			csr_mcctr <= 5'b0;
		end else begin
			if (csr_wen && (csr_addr == 12'hB03)) csr_mtime[31:0] <= csr_write_data;
			else if (csr_wen && (csr_addr == 12'hB83)) csr_mtime[63:32] <= csr_write_data;
			else if (csr_mcctr[2]) csr_mtime <= csr_mtime + 64'd1;
			if (csr_wen && (csr_addr == 12'hB04)) csr_mtimecmp[31:0] <= csr_write_data;
			else if (csr_wen && (csr_addr == 12'hB84)) csr_mtimecmp[63:32] <= csr_write_data;
			if (csr_wen && (csr_addr == 12'hB02)) csr_minstret[31:0] <= csr_write_data;
			else if (csr_wen && (csr_addr == 12'hB82)) csr_minstret[63:32] <= csr_write_data;
			else if (csr_mcctr[1]) csr_minstret <= csr_minstret + 64'd1;
			if (csr_wen && (csr_addr == 12'hB88)) csr_mcctr <= csr_write_data[4:0];
		end
	end

	always @(*) begin
		csr_wen = 1'b0;
		csr_write_data = csr_read_data; //默认写回原值（csrrs/csrrc 可能会修改特定位）
		if (csr_valid) begin
			case (csr_op)
				3'b001,3'b101: begin // csrrw(i)
					csr_wen = 1'b1;
					csr_write_data = csr_src; //写入新值
				end
				3'b010,3'b110: begin // csrrs(i)
					csr_wen = 1'b1;
					csr_write_data = csr_read_data | csr_src; //设置csr_read_data中csr_src指定位为1，其他位保持不变
				end
				3'b011,3'b111: begin // scrrc(i)
					csr_wen = 1'b1;
					csr_write_data = csr_read_data & ~csr_src; //清除csr_read_data中csr_src指定位（置0），其他位保持不变
				end
				default: begin
					csr_wen = 1'b0;
					csr_write_data = csr_read_data;
				end
			endcase
		end
	end
	always @(posedge clk) begin
		if (rst) begin
			csr_mstatus <= 32'h00001800;
			csr_mie     <= 32'b0;
			csr_mtvec   <= 32'b0;
			csr_mepc    <= 32'b0;
			csr_mcause  <= 32'b0;
		end else if (is_ecall)begin
				csr_mcause <= 32'd11;     //环境调用异常号
				csr_mepc   <= current_pc; //保存触发异常的指令地址
		end else if (csr_wen) begin
				case (csr_addr)
					12'h300: csr_mstatus <= csr_write_data;
					12'h304: csr_mie     <= csr_write_data;
					12'h305: csr_mtvec   <= csr_write_data;
					12'h341: csr_mepc    <= csr_write_data;
					12'h342: csr_mcause  <= csr_write_data;
					default: ;
				endcase
		end
	end

	//返回信号
	assign csr_rdata      = csr_read_data;
	assign redirect_valid = is_ecall || is_mret;
	assign redirect_pc    = is_ecall ? csr_mtvec :
                     	    is_mret  ? csr_mepc  :
                                       32'b0;


endmodule
