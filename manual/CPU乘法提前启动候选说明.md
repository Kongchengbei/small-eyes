# CPU 乘法提前启动候选说明

日期：2026-10-25。工作分支：`main`。

后续已进入分批优化。本文保留乘法实现细节与历史验证；当前综合候选、逐轮 PDS 结果和位流位置见 [CPU 分批优化实施记录](CPU分批优化实施记录.md)。

## 本轮范围

识别优化分支 `recog-rtl-1023` 保持原提交，CPU 修改直接在 main 工作区进行。没有创建提交或推送。

先将 menuconfig 从 Full DDR 切换为 CoreMark BRAM：

- `SOC_CPU_MEM_BRAM=1`，缓存、DDR、摄像头和前处理关闭。
- CPU 保持 70 MHz，本机串口 FPIOA0。
- 初始化文件沿用 `test/coremark_local.dat`，SHA-256 为 `d1a01d5d364f19cf6203f38a32c79c665bf4c3ad89e41aedf36d667674e5a58a`。
- 使用配置工具同步地址映射、FDC、BSP 头文件和厂商 IMEM 初始化参数，`make config-check` 通过。

原 Full DDR 配置和本轮修改前的 CPU 源码保存在 `build/cpu_coremark_20261025/before/`。

## 修改行为

原乘法路径：ID 发射到 EX，下一拍才启动乘法器的部分积阶段，再完成合并阶段。

本轮允许符合以下条件的乘法，在 ID 发射到 EX 的同一个时钟沿启动部分积阶段：

1. BRAM 和 DDR 使用同样的提前启动逻辑，不设置按存储模式启用的开关。
2. 当前 EX 没有占用乘法器。
3. 两个源寄存器均不依赖 EX/MEM 的生产者，没有待返回的 load 操作数。
4. 指令确实被 EX 接收，且没有 EX 冲刷。

提前路径直接使用寄存器堆输出（含已有 WB 写穿），避免 EX/MEM 前递数据再穿过乘法器部分积组合逻辑。操作数选择与发射握手分开，避免把 ready/flush 条件串入部分积数据选择。

满足条件时，乘法启动提前一拍。其余乘法保留原 EX 启动路径，包括 load 依赖和当前 EX 乘法完成时等待接收的下一条乘法。

乘法器仍复用同一个 `mul` 实例，四种 RV32M 乘法的算术实现没有修改。提前启动时同步设置本条 EX 指令的 started 标记，防止重复启动；完成脉冲及 MEM 背压下的结果保留沿用原逻辑。DDR 的 load 数据尚未返回时，依据数据依赖和 ready/valid 握手回退到 EX 路径，不按 DDR 模式关闭优化。

初版曾错误地把本次优化限定在 BRAM 模式。按用户要求已移除 `MUL_EARLY_START` 参数和 `id_mul_early_ready` 的 BRAM_MODE 门控，所有 Htop 实例使用同一套乘法启动策略。下列旧报告和旧位流仅作为初版记录，新通用版本结果单独记录。

## 文件对应

| 文件 | 修改 |
|---|---|
| `cpu/Hidu.v` | 判断 EX/MEM 数据依赖，提供 RF/WB 操作数及提前启动资格 |
| `cpu/Htop.v` | 连接新增信号，两种存储配置使用相同 EX 乘法逻辑 |
| `cpu/Hexu.v` | 在 ID 被接收时启动乘法，维护本条指令的启动状态 |

## 性能判断

历史实板基线为 BRAM、70 MHz、3000 次迭代：1,143,222,397 ticks，183.69129 CoreMark，2.62416 CoreMark/MHz，整个 SoC 4569 LUT。该数据来自已有的 `manual/BRAM旁路扩展实现与验证.md`，不是本轮重新测得的成绩。

本轮只对符合条件的乘法减少等待。不能把单条指令节省一拍等同于所有乘法或整个 CoreMark 都获得相同比例加速。实际收益需要新位流的 CoreMark CRC、总 ticks 和同口径资源报告确认。

