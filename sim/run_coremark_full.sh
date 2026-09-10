#!/usr/bin/env bash
set -euo pipefail

# Simulation-only: this does not modify the PDS project or generated IP.
sim_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$sim_dir"

iverilog -g2012 -I ../source/soc -s tb_coremark_full -o tb_coremark_full.vvp \
  tb_coremark_sim_stubs.v ../source/soc/config.v \
  ../source/soc/defines.v ../source/soc/fpga_unified_memory.v \
  ../source/soc/ddr_axi_bridge.v \
  ../source/soc/Hfpga_soc.v ../source/soc/Debug_core.v \
  ../source/soc/Hfpioa_simple.v ../source/soc/Hled.v \
  ../source/soc/Huart_tx.v ../source/cpu/Htop.v \
  ../source/cpu/Halu.v ../source/cpu/Hexu.v ../source/cpu/Hidu.v \
  ../source/cpu/Hifu.v ../source/cpu/Hmemu.v ../source/cpu/HRegFile.v \
  ../source/cpu/Hwbu.v ../source/cpu/Hcsr.v ../source/cpu/Btb.v \
  ../source/cpu/mul.v ../source/cpu/div.v \
  ../source/jtag/full_handshake_rx.v ../source/jtag/full_handshake_tx.v \
  ../source/jtag/jtag_dm.v ../source/jtag/jtag_driver.v \
  ../source/jtag/jtag_top.v tb_coremark_full.sv

# Example: ./run_coremark_full.sh +MAX_CYCLES=200000
vvp -n ./tb_coremark_full.vvp "$@"
