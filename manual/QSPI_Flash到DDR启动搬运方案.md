# QSPI Flash 到 DDR3 启动搬运方案

> **当前实现范围（2026-09-26）**：本文件主体是早期面向未来的 X8/QSPI 通用启动规划，其中 `6Bh`、双 Flash 交织、用户数据头、CRC、多镜像、AI 权重、256-bit burst 等不是当前实现。当前 RTL bring-up 设计为单颗 Outer Flash、SPI X1、模式 0、`03h` 普通读、24-bit byte address，从固定地址 `0x00A00000` 读取 56-byte 流水灯程序，写至 DDR `0x80000000` 并逐 word readback 后再放开 CPU。本次扫描 ID 为 `0x0B4018`，PDS 以 `xt25f128` 自定义器件和 WINBOND/W25Q NOR 兼容模板识别；实板已对一颗 Outer Flash 完成编程和 Verify，第二颗未写。未确认断电自主启动、DDR 搬运实测或 CPU 流水灯实板成功。板级 pin plan 不等于 PCB 连线证明。操作和证据详见 [PG2L200H Flash 烧写与 DDR 启动实板记录](PG2L200H_Flash烧写与DDR启动实板记录.md) 与 [Flash_DDR_Boot_Review.md](Flash_DDR_Boot_Review.md)。

> `ddr_init_done` 是 DDR IP 的硬件初始化完成输出，启动搬运器是 FPGA 硬件 FSM；它们不是 CPU 软件。NPU engine 尚未实现，但这不阻止最小 CPU 流水灯程序启动。

## 1. 目标

本方案用于盘古 200Pro+（PG2L200H-FBB676）：

1. 使用 PDS 和 USB Cable，将 FPGA 位流、CPU 程序及 AI 模型一次性写入板载 QSPI Flash。
2. 上电后，由 FPGA 配置逻辑从 Flash 加载位流。
3. 位流运行后，由 FPGA 内部的启动搬运硬件读取 Flash 用户数据区。
4. 将 CPU 程序、AI 模型等数据搬运到 DDR3 指定地址。
5. 校验数据头、地址和 CRC。
6. 全部搬运成功后才释放 CPU 复位；失败则保持 CPU 复位并输出错误码。

这些启动模块都是 FPGA 内部的 Verilog RTL，不是 CPU 软件，也不需要 OpenOCD、GDB 或 SD 卡。只有生成 Flash 数据包的打包工具运行在电脑上。

```text
PDS + USB Cable
       │ 一次写入
       ▼
QSPI Flash
┌─────────────────────────────────┐
│ FPGA bitstream │ boot_image.bin │
│                │ 程序+模型+CRC  │
└─────────────────────────────────┘
       │ 上电
       ▼
FPGA 配置逻辑加载 bitstream
       │
       ▼
QSPI读取器 → 数据头解析 → 写DDR → CRC校验
                                 │
                     成功 ───────┴──→ 释放CPU复位
                     失败 ──────────→ CPU继续复位
```

## 2. 推荐的 RTL 文件划分

建议新增：

```text
soc/flash_boot/
├── qspi_user_reader.v       # 用户模式读取Flash
├── boot_header_parser.v     # 解析用户数据头
├── crc32_stream.v           # 流式CRC32
└── flash_ddr_loader.v       # 总状态机、Flash到DDR搬运
```

需要修改：

- `soc/Hfpga_soc.v`
- `soc/ddr_axi_bridge.v`
- `soc/soc_addr_map.vh`（只有需要调整DDR分区时才修改）
- `soc.fdc`

第一版不必直接实现复杂的 AXI DMA，可以复用现有 `ddr_axi_bridge` 的 32 位请求接口。验证正确后，再升级为 256 位 AXI burst，提高大模型搬运速度。

## 3. 用户模式 QSPI Flash 读取控制器

### 3.1 职责与接口

`qspi_user_reader` 只负责读取 Flash，不负责写 Flash：

1. 接收起始地址和读取长度。
2. 拉低片选。
3. 发送读取命令、地址和 dummy clock。
4. 接收连续字节。
5. 通过 `valid/ready` 流接口把字节交给搬运器。

建议接口：

```verilog
module qspi_user_reader (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,
    input  wire [23:0] flash_addr,
    input  wire [31:0] byte_count,

    output reg  [7:0]  data,
    output reg         data_valid,
    input  wire        data_ready,

    output reg         busy,
    output reg         done,
    output reg         error,

    output reg         flash_cs_n,
    output reg         flash_cs2_n,
    inout  wire [7:0]  flash_dq
);
```

