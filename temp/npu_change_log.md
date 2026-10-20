# NPU 修改与 P&R 复盘记录

## 2026-10-17：建立基线

### 当前状态

- 工作区包含人员 A 的 RTL 清理和 NPU CNN 引擎优化修改，尚未提交。
- `soc/Hnpu_service.v` 当前只接入 `Hnpu_cnn_engine`；旧 FC、旧 DMA、旧量化路径已经从工程文件和测试入口移除。
- `soc/Hnpu_cnn_engine.v` 已使用单口串行模型读取、双 tensor bank、BRAM 属性、卷积 MAC/量化分阶段和固定移位实现。
- `soc.fdc` 已加入 125 MHz DDR 参考时钟（8 ns）及 `ddr_core_clk` 约束，并声明 CPU 与 DDR 时钟域异步。

### 已知历史结论（本轮不得重复试验）

- 旧的 `model_meta_mem` 动态多端口读取会复制大量 RAM 并造成严重拥塞；已改为从 `model_mem` 串行读取 descriptor。该方案曾把 distributed RAM 从约 13,986 降到约 1,186，并有过 route succeed 结果。
- 不再恢复或重复动态多端口 descriptor RAM 方案。
- 不通过放宽时钟约束、错误声明时钟异步或 false path 来掩盖 NPU 时序问题。
- CPU DCache Tag RAM 路径属于用户明确暂不处理的非 NPU 问题。

### 可复核的旧报告基线

报告文件：`project/place_route/run.log`、`project/report_timing/bak/rtr.db`。

- Place：16.69 s。
- Route：150.80 s；其中 detailed routing 70.12 s、hold fix 53.75 s。
- P&R：5 min 02 s，`32773/32773` nets routed，route succeed。
- 该报告生成于 2026-10-09，早于当前工作区 2026-10-16/17 的 RTL 和约束修改，不能作为当前版本验收证据。
- 旧 timing summary 的最差 setup path 是 CPU DCache Tag RAM 到 IFU，slack 0.990 ns、17 logic levels；没有找到当前 NPU 版本的 588 级路径条目。
- 旧综合日志曾对 DDR PHY 内部时钟自动创建 1000 ns 约束；因此旧报告不能证明真实 125 MHz DDR 下 NPU 时序。

### 本轮复盘结论

- 目前没有足够证据证明 Place 偏慢由当前 NPU RTL 引起，也没有足够证据证明 NPU 已在 125 MHz DDR 约束下收敛。
- 下一步先运行 RTL/仿真回归并检查综合资源；只有得到与当前源码对应的 PDS compile/synthesize/place/route/timing 结果后，才修改 NPU 或约束。
- 任何方案必须同时观察：P&R 时间、unrouted/overused、NPU 时钟 setup/hold、BRAM/DRM/LUT 资源和功能回归结果。

## 2026-10-17：挂载 PDS 工程版本核对

### 证据

- 本地 `soc/Hnpu_cnn_engine.v` SHA256：`9ee76cc4...60adc27`；挂载工程同名文件 SHA256：`c52d4613...303b43`，两者不同。
- 本地 `soc.fdc` SHA256：`05bb5ec6...11822ec`；挂载工程同名文件 SHA256：`5f9a2d59...e6bda1ba`，两者不同。
- 挂载工程的 `project.pds` 仍包含已删除的 `Hnpu_fc_engine.v`、`Hnpu_quant.v` 和旧 `Hnpu_dma.v`，并使用动态 `model_meta_mem`；这不是当前工作区的工程输入。
- 挂载工程的 Place/Route 报告约为 Place 447.58 s，约 99k nets，Route 第 9 轮有 60,152 条未布通网络和 279,463 个 overused 资源。该数据只能说明挂载工程失败，不能归因到当前本地 RTL。

### 复盘与决策

- 本次核对解决了报告归属问题，但没有产生可用于当前源码的 P&R 优化证据。
- 不把挂载工程的失败结果继续用于指导本地 RTL 修改，避免在错误版本上重复试验。
- 在当前仓库回归通过后，必须让 PDS 工程重新同步当前 `project/project.pds`、`soc.fdc` 和 RTL，再运行综合/Place/Route/Timing；同步前停止 P&R 参数和 RTL 方向的迭代。

## 2026-10-17：统一 batch tensor bank 上限

### 修改

- 文件：`soc/Hnpu_service.v`
- 将 `Hnpu_service` 的 `MAX_TENSOR_BYTES` 从引擎实例中的硬编码 `65536` 改为可配置参数，默认 `16384`。
- 依据：B-CNN32-v0.3 的最大中间张量为 16 KiB；batch service 已固定接收 32×32×4、4096-byte 输入，16 KiB 足以覆盖四层卷积/池化的最大中间结果和双 bank scratch 约束。
- image service 原本已经显式使用 `16384`，本次将 batch service 与之统一。没有改变 AXI、模型格式、结果接口或计算顺序。

### 验证

- `CCACHE_DISABLE=1 make npu-test`：通过，`NPU_TEST_PASS count=12 simulator=verilator`。
- v0.3 逐层验证：两种输入源均通过，`cases=16`、`layer_checks=144`；最大周期 `3,823,422`，仍低于 `4,375,000` 门槛。
- Verilator lint：退出码 0，无 Error；保留已有 WIDTHTRUNC/WIDTHEXPAND/BLKSEQ 警告，未发现本次修改新增的语法错误。

### 复盘与决策

- 修改达到了预期的资源边界统一，功能回归无变化；该方向可保留。
- 该修改只影响 batch 分支的 BRAM 深度，不足以单独证明 Place 时间改善；必须在当前源码同步到 PDS 后比较综合资源、Place 时间和拥塞。
- 后续核实发现 Windows PDS 可通过 WSL 的 `cmd.exe` 启动，因此此前“工具不可运行”的判断已过时。本轮在用户指定由其启动 GUI 后停止所有自主 PDS 批处理，只读取 GUI 运行日志。

## 2026-10-17：当前 D 盘工程 Compile/Synthesize 核对

### 工程选择与同步

- 使用的是 Recent Projects 列表中的第二个工程：`D:/HPUfile/JiChuang/npu/small-eyes/project/project.pds`，不是 `small-eyes-pds-WiJwtg`、`small-eyes1` 或 SparrowRV。
- 已同步当前工作区的 `project.pds`、`impl.tcl`、`soc.fdc`、`Hfpga_soc.v`、`Hnpu_cnn_engine.v`、`Hnpu_service.v`、`Hnpu_system.v` 到 D 盘。
- PDS 启动后自动刷新 `project.pds` 的生成时间和 `_timespec`，并向 D 盘 `impl.tcl` 追加运行命令；这些是工具生成元数据变化。RTL 与 `soc.fdc` 哈希复核仍一致，工程中没有旧 `Hnpu_dma/Hnpu_fc_engine/Hnpu_quant` 引用。

### 验证结果

- 当前版本 Compile：通过，2 分 10 秒，峰值内存 792 MB；日志识别并解析当前 CNN 引擎，无 Verilog 编译错误。
- 当前版本 Synthesize：通过，9 分 58 秒，峰值内存约 2.8 GB。
- 综合资源：DRM 35/415；LUT-as-DRAM 1,188/39,500；逻辑 LUT 57,124；总 LUT 58,312；寄存器 44,799；控制集 1,379；最大扇出 2,456。
- NPU 的 `tensor_a`、`tensor_b` 各为 16K x 8，分别映射为 4 个 `GTP_DRM36K_E1`（每个 16K x 2）；NPU 大块 tensor scratch 确认使用片上 DRM，不是 LUTRAM。模型缓存也在综合 RAM 资源表中，待 Device Map/最终报告继续核实具体映射细节。
- `ram_style` 属性被 PDS 报为不支持并忽略，但实际 RAM 资源表证实 tensor scratch 映射到了 DRM，因此不能把该警告误判成 LUT 实现。
- `soc.fdc` 中 8 ns DDR_REF_CLK、由其生成的 `ddr_core_clk` 及异步组约束均被 PDS 成功解析。

### Place 流程状态与复盘

- 一次 `-run dev_map` 批处理自动依赖重跑 Compile/Synthesize；用户随后明确改由其 GUI 启动、我只看日志，因此已只终止自己启动的 PDS Shell 进程，保留用户 GUI 及 `small-eyes-pds-WiJwtg` 进程。
- 该第二次依赖综合在完成前中止；不能作为成功或失败的综合结果，也没有产生当前版本 Device Map、Place/Route 或 Timing 数据。
- 本轮解决了当前 D 盘版本归属和综合/BRAM 映射不确定性；没有解决 Place 慢或 NPU 时序违例。当前不能报告 Place 时间、拥塞、合法性或 NPU slack 的前后改善。
- 复盘：NPU scratch 片上存储目标符合预期；没有修改 RTL，未重复历史上失败的动态多端口 descriptor RAM 方案，也没有放宽约束。下一步只监控用户从 GUI 启动的第二个工程日志；若当前 P&R 仍超时或严重拥塞，再根据同版本 Place 报告定位，不先猜测性修改。

## 2026-10-17：平衡 NPU 地址乘法归约树

### 修改

- 文件：`soc/Hnpu_cnn_engine.v`
- 将 `mul_u16_no_dsp` 和 `mul_u32_u16_no_dsp` 中 16 项串行 shift/add 累加改为 16 个部分积、4 层平衡加法归约。
- 保持 32-bit 模乘结果、模块接口、模型和 descriptor 语义不变；仍不使用 `*` 运算符，不把地址计算映射到 MAC/APM。CNN 的 MAC 发射速率和运算周期数不变。
- 目的：缩短组合地址/尺寸乘法的加法依赖深度，降低综合和后续时序优化所面对的串行 carry 链。此项是可验证的结构性优化假设，PDS 的综合时间、资源和 Place 收益必须由重新运行确认，不能由 RTL 仿真推断。

### 验证

- `bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12 simulator=verilator`。
- v0.3 逐层金样：32x32 输入 `cases=16`、`layer_checks=144`、最大周期 `3,789,459 < 4,375,000`；96x96 输入 `cases=16`、`layer_checks=144`、最大周期 `3,823,422 < 4,375,000`。两种输入路径均通过，结果与参考逐层输出一致。
- Verilator 编译覆盖此 Verilog 函数实现及所有 NPU 测试；测试没有新增独立乘法器算术单元测试，算术等价性由 v0.3 模型逐层金样和集成回归覆盖。
- 未运行 PDS，未取得本次修改后的综合、Device Map、Place/Route 或 Timing 报告。

### 复盘与决策

- 功能等价及周期门槛符合预期，未重复动态多端口 RAM 或约束放宽等已否决方案。
- 该结构把加法归约的串行依赖从 15 个加法级变为 4 个归约级；但每个树节点仍是 32-bit 加法，实际 PDS LUT/APM 资源、综合耗时及 Place 效果尚无证据。
- 保留该改动并交由下一次 PDS 综合验证。若综合资源显著增加或综合耗时无改善，基于同版本报告重新评估；不在没有报告的情况下继续叠加猜测性 RTL 优化。

## 2026-10-17：通用 GAP 除法改为迭代实现

### 修改前复盘与诊断

