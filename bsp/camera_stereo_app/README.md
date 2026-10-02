# 双目 Camera 固件

此目录新增独立双目采集固件，不替换 `bsp/camera_app` 的 CAM1 单目与 GPIO
诊断镜像。CAM1 使用 MMIO `0x40000300`、DDR 缓冲区 `0xB8000000`/`0xB8100000`；
CAM2 使用 MMIO `0x40000400`、缓冲区 `0xB8200000`/`0xB8300000`。每槽预留 1 MiB，
VGA RGB565 帧大小为 614400 字节。固件对两颗 OV5640 分别执行真实 SCCB 探测、
寄存器初始化及关键寄存器回读；初始化表复用 `../camera_app/ov5640_regs.c`，
`0x4740` 的期望/mask 为 `0x20/0x23`，`0x4300` 为 `0x61/0xff`。

## 构建

```sh
make -C bsp/camera_stereo_app all
```

会生成 `camera_stereo_local.bin`、`camera_stereo_remote.bin` 和兼容名
`camera_stereo.bin`（local 副本）。local UART 使用 FPIOA[0]/C24，remote 使用
FPIOA[31]/AB26，均为 115200、8-N-1、无流控。构建保留工程 RV32IM/ILP32、picolibc
及现有 startup/init，完整原始镜像必须非空、4 字节对齐且不超过 16384 字节；
短镜像仅在 binary 输入后补零，超长构建失败，不会裁剪。三个最终 `.bin` 固定
16384 字节。

新双目位流的 `BOOT_IMAGE_BYTES` 必须为 **16384**。Flash 软件镜像地址为
`0x00A00000`，写入原始 `.bin` 字节，不做端序交换。不要将此 16 KiB 镜像交给旧
SFC 处理，也不要使用旧 6956 字节单目 loader/位流。单目文件仍保留在原目录，
不受本目标影响。

## UART 输出和采集行为

引导顺序标记为 `CAMERA_STEREO BOOT`，两路分别输出 SCCB/PID 和
`CONFIG=OK VGA_RGB565 writes=...` 或失败原因；启动采集后输出
`CAMERA_STEREO CAPTURE_STARTED`。已启动的各路首个有效帧描述符都释放后立即排入
`CAMERA_STEREO INITIAL_STATUS`，此输出与每秒周期摘要一样走 RAM 队列，不等待 UART
发完。每路摘要格式为单行 `CAMn sec_ok=... total_ok=... dvp_frames=... sec_dvp=...`
并包含 `drop`、`sec_bytes`、`lines/pixels/bytes`、FIFO 当前/峰值、状态/错误标志、DMA 状态和
错误码、ready mask、当前写槽/最近完成槽、最近帧地址、`hw_sum16`、`skipped_ready`、
`discarded_old_ready` 和归还超时计数及少量样本统计。
摘要由 CSR `0xB03` 的 70 MHz mtime 以真实 1 秒间隔触发；启动时确认并开启 CSR
`0xB88` bit 2。无 PCLK/无首帧时仍会每秒报告 `FAILED_NO_PCLK` 或 `FAILED_NO_FRAME`，
另一台相机继续独立轮询。正常首报等待两路各完成一帧，避免把第二路尚未到来的
首帧误显示为失败；一路配置失败或停钟时，周期摘要仍持续输出。

