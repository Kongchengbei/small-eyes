# SoC DDR / BRAM 配置、构建与启动

本文说明如何使用仓库自带的原生 Kconfig 菜单，在 WSL 选择 DDR／BRAM 配置及 CPU 频率，生成配置头文件和 Flash manifest，并准备 PDS 烧写。配置入口是 `make menuconfig`；保存会同步 RTL 参数、CPU 时钟 FDC 倍率和 BSP 生成头文件，不会启动 PDS、修改 PLL IP、生成位流或烧写 Flash。

## 两种硬件配置

| 配置 | `SOC_CPU_MEM_BRAM` | 硬件组成 | 启动目标 |
| --- | ---: | --- | --- |
| Full DDR（默认） | 0 | ICache、DCache、DDR3、Camera；预处理默认关闭，可在 full 配置中单独开启 | 等待 DDR 初始化后从 Flash 搬到 DDR `0x80000000` |
| CoreMark BRAM | 1 | ICache、DCache、DDR3、Camera、预处理及运行期 Flash 搬运均关闭；保留 PLL、CPU、UART、FPIOA、CSR/timer、JTAG/debug | 用户 DAT/HEX 生成 IMEM IP 初始化参数，随位流进入 BRAM，从 `0x80000000` 执行 |

BRAM 地址布局固定为 IRAM `0x80000000`、32 KiB，紧接着 DRAM `0x80008000`、16 KiB。保留原 `bsp/bsp_app/link.lds`：代码和 `.data` 初值装载映像放在 IRAM，程序启动时复制 `.data` 到 DRAM，并清零 `.bss`；栈仍在 DRAM，固定 4 KiB。本次没有修改 CoreMark 源码、迭代次数、编译选项或链接脚本。DAT 必须由适合这套地址布局的程序转换而来，最多 8192 个 32 位字。

Full DDR profile 中使用 DDR 的逻辑地址范围，不会实例化这两块本地 BRAM。若后续 NPU 实现需要空间，可在评估地址图、仲裁与带宽后重新规划这些逻辑资源；本次没有增加 NPU 计算单元或缓冲区。

默认选择 Full DDR：`SOC_CPU_MEM_BRAM=0`。`soc/soc_addr_map.vh` 是 SoC memory/peripheral base、已实现的 MMIO offset/control bit 和 profile 配置值的唯一维护来源。菜单保存时会在其中应用 profile、CPU 频率、Flash 起始地址、映像长度和 UART TX FPIOA 引脚。C/汇编配置头文件以及 manifest 默认生成到 `build/menuconfig/`，同时同步 BSP 生成头文件到 `bsp/include/`。

生产 BRAM 配置通过 `cpu/cpu_bram_ip_mem.v` 例化恢复的 `IP/imem` 和 `IP/dmem` 厂商双端口 RAM。IMEM 的 A 口用于取指，B 口用于 LSU 读取代码／初始数据；DMEM 的 B 口用于运行期读写，A 口闲置。同步 RAM 的读数据和 response-valid 随时钟返回，沿用当前 CPU 的等待接口；范围外的 MMIO 仍走现有 AXI backend。`Htop` 用 `BRAM_VENDOR_IP=1` 选择厂商实现，旧推断式 RAM 仅保留用于独立单元测试。两种实现不会在生产配置中同时例化。

生产 BRAM 配置不例化 `flash_bram_boot`，其编程接口固定闲置，Flash 片选保持无效。程序已经存在于 RAM 的初始化参数中，PLL 锁定、复位同步和原有复位计数结束后直接释放 CPU。`core_active` 表示 CPU 已解除复位，不表示 CoreMark 已完成。UART/FPIOA 没有关闭。旧 Flash→BRAM 装载器源码保留作为独立测试，不再是 BRAM 生产启动路径。

## 环境准备

首次构建原生菜单需要 GCC、GNU Make、Flex、Bison 和 ncurses 开发文件；菜单前端与 C 配置工具由仓库源码本地构建。构建 BSP 还需要 `riscv-gcc` 与 `picolibc.specs`。配置菜单本身不依赖 Python。PDS 在 Windows 环境中由用户操作。

## 在 WSL 选择并生成配置

在 WSL 终端进入仓库根目录，打开标准 Kconfig 菜单：

