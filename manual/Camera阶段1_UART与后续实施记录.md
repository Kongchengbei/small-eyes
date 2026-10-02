# Camera 阶段 1～5：UART、CAM1 初始化、DVP 接收与状态记录

> 2026-10-01 更新：CAM1 已进一步接入 Async FIFO、Camera DMA、DDR 双缓冲及完整
> MMIO 调试快照。当前 local/remote 固件均为 6956 bytes，CPU 时钟信息为实际
> PLL 的 70 MHz；本地 UART TX 使用 C24，远程平台版本使用 AB26，见
> [UART_本地与远程配置及实板复测.md](UART_本地与远程配置及实板复测.md)。
> 最新固件按本地应用指南将 0x4740 改为0x20，等待用户实板复测。
> 上一轮0x23的极性解释已撤回，下面历史记录的极性说明不应作为当前配置依据，见
> [CAM1_HREF极性修正与错误输出限频.md](CAM1_HREF极性修正与错误输出限频.md)。
> 最新实现、寄存器与统一实板验收请看
> [CAM1_DMA_DDR_MMIO_离线验收与实板Review.md](CAM1_DMA_DDR_MMIO_离线验收与实板Review.md)
> 和 [Camera_DMA_MMIO_接口约定.md](Camera_DMA_MMIO_接口约定.md)。
> **下文保留为上一阶段历史记录，其中“尚未接入 DMA”、4836 bytes、90 MHz 和旧
> MMIO 表不再代表当前工程；不要据此烧写。** 尚未启动 PDS 或进行本轮实板验收。

日期：2026-09-30

## 本轮完成

- 新增独立固件目录 `bsp/camera_app/`，实现 `uart_putc()`、`uart_puts()`、
  `uart_puthex()`、`uart_putdec()` 和 115200 8-N-1 初始化。
- 生成可供当前 Flash→DDR 启动链加载的
  `bsp/camera_app/camera_uart_debug.bin`。
- 当前二进制长度为 **4836 bytes**，SHA-256 为
  `84c13b69adf4b9ad579ae7575bf9a3b4d017a6450ecfcf168f1add994fa9de26`。
- `Hfpga_soc.BOOT_IMAGE_BYTES` 已同步改为 `4836`。程序长度改变时必须再次
  同步该参数并重生成 `.sbit`，否则 loader 不会正确释放 CPU。
- 新增 `make camera-sccb-fw-test`：在真实 Htop CPU RTL、DCache、AXI backend、
  Camera SCCB GPIO 和 Huart_tx RTL 上执行该二进制，逐字节核对 UART 输出。
- 新增 CAM1 专用顶层端口与 `0x40000300` Camera MMIO。SCL/SDA 均为开漏，
  RESETB 在 FPGA 复位期间保持低；约束为 SDA=U14、SCL=W21、RESETB=T20。
- C 驱动实现 SCCB START/STOP、字节收发、ACK 检查、重复起始和 16 位寄存器
  读写，并读取 `0x300A/0x300B` 判断是否为 OV5640。
- 从本地 OV5640 DVP 应用指南提取基础初始化和 640×480/15 fps 预览表，过滤
  旧 Demo 的空洞及 720p 项，并增加明确极性配置，共形成 250 项模式表；每项
  写失败最多重试三次。
- 依据本地数据手册将 `0x4300=0x61` 配为标准字节顺序 RGB565，将
  `0x501F=0x01` 选为 ISP RGB 路径。配置后读回 RESET/stream、DVP、PLL、
  输出宽高、极性和格式等十一个关键寄存器，不能只凭 ACK 报告成功；
  `0x4740=0x21` 固定 VSYNC/HREF 高有效、PCLK 下降沿更新数据；`0x3008=0x02`
  被放在表尾，确保所有模式项完成后才退出软件待机。
- 联合仿真发现并修复 MEM 阶段 load 数据未返回便错误前递的问题。该问题会令
  `lbu` 后的字符串循环在 cache miss 时误读零并提前结束。
- 新增纯 RTL `Hcamera_dvp_rx.v`，在 CAM1 PCLK 上升沿采样 D[7:0]，按
  `{高字节,低字节}` 输出标准 RGB565，不使用旧 Demo 的 Pango 分频原语。
- 每行开始重置字节相位，统计 640 像素/行、480 行/帧，并检测奇数字节、行宽
  错误、帧高错误和 VSYNC/HREF 重叠。DVP 输入约束已加入 `soc.fdc`。
- 新增请求/应答翻转快照：PCLK 域同拍冻结帧数、上一帧像素/行数、PCLK 数、
  错误和活动标志，CPU 域收到同步应答后再锁存，避免多位异步计数器撕裂。
- 联合仿真还暴露 CPU 的 MMIO load-to-store 冒险缺口：加载指令进入 MEM
  等待响应后，依赖它的存储指令会提前进入 EX，锁存旧数据。现已让 ID 级继续
  等待 MEM 加载完成，并用现有 MEM 前递送出正确值；Camera C 驱动删除三个
  空操作，恢复快照 `busy/valid` 轮询。
