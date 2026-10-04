# 人员 A：共享 NPU 交接说明

版本：`NPU-HANDOFF-V1-DRAFT`  
适用范围：双目摄像头 ROI 路标识别项目  
验证范围：当前仅仿真

## 1. 交接结论

人员 A 已完成共享 NPU 的独立 V1 模块和基础仿真，当前包括：

- CAM1/CAM2 双路批次队列、轮转调度和完整批次淘汰；
- 单 ROI INT8 FC 计算和 DDR 读取；
- 结果与 camera、frame、ROI、box、color 元数据关联；
- INT8 bank 正常完成和批次淘汰后的归还通知；
- CPU/DDR 双时钟结果 FIFO、peek、显式 POP 和非空 IRQ；
- AXI 暂停、RID/RRESP/RLAST 错误和地址检查；
- 独立 testbench 和 `make npu-test` 回归入口。

当前尚未完成最终整机交付：

1. 当前计算核是 signed INT8 FC V1，不是完整 CNN/TFLite INT8 NPU。
2. 最终模型、量化规则和 reference vector 尚未由 B 提供。
3. RGB565 ROI 到最终 INT8 tensor 的转换尚未由 zzx 接入。
4. INT8 bank 最终地址、数量、容量和 stride 尚未由 zzx 发布。
5. `Hnpu_system` 尚未接入 `Hfpga_soc` 的最终 SoC/DDR/IRQ 拓扑。

## 2. A 已交付的代码

| 文件 | 功能 |
|---|---|
| `soc/Hnpu_fc_engine.v` | signed INT8 FC、INT64 累加、bias、算术右移、argmax、margin、AXI 读和错误处理 |
| `soc/Hnpu_service.v` | 双路队列、轮转、批次淘汰、结果槽位预留、结果关联、bank 归还 |
| `soc/Hnpu_result_mmio.v` | DDR/CPU 异步 FIFO、队首 peek、显式 POP、非空 IRQ、错误状态 |
| `soc/Hnpu_result_bridge.v` | service 到 CPU 结果 FIFO 的连接 |
| `soc/Hnpu_system.v` | A 侧 NPU 集成边界 |
| `soc/Hnpu_ctrl.v` | 基础控制寄存器、start/done/busy 和 IRQ |
| `sim/tb_npu_fc_engine.sv` | FC 和 AXI 错误测试 |
| `sim/tb_npu_service.sv` | 双路服务和结果测试 |
| `sim/tb_npu_service_drop.sv` | 队列淘汰和 bank 释放测试 |
| `sim/tb_npu_result_mmio.sv` | 异步 FIFO、peek、POP 和 IRQ 测试 |
| `sim/tb_npu_system.sv` | A 侧系统边界测试 |

## 3. 当前 V1 能力边界

### 3.1 计算规则

```text
score[c] = bias[c] + sum(input[i] * weight[c][i])
score[c] = arithmetic_shift_right(score[c], quant_shift)
```

当前支持：

- signed INT8 input；
- signed INT8 weight；
- INT64 累加；
- signed INT32 bias；
- 最多 8 类；
- argmax；
- top1-top2 margin。

当前不支持：

- Conv、Pool、ReLU 等 CNN 算子；
- 多层模型自动执行；
- Softmax 概率；
- 完整 TFLite INT8 multiplier、zero-point、rounding、saturation；
- per-channel 量化。

当前默认 `MAX_FEATURES=1024`，只是 V1 参数，不是最终模型输入规格。

### 3.2 NPU 输入数据

NPU 不直接读取 RGB565，接收上游已经转换好的 signed INT8 一维 tensor：

```text
ROI_i 地址 = batch_input_base + i * batch_input_stride
input[j]   = DDR[ROI_i 地址 + j]
```

要求：

| 项目 | 要求 |
|---|---|
| 地址、stride、长度 | 32 Byte 对齐 |
| `input_bytes` | `ceil(feature_count / 32) × 32` |
| `input_stride` | 不小于 `input_bytes` |
| padding | 不参与计算 |
| HWC/CHW、RGB/BGR | 由 B 提出，A+B 提出方案，zzx 审批；当前 NPU 只按线性数组读取 |
| 单 ROI 上限 | 当前默认 `feature_count <= 1024`，最终值待模型确认 |

## 4. 给人员 B 的接口要求

B 需要提供以下内容，A 才能完成最终模型适配和 bit-exact 验证：

