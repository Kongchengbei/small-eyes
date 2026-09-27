`timescale 1ns / 1ps

module tb_spi_flash_byte_reader;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst_n = 1'b0;
    reg req_valid = 1'b0;
    wire req_ready;
    reg [23:0] req_addr = 24'd0;
    wire rsp_valid;
    reg rsp_ready = 1'b0;
    wire [7:0] rsp_data;
    wire spi_sck;
    wire spi_cs_n;
    wire spi_mosi;
    wire spi_miso;

    spi_flash_byte_reader #(.CLK_DIV(3)) dut (
        .clk(clk), .rst_n(rst_n),
        .req_valid(req_valid), .req_ready(req_ready), .req_addr(req_addr),
        .rsp_valid(rsp_valid), .rsp_ready(rsp_ready), .rsp_data(rsp_data),
        .spi_sck(spi_sck), .spi_cs_n(spi_cs_n),
        .spi_mosi(spi_mosi), .spi_miso(spi_miso)
    );

    reg miso_drive = 1'b0;
    assign spi_miso = miso_drive;

    reg [31:0] tx_bits;
    integer tx_count;
    integer rx_count;
    integer rx_drive_index;
    integer complete_count = 0;
    integer abort_count = 0;
    reg [23:0] decoded_addr;
    reg [7:0] decoded_opcode;
    reg transaction_active = 1'b0;
    reg [23:0] completed_addrs [0:15];

    function [7:0] flash_value;
        input [23:0] addr;
        begin
            flash_value = addr[7:0] ^ addr[15:8] ^ addr[23:16] ^ 8'hA5;
        end
    endfunction

    wire [7:0] model_byte = flash_value(decoded_addr);

    // A byte-serial mode-0 Flash model. It only drives MISO after receiving
    // all 32 command/address bits and changes MISO on falling SCK edges.
    always @(negedge spi_cs_n) begin
        if (rst_n) begin
            if (spi_sck !== 1'b0)
                $fatal(1, "CS asserted while SCK was not low");
            tx_bits = 32'd0;
            tx_count = 0;
            rx_count = 0;
            rx_drive_index = 0;
            decoded_addr = 24'd0;
            decoded_opcode = 8'd0;
            transaction_active = 1'b1;
            miso_drive = 1'b0;
        end
    end

    always @(posedge spi_sck) begin
        if (spi_cs_n === 1'b0) begin
            if (tx_count < 32) begin
                tx_bits = {tx_bits[30:0], spi_mosi};
                tx_count = tx_count + 1;
                if (tx_count == 32) begin
                    decoded_opcode = tx_bits[31:24];
                    decoded_addr = tx_bits[23:0];
                    if (decoded_opcode !== 8'h03)
                        $fatal(1, "expected Read Data opcode 03, got %02x", decoded_opcode);
                end
            end else if (rx_count < 8) begin
                rx_count = rx_count + 1;
            end else begin
                $fatal(1, "more than 8 data bits clocked under one CS");
            end
        end else begin
            $fatal(1, "SCK rose while CS was high");
        end
    end

    always @(negedge spi_sck) begin
        if (spi_cs_n === 1'b0 && transaction_active && tx_count == 32 &&
            rx_drive_index < 8) begin
            miso_drive = model_byte[7-rx_drive_index];
            rx_drive_index = rx_drive_index + 1;
        end
    end

    always @(posedge spi_cs_n) begin
        if (transaction_active) begin
            if (spi_sck !== 1'b0)
                $fatal(1, "CS released while SCK was high");
            if (tx_count == 32 && rx_count == 8) begin
                if (rx_drive_index != 8)
                    $fatal(1, "Flash model drove %0d of 8 MISO bits", rx_drive_index);
                completed_addrs[complete_count] = decoded_addr;
                complete_count = complete_count + 1;
            end else begin
                abort_count = abort_count + 1;
            end
            transaction_active = 1'b0;
            miso_drive = 1'b0;
        end
    end

    task start_request;
        input [23:0] addr;
        begin
            @(negedge clk);
            req_addr = addr;
            req_valid = 1'b1;
            while (!req_ready) @(negedge clk);
            @(posedge clk);
            @(negedge clk);
            req_valid = 1'b0;
        end
    endtask

    task check_response;
        input [23:0] addr;
        input integer test_backpressure;
        reg [7:0] held_data;
        integer n;
        begin
            while (!rsp_valid) @(negedge clk);
            held_data = rsp_data;
            if (held_data !== flash_value(addr))
                $fatal(1, "read %06x returned %02x, expected %02x",
                       addr, held_data, flash_value(addr));
            if (spi_cs_n !== 1'b1 || spi_sck !== 1'b0)
                $fatal(1, "response asserted before CS high/SCK low");
            if (test_backpressure != 0) begin
                req_addr = 24'h654321;
                req_valid = 1'b1;
                for (n = 0; n < 4; n = n + 1) begin
                    @(posedge clk);
                    #1;
                    if (!rsp_valid || rsp_data !== held_data)
                        $fatal(1, "response changed under backpressure");
                    if (req_ready !== 1'b0)
                        $fatal(1, "accepted a new request while response stalled");
                    if (spi_cs_n !== 1'b1 || spi_sck !== 1'b0)
                        $fatal(1, "SPI pins changed while response stalled");
                end
                @(negedge clk);
                req_valid = 1'b0;
            end
            rsp_ready = 1'b1;
            @(posedge clk);
            @(negedge clk);
            rsp_ready = 1'b0;
            if (rsp_valid !== 1'b0)
                $fatal(1, "response did not retire after handshake");
        end
    endtask

    integer i;
    initial begin
        repeat (4) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        start_request(24'hA00000);
        check_response(24'hA00000, 1);
        start_request(24'hA00001);
        check_response(24'hA00001, 0);
        start_request(24'hA000FF);
        check_response(24'hA000FF, 0);
        start_request(24'h123456);
        check_response(24'h123456, 0);

        // Interrupt a live serial transfer with reset, then prove that a new
        // request starts cleanly and returns the actual modeled Flash byte.
        start_request(24'hA00002);
        repeat (9) @(posedge spi_sck);
        @(negedge clk);
        rst_n = 1'b0;
        #1;
        if (spi_cs_n !== 1'b1 || spi_sck !== 1'b0 || rsp_valid !== 1'b0)
            $fatal(1, "reset did not abort transfer and restore idle pins");
        req_valid = 1'b0;
        rsp_ready = 1'b0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        start_request(24'hA00002);
        check_response(24'hA00002, 0);

        if (complete_count != 5)
            $fatal(1, "expected 5 completed serial reads, saw %0d", complete_count);
        if (abort_count != 1)
            $fatal(1, "expected one reset-aborted transaction, saw %0d", abort_count);
        if (completed_addrs[0] !== 24'hA00000 ||
            completed_addrs[1] !== 24'hA00001 ||
            completed_addrs[2] !== 24'hA000FF ||
            completed_addrs[3] !== 24'h123456 ||
            completed_addrs[4] !== 24'hA00002)
            $fatal(1, "Flash model observed incorrect address sequence");

        $display("PASS: SPI byte reader serial protocol, flow control, reset and recovery");
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "testbench timeout");
    end
endmodule
