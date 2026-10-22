# NPU 分支合并与 Flash 模型地址说明

日期：2026-10-22。

## 合并范围

将本地 `feature/npu-main-work`（`3fe67a3`，包含队友的 `3dfebdd`）合并到本地 `main`。

- CNN 引擎、图像服务和 INT8 lane 使用队友分支的配套实现。
- 保留 main 的 CPU 修改、摄像头方向/曝光设置、NPU 固件入口和模型格式修正。
- `Hcamera_preprocess.v` 保留 main 的实现。它与 main 的 `Hpreprocess_regions.v` 三级流水和并行区域输出配套，不能直接换成队友分支的串行查询版本。
- DDR 时钟约束保留 main 的配置工具管理版本，避免重复定义时钟。
- PDS 工程移除已删除的旧 NPU 模块引用，补充 `Hnpu_service.v`。生成文件冲突保留 main 的记录；这些旧结果不代表合并后的设计已经完成布局布线。
- 模型保留 main 中的 v0.3 包，长度 62,720 字节，SHA-256 为 `d94e3f16c393a7879d38d6672ed9434a534632e1643a1a722bdb6a685394540c`。

## 程序起始地址没有改变

整个 Flash BIN 仍从 `0x00A00000` 烧录。NPU 电路位于 FPGA 位流中；Flash BIN 包含 CPU 程序段和模型段。

当前合并 BIN 的布局：

| 内容 | BIN 内偏移 | Flash 起始地址 | 长度 | 启动后 DDR 起始地址 |
|---|---:|---:|---:|---:|
| CPU 程序及补齐空间 | `0x0000` | `0x00A00000` | 32,768 字节 | `0x80000000` |
| NPU 模型 | `0x8000` | `0x00A08000` | 62,720 字节 | `0xB9000000` |

BIN 总长为 95,488 字节。CPU 原始程序不足 32 KiB，由打包脚本补齐后接上模型。

`Hfpga_soc.v` 中的模型地址公式：

```verilog
NPU_MODEL_FLASH_BASE = FLASH_BASE + BOOT_IMAGE_BYTES[23:0]
```

`BOOT_IMAGE_BYTES` 是 CPU 段长度，不是整个合并 BIN 的长度。

合并前工作区把该值设为 95,488，会将模型起点算成 `0x00A17500`，而模型实际位于 `0x00A08000`。队友分支提交中的默认值为 16,384，也不能直接搭配当前 CPU 段为 32,768 字节的 BIN。应同时核对烧录文件和生成 FPGA 位流时采用的参数。

这是一处已确认的配置错配。板端 `MODEL=BAD_MAGIC` 是否仅由它造成，仍需重新烧录后验证。

## menuconfig 设置

在 main 根目录运行 `make menuconfig`：

| 选项 | 当前设置 |
|---|---|
| Hardware profile | Full DDR application |
| Enable camera preprocessing | 开启 |
| Firmware BIN path | `bsp/camera_stereo_app/camera_stereo_npu_local_flash.bin` |
| Flash start address | `0xA00000` |
| CPU loader bytes | `0`，或明确填写 `32768` |
| UART TX FPIOA pin | Local pin 0 |

修正后的配置工具通过 NPU1 头、模型长度和可选 CRC 识别合并 BIN。填 `0` 时，会将 CPU 搬运长度生成为 32,768；显式填写总长度 95,488 会报错，且不会提交地址映射修改。

保存后检查 `soc/soc_addr_map.vh`：

```verilog
`define SOC_FLASH_BASE               24'hA00000
`define SOC_BOOT_IMAGE_BYTES         32'd32768
`define SOC_NPU_MODEL_BYTES          32'd62720
```

`build/menuconfig/flash_manifest.json` 分别记录 CPU 搬运长度、模型地址和整个烧录文件长度。原始文件与配置已备份到本机 `/tmp/socfpga-main-merge-20261022-204937/original/`。

## 构建和上板

```sh
make -C bsp/camera_stereo_app npu-local
make menuconfig
make config-check
```

如果修改了 CPU 段长度，请重新运行固件构建，再保存 menuconfig。打包目标会依赖地址映射和打包脚本，避免复用旧偏移的合并 BIN。

在 PDS 中重新生成 FPGA 位流并检查时序。烧录新位流后，将**整个** `camera_stereo_npu_local_flash.bin` 从 Flash `0x00A00000` 写入。不能只烧录不含模型的 16 KiB `camera_stereo_npu_local.bin`。

复位后检查串口：DDR `0xB9000000` 的 magic 应为 `0x3155504E`（字节顺序为 `NPU1`）。仍为零时，再检查实际烧录文件、位流参数和 Flash 写入结果。

## 验证范围与保留问题

已构建配置工具和本地 NPU 固件，核对模型 CRC、分段偏移和烧录清单。配置保存已检查自动长度、显式 CPU 段长度以及错误总长度的拒绝处理。

合并后的完整 SoC 已通过 PDS 2022.2-SP6.4 build 146967 Compile，目标器件为 PG2L200H/FBB676/-6。Compile 用时 1 分 14 秒，峰值内存 552 MB，日志没有 `E:` 或 `F:` 错误。

编译在临时目录进行，日志位于本机 `C:/Users/LEGION/AppData/Local/Temp/socfpga_main_merge_20261022/project/compile/run.log`。没有编写或运行 testbench，没有执行本次合并后的综合、布局布线、时序验收或板端烧录。

此前分支审查发现的通用模型边界仍保留：卷积直接右移路径没有实现非直接模式的舍入；32 位卷积累加器缺少任意 INT32 bias 的溢出限制。本次没有改动这些计算语义，不能据此宣称支持所有符合包格式的模型。当前固定 v0.3 模型是否在板上正确识别，仍需实际验收。
