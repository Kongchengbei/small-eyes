`timescale 1ns / 1ps

// Production BRAM memory adapter. The two vendor dual-port RAMs are directly
// initialized by their generated INIT parameter includes. Port A of imem is
// instruction fetch; port B of each RAM is shared by the CPU LSU and the
// optional reset-time programming interface.
module cpu_bram_ip_mem #(
    parameter [31:0] IRAM_BASE  = 32'h8000_0000,
    parameter [31:0] IRAM_BYTES = 32'h0000_8000,
    parameter [31:0] DRAM_BASE  = 32'h8000_8000,
    parameter [31:0] DRAM_BYTES = 32'h0000_4000
) (
    input             clk,
    input             rst,
    input             if_req_valid,
    input      [31:0] if_req_addr,
    output wire       if_req_ready,
    output reg        if_rsp_valid,
    output wire [31:0] if_rsp_data,
    input             data_req_valid,
    input             data_req_write,
    input      [31:0] data_req_addr,
    input      [31:0] data_req_wdata,
    input      [3:0]  data_req_wstrb,
    output wire       data_req_ready,
    output reg        data_rsp_valid,
    output wire [31:0] data_rsp_data,
    output wire       data_addr_local,
    input             prog_valid,
    input             prog_write,
    input      [31:0] prog_addr,
    input      [31:0] prog_wdata,
    input      [3:0]  prog_wstrb,
    output wire       prog_ready,
    output wire [31:0] prog_rdata
);
    wire if_in_iram = (if_req_addr >= IRAM_BASE) &&
                      (if_req_addr < IRAM_BASE + IRAM_BYTES);
    wire data_in_iram = (data_req_addr >= IRAM_BASE) &&
                        (data_req_addr < IRAM_BASE + IRAM_BYTES);
    wire data_in_dram = (data_req_addr >= DRAM_BASE) &&
                        (data_req_addr < DRAM_BASE + DRAM_BYTES);
    wire prog_in_iram = (prog_addr >= IRAM_BASE) &&
                        (prog_addr < IRAM_BASE + IRAM_BYTES);
    wire prog_in_dram = (prog_addr >= DRAM_BASE) &&
                        (prog_addr < DRAM_BASE + DRAM_BYTES);
    wire prog_in_range = prog_in_iram || prog_in_dram;

    wire [31:0] imem_a_rdata, imem_b_rdata, dmem_b_rdata;
    wire [12:0] imem_a_addr = (if_req_addr - IRAM_BASE) >> 2;
    wire [12:0] imem_b_addr = (b_addr - IRAM_BASE) >> 2;
    wire [11:0] dmem_b_addr = (b_addr - DRAM_BASE) >> 2;
    wire [31:0] b_addr = (rst && prog_valid) ? prog_addr : data_req_addr;
    wire b_iram = (rst && prog_valid) ? prog_in_iram : data_in_iram;
    wire b_write = (rst && prog_valid) ? prog_write : data_req_write;
    wire [31:0] b_wdata = (rst && prog_valid) ? prog_wdata : data_req_wdata;
    wire [3:0] b_wstrb = (rst && prog_valid) ? prog_wstrb : data_req_wstrb;
    wire b_enable = (rst && prog_valid && prog_in_range) ||
                    (!rst && data_req_valid && data_addr_local);
    wire imem_b_we = b_enable && b_iram && b_write;
    wire dmem_b_we = b_enable && !b_iram && b_write;
    reg b_read_bank_iram;
    reg prog_read_ack;
    reg [31:0] prog_read_addr_q;

    assign if_req_ready = 1'b1;
    assign data_addr_local = data_in_iram || data_in_dram;
    assign data_req_ready = data_addr_local;
    assign data_rsp_data = b_read_bank_iram ? imem_b_rdata : dmem_b_rdata;
    assign prog_rdata = b_read_bank_iram ? imem_b_rdata : dmem_b_rdata;
    assign prog_ready = rst && prog_valid && prog_in_range &&
                        (prog_write || (prog_read_ack && prog_addr == prog_read_addr_q));
    assign if_rsp_data = imem_a_rdata;

    // The generated vendor IPs have fixed 32 KiB/16 KiB capacities.
    // synthesis translate_off
    initial begin
        if (IRAM_BYTES != 32'h0000_8000 || DRAM_BYTES != 32'h0000_4000)
            $error("cpu_bram_ip_mem requires 32 KiB IRAM and 16 KiB DRAM");
    end
    // synthesis translate_on

    always @(posedge clk) begin
        if (rst) begin
            if_rsp_valid <= 1'b0;
            data_rsp_valid <= 1'b0;
            prog_read_ack <= prog_valid && prog_in_range && !prog_write;
        end else begin
            if_rsp_valid <= if_req_valid && if_in_iram;
            data_rsp_valid <= data_req_valid && !data_req_write && data_addr_local;
            prog_read_ack <= 1'b0;
        end
        if (rst && prog_valid && prog_in_range && !prog_write)
            prog_read_addr_q <= prog_addr;
        if (b_enable && !b_write)
            b_read_bank_iram <= b_iram;
    end

    imem u_imem (
        .a_addr(imem_a_addr),
        .a_wr_data(32'b0), .a_rd_data(imem_a_rdata),
        .a_wr_en(1'b0), .a_rst(1'b0), .a_wr_byte_en(4'b0), .a_clk(clk),
        .b_addr(imem_b_addr), .b_wr_data(b_wdata),
        .b_rd_data(imem_b_rdata), .b_wr_en(imem_b_we), .b_rst(1'b0),
        .b_wr_byte_en(b_wstrb), .b_clk(clk)
    );

    dmem u_dmem (
        .a_addr(12'b0), .a_wr_data(32'b0), .a_rd_data(),
        .a_wr_en(1'b0), .a_rst(1'b0), .a_wr_byte_en(4'b0), .a_clk(clk),
        .b_addr(dmem_b_addr), .b_wr_data(b_wdata),
        .b_rd_data(dmem_b_rdata), .b_wr_en(dmem_b_we), .b_rst(1'b0),
        .b_wr_byte_en(b_wstrb), .b_clk(clk)
    );
endmodule
