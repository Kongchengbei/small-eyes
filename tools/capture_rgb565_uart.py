#!/usr/bin/env python3
"""Capture and validate the camera one-shot RGB565 UART stream.

Protocol: R565DMP1 + 44-byte little-endian header + exactly payload_len bytes
+ END565D1 + matching CRC32. Incomplete captures are never named .rgb565.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import struct
import sys
import time
import zlib


MAGIC = b"R565DMP1"
FOOTER = b"END565D1"
HEADER_SIZE = 44
EXPECTED_WIDTH = 640
EXPECTED_HEIGHT = 480
EXPECTED_STRIDE = 1280
EXPECTED_PAYLOAD = 614400
EXPECTED_ADDRESSES = {0xB8000000, 0xB8100000}
HEADER_STRUCT = struct.Struct("<8sHHBBHIIHHIIII")


class CaptureError(Exception):
    pass


def unpack_header(header: bytes) -> dict[str, int | str]:
    if len(header) != HEADER_SIZE:
        raise CaptureError(f"header length is {len(header)}, expected {HEADER_SIZE}")
    (magic, version, header_len, camera, pixel_format, flags, frame, address,
     width, height, stride, payload_len, crc32, reserved) = HEADER_STRUCT.unpack(header)
    if magic != MAGIC:
        raise CaptureError("header magic mismatch")
    checks = {
        "version": (version, 1), "header_len": (header_len, HEADER_SIZE),
        "camera": (camera, 1), "pixel_format": (pixel_format, 1),
        "flags": (flags, 1), "width": (width, EXPECTED_WIDTH),
        "height": (height, EXPECTED_HEIGHT), "stride": (stride, EXPECTED_STRIDE),
        "payload_len": (payload_len, EXPECTED_PAYLOAD), "reserved": (reserved, 0),
    }
    for name, (actual, expected) in checks.items():
        if actual != expected:
            raise CaptureError(f"unsupported header {name}={actual}; expected {expected}")
    if address not in EXPECTED_ADDRESSES:
        raise CaptureError(f"frame address 0x{address:08X} is not a CAM1 RGB565 slot")
    return {
        "version": version, "header_len": header_len, "camera": camera,
        "pixel_format": "RGB565_LE", "flags": flags, "frame_count": frame,
        "frame_addr": address, "width": width, "height": height,
        "stride": stride, "payload_len": payload_len, "crc32": crc32,
        "reserved": reserved,
    }


def read_some(port, size: int, deadline: float) -> bytes:
    """Read up to size bytes while enforcing one absolute deadline."""
    result = bytearray()
    while len(result) < size:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        port.timeout = min(0.5, remaining)
        chunk = port.read(size - len(result))
        if chunk:
            result.extend(chunk)
    return bytes(result)


def read_exact(port, size: int, deadline: float, sink=None, crc: int = 0) -> tuple[bytes, int]:
    """Read exactly size bytes; optionally stream them to sink and update CRC32."""
    collected = bytearray()
    left = size
    while left:
        chunk = read_some(port, min(left, 4096), deadline)
        if not chunk:
            raise CaptureError(f"timeout/interruption after {size-left} of {size} bytes")
        if sink is None:
            collected.extend(chunk)
        else:
            sink.write(chunk)
        crc = zlib.crc32(chunk, crc)
        left -= len(chunk)
    return bytes(collected), crc & 0xFFFFFFFF


def find_valid_header(port, timeout: float) -> tuple[bytes, dict[str, int | str]]:
    """Skip startup text and accept only a magic followed by a valid fixed header."""
    deadline = time.monotonic() + timeout
    window = bytearray()
    error_window = bytearray()
    while time.monotonic() < deadline:
        magic_at = window.find(MAGIC)
        if magic_at >= 0:
            while len(window) - magic_at < HEADER_SIZE:
                b = read_some(port, 1, deadline)
                if not b:
                    raise CaptureError("timeout while reading candidate 44-byte header")
                window.extend(b)
                error_window.extend(b)
            candidate = bytes(window[magic_at:magic_at + HEADER_SIZE])
            try:
                info = unpack_header(candidate)
                return candidate, info
            except CaptureError:
                # Treat the match as ordinary bytes and continue scanning for a valid header.
                del window[:magic_at + 1]
                continue

        b = read_some(port, 1, deadline)
        if not b:
            continue
        window.extend(b)
        error_window.extend(b)
        if len(window) > len(MAGIC):
            del window[0]
        if len(error_window) > 128:
            del error_window[:len(error_window) - 128]
        if b"DUMP_ERROR code=" in error_window and error_window.endswith(b"\n"):
            line = bytes(error_window).split(b"DUMP_ERROR code=")[-1].strip()
            raise CaptureError(f"firmware reported DUMP_ERROR code={line.decode('ascii', 'replace')}")
    raise CaptureError(f"no {MAGIC.decode()} frame header seen within {timeout:g}s")


def capture(args: argparse.Namespace) -> Path:
    try:
        import serial
    except ImportError as exc:
        raise CaptureError("pyserial is required; install with: python -m pip install pyserial") from exc

    prefix: Path = args.output_prefix
    raw_path = prefix.with_suffix(".rgb565")
    partial_path = prefix.with_suffix(".rgb565.incomplete")
    metadata_path = prefix.with_suffix(".json")
    partial_meta_path = prefix.with_suffix(".incomplete.json")
    collisions = [p for p in (raw_path, partial_path, metadata_path, partial_meta_path) if p.exists()]
    if collisions:
        raise CaptureError("refusing to overwrite existing output(s): " + ", ".join(map(str, collisions)))

    print(f"Opening {args.port} at {args.baud} 8-N-1, no flow control; waiting for a valid {MAGIC.decode()} header...")
    port = serial.Serial(args.port, args.baud, bytesize=serial.EIGHTBITS,
                         parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE,
                         timeout=0.5, xonxoff=False, rtscts=False, dsrdtr=False)
    header = b""
    expected = EXPECTED_PAYLOAD
    got = 0
    running_crc = 0
    try:
        with port:
            # The firmware emits boot/status text first; scanning begins before the user resets it.
            header, info = find_valid_header(port, args.start_timeout)
            deadline = time.monotonic() + args.frame_timeout
            expected = int(info["payload_len"])
            print(f"Header accepted: CAM{info['camera']} frame={info['frame_count']} "
                  f"addr=0x{int(info['frame_addr']):08X}, {info['width']}x{info['height']}, "
                  f"{expected} bytes; receiving binary payload...")
            with partial_path.open("xb") as sink:
                left = expected
                while left:
                    chunk = read_some(port, min(left, 4096), deadline)
                    if not chunk:
                        raise CaptureError(f"payload timeout after {got} of {expected} bytes")
                    sink.write(chunk)
                    running_crc = zlib.crc32(chunk, running_crc) & 0xFFFFFFFF
                    got += len(chunk)
                    left -= len(chunk)
                sink.flush()
            footer, _ = read_exact(port, len(FOOTER) + 4, deadline)
            if footer[:len(FOOTER)] != FOOTER:
                raise CaptureError(f"bad footer magic: got {footer[:8]!r}")
            footer_crc = struct.unpack("<I", footer[len(FOOTER):])[0]
            header_crc = int(info["crc32"])
            if running_crc != header_crc or running_crc != footer_crc:
                raise CaptureError(f"CRC32 mismatch: payload=0x{running_crc:08X}, "
                                   f"header=0x{header_crc:08X}, footer=0x{footer_crc:08X}")

        info.update({
            "status": "complete", "captured_at_utc": datetime.now(timezone.utc).isoformat(),
            "serial_port": args.port, "baud": args.baud, "byte_order": "little",
            "checksum": "CRC-32/ISO-HDLC (IEEE), payload only",
            "payload_crc32": f"{running_crc:08X}", "footer": FOOTER.decode("ascii"),
        })
        partial_path.replace(raw_path)
        metadata_path.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
        print(f"Verified {got} payload bytes, CRC32={running_crc:08X}; saved {raw_path} and {metadata_path}")
        decoder = Path(__file__).with_name("rgb565_dump_to_png.py")
        import subprocess
        subprocess.run([sys.executable, str(decoder), str(raw_path), str(prefix),
                        "--width", str(info["width"]), "--height", str(info["height"]),
                        "--stride", str(info["stride"]), "--offset", "0",
                        "--byte-order", "little"], check=True)
        return raw_path
    except BaseException as exc:
        if partial_path.exists():
            partial_info = {
                "status": "incomplete", "serial_port": args.port, "baud": args.baud,
                "expected_payload_len": expected, "received_payload_len": got,
                "payload_crc32_so_far": f"{running_crc:08X}",
                "reason": str(exc),
            }
            if header:
                try:
                    partial_info["header"] = unpack_header(header)
                except CaptureError:
                    partial_info["header_bytes_hex"] = header.hex()
            partial_meta_path.write_text(json.dumps(partial_info, indent=2) + "\n", encoding="utf-8")
            print(f"INCOMPLETE: retained {partial_path} ({got}/{expected} payload bytes); "
                  f"see {partial_meta_path}", file=sys.stderr)
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("port", help="Windows COM port (e.g. COM5) or Linux device (e.g. /dev/ttyUSB0)")
    parser.add_argument("output_prefix", type=Path, help="new output prefix; existing outputs are never overwritten")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--start-timeout", type=float, default=180.0,
                        help="seconds to scan boot/status text for the frame magic")
    parser.add_argument("--frame-timeout", type=float, default=150.0,
                        help="absolute seconds allowed for header, payload and footer")
    args = parser.parse_args()
    if args.start_timeout <= 0 or args.frame_timeout <= 0:
        parser.error("timeouts must be positive")
    try:
        capture(args)
    except KeyboardInterrupt:
        print("Interrupted; no complete .rgb565 file was accepted.", file=sys.stderr)
        return 130
    except Exception as exc:
        print(f"capture failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
