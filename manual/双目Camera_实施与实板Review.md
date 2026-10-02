# 双目 Camera 实施与实板 Review（2026-10-02）

最新实板反馈：CAM1稳定约15 FPS，CAM2成功11帧后停滞，双目持续运行尚未通过。
本页离线PASS记录不代表实板通过；新增软件诊断与对照步骤见
[CAM2停滞记录](CAM2停滞_诊断与对照测试.md)，本次诊断不再修改引脚或RTL。

## 本轮范围

用户确认：颜色候选、专用硬件前处理、动态 ROI、缩放/量化与 NPU 的方案先记录在
`整体目标.md`，本轮只实现两颗 OV5640 独立并发采集。不使用旧 100H demo 位流，
不实现图像拼接、曝光同步、深度计算、模型推理或自动覆盖未释放的原图。
按用户要求由 Luna High 子代理分别实现 RTL、固件和验证，主代理集成并复核。

```text
CAM1 SCCB/init → CAM1 DVP/PCLK → Async FIFO → DMA(ID=0x40) → CAM1双槽
                                                  ↘
                                        两路写仲裁 → CPU/Camera仲裁 → DDR
                                                  ↗
CAM2 SCCB/init → CAM2 DVP/PCLK → Async FIFO → DMA(ID=0x41) → CAM2双槽

各路状态 → 各路一致性MMIO快照 → CPU → 非阻塞UART TX → PC
```

两颗摄像头各有本地 24 MHz 振荡器与独立 SCCB/RESET；软件分别探测 ID、初始化
和回读关键寄存器，然后开启两路采集。并发不等于曝光同步，帧号也不能直接视为
严格配对的立体帧。

## 地址和缓冲所有权

| 通道 | MMIO | 槽0 | 槽1 | AXI ID |
| --- | --- | --- | --- | --- |
| CAM1 | `0x40000300` | `0xB8000000` | `0xB8100000` | `0x40` |
| CAM2 | `0x40000400` | `0xB8200000` | `0xB8300000` | `0x41` |

每槽预留 1 MiB、有效帧 614400 字节。四槽合计占用 NPU Input 预留区的 4 MiB；
`0xB8400000–0xB9000000` 剩余 12 MiB 暂不分配。这里的原图不是 NPU 最终小图输入。
CAM2 复用同一套寄存器偏移，snapshot、release 和错误状态均独立。

DMA 持有正在写入的槽；完整像素/行/字节数且最后一个 DDR 写响应成功后才发布
ready。CPU 不读正在写入的槽，也不能归还其他通道的槽。无空闲槽时主动丢新帧，
记录 dropped 和粘滞错误码 9，不覆盖未释放的 ready 数据。两级仲裁都使用现有
`Haxi_2m1s_arbiter`，写事务从 AW 经 W 到 B 响应保持同一拥有者。

新固件是快速测试消费者：检查最新完成描述符的尺寸、ready 位、槽号和地址，
读取 4 个分散像素样本，确认 release 完成后才计入成功消费。漏过旧完成帧时，
允许归还该快照中的其他旧 ready 槽，并计入 `discarded_old_ready`；未读取旧帧，
不把它算作已验证图像。这不是后续 AI 的缓冲保留策略。

## 引脚变更记录（没有迁移已有 LOC）

依据：本地 `PG2L200H_双目OV5640接口核对.md`，其原理图/FMC 引脚核对沿用已确认
的 MES-FMC-LPC-IO 版本。以下均为新增 CAM2 接入，CAM1、DDR、JTAG 和 UART 球位不改。

| CAM2 信号 | 顶层端口/输入来源 | 球位 | 方向 |
| --- | --- | --- | --- |
| SCL | `cam2_scl` | W19 | 开漏 INOUT |
| SDA | `cam2_sda` | V16 | 开漏 INOUT |
| RESETB | `cam2_reset_n` | Y20 | OUTPUT |
| PCLK | `cam2_pclk` | U21 | INPUT |
| VSYNC | `cam2_vsync` | V23 | INPUT |
| HREF | `cam2_href` | W23 | INPUT |
| D7 | `cam2_data_hi[2]` | T18 | INPUT |
| D6 | `cam2_data_hi[1]` | T17 | INPUT |
| D5 | `cam2_data_hi[0]` | AA23 | INPUT |
| D4 | `fpioa[18]` | AB25 | INPUT 专用 |
| D3 | `cam2_data3` | V19 | INPUT |
| D2 | `fpioa[29]` | U25 | INPUT 专用 |
| D1 | `fpioa[28]` | U26 | INPUT 专用 |
| D0 | `cam2_data0` | V21 | INPUT |

