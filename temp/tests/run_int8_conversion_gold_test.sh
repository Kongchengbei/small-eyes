#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
conversion_dir="${1:-temp/路标INT8转换金样96_10月9日}"
tensor_dir="${2:-temp/路标逐层金样v0.2/inputs}"
if [[ ! -f "$conversion_dir/index.csv" || ! -d "$tensor_dir" ]]; then
    echo "NPU_INT8_CONVERSION_GOLD_TEST_SKIP missing current conversion/tensor gold"
    exit 0
fi
python3 temp/tests/check_int8_conversion_gold.py "$conversion_dir" --tensor32 "$tensor_dir"
echo "NPU_INT8_CONVERSION_GOLD_TEST_PASS"
