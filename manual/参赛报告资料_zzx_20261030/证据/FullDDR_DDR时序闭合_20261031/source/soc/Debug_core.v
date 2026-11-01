`timescale 1ns / 1ps

// 集中式 CPU 调试信号包装器。真正的 PANGO DebugCore 仍由 Inserter 插入。
// 该模块只负责把逻辑字段调试总线经过一个实例，便于集中增删观测字段。
module Debug_core (
    input  wire [31:0] cpu_if_pc,
    input  wire [31:0] cpu_id_pc,
    input  wire [31:0] cpu_ex_pc,
    input  wire [31:0] cpu_mem_pc,
    input  wire [31:0] cpu_wb_pc,
    input  wire [31:0] cpu_if_ins,
    input  wire [31:0] cpu_id_ins,
    input  wire [31:0] cpu_ex_ins,
    input  wire [31:0] cpu_mem_ins,
    input  wire [31:0] cpu_wb_ins,
    input  wire [31:0] cpu_dmem_addr,
    input  wire [31:0] cpu_dmem_wdata,
    input  wire [31:0] cpu_btb_predict_next_pc,
    input  wire [31:0] cpu_actual_next_pc,
    input  wire [31:0] cpu_flush_pc,
    input  wire [31:0] cpu_ctrl,
    output wire [31:0] if_pc,
    output wire [31:0] id_pc,
    output wire [31:0] ex_pc,
    output wire [31:0] mem_pc,
    output wire [31:0] wb_pc,
    output wire [31:0] if_ins,
    output wire [31:0] id_ins,
    output wire [31:0] ex_ins,
    output wire [31:0] mem_ins,
    output wire [31:0] wb_ins,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [31:0] btb_predict_next_pc,
    output wire [31:0] actual_next_pc,
    output wire [31:0] flush_pc,
    // The CPU control bus contains one deliberately reserved bit (bit 27).
    // Keep the 31 meaningful control bits in the debug wrapper.  The FPGA
    // top-level marks only the BTB profile as PAP_MARK_DEBUG; the other fields
    // remain available to RTL simulation without consuming FIC trigger bits.
    output wire [30:0] ctrl
);
    assign if_pc               = cpu_if_pc;
    assign id_pc               = cpu_id_pc;
    assign ex_pc               = cpu_ex_pc;
    assign mem_pc              = cpu_mem_pc;
    assign wb_pc               = cpu_wb_pc;
    assign if_ins              = cpu_if_ins;
    assign id_ins              = cpu_id_ins;
    assign ex_ins              = cpu_ex_ins;
    assign mem_ins             = cpu_mem_ins;
    assign wb_ins              = cpu_wb_ins;
    assign dmem_addr           = cpu_dmem_addr;
    assign dmem_wdata          = cpu_dmem_wdata;
    assign btb_predict_next_pc = cpu_btb_predict_next_pc;
    assign actual_next_pc      = cpu_actual_next_pc;
    assign flush_pc            = cpu_flush_pc;
    // Preserve CPU control bits [26:0] and [31:28], while omitting the
    // reserved CPU bit [27].  The ordering keeps the low control bits at the
    // same ILA positions and places dmem_wmask at the top four positions.
    assign ctrl                = {cpu_ctrl[31:28], cpu_ctrl[26:0]};
endmodule
