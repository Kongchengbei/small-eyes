#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
python3 temp/tests/check_int8_conversion_gold.py \
    "temp/路标INT8转换金样96_10月9日" \
    --tensor32 "temp/路标逐层金样v0.2/inputs"
echo "NPU_INT8_CONVERSION_GOLD_TEST_PASS"
