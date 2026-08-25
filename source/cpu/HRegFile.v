`timescale 1ns / 1ps

module HRegFile(
    input         clk,
	input         rst,
    input         wen,
    input  [4:0]  waddr,
    input  [31:0] wdata,
    input  [4:0]  raddr1,
    input  [4:0]  raddr2,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] rf [0:31];

	integer i;

    always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < 32; i = i + 1)
				rf[i] <= 32'b0;
		end else if (wen && (waddr != 5'd0)) begin
			rf[waddr] <= wdata;
		end
	end

	//实现wb数据的前递
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : (wen && (waddr == raddr1)) ? wdata : rf[raddr1];
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : (wen && (waddr == raddr2)) ? wdata : rf[raddr2];

endmodule
