# 最新整机 PDS 结果（2026-10-31）

CPU 70 MHz 时序已通过：slow setup WNS +0.271 ns / TNS 0 / 失败端点 0；fast setup +5.934 ns，slow hold +0.148 ns，fast hold +0.103 ns。CPU 两角 recovery/removal、最小脉宽均通过。

整机仍为 Some Constraints Violated：DDR core setup WNS -2.485 ns / TNS -9417.415 ns / 10455 个失败端点，另有 DDR/PHY 跨域 reset recovery 违例。CPU 优化没有修改这些 RTL、时钟或约束。

资源：SoC 模块 LUT 44860、FF 47571、Distributed RAM 1151、APM 69、DRM 35；CPU 模块 LUT 5256、FF 3683、Distributed RAM 45、APM 4、DRM 10。物理 LUT 48412（36917+11495），不能混用统计口径。

PDS 全流程完成，位流已生成、未烧录、没有 testbench/仿真或新实板成绩。报告时间 2026-10-31 12:00:43，位流完成 12:02:13。配置和版本说明见 [CPU时序优化结果](CPU时序优化结果_20261031.md)；对应原报告、日志、CPU 源码及哈希在 [证据](证据/FullDDR_CPU时序闭合_20261031/result.json)。

初次接入时 CPU setup -0.853 ns / DDR core -2.693 ns 的 10 月 30 日报告仍保存在证据/FullDDR_优化CPU接入后/，仅用于比较。
