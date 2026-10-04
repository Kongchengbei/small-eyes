# SoC DDR / BRAM 配置、构建与启动

本文说明如何使用仓库自带的原生 Kconfig 菜单，在 WSL 选择完整 DDR 应用配置或 CoreMark BRAM 配置，生成配置头文件和 Flash manifest，构建原 BSP 镜像，并准备 PDS 烧写。唯一配置入口是标准 `make menuconfig`；菜单不会修改 BSP 文件，也不会启动 PDS、生成位流或烧写 Flash。

## 两种硬件配置

| 配置 | `SOC_CPU_MEM_BRAM` | 硬件组成 | 启动目标 |
| --- | ---: | --- | --- |
| Full DDR（默认） | 0 | ICache、DCache、DDR3、Camera；预处理默认关闭，可在 full 配置中单独开启 | 等待 DDR 初始化后从 Flash 搬到 DDR `0x80000000` |
| CoreMark BRAM | 1 | ICache、DCache、DDR3、Camera、预处理均关闭；保留 PLL、CPU、UART、FPIOA、CSR/timer、JTAG/debug | Flash 镜像进入本地 IRAM/DRAM，校验完成后从 IRAM `0x80000000` 开始执行 |

BRAM 地址布局固定为 IRAM `0x80000000`、32 KiB，紧接着 DRAM `0x80008000`、16 KiB。`bsp/bsp_app/link.lds` 已按该地址规划：代码与初始化数据的 Flash 装载映像放在 IRAM，运行期 `.data`、`.bss` 和栈放在 DRAM，栈固定 4 KiB。镜像装载器总容量为 48 KiB；当前 CoreMark `.bin` 是 29144 字节，能放进 32 KiB IRAM。若换软件，除了 48 KiB 总容量，还要确认链接产生的代码及 `.data` 初值装载范围能放进 IRAM。

Full DDR profile 中使用 DDR 的逻辑地址范围，不会实例化这两块本地 BRAM。若后续 NPU 实现需要空间，可在评估地址图、仲裁与带宽后重新规划这些逻辑资源；本次没有增加 NPU 计算单元或缓冲区。

默认选择 Full DDR：`SOC_CPU_MEM_BRAM=0`。`soc/soc_addr_map.vh` 是 SoC memory/peripheral base、已实现的 MMIO offset/control bit 和 profile 配置值的唯一维护来源。菜单保存时会在其中应用 profile、Flash 起始地址、映像长度和 UART TX FPIOA 引脚。C/汇编配置头文件以及 manifest 默认生成到 `build/menuconfig/`，不会复制到或改写 `bsp/include/`。

BRAM CPU 的取指接口按同步 IRAM 时序工作：请求地址被接受后，指令数据与 response-valid 随时钟返回。CPU 复位期间，Flash 装载器取得 RAM 编程端口；写在 `valid && ready` 时完成，读回请求在一个时钟后伴随 `ready` 和对应数据应答。校验完成、CPU reset 释放后，该端口转由 LSU 使用。IRAM 的另一端口供取指，DRAM 为单端口 RAM。BRAM 地址内的 LSU 请求由本地 RAM 处理，范围外的 MMIO 请求走现有 AXI backend；load 会等待数据 response-valid，store 等待 ready，保证同步读延迟不会提前放行流水线。为此，Htop 增加 profile 生成选择和 BRAM 端口连接，Hifu 增加同步取指队列与预测处理，Hexu 以 MEM 接受状态门控 EX 请求，Hmemu 在 WB 停顿时保留已返回的 load 数据。BRAM profile 会移除 ICache、DCache、DDR bridge/controller 和 Camera 实例。

## 环境准备

首次构建原生菜单需要 GCC、GNU Make、Flex、Bison 和 ncurses 开发文件；菜单前端与 C 配置工具由仓库源码本地构建。构建 BSP 还需要 `riscv-gcc` 与 `picolibc.specs`。配置菜单本身不依赖 Python。PDS 在 Windows 环境中由用户操作。

## 在 WSL 选择并生成配置

在 WSL 终端进入仓库根目录，打开标准 Kconfig 菜单：

```sh
cd /mnt/f/SocFpga
make menuconfig
```