- 最新 D 盘 GUI P&R 日志实际已完成，不是仍卡在 Place：Place `300.20 s`，Detailed Route `1120.52 s`，总 Route `1309.59 s`，`86587/86587` nets routed，工具报告 placed and routed successfully。
- 但收敛状态仍为 `Fail`：Place 后 WNS `-108.218 ns`，TNS `-450886660`，Setup(Slow) 失败端点 `20824`；器件利用率 `37%`，不是整体资源耗尽。
- 时间主要消耗在 timing-driven global placement：Global placement `187.91 s`，第二轮 GP `166.08 s`。日志显示 NPU `layer_in_w` 位被复制以缓解扇出，说明布局受时序/扇出优化牵引；当前日志没有路径级起点、终点和逻辑锥，故不能断言 NPU 是全部违例的唯一来源。
- RTL 中通用 GAP 原先直接使用 32/64-bit 累加器动态除以 `layer_in_h * layer_in_w`。这会形成宽位宽的组合除法候选路径；当前 v0.3 的 4x4 GAP 实际走固定 `(sum+8) >>> 4` 分支，不需要动态除法。
- 参考依据：Yosys 开源综合器 `techlibs/common/techmap.v` 将 `$div` 映射为按位展开的 `__div_mod_u` stage 链（https://github.com/YosysHQ/yosys/blob/main/techlibs/common/techmap.v#L314-L343）。这证明通用除法可能带来深组合逻辑；不代表 PDS 必然使用相同映射，最终收益必须由本器件 PDS 报告验证。

### 修改

- 文件：`soc/Hnpu_cnn_engine.v`
- GAP 累加器从 64 位收窄到 32 位。引擎最大输入元素数受 `MAX_TENSOR_BYTES` 限制，默认上限 65536；INT8 最坏和为 `65536 * 128 = 8388608`，在 signed 32-bit 范围内。
- 保留 v0.3 4x4 的舍入右移快路径，结果和周期行为不变。
- 非固定 4x4 GAP 不再使用 `/` 组合除法，改用 32 轮 restoring divider 状态机；有符号输入通过绝对值除法后恢复符号，语义保持向零截断。每个通道增加 32 周期，仅影响通用 GAP 慢路径，不影响已冻结 v0.3 模型的 MAC 吞吐或每 ROI 周期。
- 未改 AXI、时钟约束、MAC 并行度、模型格式或 tensor BRAM。
- 新增常规测试用例，直接覆盖 divider 负数语义 `-7 / 4 = -1`。

### 验证

- `CCACHE_DISABLE=1 bash temp/tests/run_npu_tests.sh`：通过，包含新增负数 GAP 用例；末尾 `NPU_TEST_PASS count=12 simulator=verilator`。
- v0.3 32x32 输入：16 cases、144 layer checks，最大周期 `3789459 < 4375000`。
- v0.3 96x96 输入：16 cases、144 layer checks，最大周期 `3823422 < 4375000`。
- `git diff --check -- soc/Hnpu_cnn_engine.v temp/tests/tb_npu_cnn_engine.sv temp/tests/run_npu_cnn_test.sh temp/npu_change_log.md`：通过。
- 当前 GUI/PDS 由用户启动。本次修改后尚未重新运行 PDS，因此综合面积、WNS/TNS、Place 和 Route 是否改善均未验证；上述 P&R 数字是修改前基线。

### 修改后自我复盘与下一步

- 修改消除了 RTL 中通用 GAP 的动态组合除法候选路径，并缩小其累加器；功能回归与模型金样符合预期。
- 这是针对已确认的高风险结构所做的有限优化，不是对唯一关键路径的确认，也不能单凭仿真宣称 Place 已变快或时序已收敛。
- 未重复尝试动态多端口 descriptor RAM、放宽时钟约束或降低 MAC 并行度等已否决方向。
- 下一步把本地 `soc/Hnpu_cnn_engine.v`、`temp/tests/tb_npu_cnn_engine.sv`、`temp/tests/run_npu_cnn_test.sh` 同步到 D 盘的 `project/project.pds` 工程并由用户重跑 Compile/Synthesize/Place/Route。若收敛仍失败，先对这次对应的 routed DB 生成 top setup paths（起点、终点、逻辑级数、时钟组）及 NPU/CPU 分组报告，再决定下一处 RTL 修改；不要仅凭 WNS 猜测修改地址逻辑。

## 2026-10-17：新时序报告确认 GAP 为首要 DDR 关键路径

### 报告与版本核对

- 新报告：`/mnt/d/HPUfile/JiChuang/npu/small-eyes/project/report_timing/Hfpga_soc.rtr`，工具版本 Fabric Compiler 2022.2-SP6.4，时间 `2026-10-17 09:56:02`，器件 PG2L200H。
- DDR `ddr_core_clk` 要求 8 ns / 125 MHz，报告估算周期 `113.658 ns`、频率 `8.7983 MHz`，WNS `-105.658 ns`；该组 Setup(Slow) 有 `19555` 个失败端点，TNS `-439697.046 ns`。
- 最差路径起点是 NPU `tensor_b_2` DRM 的 `CLKB[0]`，终点为 CNN engine 的 `N13899_sub0...CIN`，路径组 `ddr_core_clk`。数据路径串过综合器生成的 `N13899_sub63` 到 `N13899_sub0` 减法级；前三条最差路径均从同一 tensor BRAM 读口进入同一减法链，slack 分别为 `-105.658 ns`、`-104.628 ns`、`-104.620 ns`。
- 对照该次 D 盘 RTL，GAP 仍包含 `next_gap_accumulator / mul_u16_no_dsp(layer_in_h, layer_in_w)`；因此报告对应的是旧组合除法实现，不是本地迭代除法改动。D 盘文件 SHA256 `8cd78399553334b576054137c9612831567524a275bffb51e120467098bf54f1`，与本地修复版不同。该次 bitstream 虽生成成功，但不能用于验收本地时序修复。

### 按关键路径进一步收窄

- 本地 `soc/Hnpu_cnn_engine.v` 保留 32 周期 restoring divider，但每拍只对 18-bit `{remainder, dividend_bit}` 做一次减法；余数/空间除数宽度为 17 bit，并从同一次减法的最高位判断是否取商位，避免独立宽比较器。
- 17-bit 除数覆盖最大 `H*W=65536`；本引擎 tensor 上限为 65536 个 INT8 元素，service 实际配置为 16384。累加仍为 signed 32-bit，足以覆盖 `65536 * 128` 的绝对上界。
- 固定 4x4 v0.3 GAP 仍使用原舍入移位，不经过 divider；AXI、时钟约束、卷积 MAC 和 BRAM 均未改。

### 验证与复盘

- `CCACHE_DISABLE=1 bash temp/tests/run_npu_tests.sh`：通过；包含 `-7/4=-1` 有符号 GAP 专项。
- v0.3 32x32 / 96x96：各 16 cases、144 layer checks 通过，最大周期分别 `3789459` / `3823422`，低于 `4375000` 门槛。
- SoC 集成 lint 和 `git diff --check` 通过。
- 这次本地修复正对报告证实的主关键路径；功能回归已证明语义与周期不回退，但本地 P&R 仍未运行，不能声称 WNS 已改善。当前 D 盘 bitstream 和报告来自旧 GAP RTL。
- 下一步应把本地 `soc/Hnpu_cnn_engine.v`、`temp/tests/tb_npu_cnn_engine.sv`、`temp/tests/run_npu_cnn_test.sh` 同步至 D 盘工程并重新综合、Place/Route、`report_timing`。期望该 `tensor_b -> N13899_sub*` 除法链不再出现；若新 WNS 仍差，再以新报告中的下一条真实路径继续优化，不改 DDR 8 ns 约束掩盖问题。

## 2026-10-17：修复 PDS Compile 混合赋值错误

### 诊断与修改

- D 盘 `project/compile/run.log` 在 `Hnpu_cnn_engine.v:760` 报 `Verilog-4042: Cannot mix blocking and non-blocking assignments to variable gap_div_take`。该变量在复位分支用非阻塞赋值，在 `ST_GAP_DIV` 用阻塞赋值；这是唯一致命编译错误。`Hrgb565_int8_lane` 的 case 告警及 PDS 忽略 `ram_style` 属性均为非致命项。
- 删除 `gap_div_take` 临时变量和复位赋值，直接用 `!gap_div_subtracted[17]` 生成商位并选择余数。没有改变 restoring divider 的状态周期、除法结果、接口、DDR 时序约束或 MAC 并行度。

### 验证与复盘

- `CCACHE_DISABLE=1 bash temp/tests/run_npu_tests.sh`：通过，末尾 `NPU_TEST_PASS count=12 simulator=verilator`。
- v0.3 两种输入路径均通过：各 16 cases、144 layer checks；最大周期分别为 `3789459` 和 `3823422`，低于 `4375000` 门槛。负 GAP 专项 `-7/4=-1` 通过，SoC 集成 lint 通过。
- `git diff --check` 通过。D 盘 RTL 修复后的 PDS 编译尚待用户重新运行，因此当前没有新的 PDS 综合/时序证据。
- 复盘结论：修复针对日志指出的 Verilog 赋值规则冲突，功能和周期回归未见变化，值得保留；不是重复已否决方案。下一步同步 RTL 并重跑 Compile。若编译通过，继续核验综合和新时序报告；否则根据新日志首个 `E:` 错误继续处理。

## 2026-10-17：GAP 修复版 P&R 与时序报告复核

### 流程结果

- D 盘当前版本 Compile、Synthesize、Device Map、Place/Route、Report Timing 和 Generate Bitstream 均完成；P&R 用时 `51m10s`，Place `406.03s`，Route `2495.95s`，其中 detailed routing `2319.53s`、router hold fix `115.03s`。
- 全部 `85362/85362` nets routed，Fabric Compiler 报告 placed and routed successfully；bitstream `project/generate_bitstream/Hfpga_soc.sbit` 已生成，大小约 `9.19 MB`。
- 这是布线成功，不代表时序收敛。

### 时序结果与路径归属

- 新报告 `project/report_timing/Hfpga_soc.rtr`，生成于 `2026-10-17 11:33:36`。DDR 约束仍为 8 ns / 125 MHz。
- Slow corner `ddr_core_clk` WNS `-42.603 ns`、TNS `-275776.325 ns`、`19952/107123` 个 setup 端点失败；报告估算最高频率 `19.7617 MHz`（周期 `50.603 ns`）。Fast corner同组 WNS `-20.686 ns`、`13816` 个失败端点。
- 最差 setup 路径起点 `u_rgb565_int8/lane[1].u_lane/slot_generation[0][31]`，终点 `.../batch_slot_addr[0][12]`，111 logic levels；数据到达 `55.771 ns`，其中逻辑 `18.724 ns`、布线 `31.342 ns`。次差两条也是同一组 slot-generation 到 batch-slot-address 路径，slack 约 `-42.58 ns`。
- RTL 对照 `soc/Hrgb565_int8_lane.v` 的 56 项组合 first-free/slot 选择扫描（约 163-214 行）和 `selected_slot_addr` 提交逻辑；此路径不在 `Hnpu_cnn_engine`，属于 RGB565 前处理/slot 管理逻辑。报告中唯一展示的 NPU path 是 `result_box_mem -> result_fifo` 的 slow-corner hold path，slack `+0.136 ns`，为满足；报告没有单独列出 NPU engine 的 worst setup path，故不能据此断言全部 NPU setup 路径均收敛。
- 与 GAP 修复前的旧报告相比，最差 setup 从 NPU tensor BRAM -> 579-level 宽除法链（WNS `-105.658 ns`）转为上述前处理路径（111 levels，WNS `-42.603 ns`），整体 WNS 改善 `63.055 ns`。瓶颈已转移，但全 SoC 仍未达到 125 MHz。

### 复盘与决策

- NPU GAP 结构修复消除了旧报告确认的首要 579 级逻辑锥；最新全局最差路径不再属于 NPU。RTL 仿真、逐层金样和 SoC lint 之前均通过，PDS 本轮也成功走完。
- 总体 WNS 仍失败，不能将 bitstream 描述为 125 MHz 时序通过。当前可见瓶颈是前处理的组合 slot 扫描；依据用户限定的“只改 NPU 导致的时序问题”，本轮不修改该模块。
- 下一步如需验收 NPU 本身，应由 PDS 生成以 `u_npu_system` / `Hnpu_cnn_engine` 为起终点过滤的 setup timing 报告。若继续优化全 SoC WNS，则需另行授权处理 `Hrgb565_int8_lane`，并验证改变 56-slot 扫描实现不会破坏 bank 分配行为。

