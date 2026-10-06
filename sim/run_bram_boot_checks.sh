#!/usr/bin/env bash
set -euo pipefail
export CCACHE_DISABLE="${CCACHE_DISABLE:-1}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

verilator_bin="${VERILATOR:-verilator}"

cpu_rtl=(
    cpu/Btb.v cpu/HRegFile.v cpu/Halu.v cpu/Hcsr.v cpu/Hexu.v cpu/Hidu.v
    cpu/Hifu.v cpu/Hmemu.v cpu/Htop.v cpu/Hwbu.v cpu/axi_bridge.v
    cpu/cache_util.v cpu/cpu_bram_mem.v cpu/cpu_bram_ip_mem.v
    cpu/dcache.v cpu/div.v cpu/icache.v cpu/mul.v
)
jtag_rtl=(sim/stubs/jtag_lint_waiver.v)
soc_rtl=(
    soc/Hfpga_soc.v soc/Hfpga_soc_bram_profile.v soc/Debug_core.v soc/Hled.v
    soc/Hfpioa_simple.v soc/Hnpu_ctrl.v soc/axi_mem_backend.v soc/Huart_tx.v
    soc/Hcamera_sccb_gpio.v soc/Hcamera_dvp_rx.v soc/Hcamera_dvp_regs.v
    soc/Hcamera_async_fifo.v soc/Hcamera_dma.v soc/Hcamera_subsystem.v
    soc/Haxi_2m1s_arbiter.v soc/Hpreprocess_color.v soc/Hpreprocess_regions.v
    soc/Hcamera_preprocess.v soc/Hpreprocess_stereo.v soc/ddr_axi_bridge.v
    soc/flash_boot/spi_flash_byte_reader.v soc/flash_boot/flash_ddr_loader.v
    soc/flash_boot/flash_ddr_boot.v soc/flash_boot/flash_bram_boot.v
    sim/board_ip_lint_stubs.v
)

"$verilator_bin" --binary --timing --language 1800-2012 -I. -Isoc \
    --Wno-WIDTHTRUNC --Wno-BLKLOOPINIT \
    --top-module tb_flash_bram_boot --Mdir "$tmp_dir/boot_obj" \
    cpu/cpu_bram_mem.v \
    soc/flash_boot/spi_flash_byte_reader.v \
    soc/flash_boot/flash_bram_boot.v sim/tb_flash_bram_boot.sv
"$tmp_dir/boot_obj/Vtb_flash_bram_boot"

# The board-level BRAM profile now starts directly from vendor RAM INIT
# parameters. Keep the standalone Flash-loader transfer check above as legacy
# loader coverage; test production BRAM execution with the actual IP model and
# the physical UART pin receiver instead of the old Flash-boot profile bench.
SIMULATOR=verilator SIM_TIMEOUT=30 make tb_cpu_bram_ip_memrun
SIMULATOR=verilator SIM_TIMEOUT=90 make tb_coremark_bram_ip_uartrun

# The DDR profile remains a distinct configuration and retains its two
# elaboration diagnostics. Direct vendor-BRAM elaboration/runtime coverage is
# provided by the two production tests above.
for preprocess in 0 1; do
    "$verilator_bin" --lint-only --timing --language 1800-2012 -I. -Isoc \
        --Wno-WIDTHTRUNC --Wno-BLKLOOPINIT --Wno-CASEINCOMPLETE --Wno-UNDRIVEN \
        --top-module Hfpga_soc -GCPU_MEM_BRAM=0 -GPREPROCESS_ENABLE="$preprocess" \
        "${cpu_rtl[@]}" cpu/cache_sram_beh.v "${jtag_rtl[@]}" "${soc_rtl[@]}"
done

echo "PASS: legacy Flash loader unit, production vendor-BRAM memory/UART tests, and DDR profile elaborations"
