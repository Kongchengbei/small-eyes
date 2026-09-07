`timescale 1ns / 1ps

// Small FPIOA subset used by the SparrowRV demos:
// output mapping bytes 0x00-0x1f and NIO registers 0x20-0x2f.
module Hfpioa_simple (
    input        clk,
    input        rst_n,
    input        mmio_valid,
    input        mmio_wen,
    input [7:0]  mmio_addr,
    input [31:0] mmio_wdata,
    input [3:0]  mmio_wmask,
    output reg [31:0] mmio_rdata,
    input        uart0_tx,
    input [3:0]  direct_led,
    inout [31:0] fpioa
);
    reg [4:0] fpioa_ot_reg [0:31];
    reg [31:0] nio_opt;
    reg [31:0] nio_md0;
    reg [31:0] nio_md1;
    reg [31:0] fpioa_drive;
    reg [31:0] fpioa_oe;
    reg [31:0] nio_din;
    integer i;

    wire write_map = mmio_valid && mmio_wen && (mmio_addr < 8'h20);
    wire [5:0] map_index = mmio_addr[5:0];

    function [7:0] selected_byte;
        input [31:0] value;
        input [1:0] lane;
        begin
            case (lane)
                2'd0: selected_byte = value[7:0];
                2'd1: selected_byte = value[15:8];
                2'd2: selected_byte = value[23:16];
                default: selected_byte = value[31:24];
            endcase
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nio_opt <= 32'b0;
            nio_md0 <= 32'b0;
            nio_md1 <= 32'b0;
            for (i = 0; i < 32; i = i + 1)
                fpioa_ot_reg[i] <= 5'b0;
            // Fixed outputs make the simple LED/UART interface usable before
            // software configures FPIOA, while official software may remap it.
            fpioa_ot_reg[31]  <= 5'd7;  // UART0_TX -> fpioa[31] -> AB26
            fpioa_ot_reg[8]  <= 5'd31; // direct/NIO LED0
            fpioa_ot_reg[9]  <= 5'd31;
            fpioa_ot_reg[10] <= 5'd31;
            fpioa_ot_reg[11] <= 5'd31;
        end else if (mmio_valid && mmio_wen) begin
            if (write_map) begin
                fpioa_ot_reg[map_index] <= selected_byte(mmio_wdata, mmio_addr[1:0]);
            end else begin
                case (mmio_addr)
                    8'h24: if (mmio_wmask == 4'b1111) nio_opt <= mmio_wdata;
                    8'h28: if (mmio_wmask == 4'b1111) nio_md0 <= mmio_wdata;
                    8'h2c: if (mmio_wmask == 4'b1111) nio_md1 <= mmio_wdata;
                    default: ;
                endcase
            end
        end
    end

    always @(*) begin
        nio_din = fpioa;
        fpioa_drive = 32'b0;
        fpioa_oe = 32'b0;
        for (i = 0; i < 32; i = i + 1) begin
            case (fpioa_ot_reg[i])
                5'd0: begin
                    fpioa_drive[i] = nio_opt[i];
                    fpioa_oe[i] = nio_md1[i];
                end
                5'd7: begin
                    fpioa_drive[i] = uart0_tx;
                    fpioa_oe[i] = 1'b1;
                end
                5'd31: begin
                    if (i >= 8 && i <= 11) begin
                        // Software may switch these pins to NIO push-pull;
                        // otherwise the private LED MMIO register is used.
                        fpioa_drive[i] = nio_md1[i] ? nio_opt[i] : direct_led[i-8];
                    end
                    fpioa_oe[i] = (i >= 8 && i <= 11);
                end
                default: ;
            endcase
        end
    end

    genvar g;
    generate
        for (g = 0; g < 32; g = g + 1) begin: fpioa_io
            assign fpioa[g] = fpioa_oe[g] ? fpioa_drive[g] : 1'bz;
        end
    endgenerate

    always @(*) begin
        mmio_rdata = 32'b0;
        if (mmio_valid && !mmio_wen) begin
            if (mmio_addr < 8'h20)
                mmio_rdata = {27'b0, fpioa_ot_reg[mmio_addr[4:0]]} << (mmio_addr[1:0] * 8);
            else begin
                case (mmio_addr)
                    8'h20: mmio_rdata = nio_din;
                    8'h24: mmio_rdata = nio_opt;
                    8'h28: mmio_rdata = nio_md0;
                    8'h2c: mmio_rdata = nio_md1;
                    default: mmio_rdata = 32'b0;
                endcase
            end
        end
    end
endmodule
