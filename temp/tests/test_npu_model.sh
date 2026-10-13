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

python3 - "$package" <<'PY'
import pathlib
import sys

data = pathlib.Path(sys.argv[1]).read_bytes()
assert int.from_bytes(data[0x34:0x38], "little") == 64
assert data[128 + 0x01] == 0
assert data[128 + 0x38:128 + 0x40] == bytes(8)
print("NPU_MODEL_CONTRACT_PASS scratch=64 activation_offset=0x01")
PY

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

python3 - "$package" "$tmp_dir/bad-scratch.npu" <<'PY'
import pathlib
import sys

source = bytearray(pathlib.Path(sys.argv[1]).read_bytes())
source[0x34:0x38] = (32).to_bytes(4, "little")
pathlib.Path(sys.argv[2]).write_bytes(source)
PY
if python3 scripts/npu_model.py check "$tmp_dir/bad-scratch.npu"; then
    echo "NPU_MODEL_TEST_FAIL undersized scratch accepted" >&2
    exit 1
fi

python3 - "$package" "$tmp_dir/bad-reserved.npu" <<'PY'
import pathlib
import sys

source = bytearray(pathlib.Path(sys.argv[1]).read_bytes())
source[128 + 0x38] = 1
pathlib.Path(sys.argv[2]).write_bytes(source)
PY
if python3 scripts/npu_model.py check "$tmp_dir/bad-reserved.npu"; then
    echo "NPU_MODEL_TEST_FAIL descriptor reserved byte accepted" >&2
    exit 1
fi

python3 - "$package" "$tmp_dir/legacy-duplicate-flags.npu" <<'PY'
import pathlib
import struct
import sys
import zlib

source = bytearray(pathlib.Path(sys.argv[1]).read_bytes())
descriptor = 128
source[descriptor + 1] = 1
source[descriptor + 0x38] = 1
struct.pack_into("<I", source, 0x40, zlib.crc32(source[128:]) & 0xFFFFFFFF)
pathlib.Path(sys.argv[2]).write_bytes(source)
PY
python3 scripts/npu_model.py check "$tmp_dir/legacy-duplicate-flags.npu"
echo "NPU_MODEL_LEGACY_COMPAT_PASS duplicate_flags=0x38"

echo "NPU_MODEL_TEST_PASS"
