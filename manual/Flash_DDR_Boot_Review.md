# Flash → DDR → CPU 流水灯启动 review

## 当前目标与状态

**实板状态更新（2026-09-26）**：用户已通过 JTAG Boundary Scan 的 FPGA 桥接路径，对一颗 Outer Flash 完成擦写及多次 Verify；第二颗未烧写。实际扫描 ID 为 `0x0B4018`，PDS 通过 Add Flash 自定义 `xt25f128`，使用 WINBOND/W25Q NOR 兼容模板并按 128 Mbit / 16 MiB 配置。这不能证明实物丝印型号为 W25Q128JV，后者只是手册可选型号。Convert File 将 `.sbit` 放在地址 0、56-byte `running_led_test.bin` 放在 `0x00A00000`；`Hfpga_soc.FLASH_BASE` 默认与此一致。`.sbit` 大小 9,188,552 bytes（`0x8C34C8`），最新 `.sfc` 为 10,485,816 bytes，载荷已比对。用户记录的一轮操作为擦除 35.5 秒、编程 170.6 秒、Verify 11.0 秒，随后再次 Verify 10.8 秒成功；本地日志还有同 ID `b4018` 的另一轮成功擦写和校验记录。这些操作都指向同一选中器件，不能据此称第二颗 Flash 已写入。尚无断电自主启动、DDR 搬运读回或 CPU 流水灯实板成功确认，详见[实板烧写记录](PG2L200H_Flash烧写与DDR启动实板记录.md)。

这次实现针对已确认的 PG2L200H-FBB676 工程，目标是从单颗 Outer Flash 用户区读取 56-byte RV32 程序，写到 DDR `0x80000000`，读回逐字比较成功后才允许 Htop CPU 从该地址取指并运行流水灯。本次实际扫描 ID 为 `0x0B4018`，PDS 用 `xt25f128` 自定义项和 WINBOND/W25Q NOR 兼容模板；手册中的 W25Q128JV 是可选型号，并非本次实测身份。LED MMIO 地址为 `0x40000200`。DDR BIST 已由用户确认通过，此流程不要求重复 BIST。

tracked 镜像是 `test/running_led_test.dat`：14 个 word、56 bytes。忽略文件 `test/running_led_test.bin` 同为 56 bytes，前 16 个小端字节是 `B7 02 00 40 93 82 02 20 13 03 10 00 B7 EE 16 00`。镜像固定放在 Flash `0x00A00000`（PDS user address `00a00000`），位流地址 0。SPI 使用 X1、24-bit 地址、模式 0、普通读 `03h`，每次读取 1 byte，无 dummy cycle。

最终回归由集成测试代理报告通过：`make flash-ddr-boot-test` 覆盖 DDR init 延迟 100050 cycles（150000-cycle 独立等待预算内）、56-byte DDR copy、readback mismatch 错误码 6 并保持 CPU reset、运行真实 `running_led_test` 后产生 LED=1 写事务、ready-drop 错误码 2 且 `flash_clk_enable=0`、init 恢复后错误锁存仍不解锁 CPU，以及共同 reset 后重新读取 56 bytes 并重写 DDR。该延迟场景证明较长初始化等待不会误超时，不是初始化超时失败分支测试。独立 `make spi-flash-reader-test` PASS；`make flash-boot-smoke` 的成功/失败两支 PASS；`make lint` 对 Htop、`flash_ddr_boot`、`ddr_axi_bridge` PASS。组合 CPU 成功路径观测值为 `led_writes=1 led=00000001 pc=8000001c`。

这些 RTL 回归结果来自 testbench、行为 Flash/DDR 和局部 lint。wrapper、reader、loader 与 `ddr_axi_bridge` 的 Icarus compile PASS；对 `Hfpga_soc` 使用 `iverilog -i` 得到 parse/partial elaboration PASS，但 `-i` 会忽略缺失模块，因此不代表完整顶层 elaboration。PDS 于 2026-09-26 20:40 生成 `.sbit`；当前最新 `.sfc` 大小为 10,485,816 bytes。约束报告记录 0 errors、109 critical warnings，其中包括 share pin 提示和 Flash 输出缺 drive/slew 提示。PDS 生成文件和实板单片编程校验已有证据，但都不代表断电后配置、DDR 搬运或 CPU 实板运行已验证；配置 IO 释放具体细节尚未从当前记录核实，不应列成烧写前置条件。

