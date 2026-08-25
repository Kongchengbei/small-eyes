`timescale 1ns / 1ps

module Htop #(
    parameter RESET_PC = 32'h0000_0000
) (
    input         clk,
    input         rst,

    output wire [31:0] imem_addr,
    input       [31:0] imem_rdata,

    output wire        dmem_valid,
    output wire        dmem_wen,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wmask,
    input       [31:0] dmem_rdata,

    output wire [31:0] pc,
    output wire [31:0] ins,
    output wire        is_ebreak
);
    wire        if_to_id_valid;
    wire [31:0] if_pc;
    wire [31:0] if_ins;

    wire        id_allowin;
    wire        id_to_ex_valid;
    wire [31:0] id_pc;
    wire [31:0] id_ins;
	wire [3:0]  id_m_op;
    wire [4:0]  id_rd_addr;
    wire [31:0] id_src1;
    wire [31:0] id_src2;
    wire [31:0] id_imm;
    wire [3:0]  id_alu_op;
    wire        id_alu_en;
    wire        id_src1_is_pc;
    wire        id_src1_is_zero;
    wire        id_src2_is_imm;
    wire        id_is_load;
    wire        id_is_store;
    wire        id_reg_wen;
    wire        id_is_csr;
    wire [2:0]  id_csr_op;
    wire [11:0] id_csr_addr;
    wire        id_is_ecall;
    wire        id_is_mret;
    wire        id_is_ebreak;
    wire [2:0]  id_mem_funct3;
    wire [4:0]  id_csr_imm;
    wire [1:0]  id_wb_sel;
    wire        id_flush_req;
    wire [31:0] id_redirect_pc;


    wire [31:0] ex_pc;
    wire [31:0] ex_ins;
    wire        ex_valid;
    wire        ex_allowin;
    wire        ex_to_mem_valid;
    wire [4:0]  ex_rd_addr;
    wire        ex_is_load;
    wire [2:0]  ex_mem_funct3;
    wire        ex_reg_wen;
    wire [1:0]  ex_wb_sel;
    wire        ex_is_ebreak;
    wire [31:0] ex_result;
    wire [31:0] ex_wb_value;
    wire        ex_forward_valid;
    wire [4:0]  ex_forward_rd_addr;
    wire [31:0] ex_forward_data;
    wire        ex_flush_req;
    wire [31:0] ex_flush_pc;


    wire [31:0] mem_pc;
    wire [31:0] mem_ins;
    wire        mem_allowin;
    wire        mem_to_wb_valid;
    wire [4:0]  mem_rd_addr;
    wire        mem_reg_wen;
    wire        mem_is_ebreak;
    wire [31:0] mem_wb_data;
    wire        mem_forward_valid;

    wire [31:0] wb_pc;
    wire [31:0] wb_ins;
    wire        wb_valid;
    wire        wb_allowin;
    wire        wb_reg_wen;
    wire [4:0]  wb_rd_addr;
    wire [31:0] wb_data;
    wire        wb_is_ebreak;

    //EX异常优先于id阶段。
    wire        flush    = ex_flush_req || id_flush_req;
    wire [31:0] flush_pc = ex_flush_req ? ex_flush_pc : id_redirect_pc;



    Hifu #(.RESET_PC(RESET_PC)) u_ifu (
        .clk            (clk),
        .rst            (rst),
        .id_allowin     (id_allowin),
        .flush          (flush),
        .redirect_pc    (flush_pc),
        .imem_rdata     (imem_rdata),
        .imem_addr      (imem_addr),
        .if_ins         (if_ins),
        .if_pc          (if_pc),
        .if_to_id_valid (if_to_id_valid)
    );

    Hidu u_idu (
        .clk                (clk),
        .rst                (rst),
        .if_to_id_valid     (if_to_id_valid),
        .if_pc              (if_pc),
        .if_ins             (if_ins),
        .ex_valid           (ex_valid),
        .ex_is_load         (ex_is_load),
        .ex_rd_addr         (ex_rd_addr),
        .ex_forward_valid   (ex_forward_valid),
        .ex_forward_rd_addr (ex_forward_rd_addr),
        .ex_forward_data    (ex_forward_data),
        .mem_forward_valid  (mem_forward_valid),
        .mem_forward_rd_addr(mem_rd_addr),
        .mem_forward_data   (mem_wb_data),
        .ex_allowin         (ex_allowin),
        .flush              (flush),
        .wb_reg_wen         (wb_reg_wen),
        .wb_rd_addr         (wb_rd_addr),
        .wb_data            (wb_data),
        .id_allowin         (id_allowin),
        .id_to_ex_valid     (id_to_ex_valid),
        .id_pc              (id_pc),
		.id_ins             (id_ins),
        .id_rd_addr         (id_rd_addr),
        .id_src1            (id_src1),
        .id_src2            (id_src2),
        .id_imm             (id_imm),
		.id_m_op            (id_m_op),
        .id_alu_op          (id_alu_op),
        .id_alu_en          (id_alu_en),
        .id_src1_is_pc      (id_src1_is_pc),
        .id_src1_is_zero    (id_src1_is_zero),
        .id_src2_is_imm     (id_src2_is_imm),
        .id_is_load         (id_is_load),
        .id_is_store        (id_is_store),
        .id_reg_wen         (id_reg_wen),
        .id_is_csr          (id_is_csr),
        .id_csr_op          (id_csr_op),
        .id_csr_addr        (id_csr_addr),
        .id_is_ecall        (id_is_ecall),
        .id_is_mret         (id_is_mret),
        .id_is_ebreak       (id_is_ebreak),
        .id_mem_funct3      (id_mem_funct3),
        .id_csr_imm         (id_csr_imm),
        .id_wb_sel          (id_wb_sel),
        .id_flush_req       (id_flush_req),
        .id_redirect_pc     (id_redirect_pc)
    );

    Hexu u_exu (
        .clk                 (clk),
        .rst                 (rst),
        .id_to_ex_valid      (id_to_ex_valid),
        .mem_allowin         (mem_allowin),
        .flush               (ex_flush_req),
        .id_pc               (id_pc),
        .id_ins              (id_ins),
        .id_imm              (id_imm),
        .id_src1            (id_src1),
        .id_src2            (id_src2),
        .id_rd_addr          (id_rd_addr),
        .id_alu_op           (id_alu_op),
        .id_alu_en           (id_alu_en),
		.id_m_op             (id_m_op),
        .id_src1_is_pc       (id_src1_is_pc),
        .id_src1_is_zero     (id_src1_is_zero),
        .id_src2_is_imm      (id_src2_is_imm),
        .id_is_load          (id_is_load),
        .id_is_store         (id_is_store),
        .id_mem_funct3       (id_mem_funct3),
        .id_reg_wen          (id_reg_wen),
        .id_wb_sel            (id_wb_sel),
        .id_is_csr           (id_is_csr),
        .id_csr_op           (id_csr_op),
        .id_csr_addr         (id_csr_addr),
        .id_csr_imm          (id_csr_imm),
        .id_is_ecall         (id_is_ecall),
        .id_is_mret          (id_is_mret),
        .id_is_ebreak        (id_is_ebreak),
        .ex_valid             (ex_valid),
        .ex_allowin           (ex_allowin),
        .ex_to_mem_valid      (ex_to_mem_valid),
        .ex_pc                (ex_pc),
        .ex_ins               (ex_ins),
        .ex_rd_addr           (ex_rd_addr),
        .ex_is_load           (ex_is_load),
        .ex_mem_funct3        (ex_mem_funct3),
        .ex_reg_wen           (ex_reg_wen),
        .ex_wb_sel            (ex_wb_sel),
        .ex_is_ebreak         (ex_is_ebreak),
        .ex_result            (ex_result),
        .ex_forward_valid     (ex_forward_valid),
        .ex_forward_rd_addr  (ex_forward_rd_addr),
        .ex_forward_data      (ex_forward_data),
        .ex_flush_req         (ex_flush_req),
        .ex_flush_pc          (ex_flush_pc),
		.ex_wb_value          (ex_wb_value),
        .dmem_valid           (dmem_valid),
        .dmem_wen             (dmem_wen),
        .dmem_addr            (dmem_addr),
        .dmem_wdata           (dmem_wdata),
        .dmem_wmask           (dmem_wmask)
    );

    Hmemu u_memu (
        .clk              (clk),
        .rst              (rst),
        .ex_to_mem_valid  (ex_to_mem_valid),
        .wb_allowin       (wb_allowin),
        .ex_alu_result    (ex_result),
        .ex_pc            (ex_pc),
        .ex_ins           (ex_ins),
        .ex_rd_addr       (ex_rd_addr),
        .ex_mem_funct3    (ex_mem_funct3),
        .ex_reg_wen       (ex_reg_wen),
        .ex_wb_sel        (ex_wb_sel),
        .ex_is_ebreak     (ex_is_ebreak),
		.ex_wb_value      (ex_wb_value),
        .dmem_rdata       (dmem_rdata),
        .mem_pc           (mem_pc),
        .mem_ins          (mem_ins),
        .mem_allowin      (mem_allowin),
        .mem_to_wb_valid  (mem_to_wb_valid),
        .mem_rd_addr      (mem_rd_addr),
        .mem_reg_wen      (mem_reg_wen),
        .mem_is_ebreak    (mem_is_ebreak),
        .mem_wb_data      (mem_wb_data),
        .mem_forward_valid(mem_forward_valid)
    );

    Hwbu u_wbu (
        .clk             (clk),
        .rst             (rst),
        .mem_pc          (mem_pc),
        .mem_ins         (mem_ins),
        .mem_to_wb_valid (mem_to_wb_valid),
        .mem_wb_data     (mem_wb_data),
        .mem_rd_addr     (mem_rd_addr),
        .mem_reg_wen     (mem_reg_wen),
        .mem_is_ebreak   (mem_is_ebreak),
        .wb_pc           (wb_pc),
        .wb_ins          (wb_ins),
		.wb_valid        (wb_valid),
        .wb_allowin      (wb_allowin),
        .wb_reg_wen      (wb_reg_wen),
        .wb_rd_addr      (wb_rd_addr),
        .wb_data         (wb_data),
        .wb_is_ebreak    (wb_is_ebreak)
    );

	assign pc        = wb_pc ;
    assign ins       = wb_ins;
    assign is_ebreak = wb_is_ebreak;

endmodule
