`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// ============================================================================
// Hnpu_ctrl
//
// NPU 的 CPU 时钟域控制寄存器。它不包含 DMA 或计算阵列：软件写 CTRL.start
// 后，本模块锁存一份给后续引擎使用的配置，并输出单周期 start_pulse；引擎以
// engine_done 完成任务。Task 6 才会在该接口外加入跨时钟握手。
// ============================================================================
module Hnpu_ctrl #(
    // 实际 SoC 必须由 Hfpga_soc 传入 soc_addr_map.vh 的 NPU MMIO 参数。
    // 默认零地址只避免独立复用模块时暗中复制 SoC 地址常量。
    parameter [31:0] NPU_MMIO_BASE  = 32'h0000_0000,
    parameter [31:0] NPU_MMIO_BYTES = 32'h0000_0100
) (
    input              clk,
    input              rst_n,

    // 复用 Hfpga_soc 已有的 MMIO 单拍请求接口。
    input              mmio_valid,
    input              mmio_wen,
    input      [31:0]  mmio_addr,
    input      [31:0]  mmio_wdata,
    input      [3:0]   mmio_wstrb,
    output wire        mmio_addr_sel,
    output wire        mmio_sel,
    output wire        mmio_ready,
    output reg [31:0]  mmio_rdata,

    // 后续 NPU 引擎接口。配置输出只在成功启动时更新，运行期间保持稳定。
    output reg         start_pulse,
    input              engine_done,
    output reg [31:0]  engine_input_addr,
    output reg [31:0]  engine_weight_addr,
    output reg [31:0]  engine_output_addr,
    output reg [31:0]  engine_task_bytes,

    output wire        irq
);

// 寄存器字节偏移。所有寄存器均为 32-bit，部分写由 mmio_wstrb 合并。
localparam [7:0] REG_CTRL        = `SOC_NPU_CTRL_OFFSET;
localparam [7:0] REG_STATUS      = `SOC_NPU_STATUS_OFFSET;
localparam [7:0] REG_INPUT_ADDR  = `SOC_NPU_INPUT_ADDR_OFFSET;
localparam [7:0] REG_WEIGHT_ADDR = `SOC_NPU_WEIGHT_ADDR_OFFSET;
localparam [7:0] REG_OUTPUT_ADDR = `SOC_NPU_OUTPUT_ADDR_OFFSET;
localparam [7:0] REG_TASK_BYTES  = `SOC_NPU_TASK_BYTES_OFFSET;
localparam [7:0] REG_IRQ_ENABLE  = `SOC_NPU_IRQ_ENABLE_OFFSET;
localparam [7:0] REG_IRQ_STATUS  = `SOC_NPU_IRQ_STATUS_OFFSET;

reg [31:0] input_addr_reg;
reg [31:0] weight_addr_reg;
reg [31:0] output_addr_reg;
reg [31:0] task_bytes_reg;
reg        busy_reg;
reg        done_reg;
reg        irq_enable_reg;

// 使用完整的 8-bit 窗口偏移，避免 0x44 等高位偏移别名到 STATUS(0x04)。
wire [7:0] reg_offset = mmio_addr[7:0];
wire write_access = mmio_sel && mmio_wen;
wire start_write = write_access && (reg_offset == REG_CTRL) &&
                   mmio_wstrb[0] && ((mmio_wdata & `SOC_NPU_CTRL_START_MASK) != 0);
wire done_clear_write = write_access &&
                        (((reg_offset == REG_STATUS) && mmio_wstrb[0] &&
                          ((mmio_wdata & `SOC_NPU_STATUS_DONE_MASK) != 0)) ||
                         ((reg_offset == REG_IRQ_STATUS) && mmio_wstrb[0] &&
                          ((mmio_wdata & `SOC_NPU_IRQ_DONE_MASK) != 0)));

assign mmio_addr_sel = (mmio_addr >= NPU_MMIO_BASE) &&
                       (mmio_addr < (NPU_MMIO_BASE + NPU_MMIO_BYTES));
assign mmio_sel   = mmio_valid && mmio_addr_sel;
assign mmio_ready = 1'b1;
assign irq        = done_reg && irq_enable_reg;

