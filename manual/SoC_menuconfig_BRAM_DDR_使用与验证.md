# SoC DDR / BRAM 配置、构建与启动

本文说明如何从 WSL 选择完整 DDR 应用配置或 CoreMark BRAM 配置，生成软件侧地址头文件，构建原 BSP 镜像，准备 PDS Flash 烧写清单，并验证上电后的启动链路。`tools/soc_menuconfig.py` 只编辑地址映射头文件、生成软件头文件和 manifest；它不会启动 PDS、生成位流或烧写 Flash。

## 两种硬件配置

| 配置 | `SOC_CPU_MEM_BRAM` | 硬件组成 | 启动目标 |
| --- | ---: | --- | --- |
| Full DDR（默认） | 0 | ICache、DCache、DDR3、Camera；预处理默认关闭，可在 full 配置中单独开启 | 等待 DDR 初始化后从 Flash 搬到 DDR `0x80000000` |
| CoreMark BRAM | 1 | ICache、DCache、DDR3、Camera、预处理均关闭；保留 PLL、CPU、UART、FPIOA、CSR/timer、JTAG/debug | Flash 镜像进入本地 IRAM/DRAM，校验完成后从 IRAM `0x80000000` 开始执行 |

BRAM 地址布局固定为 IRAM `0x80000000`、32 KiB，紧接着 DRAM `0x80008000`、16 KiB。`bsp/bsp_app/link.lds` 已按该地址规划：代码与初始化数据的 Flash 装载映像放在 IRAM，运行期 `.data`、`.bss` 和栈放在 DRAM，栈固定 4 KiB。镜像装载器总容量为 48 KiB；当前 CoreMark `.bin` 是 29144 字节，能放进 32 KiB IRAM。若换软件，除了 48 KiB 总容量，还要确认链接产生的代码及 `.data` 初值装载范围能放进 IRAM。

Full DDR profile 中使用 DDR 的逻辑地址范围，不会实例化这两块本地 BRAM。若后续 NPU 实现需要空间，可在评估地址图、仲裁与带宽后重新规划这些逻辑资源；本次没有增加 NPU 计算单元或缓冲区。

默认选择 Full DDR：`SOC_CPU_MEM_BRAM=0`。`soc/soc_addr_map.vh` 是 SoC memory/peripheral base、已实现的 MMIO offset/control bit 和 profile 配置值的唯一维护来源。菜单会在其中成组切换 profile 标志，并更新 Flash 起始地址、映像长度和 UART TX FPIOA 引脚。C 程序和汇编使用生成的 `bsp/include/soc_defs.h` 与 `bsp/include/soc_defs_asm.inc`，不要手改生成文件。

BRAM CPU 的取指接口按同步 IRAM 时序工作：请求地址被接受后，指令数据与 response-valid 随时钟返回。CPU 复位期间，Flash 装载器取得 RAM 编程端口；写在 `valid && ready` 时完成，读回请求在一个时钟后伴随 `ready` 和对应数据应答。校验完成、CPU reset 释放后，该端口转由 LSU 使用。IRAM 的另一端口供取指，DRAM 为单端口 RAM。BRAM 地址内的 LSU 请求由本地 RAM 处理，范围外的 MMIO 请求走现有 AXI backend；load 会等待数据 response-valid，store 等待 ready，保证同步读延迟不会提前放行流水线。为此，Htop 增加 profile 生成选择和 BRAM 端口连接，Hifu 增加同步取指队列与预测处理，Hexu 以 MEM 接受状态门控 EX 请求，Hmemu 在 WB 停顿时保留已返回的 load 数据。BRAM profile 会移除 ICache、DCache、DDR bridge/controller 和 Camera 实例。

## 环境准备

在 WSL 安装并可从仓库根目录调用 Python 3（含标准库 `curses`）、GNU Make、Verilator、Icarus Verilog、`riscv-gcc`（含 `picolibc.specs`）、`xxd` 和 `rg`。Yosys 仅用于可选的 RAM 推断检查。PDS 在 Windows 环境中由用户操作，不属于 WSL 测试依赖。

## 在 WSL 选择并生成配置

