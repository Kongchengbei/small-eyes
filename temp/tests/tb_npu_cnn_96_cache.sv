`timescale 1ns / 1ps

module tb_npu_cnn_96_cache;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT1_ADDR = 32'h8002_0000;
    localparam [31:0] INPUT2_ADDR = 32'h8002_9000;
    localparam integer MODEL_BYTES = 512;
    localparam integer INPUT_BYTES = 96 * 96 * 4;
    localparam integer MEM_BYTES = 32'h0004_0000;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg clear_error = 1'b0;
    reg [31:0] model_base = MODEL_ADDR;
    reg [31:0] model_bytes = MODEL_BYTES;
    reg [31:0] input_addr = INPUT1_ADDR;
    reg [31:0] input_bytes = INPUT_BYTES;
    reg [31:0] input_source_bytes = INPUT_BYTES;
    reg input_downsample3 = 1'b0;

    wire busy, done_pulse, error, result_reject;
    wire [7:0] error_code, result_class;
    wire [15:0] result_confidence;
    wire [31:0] result_score;
    wire model_cache_hit, model_cache_valid;
    wire [31:0] model_load_count, model_load_beats;
    wire [29:0] axi_araddr;
    wire [7:0] axi_arid, axi_arlen;
    wire [2:0] axi_arsize;
    wire [1:0] axi_arburst;
    wire axi_arvalid, axi_rready;
    reg axi_arready = 1'b0;
    reg [255:0] axi_rdata = 0;
    reg [7:0] axi_rid = 0;
    reg [1:0] axi_rresp = 0;
    reg axi_rlast = 0;
    reg axi_rvalid = 0;

    reg [7:0] mem [0:MEM_BYTES-1];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer lane;
    integer index;
    integer timeout;
    integer model_ar_count;
    integer input_ar_count;
    reg saw_cache_hit;
    string model_hex;

    always #5 clk = ~clk;

    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0010_0000),
        .MAX_MODEL_BYTES(65536), .MAX_TENSOR_BYTES(65536),
        .MAX_LAYERS(16), .MAX_CLASSES(16)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .clear_error(clear_error),
        .model_base(model_base), .model_bytes(model_bytes),
        .input_addr(input_addr), .input_bytes(input_bytes),
        .input_source_bytes(input_source_bytes), .input_downsample3(input_downsample3),
        .busy(busy), .done_pulse(done_pulse), .error(error),
        .error_code(error_code), .result_class(result_class),
        .result_confidence(result_confidence), .result_score(result_score),
        .result_reject(result_reject), .model_cache_hit(model_cache_hit),
        .model_cache_valid(model_cache_valid), .model_load_count(model_load_count),
        .model_load_beats(model_load_beats),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
        .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid), .axi_rready(axi_rready)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 0;
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
            model_ar_count <= 0;
            input_ar_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid;
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "96x96 AXI metadata mismatch");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1;
                rd_id <= axi_arid;
                if (axi_araddr >= MODEL_ADDR - DDR_BASE &&
                    axi_araddr < MODEL_ADDR - DDR_BASE + MODEL_BYTES)
                    model_ar_count <= model_ar_count + 1;
                if (axi_araddr >= INPUT1_ADDR - DDR_BASE &&
                    axi_araddr < INPUT2_ADDR - DDR_BASE + INPUT_BYTES)
                    input_ar_count <= input_ar_count + 1;
            end
            if (axi_rvalid) begin
                if (axi_rready) begin
                    axi_rvalid <= 1'b0;
                    if (rd_left == 1)
                        rd_active <= 1'b0;
                    else begin
                        rd_left <= rd_left - 1'b1;
                        rd_addr <= rd_addr + 30'd32;
                    end
                end
            end else if (rd_active) begin
                axi_rdata <= 0;
                for (lane = 0; lane < 32; lane = lane + 1)
                    axi_rdata[lane*8 +: 8] <= mem[rd_addr + lane];
                axi_rid <= rd_id;
                axi_rresp <= 2'b00;
                axi_rlast <= (rd_left == 1);
                axi_rvalid <= 1'b1;
            end
        end
    end

    task wait_done;
        begin : wait_loop
            for (timeout = 0; timeout < 1000000; timeout = timeout + 1) begin
                @(posedge clk);
                if (model_cache_hit)
                    saw_cache_hit = 1'b1;
                if (done_pulse)
                    disable wait_loop;
            end
            $fatal(1, "96x96 cache test timeout state=%0d", dut.state);
        end
    endtask

    task start_one;
        input [31:0] addr;
        begin
            input_addr = addr;
            @(negedge clk);
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;
            wait_done;
        end
    endtask

    initial begin
        if (!$value$plusargs("MODEL_HEX=%s", model_hex))
            $fatal(1, "MODEL_HEX is required");
        for (index = 0; index < MEM_BYTES; index = index + 1)
            mem[index] = 0;
        $readmemh(model_hex, mem, 0, MODEL_BYTES - 1);
        for (index = 0; index < MODEL_BYTES; index = index + 1)
            mem[MODEL_ADDR - DDR_BASE + index] = mem[index];

        // ROI 1: average R is greater than G -> class 0.
        for (index = 0; index < 96 * 96; index = index + 1) begin
            mem[INPUT1_ADDR - DDR_BASE + index * 4] = 8'd10;
            mem[INPUT1_ADDR - DDR_BASE + index * 4 + 1] = 8'd1;
        end
        // ROI 2: average G is greater than R -> class 1.
        for (index = 0; index < 96 * 96; index = index + 1) begin
            mem[INPUT2_ADDR - DDR_BASE + index * 4] = 8'd1;
            mem[INPUT2_ADDR - DDR_BASE + index * 4 + 1] = 8'd20;
        end

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        saw_cache_hit = 1'b0;
        start_one(INPUT1_ADDR);
        if (error || result_class != 0 || result_score != 10 ||
            saw_cache_hit || model_load_count != 1 || !model_cache_valid)
            $fatal(1, "96x96 first ROI mismatch class=%0d score=%0d error=%0d hit=%0d loads=%0d valid=%0d",
                   result_class, result_score, error, model_cache_hit,
                   model_load_count, model_cache_valid);

        saw_cache_hit = 1'b0;
        start_one(INPUT2_ADDR);
        if (error || result_class != 1 || result_score != 20 ||
            !saw_cache_hit || model_load_count != 1 || model_load_beats != MODEL_BYTES / 32)
            $fatal(1, "96x96 cache hit mismatch class=%0d score=%0d error=%0d hit=%0d loads=%0d beats=%0d",
                   result_class, result_score, error, model_cache_hit,
                   model_load_count, model_load_beats);
        if (model_ar_count != 1)
            $fatal(1, "model was fetched more than once ar_count=%0d", model_ar_count);
        $display("NPU_CNN_96_CACHE_PASS model_ar=%0d model_beats=%0d input_ar=%0d",
                 model_ar_count, model_load_beats, input_ar_count);
        $finish;
    end
endmodule
