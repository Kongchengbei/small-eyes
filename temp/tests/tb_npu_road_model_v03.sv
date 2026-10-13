`timescale 1ns / 1ps

module tb_npu_road_model_v03 #(
    parameter integer MODEL_BYTES = 62720,
    parameter integer ROI_COUNT = 101
);
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT_ADDR = 32'h8002_0000;
    localparam integer INPUT_BYTES = 4096;
    localparam integer MODEL_BURSTS = (MODEL_BYTES / 32 + 15) / 16;
`ifdef DS3
    localparam integer SRC_BYTES = 36864;
`else
    localparam integer SRC_BYTES = 4096;
`endif
    localparam integer MEM_BYTES = 4194304;
    localparam integer TRACE_BYTES_PER_ROI = 36972;
    // First-version target: 16 ROIs/s across two cameras. 70 MHz is a
    // conservative NPU-clock assumption; this test uses a simulated DDR.
    localparam integer FIRST_VERSION_CYCLE_LIMIT = 70000000 / 16;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg clear_error = 1'b0;
    reg [31:0] model_base = MODEL_ADDR;
    reg [31:0] model_bytes = MODEL_BYTES;
    reg [31:0] input_addr = INPUT_ADDR;
    reg [31:0] input_bytes = INPUT_BYTES;
    reg [31:0] input_source_bytes = SRC_BYTES;
    `ifdef DS3
    reg input_downsample3 = 1'b1;
`else
    reg input_downsample3 = 1'b0;
