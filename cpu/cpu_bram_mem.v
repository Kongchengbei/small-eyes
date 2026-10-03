`timescale 1ns / 1ps

// Split instruction/data memories with synchronous ports. IRAM uses port A
// for instruction fetch and port B for the LSU or boot programming port.
// DRAM uses its single synchronous port B for LSU/programming. Contents are
// deliberately not reset; the programming owner has B-port access while rst
// is asserted, and the CPU owns it after reset is released.
module cpu_bram_mem #(
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
    output reg [31:0] if_rsp_data,
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
    localparam integer IRAM_WORDS = IRAM_BYTES / 4;
    localparam integer DRAM_WORDS = DRAM_BYTES / 4;

    (* ram_style = "block" *) reg [31:0] iram [0:IRAM_WORDS-1];
    (* ram_style = "block" *) reg [31:0] dram [0:DRAM_WORDS-1];

    wire if_in_iram = (if_req_addr >= IRAM_BASE) &&
                      (if_req_addr < (IRAM_BASE + IRAM_BYTES));
    wire data_in_iram = (data_req_addr >= IRAM_BASE) &&
                        (data_req_addr < (IRAM_BASE + IRAM_BYTES));
    wire data_in_dram = (data_req_addr >= DRAM_BASE) &&
                        (data_req_addr < (DRAM_BASE + DRAM_BYTES));
    wire prog_in_iram = (prog_addr >= IRAM_BASE) &&
                        (prog_addr < (IRAM_BASE + IRAM_BYTES));
    wire prog_in_dram = (prog_addr >= DRAM_BASE) &&
                        (prog_addr < (DRAM_BASE + DRAM_BYTES));
    wire prog_in_range = prog_in_iram || prog_in_dram;

    assign if_req_ready = 1'b1;
    assign data_addr_local = data_in_iram || data_in_dram;
    assign data_req_ready = data_addr_local;

    reg prog_read_ack;
    reg [31:0] prog_read_addr_q;
    reg [31:0] iram_b_read_data;
    reg [31:0] dram_b_read_data;
    reg b_read_bank_iram;
    assign prog_ready = rst && prog_valid && prog_in_range &&
                        (prog_write || (prog_read_ack && prog_addr == prog_read_addr_q));
    assign data_rsp_data = b_read_bank_iram ? iram_b_read_data : dram_b_read_data;
    assign prog_rdata = b_read_bank_iram ? iram_b_read_data : dram_b_read_data;

    wire b_prog_valid = rst && prog_valid && prog_in_range;
    wire b_cpu_valid = !rst && data_req_valid && data_addr_local;
    wire b_req_valid = b_prog_valid || b_cpu_valid;
    wire [31:0] b_req_addr = b_prog_valid ? prog_addr : data_req_addr;
    wire b_req_write = b_prog_valid ? prog_write : data_req_write;
    wire [31:0] b_req_wdata = b_prog_valid ? prog_wdata : data_req_wdata;
    wire [3:0] b_req_wstrb = b_prog_valid ? prog_wstrb : data_req_wstrb;
    wire b_req_iram = b_prog_valid ? prog_in_iram : data_in_iram;

    always @(posedge clk) begin
        if (rst) begin
            if_rsp_valid <= 1'b0;
            data_rsp_valid <= 1'b0;
            prog_read_ack <= b_prog_valid && !prog_write;
        end else begin
            if_rsp_valid <= if_req_valid && if_in_iram;
            data_rsp_valid <= b_cpu_valid && !data_req_write;
            prog_read_ack <= b_prog_valid && !prog_write;
        end

        if (rst && b_prog_valid && !prog_write)
            prog_read_addr_q <= prog_addr;
        if (b_req_valid && !b_req_write)
            b_read_bank_iram <= b_req_iram;
    end

    // IRAM port A: synchronous instruction read; memory contents are not reset.
    always @(posedge clk) begin
        if (!rst && if_req_valid && if_in_iram)
            if_rsp_data <= iram[(if_req_addr - IRAM_BASE) >> 2];
    end

    // IRAM port B is shared between the boot programmer and LSU through the
    // b_req_* mux above. The registered read stays attached to the RAM port.
    integer iram_byte_lane;
    always @(posedge clk) begin
        if (b_req_valid && b_req_iram) begin
            if (b_req_write) begin
                for (iram_byte_lane = 0; iram_byte_lane < 4; iram_byte_lane = iram_byte_lane + 1)
                    if (b_req_wstrb[iram_byte_lane])
                        iram[(b_req_addr - IRAM_BASE) >> 2][8*iram_byte_lane +: 8] <= b_req_wdata[8*iram_byte_lane +: 8];
            end else begin
                iram_b_read_data <= iram[(b_req_addr - IRAM_BASE) >> 2];
            end
        end
    end

    // DRAM port B has the same mutually exclusive loader/LSU ownership.
    integer dram_byte_lane;
    always @(posedge clk) begin
        if (b_req_valid && !b_req_iram) begin
            if (b_req_write) begin
                for (dram_byte_lane = 0; dram_byte_lane < 4; dram_byte_lane = dram_byte_lane + 1)
                    if (b_req_wstrb[dram_byte_lane])
                        dram[(b_req_addr - DRAM_BASE) >> 2][8*dram_byte_lane +: 8] <= b_req_wdata[8*dram_byte_lane +: 8];
            end else begin
                dram_b_read_data <= dram[(b_req_addr - DRAM_BASE) >> 2];
            end
        end
    end
endmodule
