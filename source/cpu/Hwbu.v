`timescale 1ns / 1ps

module Hwbu (
    input         clk,
    input         rst,
	input [31:0]  mem_pc,
	input [31:0]  mem_ins,
    input         mem_to_wb_valid,
    input  [31:0] mem_wb_data,
    input  [4:0]  mem_rd_addr,
    input         mem_reg_wen,
    input         mem_is_ebreak,

    output wire        wb_allowin,
    output wire        wb_reg_wen,
    output wire [4:0]  wb_rd_addr,
    output wire [31:0] wb_data,
    output wire        wb_is_ebreak,
	output reg         wb_valid,
	output reg [31:0]  wb_pc,
	output reg [31:0]  wb_ins
);

    reg        wb_reg_wen_reg;
    reg [4:0]  wb_rd_addr_reg;
    reg [31:0] wb_data_reg;
    reg        wb_is_ebreak_reg;
	wire       wb_ready_go;

    assign wb_allowin       = 1'b1;
	assign wb_ready_go      = 1'b1;

    assign wb_reg_wen       = wb_valid && wb_reg_wen_reg;
    assign wb_rd_addr       = wb_rd_addr_reg;
    assign wb_data          = wb_data_reg;
    assign wb_is_ebreak     = wb_valid && wb_is_ebreak_reg;

    always @(posedge clk) begin
        if (rst) begin
            wb_valid         <= 1'b0;
            wb_reg_wen_reg   <= 1'b0;
            wb_rd_addr_reg   <= 5'b0;
            wb_data_reg      <= 32'b0;
            wb_is_ebreak_reg <= 1'b0;
			wb_pc            <= 32'b0;
			wb_ins           <= 32'h0000_0013;
        end else begin
            if (wb_allowin) begin
                wb_valid <= mem_to_wb_valid;
            end

            if (mem_to_wb_valid && wb_allowin) begin
				wb_pc            <= mem_pc;
				wb_ins           <= mem_ins;
                wb_reg_wen_reg   <= mem_reg_wen;
                wb_rd_addr_reg   <= mem_rd_addr;
                wb_data_reg      <= mem_wb_data;
                wb_is_ebreak_reg <= mem_is_ebreak;
            end
        end
    end
endmodule
