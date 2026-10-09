# PDS 大规模分配诊断记录

## 范围和验证边界

- 仅使用隔离的 `/tmp/int8-index-probe` 源副本与 Windows Temp 副本做 PDS **Compile/RTL parse**。没有运行 testbench、synthesis、device map、place-and-route、下载或烧录。
- 原始 DDR 地址映射未被诊断变体修改。当前 `soc/soc_addr_map.vh` 中 DDR 为 `0x8000_0000`、`0x4000_0000` 字节，范围到 `0xC000_0000`；INT8 块位于已有区域内。`0xB880_0000` 是地址值，不代表本次新分配了同等大小的 DDR。
- 本次成功 FullSocComb 对照使用 `SOC_ENABLE_PREPROCESS=0`、`SOC_ENABLE_DDR=1`、`SOC_ENABLE_CAMERA=1`。该次 PDS 的 155 源 RTL 文件清单仍包含 INT8 RTL；`Hfpga_soc.v` 仍实例化 `Hpreprocess_stereo`、`Hrgb565_int8_regs`、`Hrgb565_int8_stereo` 和 `Hrgb565_int8_ddr_merge`（本次验证快照约 1127、1182、1194、1234 行）。PRE0 关闭前处理功能路径，不会从 PDS 的 Compile 源清单中移除这些模块。
- 先前 PDS 报错 `E Memory alloc failed for size 17179869224` 是主机进程申请约 16 GiB 的内存，不是 DDR 地址 map 扩展。本记录中该错误与 FullSocComb 的独立 Temp 包错误分开处理。

## 已有 probe 结果

| Probe / 设计 | 已观察结果 | 可支持的结论 |
|---|---|---|
| A、B | Compile 完成；约 5 秒、峰值约 138 MB | 小型 selector/索引路径可正常通过 Compile。 |
| F | Compile 完成；约 3 秒、峰值约 133 MB | 该简化对照可正常通过 Compile。 |
| E | review 报告 Compile 完成；峰值落在约 133–156 MB 的已报告范围 | 小型对照可通过；此处不据此断定大设计根因。 |
| C | 56 次静态扫描、`integer found_count`、两组动态数组写；120 秒超时停在 FSM inference | 该结构会触发本次可重复的慢点。 |
| D | C 的数组索引收窄为 3 位；仍在 FSM inference 超时 | 单独收窄数组写索引没有消除慢点。 |
| G | `found_count` 收窄为 4 位、直接数组索引；仍在 FSM inference 超时 | 单独收窄计数器位宽没有消除慢点。 |
| CJ6 | C 只把循环变量 `j` 改为 `reg [5:0]`，范围仍为 0..55；仍在 FSM inference 超时 | 单独收窄循环变量位宽没有消除慢点。 |
| H | 保留 56 次扫描和 integer 计数，只去掉动态数组存储；Compile 通过 | 慢点与扫描/计数本身并不足以解释，数组写路径参与是更强的候选因素。 |
| H2 | 两组动态数组写替换成 `case` 的常量左值；仍观察到 FSM hang | 仅把动态左值写成常量 case 不足以解除慢点。 |
| CDataInput | 保持 C 的动态左值、56 次扫描与 integer 计数，仅把两个数组 RHS 改成外部 `data_value`；9.1 秒、峰值约 277 MB 通过 | RHS 内容或由此触发的综合器识别变化值得继续隔离；当前还不能断言是唯一根因。 |
| CSlotOnly | 只保留一个 6 位数组的动态写，仍停在 FSM inference | 慢点不要求存在 32 位地址数组；单一小数组写也可能触发。 |
| FullLane 原版 | 完整 lane 在 RTL inference 约 90 秒后停在 FSM inference（超时记录） | 完整模块与小型 C 探针有相同症状，但这本身不是数组状态被展开的证明。 |
| LaneComb | 与原 lane 等价的组合 first-free 预选改写；Compile 完成，约 113.6 秒、峰值约 511 MB；RTL inference 约 80 秒，FSM 阶段通过 | 说明组合预选版本在 Compile 阶段可以完成；耗时仍明显高于小型对照。 |
| FullSocComb 首轮 | Compile/parse 失败于 `Verilog-4104`：加密 DDR PHY 源 `ips2l_ddrphy_slice_top_v1_16.vp:190` 引用了缺失的 `rtl/ddrphy/localparam.vh` | 是 Temp 包漏拷隐藏 include，不是 FullSoc RTL 编译结果。原 IP 树共有 5 个 `.h/.vh`；旧 Temp 只拷了 `define.vh`。runner 正在补全 IP headers。 |
| FullSocComb 补包重跑 | Windows Temp GUID `f39c52ee827243ffac04c2b86f166242`；PDS PID 11824、exit 0；Compile 全部成功。实际 486.3 秒，PDS Action 7 分 58 秒、CPU 1 分 57 秒、峰值 744 MB；FSM 阶段 5.667 秒；stderr 与 `error_info.txt` 均为 0 字节 | 在相同 Full DDR + CAM、PRE0 的完整 source/config 下，LaneComb 版本通过 Compile。此结果是 Compile-only，不代表综合或布局布线通过。 |

