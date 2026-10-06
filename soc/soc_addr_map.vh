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

// Build and boot defaults. SOC_CPU_MEM_BRAM=0 selects the DDR application;
// 1 selects the CoreMark BRAM memory preset.
`define SOC_CPU_MEM_BRAM             1
`define SOC_ENABLE_ICACHE            0
`define SOC_ENABLE_DCACHE            0
`define SOC_ENABLE_DDR               0
`define SOC_ENABLE_CAMERA            0
`define SOC_ENABLE_PREPROCESS        0
`define SOC_CPU_HZ                   32'd70000000
`define SOC_UART_BAUD                32'd115200
`define SOC_UART_TX_FPIOA            0

`define SOC_FLASH_BASE               24'hA00000
`define SOC_FLASH_ADDRESS_BYTES      32'd16777216
`define SOC_BOOT_IMAGE_BYTES         32'd0
`define SOC_IRAM_BASE                32'h8000_0000
`define SOC_IRAM_BYTES               32'd32768
`define SOC_DRAM_BASE                32'h8000_8000
`define SOC_DRAM_BYTES               32'd16384

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

// CAM1 原始 RGB565 帧供未来 NPU 输入使用；两个槽各保留 1 MiB。
// 完成槽由 CPU/NPU 持有，必须显式释放后 Camera 才能再次写入。
`define SOC_CAM1_BUFFER0_BASE        32'hb800_0000
`define SOC_CAM1_BUFFER1_BASE        32'hb810_0000
`define SOC_CAM1_BUFFER_SLOT_BYTES   32'h0010_0000
`define SOC_CAM1_FRAME_BYTES         32'd614400
`define SOC_CAM2_BUFFER0_BASE        32'hb820_0000
`define SOC_CAM2_BUFFER1_BASE        32'hb830_0000
`define SOC_CAM2_MMIO_BASE           32'h4000_0400
`define SOC_CAM2_MMIO_BYTES          32'h0000_0100
`define SOC_CAM2_MMIO_END            32'h4000_0500

// 前处理 RGB565 ROI 暂存：每路两个 1 MiB bank；不覆盖四个 Camera 原图槽。
// 属于已有 16 MiB input 预留区，尚未定义最终模型 INT8 张量格式。
`define SOC_PRE1_BANK0_BASE          32'hb840_0000
`define SOC_PRE1_BANK1_BASE          32'hb850_0000
`define SOC_PRE2_BANK0_BASE          32'hb860_0000
`define SOC_PRE2_BANK1_BASE          32'hb870_0000
`define SOC_PRE_BANK_BYTES          32'h0010_0000
`define SOC_PRE_ROI_STRIDE_BYTES    32'd32768
`define SOC_NPU_INPUT_FREE_BASE     32'hb880_0000

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
`define SOC_UART_CTRL_OFFSET         8'h00
`define SOC_UART_STATUS_OFFSET       8'h04
`define SOC_UART_BAUD_OFFSET         8'h08
`define SOC_UART_TXDATA_OFFSET       8'h0c
// Legacy BSP declaration only; current RTL is TX-only and does not implement RX.
`define SOC_UART_RXDATA_LEGACY_OFFSET 8'h10
`define SOC_UART_CTRL_TX_ENABLE      32'h0000_0001
`define SOC_UART_STATUS_TX_BUSY      32'h0000_0001
// Legacy BSP compatibility bits; current RTL does not implement RX behavior.
`define SOC_UART_CTRL_RX_ENABLE_LEGACY_MASK 32'h0000_0002
`define SOC_UART_CTRL_DISABLE_LEGACY_MASK  32'h0000_000c
`define SOC_UART_STATUS_RX_READY_LEGACY_MASK 32'h0000_0002
`define SOC_UART_TX_FPIOA_FUNC       5'd7
// Legacy BSP UART1 address overlaps the reserved NPU window; no UART1 RTL exists.
`define SOC_UART1_LEGACY_BASE        (`SOC_UART0_BASE + `SOC_UART0_BYTES)
// Legacy BSP base offsets only; current RTL does not implement SPI or timers.
`define SOC_SPI_LEGACY_BASE_OFFSET   32'h0000_0200
`define SOC_TIMER0_LEGACY_BASE_OFFSET 32'h0000_0300
`define SOC_FPIOA_OUTPUT_MAP_BYTES   8'h20
`define SOC_FPIOA_NIO_DIN_OFFSET     8'h20
`define SOC_FPIOA_NIO_OPT_OFFSET     8'h24
`define SOC_FPIOA_NIO_MD0_OFFSET     8'h28
`define SOC_FPIOA_NIO_MD1_OFFSET     8'h2c
// The older BSP also names these unimplemented FPIOA registers.
`define SOC_FPIOA_ELI_MD_LEGACY_OFFSET 8'h30
`define SOC_FPIOA_INPUT_LEGACY_OFFSET  8'h80

// NPU control/status register offsets and control masks.
`define SOC_NPU_CTRL_OFFSET          8'h00
`define SOC_NPU_STATUS_OFFSET        8'h04
`define SOC_NPU_INPUT_ADDR_OFFSET    8'h08
`define SOC_NPU_WEIGHT_ADDR_OFFSET   8'h0c
`define SOC_NPU_OUTPUT_ADDR_OFFSET   8'h10
`define SOC_NPU_TASK_BYTES_OFFSET    8'h14
`define SOC_NPU_IRQ_ENABLE_OFFSET    8'h18
`define SOC_NPU_IRQ_STATUS_OFFSET    8'h1c
`define SOC_NPU_CTRL_START_MASK      32'h0000_0001
`define SOC_NPU_STATUS_BUSY_MASK     32'h0000_0001
`define SOC_NPU_STATUS_DONE_MASK     32'h0000_0002
`define SOC_NPU_IRQ_DONE_MASK        32'h0000_0001
`define SOC_NPU_IRQ_ENABLE_MASK      32'h0000_0001

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

