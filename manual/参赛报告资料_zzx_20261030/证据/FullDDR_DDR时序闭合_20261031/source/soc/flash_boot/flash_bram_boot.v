`timescale 1ns / 1ps

// Loads a raw byte image from SPI NOR into the CPU's on-chip IRAM/DRAM window.
// The image has no header: each group of four Flash bytes becomes one
// little-endian 32-bit word, then is read back before the next word is loaded.
module flash_bram_boot #(
    parameter [23:0] FLASH_BASE = 24'hA00000,
    parameter [31:0] IMAGE_BYTES = 32'd32768,
    parameter [31:0] MEM_BASE = 32'h8000_0000,
    parameter [31:0] MEM_BYTES = 32'd49152,
    parameter integer SPI_CLK_DIV = 4,
    parameter integer TIMEOUT_CYCLES = 100000
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire        flash_cs_n,
    output wire        flash_cs2_n,
    output wire        flash_mosi,
    input  wire        flash_miso,
    output wire        flash_wp_n,
    output wire        flash_hold_n,
    output wire        flash_sck,

    output wire        prog_valid,
    output wire        prog_write,
    output wire [31:0] prog_addr,
    output wire [31:0] prog_wdata,
    output wire [3:0]  prog_wstrb,
    input  wire        prog_ready,
    input  wire [31:0] prog_rdata,

    output reg         boot_done,
    output reg         boot_error,
    output reg  [3:0]  boot_error_code,
    output reg         flash_clk_enable
);
    localparam [3:0] ERR_IMAGE_CONFIG  = 4'd1;
    localparam [3:0] ERR_READER_START  = 4'd2;
    localparam [3:0] ERR_FLASH_TIMEOUT = 4'd3;
    localparam [3:0] ERR_WRITE_TIMEOUT = 4'd4;
    localparam [3:0] ERR_READ_TIMEOUT  = 4'd5;
    localparam [3:0] ERR_VERIFY        = 4'd6;

    localparam [3:0] ST_VALIDATE = 4'd0;
    localparam [3:0] ST_START    = 4'd1;
    localparam [3:0] ST_STREAM   = 4'd2;
    localparam [3:0] ST_WRITE    = 4'd3;
    localparam [3:0] ST_READ     = 4'd4;
    localparam [3:0] ST_VERIFY   = 4'd5;
    localparam [3:0] ST_DONE     = 4'd6;
    localparam [3:0] ST_ERROR    = 4'd7;

    reg [3:0] state;
    reg [31:0] timeout_count;
    reg [31:0] byte_count;
    reg [31:0] word_index;
    reg [31:0] word_data;
    reg [31:0] expected_data;
    reg [31:0] reader_req_length;
    reg reader_req_valid;
    wire reader_req_ready;
    wire reader_rsp_valid;
    wire [7:0] reader_rsp_data;
    wire reader_rsp_ready;
    wire spi_sck;
    wire spi_cs_n;
    wire spi_mosi;
    wire reader_abort = (state == ST_ERROR) || !rst_n;

    wire [32:0] image_end = {9'd0, FLASH_BASE} + {1'b0, IMAGE_BYTES};
    wire [32:0] memory_end = {1'b0, MEM_BASE} + {1'b0, MEM_BYTES};
    wire image_config_valid = (IMAGE_BYTES != 0) &&
                              (IMAGE_BYTES[1:0] == 2'b00) &&
                              (IMAGE_BYTES <= MEM_BYTES) &&
                              (image_end <= 33'h1_000000) &&
                              (memory_end <= 33'h1_0000_0000);

    assign prog_valid = (state == ST_WRITE) || (state == ST_READ);
    assign prog_write = (state == ST_WRITE);
    assign prog_addr = MEM_BASE + (word_index << 2);
    assign prog_wdata = expected_data;
    assign prog_wstrb = 4'hf;
    assign reader_rsp_ready = (state == ST_STREAM);

    spi_flash_byte_reader #(.CLK_DIV(SPI_CLK_DIV)) u_flash_reader (
        .clk(clk), .rst_n(rst_n),
        .req_valid(reader_req_valid), .req_ready(reader_req_ready),
        .req_addr(FLASH_BASE), .req_length(reader_req_length),
        .abort(reader_abort), .rsp_valid(reader_rsp_valid),
        .rsp_ready(reader_rsp_ready), .rsp_data(reader_rsp_data),
        .spi_sck(spi_sck), .spi_cs_n(spi_cs_n), .spi_mosi(spi_mosi),
        .spi_miso(flash_miso)
    );

    // Gate the dedicated configuration clock only when the serial bus is
    // idle, so an error cannot truncate a high SCK phase.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flash_clk_enable <= 1'b0;
        else if (!boot_error && !boot_done)
            flash_clk_enable <= 1'b1;
        else if (spi_cs_n && !spi_sck)
            flash_clk_enable <= 1'b0;
    end

    assign flash_cs_n = spi_cs_n;
    assign flash_cs2_n = 1'b1;
    assign flash_mosi = spi_mosi;
    assign flash_wp_n = 1'b1;
    assign flash_hold_n = 1'b1;
    assign flash_sck = spi_sck;

    task fail;
        input [3:0] code;
        begin
            boot_error <= 1'b1;
            boot_error_code <= code;
            state <= ST_ERROR;
            timeout_count <= 32'd0;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_VALIDATE;
            timeout_count <= 32'd0;
            byte_count <= 32'd0;
            word_index <= 32'd0;
            word_data <= 32'd0;
            expected_data <= 32'd0;
            reader_req_length <= IMAGE_BYTES;
            reader_req_valid <= 1'b0;
            boot_done <= 1'b0;
            boot_error <= 1'b0;
            boot_error_code <= 4'd0;
        end else begin
            case (state)
                ST_VALIDATE: begin
                    timeout_count <= 32'd0;
                    if (!image_config_valid) begin
                        fail(ERR_IMAGE_CONFIG);
                    end else begin
                        reader_req_valid <= 1'b1;
                        state <= ST_START;
                    end
                end

                ST_START: begin
                    if (reader_req_valid && reader_req_ready) begin
                        reader_req_valid <= 1'b0;
                        timeout_count <= 32'd0;
                        state <= ST_STREAM;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1) begin
                        fail(ERR_READER_START);
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_STREAM: begin
                    if (reader_rsp_valid) begin
                        timeout_count <= 32'd0;
                        byte_count <= byte_count + 1'b1;
                        case (byte_count[1:0])
                            2'd0: word_data[7:0]   <= reader_rsp_data;
                            2'd1: word_data[15:8]  <= reader_rsp_data;
                            2'd2: word_data[23:16] <= reader_rsp_data;
                            2'd3: begin
                                expected_data <= {reader_rsp_data, word_data[23:0]};
                                state <= ST_WRITE;
                            end
                        endcase
                    end else if (timeout_count >= TIMEOUT_CYCLES-1) begin
                        fail(ERR_FLASH_TIMEOUT);
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_WRITE: begin
                    if (prog_ready) begin
                        timeout_count <= 32'd0;
                        state <= ST_READ;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1) begin
                        fail(ERR_WRITE_TIMEOUT);
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_READ: begin
                    if (prog_ready) begin
                        timeout_count <= 32'd0;
                        state <= ST_VERIFY;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1) begin
                        fail(ERR_READ_TIMEOUT);
                    end else begin
                        timeout_count <= timeout_count + 1'b1;
                    end
                end

                ST_VERIFY: begin
                    if (prog_rdata != expected_data) begin
                        fail(ERR_VERIFY);
                    end else if (word_index == (IMAGE_BYTES >> 2) - 1'b1) begin
                        boot_done <= 1'b1;
                        state <= ST_DONE;
                    end else begin
                        word_index <= word_index + 1'b1;
                        state <= ST_STREAM;
                    end
                end

                ST_DONE: begin
                    boot_done <= 1'b1;
                end

                ST_ERROR: begin
                    boot_error <= 1'b1;
                end

                default: fail(ERR_IMAGE_CONFIG);
            endcase
        end
    end
endmodule