```sh
cd /mnt/f/SocFpga
make menuconfig
```

用方向键移动、Enter 进入或切换选项。Full DDR 显示 Firmware BIN、Flash 起始地址和 Loader image bytes；CoreMark BRAM 隐藏这些无关项，改为显示 Firmware HEX/DAT path。BRAM 必须选择有效 DAT 后才能保存应用，例如 `test/coremark_local.dat` 或 `/mnt/f/SocFpga/test/coremark_local.dat`。WSL 菜单填写 Linux 路径，不填 `F:\...`。

DAT 每个词必须是 8 位十六进制数，大小写、Windows CRLF 和空白均可，最多 8192 个字；原始 BIN 不接受。不足 8192 字时，余下 IMEM 填充 `00000013`。保存自动生成 `IP/imem/rtl/imem_init_param.v`，保持厂商 RAM 的参数排列，不要求手工重新生成 IP。`imem_init_words.hex` 是核对／仿真文件，PDS 实际使用 INIT 参数。文件内容变化但路径不变时，也需要明确 Save 再退出。初始化内容变化还会更新工程已列出的 `IP/imem/imem.v` 中的指纹注释，便于 PDS 识别普通 RTL 文件已变；请仍明确执行重新编译，不仅依赖 GUI 的提示。

修改完成后按 Esc 两次，在是否保存的询问中选择 Yes；或 Tab 选 Save，保持默认配置文件名后 Exit。另存到其他路径不会应用工程。Discard 不改 RTL。只有保存到默认配置且通过校验后才更新工程。

默认配置是 `build/menuconfig/.config`，输出包括 `soc_defs.h`、`soc_defs_asm.inc`、`flash_manifest.json`、`clock_config.json`。BRAM 另生成 `bram_init_manifest.json`，并将 `SOC_BOOT_IMAGE_BYTES` 置 0，表示不使用运行期 Flash 装载；其 Flash manifest 明确标为禁用、无需 User Load。DDR 的 0 则仍表示自动采用 BIN 长度，最终 RTL 得到实际非零长度。

环境变量 `SOC_CONFIG_SOURCE`、`SOC_CONFIG_FILE`、`SOC_CONFIG_OUTPUT`、`SOC_CONFIG_FDC`、`SOC_CONFIG_BSP_OUTPUT`、`SOC_CONFIG_BRAM_INIT_DIR` 可覆盖对应路径。隔离测试需一起覆盖 FDC、BSP 和初始化目录，避免修改仓库默认文件。BIN/DAT 相对路径从仓库根目录解析。

本项目构建 Kconfig 工具时启用 `KCONFIG_NO_SYMBOL_DEPFILES`，不再生成 `include/config/soc/**/*.h` 这类空白逐项依赖标记文件；项目未使用 Kbuild 的逐项依赖机制。`.config`、`auto.conf`、`autoconf.h` 和配置依赖清单仍正常生成。已有的空白标记文件不会自动删除，也不需要手动填写。可运行 `make kconfig-test` 验证首次生成、配置变更及旧配置项移除后的输出。

如果需要修改固件源码／软件时钟配置，仍按项目原有方式构建 BSP：

```sh
make -C bsp/bsp_app/example/coremark clean
make -C bsp/bsp_app/example/coremark all
wc -c bsp/bsp_app/example/coremark/coremark.bin
```

构建后，DDR 选择新 BIN 并按其长度保存；BRAM 使用你自己的转换工具得到 DAT 后选择它。仅在 DDR/BRAM 间切换，如果已有固件的链接布局、软件频率和引脚配置兼容，不要求重新编译固件。本次直接使用用户提供的 `test/coremark_local.dat`，未重新构建 CoreMark。

```sh
make menuconfig
```

Full DDR profile 可选开启 preprocessing；CoreMark BRAM 会关闭 cache、DDR、Camera 和 preprocessing。保存会同步 `bsp/include/soc_defs.h` 和 `soc_defs_asm.inc`。单目、双目及 CoreMark 的构建入口也会按当前 RTL 检查／生成头文件，并把头文件作为对象依赖；频率变化后直接重新 `make` 即可，无须为了更新频率手动清理对象。内容未变时保留头文件时间戳，不触发无意义重编译。

