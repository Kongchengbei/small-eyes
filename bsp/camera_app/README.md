# Camera 探活固件

本目录保存 Camera 调试固件：UART 调试库、物理 CAM1 的 OV5640 SCCB 芯片 ID
探测和 640×480 RGB565 初始化，并通过 CAM1 DMA 将完整帧写入 DDR。CPU 读取一致
快照、展示当前 RGB565 样本，重新计算完整 DDR 帧的 uint16 像素和并释放完成缓冲区。

## 构建

在 WSL/Linux 中执行：

```sh
make -C bsp/camera_app all
```

默认 `all` 会生成本地和远程两套固件，以及兼容文件名 `camera_uart_debug.bin`
（它始终是本地版本的副本）：

| 固件 | UART TX 路由 | 输出文件 |
| --- | --- | --- |
| local（默认） | FPIOA[0]，C24 | `camera_uart_debug_local.bin`、`.elf`、`.dump`、`.map` |
| remote | FPIOA[31]，AB26 | `camera_uart_debug_remote.bin`、`.elf`、`.dump`、`.map` |

可单独执行 `make -C bsp/camera_app local` 或 `make -C bsp/camera_app remote`。
`uart.h` 的 `CAMERA_UART_TX_FPIOA` 默认值为 0，也可通过编译参数 `-D` 覆盖。
固件启动时先将 FPIOA[0] 和 FPIOA[31] 的 UART mux 都设为 0（NIO/高阻），再只
使能所选 TX 引脚，避免旧远程位流同时从两个候选脚驱动。

每个 `.bin` 都必须单独按其实际字节长度配置 loader，Flash 地址为 `0x00A00000`。
烧录时不要使用工程中此前的 6944 字节固件或旧 SFC 镜像；它们不包含
本次修正。当前 `camera_uart_debug.bin` 是新的 local 副本，不是旧版本。
顶层 `BOOT_IMAGE_BYTES` 已改为 6956，必须由用户重新生成位流及烧录镜像。
当前构建结果：

| 固件 | 长度 | SHA-256 |
| --- | ---: | --- |
| local | 6956 字节 | `b8040bdc94718d4d35798f6e60d46e95a4ed01df6bd4b2f8394b6a6a4b4f8c0a` |
| remote | 6956 字节 | `35f321ce63f111fd67010c0a1758b4b8660708af1f883e9f2046a4db14dfcc04` |

当前 Camera 软件将 `0x4740` 配置与回读期望改为 `0x20`，回读 mask 仍为 `0x23`。
按本地应用指南第27页，这是 VSYNC 低时数据有效、HREF 高时数据有效、PCLK
下降沿更新，对应当前 RTL 的上升沿采样。上一轮 `0x23` 的极性解释已撤回；
资料术语存在冲突，仍需用户实板复测，不以模型通过宣称实板成功。
错误报告保持首次/错误签名变化时输出完整快照，相同错误在无帧轮询中定期汇总。
当前原始程序也为
6956 字节；构建会对更短镜像尾部填零、超长直接失败，不裁剪。
若板上已经是 UART 修正后、loader=6956 的位流，本次只需更新匹配的软件烧录
镜像，无需因软件修改重新综合。详见
[HREF 修正与错误报告记录](../../manual/CAM1_HREF极性修正与错误输出限频.md)。

## 串口设置与预期输出

另有独立 GPIO 线路诊断程序：`make -C bsp/camera_app gpio-test`，生成
`camera_gpio_test_local.bin` / `camera_gpio_test_remote.bin`，均填充到当前 loader
要求的 6956 字节；不会替换原 Camera bin。它保持摄像头复位，只翻转开漏 SCL/SDA，
不初始化或采图。详细步骤见
[CAM1 GPIO 最小翻转测试](../../manual/CAM1_GPIO最小翻转测试.md)。

优先使用资料包中的 `sscom5.13.1.exe`，设置为 `115200 / 8-N-1 / 无流控`。
MobaXterm 作为备选。真实 OV5640 工作正常时预期输出：

