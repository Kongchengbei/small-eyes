#!/usr/bin/env bash
set -euo pipefail

# Create the single Flash payload expected by the DDR boot loader:
#   [fixed-size CPU image][model.npu]
# The RTL loads the first segment to the CPU DDR base and the second segment
# to SOC_NPU_WEIGHT_BASE before releasing the CPU/NPU image service.

usage() {
    echo "usage: $0 CPU_IMAGE MODEL_NPU OUTPUT [CPU_IMAGE_BYTES]" >&2
    exit 2
}

[[ $# -ge 3 && $# -le 4 ]] || usage
cpu_image=$1
model_npu=$2
output=$3
cpu_bytes=${4:-16384}

[[ -f "$cpu_image" ]] || { echo "CPU image not found: $cpu_image" >&2; exit 1; }
[[ -f "$model_npu" ]] || { echo "model.npu not found: $model_npu" >&2; exit 1; }
[[ "$cpu_bytes" =~ ^[1-9][0-9]*$ ]] || { echo "CPU_IMAGE_BYTES must be positive" >&2; exit 1; }
(( cpu_bytes % 4 == 0 )) || { echo "CPU_IMAGE_BYTES must be 4-byte aligned" >&2; exit 1; }

cpu_size=$(wc -c < "$cpu_image" | tr -d ' ')
model_size=$(wc -c < "$model_npu" | tr -d ' ')
(( cpu_size <= cpu_bytes )) || {
    echo "CPU image is $cpu_size bytes, larger than reserved $cpu_bytes bytes" >&2
    exit 1
}
(( model_size > 0 && model_size % 4 == 0 )) || {
    echo "model.npu must be non-empty and 4-byte aligned" >&2
    exit 1
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 "$repo_root/scripts/npu_model.py" check "$model_npu" >/dev/null

mkdir -p "$(dirname "$output")"
cp "$cpu_image" "$output"
truncate -s "$cpu_bytes" "$output"
cat "$model_npu" >> "$output"

total_size=$(wc -c < "$output" | tr -d ' ')
echo "NPU_FLASH_IMAGE_PASS cpu_bytes=$cpu_bytes model_bytes=$model_size total_bytes=$total_size output=$output"
