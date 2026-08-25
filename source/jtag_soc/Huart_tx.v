`timescale 1ns / 1ps

// Minimal memory-mapped UART transmitter, 8-N-1.
// Register offsets: CTRL=00, STATUS=04, BAUD=08, TXDATA=0c.
module Huart_tx #(
    parameter CLK_HZ = 27_000_000,
    parameter BAUD   = 115_200
) (
    input        clk,
    input        rst_n,
    input        mmio_valid,
    input        mmio_wen,
    input [7:0]  mmio_addr,
    input [31:0] mmio_wdata,
    input [3:0]  mmio_wmask,
    output reg [31:0] mmio_rdata,
    output reg   tx_pin
);
    localparam [15:0] DEFAULT_DIV = (CLK_HZ / BAUD) - 1;
    reg [3:0]  uart_ctrl;
    reg [15:0] baud_div;
    reg [15:0] baud_count;
    reg [9:0]  shift_reg;
    reg [3:0]  bit_count;
    reg        busy;

    wire write_ctrl = mmio_valid && mmio_wen && (mmio_addr == 8'h00) && mmio_wmask[0];
    wire write_baud = mmio_valid && mmio_wen && (mmio_addr == 8'h08);
    wire write_data = mmio_valid && mmio_wen && (mmio_addr == 8'h0c) && mmio_wmask[0];
    wire tx_start = write_data && uart_ctrl[0] && !busy;

    always @(*) begin
        mmio_rdata = 32'b0;
        if (mmio_valid && !mmio_wen) begin
            case (mmio_addr)
                8'h00: mmio_rdata = {28'b0, uart_ctrl};
                8'h04: mmio_rdata = {31'b0, busy};
                8'h08: mmio_rdata = {16'b0, baud_div};
                default: mmio_rdata = 32'b0;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_ctrl  <= 4'b0001;
            baud_div   <= DEFAULT_DIV;
            baud_count <= 16'b0;
            shift_reg  <= 10'b1111111111;
            bit_count  <= 4'b0;
            busy       <= 1'b0;
            tx_pin     <= 1'b1;
        end else begin
            if (write_ctrl)
                uart_ctrl <= mmio_wdata[3:0];
            if (write_baud) begin
                if (mmio_wmask[0]) baud_div[7:0]  <= mmio_wdata[7:0];
                if (mmio_wmask[1]) baud_div[15:8] <= mmio_wdata[15:8];
            end

            if (tx_start) begin
                shift_reg  <= {1'b1, mmio_wdata[7:0], 1'b0};
                bit_count  <= 4'b0;
                baud_count <= 16'b0;
                busy       <= 1'b1;
                tx_pin     <= 1'b0;
            end else if (busy) begin
                if (baud_count >= baud_div) begin
                    baud_count <= 16'b0;
                    tx_pin     <= shift_reg[1];
                    shift_reg  <= {1'b1, shift_reg[9:1]};
                    if (bit_count == 4'd8)
                        busy <= 1'b0;
                    else
                        bit_count <= bit_count + 1'b1;
                end else begin
                    baud_count <= baud_count + 1'b1;
                end
            end
        end
    end
endmodule
