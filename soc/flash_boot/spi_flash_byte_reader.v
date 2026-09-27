`timescale 1ns / 1ps
//负责与flash通信，读取flash中的数据，写入ddr中
//单字节SPI模式0读取器，用于单个W25Q128JV在X1模式下
//每个被接受的请求启动一个自由的03h+24位地址事务
module spi_flash_byte_reader #(
    parameter integer CLK_DIV = 4
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        req_valid,
    output wire        req_ready,
    input  wire [23:0] req_addr,
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
    localparam [1:0] ST_RESP = 2'd2;

    reg [1:0] state;
    reg [31:0] tx_shift;
    reg [7:0] rx_shift;
    reg [5:0] rising_edges;
    reg [31:0] div_count;

    assign req_ready = (state == ST_IDLE) && !rsp_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            tx_shift     <= 32'd0;
            rx_shift     <= 8'd0;
            rising_edges <= 6'd0;
            div_count    <= 32'd0;
            rsp_valid    <= 1'b0;
            rsp_data     <= 8'd0;
            spi_sck      <= 1'b0;
            spi_cs_n     <= 1'b1;
            spi_mosi     <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    spi_sck   <= 1'b0;
                    spi_cs_n  <= 1'b1;
                    div_count <= 32'd0;
                    if (rsp_valid && rsp_ready)
                        rsp_valid <= 1'b0;
                    if (req_valid && req_ready) begin
                        tx_shift     <= {8'h03, req_addr};
                        rx_shift     <= 8'd0;
                        rising_edges <= 6'd0;
                        div_count    <= 32'd0;
                        spi_sck      <= 1'b0;
                        spi_cs_n     <= 1'b0;
                        spi_mosi     <= 1'b0; // 03h, MSB first
                        state        <= ST_SHIFT;
                    end
                end

                ST_SHIFT: begin
                    if (div_count == CLK_DIV-1) begin
                        div_count <= 32'd0;
                        if (!spi_sck) begin
                            // Mode 0: the Flash samples MOSI and presents
                            // the next MISO bit around this rising edge.
                            spi_sck <= 1'b1;
                            if (rising_edges >= 6'd32)
                                rx_shift <= {rx_shift[6:0], spi_miso};
                            rising_edges <= rising_edges + 1'b1;
                        end else begin
                            // MOSI changes only on falling SCK edges.
                            spi_sck <= 1'b0;
                            if (rising_edges < 6'd32) begin
                                spi_mosi <= tx_shift[30];
                                tx_shift <= {tx_shift[30:0], 1'b0};
                            end else begin
                                spi_mosi <= 1'b0;
                            end

                            // Hold the final sampled byte while SCK is
                            // returned low and CS is released.
                            if (rising_edges == 6'd40) begin
                                spi_cs_n  <= 1'b1;
                                rsp_data  <= rx_shift;
                                rsp_valid <= 1'b1;
                                state     <= ST_RESP;
                            end
                        end
                    end else begin
                        div_count <= div_count + 1'b1;
                    end
                end

                ST_RESP: begin
                    spi_sck  <= 1'b0;
                    spi_cs_n <= 1'b1;
                    if (rsp_valid && rsp_ready) begin
                        rsp_valid <= 1'b0;
                        state <= ST_IDLE;
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
