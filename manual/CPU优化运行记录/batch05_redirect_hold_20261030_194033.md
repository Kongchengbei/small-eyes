# CPU WNS 优化运行记录：batch05_redirect_hold_20261030_194033

配置：Full DDR，CPU 70 MHz，第二屏幕 PDS GUI。当前轮没有修改频率、约束或 NPU/DDR RTL。

```json
{
  "name": "batch05_redirect_hold_20261030_194033",
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
      "wns_ns": 46.34,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 2.731,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 3.679,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": -0.362,
      "tns_ns": -5.229,
      "failing_endpoints": 32
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -2.728,
      "tns_ns": -8805.414,
      "failing_endpoints": 10666
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.492,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.098,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.94,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.037,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.033,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.038,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 47.834,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 5.774,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 6.328,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.548,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 1.723,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.801,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 6.107,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.2,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.404,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.297,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 2.988,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_slow": [
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
      "wns_ns": 0.196,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.141,
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
      "wns_ns": 0.101,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.342,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.797,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.244,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.95,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.251,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.287,
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
      "wns_ns": 0.131,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.103,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.105,
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
      "wns_ns": 0.099,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.274,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.158,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.11,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.101,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.101,
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
    "wns_ns": -0.362,
    "tns_ns": -5.229,
    "failing_endpoints": 32
  },
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.548,
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
    "wns_ns": 0.105,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "resources": {
    "module_LUT": 44947,
    "FF": 47460,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5244,
    "FF": 3612,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/redirect_sample_pc[27]/opit_0_L6Q_perm/I2",
      "slack_ns": "-0.362"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/redirect_sample_pc[5]/opit_0_L6Q_perm/I2",
      "slack_ns": "-0.360"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/redirect_sample_pc[16]/opit_0_L6Q_perm/I5",
      "slack_ns": "-0.354"
    }
  ],
  "bitstream_sha256": "35f6658411c86ff506ede136719311076f80932032e0cf1c8812922fd4bef77f",
  "cpu_timing_positive": false
}
```

源码、哈希、报告及阶段日志：build/cpu_wns_20261030/batch05_redirect_hold_20261030_194033/。

没有运行 testbench 或 RTL 仿真，没有烧录；时序通过不等于完成指令功能、CoreMark 或识别实板验证。
