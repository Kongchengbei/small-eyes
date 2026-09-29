# Flash→DDR SPI 连续读取升级说明

本说明记录 2026-09-27 的启动 RTL 更新。reader 现在接受一次起始地址和长度，在同一条 SPI mode 0、X1、`03h + 24-bit address` 事务内连续输出整段数据；loader 仅请求一次，按小端每 4 byte 组成一个 DDR word，写入后逐 word 读回校验。默认镜像仍是 Flash `0x00A00000`、DDR `0x80000000`、56 bytes。

CS 在命令、地址和所有数据期间保持低。每个 byte 的 8 个采样位完成后，reader 在 SCK 低相位保持 `rsp_valid/data`，等待 loader 的 `rsp_ready`；loader 等待 DDR 写入和读回时，reader最多预取一个完整 byte，随后保持 SCK 低并继续拉低 CS，直到 DDR 流程允许接收。最后一个 byte 被 loader 接收时 CS 回到高、SCK 保持低；最后一次 DDR readback 成功后才置 `boot_done`。`boot_error` 或 DDR init 丢失会中止 Flash 流：若 SCK 已高，只完成当前高相位的下降沿，再释放 CS；不会在中止被采样后开始新的上升沿。共同复位会清除中止状态并允许重试。第二颗片选仍为高，SPI clock divider 仍为 4，CPU 仍为 70 MHz。

一次连续事务产生 `32 + 8N` 个 SCK 上升沿；旧实现每个 byte 重发命令和地址，产生 `40N` 个上升沿。56 bytes 时为 480 对 2240，纯 SPI 时钟数缩减至原来的约 1/4.67。该比值仅描述 SPI 传输；DDR 仍对每个 word 执行一次写和一次读回，不能据此承诺总启动时间提高 5 倍。

FPGA 位流加载由器件配置电路负责，RTL 这次只改配置完成后的 Flash→DDR 搬运。用户实板观察和粗略计时为冷上电到 LED 约 24 秒，KEY0 快速重启较快；该耗时尚未分段测量，连续读取版本仍待重新烧写实板验证。本次更新不修改也不缩短配置阶段。

验证由 `make spi-flash-reader-test`、`make flash-ddr-boot-test`、`make flash-boot-smoke` 和 `make lint` 覆盖。协议模型检查单次 03h 命令、跨 256-byte 页连续读取、长背压、最后 CS 关闭、中止/复位重试和第二片选未使用；端到端模型包含 DDR 写/readback 暂停及最终镜像比对。仿真不等同于 PDS 工程构建或冷上电实板验证。

## Review 清单

- 检查一次 `req_valid/req_ready` 是否携带正确 `req_addr/req_length`；长度为零或越过 24-bit Flash 地址空间时不启动。
- 检查 reader 的 `ST_IDLE → ST_SHIFT → ST_WAIT_RSP`：命令和地址只发送一次；响应等待时 SCK 低、数据稳定、CS 保持低；最后响应握手后 CS 拉高。
- 检查 loader 只发一次 Flash 请求，小端拼字，每个 word 完成 DDR 写/readback 后才接收后续字节；最终 readback 成功后才报告 `boot_done`。
- 检查错误或 DDR init 丢失会中止事务、让 SCK/CS 回到 idle 并关闭 Flash clock；共同复位可重试。
- 对照 reader TB 的 `32 + 8N` 个 SCK 上升沿与单次 CS 事务，并确认 wrapper 的第二片选始终高。

更早的逐字节事务描述见[Flash DDR Boot review](Flash_DDR_Boot_Review.md)，作为历史实现记录保留；其中“每个字节单独发 03h+地址”的行为已由本说明中的连续读取取代。硬件烧写记录与实际设备识别信息见[实板烧写与 DDR 启动记录](PG2L200H_Flash烧写与DDR启动实板记录.md)。
