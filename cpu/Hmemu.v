`timescale 1ns / 1ps


module Hmemu (
    input             clk,
    input             rst,


    input      [31:0] ex_pc,
    input      [31:0] ex_ins,
    input             wb_allowin,
    input             ex_to_mem_valid,
    input      [31:0] ex_alu_result,
    input      [4:0]  ex_rd_addr,
    input      [2:0]  ex_mem_funct3,
    input             ex_reg_wen,
    input      [1:0]  ex_wb_sel,
    input             ex_is_ebreak,
	input      [31:0] ex_wb_value,

    input      [31:0] dmem_rdata,
    input             dmem_rsp_valid,

	output reg [31:0]  mem_pc,
	output reg [31:0]  mem_ins,
    output wire        mem_allowin,
    output wire        mem_to_wb_valid,
    output wire [31:0] mem_wb_data,
    output wire        mem_forward_valid,
    output wire        mem_load_wait,
    // 调试观测：MEM 级 valid/完成条件
    output wire        dbg_mem_valid,
    output wire        dbg_mem_ready_go,
    output reg  [4:0]  mem_rd_addr,
    output reg         mem_reg_wen,
    output reg         mem_is_ebreak
);

    localparam [1:0] WB_LOAD = 2'b01;
	
    reg        mem_valid;
	wire       mem_ready_go;
    reg [2:0]  mem_funct3;
    reg [1:0]  mem_wb_sel;
    reg [1:0]  mem_offset;
    reg        mem_is_load;
    reg [31:0] mem_ex_wb_value;
    reg        mem_load_resp_received;
    reg [31:0] mem_load_resp_data;


    // A BRAM/MMIO load responds one cpu_clk after its request.  A DDR3 load
    // remains in MEM until the AXI bridge returns its selected 32-bit word.
	assign mem_ready_go    = !mem_valid || !mem_is_load ||
                             mem_load_resp_received || dmem_rsp_valid;
    assign mem_allowin     = !mem_valid || (mem_ready_go && wb_allowin);
    assign mem_to_wb_valid = mem_valid && mem_ready_go;
	//由 cpu/Hidu.v:276(+-) 检查后续指令的 `rs1/rs2` 是否依赖它。若依赖，就继续暂停；数据返回的周期再通过现有 MEM 前递送入 EX
	assign mem_load_wait  = mem_valid && mem_is_load &&
                             !mem_load_resp_received && !dmem_rsp_valid;
    assign dbg_mem_valid   = mem_valid;
    assign dbg_mem_ready_go = mem_ready_go;



	wire [31:0] load_word = mem_load_resp_received ? mem_load_resp_data : dmem_rdata;
	wire [31:0] shifted_rdata = load_word >> (mem_offset * 8);
    reg [31:0] load_data;

    always @(*) begin
        load_data = 32'b0;
        case (mem_funct3)
            3'b000:  load_data = {{24{shifted_rdata[7]}} , shifted_rdata[7:0]};
            3'b001:  load_data = {{16{shifted_rdata[15]}}, shifted_rdata[15:0]};
            3'b010:  load_data = load_word;
            3'b100:  load_data = {24'b0, shifted_rdata[7:0]};
            3'b101:  load_data = {16'b0, shifted_rdata[15:0]};
            default: load_data = 32'b0;
        endcase
    end

    assign mem_wb_data = (mem_wb_sel == WB_LOAD) ? load_data : mem_ex_wb_value;

	// A load must not be forwarded until its cache/MMIO response is valid.
	// Forwarding the placeholder dmem_rdata while MEM is stalled makes a
	// dependent branch observe zero and can terminate byte-copy/string loops
	// at every cache miss.  Non-load results remain immediately available.
    assign mem_forward_valid = mem_valid && mem_reg_wen &&
                               (mem_rd_addr != 5'd0) && mem_ready_go;

    always @(posedge clk) begin
        if (rst) begin
            mem_valid       <= 1'b0;
            mem_rd_addr     <= 5'b0;
            mem_funct3      <= 3'b0;
            mem_reg_wen     <= 1'b0;
            mem_wb_sel      <= 2'b0;
            mem_is_load     <= 1'b0;
            mem_load_resp_received <= 1'b0;
            mem_load_resp_data <= 32'b0;
            mem_is_ebreak   <= 1'b0;
            mem_offset      <= 2'b0;
			mem_pc          <= 32'b0;
            mem_ins         <= 32'h0000_0013;
			mem_ex_wb_value <= 32'b0;
        end else if (mem_allowin) begin
            mem_valid           <= ex_to_mem_valid;
	        mem_load_resp_received <= 1'b0;
    	end

		if (!rst && !mem_allowin && mem_valid && mem_is_load &&
		    dmem_rsp_valid && !mem_load_resp_received) begin
			mem_load_resp_received <= 1'b1;
			mem_load_resp_data <= dmem_rdata;
		end


		if (ex_to_mem_valid && mem_allowin) begin
			mem_pc         <= ex_pc;
            mem_ins        <= ex_ins;
			mem_rd_addr    <= ex_rd_addr;
			mem_funct3     <= ex_mem_funct3;
			mem_reg_wen    <= ex_reg_wen;
			mem_wb_sel     <= ex_wb_sel;
			mem_is_load    <= (ex_wb_sel == WB_LOAD);
			mem_is_ebreak  <= ex_is_ebreak;
			mem_offset     <= ex_alu_result[1:0];
			mem_ex_wb_value<= ex_wb_value;
		end
	end
endmodule
