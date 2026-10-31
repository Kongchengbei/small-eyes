# CPU WNS 优化运行记录：batch08_ex_ras_payload_20261030_213837

配置：Full DDR，CPU 70 MHz，第二屏幕 PDS GUI。当前轮没有修改频率、约束或 NPU/DDR RTL。

```json
{
  "name": "batch08_ex_ras_payload_20261030_213837",
  "stages": {
    "compile": true,
    "synthesis": true,
    "mapping": true,
    "pnr": true,
    "timing": true,
    "bitstream": true
  },
  "all_constraints_met": false,
  "setup_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 47.056,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 2.727,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 2.457,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": -0.003,
      "tns_ns": -0.003,
      "failing_endpoints": 1
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -2.131,
      "tns_ns": -8202.149,
      "failing_endpoints": 10272
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.104,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 4.931,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.37,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.597,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.001,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 2.515,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 48.31,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 5.646,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 5.591,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.68,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 1.98,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.545,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.992,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.714,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.107,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.28,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 4.709,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.207,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.261,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.166,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.111,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.121,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.355,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.887,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.107,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.26,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.241,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.268,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.2,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.146,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.116,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.108,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.098,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.385,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.103,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.346,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.102,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "cpu_hz": 70000000,
  "testbench_run": false,
  "board_programmed": false,
  "cpu_setup_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": -0.003,
    "tns_ns": -0.003,
    "failing_endpoints": 1
  },
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.68,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.111,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.108,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "resources": {
    "module_LUT": 44772,
    "FF": 47607,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5207,
    "FF": 3698,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_mul/N16/gopapm/CE_M",
      "slack_ns": "-0.003"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_mul/N13/gopapm/CE_M",
      "slack_ns": "0.046"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_div_done/opit_0_L5Q_perm/RS",
      "slack_ns": "0.092"
    }
  ],
  "bitstream_sha256": "795efbec8e00bcd24f97897a64ee57271538843f8fd1badf0398e4c11e62e0ee",
  "cpu_timing_positive": false
}
```

源码、哈希、报告及阶段日志：build/cpu_wns_20261030/batch08_ex_ras_payload_20261030_213837/。

没有运行 testbench 或 RTL 仿真，没有烧录；时序通过不等于完成指令功能、CoreMark 或识别实板验证。

本批采用第二次 P&R 的成功结果。第一次运行因跨夜挂起触发单次迭代 2000 秒上限，失败日志单独保存在 attempt01_paused_timeout/。第二次从原映射结果重跑，耗时 32 分 11 秒，不含挂起时间；源码、频率和时序约束均未改变。