```text
=== Small Eyes Camera Bring-up ===

UART TEST OK
DDR INIT OK
CPU CLOCK   : 70000000 Hz
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
CAM1 DMA    : ENABLED
CAM1 START  : OK
CAM1 STATUS       : 0x00000A2F
CAM1 FRAME        : 1 (DVP 1)
CAM1 LINES        : 480 (current 480)
CAM1 PIXELS       : 307200 (current 307200)
CAM1 BYTES        : 614400 (current 614400)
CAM1 FIFO LEVEL   : 0
CAM1 FIFO MAX     : <peak>
CAM1 OVERFLOW     : 0 FIFO_ERROR=0x00000000 DVP_FLAGS=0x00000000
CAM1 DMA BUSY     : 0 STATUS=0x00000105
CAM1 DMA DONE     : 1
CAM1 DMA ERROR    : 0 CODE=0x00000000
CAM1 WRITE BUFFER : 0xFFFFFFFF
CAM1 READY BUFFER : 0x00000001 LAST=0x00000000
CAM1 FRAME ADDR   : 0xB8000000
CAM1 CHECKSUM     : sum16 (not CRC32) <32-bit sum>
CAM1 RGB565 SAMPLES: <8 pixels>
CAM1 DDR CHECKSUM : sum16 (not CRC32) <32-bit sum> MATCH=YES
CAM1 RELEASE MASK : 0x00000001 RELEASED
```

快照中的完成帧计数、尺寸、地址和 checksum 来自同一 DMA 完成描述；DVP 帧计数
另行显示。`CHECKSUM` 是像素 `uint16_t` 求和后按 2^32 回绕，不是 CRC32。CPU
从 `FRAME ADDR` 读取 8 个 RGB565 样本，并扫描完整的 614400 字节做 DDR checksum
对比。ready 缓冲区在校验期间保持锁定，完成后通过 `BUFFER_RELEASE` mailbox 归还，
固件随后继续轮询和处理后续帧。快照/释放超时和 DMA、FIFO、DVP 错误均输出状态及错误码。
没有完成帧时，首次成功快照及后续每 1000 次无帧轮询也会打印状态，便于检查
有 PCLK 却没有帧边界的情况；此时地址/槽号为无效值，不会读取 DDR 图像。

如果出现 `NO ACK`，优先检查 CAM1 供电、FMC 插接、RESETB、SCL/SDA 上拉和
引脚约束；如果有 ACK 但 ID 不是 `0x5640`，再检查读事务和器件型号。

## 离线验证

```sh
make camera-sccb-gpio-test
make camera-dvp-rx-test
make camera-sccb-fw-test
make fpioa-uart-profiles-test
make camera-error-report-fw-test
```

第一项检查复位默认值、开漏输出、采集使能和 SDA 输入同步；第二项检查
RGB565 高字节拼接、正常帧计数和奇数字节/尺寸错误；第三项用真实 CPU RTL
执行 bin，由 OV5640 模型检查 250 项配置和关键寄存器回读，再输入完整
640×480 DVP 帧，并分别执行 local/remote 固件，经 FPIOA 引脚按 115200、8-N-1
解码核对 UART 输出；第四项检查复位配置、高阻、对齐字节写及映射读回；第五项
注入479行帧，检查完整尺寸错误快照和相同错误不刷屏。
所有测试都不启动 PDS，也不访问实板。实板复测步骤见
[UART 本地与远程配置记录](../../manual/UART_本地与远程配置及实板复测.md)。

Camera MMIO 从 `0x40000300` 开始：`+0x00/+0x04` 为 SCCB 与采集控制/状态，DMA
通过 `+0x64` 先于 DVP capture enable 启动。`+0x08` 请求跨时钟域快照，`+0x0C` 至
`+0x5C` 提供完成帧、FIFO、DMA、缓冲所有权和原始 DVP 诊断；`+0x60` 为缓冲释放
mailbox。动态统计由硬件一次性冻结，CPU 读取同一份快照，不能逐位同步异步计数器。
