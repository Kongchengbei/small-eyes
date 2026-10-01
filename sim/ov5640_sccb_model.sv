`timescale 1ns / 1ps

// 仅用于离线仿真的 OV5640 SCCB 从机模型。
// 它检查标准 16 位寄存器读写事务，保存写入值，并固定提供芯片 ID。
module ov5640_sccb_model (
    input  reset_n,
    inout  scl,
    inout  sda
);
    logic sda_drive_low = 1'b0;
    logic [15:0] register_address;
    logic [7:0] received_byte;
    logic [7:0] written_byte;
    logic repeated_start;
    logic [7:0] register_file [0:65535];
    integer write_count;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    task automatic wait_for_start;
        logic found;
        begin
            found = 1'b0;
            while (!found) begin
                @(negedge sda);
                if ((scl === 1'b1) && (reset_n === 1'b1))
                    found = 1'b1;
            end
        end
    endtask

    task automatic receive_byte(output logic [7:0] value);
        integer index;
        begin
            value = 8'b0;
            for (index = 7; index >= 0; index = index - 1) begin
                @(posedge scl);
                value[index] = sda;
            end
        end
    endtask

    task automatic receive_remaining_bits(input logic first_bit,
                                          output logic [7:0] value);
        integer index;
        begin
            value = 8'b0;
            value[7] = first_bit;
            for (index = 6; index >= 0; index = index - 1) begin
                @(posedge scl);
                value[index] = sda;
            end
        end
    endtask

    task automatic send_ack(input logic acknowledge);
        begin
            @(negedge scl);
            sda_drive_low = acknowledge;
            @(negedge scl);
            sda_drive_low = 1'b0;
        end
    endtask

    task automatic send_byte(input logic [7:0] value);
        integer index;
        begin
            for (index = 7; index >= 0; index = index - 1) begin
                sda_drive_low = !value[index];
                @(posedge scl);
                @(negedge scl);
            end
            sda_drive_low = 1'b0;
            // 第九个时钟由主机发送 NACK，模型只观察、不拉低 SDA。
            @(posedge scl);
            @(negedge scl);
        end
    endtask

    /* verilator lint_off INFINITELOOP */
    initial begin
        sda_drive_low = 1'b0;
        register_address = 16'b0;
        write_count = 0;
        register_file[16'h300a] = 8'h56;
        register_file[16'h300b] = 8'h40;
        forever begin
            wait_for_start();
            receive_byte(received_byte);
            if (received_byte != 8'h78) begin
                send_ack(1'b0);
            end else begin
                send_ack(1'b1);
                receive_byte(received_byte);
                register_address[15:8] = received_byte;
                send_ack(1'b1);
                receive_byte(received_byte);
                register_address[7:0] = received_byte;
                send_ack(1'b1);

                // 地址阶段之后可能继续写数据，也可能发重复起始进入读事务。
                // 先观察下一次 SCL 上升沿；若 SDA 在 SCL 保持高时下降，就是
                // 重复起始，否则该上升沿已经是写数据的最高位。
                repeated_start = 1'b0;
                @(posedge scl);
                if (sda === 1'b0) begin
                    receive_remaining_bits(1'b0, written_byte);
                end else begin
                    @(negedge scl or negedge sda);
                    if ((scl === 1'b1) && (sda === 1'b0)) begin
                        repeated_start = 1'b1;
                    end else begin
                        receive_remaining_bits(1'b1, written_byte);
                    end
                end

                if (repeated_start) begin
                    receive_byte(received_byte);
                    if (received_byte != 8'h79) begin
                        send_ack(1'b0);
                    end else begin
                        send_ack(1'b1);
                        if ((register_address == 16'h3008) &&
                            (write_count != 252))
                            $fatal(1, "OV5640 配置写入数错误: %0d", write_count);
                        send_byte(register_file[register_address]);
                    end
                end else begin
                    register_file[register_address] = written_byte;
                    write_count = write_count + 1;
                    send_ack(1'b1);
                end
            end
        end
    end
    /* verilator lint_on INFINITELOOP */
endmodule
