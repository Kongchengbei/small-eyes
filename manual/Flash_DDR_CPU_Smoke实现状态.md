# Flash → DDR → CPU smoke 实现

用户已确认实物 FPGA 为 PG2L200H，板上 DDR 官方 BIST 已通过。本阶段因此验证的是“镜像字节能否按顺序搬到 DDR、校验通过后 CPU 能否从 DDR 取指”，不重复 DDR 电气或 BIST 测试。

## 当前实现

`soc/flash_boot/flash_ddr_smoke_loader.v` 是与板级 Flash PHY 解耦的最小搬运器。它等待 `ddr_init_done`，按字节地址向 Flash 源请求镜像数据，每 4 字节组成一个小端 RV32 word；随后通过单请求 DDR 接口写入固定目标地址，并逐字读回比较。所有字节校验通过才拉高 `boot_done`。参数检查拒绝空长度、非 4 字节长度、非对齐 DDR 起始地址、Flash 24 位地址溢出和超出 `DDR_LIMIT` 的目标范围。初始化/Flash/DDR 超时、DDR 响应方向不符和读回不一致都会拉高 `boot_error` 并锁存错误码。

| 错误码 | 含义 |
|---:|---|
| 1 | 镜像长度为零或不是 4 字节倍数 |
| 2 | 等待 DDR 初始化超时 |
| 3 | Flash 请求或数据响应超时 |
| 4 | DDR 请求或响应超时 |
| 5 | DDR 响应类型错误 |
| 6 | DDR 读回数据不匹配 |

测试镜像是 4 条 RV32I 指令，按小端字节放在 Flash 行为模型中：`lui x1, 0x40000; addi x2, x0, 0x5a; sw x2, 512(x1); jal x0, 0`。写入 DDR 的地址为 `0x8000_0000`，最后一条指令原地循环；第三条指令应向 SoC 的 LED MMIO 地址 `0x4000_0200` 写入 `0x5a`。仿真使用真实 `Htop` CPU、行为 Flash、共享 DDR 模型以及启动期间由 loader 独占 DDR 的仲裁。成功场景逐字读回 DDR，并检查 CPU 复位释放及其 LED 写事务；故障场景人为破坏 DDR 读回数据，检查错误码 6 且 CPU 继续复位。

运行：

```sh
make flash-boot-smoke
```

预期输出包含 `FLASH_DDR_CPU_SMOKE_PASS ... LED=0x5a ...` 和 `FLASH_DDR_FAILURE_PATH_PASS code=6`。

## 硬件仍未接通

当前 loader 只定义字节请求/响应协议，没有板级 QSPI 控制器，也没有被实例化到 `Hfpga_soc`。仿真中的 Flash 地址 `0` 只是行为模型地址，不能当作 PDS 用户数据区地址。当前没有生成或上板验证新的 SoC 位流。

接入实板前还需从 PG2L200H 配置指南、盘古 676 底板原理图和 PDS 工程确认：配置完成后如何通过 GTP 配置时钟资源访问 Flash；FCS/FCS2 与 D0–D7 在此核心板上的实际连接；当前启动/下载配置宽度；用户数据区在 PDS 中的地址语义；双 Flash 的逻辑字节交织和数据拼接规则；以及 PDS 对 QE/读取命令的处理。以上信息未确认前，不在约束或 RTL 中固定 X8 映射、Flash 管脚或 Flash 用户区起始地址。

硬件接入还需要把板级 Flash 读出器接到 loader 字节接口，在 DDR bridge 前加入启动请求仲裁/响应路由，并让 CPU reset 条件包含 `boot_done` 与 `boot_error`。当前 `Hfpga_soc` 的 CPU 仍只等待既有复位/JTAG条件，故本实现的 CPU 释放行为只在 smoke test harness 中验证。后续先向 PDS 用户数据区写入四个已知字节并确认实际读出顺序，再连接启动 loader；这一步验证搬运链路，不再是 DDR BIST。
