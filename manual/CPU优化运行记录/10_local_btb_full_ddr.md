# CPU 优化运行记录：10_local_btb_full_ddr

配置：full_ddr，CPU 70 MHz。记录由隔离 PDS 运行生成。

## 实际结果

资源分综合（synthesis）、映射（mapped）与布局布线后（post_route）三个口径。最终资源对照使用 PRR 顶层 `Hfpga_soc` 行，不能将映射 LUT 当作最终 LUT。

```json
{
  "returncode": 255,
  "elapsed_seconds": 5971.8,
  "stages": {
    "compile": true,
    "synthesis": true,
    "mapping": true,
    "pnr": true,
    "timing": true,
    "bitstream": false
  },
  "flow_completed": false,
  "all_constraints_met": false,
  "cpu_setup_wns_tns_ns": [
    -0.608,
    -111.052
  ],
  "cpu_hold_wns_ths_ns": [
    0.1,
    0.0
  ],
  "mapped_resources": {
    "LUT": 45116,
    "APM": 69,
    "DRM": 35,
    "Distributed RAM": 1151
  },
  "synthesis_resources": {
    "LUT": 45132,
    "registers": 47377,
    "latches": 0
  },
  "post_route_resources": {
    "LUT": 44853,
    "registers": 47441,
    "Distributed RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "stopped_at_user_request": true,
  "stop_reason": "User requested pause after calculation; timing complete; subsequent bitstream generation deliberately stopped. Exit 255 is from that stop."
}
```

## 对应源码与产物

- 源码快照：`/mnt/c/Users/LEGION/AppData/Local/Temp/socfpga_cpu_batch_20261025/10_local_btb_full_ddr`。
- 源码哈希及配置：`build/cpu_batch_20261025/10_local_btb_full_ddr/manifest.json`。
- 报告及 bitstream：`build/cpu_batch_20261025/10_local_btb_full_ddr/`。
- CPU 源码及配置归档：`build/cpu_batch_20261025/10_local_btb_full_ddr/source/`。
- 正式 CoreMark DAT SHA256：`d1a01d5d364f19cf6203f38a32c79c665bf4c3ad89e41aedf36d667674e5a58a`。

## 验证边界

没有编写或运行 testbench，没有运行 RTL 仿真，没有烧录。PDS 结果仅代表实现与时序检查，不代表指令功能或 CoreMark 分数已经通过实板验证。没有修改目标频率、提交或推送。用户原有 `project/` 目录未用于本次运行。

## 按用户要求暂停

用户要求本轮计算完成后暂停。编译、综合、映射、布局布线和正式时序报告均已完成。CPU setup -0.608 ns、hold +0.100 ns，CPU 70 MHz 仍未闭合；DDR core setup 另为 -3.236 ns。CPU 最差终点为 IFU `fetch_pc_reg[5]/CE`，该信息仅记录供后续继续，不再开展修正。

已停止后续位流生成。退出码 255 来自主动停止，不是本轮新发生的 PDS 内部错误；没有可交付的第10轮完成位流。此后未启动新一轮修改或编译。
