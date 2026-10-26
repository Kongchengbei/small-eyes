# CPU 存储配置与执行策略差异说明

日期：2026-10-25。用户已授权直接实施第一批，不再等待逐项 review。本文件名保留，方便已有链接继续访问。

用户要求：CoreMark 跑分和日常工作使用同样的 CPU 优化，menuconfig 用于选择存储系统和外设，不用于设置跑分专用的执行优化。

## 本次已修正

乘法提前启动不再受 BRAM_MODE 控制：移除 `Hexu.MUL_EARLY_START` 参数，`Htop` 不再按模式传入开关，`Hidu.id_mul_early_ready` 只检查 EX/MEM 数据依赖。两个存储配置均通过相同的指令类型、操作数就绪和流水线握手条件决定是否提前启动。

## 原有执行策略差异与本轮修改

| 位置 | 原有差异 | 本轮处理 |
|---|---|---|
| `Hidu.id_mem_forward_consumer` | 只有 BRAM 模式允许一部分紧邻 load 的消费者携带 pending 标记进入 EX | 两种模式均允许相同消费者携带 pending；EX 等待匹配 MEM 数据，并在背压下保存返回值 |
| `Hidu.id_br_src1/id_br_src2`、`id_br_consumer` | BRAM 分支使用普通 EX/MEM 前递；DDR 分支使用 RF/WB 和 MEM 非 load 结果，并采用更保守的停顿 | 两种模式均使用普通 EX/MEM 前递；保留 EX load 匹配和 MEM load 等待停顿；移除按模式增加的额外停顿 |

`Hidu` 不再接收 `BRAM_MODE` 参数。两种模式均已通过 Htop 静态编译。执行策略统一后的 PDS 结果按独立候选记录；静态编译不能替代时序和实板验收。

新增 RAS 和第二批除法早退也不受 `BRAM_MODE` 控制。进度和实际检查结果见 [分批实施记录](CPU分批优化实施记录.md)。

## 存储接口相关差异，需与执行优化区别审查

| 位置 | 当前差异 | 审查重点 |
|---|---|---|
| `Htop` 存储实例 | BRAM 配置使用 IMEM/DMEM；DDR 配置使用 ICache/DCache 和 AXI | 属于存储系统选择，CPU 指令语义和执行优化应保持一致 |
| `Hifu.CONTINUOUS_FETCH`、`Htop` 取指请求和 BTB PC 关联 | 根据 BRAM 固定返回时序与 cache 接口时序选择不同取指控制 | 需要确认哪些差异是协议必需，哪些可以统一为通用 ready/valid 控制；统一时保留请求、响应、预测 PC 的对应关系 |

上述存储实例和取指接口差异仍保留。它们不代表本轮执行优化仅在跑分时开启，也不能表述为所有前端控制已完全一致。不增加固定程序地址或 CoreMark 数据专用路径，不自动改变频率，不运行 testbench，不自动提交、推送或烧录。
