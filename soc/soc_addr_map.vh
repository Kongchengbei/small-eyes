// ============================================================================
// SoC 地址映射的 RTL 单一来源
//
// 所有数值都是 CPU 可见的字节地址；END 为开区间上界，即地址范围写作
// [BASE, END)。顶层 Hfpga_soc 以这些宏作为默认参数，板型或 DDR 容量变化时
// 可以在顶层覆盖参数，而不需要散落修改各个模块。
//
// 注意：NPU 共享 DDR 区在本阶段只作预留。Task 2 才会令 CPU DCache 对此区
// 域旁路；Task 3 才会实现 NPU_MMIO_BASE 对应的寄存器。
// ============================================================================
`ifndef SOC_ADDR_MAP_VH
`define SOC_ADDR_MAP_VH

// DDR3：控制器地址宽 30 位，当前 x32 颗粒配置可寻址 1 GiB。
`define SOC_DDR_BASE                 32'h8000_0000
`define SOC_DDR_BYTES                32'h4000_0000
`define SOC_DDR_END                  32'hc000_0000

// 普通 CPU 程序和数据区：未来允许 DCache 正常缓存。
`define SOC_CPU_CACHED_DDR_BASE      32'h8000_0000
`define SOC_CPU_CACHED_DDR_BYTES     32'h3800_0000
`define SOC_CPU_CACHED_DDR_END       32'hb800_0000

// NPU 专用共享区：CPU 与 NPU 交接数据时，CPU 将在 Task 2 绕过 DCache。
`define SOC_NPU_SHARED_BASE          32'hb800_0000
`define SOC_NPU_SHARED_BYTES         32'h0800_0000
`define SOC_NPU_SHARED_END           32'hc000_0000

// 共享区内部按用途静态分段，均为 32 Byte 对齐，适合 256-bit AXI beat。
`define SOC_NPU_INPUT_BASE           32'hb800_0000
`define SOC_NPU_INPUT_BYTES          32'h0100_0000
`define SOC_NPU_INPUT_END            32'hb900_0000

`define SOC_NPU_WEIGHT_BASE          32'hb900_0000
`define SOC_NPU_WEIGHT_BYTES         32'h0200_0000
`define SOC_NPU_WEIGHT_END           32'hbb00_0000

`define SOC_NPU_OUTPUT_BASE          32'hbb00_0000
`define SOC_NPU_OUTPUT_BYTES         32'h0100_0000
`define SOC_NPU_OUTPUT_END           32'hbc00_0000

`define SOC_NPU_SCRATCH_BASE         32'hbc00_0000
`define SOC_NPU_SCRATCH_BYTES        32'h0400_0000
`define SOC_NPU_SCRATCH_END          32'hc000_0000

// MMIO 总窗口与已分配的外设窗口。
`define SOC_MMIO_BASE                32'h4000_0000
`define SOC_MMIO_BYTES               32'h0000_1000
`define SOC_MMIO_END                 32'h4000_1000

`define SOC_UART0_BASE               32'h4000_0000
`define SOC_UART0_BYTES              32'h0000_0100
`define SOC_UART0_END                32'h4000_0100

// 仅预留；Task 3 将在这一段实现 NPU 控制寄存器。
`define SOC_NPU_MMIO_BASE            32'h4000_0100
`define SOC_NPU_MMIO_BYTES           32'h0000_0100
`define SOC_NPU_MMIO_END             32'h4000_0200

`define SOC_LED_ADDR                 32'h4000_0200

// 物理 CAM1（RTL/软件统一使用一基编号）的 SCCB、DVP 控制与快照寄存器。
`define SOC_CAM1_MMIO_BASE           32'h4000_0300
`define SOC_CAM1_MMIO_BYTES          32'h0000_0100
`define SOC_CAM1_MMIO_END            32'h4000_0400

`define SOC_FPIOA_BASE               32'h4000_0f00
`define SOC_FPIOA_BYTES              32'h0000_0100
`define SOC_FPIOA_END                32'h4000_1000

`endif
