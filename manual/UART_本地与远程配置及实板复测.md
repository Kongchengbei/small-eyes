# UART 本地与远程配置及实板复测

日期：2026-10-01。范围：本地/远程 UART TX 配置、FPIOA 字节访问修正及离线回归。
后续 Camera `0x4740=0x20` 固件复测没有改变这里的引脚/6956 字节加载长度，但 Camera bin hash
已更新；本记录中的哈希保留为 UART 阶段历史，当前烧录请看
[CAM1_HREF极性修正与错误输出限频.md](CAM1_HREF极性修正与错误输出限频.md)。
本轮由 Luna High 子代理分别实施固件和 RTL，主代理联合检查。
未打开 PDS、未综合、未烧写、未访问实板串口；最终由用户统一 review、测试。

## 引脚修改记录（修改前 → 修改后）

**本次修改的是 UART 功能映射，不是 FPGA 管脚位置。** `soc.fdc` 只修改了说明注释，
下列 `PAP_IO_LOC`、3.3 V 和 LVCMOS33 约束均保持原值；Camera、FMC、DDR 引脚未改。

| 用途 | FPIOA | FPGA 管脚 | 修改前 | 修改后 |
| --- | --- | --- | --- | --- |
| 本地主板 USB-UART 的 FPGA TX | 0 | C24 | 没有默认 UART 映射 | RTL 默认映射 UART0_TX；local 固件选择它 |
| 本地主板 USB-UART 的 FPGA RX | 1 | B24 | 未实现 UART RX | 不变，当前仍只使用 TX |
| 远程测试平台 UART TX | 31 | AB26 | RTL 与固件默认选择它，曾误当成本地串口 | 保留物理约束；remote 固件选择它，本地版本关闭它的 UART 映射 |

本地资料依据：配套资料 `1_Demo_document/实验例程说明篇/`
`教程1_硬件实验指导手册_盘古676系列100Pro+开发板.pdf`，PDF 第 44 页
（印刷页码 40），板载 CP2102 的 FPGA_UART_TXD=C24、FPGA_UART_RXD=B24。
资料根目录为用户指定的 G 盘盘古 100Pro+ 配套资料。
AB26 的远程平台用途由用户确认，不据此推断本地主板扩展接口接法，也不建议改线。
当前 200H 实板仍应按其板卡版本复核 CP2102 连线，不能把配套 100Pro+ 手册当作
未经验证的 200H 板卡原理图。

具体修改位置：

- `soc.fdc`：明确 C24/B24 是本地 UART 候选脚，AB26 是远程平台候选脚；LOC 不变。
- `soc/Hfpioa_simple.v`：新增 `UART_TX_DEFAULT_FPIOA`，默认 0；远程复位配置可选 31。
- `soc/Hfpga_soc.v`：向 FPIOA 传入同名参数，默认 0；loader 长度同步为 6956。
- `bsp/camera_app/uart.h`：`CAMERA_UART_TX_FPIOA` 默认 0。
- `bsp/camera_app/uart.c`：启动先清除 0、31 两个 UART 映射，再只启用所选脚。
- `bsp/camera_app/Makefile`：local 编译选择 0，remote 选择 31，对象目录独立。

两套固件都能在本轮修正后的同一份默认本地位流上选择各自输出脚；只有需要改变
复位初始映射时，才需额外将 RTL 参数设为 31。不要让两个候选脚同时输出 UART。
“关闭 UART 映射”写入功能 0，即 NIO；当前 NIO 输出使能复位为 0，因此保持高阻。
若其他软件另行启用 NIO 输出，功能 0 不保证仍为高阻。

## 同时修复：对齐 MMIO 字节写

真实 CPU 执行 `FPIOA_OUT_MAP(31)=7` 时，AXI 请求是：

```text
地址 0x40000F1C，数据 0x07000000，WSTRB=0b1000
```

原接口仅看地址低位，错误更新映射项 28，导致软件无法重新启用项 31；旧版复位时
项 31 已是 UART，因此此前的简单测试没有暴露问题。
现按对齐字基址与各 WSTRB 更新相应项，读取返回同一对齐字的四个映射字节。
保持 CPU/AXI 总线定义不变，不修改 Camera DMA 数据通路。