用方向键移动、Enter 进入或切换选项，选择 Full DDR 或 CoreMark BRAM，设置 Flash 起始地址、映像长度、固件 BIN（若已存在）和 UART TX FPIOA pin。首次构建时 BIN 尚不存在，可先留空，但 loader 长度应保持或输入非零的 4 字节对齐值；当前 map 的历史默认值为 32768。保存时会生成 `input_bin: null` 的无固件 manifest，避免留下旧 BIN 清单。修改完成后按 Esc 两次，在是否保存的询问中选择 Yes，保存并退出；也可以按 Tab 选中 Save，保持默认配置文件名保存后，再选择 Exit 退出。另存到其他路径的配置不会应用到工程 RTL。按 Esc 两次返回并退出时，若出现保存询问并选择 No，会丢弃本次菜单更改。只有保存到默认配置文件且通过校验的配置才会应用到 `soc/soc_addr_map.vh`。

默认配置文件是 `build/menuconfig/.config`，默认输出目录是 `build/menuconfig/`，其中包含 `soc_defs.h`、`soc_defs_asm.inc`、`flash_manifest.json`，以及必要时的 `0xFF` padded BIN。未选择 BIN 时 manifest 会记录 `input_bin: null`、输入大小 0，且不会复制或生成 BIN 文件。首次打开菜单会依据当前 `soc/soc_addr_map.vh` 初始化 `.config`；后续打开保留已保存的菜单选择。环境变量 `SOC_CONFIG_SOURCE`、`SOC_CONFIG_FILE`、`SOC_CONFIG_OUTPUT` 可将输入、配置和生成目录指向其他位置，主要用于隔离配置操作。Kconfig 菜单进程在输出目录运行；固件 BIN 路径仍相对于仓库根目录解析。

本项目构建 Kconfig 工具时启用 `KCONFIG_NO_SYMBOL_DEPFILES`，不再生成 `include/config/soc/**/*.h` 这类空白逐项依赖标记文件；项目未使用 Kbuild 的逐项依赖机制。`.config`、`auto.conf`、`autoconf.h` 和配置依赖清单仍正常生成。已有的空白标记文件不会自动删除，也不需要手动填写。可运行 `make kconfig-test` 验证首次生成、配置变更及旧配置项移除后的输出。

先保存 profile 和软件选项，再按项目原有方式构建 BSP：

```sh
make -C bsp/bsp_app/example/coremark clean
make -C bsp/bsp_app/example/coremark all
wc -c bsp/bsp_app/example/coremark/coremark.bin
```

构建完成后再次打开菜单，选择刚生成的 BIN，并将 Loader image bytes 设为 0（自动使用 BIN 精确长度），然后保存默认配置并 Exit。若固件内容或长度改变，重新选择新 BIN 并保存 manifest。任何会影响 RTL 的 profile、Flash 起始地址或装载长度变化，都需要生成与新设置匹配的位流。

```sh
make menuconfig
```

Full DDR profile 可选开启 preprocessing；CoreMark BRAM 会关闭 cache、DDR、Camera 和 preprocessing。Kconfig 会阻止不支持的 profile/预处理组合。BSP Makefile、linker script、CoreMark 源码和 BSP 输出均保持原样；`build/menuconfig/` 中的生成头文件不会自动同步进 BSP。

当前 CoreMark BSP 端 `COREMARK_UART_TX_FPIOA` 固定为 0，菜单中的 UART pin 只配置 RTL FPIOA，并未接入 CoreMark 编译参数。因此选择远程 pin 31 不会自动改变固件串口引脚。本文不修改 BSP Makefile、`link.lds`、CoreMark 源码或 BSP BIN。

## 镜像长度、对齐和 manifest

本次默认 BSP 产物 `coremark.bin` 为 29144 字节（`0x71D8`）；起始地址 `0x00A00000`，因此映像结束地址（不含）为 `0x00A071D8`。每次构建后用 `wc -c` 查看实际长度，在菜单选择该 BIN 并将 Loader image bytes 设为 0，使 manifest 记录 BIN 精确长度。不要仅因历史默认值为 32768 就把短 BIN 按 32768 字节读取。

装载长度必须大于零且是 4 字节整数倍，且不能小于所选 BIN；可以大于 BIN，以便按 `0xFF` 补齐。Flash 起始地址也必须 4 字节对齐。SPI 读地址是 24 位，逻辑可寻址范围为 `[0x000000, 0x1000000)`；这不代表已确认外部 Flash 器件的物理容量。从 `0xA00000` 起的 6 MiB 只是该 24 位逻辑窗口中剩余的地址范围。保存时配置工具会检查 `FLASH_BASE + BOOT_IMAGE_BYTES` 不越过窗口。

