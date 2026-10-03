`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// Small FPIOA subset used by the SparrowRV demos:
// output mapping bytes 0x00-0x1f and NIO registers 0x20-0x2f.
module Hfpioa_simple #(
    parameter integer UART_TX_DEFAULT_FPIOA = `SOC_UART_TX_FPIOA,
    parameter [31:0] INPUT_ONLY_MASK = 32'b0
) (
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

    // 非法参数会在仿真启动时报错；索引同时限制在 0..31，避免越界访问。
    localparam integer UART_TX_DEFAULT_FPIOA_SAFE =
        ((UART_TX_DEFAULT_FPIOA >= 0) && (UART_TX_DEFAULT_FPIOA < 32)) ?
        UART_TX_DEFAULT_FPIOA : 0;

`ifndef SYNTHESIS
    initial begin
        if ((UART_TX_DEFAULT_FPIOA < 0) || (UART_TX_DEFAULT_FPIOA >= 32))
            $fatal(1, "UART_TX_DEFAULT_FPIOA must be in range 0..31");
    end
`endif

    wire write_map = mmio_valid && mmio_wen && (mmio_addr < `SOC_FPIOA_OUTPUT_MAP_BYTES);
    wire [4:0] map_index = mmio_addr[4:0];
    wire [4:0] map_word_base = {map_index[4:2], 2'b00};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nio_opt <= 32'b0;
            nio_md0 <= 32'b0;
            nio_md1 <= 32'b0;
            for (i = 0; i < 32; i = i + 1)
                fpioa_ot_reg[i] <= 5'b0;
            // 固定 LED 输出保持原有映射，软件仍可通过 FPIOA/MMIO 配置。
            fpioa_ot_reg[8]  <= 5'd31; // direct/NIO LED0
            fpioa_ot_reg[9]  <= 5'd31;
            fpioa_ot_reg[10] <= 5'd31;
            fpioa_ot_reg[11] <= 5'd31;
            // 复位时只把 UART0_TX 接到选定的候选脚；其他 UART 候选脚保持高阻。
            // 若参数选中 LED 脚，UART 映射优先且该脚不会再驱动 LED。
            fpioa_ot_reg[UART_TX_DEFAULT_FPIOA_SAFE] <= `SOC_UART_TX_FPIOA_FUNC;
        end else if (mmio_valid && mmio_wen) begin
            if (write_map) begin
                // AXI 地址按字对齐，WSTRB 才指出字内实际写入的映射字节。
                if (mmio_wmask[0]) fpioa_ot_reg[map_word_base]     <= mmio_wdata[4:0];
                if (mmio_wmask[1]) fpioa_ot_reg[map_word_base + 1] <= mmio_wdata[12:8];
                if (mmio_wmask[2]) fpioa_ot_reg[map_word_base + 2] <= mmio_wdata[20:16];
                if (mmio_wmask[3]) fpioa_ot_reg[map_word_base + 3] <= mmio_wdata[28:24];
            end else begin
                case (mmio_addr)
                    `SOC_FPIOA_NIO_OPT_OFFSET: if (mmio_wmask == 4'b1111) nio_opt <= mmio_wdata;
                    `SOC_FPIOA_NIO_MD0_OFFSET: if (mmio_wmask == 4'b1111) nio_md0 <= mmio_wdata;
                    `SOC_FPIOA_NIO_MD1_OFFSET: if (mmio_wmask == 4'b1111) nio_md1 <= mmio_wdata;
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
                `SOC_UART_TX_FPIOA_FUNC: begin
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
            assign fpioa[g] = INPUT_ONLY_MASK[g] ? 1'bz :
                              (fpioa_oe[g] ? fpioa_drive[g] : 1'bz);
        end
    endgenerate

    always @(*) begin
        mmio_rdata = 32'b0;
        if (mmio_valid && !mmio_wen) begin
            if (mmio_addr < `SOC_FPIOA_OUTPUT_MAP_BYTES) begin
                // 任一 byte 地址均读取其所在的四字节映射组，便于 lb/lw 对齐访问。
                mmio_rdata = {
                    3'b0, fpioa_ot_reg[map_word_base + 3],
                    3'b0, fpioa_ot_reg[map_word_base + 2],
                    3'b0, fpioa_ot_reg[map_word_base + 1],
                    3'b0, fpioa_ot_reg[map_word_base]
                };
            end else begin
                case (mmio_addr)
                    `SOC_FPIOA_NIO_DIN_OFFSET: mmio_rdata = nio_din;
                    `SOC_FPIOA_NIO_OPT_OFFSET: mmio_rdata = nio_opt;
                    `SOC_FPIOA_NIO_MD0_OFFSET: mmio_rdata = nio_md0;
                    `SOC_FPIOA_NIO_MD1_OFFSET: mmio_rdata = nio_md1;
                    default: mmio_rdata = 32'b0;
                endcase
            end
        end
    end
endmodule
