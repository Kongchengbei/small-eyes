# 人员 A：NPU 交接说明

人员：志勇  
范围：双目摄像头 ROI 路标分类，当前为仿真版本

## 一、已完成

- CNN NPU：Conv、ReLU、MaxPool、GAP、FC、Argmax、margin/reject。
- 96×96 源图抽取为 32×32 模型输入。
- 模型自动加载、格式检查、CRC 校验和片内缓存。
- CAM1/CAM2 队列、公平调度、整批淘汰、结果关联和 bank 归还。
- 结果 FIFO：peek、显式 POP、非空 IRQ、满保护和双时钟 CDC。
- AXI 地址、对齐、RID、RRESP、RLAST 和背压错误检查。

## 二、本次项目修改

### RTL 修改

- `soc/Hnpu_cnn_engine.v`：新增模型驱动 CNN 执行器，支持 Conv、ReLU、MaxPool、GAP、FC、Argmax、模型校验和片内模型缓存；支持从 96×96 源图抽取 32×32 输入。
- `soc/Hnpu_image_service.v`：新增逐 ROI 接入层，管理 CAM1/CAM2 队列、box/color/frame 元数据和 INT8 槽位归还；按 v0.3 最大张量配置双 16 KiB 中间缓存。
- `soc/Hnpu_cnn_engine.v`：在 CNN 执行器内部完成 signed INT8 量化、右移、ReLU 和饱和处理。
- `soc/Hnpu_service.v`：增加 CNN 模式、模型地址/长度、11 类结果、score/reject 和模型参数传递。
- `soc/Hnpu_system.v`：增加 image-mode、模型加载和 CPU/DDR 结果 FIFO 集成。
- `soc/Hfpga_soc.v`：增加 NPU image-mode、NPU 与前处理的 DDR AXI 合并连接；DDR profile 默认开启前处理和 image-mode。
- `soc/Hfpga_soc.v`：修正双路 INT8 AXI `arsize/awsize` 为每路 3 位，避免 CAM2 位段被截断。
- `soc/flash_boot/flash_ddr_loader.v`、`soc/flash_boot/flash_ddr_boot.v`：启动时先搬运 CPU 固件，再搬运 `model.npu` 到 `0xB9000000`，两段逐字回读通过后才放行 NPU。
- `soc/Hrgb565_int8_regs.v`：DDR profile 可在复位后自动使能 INT8 转换器；运行使能仍受 DDR 初始化和模型就绪门控。
- `scripts/make_npu_flash_image.sh`：把固定长度 CPU 固件和 `model.npu` 拼成上电所需 Flash 镜像。

### 工具、仿真和地址表修改

- `scripts/npu_model.py`：支持 `model.npu` 生成、解析、检查、CRC 校验和 demo 模型生成。
- `scripts/run_testbench.sh`、`scripts/sim.mk`：统一查找 `temp/tests/` 测试，并增加 CNN、image service、image system 回归入口。
- `sim/run_bram_boot_checks.sh`：加入新增 NPU RTL 的 SoC 检查源文件。
- `project/project.pds`：补齐 CNN、image service、result FIFO 等 NPU RTL 文件，保证 PDS 工程包含已接入的模块。
- `soc/soc_addr_map.vh`：统一 INT8 缓冲区、模型区、scratch 区和转换器 MMIO 地址宏。
- `temp/tests/`：新增模型格式、量化、CNN、双路 service、system、96→32 抽取和错误注入测试。

## 三、已确定的接口和地址

| 项目 | 当前约定 |
|---|---|
| DDR 源图 | `96×96×4 HWC4 INT8`，`R,G,B,0`，每张 `36,864 Byte` |
| NPU 输入 | 每隔 3 个像素抽取，得到 `32×32×4 HWC4 INT8`，`4,096 Byte` |
| 模型 | `temp/路标模型文件v0.3_10月10日/model.npu`，11 类；`classes.csv` 已收到 |
| INT8 缓冲区 | `0xB8800000～0xB8C00000`，8 个 512 KiB block |
| 模型区 | 从 `0xB9000000` 开始 |
| Scratch 区 | 从 `0xBC000000` 开始预留；当前模型主要使用片内 tensor buffer |
| NPU MMIO | `0x40000100～0x400001FF` |
| INT8 转换器 MMIO | `0x40000500～0x400005FF` |
| NPU AXI ID | `0x80` |
| INT8 转换 AXI ID | CAM1/CAM2 为 `0x60/0x61` |
| 时钟 | 数据侧使用 `ddr_core_clk`，CPU MMIO 使用 `cpu_clk` |

