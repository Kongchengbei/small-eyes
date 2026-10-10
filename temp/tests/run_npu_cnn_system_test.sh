#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
package="$tmp_dir/demo.npu"
model_hex="$tmp_dir/demo.hex"
input1_bin="$tmp_dir/input1.bin"
input2_bin="$tmp_dir/input2.bin"
input1_hex="$tmp_dir/input1.hex"
input2_hex="$tmp_dir/input2.hex"

python3 scripts/npu_model.py build-demo-32 --output "$package" >/dev/null
python3 scripts/npu_model.py check "$package" >/dev/null
head -c 4096 /dev/zero > "$input1_bin"
cp "$input1_bin" "$input2_bin"
od -An -v -t x1 "$package" |
    awk '{for (i = 1; i <= NF; i++) print $i}' > "$model_hex"
od -An -v -t x1 "$input1_bin" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$input1_hex"
od -An -v -t x1 "$input2_bin" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$input2_hex"

SIM_ARGS="+MODEL_HEX=$model_hex +INPUT1_HEX=$input1_hex +INPUT2_HEX=$input2_hex" \
    SIM_TIMEOUT="${SIM_TIMEOUT:-180}" \
    SIM_JOBS="${SIM_JOBS:-2}" \
    SIMULATOR="${SIMULATOR:-verilator}" \
    bash scripts/run_testbench.sh tb_npu_cnn_system
echo "NPU_CNN_SYSTEM_TEST_PASS simulator=${SIMULATOR:-verilator}"
