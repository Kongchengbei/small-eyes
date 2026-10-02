# CAM1 DMA / DDR / MMIO：离线验收与实板 Review

日期：2026-10-01。以《整体目标.md》为主线，本轮只完成单路物理 CAM1。
按要求使用 Luna High 子代理分别实现 DMA、Camera 子系统和 C 固件，再联合审查。
没有启动 PDS、综合、布局布线、烧写、上电或打开串口。

## 当前链路

```text
OV5640 CAM1 → DVP RX → 18-bit Async FIFO → Camera DMA → DDR 双缓冲
                    状态与完成描述 → MMIO snapshot → CPU → UART TX → PC
CPU 另从已锁定的 DDR 完成帧读取 8 个样本及全帧 checksum
```

硬件模块均为自主实现，未沿用 camera_demo 的数据通路、器件 IP 或 bitstream。
OV5640 初始化仍由 C 软件经 GPIO SCCB 执行，250 项配置及关键寄存器回读保持不变。
图像格式为 640×480 RGB565：480 行、307200 像素、614400 字节；高字节先从 DVP
到达，DDR 按小端 uint16_t 存储。

主要入口：`soc/Hcamera_subsystem.v`、`soc/Hcamera_dma.v`、
`soc/Hcamera_async_fifo.v`、`soc/Hcamera_dvp_rx.v`、`soc/camera_regs.vh`。
实际 `soc/Hfpga_soc.v` 已实例化子系统和 DDR 仲裁，PDS 工程已加入新源文件。

Camera DMA 在 DDR core clock 域工作，16 个像素合并为一个 256-bit AXI 写拍，
当前采用单拍事务（AWLEN=0，AWSIZE=5，INCR，ID=0x40），一帧 19200 次写事务。
仲裁复用 `Haxi_2m1s_arbiter`：CPU/启动 bridge 占原 CPU 口，Camera 占历史命名的
`npu_axi_*` 口；**该口现在不是 NPU DMA**。实际顶层仍未接入 NPU 计算/DMA engine。
未来 CPU、Camera、NPU 三者共存及双目，需要扩展仲裁和缓冲描述符，不在本轮隐式实现。

## 地址、所有权与一致性

- Buffer 0：`0xB8000000`；Buffer 1：`0xB8100000`；各槽 1 MiB。
- 仍位于既有 NPU Input 区，没有重复新增 DDR 地址区；每帧只使用前 614400 字节。
- DDR IP 使用局部地址：上述地址减 `0x80000000`。
- `CURRENT_WRITE_BUFFER` / `LAST_COMPLETE_BUFFER` 返回槽编号 0/1，不是地址；
  无正在写入/无完成槽时为 `0xFFFFFFFF`，地址读 `LAST_FRAME_ADDR`。
- DMA 只写空闲槽；完整帧收到最后 B 响应并通过行数、像素数、DVP 错误检查后，
  原子发布计数、地址、槽号、checksum 和 ready 位。失败帧不更改上一成功描述。
- CPU 使用快照指向的 ready 槽，完成样本/校验后通过 release mailbox 归还。
  ready 槽不会被 Camera 覆盖；已归还槽不得继续作为 CPU/NPU 图像来源。
- 当前调试固件只检查最近完成帧，并释放该次快照的全部 ready 位；它是调试消费者，
  不承诺逐帧处理。未来 NPU 必须替换为自己的帧领取/完成释放协议。
- 两槽都被持有时丢弃新帧（错误码 9、dropped 递增），不覆盖旧帧。
  115200 串口和全帧 CPU 校验明显慢于视频流，实板调试出现这类丢帧可能正常；
  它与 FIFO overflow/DDR 写错误不同，不能因此宣称摄像头满帧率搬运已验收。
- 现有 DCache 对 NPU 共享区旁路，CPU 读这些帧地址直接经过 DDR bridge。
  本轮已回归旁路测试，未另行加入 cache flush 猜测实现。

## MMIO 与 CDC

