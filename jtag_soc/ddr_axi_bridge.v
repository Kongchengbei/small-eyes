`timescale 1ns / 1ps

// CPU 32-bit data-port to DDR3-controller 256-bit standard AXI4 bridge.
// The two clocks are unrelated, so a toggle handshake permits exactly one
// outstanding transaction.  Payload registers remain stable until the other
// clock domain acknowledges the token.
module ddr_axi_bridge (
    input              cpu_clk,
    input              ddr_clk,
    input              rst_n,
    input              ddr_init_done,

    input              cpu_req_valid,
    output             cpu_req_ready,
    input              cpu_req_write,
    input      [31:0]  cpu_req_addr,
    input      [31:0]  cpu_req_wdata,
    input      [3:0]   cpu_req_wmask,
    output reg [31:0]  cpu_rsp_rdata,
    output reg         cpu_rsp_valid,
    output reg         cpu_rsp_is_read,

    output     [29:0]  axi_awaddr,
    output     [7:0]   axi_awid,
    output     [7:0]   axi_awlen,
    output     [2:0]   axi_awsize,
    output     [1:0]   axi_awburst,
    output             axi_awvalid,
    input              axi_awready,
    output     [255:0] axi_wdata,
    output     [31:0]  axi_wstrb,
    output             axi_wlast,
    output             axi_wvalid,
    input              axi_wready,
    input      [7:0]   axi_bid,
    input      [1:0]   axi_bresp,
    input              axi_bvalid,
    output             axi_bready,

    output     [29:0]  axi_araddr,
    output     [7:0]   axi_arid,
    output     [7:0]   axi_arlen,
    output     [2:0]   axi_arsize,
    output     [1:0]   axi_arburst,
    output             axi_arvalid,
    input              axi_arready,
    input      [255:0] axi_rdata,
    input      [7:0]   axi_rid,
    input      [1:0]   axi_rresp,
    input              axi_rlast,
    input              axi_rvalid,
    output             axi_rready
);

    // CPU clock domain -----------------------------------------------------
    reg [31:0] req_addr_cpu;
    reg [31:0] req_wdata_cpu;
    reg [3:0]  req_wmask_cpu;
    reg        req_write_cpu;
    reg        req_toggle_cpu;
    reg        req_busy_cpu;
    reg        init_done_cpu_meta;
    reg        init_done_cpu_sync;
    reg        ack_cpu_meta;
    reg        ack_cpu_sync;

    // Written only by ddr_clk.  The acknowledgement crosses two CPU clocks
    // before this stable response payload is sampled.
    reg [31:0] ddr_rsp_rdata;
    reg        ddr_rsp_is_read;
    reg        ack_toggle_ddr;

    assign cpu_req_ready = init_done_cpu_sync && !req_busy_cpu;

    always @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n) begin
            req_addr_cpu       <= 32'd0;
            req_wdata_cpu      <= 32'd0;
            req_wmask_cpu      <= 4'd0;
            req_write_cpu      <= 1'b0;
            req_toggle_cpu     <= 1'b0;
            req_busy_cpu       <= 1'b0;
            init_done_cpu_meta <= 1'b0;
            init_done_cpu_sync <= 1'b0;
            ack_cpu_meta       <= 1'b0;
            ack_cpu_sync       <= 1'b0;
            cpu_rsp_rdata      <= 32'd0;
            cpu_rsp_valid      <= 1'b0;
            cpu_rsp_is_read    <= 1'b0;
        end else begin
            init_done_cpu_meta <= ddr_init_done;
            init_done_cpu_sync <= init_done_cpu_meta;
            ack_cpu_meta       <= ack_toggle_ddr;
            ack_cpu_sync       <= ack_cpu_meta;
            cpu_rsp_valid      <= 1'b0;

            // A new request flips req_toggle_cpu.  DDR completes it by
            // copying that same token to ack_toggle_ddr, so equality (not
            // inequality) is the completion condition.
            if (req_busy_cpu && (ack_cpu_sync == req_toggle_cpu)) begin
                req_busy_cpu    <= 1'b0;
                cpu_rsp_rdata   <= ddr_rsp_rdata;
                cpu_rsp_is_read <= ddr_rsp_is_read;
                cpu_rsp_valid   <= 1'b1;
            end

            if (!req_busy_cpu && cpu_req_valid && cpu_req_ready) begin
                req_addr_cpu   <= cpu_req_addr;
                req_wdata_cpu  <= cpu_req_wdata;
                req_wmask_cpu  <= cpu_req_wmask;
                req_write_cpu  <= cpu_req_write;
                req_toggle_cpu <= ~req_toggle_cpu;
                req_busy_cpu   <= 1'b1;
            end
        end
    end

    // DDR clock domain -----------------------------------------------------
    reg req_ddr_meta;
    reg req_ddr_sync;
    reg req_seen_ddr;
    reg [31:0] txn_addr_ddr;
    reg [31:0] txn_wdata_ddr;
    reg [3:0]  txn_wmask_ddr;
    reg        aw_done_ddr;
    reg        w_done_ddr;

    localparam [2:0] ST_IDLE  = 3'd0;
    localparam [2:0] ST_WRITE = 3'd1;
    localparam [2:0] ST_BRESP = 3'd2;
    localparam [2:0] ST_AR    = 3'd3;
    localparam [2:0] ST_RDATA = 3'd4;
    reg [2:0] state_ddr;

    reg [255:0] write_data_expand;
    reg [31:0]  write_strobe_expand;
    always @(*) begin
        write_data_expand   = 256'd0;
        write_strobe_expand = 32'd0;
        case (txn_addr_ddr[4:2])
            3'd0: begin write_data_expand[31:0]    = txn_wdata_ddr; write_strobe_expand[3:0]   = txn_wmask_ddr; end
            3'd1: begin write_data_expand[63:32]   = txn_wdata_ddr; write_strobe_expand[7:4]   = txn_wmask_ddr; end
            3'd2: begin write_data_expand[95:64]   = txn_wdata_ddr; write_strobe_expand[11:8]  = txn_wmask_ddr; end
            3'd3: begin write_data_expand[127:96]  = txn_wdata_ddr; write_strobe_expand[15:12] = txn_wmask_ddr; end
            3'd4: begin write_data_expand[159:128] = txn_wdata_ddr; write_strobe_expand[19:16] = txn_wmask_ddr; end
            3'd5: begin write_data_expand[191:160] = txn_wdata_ddr; write_strobe_expand[23:20] = txn_wmask_ddr; end
            3'd6: begin write_data_expand[223:192] = txn_wdata_ddr; write_strobe_expand[27:24] = txn_wmask_ddr; end
            default: begin write_data_expand[255:224] = txn_wdata_ddr; write_strobe_expand[31:28] = txn_wmask_ddr; end
        endcase
    end

    function [31:0] read_word_select;
        input [255:0] data_in;
        input [2:0]   word_index;
        begin
            case (word_index)
                3'd0:    read_word_select = data_in[31:0];
                3'd1:    read_word_select = data_in[63:32];
                3'd2:    read_word_select = data_in[95:64];
                3'd3:    read_word_select = data_in[127:96];
                3'd4:    read_word_select = data_in[159:128];
                3'd5:    read_word_select = data_in[191:160];
                3'd6:    read_word_select = data_in[223:192];
                default: read_word_select = data_in[255:224];
            endcase
        end
    endfunction

    // Each AXI request transfers one 32-byte beat.  The CPU address has
    // already been decoded as DDR space; [29:0] is the DDR byte offset.
    assign axi_awaddr  = {txn_addr_ddr[29:5], 5'b0};
    assign axi_awid    = 8'd0;
    assign axi_awlen   = 8'd0;
    assign axi_awsize  = 3'd5;
    assign axi_awburst = 2'b01;
    assign axi_awvalid = (state_ddr == ST_WRITE) && !aw_done_ddr;
    assign axi_wdata   = write_data_expand;
    assign axi_wstrb   = write_strobe_expand;
    assign axi_wlast   = 1'b1;
    assign axi_wvalid  = (state_ddr == ST_WRITE) && !w_done_ddr;
    assign axi_bready  = (state_ddr == ST_BRESP);

    assign axi_araddr  = {txn_addr_ddr[29:5], 5'b0};
    assign axi_arid    = 8'd0;
    assign axi_arlen   = 8'd0;
    assign axi_arsize  = 3'd5;
    assign axi_arburst = 2'b01;
    assign axi_arvalid = (state_ddr == ST_AR);
    assign axi_rready  = (state_ddr == ST_RDATA);

    always @(posedge ddr_clk or negedge rst_n) begin
        if (!rst_n) begin
            req_ddr_meta    <= 1'b0;
            req_ddr_sync    <= 1'b0;
            req_seen_ddr    <= 1'b0;
            txn_addr_ddr    <= 32'd0;
            txn_wdata_ddr   <= 32'd0;
            txn_wmask_ddr   <= 4'd0;
            aw_done_ddr     <= 1'b0;
            w_done_ddr      <= 1'b0;
            state_ddr       <= ST_IDLE;
            ddr_rsp_rdata   <= 32'd0;
            ddr_rsp_is_read <= 1'b0;
            ack_toggle_ddr  <= 1'b0;
        end else begin
            req_ddr_meta <= req_toggle_cpu;
            req_ddr_sync <= req_ddr_meta;
            case (state_ddr)
                ST_IDLE: begin
                    if (ddr_init_done && (req_ddr_sync != req_seen_ddr)) begin
                        req_seen_ddr  <= req_ddr_sync;
                        txn_addr_ddr  <= req_addr_cpu;
                        txn_wdata_ddr <= req_wdata_cpu;
                        txn_wmask_ddr <= req_wmask_cpu;
                        aw_done_ddr   <= 1'b0;
                        w_done_ddr    <= 1'b0;
                        state_ddr     <= req_write_cpu ? ST_WRITE : ST_AR;
                    end
                end
                ST_WRITE: begin
                    if (axi_awvalid && axi_awready) aw_done_ddr <= 1'b1;
                    if (axi_wvalid  && axi_wready)  w_done_ddr  <= 1'b1;
                    if ((aw_done_ddr || (axi_awvalid && axi_awready)) &&
                        (w_done_ddr  || (axi_wvalid  && axi_wready)))
                        state_ddr <= ST_BRESP;
                end
                ST_BRESP: begin
                    if (axi_bvalid) begin
                        ddr_rsp_rdata   <= 32'd0;
                        ddr_rsp_is_read <= 1'b0;
                        ack_toggle_ddr  <= req_seen_ddr;
                        state_ddr       <= ST_IDLE;
                    end
                end
                ST_AR: begin
                    if (axi_arvalid && axi_arready)
                        state_ddr <= ST_RDATA;
                end
                ST_RDATA: begin
                    if (axi_rvalid) begin
                        ddr_rsp_rdata   <= read_word_select(axi_rdata, txn_addr_ddr[4:2]);
                        ddr_rsp_is_read <= 1'b1;
                        ack_toggle_ddr  <= req_seen_ddr;
                        state_ddr       <= ST_IDLE;
                    end
                end
                default: state_ddr <= ST_IDLE;
            endcase
        end
    end

endmodule
