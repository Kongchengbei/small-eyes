# CPU WNS 优化运行记录：batch07_squash_alignment_20261030_210356

配置：Full DDR，CPU 70 MHz，第二屏幕 PDS GUI。当前轮没有修改频率、约束或 NPU/DDR RTL。

```json
{
  "name": "batch07_squash_alignment_20261030_210356",
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
      "wns_ns": 47.446,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 2.632,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 2.368,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": -0.531,
      "tns_ns": -37.886,
      "failing_endpoints": 202
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -2.651,
      "tns_ns": -14440.995,
      "failing_endpoints": 11029
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 3.889,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.298,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.867,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.123,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.872,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 1.709,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 48.567,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 5.69,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 5.418,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.503,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 1.692,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.368,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 6.236,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.167,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.471,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.747,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 4.083,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.241,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.143,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.136,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.142,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.14,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.359,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.646,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.26,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.873,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.259,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.277,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.201,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.107,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.101,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.1,
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
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.205,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.163,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.097,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.103,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.115,
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
    "wns_ns": -0.531,
    "tns_ns": -37.886,
    "failing_endpoints": 202
  },
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.503,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.142,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.1,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "resources": {
    "module_LUT": 44847,
    "FF": 47571,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5258,
    "FF": 3677,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[17]/opit_0_L6Q_perm/CE",
      "slack_ns": "-0.531"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[19]/opit_0_L6Q_perm/CE",
      "slack_ns": "-0.531"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ras/entries_7/ram32x2d/WE",
      "slack_ns": "-0.524"
    }
  ],
  "bitstream_sha256": "0f79e5abff8efc60606b3752db3dc00e53ecefbac211ac6096b2563e7e4ec78e",
  "cpu_timing_positive": false
}
```

源码、哈希、报告及阶段日志：build/cpu_wns_20261030/batch07_squash_alignment_20261030_210356/。

没有运行 testbench 或 RTL 仿真，没有烧录；时序通过不等于完成指令功能、CoreMark 或识别实板验证。