上电镜像约定：Flash `0x00A00000` 放 `[CPU 固件固定区 16384 Byte][model.npu 62720 Byte]`，总长度 `79104 Byte`；启动器把两段分别放到 CPU DDR `0x80000000` 和模型区 `0xB9000000`，模型未完成回读校验前不接收 ROI。

## 四、模型文件

- 文件：`model.npu + classes.csv`。
- `model.npu`：128 Byte header，64 Byte/层 descriptor，INT8 权重，INT32 小端 bias，32 Byte 对齐，CRC32。
- 卷积权重：`[输出通道][卷积行][卷积列][输入通道]`。
- FC 权重：`[类别][特征]`。
- 第一版候选为 4 个卷积层：L1 `4→16`、L2 `16→32`、L3 `32→64`、L4 `64→64`；模型包按对齐后为 `62,720 Byte`，约 `3.54M MAC`，可整体缓存到片内存储。

详细格式见：`temp/人员A_模型格式与档位说明.txt`。

## 五、验证结果

```text
模型格式检查：v0.3 model.npu 通过（62,720 Byte，CRC 正确）
正式模型独立 reference：32×32 和 96×96/隔3取1，各 16 个构造案例最终结果及每例 9 个中间层 bit-exact 通过（共 288 次逐层检查；不是 B 的真实框金样）
模型缓存：正式模型只从 DDR 加载 1 次，后续 ROI 不重复读权重
速度仿真：缓存命中后 96×96 输入最慢 3,571,975 NPU 周期/ROI；70 MHz、仿真 DDR 条件下约 19.6 ROI/s，16 ROI/s 回归门槛通过；80 ROI/s 尚不满足
CNN Engine：11 个正常/错误注入案例通过
CNN Service/System、Image Service/System：通过
A 侧总回归：18 项通过（含 PDS 源文件清单与 SoC 顶层 lint）
```

执行总回归：

```bash
CCACHE_DISABLE=1 make npu-test
```

测试入口见：`temp/tests/`，输入与接口约定已汇总在本文第三、四节。

## 六、请 zzx 复核的内容

以下接口已在 RTL 连线，需 zzx 做最终配置、综合和板级复核：

1. INT8 bank、模型区、scratch 的实际保留范围和 CPU 访问属性。
2. NPU/转换器 AXI ID 是否与最终仲裁器一致。
3. NPU 结果 FIFO 非空 IRQ 到 CPU 外部中断的路由。
4. `ddr_core_clk`、`cpu_clk` 和系统复位的最终连接及复位时序。
5. 前处理逐张 descriptor、NPU 消费和 INT8 bank 归还的端到端连接。

## 七、尚待完成

- B 交付 v0.3 对应的完整 `golden_input/golden_output.csv` 后，完成真实框 bit-exact 回归；当前包只有 `model.npu/classes.csv`。
- B 交付 v0.3 逐层金样后，完成每层输出/累加器比对；旧 v0.2 金样不能当作 v0.3 验收依据。
- zzx 审批 A1 接口和地址/时钟/中断合同；完成 PDS 综合、资源/时序报告、SoC 全链路与实板 DDR/Flash 测试。
- CPU 软件读取/POP 结果 FIFO、处理 IRQ，并验证真实摄像头持续运行和实际帧率。

### A1–A8 验收状态

| 任务 | 当前状态 | 尚缺验收证据 |
|---|---|---|
| A1 接口能力 | 规格已写、RTL 已连线 | zzx 正式审批 |
| A2 双路调度 | 双路各 2 个 ROI 的交替顺序、队列与背压仿真通过；image-mode 不淘汰已接收 ROI | 真实双路持续负载/超载记录 |
| A3 DDR 搬运 | 地址、响应与模型 CRC 错误注入通过；坏模型不读取 ROI 输入 | 板级 DDR 验证 |
| A4 自动运行 | 一次加载后连续 ROI 仿真通过 | 上板持续任务 |
| A5 CNN 计算 | v0.3 的 16 个构造输入最终结果及逐层输出 bit-exact | B 的真实框、逐层金样和累加器金样 |
| A6 关联/归还 | 双路不同帧元数据与槽位归还仿真通过；模型错误时仍归还 | SoC 全链路、真实 bank 周转 |
| A7 FIFO/IRQ | peek/POP、满背压、CDC 单元仿真通过 | CPU 固件和实板中断联调 |
| A8 验证交接 | 回归与接口说明已提供 | PDS 综合/时序、实板与 zzx 签收 |

当前结论：人员 A 的 NPU 接口、96×96 到 32×32 数据通路、模型缓存、双路服务、上电双段加载和 SoC RTL 接线已完成；v0.3 模型已可在仿真中加载运行。完整精度、PDS 综合/时序和实板验证尚未完成，不能据此宣称已可上板稳定运行。
