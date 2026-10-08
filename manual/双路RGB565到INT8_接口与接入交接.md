# 双路 RGB565 到 INT8 的接入与交接

日期：2026-10-07。本文按当前 RTL 与本次任务正文记录，不把旧 NPU 交接草稿当成已经接通的系统能力。RTL 接口名和寄存器是否批准，以根代理收集的用户答复为准；目前此文记录已定的数据格式和接口责任，并标明尚待 A 对接/审批的边界。

## 数据规格与软件标准

转换规则及可执行参考工具见[RGB565_INT8_软件参考转换说明](RGB565_INT8_软件参考转换说明.md)。硬件从每路前处理器当前的整批描述符取得 RGB565 内容：`result_valid/result_ready`、`result_camera`、`result_frame`、`result_bank`、`result_addr`、`result_count`、`result_width/height`、`result_stride`、`result_boxes`、`result_colors`。有效 RGB565 是每张 18,432 字节，图像尺寸固定 96×96，源槽相邻间隔 32,768 字节。只有有效像素字节被读取。

每张输出为 36,864 字节：每像素 `R,G,B,0x00`。通道由 RGB565 little-endian 像素按高位复制展开，再各减 128 并以 8 位补码存储。没有额外归一化、裁剪、缩放或通道置换。

## 当前代码连接和缺口

`Hcamera_preprocess` 已输出每路最多 8 张 RGB565 ROI 的整批描述符。`Hpreprocess_stereo` 各实例在 `ddr_core_clk` 下运行，通过内部 `Haxi_2m1s_arbiter` 汇聚两路 DDR 读写；SoC 再把前处理和 Camera 的 AXI 接到共享 DDR 仲裁通路。前处理使用不同 AXI ID（CAM1 `0x50`、CAM2 `0x51`），Camera DMA 使用 `0x40/0x41`。仲裁事务锁定直到对应 burst/写响应结束。

`Hfpga_soc` 已接入两路 `Hrgb565_int8_lane` 和统计 MMIO。前处理 RGB565 批次 valid/ready 接到 converter 描述符端口，converter 的整批 `roi_release_*` 回到对应前处理器。逐张 INT8 描述符和释放端口已在 SoC 内部连线，但当前 `image_ready` 与 A 侧 `release_valid` 输入仍绑低；`Hnpu_service/Hnpu_system` 尚未接入，因而真实 NPU 端不消费也不归还图像。转换器可完成写入并把最多 8 条/路记录留在内部 FIFO 后背压；这不等于端到端 NPU 闭环。

DDR 仲裁采用分层连接：`Hrgb565_int8_ddr_merge` 先公平合并 CAM1/CAM2 converter lane，再公平合并 converter 与原 Camera+前处理 aggregate；aggregate 之后仍经已有 `u_camera_ddr_arbiter` 与 CPU/启动桥共享 DDR。Lane AXI ID 为 CAM1 `0x60`、CAM2 `0x61`，前处理 ID 为 `0x50/0x51`，Camera DMA 为 `0x40/0x41`。地址以完整 byte address 减 `DDR_BASE` 一次得到 30 位 local address，和现有 preprocess AXI 接法一致。该连接复用 256-bit DDR AXI 和 `ddr_core_clk`，没有 CPU 像素搬运。

`soc/soc_addr_map.vh` 现已加入 8 个 INT8 块基址、块大小、槽数、图像长度和已批准的 MMIO 窗口宏。块地址与任务规格一致：CAM1 为 `0xB8800000`、`0xB8880000`、`0xB8900000`、`0xB8980000`；CAM2 为 `0xB8A00000`、`0xB8A80000`、`0xB8B00000`、`0xB8B80000`。INT8 区间 `[0xB8800000,0xB8C00000)` 共 4 MiB。旧通用 `SOC_NPU_INPUT` 预留 `[0xB8000000,0xB9000000)` 覆盖了 Camera/ROI 与 INT8 地址；后续模型权重从 `0xB9000000` 起。旧宽泛 input 预留的语义及 A 侧最终模型内存图仍需一起核对。每张地址由所属摄像头块基址加位置号×36,864 计算，块内位置号为 0～13。DDR master 端沿用顶层既有的地址基址转换一次。

