`timescale 1ns/1ps
module tb_Btb_predict;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg [31:0] lookup_pc = 32'b0;
    reg update_valid = 1'b0;
    reg [31:0] update_pc = 32'b0;
    reg [31:0] update_target = 32'b0;
    reg update_is_conditional = 1'b0;
    reg update_taken = 1'b0;
    wire lookup_match;
    wire lookup_predict_taken;
    wire lookup_hit;
    wire [31:0] lookup_target;

    always #5 clk = ~clk;

    Btb dut (
        .clk(clk), .rst(rst),
        .lookup_pc(lookup_pc),
        .update_valid(update_valid), .update_pc(update_pc),
        .update_target(update_target),
        .update_is_conditional(update_is_conditional),
        .update_taken(update_taken),
        .lookup_match(lookup_match),
        .lookup_predict_taken(lookup_predict_taken),
        .lookup_hit(lookup_hit), .lookup_target(lookup_target)
    );

    task update_entry(input [31:0] pc, input [31:0] target,
                      input cond, input taken);
        begin
            @(negedge clk);
            update_pc = pc;
            update_target = target;
            update_is_conditional = cond;
            update_taken = taken;
            update_valid = 1'b1;
            @(negedge clk);
            update_valid = 1'b0;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 1'b0;

        // Reset must leave every entry invalid, even though the default
        // direction state itself is weak-not-taken.
        lookup_pc = 32'h0000_0020;
        #1;
        if (lookup_match || lookup_hit)
            $fatal(1, "reset did not invalidate BTB entry");

        // A taken conditional branch learns weak-taken first, then predicts.
        update_entry(32'h0000_0020, 32'h0000_001c, 1'b1, 1'b1);
        lookup_pc = 32'h0000_0020;
        #1;
        if (!lookup_hit || lookup_target != 32'h0000_001c)
            $fatal(1, "taken branch was not predicted after update");

        // A not-taken result moves weak-taken to weak-not-taken.
        update_entry(32'h0000_0020, 32'h0000_001c, 1'b1, 1'b0);
        #1;
        if (lookup_hit)
            $fatal(1, "weak-not-taken state still predicted taken");

        // Learn strongly taken, then verify one not-taken does not flip it.
        update_entry(32'h0000_0020, 32'h0000_001c, 1'b1, 1'b1);
        update_entry(32'h0000_0020, 32'h0000_001c, 1'b1, 1'b1);
        #1;
        if (!lookup_hit)
            $fatal(1, "strong-taken state was not reached");

        update_entry(32'h0000_0020, 32'h0000_001c, 1'b1, 1'b0);
        #1;
        if (!lookup_hit)
            $fatal(1, "strong-taken state changed direction too aggressively");

        // A second not-taken result changes the prediction to not-taken.
        update_entry(32'h0000_0020, 32'h0000_001c, 1'b1, 1'b0);
        #1;
        if (lookup_hit)
            $fatal(1, "2-bit predictor did not switch to not-taken");

        // A same-index/different-tag branch must replace the old entry and
        // must not alias back to the old target.
        update_entry(32'h0000_0120, 32'h0000_0220, 1'b1, 1'b1);
        lookup_pc = 32'h0000_0120;
        #1;
        if (!lookup_match || !lookup_hit || lookup_target != 32'h0000_0220)
            $fatal(1, "same-index replacement entry was not learned");
        lookup_pc = 32'h0000_0020;
        #1;
        if (lookup_match || lookup_hit)
            $fatal(1, "old same-index tag remained valid after replacement");

        // A target update for an existing unconditional jump must be visible
        // on the next lookup without disturbing its always-taken behavior.
        update_entry(32'h0000_0100, 32'h0000_0200, 1'b0, 1'b1);
        update_entry(32'h0000_0100, 32'h0000_0300, 1'b0, 1'b1);
        lookup_pc = 32'h0000_0100;
        #1;
        if (!lookup_match || !lookup_hit || lookup_target != 32'h0000_0300)
            $fatal(1, "unconditional target update failed");

        // Unconditional jumps always predict target when the entry hits.
        if (!lookup_predict_taken)
            $fatal(1, "unconditional entry did not report taken direction");

        $display("BTB_DIRECTION_TEST_PASS");
        $finish;
    end
endmodule