当前 CoreMark BSP 端 `COREMARK_UART_TX_FPIOA` 固定为 0，菜单中的 UART pin 只配置 RTL FPIOA，并未接入 CoreMark 编译参数。因此选择远程 pin 31 不会自动改变固件串口引脚。时钟联动没有改变这个引脚选择行为或 linker script。

## CPU 频率配置与联动

菜单新增 `CPU clock frequency (Hz; soc/soc_addr_map.vh)`，默认仍为 70000000。这里填的是 **CPU PLL 输出频率**，不是板上 27 MHz 输入时钟。

保存时统一更新 `SOC_CPU_HZ`、FDC 的 CPU 时钟倍率和 BSP 头文件；CPU 频率 CSR 默认值从同一配置计算。另生成 `clock_config.json`，记录频率、CSR、FDC 倍率、CPU 域异常超时周期和需手工设置 PLL 的提示。保存前验证所有文本输出，写入失败时尝试回退已替换文件；这不是断电／进程崩溃情况下的跨文件原子事务。失败后先修正错误并重新保存，不要直接综合部分配置。

| 项目 | 规则 |
| --- | --- |
| 配置范围 | 1 MHz～327.67 MHz，且为 10 kHz 整数倍；这是现有 CSR 的编码范围，不是 FPGA 可运行频率承诺 |
| CSR `mimpid` | 保留容量信息位，低 15 位为 `SOC_CPU_HZ / 10000` |
| FDC | 固定按板上 27 MHz 输入计算 CPU 倍率；同步 PLL／JTAG 层级路径，以及 10 个 DQS／CK 引脚的 profile 电气标准；引脚位置、电压及其他约束不变 |
| BSP 构建 | 同步频率头文件，并使依赖它的固件对象在配置变化后重新编译 |
| CPU 域异常超时 | `soc/soc_timeout.vh` 保持原 70 MHz 下的启动握手约 1.43 ms、诊断快照约 14.29 ms、DDR 初始化约 1 s 上限；周期数向上取整 |
| 外设速度 | 不修改 SPI 分频、SCCB 延时、摄像头配置／帧率、DMA 时钟或数据通路 |
| 不变的时钟域 | DDR、Camera PCLK、NPU 运算和 JTAG；这些域的 DMA／前处理超时不按 CPU 频率修改 |

例如设置 90 MHz 后，FDC 倍率为 `10/3`，CSR 为 `0x10202328`。软件／配置回归覆盖 70、90、100、70.5 MHz 及编码边界；不代表这些频率已通过实板时序。

异常超时仅决定多久收不到应答才报错，不要求设备等待至上限：正常应答到来后仍按原状态机立即继续。计算为编译期常量，不增加运行时除法器、限速器、帧间等待或 DMA 背压逻辑。仅按 CPU 时钟缩放这三类硬件异常上限，DDR 域 DMA 超时、软件轮询次数与 SCCB 忙等保持原实现。

保持 SPI 分频和 SCCB 延时源码不变，不代表提频后外部通信速度不变：固定分频产生的 SPI 时钟仍会随 CPU 提频变快，软件忙等的实际时间可能缩短。这是未限速的结果；若超过器件规格，仍可能出现真实通信故障，异常超时修正不能修复该故障。需另外检查外设协议兼容性，PDS timing report 不能替代该检查。本次不生成新 Camera BIN，也不运行 PDS 或生成 bitstream。

使用步骤：

1. `make menuconfig` 填写频率并保存。
2. 重新构建所用固件，例如 `make -C bsp/camera_stereo_app all diagnostics`。
3. 再打开菜单，选择新 BIN；若需精确长度，Loader image bytes 设为 0，然后保存。
4. 在 PDS 中手工把实际 PLL 输出设为相同频率，重新综合／布局布线／生成位流。
5. 检查约束导入、时钟和时序报告。自动生成的 `get_pins` 路径及 JTAG 内部连线必须实际命中，尤其切换 DDR／BRAM profile 后；本工具不能替代 PDS 的对象解析和 STA。
6. 烧录匹配的新位流与固件。旧位流、新频率固件不能混用。