当前 `Hnpu_service` 接收整批 `batch_base + roi_index * stride`，其释放通知是 `bank + frame` 整批释放；不能表达分散槽位、逐张输入地址、每图 generation，也不满足按张归还。`Hnpu_fc_engine` 默认最多读取 1,024 个输入特征，不能执行 96×96×3 彩色输入；`Hnpu_dma` 只是 DDR 复制器。上述模块存在不等于实际分类链路可用。

## 交付及归还责任

本次冻结的职责如下：

| 接口/资源 | 提供方 | 接收方与含义 |
|---|---|---|
| RGB565 批次描述符及候选框/颜色 | `Hcamera_preprocess` | 转换模块；valid/ready 握手仅代表描述符被领取 |
| RGB565 整批归还 | 转换模块 | 前处理器；仅在整批源读取结束且读事务排空后释放原 bank，不等待 NPU 推理 |
| 每张 INT8 描述符 | 转换模块 | A 的任务管理；逐张 valid/ready，含原图 camera/frame/count/index、box/color、实际 INT8 地址、块/位置、尺寸/长度和复用代次；写响应成功前不得交付 |
| 每张 INT8 归还 | A 的任务管理 | 转换模块；通知应含 camera、块、位置、代次、frame token，并有接收端 ready；只有匹配仍被占用的本代位置才释放 |
| 分类结果元数据 | A 的任务管理 | 在图像槽释放后继续保留 camera/frame/图内序号/候选框/color 与分类结果 |

转换模块与前处理之间的批次端口（每路各一组）合同如下。`desc_valid` 表示对应摄像头有一份完整 RGB565 批次描述符；合法非空描述符只有在硬件能原子预留该批所有 INT8 位置时才会 `desc_ready`，握手成功即转换模块取得 RGB565 bank 的使用权。格式/地址/数量非法的描述符会被接收并记错后释放源 bank；空批次直接接收并释放源 bank，不占 INT8 位置。`camera[7:0]` 是 1 或 2；`frame[31:0]` 是源相机帧 token；`rgb_bank` 是前处理器的两个 RGB565 bank 号；`rgb_base[31:0]` 是该 bank 的第 0 张 RGB565 起始地址；`count[7:0]` 是本帧有效 ROI 数量（0～8）；`width/height[15:0]` 是已配置输出尺寸（本版本必须 96×96）；`stride[31:0]` 是 RGB565 相邻 ROI 地址间隔（本版本 32,768 字节）；`boxes[8*64]` 和 `colors[8*3]` 是前处理器提供的候选框与颜色，转换器按 `image_index` 选取，不重新计算。

转换模块到 A 的 `image_valid/image_ready` 是逐 ROI 的稳定 valid/ready 接口。A 拉高 `image_ready` 才表示本条记录已进入 A 的任务队列；仅交付握手不代表 A 已读取图像，也不允许回收 INT8 槽。字段为：`camera[7:0]` 原摄像头编号；`frame[31:0]` 原图帧 token；`batch_count[7:0]` 源帧 ROI 总数；`image_index[7:0]` 本批次序号 0～count-1；`box[63:0]` 与 `color[2:0]` 原前处理候选元数据；`block[1:0]` 和 `position[3:0]` 分别标识 INT8 512 KiB 块号 0～3 和该块固定图像槽号 0～13；`generation[31:0]` 是该槽每次重新分配时递增的占用代次（回卷后跳过 0），用于防止旧释放请求误释放新图；`data_addr[31:0]` 是本张实际 DDR 地址，A 必须使用这个地址而不能按批次 stride 推算；`width/height[15:0]` 固定 96；`data_bytes[31:0]` 固定 36,864。