基址 `0x40000300`，完整偏移、状态位和错误码见
[Camera_DMA_MMIO_接口约定.md](Camera_DMA_MMIO_接口约定.md)。
覆盖 STATUS、完成/当前帧 pixels/bytes/lines、frame count、FIFO 当前/历史峰值、
FIFO 错误、DMA busy/done/error/error code、当前写槽、最近完成槽、帧地址、
ready mask、丢帧、DDR ready、快照序号及原始 DVP 诊断。

CPU 写 `SNAPSHOT_CTRL.bit0` 后，PCLK 域先冻结诊断及 FIFO 水位峰值，DDR 域随后
同拍冻结 DMA 描述和 FIFO 读域状态，最后 CPU 经握手锁存整组。CPU 不直接读取
异步多位计数器；完成描述各字段属于同一帧，当前采集计数另列。
这是一份跨域握手采样记录，不声称三个时钟域在同一物理瞬间冻结。
FIFO level 以条目计数，包含 SOF/EOF/EOL；跨域指针同步带来正常延迟。

快照有 valid/busy/timeout。无 PCLK 或 DDR 时钟时可报告超时，迟到应答只排空
原事务，不覆盖 CPU 快照；时钟恢复后可重新请求。时钟始终不恢复则需复位，不能
将旧快照解释为新采样。缓冲释放和 DMA 清错误各有独立 mailbox 应答。
FIFO/DVP 粘滞诊断及 FIFO 历史峰值由子系统复位清除；DMA_CONTROL.bit1 只清 DMA
全局错误，不清 FIFO/DVP 历史。错误码保留首个未清除错误。

checksum 为 `sum(uint16_t pixels) mod 2^32`，**不是 CRC32**；满足当前允许的简单
checksum 方案，但不检测像素重新排列，也不能保证所有画面变化都得到不同校验值。
固件打印明确标为 `sum16 (not CRC32)`。

DMA 超时标记帧无效，不能撤销已发 AXI VALID，需继续排空或复位。
当前错误码 5 也涵盖帧内长时间无 FIFO 输入；计时参数是 DDR 时钟周期，实板需
结合实际帧间时序复核。DMA disable 同样安全排空已发写事务并等待新的 SOF 对齐。

## 固件与时钟修正

当前输出：`bsp/camera_app/camera_uart_debug_local.bin`，**6956 bytes**，
兼容文件名 `camera_uart_debug.bin` 与它一致。
SHA-256：`b8040bdc94718d4d35798f6e60d46e95a4ed01df6bd4b2f8394b6a6a4b4f8c0a`。
当前软件按本地应用指南将 `0x4740` 改为 `0x20`，仍待用户实板确认；上一轮
`0x23` 的极性解释已撤回。粘滞错误输出限频保持不变，见
[CAM1_HREF极性修正与错误输出限频.md](CAM1_HREF极性修正与错误输出限频.md)。
另有远程 AB26 版本；引脚、长度、哈希及复测步骤见
[UART_本地与远程配置及实板复测.md](UART_本地与远程配置及实板复测.md)。
`Hfpga_soc.BOOT_IMAGE_BYTES=6956` 已同步。Flash 固件地址仍为 `0x00A00000`。
旧 6944 字节固件及配套位流/SFC 不包含本次 UART 修正，不能继续用于当前验收。
无完成帧时首次成功快照及后续每 1000 次无帧轮询也打印完整状态，不会从无效地址
读取图像，避免 PCLK 正常但没有 VSYNC 时固件永久静默。

本地 `IP/clk_pll/clk_pll.idf` 的 CLKOUT0 请求频率为 70 MHz，`soc.fdc` 生成时钟
为 27 MHz ×70/27。此前 CPU CSR 报告 90 MHz，与 UART 参数一致但与真实 PLL 不符。
本轮将 CSR 频率元数据、`soc/config.v`、UART 实例参数及固件回退频率改为 70 MHz，
**没有改变 PLL/IP**。UART 为 115200、8-N-1、无流控。

## 离线验收

