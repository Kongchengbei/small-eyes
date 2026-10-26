`timescale 1ns/1ps

// Eight-entry circular return-address stack for the front end.
// Push/pop qualification and RV32 RAS hints are supplied by the caller.
module ReturnAddressStack (
    input  wire        clk,
    input  wire        rst,
    input  wire        clear,
    input  wire        push,
    input  wire        pop,
    input  wire [31:0] push_addr,
    output wire        valid,
    output wire [31:0] top_addr
);

    reg [31:0] entries [0:7];
    reg [2:0]  next_idx;
    reg [3:0]  depth;

    wire [2:0] top_idx = next_idx - 3'd1;

    assign valid    = (depth != 4'd0);
    assign top_addr = valid ? entries[top_idx] : 32'd0;

    // `next_idx` points to the next insertion slot; the current top is the
    // preceding slot. Depth saturates at eight while the circular index wraps.
    always @(posedge clk) begin
        if (rst) begin
            next_idx <= 3'd0;
            depth    <= 4'd0;
        end else if (clear) begin
            next_idx <= 3'd0;
            depth    <= 4'd0;
        end else if (push && pop) begin
            if (depth == 4'd0) begin
                // An empty pop has no effect; the simultaneous push creates
                // the first entry.
                entries[next_idx] <= push_addr;
                next_idx          <= next_idx + 3'd1;
                depth             <= 4'd1;
            end else begin
                // Coroutine-style transfer: replace the current top and keep
                // the depth and insertion pointer unchanged.
                entries[top_idx] <= push_addr;
            end
        end else if (push) begin
            entries[next_idx] <= push_addr;
            next_idx          <= next_idx + 3'd1;
            if (depth != 4'd8)
                depth <= depth + 4'd1;
        end else if (pop && (depth != 4'd0)) begin
            next_idx <= next_idx - 3'd1;
            depth    <= depth - 4'd1;
        end
    end

endmodule