- 模型类型和算子/层顺序；
- 输入宽、高、通道数、RGB/BGR、HWC/CHW；
- `feature_count` 和每 ROI 的 INT8 字节数；
- activation/weight/bias/output 的 scale、zero-point；
- rounding、saturation 和 bias 规则；
- 类别编号，包括背景/非路标、未知和低置信度拒绝；
- 输出分数含义：logit、概率还是 margin；
- 模型包和层配置格式；
- 输入、逐层输出、最终类别/分数 reference vector；
- 模型是否兼容当前 signed INT8 FC V1。

请 B 明确：如果模型包含 CNN 算子或当前 V1 不支持的量化规则，必须列出需要 A 增加的硬件能力，不能直接交付裸模型文件。

## 5. 给 zzx 的批次接口

zzx 的 INT8 转换模块向 `Hnpu_system` 提交一整个 batch，接口字段如下：

| 字段 | 含义 |
|---|---|
| `batch_camera` | `1`/`2`，对应 CAM1/CAM2 |
| `batch_frame` | 原图 frame token |
| `batch_bank` | INT8 bank 编号 |
| `batch_input_base` | ROI 0 地址 |
| `batch_input_stride` | ROI 间距 |
| `batch_input_bytes` | 每 ROI 读取长度 |
| `batch_feature_count` | 每 ROI 有效特征数 |
| `batch_count` | ROI 数量，当前最多 8 |
| `batch_boxes` | ROI 候选框 |
| `batch_colors` | ROI 颜色标签 |
| 模型字段 | weight/base、weight stride、bias/base、class count、quant shift |

握手规则：

- `batch_valid=1` 时，所有批次字段必须保持稳定；
- 只有 `batch_valid && batch_ready` 才算 A 接收；
- 接收 batch 不等于立即归还 bank；
- A 在该批最后一次 INT8 读取完成后输出 `int8_release_valid + bank + frame`；
- 队列淘汰的完整 batch 也必须输出 bank/frame 归还；
- 正在执行的 batch 不得覆盖或强制归还。

## 6. 给 zzx 的 AXI/DDR 需求

当前 V1 的输入、权重和 bias 都通过 AXI 只读：

| 项目 | 要求 |
|---|---|
| 数据宽度 | 256 bit，32 Byte/beat |
| burst | INCR，最多 16 beats |
| 4 KiB | 单个 burst 不得跨 4 KiB 边界 |
| 对齐 | 地址、输入长度、权重 stride、bias 地址 32 Byte 对齐 |
| AXI ID | 当前默认 `8'h80`，最终由 zzx 确认 |
| 返回检查 | RID 匹配、RRESP=OKAY、RLAST 正确 |
| 背压 | 必须支持 ARREADY/RVALID 暂停 |
| 错误 | 当前 ROI 结束并记录错误，不得永久占用共享读通道 |

当前工程已有区域：

| 区域 | 当前地址/范围 | 状态 |
|---|---|---|
| CAM1 原图槽 | `0xb800_0000`、`0xb810_0000` | 已有 |
| CAM2 原图槽 | `0xb820_0000`、`0xb830_0000` | 已有 |
| CAM1 RGB565 ROI | `0xb840_0000`、`0xb850_0000` | 已有 |
| CAM2 RGB565 ROI | `0xb860_0000`、`0xb870_0000` | 已有 |
| INT8 bank | `0xb880_0000` 起 | 需要 zzx 分配 |
| 权重 | `[0xb900_0000, 0xbb00_0000)` | 候选预留，需按最终模型确认 |
| scratch | `[0xbc00_0000, 0xc000_0000)` | 多层模型需要时确认 |

`SOC_NPU_INPUT_BASE=0xb800_0000` 与 CAM1 原图槽起点重合，不能直接作为最终 INT8 bank 基址使用。zzx 发布正式地址表时必须消除重叠。

## 7. 给 zzx 的 SoC 接入需求

请 zzx 确认或修改：

- `soc/Hfpga_soc.v`：实例化并连接 `Hnpu_system`；
- DDR 仲裁器：从当前 CPU/Camera 两主扩展为包含 NPU 的连接；
- `soc/soc_addr_map.vh`：发布唯一 INT8 bank、模型、scratch、MMIO 地址；
- 前处理链：`RGB565 ROI -> INT8 转换 -> batch_valid/ready`；
- bank release：接收 `int8_release_bank/frame` 后重新开放 bank；
- CPU MMIO 译码和结果读取；
- NPU IRQ 接线；
- `ddr_clk`、`cpu_clk`、复位极性和复位释放顺序；
- NPU AXI ID 是否与 Camera/CPU 冲突；
- CPU 共享 DDR 区的缓存旁路/一致性处理。

## 8. MMIO 结果接口

