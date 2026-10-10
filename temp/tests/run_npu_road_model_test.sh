#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

golden_dir="temp/路标模型包与前处理金样v0.1"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

package="$tmp_dir/road.npu"
model_hex="$tmp_dir/road.hex"
python3 scripts/npu_model.py build-road \
    --source "$golden_dir" --output "$package" >/dev/null
python3 scripts/npu_model.py check "$package" >/dev/null
od -An -v -t x1 "$package" |
    awk '{for (i = 1; i <= NF; i++) print $i}' > "$model_hex"

run_case() {
    local case_name="$1"
    local input_bin="$2"
    local expected_class="$3"
    local expected_score="$4"
    local expected_conf="$5"
    local expected_reject="$6"
    local input_hex="$tmp_dir/${case_name}.hex"

    od -An -v -t x1 "$input_bin" |
        awk '{for (i = 1; i <= NF; i++) print $i}' > "$input_hex"
    echo "NPU ROAD MODEL TEST: $case_name"
    SIM_ARGS="+MODEL_HEX=$model_hex +INPUT_HEX=$input_hex \
+MODEL_BYTES=$(stat -c '%s' "$package") +INPUT_BYTES=$(stat -c '%s' "$input_bin") \
+EXPECTED_CLASS=$expected_class +EXPECTED_SCORE=$expected_score \
+EXPECTED_CONF=$expected_conf +EXPECTED_REJECT=$expected_reject +CASE=$case_name" \
        SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
        SIM_JOBS="${SIM_JOBS:-2}" \
        SIMULATOR="${SIMULATOR:-verilator}" \
        bash scripts/run_testbench.sh tb_npu_road_model
}

run_case accept \
    "$golden_dir/golden_input/rois/frame_000005_roi0.bin" \
    4 4067 4683 0
run_case reject \
    "$golden_dir/golden_input/rois/frame_000006_roi0.bin" \
    0 1336 2620 1

echo "NPU_ROAD_MODEL_TEST_PASS cases=2 simulator=${SIMULATOR:-verilator}"
