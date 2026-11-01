# DDR 时序优化运行记录：ddr02_metadata_vendor_candidate_20261031_191558

配置：Full DDR，CPU 70 MHz，DDR core 125 MHz，第二屏幕 PDS GUI。NPU 校验及 INT8 缓冲修改由 Luna high 编写、主代理审查。保持模型协议与频率；时钟组是否变化及有效两拍路径核验见 JSON。

```json
{
  "name": "ddr02_metadata_vendor_candidate_20261031_191558",
  "git_head": "9481c57b5f954b3e1df256531036d1406b0b2107",
  "stages": {
    "compile": true,
    "synthesis": true,
    "mapping": true,
    "pnr": true,
    "timing": true,
    "bitstream": true
  },
  "stage_errors": {
    "compile": [],
    "synthesis": [],
    "mapping": [],
    "pnr": [],
    "timing": [],
    "bitstream": []
  },
  "all_constraints_met": false,
  "cpu_hz": 70000000,
  "ddr_core_hz": 125000000,
  "testbench_run": false,
  "rtl_simulation_run": false,
  "board_programmed": false,
  "clock_constraints_changed": true,
  "constraint_candidate_only": true,
  "constraint_change_kind": "vendor_ip_independent_single_groups",
  "setup_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 46.805,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 617
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 3.442,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 738
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 3.155,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 740
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.745,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22202
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -0.322,
      "tns_ns": -10.875,
      "failing_endpoints": 76,
      "total_endpoints": 112923
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.496,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.159,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.941,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.469,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 2.32,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_setup_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.745,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22202
  },
  "ddr_setup_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": -0.322,
    "tns_ns": -10.875,
    "failing_endpoints": 76,
    "total_endpoints": 112923
  },
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 48.136,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 617
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 6.043,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 738
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 6.005,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 740
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 6.162,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22202
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 2.884,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 112923
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.818,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 6.143,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.272,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.571,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 4.423,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 6.162,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22202
  },
  "ddr_setup_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 2.884,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 112923
  },
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.297,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 617
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.29,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 738
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.247,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 740
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.141,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22202
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.123,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 112923
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.366,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.706,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.243,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.267,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.261,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.141,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22202
  },
  "ddr_hold_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.123,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 112923
  },
  "hold_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.2,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 617
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.184,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 738
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.165,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 740
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.102,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22202
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 112923
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.099,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.27,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.157,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.107,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.101,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_hold_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.102,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22202
  },
  "ddr_hold_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.1,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 112923
  },
  "recovery_slow": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 5.877,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 6.265,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.746,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2791
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 3.553,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7903
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.327,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_recovery_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.746,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2791
  },
  "ddr_recovery_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 3.553,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7903
  },
  "recovery_fast": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 7.451,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 7.704,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 8.881,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2791
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 5.24,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7903
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.938,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_recovery_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 8.881,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2791
  },
  "ddr_recovery_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 5.24,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7903
  },
  "removal_slow": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 1.322,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 1.101,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.578,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2791
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.259,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7903
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.43,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_removal_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.578,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2791
  },
  "ddr_removal_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.259,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7903
  },
  "removal_fast": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.816,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.732,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.394,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2791
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.175,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7903
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.286,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_removal_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.394,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2791
  },
  "ddr_removal_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.175,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7903
  },
  "cpu_pulse_width_slow": {
    "worst_slack_ns": 6.182,
    "failing_endpoints": 0
  },
  "ddr_pulse_width_slow": {
    "worst_slack_ns": 3.04,
    "failing_endpoints": 0
  },
  "cpu_pulse_width_fast": {
    "worst_slack_ns": 6.487,
    "failing_endpoints": 0
  },
  "ddr_pulse_width_fast": {
    "worst_slack_ns": 3.345,
    "failing_endpoints": 0
  },
  "cpu_self_checks_pass": true,
  "ddr_self_checks_pass": false,
  "resources": {
    "module_LUT": 44826,
    "FF": 47935,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5290,
    "FF": 3683,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[0]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.745,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[14]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.755,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[20]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.755,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[2]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.786,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[9]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.786,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[15]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.816,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[18]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.816,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L6Q_perm/I2",
      "slack_ns": 0.82,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L6Q_perm/I4",
      "slack_ns": 0.906,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[17]/opit_0_AQ_perm/CE",
      "slack_ns": 0.906,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[4]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.932,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[7]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.932,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[1].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/ADB[8]",
      "slack_ns": 0.933,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[10]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.942,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[26]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.942,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[19]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.943,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[21]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.943,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[25]/opit_0_AQ_perm/CE",
      "slack_ns": 0.964,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[13]/opit_0_AQ_perm/CE",
      "slack_ns": 0.966,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[24]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.986,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[25]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.986,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[0].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/ADB[8]",
      "slack_ns": 1.002,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_pc_reg[19]/opit_0/CE",
      "slack_ns": 1.006,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_pc_reg[22]/opit_0/CE",
      "slack_ns": 1.006,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[11]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.008,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[5]/opit_0_AQ_perm/CE",
      "slack_ns": 1.008,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[1].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/ADB[11]",
      "slack_ns": 1.033,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L6Q_perm/I1",
      "slack_ns": 1.045,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[9]/opit_0_L6Q_perm/I3",
      "slack_ns": 1.05,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[4]/opit_0_L6Q_perm/I5",
      "slack_ns": 1.052,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[3]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.063,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[13]/opit_0_L6Q_perm/I0",
      "slack_ns": 1.076,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[12]/opit_0_L6Q_perm/I5",
      "slack_ns": 1.083,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_ins_reg[17]/opit_0/CE",
      "slack_ns": 1.084,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_ins_reg[19]/opit_0/CE",
      "slack_ns": 1.084,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[25]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.088,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[31]/opit_0_AQ_perm/CE",
      "slack_ns": 1.095,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtvec[13]/opit_0/CE",
      "slack_ns": 1.102,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtvec[15]/opit_0/CE",
      "slack_ns": 1.102,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[8]/opit_0_L6Q_perm/I2",
      "slack_ns": 1.105,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_pc_reg[0]/opit_0/CE",
      "slack_ns": 1.105,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_pc_reg[5]/opit_0/CE",
      "slack_ns": 1.105,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[1]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.107,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[5]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.107,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[23]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.108,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[27]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.108,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[21]/opit_0_AQ_perm/CE",
      "slack_ns": 1.109,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[1].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/ADA[8]",
      "slack_ns": 1.116,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[19]/opit_0_AQ_perm/CE",
      "slack_ns": 1.128,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[16]/opit_0_L6Q_perm/I2",
      "slack_ns": 1.131,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[11]/opit_0_L6Q_perm/I2",
      "slack_ns": 1.137,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_pc_reg[29]/opit_0/CE",
      "slack_ns": 1.14,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[15]/opit_0_AQ_perm/CE",
      "slack_ns": 1.141,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[9]/opit_0_AQ_perm/CE",
      "slack_ns": 1.144,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[26]/opit_0_L6Q_perm/I5",
      "slack_ns": 1.147,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[6]/opit_0_L6Q_perm/I3",
      "slack_ns": 1.149,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[14]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.149,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[15]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.149,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[31]/opit_0_AQ_perm/CE",
      "slack_ns": 1.149,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_csr_addr[5]/opit_0_L6QL5Q_perm/CE",
      "slack_ns": 1.152,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_csr_addr[9]/opit_0_L6QL5Q_perm/CE",
      "slack_ns": 1.152,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wdata[19]/opit_0_L6Q_perm/I4",
      "slack_ns": 1.154,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/request_buffer_wstrb[0]/opit_0_L6Q_LUT6DQL5Q_perm/I3",
      "slack_ns": 1.156,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[6]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.157,
      "type": "max (slow corner)"
    }
  ],
  "worst_ddr_paths": [
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[8]",
      "slack_ns": -0.322,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[19]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.318,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_3/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.313,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.312,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.31,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[23]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.3,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_1/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.296,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.269,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.266,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.26,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_3/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.26,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[25]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.249,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_3/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.233,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[29]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.229,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.218,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_1/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.216,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[27]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.21,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[17]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.206,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/state[1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": -0.205,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_3/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.204,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[7]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.192,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[1]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.186,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_1/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/N9720.lt_29/gateop_perm/CIN",
      "slack_ns": -0.185,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[13]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.184,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[16]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.184,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[10]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.167,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[14]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.167,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[31]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.162,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[6]",
      "slack_ns": -0.161,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_1/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.159,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[8]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.154,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[11]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.154,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[15]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.154,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/state[3]/opit_0_inv_L6Q_perm/I0",
      "slack_ns": -0.154,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_1/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.153,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[3]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.152,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[21]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.141,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_model_encoding_valid/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.141,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/descriptor_scan_legacy/opit_0_inv/CE",
      "slack_ns": -0.136,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[6]",
      "slack_ns": -0.136,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[8]",
      "slack_ns": -0.135,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_h[2]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.127,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_h[12]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.127,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[7]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.119,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[9]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.119,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/error/opit_0_inv_L6Q_perm/I2",
      "slack_ns": -0.115,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_1/gopdrm_36k/ADB0[8]",
      "slack_ns": -0.11,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[12]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.104,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/state[4]/opit_0_inv_L6Q_perm/I2",
      "slack_ns": -0.098,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_3/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.098,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_h[9]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.092,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[14]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.092,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[12]",
      "slack_ns": -0.091,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.086,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kernel_size_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_1/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.084,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_scan_index[2]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.075,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_scan_index[4]/opit_0_inv_L6Q_perm/CE",
      "slack_ns": -0.075,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_expected_scratch[9]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.069,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_w[6]/opit_0_inv_L5Q_perm/CE",
      "slack_ns": -0.066,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_1/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.065,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_3/gopdrm_36k/ADB0[12]",
      "slack_ns": -0.061,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_kh_kw_m1[4]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_0/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.059,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/legacy_scan_index[3]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.058,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_input_hw_reg[3]/opit_0_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/expected_in_h[8]/opit_0_inv_L6QL5Q_perm/CE",
      "slack_ns": -0.042,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[48]/opit_0_inv_srl/D",
      "slack_ns": 4.496,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[18]/opit_0_inv_srl/D",
      "slack_ns": 4.59,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[26]/opit_0_inv_srl/D",
      "slack_ns": 4.608,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[45]/opit_0_inv_srl/D",
      "slack_ns": 4.623,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[54]/opit_0_inv_srl/D",
      "slack_ns": 4.633,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[4]/opit_0_inv_srl/D",
      "slack_ns": 4.634,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[42]/opit_0_inv_srl/D",
      "slack_ns": 4.644,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[44]/opit_0_inv_srl/D",
      "slack_ns": 4.667,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.678,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[63]/opit_0_inv_srl/D",
      "slack_ns": 4.697,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[35]/opit_0_inv_srl/D",
      "slack_ns": 4.7,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[34]/opit_0_inv_srl/D",
      "slack_ns": 4.708,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[19]/opit_0_inv_srl/D",
      "slack_ns": 4.716,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[41]/opit_0_inv_srl/D",
      "slack_ns": 4.726,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[5]/opit_0_inv_srl/D",
      "slack_ns": 4.729,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[27]/opit_0_inv_srl/D",
      "slack_ns": 4.731,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[35]/opit_0_inv_srl/D",
      "slack_ns": 4.732,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[14]/opit_0_inv_srl/D",
      "slack_ns": 4.733,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[62]/opit_0_inv_srl/D",
      "slack_ns": 4.735,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[42]/opit_0_inv_srl/D",
      "slack_ns": 4.739,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[40]/opit_0_inv_srl/D",
      "slack_ns": 4.741,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[20]/opit_0_inv_srl/D",
      "slack_ns": 4.745,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[60]/opit_0_inv_srl/D",
      "slack_ns": 4.747,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[13]/opit_0_inv_srl/D",
      "slack_ns": 4.753,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[56]/opit_0_inv_srl/D",
      "slack_ns": 4.762,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[20]/opit_0_inv_srl/D",
      "slack_ns": 4.768,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[25]/opit_0_inv_srl/D",
      "slack_ns": 4.77,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[29]/opit_0_inv_srl/D",
      "slack_ns": 4.771,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[35]/opit_0_inv_srl/D",
      "slack_ns": 4.773,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[63]/opit_0_inv_srl/D",
      "slack_ns": 4.776,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[52]/opit_0_inv_srl/D",
      "slack_ns": 4.785,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[63]/opit_0_inv_srl/D",
      "slack_ns": 4.786,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.787,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[8]/opit_0_inv_srl/D",
      "slack_ns": 4.792,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[6]/opit_0_inv_srl/D",
      "slack_ns": 4.797,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[55]/opit_0_inv_srl/D",
      "slack_ns": 4.798,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[29]/opit_0_inv_srl/D",
      "slack_ns": 4.799,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[46]/opit_0_inv_srl/D",
      "slack_ns": 4.802,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[32]/opit_0_inv_srl/D",
      "slack_ns": 4.803,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[17]/opit_0_inv_srl/D",
      "slack_ns": 4.808,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[44]/opit_0_inv_srl/D",
      "slack_ns": 4.81,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[59]/opit_0_inv_srl/D",
      "slack_ns": 4.814,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[37]/opit_0_inv_srl/D",
      "slack_ns": 4.817,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[30]/opit_0_inv_srl/D",
      "slack_ns": 4.82,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[2]/opit_0_inv_srl/D",
      "slack_ns": 4.821,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[15]/opit_0_inv_srl/D",
      "slack_ns": 4.821,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[36]/opit_0_inv_srl/D",
      "slack_ns": 4.821,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[45]/opit_0_inv_srl/D",
      "slack_ns": 4.821,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[28]/opit_0_inv_srl/D",
      "slack_ns": 4.823,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[14]/opit_0_inv_srl/D",
      "slack_ns": 4.825,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[49]/opit_0_inv_srl/D",
      "slack_ns": 4.829,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[53]/opit_0_inv_srl/D",
      "slack_ns": 4.832,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[27]/opit_0_inv_srl/D",
      "slack_ns": 4.835,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.839,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[7]/opit_0_inv_srl/D",
      "slack_ns": 4.842,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[61]/opit_0_inv_srl/D",
      "slack_ns": 4.842,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[46]/opit_0_inv_srl/D",
      "slack_ns": 4.844,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[63]/opit_0_inv_srl/D",
      "slack_ns": 4.848,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[38]/opit_0_inv_srl/D",
      "slack_ns": 4.849,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[62]/opit_0_inv_srl/D",
      "slack_ns": 4.85,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[51]/opit_0_inv_srl/D",
      "slack_ns": 4.853,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[3]/opit_0_inv_srl/D",
      "slack_ns": 4.854,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[5]/opit_0_inv_srl/D",
      "slack_ns": 4.855,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[13]/opit_0_inv_srl/D",
      "slack_ns": 4.856,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/u_ddrphy_cpd/cpd_inst/CLK_PHY",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/u_ips2l_ddrphy_cpd_lock/ddrphy_cpd_up_dnb_d[0]/opit_0_inv_srl/D",
      "slack_ns": 5.159,
      "type": "max (slow corner)"
    }
  ],
  "negative_async_paths": [],
  "phy_multicycle_paths": {
    "phy_dq_sysclk_0": {
      "reported_slow_setup_paths": 64,
      "explicit_two_cycle_paths": 64
    },
    "phy_dq_sysclk_1": {
      "reported_slow_setup_paths": 64,
      "explicit_two_cycle_paths": 64
    }
  },
  "negative_ddr_endpoint_groups": {
    "NPU": 64
  },
  "vendor_group_checks": {
    "checks": {
      "phy_dq_sysclk_0_setup_slow": true,
      "phy_dq_sysclk_0_setup_fast": true,
      "phy_dq_sysclk_0_hold_slow": true,
      "phy_dq_sysclk_0_hold_fast": true,
      "phy_dq_sysclk_0_explicit_two_cycle": true,
      "phy_dq_sysclk_1_setup_slow": true,
      "phy_dq_sysclk_1_setup_fast": true,
      "phy_dq_sysclk_1_hold_slow": true,
      "phy_dq_sysclk_1_hold_fast": true,
      "phy_dq_sysclk_1_explicit_two_cycle": true,
      "named_vendor_groups_present": true
    },
    "all_pass": true
  },
  "bitstream_sha256": "4a23150952507712d3a71434a566d81887eda3398cacabd1b9e4d67bdd085044"
}
```

源码、哈希与完整报告在 build/ddr_wns_20261031/ddr02_metadata_vendor_candidate_20261031_191558/。没有编写或运行 testbench、RTL 仿真或烧录；时序结论不代替板上正确性和吞吐验证。