## 2026-10-17：重构 RGB565 lane 的 56-slot 分配优先扫描

### 修改前复盘与依据

- 按上一条结论，用户明确要求优化 Place 阶段和全局时序，因此本次处理此前暂缓的 `Hrgb565_int8_lane` slot 组合逻辑。
- D 盘 2026-10-17 11:33 timing report 仍显示 DDR 125 MHz 约束下 slow-corner WNS `-42.603 ns`、TNS `-275776.325 ns`、19952 个 setup 失败端点。最差路径从 `slot_generation[0][31]` 到 `batch_slot_addr[0][12]`，111 logic levels；逻辑延迟 18.724 ns、布线延迟 31.342 ns。源码对应 56 槽串行 first-free 扫描、每槽递增 selected_count，并在扫描中更新所选地址。
- 参考 AMD《Vivado Design Suite User Guide: Synthesis (UG901)》中的可综合 RTL 编码/逻辑推断指导：<https://docs.amd.com/r/en-US/ug901-vivado-synthesis>。据此采用明确的组合分组计数/归约结构，而不是依赖工具将循环累加自动重构为平衡逻辑。该指南不保证本项目 PDS 的 QoR，最终频率和面积必须由 PDS 实测。

### 修改

- 文件：`soc/Hrgb565_int8_lane.v`
- 新增同文件的 `Hrgb565_first_free_selector` 组合模块，将 56 个 slot 分为 7 组、每组 8 个。8 位 popcount 使用两两求和的平衡树；每个可用 slot 的 rank 为前序组计数加组内低位可用数。
- `reserve_mask` 由每个 slot 独立产生；8 个 slot index 先按 rank 做组内 one-hot 编码，再通过分层 OR 树合并，避免 procedural 赋值推导出新的优先 mux 链。slot 地址只在 rank 选出索引后计算。`free_count` 复用分组计数的平衡归约，不再保留另一个 56 项串行累加器。
- lane 的 allocatable 条件保持原样：slot 必须空闲且 generation 未饱和。最低 slot 编号优先、最多分配 8 项、请求数语义均保持；模块接口、状态机、descriptor 接收周期和 DDR 事务不变，没有插入流水或额外等待周期。
- 新增 `sim/tb_rgb565_slot_select.sv` 与 `sim/run_rgb565_slot_select_test.sh`，以原串行 first-free 规则作为独立参考模型。

### 验证

- `bash sim/run_rgb565_slot_select_test.sh`：通过，`RGB565_SLOT_SELECT_PASS checks=10973`。覆盖全部 7 组各自 256 种局部可用位型、请求数 0/1/4/8/16/255/256、全空/全满/跨组稀疏边界，以及 2000 组确定性随机输入；逐项比较 free count、selected count、reserve mask 和排序后的 slot index。
- `verilator --lint-only --language 1800-2012 -I. -Isoc --Wno-fatal --top-module Hrgb565_int8_lane soc/Hrgb565_int8_lane.v`：通过；仅有 lane 原有的索引/截位宽度提示，没有 selector 新增语法错误或组合环路诊断。
- `git diff --check`：通过。
- 完整 SoC DDR-profile lint 未完成：本环境未找到 PDS vendor BRAM 仿真模型；使用缺失路径验证现有脚本会按预期在缺失模型处退出。未将此项记为通过。
- 未运行 PDS 综合、Place/Route，也未生成新时序报告。现有 WNS、逻辑级数和 Place 时间只作为修改前基线，不宣称本次时序已改善。

### 修改后复盘与决策

- 功能等价测试确认最低编号优先与批次数量规则未变；无新增周期，故设计吞吐架构上没有下降。该结论不等同于已测得的时钟频率。
- 结构上移除了串行 56 槽 rank/count 依赖，符合缩短关键组合锥的目标；代价是多组局部 popcount/rank 比较并行逻辑，LUT/布线面积可能变化，须以 PDS Device Map 和 timing report 判定是否值得保留。
- 没有重复修改时钟约束、降低 MAC 并行度或增加 slot 扫描周期等已否决方向。
- 下一步同步 lane RTL 到 D 盘 PDS 工程，由用户启动 Compile/Synthesize/Place/Route。若新报告未改善 slot-generation 到 batch-address 路径，或面积/拥塞明显恶化，则依据新 netlist/timing 数据调整分组结构或回退本方向；在获得新 PDS 结果前，不继续猜测性叠加修改。

## 2026-10-17：同步 lane RTL 到 PDS 工程

### 操作与证据

- 将本地已通过 Verilator 和 slot 分配专项测试的 `soc/Hrgb565_int8_lane.v` 同步到 `/mnt/d/HPUfile/JiChuang/npu/small-eyes/soc/Hrgb565_int8_lane.v`。
- 同步后两边 SHA256 均为 `da17d8218c2371ad07d55a3d1253eb2c47dbf3babdbde7bf9ad99064471e5722`。
- 同步时 D 盘日志仍在旧版本任务中运行到 route iteration 51；该运行已读取旧 RTL，不能作为本次同步后的结果。

### 复盘与下一步

- 文件版本已一致，但 PDS 已启动的任务不会重新读取已修改的 RTL；继续等待该旧任务没有验收价值。
- 下一步应停止旧任务后，从 Compile/Synthesize 重新运行，确认当前 lane selector 进入综合网表，再启动 Place/Route 并比较 unrouted、overuse、总耗时、WNS/TNS 和资源变化。

## 2026-10-17：消除 descriptor 尺寸校验的动态除法

### 修改前复盘与诊断

- 最新 PDS 工程报告时间为 2026-10-17 12:32，RTL 与本地 `soc/Hnpu_cnn_engine.v` 修改前 SHA256 一致，确认该报告对应本地 CNN 引擎和 8 ns DDR 时钟约束。
- slow-corner `ddr_core_clk` WNS `-28.114 ns`、TNS `-150475.718 ns`，19,179/106,619 个 setup endpoints 失败。最差路径为 NPU `layer_in_h[1]` 到 `kernel_index[4]` CE，100 logic levels、arrival `41.400 ns`，逻辑 `17.494 ns`、布线 `18.197 ns`。
- 路径 cell chain 含 `N9016_sub31` 到 `N9016_sub0` 连续宽减法级，随后比较并扇出到控制端。RTL 中与该尺寸输入相连的动态除法位于 `ST_DISPATCH` 的 Conv/MaxPool 输出尺寸检查：`(extent / stride) + 1`。该检查不在 ROI MAC 数据通路，但同步组合路径压在 DDR 时钟周期内。
- 同轮 P&R 成功布通 `81937/81937` nets，Place `233.36 s`，Route `961.90 s`（detailed routing `727.03 s`），总计 `22m44s`。路由成功不代表时序通过。

### 修改

- 文件：`soc/Hnpu_cnn_engine.v`
- 用等价条件 `((out_dim - 1) * stride <= extent) && (extent < out_dim * stride)` 校验 Conv/MaxPool 的宽高，移除这四个 descriptor 检查中的动态除法。
- 每个维度只用一次 8-bit stride 平衡 shift/add 乘法计算下界，上界复用下界加 stride；extent 使用 18 位无符号中间值，负有效范围、零 stride、零输出尺寸均显式拒绝。保留整数向下取整语义和 padding 语义。
- 此路径只参与模型层 descriptor dispatch，不改变已加载模型的算子、MAC、DDR/BRAM 访问节奏或每 ROI 周期；未更改 PDS 约束。
- 文件：`temp/tests/tb_npu_cnn_engine.sv`、`temp/tests/run_npu_cnn_test.sh`
- 增加错误 MaxPool 输出尺寸包测试 `bad_pool_shape`；原 `bad_shape` 继续覆盖 Conv 尺寸拒绝。

### 验证

- CNN 引擎专项：`NPU_CNN_TEST_PASS cases=13 simulator=verilator`，含正常模型、Conv/Pool 错尺寸、CRC、AXI 响应错误等用例。
- 完整回归：`CCACHE_DISABLE=1 bash temp/tests/run_npu_tests.sh` 通过，`NPU_TEST_PASS count=12 simulator=verilator`；SoC integration lint 和 Flash->DDR 模型加载检查通过。
- v0.3 逐层金样：32x32 与 96x96 各 `16 cases / 144 layer_checks` 通过，最大周期分别 `3,789,459` 与 `3,823,422`，均低于 `4,375,000` 限制。
- 独立 Verilator lint 退出码 0；新 helper 的位宽提示已消除。文件级 `git diff --check` 通过。lint 仍报告模块中既有的其他宽度提示。
- 本次 RTL 修改后的 PDS 尚未运行，不能声称 WNS、Place 或 Route 已改善。已将 RTL 同步到 D 盘 PDS 工程；需要重新跑 Compile/Synthesize/Place/Route/Timing 才能验证物理 QoR。

### 修改后自我复盘与决策

- 这次修改针对报告 cell chain 和源码中的动态除法做结构性消除，方向与证据相符；没有重复动态多端口 RAM、放宽时钟约束或降低 CNN 吞吐等已否决做法。
- 功能金样、错误 descriptor 行为和吞吐周期均符合预期。对完整整数范围，商区间判定等价于 `floor(extent/stride)+1`；18-bit extent 覆盖 16-bit 输入加两项 8-bit padding 的最大值。
- 复盘发现独立计算上下界会重复乘法器，已改为单乘法器派生上界，降低逻辑复制和布线负担；回归需覆盖这一最终版本。
- 预期减少除法导致的宽组合逻辑，但该 PDS 综合器的映射和布线影响尚未实测。此改动值得进入下一轮 PDS 验证，不在看到新报告前继续叠加优化。
- 下一步比较新报告的 NPU worst path、slow-corner WNS/TNS、CLMA/CLMS/APM/DRM、Place 和 Route 时间。若 divider 链消失而关键路径/Place 明显改善则保留；若关键路径转移或面积/布线恶化，则基于新路径单独调整。全局 WNS 中非 NPU 的 CAM 跨域路径不在本次改动范围内。

## 2026-10-17：处理本轮综合告警中的 RTL 可控项

### 修改前复盘与诊断

- 复核本轮 D 盘日志：Route 仍在进行（最近读到第 66 轮，未布通 9,717、overuse 27,494），未产生本轮最终布线/时序报告。当前改动不能影响已经生成的综合网表。
- Compile 的 3 条 `Sdm-2008` 指向 CNN RAM 上不受 PDS 支持的 `ram_style` 属性；同一轮综合仍识别 `model_mem`、`tensor_a/b` 为 RAM，模型缓存并推断为多组 DRM36K。
- 综合扇出告警定位到多个不同所有者：预处理 `scan_x` 计数、摄像头异步 FIFO `wr_fire`、CPU 信号及 DDR 控制器 `row_addr_diff`。仅修正预处理坐标计数位宽；不改跨时钟 FIFO、CPU 或 vendor DDR IP。

### 修改

- `soc/Hcamera_preprocess.v`：扫描坐标计数器宽度改为由 `FRAME_WIDTH/FRAME_HEIGHT` 参数计算；接口端口仍零扩展到 16 位，状态机和像素周期不变。
- `soc/Hnpu_cnn_engine.v`：删除 PDS 明确忽略的三处 `ram_style="block"` 属性，避免属性误导；RAM 推断继续依赖同步读写结构。新版本的 DRM 映射仍须下一次 PDS Device Map 确认。

### 验证

