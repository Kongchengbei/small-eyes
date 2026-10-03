`timescale 1ns / 1ps

module tb_memu_load_stall;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    reg wb_allowin = 1'b1;
    reg ex_to_mem_valid = 1'b0;
    reg [31:0] dmem_rdata = 32'b0;
    reg dmem_rsp_valid = 1'b0;
    wire [31:0] mem_pc, mem_ins, mem_wb_data;
    wire mem_allowin, mem_to_wb_valid, mem_forward_valid, mem_load_wait;
    wire dbg_mem_valid, dbg_mem_ready_go;
    wire [4:0] mem_rd_addr;
    wire mem_reg_wen, mem_is_ebreak;

    Hmemu dut (
        .clk(clk), .rst(rst), .ex_pc(32'h8000_0000), .ex_ins(32'h0000_2083),
        .wb_allowin(wb_allowin), .ex_to_mem_valid(ex_to_mem_valid),
        .ex_alu_result(32'h8000_1000), .ex_rd_addr(5'd1),
        .ex_mem_funct3(3'b010), .ex_reg_wen(1'b1), .ex_wb_sel(2'b01),
        .ex_is_ebreak(1'b0), .ex_wb_value(32'b0),
        .dmem_rdata(dmem_rdata), .dmem_rsp_valid(dmem_rsp_valid),
        .mem_pc(mem_pc), .mem_ins(mem_ins), .mem_allowin(mem_allowin),
        .mem_to_wb_valid(mem_to_wb_valid), .mem_wb_data(mem_wb_data),
        .mem_forward_valid(mem_forward_valid), .mem_load_wait(mem_load_wait),
        .dbg_mem_valid(dbg_mem_valid), .dbg_mem_ready_go(dbg_mem_ready_go),
        .mem_rd_addr(mem_rd_addr), .mem_reg_wen(mem_reg_wen), .mem_is_ebreak(mem_is_ebreak)
    );

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk) begin rst = 1'b0; ex_to_mem_valid = 1'b1; end
        @(posedge clk);
        @(negedge clk) begin ex_to_mem_valid = 1'b0; wb_allowin = 1'b0; end
        repeat (3) @(posedge clk);
        if (!mem_load_wait || mem_allowin)
            $fatal(1, "load did not wait for its response/backpressure");

        @(negedge clk) begin dmem_rdata = 32'hface_cafe; dmem_rsp_valid = 1'b1; end
        @(posedge clk);
        @(negedge clk) dmem_rsp_valid = 1'b0;
        repeat (3) @(posedge clk);
        #1;
        if (mem_load_wait || mem_wb_data !== 32'hface_cafe || !mem_forward_valid)
            $fatal(1, "load response was not retained while WB stalled");

        @(negedge clk) wb_allowin = 1'b1;
        #1;
        if (!mem_to_wb_valid || mem_wb_data !== 32'hface_cafe)
            $fatal(1, "retained load was not ready for WB");
        @(posedge clk);
        $display("PASS: MEM retains single-cycle load response across WB stall");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "timeout");
    end
endmodule
