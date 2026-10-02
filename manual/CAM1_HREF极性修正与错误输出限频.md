# CAM1 同步极性修正、固件复测与错误输出限频

## 当前版本：0x4740=0x20，等待实板复测

日期：2026-10-01。用户在了解采样规则和源码位置后明确授权编译新 bin。
本轮由 Luna High 子代理修改 C 配置/回读和仿真模型，主代理核对产物及记录。
仅将 `ov5640_regs.c` 的配置从 `0x23` 改为 `0x20`，`ov5640.c` 的回读
expected 改为 `0x20`、mask 保持 `0x23`；错误输出限频和尺寸报告保持不变。
不改 DVP/FIFO/DMA RTL、MMIO、DDR 地址、引脚或 loader 长度。

### 撤回上一轮极性解释

21:42 实板日志中，摄像头 ID 为 `0x5640`，配置回读通过；DVP 计数约15次/秒，
但成功帧为0，DROPPED 与 DVP 帧数一起增加。DMA_CODE=4，DVP_FLAGS=0x0D，
FIFO_ERROR=0、FIFO_MAX=4。`0x0D` 表示奇数字节、帧行数错误及 VSYNC/HREF
交叠；并非 DDR timeout 或已记录的 FIFO overflow。
DMA current=1895像素/3790字节/0行，不代表摄像头原始输出只有这些数据。

上一轮直接将数据手册表格的 polarity/active high 标签当作数据有效电平，
建议 `0x23` 并构造了同样假设的测试模型。这一解释和它所声称的“已匹配”撤回。
原回归结果只证明了错误模型下的自洽，不能作为实板极性正确的证据。

主代理与子代理分别核对本地
`4_IC_datasheet/OV5640/OV5640_AF_Imaging_Module_Application_Guide_(DVP_Interface).pdf`
第27页 §4.2，其明确写明数据有效电平和输出边沿：

| 位 | 本轮取值 | 应用指南含义 |
| --- | --- | --- |
| 0x4740[0] | 0 | VSYNC 低时输出数据有效 |
| 0x4740[1] | 0 | HREF 高时输出数据有效 |
| 0x4740[5] | 1 | 数据在 PCLK 下降沿输出 |

因此按该指南，`0x20` 对应当前 RTL 的 `!vsync && href`、PCLK 上升沿采样。
数据手册第93/133页的 polarity 表措辞与指南存在冲突，本轮以指南为受控复测
依据，不把修改说成已确认的实板根因。若仍失败，应观察实际同步/数据波形。

仿真模型已改为按寄存器 bit0/bit1 派生 VSYNC/HREF 的有效及空白电平，
并检查 `(4740 & 0x23) == 0x20`；bit5要求下降沿更新数据。
模型验证的是该指南解释下的软件/RTL自洽，不模拟真实板卡全部电气时序。

### 当前烧录文件

| 文件 | UART TX | 长度 | SHA-256 |
| --- | --- | ---: | --- |
| `bsp/camera_app/camera_uart_debug_local.bin` | C24 本地 | 6956字节 | `b8040bdc94718d4d35798f6e60d46e95a4ed01df6bd4b2f8394b6a6a4b4f8c0a` |
| `bsp/camera_app/camera_uart_debug_remote.bin` | AB26 远程 | 6956字节 | `35f321ce63f111fd67010c0a1758b4b8660708af1f883e9f2046a4db14dfcc04` |
| `bsp/camera_app/camera_uart_debug.bin` | local兼容副本 | 6956字节 | 与local相同 |

`make -C bsp/camera_app all` 已成功；local/remote原始bin均为6956字节。
原始小端bin直接用于软件区域，**不做端序交换**。Flash地址仍为 `0x00A00000`。
如果当前板上已使用 `BOOT_IMAGE_BYTES=6956` 的匹配位流，仅更新软件镜像即可，
无需因为这次C配置修改重新综合。若使用组合SFC，必须重新组合并验证软件区域；
旧SFC不会自动包含新bin。本轮没有生成SFC、打开PDS、烧写或访问实板。

GPIO备用bin保持原内容，不用于本次摄像头采图复测。
**引脚修改记录：本轮零修改**，Camera SCL=W21、SDA=U14、RESETB=T20；
UART local=C24、remote=AB26。`soc.fdc` 未修改。

### 离线回归及实板验收

完整帧与错误帧回归命令：

```sh
make camera-uart-fw-test camera-error-report-fw-test
```