## 启动链路

```text
上电 / sys_rst_n
       │
       ├── DDR IP 复位与初始化；ddr_init_done 是 IP 硬件输出
       │
       └── 同步到启动/CPU时钟域并等待初始化完成
                         │
                         ▼
           GTP_CFGCLK dedicated output 提供 SPI SCK
                         │
          Outer Flash (扫描 ID 0B4018): 03h + A00000..A00037
                         │ 56 次 byte response
                         ▼
     flash_ddr_loader: 每4字节按小端组成32-bit word
                         │ DDR write request
                         ▼
                    DDR 80000000
                         │ 写后逐word readback compare
                         ▼
      消费最后一条 readback response 后 boot_done=1
                         │ DDR owner 切至 CPU backend
                         ▼
        CPU 复位条件满足，Htop 从 reset PC=DDR_BASE 取指
                         │
                         ▼
             store 到 LED MMIO 40000200
```

`flash_ddr_loader` 是 FPGA 硬件状态机，不是 CPU 程序。`ddr_init_done` 是 DDR IP 初始化完成信号，不是软件变量。loader 在 `boot_done` 前独占单请求 DDR channel；它写每个 word 后重新读回并比较。最后一个 readback response 被消费时才宣布完成，以免 DDR response 在切换 owner 时丢失。`boot_error`/`boot_error_code` 有 RTL 定义；它们未接到现有 ILA，不能宣称已有板上错误观测。

NPU engine 尚未实现，但最小 CPU 流水灯镜像不依赖 NPU。当前核心仍保留 JTAG 调试路径；用户已确认 J10 是 SD 卡槽，绝不能把 J10 当作自定义 JTAG 扩展口接线。

## X1 当前实现与未来 X8 规划

当前 RTL 方案是**单颗 Outer Flash、SPI X1、普通读命令 `03h`**。扫描 ID 为 `0x0B4018`，PDS 自定义器件为 `xt25f128`，使用 WINBOND/W25Q NOR 兼容模板；旧记录中把 W25Q128JV 写为实物型号现予更正。`spi_flash_byte_reader.v` 输出一字节响应；wrapper 逐地址递增读取。每个字节单独发 `03h + 24-bit address`，无 dummy cycle。实板烧写只覆盖一颗，第二颗未烧写。

较早的 `QSPI_Flash到DDR启动搬运方案.md` 保留了未来 X8/QSPI 扩展设计：双颗 Flash、可能的 `6Bh`/快速读、多 lane 数据拼接、镜像头/CRC、多镜像和模型搬运。它是后续路线图，不是当前 RTL 的行为或已验证事实。上 X8 前必须实测 PDS 数据布局、双片选连接、两颗器件数据拼接/交织、QE 配置、时钟相位和吞吐；不能用封装 pin 功能替代板级证据。

## 引脚约束判读

本工程芯片与封装已确认为 PG2L200H-FBB676；用户已确认实板为 200H，并选择按该器件配置脚功能使用单片 SPI X1。对应 pin plan 为 CS=P18、idle CS2=F25、MOSI=R14、MISO=R15、WP_N=P14、HOLD_N=N14，3.3 V LVCMOS33。H13 是 GTP_CFGCLK 专用输出，由顶层 `GTP_CFGCLK` 原语驱动，不是普通 `flash_sck` top port。这项选择以用户确认器件型号为依据，**不等同于 PCB 原理图核对或导通测量，也不声称已证明 PCB 走线**。

`soc.fdc` 当前约束已采用上述 200H X1 pin plan。PDS 的 device map/place-route 报告显示这些 top port 已按对应位置映射；constraint check 对 share pin 的提示反映它们兼具配置功能。当前 PDS 工程/约束文件没有可确认配置引脚释放选项已启用的证据，准确选项名仍待实际 GUI/工程核实。实板型号确认支持选择此方案，但并不替代 PCB 接线验证。

`manual/flash_pin_profiles/` 中的 100Pro+ 手册 U15/U9 片段保留为历史候选和资料对照；它们不是当前已选 200H profile，也不要与 `soc.fdc` 当前块同时启用。100Pro+ 手册以 100H 为对象，不能推翻用户对实板 200H 型号的确认，也不能证明当前 PCB 走线。

