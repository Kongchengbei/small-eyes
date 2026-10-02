# CAM2 停滞：诊断固件与实板对照（2026-10-02）

## 已确认的现象与本轮边界

用户双目实板日志中，CAM1 持续约15 FPS，完整帧为480行、307200像素、
614400字节，零丢帧和错误。CAM2 两颗ID/初始化检查正常，先成功11帧，随后
`dvp_frames=12`、`drop=2` 固定，`dma_code=5`、`dvp_err=4`，FIFO未溢出。
此前离线双目测试通过不等于此次双目实板验收通过。

错误码5在当前 DMA 中也可由帧内等待 FIFO 数据超时触发，不能单凭名字
`DDR_TIMEOUT` 就断定 DDR 控制器故障。CAM2 的 DVP 帧计数也停止，故优先区分输入
时钟/帧信号停止、快照陈旧与帧内搬运等待；尚未确定根因。旧固件曾成功过一帧就
一直显示 `RUNNING`，不适合判断持续活跃度。

本轮只新增诊断 C 固件及离线测试，不修改 RTL、引脚、寄存器初始化表、DMA 架构、
DDR 布局或超时门限。没有自动复位、自动清除错误或覆盖未释放帧。按用户要求由
Luna High 子代理实现固件/仿真，主代理复核、集成和记录。原单目、GPIO和双目 bin 保留。

## 使用哪一份 bin

| 对照模式 | 本地主板串口 C24 / FPIOA0 | 远程串口 AB26 / FPIOA31 |
| --- | --- | --- |
| 双目同时采集诊断 | `bsp/camera_stereo_app/camera_stereo_diag_local.bin` | `camera_stereo_diag_remote.bin`（同目录） |
| 只采集 CAM2 | `bsp/camera_stereo_app/camera_cam2_only_local.bin` | `camera_cam2_only_remote.bin`（同目录） |

均为16384字节，继续使用已烧录的双目位流及其16384字节 loader。不需要为了本次
诊断重新生成位流。软件 Flash 起始地址仍是 `0x00A00000`，直接传原始 bin，不交换
端序；不要把 build 中供 readmemh 使用的换序文件烧入 Flash。串口115200、8N1、无流控。

CAM2-only **仍然初始化两颗 OV5640**，保留相同传感器运行背景，但 FPGA 的 CAM1
capture/DMA 关闭、不轮询或释放 CAM1 帧，CAM1 应显示 `DISABLED`，两项 live enable
均为0。它隔离的是 FPGA 双路采集/DDR并发负载，不是关闭第二颗传感器电源，
因此不能排除供电、模块公共电路等因素。

## 输出怎样看

启动标签是 `CAMERA_DIAG BOOT MODE=STEREO_DIAG` 或 `MODE=CAM2_ONLY`，避免误用旧 bin。
采集期只取4个分散像素并快速释放 ready，不逐帧全图校验。每路周期约1秒，CAM2
摘要相对 CAM1 延后约125ms，以避免两条长日志同时挤满2048字节队列；这不是两路
曝光/帧同步。首报和首次周期的统计窗口可能不是完整1秒，之后看连续周期增量。

| 字段 | 用途与注意事项 |
| --- | --- |
| `pclk_count / pclk_delta` | 冻结快照里的PCLK域计数及自上次该路摘要以来的增量；按32位回绕处理。计数受采集使能影响，不是独立精确频率计。 |
| `seq / seq_delta / snap_valid / fresh / age_ms` | 硬件快照序号、周期增量、最新控制有效位、本次轮询是否取得序号前进的新快照、距最近新快照的CPU时间。失效时其他字段保留历史值，不能视作当前状态。 |
| `cur_dma_pixels / cur_dma_bytes / cur_dma_lines` | 当前帧的DMA计数（偏移0x80/84/88），不是DVP当前计数，丢弃/错误路径可能清零。 |
| `frame_count / frame_delta` | DMA累计完整帧数及周期增量；`total_ok / sec_ok` 是CPU描述符检查、4点抽样并确认释放成功的帧数，不等同硬件所有完成帧。 |
| `dvp_frames / sec_dvp` | DVP累计帧结束事件及增量；不能单凭该数认定帧尺寸合格或已落DDR。 |
| `cap_en_live / dma_en_live` | CPU另外读取的实时控制寄存器，不属于冻结快照组，不能宣称与其他字段原子一致。 |
| `lines / pixels / bytes / last_addr / hw_sum16` | 最近完整成功帧的描述符；故障后会保留旧帧，不能据此说当前帧正常。sum16不是CRC32，也未在本诊断固件全图重算。 |
| `snap_timeout / poll_timeout / release_timeout` | 累计硬件快照超时、软件轮询失败、释放失败；历史超时不永久锁死状态判断。 |

`RUNNING` 需当前快照新鲜且最近2秒有成功消费；无首帧时 `WAIT_FRAME`，超过2秒
为 `STALLED`；最新轮询无法取得新快照为 `STALE_SNAPSHOT`；配置失败为
`FAILED_CONFIG`；主动关闭为 `DISABLED`。状态只是诊断分类，不替代错误码，
`RUNNING` 也不等于没有粘滞历史错误。计时来自70MHz CPU的CSR，低32位回绕用无符号相减。
`DISABLED` 路不请求快照，其帧字段是软件初始化占位，不是有效的硬件状态读数。

## 用户最终上板步骤

1. 先加载本地 `camera_stereo_diag_local.bin`，重新启动，保存从BOOT开始至少60秒完整日志。
2. 记录 CAM2 停止时 `pclk_delta/seq_delta/fresh/age_ms`、当前DMA计数、enable读回、
   `dvp_frames/frame_count` 与错误码；同时确认CAM1是否继续。不要先清错或复位掩盖首次现场。
