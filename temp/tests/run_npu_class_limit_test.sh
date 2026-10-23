#!/usr/bin/env bash
set -euo pipefail

# NPU class-count limit test.  The hardware limit is 16 classes:
#   * a 16-class package (the v0.3 package plus 5 inert extra outputs) must be
#     accepted and answer exactly like the 11-class package,
#   * a 17-class package must be refused with the model-format error 0x22,
#   * the same 17-class package must be accepted once the limit is raised, so
#     the refusal is caused by the class count and nothing else,
#   * a 16-class package whose real rows sit in the highest slots (the classes
#     that win in the ROI set take slots 15, 14, ...) must answer like the
#     11-class package with the class ids renamed, so slots 11..15 are shown
#     to be able to win.
# Both the batch path (Hnpu_service) and the production path (Hnpu_system with
# the image service) run with the default MAX_CLASSES of the RTL.  Variants are
# generated into a temporary directory and are never written anywhere else.
export PYTHONDONTWRITEBYTECODE=1
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
model_dir="${1:-temp/路标模型文件v0.3_10月10日}"
tmp_dir="$(mktemp -d /tmp/npu-class-limit.XXXXXX)"
trap '[[ -n "${KEEP_TMP:-}" ]] || rm -rf "$tmp_dir"' EXIT
[[ -z "${KEEP_TMP:-}" ]] || echo "NPU_CLASS_LIMIT_TMP=$tmp_dir"

hexdump_bytes() {
    od -An -v -t x1 "$1" | awk '{for (i = 1; i <= NF; i++) print $i}' > "$2"
}

if [[ -f "$model_dir/model.npu" ]]; then
    cp "$model_dir/model.npu" "$tmp_dir/m11.npu"
elif [[ -f "$model_dir/model.json" ]]; then
    python3 scripts/npu_model.py build-road --source "$model_dir" --output "$tmp_dir/m11.npu" >/dev/null
else
    echo "模型目录必须包含 model.npu 或 model.json: $model_dir" >&2
    exit 1
fi
python3 scripts/npu_model.py check "$tmp_dir/m11.npu" >/dev/null
for classes in 16 17; do
    python3 temp/tests/npu_class_limit_models.py build --source "$tmp_dir/m11.npu" \
        --classes "$classes" --output "$tmp_dir/m$classes.npu"
    python3 scripts/npu_model.py check "$tmp_dir/m$classes.npu" >/dev/null
done

if [[ -f "$model_dir/golden_output.csv" ]]; then
    python3 temp/tests/npu_model_reference.py golden \
        --model "$tmp_dir/m11.npu" --source "$model_dir" --output-dir "$tmp_dir/reference" >/dev/null
    # CLASS_LIMIT_ROIS: golden ROIs per run (default 14, both testbenches take up to 128; 101 = whole golden set)
    select_args=(--count "${CLASS_LIMIT_ROIS:-14}" --golden)
else
    python3 temp/tests/npu_model_reference.py smoke \
        --model "$tmp_dir/m11.npu" --output-dir "$tmp_dir/reference" --cases 16 >/dev/null
    select_args=(--count 8)
fi
python3 temp/tests/npu_class_limit_models.py select --reference-dir "$tmp_dir/reference" \
    --output-dir "$tmp_dir/full" "${select_args[@]}"
roi_count=$(( $(wc -c < "$tmp_dir/full/in32.bin" | tr -d ' ') / 4096 ))
sub_count=3
[[ "$roi_count" -ge "$sub_count" ]] || { echo "输入案例太少: $roi_count" >&2; exit 1; }
mkdir -p "$tmp_dir/sub"
head -c $((sub_count * 4096)) "$tmp_dir/full/in32.bin" > "$tmp_dir/sub/in32.bin"
head -c $((sub_count * 36864)) "$tmp_dir/full/in96.bin" > "$tmp_dir/sub/in96.bin"
head -n "$sub_count" "$tmp_dir/full/expected.txt" > "$tmp_dir/sub/expected.txt"