## 固件选择和位流更新

```sh
make -C bsp/camera_app all
```

| 使用场景 | 软件文件 | 长度 |
| --- | --- | ---: |
| 本地主板 CP2102 串口 | `bsp/camera_app/camera_uart_debug_local.bin` | 6956 字节 |
| 远程平台 AB26 串口 | `bsp/camera_app/camera_uart_debug_remote.bin` | 6956 字节 |
| 兼容旧文件名 | `bsp/camera_app/camera_uart_debug.bin`，与 local 完全一致 | 6956 字节 |

SHA-256：

```text
local : 22d11470af3716ac9d679483d7f7899d7d75acdafc1936f54c92688e75370111
remote: 7b275dcfb53c510c3bd55f51b354bc06a468bdf595dec8241bc116fa463b7f7b
```

**必须重新生成位流，不能只替换 bin。** 本轮改变了 FPIOA RTL，loader 长度也由
6944 改为 6956。此前用户生成的 `project/generate_bitstream/Hfpga_soc.sbit` 和
`.sfc` 没有由助手改写，仍是本轮修改之前的版本，不能当作已更新产物使用。

用户重新编译后，将新 `.sbit` 放到 Flash `0x000000`，所选新 `.bin` 放到
`0x00A00000`，再按 PDS 流程生成/烧写/校验组合镜像。直接使用原始 bin 字节，
**不要做大小端交换**。测试目录的 `.be.bin/.hex` 只是仿真 `$readmemh` 的输入，
不能用于 Flash 烧写。

## 离线回归与用户复测

```sh
make fpioa-uart-profiles-test
make camera-uart-fw-test
make camera-board-lint lint sim cpu-load-store-test
```

FPIOA 定向测试检查本地/远程复位映射、另一候选脚高阻、软件切换、对齐地址
0x1C 的 lane 3 只更新项 31、partial/full/零 WSTRB 及四字节读回。
CPU 联合测试分别执行两套 bin，从实际 FPIOA[0]/[31] 解码 115200、8-N-1 串行
输出，不再仅检查 UART TXDATA；同时保留 CAM1 初始化、DMA/DDR checksum 和释放
缓冲的原有检查。

本轮最终回归通过，日志：`build/uart_profiles_final_regression.log`。

```text
UART_PIN_PASS pin=0 bytes=1774
UART_PIN_PASS pin=31 bytes=1774
UART_FIRMWARE_PASS: Camera DMA/DDR samples/checksum/release  （两套均通过）
PASS: UART FPIOA default profiles and MMIO byte lanes
CPU ISA: PASS=46 FAIL=0 TIMEOUT=0 ERROR=0 TOTAL=46
load-to-store: PASS=1 FAIL=0 TIMEOUT=0 ERROR=0 TOTAL=1
```

`camera-board-lint`、`lint` 以及相关文件 `git diff --check` 通过；两套 bin 均为
6956 字节，兼容 bin 与 local 的内容及 hash 一致。上述日志中的首次失败排查不
属于最终通过记录；`build/uart_remote_lane_diagnose.log` 保留了修正前字节写问题。

用户实板步骤：

1. 检查重新生成的位流来自当前源码，loader 长度为 6956；本地选择 local bin。
2. 优先使用资料包 SSCOM，选择已确认的 CP2102 COM 口，115200 / 8-N-1 / 无流控。
   在复位前先打开串口并保存接收日志。串口工具的“发送 bin 文件”不是本工程的
   固件下载方式，程序仍由 Flash loader 加载。
3. 烧录 Verify 成功后复位或断电重启，检查启动标题、`UART TEST OK`、`DDR INIT OK`
   及后续 CAM1 状态。接收显示使用文本模式。
4. 如仍无输出，记录新位流时间、所选 bin/hash、烧录/Verify 日志、COM 口及复位
   操作，再检查 200H 实板原理图/CP2102 连线和启动链；不能仅凭截图认定 CPU 已运行。

JTAG/Flash timeout 是另外的下载链路问题；上述仿真通过不代表此前失败的 Flash
编程已经成功，也不代表物理串口和 DDR 已完成实板验收。
