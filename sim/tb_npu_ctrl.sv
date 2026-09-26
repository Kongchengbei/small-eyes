`timescale 1ns / 1ps

// NPU 控制寄存器专用回归。TB 以 CPU 风格的 MMIO 单拍访问配置寄存器，
// 并用一个小型时序模型产生 engine_done，不依赖 UART 或完整 SoC。
module tb_npu_ctrl;
    localparam [31:0] NPU_BASE = 32'h4000_0100;
    localparam [31:0] NPU_BYTES = 32'h0000_0100;
    localparam [31:0] REG_CTRL        = NPU_BASE + 32'h00;
    localparam [31:0] REG_STATUS      = NPU_BASE + 32'h04;
    localparam [31:0] REG_INPUT_ADDR  = NPU_BASE + 32'h08;
    localparam [31:0] REG_WEIGHT_ADDR = NPU_BASE + 32'h0c;
    localparam [31:0] REG_OUTPUT_ADDR = NPU_BASE + 32'h10;
    localparam [31:0] REG_TASK_BYTES  = NPU_BASE + 32'h14;
    localparam [31:0] REG_IRQ_ENABLE  = NPU_BASE + 32'h18;
    localparam [31:0] REG_IRQ_STATUS  = NPU_BASE + 32'h1c;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg        mmio_valid = 1'b0;
    reg        mmio_wen = 1'b0;
    reg [31:0] mmio_addr = 32'b0;
    reg [31:0] mmio_wdata = 32'b0;
    reg [3:0]  mmio_wstrb = 4'b0;
    wire       mmio_addr_sel;
    wire       mmio_sel;
    wire       mmio_ready;
    wire [31:0] mmio_rdata;
    wire       start_pulse;
    reg        engine_done_auto = 1'b0;
    reg        engine_done_manual = 1'b0;
    wire       engine_done = engine_done_auto || engine_done_manual;
    wire [31:0] engine_input_addr;
    wire [31:0] engine_weight_addr;
    wire [31:0] engine_output_addr;
    wire [31:0] engine_task_bytes;
    wire        irq;

    reg auto_engine_enable = 1'b1;
    reg [3:0] auto_delay = 4'b0;
    integer start_count = 0;
    integer timeout_count = 0;

    always #5 clk = ~clk;

    Hnpu_ctrl #(
        .NPU_MMIO_BASE  (NPU_BASE),
        .NPU_MMIO_BYTES (NPU_BYTES)
    ) dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .mmio_valid         (mmio_valid),
        .mmio_wen           (mmio_wen),
        .mmio_addr          (mmio_addr),
        .mmio_wdata         (mmio_wdata),
        .mmio_wstrb         (mmio_wstrb),
        .mmio_addr_sel      (mmio_addr_sel),
        .mmio_sel           (mmio_sel),
        .mmio_ready         (mmio_ready),
        .mmio_rdata         (mmio_rdata),
        .start_pulse        (start_pulse),
        .engine_done        (engine_done),
        .engine_input_addr  (engine_input_addr),
        .engine_weight_addr (engine_weight_addr),
        .engine_output_addr (engine_output_addr),
        .engine_task_bytes  (engine_task_bytes),
        .irq                (irq)
    );

    // 第一轮任务的简化引擎模型：观察 start_pulse 后等待三个时钟，再完成。
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            auto_delay <= 4'b0;
            engine_done_auto <= 1'b0;
        end else begin
            engine_done_auto <= 1'b0;
            if (start_pulse && auto_engine_enable) begin
                auto_delay <= 4'd3;
            end else if (auto_delay != 4'b0) begin
                if (auto_delay == 4'd1) begin
                    auto_delay <= 4'b0;
                    engine_done_auto <= 1'b1;
                end else begin
                    auto_delay <= auto_delay - 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            start_count = 0;
            timeout_count = 0;
        end else begin
            if (start_pulse)
                start_count = start_count + 1;
            timeout_count = timeout_count + 1;
            if (timeout_count > 500)
                $fatal(1, "NPU_CTRL_FAIL: simulation timeout");
        end
    end

    task fail;
        input string why;
        begin
            $fatal(1, "NPU_CTRL_FAIL: %0s", why);
        end
    endtask

    task expect_equal;
        input [31:0] actual;
        input [31:0] expected;
        input string name;
        begin
            if (actual !== expected)
                fail({name, " actual/expected mismatch"});
        end
    endtask

    // 模拟一笔 CPU MMIO 写；控制器固定 ready=1，故无需额外等待周期。
    task mmio_write;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  strb;
        begin
            @(negedge clk);
            mmio_valid = 1'b1;
            mmio_wen   = 1'b1;
            mmio_addr  = addr;
            mmio_wdata = data;
            mmio_wstrb = strb;
            #1;
            if (mmio_ready !== 1'b1)
                fail("MMIO write was unexpectedly stalled");
            @(posedge clk);
            @(negedge clk);
            mmio_valid = 1'b0;
            mmio_wen   = 1'b0;
            mmio_addr  = 32'b0;
            mmio_wdata = 32'b0;
            mmio_wstrb = 4'b0;
        end
    endtask

    // 模拟一笔 CPU MMIO 读，在请求有效时采样组合返回数据。
    task mmio_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            mmio_valid = 1'b1;
            mmio_wen   = 1'b0;
            mmio_addr  = addr;
            mmio_wdata = 32'b0;
            mmio_wstrb = 4'b0;
            #1;
            if (mmio_ready !== 1'b1)
                fail("MMIO read was unexpectedly stalled");
            data = mmio_rdata;
            @(posedge clk);
            @(negedge clk);
            mmio_valid = 1'b0;
            mmio_addr  = 32'b0;
        end
    endtask

    // 在同一时钟边沿同时向控制器送 W1C 与 engine_done，检验完成优先。
    task complete_and_w1c_same_cycle;
        begin
            @(negedge clk);
            mmio_valid = 1'b1;
            mmio_wen   = 1'b1;
            mmio_addr  = REG_IRQ_STATUS;
            mmio_wdata = 32'h0000_0001;
            mmio_wstrb = 4'b0001;
            engine_done_manual = 1'b1;
            @(posedge clk);
            @(negedge clk);
            mmio_valid = 1'b0;
            mmio_wen   = 1'b0;
            mmio_addr  = 32'b0;
            mmio_wdata = 32'b0;
            mmio_wstrb = 4'b0;
            engine_done_manual = 1'b0;
        end
    endtask

    // 通过公开 STATUS 寄存器轮询引擎完成，不窥探控制器的内部状态寄存器。
    task poll_done_via_mmio;
        integer guard;
        reg [31:0] status_value;
        begin : poll_loop
            for (guard = 0; guard < 32; guard = guard + 1) begin
                mmio_read(REG_STATUS, status_value);
                if (status_value[1]) begin
                    if (status_value[0])
                        fail("STATUS reports busy and done simultaneously");
                    disable poll_loop;
                end
            end
            fail("STATUS polling did not observe done");
        end
    endtask

    reg [31:0] read_data;
    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // 复位值、窗口外访问和未定义偏移均不能产生有效寄存器数据。
        mmio_read(REG_STATUS, read_data);
        expect_equal(read_data, 32'b0, "reset status");
        @(negedge clk);
        mmio_addr = NPU_BASE - 32'd4;
        #1;
        if (mmio_addr_sel || mmio_sel || (mmio_rdata != 32'b0))
            fail("out-of-window address was selected");
        mmio_addr = NPU_BASE + 32'h20;
        #1;
        if (!mmio_addr_sel || (mmio_rdata != 32'b0))
            fail("undefined register did not read as zero");
        mmio_addr = 32'b0;

        // 地址寄存器应按 byte strobe 合并，而非总是整字覆盖。
        mmio_write(REG_INPUT_ADDR, 32'h1122_3344, 4'b1111);
        mmio_write(REG_INPUT_ADDR, 32'h0000_aa00, 4'b0010);
        mmio_read(REG_INPUT_ADDR, read_data);
        expect_equal(read_data, 32'h1122_aa44, "partial input address write");
        mmio_write(REG_WEIGHT_ADDR, 32'h5566_7788, 4'b1111);
        mmio_write(REG_OUTPUT_ADDR, 32'h99aa_bbcc, 4'b1111);
        mmio_write(REG_TASK_BYTES, 32'h0000_0400, 4'b1111);
        mmio_write(REG_IRQ_ENABLE, 32'h0000_0001, 4'b0001);

        // 启动后 busy 立即可见，输出配置被锁存；busy 时第二次 start 必须忽略。
        mmio_write(REG_CTRL, 32'h0000_0001, 4'b0001);
        if (!start_pulse)
            fail("accepted start did not produce start_pulse");
        expect_equal(engine_input_addr, 32'h1122_aa44, "latched input address");
        expect_equal(engine_weight_addr, 32'h5566_7788, "latched weight address");
        expect_equal(engine_output_addr, 32'h99aa_bbcc, "latched output address");
        expect_equal(engine_task_bytes, 32'h0000_0400, "latched task bytes");
        // 紧接着再次写 start，此时 busy 已置位，必须被忽略。
        mmio_write(REG_CTRL, 32'h0000_0001, 4'b0001);
        mmio_read(REG_STATUS, read_data);
        expect_equal(read_data, 32'h0000_0001, "busy status after start");
        // 0x84 在 256 Byte 窗口内但不是已定义寄存器，不能别名到 STATUS(0x04)。
        mmio_read(NPU_BASE + 32'h84, read_data);
        expect_equal(read_data, 32'b0, "high offset invalid register");
        repeat (2) @(posedge clk);
        if (start_count != 1)
            fail("busy-time second start was not ignored");

        // 自动引擎完成后，done 粘滞、busy 清零、IRQ 置位；只经 MMIO STATUS
        // 轮询确认完成，不读取控制器内部寄存器。
        poll_done_via_mmio;
        mmio_read(REG_STATUS, read_data);
        expect_equal(read_data, 32'h0000_0002, "done status after engine completion");
        if (!irq)
            fail("done with IRQ_ENABLE did not assert irq");
        mmio_read(REG_IRQ_STATUS, read_data);
        expect_equal(read_data, 32'h0000_0001, "IRQ status after completion");

        // 故意不先 W1C；下一轮 start 必须清除旧 done 和旧 IRQ。
        auto_engine_enable = 1'b0;
        mmio_write(REG_CTRL, 32'h0000_0001, 4'b0001);
        mmio_read(REG_STATUS, read_data);
        expect_equal(read_data, 32'h0000_0001, "new start clears old done");
        if (irq)
            fail("new start did not clear old IRQ");

        // 第二轮关闭自动完成，用同拍 engine_done 与 W1C 验证完成优先。
        repeat (2) @(posedge clk);
        if (start_count != 2)
            fail("second idle start was not accepted");
        complete_and_w1c_same_cycle;
        mmio_read(REG_STATUS, read_data);
        expect_equal(read_data, 32'h0000_0002, "completion priority over same-cycle W1C");
        if (!irq)
            fail("completion-priority event did not assert irq");

        // 完成后的普通 W1C 仍应清除 done 与 IRQ。
        mmio_write(REG_IRQ_STATUS, 32'h0000_0001, 4'b0001);
        mmio_read(REG_STATUS, read_data);
        expect_equal(read_data, 32'b0, "status after W1C");
        if (irq)
            fail("IRQ remained asserted after W1C");

        $display("NPU_CTRL_PASS starts=%0d", start_count);
        $finish;
    end
endmodule
