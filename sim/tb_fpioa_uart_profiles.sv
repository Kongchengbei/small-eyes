`timescale 1ns / 1ps

module tb_fpioa_uart_profiles;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst_n = 1'b0;
    reg local_valid = 1'b0;
    reg local_wen = 1'b0;
    reg [7:0] local_addr = 8'b0;
    reg [31:0] local_wdata = 32'b0;
    reg [3:0] local_wmask = 4'b0;
    wire [31:0] local_rdata;
    reg local_uart_tx = 1'b0;
    wire [31:0] local_fpioa;

    reg remote_valid = 1'b0;
    reg remote_wen = 1'b0;
    reg [7:0] remote_addr = 8'b0;
    reg [31:0] remote_wdata = 32'b0;
    reg [3:0] remote_wmask = 4'b0;
    wire [31:0] remote_rdata;
    reg remote_uart_tx = 1'b1;
    wire [31:0] remote_fpioa;

    Hfpioa_simple #(.UART_TX_DEFAULT_FPIOA(0)) u_local (
        .clk(clk), .rst_n(rst_n),
        .mmio_valid(local_valid), .mmio_wen(local_wen),
        .mmio_addr(local_addr), .mmio_wdata(local_wdata),
        .mmio_wmask(local_wmask), .mmio_rdata(local_rdata),
        .uart0_tx(local_uart_tx), .direct_led(4'b0), .fpioa(local_fpioa)
    );

    Hfpioa_simple #(.UART_TX_DEFAULT_FPIOA(31)) u_remote (
        .clk(clk), .rst_n(rst_n),
        .mmio_valid(remote_valid), .mmio_wen(remote_wen),
        .mmio_addr(remote_addr), .mmio_wdata(remote_wdata),
        .mmio_wmask(remote_wmask), .mmio_rdata(remote_rdata),
        .uart0_tx(remote_uart_tx), .direct_led(4'b0), .fpioa(remote_fpioa)
    );

    task automatic write_map(input bit remote, input [7:0] addr,
                             input [31:0] data, input [3:0] mask);
        begin
            @(negedge clk);
            if (remote) begin
                remote_valid = 1'b1;
                remote_wen = 1'b1;
                remote_addr = addr;
                remote_wdata = data;
                remote_wmask = mask;
            end else begin
                local_valid = 1'b1;
                local_wen = 1'b1;
                local_addr = addr;
                local_wdata = data;
                local_wmask = mask;
            end
            @(negedge clk);
            if (remote) begin
                remote_valid = 1'b0;
                remote_wen = 1'b0;
            end else begin
                local_valid = 1'b0;
                local_wen = 1'b0;
            end
        end
    endtask

    task automatic check_map_read(input bit remote, input [7:0] addr,
                                  input [31:0] expected);
        reg [31:0] observed;
        begin
            @(negedge clk);
            if (remote) begin
                remote_valid = 1'b1;
                remote_wen = 1'b0;
                remote_addr = addr;
            end else begin
                local_valid = 1'b1;
                local_wen = 1'b0;
                local_addr = addr;
            end
            #1;
            observed = remote ? remote_rdata : local_rdata;
            if (observed !== expected)
                $fatal(1, "FPIOA map read addr=%02x expected=%08x got=%08x remote=%0d",
                       addr, expected, observed, remote);
            @(negedge clk);
            if (remote)
                remote_valid = 1'b0;
            else
                local_valid = 1'b0;
        end
    endtask

    task automatic check_uart_pins(input bit local_at_zero,
                                   input bit local_tx,
                                   input bit remote_tx);
        begin
            #1;
            if (local_at_zero) begin
                if (local_fpioa[0] !== local_tx || local_fpioa[31] !== 1'bz)
                    $fatal(1, "local UART expected FPIOA0=%b, FPIOA31=Z; got %b/%b",
                           local_tx, local_fpioa[0], local_fpioa[31]);
                if (remote_fpioa[31] !== remote_tx || remote_fpioa[0] !== 1'bz)
                    $fatal(1, "remote UART expected FPIOA31=%b, FPIOA0=Z; got %b/%b",
                           remote_tx, remote_fpioa[31], remote_fpioa[0]);
            end else begin
                if (local_fpioa[31] !== local_tx || local_fpioa[0] !== 1'bz)
                    $fatal(1, "switched local UART expected FPIOA31=%b, FPIOA0=Z; got %b/%b",
                           local_tx, local_fpioa[31], local_fpioa[0]);
                if (remote_fpioa[0] !== remote_tx || remote_fpioa[31] !== 1'bz)
                    $fatal(1, "switched remote UART expected FPIOA0=%b, FPIOA31=Z; got %b/%b",
                           remote_tx, remote_fpioa[0], remote_fpioa[31]);
            end
        end
    endtask

    initial begin
        #20;
        rst_n = 1'b1;
        #2;
        check_uart_pins(1'b1, local_uart_tx, remote_uart_tx);

        // 对齐字回读必须同时包含四个映射字节。
        check_map_read(1'b0, 8'd0, 32'h0000_0007);
        check_map_read(1'b1, 8'd0, 32'h0000_0000);
        check_map_read(1'b1, 8'd28, 32'h0700_0000);

        // 对齐地址加 lane 0/3 的字节写；lane 3 只更新 pin 31，不碰 pin 28。
        write_map(1'b1, 8'd28, 32'h0000_0003, 4'b0001);
        write_map(1'b1, 8'd28, 32'h0700_0000, 4'b1000);
        check_map_read(1'b1, 8'd28, 32'h0700_0003);

        // 空掩码不能修改任何映射字节。
        write_map(1'b1, 8'd28, 32'h0403_0201, 4'b0000);
        check_map_read(1'b1, 8'd28, 32'h0700_0003);

        // 全字写覆盖四个映射脚，之后从同一个字地址完整回读。
        write_map(1'b0, 8'd0, 32'h0403_0201, 4'b1111);
        check_map_read(1'b0, 8'd0, 32'h0403_0201);

        // 兼容旧式非对齐 byte 地址：0x1f + lane 3 仍写 pin 31。
        write_map(1'b0, 8'd28, 32'h0000_0003, 4'b0001);
        write_map(1'b0, 8'd31, 32'h0700_0000, 4'b1000);
        check_map_read(1'b0, 8'd31, 32'h0700_0003);

        // 软件先关闭两个候选脚，再把 UART 交叉切到另一个候选脚。
        write_map(1'b0, 8'd0, 32'h0000_0000, 4'b0001);
        write_map(1'b0, 8'd28, 32'h0000_0000, 4'b1000);
        write_map(1'b1, 8'd0, 32'h0000_0000, 4'b0001);
        write_map(1'b1, 8'd28, 32'h0000_0000, 4'b1000);
        #1;
        if (local_fpioa[0] !== 1'bz || local_fpioa[31] !== 1'bz ||
            remote_fpioa[0] !== 1'bz || remote_fpioa[31] !== 1'bz)
            $fatal(1, "cleared UART candidates must both be high impedance");

        write_map(1'b0, 8'd28, 32'h0700_0000, 4'b1000);
        write_map(1'b1, 8'd0, 32'h0000_0007, 4'b0001);
        check_uart_pins(1'b0, local_uart_tx, remote_uart_tx);

        local_uart_tx = 1'b1;
        remote_uart_tx = 1'b0;
        check_uart_pins(1'b0, local_uart_tx, remote_uart_tx);
        $display("PASS: UART FPIOA default profiles and MMIO byte lanes");
        $finish;
    end
endmodule