在 WSL 终端进入仓库根目录。先选择目标 profile、Flash 地址和 UART 引脚，使生成的软件头文件与将要生成的位流一致；再生成头文件并构建 BSP。首次构建时 BIN 还不存在，可以先不填写 BIN：

```sh
cd /mnt/f/SocFpga
make menuconfig
make -C bsp/bsp_app/example/coremark clean
make -C bsp/bsp_app/example/coremark all
wc -c bsp/bsp_app/example/coremark/coremark.bin
```

构建完成后再次打开菜单，选择刚生成的 BIN，让工具读取精确文件长度并写出烧写 manifest；或者用下方 `configure --bin ...` 和 `check` 命令完成这一步。若更改 UART 等会进入固件的设置，先保存配置、重新 clean/build，然后再以新 BIN 更新 manifest：

```sh
make menuconfig
```

日常交互入口是 `make menuconfig`，`make manuconfig` 是同义入口。方向键选择，Enter 编辑，`q` 退出。首次构建时选择 Full DDR 或 CoreMark BRAM、Flash 起始地址 `0xA00000` 和 UART TX 引脚并保存；固件生成后再次打开菜单，选择该 BIN 并保存。选定 BIN 后菜单会自动读取它的字节数，保存时会更新 `soc/soc_addr_map.vh`、生成 C/汇编头文件，并写出 `build/menuconfig/flash_manifest.json`，无需另行运行 `generate-header`。

无终端环境时可用等效命令。首次构建前可先配置 profile 和软件选项，并生成头文件：

```sh
python3 tools/soc_menuconfig.py configure \
  --profile bram \
  --flash-start-address 0x00A00000 \
  --uart-tx-fpioa 0
python3 tools/soc_menuconfig.py generate-header
make -C bsp/bsp_app/example/coremark clean
make -C bsp/bsp_app/example/coremark all
wc -c bsp/bsp_app/example/coremark/coremark.bin
```

构建后按实际 BIN 长度更新 manifest。换成完整 DDR 软件时将 `--profile bram` 改为 `--profile full`：

```sh
python3 tools/soc_menuconfig.py configure \
  --profile bram \
  --bin bsp/bsp_app/example/coremark/coremark.bin \
  --flash-start-address 0x00A00000 \
  --uart-tx-fpioa 0
python3 tools/soc_menuconfig.py check \
  --bin bsp/bsp_app/example/coremark/coremark.bin \
  --header bsp/include/soc_defs.h \
  --asm bsp/include/soc_defs_asm.inc
```

`configure` 接受 `--profile full|bram`、`--bin`、`--flash-start-address`、`--boot-image-bytes`、`--uart-tx-fpioa 0|31` 和 `--preprocess` / `--no-preprocess`。BRAM 不允许开启预处理。full/BRAM profile 的 cache、DDR、Camera 开关必须与 profile 一致；配置检查会拒绝不支持的组合。省略 `--boot-image-bytes` 且指定 BIN 时，长度自动取 BIN 的实际文件大小。

当前 BSP 默认选择本地 UART 引脚 FPIOA0。菜单将 RTL 引脚改为 31，并不会重编译 BSP 或改变 `core_portme.h` 中的 `COREMARK_UART_TX_FPIOA=0`。若要构建远程镜像，必须给编译器传入 `-DCOREMARK_UART_TX_FPIOA=31u`。原 Makefile 使用 `CFLAGS :=`，因此不要把裸 `make CFLAGS+=...` 当作安全追加方式；GNU Make 的命令行赋值会覆盖该文件中的默认 CFLAGS。保留原编译选项的一种命令是：

```sh
make -C bsp/bsp_app/example/coremark clean
make -C bsp/bsp_app/example/coremark all \
  CFLAGS='--specs=picolibc.specs -march=rv32im -mabi=ilp32 -mcmodel=medlow -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc -O2 -DCOREMARK_UART_TX_FPIOA=31u'
```

切换本地/远程编译参数后应先 `clean` 再构建。本文及本次实现均保留原 BSP Makefile、`link.lds`、CoreMark 源码和 BSP BIN，不对它们作修改。

## 镜像长度、对齐和 manifest

