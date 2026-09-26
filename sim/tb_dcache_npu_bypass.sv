`timescale 1ns / 1ps

// NPU 共享 DDR 区的 DCache bypass 回归。
// 这个 TB 直接连接 DCache 的 cache/uncache 侧接口，因此能精确检查一次
// CPU 访问究竟是 4 拍 Line refill，还是一拍、不分配 Cache Line 的访问。
module tb_dcache_npu_bypass;
    localparam [31:0] CACHED_BASE    = 32'h8000_0000;
    localparam [31:0] CACHED_BYTES   = 32'h3800_0000;
    localparam [31:0] CACHED_LAST    = 32'hb7ff_fffc;
    localparam [31:0] NPU_FIRST      = 32'hb800_0000;
    localparam [31:0] NPU_LAST       = 32'hbfff_fffc;
    localparam [31:0] MMIO_ADDR      = 32'h4000_0004;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg        dmem_req_valid = 1'b0;
    reg        dmem_req_write = 1'b0;
    reg [31:0] dmem_req_addr  = 32'b0;
    reg [31:0] dmem_req_wdata = 32'b0;
    reg [3:0]  dmem_req_wstrb = 4'b0;
    wire       dmem_req_ready;
    wire       dmem_rsp_valid;
    wire [31:0] dmem_rsp_data;
    wire       cache_miss;

    wire       rd_req;
    wire [2:0] rd_type;
    wire [31:0] rd_addr;
    reg        rd_rdy = 1'b1;
    reg        ret_valid = 1'b0;
    reg        ret_last  = 1'b0;
    reg [31:0] ret_data  = 32'b0;

    wire        wr_req;
    wire [2:0]  wr_type;
    wire [31:0] wr_addr;
    wire [3:0]  wr_wstrb;
    wire [127:0] wr_data;
    reg         wr_rdy = 1'b1;

    integer rd_handshakes = 0;
    integer wr_handshakes = 0;
    integer rsp_count = 0;
    integer timeout_count = 0;

    always #5 clk = ~clk;

    dcache #(
        .CACHEABLE_DDR_BASE      (CACHED_BASE),
        .CACHEABLE_DDR_BYTES     (CACHED_BYTES)
    ) dut (
        .clk             (clk),
        .rst             (rst),
        .dmem_req_valid  (dmem_req_valid),
        .dmem_req_write  (dmem_req_write),
        .dmem_req_addr   (dmem_req_addr),
        .dmem_req_wdata  (dmem_req_wdata),
        .dmem_req_wstrb  (dmem_req_wstrb),
        .dmem_req_ready  (dmem_req_ready),
        .dmem_rsp_valid  (dmem_rsp_valid),
        .dmem_rsp_data   (dmem_rsp_data),
        .cache_miss      (cache_miss),
        .rd_req          (rd_req),
        .rd_type         (rd_type),
        .rd_addr         (rd_addr),
        .rd_rdy          (rd_rdy),
        .ret_valid       (ret_valid),
        .ret_last        (ret_last),
        .ret_data        (ret_data),
        .wr_req          (wr_req),
        .wr_type         (wr_type),
        .wr_addr         (wr_addr),
        .wr_wstrb        (wr_wstrb),
        .wr_data         (wr_data),
        .wr_rdy          (wr_rdy)
    );

    // 对每次实际外部请求计数；缓存命中不应改变这两个计数。
    always @(posedge clk) begin
        if (!rst && rd_req && rd_rdy)
            rd_handshakes = rd_handshakes + 1;
        if (!rst && wr_req && wr_rdy)
            wr_handshakes = wr_handshakes + 1;
        if (!rst && dmem_rsp_valid)
            rsp_count = rsp_count + 1;
    end

    task fail;
        input string why;
        begin
            $fatal(1, "DCACHE_NPU_BYPASS_FAIL: %0s", why);
        end
    endtask

    // 在 DCache 空闲时送入一个 CPU load/store 请求。
    task issue_cpu_request;
        input        is_write;
        input [31:0] addr;
        input [31:0] wdata;
        input [3:0]  wstrb;
        begin
            while (!dmem_req_ready)
                @(posedge clk);
            @(negedge clk);
            dmem_req_valid = 1'b1;
            dmem_req_write = is_write;
            dmem_req_addr  = addr;
            dmem_req_wdata = wdata;
            dmem_req_wstrb = wstrb;
            @(posedge clk);
            @(negedge clk);
            dmem_req_valid = 1'b0;
            dmem_req_write = 1'b0;
            dmem_req_addr  = 32'b0;
            dmem_req_wdata = 32'b0;
            dmem_req_wstrb = 4'b0;
        end
    endtask

    // 等待并检查一笔读请求；调用结束时该读地址已经完成握手。
    task expect_read_request;
        input [2:0]  expected_type;
        input [31:0] expected_addr;
        input string name;
        begin
            wait (rd_req === 1'b1);
            #1;
            if (rd_type !== expected_type)
                fail({name, ": wrong rd_type"});
            if (rd_addr !== expected_addr)
                fail({name, ": wrong rd_addr"});
            @(posedge clk);
        end
    endtask

    // 返回指定数量的 32-bit 数据拍；最后一拍同时带 ret_last。
    task return_read_beats;
        input integer beats;
        input [31:0] seed;
        integer beat;
        begin
            for (beat = 0; beat < beats; beat = beat + 1) begin
                @(negedge clk);
                ret_valid = 1'b1;
                ret_last  = (beat == beats - 1);
                ret_data  = seed + beat;
                @(posedge clk);
            end
            @(negedge clk);
            ret_valid = 1'b0;
            ret_last  = 1'b0;
            ret_data  = 32'b0;
        end
    endtask

    // 等待并检查一笔直写；uncache store 不得产生 rd_req/refill。
    task expect_uncached_write;
        input [31:0] expected_addr;
        input [31:0] expected_data;
        input [3:0]  expected_strb;
        begin
            wait (wr_req === 1'b1);
            #1;
            if (wr_type !== 3'b010)
                fail("NPU store is not a one-word uncached write");
            if (wr_addr !== expected_addr)
                fail("NPU store address was changed");
            if (wr_wstrb !== expected_strb)
                fail("NPU store strobe is wrong");
            if (wr_data[31:0] !== expected_data)
                fail("NPU store data is wrong");
            if (rd_req)
                fail("NPU store unexpectedly starts a line refill");
            @(posedge clk);
        end
    endtask

    task wait_until_idle;
        integer guard;
        begin
            guard = 0;
            while (!dmem_req_ready) begin
                @(posedge clk);
                guard = guard + 1;
                if (guard > 32)
                    fail("DCache did not return to idle");
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst = 1'b0;

        // CPU 区末字仍属于缓存区：先产生 4 拍 refill，随后同地址必须命中。
        issue_cpu_request(1'b0, CACHED_LAST, 32'b0, 4'b0);
        expect_read_request(3'b100, 32'hb7ff_fff0, "cached boundary read");
        return_read_beats(4, 32'h1000_0000);
        wait_until_idle;
        if (rd_handshakes != 1)
            fail("cached boundary first read did not issue exactly one refill");

        issue_cpu_request(1'b0, CACHED_LAST, 32'b0, 4'b0);
        repeat (3) @(posedge clk);
        if (rd_handshakes != 1)
            fail("cached boundary second read missed instead of hitting");
        wait_until_idle;

        // NPU 区首字必须保持原地址的一拍读；两次读取都要重新发到外部。
        issue_cpu_request(1'b0, NPU_FIRST, 32'b0, 4'b0);
        expect_read_request(3'b010, NPU_FIRST, "NPU first read");
        return_read_beats(1, 32'h2000_0000);
        wait_until_idle;

        issue_cpu_request(1'b0, NPU_FIRST, 32'b0, 4'b0);
        expect_read_request(3'b010, NPU_FIRST, "NPU repeated read");
        return_read_beats(1, 32'h2000_0001);
        wait_until_idle;
        if (rd_handshakes != 3)
            fail("NPU repeated reads were cached or request count is wrong");

        // NPU 区末字也应为 uncached，防止分界判定意外使用 <=。
        issue_cpu_request(1'b0, NPU_LAST, 32'b0, 4'b0);
        expect_read_request(3'b010, NPU_LAST, "NPU last read");
        return_read_beats(1, 32'h2000_0002);
        wait_until_idle;

        // NPU store 是单拍直写，不能先读取、填充或污染任一 Cache Line。
        issue_cpu_request(1'b1, NPU_FIRST + 32'd4, 32'hdeaf_beef, 4'b0101);
        expect_uncached_write(NPU_FIRST + 32'd4, 32'hdeaf_beef, 4'b0101);
        wait_until_idle;
        if (rd_handshakes != 4)
            fail("NPU store issued an unexpected external read");
        if (wr_handshakes != 1)
            fail("NPU store did not issue exactly one external write");

        // 紧随直写再读同一字，仍必须外发单拍读；若 store 错误写入 DCache，
        // 这里会命中而不会出现 rd_req，从而直接暴露 tag/valid/dirty 污染。
        issue_cpu_request(1'b0, NPU_FIRST + 32'd4, 32'b0, 4'b0);
        expect_read_request(3'b010, NPU_FIRST + 32'd4, "NPU store-followed load");
        return_read_beats(1, 32'h2000_0003);
        wait_until_idle;
        if (rd_handshakes != 5)
            fail("NPU store-followed load was incorrectly served by DCache");

        // 原有 MMIO 同样必须保留单拍 uncached 读语义。
        issue_cpu_request(1'b0, MMIO_ADDR, 32'b0, 4'b0);
        expect_read_request(3'b010, MMIO_ADDR, "MMIO read");
        return_read_beats(1, 32'h3000_0000);
        wait_until_idle;
        if (rd_handshakes != 6)
            fail("MMIO read no longer uses an uncached one-word request");

        $display("DCACHE_NPU_BYPASS_PASS rsp_count=%0d", rsp_count);
        $finish;
    end

    // 防止任一状态机故障令仿真无期限等待。
    always @(posedge clk) begin
        if (!rst) begin
            timeout_count = timeout_count + 1;
            if (timeout_count > 1000)
                fail("simulation timeout");
        end
    end
endmodule
