# PG2L200H Flash 烧写与 DDR 启动实板记录

记录日期：2026-09-26。本文记录本次实际完成的单颗 Outer Flash 编程，并说明后续由 FPGA 启动硬件完成的 Flash→DDR→CPU 链路。这里的“完成”限于本文逐项列出的工具日志和用户实板操作；没有把尚未观察到的上电自启动结果写成成功。

## 结果摘要

- 实物 FPGA 型号已确认是 **PG2L200H-FBB676**，当前采用用户选择的 200H 引脚方案：`FCS_N/CS=P18`、第二片选 `FCS2_N=F25` 保持闲置，`MOSI=R14`、`MISO=R15`、`WP_N=P14`、`HOLD_N=N14`，专用配置时钟 `GTP_CFGCLK=H13`。这是选定的 pin plan；封装功能表不能单独证明 PCB 走线，本记录不声称已实测 PCB 连线。
- Boundary Scan 扫描到 Outer Flash 的实际 ID 为 `0x0B4018`。PDS 中通过 **Add Flash** 添加自定义 `xt25f128`，使用 WINBOND/W25Q NOR 兼容模板；容量按 128 Mbit，即 16 MiB 处理。`W25Q128JV` 是手册中的可选型号，不能据此称它为本次扫描到的实物型号。
- 本次只选中并烧写、校验了**一颗 Outer Flash**。第二颗 Flash 未烧写；这不是 X8，也没有双片交织或双片数据校验证据。
- 用户实板日志：擦除 35.5 秒，编程 170.6 秒，Verify 成功 11.0 秒，随后再次 Verify 成功 10.8 秒；操作起始地址为 `0`。这证明所选单颗 Outer Flash 的本次编程与校验完成。
- 仓库中 `test/running_led_test.bin` 被 Git ignore；tracked 的 `test/running_led_test.dat` 是 14 个 word。按每个 word 低字节先输出的小端转换得到 56-byte `.bin`，首 16 bytes 为 `B7 02 00 40 93 82 02 20 13 03 10 00 B7 EE 16 00`；已比对转换结果及 `.sfc` 在 `0x00A00000` 的载荷。
- 尚无用户确认的断电后自主配置/启动、DDR 搬运读回或 CPU 流水灯实板成功结果。RTL/仿真证据不能替代这些实板观察。

## JTAG 到 Flash 的烧写流程

1. 在 PDS 主机连接服务器（**ConnectToServer**），再用 **Boundary Scan → FPGA → Scan Outer Flash** 扫描 Outer Flash。实际扫描 ID 为 `0x0B4018`。左侧 **SPI Flash Configuration** 是另一条直接 SPI 配置路径，不应与本次的 JTAG 桥混淆。
2. 使用 **Add Flash** 登记自定义 `xt25f128` 器件，选择 WINBOND/W25Q NOR 兼容模板，按 128 Mbit（16 MiB）配置。此名称/模板是软件识别设置，不是对芯片丝印型号的额外确认。
3. 用 PDS **Convert File** 生成烧写包：FPGA 位流 `.sbit` 起始地址为 `0`；56-byte 程序 `running_led_test.bin` 起始地址为 `0x00A00000`。RTL `Hfpga_soc` 参数 `FLASH_BASE` 必须与用户程序包地址一致；当前默认值为 `24'hA00000`。本次 `.sbit` 为 9,188,552 bytes（`0x8C34C8`），最新 `.sfc` 为 10,485,816 bytes；载荷已比对。若修改 RTL 或 `FLASH_BASE`，先重生成 `.sbit` 再重打包；若只换同地址、同长度的软件，则不必重写 loader。当前顶层 `BOOT_IMAGE_BYTES=56`，该值传给 `flash_ddr_boot`/loader 的 `IMAGE_BYTES` 参数；独立 `flash_ddr_loader` 模块的参数默认值是 4。程序长度变化时需同步修改顶层参数并重新生成 bitstream。
4. 在选中的 Outer Flash 上执行 **Assign New Configuration File** 并加载 `.sfc`，然后依次 **Erase → Program → Verify**。用户记录的一轮耗时为 35.5 秒、170.6 秒、11.0 秒；之后再次 Verify 用时 10.8 秒并成功，起始地址为 `0`。本地工程日志还记录同一 ID `b4018` 的另一轮擦写和校验成功。这些都是同一选中器件的操作记录，不能证明第二颗写入。

## 上电后的 RTL 启动链路

Flash 编程结束并不等于已经证实上电启动成功。设计预期的运行顺序如下：

```text
板上配置流程从 Flash 地址 0 配置 FPGA
        ↓
Hfpga_soc / DDR IP 完成 DDR 初始化（硬件 ddr_init_done）
        ↓
flash_ddr_boot 同步初始化完成，开启 GTP_CFGCLK 输出 SPI SCK
        ↓
单颗 Flash：SPI X1 / 模式 0 / 03h / 24-bit 地址
从 FLASH_BASE=0x00A00000 逐字节读取 56 bytes
        ↓
flash_ddr_loader 每 4 bytes 按小端组装 32-bit word
        ↓
写入 DDR_BASE=0x80000000，并逐 word 读回比较
        ↓
最终读回响应通过后 boot_done 生效，DDR 通道交给 CPU
        ↓
CPU 从 reset PC=0x80000000 取指，程序写 GPIO/LED MMIO=0x40000200
```

`flash_ddr_loader` 是 FPGA 中的硬件状态机，不是 CPU 汇编。`ddr_init_done` 是 DDR IP 的硬件初始化完成信号。`flash_ddr_boot` 在第二片选上持续输出 inactive 高电平（`flash_cs2_n=1`）。PDS 主机连接 `ConnectToServer` 用于扫描和烧写期间的操作；预期板子上电后的 FPGA 自主启动不依赖该 PDS 主机连接，但本次还没有断电上电实测结果。预期 LED 次序为 LED2→LED1→LED3→LED4；LED0 只表示 DDR init done，不是 Flash 搬运完成指示。

本次复核的 `make spi-flash-reader-test`、`make flash-ddr-boot-test`、`make flash-boot-smoke` 和 `make lint` 均通过。仿真覆盖 100050-cycle DDR init 延迟、56-byte/56-read 搬运及逐 word readback、CPU 运行后 LED MMIO 首次写入 1（PC `0x8000001c`）、错误码 6、ready-drop 错误码 2 和 reset recovery。这些是行为模型仿真证据，不能写成实板 DDR 搬运或流水灯已经验证。

## 引脚资料与证据边界

新增的两份资料位于 `manual/`：

- [PG2L200H-FBB676 官方封装资料.pdf](PG2L200H-FBB676%20官方封装资料.pdf)：可查 PG2L200H-FBB676 球位及复用功能；不能单独证明 PCB 上实际连接到了哪颗 Flash。
- [Logos2 Family Product GTPs User Guide.pdf](Logos2%20Family%20Product%20GTPs%20User%20Guide.pdf)：用于查 `GTP_CFGCLK`、`GTP_INBUF` 等 Logos2 原语；不是 200H 开发板的 PCB 接线手册。

当前采用的 pin plan 源自用户对芯片型号和 200H 方案的确认。若后续要证明板级网络对应关系，仍需原理图、PCB 网络资料或电气测量。此次 Flash ID 扫描和编程校验没有提供第二颗 Flash 已写入、配置脚释放状态、断电自主启动、DDR 内容实测读回或 CPU LED 实测的证据。