python3 temp/tests/npu_class_limit_models.py build --source "$tmp_dir/m11.npu" --classes 16 \
    --winners-from "$tmp_dir/full/expected.txt" --output "$tmp_dir/m16w.npu"
python3 scripts/npu_model.py check "$tmp_dir/m16w.npu" >/dev/null

# The variants must answer like the source package before any RTL is involved.
python3 temp/tests/npu_class_limit_models.py verify --source "$tmp_dir/m11.npu" \
    --inputs "$tmp_dir/full/in32.bin" --expected "$tmp_dir/full/expected.txt" \
    --remapped "$tmp_dir/m16w.npu" --write-expected "$tmp_dir/full/expected_w16.txt" \
    "$tmp_dir/m16.npu" "$tmp_dir/m17.npu"

for model in m11 m16 m16w m17; do
    hexdump_bytes "$tmp_dir/$model.npu" "$tmp_dir/$model.hex"
done
bytes11=$(wc -c < "$tmp_dir/m11.npu" | tr -d ' ')
bytes16=$(wc -c < "$tmp_dir/m16.npu" | tr -d ' ')
bytes16w=$(wc -c < "$tmp_dir/m16w.npu" | tr -d ' ')
bytes17=$(wc -c < "$tmp_dir/m17.npu" | tr -d ' ')
for set in full sub; do
    hexdump_bytes "$tmp_dir/$set/in32.bin" "$tmp_dir/$set/in32.hex"
    hexdump_bytes "$tmp_dir/$set/in96.bin" "$tmp_dir/$set/in96.hex"
done

run_case() {
    # run_case <name> <testbench> <extra verilator flags> <plusargs>
    local name="$1" testbench="$2" flags="$3" args="$4" pass_line
    if ! env SIMULATOR="${SIMULATOR:-verilator}" SIM_JOBS="${SIM_JOBS:-2}" \
            SIM_TIMEOUT="${SIM_TIMEOUT:-600}" SIM_FLAGS="$flags" SIM_ARGS="$args" \
            bash scripts/run_testbench.sh "$testbench" > "$tmp_dir/$name.log" 2>&1; then
        tail -40 "$tmp_dir/$name.log" >&2
        echo "类数上限测试未通过: $name" >&2
        exit 1
    fi
    pass_line="$(grep -E '^NPU_CLASS_LIMIT_(SERVICE|SYSTEM)_PASS' "$tmp_dir/$name.log" || true)"
    [[ -n "$pass_line" ]] || {
        tail -40 "$tmp_dir/$name.log" >&2
        echo "类数上限测试缺少通过标记: $name" >&2
        exit 1
    }
    echo "$name: $pass_line"
    grep '^CLASS_LIMIT_RESULT' "$tmp_dir/$name.log" > "$tmp_dir/$name.results" || true
}

service_args() {
    # service_args <model> <set> <rois> <model bytes> <class count> <limit> <expect> [expected file]
    echo "+MODEL_HEX=$tmp_dir/$1.hex +INPUT_HEX=$tmp_dir/$2/in32.hex" \
         "+EXPECTED_FILE=$tmp_dir/$2/${8:-expected.txt} +ROI_COUNT=$3 +MODEL_BYTES=$4" \
         "+CLASS_COUNT=$5 +LIMIT=$6 +EXPECT=$7"
}
system_args() {
    # system_args <model> <set> <rois> <expect> [expected file]
    echo "+MODEL_HEX=$tmp_dir/$1.hex +INPUT_HEX=$tmp_dir/$2/in96.hex" \
         "+EXPECTED_FILE=$tmp_dir/$2/${5:-expected.txt} +ROI_COUNT=$3 +EXPECT=$4"
}

