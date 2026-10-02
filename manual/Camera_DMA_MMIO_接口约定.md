# CAM1 DMA 与 MMIO 本阶段接口约定

本阶段实现单路 CAM1，RGB565 640×480，480 行、307200 像素、614400 字节。
Camera DMA 在 DDR core clock 域运行，FIFO 读端也在该域；CPU 在 70 MHz 域通过
MMIO 请求快照。CPU 读 DDR 后使用 UART TX 打印，UART 不接入图像通路。

## FIFO 条目

18 bit：`[17:16]=00` 为 RGB565 像素，`01` 为 SOF，`10` 为 EOF，`11` 为 EOL。
像素在 `[15:0]`；EOF 的低 4 bit 携带当前帧 DVP 错误。事件由 DVP 接收器注册
输出，避免最后一个像素与行末标记争用一次写入。溢出后停止发送本帧，下一 SOF
重新对齐；溢出事件必须安全跨到 DMA 域，使残缺帧无法发布为有效帧。

## Hcamera_dma 接口（DDR 域）

参数：`DDR_BASE`、`DDR_BYTES`、`BUFFER0_ADDR`、`BUFFER1_ADDR`、`FRAME_WIDTH`、
`FRAME_HEIGHT`、`TIMEOUT_CYCLES`。端口：

```text
clk, rst_n, enable, ddr_ready, clear_errors
release_valid, release_mask[1:0]
fifo_empty, fifo_rd_en, fifo_rd_valid, fifo_rd_data[17:0], fifo_fault
busy, done, error, error_code[31:0], frame_active
frame_count[31:0], last_pixel_count[31:0], last_byte_count[31:0], last_line_count[31:0]
current_pixel_count[31:0], current_byte_count[31:0], current_line_count[31:0]
last_frame_addr[31:0], current_write_buffer[31:0], last_complete_buffer[31:0]
frame_checksum[31:0], ready_mask[1:0], dropped_frames[31:0]
axi_awaddr[29:0], axi_awid[7:0], axi_awlen[7:0], axi_awsize[2:0], axi_awburst[1:0]
axi_awvalid, axi_awready
axi_wdata[255:0], axi_wstrb[31:0], axi_wlast, axi_wvalid, axi_wready
axi_bid[7:0], axi_bresp[1:0], axi_bvalid, axi_bready
```

每 16 个 RGB565 像素打包成 256-bit AXI 写拍，首版单拍事务，ID=0x40。
地址为 CPU 地址减 DDR_BASE，像素以小端 uint16_t 排列。成功 EOF 必须满足行数、
像素数和 DVP 错误条件，且最后写响应已收到，再原子发布完成元数据。
checksum 是所有 uint16_t 像素之和，模 2^32；CPU 从 DDR 重新计算对比。

超时必须记录错误并保持已发出的 AXI VALID/事务直到安全完成或复位，不能
撤销未握手地址或截断已开始写事务。无效帧不修改上一完成帧的数据描述。

## 缓冲所有权

BUFFER0=0xB8000000，BUFFER1=0xB8100000，各占 1 MiB，属于既有 NPU input 区。
Camera 只选择 ready_mask 中为 0 的槽。完成后置位 ready_mask，CPU/NPU 持有
直到显式 RELEASE；两槽均占用时丢弃新帧并记数。最近完成槽与当前写入槽必须
分别报告，空闲/无完成槽使用 0xFFFFFFFF。未来双目另行扩展槽分配和仲裁。

## 快照与寄存器

偏移与 DMA 错误码见 `soc/camera_regs.vh`。SNAPSHOT_CTRL 写 bit0 请求；读 bit0
busy、bit1 valid、bit2 timeout。新请求立即清 valid；同一事务内先冻结 PCLK 诊断，
再在 DDR 域原子冻结 DMA 元数据和 FIFO 读域状态，最后由 CPU 域握手锁存整组。
完成帧 pixel/byte/line/frame/address/checksum 均来自同一 DMA 完成描述；DVP 原始
帧计数另列，允许显示正在采集下一帧而不混淆完成帧。冻结后的多位总线在握手
期间保持稳定。无 PCLK/DDR 时 CPU 请求有超时状态，不能永远轮询。

