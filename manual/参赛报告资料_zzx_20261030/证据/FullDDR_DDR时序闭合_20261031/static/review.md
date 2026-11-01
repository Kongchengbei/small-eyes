# Batch 04 只读复审

审查范围：对比 `build/ddr_wns_20261031/batch04_before/soc/Hnpu_cnn_engine.v` 与 `soc/Hnpu_cnn_engine.v`，以及对应的 `Hrgb565_int8_lane.v`。未修改 RTL/约束/配置；未运行测试平台、仿真、vvp 或 PDS。

## 结论

在所查的范围内没有发现可确认的逐拍功能反例。`weight_base` 对可见 16 位模型地址保持模 65536 等价；CONV/POOL 的越界读仍由同一地址阶段采样的 `tensor_valid_q` 屏蔽；公共元数据谓词在消费前已寄存，检查错误优先级保持原顺序；lane 的 pending/base 计数输出与旧饱和计数器逐周期等价，`clear_errors` 不清除该计数器的行为也未改变。

复审后补查了综合网表映射：padding 地址无条件送入 `tensor_a/b` 的动态读索引，而实际 PDS 映射将其接到有效 RAM 地址范围；本地网表证据见下文。故之前提出的“越界索引实际综合语义未确认”已由该映射证据消除。该检查仍不是板上功能验证。

## 逐项核查

### 权重行地址

- `model_read_addr` 是 16 位寄存器（`soc/Hnpu_cnn_engine.v:171`）。旧 CONV 地址通过 `mul_u32_u16_no_dsp(out_c[15:0], layer_kernel_size)` 计算；该函数第二操作数只有 16 位，因此其低 16 位等于 `out_c * layer_kernel_size[15:0] mod 65536`。新实现从 descriptor 的 32 位 `layer_weight_offset` 初始化 `weight_base`，每个非末输出通道加完整 32 位 `layer_kernel_size`（初始化 `:1425`，推进 `:1772`）。最终赋给 16 位 `model_read_addr` 时只保留低 16 位，所以每一行的新旧地址均为 `layer_weight_offset + out_c * (layer_kernel_size mod 65536) mod 65536`。`layer_kernel_size` 的高 16 位不会导致可见地址不等价；仅以“旧乘法器参数是 16 位”不能构成反例。
- FC 同理：`layer_in_c` 与旧乘法第二操作数均为 16 位；新实现逐行加 `layer_in_c`（`:1973`），最终地址同样截为 16 位（`:171`）。层载入时重设基址，末输出不再推进（`:1425`、`:1766-1774`、`:1968-1975`），覆盖层边界和末行。
- 本检查只确认地址的低 16 位等价，不代表超出 `model_mem` 实际长度的地址有定义；权重区域有效性取决于原有 descriptor/header 检查。

### CONV/POOL padding 读有效位配对

- 读地址与有效位在同一状态组合逻辑里由同一组坐标/偏移产生：CONV `:799-840`、POOL `:846-866`；两边均在 `ST_WEIGHT_PRIME` / `ST_CONV_MAC` 或 `ST_POOL_PRIME` / `ST_POOL` 的时钟沿分别采样 BRAM 读数据（`:898-904`）及 `tensor_valid_q`（`:887-896`）。因此在下一周期 MAC/POOL 消费时，`tensor_read_data` 与 valid 位对应前一沿呈现的地址。
- 首元素：`ST_WEIGHT_PRIME` / `ST_POOL_PRIME` 设定首 tap，采样首数据和 valid；随后进入 MAC/POOL 才消费。最后 tap：消费发生在 MAC/POOL 终止判断的同一状态沿；CONV 最终乘积由 `ST_CONV_MAC_FLUSH` 退休（`:1689-1734`），POOL 终止窗口时先将本周期的有效 tap 合并到 `pool_next` 再排队写出（`:1803-1824`）。prime/flush/drain 中不会把下一 tap 的 valid 误用于前一 tap。
- CONV 无效 tap 令 `mac_product<=0`（`:1694-1702`）；POOL 无效 tap 不更新 `pool_next`（`:1803-1808`）。`tensor_valid_q` 在其他状态保持，但这些状态不会消费它。连续输出位置/通道重新经过 prime 状态重新采样。
- 下一层 bank：CONV/POOL 输出写入 `~tensor_active`（`:1746-1748`、`:1818-1821`）；末次写使能在 `ST_WRITE_DRAIN` 周期由 RAM 写入，之后进入 `ST_LAYER_NEXT` 再翻转 `tensor_active`（`:1680-1682`、`:2026-2033`）。故下一层描述符读取前，末次写已提交，目标输出 bank 翻转后成为活动输入 bank。
- 上述是 RTL 时序/门控审查。未运行仿真或 PDS；对越界动态读索引的综合 RAM 语义仍需工具或器件文档证实（见结论中的风险）。