- `SIM_JOBS=1 SIM_TIMEOUT=600 bash scripts/run_testbench.sh tb_preprocess_stereo`：通过，含双路并行、ROI 像素、缩放、错误和超时用例。
- `CCACHE_DISABLE=1 SIM_JOBS=1 bash temp/tests/run_npu_tests.sh`：通过；v0.3 32x32、96x96 各 16 cases / 144 layer checks，周期均低于 4,375,000。
- `SIM_JOBS=1 SIM_TIMEOUT=120 bash scripts/run_testbench.sh tb_camera_async_fifo`：通过，覆盖异步双时钟顺序、满空、溢出/下溢和复位。
- `git diff --check`：通过。没有本次修改后的 PDS Compile/Synthesize 数据，因此不能宣称 PDS 告警数量或路由时间已改善。

### 修改后复盘与决策

- 两项修改均未改变接口、CDC、AXI 时序或 NPU 运算周期；仿真回归符合预期。
- 计数位宽收窄针对综合网表标注到 `Hcamera_preprocess.v:293` 的 `scan_x` 递增逻辑，但告警阈值与设计实际最大扇出统计不一致，必须用下一轮综合日志核实其是否消失，不能据 RTL 仿真下结论。
- 仍未修复的 `wr_fire`、CPU、DDR IP 扇出告警不属于本轮安全可局部修复项；异步 FIFO bank 化会改变 RAM 推断和读选择路径，需先单独评估，不在本次冒险修改。
- 下一步待当前 GUI P&R 结束后，将这两个 RTL 文件同步至 PDS 工程，重跑 Compile/Synthesize 并核对 RAM/DRM 映射及扇出告警；确认无退化后再进行 Place/Route。当前 P&R 仍使用修改前综合网表，不要把本次源代码修改计作该轮优化效果。

## 2026-10-17：减少 RGB565 lane 槽分配互连

### 修改前复盘与诊断

- 本轮 D 盘 Place/Route 日志从 `2026-10-17 13:19:40` 开始；Place 用时 `508.97 s`，Route 已到第 73 轮仍有 `8,769` 条未布通、`22,587` overuse，日志最后更新 `15:41:35`，用户随后暂停。没有本轮最终 timing/拥塞报告，不能把未完成 route 的趋势当成最终 QoR。
- 上一份已完成时序报告（`2026-10-17 11:33:36`）的最差 setup 路径来自 `Hrgb565_int8_lane` 的 `slot_generation -> batch_slot_addr`，111 级逻辑；此前 RTL 对 56 个槽一次性生成 rank、reserve mask 和 8 个优先编码索引。该路径证据支持降低其并行优先编码互连。
- 13:19 这轮 D 盘 NPU RTL 与本地不同，且缺少本轮最终报告；因此本次只改有历史时序证据的 RGB565 lane，不把结果归因给 NPU，也不据未完成日志声称已经解决全局拥塞。

### 修改

- `soc/Hrgb565_int8_lane.v`：descriptor 握手时锁存 56 位空闲快照，再用最多 56 周期的 FSM 逐槽扫描并立即预留最低编号的可用槽；快照保持原先单周期分配的 first-free 选择语义，即使扫描时收到 slot release 也不改变本批已选顺序。删除 lane 实例中的 56 槽 rank/reserve/多路索引编码网络。保留 7 组平衡 popcount，仅用于 descriptor 入队前确认空闲槽数量。两路各自独立，generation/frame 标记与槽地址在选中时锁存。
- 最坏启动附加延迟为 56 个 `ddr_core_clk` 周期（125 MHz 下 `448 ns`）；全空闲时 8 个 ROI 在 8 周期完成。每张 ROI 的 AXI 读写、CNN MAC/池化周期及 DDR 时钟不变，故稳态 ROI 服务速率不因分配器扫描降低；增加的是新批次进入首个 AXI 读之前的短延迟。
- `sim/tb_rgb565_lane_alloc.sv` / `sim/run_rgb565_lane_alloc_test.sh`：新增 lane 级测试，覆盖 descriptor 接受、8 槽最低编号次序、generation/状态预留、进入 AXI 阶段和满空闲情况下的周期数。
- 更新 `sim/tb_rgb565_slot_select.sv` 验证当前实际使用的平衡 free-slot counter，而非被 lane 淘汰的并行 selector。

### 验证与复盘

- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，8 槽批次在 8 周期进入 AXI 阶段，槽 0..7 各预留一次。
- `bash sim/run_rgb565_slot_select_test.sh`：通过，10,973 个全空/全满/边界/随机 mask 的 free-count 比对。
- `SIM_JOBS=1 SIM_TIMEOUT=600 bash scripts/run_testbench.sh tb_preprocess_stereo`：通过。
- `CCACHE_DISABLE=1 SIM_JOBS=1 bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12`；v0.3 32x32、96x96 各 16 cases / 144 layer checks 均通过，最大周期分别 `3,789,459` 和 `3,823,422`。
- Verilator lane lint 退出码 0；剩余为 lane 原有的截位/索引位宽警告，没有新增语法错误。`git diff --check` 通过。
- 修改后的 RTL 尚未在 PDS 重新 Compile/Synthesize/Place/Route；当前没有 LUT/DRM、拥塞、route 时间或 WNS 的前后物理数据。已将唯一修改的 RTL 同步到 D 盘工程并以 SHA256 `db1b37911bacd073efa966a33dd97f8aa666eb155b35d196268f27c7f8e17cd0` 复核一致。由于现有 PDS GUI shell 仍存活，不启动第二实例，避免工程锁和覆盖其状态。
- 此结构预计减小高扇出与跨槽组合互连，但 route 时间能否大幅下降必须由同器件、同约束的完整实现数据确认；新一轮必须从 Compile/Synthesize 更新网表后再 Place/Route，不能直接继续旧综合网表的第 73 轮结果。

### 决策

- 保留本修改进入下一轮 PDS 实测：它对应已记录的 lane 关键路径，并以亚微秒批次启动延迟换取较小的组合互连，未改变稳态 ROI 处理吞吐。
- 同步后先 Compile/Synthesize 核实 lane 逻辑规模和 56 槽存储实现未恶化，再跑 Place/Route；对比同版本基线的 Place 时间、每轮未布通/overuse、总 route 时间及 125 MHz setup 报告。若拥塞或布线时间未改善，或 selector 关键路径转移到更差路径，则根据新报告调整/回退，不继续猜测性叠加 RTL 改动。

## 2026-10-17：新 allocator 版本 P&R 中途观察

- D 盘 Compile/Synthesize 日志时间分别为 `16:00:05` 和 `16:04:21`，lane RTL SHA256 与本地新版本一致；P&R 于 `16:05:31` 启动，因此本次结果确实包含 allocator FSM。
- `17:11:12` 最新到 Route iteration 32：`82654` route nets、`82689` subnets、`382780` loads；未布通 `18694`、overuse `77313`，本轮 MT 时间 `259.658 s`。从 iteration 6 的 `72673/578400` 降至 iteration 32，说明仍在收敛；但每轮时间已升到约 4.3 分钟。
- 对照上一轮同为 iteration 32 的日志：`81280` route nets、未布通 `17569`、overuse `62353`、本轮 `102.282 s`。新轮中途指标更差，暂不能声称 allocator 改动改善了拥塞或速度。两轮网表/工程状态不完全相同，且目前无新 timing/congestion report，不能把差异单独归因于此 RTL 修改。
- 复盘：11:33 的 111 级 slot-generation 路径报告早于后来采用平衡 selector 的 RTL，不能作为当前拥塞唯一原因的充分证据；当前 allocator 方案尚未证明 route 收益。待本轮结束读取最终布线和 timing 报告；若终值未改善，优先回退/重做本 selector 优化，并以本轮实际关键路径和拥塞热点为依据，不继续沿旧路径猜测。

## 2026-10-17：回退未收敛的 lane allocator

### 诊断

- 当前 D 盘 P&R 从 `16:05:30` 开始，约运行 2 小时 37 分时到 route iteration 49；`82654` 条 route nets 中仍有 `13427` 条未布通、`48339` 个 overuse，单轮耗时 `387.131 s`。
- 对照已完成的旧版本 P&R：约 `81900` 条 route nets 在 iteration 20/40 的单轮耗时分别约 `12.160/5.833 s`，随后正常收敛。当前版本从 iteration 20 后单轮耗时升到约 4～6 分钟，属于明显低收益拥塞状态，不继续等待该轮作为验收结果。
- 当前 Place 结束时 `Worst slack=-12.317 ns`，Route 初始 `82689` subnets、`382780` loads；日志还显示最大扇出 `2456`。这些指标说明 router 正在处理真实拥塞，不是日志停滞或单纯 CPU 空闲。

### 修改

- 将 `soc/Hrgb565_int8_lane.v` 回退到上一次已完成布线的 first-free combinational allocator；删除本轮 `ST_ALLOC` 逐槽扫描及其 free-slot helper。该回退恢复已验证的 RTL/网表形态，不改变 CNN、DDR、BRAM 或 NPU 接口。
- 将 `sim/tb_rgb565_slot_select.sv` 改为验证回退后实际使用的 lane `free_count`、最低编号分配和 AXI 阶段；不再引用已删除的 helper 模块。

### 验证与决策

- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，槽 0～7 按顺序预留。
- `bash sim/run_rgb565_slot_select_test.sh`：通过，初始 56 个空闲槽、分配 8 个后剩余 48 个，进入 AXI 等待。
- `CCACHE_DISABLE=1 bash temp/tests/run_npu_tests.sh`：通过；SoC CNN system、NPU service/image、AXI、MMIO、前处理、32×32/96×96 金样均通过，未发现功能回归。
- Verilator lint 和 `git diff --check` 通过；仅保留原有位宽提示。回退后的 RTL 尚未同步到 D 盘，也尚未取得新的 PDS 物理结果。
- 决策：停止把当前 allocator 版本用于 P&R 验收。待当前 GUI PDS 进程由用户停止后，同步回退版本，先 Compile/Synthesize，再比较 net/load、DRM/LUT、Place 和 Route 迭代时间；不放宽 125 MHz DDR 约束，不降低 NPU 并行度。

## 2026-10-17：回退版 P&R 完成与时序复盘

### 本次实现结果

- D 盘 P&R 于 `19:14:19` 启动，`19:45:28` 完成；日志耗时 `31m12s`。Place `353.83s`，总 routing `1363.95s`，其中 detailed routing `1183.76s`、router hold fix `121.77s`。
- `84856/84856` nets routed，工具报告 placed and routed successfully；随后 `19:47:46` 生成 `Hfpga_soc.sbit`，大小 `9,188,552` bytes。布线/bitstream 成功不等于时序收敛。
- 与被暂停的 allocator FSM 轮次在相同 iteration 51 对比：未布通从 `12887` 降至 `5696`，overuse 从 `45424` 降至 `16195`，MT route time 从 `447.777s` 降至 `5.932s`。回退显著消除了此前的极端 router 收敛退化；但本次总 routing 仍约 `22m44s`。

### 时序报告

- 最新报告：`project/report_timing/Hfpga_soc.rtr`，生成于 `19:46:20`；DDR_REF_CLK / `ddr_core_clk` 约束为 `8.000ns` / `125MHz`。
- Slow corner DDR setup WNS `-46.093ns`、TNS `-278956.087ns`，`19254/107079` 个端点失败；工具估算频率 `18.4867MHz`，明显不满足 125MHz。Fast corner WNS `-22.714ns`，仍有 `14087` 个失败端点。
- 最差路径在 `Hrgb565_int8_lane`，从 `slot_generation[1][20]` 到 `batch_slot_index[5][4]`，共 `114` 级逻辑；数据路径逻辑延迟 `19.701ns`、布线延迟 `33.822ns`，布线占 `63.2%`。当前 RTL 的 56-slot 顺序组合扫描及 `selected_count` 链是对应候选逻辑锥；该路径不属于 NPU CNN 引擎。
- CPU 70MHz 组另有 `-2.235ns` setup slack。DDR 内部 slow-corner hold 最小 `+0.105ns` 且无失败；CAM 到 DDR 等跨域路径另有 setup/hold 失败，需结合 CDC/约束单独审查，不能用宽泛 false-path 掩盖。
- 本次最差路径报告未列出 NPU CNN 引擎端点，因此不能据此宣称所有 NPU 路径通过；需生成按 `u_npu_system` / `Hnpu_cnn_engine` 过滤的 setup/hold 报告。

