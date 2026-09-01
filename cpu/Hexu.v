`timescale 1ns / 1ps

module Hexu (
    input             clk,
    input             rst,

    input             id_to_ex_valid,
    input             mem_allowin,
    input             flush,

	//传递
    input      [31:0] id_pc,
    input      [31:0] id_imm,
    input      [31:0] id_src1,
    input      [31:0] id_src2,
    input      [4:0]  id_rd_addr,
    input      [3:0]  id_alu_op,
    input             id_alu_en,
	input      [3:0]  id_m_op,
    input             id_src1_is_pc,
    input             id_src1_is_zero,
    input             id_src2_is_imm,
    input             id_is_load,
    input             id_is_store,
    input      [2:0]  id_mem_funct3,
    input             id_reg_wen,
    input      [1:0]  id_wb_sel,
    input             id_is_csr,
    input      [2:0]  id_csr_op,
    input      [11:0] id_csr_addr,
    input      [4:0]  id_csr_imm,
    input             id_is_ecall,
    input             id_is_mret,
    input             id_is_ebreak,
	input  [31:0]     id_ins,
	input dmem_ready,

    output reg         ex_valid,
    output wire        ex_allowin,
    output wire        ex_to_mem_valid,
    output reg  [31:0] ex_pc,
    output reg  [31:0] ex_ins,
    output reg  [4:0]  ex_rd_addr,
    output reg         ex_is_load,
    output reg  [2:0]  ex_mem_funct3,
    output reg         ex_reg_wen,
    output reg  [1:0]  ex_wb_sel,
    output reg         ex_is_ebreak,

    output wire [31:0] ex_result,
    output wire        ex_forward_valid,
    output wire [4:0]  ex_forward_rd_addr,
    output wire [31:0] ex_forward_data,
    output wire        ex_flush_req,
    output wire [31:0] ex_flush_pc,
	output wire [31:0] ex_wb_value,

    //EX阶段生成Dmem请求
    output wire        dmem_valid,
    output wire        dmem_wen,
    output wire [31:0] dmem_addr,
    output reg  [31:0] dmem_wdata,
    output reg  [3:0]  dmem_wmask
);
    localparam [1:0] WB_ALU  = 2'b00;
    localparam [1:0] WB_LOAD = 2'b01;
    localparam [1:0] WB_PC4  = 2'b10;
    localparam [1:0] WB_CSR  = 2'b11;
	
	localparam [3:0] M_NONE   = 4'd0;
	localparam [3:0] M_MUL    = 4'd1;
	localparam [3:0] M_MULH   = 4'd2;
	localparam [3:0] M_MULHSU = 4'd3;
	localparam [3:0] M_MULHU  = 4'd4;
	localparam [3:0] M_DIV    = 4'd5;
	localparam [3:0] M_DIVU   = 4'd6;
	localparam [3:0] M_REM    = 4'd7;
	localparam [3:0] M_REMU   = 4'd8;

	reg [3:0]  ex_m_op;

	//div状态
	reg        ex_div_started;
	reg        ex_div_done;


    reg [31:0] ex_imm;
    reg [31:0] ex_src1;
    reg [31:0] ex_src2;
    reg [3:0]  ex_alu_op;
    reg        ex_alu_en;
    reg        ex_src1_is_pc;
    reg        ex_src1_is_zero;
    reg        ex_src2_is_imm;
    reg        ex_is_store;
    reg        ex_is_csr;
    reg [2:0]  ex_csr_op;
    reg [11:0] ex_csr_addr;
    reg [4:0]  ex_csr_imm;
    reg        ex_is_ecall;
    reg        ex_is_mret;
	wire [31:0] ex_csr_data;


	wire       ex_ready_go;
	// 访存请求：只看 ex_valid 和指令类型，不看 ready_go —— 这是打断组合环的关键
    wire ex_mem_req = ex_valid && (ex_is_load || ex_is_store);
	//控制信号
	assign ex_ready_go     =(!ex_valid || !ex_m_is_div || ex_div_done) //除法
						   && (!ex_mem_req || dmem_ready); //访存
    assign ex_allowin      = !ex_valid || (ex_ready_go && mem_allowin);
    assign ex_to_mem_valid = ex_valid && ex_ready_go;
	
	//M指令
	wire ex_m_valid = ex_valid && (ex_m_op != M_NONE);
	//mul
	wire ex_m_is_mul = ex_m_valid &&(ex_m_op == M_MUL   ||
	                                 ex_m_op == M_MULH  ||
	                                 ex_m_op == M_MULHSU||
	                                 ex_m_op == M_MULHU);

	wire mul_x_signed =(ex_m_op == M_MUL)||(ex_m_op == M_MULH)||(ex_m_op == M_MULHSU);
	wire mul_y_signed =(ex_m_op == M_MUL)||(ex_m_op == M_MULH);
	wire [31:0] mul_result_selected = (ex_m_op == M_MUL) ? mul_result[31:0] : mul_result[63:32];

	wire [63:0] mul_result;
	mul u_mul (
	    .x_signed     (mul_x_signed),
	    .y_signed     (mul_y_signed),
	    .x            (ex_src1),
	    .y            (ex_src2),
	    .result       (mul_result)
	);

	//div
	wire ex_m_is_div = ex_m_valid && (ex_m_op == M_DIV ||
	                                  ex_m_op == M_DIVU ||
	                                  ex_m_op == M_REM ||
	                                  ex_m_op == M_REMU);

	wire div_start     = ex_m_is_div && !ex_div_started && !ex_div_done;
	wire div_done_fire = ex_m_is_div && ex_div_started && div_done;
	wire div_signed    =(ex_m_op == M_DIV) || (ex_m_op == M_REM);
	wire [31:0] div_result_selected =(ex_m_op == M_DIV || ex_m_op == M_DIVU)? div_quotient : div_remainder;

	wire [31:0] div_quotient;
	wire [31:0] div_remainder;
	wire        div_done;
	div u_div (
	    .div_clk    (clk),
	    .reset      (rst),
	    .start      (div_start),
	    .div_signed (div_signed),
	    .x          (ex_src1),
	    .y          (ex_src2),
	    .s          (div_quotient),
	    .r          (div_remainder),
	    .done       (div_done)
	);

	
	//alu计算
    wire [31:0] alu_src1 = ex_src1_is_pc   ? ex_pc :
                           ex_src1_is_zero ? 32'b0 : ex_src1;
    wire [31:0] alu_src2 = ex_src2_is_imm ? ex_imm : ex_src2;

    Halu u_alu (
        .src1   (alu_src1),
        .src2   (alu_src2),
        .alu_op (ex_alu_op),
        .alu_en (ex_alu_en),
        .result (ex_result)
    );

	//csr
    wire csr_valid    = ex_valid && ex_is_csr   && ex_allowin;
    wire csr_is_ecall = ex_valid && ex_is_ecall && ex_allowin;
    wire csr_is_mret  = ex_valid && ex_is_mret  && ex_allowin;
    wire        csr_redirect_valid;
    wire [31:0] csr_redirect_pc;

    Hcsr u_csr (
        .clk            (clk),
        .rst            (rst),
        .csr_valid      (csr_valid),
        .csr_op         (ex_csr_op),
        .csr_addr       (ex_csr_addr),
        .csr_rs1_data   (ex_src1),
        .csr_imm        (ex_csr_imm),
        .is_ecall       (csr_is_ecall),
        .is_mret        (csr_is_mret),
        .current_pc     (ex_pc),
        .csr_rdata      (ex_csr_data),
        .redirect_valid (csr_redirect_valid),
        .redirect_pc    (csr_redirect_pc)
    );

    assign ex_flush_req = csr_redirect_valid;
    assign ex_flush_pc  = csr_redirect_pc;

    assign ex_wb_value =  ex_m_is_mul            ? mul_result_selected :
	                      ex_m_is_div            ? div_result_selected :
						  (ex_wb_sel == WB_PC4)  ? ex_pc + 32'd4 :
                          (ex_wb_sel == WB_CSR)  ? ex_csr_data   :
                          (ex_wb_sel == WB_ALU)  ? ex_result     :
                                                       32'b0;
    assign ex_forward_valid   = ex_valid && ex_reg_wen && !ex_is_load &&
                                (ex_rd_addr != 5'd0) &&
                                (!ex_m_is_div || ex_div_done);

    assign ex_forward_rd_addr = ex_rd_addr;
    assign ex_forward_data    = ex_wb_value;


    assign dmem_valid = ex_to_mem_valid && (ex_is_load || ex_is_store);
    assign dmem_wen   = dmem_valid && ex_is_store;
    assign dmem_addr  = ex_result;

	//生成掩码和数据
    always @(*) begin
        dmem_wdata = 32'b0;
        dmem_wmask = 4'b0000;
        if (dmem_valid && dmem_wen) begin
            case (ex_mem_funct3)
                3'b000: begin
                    dmem_wmask = 4'b0001 << ex_result[1:0];
                    dmem_wdata = (ex_src2 & 32'h0000_00ff) <<
                                 (ex_result[1:0] * 8);
                end
                3'b001: begin
                    dmem_wmask = 4'b0011 << ex_result[1:0];
                    dmem_wdata = (ex_src2 & 32'h0000_ffff) <<
                                 (ex_result[1:0] * 8);
                end
                3'b010: begin
                    dmem_wmask = 4'b1111;
                    dmem_wdata = ex_src2;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ex_valid        <= 1'b0;
            ex_pc           <= 32'b0;
            ex_imm          <= 32'b0;
            ex_src1         <= 32'b0;
            ex_src2         <= 32'b0;
            ex_rd_addr      <= 5'b0;
            ex_alu_op       <= 4'b1111;
            ex_alu_en       <= 1'b0;
            ex_src1_is_pc   <= 1'b0;
            ex_src1_is_zero <= 1'b0;
            ex_src2_is_imm  <= 1'b0;
            ex_is_load      <= 1'b0;
            ex_is_store     <= 1'b0;
            ex_mem_funct3   <= 3'b0;
            ex_reg_wen      <= 1'b0;
            ex_wb_sel       <= WB_ALU;
            ex_is_csr       <= 1'b0;
            ex_csr_op       <= 3'b0;
            ex_csr_addr     <= 12'b0;
            ex_csr_imm      <= 5'b0;
            ex_is_ecall     <= 1'b0;
            ex_is_mret      <= 1'b0;
            ex_is_ebreak    <= 1'b0;
				ex_ins          <= 32'h0000_0013;
				ex_m_op         <= M_NONE;
				ex_div_started  <= 1'b0;
				ex_div_done     <= 1'b0;
        end else begin
            if (flush) begin
				ex_valid      <= 1'b0;
            end else if (ex_allowin) begin
                ex_valid <= id_to_ex_valid;
            end

            if (!flush && id_to_ex_valid && ex_allowin) begin
                ex_pc          <= id_pc;
				ex_ins         <= id_ins;
                ex_imm         <= id_imm;
                ex_src1        <= id_src1;
                ex_src2        <= id_src2;
                ex_rd_addr     <= id_rd_addr;
                ex_alu_op      <= id_alu_op;
                ex_alu_en      <= id_alu_en;
                ex_src1_is_pc  <= id_src1_is_pc;
                ex_src1_is_zero<= id_src1_is_zero;
                ex_src2_is_imm <= id_src2_is_imm;
                ex_is_load     <= id_is_load;
                ex_is_store    <= id_is_store;
                ex_mem_funct3  <= id_mem_funct3;
                ex_reg_wen     <= id_reg_wen;
                ex_wb_sel      <= id_wb_sel;
                ex_is_csr      <= id_is_csr;
                ex_csr_op      <= id_csr_op;
                ex_csr_addr    <= id_csr_addr;
                ex_csr_imm     <= id_csr_imm;
                ex_is_ecall    <= id_is_ecall;
                ex_is_mret     <= id_is_mret;
                ex_is_ebreak   <= id_is_ebreak;
				ex_m_op        <= id_m_op;
            end

			//div的状态寄存器
			if (flush || ex_allowin) begin
				ex_div_started <= 1'b0;
				ex_div_done    <= 1'b0;
			end else if (div_done_fire) begin
				ex_div_done   <= 1'b1;
			end else if (div_start) begin
				ex_div_started <= 1'b1;
			end
			// M-EXT MODIFIED END
        end
    end
endmodule
