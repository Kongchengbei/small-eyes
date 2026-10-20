#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

verilator_bin="${VERILATOR:-verilator}"
"$verilator_bin" --binary --timing --language 1800-2012 -I"$repo_root/soc" \
    --Wno-fatal --Wno-PINMISSING --top-module tb_rgb565_slot_select --Mdir "$tmp_dir/obj" \
    "$repo_root/soc/Hrgb565_int8_lane.v" \
    "$repo_root/sim/tb_rgb565_slot_select.sv"
"$tmp_dir/obj/Vtb_rgb565_slot_select"