A 到转换模块的归还端口为 `release_valid/release_ready`。A 在一张已完成所需读取、结果已可靠保存且所有对应读事务排空后，提交 `camera[7:0]`、`block[1:0]`、`position[3:0]`、`generation[31:0]` 和 `frame[31:0]`。字段在 `release_valid && release_ready` 前保持稳定。ready 表示转换模块本周期已接收并校验这条释放通知；匹配当前占用记录才清除该槽，错误、重复或过期记录只计非法归还且不释放。当前协议没有额外释放确认 valid；A 可由本端 valid/ready 握手确认通知已被处理，硬件错误/非法归还计数通过状态接口观察。A 不得因结果 FIFO 入队或计算完成信号本身而在仍有 DDR 读取时释放。

RGB565 源 bank 由转换模块按现有前处理 `roi_release_valid + roi_release_bank + roi_release_frame` 整批释放。只有本批所有图像转换成功、写响应完成、源读取事务均结束后才释放；不等待 NPU 计算或结果读取。两路各自拥有描述符通道和 56 个位置的分配表，DDR AXI 可以仲裁共享，元数据与槽占用记录必须按 camera 分离。用户已批准逐张交付/归还协议和转换状态窗口 `0x40000500–0x400005ff`；本节字段为获批接口合同，RTL/SoC 接线仍须待实现后核对。

## CPU 与审批边界

CPU 继续承担启动、配置、停止、状态读取及异常恢复。逐张正常转换/交付/归还不逐笔中断 CPU。用户已批准新增状态窗口 `0x40000500–0x400005ff`；现有 NPU MMIO `0x40000100–0x400001ff`、CAM1 `0x40000300–0x400003ff`、CAM2 `0x40000400–0x400004ff` 保持原用。下表寄存器偏移为实现合同，当前方案不增加 IRQ。

审批和接入状态：

1. 用户已批准逐张 `image_valid/image_ready` 与 `release_valid/release_ready` 合同，以及 CPU 状态窗口 `0x40000500–0x400005ff`。
2. A 仍需完成 `Hnpu_service`/`Hnpu_system` 的逐张、不连续地址适配。当前 FC V1 不支持 96×96 RGB 输入；A 需结合 B 的最终模型规格/reference vectors 完成适配，不能把已有 FC 验证核描述为真实分类链路。
3. `soc_addr_map.vh` 已有统一 INT8 地址宏；需随 RTL 最终接入核对 AXI 地址换算与旧 `SOC_NPU_INPUT` 宽预留的内存图关系。
4. CPU/DDR 时钟域状态同步、计数器更新语义按 SoC 实现确认；寄存器窗口已获批，不需要再次请求窗口审批。

转换控制寄存器映射（相对 `0x40000500`，所有字段为 32 位）：

| 偏移 | 名称 | 草案语义 |
|---:|---|---|
| `0x00` | `CTRL` | bit0 enable；bit1 stop request（停止领取新批次，让当前批次排空）；bit2 清 sticky error |
| `0x04` | `STATUS` | bit0 busy；bit1 等待空闲槽；bit2 等待 DDR；bit3 等待 A 接收；bit4 error；bit5 DDR ready |
| `0x40` | `CAM1_IMAGES_DONE` | CAM1 成功转换图像数，单位张 |
| `0x44` | `CAM1_BATCH_CYCLES` | 当前实现从批次描述符握手至末张 DDR 写 B 响应完成；不包含之后因 A 暂停造成的交付等待，`HANDOFF_WAIT` 单独统计 |
| `0x48` | `CAM1_SLOT_WAIT_CYCLES` | CAM1 等待可用 INT8 槽的 `ddr_core_clk` 周期数 |
| `0x4c` | `CAM1_READ_ADDR_WAIT_CYCLES` | 等待读地址请求被接受的周期数 |
| `0x50` | `CAM1_READ_DATA_WAIT_CYCLES` | 等待读数据返回的周期数 |
| `0x54` | `CAM1_WRITE_ADDR_WAIT_CYCLES` | 等待写地址请求被接受的周期数 |
| `0x58` | `CAM1_WRITE_DATA_WAIT_CYCLES` | 等待写数据 beat 被接受的周期数 |
| `0x5c` | `CAM1_WRITE_RESP_WAIT_CYCLES` | 等待写响应的周期数 |
| `0x60` | `CAM1_HANDOFF_WAIT_CYCLES` | 等待 A 接收逐张描述符的周期数 |
| `0x64` | `CAM1_USED_SLOTS` | 当前 CAM1 占用图像槽数 |
| `0x68` | `CAM1_PEAK_SLOTS` | CAM1 占用槽数峰值 |
| `0x6c` | `CAM1_DDR_ERROR_COUNT` | CAM1 DDR/描述符错误累计数 |
| `0x70` | `CAM1_INVALID_RELEASE_COUNT` | CAM1 非法、重复、过期归还累计数 |
| `0x74` | `CAM1_FAILED_BATCHES` | CAM1 转换失败批次数 |
| `0x78` | `CAM1_LAST_FAILURE_FRAME` | 最近失败批次的原图 frame token |
| `0x7c` | `CAM1_LAST_FAILURE_INFO` | bit[15:8] 错误原因码，bit[7:0] 失败小图序号 |
| `0x80`～`0xbc` | `CAM2_*` | 与 CAM1 相同的 16 个统计字；偏移统一比 CAM1 对应项增加 `0x40`，结束于 CAM2 failure info `0xbc` |

