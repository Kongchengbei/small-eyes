# CAM1 GPIO 最小翻转测试

日期：2026-10-01。用途：检查 CPU→Camera MMIO→SCL/SDA 开漏输出→输入回读。
本轮使用 Luna High 子代理实现固件，主代理补充联合仿真与记录。
未修改 RTL、loader 参数或物理引脚约束，未运行 PDS、烧写或访问实板。

用户已确认先前 ID 全零时摄像头插错 FMC 接口。接正后应优先用原 Camera 固件
复测；本测试作为备用线路诊断，不替代 OV5640 ID、初始化、DVP/DDR 帧验收。
特别注意：本程序一直保持摄像头复位，运行期间没有有效图像是正常的。

## 文件与烧录长度

源码：`bsp/camera_app/gpio_test.c`，与原 `main.c` 分开链接。

```sh
make -C bsp/camera_app gpio-test
```

默认 `make -C bsp/camera_app all` 仍构建 Camera 固件，不会把兼容文件名换成 GPIO。

| 场景 | bin | UART TX | 字节数 |
| --- | --- | --- | ---: |
| 本地主板 | `bsp/camera_app/camera_gpio_test_local.bin` | FPIOA0/C24 | 6956 |
| 远程平台 | `bsp/camera_app/camera_gpio_test_remote.bin` | FPIOA31/AB26 | 6956 |

原始程序为 1596 字节；构建先导出完整 ELF 的加载内容，检查非空、4 字节对齐、
不超过 6956，再在原始二进制末尾填零到 6956。保留加载的 `.data`，不截断程序。
填充适配当前 `BOOT_IMAGE_BYTES=6956`；不能据此兼容长度未知或旧 6944 字节位流。

SHA-256：

```text
local : 2d5351cef2074b493055768dfa74d7455961600fece839ec02181b6a5b0a0889
remote: 661e068db3bf7f8074eed0cfdaf55a2754c8b323ad11aba685cdb52590495b12
```

如果板上已经是 UART 修正后、loader 长度为 6956 的位流，则本轮不需要重综合；
将所选 GPIO bin 置于 Flash `0x00A00000`，按用户既有流程重新组合/烧写/Verify。
位流区保持当前匹配的版本，不是把之前的旧 SFC 不加检查地继续使用。
直接烧原始 bin，不做端序交换，不用串口工具“发送文件”下载本程序。

## 测试行为与引脚记录

沿用现有 Camera 接口，**无任何管脚位置或复用变更**：

| 信号 | FPGA 管脚 | 对应 J2 pin | 行为 |
| --- | --- | ---: | --- |
| CAM1 SCL | W21 | 6 | 只拉低或高阻释放，不推挽输出高电平 |
| CAM1 SDA | U14 | 4 | 只拉低或高阻释放，不推挽输出高电平 |
| CAM1 RESETB | T20 | 12 | 始终为低，保持传感器复位 |

模块上拉使释放的线路回到高电平；若没有上拉或线路异常，可能回读为低。
整个程序不读取 ID、不配置 OV5640、不使能 DVP、不写 Camera DMA 控制寄存器。
仅写 CONTROL `0x40000300`，读取 CONTROL 和 STATUS `0x40000304`。

循环顺序如下，每步打印后保持约 500 ms（另加少量 UART 打印开销）：

| 步骤 | CONTROL | STATUS 低 6 位期望 | SCL/SDA |
| --- | --- | --- | --- |
| RELEASE | 0x06 | 0x1E | 1/1 |
| SCL_LOW | 0x04 | 0x14 | 0/1 |
| RELEASE | 0x06 | 0x1E | 1/1 |
| SDA_LOW | 0x02 | 0x0A | 1/0 |

写后等待约 5 µs，再采样两级同步输入。STATUS 高位可能包含其他硬件状态，
匹配仅核对 GPIO 低 6 位及 CONTROL 低 6 位。RESET 输出字段来自 CONTROL bit0，
不是对 T20 实物电压的独立测量；仍需在接口端验证。

计时使用本项目 CSR `0xB03` 的 mtime 低 32 位，70 MHz 下 500 ms 是 35000000 tick，
无符号差值支持计数回绕。启动先确认项目 CSR `0xB88` bit2 的计时门已开启；若否，
输出 `TIMER ERROR : MTIME DISABLED`，安全停留在 CONTROL=0x06，不修改计时门。

串口设置 115200 / 8-N-1 / 无流控，预期反复输出：

```text
=== CAM1 GPIO Toggle Test ===
HOLD MS     : 500
STEP=RELEASE CTRL=0x00000006 STATUS=0x0000001E RESET=0 SCL=1 SDA=1 MATCH=YES
STEP=SCL_LOW CTRL=0x00000004 STATUS=0x00000014 RESET=0 SCL=0 SDA=1 MATCH=YES
STEP=RELEASE CTRL=0x00000006 STATUS=0x0000001E RESET=0 SCL=1 SDA=1 MATCH=YES
STEP=SDA_LOW CTRL=0x00000002 STATUS=0x0000000A RESET=0 SCL=1 SDA=0 MATCH=YES
```

`MATCH=NO` 也持续打印，不假报成功；例如释放 SDA 后仍为低，会在 RELEASE 中读到
STATUS=0x1A、SDA=0、MATCH=NO。退出测试需复位/重启；恢复 Camera 固件后再测图像。

## 离线与实板验收

```sh
make camera-gpio-fw-test
make camera-sccb-gpio-test
```

联合测试执行交付的 6956 字节 bin，不缩短固件保持时间、不强制内部计数器。
检查实际 SCL/SDA 仿真引脚、500 ms 间隔、复位/采集始终为低、未发 Camera DMA
写请求，并从 FPIOA TX 引脚解码 UART。另将 SDA 引脚持续拉低，核对 `MATCH=NO`。
日志：`build/camera_gpio_firmware_regression.log`，本轮最终通过：

```text
CAMERA_GPIO_FIRMWARE_PASS pin=0 stuck_low=0 steps=4
CAMERA_GPIO_FIRMWARE_PASS pin=31 stuck_low=0 steps=4
CAMERA_GPIO_FIRMWARE_PASS pin=0 stuck_low=1 steps=4
```

三项都从实际 UART TX 仿真脚解码；正常两套各 362 字节，故障输出 359 字节。
SDA 恒低时 RELEASE/SCL_LOW 明确打印 MATCH=NO，未误报线路正常。
原 Camera 本地固件回归、GPIO RTL 单测、FPIOA profile 单测和 lint 也通过，见
`build/camera_gpio_compatibility.log`。相关文件 `git diff --check` 通过。

用户先断电确认 FMC/J2 插接及方向，再烧所选测试程序；在复位前打开串口保存日志。
用示波器/逻辑分析仪观察 J2 的 SCL/SDA 与 RESETB，核对上表各状态及翻转周期。
MMIO 回读成功不等于接口接触、供电和摄像头时钟均已正常，也不能证明能收到图像。
