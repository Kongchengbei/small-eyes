#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
out_dir="$repo_root/build/sim/tb_flash_ddr_model_load"
rm -rf "$out_dir"
mkdir -p "$out_dir"

CCACHE_DISABLE=1 verilator --binary --timing --assert --language 1800-2012 -Wno-fatal \
    --top-module tb_flash_ddr_model_load --Mdir "$out_dir/obj" -o simulator \
    soc/flash_boot/flash_ddr_loader.v temp/tests/tb_flash_ddr_model_load.sv \
    >"$out_dir/build.log" 2>&1 || { tail -80 "$out_dir/build.log" >&2; exit 1; }
"$out_dir/obj/simulator" | tee "$out_dir/run.log"
grep -q 'FLASH_DDR_MODEL_LOAD_PASS' "$out_dir/run.log"
