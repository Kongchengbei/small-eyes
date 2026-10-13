#!/usr/bin/env bash
set -euo pipefail

# Validate the delivered v0.3 model with the A-side CNN engine.  A complete
# model package may include golden_input/golden_output.csv; the checked-in
# delivery currently contains model.npu only, so 16 deterministic inputs
# (including INT8 extrema and colour patterns) are checked against the
# independent Python reference.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
model_dir="${1:-temp/路标模型文件v0.3_10月10日}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

hexdump_bytes() {
    od -An -v -t x1 "$1" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$2"
}

if [[ -f "$model_dir/model.npu" ]]; then
    cp "$model_dir/model.npu" "$tmp_dir/road.npu"
elif [[ -f "$model_dir/model.json" ]]; then
    python3 scripts/npu_model.py build-road --source "$model_dir" --output "$tmp_dir/road.npu" >/dev/null
else
    echo "模型目录必须包含 model.npu 或 model.json: $model_dir" >&2
    exit 1
fi
python3 scripts/npu_model.py check "$tmp_dir/road.npu" >/dev/null
model_bytes=$(wc -c < "$tmp_dir/road.npu" | tr -d ' ')
hexdump_bytes "$tmp_dir/road.npu" "$tmp_dir/model.hex"

if [[ -f "$model_dir/classes.csv" ]]; then
    python3 - "$model_dir/classes.csv" <<'PY'
import csv
import pathlib
import sys

rows = list(csv.DictReader(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8-sig").splitlines()))
ids = [int(row["index"]) for row in rows]
if ids != list(range(11)):
    raise SystemExit(f"classes.csv IDs must be 0..10, got {ids}")
print("NPU_CLASSES_CHECK_PASS count=11")
PY
fi

if [[ -f "$model_dir/golden_output.csv" ]]; then
    python3 temp/tests/npu_model_reference.py golden \
        --model "$tmp_dir/road.npu" --source "$model_dir" --output-dir "$tmp_dir/reference" >/dev/null
else
    python3 temp/tests/npu_model_reference.py smoke \
        --model "$tmp_dir/road.npu" --output-dir "$tmp_dir/reference" --cases 16 --layers >/dev/null
fi
cp "$tmp_dir/reference/inputs32.bin" "$tmp_dir/in32.bin"
cp "$tmp_dir/reference/inputs96.bin" "$tmp_dir/in96.bin"
roi_count=$(( $(wc -c < "$tmp_dir/in32.bin" | tr -d ' ') / 4096 ))
[[ "$roi_count" -gt 0 ]] || { echo "没有生成输入案例" >&2; exit 1; }
[[ "$(wc -c < "$tmp_dir/in96.bin" | tr -d ' ')" -eq $((roi_count * 36864)) ]] || {
    echo "96x96 输入长度不对" >&2
    exit 1
}
hexdump_bytes "$tmp_dir/in32.bin" "$tmp_dir/in32.hex"
hexdump_bytes "$tmp_dir/in96.bin" "$tmp_dir/in96.hex"
if [[ -f "$tmp_dir/reference/layers.bin" ]]; then
    hexdump_bytes "$tmp_dir/reference/layers.bin" "$tmp_dir/layers.hex"
    [[ "$(wc -c < "$tmp_dir/reference/layers.bin" | tr -d ' ')" -eq $((roi_count * 36972)) ]] || {
        echo "逐层参考长度不对" >&2
        exit 1
    }
fi
awk '{print $1, $2, $3, $4}' "$tmp_dir/reference/expected32.txt" > "$tmp_dir/expected.txt"

for mode in 32 96; do
    defs=()
    [[ "$mode" == 96 ]] && defs+=(-DDS3)
    obj="$tmp_dir/obj$mode"
    CCACHE_DISABLE=1 verilator --binary --timing --assert --language 1800-2012 \
        -Wno-fatal -Wno-BLKLOOPINIT "${defs[@]}" \
        --top-module tb_npu_road_model_v03 -j "${SIM_JOBS:-2}" \
        --Mdir "$obj" -o simulator \
        -GMODEL_BYTES="$model_bytes" -GROI_COUNT="$roi_count" \
        soc/Hnpu_quant.v soc/Hnpu_cnn_engine.v temp/tests/tb_npu_road_model_v03.sv \
        > "$tmp_dir/build$mode.log" 2>&1 || {
            tail -40 "$tmp_dir/build$mode.log" >&2
            exit 1
        }
    run_args=(+MODEL_HEX="$tmp_dir/model.hex" \
        +INPUTS_HEX="$tmp_dir/in$mode.hex" \
        +EXPECTED_FILE="$tmp_dir/expected.txt")
    [[ -f "$tmp_dir/layers.hex" ]] && run_args+=(+LAYERS_HEX="$tmp_dir/layers.hex")
    "$obj/simulator" "${run_args[@]}" > "$tmp_dir/run$mode.log" 2>&1 || {
            tail -10 "$tmp_dir/run$mode.log" >&2
            exit 1
        }
    grep -q "NPU_ROAD_V03_PASS" "$tmp_dir/run$mode.log" || {
        tail -10 "$tmp_dir/run$mode.log" >&2
        exit 1
    }
    grep "NPU_ROAD_V03_PASS" "$tmp_dir/run$mode.log"
done
echo "NPU_ROAD_MODEL_V03_TEST_PASS cases=$roi_count model_bytes=$model_bytes"
