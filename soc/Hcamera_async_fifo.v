`timescale 1ns / 1ps

// 摄像头像素/帧事件跨时钟 FIFO。数据内容由上层编码，帧事件必须和像素
// 一样走 FIFO，不能把 PCLK 域的单拍脉冲直接送到系统时钟域。
// ADDR_WIDTH 至少为 2，深度为 2^ADDR_WIDTH。
module Hcamera_async_fifo #(
    parameter integer DATA_WIDTH = 18,
    parameter integer ADDR_WIDTH = 10
) (
    input                         rst_n,
    input                         wr_clk,
    input                         wr_en,
    input      [DATA_WIDTH-1:0]   wr_data,
    output reg                    full,
    output reg                    overflow,
    input                         rd_clk,
    input                         rd_en,
    output reg [DATA_WIDTH-1:0]   rd_data,
    output reg                    rd_valid,
    output reg                    empty,
    output reg                    underflow,
    output reg [ADDR_WIDTH:0]     wr_level,
    output reg [ADDR_WIDTH:0]     rd_level,
    output reg [ADDR_WIDTH:0]     wr_max_level
);
    localparam integer DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_bin;
    reg [ADDR_WIDTH:0] wr_gray;
    reg [ADDR_WIDTH:0] rd_bin;
    reg [ADDR_WIDTH:0] rd_gray;

    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rd_gray_meta;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rd_gray_sync;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wr_gray_meta;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wr_gray_sync;

    reg wr_rst_q1;
    reg wr_rst_q2;
    reg rd_rst_q1;
    reg rd_rst_q2;

    wire wr_rst_n = wr_rst_q2;
    wire rd_rst_n = rd_rst_q2;
    wire wr_fire = wr_rst_n && wr_en && !full;
    wire rd_fire = rd_rst_n && rd_en && !empty;

    wire [ADDR_WIDTH:0] wr_bin_next = wr_bin + {{ADDR_WIDTH{1'b0}}, wr_fire};
    wire [ADDR_WIDTH:0] rd_bin_next = rd_bin + {{ADDR_WIDTH{1'b0}}, rd_fire};
    wire [ADDR_WIDTH:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [ADDR_WIDTH:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;
    wire [ADDR_WIDTH:0] rd_bin_sync;
    wire [ADDR_WIDTH:0] wr_bin_sync;

    function automatic [ADDR_WIDTH:0] gray_to_binary(
        input [ADDR_WIDTH:0] gray_value
    );
        integer bit_index;
        begin
            gray_to_binary[ADDR_WIDTH] = gray_value[ADDR_WIDTH];
            for (bit_index = ADDR_WIDTH-1; bit_index >= 0; bit_index = bit_index-1)
                gray_to_binary[bit_index] =
                    gray_to_binary[bit_index+1] ^ gray_value[bit_index];
        end
    endfunction

    assign rd_bin_sync = gray_to_binary(rd_gray_sync);
    assign wr_bin_sync = gray_to_binary(wr_gray_sync);
    wire full_next = wr_gray_next ==
        {~rd_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], rd_gray_sync[ADDR_WIDTH-2:0]};
    wire empty_next = rd_gray_next == wr_gray_sync;

    // 统一异步复位断言，各时钟域独立两拍释放。
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_rst_q1 <= 1'b0;
            wr_rst_q2 <= 1'b0;
        end else begin
            wr_rst_q1 <= 1'b1;
            wr_rst_q2 <= wr_rst_q1;
        end
    end

    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_rst_q1 <= 1'b0;
            rd_rst_q2 <= 1'b0;
        end else begin
            rd_rst_q1 <= 1'b1;
            rd_rst_q2 <= rd_rst_q1;
        end
    end

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin       <= {(ADDR_WIDTH+1){1'b0}};
            wr_gray      <= {(ADDR_WIDTH+1){1'b0}};
            rd_gray_meta <= {(ADDR_WIDTH+1){1'b0}};
            rd_gray_sync <= {(ADDR_WIDTH+1){1'b0}};
            full         <= 1'b0;
            overflow     <= 1'b0;
            wr_level     <= {(ADDR_WIDTH+1){1'b0}};
            wr_max_level <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rd_gray_meta <= rd_gray;
            rd_gray_sync <= rd_gray_meta;
            wr_bin       <= wr_bin_next;
            wr_gray      <= wr_gray_next;
            full         <= full_next;
            wr_level     <= wr_bin_next - rd_bin_sync;
            if ((wr_bin_next - rd_bin_sync) > wr_max_level)
                wr_max_level <= wr_bin_next - rd_bin_sync;
            if (wr_fire)
                mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            if (wr_en && full)
                overflow <= 1'b1;
        end
    end

    // 读数据在成功读拍后有效；无读请求时 rd_valid 为 0。
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin       <= {(ADDR_WIDTH+1){1'b0}};
            rd_gray      <= {(ADDR_WIDTH+1){1'b0}};
            wr_gray_meta <= {(ADDR_WIDTH+1){1'b0}};
            wr_gray_sync <= {(ADDR_WIDTH+1){1'b0}};
            rd_data      <= {DATA_WIDTH{1'b0}};
            rd_valid     <= 1'b0;
            empty        <= 1'b1;
            underflow    <= 1'b0;
            rd_level     <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wr_gray_meta <= wr_gray;
            wr_gray_sync <= wr_gray_meta;
            rd_bin       <= rd_bin_next;
            rd_gray      <= rd_gray_next;
            empty        <= empty_next;
            rd_level     <= wr_bin_sync - rd_bin_next;
            rd_valid     <= rd_fire;
            if (rd_fire)
                rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
            if (rd_en && empty)
                underflow <= 1'b1;
        end
    end
endmodule
