`timescale 1ns / 1ps

module tb_npu_fc_engine;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] INPUT_ADDR = 32'h8000_1000;
    localparam [31:0] WEIGHT_ADDR = 32'h8000_2000;
    localparam [31:0] BIAS_ADDR = 32'h8000_3000;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg clear_error = 1'b0;
    reg [31:0] input_addr;
    reg [31:0] input_bytes;
    reg [31:0] weight_addr;
    reg [31:0] weight_stride;
    reg [31:0] bias_addr;
    reg [15:0] feature_count;
    reg [7:0] class_count;
    reg [5:0] quant_shift;
    wire busy;
    wire done_pulse;
    wire error;
    wire [7:0] error_code;
    wire [7:0] result_class;
    wire [15:0] result_confidence;
    wire [31:0] result_score;
    wire [29:0] axi_araddr;
    wire [7:0] axi_arid;
    wire [7:0] axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid;
    reg axi_arready = 1'b0;
    reg [255:0] axi_rdata = 0;
    reg [7:0] axi_rid = 0;
    reg [1:0] axi_rresp = 0;
    reg axi_rlast = 0;
    reg axi_rvalid = 0;
    wire axi_rready;

    reg [255:0] mem [0:2047];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer ar_count;
    integer lane;
    integer i;
    reg inject_rresp;
    reg inject_rid;
    reg inject_missing_rlast;
    reg inject_late_rlast;
    integer last_read_count;

    always #5 clk = ~clk;

    Hnpu_fc_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0001_0000),
        .MAX_FEATURES(32), .MAX_CLASSES(3)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .clear_error(clear_error),
        .input_addr(input_addr), .input_bytes(input_bytes),
        .weight_addr(weight_addr), .weight_stride(weight_stride),
        .bias_addr(bias_addr), .feature_count(feature_count),
        .class_count(class_count), .quant_shift(quant_shift),
        .busy(busy), .done_pulse(done_pulse), .error(error), .error_code(error_code),
        .result_class(result_class), .result_confidence(result_confidence),
        .result_score(result_score), .axi_araddr(axi_araddr), .axi_arid(axi_arid),
        .axi_arlen(axi_arlen), .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
        .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
            ar_count <= 0;
            rd_active <= 1'b0;
            rd_addr <= 0;
            rd_left <= 0;
            rd_id <= 0;
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rdata <= 0;
            axi_rid <= 0;
            axi_rresp <= 0;
            axi_rlast <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid && (cycle_count[1:0] != 2'b00);
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "FC AXI metadata mismatch");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1;
                rd_id <= axi_arid;
                ar_count <= ar_count + 1;
            end
            if (axi_rvalid) begin
                if (axi_rready) begin
                    axi_rvalid <= 1'b0;
                    if (rd_left == 1) begin
                        if (inject_late_rlast)
                            rd_left <= 0;
                        else
                            rd_active <= 1'b0;
                    end else if (rd_left == 0) begin
                        rd_active <= 1'b0;
                    end
                    else begin
                        rd_left <= rd_left - 1'b1;
                        rd_addr <= rd_addr + 30'd32;
                    end
                end
            end else if (rd_active && (cycle_count[1:0] != 2'b01)) begin
                axi_rdata <= mem[rd_addr[15:5]];
                axi_rid <= inject_rid ? 8'h81 : rd_id;
                axi_rresp <= inject_rresp ? 2'b10 : 2'b00;
                axi_rlast <= inject_missing_rlast ? 1'b0 :
                             (inject_late_rlast ? (rd_left == 0) : (rd_left == 1));
                axi_rvalid <= 1'b1;
            end
        end
    end

    task reset_case;
        begin
            rst_n = 1'b0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            @(negedge clk);
            inject_rresp = 1'b0;
            inject_rid = 1'b0;
            inject_missing_rlast = 1'b0;
            inject_late_rlast = 1'b0;
            ar_count = 0;
        end
    endtask

    task start_task;
        begin
            @(negedge clk);
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task wait_done;
        integer timeout;
        begin : wait_loop
            for (timeout = 0; timeout < 2000; timeout = timeout + 1) begin
                @(posedge clk);
                if (done_pulse)
                    disable wait_loop;
            end
            $fatal(1, "FC engine timeout");
        end
    endtask

    task expect_error;
        input [7:0] expected;
        begin
            if (!error || error_code != expected)
                $fatal(1, "FC expected error=%0d actual=%0d code=%0d",
                       expected, error, error_code);
        end
    endtask

    initial begin
        input_addr = INPUT_ADDR;
        input_bytes = 32;
        weight_addr = WEIGHT_ADDR;
        weight_stride = 32;
        bias_addr = BIAS_ADDR;
        feature_count = 32;
        class_count = 3;
        quant_shift = 1;
        inject_rresp = 1'b0;
        inject_rid = 1'b0;
        inject_missing_rlast = 1'b0;
        inject_late_rlast = 1'b0;
        for (i = 0; i < 2048; i = i + 1)
            mem[i] = 0;

        // Input is +3. Scores before quantization are +96, 0, -96;
        // arithmetic shift by one must select class 0 with margin 48.
        for (lane = 0; lane < 32; lane = lane + 1) begin
            mem[(INPUT_ADDR - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd3;
            mem[(WEIGHT_ADDR - DDR_BASE) >> 5][lane*8 +: 8] = 8'sd1;
            mem[((WEIGHT_ADDR + 32 - DDR_BASE) >> 5)][lane*8 +: 8] = 8'sd0;
            mem[((WEIGHT_ADDR + 64 - DDR_BASE) >> 5)][lane*8 +: 8] = -8'sd1;
        end
        mem[(BIAS_ADDR - DDR_BASE) >> 5][31:0] = 32'sd0;
        mem[(BIAS_ADDR - DDR_BASE) >> 5][63:32] = 32'sd0;
        mem[(BIAS_ADDR - DDR_BASE) >> 5][95:64] = 32'sd0;

        reset_case;
        start_task;
        wait_done;
        if (error || result_class != 0 || result_score != 32'd48 ||
            result_confidence != 16'd48)
            $fatal(1, "FC numerical result mismatch class=%0d score=%0d conf=%0d error=%0d",
                   result_class, result_score, result_confidence, error);

        reset_case;
        input_addr = INPUT_ADDR + 1;
        start_task;
        wait_done;
        // Alignment is a configuration error; ERR_RANGE is reserved for an
        // address outside the configured DDR window.
        expect_error(8'd1);
        if (ar_count != 0)
            $fatal(1, "invalid FC address issued an AXI read");

        reset_case;
        bias_addr = 32'h8000_3fe0;
        start_task;
        wait_done;
        expect_error(8'd1);
        if (ar_count != 0)
            $fatal(1, "4 KiB-crossing bias address issued an AXI read");
        bias_addr = BIAS_ADDR;

        reset_case;
        input_addr = INPUT_ADDR;
        inject_rresp = 1'b1;
        start_task;
        wait_done;
        expect_error(8'd2);

        reset_case;
        inject_rresp = 1'b0;
        inject_rid = 1'b1;
        start_task;
        wait_done;
        expect_error(8'd3);

        reset_case;
        inject_rid = 1'b0;
        inject_missing_rlast = 1'b1;
        start_task;
        wait_done;
        expect_error(8'd4);

        reset_case;
        inject_missing_rlast = 1'b0;
        inject_late_rlast = 1'b1;
        start_task;
        wait_done;
        expect_error(8'd4);

        $display("NPU_FC_ENGINE_PASS reads=%0d", ar_count);
        $finish;
    end
endmodule
