`timescale 1ns/1ps

// Focused regression for the M-mode CSR/trap rules implemented in Hcsr.
module tb_Hcsr;
    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;

    reg        csr_valid = 1'b0;
    reg [2:0]  csr_op = 3'b000;
    reg [11:0] csr_addr = 12'b0;
    reg [31:0] csr_rs1_data = 32'b0;
    reg [4:0]  csr_imm = 5'b0;
    reg        is_ecall = 1'b0;
    reg        is_ebreak = 1'b0;
    reg        is_mret = 1'b0;
    reg        interrupt_boundary = 1'b0;
    reg        irq_external = 1'b0;
    reg [31:0] current_pc = 32'b0;
    wire [31:0] csr_rdata;
    wire redirect_valid;
    wire [31:0] redirect_pc;

    Hcsr dut (
        .clk(clk), .rst(rst),
        .csr_valid(csr_valid), .csr_op(csr_op), .csr_addr(csr_addr),
        .csr_rs1_data(csr_rs1_data), .csr_imm(csr_imm),
        .is_ecall(is_ecall), .is_ebreak(is_ebreak), .is_mret(is_mret),
        .interrupt_boundary(interrupt_boundary), .irq_external(irq_external),
        .current_pc(current_pc), .csr_rdata(csr_rdata),
        .redirect_valid(redirect_valid), .redirect_pc(redirect_pc)
    );

    task csr_write(input [11:0] addr, input [31:0] value);
        begin
            @(negedge clk);
            csr_valid = 1'b1;
            csr_op = 3'b001; // CSRRW
            csr_addr = addr;
            csr_rs1_data = value;
            @(posedge clk);
            #1;
            @(negedge clk);
            csr_valid = 1'b0;
            csr_op = 3'b000;
        end
    endtask

    task check_value(input [31:0] actual, input [31:0] wanted, input [8*40-1:0] name);
        begin
            if (actual !== wanted)
                $fatal(1, "%0s: got %08x, expected %08x", name, actual, wanted);
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 1'b0;
        @(negedge clk);

        check_value(dut.csr_mstatus, 32'h0000_1800, "mstatus reset");
        check_value(dut.csr_mie, 32'h0, "mie reset");
        check_value(csr_rdata, 32'h0, "default csr read");

        csr_write(12'h305, 32'h0000_1003);
        check_value(dut.csr_mtvec, 32'h0000_1000, "mtvec direct alignment");
        csr_write(12'h340, 32'hdead_beef);
        check_value(dut.csr_mscratch, 32'hdead_beef, "mscratch rw");

        // Enable MIE; ecall must stack it into MPIE and clear MIE.
        csr_write(12'h300, 32'h0000_0008);
        check_value(dut.csr_mstatus, 32'h0000_1808, "mstatus MIE write");
        @(negedge clk);
        current_pc = 32'h0000_2000;
        is_ecall = 1'b1;
        #1;
        if (!redirect_valid || redirect_pc !== 32'h0000_1000)
            $fatal(1, "ecall redirect incorrect");
        @(posedge clk);
        #1;
        is_ecall = 1'b0;
        check_value(dut.csr_mcause, 32'd11, "ecall cause");
        check_value(dut.csr_mepc, 32'h0000_2000, "ecall mepc");
        check_value(dut.csr_mstatus, 32'h0000_1880, "ecall mstatus stack");

        // MRET restores MIE from MPIE and forces MPIE=1 in M-only mode.
        @(negedge clk);
        is_mret = 1'b1;
        #1;
        if (!redirect_valid || redirect_pc !== 32'h0000_2000)
            $fatal(1, "mret redirect incorrect");
        @(posedge clk);
        #1;
        is_mret = 1'b0;
        check_value(dut.csr_mstatus, 32'h0000_1888, "mret mstatus restore");

        // Enable both sources; MEI has priority and must set bit 31 in mcause.
        csr_write(12'h304, 32'h0000_0880);
        @(negedge clk);
        current_pc = 32'h0000_3000;
        irq_external = 1'b1;
        interrupt_boundary = 1'b1;
        #1;
        if (!redirect_valid)
            $fatal(1, "external interrupt was not taken");
        @(posedge clk);
        #1;
        interrupt_boundary = 1'b0;
        irq_external = 1'b0;
        check_value(dut.csr_mcause, 32'h8000_000b, "external interrupt cause");
        check_value(dut.csr_mepc, 32'h0000_3004, "external interrupt mepc");
        check_value(dut.csr_mstatus, 32'h0000_1880, "interrupt mstatus stack");

        // A still-pending source must be checked immediately by MRET.
        @(negedge clk);
        irq_external = 1'b1;
        is_mret = 1'b1;
        #1;
        if (!redirect_valid || redirect_pc !== 32'h0000_1000)
            $fatal(1, "mret did not immediately re-enter pending interrupt");
        @(posedge clk);
        #1;
        is_mret = 1'b0;
        irq_external = 1'b0;
        check_value(dut.csr_mcause, 32'h8000_000b, "mret pending cause");
        check_value(dut.csr_mepc, 32'h0000_3004, "mret pending mepc");

        // Re-enable MIE, disable MEIE, and make the timer pending.
        csr_write(12'h300, 32'h0000_1888);
        csr_write(12'h304, 32'h0000_0080);
        csr_write(12'hB84, 32'h0000_0000);
        csr_write(12'hB04, 32'h0000_0000);
        @(negedge clk);
        current_pc = 32'h0000_4000;
        interrupt_boundary = 1'b1;
        #1;
        if (!redirect_valid)
            $fatal(1, "timer interrupt was not taken");
        @(posedge clk);
        #1;
        interrupt_boundary = 1'b0;
        check_value(dut.csr_mcause, 32'h8000_0007, "timer interrupt cause");
        check_value(dut.csr_mepc, 32'h0000_4004, "timer interrupt mepc");

        $display("PASS tb_Hcsr");
        $finish;
    end
endmodule
