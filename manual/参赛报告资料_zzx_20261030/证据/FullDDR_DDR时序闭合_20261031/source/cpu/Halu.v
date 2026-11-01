`timescale 1ns / 1ps
module Halu(
    
	input  wire [31:0] src1,        // 操作数1
    input  wire [31:0] src2,        // 操作数2
    input  wire [3:0]  alu_op,      // 功能
    input  wire alu_en,	
    output reg  [31:0] result
    //output reg ZF,        // Zero Flag
    //output reg SF         // Sign Flag
);
	wire [4:0] shift_num = src2[4:0];
	always @(*) begin
			result = 32'b0;
		if(alu_en)begin
			case(alu_op)
            	4'b0000: begin
                	result = src1 + src2;
            	end
            	4'b0001: begin
                	result = src1 + (~src2 + 1'b1);
            	end

            	4'b0010: begin
                	result = src1 << shift_num;
            	end
            	4'b0011: begin
					result = (($signed(src1) < $signed(src2))) ? 32'b1:32'b0;		           
				end
            	4'b0100: begin
                	//无符号比较：src1 < src2 
                	result = (src1 < src2) ? 32'b1 : 32'b0;
            	end

            	4'b0101: begin
                	result = src1 ^ src2; // 直接按位异或
            	end

            	4'b0110: begin
					// 无符号右移，高位补0	
					result = src1 >> shift_num;
            	end
            	4'b0111: begin
                	// 有符号右移，高位补符号位
					result = $signed(src1) >>> shift_num;
				end
            	4'b1000: begin
                	result = src1 | src2;
            	end

             4'b1001: begin
                 result = src1 & src2; 
             end


            	4'b1111: begin
                	result = 32'b0000; // 无效指令时输出0
            	end

            	default: begin
                	result = 32'b0000;
            	end
        	endcase
		end
        	//标志位
        	//ZF = (result == 32'b0000) ? 1'b1 : 1'b0; // 结果为0 → ZF=1
        	//SF = result[31];                         // 结果符号位 → SF
	end
endmodule
