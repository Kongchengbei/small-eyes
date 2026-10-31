# CPU WNS 优化运行记录：batch04_branch_compare_20261030_130304

配置：Full DDR，CPU 70 MHz，第二屏幕 PDS GUI。当前轮没有修改频率、约束或 NPU/DDR RTL。

```json
{
  "name": "batch04_branch_compare_20261030_130304",
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
      "wns_ns": 46.892,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 1.355,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 1.823,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": -0.586,
      "tns_ns": -11.84,
      "failing_endpoints": 84
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -2.717,
      "tns_ns": -7476.414,
      "failing_endpoints": 10070
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.153,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 4.697,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.52,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.726,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 1.933,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.098,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 48.179,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 4.843,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 5.157,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.397,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 1.714,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.613,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.844,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.843,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.233,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.362,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 3.049,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    }
  ],
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.198,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.219,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.231,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.143,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.102,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.353,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 1.109,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.119,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.2,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.339,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.306,
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
      "wns_ns": 0.148,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.149,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.102,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.099,
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
      "wns_ns": 0.497,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.125,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_rst_clk",
      "wns_ns": 1.263,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.13,
      "tns_ns": 0.0,
      "failing_endpoints": 0
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.1,
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
    "wns_ns": -0.586,
    "tns_ns": -11.84,
    "failing_endpoints": 84
  },
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.397,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.143,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "cpu_hold_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.102,
    "tns_ns": 0.0,
    "failing_endpoints": 0
  },
  "resources": {
    "module_LUT": 44895,
    "FF": 47491,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5305,
    "FF": 3614,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/forced_fetch_pc[11]/opit_0_AQ_perm/CE",
      "slack_ns": "-0.586"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/forced_fetch_pc[10]/opit_0_AQ_perm/CE",
      "slack_ns": "-0.577"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_ifu/forced_fetch_pc[9]/opit_0_AQ_perm/CE",
      "slack_ns": "-0.511"
    }
  ],
  "bitstream_sha256": "69c9223756b1243f5561298a96396c473c3d0fd0a1f043d3d95f4f70f942fdb7",
  "cpu_timing_positive": false
}
```

源码、哈希、报告及阶段日志：build/cpu_wns_20261030/batch04_branch_compare_20261030_130304/。

没有运行 testbench 或 RTL 仿真，没有烧录；时序通过不等于完成指令功能、CoreMark 或识别实板验证。