3. 再加载本地 `camera_cam2_only_local.bin`，以同样的冷启动方式记录至少60秒；确认
   `MODE=CAM2_ONLY`，CAM1 `DISABLED` 且两项enable为0。两次测试均不改变接线与初始化参数。
4. 若断电检查连接，必须先完全断电；本轮不要求带电插拔、替换FMC、移换同板摄像头或自动操作PDS。

判断方向：

- CAM2-only也停，且新鲜快照/PCLK增量持续但DVP不成帧：优先检查CAM2帧/行信号、传感器输出和该路采样/时序。
- PCLK不增长并出现快照失败：检查时钟/电源/连接；仍需排除快照路径问题，不能只凭单字段定案。
- 只有双目并发停：进一步核查CAM2 CDC/时序及共享DDR事务仲裁、负载影响；不能直接判定“加缓冲即可”。
- DVP持续增长而DMA完成停止：进一步检查FIFO、DMA状态机及AW/W/B握手；当前快照未暴露逐握手探针，必要时另行设计RTL观测。

## 构建与验证记录

`make camera-diagnostic-firmware` 只编译四个新变体；`make camera-diagnostic-status-test`
验证纯C状态逻辑的2秒边界、恢复及计时回绕。真实CPU/双路MMIO/DDR/FPIOA UART测试
目标为 `camera-diagnostic-stereo-fw-test`、`camera-diagnostic-cam2-fw-test`；长故障注入
目标为 `camera-diagnostic-stall-fw-test`，不缩短生产固件2秒阈值。

本次没有操作实板，诊断程序不是已确定根因后的修复。实板对照结果应继续记录于此。

镜像记录（完整raw前缀与交付bin逐字节一致，剩余空间仅补零）：

| 镜像 | raw字节 | 交付字节 | SHA-256 |
| --- | --- | --- | --- |
| `camera_stereo_diag_local.bin` | 8484 | 16384 | `add046610e19428f0887074c0e43e3647e4e70ea7046683184d0c37f5f3c3392` |
| `camera_stereo_diag_remote.bin` | 8484 | 16384 | `a79e4ce646343103ff926cb69074ac551cd249b9c59f39b5d906c18d310f76a5` |
| `camera_cam2_only_local.bin` | 8456 | 16384 | `bce2251cc8d20e7cffef93883d6cfe5d58fc503894826c58f36eb24ce3956572` |
| `camera_cam2_only_remote.bin` | 8456 | 16384 | `15ec1c4d5b8b3cbc9a997e0d79d4d50dd4f34637172fd5bbe850aa1773ba0bdc` |

旧双目local/兼容镜像仍为
`9862750e294dbf7b3e19f9948d37dd36712f6694b04a3fb0a8ad3f46674d0e64`，
remote仍为 `5ea678c7c42f1b45914126aef8f874ce13f2075da9ee04c8a8d3b5750f66d91e`。
本轮前后Camera RTL、顶层、FPIOA和 `soc.fdc` 校验值一致。

已通过的离线检查：

- 四变体交叉编译（无编译警告）、长度、raw前缀与零填充检查；旧双目镜像不变。
- 纯C状态测试：首次等待、2秒边界、最近帧停滞、快照恢复、主动禁用/配置失败优先级、32位计时回绕。
- 实际CPU/DDR/MMIO/FPIOA UART双目诊断：完成并释放8/7帧，sum16分别为
  `8A800000/24EA0000`，零DMA错误/丢帧，两路252次SCCB写入，完整摘要字段与两路RUNNING断言通过。
- 实际CPU的CAM2-only：CAM2完成并释放8帧、sum16为`24EA0000`；CAM1 capture/DMA
  从未使能、零帧/释放/AXI写，两槽DDR内容未改变，完整摘要DISABLED/RUNNING断言通过。
- 上述两种模式的远程bin也通过FPIOA31物理UART逐字节解码测试：双目完成/释放8/7帧，
  CAM2-only完成/释放8帧，零错误/丢帧。日志为 `build/camera_diag_stereo_remote.log`
  和 `build/camera_diag_cam2_only_remote.log`。这里的“物理UART”指仿真的引脚波形，不是实板。
- 保持CAM2 PCLK、在3个完整帧后仅送一行再停止帧内数据的真实CPU故障测试通过：
  CAM2为3个完整帧、当前640像素/1280字节/1行，DMA错误码5；真实2秒门限后摘要
  `state=STALLED fresh=1 pclk_delta=22728033 seq_delta=73697`，CAM1继续完成/释放97帧，
  零错误/丢帧，无自动复位。日志为 `build/camera_diag_input_stall.log`。该激励验证
  诊断能力，不等同已复现实板全部错误标志或已确定根因。
- 诊断四变体的初始化表对象路径已隔离，`make -j4 diagnostics`通过且bin校验值完全不变。

健康仿真最初版本在CAM2摘要仅输出前缀时就结束，因此其结果未采用；修正为等待
两路完整UART行后重跑取得以上PASS。后续Makefile测试目标默认将输出保存到
`build/camera_diag_stereo.log`、`build/camera_diag_cam2_only.log` 和故障测试log。
故障日志来自最后一次测试标签修正前的构建，末尾有正确的`INPUT_STALL_PASS`和多余的
泛`STEREO_PASS`；后者不作健康双目验收依据。之后只修正标签并重复已有UART状态断言，
最新TB已重新构建，未为该显示修正重跑长故障场景；固件和核心故障断言未改变。