`endif

    wire busy;
    wire done_pulse;
    wire error;
    wire [7:0] error_code;
    wire [7:0] result_class;
    wire [15:0] result_confidence;
    wire result_reject;
    wire [31:0] result_score;
    wire model_cache_hit;
    wire model_cache_valid;
    wire [31:0] model_load_count;
    wire [31:0] model_load_beats;
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
    integer model_ar_count;
    integer case_start_cycle;
    integer active_case;
    integer max_cached_cycles;
    integer expected_class [0:ROI_COUNT-1];
    integer expected_margin [0:ROI_COUNT-1];
    integer expected_reject [0:ROI_COUNT-1];
    integer expected_score [0:ROI_COUNT-1];
    integer expected_extra;
    integer layer_check_count;
    integer trace_layer, trace_base, trace_length, trace_byte;
    reg [7:0] observed_byte;
    reg [7:0] layer_expected [0:ROI_COUNT*TRACE_BYTES_PER_ROI-1];
    reg check_layers = 1'b0;
    string model_hex;
    string inputs_hex;
    string expected_file;
    string layers_hex;

    always #5 clk = ~clk;

    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0040_0000),
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
        .result_score(result_score), .model_cache_hit(model_cache_hit),
        .model_cache_valid(model_cache_valid), .model_load_count(model_load_count),
        .model_load_beats(model_load_beats), .axi_araddr(axi_araddr), .axi_arid(axi_arid),
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
            model_ar_count <= 0;
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
                if (axi_araddr >= MODEL_ADDR - DDR_BASE &&
                    axi_araddr < MODEL_ADDR - DDR_BASE + MODEL_BYTES)
                    model_ar_count <= model_ar_count + 1;
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

    // Compare every intermediate tensor at the layer boundary. ST_LAYER_NEXT
    // is one cycle after the final write and before the ping-pong slot flips.
    always @(negedge clk) begin
        if (rst_n && check_layers && dut.state == 6'd14) begin
            trace_layer = dut.layer_index;
            case (trace_layer)
                0: begin trace_base = 0;     trace_length = 16384; end // Conv1
                1: begin trace_base = 16384; trace_length = 4096;  end // Pool1
                2: begin trace_base = 20480; trace_length = 8192;  end // Conv2
                3: begin trace_base = 28672; trace_length = 2048;  end // Pool2
                4: begin trace_base = 30720; trace_length = 4096;  end // Conv3
                5: begin trace_base = 34816; trace_length = 1024;  end // Pool3
                6: begin trace_base = 35840; trace_length = 1024;  end // Conv4
                7: begin trace_base = 36864; trace_length = 64;    end // GAP
                8: begin trace_base = 36928; trace_length = 44;    end // FC logits
                default: $fatal(1, "unexpected layer boundary %0d", trace_layer);
            endcase
            for (trace_byte = 0; trace_byte < trace_length; trace_byte = trace_byte + 1) begin
                if (trace_layer == 8)
                    observed_byte = dut.fc_output_mem[trace_byte / 4] >> ((trace_byte % 4) * 8);
                else if (dut.tensor_active == 0)
                    observed_byte = dut.tensor_b[trace_byte];
                else
                    observed_byte = dut.tensor_a[trace_byte];
                if (observed_byte !== layer_expected[active_case * TRACE_BYTES_PER_ROI + trace_base + trace_byte])
                    $fatal(1, "LAYER_MISMATCH case=%0d layer=%0d byte=%0d got=%02x expected=%02x",
                           active_case, trace_layer, trace_byte, observed_byte,
                           layer_expected[active_case * TRACE_BYTES_PER_ROI + trace_base + trace_byte]);
            end
            layer_check_count = layer_check_count + 1;
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
            case_start_cycle = cycle_count;
            active_case = case_index;
            input_addr = INPUT_ADDR + case_index * SRC_BYTES;
            start = 1'b1;
            @(posedge clk);
            @(negedge clk);
            start = 1'b0;
            wait_done;
            if (case_index != 0 && cycle_count - case_start_cycle > max_cached_cycles)
                max_cached_cycles = cycle_count - case_start_cycle;
            $display("ROAD_RESULT case=%0d cycles=%0d class=%0d margin=%0d reject=%0d score=%0d error=%0d", case_index, cycle_count - case_start_cycle, result_class, result_confidence, result_reject, $signed(result_score), error);
            if (error || result_class != expected_class[case_index] ||
                result_confidence != expected_margin[case_index] ||
                result_reject != expected_reject[case_index] ||
                $signed(result_score) != expected_score[case_index])
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
        check_layers = $value$plusargs("LAYERS_HEX=%s", layers_hex);
        if (check_layers)
            $readmemh(layers_hex, layer_expected);

        for (index = 0; index < MEM_BYTES; index = index + 1)
            mem[index] = 0;
        if ((MODEL_ADDR - DDR_BASE) + MODEL_BYTES > MEM_BYTES ||
            (INPUT_ADDR - DDR_BASE) + ROI_COUNT * SRC_BYTES > MEM_BYTES)
            $fatal(1, "ROAD ALL memory image exceeds test memory");
        $readmemh(model_hex, mem, MODEL_ADDR - DDR_BASE,
                  MODEL_ADDR - DDR_BASE + MODEL_BYTES - 1);
        $readmemh(inputs_hex, mem, INPUT_ADDR - DDR_BASE,
                  INPUT_ADDR - DDR_BASE + ROI_COUNT * SRC_BYTES - 1);

        expected_fd = $fopen(expected_file, "r");
        if (!expected_fd)
            $fatal(1, "cannot open EXPECTED_FILE");
        for (index = 0; index < ROI_COUNT; index = index + 1) begin
            if ($fscanf(expected_fd, "%d %d %d %d\n", expected_class[index],
                        expected_margin[index], expected_reject[index],
                        expected_score[index]) != 4)
                $fatal(1, "expected file ended at case=%0d", index);
        end
        if ($fscanf(expected_fd, "%d", expected_extra) == 1)
            $fatal(1, "expected file has more than %0d cases", ROI_COUNT);
        $fclose(expected_fd);

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        max_cached_cycles = 0;
        active_case = -1;
        layer_check_count = 0;
        for (index = 0; index < ROI_COUNT; index = index + 1)
            run_case(index);

        if (model_ar_count != MODEL_BURSTS || model_load_count != 1 ||
            model_load_beats != MODEL_BYTES / 32 || !model_cache_valid)
            $fatal(1, "MODEL_CACHE_FAIL ar=%0d loads=%0d beats=%0d valid=%0d",
                   model_ar_count, model_load_count, model_load_beats, model_cache_valid);
        if (ROI_COUNT > 1 && max_cached_cycles > FIRST_VERSION_CYCLE_LIMIT)
            $fatal(1, "NPU_THROUGHPUT_FAIL cycles=%0d limit=%0d",
                   max_cached_cycles, FIRST_VERSION_CYCLE_LIMIT);
        if (check_layers && layer_check_count != ROI_COUNT * 9)
            $fatal(1, "LAYER_CHECK_COUNT_FAIL got=%0d expected=%0d",
                   layer_check_count, ROI_COUNT * 9);

        $display("NPU_ROAD_V03_PASS cases=%0d src_bytes=%0d layer_checks=%0d max_cached_cycles=%0d limit=%0d", ROI_COUNT, SRC_BYTES, layer_check_count, max_cached_cycles, FIRST_VERSION_CYCLE_LIMIT);
        $finish;
    end
endmodule