日志：`build/camera_4740_20_firmware_regression.log`，完整命令退出码0。

- local/remote完整帧通过：480行、307200像素、614400字节、DMA_CODE=0，
  DDR sum16=0x8A800000且MATCH=YES，校验后成功释放缓冲。
- 真实FPIOA引脚UART解码通过，pin0/pin31各1775字节。
- 479行坏帧回归通过：失败帧不伪报成功，尺寸错误快照与重复错误限频检查通过。
- 子代理执行修正模型的Verilator lint通过；相关源码/记录diffcheck通过。
- local与兼容副本相同，原始bin与交付bin相同；GPIO bin哈希未变。
- DVP/DMA/子系统/顶层和soc.fdc的SHA-256与本轮修改前逐项相同。

以上是离线模型结果，**不是实板成功记录**。
实板重启后请保存从启动到首次完整帧/错误快照的日志，验收480行、307200像素、
614400字节、DMA无错、READY有效及DDR checksum MATCH=YES。
首次启动尚未完成帧时主值为0可以正常，之后必须出现成功帧；若错误持续，保留
括号current值、DVP帧数、FIFO峰值及错误码，不要只贴ID或REG WRITE OK。

## 以下为历史记录：0x21→0x23，极性判断已撤回

下面保留上一轮授权、旧hash和回归经过，便于追溯；不是当前烧录指导。
上一轮的错误报告限频仍有效，极性解释和模拟极性的验收结论已被上文取代。

## 实板日志与诊断

用户更正 FMC 插接后，实板能读到 OV5640 ID `0x56/0x40`，配置回读通过，并进入
采集。随后反复打印：

```text
STATUS=0x00004C0F DMA_STATUS=0x00000009 DMA_CODE=0x00000004
FIFO_ERROR=0x00000000 DVP_FLAGS=0x00000004 RAW_FLAGS=0x00000004
```

- DMA_CODE=4：某帧像素总数不等于 307200，并非 DDR timeout。
- DVP_FLAGS bit2=1：某帧行数不等于 480。
- DVP_FLAGS 与 RAW_FLAGS 是同一组 DVP 粘滞标志的读值，不是两次独立错误。
- 重复打印粘滞位不代表每一行日志都对应一次新故障。
- 首次 FRAME=0、尺寸=0、地址=0xFFFFFFFF 是首帧未完成时的探活快照，不等于
  摄像头整个运行期间都没有输出。

本地 `manual/4_IC_datasheet/OV5640/OV5640_DataSheet.pdf`，PDF 第 93 页表 6-6
及第 133 页表 7-18：`0x4740.bit1` 为 HREF polarity，0=低有效，1=高有效。
之前固件写入 0x21，bit1=0，却在 `Hcamera_dvp_rx.v` 中按 HREF 高有效接收，
形成明确的配置/RTL 约定矛盾。原回读检查也期待 0x21，所以“REG WRITE OK”不能
发现这一矛盾。宽高寄存器 0x3808–0x380B 对应 640×480，不需要因此改分辨率。

该矛盾是本轮优先修正项；尚未凭物理波形证明它是实板全部错误的唯一来源。
后续还需复测每帧行数/像素数、FIFO、DDR checksum，而不是仅看 ID 或 ACK。

## 修改记录

| 文件/项目 | 修改前 | 修改后 |
| --- | --- | --- |
| `bsp/camera_app/ov5640_regs.c` | 0x4740=0x21 | 0x4740=0x23，VSYNC/HREF 均高有效 |
| `bsp/camera_app/ov5640.c` | 期望0x21、mask0x23 | 期望0x23、mask仍0x23 |
| `bsp/camera_app/main.c` | 每次错误快照都打印 ERROR DETAIL | 首次/错误签名变化打印 ERROR SNAPSHOT 与完整字段 |
| `bsp/camera_app/Makefile` | 原始 bin 直接交付 | 完整原始加载内容检查后填零到6956，超长失败，不截断 |
| `sim/tb_Htop.sv` | 模型硬编码 HREF 高有效，与配置无关联 | 检查4740极性，HREF波形按模型寄存器产生 |

**引脚没有修改**：SCL=W21、SDA=U14、RESETB=T20，UART local=C24、remote=AB26。
未改 `soc.fdc` 的任何物理约束，未改 DVP/FIFO/DMA RTL、寄存器布局或缓冲区地址。
本轮仿真修改仅用于验收，不进入实板位流。