`LAST_FAILURE_INFO` 当前原因码：1=非法描述符/尺寸/地址/数量（小图序号 `0xff` 表示描述符级错误，没有有效小图序号），2=读响应或协议错误，3=写 B 响应错误，4=转换事务超时。每次 CPU 统计读都请求新快照；若连续失败事件在分开读取 `LAST_FAILURE_FRAME/INFO` 期间发生，两字可能对应不同的最近事件。当前没有专用锁存命令同时固定这两个字段。

周期类计数使用 `ddr_core_clk`，饱和到 `0xffffffff`。不同读写通道、两路等待可以重叠；等待项不得相加冒充总耗时。每次统计寄存器读使用请求/应答快照：CPU 对统计地址发起读后，`mmio_ready` 等待 DDR 域锁存两路完整统计向量并回传确认，然后从该次快照返回所选字；这避免单个多位计数器逐位同步造成撕裂，但连续读取不同地址会得到不同时间点的快照。`STATUS` 实时状态位分别经过同步器。MMIO 窗口已获用户批准。软件 stop 只停止领取新批次，已接收的批次继续处理/排空；槽 generation 和占用状态只在共享 SoC 冷复位时清除，因此 A 必须在同一复位中清空尚未处理的释放队列。CPU 写 stop 不能直接清除仍被事务占用的槽。

任务正文已经确定的 96×96、颜色展开、R/G/B/0 布局、每路 4 块、每块 14 张、按张交付/归还，不再沿用旧“待 B 确认尺寸”及“INT8 整批归还”描述；用户的 `待确认问题回复.md` 原文件未改写。

## 与 A 联调及实板步骤

联调开始前由 A 提供可接入的逐张输入与归还接口，并确认当前核的模型能力；B 提供 96×96 RGB565 输入和逐字节标准输出。用软件标准工具生成转换参考，再把转换模块 DDR 输出按有效 36,864 字节逐字节比较。联调应分别检查每张写响应完成后才出现交付、接收暂停时 descriptor 稳定、归还暂停时 release 保持、generation 防止陈旧释放、源 RGB565 在读取排空后整批归还。双路并发期间记录读写 ID、目标范围、每路进展及槽所有权，确认没有跨路污染。

总体吞吐目标为每路每秒完成至少 1 个选中原图帧的全部有效小图分类，后续目标每路 5 帧/秒；最多 8 张时分别对应双路 16 张/秒、80 张/秒。转换器只能报告自己的转换统计，完整分类吞吐必须待 A 的实际模型接入后测量，不能由转换模块单独承诺。

实板需在转换和 A 的模型引擎接入后连续运行至少 5 分钟，检查两路均持续推进、DDR 不越过保留区/块尾 8 KiB、无未归还覆盖、暂停和错误后无提前复用，且 Camera 采集和前处理行为保持正常。当前没有实板记录；不可把目标帧率写成实测吞吐。

