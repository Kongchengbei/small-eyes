module Icache(
	input  wire        clk,
	input  wire        rst,

	input  wire        refill_valid,
	input  wire [31:0] refill_pc,
	input  wire [31:0] refill_data,

	input  wire [31:0] lookup_pc,
	output wire        lookup_hit,
	output wire [31:0] lookup_data 
);

wire [3:0]  lookup_index;
wire [25:0] lookup_tag;

reg        valid[0:15];
reg [25:0]   tag[0:15];
reg [31:0]  data[0:15];

assign lookup_index = lookup_pc[5:2];
assign lookup_tag   = lookup_pc[31:6];

assign lookup_hit   = valid[lookup_index] && tag[lookup_index] == lookup_tag;

assign lookup_data  = lookup_hit ? data[lookup_index] : 32'h0;

//填充
wire [3:0] refill_index;
wire [25:0] refill_tag;
assign      refill_index = refill_pc[5:2];
assign      refill_tag   = refill_pc[31:6];

always @(posedge clk) begin
	integer i;
	if(rst)begin
		  for(i = 0;i<16;i++)begin
			valid[i] <= 0;
			tag[i]   <= 0;
			data[i]  <= 0;
		  end
	end
	else if(refill_valid)begin
		valid[refill_index] <= 1;
		tag[refill_index]   <= refill_tag;
		data[refill_index]  <= refill_data;
	end
end



endmodule
