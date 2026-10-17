`timescale 1ns / 1ps

module Hidu #(
    parameter BRAM_MODE = 1'b0
) (
    input             clk,
    input             rst,

    input             if_to_id_valid,
    input      [31:0] if_pc,
    input      [31:0] if_ins,
	//前递信号
    input             ex_valid,
    input             ex_is_load,
    input      [4:0]  ex_rd_addr,
    input             ex_reg_wen,
    input             ex_forward_valid,
    input      [4:0]  ex_forward_rd_addr,
    input      [31:0] ex_forward_data,
    input             mem_forward_valid,
    input             mem_load_wait,
    input      [4:0]  mem_forward_rd_addr,
    input      [31:0] mem_forward_data,
    input             mem_load_valid,
    input             mem_alu_forward_valid,
    input      [31:0] mem_alu_forward_data,
    input             ex_allowin,
    input             flush,
	//wb的写回
    input             wb_reg_wen,
    input      [4:0]  wb_rd_addr,
    input      [31:0] wb_data,
	//传递
    output wire [31:0] id_pc,
	output wire [31:0] id_ins,
    output wire        id_allowin,
    output wire        id_to_ex_valid,
    output wire [4:0]  id_rd_addr,
    output wire [31:0] id_src1,
    output wire [31:0] id_src2,
    output wire        id_src1_mem_pending,
    output wire        id_src2_mem_pending,
    output wire [4:0]  id_mem_pending_rd_addr,
    output wire [31:0] id_imm,
    output reg  [3:0]  id_alu_op,
    output wire        id_alu_en,
	output wire [3:0]  id_m_op,
    output wire        id_src1_is_pc,
    output wire        id_src1_is_zero,
    output wire        id_src2_is_imm,
    output wire        id_is_load,
    output wire        id_is_store,
    output wire        id_reg_wen,
    output wire        id_is_csr,
    output wire [2:0]  id_csr_op,
    output wire [11:0] id_csr_addr,
    output wire        id_is_ecall,
    output wire        id_is_mret,
    output wire        id_is_ebreak,
    output wire [2:0]  id_mem_funct3,
    output wire [4:0]  id_csr_imm,
    output wire [1:0]  id_wb_sel,
    output wire        id_flush_req,
    output wire [31:0] id_redirect_pc,
    //btb
     output wire        btb_update_valid,
     output wire [31:0] btb_update_pc,
     output wire [31:0] btb_update_target,
     output wire        btb_update_is_conditional,
     output wire        btb_update_taken,
     input  wire  [31:0] btb_predict_next_pc,
    output wire [31:0] actual_next_pc,
    // 调试观测：ID 级状态、暂停和 BTB 误预测
    output wire        dbg_id_valid,
    output wire        dbg_id_stall,
    output wire        dbg_id_ready_go,
    output wire        dbg_mispredict
);
    localparam [1:0] WB_ALU  = 2'b00;
    localparam [1:0] WB_LOAD = 2'b01;
    localparam [1:0] WB_PC4  = 2'b10;
    localparam [1:0] WB_CSR  = 2'b11;

	//乘除法
	localparam [3:0] M_NONE  = 4'd0;
	localparam [3:0] M_MUL   = 4'd1;
	localparam [3:0] M_MULH  = 4'd2;
	localparam [3:0] M_MULHSU= 4'd3;
	localparam [3:0] M_MULHU = 4'd4;
	localparam [3:0] M_DIV   = 4'd5;
	localparam [3:0] M_DIVU  = 4'd6;
	localparam [3:0] M_REM   = 4'd7;
	localparam [3:0] M_REMU  = 4'd8;

    reg        id_valid;
    reg [31:0] id_pc_reg;
    reg [31:0] id_ins_reg;

	wire [31:0] id_rs1_data;
	wire [31:0] id_rs2_data;

    wire       id_is_jal;
    wire       id_is_jalr;
    wire       id_uses_rs1;
    wire       id_uses_rs2;
    wire [4:0] id_rs1_addr;
    wire [4:0] id_rs2_addr;
    
    //btb -- 关于这个actual_next_pc和mispredict
    wire [31:0] id_actual_next_pc;
    wire        mispredict;
    reg [31:0]  id_predict_next_pc;
    wire        actual_taken;
    wire [31:0] sequential_pc = id_pc_reg + 32'd4;
    wire [10:0] target_pc_group_equal;
    wire [10:0] sequential_pc_group_equal;
    wire        target_pc_match;
    wire        sequential_pc_match;
    reg         chosen_pc_match;
    genvar      pc_group;
	
    //译码识别指令
    wire [6:0] opcode = id_ins_reg[6:0];
    wire [2:0] funct3 = id_ins_reg[14:12];
    wire [6:0] funct7 = id_ins_reg[31:25];

    wire type_i   = (opcode == 7'b0010011) ||
                    (opcode == 7'b0000011) ||
                    (opcode == 7'b1100111);
    wire type_u   = (opcode == 7'b0110111) || (opcode == 7'b0010111);
    wire type_s   = (opcode == 7'b0100011);
    wire type_j   = (opcode == 7'b1101111);
    wire type_r   = (opcode == 7'b0110011);
    wire type_b   = (opcode == 7'b1100011);
    wire type_sys = (opcode == 7'b1110011);

    assign id_pc       = id_pc_reg;
    assign id_rs1_addr = id_ins_reg[19:15];
    assign id_rs2_addr = id_ins_reg[24:20];
    assign id_rd_addr  = id_ins_reg[11:7];

    assign id_is_jal    = type_j;
    assign id_is_jalr   = type_i && (opcode == 7'b1100111);
    assign id_is_load   = (opcode == 7'b0000011);
    assign id_is_store  = type_s;
    wire   id_is_beq    = type_b && (funct3 == 3'b000);
    wire   id_is_bne    = type_b && (funct3 == 3'b001);
    wire   id_is_bge    = type_b && (funct3 == 3'b101);
    wire   id_is_bgeu   = type_b && (funct3 == 3'b111);
    wire   id_is_blt    = type_b && (funct3 == 3'b100);
    wire   id_is_bltu   = type_b && (funct3 == 3'b110);
    wire   id_is_branch = type_b;
	wire   id_is_m      = type_r && (funct7 == 7'b0000001);
    assign id_is_ebreak = (id_ins_reg == 32'h0010_0073);
    assign id_is_ecall  = (id_ins_reg == 32'h0000_0073);
    assign id_is_mret   = (id_ins_reg == 32'h3020_0073);
    assign id_is_csr    = type_sys && (funct3 != 3'b000);
    assign id_csr_op    = type_sys ? funct3 : 3'b000;
    assign id_csr_addr  = type_sys ? id_ins_reg[31:20] : 12'b0;


    assign id_uses_rs1 = type_r || type_i || type_s || type_b || (id_is_csr && !funct3[2]);
    assign id_uses_rs2 = type_r || type_s || type_b;

    assign id_src1_is_pc   = (opcode == 7'b0010111) || id_is_jal;
    assign id_src1_is_zero = (opcode == 7'b0110111);
    assign id_src2_is_imm  = type_i || type_s || type_u || type_j;

    assign id_alu_en  = (type_r & !id_is_m) || (type_i && !id_is_jalr) || type_u || type_s;

    assign id_reg_wen = type_r || type_i || type_u || type_j || id_is_csr;


	assign id_m_op = !id_is_m           ? M_NONE :
					 (funct3 == 3'b000) ? M_MUL  :
					 (funct3 == 3'b001) ? M_MULH :
					 (funct3 == 3'b010) ? M_MULHSU :
					 (funct3 == 3'b011) ? M_MULHU :
					 (funct3 == 3'b100) ? M_DIV  :
					 (funct3 == 3'b101) ? M_DIVU :
					 (funct3 == 3'b110) ? M_REM  :
					                      M_REMU;
	//alu操作码
    always @(*) begin
        id_alu_op = 4'b1111;
        case (opcode)
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000)
                            id_alu_op = 4'b0000;
                        else if (funct7 == 7'b0100000)
                            id_alu_op = 4'b0001;
                    end
                    3'b001: id_alu_op = 4'b0010;
                    3'b010: id_alu_op = 4'b0011;
                    3'b011: id_alu_op = 4'b0100;
                    3'b100: id_alu_op = 4'b0101;
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            id_alu_op = 4'b0110;
                        else if (funct7 == 7'b0100000)
                            id_alu_op = 4'b0111;
                    end
                    3'b110: id_alu_op = 4'b1000;
                    3'b111: id_alu_op = 4'b1001;
                    default:id_alu_op = 4'b1111;
                endcase
            end
            7'b0010011: begin
                case (funct3)
                    3'b000: id_alu_op = 4'b0000;
                    3'b001: id_alu_op = 4'b0010;
                    3'b010: id_alu_op = 4'b0011;
                    3'b011: id_alu_op = 4'b0100;
                    3'b100: id_alu_op = 4'b0101;
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            id_alu_op = 4'b0110;
                        else if (funct7 == 7'b0100000)
                            id_alu_op = 4'b0111;
                    end
                    3'b110: id_alu_op = 4'b1000;
                    3'b111: id_alu_op = 4'b1001;
                    default: id_alu_op = 4'b1111;
                endcase
            end
            7'b0010111, 7'b0110111: id_alu_op = 4'b0000;
            7'b0000011, 7'b0100011: id_alu_op = 4'b0000;
            default: id_alu_op = 4'b1111;
        endcase
    end
	
	//立即数
    wire [31:0] imm_i = {{20{id_ins_reg[31]}}, id_ins_reg[31:20]};
    wire [31:0] imm_s = {{20{id_ins_reg[31]}}, id_ins_reg[31:25], id_ins_reg[11:7]};
    wire [31:0] imm_u = {id_ins_reg[31:12], 12'b0};
    wire [31:0] imm_j = {{12{id_ins_reg[31]}}, id_ins_reg[19:12], id_ins_reg[20],
                         id_ins_reg[30:21], 1'b0};
    wire [31:0] imm_b = {{20{id_ins_reg[31]}}, id_ins_reg[7], id_ins_reg[30:25],
                         id_ins_reg[11:8], 1'b0};

    assign id_imm = type_sys ? {27'b0, id_ins_reg[19:15]} :
                    type_i   ? imm_i :
                    type_b   ? imm_b :
                    type_s   ? imm_s :
                    type_u   ? imm_u :
                    type_j   ? imm_j : 32'b0;

    assign id_mem_funct3 = funct3;
    assign id_csr_imm    = id_imm[4:0];
    assign id_wb_sel     = id_is_load ? WB_LOAD :
                           (id_is_jal || id_is_jalr) ? WB_PC4 :
                           id_is_csr ? WB_CSR : WB_ALU;

    HRegFile u_rf (
        .clk    (clk),
		.rst    (rst),
        .wen    (wb_reg_wen),
        .waddr  (wb_rd_addr),
        .wdata  (wb_data),
        .raddr1 (id_rs1_addr),
        .raddr2 (id_rs2_addr),
        .rdata1 (id_rs1_data),
        .rdata2 (id_rs2_data)
    );

    assign id_src1 =
        (id_rs1_addr != 5'd0 && ex_forward_valid  &&
         (ex_forward_rd_addr  == id_rs1_addr)) ? ex_forward_data :
        (id_rs1_addr != 5'd0 && mem_forward_valid &&
         (mem_forward_rd_addr == id_rs1_addr)) ? mem_forward_data : id_rs1_data;

    assign id_src2 =
        (id_rs2_addr != 5'd0 && ex_forward_valid  &&
         (ex_forward_rd_addr  == id_rs2_addr)) ? ex_forward_data :
        (id_rs2_addr != 5'd0 && mem_forward_valid &&
         (mem_forward_rd_addr == id_rs2_addr)) ? mem_forward_data : id_rs2_data;

    // DDR 版分支和 JALR 在 ID 级算跳转、决定冲刷取指。这里的操作数要是再接
    // EX 的 ALU 结果或 DCache 刚返回的 load 数据，一路连到 ICache 地址，
    // cpu_clk 70 MHz 收不住。所以只从寄存器取：MEM 级已锁存的非 load 结果，
    // 或寄存器堆（含 WB 写穿）。依赖还在 EX 的指令或 MEM 里的 load 时多停，
    // 等它往后走一级再取（见下面 br_operand_stall）。BRAM 版不变。
    wire id_br_consumer = !BRAM_MODE && (id_is_branch || id_is_jalr);

    wire [31:0] id_br_src1 = BRAM_MODE ? id_src1 :
        (id_rs1_addr != 5'd0 && mem_alu_forward_valid &&
         (mem_forward_rd_addr == id_rs1_addr)) ? mem_alu_forward_data : id_rs1_data;

    wire [31:0] id_br_src2 = BRAM_MODE ? id_src2 :
        (id_rs2_addr != 5'd0 && mem_alu_forward_valid &&
         (mem_forward_rd_addr == id_rs2_addr)) ? mem_alu_forward_data : id_rs2_data;

    // Branches and JALR still consume operands in ID. Other EX consumers
    // may carry an immediately preceding load dependency into EX in BRAM mode.
    wire id_mem_forward_consumer = BRAM_MODE &&
                                   (id_alu_en || (id_m_op != M_NONE) ||
                                    (id_is_csr && !funct3[2])) &&
                                   !id_is_branch && !id_is_jalr;
    assign id_src1_mem_pending = id_mem_forward_consumer && id_uses_rs1 &&
                                 ex_valid && ex_is_load &&
                                 (ex_rd_addr != 5'd0) &&
                                 (id_rs1_addr == ex_rd_addr);
    assign id_src2_mem_pending = id_mem_forward_consumer && id_uses_rs2 &&
                                 ex_valid && ex_is_load &&
                                 (ex_rd_addr != 5'd0) &&
                                 (id_rs2_addr == ex_rd_addr);
    assign id_mem_pending_rd_addr = (id_src1_mem_pending || id_src2_mem_pending) ?
                                    ex_rd_addr : 5'b0;

    wire branch_taken = id_is_beq ? (id_br_src1 == id_br_src2) :
                        id_is_bne ? (id_br_src1 != id_br_src2) :
                        (id_is_bge  && ($signed(id_br_src1) >= $signed(id_br_src2))) ||
                        (id_is_bgeu && (        id_br_src1  >=         id_br_src2))  ||
                        (id_is_blt  && ($signed(id_br_src1) < $signed(id_br_src2)))  ||
                        (id_is_bltu && (id_br_src1 < id_br_src2));
	//阻塞
    wire id_ex_load_match_rs1 = ex_valid && ex_is_load && (ex_rd_addr != 5'd0) &&
                                id_uses_rs1 && (id_rs1_addr == ex_rd_addr);
    wire id_ex_load_match_rs2 = ex_valid && ex_is_load && (ex_rd_addr != 5'd0) &&
                                id_uses_rs2 && (id_rs2_addr == ex_rd_addr);
    wire ex_load_stall = (id_ex_load_match_rs1 || id_ex_load_match_rs2) &&
                         !id_mem_forward_consumer;

    // load 进入 MEM 后可能还在等待 DCache/MMIO 响应。依赖它的指令必须留在Id
    // 待返回数据可前递时再锁存到 EX，包括 sw 的数据和地址源
    wire mem_load_stall = mem_load_wait && (mem_forward_rd_addr != 5'd0) &&
                          ((id_uses_rs1 && !id_ex_load_match_rs1 &&
                            (id_rs1_addr == mem_forward_rd_addr)) ||
                           (id_uses_rs2 && !id_ex_load_match_rs2 &&
                            (id_rs2_addr == mem_forward_rd_addr)));

    // DDR 版分支/JALR：依赖还在 EX 的任何写寄存器指令，或 MEM 里的 load（不论
    // 数据回没回来），都先停住
    wire br_ex_match_rs1 = ex_valid && ex_reg_wen && (ex_rd_addr != 5'd0) &&
                           id_uses_rs1 && (id_rs1_addr == ex_rd_addr);
    wire br_ex_match_rs2 = ex_valid && ex_reg_wen && (ex_rd_addr != 5'd0) &&
                           id_uses_rs2 && (id_rs2_addr == ex_rd_addr);
    wire br_mem_load_match = mem_load_valid && (mem_forward_rd_addr != 5'd0) &&
                             ((id_uses_rs1 && (id_rs1_addr == mem_forward_rd_addr)) ||
                              (id_uses_rs2 && (id_rs2_addr == mem_forward_rd_addr)));
    wire br_operand_stall = id_br_consumer &&
                            (br_ex_match_rs1 || br_ex_match_rs2 || br_mem_load_match);

    wire id_stall = id_valid && (ex_load_stall || mem_load_stall || br_operand_stall);

	//控制信号
    wire   id_ready_go      = !id_stall;
    assign id_allowin       = !id_valid || (id_ready_go && ex_allowin);
    assign id_to_ex_valid   = id_valid && id_ready_go;

    assign dbg_id_valid     = id_valid;
    assign dbg_id_stall     = id_stall;
    assign dbg_id_ready_go  = id_ready_go;

    wire id_fire  = id_valid && id_ready_go && ex_allowin;//已经正确，ID具备向下执行的条件
    assign id_flush_req =  mispredict;//(id_fire &&(id_is_jal || id_is_jalr ||(id_is_branch && branch_taken))) || mispredict;
    assign id_redirect_pc = id_is_jalr ? ((id_br_src1 + id_imm) & ~32'd1) :
                                         (id_pc_reg + id_imm);

	assign id_ins = id_ins_reg;

    //关于btb
	// 无条件跳转和条件分支都在解析完成后更新 BTB；条件分支同时
	// 更新方向计数器，JAL/JALR 则固定视为 taken。
	assign btb_update_valid  = id_fire &&
                        	(id_is_jal || id_is_jalr || id_is_branch);
	assign btb_update_pc     = id_pc_reg;
	assign btb_update_target = id_redirect_pc;
	assign btb_update_is_conditional = id_is_branch;
	assign btb_update_taken  = id_is_branch ? branch_taken : 1'b1;
    assign actual_taken = id_is_jal || id_is_jalr || (id_is_branch && branch_taken);
    assign id_actual_next_pc = actual_taken ? id_redirect_pc : id_pc_reg+4;
    assign actual_next_pc    = id_actual_next_pc;
	//实际 PC 候选与预测 PC
    //并行比较两个PC候选:十个3位组和一个最终的2位组
    generate
        for (pc_group = 0; pc_group < 10; pc_group = pc_group + 1) begin: gen_pc_compare
            assign target_pc_group_equal[pc_group] =
                (id_redirect_pc[pc_group*3 +: 3] == id_predict_next_pc[pc_group*3 +: 3]);
            assign sequential_pc_group_equal[pc_group] =
                (sequential_pc[pc_group*3 +: 3] == id_predict_next_pc[pc_group*3 +: 3]);
        end
    endgenerate
    assign target_pc_group_equal[10] =
        (id_redirect_pc[31:30] == id_predict_next_pc[31:30]);
    assign sequential_pc_group_equal[10] =
        (sequential_pc[31:30] == id_predict_next_pc[31:30]);

    wire target_pc_match_low =
        ((target_pc_group_equal[0] && target_pc_group_equal[1]) &&
         (target_pc_group_equal[2] && target_pc_group_equal[3])) &&
        (target_pc_group_equal[4] && target_pc_group_equal[5]);
    wire target_pc_match_high =
        ((target_pc_group_equal[6] && target_pc_group_equal[7]) &&
         (target_pc_group_equal[8] && target_pc_group_equal[9])) &&
        target_pc_group_equal[10];
    wire sequential_pc_match_low =
        ((sequential_pc_group_equal[0] && sequential_pc_group_equal[1]) &&
         (sequential_pc_group_equal[2] && sequential_pc_group_equal[3])) &&
        (sequential_pc_group_equal[4] && sequential_pc_group_equal[5]);
    wire sequential_pc_match_high =
        ((sequential_pc_group_equal[6] && sequential_pc_group_equal[7]) &&
         (sequential_pc_group_equal[8] && sequential_pc_group_equal[9])) &&
        sequential_pc_group_equal[10];
    assign target_pc_match = target_pc_match_low && target_pc_match_high;
    assign sequential_pc_match = sequential_pc_match_low && sequential_pc_match_high;

/*在硬件中，方向是二进制的，因此只有两个候选匹配项会进入选择器
保留原始四状态模拟结果，喂入选择器。保留原始的四状态模拟结果*/
    always @(*) begin
        chosen_pc_match = actual_taken ? target_pc_match : sequential_pc_match;
        // synthesis translate_off
        if ((actual_taken !== 1'b0) && (actual_taken !== 1'b1))
            chosen_pc_match = (actual_next_pc == id_predict_next_pc);
        // synthesis translate_on
    end
    assign mispredict = id_fire && !chosen_pc_match;
    assign dbg_mispredict    = mispredict;
    //传递
    always @(posedge clk) begin
        if (rst) begin
            id_valid   <= 1'b0;
            id_pc_reg  <= 32'b0;
            id_ins_reg <= 32'h0000_0013;
            id_predict_next_pc <= 32'h0;
        end else begin
            if (flush) begin
                id_valid <= 1'b0;
            end else if (id_allowin) begin
                id_valid <= if_to_id_valid;
            end

            if (!flush && if_to_id_valid && id_allowin) begin
                id_pc_reg          <= if_pc;
                id_ins_reg         <= if_ins;
                id_predict_next_pc <= btb_predict_next_pc;
            end
        end
    end
endmodule
