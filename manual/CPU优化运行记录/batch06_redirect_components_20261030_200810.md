# CPU WNS 优化运行记录：batch06_redirect_components_20261030_200810

配置：Full DDR，CPU 70 MHz，第二屏幕 PDS GUI。当前轮没有修改频率、约束或 NPU/DDR RTL。

```json
{
  "name": "batch06_redirect_components_20261030_200810",
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
      "wns_ns": 46.611,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 3.214,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 3.939,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": -0.795,
      "tns_ns": -67.355,
      "failing_endpoints": 334
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -2.503,
      "tns_ns": -8676.02,
      "failing_endpoints": 10280
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.333,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.129,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.788,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.079,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.646,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 1.501,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 47.995,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 6.048,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 6.383,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.366,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 1.7,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.639,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 6.061,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.18,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.364,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.685,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 3.985,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.22,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.164,
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
      "wns_ns": 0.164,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.106,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.377,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.748,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.145,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.903,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.266,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.281,
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
      "wns_ns": 0.116,
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
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.317,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.104,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.156,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.102,
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
    "wns_ns": -0.795,
    "tns_ns": -67.355,
    "failing_endpoints": 334
  },
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.366,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.164,
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
    "module_LUT": 44852,
    "FF": 47543,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5286,
    "FF": 3677,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_valid/opit_0_L6Q_perm/RS",
      "slack_ns": "-0.795"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/force_fetch/opit_0_L6Q_perm/RS",
      "slack_ns": "-0.795"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/fetch_pending/opit_0_L6Q_perm/I0",
      "slack_ns": "-0.738"
    }
  ],
  "bitstream_sha256": "90418b60358d2902e5af8471be34a08634685f0fcf33136bb30c62b6c5632687",
  "cpu_timing_positive": false
}
```

源码、哈希、报告及阶段日志：build/cpu_wns_20261030/batch06_redirect_components_20261030_200810/。

没有运行 testbench 或 RTL 仿真，没有烧录；时序通过不等于完成指令功能、CoreMark 或识别实板验证。
