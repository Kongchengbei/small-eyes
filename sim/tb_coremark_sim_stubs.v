`timescale 1ns / 1ps

// Simulation-only replacements for the board-specific input buffer and
// generated dual-port BRAM IP. Do not add this file to the PDS project.
module GTP_INBUF #(
    parameter IOSTANDARD = "DEFAULT",
    parameter TERM_DDR = "ON"
) (
    output O,
    input  I
);
    assign O = I;
endmodule

// The DDR reference clock uses a differential Pango primitive on hardware.
// The full-SoC smoke test has only one clock source, so retain its positive
// leg.  This is deliberately a simulation-only model.
module GTP_INBUFGDS #(
    parameter IOSTANDARD = "DEFAULT",
    parameter TERM_DIFF = "ON"
) (
    output O,
    input  I,
    input  IB
);
    assign O = I;
endmodule

// Simulation-only PLL replacement. The board IP uses a vendor GTP primitive
// that is unavailable to Icarus; the smoke test only needs a stable clock and
// lock indication, so pass the testbench clock through unchanged.
module clk_pll (
    output wire clkout0,
    input  wire clkin1,
    output wire lock
);
    assign clkout0 = clkin1;
    assign lock    = 1'b1;
endmodule

// Simulation shell for the generated DDR3 controller.  It lets the CPU-side
// CoreMark smoke test elaborate after the DDR3 IP was added to the SoC; real
// DDR3 training and AXI storage behaviour are verified separately by
// ddr_axi_bridge_tb and on the FPGA.  Never add this module to the PDS project.
module ddr3_ctrl_v116 (
    input ref_clk, input resetn,
    output core_clk, output pll_lock, output phy_pll_lock, output gpll_lock,
    output rst_gpll_lock, output ddrphy_cpd_lock, output ddr_init_done,
    input [29:0] axi_awaddr, input [7:0] axi_awid, input [7:0] axi_awlen,
    input [2:0] axi_awsize, input [1:0] axi_awburst, output axi_awready,
    input axi_awvalid, input [255:0] axi_wdata, input [31:0] axi_wstrb,
    input axi_wlast, input axi_wvalid, output axi_wready, input axi_bready,
    output [7:0] axi_bid, output [1:0] axi_bresp, output axi_bvalid,
    input [29:0] axi_araddr, input [7:0] axi_arid, input [7:0] axi_arlen,
    input [2:0] axi_arsize, input [1:0] axi_arburst, input axi_arvalid,
    output axi_arready, input axi_rready, output [255:0] axi_rdata,
    output [7:0] axi_rid, output axi_rlast, output axi_rvalid,
    output [1:0] axi_rresp,
    input apb_clk, input apb_rst_n, input apb_sel, input apb_enable,
    input [7:0] apb_addr, input apb_write, output apb_ready,
    input [15:0] apb_wdata, output [15:0] apb_rdata,
    output mem_rst_n, output mem_ck, output mem_ck_n, output mem_cke,
    output mem_cs_n, output mem_ras_n, output mem_cas_n, output mem_we_n,
    output mem_odt, output [14:0] mem_a, output [2:0] mem_ba,
    inout [3:0] mem_dqs, inout [3:0] mem_dqs_n, inout [31:0] mem_dq,
    output [3:0] mem_dm,
    input dbg_gate_start, input dbg_cpd_start, input dbg_ddrphy_rst_n,
    input dbg_gpll_scan_rst, input samp_position_dyn_adj,
    input [31:0] init_samp_position_even, input wrcal_position_dyn_adj,
    input [31:0] init_wrcal_position, input force_read_clk_ctrl,
    input [15:0] init_slip_step, input [11:0] init_read_clk_ctrl,
    output [33:0] debug_calib_ctrl, output [95:0] dbg_slice_status,
    output [95:0] dbg_slice_state, output [299:0] debug_data,
    output [1:0] dbg_dll_upd_state, output [8:0] debug_gpll_dps_phase,
    output [2:0] dbg_rst_dps_state, output [5:0] dbg_tran_err_rst_cnt,
    output dbg_ddrphy_init_fail, input debug_cpd_offset_adj,
    input debug_cpd_offset_dir, input [9:0] debug_cpd_offset,
    output [9:0] debug_dps_cnt_dir0, output [9:0] debug_dps_cnt_dir1,
    input ck_dly_en, input [7:0] init_ck_dly_step,
    output [7:0] ck_dly_set_bin, output align_error,
    output [3:0] debug_rst_state, output [3:0] debug_cpd_state
);
    assign core_clk        = ref_clk;
    assign pll_lock        = resetn;
    assign phy_pll_lock    = resetn;
    assign gpll_lock       = resetn;
    assign rst_gpll_lock   = resetn;
    assign ddrphy_cpd_lock = resetn;
    assign ddr_init_done   = resetn;
    assign axi_awready = 1'b1;
    assign axi_wready  = 1'b1;
    assign axi_bid     = 8'd0;
    assign axi_bresp   = 2'b00;
    assign axi_bvalid  = 1'b0;
    assign axi_arready = 1'b1;
    assign axi_rdata   = 256'd0;
    assign axi_rid     = 8'd0;
    assign axi_rlast   = 1'b1;
    assign axi_rvalid  = 1'b0;
    assign axi_rresp   = 2'b00;
    assign apb_ready = 1'b1;
    assign apb_rdata = 16'd0;
    assign mem_rst_n = resetn;
    assign mem_ck = 1'b0;
    assign mem_ck_n = 1'b0;
    assign mem_cke = 1'b0;
    assign mem_cs_n = 1'b1;
    assign mem_ras_n = 1'b1;
    assign mem_cas_n = 1'b1;
    assign mem_we_n = 1'b1;
    assign mem_odt = 1'b0;
    assign mem_a = 15'd0;
    assign mem_ba = 3'd0;
    assign mem_dm = 4'd0;
    assign debug_calib_ctrl = 34'd0;
    assign dbg_slice_status = 96'd0;
    assign dbg_slice_state = 96'd0;
    assign debug_data = 300'd0;
    assign dbg_dll_upd_state = 2'd0;
    assign debug_gpll_dps_phase = 9'd0;
    assign dbg_rst_dps_state = 3'd0;
    assign dbg_tran_err_rst_cnt = 6'd0;
    assign dbg_ddrphy_init_fail = 1'b0;
    assign debug_dps_cnt_dir0 = 10'd0;
    assign debug_dps_cnt_dir1 = 10'd0;
    assign ck_dly_set_bin = 8'd0;
    assign align_error = 1'b0;
    assign debug_rst_state = 4'd0;
    assign debug_cpd_state = 4'd0;
endmodule

module imem (
    input  [12:0] a_addr,
    input  [31:0] a_wr_data,
    output reg [31:0] a_rd_data,
    input         a_wr_en,
    input         a_rst,
    input  [3:0]  a_wr_byte_en,
    input         a_clk,
    input  [12:0] b_addr,
    input  [31:0] b_wr_data,
    output reg [31:0] b_rd_data,
    input         b_wr_en,
    input         b_rst,
    input  [3:0]  b_wr_byte_en,
    input         b_clk
);
    reg [31:0] mem [0:8191];
    integer i;

    initial begin
        for (i = 0; i < 8192; i = i + 1)
            mem[i] = 32'b0;
        $readmemh("../source/soc/coremark.dat", mem);
    end

    always @(posedge a_clk) begin
        if (a_rst) begin
            a_rd_data <= 32'b0;
        end else begin
            if (a_wr_en) begin
                if (a_wr_byte_en[0]) mem[a_addr][7:0]   <= a_wr_data[7:0];
                if (a_wr_byte_en[1]) mem[a_addr][15:8]  <= a_wr_data[15:8];
                if (a_wr_byte_en[2]) mem[a_addr][23:16] <= a_wr_data[23:16];
                if (a_wr_byte_en[3]) mem[a_addr][31:24] <= a_wr_data[31:24];
            end else begin
                a_rd_data <= mem[a_addr];
            end
        end
    end

    always @(posedge b_clk) begin
        if (b_rst) begin
            b_rd_data <= 32'b0;
        end else begin
            if (b_wr_en) begin
                if (b_wr_byte_en[0]) mem[b_addr][7:0]   <= b_wr_data[7:0];
                if (b_wr_byte_en[1]) mem[b_addr][15:8]  <= b_wr_data[15:8];
                if (b_wr_byte_en[2]) mem[b_addr][23:16] <= b_wr_data[23:16];
                if (b_wr_byte_en[3]) mem[b_addr][31:24] <= b_wr_data[31:24];
            end else begin
                b_rd_data <= mem[b_addr];
            end
        end
    end
endmodule

module dmem (
    input  [11:0] a_addr,
    input  [31:0] a_wr_data,
    output reg [31:0] a_rd_data,
    input         a_wr_en,
    input         a_rst,
    input  [3:0]  a_wr_byte_en,
    input         a_clk,
    input  [11:0] b_addr,
    input  [31:0] b_wr_data,
    output reg [31:0] b_rd_data,
    input         b_wr_en,
    input         b_rst,
    input  [3:0]  b_wr_byte_en,
    input         b_clk
);
    reg [31:0] mem [0:4095];
    integer i;

    initial begin
        for (i = 0; i < 4096; i = i + 1)
            mem[i] = 32'b0;
    end

    always @(posedge a_clk) begin
        if (a_rst) begin
            a_rd_data <= 32'b0;
        end else begin
            if (a_wr_en) begin
                if (a_wr_byte_en[0]) mem[a_addr][7:0]   <= a_wr_data[7:0];
                if (a_wr_byte_en[1]) mem[a_addr][15:8]  <= a_wr_data[15:8];
                if (a_wr_byte_en[2]) mem[a_addr][23:16] <= a_wr_data[23:16];
                if (a_wr_byte_en[3]) mem[a_addr][31:24] <= a_wr_data[31:24];
            end else begin
                a_rd_data <= mem[a_addr];
            end
        end
    end

    always @(posedge b_clk) begin
        if (b_rst) begin
            b_rd_data <= 32'b0;
        end else begin
            if (b_wr_en) begin
                if (b_wr_byte_en[0]) mem[b_addr][7:0]   <= b_wr_data[7:0];
                if (b_wr_byte_en[1]) mem[b_addr][15:8]  <= b_wr_data[15:8];
                if (b_wr_byte_en[2]) mem[b_addr][23:16] <= b_wr_data[23:16];
                if (b_wr_byte_en[3]) mem[b_addr][31:24] <= b_wr_data[31:24];
            end else begin
                b_rd_data <= mem[b_addr];
            end
        end
    end
endmodule
