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
if [[ -n "${MODEL_PACKAGE:-}" ]]; then
    package="$MODEL_PACKAGE"
    strict_zero_output=0
else
    python3 scripts/npu_model.py build-demo-32 --output "$package" >/dev/null
    strict_zero_output=1
fi
python3 scripts/npu_model.py check "$package" >/dev/null
model_bytes=$(wc -c < "$package" | tr -d ' ')
model_class_count=$(od -An -j22 -N1 -tu1 "$package" | tr -d ' ')
head -c 4096 /dev/zero > "$input1_bin"
cp "$input1_bin" "$input2_bin"
od -An -v -t x1 "$package" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$model_hex"
od -An -v -t x1 "$input1_bin" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$input1_hex"
od -An -v -t x1 "$input2_bin" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$input2_hex"
SIM_ARGS="+MODEL_HEX=$model_hex +MODEL_BYTES=$model_bytes +MODEL_CLASS_COUNT=$model_class_count +STRICT_ZERO_OUTPUT=$strict_zero_output +INPUT1_HEX=$input1_hex +INPUT2_HEX=$input2_hex" \
    SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
    SIM_JOBS="${SIM_JOBS:-2}" \
    SIMULATOR="${SIMULATOR:-verilator}" \
    bash scripts/run_testbench.sh tb_npu_cnn_service
echo "NPU_CNN_SERVICE_TEST_PASS simulator=${SIMULATOR:-verilator}"