### 复盘与决策

- 回退实现恢复了可收敛布线，确认先前极端 route 慢与 allocator FSM 版本相关；当前 Route 已完成，但全局 125MHz 时序仍不合格。
- 最新全局瓶颈位于 NPU 外的 RGB565 lane。按既定范围，本轮不擅自修改该模块，也不放宽 DDR 时钟约束。若继续要求全 SoC 达到 125MHz，需要明确扩大范围后，针对该 114 级 lane 路径优化并用 PDS 报告验证。
- 下一步先取得 NPU 专项 timing report；只有其中显示 NPU 自身仍是关键瓶颈时才继续改 NPU。若目标改为全芯片时序收敛，再针对 lane 关键路径制定单独方案。

## 2026-10-17：分段流水化 56 槽分配器

### 修改前复盘与依据

- 上一轮已完成 P&R 基线为 31m12s，Place 353.83s、Route 1363.95s；DDR slow-corner WNS `-46.093ns`。最差路径在 `Hrgb565_int8_lane`，从 slot generation 到 batch slot index 共 114 级，逻辑延迟 19.701ns、布线延迟 33.822ns。
- 历史 56 周期逐槽 FSM 曾出现 route iteration 51 单轮 447.777s、未布通 12887、overuse 45424；已明确否决，不复用该架构。本次保留每批一次接受的语义，改为固定 4 周期短流水，不做 56 周期扫描。
- 厂商依据：Pango ADS Synthesis User Guide 第 2 章（pp.19-20）将 Retiming 描述为移动已有寄存器以优化时序，同时指出资源共享可能降低时序；本次采用显式短流水边界，不依赖综合器自动 retiming。Pango Timing Analyzer User Guide v1.4 §4.1（pp.14-15）说明按 logic levels 筛路径的报告设置，但强调启用该筛选后不能用报告排序判断时序收敛；本次仍以 PDS slack/WNS 和实际 path delay 为准。Pango Design Suite User Guide 2022.2（pp.113-118）说明 placement decongestion 对时序/布线耗时的权衡及器件相关设置；本次不改 P&R 策略或 DDR 约束，保持与现有基线可比。

### 修改

- 文件：`soc/Hrgb565_int8_lane.v`
- 接受 descriptor 时锁存 56 位 allocatable 快照；后续依次寄存组内 rank/计数、组前缀、选中槽并提交预留，最后计算槽地址后启动 AXI。组内 rank 每 8 槽局部计算，free count 使用 7 组平衡 popcount/归约，不再有 56 项 `selected_count` 串行组合链。
- 选择规则仍为最低编号优先；generation 饱和值仍不可分配；提交前并发 release 只会释放其它槽，不会改变已锁存快照。模块/AXI 接口、DDR 访问序列、NPU MAC 速率和稳态 ROI 吞吐不变；每批只增加 4 个 `ddr_core_clk` 启动周期（125MHz 下 32ns）。新增约 294 个 allocator 状态位，约为基线 44799 个寄存器的 0.7%；实际 LUT/DRM 资源仍以 PDS 综合报告确认。
- 未改 `soc.fdc`、P&R 参数、125MHz 约束、CNN MAC 并行度或 BRAM 结构。

### 验证

- `bash sim/run_rgb565_slot_select_test.sh`：67 组通过，含全空闲、跨组稀疏、generation 饱和和 64 组确定性随机掩码；逐项比对槽顺序、预留/generation 更新及 free count。AXI 启动固定增加 4 周期。
- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，0..7 槽顺序正确，启动 4 周期。
- `CCACHE_DISABLE=1 SIM_JOBS=1 bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12`；v0.3 32x32 / 96x96 各 16 cases、144 layer checks 均通过，最大周期 3789459 / 3823422，低于 4375000。
- `SIM_JOBS=1 SIM_TIMEOUT=600 bash scripts/run_testbench.sh tb_preprocess_stereo`：通过全部双路预处理场景。
- Verilator lane lint 退出码 0，未新增 lint 告警；`git diff --check` 通过。剩余为模块已有的截位/索引宽度提示。
- 本次未运行 PDS Compile/Synthesize/Place/Route；物理时序、面积和 route 时间尚无新数据，不能声称 114 级路径已消失或 P&R 时间已保证不增加。

### 复盘与 P&R 止损门槛

- 功能与流水周期符合预期；相比被否决的 56 周期 FSM，本次是固定短流水且避免逐槽动态地址扫描，值得进入一次受控 PDS 验证。新增 rank 比较/归约可能增加少量 LUT/互连，故不以仿真结果代替物理验收。
- 以同一基线/器件/约束比较：Place 应不超过 410s，Route 不超过 1500s，P&R 总时间不超过 34m20s；Route iteration 51 若未布通或 overuse 超过基线两倍（11392 / 32390），或连续 3 轮单轮 MT route 超过 60s，则停止本轮，不再等待小时级无效收敛。超过门槛即判定未满足“route 时间不突增”，再据新 netlist/拥塞报告缩小或撤回该结构。
- 时序验收要求新报告显示原 lane critical path 明显缩短、WNS 优于 `-46.093ns`；仍须检查其它 DDR/CAM/CPU 失败路径，不能把路径转移称为全局 timing closure。保持 8ns DDR 时钟约束，不使用 false path 隐藏真实同步路径。
- 下一步只将此 RTL 同步至 D 盘 PDS 工程，由用户启动 Compile/Synthesize/Place/Route。先检查综合器是否接受 RTL、寄存器/LUT/DRM 规模；满足后再进行带上述止损条件的单轮 P&R。

## 2026-10-18：局部扫描替换全局 rank 网络

### 修改前复盘与诊断

- 上一轮 4 周期分组 rank 版本已在 D 盘完成一轮实际 Route，但结果为失败：`81502` 条网络中仅 `79911` 条布通，第 145 轮单轮耗时 `24562.932s`，工具报 `Design is too congested to be routed`；总 P&R 耗时约 `10h48m34s`。
- 失败网表的拥塞清单包含 release 动态索引、FIFO 读指针以及该 allocator 的高扇出 rank/候选网络。说明“并行计算 56 个全局 rank，再对 8 个 rank 做全局匹配”虽然减少了逻辑级数，但产生了跨区域大规模互连；继续等待该轮没有验收价值。
- 本轮不重复全局 rank/prefix/全局候选比较结构，也不调整 PDS 参数、DDR 约束、CNN 并行度或 BRAM 结构。

### RTL 修改

- 文件：`soc/Hrgb565_int8_lane.v`
- 删除 56 槽全局 rank、7 组 prefix 寄存器、8x56 rank-match 比较网络以及全局 one-hot 合并逻辑。
- 改为 7 组、每组 8 槽的局部扫描 allocator：锁存一次 56 位可分配快照；每个 `ST_ALLOC_SCAN` 周期只激活一个 8 槽组，计算该组局部 rank，并按最低槽号顺序预留本组需要的槽；最多扫描 7 组，再进入地址阶段。
- 保持最低编号优先、generation 饱和槽不可分配、整批预留和最多 8 个 ROI 的语义；AXI 事务、输入转换、DDR 地址格式、NPU MAC 和模型接口不变。最坏启动延迟由原 4 周期测试断言放宽为最多 8 周期，稳态每批处理吞吐不改变，只增加分配启动等待。

### 验证

- `bash sim/run_rgb565_slot_select_test.sh`：通过，`RGB565_SLOT_SELECT_PASS cases=67 randomized=64`；确定性稀疏向量覆盖槽位 `0,8,16,24,32,40,48,55` 的全部 7 个组，另覆盖全空闲、generation 饱和和确定性随机掩码，最坏启动延迟 8 周期。
- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，`RGB565_LANE_ALLOC_PASS cycles=2`。
- `CCACHE_DISABLE=1 SIM_JOBS=1 bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12 simulator=verilator`；32x32 和 96x96 v0.3 输入均为 16 cases / 144 layer checks，最大周期分别为 `3789459` 和 `3823422`，低于 `4375000` 门槛。
- Verilator lint 退出码 0，`git diff --check` 通过。lint 中剩余的是 lane 原有的位宽提示，本轮没有新增语法错误。

### 修改后复盘与止损

- 功能回归证明局部扫描的槽位顺序、generation 处理和整套 NPU 接口行为正确；本地仿真不能证明 PDS 拥塞一定改善。
- 该结构将跨 56 槽的全局候选网络限制为当前 8 槽组内的局部组合逻辑，方向与失败报告中的高互连证据一致，值得进行一次新的 PDS Compile/Synthesize/Place/Route 验证。
- 本轮尚未取得新物理结果。下一轮以同一器件和约束比较：Compile/Synthesize 是否通过、总网络数、最大扇出、Place 时间、Route iteration 51 的未布通/overuse、Route 总时间和 WNS/TNS。若再次出现小时级收敛、route 失败或拥塞显著高于已成功基线，停止继续叠加 RTL 结构，回到最后可布通版本并基于新报告定位单一高扇出源。

## 2026-10-18：CNN MAC 乘法/累加分阶段

### 修改前复盘与依据

- 历史 P&R 证据显示 NPU 曾出现 BRAM 输出到计算/回写的超长组合路径；当前 `Hnpu_cnn_engine.v` 的卷积和 FC 状态原来在同一个时钟边界完成 INT8 乘法与 32 位累加。
- 本轮采用 NVDLA/Gemmini 中“片上存储、数据搬运和计算分阶段”的原则，只在现有单 MAC 数据通路中增加乘积寄存器，不引入新的全局互连、不改变 tensor/model BRAM、AXI、模型格式或 MAC 并行度。
- 不重复已否决的全局 rank/候选网络方案；不修改 DDR 125 MHz 约束，也不使用 false path 隐藏时序问题。

### RTL 修改

- 文件：`soc/Hnpu_cnn_engine.v`
- 增加 `mac_product` 和 `mac_product_valid` 寄存器。`ST_CONV_MAC`/`ST_FC_MAC` 每周期继续读取并发起一个当前乘法，同时累加上一周期的乘积；首个周期填充流水，最后一个乘积由新增的 `ST_CONV_MAC_FLUSH` 或 `ST_FC_MAC_FLUSH` 退休。
- 卷积写回和 FC logit 发布都在 flush 完成后进行，避免最后一个乘积丢失。模型权重仍从片内 `model_mem` 读取，tensor 双 bank 和所有外部接口不变。
- 该改动将乘法从累加反馈路径中移出；稳态仍为每周期一个 MAC，仅每个卷积输出/FC 输出增加一个 flush 周期，没有降低 MAC 并行度。

### 仿真验证

- `CCACHE_DISABLE=1 SIM_JOBS=1 SIM_TIMEOUT=600 bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12 simulator=verilator`。
- CNN engine 的有效模型、错误注入、AXI RRESP/RID/RLAST、GAP 负数除法均通过；service/system、96×96 image service/system、96×96 cache 均通过。
- v0.3 模型逐层金样：32×32 为 16 cases / 144 layer checks，最大 `3,819,167` cycles；96×96 为 16 cases / 144 layer checks，最大 `3,853,129` cycles；均低于 `4,375,000` 限制。模型大小 `62,720` bytes，11 类检查通过。
- 相对上一轮记录的旧最大值 `3,789,459` / `3,823,422`，新增约 `29,708` / `29,707` 周期，符合卷积输出数量对应的 flush 开销，结果和逐层金样没有变化。
- `git diff --check` 通过；完整测试编译使用 Verilator 5.038，没有新增语法/编译错误。

