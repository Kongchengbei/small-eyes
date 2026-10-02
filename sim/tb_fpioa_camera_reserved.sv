`timescale 1ns / 1ps

// CAM2 占用脚只能作为输入：即使 MMIO 尝试 NIO/UART 输出映射也必须保持高阻。
module tb_fpioa_camera_reserved;
    localparam [31:0] CAM2_MASK = 32'h3004_0000;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg mmio_valid = 1'b0;
    reg mmio_wen = 1'b0;
    reg [7:0] mmio_addr = 8'b0;
    reg [31:0] mmio_wdata = 32'b0;
    reg [3:0] mmio_wmask = 4'b0;
    wire [31:0] mmio_rdata;
    reg uart0_tx = 1'b0;
    reg [3:0] direct_led = 4'b0;
    tri [31:0] fpioa;
    reg [31:0] external_drive = 32'b0;
    reg [31:0] external_oe = 32'b0;
    reg [2:0] cam2_data_hi = 3'b0;
    reg cam2_data3 = 1'b0;
    reg cam2_data0 = 1'b0;
    wire [7:0] cam2_data = {cam2_data_hi, fpioa[18], cam2_data3,
                            fpioa[29], fpioa[28], cam2_data0};
    integer pattern_index;
    reg [31:0] expected_bus;

    always #5 clk = ~clk;
    genvar pin;
    generate
        for (pin = 0; pin < 32; pin = pin + 1) begin: external_pads
            assign fpioa[pin] = external_oe[pin] ? external_drive[pin] : 1'bz;
        end
    endgenerate

    Hfpioa_simple #(
        .UART_TX_DEFAULT_FPIOA(0),
        .INPUT_ONLY_MASK(CAM2_MASK)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .mmio_valid(mmio_valid), .mmio_wen(mmio_wen),
        .mmio_addr(mmio_addr), .mmio_wdata(mmio_wdata),
        .mmio_wmask(mmio_wmask), .mmio_rdata(mmio_rdata),
        .uart0_tx(uart0_tx), .direct_led(direct_led), .fpioa(fpioa)
    );

    task automatic write_reg(input [7:0] addr, input [31:0] value,
                             input [3:0] mask);
        begin
            @(negedge clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b1;
            mmio_addr = addr;
            mmio_wdata = value;
            mmio_wmask = mask;
            @(negedge clk);
            mmio_valid = 1'b0;
            mmio_wen = 1'b0;
            mmio_wmask = 4'b0;
        end
    endtask

    task automatic check_reserved_z(input integer pin_index);
        begin
            // 暂时松开外部传感器驱动，直接观察 PAD 是否为高阻。
            external_oe[pin_index] = 1'b0;
            #1;
            if (fpioa[pin_index] !== 1'bz)
                $fatal(1, "CAM2 保留脚 %0d 被内部驱动，值=%b", pin_index,
                       fpioa[pin_index]);
            external_oe[pin_index] = 1'b1;
            #1;
        end
    endtask

    task automatic check_input(input [31:0] expected);
        begin
            mmio_valid = 1'b1;
            mmio_wen = 1'b0;
            mmio_addr = 8'h20;
            #1;
            if ((mmio_rdata & CAM2_MASK) !== (expected & CAM2_MASK))
                $fatal(1, "FPIOA 输入读回错误 actual=%08x expected=%08x",
                       mmio_rdata, expected);
            mmio_valid = 1'b0;
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        // 分别验证三根 CAM2 输入脚的两种外部电平组合。
        external_oe = CAM2_MASK;
        external_drive = 32'h3004_0000;
        #1;
        check_input(CAM2_MASK);
        external_drive = 32'b0;
        #1;
        check_input(32'b0);

        // 将保留脚全部尝试切成 NIO 推挽输出并驱高。
        write_reg(8'h24, CAM2_MASK, 4'hf);
        write_reg(8'h2c, CAM2_MASK, 4'hf);
        write_reg(8'h12, 32'h0000_0000, 4'b0001); // pin 18 -> NIO
        write_reg(8'h1c, 32'h0000_0000, 4'b0001); // pin 28 -> NIO
        write_reg(8'h1d, 32'h0000_0000, 4'b0001); // pin 29 -> NIO
        repeat (2) @(negedge clk);
        check_reserved_z(18);
        check_reserved_z(28);
        check_reserved_z(29);

        // 再逐个映射到 UART_TX，物理脚仍必须保持输入高阻。
        write_reg(8'h10, 32'h0007_0000, 4'b0100); // pin 18
        write_reg(8'h1c, 32'h0000_0700, 4'b0010); // pin 28
        write_reg(8'h1c, 32'h0007_0000, 4'b0100); // pin 29
        uart0_tx = 1'b1;
        repeat (2) @(negedge clk);
        check_reserved_z(18);
        check_reserved_z(28);
        check_reserved_z(29);
        uart0_tx = 1'b0;
        #1;
        check_input(32'b0);
        external_drive = CAM2_MASK;
        #1;
        check_input(CAM2_MASK);

        // 覆盖全部 256 种 CAM2_D[7:0] 组合，验证三个 FPIOA 位的次序和落点。
        // 生产顶层使用同一拼接：D4=18、D2=29、D1=28，其余五位为独立输入。
        for (pattern_index = 0; pattern_index < 256; pattern_index = pattern_index + 1) begin
            cam2_data_hi = pattern_index[7:5];
            cam2_data3 = pattern_index[3];
            cam2_data0 = pattern_index[0];
            external_drive = 32'b0;
            external_drive[18] = pattern_index[4];
            external_drive[29] = pattern_index[2];
            external_drive[28] = pattern_index[1];
            #1;
            if (cam2_data !== pattern_index[7:0])
                $fatal(1, "CAM2 DVP byte assembly error input=%02x got=%02x",
                       pattern_index[7:0], cam2_data);
            expected_bus = 32'b0;
            expected_bus[18] = pattern_index[4];
            expected_bus[29] = pattern_index[2];
            expected_bus[28] = pattern_index[1];
            check_input(expected_bus);
        end

        // 默认脚 0 和可配置脚 31 的 UART 输出映射维持原行为。
        if (fpioa[0] !== 1'b0) $fatal(1, "UART 默认脚 0 未输出 uart0_tx");
        write_reg(8'h1c, 32'h0700_0000, 4'b1000); // pin 31 -> UART_TX
        uart0_tx = 1'b1;
        #1;
        if (fpioa[0] !== 1'b1 || fpioa[31] !== 1'b1)
            $fatal(1, "普通 UART 映射异常 pin0=%b pin31=%b", fpioa[0], fpioa[31]);

        // CAM2 脚仍可读，且与外部传感器输入一致。
        check_input(CAM2_MASK);
        $display("FPIOA_CAMERA_RESERVED_PASS mask=%08x", CAM2_MASK);
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "FPIOA camera reserved test timed out");
    end
endmodule
