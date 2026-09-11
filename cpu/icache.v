`timescale 1ns / 1ps

module icache #(
    parameter [31:0] DDR_BASE   = 32'h8000_0000,
    parameter [31:0] DDR_BYTES  = 32'h4000_0000
) (
    input              clk,
    input              rst,
    input              flush,

    // CPU / IFU
    input              cpu_req_valid,
    input      [31:0]  cpu_req_pc,
    output wire        cpu_req_ready,
    output wire        cpu_resp_valid,
    output wire [31:0] cpu_resp_data,
    output wire        cache_miss,

    //AXI桥，主要的作用是cache miss的时候使用
    output wire        rd_req,
    output wire [ 2:0] rd_type,
    output wire [31:0] rd_addr,
    input              rd_rdy,
    input              ret_valid,
    input              ret_last,
    input      [31:0]  ret_data,

	//icache是没有写请求的
    output wire        wr_req,
    output wire [ 2:0] wr_type,
    output wire [31:0] wr_addr,
    output wire [ 3:0] wr_wstrb,
    output wire [127:0]wr_data,
    input              wr_rdy
);

//锁存pc
reg        hold;    //1忙，禁止新请求；0空闲
reg [31:0] hold_pc; //快照pc

wire [31:0] proc_pc = hold ? hold_pc : cpu_req_pc;

wire [7:0]  proc_index = proc_pc[11:4];  //索引
wire [19:0] proc_tag   = proc_pc[31:12]; //标签
wire [3:0]  proc_offset= proc_pc[3:0];   //偏移

//状态
localparam main_idle    = 4'b0001;
localparam main_lookup  = 4'b0010;
localparam main_replace = 4'b0100;
localparam main_refill  = 4'b1000;

reg [3:0] main_state;

wire main_state_is_idle    = (main_state == main_idle);
wire main_state_is_lookup  = (main_state == main_lookup);
wire main_state_is_replace = (main_state == main_replace);
wire main_state_is_refill  = (main_state == main_refill);

wire accept = cpu_req_valid && !hold && main_state_is_idle;

reg        request_buffer_uncache_en;
reg [ 7:0] request_buffer_index;
reg [19:0] request_buffer_tag;
reg [ 3:0] request_buffer_offset;

reg  [1:0] miss_buffer_replace_way;
reg  [1:0] miss_buffer_ret_num; //记录AXI返回了第几拍
wire [1:0] ret_num_add_one;    

reg rd_req_buffer;  //记录 AXI 读事务是否已经真正被总线接受并启动

//BRAM 接口
wire [7:0]  way_bank_addra [1:0][3:0]; //地址
wire [31:0] way_bank_dina  [1:0][3:0]; //写数据
wire [31:0] way_bank_douta [1:0][3:0]; //读数据
wire        way_bank_ena   [1:0][3:0]; //读使能
wire [3:0]  way_bank_wea   [1:0][3:0]; //写使能，字节掩码

wire        way_tagv_ena   [1:0]; //读使能
wire [7:0]  way_tagv_addra [1:0]; //地址
wire [20:0] way_tagv_douta [1:0]; //读数据
wire        way_tagv_wea   [1:0]; //写使能
wire [20:0] way_tagv_dina  [1:0]; //写数据
//命中
wire [1:0]  way_hit;
wire        cache_hit;

//替换策略
wire [31:0] way_load_word [1:0]; //每路选出的单个word
wire [127:0] way_data     [1:0]; //每路拼成的128位数据
wire [31:0] load_res;            //最终命中的指令

wire [1:0]  random_val; //随机替换路
wire [3:0]  chosen_way; //解码后的独热码       
wire [1:0]  replace_way;//最终替换路
wire [1:0]  invalid_way;//无效位
wire        has_invalid_way;//是否存在无效路
wire [1:0]  rand_repl_way;  //随机选择的路

//回填写入
wire [1:0]  way_wr_en;   //回填时写哪一路（单热编码）
wire [31:0] refill_data; //当前拍要写入的数据

genvar i, j;

// ---------------- address-window / uncache decode --------------------------
wire addr_ddr  = (proc_pc >= DDR_BASE)  && (proc_pc < (DDR_BASE  + DDR_BYTES));
wire uncache_addr = !addr_ddr;

always @(posedge clk) begin
    if (rst) begin
        main_state <= main_idle;
        hold        <= 1'b0;
        hold_pc     <= 32'b0;

        request_buffer_uncache_en <= 1'b0;
        request_buffer_index      <= 8'b0;
        request_buffer_tag        <= 20'b0;
        request_buffer_offset     <= 4'b0;
        miss_buffer_replace_way   <= 2'b0;
        miss_buffer_ret_num       <= 2'b0;
        rd_req_buffer             <= 1'b0;
    end
    else begin
        //握手成功
        if (accept) begin 
            hold    <= 1'b1;
            hold_pc <= cpu_req_pc;
        end
        else if (cpu_resp_valid || (flush && main_state_is_lookup) ||(flush && main_state_is_replace && !(rd_req && rd_rdy)))
            hold <= 1'b0;
		
		//状态机
        case (main_state)
            main_idle: begin
                if (accept) begin
                    main_state                <= main_lookup;
                    request_buffer_uncache_en <= uncache_addr;
                    request_buffer_index      <= proc_index;
                    request_buffer_offset     <= proc_offset;
                end
            end
            main_lookup: begin
                if (flush) begin
                    main_state <= main_idle;
                end
                else if (cache_hit) begin
                    main_state <= main_idle;
                end
                else begin
                    main_state              <= main_replace;
                    request_buffer_tag      <= proc_tag;
                    miss_buffer_replace_way <= replace_way;
                end
            end
            main_replace: begin
                if (flush && !(rd_req && rd_rdy)) begin
                    main_state <= main_idle;
                end
                else if (rd_rdy) begin
                    main_state <= main_refill;
                    miss_buffer_ret_num <= 2'b0;
                end
            end
            main_refill: begin
                if ((ret_valid && ret_last) || !rd_req_buffer) begin
                    main_state <= main_idle;
                end
                else if (ret_valid) begin
                    miss_buffer_ret_num <= ret_num_add_one;
                end
            end
            default: main_state <= main_idle;
        endcase

        // ---- rd_req in-flight marker ----
        if (rd_req)
            rd_req_buffer <= 1'b1;
        else if (main_state_is_refill && (ret_valid && ret_last))
            rd_req_buffer <= 1'b0;
    end
end

//tag比较
//0位有效位
//20-1存储的Tag
generate
    for (i = 0; i < 2; i = i + 1) begin: gen_way_hit
        assign way_hit[i] = way_tagv_douta[i][0] && (proc_tag == way_tagv_douta[i][20:1]);
    end
endgenerate

assign cache_hit = |way_hit && !request_buffer_uncache_en;

//数据选择
//[起始位 +: 宽度]，表示从起始位向上递增取 32 位。例如 [64 +: 32] 取的是 [95:64]
generate
    for (i = 0; i < 2; i = i + 1) begin: gen_data
		//把 4 个 32-bit Bank 拼成一条完整的 128-bit Cache Line
        assign way_data[i] = {way_bank_douta[i][3], way_bank_douta[i][2],
                              way_bank_douta[i][1], way_bank_douta[i][0]};
		//根据 Offset，从 128-bit 中切出对应的 32-bit Word
        assign way_load_word[i] = way_data[i][request_buffer_offset[3:2]*32 +: 32];
    end
endgenerate

assign load_res = {32{way_hit[0]}} & way_load_word[0] |
                  {32{way_hit[1]}} & way_load_word[1];

//替换策略
decoder_2_4 dec_rand_way (.in({1'b0, random_val[0]}), .out(chosen_way));

one_valid_n #(2) sel_one_invalid (
    .in     (~{way_tagv_douta[1][0], way_tagv_douta[0][0]}),
    .out    (invalid_way),
    .nozero (has_invalid_way)
);

assign rand_repl_way = has_invalid_way ? invalid_way : chosen_way[1:0];
assign replace_way   = rand_repl_way;

//AXI总线
assign rd_req   = main_state_is_replace;
assign rd_type  = request_buffer_uncache_en ? 3'b010 : 3'b100;
assign rd_addr  = request_buffer_uncache_en ?
                  {request_buffer_tag, request_buffer_index, request_buffer_offset} :
                  {request_buffer_tag, request_buffer_index, 4'b0};

assign wr_req   = 1'b0;
assign wr_type  = 3'b0;
assign wr_addr  = 32'b0;
assign wr_wstrb = 4'b0;
assign wr_data  = 128'b0;

//输出控制层
assign cpu_resp_valid = ((main_state_is_lookup && (cache_hit)) ||
                         (main_state_is_refill && ret_valid &&
                          ((miss_buffer_ret_num == request_buffer_offset[3:2]) ||//关键字优先
                           request_buffer_uncache_en))) && hold;

assign cpu_resp_data = main_state_is_lookup ? load_res : ret_data;//哪里来的数据

assign cpu_req_ready = main_state_is_idle && !hold; //cache是否忙碌

assign cache_miss = main_state_is_refill && ret_last && !request_buffer_uncache_en; //调试使用了

//axi返回计数器
assign ret_num_add_one[0] = miss_buffer_ret_num[0] ^ 1'b1;
assign ret_num_add_one[1] = miss_buffer_ret_num[1] ^ miss_buffer_ret_num[0];

assign refill_data = ret_data;
assign way_wr_en   = miss_buffer_replace_way & {2{ret_valid &&
                                                    !request_buffer_uncache_en}};

//BRAM的控制信号
generate
    for (i = 0; i < 2; i = i + 1) begin: gen_data_way
        for (j = 0; j < 4; j = j + 1) begin: gen_data_bank
            assign way_bank_ena[i][j] =(!request_buffer_uncache_en) || main_state_is_idle || main_state_is_lookup;
            assign way_bank_addra[i][j] = main_state_is_idle ? proc_index :request_buffer_index;
            assign way_bank_wea[i][j] ={4{main_state_is_refill &&(way_wr_en[i] && (miss_buffer_ret_num == j[1:0]))}} & 4'hf;
            assign way_bank_dina[i][j] = {32{main_state_is_refill}} & refill_data;
        end
    end
endgenerate

generate
    for (i = 0; i < 2; i = i + 1) begin: gen_tagv_way
        assign way_tagv_addra[i] = (main_state_is_idle ||main_state_is_lookup) ? proc_index :request_buffer_index;
        assign way_tagv_ena[i] = (!request_buffer_uncache_en) ||main_state_is_idle || main_state_is_lookup;

        assign way_tagv_wea[i] = miss_buffer_replace_way[i] && main_state_is_refill &&
                                 !request_buffer_uncache_en &&
                                 (ret_valid && ret_last);

        assign way_tagv_dina[i] = {request_buffer_tag, 1'b1};
    end
endgenerate

//BRAM实例
generate
    for (i = 0; i < 2; i = i + 1) begin: data_ram_way
        for (j = 0; j < 4; j = j + 1) begin: data_ram_bank
            data_bank_sram u (
                .addra (way_bank_addra[i][j]),
                .clka  (clk),
                .dina  (way_bank_dina[i][j]),
                .douta (way_bank_douta[i][j]),
                .ena   (way_bank_ena[i][j]),
                .wea   (way_bank_wea[i][j])
            );
        end
    end
endgenerate

generate
    for (i = 0; i < 2; i = i + 1) begin: tagv_ram_way
        tagv_sram u (
            .addra (way_tagv_addra[i]),
            .clka  (clk),
            .dina  (way_tagv_dina[i]),
            .douta (way_tagv_douta[i]),
            .ena   (way_tagv_ena[i]),
            .wea   (way_tagv_wea[i])
        );
    end
endgenerate

//随机数生成
lfsr u_lfsr (
    .clk        (clk),
    .reset      (rst),
    .random_val (random_val)
);

endmodule
