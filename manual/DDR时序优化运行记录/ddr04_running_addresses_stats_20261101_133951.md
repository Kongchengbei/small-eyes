# DDR 时序优化运行记录：ddr04_running_addresses_stats_20261101_133951

配置：Full DDR，CPU 70 MHz，DDR core 125 MHz，第二屏幕 PDS GUI。NPU 校验及 INT8 缓冲修改由 Luna high 编写、主代理审查。保持模型协议与频率；时钟组是否变化及有效两拍路径核验见 JSON。

```json
{
  "name": "ddr04_running_addresses_stats_20261101_133951",
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
  "all_constraints_met": true,
  "cpu_hz": 70000000,
  "ddr_core_hz": 125000000,
  "testbench_run": false,
  "rtl_simulation_run": false,
  "board_programmed": false,
  "clock_constraints_changed": true,
  "constraint_candidate_only": false,
  "constraint_change_kind": "vendor_ip_independent_single_groups",
  "setup_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 46.759,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 625
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 4.509,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 729
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 3.513,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 714
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.799,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22058
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.04,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113335
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.462,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 4.878,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.976,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 434
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.094,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 2.274,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_setup_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.799,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22058
  },
  "ddr_setup_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.04,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113335
  },
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 48.082,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 625
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 6.807,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 729
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 6.14,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 714
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 6.317,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22058
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 2.708,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113335
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.819,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 6.055,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.246,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 434
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.327,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 4.404,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 6.317,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22058
  },
  "ddr_setup_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 2.708,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113335
  },
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.201,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 625
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.214,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 729
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.259,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 714
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.156,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22058
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113335
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.36,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.81,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.273,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 434
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.261,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.259,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.156,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22058
  },
  "ddr_hold_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.1,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113335
  },
  "hold_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.199,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 625
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.146,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 729
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.179,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 714
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.108,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22058
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.099,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113335
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.389,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.173,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 434
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.104,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_hold_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.108,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22058
  },
  "ddr_hold_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.099,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113335
  },
  "recovery_slow": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 6.226,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 6.176,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 6.594,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2793
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 2.317,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7919
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.356,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 100
    }
  ],
  "cpu_recovery_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 6.594,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2793
  },
  "ddr_recovery_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 2.317,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7919
  },
  "recovery_fast": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 7.741,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 7.626,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 9.495,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2793
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 4.484,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7919
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.412,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 100
    }
  ],
  "cpu_recovery_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 9.495,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2793
  },
  "ddr_recovery_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 4.484,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7919
  },
  "removal_slow": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.751,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 1.314,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.743,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2793
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.418,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7919
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.365,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 100
    }
  ],
  "cpu_removal_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.743,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2793
  },
  "ddr_removal_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.418,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7919
  },
  "removal_fast": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.506,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.849,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.505,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2793
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.282,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7919
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.247,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 100
    }
  ],
  "cpu_removal_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.505,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2793
  },
  "ddr_removal_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.282,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7919
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
  "ddr_self_checks_pass": true,
  "resources": {
    "module_LUT": 44422,
    "FF": 47970,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5283,
    "FF": 3685,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[31]/opit_0_AQ_perm/CE",
      "slack_ns": 0.799,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[31]/opit_0_AQ_perm/CE",
      "slack_ns": 0.858,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[63]/opit_0_AQ_perm/CE",
      "slack_ns": 0.932,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[31]/opit_0_AQ_perm/CE",
      "slack_ns": 0.932,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[27]/opit_0_AQ_perm/CE",
      "slack_ns": 0.946,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[63]/opit_0_AQ_perm/CE",
      "slack_ns": 0.984,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L6Q_perm/I5",
      "slack_ns": 1.004,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[27]/opit_0_AQ_perm/CE",
      "slack_ns": 1.005,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[31]/opit_0_AQ_perm/RS",
      "slack_ns": 1.033,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/N371_1/gateop_perm/I2",
      "slack_ns": 1.034,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L6Q_perm/I0",
      "slack_ns": 1.079,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[59]/opit_0_AQ_perm/CE",
      "slack_ns": 1.079,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[27]/opit_0_AQ_perm/CE",
      "slack_ns": 1.079,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[23]/opit_0_AQ_perm/CE",
      "slack_ns": 1.093,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[27]/opit_0_AQ_perm/RS",
      "slack_ns": 1.113,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/remainder_reg[31]/opit_0_AQ_perm/CE",
      "slack_ns": 1.125,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtvec[16]/opit_0/CE",
      "slack_ns": 1.127,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[59]/opit_0_AQ_perm/CE",
      "slack_ns": 1.131,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[23]/opit_0_AQ_perm/CE",
      "slack_ns": 1.152,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mscratch[19]/opit_0/CE",
      "slack_ns": 1.159,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[4]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.172,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[21]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.172,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L6Q_perm/I1",
      "slack_ns": 1.18,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[6]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.186,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[8]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.186,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[22]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.19,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[29]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.19,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[23]/opit_0_AQ_perm/RS",
      "slack_ns": 1.193,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[12]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.198,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[14]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.198,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mscratch[26]/opit_0/CE",
      "slack_ns": 1.2,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mscratch[29]/opit_0/CE",
      "slack_ns": 1.2,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[15]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.203,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mscratch[23]/opit_0/CE",
      "slack_ns": 1.208,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[2]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.211,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[5]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.211,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[7]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.214,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[25]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.214,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[55]/opit_0_AQ_perm/CE",
      "slack_ns": 1.226,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[23]/opit_0_AQ_perm/CE",
      "slack_ns": 1.226,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[18]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.235,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[20]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.235,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[27]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.235,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[28]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.235,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mscratch[22]/opit_0/CE",
      "slack_ns": 1.238,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_minstret[19]/opit_0_AQ_perm/CE",
      "slack_ns": 1.24,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[28]/opit_0_AQ_perm/CIN",
      "slack_ns": 1.25,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[14]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.269,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/remainder_reg[27]/opit_0_AQ_perm/CE",
      "slack_ns": 1.272,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_div/quotient_reg[19]/opit_0_AQ_perm/RS",
      "slack_ns": 1.273,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[55]/opit_0_AQ_perm/CE",
      "slack_ns": 1.278,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[26]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.282,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[31]/opit_0_L5Q_perm/CE",
      "slack_ns": 1.282,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[30]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.284,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[31]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.284,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[13]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.297,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[17]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.297,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/data_ram_way[1].data_ram_bank[2].u/u_ram/U_ipml_spram_DataRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[19]/opit_0_AQ_perm/CE",
      "slack_ns": 1.299,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[11]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.305,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[26]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.305,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtvec[24]/opit_0/CE",
      "slack_ns": 1.311,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtvec[26]/opit_0/CE",
      "slack_ns": 1.311,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[10]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.32,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[1].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mepc[16]/opit_0_L6Q_perm/CE",
      "slack_ns": 1.32,
      "type": "max (slow corner)"
    }
  ],
  "worst_ddr_paths": [
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.04,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[8]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.111,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[11]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.117,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[9]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.138,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[7]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.14,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[6]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.145,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[10]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.145,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[12]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.145,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[4]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.147,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_3/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/N9109.lt_29/gateop_perm/CIN",
      "slack_ns": 0.16,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[17]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.161,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[5]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.162,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[2]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.169,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[15]/opit_0_inv_L6Q_perm/I2",
      "slack_ns": 0.175,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[14]/opit_0_inv_L6Q_perm/I2",
      "slack_ns": 0.203,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[3]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.231,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[13]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.245,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[0]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.255,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_shift[0]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[2]/opit_0_inv_L6Q_perm/I1",
      "slack_ns": 0.358,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_shift[0]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[0]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.359,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[31][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.371,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/mac_product[16]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.372,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[10][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.385,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[29][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.388,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[53][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.388,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_shift[0]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[0]/opit_0_inv_L6Q_perm/I2",
      "slack_ns": 0.389,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[0][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.392,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[32][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.405,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/gap_position[2]/opit_0_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[13]",
      "slack_ns": 0.415,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[54][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.416,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_shift[0]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[5]/opit_0_inv_L6Q_perm/I2",
      "slack_ns": 0.421,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[27][1]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.421,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[12][1]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.425,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[42][1]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.425,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[16][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.426,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[8][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.43,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[14][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.43,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[40][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.432,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[19][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.433,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[39][1]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.433,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[15][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.435,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/gap_position[2]/opit_0_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[13]",
      "slack_ns": 0.437,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_shift[0]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[5]/opit_0_inv_L6Q_perm/I0",
      "slack_ns": 0.44,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[11][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.442,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[55][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.442,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_shift[0]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[4]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.445,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_header_mem[58][5]/opit_0/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/read_addr_reg[29]/opit_0_inv_AQ_perm/I1",
      "slack_ns": 0.446,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[52][1]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.45,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[20][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.454,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[33][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.455,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[49][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.455,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_layout_reg[5]/opit_0_inv/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_addr[10]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.457,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[26][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.458,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[30][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.458,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[34][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.459,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[36][0]/opit_0_inv_L6Q_perm/I3",
      "slack_ns": 0.462,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[21][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.469,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[22][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.474,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[48][1]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.477,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[3][0]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.478,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[5][0]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.478,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[44][0]/opit_0_inv_L6Q_perm/I4",
      "slack_ns": 0.478,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/image_rgb_base[17]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/slot_state[46][1]/opit_0_inv_L6Q_perm/I5",
      "slack_ns": 0.478,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_write_data[4]/opit_0_inv_L6Q_perm/I2",
      "slack_ns": 0.481,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[5]/opit_0_inv_srl/D",
      "slack_ns": 4.462,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[29]/opit_0_inv_srl/D",
      "slack_ns": 4.542,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[4]/opit_0_inv_srl/D",
      "slack_ns": 4.606,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[18]/opit_0_inv_srl/D",
      "slack_ns": 4.639,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[61]/opit_0_inv_srl/D",
      "slack_ns": 4.639,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[52]/opit_0_inv_srl/D",
      "slack_ns": 4.651,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[12]/opit_0_inv_srl/D",
      "slack_ns": 4.661,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[16]/opit_0_inv_srl/D",
      "slack_ns": 4.666,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.669,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[44]/opit_0_inv_srl/D",
      "slack_ns": 4.673,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[8]/opit_0_inv_srl/D",
      "slack_ns": 4.681,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[19]/opit_0_inv_srl/D",
      "slack_ns": 4.687,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[37]/opit_0_inv_srl/D",
      "slack_ns": 4.687,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[39]/opit_0_inv_srl/D",
      "slack_ns": 4.693,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[16]/opit_0_inv_srl/D",
      "slack_ns": 4.696,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[42]/opit_0_inv_srl/D",
      "slack_ns": 4.702,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[45]/opit_0_inv_srl/D",
      "slack_ns": 4.707,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[17]/opit_0_inv_srl/D",
      "slack_ns": 4.715,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[31]/opit_0_inv_srl/D",
      "slack_ns": 4.715,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[45]/opit_0_inv_srl/D",
      "slack_ns": 4.721,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[14]/opit_0_inv_srl/D",
      "slack_ns": 4.728,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[62]/opit_0_inv_srl/D",
      "slack_ns": 4.728,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.728,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[35]/opit_0_inv_srl/D",
      "slack_ns": 4.736,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[33]/opit_0_inv_srl/D",
      "slack_ns": 4.738,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[42]/opit_0_inv_srl/D",
      "slack_ns": 4.739,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[31]/opit_0_inv_srl/D",
      "slack_ns": 4.741,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[10]/opit_0_inv_srl/D",
      "slack_ns": 4.742,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[11]/opit_0_inv_srl/D",
      "slack_ns": 4.745,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[30]/opit_0_inv_srl/D",
      "slack_ns": 4.748,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[55]/opit_0_inv_srl/D",
      "slack_ns": 4.748,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[22]/opit_0_inv_srl/D",
      "slack_ns": 4.748,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.754,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[58]/opit_0_inv_srl/D",
      "slack_ns": 4.757,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[16]/opit_0_inv_srl/D",
      "slack_ns": 4.762,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[37]/opit_0_inv_srl/D",
      "slack_ns": 4.763,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[58]/opit_0_inv_srl/D",
      "slack_ns": 4.767,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[51]/opit_0_inv_srl/D",
      "slack_ns": 4.771,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[51]/opit_0_inv_srl/D",
      "slack_ns": 4.771,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[48]/opit_0_inv_srl/D",
      "slack_ns": 4.775,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[27]/opit_0_inv_srl/D",
      "slack_ns": 4.777,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[54]/opit_0_inv_srl/D",
      "slack_ns": 4.783,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[56]/opit_0_inv_srl/D",
      "slack_ns": 4.79,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[28]/opit_0_inv_srl/D",
      "slack_ns": 4.796,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[60]/opit_0_inv_srl/D",
      "slack_ns": 4.798,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[22]/opit_0_inv_srl/D",
      "slack_ns": 4.8,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[41]/opit_0_inv_srl/D",
      "slack_ns": 4.803,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[17]/opit_0_inv_srl/D",
      "slack_ns": 4.804,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[32]/opit_0_inv_srl/D",
      "slack_ns": 4.804,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[18]/opit_0_inv_srl/D",
      "slack_ns": 4.804,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[38]/opit_0_inv_srl/D",
      "slack_ns": 4.806,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[0]/opit_0_inv_srl/D",
      "slack_ns": 4.807,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[52]/opit_0_inv_srl/D",
      "slack_ns": 4.81,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[14]/opit_0_inv_srl/D",
      "slack_ns": 4.811,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[27]/opit_0_inv_srl/D",
      "slack_ns": 4.814,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[21]/opit_0_inv_srl/D",
      "slack_ns": 4.815,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[56]/opit_0_inv_srl/D",
      "slack_ns": 4.815,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[50]/opit_0_inv_srl/D",
      "slack_ns": 4.815,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[48]/opit_0_inv_srl/D",
      "slack_ns": 4.815,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[24]/opit_0_inv_srl/D",
      "slack_ns": 4.816,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[50]/opit_0_inv_srl/D",
      "slack_ns": 4.818,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[0]/opit_0_inv_srl/D",
      "slack_ns": 4.821,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[15]/opit_0_inv_srl/D",
      "slack_ns": 4.821,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[57]/opit_0_inv_srl/D",
      "slack_ns": 4.823,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/u_ddrphy_cpd/cpd_inst/CLK_PHY",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/u_ips2l_ddrphy_cpd_lock/ddrphy_cpd_up_dnb_d[0]/opit_0_inv_srl/D",
      "slack_ns": 4.878,
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
  "negative_ddr_endpoint_groups": {},
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
  "bitstream_sha256": "47387250ae7cd85bfbadec325d0a60e07a8732d0bf8ae8f26595ef1b4755b025"
}
```

源码、哈希与完整报告在 build/ddr_wns_20261031/ddr04_running_addresses_stats_20261101_133951/。没有编写或运行 testbench、RTL 仿真或烧录；时序结论不代替板上正确性和吞吐验证。