若明确需要把装载长度设得比 BIN 大，在菜单中输入 4 字节对齐的较大长度，配置工具会保留输入文件不变，另生成 `build/menuconfig/<名称>.padded-<长度>.bin`，并在 manifest 中记录 `0xFF` 填充字节数。此时 PDS 应烧写 manifest 列出的 padded 文件，而不是较短的原文件。若文件长度不是 4 的倍数，应将 loader 长度设为下一个 4 字节边界，让工具生成填充产物。默认 CoreMark BIN 长度已对齐，无需填充。烧写使用原始小端 `.bin` 字节；不要使用仿真专用的 reverse-bytes 文件。

Manifest 至少列出 profile、输入 BIN、实际输入大小、loader 长度、Flash 起始及结束地址、填充文件和填充值。它是给操作者核对 PDS 烧写设置的记录，不是 PDS 工程，也不会自动生成烧写包：

```text
build/menuconfig/flash_manifest.json
```

## 生成 profile 位流并在 PDS 烧写

先在 WSL 保存配置，再交由操作者在 Windows/PDS 中打开现有工程。PDS 用户负责确认项目包含新 RTL 文件 `soc/Hfpga_soc_bram_profile.v`、`soc/flash_boot/flash_bram_boot.v` 和 `cpu/cpu_bram_mem.v`，然后按所选 profile 重新执行编译、综合、布局布线和位流生成。BRAM 选择 `SOC_CPU_MEM_BRAM=1`；Full DDR 使用 0。更改 profile、Flash 起始地址或装载长度后，都要生成匹配的新位流；同 profile 下若新 BIN 长度变化，也要更新长度配置并生成新位流。只有 profile、基址和长度都未变时，才可直接替换并重新烧写 BIN。

在 PDS Flash 烧写页，按 manifest 使用对应软件文件和 `flash_start_address`。典型组合是 FPGA 配置位流放在配置区地址 `0x000000`，原始程序 BIN 放在用户区 `0x00A00000`；如果 manifest 指定 padded 文件，则使用该文件。烧写后在 PDS 执行擦除/编程/校验时，确保校验对象与 manifest 的文件及地址完全一致。

本文没有运行 PDS，也没有生成新 `.sbit` / `.sfc`、烧写 Flash、下载位流或做实板验证。RTL 文件进入工程和离线仿真都不能替代 PDS 对目标器件的综合、资源、引脚、布线和时序确认。BRAM RAM 的通用 RTL/Yosys 检查显示 IRAM 为同步双端口、DRAM 为同步单端口；目标 Pango 器件的实际 BRAM 推断数量和映射仍待用户在 PDS 中检查。

## 上电后启动过程

Full DDR 位流启动后，DDR 控制器先完成初始化；启动逻辑再从 Flash 基址读取配置长度的原始映像，按每 4 字节小端组字，写入 DDR `0x80000000` 并逐字读回校验。BRAM 位流启动不等待 DDR：装载逻辑从 Flash 读取同样格式的原始映像，写到 IRAM，再按同步 RAM 接口逐字读回校验。两种 profile 均在校验完成后释放 CPU reset；Flash 地址越界、长度不合规、超时或读回不匹配都会保持 CPU reset。外部复位可重新启动装载流程。

当前 SPI 通路使用单颗 Flash、X1、模式 0、`03h` Read Data 命令和 24 位字节地址。镜像没有自定义头部、校验和或字节序转换；加载器读多少字节由生成到 RTL 的 `SOC_BOOT_IMAGE_BYTES` 决定。启动后本地 CoreMark UART 默认 115200、FPIOA0，预期起始提示为：

```text
Start CoreMark CPU=70000000 Hz UART=115200 TX_FPIOA=0
```

默认 `ITERATIONS=0` 使用 CoreMark 自动迭代选择；正式成绩需使用满足基准运行时间要求的完整运行，并核对最终 CRC。短迭代仿真输出不能作为成绩。

## 验证范围

历史验证曾覆盖 DDR/Camera 与 BRAM 仿真、SPI 装载、CPU ISA、CSR/timer 和 CoreMark CRC fixture；短迭代 fixture 会显示运行时间不足 10 秒的提示，不能作为成绩。当前根 Makefile 已按要求精简为原生 Kconfig 菜单入口，不再提供此前的硬件回归调度目标。任何仿真结果都不能证明目标器件的 BRAM 映射、时序、引脚和实板启动；这些仍由用户在 PDS 与板上确认。
