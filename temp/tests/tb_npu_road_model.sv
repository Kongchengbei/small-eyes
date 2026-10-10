
`timescale 1ns / 1ps

module tb_npu_road_model;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT_ADDR = 32'h8002_0000;
    localparam integer MEM_BYTES = 262144;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg clear_error = 1'b0;
    reg [31:0] model_base = MODEL_ADDR;
    reg [31:0] model_bytes = 0;
    reg [31:0] input_addr = INPUT_ADDR;
    reg [31:0] input_bytes = 0;
    reg [31:0] input_source_bytes = 0;
    reg input_downsample3 = 1'b0;

    wire busy;
    wire done_pulse;
    wire error;
    wire [7:0] error_code;
    wire [7:0] result_class;
    wire [15:0] result_confidence;
    wire result_reject;
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

    reg [7:0] mem [0:MEM_BYTES-1];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [12:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer lane;
    integer index;
    integer timeout;
    integer model_len;
    integer input_len;
    integer model_offset;
    integer input_offset;
    integer expected_class;
    integer expected_score;
    integer expected_confidence;
    integer expected_reject;
    string model_hex;
    string input_hex;
    string case_name;

    always #5 clk = ~clk;

    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0004_0000),
        .MAX_MODEL_BYTES(65536), .MAX_TENSOR_BYTES(16384),
        .MAX_LAYERS(16), .MAX_CLASSES(16)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .clear_error(clear_error),
        .model_base(model_base), .model_bytes(model_bytes),
        .input_addr(input_addr), .input_bytes(input_bytes),
        .input_source_bytes(input_source_bytes), .input_downsample3(input_downsample3),
        .busy(busy), .done_pulse(done_pulse), .error(error),
        .error_code(error_code), .result_class(result_class),
        .result_confidence(result_confidence), .result_reject(result_reject),
        .result_score(result_score),
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
        end else begin
            cycle_count <= cycle_count + 1;
            axi_arready <= !rd_active && !axi_rvalid && (cycle_count[1:0] != 2'b00);
            if (axi_arvalid && axi_arready) begin
                if (axi_arid != 8'h80 || axi_arsize != 3'b101 || axi_arburst != 2'b01)
                    $fatal(1, "ROAD AXI metadata mismatch");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1;
                rd_id <= axi_arid;
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
            end else if (rd_active && (cycle_count[1:0] != 2'b01)) begin
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
            for (timeout = 0; timeout < 20000000; timeout = timeout + 1) begin
                @(posedge clk);
                if (done_pulse)
                    disable wait_loop;
            end
            $fatal(1, "ROAD model timeout case=%s state=%0d", case_name, dut.state);
        end
    endtask

    initial begin
        if (!$value$plusargs("MODEL_HEX=%s", model_hex))
            $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("INPUT_HEX=%s", input_hex))
            $fatal(1, "INPUT_HEX is required");
        if (!$value$plusargs("MODEL_BYTES=%d", model_len))
            $fatal(1, "MODEL_BYTES is required");
        if (!$value$plusargs("INPUT_BYTES=%d", input_len))
            $fatal(1, "INPUT_BYTES is required");
        if (!$value$plusargs("EXPECTED_CLASS=%d", expected_class))
            $fatal(1, "EXPECTED_CLASS is required");
        if (!$value$plusargs("EXPECTED_SCORE=%d", expected_score))
            $fatal(1, "EXPECTED_SCORE is required");
        if (!$value$plusargs("EXPECTED_CONF=%d", expected_confidence))
            $fatal(1, "EXPECTED_CONF is required");
        if (!$value$plusargs("EXPECTED_REJECT=%d", expected_reject))
            $fatal(1, "EXPECTED_REJECT is required");
        if (!$value$plusargs("CASE=%s", case_name))
            case_name = "road_golden";

        model_bytes = model_len;
        input_bytes = input_len;
        input_source_bytes = input_len;
        model_offset = MODEL_ADDR - DDR_BASE;
        input_offset = INPUT_ADDR - DDR_BASE;
        if (model_offset + model_len > MEM_BYTES || input_offset + input_len > MEM_BYTES)
            $fatal(1, "golden memory image exceeds test memory");
        for (index = 0; index < MEM_BYTES; index = index + 1)
            mem[index] = 0;
        $readmemh(model_hex, mem, model_offset, model_offset + model_len - 1);
        $readmemh(input_hex, mem, input_offset, input_offset + input_len - 1);

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        start = 1'b0;
        wait_done;

        if (error || result_class != expected_class || result_score != expected_score ||
            result_confidence != expected_confidence || result_reject != expected_reject)
            $fatal(1, "ROAD GOLDEN FAIL case=%s class=%0d score=%0d conf=%0d reject=%0d err=%0d code=%0d",
                   case_name, result_class, result_score, result_confidence,
                   result_reject, error, error_code);
        $display("NPU_ROAD_GOLDEN_PASS case=%s class=%0d score=%0d conf=%0d reject=%0d",
                 case_name, result_class, result_score, result_confidence, result_reject);
        $finish;
    end
endmodule
