#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
tmp_dir="$(mktemp -d /tmp/npu-cnn-96.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

python3 scripts/npu_model.py build-demo-96 --output "$tmp_dir/model.npu"
od -An -v -t x1 "$tmp_dir/model.npu" |
    awk '{for (i = 1; i <= NF; i++) print $i}' > "$tmp_dir/model.hex"

SIMULATOR="${SIMULATOR:-verilator}" \
SIM_JOBS="${SIM_JOBS:-2}" SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
SIM_ARGS="+MODEL_HEX=$tmp_dir/model.hex" \
bash scripts/run_testbench.sh tb_npu_cnn_96_cache
echo "NPU_CNN_96_CACHE_TEST_PASS simulator=${SIMULATOR:-verilator}"
