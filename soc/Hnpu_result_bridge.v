`timescale 1ns / 1ps

// Connects the DDR-domain Hnpu_service result handshake to the CPU-domain
// Hnpu_result_mmio FIFO.  Keeping this adapter separate makes the service
// usable with a direct DDR scoreboard and makes the CDC boundary explicit.
module Hnpu_result_bridge #(
    parameter integer FIFO_DEPTH = 8
) (
    input         ddr_clk,
    input         cpu_clk,
    input         rst_n,
    input         service_result_valid,
    output wire   service_result_ready,
    input [255:0] service_result_record,
    input         mmio_valid,
    input         mmio_wen,
    input [7:0]   mmio_addr,
    input [31:0]  mmio_wdata,
    input [3:0]   mmio_wstrb,
    output wire   mmio_ready,
    output wire [31:0] mmio_rdata,
    output wire   irq,
    output wire   producer_overflow,
    output wire [7:0] producer_error_code
);
    Hnpu_result_mmio #(.FIFO_DEPTH(FIFO_DEPTH), .RECORD_BITS(256)) u_result_fifo (
        .producer_clk(ddr_clk),
        .consumer_clk(cpu_clk),
        .rst_n(rst_n),
        .producer_valid(service_result_valid),
        .producer_ready(service_result_ready),
        .producer_record(service_result_record),
        .mmio_valid(mmio_valid),
        .mmio_wen(mmio_wen),
        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_wstrb(mmio_wstrb),
        .mmio_ready(mmio_ready),
        .mmio_rdata(mmio_rdata),
        .irq(irq),
        .producer_overflow(producer_overflow),
        .producer_error_code(producer_error_code)
    );
endmodule