`hw_sum16` 是 DMA 硬件对 16 位像素的和，不是 CRC32，也不是 CPU 完整帧匹配校验。
固件只从通过宽高、字节数、完成槽、ready 位和物理地址检查的最新描述符中取 4 个
分散 RGB565 样本。确认最新描述符后，会释放该快照中所有 ready 槽：若固件轮询
漏过一个完成描述符，较旧 ready 槽也会被快速丢弃并计入 `discarded_old_ready`，
防止该槽长期占用。这是快速调试消费者的丢帧策略，不适用于需要保留每帧的 AI
消费者；旧槽内容不会被读取或验证。`skipped_ready` 统计相邻两次成功消费之间，
没有作为旧 ready 槽显式归还的 DMA 完成帧缺口。两项都是丢帧统计，不代表对丢弃帧
DDR 内容的验证。只有归还成功后才更新成功帧统计和已消费帧号；归还超时会保留描述符，
在后续轮询重试。DMA
错误码 9 会按 `DMA_STICKY_NO_FREE_BUFFER` 原样报告。FIFO、DVP、DDR 状态和错误码
不做屏蔽。UART TX 使用 2048 字节环形队列，运行期主循环每轮至多送出一个字符；
队列满时增加 `LOG_DROPPED` 计数，避免日志拖延缓冲区释放。

已完成交叉编译、镜像长度/hash 和两套真实 CPU/UART 离线回归；两路均至少完成
并释放6帧，两种完整VGA图案/硬件sum16正确，零错误/丢帧。不会启动 PDS、不访问
串口或实板。`make camera-stereo-fw-test` 复跑本地/远程版本；
`make camera-stereo-throughput-fw-test` 额外执行真实一秒周期摘要和连续输入测试，
已PASS：一秒摘要44/36帧，结束48/39帧且全部释放，错误/丢帧为零。这是仿真激励
速度，不是实物摄像头帧率或带AI后的性能承诺。
实际双目时序、布线与长时间吞吐仍须用户最终上板验收，详见
`manual/双目Camera_实施与实板Review.md`。

## CAM2 诊断固件

使用独立目标 `make -C bsp/camera_stereo_app diagnostics` 构建四个新的 16 KiB
镜像：`camera_stereo_diag_local.bin`、`camera_stereo_diag_remote.bin`、
`camera_cam2_only_local.bin` 和 `camera_cam2_only_remote.bin`。local UART 使用
FPIOA[0]/C24，remote 使用 FPIOA[31]/AB26。此目标使用既有 startup、RV32IM/ILP32、
picolibc 和链接脚本；每个完整 raw binary 必须非空、4 字节对齐且不超过 16384
字节，较短镜像只补零，不截断。

`camera_stereo_diag` 同时采集两路。`camera_cam2_only` 仍分别探测和配置两颗
OV5640，但关闭 CAM1 capture/DMA，将 CAM1 报告为 `DISABLED`，不轮询 CAM1；只有
CAM2 采集并释放缓冲区。两种模式都保留快速消费者的 4 点抽样、描述符校验、最新
ready 描述符优先及释放失败重试。

诊断行仍以 `CAMn sec_ok=` 开头，加入 PCLK 计数/增量、快照序号与增量、快照有效和
新鲜标志/年龄、DMA 当前像素/字节/行数、capture/DMA 控制读回、已完成帧数/增量及
DVP 帧增量。capture/DMA 读回是单独的实时 CSR 读取，不属于冻结快照组。新鲜度要求
成功快照的序号前进；PCLK 增量按 32 位回绕相减。状态区分 `DISABLED`、
`FAILED_CONFIG`、`WAIT_FRAME`、`STALE_SNAPSHOT`、`STALLED` 和 `RUNNING`；两秒门限
使用 CSR `0xB03` 的 70 MHz 计时，帧成功时间只在 release ack 后更新。日志每秒先排入
CAM1，再延后排入 CAM2，为现有 2048 字节 UART 环形队列留出发送时间。

新增诊断四变体已交叉编译；本地/远程两种模式的真实CPU、DDR、MMIO与仿真FPIOA UART
验证通过。保持CAM2 PCLK而停送帧内数据的故障测试中，超过2秒正确显示STALLED，
CAM1继续完成/释放97帧，无自动复位。镜像SHA、测试证据与实板对照步骤见
`manual/CAM2停滞_诊断与对照测试.md`。这不是已确定根因的CAM2修复，仍需实板对照日志。