本次默认 BSP 产物 `coremark.bin` 为 29144 字节（`0x71D8`）；起始地址 `0x00A00000`，因此映像结束地址（不含）为 `0x00A071D8`。请在每次构建后用 `wc -c` 查看实际长度，再让菜单自动采用该长度，或将该值显式传给 `--boot-image-bytes`。不要仅因历史默认值为 32768 就把短 BIN 按 32768 字节读取。

装载长度必须大于零且是 4 字节整数倍，且不能小于所选 BIN；可以大于 BIN，以便按 `0xFF` 补齐。Flash 起始地址也必须 4 字节对齐。SPI 读地址是 24 位，逻辑可寻址范围为 `[0x000000, 0x1000000)`；这不代表已确认外部 Flash 器件的物理容量。从 `0xA00000` 起的 6 MiB 只是该 24 位逻辑窗口中剩余的地址范围。工具会检查 `FLASH_BASE + BOOT_IMAGE_BYTES` 不越过窗口。

若明确需要把装载长度设得比 BIN 大，工具会保留输入文件不变，另生成 `build/menuconfig/<名称>.padded-<长度>.bin`，并在 manifest 中记录 `0xFF` 填充字节数。此时 PDS 应烧写 manifest 列出的 padded 文件，而不是较短的原文件。若文件长度不是 4 的倍数，应显式将 loader 长度设为下一个 4 字节边界，让工具生成填充产物。默认 CoreMark BIN 长度已对齐，无需填充。烧写使用原始小端 `.bin` 字节；不要使用仿真专用的 reverse-bytes 文件。

Manifest 至少列出 profile、输入 BIN、实际输入大小、loader 长度、Flash 起始及结束地址、填充文件和填充值。它是给操作者核对 PDS 烧写设置的记录，不是 PDS 工程，也不会自动生成烧写包：

```text
build/menuconfig/flash_manifest.json
```

## 生成 profile 位流并在 PDS 烧写

先在 WSL 完成配置检查，再交由操作者在 Windows/PDS 中打开现有工程。PDS 用户负责检查项目已注册的新 RTL 文件，包括 `soc/Hfpga_soc_bram_profile.v`、`soc/flash_boot/flash_bram_boot.v` 和 `cpu/cpu_bram_mem.v`，然后按所选 profile 重新执行编译、综合、布局布线和位流生成。BRAM 选择 `SOC_CPU_MEM_BRAM=1` 的配置；完整应用使用 0。更改 profile、Flash 起始地址或装载长度后，都要生成匹配的新位流；同 profile 下若新 BIN 长度变化，也要更新长度配置并生成新位流。只有 profile、基址和长度都未变时，才可直接替换并重新烧写 BIN。

在 PDS Flash 烧写页，按 manifest 使用对应软件文件和 `flash_start_address`。典型组合是 FPGA 配置位流放在配置区地址 `0x000000`，原始程序 BIN 放在用户区 `0x00A00000`；如果 manifest 指定 padded 文件，则使用该文件。烧写后在 PDS 执行擦除/编程/校验时，确保校验对象与 manifest 的文件及地址完全一致。

本文没有运行 PDS，也没有生成新 `.sbit` / `.sfc`、烧写 Flash、下载位流或做实板验证。RTL 文件进入工程和离线仿真都不能替代 PDS 对目标器件的综合、资源、引脚、布线和时序确认。BRAM RAM 的通用 RTL/Yosys 检查显示 IRAM 为同步双端口、DRAM 为同步单端口；目标 Pango 器件的实际 BRAM 推断数量和映射仍待用户在 PDS 中检查。

## 上电后启动过程

Full DDR 位流启动后，DDR 控制器先完成初始化；启动逻辑再从 Flash 基址读取配置长度的原始映像，按每 4 字节小端组字，写入 DDR `0x80000000` 并逐字读回校验。BRAM 位流启动不等待 DDR：装载逻辑从 Flash 读取同样格式的原始映像，写到 IRAM，再按同步 RAM 接口逐字读回校验。两种 profile 均在校验完成后释放 CPU reset；Flash 地址越界、长度不合规、超时或读回不匹配都会保持 CPU reset。外部复位可重新启动装载流程。

