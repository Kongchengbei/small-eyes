#!/usr/bin/env python3
"""Decode a captured raw RGB565 frame/dump to PNG without third-party packages.

The input must be a real byte dump from the board (or a subrange of one).
This tool does not synthesize pixels. By default it writes the unmodified
orientation and three flip variants to make direction comparisons easy.
"""

from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


def png_chunk(kind: bytes, data: bytes) -> bytes:
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def write_png(path: Path, width: int, height: int, rgb_rows: list[bytes]) -> None:
    raw = b"".join(b"\x00" + row for row in rgb_rows)
    png = (b"\x89PNG\r\n\x1a\n"
           + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
           + png_chunk(b"IDAT", zlib.compress(raw, level=6))
           + png_chunk(b"IEND", b""))
    path.write_bytes(png)


def decode_rows(data: bytes, width: int, height: int, stride: int,
                offset: int, byte_order: str) -> list[bytes]:
    row_bytes = width * 2
    required = offset + (height - 1) * stride + row_bytes
    if offset < 0 or required > len(data):
        raise ValueError(f"dump has {len(data)} bytes; need at least {required} bytes "
                         f"for offset={offset}, {width}x{height}, stride={stride}")
    if stride < row_bytes:
        raise ValueError(f"stride must be at least width*2 ({row_bytes}), got {stride}")

    result: list[bytes] = []
    for y in range(height):
        start = offset + y * stride
        src = data[start:start + row_bytes]
        row = bytearray(width * 3)
        for x in range(width):
            a, b = src[x * 2], src[x * 2 + 1]
            pixel = (a | (b << 8)) if byte_order == "little" else ((a << 8) | b)
            r5, g6, b5 = (pixel >> 11) & 0x1F, (pixel >> 5) & 0x3F, pixel & 0x1F
            i = x * 3
            row[i:i + 3] = bytes(((r5 << 3) | (r5 >> 2),
                                  (g6 << 2) | (g6 >> 4),
                                  (b5 << 3) | (b5 >> 2)))
        result.append(bytes(row))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="real raw RGB565 dump from the board")
    parser.add_argument("output_prefix", type=Path, help="output prefix, e.g. cam1_frame")
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=480)
    parser.add_argument("--stride", type=int, help="bytes per source row; default width*2")
    parser.add_argument("--offset", type=lambda s: int(s, 0), default=0,
                        help="byte offset of first pixel in dump; decimal or 0x-prefixed")
    parser.add_argument("--byte-order", choices=("little", "big"), default="little",
                        help="byte order within each RGB565 pixel (default: little)")
    parser.add_argument("--only-original", action="store_true",
                        help="write only the as-captured orientation")
    args = parser.parse_args()
    if args.width <= 0 or args.height <= 0:
        parser.error("width and height must be positive")
    stride = args.stride if args.stride is not None else args.width * 2
    source = args.input.read_bytes()
    rows = decode_rows(source, args.width, args.height, stride, args.offset, args.byte_order)

    variants = {"original": rows}
    if not args.only_original:
        variants["hflip"] = [b"".join(row[x:x + 3] for x in range(len(row) - 3, -1, -3))
                              for row in rows]
        variants["vflip"] = list(reversed(rows))
        variants["hvflip"] = list(reversed(variants["hflip"]))
    for suffix, variant in variants.items():
        path = args.output_prefix.with_name(args.output_prefix.name + f"_{suffix}.png")
        write_png(path, args.width, args.height, variant)
        print(f"wrote {path} ({args.width}x{args.height}, RGB565 {args.byte_order}-endian, "
              f"offset={args.offset}, stride={stride})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