FDC 中使用 PDS 编译日志的命名规则：generate 命名块与对象之间用 `.`，模块实例层级用 `/`。DDR profile 的 PLL pin 为 `g_ddr_profile.u_pll/u_gpll:CLKOUT0`，JTAG net 为 `g_ddr_profile.JTAG_TCK_in`；BRAM profile 分别为 `g_bram_profile.u_bram_profile/u_pll/u_gpll:CLKOUT0` 和 `g_bram_profile.u_bram_profile/JTAG_TCK_in`。只生成当前 profile 的一组约束，不同时引用未实例化的分支。上述端点根据当前 RTL 和编译日志推导，仍需 PDS 当前设计视图验证，不表示已经通过综合或布局布线。

BRAM profile 没有 DDR PHY。保留的 `mem_ck`／`mem_ck_n` 分别是常量 0／1，`mem_dqs[3:0]`／`mem_dqs_n[3:0]` 是高阻，综合后是普通输出／三态缓冲器，不是差分 DDR 缓冲器。这 10 个端口只在 BRAM 模式使用单端 `HSTL15_I`，切回 DDR 模式自动恢复原来的 `HSTL15D_I`。所有 DDR 引脚位置、1.5 V VCCIO、方向、驱动、SLEW 和终端属性保持不变；DDR reset 仍拉低、CKE 仍拉低、CS 仍拉高，DQ／DQS 仍高阻。未使用的差分参考输入 `clk_p/n` 仍沿用原约束并由 PDS 按 dangling 忽略，不全局替换差分标准。

配置工具要求上述每个端口恰好有一条标准约束，缺失、重复或未知标准会在写入前拒绝更新。此修正针对已有 BRAM 网表与差分标准不匹配的报错，仍需实际 PDS 重新综合／device map／place & route 验证；仿真与文本检查不证明电气检查或时序通过。缺少 SLEW／DRIVE 及 share-pin 的提示与本次阻塞错误不同，本次不为消除提示统一修改其他引脚电气属性。

可运行 `make config-check` 检查 RTL、FDC 倍率／profile 路径／DDR 引脚标准及 BSP 头文件是否一致；`make config-test` 在临时副本测试频率与 DDR／BRAM 双向切换、旧 JTAG／PLL 路径与不匹配 IO 标准检测、管理块格式／写入失败保护、旧配置迁移及 CPU 频率 CSR RTL，并逐字比较其他引脚约束不变。修改频率或 profile 必须提供 `--fdc`，菜单入口已自动提供。`make config-headers` 只按当前 RTL 重生成 BSP 头文件，不修改 PLL 或 FDC。

## DDR 镜像长度、对齐和 manifest

历史 CoreMark BIN 曾为 29144 字节；频率联动或其他代码修改后长度可能改变。每次构建后用 `wc -c` 查看实际长度，再选择新 BIN 并将 Loader image bytes 设为 0。不要沿用历史长度或仅因默认值为 32768 就把短 BIN 按 32768 字节读取。

装载长度必须大于零且是 4 字节整数倍，且不能小于所选 BIN；可以大于 BIN，以便按 `0xFF` 补齐。Flash 起始地址也必须 4 字节对齐。SPI 读地址是 24 位，逻辑可寻址范围为 `[0x000000, 0x1000000)`；这不代表已确认外部 Flash 器件的物理容量。从 `0xA00000` 起的 6 MiB 只是该 24 位逻辑窗口中剩余的地址范围。保存时配置工具会检查 `FLASH_BASE + BOOT_IMAGE_BYTES` 不越过窗口。

若明确需要把装载长度设得比 BIN 大，在菜单中输入 4 字节对齐的较大长度，配置工具会保留输入文件不变，另生成 `build/menuconfig/<名称>.padded-<长度>.bin`，并在 manifest 中记录 `0xFF` 填充字节数。此时 PDS 应烧写 manifest 列出的 padded 文件，而不是较短的原文件。若文件长度不是 4 的倍数，应将 loader 长度设为下一个 4 字节边界，让工具生成填充产物。默认 CoreMark BIN 长度已对齐，无需填充。烧写使用原始小端 `.bin` 字节；不要使用仿真专用的 reverse-bytes 文件。

Manifest 至少列出 profile、输入 BIN、实际输入大小、loader 长度、Flash 起始及结束地址、填充文件和填充值。它是给操作者核对 PDS 烧写设置的记录，不是 PDS 工程，也不会自动生成烧写包：

```text
build/menuconfig/flash_manifest.json
```

