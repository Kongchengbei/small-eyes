# 盘古 676 系列底板：DDR 与 Flash 启动核查

截至 2026-09-25。用户确认实物 J10 是 SD 卡槽，核心板实装 FPGA 为 **PG2L200H**。盘古 100Pro+ 与 200Pro+ 共用兼容底板布局，但分别装 PG2L100H 与 PG2L200H；此处以实装 PG2L200H 为工程目标。

## 已核实

- 当前 `project/project.pds` 选择 `PG2L200H-FBB676`，`IP/clk_pll/clk_pll.idf` 和 `IP/ddr3_ctrl_v116/ddr3_ctrl_v116.idf` 也由 PG2L200H 生成；与实装器件型号一致，不需要改成 PG2L100H。封装 FBB676 与工程及 200Pro+ 资料一致。
- 资料包的 `2_Demo/2_9_ddr3_test` 是 PG2L100H 的 DDR 示例，其 `.sbit` 不能用于实装 PG2L200H。仓库的 `vendor_demo/ddr3_test_200pro/` 是 PG2L200H-FBB676 的 DDR 示例，可作为这块板 DDR 初始化与读写的第一步测试；它不是当前 SoC 的 CPU/Flash 启动位流。
- 当前 `soc.fdc` 与 PG2L100H 示例的 71 个同名 DDR 信号位置完全相同；`clk=D18`、`hard_rst_n=C22`、`core_active=A20` 也对应系列底板的时钟、按键及 LED。这支持底板布线共用的判断，尚不能代替上板验证。
- 当前 `soc.fdc` 将自定义 JTAG 的 R20/P19/M24/T24 标成 MINI 底板 J10 扩展口 4/6/8/10。用户实物 J10 是 SD 卡槽；100Pro+ 底板手册把 R20、P19、T24 分别用于 HDMI 输出的行同步、数据位 0 和像素时钟。不能从 J10 接入这条自定义 JTAG。PDS 配置用的板载 JTAG 与这些普通 IO 上的自定义 JTAG 是两条不同路径。
- PG2L100H DDR 示例采用 AXI Reduced 接口；当前 PG2L200H DDR IP 采用 AXI Standard 接口。两份示例 IP 不能互换，但当前 SoC 的 DDR bridge 与其 PG2L200H DDR IP 接口类型一致，不需要为了板卡名称改用 100H IP。
- `manual/QSPI_Flash到DDR启动搬运方案.md` 的目标写为 PG2L200H。其启动顺序仍可作设计参考，但 Flash 用户模式读取、DDR 搬运和 CPU 复位门控尚未进入当前 RTL；把程序放进 Flash 用户数据区不会自动执行。

## 下一次上板的顺序

1. 用 `vendor_demo/ddr3_test_200pro/ipcore/ddr3_test/pnr/generate_bitstream/test_ddr.sbit` 验证 DDR 初始化与读写结果，并保留当前 PG2L200H 工程及 IP。
2. 对照实物底板重新核对顶层普通 IO，特别是自定义 JTAG 四根线。不要按 MINI 底板的 J10 扩展口注释接线。
3. 为 Flash 用户数据实现 256 字节固定地址读取、DDR 搬运与回读；校验成功后释放 CPU，运行 `0x8000_0000` 的最小程序，最后再加入多镜像和 AI 权重。

## 资料来源

- `G:/2026FPGA创新设计竞赛紫光同创杯资料包/盘古100Pro+开发板（MES2L676-100HP）配套资料/1_Demo_document/实验例程说明篇/教程1_硬件实验指导手册_盘古676系列100Pro+开发板.pdf`（首页列出 100Pro+ 与 200Pro+ 器件型号）
- 同一资料包的 `2_Demo/2_9_ddr3_test/`（PG2L100H 示例）
- `vendor_demo/ddr3_test_200pro/`（PG2L200H 示例）
- `F:/Jichuang-small_eyes/manual/2026小眼睛职业技能赛配套资料包/02 远程实验平台FPGA主板卡配套资料/1_Demo_document/实验例程说明篇/教程1_盘古MINI系列开发板硬件指导手册_V1.3.pdf`（仅用于解释旧 J10 注释的来源）
- [小眼睛科技对盘古 676 系列两款板卡的说明](https://bbs.elecfans.com/jishu_2477585_1_1.html)
