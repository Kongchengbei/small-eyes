`timescale 1ns/1ps
module Btb(
	input  wire        clk,
	input  wire        rst, 
	input  wire [31:0] lookup_pc,
	input  wire        update_valid,
	input  wire [31:0] update_pc,
	input  wire [31:0] update_target,
	input  wire        update_is_conditional,
	input  wire        update_taken,

	output wire        lookup_hit,
	output wire [31:0] lookup_target
);

wire [3:0]  lookup_index;
wire [25:0] lookup_tag;

reg        valid  [0:15];
reg [25:0] tag    [0:15];
reg [31:0] target [0:15];
// 条件分支方向状态：00/01=倾向不跳转，10/11=倾向跳转。
reg [1:0]  direction [0:15];
// 0: 无条件跳转（JAL/JALR）；1: 条件分支（B 类指令）。
reg        is_conditional [0:15];

assign lookup_index = lookup_pc[5:2];
assign lookup_tag   = lookup_pc[31:6];

wire lookup_match = valid[lookup_index] && tag[lookup_index] == lookup_tag;
wire lookup_taken = !is_conditional[lookup_index] || direction[lookup_index][1];

// 对无条件跳转，命中即使用目标；对条件分支，仅在方向计数器预测
// taken 时报告命中，否则由 Hifu 回退到 PC+4（静态不跳转路径）。
assign lookup_hit    = lookup_match && lookup_taken;
assign lookup_target = lookup_hit ? target[lookup_index] : 32'h0;

//更新逻辑
wire [3:0]  update_index;
wire [25:0] update_tag;
assign update_index = update_pc[5:2];
assign update_tag   = update_pc[31:6];

always @(posedge clk) begin : update_block
	integer i;
	if(rst) begin
        for (i = 0; i < 16; i = i + 1) begin
             valid[i]  <= 0;
             tag[i]    <= 0;
             target[i] <= 0;
			 direction[i] <= 2'b01;
			 is_conditional[i] <= 1'b0;
		end
	end
	else if(update_valid) begin
	    valid[update_index]  <= 1'b1;
		tag  [update_index]  <= update_tag;
	    target[update_index] <= update_target;
	    is_conditional[update_index] <= update_is_conditional;

	    if (!update_is_conditional) begin
	        // JAL/JALR 必然跳转，不需要方向学习。
	        direction[update_index] <= 2'b11;
	    end
	    else if (!valid[update_index] ||
	             tag[update_index] != update_tag ||
	             !is_conditional[update_index]) begin
	        // 新建/替换条件分支表项：从弱状态开始，避免一次结果
	        // 直接锁死预测方向。
	        direction[update_index] <= update_taken ? 2'b10 : 2'b01;
	    end
	    else if (update_taken) begin
	        // taken：饱和加一。
	        if (direction[update_index] != 2'b11)
	            direction[update_index] <= direction[update_index] + 2'b01;
	    end
	    else begin
	        // not-taken：饱和减一。
	        if (direction[update_index] != 2'b00)
	            direction[update_index] <= direction[update_index] - 2'b01;
	    end
	end
end

endmodule
