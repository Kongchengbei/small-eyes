`timescale 1ns / 1ps

// Serialized 32-bit AXI slave for the unified memory map.
// Normal memory is external DDR only. MMIO is deliberately uncached by the
// CPU caches and is presented to the peripheral bus one beat at a time.
// JTAG uses the same DDR request channel as the CPU and is admitted only while
// the AXI side is idle.
module axi_mem_backend #(
    parameter [31:0] MMIO_BASE  = 32'h4000_0000,
    parameter [31:0] MMIO_BYTES = 32'h0000_1000,
    parameter [31:0] DDR_BASE   = 32'h8000_0000,
    parameter [31:0] DDR_BYTES  = 32'h4000_0000
) (
    input  clk,
    input  rst_n,

    input  [3:0]  axi_awid,
    input  [31:0] axi_awaddr,
    input  [7:0]  axi_awlen,
    input  [2:0]  axi_awsize,
    input  [1:0]  axi_awburst,
    input         axi_awvalid,
    output        axi_awready,
    input  [31:0] axi_wdata,
    input  [3:0]  axi_wstrb,
    input         axi_wlast,
    input         axi_wvalid,
    output        axi_wready,
    output [3:0]  axi_bid,
    output [1:0]  axi_bresp,
    output        axi_bvalid,
    input         axi_bready,

    input  [3:0]  axi_arid,
    input  [31:0] axi_araddr,
    input  [7:0]  axi_arlen,
    input         [2:0] axi_arsize,
    input         [1:0] axi_arburst,
    input         axi_arvalid,
    output        axi_arready,
    output [3:0]  axi_rid,
    output [31:0] axi_rdata,
    output [1:0]  axi_rresp,
    output        axi_rlast,
    output        axi_rvalid,
    input         axi_rready,

    output wire        mmio_req_valid,
    output wire        mmio_req_wen,
    output wire [31:0] mmio_req_addr,
    output wire [31:0] mmio_req_wdata,
    output wire [3:0]  mmio_req_wstrb,
    input              mmio_req_ready,
    input       [31:0] mmio_req_rdata,

    output wire        ddr_req_valid,
    input              ddr_req_ready,
    output wire        ddr_req_write,
    output wire [31:0] ddr_req_addr,
    output wire [31:0] ddr_req_wdata,
    output wire [3:0]  ddr_req_wstrb,
    input              ddr_rsp_valid,
    output wire        ddr_rsp_ready,
    input              ddr_rsp_is_read,
    input       [31:0] ddr_rsp_rdata,

    input       [31:0] jtag_cmd_addr,
    input              jtag_cmd_read,
    input              jtag_cmd_valid,
    input       [31:0] jtag_cmd_wdata,
    input       [3:0]  jtag_cmd_wmask,
    input              jtag_rsp_ready,
    output             jtag_cmd_ready,
    output reg         jtag_rsp_valid,
    output             jtag_rsp_err,
    output reg  [31:0] jtag_rsp_rdata
);

localparam [2:0] REG_NONE = 3'd0;
localparam [2:0] REG_MMIO = 3'd1;
localparam [2:0] REG_DDR  = 3'd2;

localparam [3:0] S_IDLE       = 4'd0;
localparam [3:0] S_R_ISSUE    = 4'd1;
localparam [3:0] S_R_DDR      = 4'd2;
localparam [3:0] S_R_RESPONSE = 4'd3;
localparam [3:0] S_W_WAIT     = 4'd4;
localparam [3:0] S_W_DDR      = 4'd5;
localparam [3:0] S_W_RESPONSE = 4'd6;

localparam [2:0] J_IDLE       = 3'd0;
localparam [2:0] J_DDR_ISSUE = 3'd1;
localparam [2:0] J_DDR_WAIT  = 3'd2;
localparam [2:0] J_RESPONSE   = 3'd3;

reg [3:0] state;
reg [2:0] jtag_state;
reg [3:0]  ar_id_reg;
reg [31:0] ar_base_reg;
reg [7:0]  ar_len_reg;
reg [7:0]  read_beat;
reg [31:0] read_data_reg;
reg [3:0]  aw_id_reg;
reg [31:0] aw_base_reg;
reg [7:0]  aw_len_reg;
reg [7:0]  write_beat;
reg [31:0] jtag_addr_reg;
reg        jtag_read_reg;
reg [31:0] jtag_wdata_reg;
reg [3:0]  jtag_wmask_reg;
reg        jtag_rsp_err_reg;

function [2:0] region_of;
    input [31:0] addr;
    begin
        if ((addr >= MMIO_BASE) && (addr < MMIO_BASE + MMIO_BYTES))
            region_of = REG_MMIO;
        else if ((addr >= DDR_BASE) && (addr < DDR_BASE + DDR_BYTES))
            region_of = REG_DDR;
        else
            region_of = REG_NONE;
    end
endfunction

wire [31:0] read_addr   = ar_base_reg + ({24'b0, read_beat} << 2);
wire [31:0] write_addr  = aw_base_reg + ({24'b0, write_beat} << 2);
wire        read_last  = (read_beat == ar_len_reg);
wire        write_last = (write_beat == aw_len_reg);
wire [2:0]  read_region  = region_of(read_addr);
wire [2:0]  write_region = region_of(write_addr);
wire        jtag_cmd_fire = jtag_cmd_valid && jtag_cmd_ready;

// AXI has priority over JTAG whenever both request sources are active.
assign axi_awready = rst_n && (state == S_IDLE) && (jtag_state == J_IDLE) &&
                     !jtag_rsp_valid;
assign axi_arready = rst_n && (state == S_IDLE) && (jtag_state == J_IDLE) &&
                     !jtag_rsp_valid && !axi_awvalid;
assign jtag_cmd_ready = rst_n && (state == S_IDLE) &&
                        (jtag_state == J_IDLE) && !jtag_rsp_valid &&
                        !axi_awvalid && !axi_arvalid;

assign mmio_req_valid = ((state == S_R_ISSUE) && (read_region == REG_MMIO)) ||
                        ((state == S_W_WAIT) && (write_region == REG_MMIO) &&
                         axi_wvalid);
assign mmio_req_wen   = (state == S_W_WAIT) &&
                       (write_region == REG_MMIO) && axi_wvalid;
assign mmio_req_addr  = (state == S_W_WAIT) ? write_addr : read_addr;
assign mmio_req_wdata = axi_wdata;
assign mmio_req_wstrb = axi_wstrb;

assign ddr_req_valid = rst_n &&
                       (((state == S_R_ISSUE) && (read_region == REG_DDR)) ||
                       ((state == S_W_WAIT) && (write_region == REG_DDR) &&
                        axi_wvalid) ||
                       (jtag_state == J_DDR_ISSUE));
assign ddr_req_write = ((state == S_W_WAIT) && (write_region == REG_DDR) &&
                        axi_wvalid) ||
                       ((jtag_state == J_DDR_ISSUE) && !jtag_read_reg);
assign ddr_req_addr  = (jtag_state == J_DDR_ISSUE) ? jtag_addr_reg :
                       (state == S_W_WAIT) ? write_addr : read_addr;
assign ddr_req_wdata = (jtag_state == J_DDR_ISSUE) ? jtag_wdata_reg :
                       axi_wdata;
assign ddr_req_wstrb = (jtag_state == J_DDR_ISSUE) ? jtag_wmask_reg :
                       axi_wstrb;

// Keep the response valid in the bridge until this consumer handshake.
assign ddr_rsp_ready = (state == S_R_DDR) || (state == S_W_DDR) ||
                       (jtag_state == J_DDR_WAIT);

assign axi_rid    = ar_id_reg;
assign axi_rdata  = read_data_reg;
assign axi_rresp  = 2'b00;
assign axi_rlast  = (state == S_R_RESPONSE) && read_last;
assign axi_rvalid = rst_n && (state == S_R_RESPONSE);
assign axi_wready = rst_n && (state == S_W_WAIT) &&
                    ((write_region == REG_DDR) ? ddr_req_ready :
                     (write_region == REG_MMIO) ? mmio_req_ready : 1'b1);
assign axi_bid    = aw_id_reg;
assign axi_bresp  = 2'b00;
assign axi_bvalid = rst_n && (state == S_W_RESPONSE);
assign jtag_rsp_err = jtag_rsp_valid && jtag_rsp_err_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state            <= S_IDLE;
        jtag_state       <= J_IDLE;
        ar_id_reg        <= 4'b0;
        ar_base_reg      <= 32'b0;
        ar_len_reg       <= 8'b0;
        read_beat        <= 8'b0;
        read_data_reg    <= 32'b0;
        aw_id_reg        <= 4'b0;
        aw_base_reg      <= 32'b0;
        aw_len_reg       <= 8'b0;
        write_beat       <= 8'b0;
        jtag_addr_reg    <= 32'b0;
        jtag_read_reg    <= 1'b0;
        jtag_wdata_reg   <= 32'b0;
        jtag_wmask_reg   <= 4'b0;
        jtag_rsp_err_reg <= 1'b0;
        jtag_rsp_valid   <= 1'b0;
        jtag_rsp_rdata   <= 32'b0;
    end
    else begin
        case (state)
            S_IDLE: begin
                if (axi_awvalid && axi_awready) begin
                    aw_id_reg   <= axi_awid;
                    aw_base_reg <= axi_awaddr;
                    aw_len_reg  <= axi_awlen;
                    write_beat  <= 8'b0;
                    state       <= S_W_WAIT;
                end
                else if (axi_arvalid && axi_arready) begin
                    ar_id_reg   <= axi_arid;
                    ar_base_reg <= axi_araddr;
                    ar_len_reg  <= axi_arlen;
                    read_beat   <= 8'b0;
                    state       <= S_R_ISSUE;
                end
            end

            S_R_ISSUE: begin
                if (read_region == REG_DDR) begin
                    if (ddr_req_ready)
                        state <= S_R_DDR;
                end
                else if (read_region == REG_MMIO) begin
                    if (mmio_req_ready) begin
                        read_data_reg <= mmio_req_rdata;
                        state <= S_R_RESPONSE;
                    end
                end
                else begin
                    read_data_reg <= 32'b0;
                    state <= S_R_RESPONSE;
                end
            end

            S_R_DDR: begin
                if (ddr_rsp_valid && ddr_rsp_ready) begin
                    read_data_reg <= ddr_rsp_rdata;
                    state <= S_R_RESPONSE;
                end
            end

            S_R_RESPONSE: begin
                if (axi_rvalid && axi_rready) begin
                    if (read_last)
                        state <= S_IDLE;
                    else begin
                        read_beat <= read_beat + 8'd1;
                        state <= S_R_ISSUE;
                    end
                end
            end

            S_W_WAIT: begin
                if (axi_wvalid && axi_wready) begin
                    if (write_region == REG_DDR)
                        state <= S_W_DDR;
                    else if (write_last) begin
                        state <= S_W_RESPONSE;
                    end
                    else begin
                        write_beat <= write_beat + 8'd1;
                    end
                end
            end

            S_W_DDR: begin
                if (ddr_rsp_valid && ddr_rsp_ready) begin
                    if (write_last)
                        state <= S_W_RESPONSE;
                    else begin
                        write_beat <= write_beat + 8'd1;
                        state <= S_W_WAIT;
                    end
                end
            end

            S_W_RESPONSE: begin
                if (axi_bvalid && axi_bready)
                    state <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase

        // JTAG shares the DDR local port but has a holding response register,
        // so a slow DMI consumer cannot lose a completed access.
        if (jtag_cmd_fire) begin
            jtag_addr_reg  <= jtag_cmd_addr;
            jtag_read_reg  <= jtag_cmd_read;
            jtag_wdata_reg <= jtag_cmd_wdata;
            jtag_wmask_reg <= jtag_cmd_wmask;
            if (region_of(jtag_cmd_addr) == REG_DDR) begin
                jtag_state <= J_DDR_ISSUE;
            end
            else begin
                jtag_rsp_valid   <= 1'b1;
                jtag_rsp_err_reg <= 1'b1;
                jtag_rsp_rdata   <= 32'b0;
                jtag_state       <= J_RESPONSE;
            end
        end
        else begin
            case (jtag_state)
                J_DDR_ISSUE: begin
                    if (ddr_req_ready)
                        jtag_state <= J_DDR_WAIT;
                end
                J_DDR_WAIT: begin
                    if (ddr_rsp_valid && ddr_rsp_ready) begin
                        jtag_rsp_valid   <= 1'b1;
                        jtag_rsp_err_reg <= 1'b0;
                        jtag_rsp_rdata   <= jtag_read_reg ? ddr_rsp_rdata : 32'b0;
                        jtag_state       <= J_RESPONSE;
                    end
                end
                J_RESPONSE: begin
                    if (jtag_rsp_valid && jtag_rsp_ready) begin
                        jtag_rsp_valid   <= 1'b0;
                        jtag_rsp_err_reg <= 1'b0;
                        jtag_state       <= J_IDLE;
                    end
                end
                default: begin
                    if (!jtag_rsp_valid)
                        jtag_state <= J_IDLE;
                end
            endcase
        end
    end
end

endmodule
