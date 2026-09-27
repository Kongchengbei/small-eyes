`timescale 1ns / 1ps

//负责连接和通道切换
/*它将 reader 和 loader 接起来，并处理:
将 ddr_init_done 同步到 CPU 时钟域
控制 Flash 配置时钟的使能
搬运期间，让 loader 独占 DDR 请求通道
校验完成后，把 DDR 通道交给 CPU backend
失败时屏蔽请求，等待系统复位
*/
//它输出启动状态，真正保持或释放 CPU 复位的逻辑在 Hfpga_soc.v 中
module flash_ddr_boot #(
    parameter [23:0] FLASH_BASE = 24'hA00000,
    parameter [31:0] DDR_BASE = 32'h8000_0000,
    parameter [32:0] DDR_LIMIT = 33'h0_C000_0000,//0xBFFFFFFF
    parameter [31:0] IMAGE_BYTES = 32'd56,
    parameter integer SPI_CLK_DIV = 4,
    parameter integer TIMEOUT_CYCLES = 100000,
    parameter integer DDR_INIT_TIMEOUT_CYCLES = TIMEOUT_CYCLES
) (
    input wire clk,
    input wire rst_n,
    input wire ddr_init_done,

    output wire flash_cs_n,
    output wire flash_cs2_n,
    output wire flash_mosi,
    input wire flash_miso,
    output wire flash_wp_n,
    output wire flash_hold_n,
    output wire flash_sck,

    input wire run_req_valid,
    output wire run_req_ready,
    input wire run_req_write,
    input wire [31:0] run_req_addr,
    input wire [31:0] run_req_wdata,
    input wire [3:0] run_req_wstrb,
    output wire run_rsp_valid,
    input wire run_rsp_ready,
    output wire run_rsp_is_read,
    output wire [31:0] run_rsp_rdata,

    output wire ddr_req_valid,
    input wire ddr_req_ready,
    output wire ddr_req_write,
    output wire [31:0] ddr_req_addr,
    output wire [31:0] ddr_req_wdata,
    output wire [3:0] ddr_req_wstrb,
    input wire ddr_rsp_valid,
    output wire ddr_rsp_ready,
    input wire ddr_rsp_is_read,
    input wire [31:0] ddr_rsp_rdata,

    output wire boot_done,
    output wire boot_error,
    output wire [3:0] boot_error_code,
    output wire ddr_ready_cpu,
    output reg flash_clk_enable
);
    reg ddr_init_sync;
    reg ddr_init_meta_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ddr_init_meta_q <= 1'b0;
            ddr_init_sync <= 1'b0;
        end else begin
            ddr_init_meta_q <= ddr_init_done;
            ddr_init_sync <= ddr_init_meta_q;
        end
    end
    assign ddr_ready_cpu = ddr_init_sync;

    wire flash_req_valid;
    wire [23:0] flash_req_addr;
    wire flash_rsp_valid;
    wire flash_rsp_ready;
    wire [7:0] flash_rsp_data;
    wire spi_sck;
    wire spi_cs_n;
    wire spi_mosi;
    wire flash_reader_req_ready;

    // Enable the dedicated configuration-clock output after DDR init has
    // crossed into cpu_clk.  On failure or init loss, finish any in-flight
    // byte first, then gate the clock only when CS is inactive and SCK is low.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            flash_clk_enable <= 1'b0;
        else if (ddr_init_sync && !boot_error)
            flash_clk_enable <= 1'b1;
        else if (spi_cs_n && !spi_sck)
            flash_clk_enable <= 1'b0;
    end

    spi_flash_byte_reader #(
        .CLK_DIV(SPI_CLK_DIV)
    ) u_flash_reader (
        .clk       (clk),
        .rst_n     (rst_n),
        .req_valid (flash_req_valid && ddr_init_sync && !boot_error),
        .req_ready (flash_reader_req_ready),
        .req_addr  (flash_req_addr),
        .rsp_valid (flash_rsp_valid),
        .rsp_ready (flash_rsp_ready),
        .rsp_data  (flash_rsp_data),
        .spi_sck   (spi_sck),
        .spi_cs_n  (spi_cs_n),
        .spi_mosi  (spi_mosi),
        .spi_miso  (flash_miso)
    );

    wire loader_ddr_req_valid;
    wire loader_ddr_req_ready;
    wire loader_ddr_req_write;
    wire [31:0] loader_ddr_req_addr;
    wire [31:0] loader_ddr_req_wdata;
    wire [3:0] loader_ddr_req_wstrb;
    wire loader_ddr_rsp_valid;
    wire loader_ddr_rsp_ready;
    wire loader_ddr_rsp_is_read;
    wire [31:0] loader_ddr_rsp_rdata;
    wire loader_busy;
    wire flash_req_ready = flash_reader_req_ready &&
                           ddr_init_sync && !boot_error;

    flash_ddr_loader #(
        .FLASH_BASE     (FLASH_BASE),
        .DDR_BASE       (DDR_BASE),
        .DDR_LIMIT      (DDR_LIMIT),
        .IMAGE_BYTES    (IMAGE_BYTES),
        .TIMEOUT_CYCLES (TIMEOUT_CYCLES),
        .DDR_INIT_TIMEOUT_CYCLES (DDR_INIT_TIMEOUT_CYCLES)
    ) u_loader (
        .clk            (clk),
        .rst_n          (rst_n),
        .ddr_init_done  (ddr_init_sync),
        .flash_req_valid(flash_req_valid),
        .flash_req_ready(flash_req_ready),
        .flash_req_addr (flash_req_addr),
        .flash_rsp_valid(flash_rsp_valid),
        .flash_rsp_ready(flash_rsp_ready),
        .flash_rsp_data (flash_rsp_data),
        .ddr_req_valid  (loader_ddr_req_valid),
        .ddr_req_ready  (loader_ddr_req_ready),
        .ddr_req_write  (loader_ddr_req_write),
        .ddr_req_addr   (loader_ddr_req_addr),
        .ddr_req_wdata  (loader_ddr_req_wdata),
        .ddr_req_wstrb  (loader_ddr_req_wstrb),
        .ddr_rsp_valid  (loader_ddr_rsp_valid),
        .ddr_rsp_ready  (loader_ddr_rsp_ready),
        .ddr_rsp_is_read(loader_ddr_rsp_is_read),
        .ddr_rsp_rdata  (loader_ddr_rsp_rdata),
        .boot_done      (boot_done),
        .boot_error     (boot_error),
        .error_code     (boot_error_code),
        .busy           (loader_busy)
    );

    // Ownership changes only after boot_done is raised.  The loader raises it
    // on the same edge that consumes its final response, so no response is
    // delivered to both masters or discarded during the transition.
    wire run_owner = boot_done && !boot_error && ddr_init_sync;
    wire boot_owner = !run_owner && !boot_error && ddr_init_sync;

    assign ddr_req_valid = boot_owner ? loader_ddr_req_valid :
                           run_owner  ? run_req_valid : 1'b0;
    assign ddr_req_write = boot_owner ? loader_ddr_req_write :
                           run_owner  ? run_req_write : 1'b0;
    assign ddr_req_addr = boot_owner ? loader_ddr_req_addr :
                          run_owner  ? run_req_addr : 32'd0;
    assign ddr_req_wdata = boot_owner ? loader_ddr_req_wdata :
                           run_owner  ? run_req_wdata : 32'd0;
    assign ddr_req_wstrb = boot_owner ? loader_ddr_req_wstrb :
                           run_owner  ? run_req_wstrb : 4'd0;

    assign loader_ddr_req_ready = boot_owner && ddr_req_ready;
    assign run_req_ready = run_owner && ddr_req_ready;

    assign loader_ddr_rsp_valid = boot_owner && ddr_rsp_valid;
    assign loader_ddr_rsp_is_read = boot_owner && ddr_rsp_is_read;
    assign loader_ddr_rsp_rdata = boot_owner ? ddr_rsp_rdata : 32'd0;
    assign run_rsp_valid = run_owner && ddr_rsp_valid;
    assign run_rsp_is_read = run_owner && ddr_rsp_is_read;
    assign run_rsp_rdata = run_owner ? ddr_rsp_rdata : 32'd0;
    assign ddr_rsp_ready = boot_owner ? loader_ddr_rsp_ready :
                           run_owner  ? run_rsp_ready : 1'b0;

    assign flash_cs_n = spi_cs_n;
    assign flash_cs2_n = 1'b1;
    assign flash_mosi = spi_mosi;
    assign flash_wp_n = 1'b1;
    assign flash_hold_n = 1'b1;
    assign flash_sck = spi_sck;
endmodule
