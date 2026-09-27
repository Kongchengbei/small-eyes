# 盘古 676 系列底板：DDR 与 Flash 启动核查

截至 2026-09-26。用户确认实物 J10 是 SD 卡槽，核心板实装 FPGA 为 **PG2L200H-FBB676**。盘古 100Pro+ 与 200Pro+ 共用兼容底板布局，但分别装 PG2L100H 与 PG2L200H；此处以实装 PG2L200H 为工程目标。

本文件此前的 2026-09-25 状态段落是历史核查快照。当前 Flash 编程与启动证据以[实板烧写记录](PG2L200H_Flash烧写与DDR启动实板记录.md)为准：一颗 Outer Flash 已经编程并两次 Verify 成功，第二颗未烧写；尚无断电自主启动、DDR 搬运读回或 CPU 流水灯实板成功的确认。

## 当前实现状态

- 已完成 Flash→DDR→CPU 流水灯 smoke 设计接入：固定从 Flash 用户地址 `0x00A00000` 读取 `test/running_led_test.bin`（56 bytes），写入 DDR `0x80000000` 并逐 word readback 后才允许 CPU 执行。实现细节、仿真证据和硬件限制见 [Flash_DDR_Boot_Review.md](Flash_DDR_Boot_Review.md)。
- 最终回归复核：`make flash-ddr-boot-test` 验证 56-byte copy、CPU 的 LED 写、延迟初始化等待预算、readback 错误、ready-drop clock disable 和 reset 重试；`make spi-flash-reader-test`、旧 `make flash-boot-smoke`（四指令 `0x5a` 成功/失败两支）及 `make lint` 均通过。集成仿真观测 100050-cycle init 延迟、56 bytes/56 reads、CPU 首个 LED 写 1（PC `0x8000001c`）、错误码 6、ready-drop 错误码 2 和 reset recovery。这些是仿真证据，不是实板启动结果。
- PDS 已生成当前 `.sbit/.sfc` 并完成对一颗 Outer Flash 的擦写与两次 Verify。实际器件扫描 ID 为 `0x0B4018`，PDS 以 `xt25f128` 自定义项和 WINBOND/W25Q 兼容模板识别，容量 128 Mbit；这不是实物丝印型号确认。第二颗未写入，不能称作 X8 烧写。
- 当前选用 PG2L200H pin plan：P18 CS、F25 第二片选保持闲置、R14 MOSI、R15 MISO、P14 WP、N14 HOLD、H13 GTP_CFGCLK。该方案不等于 PCB 连线证明。此前“确认原理图/导通后再烧写”属于烧写前的历史待办；现在应把剩余核对用于解释板级连线，不抹去已完成的烧写事实。

## 已核实

- 当前 `project/project.pds` 选择 `PG2L200H-FBB676`，`IP/clk_pll/clk_pll.idf` 和 `IP/ddr3_ctrl_v116/ddr3_ctrl_v116.idf` 也由 PG2L200H 生成；与实装器件型号一致，不需要改成 PG2L100H。封装 FBB676 与工程及 200Pro+ 资料一致。
- 资料包的 `2_Demo/2_9_ddr3_test` 是 PG2L100H 的 DDR 示例，其 `.sbit` 不能用于实装 PG2L200H。仓库的 `vendor_demo/ddr3_test_200pro/` 是 PG2L200H-FBB676 的 DDR 示例，可作为这块板 DDR 初始化与读写的第一步测试；它不是当前 SoC 的 CPU/Flash 启动位流。
- 当前 `soc.fdc` 与 PG2L100H 示例的 71 个同名 DDR 信号位置完全相同；`clk=D18`、`hard_rst_n=C22`、`core_active=A20` 也对应系列底板的时钟、按键及 LED。这支持底板布线共用的判断，尚不能代替上板验证。
- 当前 `soc.fdc` 将自定义 JTAG 的 R20/P19/M24/T24 标成 MINI 底板 J10 扩展口 4/6/8/10。用户实物 J10 是 SD 卡槽；100Pro+ 底板手册把 R20、P19、T24 分别用于 HDMI 输出的行同步、数据位 0 和像素时钟。不能从 J10 接入这条自定义 JTAG。PDS 配置用的板载 JTAG 与这些普通 IO 上的自定义 JTAG 是两条不同路径。
- `Hfpga_soc` 的自定义 CPU JTAG 顶层输入会影响 reset/halt 请求，不是 PDS 板载下载 JTAG，也不是通过普通 IO 烧写 Flash 的接口。上板观察前核对它们的实际板级连接；未用的调试输入应保持可靠静态电平，避免意外请求阻止 CPU 运行。
- PG2L100H DDR 示例采用 AXI Reduced 接口；当前 PG2L200H DDR IP 采用 AXI Standard 接口。两份示例 IP 不能互换，但当前 SoC 的 DDR bridge 与其 PG2L200H DDR IP 接口类型一致，不需要为了板卡名称改用 100H IP。
- `manual/QSPI_Flash到DDR启动搬运方案.md` 保留原有 X8、数据头、CRC、多镜像和 AI 权重构想作为未来扩展。当前实现先走单颗 Flash SPI X1 和 56-byte 固定程序；不要把旧 X8 方案误当作当前 RTL。

## 后续上电验证

1. 用户已报告 DDR BIST 通过，不必重复该验证；保留 PG2L200H 工程及 IP。
2. 断电重启，记录 FPGA 是否从地址 0 配置，以及 DDR init、Flash 用户数据读取、DDR 写入/逐字回读、CPU reset 释放和 LED 行为。当前没有这些上电实测结果。
3. 若启动失败，再结合工程实际配置、板级连接资料和可观察信号定位；封装资料只说明芯片球位功能，不能代替 PCB 网络证明。不要按 MINI 底板 J10 注释接线，J10 是 SD 卡槽。
4. X1 单片流程获得实板启动证据后，再规划 X8、通用镜像、CRC 和 AI 权重，不将未来功能记为当前完成项。

## 资料来源

- `G:/2026FPGA创新设计竞赛紫光同创杯资料包/盘古100Pro+开发板（MES2L676-100HP）配套资料/1_Demo_document/实验例程说明篇/教程1_硬件实验指导手册_盘古676系列100Pro+开发板.pdf`（首页列出 100Pro+ 与 200Pro+ 器件型号）
- 同一资料包的 `2_Demo/2_9_ddr3_test/`（PG2L100H 示例）
- `vendor_demo/ddr3_test_200pro/`（PG2L200H 示例）
- `F:/Jichuang-small_eyes/manual/2026小眼睛职业技能赛配套资料包/02 远程实验平台FPGA主板卡配套资料/1_Demo_document/实验例程说明篇/教程1_盘古MINI系列开发板硬件指导手册_V1.3.pdf`（仅用于解释旧 J10 注释的来源）
- [小眼睛科技对盘古 676 系列两款板卡的说明](https://bbs.elecfans.com/jishu_2477585_1_1.html)