当下游 `data_ready=0` 时，读取器必须暂停 QSPI 时钟或者将数据放入 FIFO，不能继续读出后直接丢弃数据。

### 3.2 配置 Flash 时钟

PG2L200H 的 `CFG_CLK` 是专用配置时钟脚。配置完成后，用户逻辑需要实例化 `GTP_CFGCLK`，才能继续向板载 Flash 输出时钟：

```verilog
wire qspi_clk;
wire qspi_clk_enable;

GTP_CFGCLK u_flash_cfgclk (
    .CLKIN(qspi_clk),
    .CE_N (~qspi_clk_enable)
);
```

`CE_N` 为低有效。关闭读取时应让两路片选保持高电平，并关闭时钟输出。

官方资料：

- [Logos2 GTP 用户指南](https://www.pangomicro.com/en/uploads/67142089_1729131824.pdf)
- [Logos2 配置用户指南](https://www.pangomicro.com/en/uploads/69345021_1729131793.pdf)
- [PG2L200H-FBB676 封装手册](https://www.pangomicro.com/en/uploads/34165729_1729132019.pdf)

### 3.3 PG2L200H-FBB676 相关管脚

| 信号 | FPGA 管脚 |
|---|---:|
| CFG_CLK | H13 |
| D0 | R14 |
| D1 | R15 |
| D2 | P14 |
| D3 | N14 |
| D4 | N16 |
| D5 | N17 |
| D6 | R16 |
| D7 | R17 |
| FCS_N | P18 |
| FCS2_N | F25 |

X8 配置模式下：

- D0～D3 对应第一颗 SPI Flash。
- D4～D7 对应第二颗 SPI Flash。
- `FCS_N` 是第一颗 Flash 的片选。
- `FCS2_N` 是第二颗 Flash 的片选。
- 两颗 Flash 共用 `CFG_CLK`。

最终加入 `soc.fdc` 前，仍需用盘古 200Pro+ 原理图复核板上连接方式。

### 3.4 建议的读取状态机

第一版可研究使用 `0x6B Fast Read Quad Output`，具体命令、dummy 数量和 QE 位要求以 W25Q128JV 手册为准。

```text
IDLE
  ↓ start
CS_LOW
  ↓
SEND_CMD       发送读取命令
  ↓
SEND_ADDR      发送24位地址
  ↓
DUMMY_CLOCK    发送规定数量的dummy周期
  ↓
READ_DATA      连续接收D[7:0]
  ↓
CS_HIGH
  ↓
DONE
```

两颗 Flash 同时发送命令时，可以分别驱动 D0 和 D4：

```verilog
reg tx_bit;

assign flash_dq[0] = dq0_oe ? tx_bit : 1'bz;
assign flash_dq[4] = dq4_oe ? tx_bit : 1'bz;

wire [7:0] flash_data = flash_dq;
```

进入数据接收阶段后，D0～D7 全部切换为输入。

第一版将 QSPI 时钟设置在 5～10 MHz，确认读数顺序正确后再提高频率。

### 3.5 X8 数据交织必须实测

PDS 在 X8 模式下会把逻辑数据分布到两颗 Flash。以下内容不能仅凭经验确定：

- PDS 中用户数据起始地址是聚合逻辑地址还是单颗 Flash 物理地址。
- 两颗 Flash 数据的高、低半字节排列。
- 物理地址是否对应两个连续的逻辑字节。
- 奇偶逻辑地址对应哪一次 QSPI 采样。

应先让 PDS 写入一小段已知数据，例如：

```text
00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF
```

再通过启动读取器、片上逻辑分析仪或状态寄存器观察实际读取顺序，确定地址换算和半字节拼接方式。

## 4. 用户数据头格式

不建议长期把程序地址、模型地址和长度写死在 RTL 中。可以定义一个固定的小端格式启动数据包。

### 4.1 总数据头：32 字节

| 偏移 | 长度 | 内容 |
|---:|---:|---|
| 0x00 | 4 | Magic，例如 `PGB0` |
| 0x04 | 2 | 格式版本 |
| 0x06 | 2 | 数据头总长度 |
| 0x08 | 4 | 镜像数量 |
| 0x0C | 4 | 整个数据包长度 |
| 0x10 | 4 | 数据头 CRC32 |
| 0x14 | 4 | flags |
| 0x18 | 8 | 保留 |

数据头 CRC 建议覆盖总数据头和全部镜像描述符；计算时将数据头中的 CRC 字段临时视为零。

### 4.2 每个镜像描述符：32 字节

| 偏移 | 长度 | 内容 |
|---:|---:|---|
| 0x00 | 4 | 类型：CPU程序、模型、配置等 |
| 0x04 | 4 | 相对用户数据区起点的 Flash 偏移 |
| 0x08 | 4 | DDR 目标地址 |
| 0x0C | 4 | 数据长度 |
| 0x10 | 4 | 数据 CRC32 |
| 0x14 | 4 | flags |
| 0x18 | 8 | 保留 |

示例：

```text
镜像0：
  type         = 1，CPU程序
  flash_offset = 0x00000100
  ddr_addr     = 0x80000000
  length       = 512KB

镜像1：
  type         = 2，AI模型
  flash_offset = 0x00080100
  ddr_addr     = 0xB9000000
  length       = 8MB
```

当前工程中：

- CPU 复位地址为 `0x8000_0000`。
- NPU 权重区为 `0xB900_0000～0xBAFF_FFFF`。
- DDR 总范围为 `0x8000_0000～0xBFFF_FFFF`。

地址定义见 `soc/soc_addr_map.vh`。

### 4.3 解析实现

解析器可以根据字节序号装入寄存器：

```verilog
always @(posedge clk) begin
    if (!rst_n) begin
        byte_index <= 0;
        magic      <= 0;
    end else if (header_byte_valid && header_byte_ready) begin
        case (byte_index)
            0: magic[7:0]    <= header_byte;
            1: magic[15:8]   <= header_byte;
            2: magic[23:16]  <= header_byte;
            3: magic[31:24]  <= header_byte;
            4: version[7:0]  <= header_byte;
            5: version[15:8] <= header_byte;
            // 继续解析其他字段
        endcase

        byte_index <= byte_index + 1'b1;
    end
end
```

解析完成后至少检查：

1. Magic 正确。
2. 版本号受支持。
3. `image_count` 不超过硬件上限，例如 8。
4. `flash_offset + length` 没有溢出或超过 Flash 用户区。
5. `ddr_addr + length` 没有溢出或超过 DDR。
6. CPU 程序和模型目标地址位于允许区域。
7. 地址和长度满足所需对齐。
8. 数据头 CRC 正确。

第一版可暂时跳过通用数据头，使用固定参数跑通搬运链路：

```verilog
localparam FLASH_DATA_ADDR = 24'h400000;
localparam DDR_DATA_ADDR   = 32'h80000000;
localparam DATA_BYTES      = 32'h00001000;
localparam EXPECTED_CRC    = 32'hXXXXXXXX;
```

## 5. Flash 到 DDR 搬运状态机

### 5.1 复用现有 DDR 请求接口

当前 `soc/ddr_axi_bridge.v` 已提供：

```verilog
cpu_req_valid
cpu_req_ready
cpu_req_write
cpu_req_addr
cpu_req_wdata
cpu_req_wmask

cpu_rsp_valid
cpu_rsp_ready
cpu_rsp_is_read
cpu_rsp_rdata
```

因此第一版启动搬运器可以直接生成相同形式的 32 位请求，无需再实现完整 AXI 主机。

### 5.2 QSPI 字节打包为 32 位

```verilog
case (byte_lane)
    2'd0: word_buffer[7:0]   <= flash_byte;
    2'd1: word_buffer[15:8]  <= flash_byte;
    2'd2: word_buffer[23:16] <= flash_byte;
    2'd3: word_buffer[31:24] <= flash_byte;
endcase
```

收到四个字节后提交写请求：

```verilog
loader_req_valid <= 1'b1;
loader_req_write <= 1'b1;
loader_req_addr  <= current_ddr_addr;
loader_req_wdata <= completed_word;
loader_req_wstrb <= 4'b1111;
```

最后不足四字节时：

```text
1字节：wstrb = 0001
2字节：wstrb = 0011
3字节：wstrb = 0111
```

### 5.3 总状态机

```verilog
localparam ST_RESET        = 4'd0;
localparam ST_WAIT_DDR     = 4'd1;
localparam ST_READ_HEADER  = 4'd2;
localparam ST_CHECK_HEADER = 4'd3;
localparam ST_READ_ENTRY   = 4'd4;
localparam ST_START_IMAGE  = 4'd5;
localparam ST_GET_BYTE     = 4'd6;
localparam ST_WRITE_WORD   = 4'd7;
localparam ST_WAIT_WRITE   = 4'd8;
localparam ST_CHECK_CRC    = 4'd9;
localparam ST_NEXT_IMAGE   = 4'd10;
localparam ST_DONE         = 4'd11;
localparam ST_ERROR        = 4'd12;
```

流程：

```text
等待 ddr_init_done
  ↓
读取并解析数据头
  ↓
检查地址、长度、数据头CRC
  ↓
选择第一个镜像
  ↓
连续读取Flash
  ↓
每4字节写一次DDR
  ↓
等待最后一次DDR写响应
  ↓
比较payload CRC
  ↓
还有镜像？继续搬运
  ↓
boot_done = 1
```

### 5.4 启动搬运器和正常系统共用 DDR

将当前 `axi_mem_backend` 输出重命名为 `run_req_*`，启动搬运器输出命名为 `boot_req_*`，然后在 `ddr_axi_bridge` 前加入二选一。

```verilog
wire boot_owns_ddr = !boot_done;

assign bridge_req_valid = boot_owns_ddr ?
                          boot_req_valid : run_req_valid;
assign bridge_req_write = boot_owns_ddr ?
                          boot_req_write : run_req_write;
assign bridge_req_addr  = boot_owns_ddr ?
                          boot_req_addr : run_req_addr;
assign bridge_req_wdata = boot_owns_ddr ?
                          boot_req_wdata : run_req_wdata;
assign bridge_req_wstrb = boot_owns_ddr ?
                          boot_req_wstrb : run_req_wstrb;

assign boot_req_ready =  boot_owns_ddr && bridge_req_ready;
assign run_req_ready  = !boot_owns_ddr && bridge_req_ready;
```

响应通道也要按所有者选择：

```verilog
assign boot_rsp_valid =  boot_owns_ddr && bridge_rsp_valid;
assign run_rsp_valid  = !boot_owns_ddr && bridge_rsp_valid;
assign bridge_rsp_ready = boot_owns_ddr ?
                          boot_rsp_ready : run_rsp_ready;
```

`boot_done` 必须在最后一次 DDR 响应已经被接收后才置位。不能在最后一次请求刚发出时切换所有者，否则响应可能被错误地送给正常系统。

## 6. CRC32

建议采用常用的 CRC-32/ISO-HDLC 参数：

- 反射多项式：`0xEDB88320`
- 初始值：`0xFFFFFFFF`
- 结束异或：`0xFFFFFFFF`
- 电脑端可使用 Python `zlib.crc32()` 生成对应结果

每输入一个字节更新一次：

```verilog
function [31:0] crc32_next_byte;
    input [31:0] crc_in;
    input [7:0]  data_in;
    integer i;
    reg [31:0] c;
begin
    c = crc_in ^ data_in;

    for (i = 0; i < 8; i = i + 1) begin
        if (c[0])
            c = (c >> 1) ^ 32'hEDB88320;
        else
            c = c >> 1;
    end

    crc32_next_byte = c;
end
endfunction
```

```verilog
if (image_start)
    crc_reg <= 32'hFFFFFFFF;
else if (flash_data_valid && flash_data_ready)
    crc_reg <= crc32_next_byte(crc_reg, flash_data);

wire [31:0] calculated_crc = crc_reg ^ 32'hFFFFFFFF;
```

CRC 必须只在流握手成功时更新：

```verilog
flash_data_valid && flash_data_ready
```

否则下游暂停时，同一个字节可能被重复计算。

可以分两级验证：

1. Flash 流 CRC：验证从 Flash 读取的数据流。
2. DDR 回读 CRC：写完后重新读取 DDR，验证 DDR 中的最终内容。

第一版先做 Flash 流 CRC；正式版本增加 DDR 回读 CRC 或至少检查 AXI `BRESP/RRESP`。当前 `ddr_axi_bridge` 没有向上层传递 AXI 响应错误，需要增加 `rsp_error` 输出。

## 7. 搬运完成前保持 CPU 复位

当前 `soc/Hfpga_soc.v` 中 CPU 复位逻辑为：

```verilog
wire cpu_rst = !sys_rst_n || (cpu_rst_cnt != 4'hF) ||
               jtag_reset_req || jtag_halt_req;
```

应增加 DDR 初始化和启动搬运完成条件：

```verilog
wire cpu_rst = !sys_rst_n       ||
               !ddr_init_done   ||
               !boot_done       ||
               (cpu_rst_cnt != 4'hF) ||
               jtag_reset_req   ||
               jtag_halt_req;
```

复位延迟计数器应在 `boot_done` 后重新计数：

```verilog
always @(posedge cpu_clk) begin
    if (!sys_rst_n || !boot_done)
        cpu_rst_cnt <= 4'd0;
    else if (cpu_rst_cnt != 4'hF)
        cpu_rst_cnt <= cpu_rst_cnt + 1'b1;
end
```

复位域必须分开：

```text
CPU模块：使用 cpu_rst
启动搬运器：使用 sys_rst_n 或独立 boot_rst_n
```

不能让启动搬运器使用 `cpu_rst`，否则会死锁：

```text
boot_done未完成
  → cpu_rst保持有效
  → 搬运器也被复位
  → boot_done永远不能完成
```

`core_active` 建议改为：

```verilog
assign core_active = ddr_init_done && boot_done;
```

## 8. 错误处理

启动失败时：

```verilog
boot_done  <= 1'b0;
boot_error <= 1'b1;
```

CPU 保持复位，并通过 LED 或调试寄存器输出错误码：

| 错误码 | 含义 |
|---:|---|
| 1 | DDR 初始化超时 |
| 2 | Flash 读取失败 |
| 3 | Magic 错误 |
| 4 | 数据头 CRC 错误 |
| 5 | Flash 或 DDR 地址越界 |
| 6 | payload CRC 错误 |
| 7 | DDR/AXI 响应错误 |

建议设置 DDR 初始化、Flash 读取和 DDR 响应超时计数器，避免状态机永久卡死而无法判断原因。

## 9. 电脑端打包与 PDS 写入

电脑端需要一个小型打包工具，例如 `tools/make_boot_image.py`，负责：

1. 读取 CPU 程序二进制文件。
2. 读取 AI 模型或权重文件。
3. 计算各镜像 CRC32。
4. 生成总数据头和镜像描述符。
5. 对各数据区域进行地址对齐和填充。
6. 输出一个 `boot_image.bin`。

然后在 PDS 的 Flash Programming File 生成界面中：

```text
BitStream File：加载 FPGA 位流，地址为 0
User Data File：加载 boot_image.bin，地址为规划的 USER_BASE
```

`USER_BASE` 必须：

- 避开 bitstream 实际占用范围。
- 满足 PDS/Flash 要求的扇区对齐。
- 给用户数据预留足够连续容量。
- 在硬件读取器和电脑端打包工具中使用同一含义。

## 10. 推荐开发顺序

按照以下顺序逐步验证，不要一次性打开全部功能：

1. 用 PDS 向用户区写入 256 字节已知测试数据。
2. 实现低速 QSPI 读取，并确认 X8 数据排列和地址换算。
3. 使用固定 Flash 地址和固定 DDR 地址搬运 256 字节。
4. 从 DDR 回读前几个字，确认写入结果。
5. 加入 payload CRC。
6. 加入 `boot_done` 和 CPU 复位控制。
7. 搬运一个最小 CPU 程序到 `0x80000000`，释放 CPU 后点亮 LED。
8. 加入通用数据头和多镜像支持。
9. 加入 AI 模型或权重镜像。
10. 性能不够时，将 32 位单次写升级成 256 位 AXI burst。

## 11. 第一版的最小验收标准

第一版不要以“能够搬运完整 AI 模型”为目标，而应满足：

1. 上电后 DDR 初始化成功。
2. 能从 Flash 用户区读到已知测试数据。
3. 能把测试数据写入 `0x80000000`。
4. CRC 与电脑端结果一致。
5. CRC 成功前 CPU 始终处于复位状态。
6. CRC 成功后 CPU 从 `0x80000000` 开始执行最小程序。
7. 任何错误都会保持 CPU 复位并给出明确错误码。

完成这一步后，CPU 程序、AI 模型和其他资源都只是数据长度与目标地址的变化，不再改变整体启动架构。

## 12. 实现前仍需确认的板级信息

为了完成可综合、可上板的精确代码，还需要确认：

1. 盘古 200Pro+ 原理图中两颗 W25Q128JV 与 FPGA 配置管脚的连接页。
2. PDS 当前工程选择的配置宽度是否为 X8。
3. PDS 的 Flash Programming File 页面中用户数据地址范围和显示单位。
4. W25Q128JV 的 QE 位在 PDS 下载和重新上电后的状态。
5. PDS 生成的 X8 用户数据在两颗 Flash 中的交织规则。

其中第 5 项可以用递增测试数据快速实测，不需要依赖猜测。
