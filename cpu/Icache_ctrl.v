module Icache_ctrl(
    input  wire        clk,
	input  wire        rst,
	input  wire         flush,
    //给这个if阶段
	//这里是两个通道，也就是两份握手协议
	//一个是关于这个地址请求的 一个是数据返回的，这是两个不同的通道
	input  wire        cpu_req_valid,
	input  wire  [31:0] cpu_req_pc,
	output wire        cpu_resp_valid,//cpu_resp_valid = 1：Cache 说“我有指令”
	output wire   [31:0] cpu_resp_data,
	//握手信号--确保信号正常
	//两者都为 1：这一条指令才真正完成传输

    // 请求握手：
    // 防止 Cache 忙时错误接收新的 PC。

    // 响应握手 + resp_data_reg：
    // 防止 IF 阻塞时，返回的指令数据丢失。   
    output wire        cpu_req_ready,
    input  wire        cpu_resp_ready,//IFU 说“我能接收"
	//给这个ram取指令数据
	output wire         mem_req_valid,
	output wire  [31:0] mem_req_addr,
	input  wire         mem_resp_valid,
	input  wire  [31:0] mem_resp_data
);

wire         cache_hit;
wire [31:0]  cache_data;
wire         refill_valid;
wire [31:0]  refill_pc;
wire [31:0]  refill_data;
reg  [31:0]  miss_pc;     //保存未命中的指令
reg  [1:0]   state;

reg [31:0] resp_data_reg;
localparam State_look_up   = 2'b00;
localparam State_miss_req  = 2'b01;
localparam State_miss_wait = 2'b10;
localparam State_resp      = 2'b11;

Icache u_Icache(
	.clk          	( clk           ),
	.rst          	( rst           ),
	.refill_valid 	( refill_valid ),
	.refill_pc    	( refill_pc    ),
	.refill_data  	( refill_data  ),
	.lookup_pc    	( cpu_req_pc     ),
	.lookup_hit   	( cache_hit  ),
	.lookup_data  	( cache_data )
);
always @(posedge clk) begin
	if(rst)begin
		state   <= State_look_up;
		miss_pc <= 32'h0;
		resp_data_reg <= 32'h0;
	end
	else if (flush) begin
        state         <= State_look_up;
        miss_pc       <= 32'h0;
        resp_data_reg <= 32'h0;
    end
	else if(state == State_look_up)begin
		//  if(cpu_req_valid && cache_hit)begin
		// 	  //cpu_resp_valid <= 1'h1;
		// 	  cpu_resp_data  <= cache_data;
		//  end
		//  else
		if(cpu_req_valid && cpu_req_ready)begin
			if(cache_hit)begin
			resp_data_reg <= cache_data;
			state         <= State_resp;
		end
		else if(cpu_req_valid && !cache_hit)begin
			  miss_pc <= cpu_req_pc;
			  state   <= State_miss_req;
		 end
		end
	end
	else if(state == State_miss_req)begin
		// mem_req_valid <= 1'h1;
		//mem_req_addr  <= miss_pc;
		state         <= State_miss_wait;
	end
	else if(state == State_miss_wait)begin
		if(mem_resp_valid)begin
			// refill_pc   <= miss_pc;
			// refill_data <= mem_resp_data;
			resp_data_reg <= mem_resp_data;
			state       <= State_resp;
		end
	end
	else if(state == State_resp)begin
		if(cpu_resp_valid && cpu_resp_ready)begin
			state <= State_look_up;
		end
	end
end

assign cpu_resp_valid= (state == State_resp);//((state == State_look_up && cpu_req_valid && cache_hit) || (state== State_miss_wait && mem_resp_valid) ) ? 1'h1 : 1'h0;
//assign cpu_resp_data = cpu_resp_valid ? cache_data : 32'h0; //(cpu_req_valid && cache_hit)&&(state == State_look_up) ? cache_data : 32'h0;
assign mem_req_valid = (state == State_miss_req) ? 1'h1 : 1'h0;
assign refill_pc     = (state == State_miss_wait) && mem_resp_valid ? miss_pc : 32'h0;
assign refill_data   = (state == State_miss_wait) && mem_resp_valid ? mem_resp_data : 32'h0;
assign mem_req_addr  = (state == State_miss_req)   ? miss_pc : 32'h0;
assign refill_valid  = state == State_miss_wait && mem_resp_valid;


// assign cpu_resp_data = (state == State_look_up && cpu_req_valid && cache_hit) ? cache_data : 
//                        ((state== State_miss_wait && mem_resp_valid) ? mem_resp_data : 32'h0 ); 
assign cpu_resp_data = (state == State_resp)  ? resp_data_reg : 32'h0; 
assign cpu_req_ready = (state == State_look_up);








endmodule
