`timescale 1ns / 1ps

// RV32IM machine-mode CSR block.
module Hcsr (
    input         clk,
    input         rst,

    input         csr_valid,
    input  [2:0]  csr_op,
    input  [11:0] csr_addr,
    input  [31:0] csr_rs1_data,
    input  [4:0]  csr_imm,

    input         is_ecall,
    input         is_ebreak,
    input         is_mret,
//当此条件被触发时，EX指令已完成。中断将在该指令之后发生，因此mepc现在等于pc+4。
//在该指令之后被取用，因此mepc为current_pc+4。
    input         interrupt_boundary,//中断边界：EX指令已完成，且中断将在该指令之后发生
    input         irq_external,//外部中断请求信号
    input  [31:0] current_pc,

    output wire [31:0] csr_rdata,
    output wire        redirect_valid,
    output wire [31:0] redirect_pc
);

    localparam [31:0] CSR_MVENDORID_VALUE = 32'h0011_4514;
    localparam [31:0] CSR_MIMPID_VALUE    = 32'h1020_2328;
    localparam [31:0] MSTATUS_RESET       = 32'h0000_1800;
    localparam [31:0] MIE_WR_MASK         = 32'h0000_0880; // MEIE, MTIE

    reg [31:0] csr_mstatus;
    reg [31:0] csr_mie;
    reg [31:0] csr_mtvec;
    reg [31:0] csr_mscratch;
    reg [31:0] csr_mepc;
    reg [31:0] csr_mcause;
    reg [31:0] csr_mtval;
    // mtimecmp  MTIP 
    reg [63:0] csr_mtime;
    reg [63:0] csr_mtimecmp;
    reg [63:0] csr_minstret;
    reg [4:0]  csr_mcctr;

    wire timer_pending    = (csr_mtime >= csr_mtimecmp);
    wire external_pending = irq_external;
    wire [31:0] csr_mip = {20'b0, external_pending, 3'b0,
                           timer_pending, 7'b0};

//MEI优先于MTI。中断只能在由EX提供的架构边界处执行
//irq _ Interrupt Request
    wire interrupt_mie = is_mret ? csr_mstatus[7] : csr_mstatus[3];
    wire interrupt_check = interrupt_boundary || is_mret;
    wire take_external_irq = interrupt_check && interrupt_mie &&
							 csr_mie[11] && external_pending;
    wire take_timer_irq    = interrupt_check && interrupt_mie &&
                             csr_mie[7] && timer_pending;
    wire take_interrupt    = take_external_irq || take_timer_irq;
    wire take_exception    = is_ecall || is_ebreak;

    reg        csr_writable;
    reg        csr_wen;
    reg [31:0] csr_read_data;
    reg [31:0] csr_write_data;
    wire [31:0] csr_src = csr_op[2] ? {27'b0, csr_imm} : csr_rs1_data;

    //只读CSR寄存器：MVENDORID、MARCHID、MIMPID、MHARTID
    always @(*) begin
        case (csr_addr)
            12'h300, 12'h304, 12'h305, 12'h340, 12'h341,
            12'h342, 12'h343, 12'hB02, 12'hB82, 12'hB03,
            12'hB83, 12'hB04, 12'hB84, 12'hB88:
                csr_writable = 1'b1;
            default:
                csr_writable = 1'b0;
        endcase
    end

    always @(*) begin
        case (csr_addr)
            12'h300: csr_read_data = csr_mstatus;
			//	32'h4000_1100
			//		└─ bit 30 = 1：MXL = 01，表示 RV32
			//   			└─ bit 12 = 1：实现 M 扩展
			//       			└─ bit 8 = 1：实现 I 扩展
            12'h301: csr_read_data = 32'h4000_1100;
            12'h304: csr_read_data = csr_mie;
            12'h305: csr_read_data = csr_mtvec;
            12'h340: csr_read_data = csr_mscratch;
            12'h341: csr_read_data = csr_mepc;
            12'h342: csr_read_data = csr_mcause;
            12'h343: csr_read_data = csr_mtval;
            12'h344: csr_read_data = csr_mip;
            12'hB02: csr_read_data = csr_minstret[31:0];
            12'hB82: csr_read_data = csr_minstret[63:32];
            12'hB03: csr_read_data = csr_mtime[31:0];
            12'hB83: csr_read_data = csr_mtime[63:32];
            12'hB04: csr_read_data = csr_mtimecmp[31:0];
            12'hB84: csr_read_data = csr_mtimecmp[63:32];
            12'hB88: csr_read_data = {27'b0, csr_mcctr};
            12'hF11: csr_read_data = CSR_MVENDORID_VALUE;
            12'hF12: csr_read_data = 32'b0; // marchid
            12'hF13: csr_read_data = CSR_MIMPID_VALUE;
            12'hF14: csr_read_data = 32'b0; // mhartid: one hart
            default: csr_read_data = 32'b0;
        endcase
    end

    // CSRRS/CSRRC with rs1=x0 (or zimm=0) are reads only.
    always @(*) begin
        csr_wen        = 1'b0;
        csr_write_data = csr_read_data;
        if (csr_valid && csr_writable) begin
            case (csr_op)
                3'b001, 3'b101: begin // CSRRW/CSRRWI
                    csr_wen        = 1'b1;
                    csr_write_data = csr_src;
                end
                3'b010, 3'b110: begin // CSRRS/CSRRSI
                    csr_wen        = |csr_src;
                    csr_write_data = csr_read_data | csr_src;
                end
                3'b011, 3'b111: begin // CSRRC/CSRRCI
                    csr_wen        = |csr_src;
                    csr_write_data = csr_read_data & ~csr_src;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            csr_mtime    <= 64'b0;
            csr_mtimecmp <= 64'hffff_ffff_ffff_ffff;
            csr_minstret <= 64'b0;
            //保留项目计数器门，但使mtime运行由
			//默认设置，以便配置的定时器能够真正变为待处理状态。
            csr_mcctr    <= 5'b00100;
        end else begin
            if (csr_wen && (csr_addr == 12'hB03))
                csr_mtime[31:0] <= csr_write_data;
            else if (csr_wen && (csr_addr == 12'hB83))
                csr_mtime[63:32] <= csr_write_data;
            else if (csr_mcctr[2])
                csr_mtime <= csr_mtime + 64'd1;

            if (csr_wen && (csr_addr == 12'hB04))
                csr_mtimecmp[31:0] <= csr_write_data;
            else if (csr_wen && (csr_addr == 12'hB84))
                csr_mtimecmp[63:32] <= csr_write_data;

            if (csr_wen && (csr_addr == 12'hB02))
                csr_minstret[31:0] <= csr_write_data;
            else if (csr_wen && (csr_addr == 12'hB82))
                csr_minstret[63:32] <= csr_write_data;
            else if (csr_mcctr[1])
                csr_minstret <= csr_minstret + 64'd1;

            if (csr_wen && (csr_addr == 12'hB88))
                csr_mcctr <= csr_write_data[4:0];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            csr_mstatus  <= MSTATUS_RESET;
            csr_mie      <= 32'b0;
            csr_mtvec    <= 32'b0;
            csr_mscratch <= 32'b0;
            csr_mepc     <= 32'b0;
            csr_mcause   <= 32'b0;
            csr_mtval    <= 32'b0;
        end else if (take_exception) begin
            // Trap entry: MPIE <= MIE, MIE <= 0, MPP <= M (11).
            csr_mstatus <= {19'b0, 2'b11, 3'b0, csr_mstatus[3],
                            3'b0, 1'b0, 3'b0};
            csr_mepc    <= current_pc & 32'hffff_fffc;
            csr_mcause  <= is_ecall ? 32'd11 : 32'd3;
            csr_mtval   <= 32'b0;
        end else if (take_interrupt) begin
            csr_mstatus <= {19'b0, 2'b11, 3'b0, interrupt_mie,
                            3'b0, 1'b0, 3'b0};
            csr_mepc    <= is_mret ? csr_mepc :
                                    ((current_pc + 32'd4) & 32'hffff_fffc);
            csr_mcause  <= take_external_irq ? 32'h8000_000b :
                                                32'h8000_0007;
            csr_mtval   <= 32'b0;
        end else if (is_mret) begin
            // MRET: MIE <= MPIE, MPIE <= 1, MPP <= M M-only.
            csr_mstatus <= {19'b0, 2'b11, 3'b0, 1'b1,
                            3'b0, csr_mstatus[7], 3'b0};
        end else if (csr_wen) begin
            case (csr_addr)
                // Only implemented M-mode fields are writable; MPP is M
                12'h300: csr_mstatus <= {19'b0, 2'b11, 3'b0,
                                          csr_write_data[7], 3'b0,
                                          csr_write_data[3], 3'b0};
                12'h304: csr_mie      <= csr_write_data & MIE_WR_MASK;
                // Direct mode only; force MODE=00 and 4-byte alignment
                12'h305: csr_mtvec    <= csr_write_data & 32'hffff_fffc;
                12'h340: csr_mscratch <= csr_write_data;
                12'h341: csr_mepc     <= csr_write_data & 32'hffff_fffc;
                12'h342: csr_mcause   <= csr_write_data;
                12'h343: csr_mtval    <= csr_write_data;
                default: ;
            endcase
        end
    end

    assign csr_rdata      = csr_read_data;
    assign redirect_valid = take_exception || is_mret || take_interrupt;
    assign redirect_pc    = (is_mret && !take_interrupt) ? csr_mepc :
                           (csr_mtvec & 32'hffff_fffc);

endmodule