- 新增 `make cpu-load-store-test` 定向回归，覆盖 MMIO `lw` 后紧接 `sw/sb/sh`、
  DDR 加载后紧接依赖地址的 `sw`。修复前首个用例失败，修复后通过。

## 已完成的离线验收

```text
make -C bsp/camera_app clean all
BOOT_IMAGE_BYTES=4836

make camera-sccb-gpio-test
CAM1_SCCB_GPIO_PASS

make camera-dvp-rx-test
CAM1_DVP_RX_PASS

make cpu-load-store-test
Summary: PASS=1 FAIL=0 TIMEOUT=0 ERROR=0 TOTAL=1

make camera-sccb-fw-test
UART_FIRMWARE_PASS

make dcache-bypass
DCACHE_NPU_BYPASS_PASS rsp_count=10

make sim
Summary: PASS=46 FAIL=0 TIMEOUT=0 ERROR=0 TOTAL=46
```

联合仿真核对的串口内容为：

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

仿真中的 OV5640 是 SCCB 从机模型，用于检查 16 位寄存器地址、ACK、重复起始、
250 项配置写入和关键寄存器回读。DVP 模型随后输入完整 640×480 帧，硬件侧
实际统计为 307200 像素和 480 行。这里的所有结果仍是离线闭环，不代表已经
上板确认真实图像输出。

Camera MMIO 当前定义如下：

| 地址偏移 | 作用 |
|---|---|
| `+0x00` | RESETB、SCL/SDA 开漏释放、DVP 采集使能 |
| `+0x04` | SCCB 引脚状态、DVP 活动状态、快照忙和错误摘要 |
| `+0x08` | 写 bit0 请求快照；读 busy/valid |
| `+0x0C` | 快照帧计数 |
| `+0x10` | 上一完成帧的像素数 |
| `+0x14` | 采集使能后的 PCLK 计数 |
| `+0x18` | 粘滞错误标志 |
| `+0x1C` | 上一完成帧的行数 |

`DDR INIT OK` 的依据是当前硬件只有在 DDR 初始化完成、Flash 镜像全部写入 DDR
并逐字读回一致后才释放 CPU 复位。它不是由软件重新训练 DDR 得出的结果。

## 实板验证策略

本轮没有启动 PDS、没有重新生成位流、没有上板。

**不为当前探活/初始化程序单独安排上板测试，也不为它单独重生成或烧写
bitstream。** 当前固件作为后续 DVP 和 Camera MMIO 的基础保存。

等 SCCB 探活、OV5640 初始化、DVP RX 和 Camera MMIO 集成完成后，再进行一次性
实板 review：

1. 重新构建届时的 Camera 综合固件，记录最终 `.bin` 的准确长度，并同步更新
   `Hfpga_soc.BOOT_IMAGE_BYTES`；不能继续沿用当前程序的 4836 bytes。
2. 统一重新生成包含 CPU 修复和 Camera RTL 的 `.sbit`。
3. Convert File 中把新 `.sbit` 放在地址 `0x000000`，把最终 Camera 固件放在
   `0x00A00000`。
4. 优先启动资料包自带的
   `5_Software\串口调试助手\sscom5.13.1.exe`；MobaXterm 作为备选。打开已经
   验证过的板载串口，配置 `115200 / 8-N-1 / 无流控`。
5. 擦写、Verify 后断电重启，在同一次会话中统一核对 UART、DDR、OV5640 ID、
   初始化结果、DVP 状态、帧数、像素数和错误寄存器。

## Camera 资料审计结论

- 旧初始化表位于 `camera_demo/source/rtl/reg_config.v`，SCCB 写模块位于
  `camera_demo/source/rtl/i2c_com.v`。表索引稀疏，空洞会输出 `24'hffffff`，
  必须筛出有效项并逐项核对，不能原样转换为 C 表。
- 本地《OV5640 自动对焦成像模组应用指南（DVP 接口）》提供了完整基础表和
  VGA 预览表；旧 Demo 的输出尺寸寄存器为 `0x0500×0x02D0`，确认是
  1280×720，不能标作 VGA。RGB565 的格式与字节顺序以数据手册为准。
- 旧 RGB565 拼接模块 `camera_demo/source/rtl/cmos_8_16bit.v` 使用
  `GTP_IOCLKDIV_E2`，新实现应采用普通、可仿真的 RTL，而不是移植该模块。
- `camera_demo` 虽把工程器件名改成 PG2L200H-FBB676，但多个 PLL/DDR/帧缓存
  `.idf` 仍标识 PG2L100H/FBG676；其已有 bitstream 不作为当前 200H 的依据。
