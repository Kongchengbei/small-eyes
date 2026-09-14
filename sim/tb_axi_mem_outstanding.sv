`timescale 1ns / 1ps

// 针对 axi_mem_backend 两项按序读队列的专用回归测试。
// A 是 ID=0 的两拍 burst，B 是 ID=1 的单拍 burst。要求 B 在 A 完成前已被
// 接收，但 R 通道仍必须按 A0、A1/RLAST、B0/RLAST 的顺序返回。
module tb_axi_mem_outstanding;
    localparam [31:0] DDR_BASE = 32'h8000_0000;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #5 clk = ~clk;

    reg [3:0]  axi_awid = 4'd0;
    reg [31:0] axi_awaddr = 32'd0;
    reg [7:0]  axi_awlen = 8'd0;
    reg [2:0]  axi_awsize = 3'd2;
    reg [1:0]  axi_awburst = 2'b01;
    reg        axi_awvalid = 1'b0;
    wire       axi_awready;
    reg [31:0] axi_wdata = 32'd0;
    reg [3:0]  axi_wstrb = 4'd0;
    reg        axi_wlast = 1'b1;
    reg        axi_wvalid = 1'b0;
    wire       axi_wready;
    wire [3:0] axi_bid;
    wire [1:0] axi_bresp;
    wire       axi_bvalid;
    reg        axi_bready = 1'b1;

    reg [3:0]  axi_arid = 4'd0;
    reg [31:0] axi_araddr = 32'd0;
    reg [7:0]  axi_arlen = 8'd0;
    reg [2:0]  axi_arsize = 3'd2;
    reg [1:0]  axi_arburst = 2'b01;
    reg        axi_arvalid = 1'b0;
    wire       axi_arready;
    wire [3:0] axi_rid;
    wire [31:0] axi_rdata;
    wire [1:0] axi_rresp;
    wire       axi_rlast;
    wire       axi_rvalid;
    reg        axi_rready = 1'b1;

    wire        mmio_req_valid;
    wire        mmio_req_wen;
    wire [31:0] mmio_req_addr;
    wire [31:0] mmio_req_wdata;
    wire [3:0]  mmio_req_wstrb;

    wire        ddr_req_valid;
    reg         ddr_req_ready = 1'b1;
    wire        ddr_req_write;
    wire [31:0] ddr_req_addr;
    wire [31:0] ddr_req_wdata;
    wire [3:0]  ddr_req_wstrb;
    reg         ddr_rsp_valid = 1'b0;
    wire        ddr_rsp_ready;
    reg         ddr_rsp_is_read = 1'b1;
    reg [31:0]  ddr_rsp_rdata = 32'd0;

    integer response_count = 0;
    reg b_accepted = 1'b0;
    reg a_complete = 1'b0;

    axi_mem_backend dut (
        .clk(clk), .rst_n(rst_n),
        .axi_awid(axi_awid), .axi_awaddr(axi_awaddr),
        .axi_awlen(axi_awlen), .axi_awsize(axi_awsize),
        .axi_awburst(axi_awburst), .axi_awvalid(axi_awvalid),
        .axi_awready(axi_awready), .axi_wdata(axi_wdata),
        .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
        .axi_bid(axi_bid), .axi_bresp(axi_bresp),
        .axi_bvalid(axi_bvalid), .axi_bready(axi_bready),
        .axi_arid(axi_arid), .axi_araddr(axi_araddr),
        .axi_arlen(axi_arlen), .axi_arsize(axi_arsize),
        .axi_arburst(axi_arburst), .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready), .axi_rid(axi_rid),
        .axi_rdata(axi_rdata), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready),
        .mmio_req_valid(mmio_req_valid), .mmio_req_wen(mmio_req_wen),
        .mmio_req_addr(mmio_req_addr), .mmio_req_wdata(mmio_req_wdata),
        .mmio_req_wstrb(mmio_req_wstrb), .mmio_req_ready(1'b1),
        .mmio_req_rdata(32'd0),
        .ddr_req_valid(ddr_req_valid), .ddr_req_ready(ddr_req_ready),
        .ddr_req_write(ddr_req_write), .ddr_req_addr(ddr_req_addr),
        .ddr_req_wdata(ddr_req_wdata), .ddr_req_wstrb(ddr_req_wstrb),
        .ddr_rsp_valid(ddr_rsp_valid), .ddr_rsp_ready(ddr_rsp_ready),
        .ddr_rsp_is_read(ddr_rsp_is_read), .ddr_rsp_rdata(ddr_rsp_rdata),
        .jtag_cmd_addr(32'd0), .jtag_cmd_read(1'b0),
        .jtag_cmd_valid(1'b0), .jtag_cmd_wdata(32'd0),
        .jtag_cmd_wmask(4'd0), .jtag_rsp_ready(1'b1),
        .jtag_cmd_ready(), .jtag_rsp_valid(), .jtag_rsp_err(),
        .jtag_rsp_rdata()
    );

    // 每接收一笔本地 DDR 请求就产生一个响应。这里把请求地址作为返回数据，
    // 方便检查每一个 R 通道数据拍究竟属于 A 还是 B。
    always @(posedge clk) begin
        if (!rst_n) begin
            ddr_rsp_valid <= 1'b0;
        end else begin
            if (ddr_rsp_valid && ddr_rsp_ready)
                ddr_rsp_valid <= 1'b0;
            if (ddr_req_valid && ddr_req_ready) begin
                if (ddr_req_write)
                    $fatal(1, "unexpected write request");
                ddr_rsp_valid <= 1'b1;
                ddr_rsp_rdata <= ddr_req_addr;
            end
        end
    end

    always @(posedge clk) begin
        if (rst_n && axi_arvalid && axi_arready && (axi_arid == 4'd1)) begin
            if (a_complete)
                $fatal(1, "B was accepted after A completed; not outstanding");
            b_accepted <= 1'b1;
        end

        if (rst_n && axi_rvalid && axi_rready) begin
            case (response_count)
                0: if ((axi_rid != 4'd0) || axi_rlast ||
                        (axi_rdata != DDR_BASE + 32'h1000))
                       $fatal(1, "expected A beat 0");
                1: if ((axi_rid != 4'd0) || !axi_rlast ||
                        (axi_rdata != DDR_BASE + 32'h1004))
                       $fatal(1, "expected A beat 1 / RLAST");
                2: if ((axi_rid != 4'd1) || !axi_rlast ||
                        (axi_rdata != DDR_BASE + 32'h2000))
                       $fatal(1, "expected B only after A / RLAST");
                default: $fatal(1, "unexpected extra read response");
            endcase

            if (axi_rlast && (axi_rid == 4'd0))
                a_complete <= 1'b1;
            response_count <= response_count + 1;
        end
    end

    task automatic send_read;
        input [3:0] id;
        input [31:0] addr;
        input [7:0] len;
        begin
            axi_arid    = id;
            axi_araddr  = addr;
            axi_arlen   = len;
            axi_arvalid = 1'b1;
            do @(posedge clk); while (!axi_arready);
            axi_arvalid = 1'b0;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // 先接收 A；再发送 B，此时 A 尚未返回任何 RDATA。
        send_read(4'd0, DDR_BASE + 32'h1000, 8'd1);
        send_read(4'd1, DDR_BASE + 32'h2000, 8'd0);

        wait (response_count == 3);
        if (!b_accepted)
            $fatal(1, "B address handshake was never observed");
        $display("OUTSTANDING_IN_ORDER_PASS");
        $finish;
    end

    initial begin
        repeat (200) @(posedge clk);
        $fatal(1, "timeout");
    end
endmodule
