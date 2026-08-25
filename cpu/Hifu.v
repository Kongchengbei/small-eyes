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
    output wire [31:0] imem_addr,

    output wire [31:0] if_ins,
    output wire [31:0] if_pc,
    output wire        if_to_id_valid
);

    wire [31:0] pf_next_pc;
    wire        pf_issue;


    reg [31:0] if_pc_reg;
	//控制信号
    reg        if_valid;
    wire       if_allowin;
	wire       if_ready_go;

	assign if_ready_go    =  1'b1;
    assign if_allowin     = !if_valid || (if_ready_go && id_allowin);
    assign if_to_id_valid = if_valid && if_ready_go;

    assign pf_next_pc = flush ? redirect_pc : (if_pc_reg + 32'd4);
    assign pf_issue   = flush || if_allowin; //是否更新pc到imem_addr

    assign imem_addr      = pf_issue ? pf_next_pc : if_pc_reg;

    always @(posedge clk) begin
        if (rst) begin
            if_pc_reg <= RESET_PC - 32'd4;
            if_valid  <= 1'b0;
        end else if (pf_issue) begin
            if_pc_reg <= pf_next_pc;
            if_valid  <= 1'b1;
        end
    end

	//输出id的数据
    assign if_pc          = if_pc_reg;
    assign if_ins         = imem_rdata;
endmodule