# Batch path: default MAX_CLASSES of Hnpu_service.  The 17-class refusal run
# declares 16 classes on the batch interface (the most it lets through) so the
# package header, not the interface, is what gets refused.
run_case svc_ref11 tb_npu_class_limit_service "" \
    "$(service_args m11 full "$roi_count" "$bytes11" 11 16 accept)"
run_case svc_acc16 tb_npu_class_limit_service "" \
    "$(service_args m16 full "$roi_count" "$bytes16" 16 16 accept)"
run_case svc_win16 tb_npu_class_limit_service "" \
    "$(service_args m16w full "$roi_count" "$bytes16w" 16 16 accept expected_w16.txt)"
run_case svc_rej17 tb_npu_class_limit_service "" \
    "$(service_args m17 sub "$sub_count" "$bytes17" 16 16 model_error)"
run_case svc_ctl17 tb_npu_class_limit_service "-DDUT_MAX_CLASSES=32" \
    "$(service_args m17 sub "$sub_count" "$bytes17" 17 32 accept)"

# Production path: default MAX_CLASSES of Hnpu_system (image service).
run_case sys_ref11 tb_npu_class_limit_system "-GMODEL_BYTES=$bytes11" \
    "$(system_args m11 full "$roi_count" accept)"
run_case sys_acc16 tb_npu_class_limit_system "-GMODEL_BYTES=$bytes16" \
    "$(system_args m16 full "$roi_count" accept)"
run_case sys_win16 tb_npu_class_limit_system "-GMODEL_BYTES=$bytes16w" \
    "$(system_args m16w full "$roi_count" accept expected_w16.txt)"
run_case sys_rej17 tb_npu_class_limit_system "-GMODEL_BYTES=$bytes17" \
    "$(system_args m17 sub "$sub_count" model_error)"
run_case sys_ctl17 tb_npu_class_limit_system "-GMODEL_BYTES=$bytes17 -DDUT_MAX_CLASSES=32" \
    "$(system_args m17 sub "$sub_count" accept)"

same_results() {
    cmp -s "$tmp_dir/$1.results" "$tmp_dir/$2.results" || {
        echo "结果不一致: $1 与 $2" >&2
        diff "$tmp_dir/$1.results" "$tmp_dir/$2.results" >&2 || true
        exit 1
    }
}
[[ "$(wc -l < "$tmp_dir/svc_ref11.results" | tr -d ' ')" -eq "$roi_count" ]] || {
    echo "svc_ref11 结果条数不对" >&2
    exit 1
}
head -n "$sub_count" "$tmp_dir/svc_ref11.results" > "$tmp_dir/ref11_sub.results"
same_results svc_ref11 svc_acc16
same_results svc_ref11 sys_ref11
same_results sys_ref11 sys_acc16
same_results ref11_sub svc_ctl17
same_results ref11_sub sys_ctl17
same_results svc_win16 sys_win16

# The renamed-class variant must differ from the 11-class run in the class field only.
without_class() { sed -E 's/ class=[0-9]+//' "$tmp_dir/$1.results"; }
for level in svc sys; do
    cmp -s <(without_class ${level}_ref11) <(without_class ${level}_win16) || {
        echo "${level}_win16 的 margin/reject/score 与 ${level}_ref11 不一致" >&2
        diff <(without_class ${level}_ref11) <(without_class ${level}_win16) >&2 || true
        exit 1
    }
done
high_winners="$(sed -En 's/^CLASS_LIMIT_RESULT idx=[0-9]+ class=([0-9]+) .*/\1/p' "$tmp_dir/svc_win16.results" |
    awk '$1 >= 11' | sort -un | paste -sd, -)"
case ",$high_winners," in
    *,15,*) ;;
    *) echo "没有任何 ROI 在槽位 15 获胜: [$high_winners]" >&2; exit 1 ;;
esac

echo "NPU_CLASS_LIMIT_TEST_PASS rois=$roi_count refused_rois=$sub_count bytes=$bytes11/$bytes16/$bytes17 high_slot_winners=$high_winners simulator=${SIMULATOR:-verilator}"
