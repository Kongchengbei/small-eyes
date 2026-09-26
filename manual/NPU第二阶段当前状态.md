# NPU 第二阶段当前状态

截至 2026-09-16。第二阶段正在为 NPU 接入现有 SoC 准备共享内存和 DDR 数据通路；目前还没有 NPU 计算阵列。

## 已完成的独立工作

| Task | 内容 | 验证结果 |
|---|---|---|
| 1 | 统一 1 GiB DDR、NPU 共享区和 MMIO 地址映射 | `make addr-map` 通过 |
| 2 | CPU 访问 `0xB800_0000–0xBFFF_FFFF` 时绕过 DCache | `make dcache-bypass` 通过 |
| 3 | NPU 配置、启动、`busy/done` 和完成 IRQ 寄存器 | `make npu-ctrl` 通过 |
| 4 | 256-bit AXI DMA 搬运骨架及独立错误检测 | `make npu-dma` 通过 |
| 5 | CPU/DMA 共用 DDR 的双主 AXI 仲裁器；读写事务分别锁定，地址阻塞期间保持字段稳定 | `make npu-arbiter` 通过独立新目录复跑及只读终审 |

Task 4 的 DMA 目前只将数据从 DDR 读出再写回，不执行神经网络运算。Task 5 仲裁器每个方向各允许一笔事务在途。详细地址与寄存器定义见[第二阶段地址映射](NPU第二阶段地址映射.md)。

## 当前尚未接通的部分

- [SoC 顶层](../soc/Hfpga_soc.v)仍由 CPU DDR bridge 直连 DDR IP；DMA 和双主仲裁器只经过独立仿真，尚未接入顶层。
- 控制寄存器在 `cpu_clk` 域，DMA 计划运行于 `ddr_core_clk` 域；启动、配置、完成和错误需要可靠的跨时钟握手。顶层的 `npu_engine_done` 目前固定为 `0`。
- DMA 已有 `error/error_pulse` 输出，但控制器尚无 CPU 可读的错误状态；失败任务目前不能通过 MMIO 正常结束 `busy` 并报告原因。
- 共享区的 CPU 访问已不分配 DCache 行，这是当前一致性方案的基础；CPU 写入、DMA 读写、CPU 读回的完整顺序尚未做顶层端到端验证。普通可缓存 DDR 区不作为 DMA 共享缓冲区。
- 实体开发板上的 JTAG 装载 DDR、资源占用、时序和模型推理均未验证。UART RX 不是共享内存验证的前置条件。

## 下一步

1. **系统集成**：把仲裁器和 DMA 接入 DDR，完成跨时钟命令/结果握手；为 DMA 错误增加 CPU 可读状态，并定义错误时 `busy`、`done` 与 IRQ 的行为。
2. **端到端验证**：覆盖 CPU 向非缓存共享区写输入、DMA 搬运、完成后 CPU 读回，以及非法地址和 DDR 响应错误；实体板到手后再验证 JTAG 装载和板上 DDR 路径。
3. **NPU 计算实现**：确定目标模型和量化格式后，再设计计算单元、片上缓冲及调度，替换当前 DMA 的原样搬运过程。

上述前两项是根据当前未接通的接口整理的后续工作，不代表已找到原始七项计划中 Task 6、7 的正式名称。当前改动尚未提交。
