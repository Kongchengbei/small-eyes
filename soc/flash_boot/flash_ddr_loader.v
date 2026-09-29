`timescale 1ns / 1ps

//负责搬运和校验
//它先等待 DDR 初始化完成，再发起一次连续 Flash 读取。每收到四个字节，就组成一个小端的 32 位数据。
module flash_ddr_loader #(
    parameter [23:0] FLASH_BASE = 24'hA00000,
    parameter [31:0] DDR_BASE   = 32'h8000_0000,
    parameter [32:0] DDR_LIMIT  = 33'h0_c000_0000,
    parameter [31:0] IMAGE_BYTES = 32'd4,
    parameter integer TIMEOUT_CYCLES = 100000,
    // Keep legacy testbench behavior unless integration sets a longer DDR
    // training allowance explicitly.
    parameter integer DDR_INIT_TIMEOUT_CYCLES = TIMEOUT_CYCLES
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ddr_init_done,

    output reg         flash_req_valid,
    input  wire        flash_req_ready,
    output wire [23:0] flash_req_addr,
    output wire [31:0] flash_req_length,
    input  wire        flash_rsp_valid,
    output wire        flash_rsp_ready,
    input  wire [7:0]  flash_rsp_data,

    output reg         ddr_req_valid,
    input  wire        ddr_req_ready,
    output reg         ddr_req_write,
    output reg  [31:0] ddr_req_addr,
    output reg  [31:0] ddr_req_wdata,
    output wire [3:0]  ddr_req_wstrb,
    input  wire        ddr_rsp_valid,
    output wire        ddr_rsp_ready,
    input  wire        ddr_rsp_is_read,
    input  wire [31:0] ddr_rsp_rdata,

    output reg         boot_done,
    output reg         boot_error,
    output reg  [3:0]  error_code,
    output wire        busy
);
    localparam [3:0] ERR_BAD_CONFIG = 4'd1;
    localparam [3:0] ERR_DDR_INIT   = 4'd2;
    localparam [3:0] ERR_FLASH_TO   = 4'd3;
    localparam [3:0] ERR_DDR_TO     = 4'd4;
    localparam [3:0] ERR_DDR_KIND   = 4'd5;
    localparam [3:0] ERR_READBACK   = 4'd6;

    localparam [3:0] ST_WAIT_DDR = 4'd0;
    localparam [3:0] ST_FLASH_REQ = 4'd1;
    localparam [3:0] ST_FLASH_RSP = 4'd2;
    localparam [3:0] ST_DDR_WRITE = 4'd3;
    localparam [3:0] ST_DDR_WRITE_RSP = 4'd4;
    localparam [3:0] ST_DDR_READ = 4'd5;
    localparam [3:0] ST_DDR_READ_RSP = 4'd6;
    localparam [3:0] ST_DONE = 4'd7;
    localparam [3:0] ST_ERROR = 4'd8;

    reg [3:0] state;
    reg [31:0] byte_index;
    reg [1:0] byte_lane;
    reg [23:0] word_buffer;
    reg [31:0] expected_word;
    reg [31:0] timeout_count;
    wire [32:0] flash_end_exclusive = {9'd0, FLASH_BASE} + {1'b0, IMAGE_BYTES};
    wire [32:0] ddr_end_exclusive = {1'b0, DDR_BASE} + {1'b0, IMAGE_BYTES};

    assign flash_req_addr = FLASH_BASE;
    assign flash_req_length = IMAGE_BYTES;
    assign flash_rsp_ready = (state == ST_FLASH_RSP);
    assign ddr_req_wstrb = 4'b1111;
    assign ddr_rsp_ready = (state == ST_DDR_WRITE_RSP) ||
                           (state == ST_DDR_READ_RSP);
    assign busy = (state != ST_DONE) && (state != ST_ERROR);
	//统一处理启动失败
    task fail;
        input [3:0] code;
        begin
            boot_done <= 1'b0;
            boot_error <= 1'b1;
            error_code <= code;
            state <= ST_ERROR;
        end
    endtask

    always @(*) begin
        flash_req_valid = (state == ST_FLASH_REQ);
        ddr_req_valid = (state == ST_DDR_WRITE) ||
                        (state == ST_DDR_READ);
        ddr_req_write = (state == ST_DDR_WRITE);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_WAIT_DDR;
            byte_index <= 32'd0;
            byte_lane <= 2'd0;
            word_buffer <= 24'd0;
            expected_word <= 32'd0;
            timeout_count <= 32'd0;
            ddr_req_addr <= DDR_BASE;
            ddr_req_wdata <= 32'd0;
            boot_done <= 1'b0;
            boot_error <= 1'b0;
            error_code <= 4'd0;
        end else begin
			//一旦初始DDR训练完成，任何后续的损失意味着
			//加载的图像不再可信,需要执行系统重置以重新运行复制。
            if ((state != ST_WAIT_DDR) && (state != ST_ERROR) &&
                !ddr_init_done) begin
                fail(ERR_DDR_INIT);
            end else case (state)
                ST_WAIT_DDR: begin
                    if ((IMAGE_BYTES == 0) || (IMAGE_BYTES[1:0] != 0) ||
                        (DDR_BASE[1:0] != 0) ||
                        (flash_end_exclusive > 33'h1_000000) ||
                        (ddr_end_exclusive > 33'h1_00000000) ||
                        (ddr_end_exclusive > DDR_LIMIT) ||
                        (TIMEOUT_CYCLES < 1) ||
                        (DDR_INIT_TIMEOUT_CYCLES < 1))
                        fail(ERR_BAD_CONFIG);
                    else if (ddr_init_done) begin
                        timeout_count <= 32'd0;
                        state <= ST_FLASH_REQ;
                    end else if (timeout_count >= DDR_INIT_TIMEOUT_CYCLES-1)
                        fail(ERR_DDR_INIT);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_FLASH_REQ: begin
                    if (flash_req_ready) begin
                        timeout_count <= 32'd0;
                        state <= ST_FLASH_RSP;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1)
                        fail(ERR_FLASH_TO);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_FLASH_RSP: begin
                    if (flash_rsp_valid) begin
                        timeout_count <= 32'd0;
                        case (byte_lane)
                            2'd0: word_buffer[7:0]   <= flash_rsp_data;
                            2'd1: word_buffer[15:8]  <= flash_rsp_data;
                            2'd2: word_buffer[23:16] <= flash_rsp_data;
                            2'd3: begin
                                expected_word <= {flash_rsp_data,
                                                  word_buffer[23:0]};
                                ddr_req_addr <= DDR_BASE + byte_index - 3;
                                ddr_req_wdata <= {flash_rsp_data,
                                                  word_buffer[23:0]};
                            end
                        endcase
                        byte_index <= byte_index + 1'b1;
                        if (byte_lane == 2'd3)
                            state <= ST_DDR_WRITE;
                        else begin
                            byte_lane <= byte_lane + 1'b1;
                            state <= ST_FLASH_RSP;
                        end
                    end else if (timeout_count >= TIMEOUT_CYCLES-1)
                        fail(ERR_FLASH_TO);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_DDR_WRITE: begin
                    if (ddr_req_ready) begin
                        timeout_count <= 32'd0;
                        state <= ST_DDR_WRITE_RSP;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1)
                        fail(ERR_DDR_TO);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_DDR_WRITE_RSP: begin
                    if (ddr_rsp_valid) begin
                        timeout_count <= 32'd0;
                        if (ddr_rsp_is_read)
                            fail(ERR_DDR_KIND);
                        else
                            state <= ST_DDR_READ;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1)
                        fail(ERR_DDR_TO);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_DDR_READ: begin
                    if (ddr_req_ready) begin
                        timeout_count <= 32'd0;
                        state <= ST_DDR_READ_RSP;
                    end else if (timeout_count >= TIMEOUT_CYCLES-1)
                        fail(ERR_DDR_TO);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_DDR_READ_RSP: begin
                    if (ddr_rsp_valid) begin
                        timeout_count <= 32'd0;
                        if (!ddr_rsp_is_read)
                            fail(ERR_DDR_KIND);
                        else if (ddr_rsp_rdata != expected_word)
                            fail(ERR_READBACK);
                        else if (byte_index == IMAGE_BYTES) begin
                            boot_done <= 1'b1;
                            state <= ST_DONE;
                        end else begin
                            byte_lane <= 2'd0;
                            state <= ST_FLASH_RSP;
                        end
                    end else if (timeout_count >= TIMEOUT_CYCLES-1)
                        fail(ERR_DDR_TO);
                    else
                        timeout_count <= timeout_count + 1'b1;
                end

                ST_DONE: begin end
                ST_ERROR: begin end
                default: fail(ERR_BAD_CONFIG);
            endcase
        end
    end
endmodule
