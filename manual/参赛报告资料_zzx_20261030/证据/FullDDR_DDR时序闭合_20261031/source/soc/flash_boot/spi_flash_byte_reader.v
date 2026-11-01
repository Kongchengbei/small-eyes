`timescale 1ns / 1ps
//负责与Flash通信，提供串行字节流供启动搬运器使用
//单颗SPI NOR的模式0 X1连续03h读取器
//每个被接受的请求启动一次03h+24位地址事务，并在CS保持期间输出数据流
module spi_flash_byte_reader #(
    parameter integer CLK_DIV = 4
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_valid,
    output wire        req_ready,
    input  wire [23:0] req_addr,
    input  wire [31:0] req_length,
    input  wire        abort,
    output reg         rsp_valid,
    input  wire        rsp_ready,
    output reg  [7:0]  rsp_data,
    output reg         spi_sck,
    output reg         spi_cs_n,
    output reg         spi_mosi,
    input  wire        spi_miso
);
    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_SHIFT = 2'd1;
    localparam [1:0] ST_WAIT_RSP = 2'd2;

    reg [1:0] state;
    reg [31:0] tx_shift;
    reg [7:0] rx_shift;
    reg [5:0] rising_edges;
    reg [31:0] bytes_left;
    reg [31:0] div_count;
    reg abort_pending;

    wire [32:0] req_end_exclusive = {9'd0, req_addr} + {1'b0, req_length};
    assign req_ready = (state == ST_IDLE) && !rsp_valid && !abort && !abort_pending &&
                       (req_length != 0) &&
                       (req_end_exclusive <= 33'h1_000000);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            tx_shift      <= 32'd0;
            rx_shift      <= 8'd0;
            rising_edges  <= 6'd0;
            bytes_left    <= 32'd0;
            div_count     <= 32'd0;
            abort_pending <= 1'b0;
            rsp_valid     <= 1'b0;
            rsp_data      <= 8'd0;
            spi_sck       <= 1'b0;
            spi_cs_n      <= 1'b1;
            spi_mosi      <= 1'b0;
        end else if ((abort || abort_pending) && !spi_cs_n) begin
            // If a bit is already high, finish only its falling edge. Never
            // start another bit after abort has been observed.
            if (!spi_sck) begin
                state         <= ST_IDLE;
                spi_cs_n      <= 1'b1;
                spi_sck       <= 1'b0;
                spi_mosi      <= 1'b0;
                div_count     <= 32'd0;
                rsp_valid     <= 1'b0;
                abort_pending <= 1'b0;
            end else if (div_count == CLK_DIV-1) begin
                state         <= ST_IDLE;
                spi_cs_n      <= 1'b1;
                spi_sck       <= 1'b0;
                spi_mosi      <= 1'b0;
                div_count     <= 32'd0;
                rsp_valid     <= 1'b0;
                abort_pending <= 1'b0;
            end else begin
                div_count     <= div_count + 1'b1;
                abort_pending <= 1'b1;
            end
        end else begin
            case (state)
                ST_IDLE: begin
                    spi_sck   <= 1'b0;
                    spi_cs_n  <= 1'b1;
                    div_count <= 32'd0;
                    if (rsp_valid && rsp_ready)
                        rsp_valid <= 1'b0;
                    if (req_valid && req_ready) begin
                        tx_shift      <= {8'h03, req_addr};
                        rx_shift      <= 8'd0;
                        rising_edges  <= 6'd0;
                        bytes_left    <= req_length;
                        div_count     <= 32'd0;
                        spi_sck       <= 1'b0;
                        spi_cs_n      <= 1'b0;
                        spi_mosi      <= 1'b0;
                        state         <= ST_SHIFT;
                    end
                end

                ST_SHIFT: begin
                    if (div_count == CLK_DIV-1) begin
                        div_count <= 32'd0;
                        if (!spi_sck) begin
                            spi_sck <= 1'b1;
                            if (rising_edges >= 6'd32)
                                rx_shift <= {rx_shift[6:0], spi_miso};
                            rising_edges <= rising_edges + 1'b1;
                        end else begin
                            spi_sck <= 1'b0;
                            if (rising_edges < 6'd32) begin
                                spi_mosi <= tx_shift[30];
                                tx_shift <= {tx_shift[30:0], 1'b0};
                            end else begin
                                spi_mosi <= 1'b0;
                                if (rising_edges == 6'd40) begin
                                    rsp_data  <= rx_shift;
                                    rsp_valid <= 1'b1;
                                    state     <= ST_WAIT_RSP;
                                end
                            end
                        end
                    end else begin
                        div_count <= div_count + 1'b1;
                    end
                end

                ST_WAIT_RSP: begin
                    spi_sck <= 1'b0;
                    if (rsp_valid && rsp_ready) begin
                        rsp_valid  <= 1'b0;
                        bytes_left <= bytes_left - 1'b1;
                        if (bytes_left == 1) begin
                            spi_cs_n <= 1'b1;
                            spi_mosi <= 1'b0;
                            state    <= ST_IDLE;
                        end else begin
                            rx_shift     <= 8'd0;
                            rising_edges <= 6'd32;
                            div_count    <= 32'd0;
                            state        <= ST_SHIFT;
                        end
                    end
                end

                default: begin
                    state     <= ST_IDLE;
                    spi_sck   <= 1'b0;
                    spi_cs_n  <= 1'b1;
                    spi_mosi  <= 1'b0;
                    rsp_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule
