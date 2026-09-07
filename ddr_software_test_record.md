# DDR 软件访问验证记录

日期：2026-09-05

## 已确认的地址映射

- CPU 数据访问地址 `0x8000_0000` 至 `0xBFFF_FFFF` 映射到板载 DDR3 的 1 GiB
  字节地址窗口。
- 程序指令仍应从 IMEM（地址 `0x0000_0000`）执行；本阶段不把程序代码放入 DDR3。

## 现有软件筛选结论

候选使用资料包内现成的 CoreMark 工程：

`manual/2026小眼睛职业技能赛配套资料包/01 RISC-V参考资料/3.risc_v源码/`
`SparrowRV-master/bsp/bsp_app/example/coremark`

它是当前最适合验证 CPU 经由 DDR AXI 桥读写外部存储器的既有软件，原因如下：

- CoreMark 当前使用 `STATIC` 内存模式；`core_main.c` 定义了
  `static_memblk[TOTAL_DATA_SIZE]`，默认工作区大小为 2,000 字节。
- 测试会反复读写这个工作区，并通过 CRC 输出 `Correct operation validated`（或等效的
  validated 结果），因此可同时验证读、写和数据一致性。
- 它已有可编译的 RV32IM 工程、串口输出和已知的正确结果，不需要新写测试程序。

## 当前版本不能直接使用的原因

资料包中已有的 `coremark.elf` / `coremark.bin` 仍按原始链接脚本链接：

- `.data` 位于 `0x2000_0000`；
- `.bss`（含 `static_memblk`）也位于 `0x2000_0000`；
- 默认 SRAM 链接区为 `0x2000_0000` 至 `0x2000_3fff`。

所以当前工程中的旧 `Coremark.dat` 或资料包中的既有 `coremark.bin` 均**不会**访问
`0x8000_0000`，不能据此宣称 DDR AXI 桥已由软件验证。

## 暂定后续方案（尚未执行）

保留现成 CoreMark 的 C 源码与测试逻辑不变，仅制作一份 DDR 版链接脚本并重新链接：

1. 保持 `.text` / IMEM 装载镜像在 `0x0000_0000`；
2. 保持启动栈在片上 SRAM `0x2000_0000`，避免测试栈延迟掩盖测试对象；
3. 将 CoreMark 的工作数据（至少 `.bss` 中的 `static_memblk`，必要时 `.data`）定位到
   `0x8000_0000`；
4. 转换生成 IMEM 所需的 `.dat` 文件后，再通过现有串口观察 CoreMark CRC 和
   `validated` 结果。

这样得到的是“现成 CoreMark 的 DDR 数据区版本”，而不是额外编写的专用测试程序。

## 不采用的现有工程

资料包中的 `2_9_ddr3_test` 是 Pango 的 DDR3 控制器 RTL 硬件测试工程：

`manual/2026小眼睛职业技能赛配套资料包/02 远程实验平台FPGA主板卡配套资料/`
`2_Demo/2_9_ddr3_test/2_9_ddr3_test/ddr3_test`

它验证 DDR3 IP 和 PHY 训练，但不是运行在本项目 RISC-V CPU 上的软件，也不会经过本项目
的 `0x8000_0000` 地址译码和 `ddr_axi_bridge`，因此不能代替上述软件验证。

## 详细设计文档待补充的存储子系统

详细设计文档中应把 DDR3、AXI 桥和后续 DCache 作为正式的“存储子系统”章节，而不能只在
CoreMark 测试说明中提及。建议采用以下总体结构：

```text
CPU 数据访存
├── 0x2000_0000：片内 DMem/BRAM，绕过 DCache
├── 0x4000_0000：MMIO 外设，禁止缓存
└── 0x8000_0000：DCache → AXI 桥 → DDR3 控制器 → DDR3 颗粒
```

DDR3 章节至少记录：

- Pango DDR3 Interface IP 版本 1.16a，Controller + PHY 模式；
- 125 MHz 差分参考时钟、1000 Mbps 数据速率和 32 位物理数据宽度；
- `ddr_init_done` 的用途，以及初始化完成前 CPU 请求的阻塞行为；
- `0x8000_0000` 至 `0xBFFF_FFFF` 的 1 GiB CPU 数据地址窗口。

AXI 桥章节至少记录：

- 当前 CPU 侧为 32 位单次读写请求，DDR 控制器侧为 256 位 AXI4；
- 地址按 32 字节边界对齐，由 CPU 地址位 `[4:2]` 选择 8 个 32 位通道之一；
- CPU 的 4 位写掩码扩展到对应通道的 32 位 AXI `WSTRB`；
- CPU 时钟与 DDR `core_clk` 异步，当前采用单请求在途的请求/响应 CDC 握手；
- 已有 testbench 覆盖初始化阻塞、通道 5 写入、通道 5 读取和 CDC 返回。

DCache 章节按预期完成后的设计记录，并注明尚未实现：

- 仅缓存 DDR 地址窗口，BRAM 和 MMIO 均旁路；
- Cache Line 建议采用 32 字节，与一个 256 位 AXI 数据拍严格匹配；
- CPU 与 DCache 之间仍为 32 位 `load/store` 接口；
- DCache 缺失时，后端应一次读取完整 256 位 Cache Line；
- 需要记录容量、组数、路数、Tag/Valid/Dirty、替换策略和写策略；
- 需要增加访问、命中和缺失计数器，用于比较 DDR 缓存前后的 CoreMark 性能。

当前 `ddr_axi_bridge` 是无缓存阶段的验证桥：一次 256 位 AXI 读取只返回 CPU 所需的一个
32 位通道。加入 DCache 时应调整为以下接口边界：

```text
CPU ↔ DCache：32 位 load/store
DCache ↔ AXI 后端：256 位 Cache Line
AXI 后端 ↔ DDR3：256 位 AXI4
```

否则一次 32 字节缓存行回填需要重复发起 8 次 256 位读取，既浪费 DDR 带宽，也无法体现
256 位 AXI 数据宽度的优势。