### 修改后复盘与决策

- 功能结果正确，周期增加受控，且关键乘法不再直接落在累加器反馈路径；该方案值得保留并进入一次受控 PDS 综合验证。
- 本地仿真不能证明 P&R 时序或 route 时间改善。当前没有本轮 RTL 对应的 PDS Compile/Synthesize/Place/Route/Timing 报告，因此不宣称 WNS、拥塞、BRAM/LUT 或 route 时间已改善。
- 下一步只同步 `soc/Hnpu_cnn_engine.v` 到 PDS 工程，由用户从 Compile/Synthesize 开始运行。先核对综合通过、`model_mem`/`tensor_a`/`tensor_b` 仍映射到 BRAM/DRM、MAC 资源未异常膨胀；再比较 Place/Route 时间、拥塞和 NPU 专项 125 MHz 时序。若物理结果无改善或出现资源/性能退化，停止继续叠加流水结构，依据新报告决定保留或回退。

## 2026-10-19：PDS lane allocator 回退与同步

### 修改前复盘与判断

- 2026-10-18 的失败 P&R 在约 4 小时 29 分后仍有 12,234 条网络未布通、36,320 个 overuse，Route 第 69 轮达到工具拥塞失败；失败网络清单约 4,867 条来自 RGB565 lane、约 238 条来自 NPU，综合网表最大扇出 2,456。这些证据使 lane allocator 成为高优先级嫌疑点，但不能证明它是唯一根因。
- 对比本地已知可完整布线的 first-free allocator，D 盘 PDS 工程仍是分组 rank/扫描 allocator；未重复使用此前失败的全局 rank 方案，也不改时钟约束、P&R 参数、CNN 并行度或 BRAM。
- 已成功布线的 first-free 基线曾在约 31 分 12 秒完成 84,856/84,856 nets 并生成 bitstream，但 DDR slow-corner WNS 为 -46.093 ns。因此回退只能恢复已知的布线基线，不能代表时序达标。

### 修改与验证

- 将 `soc/Hrgb565_int8_lane.v` 同步到 D 盘 `npu/small-eyes/soc/`，恢复 first-free 组合分配器；删除失败版本中的 rank、组扫描状态机和额外跨槽候选网络。保留原有槽位最低编号优先、整批预留、DDR 访问和 NPU 数据接口语义。
- 本地与 D 盘文件 SHA-256 均为 `af858aaecdecfc497d9c0150fb3e203d6c27d89c987fc6d009037aee853e3f5f`。
- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，槽 0..7 顺序正确，`cycles=0`。
- `bash sim/run_rgb565_slot_select_test.sh`：通过，`RGB565_SLOT_SELECT_PASS cases=67 randomized=64 latency=0`。Verilator 仍报告该模块已有的位宽扩展/截断提示；测试退出码为 0。
- `CCACHE_DISABLE=1 SIM_JOBS=1 SIM_TIMEOUT=600 bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12`；v0.3 32×32 输入 16 cases/144 layer checks、最大 3,819,167 cycles，96×96 输入 16 cases/144 layer checks、最大 3,853,129 cycles，均低于 4,375,000 周期门槛。
- `SIM_JOBS=1 SIM_TIMEOUT=600 bash scripts/run_testbench.sh tb_preprocess_stereo`：通过全部双路预处理场景。

### 修改后复盘与下一步

- 本地功能回归覆盖 allocator、SoC/NPU、模型逐层金样及双路前处理，结果符合预期；这是对 allocator 功能的验证，不是对物理拥塞或时序的验证。
- 当前 PDS GUI 进程仍打开；同步后尚无新 Compile/Synthesize/Place/Route 报告。下一轮从 Compile/Synthesize 开始，核对综合输入确实读取上述 SHA 的 RTL，再比较 Place 时间、route nets/loads、各轮未布通和 overuse、最终 route 时间、DRM/LUT 及 125 MHz timing。
- 若新版本仍出现小时级 route、拥塞失败，或结果与已知基线明显恶化，停止继续更换 allocator 结构；依据新一轮拥塞热点和 timing path 再定位。不得据本地仿真宣称 P&R 或时序问题已经解决。

## 2026-10-19：按最新时序报告拆分 lane 槽分配

### 报告复盘

- 本轮 P&R 已成功完成并生成 bitstream；Route 用时 `0h58m34s`，没有布线失败。
- 最新 slow-corner 报告将 `ddr_core_clk` 约束为 125 MHz / 8 ns，但 WNS 为 `-43.979 ns`、TNS 为 `-272639.222 ns`，18,434 个 endpoint 失败。最差路径从 `lane[1].slot_generation[0][28]` 到 `lane[1].batch_slot_addr[3][14]`，110 级逻辑，data arrival `56.971 ns`；lane[0] 有相同类型的关键路径。
- 最差路径属于 `Hrgb565_int8_lane` 的 56 槽组合 first-free 分配，不是 CNN MAC/BRAM datapath。CPU 另有 `-2.469 ns` WNS，CAM/DDR 交叉时钟路径也有失败；本次修改只处理证据明确的 lane 组合路径，不宣称全局时序由此收敛。
- 不复用已导致小时级 route 失败的全局 rank/prefix 网络或 56 周期扫描方案；不更改时钟约束、P&R 参数、NPU 并行度、DDR、BRAM 或模型算术。

### RTL 修改

- `soc/Hrgb565_int8_lane.v`：descriptor 被接受时锁存 56 位可用槽快照；之后用 7 组、每组 8 位的分层首空槽编码器，每周期只提交一个最低编号空闲槽，最多 8 周期后启动该批 AXI 读取。没有跨 56 槽的逐项 `selected_count` 递增链，也没有 8×56 rank 比较/候选交叉网络。
- 本地及 D 盘 PDS 工程文件 SHA-256：`6ba15da9ea0ba7bfbebb60b71c8e17a32e23d2dc5f93aee8311012f6dbe20091`。
- 同步把空闲槽计数改为 8 槽局部 popcount 加分组归约，避免原 56 项串行计数成为下一个明显长链。
- 额外状态为 56 位快照和 3 位批内位置；最高只增加 8 个 `ddr_core_clk` 周期（125 MHz 下 64 ns）批次启动延迟。稳态每 ROI 的 AXI、RGB565 转换、NPU MAC 周期和 BRAM 使用不变。
- 若快照不变量意外失效，错误路径将只按已完成的位置清理已分配槽并归还 frame bank，防止部分分配泄漏。

### 验证

- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，8 槽按 0..7 分配，8 周期后进入 AXI。
- `bash sim/run_rgb565_slot_select_test.sh`：通过，69 组（64 组确定性随机），覆盖全空闲、稀疏跨组、generation 饱和、不同请求数、容量不足和分配期间释放旧槽；最低编号优先及接受时快照语义正确，最大延迟 8 周期。
- `CCACHE_DISABLE=1 SIM_JOBS=1 SIM_TIMEOUT=600 bash temp/tests/run_npu_tests.sh`：通过，`NPU_TEST_PASS count=12`；v0.3 32×32、96×96 各 16 cases / 144 layer checks，最大周期分别 `3,819,167`、`3,853,129`，均低于 `4,375,000`。
- `SIM_JOBS=1 SIM_TIMEOUT=600 bash scripts/run_testbench.sh tb_preprocess_stereo`：双路前处理全部通过。
- Verilator lint 退出码为 0（使用 `--Wno-fatal`）；未新增语法错误。剩余 WIDTHTRUNC 是本模块既有的地址截位、常量除模和索引宽度提示。`git diff --check` 通过。

### 复盘与 P&R 止损条件

- 新结构在功能上通过定向及端到端回归，关键路径逻辑由长串行扫描改为寄存快照后的 7 组/8 位优先编码；这提供了明确的时序改善机制，但仿真不能给出 PDS 的实际 WNS、拥塞或 route 时间。
- 新 RTL 尚未经过 PDS Compile/Synthesize/Place/Route。同步后先确认 Compile/Synthesize 通过、综合器识别新增状态且 BRAM/DRM 与 LUT/寄存器资源没有异常，再开始一次完整 P&R。
- 本轮成功基线 Place/Route 用时 `58m34s`。实现过程中观察每轮未布通数与 overuse；若连续 3 轮未布通/overuse 无下降，或单轮耗时超过 5 分钟且指标无改善，暂停并读取日志/拥塞清单，不继续小时级运行。这个门槛用于尽早止损，不构成 P&R 成功保证。
- 只有新报告显示 lane 路径及全局 slow-corner WNS/TNS 实际改善，且完整路由成功，才能确认本次物理优化有效。CPU、CAM/DDR CDC 路径仍须按报告分别处理；不得用 false-path 隐藏真实同步路径。

## 2026-10-19：lane 分配器地址路径与计数链缩短

### 报告复盘与定位

- 沿用 2026-10-19 13:55 slow-corner 报告：最差路径为 `lane[1].slot_generation[0][28]` → `lane[1].batch_slot_addr[3][14]`，110 级逻辑、data arrival `56.971 ns`（8 ns 预算）。
- 该路径终点是批内槽地址寄存器、起点是 generation 快照。路径上的重逻辑来自：① `block_base` 用 32 位 `%14` 取模与 `%` 运算，属于宽除法；② `case(alloc_position)` 八个分支各自复制一份 `block_base(...)`；③ 独立的 56 项串行占用计数链 `used_count_next`。
- 未改变分配语义、槽编号顺序、接受时快照时机、每周期提交一个槽、最多 8 周期启动 AXI、AXI/DDR/NPU 接口；不改时钟约束、P&R 参数、NPU 并行度、DDR、BRAM 与算术。

### RTL 修改（`soc/Hrgb565_int8_lane.v`）

- 重写 `block_base`：用 6 位常量比较分解 `slot = 14*block + position`（`block = slot>=42 ? 3 : slot>=28 ? 2 : slot>=14 ? 1 : 0`，`position = slot - 14*block`），地址改为 `BLOCK0_BASE + (block<<19) + position*9KiB`；删除 32 位 `%14`，块内偏移与块跨距都变成移位/常量乘。块间步进 0x80000、块内 `position` ≤ 13，各块区域不重叠。
- 只计算一次 `wire [31:0] alloc_selected_addr = block_base(alloc_selected_index)`，替换 8 处 `batch_slot_addr[n]<=block_base(alloc_selected_index)`，消除除法/乘法的 8 份复制。
- 占用计数 `used_count_next` 由 56 项串行 `used_count_next+1'b1` 链改为与 `free_count` 相同的平衡归约：`slot_used_points[55:0]` 每槽取 `|slot_state`，7 组 `popcount8` 后平衡求和。
- 局部组掩码 `alloc_local_mask` 由 7 次串行 OR 累加改为单表达式并行 OR。

### 验证

- `bash sim/run_rgb565_slot_select_test.sh`：通过，`cases=69 randomized=64 max_latency=8`。
- `bash sim/run_rgb565_lane_alloc_test.sh`：通过，`cycles=8 first_slot=0 last_slot=7`。
- `run_npu_image_service_test.sh`、`run_npu_image_system_test.sh`：通过。
- `run_flash_ddr_model_load_test.sh`、`run_npu_cnn_test.sh`、`run_npu_cnn_service_test.sh`、`run_npu_cnn_system_test.sh`、`run_npu_cnn_96_cache_test.sh`：通过。
- `run_npu_soc_integration_lint.sh`：本机缺少 `rg`(ripgrep)，脚本第 10 行 `rg -Fq` 直接失败，属环境问题。手工核对 `project/project.pds` 已包含全部 `soc/Hnpu_*.v` 与 `soc/Hrgb565_int8_*.v`，并手工运行脚本内的 `verilator --lint-only ... --top-module Hfpga_soc`，无 Error、无 `Hfpga_soc.v` 位宽告警。
- Verilator lint 退出码为 0（`--Wno-fatal`）；剩余 WIDTHTRUNC 是本模块既有的地址截位与索引宽度提示。`git diff --check` 通过。

