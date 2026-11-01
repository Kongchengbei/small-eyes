# 优化 CPU 接入当前 SoC

后续更新：DDR 时序优化已完成，当前结果见 [DDR时序闭合结果_20261031.md](DDR时序闭合结果_20261031.md)。以下数据保留为 CPU 接入/优化阶段的历史记录。

最新状态（2026-10-31）：进一步完成本地 CPU 时序优化，Full DDR 下 70 MHz CPU slow setup WNS +0.271 ns，CPU 全部报告检查通过；DDR/NPU 相关整机违例仍在。位流已生成、未烧录、未取得新实板跑分。以下接入内容为初始阶段记录，最终版本和验证范围见 [CPU时序优化结果](CPU时序优化结果_20261031.md)。

接入日期：2026-10-30。工程基线为 `a00aa3b`；CPU 来源为 main 的 `78cd22d87291476988d868bc3b048407293a4dbc`。该提交的 cpu 目录与历史实测版本 `823565a` 一致。初次接入阶段没有切换分支、合并整条 main、提交或推送；2026-10-31 按用户新指示将已验证状态纳入 main 合并提交。

## 接入内容

导入 cpu/Btb.v、Hexu.v、Hidu.v、Hifu.v、Htop.v、ReturnAddressStack.v、div.v、icache.v，共 8 个文件。包括通用乘法提前启动、前递策略统一、8 项返回地址栈、BTB 更新与存储推断优化、除法早退和 ICache 取消路径调整。CPU 对外端口保持不变。

project/project.pds 增补 ReturnAddressStack.v，包含 _format 与 _timespec，保留原文件其余内容和 CRLF。ReturnAddressStack.v 是当前分支新增的未跟踪文件，后续用户自行提交时应一并纳入。

## 当前配置保护

接入前后逐文件哈希核对，soc/Hfpga_soc.v、soc/Hnpu_image_service.v、soc/soc_addr_map.vh、soc.fdc、build/menuconfig/.config 保持不变，包含用户已有的 SoC 和 NPU 本地修改。仍为 Full DDR、70 MHz，摄像头与前处理开启。CPU 优化没有仅限 BRAM 的开关。

## 已做的检查

Htop 的 BRAM_MODE=0 和 1 两种配置均通过 Icarus 静态编译，只生成 elaboration 文件，没有执行仿真。完整 Full DDR SoC 通过 Verilator --lint-only，无错误结束；板级 IP 使用仓库已有的端口占位模块。因此它只检查语法与连线，不能证明实际 PLL/DDR IP、PDS 综合或板上功能正确。

Lint 仍有警告：3 个 JTAG 隐式网络、8 个 NPU 函数中间变量锁存器警告，以及位宽和 case 覆盖警告；本次未修改对应 NPU/JTAG 模块，不宣称零警告。详见 build/cpu_soc_integration/20261030_102223_364038/soc_full_static.log。

## 初次接入时的验证安排（历史记录）

重新加载 PDS 工程，从 Compile 开始完成综合、布局布线、时序和位流生成；检查完整系统各时钟域。历史优化 CPU 的 Full DDR 运行曾出现 CPU setup -0.608 ns，不能用 BRAM 时序通过代替本次完整系统验收。新位流生成后，再复核启动、CoreMark 和摄像头/NPU 识别行为。

此次只替换 CPU RTL，没有改 CPU ISA、内存地址或程序协议，现有匹配模型的 Flash 固件包无需仅因 CPU 替换而重新编译。

## 证据和回退

修改前文件、修改后快照与哈希清单保存在 build/cpu_soc_integration/20261030_102223_364038/。before/ 是修改前快照，after/ 是修改后快照；原来不存在的 ReturnAddressStack.v 记在 manifest.json 的 absent_before 字段。仅按清单恢复本次文件，避免覆盖之后的新工作。

初次接入阶段没有运行 PDS。此后已按用户授权执行多轮 PDS 完整流程，并继续优化 CPU 时序；最新结果及源码归档见 [CPU 时序闭合记录](CPU时序闭合_20261030.md)。时序优化阶段没有编写或运行 testbench、烧录或修改频率；本次合并按用户授权提交到 main，未推送。