// CAM1 MMIO offsets, error codes and control masks. camera_regs.vh preserves
// the historical CAM_* macro spellings as aliases to these definitions.
`define SOC_CAM_SNAPSHOT_CTRL                8'h08
`define SOC_CAM_FRAME_COUNT                  8'h0c
`define SOC_CAM_PIXEL_COUNT                  8'h10
`define SOC_CAM_PCLK_COUNT                   8'h14
`define SOC_CAM_ERROR_FLAGS                  8'h18
`define SOC_CAM_LINE_COUNT                   8'h1c
`define SOC_CAM_STATUS                       8'h20
`define SOC_CAM_BYTE_COUNT                   8'h24
`define SOC_CAM_FIFO_LEVEL                   8'h28
`define SOC_CAM_FIFO_MAX_LEVEL               8'h2c
`define SOC_CAM_FIFO_ERROR                  8'h30
`define SOC_CAM_DMA_STATUS                   8'h34
`define SOC_CAM_DMA_ERROR_CODE               8'h38
`define SOC_CAM_LAST_FRAME_ADDR              8'h3c
`define SOC_CAM_CURRENT_WRITE_BUFFER         8'h40
`define SOC_CAM_LAST_COMPLETE_BUFFER         8'h44
`define SOC_CAM_FRAME_CHECKSUM               8'h48
`define SOC_CAM_READY_MASK                   8'h4c
`define SOC_CAM_DROPPED_FRAMES               8'h50
`define SOC_CAM_SNAPSHOT_SEQUENCE            8'h54
`define SOC_CAM_DVP_FRAME_COUNT              8'h58
`define SOC_CAM_DVP_ERROR_FLAGS              8'h5c
`define SOC_CAM_BUFFER_RELEASE               8'h60
`define SOC_CAM_DMA_CONTROL                  8'h64
`define SOC_CAM_BUFFER0_ADDR                 8'h68
`define SOC_CAM_BUFFER1_ADDR                 8'h6c
`define SOC_CAM_FRAME_BYTES                  8'h70
`define SOC_CAM_FRAME_WIDTH                  8'h74
`define SOC_CAM_FRAME_HEIGHT                 8'h78
`define SOC_CAM_DDR_READY                    8'h7c
`define SOC_CAM_CURRENT_PIXEL_COUNT          8'h80
`define SOC_CAM_CURRENT_BYTE_COUNT           8'h84
`define SOC_CAM_CURRENT_LINE_COUNT           8'h88
`define SOC_CAM_ERR_NONE                     32'd0
`define SOC_CAM_ERR_FIFO_OVERFLOW            32'd1
`define SOC_CAM_ERR_UNEXPECTED_SOF           32'd2
`define SOC_CAM_ERR_UNEXPECTED_EOF           32'd3
`define SOC_CAM_ERR_BAD_PIXEL_COUNT           32'd4
`define SOC_CAM_ERR_DDR_TIMEOUT               32'd5
`define SOC_CAM_ERR_DDR_WRITE                 32'd6
`define SOC_CAM_ERR_BAD_LINE_COUNT            32'd7
`define SOC_CAM_ERR_DVP                       32'd8
`define SOC_CAM_ERR_NO_FREE_BUFFER            32'd9
`define SOC_CAM_ERR_BAD_CONFIG                32'd10
`define SOC_CAM_ERR_FIFO_UNDERFLOW            32'd11
`define SOC_CAM_SNAPSHOT_BUSY_MASK             32'h0000_0001
`define SOC_CAM_SNAPSHOT_VALID_MASK            32'h0000_0002
`define SOC_CAM_SNAPSHOT_TIMEOUT_MASK          32'h0000_0004
`define SOC_CAM_SNAPSHOT_START_MASK            32'h0000_0001
`define SOC_CAM_RELEASE_BUSY_MASK              32'h0000_0001
`define SOC_CAM_BUFFER_RELEASE_MASK            2'b11
`define SOC_CAM_SCCB_RESET_N_MASK              32'h0000_0001
`define SOC_CAM_SCCB_SCL_RELEASE_MASK          32'h0000_0002
`define SOC_CAM_SCCB_SDA_RELEASE_MASK          32'h0000_0004
`define SOC_CAM_SCCB_CAPTURE_ENABLE_MASK       32'h0000_0008
`define SOC_CAM_SCCB_STATUS_SDA_MASK           32'h0000_0004
`define SOC_CAM_SCCB_STATUS_SCL_SYNC_MASK      32'h0000_0002
`define SOC_CAM_SCCB_STATUS_SDA_SYNC_MASK      32'h0000_0004
`define SOC_CAM_SCCB_STATUS_RESET_N_MASK       32'h0000_0001
`define SOC_CAM_SCCB_STATUS_SCL_RELEASE_MASK   32'h0000_0008
`define SOC_CAM_SCCB_STATUS_SDA_RELEASE_MASK   32'h0000_0010
`define SOC_CAM_SCCB_STATUS_CAPTURE_MASK       32'h0000_0020
`define SOC_CAM_SCCB_CONTROL_OFFSET             8'h00
`define SOC_CAM_SCCB_STATUS_OFFSET              8'h04
`define SOC_CAM_SCCB_CONTROL_MASK               32'h0000_003f
`define SOC_CAM_STATUS_ERROR_MASK               32'h0000_6480
`define SOC_CAM_DMA_ENABLE_MASK                 32'h0000_0001
`define SOC_CAM_DMA_CLEAR_MASK                  32'h0000_0002
`define SOC_CAM_LEGACY_STATUS_OFFSET            8'h04

`endif
