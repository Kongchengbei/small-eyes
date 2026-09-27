# Flash → DDR → CPU smoke 实现状态

**实板编程状态更新（2026-09-26）**：一颗 Outer Flash 已经通过 PDS JTAG 桥接流程擦写并多次 Verify 成功，第二颗未烧写。实际扫描 ID `0x0B4018`，软件以 `xt25f128` 自定义项和 WINBOND/W25Q NOR 兼容模板识别。烧写完成不代表断电自启动、DDR 用户数据读回或 CPU 流水灯已有实板成功结果；完整步骤见[烧写记录](PG2L200H_Flash烧写与DDR启动实板记录.md)。下文此前写的 W25Q128JV 是旧型号推断，现以扫描 ID/软件配置为准。

用户已确认实物 FPGA 为 PG2L200H，板上 DDR 官方 BIST 已通过。本阶段因此验证的是“镜像字节能否按顺序搬到 DDR、校验通过后 CPU 能否从 DDR 取指”，不重复 DDR 电气或 BIST 测试。

## 当前实现

`soc/flash_boot/flash_ddr_loader.v` 是最小搬运器：等待 DDR 初始化，接收 Flash 字节并每 4 字节组成小端 RV32 word，写入 DDR 后逐字读回比较。`spi_flash_byte_reader.v` 以 SPI X1、模式 0、`03h + 24-bit address` 逐字节读取；`flash_ddr_boot.v` 将 reader、loader、DDR 单请求通道仲裁和 Flash 外部信号接在一起。loader 只在最后一次 DDR readback 响应被消费后报告 `boot_done`。参数检查和超时/响应类型/readback错误都锁存 `boot_error` 与错误码。

当前集成目标从 PG2L200H `GTP_CFGCLK` 专用配置时钟资源输出 SPI SCK，不能将 H13 当作普通顶层 SCK 端口约束。`Hfpga_soc` 中启动状态机的 DDR 初始化输入是 DDR IP 的硬件 `ddr_init_done`；loader 是 FPGA 硬件 FSM，不是 CPU 汇编程序。CPU 复位入口设为 `DDR_BASE` (`0x80000000`)。`core_active` 仍表示 DDR 初始化状态，不表示 Flash boot 成功。虽然 RTL 有 `boot_error/boot_error_code`，当前尚未把它接到现有 ILA，因此不能依赖已有板上 ILA 观察启动错误。

| 错误码 | 含义 |
|---:|---|
| 1 | 参数无效：镜像长度为零或非 4 字节倍数、DDR 起始地址未对齐、Flash 24-bit 地址溢出、DDR 地址范围越界，或 timeout 参数小于 1 |
| 2 | DDR 初始化等待超时，或初始化完成后 DDR init 状态丢失 |
| 3 | Flash 请求或数据响应超时 |
| 4 | DDR 请求或响应超时 |
| 5 | DDR 响应类型错误 |
| 6 | DDR 读回数据不匹配 |

tracked 测试程序 `test/running_led_test.dat` 为 14 个 32-bit word / 56 bytes。被忽略的 `test/running_led_test.bin` 为 56 bytes，小端前 16 字节为 `B7 02 00 40 93 82 02 20 13 03 10 00 B7 EE 16 00`。目标 DDR 地址 `0x80000000`，LED MMIO 地址 `0x40000200`。

最终回归由集成测试代理报告通过。`make flash-ddr-boot-test` 覆盖真实 `test/running_led_test.dat`（56 bytes）：延迟 DDR init（100050 cycles）、readback mismatch code 6 且 CPU 保持 reset、CPU 运行后 LED MMIO 写入 1（结束 PC `0x8000001c`）、ready-drop 后 code 2 且 Flash clock disable、init 恢复不能解除错误锁存，以及共同 reset 后再次完成 56-byte 读取和 DDR 写入。旧 `make flash-boot-smoke` 仍运行 `sim/tb_flash_ddr_smoke.sv` 中四指令 `0x5a` 镜像，成功/失败两支 PASS；它不是 56-byte 测试。`make spi-flash-reader-test` 通过；`make lint` 对 Htop、`flash_ddr_boot`、`ddr_axi_bridge` 通过。

这些是 testbench、行为模型和局部 lint 结果。wrapper、reader、loader 与 `ddr_axi_bridge` 的 Icarus compile PASS；`iverilog -i` 对 `Hfpga_soc` 的 parse/partial elaboration PASS，但它会忽略缺失模块，不能视为完整顶层 elaboration。结果不覆盖 vendor primitive、真实 DDR PHY、实际管脚约束、Windows PDS 综合/布局布线或实板。PDS 中列出 RTL 源文件只是工程登记，不等于 PDS 编译或生成位流成功。

运行 smoke test：

```sh
make flash-boot-smoke
```

该 target 保持四指令 smoke 镜像：它应向 LED MMIO 写 `0x5a`，失败分支破坏读回并检查 code 6。56-byte `running_led_test.dat` 的 CPU 集成测试由 `make flash-ddr-boot-test` 运行，预期 LED 写 1。

## Flash 板级接线与当前验证边界

PDS 工程源文件表已登记本次三个启动模块。固定 Flash 用户区地址为 `0x00A00000`（PDS user address `00a00000`），RTL 以 SPI X1 和 24-bit 地址读取。本次 `.sbit` 为 9,188,552 bytes，小于 `0xA00000`；最新 `.sfc` 为 10,485,816 bytes。任何 RTL 或 `FLASH_BASE` 更新后必须重生成 `.sbit` 再重新打包；若只换同地址同长度的程序，无需改 loader。当前默认 `IMAGE_BYTES=56`，程序长度变化时需同步改参数并重新生成 bitstream。实板已证明单颗 Outer Flash 擦写及 Verify 成功，但没有上电运行证据。

后续需要断电上电，核实配置、DDR init、Flash→DDR 搬运和 CPU LED 行为。封装 pin plan 不能单独证明 PCB 上 Flash 信号的连接；当前采用用户选择的 200H pin plan 不构成走线实测。PDS 主机 ConnectToServer 用于扫描/烧写；预期断电上电自主启动不依赖该连接。当前 X1 `03h` 读取不依赖双 Flash 交织或 QE；这些属于未来 X8/QSPI 扩展核查项。

本次是固定镜像的第一版，不包含通用数据头、CRC、多镜像和 AI 权重。NPU engine 尚未实现，也不阻碍最小 CPU 流水灯启动。当前记录没有确认 PDS 中配置引脚释放设置的具体取值；J10 是 SD 卡槽，不是自定义 JTAG 扩展接口。