当前 NPU MMIO 候选窗口为 `0x4000_0100`～`0x4000_01ff`，最终由 zzx 发布。

| 偏移 | 寄存器 | 规则 |
|---:|---|---|
| `0x20` | `RESULT_STATUS` | count、empty、full、error |
| `0x24`～`0x40` | `RESULT_DATA0`～`7` | 队首 256 bit，peek，不出队 |
| `0x44` | `RESULT_POP` | 写 bit0=1，弹出一条完整结果 |
| `0x48` | `RESULT_IRQ_ENABLE` | bit0 非空 IRQ，bit1 错误 IRQ |
| `0x4c` | `RESULT_IRQ_STATUS` | 非空/错误状态，错误 W1C |
| `0x50` | `RESULT_ERROR_CODE` | 最近错误码 |

结果 FIFO 满时，生产者 `ready=0`，属于正常背压，不覆盖已有结果。FIFO 非空时产生电平 IRQ，读空后撤销。

## 9. 结果记录和 bank 归还

每个 ROI 结果必须保留：

```text
camera、frame、bank、roi、box、color、class、confidence/margin、error
```

结果顺序：

```text
engine_done
  -> 生成 ROI 结果
  -> 结果 FIFO 接收
  -> 最后一个 ROI 完成后发 bank/frame release
```

被淘汰 batch 的 bank 在淘汰时释放。背景/非路标、未知路标和低置信度拒绝属于正常模型结果，不应记为硬件错误。

## 10. 验证交付

运行命令：

```bash
CCACHE_DISABLE=1 make npu-test
```

当前回归通过项：

```text
SOC_ADDR_MAP_PASS
NPU_CTRL_PASS
NPU_DMA_PASS
AXI_2M1S_ARBITER_PASS
NPU_FC_ENGINE_PASS
NPU_SERVICE_PASS
NPU_SERVICE_DROP_PASS
NPU_RESULT_MMIO_PASS
NPU_SYSTEM_PASS
```

已覆盖：

- signed INT8 FC 和 argmax/margin；
- AXI ready/valid 暂停；
- RRESP、RID、RLAST 错误；
- 双路公平调度；
- 队列满和完整批次淘汰；
- 正常/淘汰 batch 的 bank 释放；
- FIFO 满保护、peek、POP 和非空 IRQ；
- CPU/DDR 双时钟 FIFO 复位释放。

正式项目还需要补测：

- B 的 reference vector 逐层/最终结果比对；
- 最终 RGB565 到 INT8 转换逐元素比对；
- `Hfpga_soc` 顶层闭环；
- 最终 INT8 bank 地址和真实模型容量；
- CPU MMIO/IRQ 软件流程；
- 双路持续提交和最终地址下的 DDR 竞争。

## 11. 当前任务状态和下一步

| 任务 | 状态 |
|---|---|
| A1 能力和接口 | V1 草案已完成，待模型和三方审批 |
| A2 双路批次管理 | 独立 RTL 和仿真基本完成 |
| A3 DDR 数据搬运 | V1 已完成，待最终 bank/模型接入 |
| A4 按模型配置运行 | 模型包解析、多层执行器未完成 |
| A5 计算硬件 | FC V1 完成；是否扩展 CNN 待 B 模型确认 |
| A6 结果/bank 管理 | 独立 RTL 和仿真基本完成，待整机接入 |
| A7 MMIO/FIFO/IRQ | 独立 RTL 和仿真基本完成，待 SoC 接入 |
| A8 验证和交接 | 独立回归完成，待 reference vector 和整机闭环 |

后续顺序：

1. B 提交模型和 reference vector。
2. A+B 确认模型是否兼容当前 V1，或确定需要增加的算子/量化能力。
3. zzx 发布模型输入标准、DDR/MMIO 地址、AXI/IRQ/时钟复位连接。
4. A 完成最终模型适配和 bit-exact 验证。
5. zzx 完成 INT8 转换和 `Hfpga_soc` 接入。
6. 三方完成静态数据、单路、双路和持续任务仿真。

## 12. 接口变更要求

输入布局、量化、batch 字段、结果位域、DDR/MMIO 地址、AXI ID、时钟复位或 IRQ 发生变化时，必须提交变更记录，说明：

- 新旧版本和修改原因；
- 受影响的 RTL、模型工具、CPU 文件；
- 是否兼容旧版本；
- 需要重新执行的测试；
- 需要 B/zzx 修改的端口和文件。

本说明中的最终有效版本必须与以下版本同时记录：

```text
NPU capability version
NPU interface version
model input/model package version
DDR/MMIO map version
reference vector version
RTL and CPU firmware version
```
