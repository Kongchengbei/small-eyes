`timescale 1ns / 1ps

module Hifu #(
    parameter [31:0] RESET_PC = 32'h8000_0000
) (
    input              clk,
    input              rst,

    input              id_allowin,
    input              flush,
    input       [31:0] redirect_pc,

    input       [31:0] imem_rdata,
    input              imem_resp_valid,
    input              imem_req_ready,
    output wire        imem_req_valid,
    output wire [31:0] imem_addr,

    output wire [31:0] if_ins,
    output wire [31:0] if_pc,
    output wire        if_to_id_valid,

    // 调试观测：保留 IF 级真实 valid/allowin，供 Htop 打包到调试总线
    output wire        dbg_if_valid,
    output wire        dbg_if_allowin,

    //增加btb的
    input  wire [31:0] btb_target,
    input  wire        btb_hit,
    output wire [31:0] predict_next_pc
);
    
    
    wire [31:0] if_predict_next_pc;

    reg [31:0] if_pc_reg;
	reg [31:0] if_ins_reg;
	reg [31:0] fetch_pc_reg;
	reg        fetch_pending;
	reg [31:0] forced_fetch_pc;
	reg        force_fetch;
	//控制信号
    reg        if_valid;
    wire       if_allowin;
	wire       if_ready_go;

///////////////////////////////////////////////////////////
	assign if_ready_go    =  1'b1;
    assign if_allowin     = !if_valid || (if_ready_go && id_allowin);
    assign if_to_id_valid = if_valid && if_ready_go;
    assign dbg_if_valid   = if_valid;
    assign dbg_if_allowin = if_allowin;
    assign if_predict_next_pc = (btb_hit ? btb_target : (if_pc_reg + 32'd4));
    assign imem_addr         = flush ? redirect_pc :
	                             force_fetch ? forced_fetch_pc :
	                             if_predict_next_pc;
    assign imem_req_valid    = !flush && !fetch_pending && if_allowin;
  
    always @(posedge clk) begin
        if (rst) begin
            if_pc_reg <= RESET_PC - 32'd4;
            if_ins_reg <= 32'h0000_0013;
			fetch_pc_reg <= 32'b0;
			fetch_pending <= 1'b0;
			forced_fetch_pc <= RESET_PC;
			force_fetch <= 1'b1;
            if_valid  <= 1'b0;
        end else if (flush) begin
            // Keep the next sequential calculation anchored at the
            // redirect target while the cache discards any old miss.
            if_pc_reg      <= redirect_pc - 32'd4;
			if_ins_reg      <= 32'h0000_0013;
			fetch_pending   <= 1'b0;
			forced_fetch_pc <= redirect_pc;
			force_fetch    <= 1'b1;
			if_valid        <= 1'b0;
        end else begin
			if (if_valid && id_allowin)
				if_valid <= 1'b0;

			if (imem_req_valid && imem_req_ready) begin
				fetch_pc_reg  <= imem_addr;
				fetch_pending <= 1'b1;
				force_fetch   <= 1'b0;
			end

			if (imem_resp_valid && fetch_pending) begin
				if_pc_reg      <= fetch_pc_reg;
				if_ins_reg     <= imem_rdata;
				fetch_pending  <= 1'b0;
				if_valid       <= 1'b1;
			end
        end
    end


	//输出id的数据
	    assign if_pc           = if_pc_reg;
	    assign if_ins          = if_ins_reg;
    //btb输出的下一条的指令pc
    assign predict_next_pc = if_predict_next_pc; 

endmodule
