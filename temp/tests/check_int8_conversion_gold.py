#!/usr/bin/env python3
"""Verify the 96x96 RGB565/INT8 gold package without third-party modules."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def convert(rgb565: bytes) -> bytes:
    result = bytearray()
    for offset in range(0, len(rgb565), 2):
        pixel = int.from_bytes(rgb565[offset : offset + 2], "little")
        r5 = pixel >> 11
        g6 = (pixel >> 5) & 0x3F
        b5 = pixel & 0x1F
        result.extend(
            value & 0xFF
            for value in (
                ((r5 << 3) | (r5 >> 2)) - 128,
                ((g6 << 2) | (g6 >> 4)) - 128,
                ((b5 << 3) | (b5 >> 2)) - 128,
                0,
            )
        )
    return bytes(result)


def hex_beats(data: bytes) -> list[str]:
    return [data[offset : offset + 32][::-1].hex() for offset in range(0, len(data), 32)]


def first_diff(left: bytes, right: bytes) -> int:
    return next(
        (index for index, (a, b) in enumerate(zip(left, right)) if a != b),
        min(len(left), len(right)),
    )


def sampled_32(data: bytes) -> bytes:
    result = bytearray()
    for y in range(32):
        row = y * 3 * 96 * 4
        for x in range(32):
            offset = row + x * 3 * 4
            result.extend(data[offset : offset + 4])
    return bytes(result)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("gold_dir", type=Path)
    parser.add_argument("--tensor32", type=Path)
    args = parser.parse_args()
    gold_dir = args.gold_dir
    tensor_dir = args.tensor32
    rows = list(csv.DictReader((gold_dir / "index.csv").read_text(encoding="utf-8-sig").splitlines()))
    errors: list[str] = []

    for row in rows:
        name = row["name"]
        rgb565 = (gold_dir / "inputs" / f"{name}_96.bin").read_bytes()
        int8 = (gold_dir / "int8" / f"{name}_96_int8.bin").read_bytes()
        if len(rgb565) != 96 * 96 * 2:
            errors.append(f"{name}: RGB565 length={len(rgb565)}")
        if len(int8) != 96 * 96 * 4:
            errors.append(f"{name}: INT8 length={len(int8)}")
        if hex_beats(rgb565) != (gold_dir / "inputs" / f"{name}_96.hex").read_text().split():
            errors.append(f"{name}: RGB565 bin/hex mismatch")
        if hex_beats(int8) != (gold_dir / "int8" / f"{name}_96_int8.hex").read_text().split():
            errors.append(f"{name}: INT8 bin/hex mismatch")
        expected = convert(rgb565)
        if expected != int8:
            errors.append(f"{name}: RGB565 to INT8 mismatch at byte {first_diff(expected, int8)}")
        if row["sampled_vs_tensor32"] == "相同":
            if tensor_dir is None:
                errors.append(f"{name}: --tensor32 is required")
            else:
                tensor = (tensor_dir / f"{name}.bin").read_bytes()
                sampled = sampled_32(int8)
                if sampled != tensor:
                    errors.append(f"{name}: 96-to-32 sampling mismatch at byte {first_diff(sampled, tensor)}")

    print(f"INT8_GOLDEN_CHECK cases={len(rows)} mismatches={len(errors)}")
    for error in errors[:20]:
        print(f"INT8_GOLDEN_ERROR {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
