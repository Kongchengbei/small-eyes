// Placeholder: generated for local CoreMark simulation.
`timescale 1ns/1ps

// CoreMark smoke test for the Htop RTL.  The instruction image contains the
// program plus its initialized data; startup copies the data section to DMEM.
module tb_coremark;
    localparam integer IMEM_WORDS = 8192;  // 32 KiB
    localparam integer DMEM_WORDS = 4096;  // 16 KiB at 0x2000_0000

    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;

    wire [31:0] imem_addr;
    reg  [31:0] imem_rdata;
    wire        dmem_valid, dmem_wen;
    wire [31:0] dmem_addr, dmem_wdata;
    wire [3:0]  dmem_wmask;
    reg  [31:0] dmem_rdata;
    wire [31:0] pc, ins;
    wire        is_ebreak;

    reg [31:0] imem [0:IMEM_WORDS-1];
    reg [31:0] dmem [0:DMEM_WORDS-1];
    integer i;
    integer cycles = 0;
    integer uart_chars = 0;
    integer mmio_writes = 0;
	integer fpioa_count;
    reg [31:0] last_mcause = 32'h0;

    Htop #(.RESET_PC(32'h0000_0000)) dut (
        .clk(clk), .rst(rst),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_valid(dmem_valid), .dmem_wen(dmem_wen),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_wmask(dmem_wmask), .dmem_rdata(dmem_rdata),
        // Htop now exposes the ready/反压握手；CPU-only TB 中 RAM 视为
        // 当拍完成，因此必须明确拉高，不能悬空为 X。
        .dmem_ready(1'b1),
        .pc(pc), .ins(ins), .is_ebreak(is_ebreak)
    );

    // Model the generated BRAMs: both read ports update one clock after the
    // address is presented.  The former combinational model made a load in
    // MEM observe the following EX address and is no longer valid after the
    // CPU was changed to synchronous BRAM interfaces.
    always @(posedge clk) begin
        if (rst) begin
            imem_rdata <= 32'h0000_0013;
            dmem_rdata <= 32'b0;
        end else begin
            if ((imem_addr < 32'h0000_8000) && (imem_addr[1:0] == 2'b00))
                imem_rdata <= imem[imem_addr[14:2]];
            else
                imem_rdata <= 32'h0000_0013;

            // CPU data reads can access the initialized image in IMEM
            // (startup), normal data RAM, or the idle UART status register.
            if ((dmem_addr < 32'h0000_8000) && (dmem_addr[1:0] == 2'b00))
                dmem_rdata <= imem[dmem_addr[14:2]];
            else if ((dmem_addr >= 32'h2000_0000) &&
                     (dmem_addr <  32'h2000_4000) &&
                     (dmem_addr[1:0] == 2'b00))
                dmem_rdata <= dmem[dmem_addr[13:2]];
            else if (dmem_addr == 32'h4000_0004)
                dmem_rdata <= 32'b0; // UART status: idle
            else
                dmem_rdata <= 32'b0;
        end
    end

    always @(posedge clk) begin
        if (!rst && dmem_valid && dmem_wen) begin
            if (dmem_addr[31:28] == 4'h4) begin
                mmio_writes = mmio_writes + 1;
                if (mmio_writes <= 40)
                    $display("MMIO[%0d] cycle=%0d pc=%08x addr=%08x data=%08x mask=%x", mmio_writes, cycles, pc, dmem_addr, dmem_wdata, dmem_wmask);
            end
            if ((dmem_addr >= 32'h2000_0000) &&
                (dmem_addr <  32'h2000_4000)) begin
                if (dmem_wmask[0]) dmem[dmem_addr[13:2]][7:0]   <= dmem_wdata[7:0];
                if (dmem_wmask[1]) dmem[dmem_addr[13:2]][15:8]  <= dmem_wdata[15:8];
                if (dmem_wmask[2]) dmem[dmem_addr[13:2]][23:16] <= dmem_wdata[23:16];
                if (dmem_wmask[3]) dmem[dmem_addr[13:2]][31:24] <= dmem_wdata[31:24];
            end
            if (dmem_addr == 32'h4000_000c) begin
                $write("%c", dmem_wdata[7:0]);
                uart_chars = uart_chars + 1;
            end
            if (dmem_addr == 32'h4000_0008)
                $display("[UART] baud_div=%0d", dmem_wdata[15:0]);
        end
        if (!rst) cycles = cycles + 1;
        if (!rst && (cycles % 1000) == 0)
            $display("PROGRESS cycle=%0d pc=%08x ins=%08x ebreak=%b", cycles, pc, ins, is_ebreak);
        if (!rst && dut.u_exu.u_csr.csr_mcause != last_mcause) begin
            $display("MCAUSE changed cycle=%0d pc=%08x mcause=%08x mepc=%08x mtvec=%08x", cycles, pc, dut.u_exu.u_csr.csr_mcause, dut.u_exu.u_csr.csr_mepc, dut.u_exu.u_csr.csr_mtvec);
            last_mcause = dut.u_exu.u_csr.csr_mcause;
        end
    end

    initial begin
        for (i = 0; i < IMEM_WORDS; i = i + 1) imem[i] = 32'h0000_0013;
        for (i = 0; i < DMEM_WORDS; i = i + 1) dmem[i] = 32'b0;
        $readmemh("../source/soc/coremark.dat", imem);
        $dumpfile("tb_coremark.vcd");
        $dumpvars(0, tb_coremark);
        repeat (8) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        repeat (2000000) @(posedge clk);
        $display("\nTIMEOUT cycles=%0d pc=%08x ins=%08x uart_chars=%0d",
                 cycles, pc, ins, uart_chars);
        $finish;
    end
	always @(posedge clk) begin
    if (rst) begin
        fpioa_count = 0;
    end else if (dmem_valid &&
                 dmem_wen &&
                 (dmem_addr == 32'h4000_0f1f)) begin

        			fpioa_count = fpioa_count + 1;

        			$display("FPIOA[%0d] cycle=%0d pc=%08x data=%08x",
                 			fpioa_count, cycles, pc, dmem_wdata);

        			if (fpioa_count >= 2) begin
            			$display("CPU_RESTART: CoreMark returned to startup");
            			$finish;
        			end
    			end
end
endmodule