当前 SPI 通路使用单颗 Flash、X1、模式 0、`03h` Read Data 命令和 24 位字节地址。镜像没有自定义头部、校验和或字节序转换；加载器读多少字节由生成到 RTL 的 `SOC_BOOT_IMAGE_BYTES` 决定。启动后本地 CoreMark UART 默认 115200、FPIOA0，预期起始提示为：

```text
Start CoreMark CPU=70000000 Hz UART=115200 TX_FPIOA=0
```

默认 `ITERATIONS=0` 使用 CoreMark 自动迭代选择；正式成绩需使用满足基准运行时间要求的完整运行，并核对最终 CRC。不要把下述单迭代仿真当作分数。

## 离线验证命令与结果

在仓库根目录运行：

```sh
python3 tools/run_soc_tests.py config
python3 tools/run_soc_tests.py full
python3 tools/run_soc_tests.py bram
python3 tools/run_soc_tests.py all
```

`config` 检查菜单配置、地址定义和生成头文件，并默认用伪终端启动菜单检查其可打开。`full` 运行完整 DDR/Camera 既有回归；`bram` 运行 BRAM 启动/顶层 profile smoke、CPU BRAM、ISA、load/store、CSR/timer 和 CoreMark 单迭代 CRC fixture；`all` 先做配置检查，再运行 full 和 BRAM。命令不调用 PDS、板卡或 Flash 烧写工具，输出保存在 `build/`。

建议优先使用该 runner，而不是直接调用各个 `make` 仿真目标：runner 会传入 RTL include 路径并协调 Icarus 与 Verilator 的不同构建方式。若手动运行顶层 Verilator 目标，需像 runner 一样指定 `VERILATOR='verilator -Isoc'`；直接运行 Icarus 命令时也要加 `-Isoc`。

重点启动 bench 也可独立运行：

```sh
bash sim/run_bram_boot_checks.sh
```

它使用真实 SPI 字节读取器和 `cpu_bram_mem`，检查 32776 字节流从测试 Flash 地址 `0x5A3210` 读取、从 IRAM 跨到 DRAM、逐字读回、超时和校验失败时保持 reset、复位后重试，以及实际 BRAM 顶层程序启动。profile lint 覆盖 DDR、BRAM 和 `PREPROCESS_ENABLE=1` 的 full 结构。仿真用 behavioral PLL/IO stubs；JTAG 只保持空闲，lint 对现有 JTAG RTL 的既有警告采用文件范围 waiver，因此这不是 JTAG、电气、PLL/IP 实现或 DDR PHY 验证。

最终聚合命令 `python3 -B tools/run_soc_tests.py all` 已通过，退出码为 0；日志保存在 `build/verification/soc_all_suite.log`。测试覆盖配置和生成头文件、完整 DDR/Camera 回归、BRAM SPI 装载和顶层启动、Full/BRAM 各 46 项 ISA、CPU BRAM/memory/Hifu/MEM stall、CSR/timer、CoreMark CRC，以及 full profile 的 preprocessing 组合。新增 BRAM 测试使用实际串行 Flash 模型和 `cpu_bram_mem`，覆盖配置长度、IRAM 到 DRAM 的跨界、读回校验、超时、错误保持 reset 与复位重试；顶层 smoke 运行 Flash 中的小程序并检查 LED 写入。完整 full suite 还覆盖 Camera/DMA、NPU 相关现有路径、cache bypass 和 UART/FPIOA 资源检查。

这些是仿真、语法和 profile lint 结果。PDS 工程中新增文件路径已登记并通过静态检查，但尚未由本次工作在 PDS 中综合或生成位流；目标器件 RAM 映射、时序、引脚和实板启动仍由用户在 PDS 和板上确认。

单迭代 CoreMark fixture 的作用是验证启动、UART 字节和 CRC；它会触发运行时间短于 10 秒的预期提示，并可能打印 `Errors detected`。这是短 fixture 的预期提示，不是 CRC 不匹配，也不是有效成绩。RTL/模拟器还不能证明目标器件实际 BRAM 资源和时序，也不能代替用户在 PDS 生成位流、Flash 校验及上电观察。
