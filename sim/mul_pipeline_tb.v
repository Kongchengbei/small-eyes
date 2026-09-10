`timescale 1ns / 1ps

module mul_pipeline_tb;
    reg         clk;
    reg         rst;
    reg         start;
    reg         x_signed;
    reg         y_signed;
    reg  [31:0] x;
    reg  [31:0] y;
    wire [63:0] result;
    wire        done;
    integer     errors;
    integer     i;

    mul dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .x_signed (x_signed),
        .y_signed (y_signed),
        .x        (x),
        .y        (y),
        .result   (result),
        .done     (done)
    );

    always #5 clk = ~clk;

    task automatic run_case;
        input        xs;
        input        ys;
        input [31:0] x_in;
        input [31:0] y_in;
        reg signed [32:0] ref_x;
        reg signed [32:0] ref_y;
        reg signed [65:0] ref_product;
        reg        [63:0] expected;
        begin
            ref_x = xs ? {x_in[31], x_in} : {1'b0, x_in};
            ref_y = ys ? {y_in[31], y_in} : {1'b0, y_in};
            ref_product = ref_x * ref_y;
            expected = ref_product[63:0];

            @(negedge clk);
            x_signed = xs;
            y_signed = ys;
            x        = x_in;
            y        = y_in;
            start    = 1'b1;

            // First rising edge captures four partial products.
            @(posedge clk);
            #1;
            if (done) begin
                $display("FAIL: done asserted one cycle too early");
                errors = errors + 1;
            end

            @(negedge clk);
            start = 1'b0;

            // Second rising edge must produce the final 64-bit product.
            @(posedge clk);
            #1;
            if (!done) begin
                $display("FAIL: done missing after two pipeline stages");
                errors = errors + 1;
            end
            if (result !== expected) begin
                $display("FAIL: xs=%0d ys=%0d x=%h y=%h got=%h expected=%h",
                         xs, ys, x_in, y_in, result, expected);
                errors = errors + 1;
            end

            // done is a pulse, not a sticky level.
            @(posedge clk);
            #1;
            if (done) begin
                $display("FAIL: done must be a one-cycle pulse");
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk      = 1'b0;
        rst      = 1'b1;
        start    = 1'b0;
        x_signed = 1'b0;
        y_signed = 1'b0;
        x        = 32'b0;
        y        = 32'b0;
        errors   = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Directed tests for MUL, MULH, MULHSU, and MULHU operand modes.
        run_case(1'b1, 1'b1, 32'hffff_fffe, 32'h0000_0003);
        run_case(1'b1, 1'b1, 32'h8000_0000, 32'hffff_ffff);
        run_case(1'b1, 1'b0, 32'h8000_0000, 32'hffff_ffff);
        run_case(1'b0, 1'b0, 32'hffff_ffff, 32'hffff_ffff);
        run_case(1'b1, 1'b0, 32'hffff_ffff, 32'h8000_0000);

        // Mixed-sign pseudo-random cases exercise the split and alignment.
        for (i = 0; i < 16; i = i + 1) begin
            run_case(1'b0, 1'b0, $random, $random);
            run_case(1'b1, 1'b1, $random, $random);
            run_case(1'b1, 1'b0, $random, $random);
        end

        if (errors == 0)
            $display("PASS: two-cycle multiplier latency and all RV32M signedness modes");
        else
            $display("FAIL: %0d multiplier test(s) failed", errors);
        $finish;
    end
endmodule