## 生成 profile 位流并在 PDS 烧写

先在 WSL 保存配置，再在 Windows/PDS 打开现有工程。`project/project.pds` 已加入 `cpu/cpu_bram_ip_mem.v` 和 `IP/imem`、`IP/dmem` 的 wrapper／底层 RTL。`imem_init_param.v` 是模块内部 include，不作为独立 Verilog 顶层文件列入。没有加入会引用旧绝对 DAT 路径的 IDF，也不需要打开 IP 编辑器重生成。按所选 profile 重新编译、综合、布局布线、生成位流；BRAM 的 DAT 内容变化也必须重新生成位流。

BRAM：只烧录新位流，程序随位流进入 IMEM；不需要将 CoreMark BIN／DAT 放到 User Load `0xA00000`。Flash 旧用户区内容不影响这条启动路径。

DDR：仍按 Flash manifest 烧写程序 BIN，典型地址为 `0x00A00000`；若指定 padded 文件则使用它。位流仍放配置区。不要把文本 DAT 当作 DDR 装载器的原始 BIN。

本次没有运行 PDS、生成 `.sbit` / `.sfc` 或做实板验证。厂商 RAM 模型的例化和仿真通过不替代目标器件的综合、资源、引脚、布线与时序检查；这些由用户完成。关闭外设是否满足赛事规则，应以赛事原文为准，本次没有对 CoreMark 程序作专项优化。

## 上电后启动过程

Full DDR 启动后，DDR 控制器先初始化；启动逻辑从 Flash 基址读取原始映像，按每 4 字节小端组字写到 DDR `0x80000000`，读回校验后释放 CPU。BRAM 不等待 DDR、不读取 Flash，配置位流中的 INIT 参数已经填入 IMEM，时钟／复位准备完成即可执行。

DDR 的 SPI 通路仍为 X1、模式 0、`03h` 和 24 位地址。BRAM 无这一步。两种配置中，本地 CoreMark UART 默认 115200、FPIOA0，预期启动提示为：

```text
Start CoreMark CPU=70000000 Hz UART=115200 TX_FPIOA=0
```

本次保留输入 DAT/BIN 已有的迭代设置，没有修改迭代次数。正式成绩仍需满足基准运行时间要求并核对最终 CRC；启动仿真不能作为成绩。

## 验证范围

历史验证曾覆盖 DDR/Camera 与 BRAM 仿真、SPI 装载、CPU ISA、CSR/timer 和 CoreMark CRC fixture；短迭代 fixture 会显示运行时间不足 10 秒的提示，不能作为成绩。当前根 Makefile 支持 `make all=<testbench 名称>run`，可用 `make sim-list` 查看测试列表。任何仿真结果都不能证明目标器件的 BRAM 映射、时序、引脚和实板启动；这些仍由用户在 PDS 与板上确认。

### BRAM 模式的实际 DAT / 厂商 RAM 串口启动测试

```sh
make bram-init HEX=test/coremark_local.dat
make all=tb_cpu_bram_ip_memrun SIM_TIMEOUT=30
make all=tb_coremark_bram_ip_uartrun SIM_TIMEOUT=90
```

`tb_cpu_bram_ip_mem` 通过实际 PDS `GTP_DRM36K_E1` 仿真模型，核对 IMEM 全部 8192 字、LSU 的 IRAM 读取和 DMEM 的字节写掩码。`tb_coremark_bram_ip_uart` 从当前生成的 INIT 参数启动完整 `Hfpga_soc`，没有 Flash 模型、测试台预填 RAM 或强制跳过 CPU 启动。`PDS_SIM_DIR` 可指定厂商仿真模型目录，默认使用本机 PDS 安装路径。

仿真 PLL 按配置 CPU 频率运行；独立接收器从顶层 `fpioa[0]` 按 115200、8N1 解码 55 字节启动提示，检查编程接口和 Flash 保持闲置。成功后打印 PASS。旧 `tb_coremark_bram_uart` 的 Flash→BRAM 生产启动假设已过时，不能用其旧结果代表当前路径。

该测试只验证启动提示，不等待最终 CoreMark 得分和 CRC。厂商 RAM 使用实际模型，但 PLL／IO 等仍有仿真替代，不能证明实板串口、PLL 或时序通过；最终还需烧写新位流验证。
