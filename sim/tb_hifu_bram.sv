`timescale 1ns / 1ps

module tb_hifu_bram;
    localparam [31:0] BASE = 32'h8000_0000;
    localparam [31:0] TARGET = 32'h8000_0040;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    reg id_allowin = 1'b1;
    reg flush = 1'b0;
    reg [31:0] redirect_pc = 32'b0;
    wire [31:0] imem_rdata;
    wire imem_resp_valid;
    wire imem_req_ready = 1'b1;
    wire imem_req_valid;
    wire [31:0] imem_addr;
    wire [31:0] if_ins, if_pc, predict_next_pc, btb_lookup_pc;
    wire if_to_id_valid, dbg_if_valid, dbg_if_allowin;
    wire [31:0] btb_target = TARGET;
    wire btb_hit = (btb_lookup_pc == BASE + 32'd8);

    reg [31:0] mem [0:127];
    reg [31:0] mem_rdata = 32'b0;
    reg mem_rvalid = 1'b0;
    assign imem_rdata = mem_rdata;
    assign imem_resp_valid = mem_rvalid;

    Hifu #(.RESET_PC(BASE), .CONTINUOUS_FETCH(1'b1)) dut (
        .clk(clk), .rst(rst),
        .id_allowin(id_allowin), .flush(flush), .redirect_pc(redirect_pc),
        .imem_rdata(imem_rdata), .imem_resp_valid(imem_resp_valid),
        .imem_req_ready(imem_req_ready), .imem_req_valid(imem_req_valid),
        .imem_addr(imem_addr), .if_ins(if_ins), .if_pc(if_pc),
        .if_to_id_valid(if_to_id_valid), .btb_lookup_pc(btb_lookup_pc),
        .dbg_if_valid(dbg_if_valid), .dbg_if_allowin(dbg_if_allowin),
        .btb_target(btb_target), .btb_hit(btb_hit),
        .predict_next_pc(predict_next_pc)
    );

    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1)
            mem[i] = 32'h1000_0000 + i;
    end

    // One-cycle synchronous instruction memory model.
    always @(posedge clk) begin
        mem_rvalid <= !rst && imem_req_valid && imem_req_ready;
        if (!rst && imem_req_valid && imem_req_ready)
            mem_rdata <= mem[(imem_addr - BASE) >> 2];
    end

    reg [31:0] expected_pc = BASE;
    integer transfer_count = 0;
    integer previous_transfer_cycle = -1;
    integer cycle_count = 0;
    reg previous_cycle_ready = 1'b0;
    reg checking = 1'b1;
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        if (!rst && checking && if_to_id_valid && id_allowin) begin
            if (if_pc !== expected_pc)
                $fatal(1, "fetch PC[%0d]=%08x expected %08x", transfer_count, if_pc, expected_pc);
            if (if_ins !== mem[(if_pc - BASE) >> 2])
                $fatal(1, "fetch data mismatch pc=%08x ins=%08x", if_pc, if_ins);
            if (predict_next_pc !== ((if_pc == BASE + 32'd8) ? TARGET : (if_pc + 32'd4)))
                $fatal(1, "prediction not paired with PC=%08x pred=%08x", if_pc, predict_next_pc);
            if (previous_cycle_ready && previous_transfer_cycle >= 0 && cycle_count != previous_transfer_cycle + 1)
                $fatal(1, "sequential/BTB fetch bubble between transfers %0d and %0d", transfer_count-1, transfer_count);
            previous_transfer_cycle <= cycle_count;
            transfer_count <= transfer_count + 1;
            expected_pc <= (if_pc == BASE + 32'd8) ? TARGET : (if_pc + 32'd4);
        end else if (!rst && flush) begin
            expected_pc <= redirect_pc;
        end
        previous_cycle_ready <= id_allowin;
    end

    reg [31:0] held_pc, held_ins;
    initial begin
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 1'b0;
        wait (transfer_count == 5);

        // Force a downstream stall long enough to fill both fetch slots.
        @(negedge clk) id_allowin = 1'b0;
        wait (if_to_id_valid);
        held_pc = if_pc;
        held_ins = if_ins;
        repeat (4) begin
            @(posedge clk);
            #1;
            if (!if_to_id_valid || if_pc !== held_pc || if_ins !== held_ins)
                $fatal(1, "IF entry changed while ID was stalled");
        end
        @(negedge clk) id_allowin = 1'b1;
        repeat (3) @(posedge clk);

        // A redirect must discard queued sequential work and restart at target.
        @(negedge clk);
        id_allowin = 1'b0;
        flush = 1'b1;
        redirect_pc = BASE + 32'h80;
        @(posedge clk);
        #1;
        @(negedge clk);
        flush = 1'b0;
        id_allowin = 1'b1;
        wait (if_to_id_valid);
        if (if_pc !== BASE + 32'h80 || if_ins !== mem[32])
            $fatal(1, "redirect fetch mismatch pc=%08x ins=%08x", if_pc, if_ins);
        $display("PASS: BRAM IF throughput, BTB target, stall retention, redirect flush");
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "timeout");
    end
endmodule
