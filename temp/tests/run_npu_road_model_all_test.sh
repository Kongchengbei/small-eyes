#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

golden_dir="temp/路标模型包与前处理金样v0.1"
rois_dir="$golden_dir/golden_input/rois"
golden_csv="$golden_dir/golden_output.csv"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
package="$tmp_dir/road.npu"
model_hex="$tmp_dir/road.hex"
inputs_bin="$tmp_dir/inputs.bin"
inputs_hex="$tmp_dir/inputs.hex"
expected_file="$tmp_dir/expected.txt"

roi_count=$(($(wc -l < "$golden_csv") - 1))
if [[ "$roi_count" -ne 33 ]]; then
    echo "expected 33 golden ROIs, found $roi_count" >&2
    exit 1
fi

python3 scripts/npu_model.py build-road --source "$golden_dir" --output "$package" >/dev/null
python3 scripts/npu_model.py check "$package" >/dev/null
od -An -v -t x1 "$package" |
    awk '{for (i = 1; i <= NF; i++) print $i}' > "$model_hex"

: > "$inputs_bin"
while IFS=, read -r frame roi class margin reject rest; do
    [[ "$frame" == frame ]] && continue
    cat "$rois_dir/${frame}_roi${roi}.bin" >> "$inputs_bin"
done < "$golden_csv"
if [[ "$(stat -c '%s' "$inputs_bin")" -ne $((33 * 4096)) ]]; then
    echo "golden input concatenation has unexpected size" >&2
    exit 1
fi
od -An -v -t x1 "$inputs_bin" |
    awk '{for (i = 1; i <= NF; i++) print $i}' > "$inputs_hex"
awk -F, 'NR > 1 {print $3, $4, $5}' "$golden_csv" > "$expected_file"

SIM_ARGS="+MODEL_HEX=$model_hex +INPUTS_HEX=$inputs_hex +EXPECTED_FILE=$expected_file" \
    SIM_TIMEOUT="${SIM_TIMEOUT:-600}" \
    SIM_JOBS="${SIM_JOBS:-2}" \
    SIMULATOR="${SIMULATOR:-verilator}" \
    bash scripts/run_testbench.sh tb_npu_road_model_all
echo "NPU_ROAD_MODEL_ALL_TEST_PASS cases=$roi_count simulator=${SIMULATOR:-verilator}"
