`timescale 1ns / 1ps

module Htop #(
    parameter RESET_PC = 32'h8000_0000,
    parameter BRAM_MODE = 1'b0,
    parameter [31:0] DDR_BASE   = 32'h8000_0000,
    parameter [31:0] DDR_BYTES  = 32'h4000_0000,
    parameter [31:0] IRAM_BASE  = 32'h8000_0000,
    parameter [31:0] IRAM_BYTES = 32'h0000_8000,
    parameter [31:0] DRAM_BASE  = 32'h8000_8000,
    parameter [31:0] DRAM_BYTES = 32'h0000_4000,
    // 仅 DCache 使用此窗口判断是否允许分配 Cache Line；完整 DDR 窗口仍
    // 传给 ICache 和 AXI backend。默认值保持旧设计的“全部 DDR 可缓存”。
    parameter [31:0] DCACHEABLE_DDR_BASE  = DDR_BASE,
    parameter [31:0] DCACHEABLE_DDR_BYTES = DDR_BYTES
) (
    input         clk,
    input         rst,
    // Aggregated M-mode external interrupt, active high.
    input         irq_external,

    // Optional synchronous programming/readback port for BRAM_MODE.
    input         bram_prog_valid,
    input         bram_prog_write,
    input  [31:0] bram_prog_addr,
    input  [31:0] bram_prog_wdata,
    input  [3:0]  bram_prog_wstrb,
    output wire   bram_prog_ready,
    output wire [31:0] bram_prog_rdata,

    // ---- AXI4 master (32-bit data) ----
    output wire [3:0]  axi_awid,
    output wire [31:0] axi_awaddr,
    output wire [7:0]  axi_awlen,
    output wire [2:0]  axi_awsize,
    output wire [1:0]  axi_awburst,
    output wire        axi_awvalid,
    input  wire        axi_awready,

    output wire [3:0]  axi_wid,
    output wire [31:0] axi_wdata,
    output wire [3:0]  axi_wstrb,
    output wire        axi_wlast,
    output wire        axi_wvalid,
    input  wire        axi_wready,

    input  wire [3:0]  axi_bid,
    input  wire [1:0]  axi_bresp,
    input  wire        axi_bvalid,
    output wire        axi_bready,

    output wire [3:0]  axi_arid,
    output wire [31:0] axi_araddr,
    output wire [7:0]  axi_arlen,
    output wire [2:0]  axi_arsize,
    output wire [1:0]  axi_arburst,
    output wire        axi_arvalid,
    input  wire        axi_arready,

    input  wire [3:0]  axi_rid,
    input  wire [31:0] axi_rdata,
    input  wire [1:0]  axi_rresp,
    input  wire        axi_rlast,
    input  wire        axi_rvalid,
    output wire        axi_rready,

    // ---- debug / status exports (unchanged from the previous top) ----
    output wire [31:0] pc,
    output wire [31:0] ins,
    output wire        is_ebreak,
    output wire        icache_miss,
    output wire        dcache_miss,

    output wire [31:0] debug_if_pc,
    output wire [31:0] debug_id_pc,
    output wire [31:0] debug_ex_pc,
    output wire [31:0] debug_mem_pc,
    output wire [31:0] debug_wb_pc,
    output wire [31:0] debug_if_ins,
    output wire [31:0] debug_id_ins,
    output wire [31:0] debug_ex_ins,
    output wire [31:0] debug_mem_ins,
    output wire [31:0] debug_wb_ins,
    output wire [31:0] debug_dmem_addr,
    output wire [31:0] debug_dmem_wdata,
    output wire [31:0] debug_btb_predict_next_pc,
    output wire [31:0] debug_actual_next_pc,
    output wire [31:0] debug_flush_pc,
    output wire [31:0] debug_ctrl
);

    // ------------------------------------------------------------------
    // pipeline control wires (kept from the previous Htop)
    // ------------------------------------------------------------------
    wire        if_to_id_valid;
    wire [31:0] if_pc;
    wire [31:0] if_ins;
    wire [31:0] if_req_pc;
    wire        if_req_valid;
    wire        if_req_ready;
    wire        if_resp_valid;
    wire [31:0] if_resp_data;
    wire        bram_if_ready;
    wire        bram_if_resp_valid;
    wire [31:0] bram_if_resp_data;

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
    wire        mem_load_wait;

    wire [31:0] wb_pc;
    wire [31:0] wb_ins;
    wire        wb_valid;
    wire        wb_allowin;
    wire        wb_reg_wen;
    wire [4:0]  wb_rd_addr;
    wire [31:0] wb_data;
    wire        wb_is_ebreak;

    // EX exceptions have priority over ID.
    wire        flush    = ex_flush_req || id_flush_req;
    wire [31:0] flush_pc = ex_flush_req ? ex_flush_pc : actual_next_pc;

    wire [31:0] btb_lookup_pc;
    wire [31:0] if_btb_lookup_pc;
    wire        btb_lookup_hit;
    wire        btb_lookup_match;
    wire        btb_lookup_predict_taken;
    wire [31:0] btb_look_up_target;
    wire        btb_update_valid;
    wire        btb_update_valid_id;
    wire [31:0] btb_update_pc;
    wire [31:0] btb_update_target;
    wire        btb_update_is_conditional;
    wire        btb_update_taken;
    wire [31:0] btb_predict_next_pc;
    wire [31:0] actual_next_pc;

    // ---- LSU / cache buses -------------------------------------------
    wire        dmem_valid;
    wire        dmem_wen;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [3:0]  dmem_wmask;
    wire        dmem_ready;
    wire        dmem_rsp_valid;
    wire [31:0] dmem_rdata;
    wire        bram_data_local;
    wire        bram_data_ready;
    wire        bram_data_rsp_valid;
    wire [31:0] bram_data_rsp_data;
    reg         bram_load_route_valid;
    reg         bram_load_route_local;
    always @(posedge clk) begin
        if (rst || !BRAM_MODE) begin
            bram_load_route_valid <= 1'b0;
            bram_load_route_local <= 1'b0;
        end else if (dmem_valid && !dmem_wen && dmem_ready) begin
            bram_load_route_valid <= 1'b1;
            bram_load_route_local <= bram_data_local;
        end else if (dmem_rsp_valid) begin
            bram_load_route_valid <= 1'b0;
        end
    end

    // dcache <-> axi_bridge (data channel)
    wire        dc_rd_req;
    wire [2:0]  dc_rd_type;
    wire [31:0] dc_rd_addr;
    wire        dc_rd_rdy;
    wire        dc_ret_valid;
    wire        dc_ret_last;
    wire [31:0] dc_ret_data;
    wire        dc_wr_req;
    wire [2:0]  dc_wr_type;
    wire [31:0] dc_wr_addr;
    wire [3:0]  dc_wr_wstrb;
    wire [127:0]dc_wr_data;
    wire        dc_wr_rdy;

    // icache <-> axi_bridge (instruction channel)
    wire        ic_rd_req;
    wire [2:0]  ic_rd_type;
    wire [31:0] ic_rd_addr;
    wire        ic_rd_rdy;
    wire        ic_ret_valid;
    wire        ic_ret_last;
    wire [31:0] ic_ret_data;
    wire        ic_wr_req;
    wire [2:0]  ic_wr_type;
    wire [31:0] ic_wr_addr;
    wire [3:0]  ic_wr_wstrb;
    wire [127:0]ic_wr_data;
    wire        ic_wr_rdy;

    // Debug source signals (unchanged semantics as the previous Htop).
    wire dbg_if_valid;
    wire dbg_if_allowin;
    wire dbg_id_valid;
    wire dbg_id_stall;
    wire dbg_id_ready_go;
    wire dbg_mispredict;
    wire dbg_ex_ready_go;
    wire dbg_mem_valid;
    wire dbg_mem_ready_go;

    // IFU + icache
    Hifu #(.RESET_PC(RESET_PC), .CONTINUOUS_FETCH(BRAM_MODE)) u_ifu (
        .clk            (clk),
        .rst            (rst),
        .id_allowin     (id_allowin),
        .flush          (flush),
        .redirect_pc    (flush_pc),
        .imem_rdata     (BRAM_MODE ? bram_if_resp_data : if_resp_data),
        .imem_resp_valid(BRAM_MODE ? bram_if_resp_valid : if_resp_valid),
        .imem_req_ready (BRAM_MODE ? bram_if_ready : if_req_ready),
        .imem_req_valid (if_req_valid),
        //btb
        .btb_hit        (btb_lookup_hit),
        .btb_target     (btb_look_up_target),
        .predict_next_pc(btb_predict_next_pc),
        .imem_addr      (if_req_pc),
        .if_ins         (if_ins),
        .if_pc          (if_pc),
        .if_to_id_valid (if_to_id_valid),
        .btb_lookup_pc  (if_btb_lookup_pc),
        .dbg_if_valid   (dbg_if_valid),
        .dbg_if_allowin (dbg_if_allowin)
    );

    generate if (!BRAM_MODE) begin: gen_icache
    icache #(
        .DDR_BASE   (DDR_BASE),
        .DDR_BYTES  (DDR_BYTES)
    ) u_icache (
        .clk            (clk),
        .rst            (rst),
        .flush          (flush),
        .cpu_req_valid  (if_req_valid),
        .cpu_req_pc     (if_req_pc),
        .cpu_req_ready  (if_req_ready),
        .cpu_resp_valid (if_resp_valid),
        .cpu_resp_data  (if_resp_data),
        .cache_miss     (icache_miss),

        .rd_req         (ic_rd_req),
        .rd_type        (ic_rd_type),
        .rd_addr        (ic_rd_addr),
        .rd_rdy         (ic_rd_rdy),
        .ret_valid      (ic_ret_valid),
        .ret_last       (ic_ret_last),
        .ret_data       (ic_ret_data),

        .wr_req         (ic_wr_req),
        .wr_type        (ic_wr_type),
        .wr_addr        (ic_wr_addr),
        .wr_wstrb       (ic_wr_wstrb),
        .wr_data        (ic_wr_data),
        .wr_rdy         (ic_wr_rdy)
    );
    end else begin: gen_no_icache
        assign if_req_ready = 1'b0;
        assign if_resp_valid = 1'b0;
        assign if_resp_data = 32'b0;
        assign ic_rd_req = 1'b0;
        assign ic_rd_type = 3'b0;
        assign ic_rd_addr = 32'b0;
        assign ic_wr_req = 1'b0;
        assign ic_wr_type = 3'b0;
        assign ic_wr_addr = 32'b0;
        assign ic_wr_wstrb = 4'b0;
        assign ic_wr_data = 128'b0;
        assign icache_miss = 1'b0;
    end endgenerate

    generate if (BRAM_MODE) begin: gen_cpu_bram
        cpu_bram_mem #(
            .IRAM_BASE(IRAM_BASE), .IRAM_BYTES(IRAM_BYTES),
            .DRAM_BASE(DRAM_BASE), .DRAM_BYTES(DRAM_BYTES)
        ) u_bram_mem (
            .clk(clk), .rst(rst),
            .if_req_valid(if_req_valid), .if_req_addr(if_req_pc),
            .if_req_ready(bram_if_ready), .if_rsp_valid(bram_if_resp_valid),
            .if_rsp_data(bram_if_resp_data),
            .data_req_valid(dmem_valid), .data_req_write(dmem_wen),
            .data_req_addr(dmem_addr), .data_req_wdata(dmem_wdata),
            .data_req_wstrb(dmem_wmask), .data_req_ready(bram_data_ready),
            .data_rsp_valid(bram_data_rsp_valid), .data_rsp_data(bram_data_rsp_data),
            .data_addr_local(bram_data_local),
            .prog_valid(bram_prog_valid), .prog_write(bram_prog_write),
            .prog_addr(bram_prog_addr), .prog_wdata(bram_prog_wdata),
            .prog_wstrb(bram_prog_wstrb), .prog_ready(bram_prog_ready),
            .prog_rdata(bram_prog_rdata)
        );
        assign dmem_ready = !rst && (bram_data_local ? bram_data_ready :
                            ((ex_ins[6:0] == 7'b0100011) ? dc_wr_rdy : dc_rd_rdy));
        assign dmem_rsp_valid = bram_load_route_valid &&
                                (bram_load_route_local ? bram_data_rsp_valid :
                                 (dc_ret_valid && dc_ret_last));
        assign dmem_rdata = bram_load_route_local ? bram_data_rsp_data : dc_ret_data;
    end else begin: gen_no_cpu_bram
        assign bram_if_ready = 1'b0;
        assign bram_if_resp_valid = 1'b0;
        assign bram_if_resp_data = 32'b0;
        assign bram_data_local = 1'b0;
        assign bram_data_ready = 1'b0;
        assign bram_data_rsp_valid = 1'b0;
        assign bram_data_rsp_data = 32'b0;
        assign bram_prog_ready = 1'b0;
        assign bram_prog_rdata = 32'b0;
    end endgenerate

    // Branch predictor
    assign btb_lookup_pc = BRAM_MODE ? if_btb_lookup_pc : if_pc;
    Btb u_btb (
        .clk            (clk),
        .rst            (rst),
        .lookup_pc      (btb_lookup_pc),
        .update_valid   (btb_update_valid),
        .update_pc      (btb_update_pc),
        .update_target  (btb_update_target),
        .update_is_conditional (btb_update_is_conditional),
        .update_taken   (btb_update_taken),
        .lookup_match   (btb_lookup_match),
        .lookup_predict_taken (btb_lookup_predict_taken),
        .lookup_hit     (btb_lookup_hit),
        .lookup_target  (btb_look_up_target)
    );

    //An older EX-stage CSR redirect wins over an ID update
    assign btb_update_valid = btb_update_valid_id && !ex_flush_req;

    // ID
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
        .mem_load_wait      (mem_load_wait),
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
        .id_redirect_pc     (id_redirect_pc),
        //btb
        .btb_update_pc      (btb_update_pc),
        .btb_update_valid   (btb_update_valid_id),
        .btb_update_target  (btb_update_target),
        .btb_update_is_conditional (btb_update_is_conditional),
        .btb_update_taken   (btb_update_taken),
        .btb_predict_next_pc(btb_predict_next_pc),
        .actual_next_pc     (actual_next_pc),
        .dbg_id_valid       (dbg_id_valid),
        .dbg_id_stall       (dbg_id_stall),
        .dbg_id_ready_go    (dbg_id_ready_go),
        .dbg_mispredict     (dbg_mispredict)
    );

    // EX (memory request goes to dcache)
    Hexu u_exu (
        .clk                 (clk),
        .rst                 (rst),
        .irq_external        (irq_external),
        .id_to_ex_valid      (id_to_ex_valid),
        .mem_allowin         (mem_allowin),
        .flush               (ex_flush_req),
        .id_pc               (id_pc),
        .id_ins              (id_ins),
        .id_imm              (id_imm),
        .id_src1             (id_src1),
        .id_src2             (id_src2),
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
        .id_wb_sel           (id_wb_sel),
        .id_is_csr           (id_is_csr),
        .id_csr_op           (id_csr_op),
        .id_csr_addr         (id_csr_addr),
        .id_csr_imm          (id_csr_imm),
        .id_is_ecall         (id_is_ecall),
        .id_is_mret          (id_is_mret),
        .id_is_ebreak        (id_is_ebreak),
        .ex_valid            (ex_valid),
        .ex_allowin          (ex_allowin),
        .ex_to_mem_valid     (ex_to_mem_valid),
        .ex_pc               (ex_pc),
        .ex_ins              (ex_ins),
        .ex_rd_addr          (ex_rd_addr),
        .ex_is_load          (ex_is_load),
        .ex_mem_funct3       (ex_mem_funct3),
        .ex_reg_wen          (ex_reg_wen),
        .ex_wb_sel           (ex_wb_sel),
        .ex_is_ebreak        (ex_is_ebreak),
        .ex_result           (ex_result),
        .ex_forward_valid    (ex_forward_valid),
        .ex_forward_rd_addr  (ex_forward_rd_addr),
        .ex_forward_data     (ex_forward_data),
        .ex_flush_req        (ex_flush_req),
        .ex_flush_pc         (ex_flush_pc),
        .ex_wb_value         (ex_wb_value),
        .dbg_ex_ready_go     (dbg_ex_ready_go),
        .dmem_valid          (dmem_valid),
        .dmem_wen            (dmem_wen),
        .dmem_addr           (dmem_addr),
        .dmem_wdata          (dmem_wdata),
        .dmem_wmask          (dmem_wmask),
        .dmem_ready          (dmem_ready)
    );

    generate if (!BRAM_MODE) begin: gen_dcache
    dcache #(
        .CACHEABLE_DDR_BASE      (DCACHEABLE_DDR_BASE),
        .CACHEABLE_DDR_BYTES     (DCACHEABLE_DDR_BYTES)
    ) u_dcache (
        .clk             (clk),
        .rst             (rst),
        .dmem_req_valid  (dmem_valid),
        .dmem_req_write  (dmem_wen),
        .dmem_req_addr   (dmem_addr),
        .dmem_req_wdata  (dmem_wdata),
        .dmem_req_wstrb  (dmem_wmask),
        .dmem_req_ready  (dmem_ready),
        .dmem_rsp_valid  (dmem_rsp_valid),
        .dmem_rsp_data   (dmem_rdata),
        .cache_miss      (dcache_miss),

        .rd_req          (dc_rd_req),
        .rd_type         (dc_rd_type),
        .rd_addr         (dc_rd_addr),
        .rd_rdy          (dc_rd_rdy),
        .ret_valid       (dc_ret_valid),
        .ret_last        (dc_ret_last),
        .ret_data        (dc_ret_data),
        .wr_req          (dc_wr_req),
        .wr_type         (dc_wr_type),
        .wr_addr         (dc_wr_addr),
        .wr_wstrb        (dc_wr_wstrb),
        .wr_data         (dc_wr_data),
        .wr_rdy          (dc_wr_rdy)
    );
    end else begin: gen_no_dcache
        assign dc_rd_req = dmem_valid && !bram_data_local && !dmem_wen;
        assign dc_rd_type = 3'b010;
        assign dc_rd_addr = {dmem_addr[31:2], 2'b00};
        assign dc_wr_req = dmem_valid && !bram_data_local && dmem_wen;
        assign dc_wr_type = 3'b010;
        assign dc_wr_addr = {dmem_addr[31:2], 2'b00};
        assign dc_wr_wstrb = dmem_wmask;
        assign dc_wr_data = {96'b0, dmem_wdata};
        assign dcache_miss = 1'b0;
    end endgenerate

    //MEM
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
        .dmem_rsp_valid   (dmem_rsp_valid),
        .mem_pc           (mem_pc),
        .mem_ins          (mem_ins),
        .mem_allowin      (mem_allowin),
        .mem_to_wb_valid  (mem_to_wb_valid),
        .mem_rd_addr      (mem_rd_addr),
        .mem_reg_wen      (mem_reg_wen),
        .mem_is_ebreak    (mem_is_ebreak),
        .mem_wb_data      (mem_wb_data),
        .mem_forward_valid(mem_forward_valid),
        .mem_load_wait     (mem_load_wait),
        .dbg_mem_valid    (dbg_mem_valid),
        .dbg_mem_ready_go (dbg_mem_ready_go)
    );

    // WB
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

    // axi_bridge (merges icache + dcache onto one AXI master)
    axi_bridge u_axi_bridge (
        .clk               (clk),
        .reset             (rst),

        .arid              (axi_arid),
        .araddr            (axi_araddr),
        .arlen             (axi_arlen),
        .arsize            (axi_arsize),
        .arburst           (axi_arburst),
        .arlock            (),
        .arcache           (),
        .arprot            (),
        .arvalid           (axi_arvalid),
        .arready           (axi_arready),

        .rid               (axi_rid),
        .rdata             (axi_rdata),
        .rresp             (axi_rresp),
        .rlast             (axi_rlast),
        .rvalid            (axi_rvalid),
        .rready            (axi_rready),

        .awid              (axi_awid),
        .awaddr            (axi_awaddr),
        .awlen             (axi_awlen),
        .awsize            (axi_awsize),
        .awburst           (axi_awburst),
        .awlock            (),
        .awcache           (),
        .awprot            (),
        .awvalid           (axi_awvalid),
        .awready           (axi_awready),

        .wid               (axi_wid),
        .wdata             (axi_wdata),
        .wstrb             (axi_wstrb),
        .wlast             (axi_wlast),
        .wvalid            (axi_wvalid),
        .wready            (axi_wready),

        .bid               (axi_bid),
        .bresp             (axi_bresp),
        .bvalid            (axi_bvalid),
        .bready            (axi_bready),

        .inst_rd_req       (ic_rd_req),
        .inst_rd_type      (ic_rd_type),
        .inst_rd_addr      (ic_rd_addr),
        .inst_rd_rdy       (ic_rd_rdy),
        .inst_ret_valid    (ic_ret_valid),
        .inst_ret_last     (ic_ret_last),
        .inst_ret_data     (ic_ret_data),
        .inst_wr_req       (ic_wr_req),
        .inst_wr_type      (ic_wr_type),
        .inst_wr_addr      (ic_wr_addr),
        .inst_wr_wstrb     (ic_wr_wstrb),
        .inst_wr_data      (ic_wr_data),
        .inst_wr_rdy       (ic_wr_rdy),

        .data_rd_req       (dc_rd_req),
        .data_rd_type      (dc_rd_type),
        .data_rd_addr      (dc_rd_addr),
        .data_rd_rdy       (dc_rd_rdy),
        .data_ret_valid    (dc_ret_valid),
        .data_ret_last     (dc_ret_last),
        .data_ret_data     (dc_ret_data),
        .data_wr_req       (dc_wr_req),
        .data_wr_type      (dc_wr_type),
        .data_wr_addr      (dc_wr_addr),
        .data_wr_wstrb     (dc_wr_wstrb),
        .data_wr_data      (dc_wr_data),
        .data_wr_rdy       (dc_wr_rdy),
        .write_buffer_empty()
    );

    assign pc        = wb_pc;
    assign ins       = wb_ins;
    assign is_ebreak = wb_is_ebreak;

    // debug exports
    assign debug_if_pc               = if_pc;
    assign debug_id_pc               = id_pc;
    assign debug_ex_pc               = ex_pc;
    assign debug_mem_pc              = mem_pc;
    assign debug_wb_pc               = wb_pc;
    assign debug_if_ins              = if_ins;
    assign debug_id_ins              = id_ins;
    assign debug_ex_ins              = ex_ins;
    assign debug_mem_ins             = mem_ins;
    assign debug_wb_ins              = wb_ins;
    assign debug_dmem_addr           = dmem_addr;
    assign debug_dmem_wdata          = dmem_wdata;
    assign debug_btb_predict_next_pc = btb_predict_next_pc;
    assign debug_actual_next_pc      = actual_next_pc;
    assign debug_flush_pc            = flush_pc;

    // ctrl bit map kept identical to the previous Htop.
    assign debug_ctrl = {dmem_wmask, 1'b0, btb_update_valid, btb_lookup_predict_taken,
                         btb_lookup_match, dbg_mispredict, ex_flush_req, flush,
                         dmem_ready, dmem_wen, dmem_valid,
                         wb_allowin, wb_valid,
                         dbg_mem_ready_go, mem_allowin, mem_to_wb_valid,
                         dbg_mem_valid,
                         dbg_ex_ready_go, ex_allowin, ex_to_mem_valid, ex_valid,
                         dbg_id_ready_go, id_allowin, id_to_ex_valid,
                         dbg_id_stall, dbg_id_valid,
                         dbg_if_allowin, if_to_id_valid, dbg_if_valid};

endmodule