// 将字节使能写合并到原寄存器值，地址类和长度类寄存器均使用这一规则。
function [31:0] merge_wstrb;
    input [31:0] old_value;
    input [31:0] new_value;
    input [3:0]  wstrb;
    begin
        merge_wstrb[7:0]   = wstrb[0] ? new_value[7:0]   : old_value[7:0];
        merge_wstrb[15:8]  = wstrb[1] ? new_value[15:8]  : old_value[15:8];
        merge_wstrb[23:16] = wstrb[2] ? new_value[23:16] : old_value[23:16];
        merge_wstrb[31:24] = wstrb[3] ? new_value[31:24] : old_value[31:24];
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        input_addr_reg    <= 32'b0;
        weight_addr_reg   <= 32'b0;
        output_addr_reg   <= 32'b0;
        task_bytes_reg    <= 32'b0;
        engine_input_addr <= 32'b0;
        engine_weight_addr<= 32'b0;
        engine_output_addr<= 32'b0;
        engine_task_bytes <= 32'b0;
        busy_reg          <= 1'b0;
        done_reg          <= 1'b0;
        irq_enable_reg    <= 1'b0;
        start_pulse       <= 1'b0;
    end else begin
        // start_pulse 是事件而非状态，默认每拍清零。
        start_pulse <= 1'b0;

        if (write_access) begin
            case (reg_offset)
                REG_INPUT_ADDR:
                    input_addr_reg  <= merge_wstrb(input_addr_reg, mmio_wdata, mmio_wstrb);
                REG_WEIGHT_ADDR:
                    weight_addr_reg <= merge_wstrb(weight_addr_reg, mmio_wdata, mmio_wstrb);
                REG_OUTPUT_ADDR:
                    output_addr_reg <= merge_wstrb(output_addr_reg, mmio_wdata, mmio_wstrb);
                REG_TASK_BYTES:
                    task_bytes_reg  <= merge_wstrb(task_bytes_reg, mmio_wdata, mmio_wstrb);
                REG_IRQ_ENABLE:
                    if (mmio_wstrb[0])
                irq_enable_reg <= ((mmio_wdata & `SOC_NPU_IRQ_ENABLE_MASK) != 0);
                default: begin end
            endcase
        end

        // 运行期配置只在 start 被接受时更新，防止软件后续写寄存器撕裂引擎参数。
        // 新任务开始即撤销上一任务残留的 done/IRQ，避免软件尚未来得及 W1C
        // 时把“busy=1, done=1”误判成新任务已经完成。
        if (start_write && !busy_reg) begin
            start_pulse        <= 1'b1;
            busy_reg           <= 1'b1;
            done_reg           <= 1'b0;
            engine_input_addr  <= input_addr_reg;
            engine_weight_addr <= weight_addr_reg;
            engine_output_addr <= output_addr_reg;
            engine_task_bytes  <= task_bytes_reg;
        end

        // done 为粘滞状态。若 engine_done 和软件 W1C 同拍，完成优先，确保
        // 新完成事件及对应 IRQ 不会被同拍清除而丢失。
        if (engine_done && busy_reg) begin
            busy_reg <= 1'b0;
            done_reg <= 1'b1;
        end else if (done_clear_write) begin
            done_reg <= 1'b0;
        end
    end
end

always @(*) begin
    // 窗口外或未定义寄存器均返回零，避免误访问泄漏内部状态。
    mmio_rdata = 32'b0;
    if (mmio_addr_sel) begin
        case (reg_offset)
            REG_STATUS:      mmio_rdata = (done_reg ? `SOC_NPU_STATUS_DONE_MASK : 32'b0) |
                                           (busy_reg ? `SOC_NPU_STATUS_BUSY_MASK : 32'b0);
            REG_INPUT_ADDR:  mmio_rdata = input_addr_reg;
            REG_WEIGHT_ADDR: mmio_rdata = weight_addr_reg;
            REG_OUTPUT_ADDR: mmio_rdata = output_addr_reg;
            REG_TASK_BYTES:  mmio_rdata = task_bytes_reg;
            REG_IRQ_ENABLE:  mmio_rdata = {31'b0, irq_enable_reg};
            REG_IRQ_STATUS:  mmio_rdata = {31'b0, done_reg};
            default:         mmio_rdata = 32'b0;
        endcase
    end
end

endmodule
