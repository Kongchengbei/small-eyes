`timescale 1ns/1ps
module Btb(
	input  wire        clk,
	input  wire        rst, 
	input  wire [31:0] lookup_pc,
	input  wire        update_valid,
	input  wire [31:0] update_pc,
	input  wire [31:0] update_target,

	output wire        lookup_hit,
	output wire [31:0] lookup_target
);

wire [3:0]  lookup_index;
wire [25:0] lookup_tag;

reg        valid  [0:15];
reg [25:0] tag    [0:15];
reg [31:0] target [0:15];

assign lookup_index = lookup_pc[5:2];
assign lookup_tag   = lookup_pc[31:6];


assign lookup_hit    = valid[lookup_index] && tag[lookup_index] == lookup_tag;
assign lookup_target = lookup_hit ? target[lookup_index] : 32'h0;

//更新逻辑
wire [3:0]  update_index;
wire [25:0] update_tag;
assign update_index = update_pc[5:2];
assign update_tag   = update_pc[31:6];

always @(posedge clk) begin
	integer i; 
	if(rst) begin
        for (i = 0; i < 16; i = i + 1) begin
        // 循环体操作
             valid[i]  <= 0;
             tag[i]    <= 0;
             target[i] <= 0;
		end
	end
	else if(update_valid) begin
	    valid[update_index] <= 1'h1;
		tag  [update_index] <= update_tag;
	   target[update_index] <= update_target; 
	end
end

endmodule