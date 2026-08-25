`timescale 1ns / 1ps
module Hmemu_fpga (
    input         valid,
    input         wen,
    input  [2:0]  funct3,
    input  [31:0] addr,
    input  [31:0] store_data,

    output        dmem_valid,
    output        dmem_wen,
    output [31:0] dmem_addr,
    output reg [31:0] dmem_wdata,
    output reg [3:0]  dmem_wmask,

    input  [31:0] dmem_rdata,
    output reg [31:0] load_data
);

    wire [1:0] offset = addr[1:0];
    wire [31:0] shifted_rdata = dmem_rdata >> (offset * 8);

    assign dmem_valid = valid;
    assign dmem_wen   = valid && wen;
    assign dmem_addr  = addr;

    always @(*) begin
        dmem_wmask = 4'b0000;
        dmem_wdata = 32'b0;

        if (valid && wen) begin
            case (funct3)
                3'b000: begin //SB
                    dmem_wmask = 4'b0001 << offset;
                    dmem_wdata = (store_data & 32'hff) << (offset * 8);
                end
                3'b001: begin //SH
                    dmem_wmask = 4'b0011 << offset;
                    dmem_wdata = (store_data & 32'hffff) << (offset * 8);
                end
                3'b010: begin //SW
                    dmem_wmask = 4'b1111;
                    dmem_wdata = store_data;
                end
				default: begin
					dmem_wmask = 4'b0000;
					dmem_wdata = 32'b0;
				end
            endcase
        end
    end

    always @(*) begin
        load_data = 32'b0;

        if (valid && !wen) begin
            case (funct3)
                3'b000: load_data = {{24{shifted_rdata[7]}},  shifted_rdata[7:0]};   // LB
                3'b001: load_data = {{16{shifted_rdata[15]}}, shifted_rdata[15:0]};  // LH
                3'b010: load_data = dmem_rdata;                                        // LW
                3'b100: load_data = {24'b0, shifted_rdata[7:0]};                       // LBU
                3'b101: load_data = {16'b0, shifted_rdata[15:0]};                      // LHU
                default: load_data = 32'b0;
            endcase
        end
    end

endmodule