- 后续补充核查已经由双目模块原理图、FMC 200K 原理图以及明确标注
  `PG2L100H/200H-676` 的 J2/J3 管脚表闭环确认接口。完整结论见
  `manual/PG2L200H_双目OV5640接口核对.md`。仍只复用经过核对的连接信息，不
  复用旧 demo 的 IP、RTL 或 bitstream。

## 后续顺序

1. CAM1 的 RESET 与 GPIO 模拟 SCCB 已完成离线闭环；待最终联合上板时确认真实
   `0x300A/0x300B = 0x56/0x40`。
2. CAM1 的独立 C 初始化表、逐项 ACK 和关键寄存器回读已完成离线闭环；待最终
   联合上板确认真实 `CAM1 ID/RESET/CONFIG/START`。
3. CAM1 DVP RX、RGB565 拼接和 Camera MMIO 已完成离线计数验收。独立 Async FIFO
   RTL 与跨时钟压力测试已完成；`make camera-dvp-fifo-test` 又验证了完整 VGA 帧
   的帧开始、307200 个 RGB565 像素及帧结束事件按序到达系统时钟域。事件编码
   暂在 testbench 内，生产接口随下一阶段 Camera DMA 一起确定。现在没有消费者，
   故暂不接入 SoC 顶层。
4. CAM1 FIFO/DMA 稳定后复用同一套模块接入 CAM2，同时解决 `fpioa[18]`、
   `fpioa[28]`、`fpioa[29]` 与 CAM2 数据线的三个约束冲突。
5. 随后进入双目同步与 NPU；HDMI 最后接入。

### Async FIFO 与现有 NPU DMA 核查

`soc/Hcamera_async_fifo.v` 是独立双时钟 FIFO：写端为摄像头 PCLK，读端预留
给系统时钟域；默认数据宽度 18 bit、深度 1024 项。灰码指针经双触发器同步，
满/空只在本时钟域判定，读数据按请求注册输出；满写和空读分别锁存 overflow、
underflow。统一异步复位断言，各域两拍同步释放。它只传输上层给出的条目，
联合 testbench 把帧起止事件编码成独立条目；生产接口的事件编码和溢出后整帧
作废策略要由 Camera DMA 接入时共同完成。

`make camera-async-fifo-test` 用不同频率时钟验证随机传输顺序、读端背压、满写、
空读和中途复位。该测试属于模块级离线验证，**还不能宣称实际摄像头无溢出，
也不能宣称图像已进 DDR**。接入真实 DDR 后要用可控背压和满帧校验验收。
`make camera-dvp-fifo-test` 使用约 23.8 MHz PCLK 和 90 MHz 读时钟，输入完整
640×480 RGB565 帧，在读端加入限速及暂停，逐项核对 307202 个像素/帧标记条目，
并要求 FIFO 积压峰值至少 40 项；本次峰值为 54 项，离线结果为
`CAM1_DVP_FIFO_PASS`，FIFO overflow/underflow 均为零。

现有 `soc/Hnpu_dma.v` 是 256-bit AXI4 的 DDR→片上 16 拍缓冲→DDR 复制骨架：
先读源地址，再把缓冲写到目标地址。它确有 AXI 写通道，但没有像素流输入，
不能直接完成 Camera→DDR 搬运。当前 `Hfpga_soc.v` 也尚未实例化 NPU DMA 或
两主机 AXI 仲裁器；二者目前只做了独立仿真。Camera DMA 应另写流式写入模块，
可参考 NPU DMA 的 AXI 写握手、错误响应和 4 KiB 边界处理。
现有仲裁器只有 CPU/NPU 两个主机口，最终 CPU、Camera、NPU 共存还需扩展
仲裁拓扑，不能把 Camera 写入误算作已有 NPU DMA 功能。

《整体目标.md》中 `0xB8000000` 是帧基址示例，但现有地址图把该地址划给
NPU input，整个 `0xB8000000–0xBFFFFFFF` 是 NPU 共享区。真正接入 Camera DMA
前必须明确划出不会覆盖 NPU 数据的帧缓冲，并确定 CPU 读回时的 DCache
旁路或一致性策略；不能直接套用文档示例地址。
本阶段不实现 Camera DMA、不修改 DDR 地址分配；上述内容仅作为下一阶段设计约束。

本地证据不足时才查网络资料；网络资料优先矩阵社区和正点原子，但任何网络
示例的引脚与 IP 配置仍不能替代当前 200H 板级原理图。

## 本地调试工具

- 串口默认使用资料包 `5_Software/串口调试助手/sscom5.13.1.exe`。
- `F:/MobaXterm_Portable_v26.3/MobaXterm_Personal_26.3.exe` 保留为备选。
- 资料包中的 `5_Software/Wireshark/Wireshark-win32-2.4.1.0.exe` 和
  `5_Software/网络调试助手/NetAssist.exe` 仅在后续实际引入以太网/网络传输时
  使用；当前 UART、SCCB、DVP 阶段不需要抓包。
