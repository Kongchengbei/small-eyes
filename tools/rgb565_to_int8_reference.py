#!/usr/bin/env python3
"""Independent byte-exact reference for the project's 96x96 RGB565 input."""

from __future__ import annotations

import argparse
from pathlib import Path


WIDTH = 96
HEIGHT = 96
INPUT_BYTES = WIDTH * HEIGHT * 2
OUTPUT_BYTES = WIDTH * HEIGHT * 4


def convert_rgb565(data: bytes) -> bytes:
    """Convert little-endian RGB565 pixels to R,G,B,0 signed-INT8 bytes.

    Signed values are emitted in their two's-complement byte representation.
    Each source pixel is read independently as low byte then high byte.
    """
    if len(data) != INPUT_BYTES:
        raise ValueError(f"expected exactly {INPUT_BYTES} input bytes, got {len(data)}")

    output = bytearray(OUTPUT_BYTES)
    dst = 0
    for src in range(0, INPUT_BYTES, 2):
        pixel = data[src] | (data[src + 1] << 8)
        r5 = (pixel >> 11) & 0x1F
        g6 = (pixel >> 5) & 0x3F
        b5 = pixel & 0x1F

        r8 = (r5 << 3) | (r5 >> 2)
        g8 = (g6 << 2) | (g6 >> 4)
        b8 = (b5 << 3) | (b5 >> 2)

        output[dst] = (r8 - 128) & 0xFF
        output[dst + 1] = (g8 - 128) & 0xFF
        output[dst + 2] = (b8 - 128) & 0xFF
        output[dst + 3] = 0
        dst += 4
    return bytes(output)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Convert one tightly packed 96x96 little-endian RGB565 image "
        "to R,G,B,0 signed-INT8 bytes."
    )
    parser.add_argument("input", type=Path, help="raw 18,432-byte RGB565 image")
    parser.add_argument("output", type=Path, help="raw 36,864-byte INT8 tensor")
    args = parser.parse_args()

    source = args.input.read_bytes()
    converted = convert_rgb565(source)
    args.output.write_bytes(converted)
    print(f"converted {len(source)} bytes to {len(converted)} bytes ({WIDTH}x{HEIGHT}, RGB, 4 bytes/pixel)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