### 元数据公共谓词及错误优先级

- `meta_common_dimensions_ok` 与 `meta_common_capacity_ok` 在 `ST_METADATA_ARITH` 采样（`:1491-1508`）；`meta_common_descriptor_ok` 在下一状态 `ST_METADATA_COMPARE` 采样（`:1537-1554`）；随后才进入 `ST_CHECK`（`:1534`、`:1571`）。descriptor 和 `layer_*` 在 `ST_LAYER_FETCH` 锁存，直到检查结束未见中途覆盖（`:1403-1437`）。因此检查使用的寄存谓词在消费前稳定。
- 条件与旧 `ST_CHECK` 中的公共逻辑表达式一致；带符号的 capacity 比较显式保持 `$signed(...) > MAX_TENSOR_BYTES`（`:1504-1508`）。此前先判 unsupported op，再判公共 descriptor/shape，之后再判各操作特有条件；现顺序相同（`:1580-1638`）。CONV 内仍先判量化参数再判几何/权重字节，FC、POOL 等分支次序也未因此改动。
- 只读审查未发现因预采样引入一拍陈旧值或改变错误码优先级的反例。

### lane bad-release 计数

- 旧实现每个时钟沿执行 `if (release_valid && !release_hit) bad_release_count<=sat_inc(bad_release_count)`；新实现用 `bad_event_q` 暂存本沿事件、`bad_count_base` 在下一沿提交前一事件，并组合输出 `bad_event_q ? sat_inc(bad_count_base) : bad_count_base`（`soc/Hrgb565_int8_lane.v:165-175,438-446`）。
- 对任意连续/间隔事件，时钟沿后输出均为“此前已提交事件数 + 当前 pending 事件”；这与旧寄存器在同一沿后递增的可见值一致。饱和时 `sat_inc(0xffffffff)` 保持原值；base 与投影均饱和，连续坏消息不会回绕。
- 异步复位同时清零 base 与 pending 位（`:370-385`）。`clear_errors` 仅清 `error`（`:401-404`），旧版对 bad count 也不响应 `clear_errors`；该行为保持一致。

## 验证边界

本结论来自静态 RTL/diff、逐拍时序推理及已有 PDS 网表映射检查，没有运行 testbench、仿真、形式验证或新的 PDS 流程。所有参数/模型格式组合下的动态可达性和板上功能行为未由此证明。

## PDS RAM 映射补充证据

根代理检查当前 PDS 综合网表的结果记录在 `build/ddr_wns_20261031/batch04/ram_mapping.json` 与 `build/ddr_wns_20261031/batch04/ram_mapping.txt`：8 个 `tensor_a/b_0..3` RAM 实例的 `ADDRB` 均只连接 `tensor_read_addr[13:0]`，`WEB` 固定为 0；对应源网表完整层级路径收录于 JSON。该工程的 `MAX_TENSOR_BYTES=16384`，因此14位地址覆盖整个实际 RAM 深度。越界 padding 坐标不会以16位原始索引访问 RAM，而是经综合网表地址截位映射到 RAM 内地址；其读值仍由原有同拍 `tensor_valid_q` 屏蔽，且读端没有写使能或外部访问副作用。此证据确认当前综合网表的 RAM 地址连线与有效位门控关系，不替代板上或端到端模型结果验证。
