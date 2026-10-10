#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
package="$tmp_dir/demo.npu"
model_hex="$tmp_dir/demo.hex"
python3 scripts/npu_model.py build-demo --output "$package" >/dev/null
od -An -v -t x1 "$package" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$model_hex"

cases=(valid bad_magic bad_crc bad_version bad_descriptor unknown_op bad_shape weight_section bad_rresp bad_rid bad_rlast)
for case_name in "${cases[@]}"; do
    echo "NPU CNN TEST: $case_name"
    SIM_ARGS="+MODEL_HEX=$model_hex +CASE=$case_name" \
        SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
        SIM_JOBS="${SIM_JOBS:-2}" \
        SIMULATOR="${SIMULATOR:-verilator}" \
        bash scripts/run_testbench.sh tb_npu_cnn_engine
done

echo "NPU_CNN_TEST_PASS cases=${#cases[@]} simulator=${SIMULATOR:-verilator}"
