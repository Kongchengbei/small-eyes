`timescale 1ns / 1ps

// Retire-trace harness: board-accurate memory timing, dumps every retired
// instruction so it can be diffed against an ISA-simulator golden trace.
module tb_trace;
    reg clk = 1'b0;
    reg hard_rst_n = 1'b0;
    always #18.5 clk = ~clk;

    wire [31:0] fpioa;
    wire        core_active;
    wire        JTAG_TDO;
    reg JTAG_TCK = 1'b0, JTAG_TMS = 1'b1, JTAG_TDI = 1'b0;

    Hfpga_soc dut (
        .clk(clk), .hard_rst_n(hard_rst_n),
        .JTAG_TCK(JTAG_TCK), .JTAG_TMS(JTAG_TMS), .JTAG_TDI(JTAG_TDI),
        .JTAG_TDO(JTAG_TDO), .core_active(core_active), .fpioa(fpioa)
    );

    integer fh;
    integer retired = 0;
    integer cycles  = 0;

    // WB stage is the retire point.  Register writes are issued from WB too, so
    // wb_rd_addr / wb_data are exactly the architectural update of wb_pc.
    wire        wb_valid   = dut.u_cpu.u_wbu.wb_valid;
    wire [31:0] wb_pc      = dut.u_cpu.wb_pc;
    wire [31:0] wb_ins     = dut.u_cpu.wb_ins;
    wire        wb_reg_wen = dut.u_cpu.wb_reg_wen;
    wire [4:0]  wb_rd      = dut.u_cpu.wb_rd_addr;
    wire [31:0] wb_data    = dut.u_cpu.wb_data;

    initial begin
        fh = $fopen("/tmp/rtl_trace.txt", "w");
        repeat (40) @(posedge clk);
        hard_rst_n = 1'b1;
    end

    always @(posedge clk) begin
        if (hard_rst_n) begin
            cycles = cycles + 1;
            if (wb_valid) begin
                retired = retired + 1;
                if (retired <= `TRACE_LIMIT) begin
                    if (wb_reg_wen && (wb_rd != 5'd0))
                        $fwrite(fh, "%08x %08x x%0d=%08x\n", wb_pc, wb_ins, wb_rd, wb_data);
                    else
                        $fwrite(fh, "%08x %08x\n", wb_pc, wb_ins);
                end else begin
                    $fclose(fh);
                    $display("trace done: %0d instructions, %0d cycles", retired, cycles);
                    $finish;
                end
            end
        end
    end

    initial begin
        #`SIM_TIME_NS;
        $fclose(fh);
        $display("trace timeout: %0d instructions, %0d cycles", retired, cycles);
        $finish;
    end
endmodule
