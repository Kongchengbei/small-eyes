# CoreMark 从 Flash 启动

当前启动路径为：Flash `0x00A00000` → DDR `0x80000000` → CPU。CoreMark 可以放在 Flash 中，无需固化为 FPGA 内部 ROM；FPGA 位流负责实现 CPU、DDR 接口和 Flash 启动加载器。

## 2026-10-03 问题定位

用户使用本地 C24（FPIOA0），串口为 115200，烧录 `test/coremark.bin`。

修复前该文件与 `bsp/bsp_app/example/coremark/coremark.bin` 完全相同，SHA256 为 `6a10b728a83c353ebd42d8e1e35b6ce5a17aab52c7e8395b24abf6414ca6b02c`，大小为 28756 字节，是 2026-09-14 的旧产物。旧 ELF 显示 `.init/.text` 和运行期 `.data` 都从 `0x80000000` 开始；在当前统一 DDR 映射下，启动复制数据会覆盖代码，`.bss/stack` 也落在代码范围。旧 `coremark.map` 同时记录 `_app_base_addr=0x80000000` 和 `_sram_base_addr=0x80000000`。当前原有 `bsp/bsp_app/link.lds` 的数据基地址已是 `0x80008000`，不需要修改它；旧产物与当前脚本不一致。旧 makefile 没有把链接脚本列为 ELF 的依赖，脚本更新不能保证触发重新链接。

不能仅从本次旧产物推断先前远程实测使用了相同的固件与位流。仓库另有采用代码 `0x00000000`、数据 `0x20000000` 的旧 `Coremark.dat` 和仿真平台，它们与当前 DDR/Flash 架构不同；尚无证据证明远程测试实际使用哪一套版本。

另一个独立问题是，原 `Hfpga_soc.BOOT_IMAGE_BYTES=16384`，小于旧镜像及修复后镜像的完整长度。加载器只能检查已经搬运的范围，并不知道 bin 的真实长度，不能依靠 `boot_done` 判断程序是否完整。

旧移植代码硬编码 FPIOA31，UART 分频为 `CPU_HZ/baud`；当前 `Huart_tx` 需要 `CPU_HZ/baud-1`。分频差一个时钟不足以单独解释整屏乱码，但应与 RTL 保持一致。乱码的最终实板原因需重烧后确认。

## 修改内容

- `core_portme.c`：选择本地/远程 UART 引脚；配置分频与 TX 使能；打印主频和引脚；高低高重读 64 位 mtime，计时不停止计数器。
- `core_portme.h`：引脚、迭代次数和编译参数改为可配置。默认 `ITERATIONS=0` 使用现有 CoreMark 自动迭代逻辑；报告实际编译参数。
- 保留原有 `bsp/bsp_app/link.lds`：代码从 `0x80000000` 开始，运行期数据从 `0x80008000` 开始，数据区 16 KiB，其中栈 4 KiB。构建时使用此脚本重新链接，而不是沿用旧 ELF/bin；临时创建的专用脚本已撤去。
- `makefile`：使用独立对象目录，避免改写 Camera 使用的 BSP 对象；明确依赖链接脚本和构建选项；生成 local/remote 两个镜像，补齐到 32768 字节。
- `Hfpga_soc.v`：默认搬运长度改为 32768 字节。其他固件需补齐为相同长度，或者生成位流时覆盖参数为其实际长度。
- `sim/tb_Htop.sv`：添加 CoreMark 启动、UART 引脚解码及单迭代 CRC 检查模式。

CoreMark 的链表、矩阵、状态机及 CRC 算法未修改。板级初始化和计时属于官方说明中的移植部分，见 [EEMBC 裸机移植说明](https://github.com/eembc/coremark/blob/main/barebones_porting.md)。

## 构建和烧录

在工程根目录的 WSL 终端运行：

```sh
make -C bsp/bsp_app/example/coremark
```

也可以进入 `bsp/bsp_app/example/coremark` 后执行 `make help` 查看命令。`make local` 生成本地版本，`make remote` 生成远程版本，`make -j4` 并行构建两套版本；`make ITERATIONS=2000` 固定迭代次数，`make OPT=-O1` 更换优化级别。`make clean` 清理此例程自己的对象与 ELF/bin/map/dump，保留源码、公共 BSP 对象和 `test/` 中已经复制的交付文件。完整重建请依次执行 `make clean`、`make`，不要将二者放入同一次并行 make。

输出：

| 文件 | 用途 |
| --- | --- |
| `bsp/bsp_app/example/coremark/coremark_local.bin` | 本地 C24 / FPIOA0 |
| `bsp/bsp_app/example/coremark/coremark_remote.bin` | 远程 AB26 / FPIOA31 |
| `bsp/bsp_app/example/coremark/coremark.bin` | local 的相同副本 |
| `test/coremark.bin`、`test/coremark_local.bin` | 本次交付的 local 副本；后续构建不会自动更新 test |
| `test/coremark_remote.bin` | 本次交付的 remote 副本 |

默认版本有效内容为 30196 字节，补齐后为 32768 字节。用于 Flash 的 bin 保持原始小端字节序，不进行 readmemh 字序转换。

1. 重新运行 PDS 综合、实现和位流生成，并下载新位流。确认顶层 `BOOT_IMAGE_BYTES=32768`；只下载新 bin 而保留 16 KiB 加载器不能完整运行。
2. 本地板将 `test/coremark.bin` 烧录到 Flash 地址 `0x00A00000`，与 FPGA 配置区分开。
3. 串口设为 115200、8N1、无流控，使用 C24 对应串口。复位后应看到：

```text
Start CoreMark CPU=70000000 Hz UART=115200 TX_FPIOA=0
```

4. 自动选择迭代次数后输出结果。启动文字与最终结果之间会有等待；正式结果应没有 CRC 错误，运行时间至少 10 秒。此时才能把输出视为有效成绩。

不要继续烧录旧 bin，也不要把根目录的旧 `Coremark.dat` 当成此次 Flash 镜像。

旧镜像和 ELF 已保存在 `build/coremark_previous/`。BSP 的 CoreMark 源文件及 `test/` 目录当前受 `.gitignore` 排除，Git 默认不会显示这些文件的修改；本次并未调整忽略规则。

## 验证范围

两套默认镜像交叉编译通过。使用真实 Htop、Huart_tx 和 Hfpioa_simple 验证默认镜像启动输出，并按 115200 从 FPIOA0/FPIOA31 逐字节解码。另以 `ITERATIONS=1` 的独立短测镜像检查算法 CRC 和计时；这种短测不满足正式成绩的运行时间要求，不作为评分结果。交付文件恢复为默认自动迭代版本。

尚未重新运行 PDS、烧录或完成实板复测。仿真将程序直接加载到 DDR 模型，不是 SPI Flash→DDR 的全链路实测，也不产生实板 CoreMark 分数。