```sh
make -C bsp/camera_app all
make camera-dma-test camera-snapshot-test camera-pipeline-test
make camera-uart-fw-test
make fpioa-uart-profiles-test
make camera-board-lint lint addr-map
make sim cpu-load-store-test dcache-bypass npu-arbiter
make camera-sccb-gpio-test camera-dvp-rx-test camera-async-fifo-test camera-dvp-fifo-test
```

真实 CPU 联合模型执行上述 bin，经真实 bridge/仲裁器访问共享 DDR 模型，核对
SCCB 配置、DVP 输入、DMA 写入、MMIO 快照、CPU DDR 读回和 UART 输出。
全红测试帧观察结果：

```text
CPU CLOCK   : 70000000 Hz
CAM1 FRAME        : 1 (DVP 1)
CAM1 LINES        : 480 (current 480)
CAM1 PIXELS       : 307200 (current 307200)
CAM1 BYTES        : 614400 (current 614400)
CAM1 FIFO LEVEL   : 0
CAM1 FIFO MAX     : 2
CAM1 OVERFLOW     : 0 FIFO_ERROR=0x00000000 DVP_FLAGS=0x00000000
CAM1 DMA BUSY     : 0 STATUS=0x00000105
CAM1 DMA DONE     : 1
CAM1 DMA ERROR    : 0 CODE=0x00000000
CAM1 WRITE BUFFER : 0xFFFFFFFF
CAM1 READY BUFFER : 0x00000001 LAST=0x00000000
CAM1 FRAME ADDR   : 0xB8000000
CAM1 CHECKSUM     : sum16 (not CRC32) 0x8A800000
CAM1 DDR CHECKSUM : sum16 (not CRC32) 0x8A800000 MATCH=YES
CAM1 RELEASE MASK : 0x00000001 RELEASED
UART_FIRMWARE_PASS: Camera DMA/DDR samples/checksum/release
```

其余实际验收结果：

- DMA 定向：`PASS frames=8 dropped=12 writes=13`，覆盖 partial beat、跨行连续
  打包、双槽、overflow、过量像素、DVP 错误、B 错误、AW/FIFO 超时及恢复、disable
  排空，并分别清错误核对 unexpected SOF/EOF、bad pixel/line 错误码。
- 跨域：`CAMERA_SNAPSHOT_OVERFLOW_RECOVERY_PASS`；无 PCLK 超时、迟到应答、重试、
  状态位映射及溢出后重新对齐通过。满深度 16 的历史 FIFO 峰值从 MMIO 读出为 16，
  防止多位水位被意外截断。
- 全 VGA：`CAMERA_PIPELINE_PASS VGA=640x480 frames=3 writes=57600`；逐像素 DDR
  内容核对、第二帧中主动 snapshot、冻结字段、双槽保护及释放复用通过。
  图案校验值 `0x497DA800`、`0x55DEB800`、`0x596E1800`。
- CPU ISA：46/46；load→store 定向：1/1；DCache NPU 区旁路、AXI 仲裁、SCCB GPIO、
  DVP RX、Async FIFO、旧 DVP/FIFO 跨域回归全部通过。
- `camera-board-lint`、`lint`、`addr-map` 通过；相关源码 `git diff --check` 通过。
- 日志保存在 `build/camera_regression.log`、`build/camera_dma_mmio_acceptance.log`、
  `build/camera_error_watermark_tests.log`、`build/camera_final_cdc_lint.log` 和
  `build/camera_final_cpu_pipeline.log`；历史 6944 bytes 版本的 CPU/UART 与顶层检查
  见 `build/camera_final_firmware.log`。当前 UART 配置回归见上述 UART 专项记录。
  build 为可再生成的本地仿真产物。

联合审查实际修复了：上一完成帧 checksum 被下一 SOF 清除、FIFO level 位宽截断、
CPU 应答同步器放错时钟域、溢出后下一 SOF 被丢弃、DMA done 可见性、槽号/地址混淆
以及禁用时不安全退出。额外发现的帧中 snapshot 后缺像素则是测试平台行首未重新
对齐 PCLK；修正传感器模型后通过，不以 `force` 或取消快照断言隐藏问题。