## 验证状态

- BRAM_MODE=0 和 BRAM_MODE=1 的 Htop 静态展开通过，未执行生成的仿真程序。
- 未编写或运行 testbench，未运行指令仿真、CoreMark 仿真或板端程序。
- PDS 2022.2-SP6.4 build 146967，新旧版本均完成 Compile、Synthesize、Device Map、Place & Route 和多角时序分析，报告均为 All Constraints Met。

初版限定 BRAM 的历史对照（CoreMark BRAM、70 MHz、PG2L200H/FBB676/-6）：

| 指标 | 本轮重新构建的基线 | 乘法提前启动候选 |
|---|---:|---:|
| 整个 SoC 映射 LUT | 4575 | 4588 |
| 综合寄存器数 | 4338 | 4338 |
| APM | 4 | 4 |
| DRM | 12 | 12 |
| CPU setup WNS | +0.874 ns | +0.847 ns |
| CPU setup TNS | 0 | 0 |
| CPU fast-corner hold WHS | +0.105 ns | +0.133 ns |

LUT 增加 13 个，约 0.284%。同频率下，实测总 ticks 需要低于基线的 `4575/4588 ≈ 0.99717`，才能同时提高 CoreMark/LUT。新的 CoreMark 成绩仍未测得。

本轮映射基线 4575 LUT 与历史报告 4569 LUT 是不同次构建结果，资源对照使用本轮相同工具与约束下的两个快照，不直接混用。

报告和汇总位于 `build/cpu_coremark_20261025/reports/` 与 `comparison.json`。PDS 临时工程在 `C:/Users/LEGION/AppData/Local/Temp/socfpga_cpu_mul_20261025/`，没有覆盖原工程中用户已有的识别位流及日志。

完成检查后仍需板端验证 CRC 和正式迭代成绩。BRAM 模式程序随 FPGA 位流初始化，需重新生成位流；没有执行自动烧录。

## 初版位流（已被通用版本替代）

已在同一次完整 PDS 流程中生成候选位流：`build/cpu_coremark_20261025/bitstream/Hfpga_soc.sbit`，9,188,552 字节。同目录保存其时序报告、映射报告、生成日志和 manifest。原工程 `project/` 下的识别位流没有被替换。

此初版带有错误的模式限制，不再作为本次验收文件；文件保留作历史记录，manifest 已标记 superseded。通用版本的检查结果和位流另存于 `build/cpu_coremark_20261025/common_cpu/`。新的分数和 CoreMark/LUT 收益仍待实测。

## 移除模式限制后的检查结果

新版本在 BRAM 和 DDR 中均使用同一套乘法启动逻辑。Htop 的两种模式静态展开通过，两份 PDS 快照的 CPU 源码与当前工作区一致。

- BRAM：PDS 编译、综合、器件映射、布局布线、时序和位流生成通过；4588 LUT，setup WNS +0.847 ns，TNS 0，fast-corner hold WHS +0.133 ns。
- Full DDR：PDS 编译、综合通过。整机综合用了 17 分 7 秒，检查范围对本次小改动过大；额外的器件映射被主动停止，不作为失败或通过的结果。没有执行本版 DDR 布局布线及时序验证。
- 新候选位流位于 `build/cpu_coremark_20261025/common_cpu/bitstream/Hfpga_soc.sbit`；它是 CoreMark BRAM 配置，程序已嵌入 IMEM，未执行烧录。
- 本轮未编写或运行 testbench，未测得新的实板 CoreMark 分数。汇总在 `common_cpu/validation_summary.json`，已完成的报告在 `common_cpu/reports/`。

这只完成了本次乘法优化的跨模式统一。旧有的模式相关前递、分支和取指策略另列在 `CPU存储配置与执行策略差异待审查.md`，不能把它们写成已全部统一，也没有在本次顺带实施这些重构。
