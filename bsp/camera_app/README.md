# Camera 探活固件

本目录保存 `manual/整体目标.md` Camera 第一至五阶段的固件：UART 调试库、
物理 CAM1 的 OV5640 SCCB 芯片 ID 探测、640×480 RGB565 初始化，以及 DVP
接收状态、帧数、像素数、行数和错误标志读取。

## 构建

在 WSL/Linux 中执行：

```sh
make -C bsp/camera_app clean all
```

输出文件为 `camera_uart_debug.bin`。当前二进制长度为 **4836 字节**，必须与
`Hfpga_soc.BOOT_IMAGE_BYTES` 保持一致，并放在 Flash 地址 `0x00A00000`。
程序长度变化后必须重新生成 FPGA 位流；不能只替换一个长度不同的 bin。

## 串口设置与预期输出

优先使用资料包中的 `sscom5.13.1.exe`，设置为 `115200 / 8-N-1 / 无流控`。
MobaXterm 作为备选。真实 OV5640 工作正常时预期输出：

```text
=== Small Eyes Camera Bring-up ===

UART TEST OK
DDR INIT OK
CPU CLOCK   : 90000000 Hz
UART MMIO   : 0x40000000
SYSTEM READY
CAM1 probe...
CAM1 SCCB    : OK
CAM1 PIDH    : 0x00000056
CAM1 PIDL    : 0x00000040
CAM1 OV5640 : DETECTED
CAM1 RESET  : OK
CAM1 CONFIG : 640x480 RGB565
REG WRITE   : OK
CAM1 START  : OK
CAM1 STATUS : 0x0000001F
CAM1 FRAMES : 1
CAM1 PIXELS : 307200
CAM1 LINES  : 480
CAM1 ERRORS : 0x00000000
```

如果出现 `NO ACK`，优先检查 CAM1 供电、FMC 插接、RESETB、SCL/SDA 上拉和
引脚约束；如果有 ACK 但 ID 不是 `0x5640`，再检查读事务和器件型号。

## 离线验证

```sh
make camera-sccb-gpio-test
make camera-dvp-rx-test
make camera-sccb-fw-test
```

第一项检查复位默认值、开漏输出、采集使能和 SDA 输入同步；第二项检查
RGB565 高字节拼接、正常帧计数和奇数字节/尺寸错误；第三项用真实 CPU RTL
执行 bin，由 OV5640 模型检查 250 项配置和关键寄存器回读，再输入完整
640×480 DVP 帧并逐字节核对 UART 输出。所有测试都不启动 PDS，也不访问实板。

Camera MMIO 从 `0x40000300` 开始：`+0x00/+0x04` 为 SCCB 与采集控制/状态，
`+0x08` 为跨时钟域快照请求，`+0x0C/+0x10/+0x14/+0x18/+0x1C` 分别为冻结
的帧数、像素数、PCLK 数、错误标志和行数。统计由 PCLK 域一次性冻结，CPU
只读取同一份快照，不能逐位同步异步计数器。