这不代表实板吞吐、DDR PHY、图像极性/质量、物理 CDC 时序和完整视频帧率已经确认。
UART 回归已扩展到真实 FPIOA 模块与 TX 引脚串行解码，并保留 TXDATA 内容核对。
仿真检查 70 MHz 时钟配置下的 115200、8-N-1；真实板上时钟、物理引脚电平及
PC 收串口日志仍待用户实板验收，不能用仿真代替。
顶层 lint 使用本地 IP 端口声明替身，仅检查连线；旧 CPU/JTAG/外设的若干既有告警
被限定在该目标豁免，新 Camera 子系统 lint/模块测试不使用 warning-fatal 总开关豁免。

## 用户统一实板 Review 清单

1. 保存当前源码、bin、长度与 hash。按
   [PG2L200H_双目OV5640接口核对.md](PG2L200H_双目OV5640接口核对.md)
   核对物理 CAM1 插接、供电、接口方向和已确认引脚，暂不启用 CAM2。
2. 手动在 PDS 确认 PG2L200H-FBB676、IP 器件及新源文件，再综合/布局布线。
   检查 Async FIFO RAM 推断、CDC synchronizer、未约束路径和时序收敛。
   现有 FDC 已声明 CPU/PCLK 异步；本轮新增 FIFO 读端为 DDR core clock，必须在
   实际 IP 生成时钟报告中补核 PCLK/DDR、CPU/DDR 跨域约束和 Gray 总线延迟/偏斜，
   不能把功能仿真当作 CDC 时序签核。本轮未猜测 DDR IP 内部时钟名写约束。
3. 确认 `BOOT_IMAGE_BYTES=6956`，新位流放 Flash `0x000000`，local bin 放
   `0x00A00000`。不能继续使用旧 Camera bitstream 或只替换不同长度的 bin。
4. 优先资料包 `5_Software/串口调试助手/sscom5.13.1.exe`，MobaXterm 备选。
   串口配置 115200 / 8-N-1 / 无流控；保存完整日志后 Verify、断电重启。
5. 同次启动观察 DDR INIT、OV5640 ID 0x5640、配置回读成功、有效 PCLK/VSYNC/HREF、
   完成帧 480/307200/614400、帧地址/槽号、FIFO 水位/峰值及错误码。
   首帧尚未完成时可能先看到 FRAME=0、尺寸=0、地址/槽号=0xFFFFFFFF；这是探活
   快照，不是有效帧描述。验收要看随后 ready 置位后的完整帧。
6. 改变拍摄内容，观察样本和 sum16 是否变化，确认每次 `DDR CHECKSUM MATCH=YES`。
   Camera FIFO overflow、DDR write error、DDR timeout 不应被“有串口打印”掩盖。
   错误码 9 如持续出现，先按调试消费者太慢核查，不与 FIFO overflow 混淆。
7. 确认写槽与 ready 槽不冲突、释放后可恢复后续采集，再决定双目/NPU 下一阶段。
   未来 NPU 需要 RGB565→其输入布局/量化的预处理；当前帧缓冲内容仍是 RGB565，
   **不是已经适配某个 NPU 张量格式的输入**。

本轮未使用 Web；参考沿用本地 manual 的 OV5640 数据手册/应用指南、板级接口核对，
以及当前工程的 PLL、DDR IP、地址图、旁路和仲裁 RTL。Wireshark 无本阶段用途。

## 640×480 采集与 720P 显示

摄像头采集尺寸与 HDMI 输出时序独立。OV5640 当前配置为 VGA，旧 demo 为
1280×720；当前没有 HDMI 显示链路。若显示器仅接收 720P，后续 HDMI 必须输出
1280×720 的有效区域及对应完整时序，不能直接发送 VGA 时序。
第一版可把 640×480 图像居中放入 720P 画面并补黑边（左右各 320、上下各 120），
无需图像缩放；要等比例放大可输出 960×720，左右各 160 黑边，避免 4:3 被拉成
16:9。本轮保持 VGA Camera→DDR，不因显示需求提前修改 DMA 尺寸/缓冲协议。
