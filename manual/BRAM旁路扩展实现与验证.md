# BRAM 旁路扩展实现与验证

## 范围

本轮由用户授权沿扩展旁路的思路继续优化，仍由 Luna high 实现、主代理复核。五级流水线保持 IF→ID→EX→MEM→WB；不新增 testbench，在实现完成后使用现有测试入口统一验证。

本轮起点为上一轮稳定 BRAM 实现：70 MHz，实板 3000 次迭代 1160580397 ticks，180.94395 CoreMark，2.58491 CoreMark/MHz，整个 SoC 4614 LUT。

## RTL 修改

仅修改 `cpu/Hidu.v` 和 `cpu/Hexu.v`。

### Hidu：允许更多 EX 消费者携带待前递标记

BRAM 模式下，紧邻 EX load 的消费者范围由普通 ALU 扩展到：

- 后续 load/store 的地址计算源。
- store 的数据源。
- MUL/MULH/MULHSU/MULHU 与 DIV/DIVU/REM/REMU 的源操作数。
- CSR 寄存器操作数；CSR 立即数操作仍使用原立即数字段。

仍使用逐源 pending 标记和一个共享的生产者 rd 标识。分支和 JALR 在 ID 使用操作数，保留其 load 依赖停顿。DDR 模式不启用上述放行。

### Hexu：所有 EX 操作数消费者使用解析后的值

复用 `ex_src1_value` / `ex_src2_value`，分别选择匹配的有效 MEM 前递值或者已保存的操作数。除 ALU 外，乘法器、除法器、CSR 和 store 字节/半字/字数据都接入该值。

乘除法的 start 必须等待所有待前递操作数有效，防止较慢 MMIO load 尚未返回时提前启动计算。EX 的放行、前递有效、访存提交和 CSR 操作也受操作数就绪控制。

保留前递值保存：当返回值有效但 EX 因乘除法计算或访存背压继续保持时，保存正确操作数并清除相应 pending 标记。生产者离开 MEM 后仍可继续执行。

访存 ready 可以组合检查地址；有效请求仅在 EX 操作数就绪且 MEM 可接收时提交，避免提前请求或重复写入。

## 最后统一验证

扩展现有 `sim/cpu_bram_forward.S`，未新增 testbench。新场景覆盖 word/byte/halfword store 数据、load→load/store 地址、两源同时依赖、M 操作数等待、MMIO 延迟、store 背压、CSR 寄存器和立即数操作。背压测试在 load 前将源寄存器设置为错误哨兵值，确保遗漏前递或保存时会失败。

相同 50 份程序分别运行本轮开始前的稳定仿真二进制和当前 RTL。基线二进制对应的四个主要流水线源码与本轮快照完全一致。

| 验证 | 结果 |
| --- | --- |
| BRAM 指令验证 | 前后均 50/50 通过；2 项减少拍数，0 项增加 |
| DDR 兼容验证 | 前后均 50/50 通过；全部执行拍数一致 |
| 扩展综合程序，BRAM | 2125 → 1980 拍，减少 145 拍 |
| MMIO load/store 程序，BRAM | 66 → 61 拍 |
| 原综合时序程序，BRAM | 852 → 852 拍 |
| CSR timer/中断/mret，BRAM | 5029 → 5029 拍 |
| 厂商 BRAM INIT 启动 | 实际厂商模型下 FPIOA0 UART 55 字节启动提示通过 |

50 份程序包括 46 份现有 RV32I/M 指令程序、扩展综合程序、原综合时序程序、MMIO 程序和 CSR timer 程序。仿真构建未出现组合环或锁存器警告，RTL diff 空白检查通过。

使用与上一轮完全相同的离线 CoreMark 单迭代 ELF/HEX，前后 list/matrix/state/final CRC 一致，最终 CRC 0xe714：

| 指标 | 本轮前 | 本轮后 |
| --- | ---: | ---: |
| 迭代次数 | 1 | 1 |
| 计时区间 ticks | 387052 | 381266 |

本轮额外减少约 1.49% 的计时拍数，对应该离线检查约 1.52% 的吞吐提升。单迭代运行时间不满足正式跑分条件，不将其输出当作正式成绩。生产固件、DAT/BIN 和厂商 RAM 初始化内容未被这份离线映像覆盖。

用户已于 2026-10-13 完成 PDS 编译和正式 3000 次迭代实板运行，结果见下节。扩展 load→访存地址前递后的组合路径在本次 70 MHz 编译中通过时序检查。

## 实板与资源结果（2026-10-13）

同为 BRAM、70 MHz、3000 次迭代，GCC 10.2.0 与编译选项一致。用户串口输出 Correct operation validated，seed/list/matrix/state/final CRC 与原生产结果一致，最终 CRC 为 0xcc42。

| 指标 | 本轮前 | 本轮后 | 本轮变化 |
| --- | ---: | ---: | ---: |
| Total ticks | 1160580397 | 1143222397 | 减少 1.496% |
| CoreMark | 180.94395 | 183.69129 | 提升 1.518% |
| CoreMark/MHz | 2.58491 | 2.62416 | 提升约 1.52% |
| 整个 SoC LUT | 4614 | 4569 | 减少 45，约 0.975% |
| CoreMark/SoC LUT | 0.03921629 | 0.04020383 | 提升约 2.518% |
| CPU setup WNS | +0.778 ns | +0.858 ns | 均满足 70 MHz |

本轮减少 17358000 个计时拍数，实板趋势与离线检查的 1.495% 拍数下降一致。本次 CPU fast-corner hold 最小余量 +0.111 ns，报告显示所有约束满足。

相对最初 BRAM 基线（1206606019 ticks、174.04190 CoreMark、2.48631 CoreMark/MHz、4342 LUT），两轮累计拍数减少约 5.253%，CoreMark 提升约 5.544%，CoreMark/SoC LUT 提升约 0.301%。当前同时超过最初基线的执行效率与资源效率，但资源效率增幅较小。

映射报告内部时间为 21:11:37，时序报告为 21:13:49，位流生成完成时间为 21:14:18。报告及实板指标保存到 `build/bram_forward_expansion/after_reports/` 和 `board_metrics_after.json`。资源比较统一使用整个 SoC LUT，CPU 层级资源需另行统计。

## 查看本轮修改

本轮独立快照和补丁位于 `build/bram_forward_expansion/`。

VS Code：右键 `before/cpu/Hexu.v`，选择“选择以进行比较”；右键 `after/cpu/Hexu.v`，选择“与已选项目进行比较”。`Hidu.v` 同样操作。左侧为本轮前，右侧为本轮后；编辑实际 RTL 时使用仓库 `cpu/` 下的文件。

Git 查看本轮差异：

```sh
git diff --no-index -- build/bram_forward_expansion/before build/bram_forward_expansion/after
```

`changes.patch` 仅含本轮差异；`bram_instruction_results.json`、`ddr_instruction_results.json` 和 `coremark_iter1/` 保存结果及日志。未创建提交或暂存用户修改。