### 复盘与下一步

- 本次只针对证据明确的最差 lane 组合路径削减深度与复制。这提供了结构性的时序改善机制，但本地仿真不能给出 PDS 的实际 WNS、拥塞或 route 时间。
- 当前文件 SHA-256 为 `9b8ab63d44d7984a09f8874240725809b001940e6b92cb8ebadd819a70437317`；尚未同步到 D 盘 PDS 工程，D 盘仍是上一版 `6ba15da9ea0ba7bfbebb60b71c8e17a32e23d2dc5f93aee8311012f6dbe20091`。
- 下一步：把本文件同步到 D 盘，从 Compile/Synthesize 开始，确认综合通过且无新增资源异常，再做一次完整 P&R；比较 lane 关键路径级数/data arrival、全局 WNS/TNS，以及各轮未布通/overuse 与总 route 时间。只有新报告显示实际改善且布线成功，才能确认有效；否则按拥塞热点和 timing path 再定位，不得据本地仿真宣称问题已解决。

## 2026-10-19：同步 lane 地址路径优化版

### 同步前复盘

- D 盘上一轮使用的是旧版 `Hrgb565_int8_lane.v`，SHA-256 为
  `6ba15da9ea0ba7bfbebb60b71c8e17a32e23d2dc5f93aee8311012f6dbe20091`。
- 该轮 Route 在第 16 轮异常退出：总网络 79,454，未布通 30,376，overuse 144,515；未生成对应时序报告，不能用它评价本次地址路径优化。

### 同步结果

- 已将本地经过 Verilator/定向回归验证的
  `soc/Hrgb565_int8_lane.v` 同步到 `/mnt/d/HPUfile/JiChuang/npu/small-eyes/soc/`。
- 源文件与目标文件 SHA-256 均为
  `9b8ab63d44d7984a09f8874240725809b001940e6b92cb8ebadd819a70437317`。
- 本次只同步该 RTL 文件，没有修改 D 盘工程配置、约束或其他 RTL。

### 当前结论

- 新版本尚未经过 PDS Compile/Synthesize/Place/Route，因此不能提前宣称时序或拥塞已改善。
- 下一步从 Compile/Synthesize 开始；确认工程实际读取新哈希后，再比较 Place/Route、未布通/overuse、资源和 125 MHz 时序。

### 2026-10-19 P&R 实测（lane 改动同步后第一轮，15:46 启动）

- D 盘 `soc/Hrgb565_int8_lane.v` SHA-256 与本机一致（`9b8ab63d44d7984a09f8874240725809b001940e6b92cb8ebadd819a70437317`），确认本轮 P&R 用的就是上述 lane 改动。
- 综合：Setup WNS `-13.545 ns`、TNS `-56029.966 ns`。
- DevMap 资源：LUT 51957/159800 (33%)、FF 45075/319600 (15%)、DRM 35、APM 27；与改前（LUT 51833 / FF 45063）基本持平。说明本次改动的作用是**缩短逻辑深度**，不是减少面积。
- 布局结果：`Worst slack after global placement -13946 ps`、`after detailed placement -11686 ps`、`Worst slack after placement -11696 ps`、`TNS after placement -84338962 ps`。
- 对比改前成功基线（13:53，`Worst slack after placement -44292 ps`、`TNS after placement -277959665 ps`）：WNS 由约 `-44.29 ns` 改善到 `-11.70 ns`（约 3.8×），TNS 由约 `-277.96 µs` 改善到 `-84.34 µs`（约 3.3×）；参与布线的网络数由 84695 降到 79610。
- 布线进度（15:46 起）：iter14 未布通 69652 / overuse 517711 → iter53 未布通 12300 / overuse 37813；单轮 MT route time 由约 20 s 递增到约 140 s。16:56 时仍在迭代，未收敛，也没有新的 `report_timing`。
- 与改前基线按相同迭代号对比：iter31 改前 14788（overuse 55333）vs 本轮 22308（overuse 88987）；iter51 改前 6040（overuse 18154）vs 本轮 12684（overuse 39579）。本轮拥塞轨迹更慢，且单轮耗时递增。

### 结论与止损

- lane 分配器改动对**时序**有效，方向正确，应保留：综合/布局 WNS、TNS 都大幅改善，这是本地仿真给不出的物理证据。
- **布线速度没有改善**，route 慢的主因是全局拥塞（125 MHz 域仍有大量失败端点），不是单条 lane 关键路径。要继续提速，需削减拥塞源：56 位 `alloc_selected_mask` 高扇出、`image_block/image_position` 的 `/14`、`%14`、`np…_release_ready` 类 5735 扇出网、`u_preprocess_stereo`。
- 止损：若连续 3 轮未布通/overuse 不再下降，或单轮超过 10 分钟且指标无改善，停止本轮；不得用这轮（尚未收敛）宣称布线时间改善。

### 2026-10-19 第二轮：lane 拥塞优化（去除读地址乘法器与 /14 除法器）

用户决定停掉 15:46 那轮未收敛的布线，直接做下一轮拥塞优化，约束是**不能明显降低 NPU 性能**。

#### 先定位拥塞源（用综合报告，不猜）

从 `synthesize/Hfpga_soc.snr` 的 “Device Utilization Summary Of Each Module” 提取各模块用量：

| 模块 | LUT | FF | LUT-CARRY | LUT7-MUX |
|---|---|---|---|---|
| u_rgb565_int8（2 个 lane） | 14185 | 13092 | 4826 | 1428 |
| u_npu_system | 12235 | 3672 | — | — |
| u_preprocess_stereo | 7769 | 5846 | — | — |
| u_ddr3_ctrl | 7149 | 10080 | — | — |
| u_cpu | 5096 | 3995 | — | — |

结论：`u_rgb565_int8` 占全设计 **27% LUT、29% FF、24% 进位链、51% 的 LUT7 宽 mux**，同时又是 10-18 未布通清单里约 74% 的来源。它是拥塞震中，且是“局部密度”问题（整设计利用率只有 33%）。

另：未布通 net 的 driver 坐标集中在 TX 60–119 / TY 80–199 一片连续区域，也印证是局部密度而非全局资源不足。

#### 本次改动（语义等价，`soc/Hrgb565_int8_lane.v`）

1. **去掉读地址上的 8×32 变量乘法器**。原来
   `read_local_addr = batch_rgb_base + image_index_reg*batch_rgb_stride + input_beat*32`。
   改为维护一个跨图像累加的基址寄存器 `image_rgb_base`：
   - 批次开始时 `image_rgb_base <= desc_rgb_base`；
   - 每切换到一个新图像时 `image_rgb_base <= image_rgb_base + batch_rgb_stride`；
   - 读地址变为 `image_rgb_base + input_beat*32`。
   功能完全一致（第 k 个图像地址仍为 base + k·stride），但不再综合出乘法器。
   该乘法器此前在 APM 报告里表现为 `lane[*].u_lane/N1239_m*`。

2. **去掉图像上报路径上的 `/14` 与 `%14`**。新增 `slot_block_of()` / `slot_position_of()`
   两个常量比较+移位的小函数，`block_base()` 与 `image_block`/`image_position` 共用；
   与上一轮去掉 `block_base` 里 32 位 `%14` 的做法保持一致。

刻意**没有**做的改动（及原因）：
- 没有把 56 个 `slot_generation[j]+1` 增量器合并成一个共享增量器：那会新增一个 56:1 的宽 mux，
  扇入更集中，对拥塞可能反而更差，且会新增一条 `alloc_selected_index→56:1 mux→寄存器` 的关键路径。
- 没有删除 `slot_frame[56]` 数组：虽然 `slot_generation` 在饱和前严格单增、看起来可替代帧比较，
  但 `sim/tb_rgb565_slot_select.sv::check_release_snapshot` 明确依赖 `slot_frame` 快照语义，
  属于受保护的语义，不在本轮改动范围。

#### 验证

- `sim/run_rgb565_slot_select_test.sh` → `RGB565_SLOT_SELECT_PASS cases=69 randomized=64 max_latency=8`
- `sim/run_rgb565_lane_alloc_test.sh` → `RGB565_LANE_ALLOC_PASS cycles=8 first_slot=0 last_slot=7`
- `run_npu_image_service_test.sh` / `run_npu_image_system_test.sh` → PASS
- `run_flash_ddr_model_load_test.sh` → PASS
- `run_npu_cnn_test.sh`(cases=13) / `run_npu_cnn_service_test.sh` / `run_npu_cnn_system_test.sh` / `run_npu_cnn_96_cache_test.sh` → 全部 PASS
- `run_npu_road_model_test.sh` / `run_npu_road_model_v03_test.sh` → `NPU_ROAD_MODEL_V03_TEST_PASS cases=16 model_bytes=62720`
  （`max_cached_cycles=3819167 / 3853129`，limit `4375000`，与改动前的量级一致）
- `run_int8_conversion_gold_test.sh` → `SKIP missing current conversion/tensor gold`（缺基准，与本次改动无关）
- `git diff --check` 干净；改动只涉及 `soc/Hrgb565_int8_lane.v`。

改动后文件 SHA-256：`0f672b5b1a70f074946654dd3745b02b3cb34a9a02be4dae39af641eff5b6d47`
（同步前 D 盘为 `9b8ab63d44d7984a09f8874240725809b001940e6b92cb8ebadd819a70437317`）。

#### 预期与不确定性（重要）

- 这两处都属于“去掉冗余算术后缀”，对**时序**是顺向收益，对**面积/拥塞**是温和收益（预计量级在千 LUT 以内）。
- 单靠这一轮 RTL 微调**未必能**把 ~12k 未布通降到 0。真正决定布线能否收敛的是布局：同样大小的设计在 13:53 那轮是能布通的，
  本轮只是换个 netlist 布局就卡住，说明是**布局敏感**。若同步后仍卡住，下一步优先级：
  1. 对 `u_rgb565_int8`（或两个 lane 分别）加 pblock/区域约束，迫使布局摊开，缓解局部密度；
  2. 换 P&R 策略/种子重跑，观察是否只是布局落点问题；
  3. 再考虑结构性压缩 lane 的 56 深度宽数组。
- 本地仿真只能证明功能等价，不能证明 PDS 的 WNS/拥塞/布线时间。必须同步到 D 盘重跑 Compile/Synthesize/Place/Route 才能定论。

## 2026-10-19：第二轮 lane 改动的 P&R 实测（17:43 启动）与不收敛根因定位

### 实测数据

本轮 RTL：`soc/Hrgb565_int8_lane.v` SHA-256 `0f672b5b…`（第二轮拥塞优化版）。

- 综合 `Synthesize Setup WNS = -13.545 ns`、`TNS = -54791.869 ns`。
- 布局 `Worst slack after placement = -11413 ps`、`TNS = -84113880 ps`。
- 资源：`LUT 51760 / 159800 (33%)`、`FF 45071 / 319600`。
  第二轮改动基本面积中性（LUT -197，FF 持平）；`g_ddr_profile.u_rgb565_int8`
  综合后 14014 LUT / 13122 FF（上一轮 14185）。
- 布线到 19:01 仍在第 23 轮，`未布通 23422 / overused 96377`，未收敛。
  **单轮耗时 357.577 s（≈6 分钟）**，实测 100 s 内一轮都跑不完。

### 与前面几轮对比（关键）

