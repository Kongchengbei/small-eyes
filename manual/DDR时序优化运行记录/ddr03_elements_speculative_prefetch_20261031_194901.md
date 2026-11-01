# DDR 时序优化运行记录：ddr03_elements_speculative_prefetch_20261031_194901

配置：Full DDR，CPU 70 MHz，DDR core 125 MHz，第二屏幕 PDS GUI。NPU 校验及 INT8 缓冲修改由 Luna high 编写、主代理审查。保持模型协议与频率；时钟组是否变化及有效两拍路径核验见 JSON。

```json
{
  "name": "ddr03_elements_speculative_prefetch_20261031_194901",
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
  "constraint_candidate_only": false,
  "constraint_change_kind": "vendor_ip_independent_single_groups",
  "setup_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 45.693,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 588
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 3.347,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 737
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 2.518,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 712
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.553,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22365
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": -0.78,
      "tns_ns": -40.969,
      "failing_endpoints": 194,
      "total_endpoints": 113425
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 4.161,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 4.89,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 4.779,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 2.014,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 2.047,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_setup_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.553,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22365
  },
  "ddr_setup_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": -0.78,
    "tns_ns": -40.969,
    "failing_endpoints": 194,
    "total_endpoints": 113425
  },
  "setup_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 47.487,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 588
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 6.104,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 737
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 5.6,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 712
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 6.096,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22365
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 2.682,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113425
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 5.638,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 5.991,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.136,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 4.354,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 4.24,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_setup_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 6.096,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22365
  },
  "ddr_setup_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 2.682,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113425
  },
  "hold_slow": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.208,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 588
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.236,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 737
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.161,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 712
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.145,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22365
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.103,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113425
    },
    {
      "launch": "phy_dq_sysclk_1",
      "capture": "ddr_core_clk",
      "wns_ns": 0.343,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 260
    },
    {
      "launch": "phy_dq_sysclk_0",
      "capture": "ddr_core_clk",
      "wns_ns": 0.853,
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
      "wns_ns": 0.253,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.275,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 420
    }
  ],
  "cpu_hold_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.145,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 22365
  },
  "ddr_hold_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.103,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113425
  },
  "hold_fast": [
    {
      "launch": "JTAG_CLK",
      "capture": "JTAG_CLK",
      "wns_ns": 0.2,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 588
    },
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.152,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 737
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.112,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 712
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.102,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 22365
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 113425
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
      "wns_ns": 0.38,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 1
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.158,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 438
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_0",
      "wns_ns": 0.1,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 196
    },
    {
      "launch": "ddr_core_clk",
      "capture": "phy_dq_sysclk_1",
      "wns_ns": 0.106,
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
    "total_endpoints": 22365
  },
  "ddr_hold_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.1,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 113425
  },
  "recovery_slow": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 5.183,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 5.831,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 5.849,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2794
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 3.115,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7901
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 5.616,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_recovery_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 5.849,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2794
  },
  "ddr_recovery_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 3.115,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7901
  },
  "recovery_fast": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 7.012,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 7.423,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 9.078,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2794
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 4.931,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7901
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 6.512,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_recovery_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 9.078,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2794
  },
  "ddr_recovery_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 4.931,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7901
  },
  "removal_slow": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 1.203,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.466,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.457,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2794
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.385,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7901
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.416,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_removal_slow": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.457,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2794
  },
  "ddr_removal_slow": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.385,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7901
  },
  "removal_fast": [
    {
      "launch": "CAM1_PCLK",
      "capture": "CAM1_PCLK",
      "wns_ns": 0.808,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "CAM2_PCLK",
      "capture": "CAM2_PCLK",
      "wns_ns": 0.313,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 192
    },
    {
      "launch": "cpu_clk",
      "capture": "cpu_clk",
      "wns_ns": 0.305,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 2794
    },
    {
      "launch": "ddr_core_clk",
      "capture": "ddr_core_clk",
      "wns_ns": 0.261,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 7901
    },
    {
      "launch": "ddr_rst_clk",
      "capture": "ddr_rst_clk",
      "wns_ns": 0.278,
      "tns_ns": 0.0,
      "failing_endpoints": 0,
      "total_endpoints": 101
    }
  ],
  "cpu_removal_fast": {
    "launch": "cpu_clk",
    "capture": "cpu_clk",
    "wns_ns": 0.305,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 2794
  },
  "ddr_removal_fast": {
    "launch": "ddr_core_clk",
    "capture": "ddr_core_clk",
    "wns_ns": 0.261,
    "tns_ns": 0.0,
    "failing_endpoints": 0,
    "total_endpoints": 7901
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
    "module_LUT": 44791,
    "FF": 47938,
    "Distributed_RAM": 1151,
    "APM": 69,
    "DRM": 35
  },
  "cpu_resources": {
    "module_LUT": 5284,
    "FF": 3685,
    "Distributed_RAM": 45,
    "APM": 4,
    "DRM": 10
  },
  "worst_cpu_paths": [
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/btb_train_taken_q/opit_0_L6Q_perm/I4",
      "slack_ns": 0.553,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L7Q_perm/M",
      "slack_ns": 0.564,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/redirect_taken_q/opit_0_L6Q_perm/I5",
      "slack_ns": 0.57,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[31]/opit_0_AQ_perm/CE",
      "slack_ns": 0.65,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[25]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.718,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[31]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.718,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[28]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.745,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[3]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.752,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[11]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.752,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[14]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.758,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[21]/opit_0_AQ_perm/CE",
      "slack_ns": 0.762,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[10]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.763,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[27]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.763,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[19]/opit_0_AQ_perm/CE",
      "slack_ns": 0.776,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_div_done/opit_0_L5Q_perm/RS",
      "slack_ns": 0.779,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_div_started/opit_0_L6Q_LUT6DQL5_perm/RS",
      "slack_ns": 0.779,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_mul_done/opit_0_L5Q_perm/RS",
      "slack_ns": 0.779,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[25]/opit_0_AQ_perm/CE",
      "slack_ns": 0.807,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[23]/opit_0_AQ_perm/CE",
      "slack_ns": 0.813,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[11]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.814,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[12]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.814,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[27]/opit_0_AQ_perm/CE",
      "slack_ns": 0.818,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[27]/opit_0_AQ_perm/CE",
      "slack_ns": 0.827,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[9]/opit_0_AQ_perm/CE",
      "slack_ns": 0.831,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[17]/opit_0_AQ_perm/CE",
      "slack_ns": 0.836,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/icache_cancel_q/opit_0_L7Q_perm/B0",
      "slack_ns": 0.839,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[7]/opit_0_AQ_perm/CE",
      "slack_ns": 0.844,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[20]/opit_0_L6Q_perm/I2",
      "slack_ns": 0.85,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[8]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.855,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[9]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.855,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[15]/opit_0_AQ_perm/CE",
      "slack_ns": 0.855,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[3]/opit_0_AQ_perm/CE",
      "slack_ns": 0.86,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[8]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.862,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[29]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.862,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[30]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.862,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[15]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.868,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[19]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.868,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[29]/opit_0_L6Q_perm/I5",
      "slack_ns": 0.874,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[8]/opit_0_L6Q_perm/I5",
      "slack_ns": 0.877,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[10]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.884,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[16]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.884,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[19]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.886,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[22]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.886,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[23]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.887,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[26]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.891,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[13]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.894,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[15]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.894,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[18]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.902,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[2]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.904,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[4]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.904,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[5]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.904,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[22]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.904,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[31]/opit_0_AQ_perm/CE",
      "slack_ns": 0.91,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[16]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.913,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[24]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.913,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[18]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.93,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/gen_icache.u_icache/hold_pc[28]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.93,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[30]/opit_0_L6Q_perm/I3",
      "slack_ns": 0.933,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[23]/opit_0_AQ_perm/CE",
      "slack_ns": 0.934,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[7]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.936,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src2[12]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.936,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/u_csr/csr_mtime[19]/opit_0_AQ_perm/CE",
      "slack_ns": 0.937,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_idu/id_predict_next_pc[29]/opit_0_AQ_perm/CE",
      "slack_ns": 0.942,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_cpu/gen_dcache.u_dcache/tagv_ram_way[0].u/u_ram/U_ipml_spram_TagvRAM/ADDR_LOOP[0].DATA_LOOP[0].U_GTP_DRM18K/gopdrm_18k_inv/CLKB",
      "endpoint": "g_ddr_profile.u_cpu/u_exu/ex_src1[20]/opit_0_L6Q_perm/CE",
      "slack_ns": 0.952,
      "type": "max (slow corner)"
    }
  ],
  "worst_ddr_paths": [
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_upper/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.78,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[31]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.612,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[28]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.611,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[30]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.611,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_lower/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.598,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[26]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.593,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[20]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.569,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[12]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.567,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.564,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[8]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.562,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_lower/gopdrm_36k/ADB_CAS",
      "slack_ns": -0.554,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[16]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.548,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_2_upper/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.545,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[18]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.537,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[14]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.528,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[4]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.527,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.517,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_out_elements[1]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/out_x[3]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.511,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[6]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.504,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.492,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_upper/gopdrm_36k/ADB_CAS",
      "slack_ns": -0.48,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.48,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/gap_position[1]/opit_0_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_3/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.479,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[24]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.467,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[2]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.455,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[0]/opit_0_inv_L6Q_perm/CE",
      "slack_ns": -0.453,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.452,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.443,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[22]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.434,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_1_upper/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.429,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_3_lower/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.421,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.412,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_5_upper/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.41,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[1].u_lane/bad_release_count[10]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.399,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.382,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/bad_release_count[4]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.378,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_3_lower/gopdrm_36k/ADB_CAS",
      "slack_ns": -0.371,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/bad_release_count[10]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.369,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/bad_release_count[2]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.358,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_out_elements[1]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/out_x[1]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.357,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[9]",
      "slack_ns": -0.355,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_2_upper/gopdrm_36k/ADB_CAS",
      "slack_ns": -0.354,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/bad_release_count[18]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.35,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_out_elements[1]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/out_x[11]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.338,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/rel_v/opit_0_inv_L6QL5Q1_perm/CLK",
      "endpoint": "g_ddr_profile.u_rgb565_int8/lane[0].u_lane/bad_release_count[20]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.336,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.335,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_out_elements[1]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/out_x[7]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.332,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/layer_out_elements[1]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/out_x[9]/opit_0_inv_AQ_perm/CE",
      "slack_ns": -0.319,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/ADB0[9]",
      "slack_ns": -0.319,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_3_upper/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.317,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[8]",
      "slack_ns": -0.313,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_2/gopdrm_36k/CLKB[0]",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/N9712.lt_29/gateop_perm/CIN",
      "slack_ns": -0.294,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_5_upper/gopdrm_36k/ADB_CAS",
      "slack_ns": -0.294,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_upper/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.29,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_0/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.288,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_7_lower/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.273,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_1_lower/gopdrm_36k/ADB0[14]",
      "slack_ns": -0.27,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_0/gopdrm_36k/ADB0[8]",
      "slack_ns": -0.27,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[10]",
      "slack_ns": -0.266,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_lower/gopdrm_36k/ADB0[13]",
      "slack_ns": -0.263,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_b_2/gopdrm_36k/ADB0[7]",
      "slack_ns": -0.262,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_4_upper/gopdrm_36k/ADB0[11]",
      "slack_ns": -0.259,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/fc_output[7]/opit_0_inv_AQ_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/model_mem_1_upper/gopdrm_36k/ADB_CAS",
      "slack_ns": -0.255,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/conv_ic_reg[5]/opit_0_inv_L6QL5Q_perm/CLK",
      "endpoint": "g_ddr_profile.u_npu_system/g_image_service.u_service/u_engine/tensor_a_0/gopdrm_36k/ADB0[9]",
      "slack_ns": -0.252,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[56]/opit_0_inv_srl/D",
      "slack_ns": 4.161,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[6]/opit_0_inv_srl/D",
      "slack_ns": 4.405,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[60]/opit_0_inv_srl/D",
      "slack_ns": 4.477,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[37]/opit_0_inv_srl/D",
      "slack_ns": 4.549,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[61]/opit_0_inv_srl/D",
      "slack_ns": 4.579,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[33]/opit_0_inv_srl/D",
      "slack_ns": 4.617,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[33]/opit_0_inv_srl/D",
      "slack_ns": 4.623,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[9]/opit_0_inv_srl/D",
      "slack_ns": 4.63,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[12]/opit_0_inv_srl/D",
      "slack_ns": 4.631,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[13]/opit_0_inv_srl/D",
      "slack_ns": 4.645,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[37]/opit_0_inv_srl/D",
      "slack_ns": 4.649,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[29]/opit_0_inv_srl/D",
      "slack_ns": 4.656,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[19]/opit_0_inv_srl/D",
      "slack_ns": 4.673,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[53]/opit_0_inv_srl/D",
      "slack_ns": 4.675,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[62]/opit_0_inv_srl/D",
      "slack_ns": 4.679,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[24]/opit_0_inv_srl/D",
      "slack_ns": 4.688,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[12]/opit_0_inv_srl/D",
      "slack_ns": 4.689,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[54]/opit_0_inv_srl/D",
      "slack_ns": 4.693,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[46]/opit_0_inv_srl/D",
      "slack_ns": 4.696,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[36]/opit_0_inv_srl/D",
      "slack_ns": 4.696,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[17]/opit_0_inv_srl/D",
      "slack_ns": 4.697,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[18]/opit_0_inv_srl/D",
      "slack_ns": 4.7,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[40]/opit_0_inv_srl/D",
      "slack_ns": 4.7,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[56]/opit_0_inv_srl/D",
      "slack_ns": 4.716,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[3]/opit_0_inv_srl/D",
      "slack_ns": 4.72,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[4]/opit_0_inv_srl/D",
      "slack_ns": 4.724,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[19]/opit_0_inv_srl/D",
      "slack_ns": 4.724,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[28]/opit_0_inv_srl/D",
      "slack_ns": 4.73,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[7]/opit_0_inv_srl/D",
      "slack_ns": 4.731,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[25]/opit_0_inv_srl/D",
      "slack_ns": 4.733,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[59]/opit_0_inv_srl/D",
      "slack_ns": 4.738,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[7]/opit_0_inv_srl/D",
      "slack_ns": 4.742,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[62]/opit_0_inv_srl/D",
      "slack_ns": 4.745,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[0]/opit_0_inv_srl/D",
      "slack_ns": 4.756,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[10]/opit_0_inv_srl/D",
      "slack_ns": 4.757,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/DDC.u_ddc_dq/ddc_inst_PHY/CLKB",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rdvalid_r1/opit_0_inv_srl/D",
      "slack_ns": 4.757,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[51]/opit_0_inv_srl/D",
      "slack_ns": 4.758,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[30]/opit_0_inv_srl/D",
      "slack_ns": 4.759,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[28]/opit_0_inv_srl/D",
      "slack_ns": 4.76,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[50]/opit_0_inv_srl/D",
      "slack_ns": 4.768,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[6].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[51]/opit_0_inv_srl/D",
      "slack_ns": 4.77,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[27]/opit_0_inv_srl/D",
      "slack_ns": 4.77,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[21]/opit_0_inv_srl/D",
      "slack_ns": 4.772,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[10]/opit_0_inv_srl/D",
      "slack_ns": 4.774,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[9]/opit_0_inv_srl/D",
      "slack_ns": 4.775,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[30]/opit_0_inv_srl/D",
      "slack_ns": 4.777,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[11]/opit_0_inv_srl/D",
      "slack_ns": 4.779,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[59]/opit_0_inv_srl/D",
      "slack_ns": 4.787,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[46]/opit_0_inv_srl/D",
      "slack_ns": 4.787,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[31]/opit_0_inv_srl/D",
      "slack_ns": 4.79,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[57]/opit_0_inv_srl/D",
      "slack_ns": 4.79,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[0].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[2]/opit_0_inv_srl/D",
      "slack_ns": 4.79,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[4].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[39]/opit_0_inv_srl/D",
      "slack_ns": 4.79,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[0].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[58]/opit_0_inv_srl/D",
      "slack_ns": 4.791,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[63]/opit_0_inv_srl/D",
      "slack_ns": 4.791,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[17]/opit_0_inv_srl/D",
      "slack_ns": 4.791,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[7].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[63]/opit_0_inv_srl/D",
      "slack_ns": 4.791,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[11]/opit_0_inv_srl/D",
      "slack_ns": 4.794,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[27]/opit_0_inv_srl/D",
      "slack_ns": 4.795,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[5].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[45]/opit_0_inv_srl/D",
      "slack_ns": 4.796,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/dq_loop[1].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[2].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[8]/opit_0_inv_srl/D",
      "slack_ns": 4.798,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[1].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[19]/opit_0_inv_srl/D",
      "slack_ns": 4.8,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[2].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[18]/opit_0_inv_srl/D",
      "slack_ns": 4.8,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/dq_loop[3].u_iobuf_dq/opit_1/ICLKDIV",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/ddrphy_slice_top/i_dqs_group[3].ddrphy_data_slice/ddrphy_dqs_rddata_align/rddata_r1[31]/opit_0_inv_srl/D",
      "slack_ns": 4.8,
      "type": "max (slow corner)"
    },
    {
      "startpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/u_ddrphy_cpd/cpd_inst/CLK_PHY",
      "endpoint": "g_ddr_profile.u_ddr3_ctrl/u_ddrphy_top/u_ips2l_ddrphy_cpd_lock/ddrphy_cpd_up_dnb_d[0]/opit_0_inv_srl/D",
      "slack_ns": 4.89,
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
    "NPU": 42,
    "INT8_buffer": 22
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
  "bitstream_sha256": "dc307aac7dbee435aa2f05009b7e069945beef918b92da17166ac658fcc2ea8a"
}
```

源码、哈希与完整报告在 build/ddr_wns_20261031/ddr03_elements_speculative_prefetch_20261031_194901/。没有编写或运行 testbench、RTL 仿真或烧录；时序结论不代替板上正确性和吞吐验证。