原 `fpioa[18]/[28]/[29]` 的 LOC 不变，FDC 方向由 INOUT 改为 INPUT；顶层对
`Hfpioa_simple` 设置 `INPUT_ONLY_MASK=0x30040000`，这三位即使被 MMIO 映射到
UART/NIO 推挽输出也强制高阻，因此不再可用作普通输出。未重复声明同球位端口。
静态检查 143 个 LOC 无重复球位；UART 本地 `fpioa[0]/C24`、远程
`fpioa[31]/AB26` 均保持不变。增加 CAM2_PCLK 的 100 MHz 保守时钟约束并声明
CPU/CAM1_PCLK/CAM2_PCLK 异步；这是约束上限，不代表固件设置了 100 MHz PCLK。

厂商 PDS 对顶层 inout 的常量高阻优化及 FDC INPUT 属性、资源、布线和时序仍须
实际生成新位流验证，离线仿真不能替代这一项。

## 固件文件和启动长度（重要）

- 本地串口用 `bsp/camera_stereo_app/camera_stereo_local.bin`。
- 远程串口用 `bsp/camera_stereo_app/camera_stereo_remote.bin`。
- `camera_stereo.bin` 是 local 副本，不是第三种硬件配置。
- 三份最终镜像均为 **16384 字节**；raw 为 7560 字节，剩余零填充，超长构建报错不截断。
- 新顶层默认 `BOOT_IMAGE_BYTES=16384`，软件 Flash 偏移仍为 `0x00A00000`。
- Flash 写入原始 bin，**不做大小端翻转**；Makefile 的 reverse-bytes 只生成仿真 readmemh 输入。
- 必须重新生成匹配的双目位流，以及需要时重新生成包含软件的 SFC。
  只换 bin 不能给旧位流增加 CAM2，也不能让旧 6956 字节 loader 正确加载此镜像。
- 原 `bsp/camera_app` 单目/GPIO 镜像未改，继续留作旧版本回退和诊断。

SHA-256：

```text
local / camera_stereo.bin:
9862750e294dbf7b3e19f9948d37dd36712f6694b04a3fb0a8ad3f46674d0e64
remote:
5ea678c7c42f1b45914126aef8f874ce13f2075da9ee04c8a8d3b5750f66d91e
```

构建：`make camera-stereo-firmware`。初始化 `0x4740=0x20`，回读 mask `0x23`；
其他参数保持已经通过 CAM1 实板验收的 VGA RGB565 配置，不重新猜极性。

## UART 与测试证据

UART 115200、8-N-1、无流控；初始化日志可阻塞，但开始采集后日志通过 2048 字节
RAM 队列排出，每轮最多发一个字符。正常首报等待两路各有完整帧，之后以本工程
CSR mtime 每秒输出两路摘要；FIFO/DMA/DDR 状态来自各路 snapshot，不直接读取
异步多位计数器。日志队列满只丢日志并计数，不阻塞采集。

字段包含成功消费/DVP/丢帧计数、480 行/307200 像素/614400 字节、FIFO 当前/峰值、
错误码、当前写槽/ready mask/最近完成槽与地址、硬件 sum16、少量样本、快照/释放
超时计数。`hw_sum16` 不是 CRC32，也不打印未经完整 DDR 重算的 `MATCH=YES`。

已通过的离线测试（日志保留在 `build/`，此处记录关键结果）：

