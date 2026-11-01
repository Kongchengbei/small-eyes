`timescale 1ns / 1ps

// Behavioral cache RAMs for simulation. The FPGA implementation uses the
// generated DataRAM and TagvRAM wrappers in cache_bram.v; these modules keep
// the same ports while avoiding a vendor-specific primitive in Verilator.

module data_bank_sram (
    input  [7:0]  addra,
    input         clka,
    input  [31:0] dina,
    output reg [31:0] douta,
    input         ena,
    input  [3:0]  wea
);
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        douta = 32'b0;
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    always @(posedge clka) begin
        // The generated RAM has a registered read output. Its wrapper does
        // not expose an enable, so ena is intentionally accepted but unused.
        douta <= mem[addra];
        if (wea[0])
            mem[addra][7:0] <= dina[7:0];
        if (wea[1])
            mem[addra][15:8] <= dina[15:8];
        if (wea[2])
            mem[addra][23:16] <= dina[23:16];
        if (wea[3])
            mem[addra][31:24] <= dina[31:24];
    end
endmodule

module tagv_sram (
    input  [7:0]  addra,
    input         clka,
    input  [20:0] dina,
    output reg [20:0] douta,
    input         ena,
    input         wea
);
    reg [20:0] mem [0:255];
    integer i;

    initial begin
        douta = 21'b0;
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 21'b0;
    end

    always @(posedge clka) begin
        douta <= mem[addra];
        if (wea)
            mem[addra] <= dina;
    end
endmodule
