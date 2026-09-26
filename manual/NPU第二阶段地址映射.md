# 第二阶段 NPU 地址映射

RTL 的唯一地址常量来源是 [`soc/soc_addr_map.vh`](../soc/soc_addr_map.vh)。本文件用于说明各段的用途；软件中的地址常量应由该文件同步导出，而不应自行另定数值。

`project/project.pds` 将工程工作目录设为 `project/`。因此 `Hfpga_soc.v` 显式引用 `../soc/soc_addr_map.vh`，直接定位唯一头文件，不依赖 PDS 是否将 Verilog 源目录自动加入 include 搜索路径。仿真 TB 则由 `Makefile` 显式传入 `-Isoc`，以裸文件名引用同一头文件。

地址采用 `[起始地址, 结束地址)` 表示，单位为 Byte。

| CPU 可见地址范围 | 大小 | 用途 | DCache 策略 |
|---|---:|---|---|
| `0x4000_0000` – `0x4000_00ff` | 256 B | UART0 | 非缓存 |
| `0x4000_0100` – `0x4000_01ff` | 256 B | NPU 控制寄存器预留 | 非缓存 |
| `0x4000_0200` | 4 B | LED | 非缓存 |
| `0x4000_0f00` – `0x4000_0fff` | 256 B | FPIOA | 非缓存 |
| `0x8000_0000` – `0xb7ff_ffff` | 896 MiB | CPU 程序、堆、栈和普通数据 | 可缓存 |
| `0xb800_0000` – `0xb8ff_ffff` | 16 MiB | NPU 输入图像/输入特征图 | Task 2 后旁路 |
| `0xb900_0000` – `0xbaff_ffff` | 32 MiB | NPU 量化权重 | Task 2 后旁路 |
| `0xbb00_0000` – `0xbbff_ffff` | 16 MiB | NPU 输出结果/输出特征图 | Task 2 后旁路 |
| `0xbc00_0000` – `0xbfff_ffff` | 64 MiB | NPU 中间特征图与 DMA 临时区 | Task 2 后旁路 |

DDR3 的当前控制器配置为 30 位 AXI 字节地址、256-bit 数据口，因此 CPU 映射的 DDR 总窗口是 `0x8000_0000` – `0xbfff_ffff`（1 GiB）。`link.lds` 的程序和运行期数据只使用该窗口起始的 `48 KiB`，与从 `0xb800_0000` 开始的 NPU 共享区没有重叠。

NPU 四个 DDR 子区都以 32 Byte 对齐，与一拍 256-bit AXI 数据相匹配。第一版 NPU 不改变这些固定分区；若模型实际需要更大空间，应统一修改 `soc_addr_map.vh`、重新运行地址映射测试，并审核软件地址定义后再调整。

Task 2 的接口约定：DCache 只把 `SOC_CPU_CACHED_DDR_BASE` 至 `SOC_CPU_CACHED_DDR_END` 当作可缓存区；NPU 共享区仍通过原 DDR 通路访问，但必须绕过 DCache。Task 3 的控制器只响应 `SOC_NPU_MMIO_BASE` 至 `SOC_NPU_MMIO_END`。

## NPU 控制寄存器

寄存器位于 `0x4000_0100` 起的 256 Byte MMIO 窗口，均为 32-bit 小端寄存器。地址、任务长度和 IRQ 使能支持按 `WSTRB` 的字节部分写；引擎侧配置仅在成功接受 `start` 时锁存。

| 偏移 | 名称 | 位定义 / 访问方式 |
|---:|---|---|
| `0x00` | `CTRL` | bit0 写 `1`：仅在 `busy=0` 时产生一次 `start_pulse`。 |
| `0x04` | `STATUS` | bit0 `busy`，bit1 粘滞 `done`；向 bit1 写 `1` 可 W1C 清除 `done`。 |
| `0x08` | `INPUT_ADDR` | NPU 输入缓冲区地址。 |
| `0x0c` | `WEIGHT_ADDR` | 权重缓冲区地址。 |
| `0x10` | `OUTPUT_ADDR` | 输出缓冲区地址。 |
| `0x14` | `TASK_BYTES` | 本次任务的字节长度。 |
| `0x18` | `IRQ_ENABLE` | bit0：`done` 中断使能。 |
| `0x1c` | `IRQ_STATUS` | bit0：`done` pending；向 bit0 写 `1` 可 W1C 清除。 |

`irq = done & irq_enable`。成功接受新的 `start` 会清除上一任务遗留的 `done` 与 IRQ；同一时钟内若引擎完成与软件 W1C 同时发生，完成事件优先，因此不会丢失新的 `done` 或 IRQ。

## Task 4 DMA 总线约定

`Hnpu_dma` 使用独立的 256-bit AXI4 master，单拍为 32 Byte（`AxSIZE=5`），固定 ID 为 `0x80`；CPU 取指/数据现有默认 ID 分别为 `0`/`1`，故不会混淆。DMA 输入的 CPU 地址先校验仍在完整 DDR 窗口内，再减去 `0x8000_0000`，形成 DDR 控制器所需的 30-bit 本地字节地址。每个 burst 最多 16 拍，并同时在源、目的任一侧的 4 KiB 边界前截断；首版要求源/目的均 32 Byte 对齐，长度为 32 Byte 的整数倍。零长度立即成功完成，非法请求不产生 AXI 访问并报错。
