`timescale 1ns / 1ps

module tb_spi_flash_byte_reader;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst_n = 1'b0;
    reg req_valid = 1'b0;
    wire req_ready;
    reg [23:0] req_addr = 24'd0;
    reg [31:0] req_length = 32'd0;
    reg abort = 1'b0;
    wire rsp_valid;
    reg rsp_ready = 1'b0;
    wire [7:0] rsp_data;
    wire spi_sck;
    wire spi_cs_n;
    wire spi_mosi;
    wire spi_miso;

    spi_flash_byte_reader #(.CLK_DIV(3)) dut (
        .clk(clk), .rst_n(rst_n), .req_valid(req_valid), .req_ready(req_ready),
        .req_addr(req_addr), .req_length(req_length), .abort(abort),
        .rsp_valid(rsp_valid), .rsp_ready(rsp_ready), .rsp_data(rsp_data),
        .spi_sck(spi_sck), .spi_cs_n(spi_cs_n), .spi_mosi(spi_mosi), .spi_miso(spi_miso)
    );

    reg miso_drive = 1'b0;
    assign spi_miso = miso_drive;
    reg [31:0] tx_bits = 32'd0;
    integer tx_count = 0;
    integer data_bits = 0;
    integer stream_bytes = 0;
    integer transactions = 0;
    integer completed_transactions = 0;
    integer abort_transactions = 0;
    integer rising_edges = 0;
    integer expected_stream_bytes = 0;
    reg [23:0] decoded_addr = 24'd0;
    reg [7:0] decoded_opcode = 8'd0;
    reg transaction_active = 1'b0;

    function [7:0] flash_value;
        input [23:0] addr;
        begin flash_value = addr[7:0] ^ addr[15:8] ^ addr[23:16] ^ 8'hA5; end
    endfunction

    wire [23:0] model_addr = decoded_addr + stream_bytes[23:0];
    wire [7:0] model_byte = flash_value(model_addr);

    always @(negedge spi_cs_n) begin
        if (rst_n) begin
            if (spi_sck !== 1'b0) $fatal(1, "CS asserted while SCK was not low");
            tx_bits = 32'd0;
            tx_count = 0;
            data_bits = 0;
            stream_bytes = 0;
            decoded_addr = 24'd0;
            decoded_opcode = 8'd0;
            transaction_active = 1'b1;
            transactions = transactions + 1;
            miso_drive = 1'b0;
        end
    end

    always @(posedge spi_sck) begin
        if (spi_cs_n !== 1'b0) $fatal(1, "SCK rose while CS high");
        rising_edges = rising_edges + 1;
        if (tx_count < 32) begin
            tx_bits = {tx_bits[30:0], spi_mosi};
            tx_count = tx_count + 1;
            if (tx_count == 32) begin
                decoded_opcode = tx_bits[31:24];
                decoded_addr = tx_bits[23:0];
                if (decoded_opcode !== 8'h03) $fatal(1, "expected 03h, got %02x", decoded_opcode);
            end
        end else begin
            data_bits = data_bits + 1;
            if (data_bits == 8) begin
                data_bits = 0;
                stream_bytes = stream_bytes + 1;
            end
        end
    end

    always @(negedge spi_sck) begin
        if (spi_cs_n === 1'b0 && transaction_active && tx_count == 32)
            miso_drive = model_byte[7-data_bits];
    end

    always @(posedge spi_cs_n) begin
        if (transaction_active) begin
            if (spi_sck !== 1'b0) $fatal(1, "CS released while SCK was high");
            if (tx_count == 32 && stream_bytes == expected_stream_bytes && data_bits == 0)
                completed_transactions = completed_transactions + 1;
            else
                abort_transactions = abort_transactions + 1;
            transaction_active = 1'b0;
            miso_drive = 1'b0;
        end
    end

    task start_request;
        input [23:0] addr;
        input [31:0] length;
        begin
            @(negedge clk);
            req_addr = addr;
            req_length = length;
            expected_stream_bytes = length;
            req_valid = 1'b1;
            #1;
            if (!req_ready) $fatal(1, "valid request was not ready at start");
            @(posedge clk);
            @(negedge clk);
            req_valid = 1'b0;
        end
    endtask

    task consume_expected;
        input [23:0] addr;
        input integer stall_cycles;
        reg [7:0] held_data;
        reg old_sck;
        integer n;
        begin
            while (!rsp_valid) @(negedge clk);
            held_data = rsp_data;
            if (held_data !== flash_value(addr))
                $fatal(1, "read %06x returned %02x expected %02x", addr, held_data, flash_value(addr));
            old_sck = spi_sck;
            for (n = 0; n < stall_cycles; n = n + 1) begin
                @(posedge clk); #1;
                if (!rsp_valid || rsp_data !== held_data || spi_sck !== old_sck)
                    $fatal(1, "response/SCK changed under backpressure");
                if (spi_cs_n !== 1'b0)
                    $fatal(1, "CS unexpectedly released before stream handshake");
            end
            rsp_ready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            rsp_ready = 1'b0;
        end
    endtask

    integer i;
    integer edges_before_abort;
    reg [23:0] check_addr;
    initial begin
        repeat (4) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;

        // Invalid lengths and a 24-bit address overflow must not start clocks.
        @(negedge clk); req_addr = 24'hA00000; req_length = 0; req_valid = 1'b1;
        repeat (3) begin @(posedge clk); #1; if (req_ready || !spi_cs_n || spi_sck) $fatal(1, "accepted zero length"); end
        @(negedge clk); req_addr = 24'hFFFFFE; req_length = 4;
        repeat (3) begin @(posedge clk); #1; if (req_ready || !spi_cs_n || spi_sck) $fatal(1, "accepted overflowing request"); end
        @(negedge clk); req_valid = 1'b0;

        // One continuous 6-byte transaction crosses the 256-byte page edge.
        start_request(24'hA000FE, 6);
        for (i = 0; i < 6; i = i + 1) begin
            check_addr = 24'hA000FE + i[23:0];
            consume_expected(check_addr, (i == 1) ? 24 : 2);
        end
        wait (spi_cs_n === 1'b1);
        if (transactions != 1 || completed_transactions != 1 || abort_transactions != 0)
            $fatal(1, "expected one completed CS transaction, got total=%0d complete=%0d abort=%0d", transactions, completed_transactions, abort_transactions);
        if (rising_edges != 32 + 8*6)
            $fatal(1, "expected 80 SCK rising edges, got %0d", rising_edges);

        // A one-clock abort pulse during the high SCK phase must release CS
        // after that falling edge and must not allow a later rising edge.
        start_request(24'hA00100, 20);
        do @(negedge clk); while (spi_sck !== 1'b1);
        edges_before_abort = rising_edges;
        abort = 1'b1;
        @(negedge clk); abort = 1'b0;
        wait (spi_cs_n === 1'b1);
        if (rising_edges != edges_before_abort)
            $fatal(1, "abort permitted an additional rising edge");
        repeat (20) @(posedge clk);
        if (spi_sck || !spi_cs_n || rising_edges != edges_before_abort)
            $fatal(1, "abort did not leave pins idle without another rising edge");

        // Reset also cancels a transfer; a clean request can immediately retry.
        start_request(24'hA00120, 2);
        repeat (5) @(posedge spi_sck);
        @(negedge clk); rst_n = 1'b0;
        #1;
        if (spi_cs_n !== 1'b1 || spi_sck !== 1'b0 || rsp_valid !== 1'b0)
            $fatal(1, "reset did not restore idle pins");
        req_valid = 1'b0; rsp_ready = 1'b0;
        repeat (3) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;
        start_request(24'hA00120, 2);
        consume_expected(24'hA00120, 0);
        consume_expected(24'hA00121, 0);
        wait (spi_cs_n === 1'b1);
        if (transactions != 4 || completed_transactions != 2 || abort_transactions != 2)
            $fatal(1, "unexpected transaction counts total=%0d complete=%0d abort=%0d", transactions, completed_transactions, abort_transactions);
        $display("PASS: SPI stream command once, page crossing, backpressure, abort, reset/retry");
        $finish;
    end

    initial begin #4000000; $fatal(1, "testbench timeout"); end
endmodule
