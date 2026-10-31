`timescale 1ns / 1ps

// ===========================================================================
// cache_sram  --  PRODUCTION version (Pango)
//
// Implements the cache data/tag arrays with the *generated* single-port BRAM
// macros that must be added to the Pango project:
//     DataRAM : 256 x 32 bit, byte write enable   (IP/DataRAM/DataRAM.v)
//     TagvRAM : 256 x 21 bit, single write enable (IP/TagvRAM/TagvRAM.v)
//
// icache.v / dcache.v only instantiate the two modules below, so the caches
// do not change between simulation and implementation.
//
// Mapping notes:
//   * both macros have a synchronous, registered read (1-cycle latency), which
//     is what the cache state machines assume;
//   * the macros have no clock enable (they read every clock), so the cache's
//     `ena` input is accepted but unused;
//   * `rst` only clears the RAM output register (never the contents), tie low;
//   * on power-up Pango BRAM content defaults to 0, so the tagv `valid` bit
//     starts cleared as the cache requires.
//
// For pure-Verilator simulation without the Pango IP, compile the behavioural
// twin `cpu/cache_sram_beh.v` instead of this file.
// ===========================================================================

// One 32-bit word bank: 256 entries, byte-enable write, synchronous read.
module data_bank_sram (
    input  [7:0]  addra,
    input         clka,
    input  [31:0] dina,
    output [31:0] douta,
    input         ena,
    input  [3:0]  wea
);
    DataRAM u_ram (
        .addr        (addra),
        .wr_data     (dina),
        .rd_data     (douta),
        .wr_en       (|wea),
        .clk         (clka),
        .wr_byte_en  (wea),
        .rst         (1'b0)
    );
endmodule

// Tag + valid array of one way: 256 entries x [20:0] = {tag[20:1], valid}.
module tagv_sram (
    input  [7:0]  addra,
    input         clka,
    input  [20:0] dina,
    output [20:0] douta,
    input         ena,
    input         wea
);
    TagvRAM u_ram (
        .addr        (addra),
        .wr_data     (dina),
        .rd_data     (douta),
        .wr_en       (wea),
        .clk         (clka),
        .rst         (1'b0)
    );
endmodule