错误签名仅含 CAM_STATUS 的 FIFO overflow/underflow、DMA/DVP error 位，DMA_STATUS
的 error 位及错误码/flags；忽略 frame active、busy、done、ready 等动态运行态。
因此，同一错误下正常状态波动不会重复触发整份错误输出。
无 ready 帧时约每 1000 次轮询打印完整状态，同轮去重；有 ready 帧仍显示该帧
统计、DDR 样本/checksum，校验后释放缓冲。异常状态仍不会被当作有效帧。

`LINES/PIXELS/BYTES` 主值是最近成功完成帧，括号 `current` 是 DMA 当前帧统计。
失败帧不更新成功描述；不能把主值0误读为“失败帧实际收到0”。current 计数会随
下一帧重置，本轮没有扩展 RTL 保存每个失败帧的历史描述。

## 新软件文件与加载方式

```sh
make -C bsp/camera_app all
```

local/remote 原始 bin 均为 6956 字节；构建支持更短程序末尾填零，不改变当前
`BOOT_IMAGE_BYTES=6956`。本轮没有增加 loader 长度，因此已经使用匹配位流的
实板不需要因本次软件修正重新综合，但必须重新组合/烧写并 Verify 软件区域。

| 文件 | 用途 | SHA-256 |
| --- | --- | --- |
| `bsp/camera_app/camera_uart_debug_local.bin` | 本地 C24 | `ed27c246361c625e289cb2913a41d929d2d8c736ea612cb4ef17d1077610f571` |
| `bsp/camera_app/camera_uart_debug_remote.bin` | 远程 AB26 | `bf0a80b62e2172b1f1dc4fa719e60e39881f0a3050dc0fafc017ef025f9d75dd` |
| `bsp/camera_app/camera_uart_debug.bin` | local 的兼容副本 | 与 local 相同 |

软件仍放 Flash `0x00A00000`，使用原始 bin，不做端序交换。
旧同名文件/SFC 不会因源码更新而自动变为新镜像，需检查所选文件的 hash。
如果板上位流还是旧6944字节版本，仍须先按 UART 修改记录更新，不适用“只换bin”。
GPIO 备用程序独立保留，说明见 `CAM1_GPIO最小翻转测试.md`；它保持传感器复位，
不用于这次 DVP 错误复测。

## 回归与实板复测

旧 0x21 local bin 已保存在本地 build 诊断目录，以新的极性检查执行，明确报
`DVP 极性与接收器约定不符: 4740=21`，证明原联合测试存在漏检。
这个负例不模拟物理板卡，而是防止测试模型再次掩盖初始化约定矛盾。
记录：`build/camera_href_review/before_expected_failure.log`。

新固件最终回归通过：

```sh
make camera-uart-fw-test
make camera-error-report-fw-test
make camera-board-lint lint camera-dvp-rx-test camera-sccb-gpio-test
make sim cpu-load-store-test
```

- local 与 remote 两套真实 CPU 固件执行通过，实际 FPIOA UART TX 解码各1775字节；
  VGA完整帧480行/307200像素/614400字节，DDR checksum=0x8A800000、MATCH=YES，
  缓冲校验后释放。日志：`build/camera_href_review/after_firmware.log`。
- 注入479行帧时，完整同一份 ERROR SNAPSHOT 正确打印 current 479行、306560像素、
  613120字节、DVP flags=4、DMA code=4、ready=0；失败帧没有伪报成功或释放。
  随后继续运行至少1000000 CPU周期，相同错误标题不再刷屏，实际UART输出排空后
  报 `CAMERA_BAD_FRAME_REPORT_PASS`。日志：`build/camera_href_review/error_reporting.log`。
- board lint、模块 lint、DVP RX/SCCB GPIO 通过，见
  `build/camera_href_review/module_checks.log`。
- ISA46/46、load-to-store1/1通过，见`build/camera_href_review/cpu_checks.log`。
- bin长度、兼容副本与hash核对及相关文件`git diff --check`通过；独立GPIO测试
  local/remote/SDA恒低三项也已通过，见其专项记录。

用户复测时先开串口保存日志，再重启：检查 ID/config，通过后关注
480 行、307200 像素、614400 字节、READY BUFFER、DDR checksum MATCH=YES。
如还有错误，发送首次 ERROR SNAPSHOT 的全部字段和后续定期快照，不必贴大量
重复摘要；要保留括号 current 值、FIFO水位/峰值、DVP帧数及错误码。
助手未打开 PDS、未上板或烧写，本记录不声称实板问题已经解决。
