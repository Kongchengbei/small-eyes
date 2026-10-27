#!/usr/bin/env bash
set -euo pipefail

# Create the single Flash payload expected by the DDR boot loader:
#   [fixed-size CPU image][model.npu]
# The RTL loads the first segment to the CPU DDR base and the second segment
# to SOC_NPU_WEIGHT_BASE before releasing the CPU/NPU image service.
# The RTL reads model.npu at FLASH_BASE + SOC_BOOT_IMAGE_BYTES, so the CPU
# segment size defaults to SOC_BOOT_IMAGE_BYTES in soc/soc_addr_map.vh and
# must match it.

usage() {
    echo "usage: $0 CPU_IMAGE MODEL_NPU OUTPUT [CPU_IMAGE_BYTES]" >&2
    exit 2
}

[[ $# -ge 3 && $# -le 4 ]] || usage
cpu_image=$1
model_npu=$2
output=$3

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
addr_map="$repo_root/soc/soc_addr_map.vh"
map_bytes=$(sed -n "s/^\`define SOC_BOOT_IMAGE_BYTES[[:space:]]*32'd\([0-9][0-9]*\).*/\1/p" "$addr_map")
[[ -n "$map_bytes" ]] || { echo "SOC_BOOT_IMAGE_BYTES not found in $addr_map" >&2; exit 1; }
model_map_bytes=$(sed -n "s/^\`define SOC_NPU_MODEL_BYTES[[:space:]]*32'd\([0-9][0-9]*\).*/\1/p" "$addr_map")
[[ -n "$model_map_bytes" ]] || { echo "SOC_NPU_MODEL_BYTES not found in $addr_map" >&2; exit 1; }
cpu_bytes=${4:-$map_bytes}

[[ -f "$cpu_image" ]] || { echo "CPU image not found: $cpu_image" >&2; exit 1; }
[[ -f "$model_npu" ]] || { echo "model.npu not found: $model_npu" >&2; exit 1; }
[[ "$cpu_bytes" =~ ^[1-9][0-9]*$ ]] || { echo "CPU_IMAGE_BYTES must be positive" >&2; exit 1; }
(( cpu_bytes % 4 == 0 )) || { echo "CPU_IMAGE_BYTES must be 4-byte aligned" >&2; exit 1; }
(( cpu_bytes == map_bytes )) || {
    echo "CPU_IMAGE_BYTES=$cpu_bytes differs from SOC_BOOT_IMAGE_BYTES=$map_bytes;" \
        "the RTL would read model.npu from the wrong Flash offset" >&2
    exit 1
}

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
(( model_size == model_map_bytes )) || {
    echo "model.npu is $model_size bytes, but SOC_NPU_MODEL_BYTES=$model_map_bytes;" \
        "the boot loader and NPU service must use the same model length" >&2
    exit 1
}

python3 "$repo_root/scripts/npu_model.py" check "$model_npu" >/dev/null

mkdir -p "$(dirname "$output")"
cp "$cpu_image" "$output"
truncate -s "$cpu_bytes" "$output"
cat "$model_npu" >> "$output"

total_size=$(wc -c < "$output" | tr -d ' ')
echo "NPU_FLASH_IMAGE_PASS cpu_bytes=$cpu_bytes model_bytes=$model_size total_bytes=$total_size output=$output"