CAM_STATUS 位：0 enable，1 PCLK seen，2 VSYNC seen，3 HREF seen，4 frame active，
5 frame done/ready，6 FIFO full，7 overflow，8 DMA busy，9 DMA done，10 DMA error，
11 DDR ready，12 DVP frame active，13 FIFO underflow，14 DVP error。FIFO_ERROR 位 0 overflow、1 underflow、
2 token collision。DMA_STATUS 位 0 enable、1 busy、2 done、3 error、9:8 ready_mask。

BUFFER_RELEASE 写低两位，经独立 mailbox 到 DDR 域；读 bit0 busy。
DMA_CONTROL bit0 enable，写 bit1 请求清错误（握手避免脉冲丢失）。
动态只读字段均来自快照；静态尺寸/固定地址和控制 mailbox busy 可直接读取。

基址 `0x40000300`。除控制项及固定配置外，以下读值均为 CPU 域冻结快照：

| 偏移 | 寄存器/含义 |
|---|---|
| 00 / 04 | 既有 SCCB GPIO 控制 / 状态 |
| 08 | SNAPSHOT_CTRL：写 bit0 请求，读 busy/valid/timeout |
| 0C / 10 / 1C / 24 | FRAME_COUNT / PIXEL_COUNT / LINE_COUNT / BYTE_COUNT（成功帧） |
| 14 / 18 | PCLK_COUNT / DVP 粘滞错误（兼容旧偏移） |
| 20 | CAM_STATUS |
| 28 / 2C / 30 | FIFO_LEVEL / FIFO_MAX_LEVEL / FIFO_ERROR |
| 34 / 38 | DMA_STATUS / DMA_ERROR_CODE |
| 3C | LAST_FRAME_ADDR：CPU 地址 |
| 40 / 44 | CURRENT_WRITE_BUFFER / LAST_COMPLETE_BUFFER：槽编号 0/1 |
| 48 | FRAME_CHECKSUM：上一成功帧的 sum16，非 CRC32 |
| 4C / 50 / 54 | READY_MASK / DROPPED_FRAMES / SNAPSHOT_SEQUENCE |
| 58 / 5C | DVP_FRAME_COUNT / DVP_ERROR_FLAGS：接收端原始诊断 |
| 60 | BUFFER_RELEASE：写 mask[1:0]，读 bit0 mailbox busy |
| 64 | DMA_CONTROL：bit0 enable，写 bit1 clear errors / 读 bit1 clear busy |
| 68 / 6C | BUFFER0_ADDR / BUFFER1_ADDR：静态配置 |
| 70 / 74 / 78 | FRAME_BYTES / FRAME_WIDTH / FRAME_HEIGHT：静态配置 |
| 7C | DDR_READY：快照值 |
| 80 / 84 / 88 | CURRENT_PIXEL_COUNT / CURRENT_BYTE_COUNT / CURRENT_LINE_COUNT |

完成帧描述总是最后一帧成功结果；DMA error/code 为全局粘滞诊断，可能包含后来
丢弃帧的错误，不能将其误标为上一成功帧的图像无效。DONE 在成功完成时置位，
下一 SOF 清除；是否仍可读取某槽应以 READY_MASK 为准，不单独依赖 DONE。

| DMA 错误码 | 含义 |
|---|---|
| 0 | 无错误 |
| 1 | FIFO overflow / 数据通路故障事件 |
| 2 / 3 | unexpected SOF / unexpected EOF 或无有效帧时收到像素 |
| 4 | bad pixel count |
| 5 | DDR 通道超时或帧内 FIFO 输入长期停滞 |
| 6 | DDR B 响应错误 / ID 不符 |
| 7 / 8 | bad line count / EOF 携带 DVP 错误 |
| 9 | 两个缓冲均被持有，无可写槽 |
| 10 | 缓冲越界、重叠、非对齐或尺寸非法 |
| 11 | FIFO underflow，预留；当前通过 FIFO_ERROR.bit1 报告 |

## 验证边界

离线测试需覆盖完整 VGA 帧及 DDR 读回 checksum、不同图案改变 checksum、FIFO
背压/溢出、SOF/EOF 错序、错误像素/行数、DDR 写错误/超时、两槽保护及 release、
跨域快照的一致性和无时钟超时。最终真实 CPU 固件逐字段打印并核对 DDR 样本。
保留实板 review 记录，当前不启动 PDS 或物理串口。
