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

## CAM1 one-shot RGB565 串口导出

`make frame-dump-local` 或 `make frame-dump-remote` 构建独立的一帧导出固件，输出
`camera_frame_uart_dump_local.bin` / `camera_frame_uart_dump_remote.bin`（各 16 KiB）。
local 使用 FPIOA[0]/C24，remote 使用 FPIOA[31]/AB26。普通 `all`、`local`、`remote`
和 `diagnostics` 目标保持原用途，不会自动替换为导出固件。

导出固件验证一个 CAM1 完成帧，停止采集并等待 DMA 禁用/空闲后，经 UART 发送协议头、
完整 640×480 RGB565 payload 和 CRC32 footer；完整帧传输确认后才释放对应 DMA 槽。
115200 baud 下约需 54 秒，采集在此期间暂停。它只会输出一帧并在固件重新启动后才再
采集。构建后需操作者按既有流程烧录匹配镜像；构建 target 不会烧录或改变工程 Flash
配置。

电脑端接收和方向对照步骤见
[`manual/真实RGB565帧导出与方向查看.md`](../../manual/真实RGB565帧导出与方向查看.md)，
接收脚本为 `tools/capture_rgb565_uart.py`，它会检查 44 字节 `R565DMP1` header、固定
payload 长度、`END565D1` footer 和 IEEE CRC32，验证完整后再输出 `.rgb565`、metadata
JSON 和四种方向 PNG。超时/中断的 payload 保留为 `.incomplete`，不作为完整采集帧。

## 全流程上板测试固件（NPU）

`make -C bsp/camera_stereo_app npu` 构建 `main_npu.c`：两颗 OV5640 → 前处理找框 →
INT8 → NPU → UART 逐条输出识别结果。找框、INT8、NPU 都由硬件自动运行（参数在
`soc/Hfpga_soc.v` 中写死，上电自动使能）；CPU 只探测并配置两颗摄像头、打开两路采集
和 DMA，再从 NPU 结果队列（`SOC_NPU_MMIO_BASE` 偏移 `0x20/0x24/0x44`，见
`soc/Hnpu_result_mmio.v`）逐条取出、解码、打印，并每秒输出一次统计。相机缓存由前处理
硬件读取和归还，CPU 只读统计快照，不归还缓存。

构建产物（也可用 `npu-local`、`npu-remote` 单独构建）：

- `camera_stereo_npu_local.bin`、`camera_stereo_npu_remote.bin`：16384 字节 CPU 镜像，
  UART 分别走 FPIOA[0]/C24、FPIOA[31]/AB26。
- `camera_stereo_npu_local_flash.bin`、`camera_stereo_npu_remote_flash.bin`：95488 字节
  整片 Flash 镜像，即 CPU 镜像补零到 `SOC_BOOT_IMAGE_BYTES`（当前 main 为 32768）后接
  `model.npu`（62720 字节），由 `scripts/make_npu_flash_image.sh` 生成并检查模型文件。

可选变量：`NPU_MODEL` 指定模型（默认 `temp/路标模型文件v0.3_10月10日/model.npu`）；
`NPU_PRINT_BACKGROUND=0` 时背景框只计数、不逐条打印（默认 1）；
`NPU_CAM2_ORIENTATION_AS_CAM1=0` 时 CAM2 保持驱动默认方向（默认 1，见下文）。`.o`
不跟踪命令行变量，改变量后先 `rm -rf build/npu camera_stereo_npu_*.bin` 再构建；不要用
`make clean`，它会删掉本目录所有 `.bin`，包括其它固件已入库的镜像。

烧录时把 `_flash.bin` 整份从 Flash `0x00A00000` 写入（原始字节，不做端序交换）。上电后
flash_ddr_boot 把前 32768 字节搬到 DDR `0x80000000` 执行，把 `0x00A08000` 起的 62720
字节模型搬到 `SOC_NPU_WEIGHT_BASE`（`0xB9000000`）。只烧 16 KiB 的 `.bin` 时，NPU 用的是
Flash 里原有的内容。loader 不校验模型，固件启动时打印 `MODEL` 行供核对：v0.3 应为
`magic=0x3155504E`、`crc=0x207156DE`，读不到模型时显示 `MODEL=BAD_MAGIC`。位流须用同一份
`soc/soc_addr_map.vh`（DDR 版，`SOC_CPU_MEM_BRAM=0`）综合。

UART 为 115200、8-N-1。上电约 0.5 秒（两颗摄像头配置完）后输出启动信息：

```text
=== Road Sign NPU Pipeline ===
NPU_PIPELINE BOOT
CPU CLOCK=70000000 UART=115200 TX_FPIOA=0 PRINT_BACKGROUND=1
MODEL base=0xB9000000 magic=0x3155504E classes=11 bytes=62720 crc=0x207156DE reject_margin=1251
CAM1 SCCB=OK PID=0x00005640
CAM1_ORIENTATION=180 3820=0x00000047 3821=0x00000001 COLORBAR_503D=0x00000000
CAM1 CONFIG=OK VGA_RGB565 writes=255
CAM2 SCCB=OK PID=0x00005640
CAM2_ORIENTATION=180 3820=0x00000047 3821=0x00000001 COLORBAR_503D=0x00000000
CAM2 CONFIG=OK VGA_RGB565 writes=255
INT8 ctrl=0x00000001 status=0x00000020
NPU_PIPELINE CAPTURE_STARTED
```

