#!/usr/bin/env bash
# v0.3 路标模型（11 类）在 Hnpu_cnn_engine 上的全量核对：用 scripts/npu_model.py build-road 从模型包生成 model.npu，
# 跑包里全部 101 个金样框，类别、margin、拒识逐个与 golden_output.csv 比；32×32 直接输入、96×96 隔 3 取 1 各跑一遍。
# 用法（仓库根目录）：bash temp/tests/run_npu_road_model_v03_test.sh [模型包目录]
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
golden_dir="${1:-temp/路标模型包v0.3_10月9日}"
rois_dir="$golden_dir/golden_input/rois"
golden_csv="$golden_dir/golden_output.csv"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

hexdump_bytes() { od -An -v -t x1 "$1" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$2"; }

python3 scripts/npu_model.py build-road --source "$golden_dir" --output "$tmp_dir/road.npu" >/dev/null
python3 scripts/npu_model.py check "$tmp_dir/road.npu" >/dev/null
[[ "$(wc -c < "$tmp_dir/road.npu" | tr -d ' ')" -eq 62720 ]] || { echo "model.npu 应为 62720 字节" >&2; exit 1; }
hexdump_bytes "$tmp_dir/road.npu" "$tmp_dir/model.hex"

roi_count=$(($(wc -l < "$golden_csv") - 1))
[[ "$roi_count" -eq 101 ]] || { echo "golden_output.csv 应有 101 个框，实际 $roi_count" >&2; exit 1; }
: > "$tmp_dir/in32.bin"; : > "$tmp_dir/in96.bin"
while IFS=, read -r frame roi rest; do
    [[ "$frame" == frame ]] && continue
    cat "$rois_dir/${frame}_roi${roi}.bin" >> "$tmp_dir/in32.bin"
    cat "$rois_dir/${frame}_roi${roi}_96_int8.bin" >> "$tmp_dir/in96.bin"
done < "$golden_csv"
[[ "$(wc -c < "$tmp_dir/in32.bin" | tr -d ' ')" -eq $((roi_count * 4096)) &&
   "$(wc -c < "$tmp_dir/in96.bin" | tr -d ' ')" -eq $((roi_count * 36864)) ]] || { echo "输入拼接长度不对" >&2; exit 1; }
hexdump_bytes "$tmp_dir/in32.bin" "$tmp_dir/in32.hex"
hexdump_bytes "$tmp_dir/in96.bin" "$tmp_dir/in96.hex"
awk -F, 'NR > 1 {print $3, $4, $5}' "$golden_csv" > "$tmp_dir/expected.txt"

for mode in 32 96; do
    defs=""; [[ "$mode" == 96 ]] && defs="-DDS3"
    obj="$tmp_dir/obj$mode"
    CCACHE_DISABLE=1 verilator --binary --timing --assert --language 1800-2012 -Wno-fatal -Wno-BLKLOOPINIT $defs \
        --top-module tb_npu_road_model_v03 -j "${SIM_JOBS:-2}" --Mdir "$obj" -o simulator \
        soc/Hnpu_cnn_engine.v temp/tests/tb_npu_road_model_v03.sv > "$tmp_dir/build$mode.log" 2>&1 ||
        { tail -30 "$tmp_dir/build$mode.log" >&2; exit 1; }
    "$obj/simulator" +MODEL_HEX="$tmp_dir/model.hex" +INPUTS_HEX="$tmp_dir/in$mode.hex" \
        +EXPECTED_FILE="$tmp_dir/expected.txt" > "$tmp_dir/run$mode.log" 2>&1 || { tail -5 "$tmp_dir/run$mode.log" >&2; exit 1; }
    grep -q "NPU_ROAD_V03_PASS" "$tmp_dir/run$mode.log" || { tail -5 "$tmp_dir/run$mode.log" >&2; exit 1; }
    echo "${mode}×${mode} 输入：$(grep NPU_ROAD_V03_PASS "$tmp_dir/run$mode.log")"
done
echo "NPU_ROAD_MODEL_V03_TEST_PASS cases=$roi_count"