| 轮次 | 布局 WNS | 布线表现 |
| --- | --- | --- |
| 13:53 基线 | -44.29 ns | 431 轮 / 2529 s，跑通（但 setup 仍失败 -44 ns） |
| 15:46（lane v1） | -11.70 ns | 单轮 20 s 涨到 140 s，卡住 |
| 17:43（lane v2） | -11.41 ns | 单轮 19 s 已涨到 357 s，卡住 |

- 按同一迭代号看，本轮的**拥塞收敛反而最好**：降到 23.4k 未布通时本轮是第 23 轮、
  基线约第 26 轮、lane v1 约第 31 轮。
- 但**单轮耗时是基线的 30 倍量级且仍在涨**（基线 431 轮平均 5.9 s/轮）。

结论：**时序越好、布线越慢**。这是时序驱动布局在追一个够不到的 8 ns 目标
（设计实际约 19~21 ns）时把逻辑摊不开／摊开不当造成的局部密度，而不是资源不够
（全设计只有 33% LUT / 15% FF）。

### 不收敛的直接证据

`place_route/fail_route_nets.txt`（801979 行，10-18 的失败布线转储）统计：

- 未布通 net 驱动端坐标：TX 2..121（峰值 60..110）、TY 54..232（峰值 90..140），
  最密点是 TX 70 / TY 130（单个 10x10 桶 568 条）。
- 而这块逻辑就是 `g_ddr_profile.u_rgb565_int8`（DMR 里
  `g_ddr_profile.u_rgb565_int8/lane[0].u_lane`、`lane[1].u_lane`）。
  注意这份转储是 10-18 14:19 的，早于本轮 lane 改动，只能作为“lane 是热点”
  的旁证，不是当前版本的验收数据。

### 翻 PDS 手册找到的对症开关（重要，下次优先试）

`docs/Pango_Design_Suite_User_Guide.pdf` 3.4.1「布局模块 / 布线模块」：

- **Placement Decongestion Mode**（tcl `pnr -plc_decongestion`）：
  “由于用户设计复杂，各逻辑间连接（Net）关系强，可能导致布局算法无法有效扩散，
  布局密度偏高，对时序优化以及布线时长造成不利影响。根据用户设计主要资源最大占比，
  设置面积扩展系数。设置值可选 [0..9]。一般情况下，模式设置值越大，布局范围越大，
  **布线速度越快，但时序将会变差**。”
  PG2L200H 默认值 1。手册提醒“资源使用率超过 70% 时大值不确定，建议 0..4”；
  本设计只有 33% LUT / 15% FF，可以安全取 3（或 4）。
  **这就是“布局密度偏高导致布线时间过长”的官方解法，比 pblock 更对症、零风险。**
- **Slack Weight**（`-slack_weight`，默认 90）：控制时序在布线中的权重。
  调低可让布线器不再死磕够不到的时序，收敛更快。
- **Dump Router Congestion Plot**（默认关）：勾上后 `place_route/CongestionPlot/`
  和 `CongestionNetInfo/` 会每轮输出拥塞节点；可用
  Report Summary -> Flow Summary 右键 “Open Congestion Plot” 可视化。
  **下次开这个，就不用靠转储反推了。**
- **Action Timeout(min)**（默认 0 = 不超时）：本设计单种子没有超时保护，
  所以能一路挂几小时。建议设 60~90，卡住自动杀。
- **Dispose Carry Chain Prior**（PG2L200H 默认关）：lane 里有 4817 个 CARRY，
  进位链是布线大户，可考虑勾上试。
- 多种子：`Iterations (Placement)` / `Maximum Number Of Mutil-seed …` 默认 1，
  配合 `Sort Strategy`/`Filter Strategies` 可并行跑多个种子挑最好的。
  鉴于我们已经观测到“同一 netlist 换布局落点就卡”，多种子是对症的兜底手段。

### 本轮新增的文件

- `soc_region.pcf`：`def_region` / `def_inst_region` 区域约束，把
  `g_ddr_profile.u_rgb565_int8` 约束到 x 40..179 / y 50..199。
  用法：Device Map 后 Tools -> Physical Constraint Editor (Post-Map) ->
  Select a pcf to edit -> 加入本文件 -> OK -> 再跑 Place/Route。
  坐标单位 = floor(CLMA/6)，与日志里的 TX/TY 一致（已用
  `CLMA_651_1218 -> TX 108 TY 203` 和时钟域表核对）。
  区域 140x150 = 21000 网格位 ≈ 器件 59750 位的 35% ≈ 56000 LUT 容量，
  lane 14014 LUT -> 局部密度约 25%。

### 下一步方案（用户确认：PDS 设置与区域约束两边一起改）

比赛规则最终确认**允许改 PDS 设置**，因此采用"两边一起上"，一次把收敛概率拉满。
代价是变好后分不清是哪一项起了作用；后续如需归因，再单独回退一项重跑。

**一、PDS 工程设置（Project Setting / 右侧 Options）**

| 选项 | 位置 | 现值 | 改为 | 依据 |
| --- | --- | --- | --- | --- |
| Placement Decongestion Mode | Place & Route → Placement | 1（默认） | **3** | 手册："值越大布局范围越大，布线速度越快，但时序将会变差"；本设计 33% LUT / 15% FF，远低于手册提醒的 70% 阈值，取 3 安全 |
| Dump Router Congestion Plot | Place & Route → Router | 关 | **开** | 每轮输出 `place_route/CongestionPlot/`、`CongestionNetInfo/`，可直接可视化拥塞，不用再靠转储反推 |
| Action Timeout(min) | Place & Route → General | 0（永不超时） | **90** | 卡住自动杀进程，避免再挂几小时 |
| Slack Weight | Place & Route → Router | 90 | **50**（可选） | 降低布线时对时序的权重，不再死磕够不到的 8 ns；这是四项里唯一有真实时序代价的，不想牺牲可保 90 |

**二、区域约束**

- 已写入 `project/device_map/Hfpga_soc.pcf`（该文件是 `project.pds` 里
  `wgt_edit_placement_cons` 实际引用的物理约束输入）末尾：
  ```
  def_region lane_region 40 179 50 199
  def_inst_region g_ddr_profile.u_rgb565_int8 lane_region
  ```
  原文件已备份为 `project/device_map/Hfpga_soc.pcf.bak_before_region`。
- 同时保留独立文件 `soc_region.pcf`（含方案 B：两个 lane 各占半区），
  可用 PCE 的 "Select a pcf to edit" 方式加入。
- **注意**：Device Map 会重新生成 `Hfpga_soc.pcf`。若整个流程重跑，
  需把 `Override .pcf` 设为 false，或在 Device Map 之后检查那两行 `def_region`
  / `def_inst_region` 是否还在；否则区域约束会静默失效，等于只测了设置那一半。
  最省事的做法是只跑 **Place & Route**（当前 Compile/Synthesize/Device Map
  输出已经是 lane v2 的）。

**三、判据**

跑完后看：`u_rgb565_int8` 的 LUT/FF、单轮 `MT total route time` 走势、
未布通/overuse 下降速度，以及 `CongestionPlot` 里最深的拥塞点在哪。
若单轮时间仍数百秒，说明密度没解开，下一步转 RTL（压缩 56 深度宽数组 /
4817 个进位链），或重新讨论 `ddr_core_clk` 的 8 ns 目标。

---

## 2026-10-19 22:2x　RTL：槽位 tag 改为 per-batch epoch（方案 A）

**背景**：`u_rgb565_int8` 两个 lane 实测 6909/7105 LUT、6553/6569 FF、
**2410/2407 个进位链（91 个 group）**，是局部拥塞与布线时间爆炸的主因
（baseline 跑到 iter 31 时单轮已达 468 s）。成本拆解与实测吻合：
56 个 `slot_generation[j] <= slot_generation[j]+1`（56×32 = 1792 个加法器
= 1792 LUT + 1792 进位链）占每 lane 进位链的 ~74%。

**改动**（`soc/Hrgb565_int8_lane.v`，纯结构，无流水级增减）：

1. 新增 `reg [31:0] gen_epoch`，复位值 `32'd1`。
2. `ST_ALLOC` 里 `slot_generation[j] <= gen_epoch`（同一批 8 个槽写**同一个值**，
   只剩 FF 的 CE，数据通路 0 LUT）；离批（转 `ST_AR` 或失败转 `ST_CLEAN`）时
   `gen_epoch <= gen_epoch + 1`。
3. `allocatable_mask` 增加 `gen_epoch != 32'hffff_ffff` 的全局饱和保护
   （保留原 per-slot 判断不动，测试台的饱和用例因此无需修改）。

**语义**：tag 仍是"每次占用唯一且单调递增"；同一批内多槽共享 tag，
由 `(槽号, tag)` 共同定位一次占用，释放匹配只会更严格。
分配顺序（最低号空闲槽）、accept-time 快照、每拍 1 槽、≤8 拍进 AXI 全部不变。

**预期收益（每 lane）**：−1792 LUT、−1792 进位链（另加 1 个 epoch 加法器，
净约 −1760 / −1760）。FF 数量不变。

**验证**：Verilator 全绿，且**测试台零改动**
- `RGB565_SLOT_SELECT_PASS cases=69 randomized=64 max_latency=8`
- `RGB565_LANE_ALLOC_PASS cycles=8`
- `CAMERA_STEREO_PASS`（端到端 DDR checksum 校验）
- `NPU_IMAGE_SYSTEM_PASS results=2 releases=2`
- `NPU_CNN_SYSTEM_PASS results=2 releases=2`
- `NPU_ROAD_V03_PASS cases=16 layer_checks=144` / `NPU_ROAD_MODEL_V03_TEST_PASS`

**待 PDS 确认**：`synthesize/Hfpga_soc.snr` 的 LUT / LUT CARRY、单轮
`MT total route time` 走势、unrouted/overuse 轨迹、最终 WNS。
本地只能证明功能，证明不了物理指标。

**后续可选**（本轮未做）：`used_slots` 改增量计数（−~400 LUT，但 `peak_slots`
瞬态可能差 1）、`slot_state` 改 one-hot 掩码（−~300 LUT）、
释放路径 56:1 宽 mux 进 LUTRAM（−~2600 LUT，但要给 release 加 1 拍，**可能影响吞吐，暂不做**）。

## 2026-10-19 22:4x　RTL：used_slots 改为 free_count 的补数

**改动**：删除 `slot_used_points` / `used_group_count` / 整棵 `used_pair*`
加法树（原来每拍做 7 组 `popcount8` + 平衡归约），改为

```verilog
wire [5:0] used_count_next = 6'd56 - free_count;
```

`free_count` 本来就要算（`desc_ready` 用），所以这一项从"每拍 56 位归约"
变成"一个 6 位减法"。

**等价性**：正常运行时每个 `state==0` 的槽都可分配，故
`56 - free_count == #{slot_state != 0}`；两者都打一拍进 `used_slots`，
**输出逐位一致**，`peak_slots` 也不会漂移，历史数据仍可比较。
唯一差异出现在 TB 强制 `slot_generation==0xffff_ffff` 的退役槽场景，
而 `used_slots` 不被任何用例或控制路径使用。

**收益（每 lane）**：约 −160 LUT、−160 进位链。
**验证**：全套回归重跑仍全绿（见上）。

## 2026-10-19 22:4x　评估后放弃：slot_state 改 one-hot

复核后放弃，理由写清楚免得以后重复讨论：
- 收益约 −500 LUT（8 个 CLEAN 态索引读 + 索引写译码 + 释放读），
  但 `tb_rgb565_slot_select.sv` 里有 **15 处**直接读写 `dut.slot_state`
  并断言 0/1/2 三态组合（`check_capacity_stall` / `check_release_snapshot`
  / `check_allocation`）。改编码必须把这 15 处全部重写，
  等于把"释放快照"那条唯一的守卫用例也一起改掉。
- 收益/风险比不划算。等 P&R 实测 A+C 之后若密度仍不够，再连同 TB 一起改。
