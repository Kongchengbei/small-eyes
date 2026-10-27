#!/usr/bin/env python3
"""Pad a valid NPU model to the byte count fixed by the current FPGA image."""

import argparse
import sys
import zlib
from pathlib import Path

from npu_model import HEADER_BYTES, put_u32, read_header, validate


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--size", required=True, type=int)
    args = parser.parse_args()

    data = bytearray(args.input.read_bytes())
    errors = validate(data)
    if errors:
        parser.error("input model is invalid: " + "; ".join(errors))
    if args.size < len(data) or args.size % 32:
        parser.error("target size must be >= input size and 32-byte aligned")

    data.extend(bytes(args.size - len(data)))
    put_u32(data, 0x30, args.size)
    put_u32(data, 0x40, zlib.crc32(data[HEADER_BYTES:]) & 0xFFFFFFFF)
    errors = validate(data)
    if errors:
        parser.error("padded model is invalid: " + "; ".join(errors))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    print(f"NPU_MODEL_PAD_PASS bytes={len(data)} classes={read_header(data)['class_count']} output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