之后每个框输出一行：

```text
NPU cam=1 frame=3 roi=1 result=pl40 class=5 reject=0 conf=2964 score=2076 err=0 color=red box=397,176,538,342
```

- `cam` 为 1 或 2；`frame` 为该路 DMA 帧号；`roi` 为本帧第几个框（从 0 起，每帧最多 8 个）。
- `class` 为 NPU 最高分类别，编号同 `classes.csv`：0 background、1 unknown、2 pne、3 pn、
  4 p11、5 pl40、6 pl60、7 pl80、8 pl120、9 i5、10 w57。
- `conf` 为最高分减第二名（16 位饱和）；`conf` 低于模型门槛 `reject_margin`（v0.3 为
  1251）时 `reject=1`；`score` 为最高分原值（有符号）。
- `result` 为最终判定：`err` 非 0 为 `error`，`reject=1` 或 `class=1` 为 `unknown`，
  `class=0` 为 `background`，其余为类别名。
- `err` 为 NPU 错误码，0 正常；`color` 为前处理判定的颜色（red/yellow/blue/black）；
  `box` 为 x0,y0,x1,y1，640×480 画面坐标，含端点。

每秒输出四行：

- `STAT`：`npu_sec` 本秒结果数，`npu_total` 累计；`sign/unknown/background/error` 按
  `result` 累计；`classes=` 按 `class` 字段累计 11 类（不看 `reject`，和前几项对不上属正常）；
  `unprinted` 为串口队列不够、只计数没打印的结果条数（硬件结果队列照常弹出）；`queue` 为结果
  队列当前深度；`npu_err` 为 NPU 错误码寄存器。
- `INT8`：每路 `images` 已转小图数，`usage/peak` 缓存占用及峰值，`failed` 失败批次、
  `ddr_err`、`bad_release`，正常时后三项为 0。
- `CAM1`、`CAM2`：`dvp_frames/sec_dvp` 摄像头出帧，`dma_frames/sec_dma` 写入 DDR 的帧，
  `drop` 两块缓存都被占用时丢掉的帧，以及 FIFO、状态、错误标志和 ready mask；`state` 为
  `RUNNING`、`FAILED_NO_PCLK` 或 `FAILED_NO_FRAME`。

字符队列满时另输出 `LOG_DROPPED=累计丢失字符数`。

NPU 每个框约 32 ms，两路合计每秒约 31～32 个框。框多时前处理占着缓存，DMA 会丢掉新帧：
`drop` 增长，同时出现 `errors=0x00000400`、`dma_code=9`（`DMA_STICKY_NO_FREE_BUFFER`），
这是正常丢帧，不是故障；被处理的帧结果完整，不会出现半帧。

已知现象：持续忙时，同一路结果的帧号偶尔倒序（仿真里出现过第 9 帧排在第 14 帧之后），每条
结果仍对应自己那一帧。原因是 `soc/Hcamera_preprocess.v` 在两块原图都 READY 时固定先取 0 号
缓存（`selected_source = !source_ready_mask[0]`），1 号缓存里的旧帧会被饿住。若要按帧序
输出，可改为两块都 READY 时取帧号较旧的一块：

```verilog
wire [31:0] source_frame_delta = source_frame1 - source_frame0;
wire selected_source = source_ready_mask == 2'b11 ? source_frame_delta[31] : !source_ready_mask[0];
```

该改动未合入。同样的连续出帧整片仿真中，改后 23 帧 64 条结果仍全部正确、两路帧序按序，
仓库 `tb_preprocess_stereo` 测试也通过。

CAM2 方向：曝光等寄存器两颗共用 `../camera_app/ov5640_regs.c` 同一张表，原先只有方向
（`0x3820/0x3821`）是 CAM1 独有（彩条开关 `CAM1_SENSOR_COLORBAR` 也只作用于 CAM1，默认关）。
全流程固件默认 `NPU_CAM2_ORIENTATION_AS_CAM1=1`，CAM2 也写 180° 方向（启动行
`CAM2_ORIENTATION=180`）；若 CAM2 实物装法和 CAM1 不同、画面反了，用 `=0` 重新构建，
启动行显示 `CAM2_ORIENTATION=DEFAULT`。

验证：整片 Verilator 仿真（`Hfpga_soc` 全芯片 + DDR3 行为模型 + SPI Flash 模型 + 两路
OV5640 DVP 激励），从 local `_flash.bin` 上电启动，把 v0.3 金样图送进两路摄像头，串口每条
结果与金样（`frontend_v03` 找框 + 参考模型分类）逐项比对：单帧 2 帧 5 条、每路 4 帧间隔发送
8 帧 22 条、按真实帧率连续发送（含 DMA 丢帧）23 帧 64 条，全部一致，`failed`、`ddr_err`、
`npu_err`、`unprinted` 均为 0。仿真不含实物曝光和布线，最终以上板为准。

目录里的四个 `camera_stereo_npu_*` 镜像即上述仿真所用版本（仿真跑的是 local，remote 只差
UART 引脚）。`bsp_app` 不在仓库内，构建时的 startup/init 按现有 `camera_stereo_local.bin`
反汇编复原；用本机 `bsp_app` 重新 `make npu` 得到的镜像功能相同，字节不一定一致。
