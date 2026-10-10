#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

package="$tmp_dir/demo.npu"
python3 scripts/npu_model.py build-demo --output "$package"
python3 scripts/npu_model.py check "$package"
python3 scripts/npu_model.py inspect "$package" >/dev/null

python3 - "$package" "$tmp_dir/bad.npu" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_bytes()
broken = bytearray(source)
broken[0] ^= 0x01
pathlib.Path(sys.argv[2]).write_bytes(broken)
PY

if python3 scripts/npu_model.py check "$tmp_dir/bad.npu"; then
    echo "NPU_MODEL_TEST_FAIL invalid package accepted" >&2
    exit 1
fi

python3 - "$package" "$tmp_dir/bad-descriptor.npu" <<'PY'
import pathlib
import sys

source = bytearray(pathlib.Path(sys.argv[1]).read_bytes())
# Keep the CRC valid so the structural descriptor check is exercised.
source[0x1c:0x20] = (64).to_bytes(4, "little")
pathlib.Path(sys.argv[2]).write_bytes(source)
PY
if python3 scripts/npu_model.py check "$tmp_dir/bad-descriptor.npu"; then
    echo "NPU_MODEL_TEST_FAIL truncated descriptor table accepted" >&2
    exit 1
fi

echo "NPU_MODEL_TEST_PASS"
