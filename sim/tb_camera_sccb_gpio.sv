`timescale 1ns / 1ps

module tb_camera_sccb_gpio;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic mmio_valid = 1'b0;
    logic mmio_wen = 1'b0;
    logic [7:0] mmio_addr = 8'b0;
    logic [31:0] mmio_wdata = 32'b0;
    logic [3:0] mmio_wmask = 4'b0;
    wire [31:0] mmio_rdata;
    tri1 cam1_scl;
    tri1 cam1_sda;
    wire cam1_reset_n;
    wire cam1_capture_enable;
    logic sensor_sda_low = 1'b0;

    assign cam1_sda = sensor_sda_low ? 1'b0 : 1'bz;

    always #5 clk = ~clk;

    Hcamera_sccb_gpio dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .mmio_valid   (mmio_valid),
        .mmio_wen     (mmio_wen),
        .mmio_addr    (mmio_addr),
        .mmio_wdata   (mmio_wdata),
        .mmio_wmask   (mmio_wmask),
        .mmio_rdata   (mmio_rdata),
        .cam1_scl     (cam1_scl),
        .cam1_sda     (cam1_sda),
        .cam1_reset_n (cam1_reset_n),
        .cam1_capture_enable(cam1_capture_enable)
    );

    task automatic write_control(input logic [31:0] value,
                                 input logic [3:0] mask);
        begin
            @(negedge clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b1;
            mmio_addr = 8'h00;
            mmio_wdata = value;
            mmio_wmask = mask;
            @(negedge clk);
            mmio_valid = 1'b0;
            mmio_wen = 1'b0;
        end
    endtask

    task automatic read_status(output logic [31:0] value);
        begin
            @(negedge clk);
            mmio_valid = 1'b1;
            mmio_wen = 1'b0;
            mmio_addr = 8'h04;
            #1 value = mmio_rdata;
            @(negedge clk);
            mmio_valid = 1'b0;
        end
    endtask

    logic [31:0] status;
    initial begin
        repeat (3) @(posedge clk);
        if ((cam1_reset_n !== 1'b0) || (cam1_scl !== 1'b1) ||
            (cam1_sda !== 1'b1))
            $fatal(1, "复位默认状态错误");

        rst_n = 1'b1;
        write_control(32'h0000_0000, 4'b0001);
        if ((cam1_reset_n !== 1'b0) || (cam1_scl !== 1'b0) ||
            (cam1_sda !== 1'b0))
            $fatal(1, "开漏拉低控制错误");

        write_control(32'h0000_0007, 4'b0001);
        if ((cam1_reset_n !== 1'b1) || (cam1_scl !== 1'b1) ||
            (cam1_sda !== 1'b1))
            $fatal(1, "线路释放控制错误");

        // 无低字节写使能时不得改变控制寄存器。
        write_control(32'h0000_0000, 4'b0000);
        if ((cam1_reset_n !== 1'b1) || (cam1_scl !== 1'b1) ||
            (cam1_sda !== 1'b1))
            $fatal(1, "字节写使能处理错误");

        sensor_sda_low = 1'b1;
        repeat (3) @(posedge clk);
        read_status(status);
        if (status[2] !== 1'b0)
            $fatal(1, "未采到从机拉低的 SDA");

        sensor_sda_low = 1'b0;
        repeat (3) @(posedge clk);
        read_status(status);
        if ((status[4:0] !== 5'b1_1_1_1_1))
            $fatal(1, "STATUS 读回错误: %08x", status);

        write_control(32'h0000_000f, 4'b0001);
        read_status(status);
        if ((status[5] !== 1'b1) || (cam1_capture_enable !== 1'b1))
            $fatal(1, "DVP 采集使能控制错误: %08x", status);

        $display("CAM1_SCCB_GPIO_PASS");
        $finish;
    end
endmodule
