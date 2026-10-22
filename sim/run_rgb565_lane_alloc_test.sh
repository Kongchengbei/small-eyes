#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

verilator --binary --timing --language 1800-2012 \
    -I"$repo_root" -I"$repo_root/soc" --Wno-fatal \
    --top-module tb_rgb565_lane_alloc --Mdir "$tmp_dir/obj" \
    "$repo_root/soc/Hrgb565_int8_lane.v" \
    "$repo_root/sim/tb_rgb565_lane_alloc.sv" >"$tmp_dir/build.log" 2>&1 || {
        cat "$tmp_dir/build.log" >&2
        exit 1
    }
"$tmp_dir/obj/Vtb_rgb565_lane_alloc"