## 完成状态

- 软件与文档文件：`tools/rgb565_to_int8_reference.py`、`manual/RGB565_INT8_软件参考转换说明.md`、`manual/双路RGB565到INT8_接口与接入交接.md`。`manual/双路硬件前处理_实现与验证.md` 已追加新输入协议说明；工程源文件清单 `project/project.pds` 已加入 lane/stereo/DDR merge/regs 四个新 RTL 文件；未修改生成的 parse-design screen 清单。
- 已完成并自检：独立软件标准转换程序；当前 RGB565 前处理/NPU/DDR 代码审查；接口责任与数据规格文档；明确旧整批 NPU 接口不可直接满足新按张协议。参考程序的非 testbench 自检通过，覆盖黑/红/绿/蓝/白/中灰已知字节、错误输入长度拒绝、96×96 输出长度 36,864 字节、每像素占位字节为 0，以及文档命令行成功/错误调用。
- 尚未逐数据集验证：B 的 reference vector 尚未提供，尚未执行与 B 数据的逐字节对照；软件自检不是 RTL 验证。
- 已完成的静态 RTL 核查：独立 Icarus elaboration 和 DDR profile 顶层 Verilator lint 均通过，范围和命令见下方。`git diff --check` 通过。这些是语法/静态 elaboration/lint 核查，不代表行为仿真或器件综合。
- 已实现、静态核查通过但功能未验证：两路 `Hrgb565_int8_lane`、双路公平/层级 DDR merge、CPU 状态寄存器已在 `Hfpga_soc` 连线；每路统计还暴露失败批次数、最近失败 frame、原因码和 ROI 序号。A 的 `image_ready`/逐张 `release_valid` 仍是常量背压/无通知，尚未接入 `Hnpu_service/Hnpu_system`，所以并非真实 NPU 闭环。
- 未验证：按要求未新增、修改或运行任何 testbench；没有行为仿真、PDS 器件综合/布局布线、资源/时序报告或实板数据。BRAM profile 的完整解析未通过，因为当前环境未提供供应商原语 `GTP_DRM36K_E1`；因此本次静态核查限于 DDR profile。
- 依赖 A：逐张不连续输入、generation 归还握手、结果元数据保留及真实模型计算。
- 依赖 B：96×96 符合新格式的模型输入样本/reference vector、量化/模型能力说明。
- 已批准：逐张交付/归还协议及 CPU 状态窗口 `0x40000500–0x400005ff`。仍依赖 A 完成每图真实地址与释放协议适配，依赖 B 提供规格/参考输入；INT8 地址宏和状态寄存器需随最终 RTL/SoC 接入复核。

静态核查命令和结果：

```sh
iverilog -g2012 -Isoc -s Hrgb565_int8_stereo -o /tmp/int8_stereo.vvp soc/Hrgb565_int8_lane.v soc/Hrgb565_int8_stereo.v
iverilog -g2012 -Isoc -s Hrgb565_int8_regs -o /tmp/int8_regs.vvp soc/Hrgb565_int8_regs.v
iverilog -g2012 -Isoc -s Hrgb565_int8_ddr_merge -o /tmp/int8_merge.vvp soc/Haxi_2m1s_arbiter.v soc/Hrgb565_int8_ddr_merge.v
```

三条命令均 exit 0。顶层 `Hfpga_soc` DDR profile 使用 Verilator `--lint-only --timing --language 1800-2012 -I. -Isoc`，并包含完整 RTL 源列表及 `sim/board_ip_lint_stubs.v`；`CPU_MEM_BRAM=0` 下分别令 `PREPROCESS_ENABLE=0` 和 `1`，两次均 exit 0 且无输出。lint 使用告警选项 `--Wno-WIDTHTRUNC --Wno-BLKLOOPINIT --Wno-CASEINCOMPLETE --Wno-UNDRIVEN --Wno-fatal`。这些命令没有运行 testbench。

交付状态：**软件参考和接入说明完成；RTL联调、NPU模型、性能及实板未验证。**
