`timescale 1ns / 1ps

module tb_flash_ddr_model_load;
    localparam [23:0] CPU_FLASH = 24'h000000;
    localparam [23:0] MODEL_FLASH = 24'h000100;
    localparam [31:0] CPU_DDR = 32'h8000_0000;
    localparam [31:0] MODEL_DDR = 32'hb900_0000;
    localparam integer CPU_BYTES = 16;
    localparam integer MODEL_BYTES = 8;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg ddr_init_done = 1'b0;
    always #5 clk = ~clk;

    wire flash_req_valid, flash_req_ready;
    wire [23:0] flash_req_addr;
    wire [31:0] flash_req_length;
    reg flash_rsp_valid_q = 1'b0;
    reg [7:0] flash_rsp_data_q = 8'd0;
    reg flash_active = 1'b0;
    reg [23:0] flash_active_addr = 24'd0;
    reg [31:0] flash_index = 32'd0;
    wire flash_rsp_valid, flash_rsp_ready;
    wire [7:0] flash_rsp_data;
    assign flash_req_ready = !flash_active;
    assign flash_rsp_valid = flash_rsp_valid_q;
    assign flash_rsp_data = flash_rsp_data_q;

    function [7:0] flash_byte;
        input [23:0] base;
        input [31:0] index;
        begin
            if (base == CPU_FLASH) begin
                case (index)
                    0: flash_byte = 8'h10; 1: flash_byte = 8'h11;
                    2: flash_byte = 8'h12; 3: flash_byte = 8'h13;
                    4: flash_byte = 8'h20; 5: flash_byte = 8'h21;
                    6: flash_byte = 8'h22; 7: flash_byte = 8'h23;
                    8: flash_byte = 8'h30; 9: flash_byte = 8'h31;
                    10: flash_byte = 8'h32; 11: flash_byte = 8'h33;
                    12: flash_byte = 8'h40; 13: flash_byte = 8'h41;
                    14: flash_byte = 8'h42; default: flash_byte = 8'h43;
                endcase
            end else begin
                case (index)
                    0: flash_byte = 8'ha0; 1: flash_byte = 8'ha1;
                    2: flash_byte = 8'ha2; 3: flash_byte = 8'ha3;
                    4: flash_byte = 8'hb0; 5: flash_byte = 8'hb1;
                    default: flash_byte = 8'hb2;
                endcase
            end
        end
    endfunction

    wire ddr_req_valid, ddr_req_write;
    wire ddr_req_ready;
    wire [31:0] ddr_req_addr, ddr_req_wdata;
    wire [3:0] ddr_req_wstrb;
    wire ddr_rsp_valid, ddr_rsp_ready, ddr_rsp_is_read;
    reg ddr_rsp_valid_q = 1'b0;
    reg ddr_rsp_is_read_q = 1'b0;
    reg [31:0] ddr_rsp_rdata_q = 32'd0;
    wire [31:0] ddr_rsp_rdata;
    assign ddr_req_ready = 1'b1;
    assign ddr_rsp_valid = ddr_rsp_valid_q;
    assign ddr_rsp_is_read = ddr_rsp_is_read_q;
    assign ddr_rsp_rdata = ddr_rsp_rdata_q;

    reg [31:0] cpu_mem [0:3];
    reg [31:0] model_mem [0:1];
    integer cycles;
    integer i;
    wire [31:0] cpu_word = (ddr_req_addr - CPU_DDR) >> 2;
    wire [31:0] model_word = (ddr_req_addr - MODEL_DDR) >> 2;

    wire boot_done, boot_error;
    wire [3:0] error_code;
    wire busy;

    flash_ddr_loader #(
        .FLASH_BASE(CPU_FLASH), .DDR_BASE(CPU_DDR),
        .DDR_LIMIT(33'h1_0000_0000), .IMAGE_BYTES(CPU_BYTES),
        .MODEL_ENABLE(1), .MODEL_FLASH_BASE(MODEL_FLASH),
        .MODEL_DDR_BASE(MODEL_DDR), .MODEL_BYTES(MODEL_BYTES),
        .TIMEOUT_CYCLES(1000), .DDR_INIT_TIMEOUT_CYCLES(1000)
    ) dut (
        .clk(clk), .rst_n(rst_n), .ddr_init_done(ddr_init_done),
        .flash_req_valid(flash_req_valid), .flash_req_ready(flash_req_ready),
        .flash_req_addr(flash_req_addr), .flash_req_length(flash_req_length),
        .flash_rsp_valid(flash_rsp_valid), .flash_rsp_ready(flash_rsp_ready),
        .flash_rsp_data(flash_rsp_data), .ddr_req_valid(ddr_req_valid),
        .ddr_req_ready(ddr_req_ready), .ddr_req_write(ddr_req_write),
        .ddr_req_addr(ddr_req_addr), .ddr_req_wdata(ddr_req_wdata),
        .ddr_req_wstrb(ddr_req_wstrb), .ddr_rsp_valid(ddr_rsp_valid),
        .ddr_rsp_ready(ddr_rsp_ready), .ddr_rsp_is_read(ddr_rsp_is_read),
        .ddr_rsp_rdata(ddr_rsp_rdata), .boot_done(boot_done),
        .boot_error(boot_error), .error_code(error_code), .busy(busy)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            flash_rsp_valid_q <= 1'b0;
            flash_active <= 1'b0;
            flash_index <= 0;
            ddr_rsp_valid_q <= 1'b0;
        end else begin
            if (flash_req_valid && flash_req_ready) begin
                if ((flash_req_addr !== CPU_FLASH && flash_req_addr !== MODEL_FLASH) ||
                    (flash_req_addr == CPU_FLASH && flash_req_length !== CPU_BYTES) ||
                    (flash_req_addr == MODEL_FLASH && flash_req_length !== MODEL_BYTES))
                    $fatal(1, "unexpected Flash segment addr=%h len=%0d", flash_req_addr, flash_req_length);
                flash_active <= 1'b1;
                flash_active_addr <= flash_req_addr;
                flash_index <= 0;
                flash_rsp_data_q <= flash_byte(flash_req_addr, 0);
                flash_rsp_valid_q <= 1'b1;
            end else if (flash_rsp_valid_q && flash_rsp_ready) begin
                if (flash_index + 1 >= flash_req_length) begin
                    flash_active <= 1'b0;
                    flash_rsp_valid_q <= 1'b0;
                end else begin
                    flash_index <= flash_index + 1'b1;
                    flash_rsp_data_q <= flash_byte(flash_active_addr, flash_index + 1'b1);
                end
            end

            if (ddr_rsp_valid_q && ddr_rsp_ready)
                ddr_rsp_valid_q <= 1'b0;
            if (ddr_req_valid && ddr_req_ready) begin
                ddr_rsp_valid_q <= 1'b1;
                ddr_rsp_is_read_q <= !ddr_req_write;
                if (ddr_req_write) begin
                    if (ddr_req_addr >= MODEL_DDR)
                        model_mem[model_word] <= ddr_req_wdata;
                    else
                        cpu_mem[cpu_word] <= ddr_req_wdata;
                end else if (ddr_req_addr >= MODEL_DDR)
                    ddr_rsp_rdata_q <= model_mem[model_word];
                else
                    ddr_rsp_rdata_q <= cpu_mem[cpu_word];
            end
        end
    end

    initial begin
        for (i = 0; i < 4; i = i + 1) cpu_mem[i] = 0;
        for (i = 0; i < 2; i = i + 1) model_mem[i] = 0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        ddr_init_done = 1'b1;
        cycles = 0;
        while (!boot_done && !boot_error && cycles < 100000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        if (boot_error || !boot_done)
            $fatal(1, "dual-segment boot failed done=%b error=%b code=%0d", boot_done, boot_error, error_code);
        if (cpu_mem[0] !== 32'h13121110 || cpu_mem[1] !== 32'h23222120 ||
            cpu_mem[2] !== 32'h33323130 || cpu_mem[3] !== 32'h43424140 ||
            model_mem[0] !== 32'ha3a2a1a0 || model_mem[1] !== 32'hb2b2b1b0)
            $fatal(1, "dual-segment DDR contents mismatch");
        $display("FLASH_DDR_MODEL_LOAD_PASS cpu_base=%h model_base=%h", CPU_DDR, MODEL_DDR);
        $finish;
    end

    initial begin
        #2_000_000;
        $fatal(1, "dual-segment boot timeout");
    end
endmodule
