#!/usr/bin/env bash
set -euo pipefail

# Check the PDS *mapping report*, not RTL attributes. Pass the report path as
# $1 when running against a different PDS workspace.
report=${1:-/mnt/d/HPUfile/JiChuang/npu/small-eyes/project/synthesize/apm_drm_lutram_utilization.log}
if [[ ! -r "$report" ]]; then
    echo "NPU_BRAM_CHECK_FAIL missing_report=$report" >&2
    exit 1
fi

check_bank() {
    local bank=$1 expected=$2 actual
    actual=$(rg -c "[[:space:]]${bank}_[0-9]+(_upper|_lower)?[[:space:]]+\\|.*GTP_DRM36K_E1" "$report" || true)
    actual=${actual:-0}
    if [[ "$actual" != "$expected" ]]; then
        echo "NPU_BRAM_CHECK_FAIL bank=$bank expected_DRM36K=$expected actual=$actual" >&2
        exit 1
    fi
    if rg -q "${bank}_[0-9]+.*GTP_RAM" "$report"; then
        echo "NPU_BRAM_CHECK_FAIL bank=$bank has_LUT_RAM_mapping" >&2
        exit 1
    fi
    echo "NPU_BRAM_BANK_PASS bank=$bank DRM36K=$actual"
}

check_bank model_mem 16
check_bank tensor_a 4
check_bank tensor_b 4
echo "NPU_BRAM_CHECK_PASS large_storage_DRM36K=24"
