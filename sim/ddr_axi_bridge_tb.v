`timescale 1ns / 1ps

// Stand-alone behavioural check for the bridge.  It deliberately uses
// unrelated 70 MHz-ish CPU and 125 MHz DDR clocks, writes a sparse byte mask
// into word lane 5 of a 256-bit AXI beat, then reads that same lane back.
module ddr_axi_bridge_tb;
    reg cpu_clk = 1'b0;
    reg ddr_clk = 1'b0;
    always #7 cpu_clk = ~cpu_clk;
    always #4 ddr_clk = ~ddr_clk;

    reg rst_n;
    reg ddr_init_done;
    reg cpu_req_valid;
    wire cpu_req_ready;
    reg cpu_req_write;
    reg [31:0] cpu_req_addr;
    reg [31:0] cpu_req_wdata;
    reg [3:0] cpu_req_wmask;
    wire [31:0] cpu_rsp_rdata;
    wire cpu_rsp_valid;
    wire cpu_rsp_is_read;

    wire [29:0] axi_awaddr;
    wire [7:0] axi_awid;
    wire [7:0] axi_awlen;
    wire [2:0] axi_awsize;
    wire [1:0] axi_awburst;
    wire axi_awvalid;
    wire axi_awready = 1'b1;
    wire [255:0] axi_wdata;
    wire [31:0] axi_wstrb;
    wire axi_wlast;
    wire axi_wvalid;
    wire axi_wready = 1'b1;
    reg [7:0] axi_bid;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    wire axi_bready;

    wire [29:0] axi_araddr;
    wire [7:0] axi_arid;
    wire [7:0] axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid;
    wire axi_arready = 1'b1;
    reg [255:0] axi_rdata;
    reg [7:0] axi_rid;
    reg [1:0] axi_rresp;
    reg axi_rlast;
    reg axi_rvalid;
    wire axi_rready;

    ddr_axi_bridge dut (
        .cpu_clk(cpu_clk), .ddr_clk(ddr_clk), .rst_n(rst_n),
        .ddr_init_done(ddr_init_done),
        .cpu_req_valid(cpu_req_valid), .cpu_req_ready(cpu_req_ready),
        .cpu_req_write(cpu_req_write), .cpu_req_addr(cpu_req_addr),
        .cpu_req_wdata(cpu_req_wdata), .cpu_req_wmask(cpu_req_wmask),
        .cpu_rsp_rdata(cpu_rsp_rdata), .cpu_rsp_valid(cpu_rsp_valid),
        .cpu_rsp_is_read(cpu_rsp_is_read),
        .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize), .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid), .axi_awready(axi_awready),
        .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb), .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
        .axi_bid(axi_bid), .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid),
        .axi_bready(axi_bready),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
        .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready)
    );

    reg aw_seen;
    reg w_seen;
    reg read_pending;
    reg [29:0] captured_awaddr;
    reg [255:0] captured_wdata;
    reg [31:0] captured_wstrb;

    always @(posedge ddr_clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_seen        <= 1'b0;
            w_seen         <= 1'b0;
            read_pending   <= 1'b0;
            axi_bvalid     <= 1'b0;
            axi_rvalid     <= 1'b0;
            captured_awaddr <= 30'd0;
            captured_wdata <= 256'd0;
            captured_wstrb <= 32'd0;
        end else begin
            if (axi_awvalid) begin
                aw_seen         <= 1'b1;
                captured_awaddr <= axi_awaddr;
            end
            if (axi_wvalid) begin
                w_seen          <= 1'b1;
                captured_wdata  <= axi_wdata;
                captured_wstrb  <= axi_wstrb;
            end
            if (aw_seen && w_seen)
                axi_bvalid <= 1'b1;
            if (axi_bvalid && axi_bready) begin
                axi_bvalid <= 1'b0;
                aw_seen    <= 1'b0;
                w_seen     <= 1'b0;
            end

            if (axi_arvalid)
                read_pending <= 1'b1;
            if (read_pending) begin
                axi_rvalid   <= 1'b1;
                read_pending <= 1'b0;
            end
            if (axi_rvalid && axi_rready)
                axi_rvalid <= 1'b0;
        end
    end

    task issue_request;
        input write_not_read;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  mask;
        begin
            while (!cpu_req_ready) @(posedge cpu_clk);
            @(negedge cpu_clk);
            cpu_req_write = write_not_read;
            cpu_req_addr  = addr;
            cpu_req_wdata = data;
            cpu_req_wmask = mask;
            cpu_req_valid = 1'b1;
            @(posedge cpu_clk);
            @(negedge cpu_clk);
            cpu_req_valid = 1'b0;
        end
    endtask

    initial begin
        rst_n          = 1'b0;
        ddr_init_done  = 1'b0;
        cpu_req_valid  = 1'b0;
        cpu_req_write  = 1'b0;
        cpu_req_addr   = 32'd0;
        cpu_req_wdata  = 32'd0;
        cpu_req_wmask  = 4'd0;
        axi_bid        = 8'd0;
        axi_bresp      = 2'b00;
        axi_rid        = 8'd0;
        axi_rresp      = 2'b00;
        axi_rlast      = 1'b1;
        axi_rdata      = 256'd0;
        axi_rdata[191:160] = 32'h1234_5678;

        #31 rst_n = 1'b1;
        repeat (2) @(posedge cpu_clk);
        if (cpu_req_ready !== 1'b0) begin
            $display("FAIL: CPU request became ready before DDR initialization");
            $fatal;
        end
        $display("PASS: CPU request is held until ddr_init_done");

        #19 ddr_init_done = 1'b1;
        repeat (4) @(posedge cpu_clk);
        if (cpu_req_ready !== 1'b1) begin
            $display("FAIL: CPU request did not become ready after DDR initialization");
            $fatal;
        end

        issue_request(1'b1, 32'h8000_0014, 32'hAABB_CCDD, 4'b0101);
        wait (cpu_rsp_valid);
        #1;
        if (cpu_rsp_is_read || captured_awaddr != 30'h0000_0000 ||
            captured_wdata[191:160] != 32'hAABB_CCDD ||
            captured_wstrb[23:20] != 4'b0101 || axi_awsize != 3'd5) begin
            $display("FAIL: AXI write conversion addr=%h data_lane5=%h strb_lane5=%h size=%h read=%b",
                     captured_awaddr, captured_wdata[191:160],
                     captured_wstrb[23:20], axi_awsize, cpu_rsp_is_read);
            $fatal;
        end
        $display("PASS: write 0x80000014 -> AXI lane 5, data=AABBCCDD, WSTRB=0101");

        issue_request(1'b0, 32'h8000_0014, 32'd0, 4'd0);
        wait (cpu_rsp_valid && cpu_rsp_is_read);
        #1;
        if (cpu_rsp_rdata != 32'h1234_5678 || axi_araddr != 30'h0000_0000 ||
            axi_arsize != 3'd5) begin
            $display("FAIL: AXI read conversion");
            $fatal;
        end
        $display("PASS: read 0x80000014 <- AXI lane 5, data=12345678");

        $display("PASS: ddr_axi_bridge read/write width conversion and CDC handshake");
        $finish;
    end
endmodule
