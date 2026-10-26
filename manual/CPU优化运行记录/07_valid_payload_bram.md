# CPU 优化运行记录：07_valid_payload_bram

配置：bram，CPU 70 MHz。记录由隔离 PDS 运行生成。

## 实际结果

资源分综合（synthesis）、映射（mapped）与布局布线后（post_route）三个口径。最终资源对照使用 PRR 顶层 `Hfpga_soc` 行，不能将映射 LUT 当作最终 LUT。

```json
{
  "returncode": 0,
  "elapsed_seconds": 744.7,
  "stages": {
    "compile": true,
    "synthesis": true,
    "mapping": true,
    "pnr": true,
    "timing": true,
    "bitstream": true
  },
  "flow_completed": true,
  "all_constraints_met": true,
  "cpu_setup_wns_tns_ns": [
    0.829,
    0.0
  ],
  "cpu_hold_wns_ths_ns": [
    0.145,
    0.0
  ],
  "mapped_resources": {
    "LUT": 4657,
    "APM": 4,
    "DRM": 12,
    "Distributed RAM": 16
  },
  "synthesis_resources": {
    "LUT": 4659,
    "registers": 4361,
    "latches": 0
  },
  "post_route_resources": {
    "LUT": 4590,
    "registers": 4371,
    "Distributed RAM": 16,
    "APM": 4,
    "DRM": 12
  },
  "bitstream_sha256": "fad5e5fbd84f0eaa9956303fd3d2c26cc03db31aa5eaa81f30b5bd89fcd537db"
}
```

## 对应源码与产物

- 源码快照：`/mnt/c/Users/LEGION/AppData/Local/Temp/socfpga_cpu_batch_20261025/07_valid_payload_bram`。
- 源码哈希及配置：`build/cpu_batch_20261025/07_valid_payload_bram/manifest.json`。
- 报告及 bitstream：`build/cpu_batch_20261025/07_valid_payload_bram/`。
- CPU 源码及配置归档：`build/cpu_batch_20261025/07_valid_payload_bram/source/`。
- 正式 CoreMark DAT SHA256：`d1a01d5d364f19cf6203f38a32c79c665bf4c3ad89e41aedf36d667674e5a58a`。

## 验证边界

没有编写或运行 testbench，没有运行 RTL 仿真，没有烧录。PDS 结果仅代表实现与时序检查，不代表指令功能或 CoreMark 分数已经通过实板验证。没有修改目标频率、提交或推送。用户原有 `project/` 目录未用于本次运行。
