`timescale 1ns / 1ps

module tb_camera_async_fifo;
    logic rst_n = 1'b0;
    logic wr_clk = 1'b0;
    logic rd_clk = 1'b0;
    logic wr_en = 1'b0;
    logic [17:0] wr_data = 18'b0;
    wire full;
    wire overflow;
    logic rd_en = 1'b0;
    wire [17:0] rd_data;
    wire rd_valid;
    wire empty;
    wire underflow;

    integer mode = 0;
    integer wr_attempts = 0;
    integer wr_count = 0;
    integer rd_count = 0;
    logic [17:0] expected [0:4095];

    always #7 wr_clk = ~wr_clk;
    always #5 rd_clk = ~rd_clk;

    Hcamera_async_fifo #(.DATA_WIDTH(18), .ADDR_WIDTH(4)) dut (
        .rst_n, .wr_clk, .wr_en, .wr_data, .full, .overflow,
        .rd_clk, .rd_en, .rd_data, .rd_valid, .empty, .underflow,
        .wr_level(), .rd_level(), .wr_max_level()
    );

    // 写入递增序列；满时仍继续给出数据，用于确认不会覆盖旧像素。
    always @(negedge wr_clk) begin
        wr_en = 1'b0;
        if (mode == 1 && wr_attempts < 1000 && $urandom_range(0, 3) != 0) begin
            wr_en = 1'b1;
            wr_data = {2'b00, 16'(wr_attempts)};
            wr_attempts++;
        end else if (mode == 2) begin
            wr_en = 1'b1;
            wr_data = {2'b01, 16'(wr_attempts)};
            wr_attempts++;
        end
    end

    always @(posedge wr_clk) begin
        if (rst_n && wr_en && !full) begin
            expected[wr_count] = wr_data;
            wr_count++;
        end
    end

    // rd_valid 是成功读拍的注册结果，在下降沿比对可避开仿真调度竞态。
    always @(negedge rd_clk) begin
        if (rst_n && rd_valid) begin
            if (rd_count >= wr_count)
                $fatal(1, "FIFO 产生了多余数据");
            if (rd_data !== expected[rd_count])
                $fatal(1, "FIFO 顺序/数据错误：序号 %0d, 实际 %h, 预期 %h",
                       rd_count, rd_data, expected[rd_count]);
            rd_count++;
        end
        case (mode)
            1: rd_en = !empty && ($urandom_range(0, 3) != 0);
            3: rd_en = !empty;
            4: rd_en = 1'b1;
            default: rd_en = 1'b0;
        endcase
    end

    initial begin
        #2000000;
        $fatal(1, "FIFO 测试超时");
    end

    initial begin
        repeat (6) @(posedge rd_clk);
        rst_n = 1'b1;
        repeat (6) @(posedge wr_clk);

        mode = 1;
        wait (wr_attempts == 1000);
        @(posedge wr_clk);
        mode = 3;
        wait (rd_count == wr_count && empty);
        repeat (5) @(posedge rd_clk);
        if (overflow || underflow || wr_count != 1000)
            $fatal(1, "随机双时钟传输统计异常：写 %0d, 读 %0d", wr_count, rd_count);

        // 人为暂停读端，强制满、溢出，再核对已接受数据的顺序。
        mode = 2;
        repeat (50) @(posedge wr_clk);
        mode = 3;
        if (!overflow || !full)
            $fatal(1, "满 FIFO 未报告溢出");
        wait (rd_count == wr_count && empty);
        repeat (5) @(posedge rd_clk);
        if (underflow)
            $fatal(1, "正常排空不应产生下溢");

        mode = 4;
        repeat (4) @(posedge rd_clk);
        mode = 0;
        repeat (2) @(posedge rd_clk);
        if (!underflow || rd_count != wr_count)
            $fatal(1, "空读未报告下溢，或产生伪数据");

        // 非空时复位，确认双方指针及状态重新对齐。
        mode = 2;
        repeat (6) @(posedge wr_clk);
        @(negedge wr_clk);
        #1;
        mode = 0;
        rst_n = 1'b0;
        wr_count = 0;
        rd_count = 0;
        wr_attempts = 0;
        repeat (5) @(posedge rd_clk);
        rst_n = 1'b1;
        repeat (6) @(posedge wr_clk);
        if (full || !empty || overflow || underflow || rd_valid)
            $fatal(1, "复位后 FIFO 状态错误");

        mode = 1;
        wait (wr_attempts == 1000);
        @(posedge wr_clk);
        mode = 3;
        wait (rd_count == wr_count && empty);
        repeat (5) @(posedge rd_clk);
        if (wr_count != 1000 || overflow || underflow)
            $fatal(1, "复位后的传输异常");

        $display("CAMERA_ASYNC_FIFO_PASS: 双时钟顺序、满/空、溢出/下溢、复位");
        $finish;
    end
endmodule
