`timescale 1ns/1ps
module Btb(
	input  wire        clk,
	input  wire        rst, 
	input  wire [31:0] lookup_pc,
	input  wire        update_valid,
	input  wire [31:0] update_pc,
	input  wire [31:0] update_target,
	input  wire        update_is_conditional,
	input  wire        update_is_return,
	input  wire        update_taken,

	// lookup_match means the indexed entry is valid and its tag matches.
	// lookup_hit additionally requires a taken prediction and is the signal
	// consumed by Hifu to select the BTB target.
	output wire        lookup_match,
	output wire        lookup_predict_taken,
	output wire        lookup_hit,
	output wire        lookup_is_return,
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
reg        is_return [0:15];

assign lookup_index = lookup_pc[5:2];
assign lookup_tag   = lookup_pc[31:6];

assign lookup_match = valid[lookup_index] && tag[lookup_index] == lookup_tag;
// Direction state is reported independently of tag match for debugging;
// lookup_hit is the qualified prediction-valid signal used by the IF stage.
assign lookup_predict_taken = !is_conditional[lookup_index] || direction[lookup_index][1];

// 对无条件跳转，命中即使用目标；对条件分支，仅在方向计数器预测
// taken 时报告命中，否则由 Hifu 回退到 PC+4（静态不跳转路径）。
assign lookup_hit    = lookup_match && lookup_predict_taken;
assign lookup_is_return = lookup_match && is_return[lookup_index];
assign lookup_target = lookup_hit ? target[lookup_index] : 32'h0;

//更新逻辑
wire [3:0]  update_index;
wire [25:0] update_tag;
assign update_index = update_pc[5:2];
assign update_tag   = update_pc[31:6];

always @(posedge clk) begin : update_block
	integer i;
	if(rst) begin
        // Payload tag/target need not reset: valid masks every lookup until
        // the first complete update, and reset never accepts a table write.
        for (i = 0; i < 16; i = i + 1) begin
             valid[i]  <= 0;
			 direction[i] <= 2'b01;
			 is_conditional[i] <= 1'b0;
             is_return[i] <= 1'b0;
		end
	end
	else begin
	    if (update_valid) begin
	        valid[update_index]  <= 1'b1;
	        tag[update_index]    <= update_tag;
	        target[update_index] <= update_target;
	        is_conditional[update_index] <= update_is_conditional;
	        is_return[update_index] <= update_is_return;
	    end

	    // Unroll one constant entry at a time so direction writes do not use
	    // the dynamic update_index read/modify/write path.
	    for (i = 0; i < 16; i = i + 1) begin
	        if (update_valid && (update_index == i)) begin
	            if (!update_is_conditional) begin
	                // JAL/JALR are always taken.
	                direction[i] <= 2'b11;
	            end
	            else if (!valid[i] || tag[i] != update_tag || !is_conditional[i]) begin
	                // New/replaced conditional branch starts weakly in its result direction.
	                direction[i] <= {update_taken, !update_taken};
	            end
	            else begin
	                // Explicit 2-bit saturating counter next-state equations.
	                direction[i][1] <= update_taken ?
	                    (direction[i][1] | direction[i][0]) :
	                    (direction[i][1] & direction[i][0]);
	                direction[i][0] <= update_taken ?
	                    (direction[i][1] | ~direction[i][0]) :
	                    (direction[i][1] & ~direction[i][0]);
	            end
	        end
	    end
	end
end

endmodule