## 当前解释：证据与假设

已证实的是：慢点发生在 PDS FSM inference 阶段；C/D/G/CJ6/H2/CSlotOnly 的对应 run 超时，而 CDataInput、H 和 LaneComb 的已报告 Compile 能完成。把 `found_count`、数组索引或循环变量分别缩窄，都没有单独解除慢点。

对照结果显示，原版 descriptor clocked first-free reservation 的循环计数/动态数组写组合与慢速 FSM 阶段相关，而 LaneComb 的等价组合预选实现通过了 FullSoc Compile。现有证据尚不能确认这是唯一触发因素，也不能确认 PDS/Synplify 如何处理这些数组：它可能把动态写入的数据结构识别为 FSM 状态集合；`batch_slot_addr[0:7]` 32 位地址数组是一个候选，但 32 位×8 存储本身不证明发生了 `2^32` 状态枚举，CSlotOnly 的 hang 也表明不能只归因于单一 32 位地址数组。内部误识别或展开机制仍未确认。

属性版 `syn_state_machine = "0"`、LaneIndexOnly、LaneNoFsmBatch 等仍需以其各自的 Compile 日志判定是否接受属性、是否完成；不要把准备好的源码当作已验证结果。

## FullSocComb 最终结果与源快照核对

- 完整 SoC 的 LaneComb Temp run 已成功：`C:/Users/LEGION/AppData/Local/Temp/pds_int8_probe_f39c52ee827243ffac04c2b86f166242/FullSocComb`，PDS PID 11824，exit code 0。Compile 全程 486.3 秒，PDS Action 7:58，CPU 1:57，峰值内存 744 MB，FSM 5.667 秒；PDS stderr 和 `work/compile/error_info.txt` 都为空。
- 独立读取当前原工程 PDS filelist并逐项 SHA-256 对比该成功 Temp：155/155 RTL 源都存在；155 项非 lane 源与当前工程 **0 差异**。被替换的 `soc/Hrgb565_int8_lane.v` 是 LaneComb，SHA-256 `90c86dd8327507b6fd7b3cbeca9178a89d621976a3532a68bc5e96ef9703d986`；原 lane SHA-256 `d271fc155119a7ba06b3fddff37b5fb9ae4a9ef43a59c73a5a0c196f7d295047`。
- 12/12 个头文件及 RAM 初始化依赖都存在于成功 Temp，且相对 `/tmp` source package 与当前工程逐项 SHA 一致。12 项包括 Verilog include `.vh` 和 PDS/RTL 列表所依赖的初始化 `.v` 文件；其中加密 DDR PHY 所需 `IP/ddr3_ctrl_v116/rtl/ddrphy/localparam.vh` 已包含。FullSocComb 首轮 4104 是漏拷此加密隐藏依赖；补齐后重跑成功。
- 原工程基线：Git HEAD `f5da990d96dcc068aaa57e9c8a7257ae04fc853e`；复核改动前 `git diff --binary | sha256sum` 为 `d68f582875f258389c97470008947819994cd8cae3ec8769e88247812631ccc0`。成功 FullSocComb 副本与本次验证工作区在配置文件哈希上相同：`soc/soc_addr_map.vh` 为 `a260e8ba580fb91bf70264c9b15580094346c47622afe06d7de49dc038717ffb`，`soc/config.v` 为 `1346e11a1b7dd01edbead15d96d02e24e90a4bd1c14004b54134c0decb267f8d`；本次对照配置为 DDR=1、CAM=1、PREPROCESS=0。该成功试验使用独立 Temp 副本，随后才将同一已验证 LaneComb patch 应用到工作树；其他既有工作区改动未触碰。

## 结论边界

对照结果将异常编译的触发结构指向原时钟过程中的 56 槽预订扫描、累计计数和动态批次数组写入。等价改写在相同配置的完整 SoC Compile 成功；现有日志不能确认精确 16 GiB 申请对应的内部对象或唯一内部机制。原逻辑在修改前 Git HEAD 的 `soc/Hrgb565_int8_lane.v` 第 311–320 行；当前候选实现位于 [Hrgb565_int8_lane.v](/mnt/f/SocFpga/soc/Hrgb565_int8_lane.v:365)。成功对照使用原 DDR map，没有扩展 DDR 地址范围。

**未证实的内部机制：**不能据此宣称综合器已把数组误认成 FSM 状态、枚举出 `2^32` 张量地址或真的展开出某个精确大小的状态表。原来的 `E Memory alloc failed for size 17179869224` 是 PDS 主机进程的约 16 GiB 内存申请；DDR 映射没有因此增大。该精确的内部原因仍需 PDS 更详细的 FSM/内存报告才能确认。

最终仍只验证了 PDS Compile/RTL elaboration。没有运行 testbench、synthesis、device map、place-and-route 或 FPGA 下载。经批准的 LaneComb unified diff 已应用到 `soc/Hrgb565_int8_lane.v`；当前该文件 SHA-256 应为 `90c86dd8327507b6fd7b3cbeca9178a89d621976a3532a68bc5e96ef9703d986`，与成功 FullSocComb 临时副本中的 lane 完全一致。