保留既有 71 个 DDR pin 和其余普通 IO 约束；此改动不重映射它们。`soc.fdc` 中既有 J10 自定义 JTAG 旧注释仍需按实际 SD 卡槽理解，不应因此接线。

## PDS/烧写记录与下一步

以下烧写前待办是历史步骤，现由已完成的实板操作取代。本次先在 PDS 主机执行 ConnectToServer，再经 **Boundary Scan → FPGA → Scan Outer Flash** 扫描、配置并访问 Outer Flash。Add Flash 添加 `xt25f128` 自定义器件；Convert File 将 `.sbit` 起址设为 0、56-byte 程序起址设为 `0x00A00000`。随后对选中器件使用 **Assign New Configuration File** 加载 `.sfc`，依次 Erase、Program、Verify；随后再次 Verify 成功。扫描、擦写和校验都只涉及一颗 Outer Flash，第二颗未烧写。左侧 **SPI Flash Configuration** 是不同的直接 SPI 配置通道。ConnectToServer 是 PDS 主机扫描/烧写操作期间所需；预期板子断电上电后的自主启动不依赖它，但本次没有该启动实测结果。

`Hfpga_soc` 当前 `FLASH_BASE=24'hA00000`、`BOOT_IMAGE_BYTES=56`。修改 RTL 或 `FLASH_BASE` 后必须重生成 `.sbit` 并重打包；仅替换同地址、同长度的程序无需改 loader，程序长度变化则要同步修改 `BOOT_IMAGE_BYTES` 并重生成 bitstream。后续任务是断电重启并观察 FPGA 配置、DDR init、Flash 数据搬运及逐字读回、CPU reset 释放和 LED 行为。遇到问题再结合实际 PDS 配置、可获得的板级资料和启动观测定位；不把未核实的配置引脚释放 GUI 项列作已完成事实或烧写前置条件。

## 风险、边界与待完成项

- 一颗 Outer Flash 已有擦写及重复 Verify 成功的实板记录；第二颗未写。没有断电自主启动、DDR 搬运读回或 CPU 流水灯实板成功结果。
- 若重新生成位流或 `.sfc`，要按新文件长度复核位流地址与用户数据地址的安全间隔。
- 200H pin plan 已按用户确认选用，但并非 PCB 连线证明；芯片封装资料不是原理图。
- PDS 配置引脚释放设置的具体值尚未从当前记录核实；这是待核对的工程细节，不否定已经完成的烧写。
- `flash_wp_n`、`flash_hold_n` 当前应保持高电平；板级网络、电平与上拉仍需确认。
- 最终回归已覆盖 Flash clock enable、DDR init 同步与丢失错误锁存、100050-cycle 初始化延迟在 150000-cycle 等待预算内完成，以及共同 reset 重试；没有声称测试过 init timeout 到期失败分支。验证范围仍是行为模型组合仿真。
- `core_active` 保持 DDR 初始化语义，不表示 boot_done。现有 ILA 没有 boot error 探针。
- 板载 PDS/JTAG 下载链路与自定义 CPU JTAG 顶层口是两种接口。未使用的自定义调试输入须按板级连接保持可靠静态电平；J10 是 SD 卡槽，不能接自定义 JTAG。
- 这是 56-byte 固定镜像 bring-up，不实现通用头、CRC、AI 模型和 NPU 计算。NPU 缺失不阻断此最小流程。
- CPU 未能从 DDR 执行时，优先检查 PC/reset、DDR backend response 路由、镜像字节序及 LED MMIO；不要先假设是 DDR BIST 失败。

## 证据与参考

- 官方 PG2L200H-FBB676 封装资料：<https://www.pangomicro.com/en/uploads/34165729_1729132019.pdf>
- Logos2 GTP 用户指南（GTP_CFGCLK、CE_N 等）：<https://www.pangomicro.com/en/uploads/67142089_1729131824.pdf>
- W25Q128JV 数据手册（03h Read Data）：<https://www.winbond.com/resource-files/w25q128jv%20revg%2004082019%20plus.pdf>
- 100Pro+ 板卡手册（本地资料包，Flash/IO 连接表约第 28 页）：`/mnt/g/2026FPGA创新设计竞赛紫光同创杯资料包/盘古100Pro+开发板（MES2L676-100HP）配套资料/1_Demo_document/实验例程说明篇/教程1_硬件实验指导手册_盘古676系列100Pro+开发板.pdf`
