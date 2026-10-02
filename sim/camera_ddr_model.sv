`timescale 1ns / 1ps

// CPU 与 Camera 共用的 DDR AXI 行为模型，稀疏保存程序区和两个 1 MiB 帧槽。
// 所有数据访问经过真实桥/仲裁器；模型仅替代外部 DDR 控制器。
module camera_ddr_model (
    input clk, input rst_n,
    input [29:0] axi_awaddr, input [7:0] axi_awid, input [7:0] axi_awlen,
    input [2:0] axi_awsize, input [1:0] axi_awburst,
    input axi_awvalid, output axi_awready,
    input [255:0] axi_wdata, input [31:0] axi_wstrb,
    input axi_wlast, input axi_wvalid, output axi_wready,
    output [7:0] axi_bid, output [1:0] axi_bresp,
    output axi_bvalid, input axi_bready,
    input [29:0] axi_araddr, input [7:0] axi_arid, input [7:0] axi_arlen,
    input [2:0] axi_arsize, input [1:0] axi_arburst,
    input axi_arvalid, output axi_arready,
    output [255:0] axi_rdata, output [7:0] axi_rid,
    output [1:0] axi_rresp, output axi_rlast,
    output axi_rvalid, input axi_rready
);
    localparam [31:0] FRAME_LOCAL = 32'h3800_0000;
    reg [31:0] program_mem [0:16383];
    reg [31:0] frame_mem [0:524287];
    reg [31:0] cycles = 0;
    reg aw_seen = 0, w_seen = 0;
    reg [29:0] saved_addr;
    reg [7:0] saved_id;
    reg [255:0] saved_data;
    reg [31:0] saved_strb;
    reg [7:0] bid_q;
    reg bvalid_q = 0;
    reg [3:0] bdelay = 0;
    reg [255:0] rdata_q;
    reg [7:0] rid_q;
    reg rvalid_q = 0;
    reg [3:0] rdelay = 0;
    integer camera_writes = 0;
    integer cpu_reads = 0;
    integer k;
    integer init_index;
    string program_file;

    function automatic [31:0] read_word(input [31:0] address);
        if (address < 32'h0001_0000)
            read_word = program_mem[address >> 2];
        else if (address >= FRAME_LOCAL && address < FRAME_LOCAL + 32'h0020_0000)
            read_word = frame_mem[(address - FRAME_LOCAL) >> 2];
        else
            read_word = 32'b0;
    endfunction

    task automatic write_byte(input [31:0] address, input [7:0] value);
        if (address < 32'h0001_0000)
            program_mem[address >> 2][address[1:0]*8 +: 8] = value;
        else if (address >= FRAME_LOCAL && address < FRAME_LOCAL + 32'h0020_0000)
            frame_mem[(address - FRAME_LOCAL) >> 2][address[1:0]*8 +: 8] = value;
        else
            $fatal(1, "DDR 写越界：%h", address);
    endtask

    assign axi_awready = rst_n && !aw_seen && !bvalid_q && bdelay == 0 &&
                         cycles[1:0] != 2'b00;
    assign axi_wready = rst_n && !w_seen && !bvalid_q && bdelay == 0 &&
                        cycles[2:0] != 3'b010;
    assign axi_bid = bid_q;
    assign axi_bresp = 2'b00;
    assign axi_bvalid = bvalid_q;
    assign axi_arready = rst_n && !rvalid_q && rdelay == 0 && cycles[1:0] != 2'b01;
    assign axi_rid = rid_q;
    assign axi_rdata = rdata_q;
    assign axi_rresp = 2'b00;
    assign axi_rlast = 1'b1;
    assign axi_rvalid = rvalid_q;

    initial begin
        for (init_index = 0; init_index < 16384; init_index++)
            program_mem[init_index] = 0;
        for (init_index = 0; init_index < 524288; init_index++)
            frame_mem[init_index] = 0;
        program_file = "";
        if ($value$plusargs("PROGRAM=%s", program_file))
            $readmemh(program_file, program_mem);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycles <= 0;
            aw_seen <= 0;
            w_seen <= 0;
            bvalid_q <= 0;
            bdelay <= 0;
            rvalid_q <= 0;
            rdelay <= 0;
            rdata_q <= 0;
            rid_q <= 0;
            bid_q <= 0;
            camera_writes <= 0;
            cpu_reads <= 0;
        end else begin
            cycles <= cycles + 1;
            if (axi_awvalid && axi_awready) begin
                if (axi_awlen != 0 || axi_awsize != 5 || axi_awburst != 1 || axi_awaddr[4:0] != 0)
                    $fatal(1, "DDR AW 配置错误");
                saved_addr <= axi_awaddr;
                saved_id <= axi_awid;
                aw_seen <= 1;
            end
            if (axi_wvalid && axi_wready) begin
                if (!axi_wlast)
                    $fatal(1, "单拍 DDR 写缺少 WLAST");
                saved_data <= axi_wdata;
                saved_strb <= axi_wstrb;
                w_seen <= 1;
            end
            if (aw_seen && w_seen && !bvalid_q && bdelay == 0) begin
                for (k = 0; k < 32; k++)
                    if (saved_strb[k])
                        write_byte({2'b0, saved_addr} + 32'(k), saved_data[k*8 +: 8]);
                bid_q <= saved_id;
                bdelay <= 3;
                aw_seen <= 0;
                w_seen <= 0;
                if (saved_id == 8'h40)
                    camera_writes <= camera_writes + 1;
            end else if (bdelay != 0) begin
                bdelay <= bdelay - 1;
                if (bdelay == 1)
                    bvalid_q <= 1;
            end
            if (bvalid_q && axi_bready)
                bvalid_q <= 0;

            if (axi_arvalid && axi_arready) begin
                if (axi_arlen != 0 || axi_arsize != 5 || axi_arburst != 1 || axi_araddr[4:0] != 0)
                    $fatal(1, "DDR AR 配置错误");
                for (k = 0; k < 8; k++)
                    rdata_q[k*32 +: 32] <= read_word({2'b0, axi_araddr} + 32'(k*4));
                rid_q <= axi_arid;
                rdelay <= 2;
                cpu_reads <= cpu_reads + 1;
            end else if (rdelay != 0) begin
                rdelay <= rdelay - 1;
                if (rdelay == 1)
                    rvalid_q <= 1;
            end
            if (rvalid_q && axi_rready)
                rvalid_q <= 0;
        end
    end
endmodule
