`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// RV32IM machine-mode CSR block.
module Hcsr #(
    parameter [31:0] CPU_HZ = `SOC_CPU_HZ
) (
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
    // 保持现有 ABI：低 15 位为频率 / 10 kHz，高位的存储容量信息不变。
    localparam [31:0] CSR_MIMPID_VALUE    = 32'h1020_0000 | (CPU_HZ / 32'd10000);
    localparam [31:0] MSTATUS_RESET       = 32'h0000_1800;
    localparam [31:0] MIE_WR_MASK         = 32'h0000_0880; // MEIE, MTIE

    reg [31:0] csr_mstatus;
    reg [31:0] csr_mie;
    reg [31:0] csr_mtvec;
    reg [31:0] csr_mscratch;
    reg [31:0] csr_mepc;
    localparam [2:0] MCAUSE_ZERO = 3'd0, MCAUSE_SOFTWARE = 3'd1,
                     MCAUSE_ECALL = 3'd2, MCAUSE_EBREAK = 3'd3,
                     MCAUSE_EXTERNAL = 3'd4, MCAUSE_TIMER = 3'd5;
    reg [31:0] csr_mcause_data;
    reg [2:0]  csr_mcause_kind;
    reg [31:0] csr_mtval_data;
    reg        csr_mtval_zero;
    // Trap entry changes a small state tag instead of distributing a late
    // trap enable/reset across both 32-bit software-writable payload banks.
    wire [31:0] csr_mcause = (csr_mcause_kind == MCAUSE_SOFTWARE) ? csr_mcause_data :
                             (csr_mcause_kind == MCAUSE_ECALL) ? 32'd11 :
                             (csr_mcause_kind == MCAUSE_EBREAK) ? 32'd3 :
                             (csr_mcause_kind == MCAUSE_EXTERNAL) ? 32'h8000_000b :
                             (csr_mcause_kind == MCAUSE_TIMER) ? 32'h8000_0007 : 32'b0;
    wire [31:0] csr_mtval = csr_mtval_zero ? 32'b0 : csr_mtval_data;
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
    // Pending/enabled sources depend on registered CSR state. Merge them
    // before applying the late EX retirement boundary rather than fanning
    // that boundary through both source decoders and merging afterward.
    wire external_irq_enabled_pending = csr_mie[11] && external_pending;
    wire timer_irq_enabled_pending = csr_mie[7] && timer_pending;
    wire irq_enabled_pending = external_irq_enabled_pending || timer_irq_enabled_pending;
    wire take_interrupt = interrupt_check && interrupt_mie && irq_enabled_pending;
    wire take_exception    = is_ecall || is_ebreak;

    reg        csr_wen;
    reg [31:0] csr_read_data;
    reg [31:0] csr_write_data;
    wire [31:0] csr_src = csr_op[2] ? {27'b0, csr_imm} : csr_rs1_data;

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
        // Decode write intent here; each actual register below checks its
        // own writable address. Read-only/unknown addresses have no write
        // destination. Avoid a global address-OR followed by another decode.
        if (csr_valid) begin
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

    wire mtime_write_low  = csr_wen && (csr_addr == 12'hB03);
    wire mtime_write_high = csr_wen && (csr_addr == 12'hB83);
    wire mtime_count = csr_mcctr[2] && !mtime_write_low && !mtime_write_high;
    wire minstret_write_low  = csr_wen && (csr_addr == 12'hB02);
    wire minstret_write_high = csr_wen && (csr_addr == 12'hB82);
    wire minstret_count = csr_mcctr[1] && !minstret_write_low && !minstret_write_high;

    // A same-edge trap/reset masks any speculative payload write via the
    // tags below. Every later software write replaces the full payload before
    // its tag selects it, preserving CSRRW/CSRRS/CSRRC read/modify/write data.
    always @(posedge clk) begin
        // MRET holds the visible tags, so it must also hold any payload that
        // they already select. Trap/reset instead select a constant value.
        if (!is_mret && csr_wen && (csr_addr == 12'h342))
            csr_mcause_data <= csr_write_data;
        if (!is_mret && csr_wen && (csr_addr == 12'h343))
            csr_mtval_data <= csr_write_data;
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
            // A software write to either half suppresses the entire counter
            // increment, matching the original priority. Otherwise the high
            // half changes only on the carry from the registered low half.
            if (mtime_write_low)
                csr_mtime[31:0] <= csr_write_data;
            else if (mtime_count)
                csr_mtime[31:0] <= csr_mtime[31:0] + 32'd1;
            if (mtime_write_high)
                csr_mtime[63:32] <= csr_write_data;
            else if (mtime_count && (&csr_mtime[31:0]))
                csr_mtime[63:32] <= csr_mtime[63:32] + 32'd1;

            if (csr_wen && (csr_addr == 12'hB04))
                csr_mtimecmp[31:0] <= csr_write_data;
            else if (csr_wen && (csr_addr == 12'hB84))
                csr_mtimecmp[63:32] <= csr_write_data;

            if (minstret_write_low)
                csr_minstret[31:0] <= csr_write_data;
            else if (minstret_count)
                csr_minstret[31:0] <= csr_minstret[31:0] + 32'd1;
            if (minstret_write_high)
                csr_minstret[63:32] <= csr_write_data;
            else if (minstret_count && (&csr_minstret[31:0]))
                csr_minstret[63:32] <= csr_minstret[63:32] + 32'd1;

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
            csr_mcause_kind <= MCAUSE_ZERO;
            csr_mtval_zero  <= 1'b1;
        end else if (take_exception) begin
            // Trap entry: MPIE <= MIE, MIE <= 0, MPP <= M (11).
            csr_mstatus <= {19'b0, 2'b11, 3'b0, csr_mstatus[3],
                            3'b0, 1'b0, 3'b0};
            csr_mepc    <= current_pc & 32'hffff_fffc;
            csr_mcause_kind <= is_ecall ? MCAUSE_ECALL : MCAUSE_EBREAK;
            csr_mtval_zero  <= 1'b1;
        end else if (take_interrupt) begin
            csr_mstatus <= {19'b0, 2'b11, 3'b0, interrupt_mie,
                            3'b0, 1'b0, 3'b0};
            csr_mepc    <= is_mret ? csr_mepc :
                                    ((current_pc + 32'd4) & 32'hffff_fffc);
            // This choice is sampled only under take_interrupt; an enabled
            // external source keeps priority over an enabled timer source.
            csr_mcause_kind <= external_irq_enabled_pending ? MCAUSE_EXTERNAL : MCAUSE_TIMER;
            csr_mtval_zero  <= 1'b1;
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
                12'h342: csr_mcause_kind <= MCAUSE_SOFTWARE;
                12'h343: csr_mtval_zero  <= 1'b0;
                default: ;
            endcase
        end
    end

    assign csr_rdata      = csr_read_data;
    // MRET always redirects, whether it returns or immediately takes an IRQ.
    // Outside MRET, the IRQ redirect uses the ordinary MIE bit directly. This
    // avoids carrying the MRET/MPIE selection through the EX flush fanout.
    assign redirect_valid = take_exception || is_mret ||
                            (interrupt_boundary && csr_mstatus[3] && irq_enabled_pending);
    assign redirect_pc    = (is_mret && !take_interrupt) ? csr_mepc :
                           (csr_mtvec & 32'hffff_fffc);

endmodule
