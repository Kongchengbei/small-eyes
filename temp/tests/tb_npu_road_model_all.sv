`timescale 1ns / 1ps

module tb_npu_road_model_all;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT_ADDR = 32'h8002_0000;
    localparam integer MODEL_BYTES = 62496;
    localparam integer INPUT_BYTES = 4096;
    localparam integer ROI_COUNT = 33;
    localparam integer MEM_BYTES = 524288;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg clear_error = 1'b0;
    reg [31:0] model_base = MODEL_ADDR;
    reg [31:0] model_bytes = MODEL_BYTES;
    reg [31:0] input_addr = INPUT_ADDR;
    reg [31:0] input_bytes = INPUT_BYTES;
    reg [31:0] input_source_bytes = INPUT_BYTES;
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
    reg axi_rlast = 1'b0;
    reg axi_rvalid = 1'b0;
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
    integer expected_fd;
    integer expected_class [0:ROI_COUNT-1];
    integer expected_margin [0:ROI_COUNT-1];
    integer expected_reject [0:ROI_COUNT-1];
    integer expected_extra;
    string model_hex;
    string inputs_hex;
    string expected_file;

    always #5 clk = ~clk;

    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0008_0000),
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
        .result_score(result_score), .axi_araddr(axi_araddr), .axi_arid(axi_arid),
        .axi_arlen(axi_arlen), .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
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
                    $fatal(1, "ROAD ALL AXI metadata mismatch");
                if ((axi_araddr + ((axi_arlen + 1) << 5)) > MEM_BYTES)
                    $fatal(1, "ROAD ALL AXI address outside test memory");
                rd_active <= 1'b1;
                rd_addr <= axi_araddr;
                rd_left <= axi_arlen + 1'b1;
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
            $fatal(1, "ROAD ALL timeout state=%0d case=%0d", dut.state, index);
        end
    endtask

    task run_case;
        input integer case_index;
        begin : case_loop
            @(negedge clk);
            input_addr = INPUT_ADDR + case_index * INPUT_BYTES;
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;
            wait_done;
            if (error || result_class != expected_class[case_index] ||
                result_confidence != expected_margin[case_index] ||
                result_reject != expected_reject[case_index])
                $fatal(1, "ROAD ALL FAIL case=%0d class=%0d/%0d margin=%0d/%0d reject=%0d/%0d error=%0d code=%0d",
                       case_index, result_class, expected_class[case_index],
                       result_confidence, expected_margin[case_index], result_reject,
                       expected_reject[case_index], error, error_code);
        end
    endtask

    initial begin : test
        if (!$value$plusargs("MODEL_HEX=%s", model_hex))
            $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("INPUTS_HEX=%s", inputs_hex))
            $fatal(1, "INPUTS_HEX is required");
        if (!$value$plusargs("EXPECTED_FILE=%s", expected_file))
            $fatal(1, "EXPECTED_FILE is required");

        for (index = 0; index < MEM_BYTES; index = index + 1)
            mem[index] = 0;
        if ((MODEL_ADDR - DDR_BASE) + MODEL_BYTES > MEM_BYTES ||
            (INPUT_ADDR - DDR_BASE) + ROI_COUNT * INPUT_BYTES > MEM_BYTES)
            $fatal(1, "ROAD ALL memory image exceeds test memory");
        $readmemh(model_hex, mem, MODEL_ADDR - DDR_BASE,
                  MODEL_ADDR - DDR_BASE + MODEL_BYTES - 1);
        $readmemh(inputs_hex, mem, INPUT_ADDR - DDR_BASE,
                  INPUT_ADDR - DDR_BASE + ROI_COUNT * INPUT_BYTES - 1);

        expected_fd = $fopen(expected_file, "r");
        if (!expected_fd)
            $fatal(1, "cannot open EXPECTED_FILE");
        for (index = 0; index < ROI_COUNT; index = index + 1) begin
            if ($fscanf(expected_fd, "%d %d %d\n", expected_class[index],
                        expected_margin[index], expected_reject[index]) != 3)
                $fatal(1, "expected file ended at case=%0d", index);
        end
        if ($fscanf(expected_fd, "%d", expected_extra) == 1)
            $fatal(1, "expected file has more than %0d cases", ROI_COUNT);
        $fclose(expected_fd);

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        for (index = 0; index < ROI_COUNT; index = index + 1)
            run_case(index);

        $display("NPU_ROAD_MODEL_ALL_PASS cases=%0d", ROI_COUNT);
        $finish;
    end
endmodule