| 测试 | 结果 | 日志 |
| --- | --- | --- |
| 地址映射、各模块/顶层 lint | PASS | `camera_stereo_lint.log`、`camera_stereo_board_lint.log` |
| 单目 DVP/DMA/整链路、快照溢出恢复、AXI 仲裁 | PASS | `camera_stereo_regression.log` |
| 旧单目 CPU/DDR/UART | PASS，1775 字节真实 TX 解码，整帧 sum16 MATCH | `camera_stereo_mono_fw_regression.log` |
| 双目异步 VGA/DDR | PASS，CAM1/CAM2 AW/W/B各76800/57600 | `camera_stereo_pipeline.log` |
| FPIOA 高阻、UART 不变、CAM2 全256字节组装 | PASS（Icarus） | `camera_stereo_pipeline.log` |
| 双目 local 原始bin执行 | PASS，帧/释放7/6，1339字节TX解码，错误/丢帧0/0 | `camera_stereo_local_fw_final.log` |
| 双目 remote 原始bin执行 | PASS，帧/释放7/6，1340字节TX解码，错误/丢帧0/0 | `camera_stereo_remote_fw_final.log` |
| 未缩短计时的一秒持续输入/周期摘要 | PASS，结束帧/释放48/39，错误/丢帧0/0，2291字节TX解码 | `camera_stereo_throughput_fw.log` |

双目流水线用不同、随帧变化的像素图案，逐字检查四个槽的有效帧内容：两个槽
占满时第三帧不产生DDR写入、不覆盖旧图；release 后写回；CPU不请求新snapshot
时视图保持冻结；CAM2停钟快照超时、CAM1继续完成新帧，CAM2恢复后可再快照。

固件端到端回归预装原始bin到DDR程序区，执行实际CPU、SCCB、MMIO、DMA和UART
RTL，DDR行为模型替代外部控制器，不替代CPU/固件。两路RGB565图案分别为
`0xF800`/`0x07E0`，完整帧sum16为`0x8A800000`/`0x24EA0000`。固件消费者只是
取4样本，**完整图像比较在testbench中执行**，没有伪造固件MATCH。该回归不覆盖
Flash实际电气、厂商DDR PHY与布线。多驱动/Z的PAD检查由Icarus单独覆盖，CPU
Verilator平台直连DVP数据输入；不把Verilator的二态inout解析当作电气证明。

真实一秒周期摘要已执行：CSR计满70000000个CPU周期，摘要成功消费44/36帧，
分别27033600/22118400字节，FIFO峰值3/3，丢帧、DMA/DVP/FIFO错误、快照/释放
超时均为零；第二次摘要物理TX发送完成时已累计48/39帧并全部归还。
这里的44/36是不同PCLK激励下的压力测试节奏，**不是实物OV5640帧率配置或测量**。
当前固件不执行AI/全图前处理，测试不能预测未来模型消费者的保留时间。
运行入口：

```sh
make addr-map camera-board-lint
make fpioa-uart-profiles-test fpioa-camera-reserved-test
make camera-stereo-test
make camera-stereo-fw-test
make camera-stereo-throughput-fw-test
make camera-dma-test camera-pipeline-test camera-snapshot-test npu-arbiter
```

## 留给用户的一次性实板验收

1. Review 本记录和 `soc.fdc`，确认两颗摄像头插在正确 FMC、模块电平/供电匹配。
2. 用户在 PDS 重新生成双目 bit；查看重复管脚、输入方向、PCLK 路由与时序报告。
   工程已有各复用 RTL 文件，无需沿用旧 demo 或增加未实现 NPU 模块。
3. 用新双目位流及对应 local/remote 16 KiB bin 生成/下载；Flash 软件偏移如上。
4. 两路均应 `PID=0x00005640`、`CONFIG=OK VGA_RGB565 writes=252`，然后 CAPTURE_STARTED。
5. 观察至少 60 秒：两路 total_ok/dvp_frames 持续增长、每秒吞吐接近输入帧率，
   pixels/bytes/lines 正确，FIFO/DVP 错误为零、FIFO 峰值稳定，drop/超时不持续增长。
   粘滞 dma_code 需结合 drop 增量看，不能仅因上一时刻的 code 判定当前帧损坏。
6. 分别遮挡/移动两路画面，各自样本/hw_sum16 应变化且地址属于自己；这是调试
   线索，不是双目曝光同步、颜色准确或完整逐像素校验的验收。
7. 一路异常应不影响另一路继续计帧；断插摄像头前先断电，不做带电拔插。

本轮没有主动打开 PDS、串口软件或执行烧录，不声称双目已实板通过。
