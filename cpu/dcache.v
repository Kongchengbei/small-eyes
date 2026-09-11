`timescale 1ns / 1ps

module dcache #(
    parameter [31:0] DDR_BASE   = 32'h8000_0000,
    parameter [31:0] DDR_BYTES  = 32'h4000_0000
) (
    input              clk,
    input              rst,

    // CPU / LSU
    input              dmem_req_valid,
    input              dmem_req_write,     // 1 = store, 0 = load
    input      [31:0]  dmem_req_addr,
    input      [31:0]  dmem_req_wdata,
    input      [3:0]   dmem_req_wstrb,
    output wire        dmem_req_ready,
    output wire        dmem_rsp_valid,
    output wire [31:0] dmem_rsp_data,
    output wire        cache_miss,

    //AXI桥接口
    output wire        rd_req,
    output wire [ 2:0] rd_type,
    output wire [31:0] rd_addr,
    input              rd_rdy,
    input              ret_valid,
    input              ret_last,
    input      [31:0]  ret_data,

    output reg         wr_req,
    output wire [ 2:0] wr_type,
    output wire [31:0] wr_addr,
    output wire [ 3:0] wr_wstrb,
    output wire [127:0]wr_data,
    input              wr_rdy
);

//状态
localparam main_idle    = 5'b00001;
localparam main_lookup  = 5'b00010;
localparam main_miss    = 5'b00100;
localparam main_replace = 5'b01000;
localparam main_refill  = 5'b10000;

//写缓冲状态
localparam write_buffer_idle  = 1'b0;
localparam write_buffer_write = 1'b1;

reg [4:0] main_state;
reg       write_buffer_state;

wire main_state_is_idle    = (main_state == main_idle);
wire main_state_is_lookup  = (main_state == main_lookup);
wire main_state_is_miss    = (main_state == main_miss);
wire main_state_is_replace = (main_state == main_replace);
wire main_state_is_refill  = (main_state == main_refill);

wire write_state_is_full   = (write_buffer_state == write_buffer_write);

//dcache的锁存pc责任交给ex阶段了
reg        hold;

wire [31:0] proc_addr    = dmem_req_addr;
wire [3:0]  proc_offset  = {proc_addr[3:2], 2'b00};
wire [7:0]  proc_index   = proc_addr[11:4];
wire [19:0] proc_tag     = proc_addr[31:12];

wire addr_ddr  = (proc_addr >= DDR_BASE)  && (proc_addr < (DDR_BASE  + DDR_BYTES));
wire uncache_addr = !addr_ddr;


//脏位
reg [1:0] way_d_reg [255:0];

wire [7:0]  way_bank_addra [1:0][3:0];
wire [31:0] way_bank_dina  [1:0][3:0];
wire [31:0] way_bank_douta [1:0][3:0];
wire        way_bank_ena   [1:0][3:0];
wire [3:0]  way_bank_wea   [1:0][3:0];

wire [7:0]  way_tagv_addra [1:0];
wire [20:0] way_tagv_dina  [1:0];
wire [20:0] way_tagv_douta [1:0];
wire        way_tagv_ena   [1:0];
wire        way_tagv_wea   [1:0];

wire wr_match_way_bank [1:0][3:0]; //前要写的是哪个 Way 的哪个 Bank

wire [1:0]  way_hit;
wire        cache_hit;

wire [31:0] way_load_word [1:0];// 每路选出的 32-bit Word
wire [127:0] way_data     [1:0];// 每路拼接的 128-bit Line
wire [31:0] load_res; //最终的数据

wire [1:0]  random_val;
wire [3:0]  chosen_way;
wire [1:0]  replace_way; //最终选择的替换路
wire [1:0]  invalid_way;
wire        has_invalid_way;
wire [1:0]  rand_repl_way;

wire [127:0] replace_data;//被替换行的 128-bit 数据
wire         replace_d;//是否脏
wire         replace_v; //是否有效
wire [19:0]  replace_tag;//tag

wire [1:0]  way_wr_en;

wire [31:0] refill_data;
wire [31:0] write_in;

wire        uncache_wr;
reg         uncache_wr_buffer;


genvar i, j;
integer k;

//寄存器
reg        request_buffer_op;
reg [ 2:0] request_buffer_size;
reg [ 7:0] request_buffer_index;
reg [19:0] request_buffer_tag;
reg [ 3:0] request_buffer_offset;
reg [ 3:0] request_buffer_wstrb;
reg [31:0] request_buffer_wdata;
reg        request_buffer_uncache_en;

reg  [1:0] miss_buffer_replace_way;
reg  [1:0] miss_buffer_ret_num;
wire [1:0] ret_num_add_one;

reg  [7:0] write_buffer_index;
reg  [3:0] write_buffer_wstrb;
reg  [31:0]write_buffer_wdata;
reg  [1:0] write_buffer_way;
reg  [3:0] write_buffer_offset;

reg rd_req_buffer;

//状态机
always @(posedge clk) begin
    if (rst) begin
        main_state <= main_idle;
        hold        <= 1'b0;

        request_buffer_op          <= 1'b0;
        request_buffer_size        <= 3'b0;
        request_buffer_index       <= 8'b0;
        request_buffer_tag         <= 20'b0;
        request_buffer_offset      <= 4'b0;
        request_buffer_wstrb       <= 4'b0;
        request_buffer_wdata       <= 32'b0;
        request_buffer_uncache_en  <= 1'b0;

        miss_buffer_replace_way    <= 2'b0;
        miss_buffer_ret_num        <= 2'b0;
        rd_req_buffer              <= 1'b0;
        wr_req                     <= 1'b0;
        uncache_wr_buffer          <= 1'b0;
        for (k = 0; k < 256; k = k + 1)
            way_d_reg[k] <= 2'b0;
    end
    else begin
        if (accept)
            hold <= 1'b1;
        else if (cpu_rsp_pulse)
            hold <= 1'b0;

        case (main_state)
            main_idle: begin
                if (accept) begin
                    main_state <= main_lookup;
                    request_buffer_op          <= dmem_req_write;
                    request_buffer_size        <= 3'b010; // always word
                    request_buffer_index       <= proc_index;
                    request_buffer_tag         <= proc_tag;
                    request_buffer_offset      <= proc_offset;
                    request_buffer_wstrb       <= dmem_req_wstrb;
                    request_buffer_wdata       <= dmem_req_wdata;
                    request_buffer_uncache_en  <= uncache_addr;
                end
            end
            main_lookup: begin
                if (cache_hit) begin
                    main_state <= main_idle;
                end
                else if (uncache_wr || ((replace_d && replace_v) && !request_buffer_uncache_en)) begin
                    main_state <= main_miss;
                    uncache_wr_buffer         <= uncache_wr;
                    miss_buffer_replace_way   <= replace_way;
                end
                else begin
                    main_state <= main_replace;
                    uncache_wr_buffer         <= uncache_wr;
                    miss_buffer_replace_way   <= replace_way;
                end
            end
            main_miss: begin
                if (wr_rdy) begin
                    main_state <= main_replace;
                    wr_req     <= 1'b1;
                end
            end
            main_replace: begin
                if (rd_rdy) begin
                    main_state <= main_refill;
                    miss_buffer_ret_num <= 2'b0;
                end
                wr_req <= 1'b0;
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

        //AXI 飞行标记
        if (rd_req)
            rd_req_buffer <= 1'b1;
        else if (main_state_is_refill && (ret_valid && ret_last))
            rd_req_buffer <= 1'b0;

        //Dirty 位更新
        if (main_state_is_refill && ((ret_valid && ret_last) || !rd_req_buffer) &&
    	!request_buffer_uncache_en) begin
    		// 整体赋值，完美复现原始逻辑：选中路的脏位 = op，未选中路保持原样
    		way_d_reg[request_buffer_index] <=(way_d_reg[request_buffer_index] & ~miss_buffer_replace_way) | (miss_buffer_replace_way & {2{request_buffer_op}});
		end
        else if (write_state_is_full) begin
            way_d_reg[write_buffer_index] <= way_d_reg[write_buffer_index] | write_buffer_way;
        end


    end
end

// 写缓冲状态机
always @(posedge clk) begin
    if (rst) begin
        write_buffer_state <= write_buffer_idle;
        write_buffer_index <= 8'b0;
        write_buffer_wstrb <= 4'b0;
        write_buffer_wdata <= 32'b0;
        write_buffer_offset<= 4'b0;
        write_buffer_way   <= 2'b0;
    end
    else case (write_buffer_state)
        write_buffer_idle: begin
            if (main_state_is_lookup && cache_hit && request_buffer_op) begin
                write_buffer_state <= write_buffer_write;
                write_buffer_index <= request_buffer_index;
                write_buffer_wstrb <= request_buffer_wstrb;
                write_buffer_wdata <= request_buffer_wdata;
                write_buffer_offset<= request_buffer_offset;
                write_buffer_way   <= way_hit;
            end
        end
        write_buffer_write: begin
            if (main_state_is_lookup && cache_hit && request_buffer_op) begin
                write_buffer_state <= write_buffer_write;
                write_buffer_index <= request_buffer_index;
                write_buffer_wstrb <= request_buffer_wstrb;
                write_buffer_wdata <= request_buffer_wdata;
                write_buffer_offset<= request_buffer_offset;
                write_buffer_way   <= way_hit;
            end
            else begin
                write_buffer_state <= write_buffer_idle;
            end
        end
        default: write_buffer_state <= write_buffer_idle;
    endcase
end

// 请求接收门控
wire main_idle2lookup = !(write_state_is_full && ((proc_offset[3:2] == write_buffer_offset[3:2]) || (write_buffer_index == proc_index)));//写缓冲有未提交数据，新请求与写缓冲冲突

wire accept = dmem_req_valid && !hold && main_state_is_idle && main_idle2lookup;

assign dmem_req_ready = main_state_is_idle && main_idle2lookup && !hold;

// tag比较
generate
    for (i = 0; i < 2; i = i + 1) begin: gen_way_hit
        assign way_hit[i] = way_tagv_douta[i][0] &&
                            (request_buffer_tag == way_tagv_douta[i][20:1]);
    end
endgenerate

assign cache_hit = |way_hit && !request_buffer_uncache_en;

//数据选择
generate
    for (i = 0; i < 2; i = i + 1) begin: gen_way_data
        assign way_data[i] = {way_bank_douta[i][3], way_bank_douta[i][2],
                              way_bank_douta[i][1], way_bank_douta[i][0]};
        assign way_load_word[i] = way_data[i][request_buffer_offset[3:2]*32 +: 32];
    end
endgenerate

assign load_res = {32{way_hit[0]}} & way_load_word[0] |
                  {32{way_hit[1]}} & way_load_word[1];

// Uncache 写请求识别
assign uncache_wr = request_buffer_uncache_en && request_buffer_op;

//替换路
decoder_2_4 dec_rand_way (.in({1'b0, random_val[0]}), .out(chosen_way));

//是否存在无效路
one_valid_n #(2) sel_one_invalid (
    .in     (~{way_tagv_douta[1][0], way_tagv_douta[0][0]}),
    .out    (invalid_way),
    .nozero (has_invalid_way)
);
//最终选择
assign rand_repl_way = has_invalid_way ? invalid_way : chosen_way[1:0];
assign replace_way   = rand_repl_way;

//判断是否写回
wire [1:0] way_d = way_d_reg[request_buffer_index] | {2{(write_buffer_index == request_buffer_index) && write_state_is_full}} & write_buffer_way;

assign replace_d = |(replace_way & way_d);
assign replace_v = |(replace_way & {way_tagv_douta[1][0], way_tagv_douta[0][0]});

assign replace_tag = {20{miss_buffer_replace_way[0]}} & way_tagv_douta[0][20:1] |
                     {20{miss_buffer_replace_way[1]}} & way_tagv_douta[1][20:1];

assign replace_data = {128{miss_buffer_replace_way[0]}} & way_data[0] |
                      {128{miss_buffer_replace_way[1]}} & way_data[1];

//AXI
assign wr_type  = uncache_wr_buffer ? 3'b010 : 3'b100;
assign wr_addr  = uncache_wr_buffer ? {request_buffer_tag, request_buffer_index, request_buffer_offset} : {replace_tag, request_buffer_index, 4'b0};
assign wr_data  = uncache_wr_buffer ? {96'b0, request_buffer_wdata} : replace_data;
assign wr_wstrb = uncache_wr_buffer ? request_buffer_wstrb : 4'hf;

assign rd_req   = main_state_is_replace && !(uncache_wr_buffer);
assign rd_type  = request_buffer_uncache_en ? 3'b010 : 3'b100;
assign rd_addr  = request_buffer_uncache_en ? {request_buffer_tag, request_buffer_index, request_buffer_offset} : {request_buffer_tag, request_buffer_index, 4'b0};

//反应
wire data_ok = (main_state_is_lookup && cache_hit) ||
               (main_state_is_miss && uncache_wr_buffer && wr_rdy) ||
               (main_state_is_refill && ret_valid &&
                ((miss_buffer_ret_num == request_buffer_offset[3:2]) || //cwf
                 request_buffer_uncache_en));

wire cpu_rsp_pulse    = data_ok && hold;
assign dmem_rsp_valid = cpu_rsp_pulse;
assign dmem_rsp_data  = main_state_is_lookup ? load_res : ret_data;

assign cache_miss = main_state_is_refill && ret_last && !(request_buffer_uncache_en);

// Refill 数据合并
assign write_in =
    {(request_buffer_wstrb[3] ? request_buffer_wdata[31:24] : ret_data[31:24]),
     (request_buffer_wstrb[2] ? request_buffer_wdata[23:16] : ret_data[23:16]),
     (request_buffer_wstrb[1] ? request_buffer_wdata[15:8]  : ret_data[15:8]),
     (request_buffer_wstrb[0] ? request_buffer_wdata[7:0]   : ret_data[7:0])};

assign refill_data = (request_buffer_op && (request_buffer_offset[3:2] == miss_buffer_ret_num)) ? write_in : ret_data;

assign way_wr_en = miss_buffer_replace_way & {2{ret_valid &&
                                               !request_buffer_uncache_en}};//写使能

//axi回填加1
assign ret_num_add_one[0] = miss_buffer_ret_num[0] ^ 1'b1;
assign ret_num_add_one[1] = miss_buffer_ret_num[1] ^ miss_buffer_ret_num[0];

// 控制信号生成器
generate
    for (i = 0; i < 2; i = i + 1) begin: gen_data_way
        for (j = 0; j < 4; j = j + 1) begin: gen_data_bank
            assign wr_match_way_bank[i][j] = write_state_is_full && write_buffer_way[i] &&
                (write_buffer_offset[3:2] == j[1:0]);
            assign way_bank_addra[i][j] = wr_match_way_bank[i][j] ? write_buffer_index :
                (main_state_is_idle ? proc_index : request_buffer_index);
            assign way_bank_wea[i][j] = {4{wr_match_way_bank[i][j]}} & write_buffer_wstrb |
                {4{main_state_is_refill &&
                   (way_wr_en[i] && (miss_buffer_ret_num == j[1:0]))}} & 4'hf;

            assign way_bank_dina[i][j] = {32{write_state_is_full}}  & write_buffer_wdata |
                {32{main_state_is_refill}} & refill_data;

            assign way_bank_ena[i][j] = (!request_buffer_uncache_en) || main_state_is_idle ||
                main_state_is_lookup;
        end
    end
endgenerate

generate
    for (i = 0; i < 2; i = i + 1) begin: gen_tagv_way
        assign way_tagv_addra[i] = (main_state_is_idle || main_state_is_lookup) ? proc_index : request_buffer_index;
        assign way_tagv_ena[i] = (!request_buffer_uncache_en) || main_state_is_idle || main_state_is_lookup;
        assign way_tagv_wea[i] = miss_buffer_replace_way[i] && main_state_is_refill &&
                                 !request_buffer_uncache_en &&
                                 ((ret_valid && ret_last));
        assign way_tagv_dina[i] = {request_buffer_tag, 1'b1};
    end
endgenerate



//实例化
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

lfsr u_lfsr (
    .clk        (clk),
    .reset      (rst),
    .random_val (random_val)
);

endmodule
