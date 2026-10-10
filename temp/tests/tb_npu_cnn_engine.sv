`timescale 1ns / 1ps

module tb_npu_cnn_engine;
    localparam [31:0] DDR_BASE = 32'h8000_0000;
    localparam [31:0] MODEL_ADDR = 32'h8000_1000;
    localparam [31:0] INPUT_ADDR = 32'h8000_2000;
    localparam integer MODEL_BYTES = 640;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg start = 1'b0;
    reg clear_error = 1'b0;
    reg [31:0] model_base = MODEL_ADDR;
    reg [31:0] model_bytes = MODEL_BYTES;
    reg [31:0] input_addr = INPUT_ADDR;
    reg [31:0] input_bytes = 32;
    reg [31:0] input_source_bytes = 32;
    reg input_downsample3 = 1'b0;

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

    reg [7:0] mem [0:65535];
    reg rd_active;
    reg [29:0] rd_addr;
    reg [8:0] rd_left;
    reg [7:0] rd_id;
    integer cycle_count;
    integer lane;
    integer index;
    integer timeout;
    integer model_offset;
    integer input_offset;
    string model_hex;
    string case_name;
    reg inject_rresp;
    reg inject_rid;
    reg inject_bad_rlast;

    always #5 clk = ~clk;

    Hnpu_cnn_engine #(
        .DDR_BASE(DDR_BASE), .DDR_BYTES(32'h0001_0000),
        .MAX_MODEL_BYTES(65536), .MAX_TENSOR_BYTES(16384),
        .MAX_LAYERS(16), .MAX_CLASSES(16)
    ) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .clear_error(clear_error),
        .model_base(model_base), .model_bytes(model_bytes),
        .input_addr(input_addr), .input_bytes(input_bytes),
        .input_source_bytes(input_source_bytes), .input_downsample3(input_downsample3),
        .busy(busy), .done_pulse(done_pulse), .error(error),
        .error_code(error_code), .result_class(result_class),
        .result_confidence(result_confidence), .result_score(result_score),
        .axi_araddr(axi_araddr), .axi_arid(axi_arid), .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize), .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid), .axi_arready(axi_arready),
        .axi_rdata(axi_rdata), .axi_rid(axi_rid), .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast), .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready)
    );

    function [31:0] crc32_byte;
        input [31:0] crc;
        input [7:0] data;
        reg [31:0] c;
        integer bit_index;
        begin
            c = crc ^ data;
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                c = c[0] ? ((c >> 1) ^ 32'hedb8_8320) : (c >> 1);
            crc32_byte = c;
        end
    endfunction

    task recompute_payload_crc;
        reg [31:0] crc;
        integer offset;
        begin
            crc = 32'hffff_ffff;
            for (offset = 128; offset < MODEL_BYTES; offset = offset + 1)
                crc = crc32_byte(crc, mem[model_offset + offset]);
            crc = ~crc;
            mem[model_offset + 64] = crc[7:0];
            mem[model_offset + 65] = crc[15:8];
            mem[model_offset + 66] = crc[23:16];
            mem[model_offset + 67] = crc[31:24];
        end
    endtask

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
                    $fatal(1, "CNN AXI metadata mismatch");
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
                axi_rid <= inject_rid ? 8'h81 : rd_id;
                axi_rresp <= inject_rresp ? 2'b10 : 2'b00;
                axi_rlast <= inject_bad_rlast ? 1'b0 : (rd_left == 1);
                axi_rvalid <= 1'b1;
            end
        end
    end

    task wait_done;
        begin : wait_loop
            for (timeout = 0; timeout < 10000; timeout = timeout + 1) begin
                @(posedge clk);
                if (done_pulse)
                    disable wait_loop;
            end
            $fatal(1, "CNN engine timeout case=%s state=%0d", case_name, dut.state);
        end
    endtask

    initial begin
        if (!$value$plusargs("MODEL_HEX=%s", model_hex))
            $fatal(1, "MODEL_HEX is required");
        if (!$value$plusargs("CASE=%s", case_name))
            case_name = "valid";

        for (index = 0; index < 65536; index = index + 1)
            mem[index] = 0;
        $readmemh(model_hex, mem, 0, MODEL_BYTES - 1);
        model_offset = MODEL_ADDR - DDR_BASE;
        input_offset = INPUT_ADDR - DDR_BASE;
        for (index = 0; index < MODEL_BYTES; index = index + 1)
            mem[model_offset + index] = mem[index];

        // CHW input: 1..16 followed by the 16-byte DMA padding.
        for (index = 0; index < 16; index = index + 1)
            mem[input_offset + index] = index + 1;
        for (index = 16; index < 32; index = index + 1)
            mem[input_offset + index] = 0;

        if (case_name == "bad_magic")
            mem[model_offset] = mem[model_offset] ^ 8'h01;
        else if (case_name == "bad_crc")
            mem[model_offset + 128] = mem[model_offset + 128] ^ 8'h01;
        else if (case_name == "bad_version") begin
            mem[model_offset + 4] = 8'h02;
        end else if (case_name == "bad_descriptor") begin
            mem[model_offset + 28] = 8'd64;
        end else if (case_name == "unknown_op") begin
            mem[model_offset + 128] = 8'h7f;
            recompute_payload_crc;
        end else if (case_name == "bad_shape") begin
            mem[model_offset + 128 + 8] = 8'h03;
            recompute_payload_crc;
        end else if (case_name == "weight_section") begin
            // Point the first CONV weight descriptor at the header.  The
            // package CRC is valid, so this exercises section-bound checking.
            mem[model_offset + 128 + 32] = 8'h00;
            mem[model_offset + 128 + 33] = 8'h00;
            mem[model_offset + 128 + 34] = 8'h00;
            mem[model_offset + 128 + 35] = 8'h00;
            recompute_payload_crc;
        end else if (case_name == "bad_rresp") begin
            inject_rresp = 1'b1;
        end else if (case_name == "bad_rid") begin
            inject_rid = 1'b1;
        end else if (case_name == "bad_rlast") begin
            inject_bad_rlast = 1'b1;
        end else if (case_name != "valid")
            $fatal(1, "unknown test case %s", case_name);

        if (case_name == "valid" || case_name == "bad_magic" ||
            case_name == "bad_crc" || case_name == "bad_version" ||
            case_name == "bad_descriptor" || case_name == "unknown_op" ||
            case_name == "bad_shape" || case_name == "weight_section") begin
            inject_rresp = 1'b0;
            inject_rid = 1'b0;
            inject_bad_rlast = 1'b0;
        end

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        @(negedge clk);
        start = 1'b0;
        wait_done;

        if (case_name == "valid") begin
            if (error || result_class != 0 || result_score != 11 ||
                result_confidence != 1)
                $fatal(1, "CNN result mismatch class=%0d score=%0d conf=%0d error=%0d",
                       result_class, result_score, result_confidence, error);
        end else if (case_name == "bad_magic") begin
            if (!error || error_code != 8'h20) $fatal(1, "bad magic not rejected code=%0d", error_code);
        end else if (case_name == "bad_crc") begin
            if (!error || error_code != 8'h23) $fatal(1, "bad CRC not rejected code=%0d", error_code);
        end else if (case_name == "bad_version") begin
            if (!error || error_code != 8'h21) $fatal(1, "bad version not rejected code=%0d", error_code);
        end else if (case_name == "bad_descriptor") begin
            if (!error || error_code != 8'h22) $fatal(1, "bad descriptor not rejected code=%0d", error_code);
        end else if (case_name == "unknown_op") begin
            if (!error || error_code != 8'h26) $fatal(1, "unknown op not rejected code=%0d", error_code);
        end else if (case_name == "bad_shape") begin
            if (!error || error_code != 8'h25) $fatal(1, "bad shape not rejected code=%0d", error_code);
        end else if (case_name == "weight_section") begin
            if (!error || error_code != 8'h25) $fatal(1, "weight section violation not rejected code=%0d", error_code);
        end else if (case_name == "bad_rresp") begin
            if (!error || error_code != 8'h02) $fatal(1, "RRESP error not detected code=%0d", error_code);
        end else if (case_name == "bad_rid") begin
            if (!error || error_code != 8'h03) $fatal(1, "RID error not detected code=%0d", error_code);
        end else if (case_name == "bad_rlast") begin
            if (!error || error_code != 8'h04) $fatal(1, "RLAST error not detected code=%0d", error_code);
        end

        $display("NPU_CNN_CASE_PASS case=%s", case_name);
        $finish;
    end
endmodule
