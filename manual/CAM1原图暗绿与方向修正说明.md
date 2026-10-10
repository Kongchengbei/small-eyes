# CAM1 原图方向与暗绿排查

本次软件调整只针对 CAM1 的方向和后续颜色定位，不宣称已经修复暗绿。共享
OV5640 表仍写 `0x4740=0x20`：应用指南第27页 §4.2 将 bit0=0 解释为 VSYNC
低时数据有效、bit1=0 解释为 HREF 高时数据有效，并说明 bit5=1 时数据在
PCLK 下降沿输出；这与现有 RTL 的低 VSYNC/高 HREF 有效和上升沿采样相配合。
本地数据手册的 bit1 polarity 表格解释相反，资料冲突仍需结合实板波形判断，
因此没有把 HREF 极性改成 `0x22`。

共享初始化后，stereo 相机路径会对 CAM1 单独写入并读回 `0x3820=0x47`、
`0x3821=0x01`，相对共享表的 `0x41/0x07` 反转垂直和水平镜像位；CAM2 保持
共享表原方向。成功日志包含相机编号、方向寄存器和 `0x503D` 彩条值，配置或
读回失败沿用相机编号及失败寄存器报告。普通 stereo、诊断和帧导出固件只要
走 `cam_configure_vga()` 都应用此设置。此次方向判断来自收到的 `hvflip` 解码
图像；已有导出帧 CRC 未通过，仍应把图像方向视为待有效帧复核。

颜色问题使用一个默认关闭的传感器彩条开关隔离。普通构建写入并读回
`0x503D=0`；要制作一次性 CAM1 彩条诊断固件，可在编译 `camera_stereo.c` 时
定义 `CAM1_SENSOR_COLORBAR=1`，它会令 CAM1 写入并核对 `0x503D=0x84`，CAM2
仍保持关闭。以下命令构建帧导出彩条版本；它保留当前 Makefile 的全部 C flags，
只追加宏，并强制重编避免复用旧目标文件。它会覆盖同名的
`camera_frame_uart_dump_local.bin`（帧导出固件），并在 `build/dump/local` 留下
带彩条宏的目标文件：

```sh
make -C bsp/camera_stereo_app -B camera_frame_uart_dump_local.bin \
  CFLAGS='--specs=picolibc.specs -march=rv32im -mabi=ilp32 -mcmodel=medlow -ffunction-sections -fdata-sections -Os -Wall -Wextra -I. -I../camera_app -DCAM1_SENSOR_COLORBAR=1'
```

将目标改为 `camera_frame_uart_dump_remote.bin` 可生成 remote 版本。要恢复普通
真实画面固件，必须强制重编以下目标（不要只运行普通 `make`，它可能复用上述
带宏的对象）：

```sh
make -B -C bsp/camera_stereo_app frame-dump
```

随后再观察真实场景。传感器彩条颜色正常而场景仍暗绿，
定位方向应转向真实场景下的 AE/AWB/ISP；彩条也异常时，继续检查 DVP 数据位
采样、D[9:2] 到 FPGA 输入的对应关系及 RGB565 字节拼接。彩条本身不自动证明
板上引脚映射或 DDR 内容正确。

仓库中的 `captures/cam1.rgb565.incomplete`、`cam1_retry2.rgb565.incomplete`
及其 JSON 是 CRC 不匹配的 UART 导出。CRC 失败时仍可用单独解码工具生成 PNG，
用于查看收到字节的布局和大致方向；PNG 能生成不代表数据通过完整性校验，也
不能证明传感器/DDR 源帧颜色正确。第一份数据存在一个单像素替换候选可使 CRC
吻合，第二份数据的少数异常色枚举未找到 CRC 匹配；在板上固件版本及有效 CRC
源帧确认前，这些都只是收到数据的观察，不可当作传感器金样或已恢复图像。

重新验证时需用更新后的源码重建相应 local/remote `.bin`，再按既有软件镜像
流程写入 Flash 原软件位置 `0x00A00000` 并 Verify；旧 BIN/SFC 不会自动包含
这些改动。未经此次重建和烧录的板卡不能用于判断软件修正效果。分别记录：

1. **方向**：CAM1 的有效帧是否正向；CAM2 是否仍保持原方向。
2. **颜色**：先检查彩条区域能否呈现红、绿、蓝、白，再恢复普通模式判断真实
   场景亮度和颜色。
3. **完整性**：UART 头尾 CRC 是否通过，并独立检查 DDR 源帧校验。

方向、颜色和 CRC 是三项独立结果；任何一项通过都不能代替另外两项。
