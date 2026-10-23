#!/usr/bin/env python3
"""Class-limit test helper: build N-class variants of an NPU package.

The extra FC rows use weight == weight_zero_point (zero contribution) and a
bias of -2**30, so they never reach the top-2 logits.  Class, margin, reject
and score of every input equal the source package; the variants only exercise
the hardware class-count limit.  With --winners-from the real rows are instead
moved to the highest slots (the classes that win in the given ROI set take
slots N-1, N-2, ...) and the pad rows fill the low slots, so the same inputs
now win in slots 11..15; margin, reject and score still equal the source.
Variants are build products: write them to a temporary directory, never to a
path the firmware could load as the real model.
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import npu_model as nm  # noqa: E402
import npu_model_reference as ref  # noqa: E402

PAD_BIAS = -(1 << 30)


def winner_slots(winners: list[int], old: int, classes: int) -> list[int]:
    """Destination slot of every source class: classes that win in the ROI set take the highest slots."""
    first_seen = list(dict.fromkeys(winners))
    order = first_seen + [c for c in range(old) if c not in first_seen]
    return [classes - 1 - order.index(c) for c in range(old)]


def place_rows(raw: bytes, row_bytes: int, old: int, classes: int, slots: list[int], pad_row: bytes) -> bytes:
    if len(raw) != old * row_bytes:
        raise ValueError(f"FC table is {len(raw)} bytes, expected {old * row_bytes}")
    rows = [pad_row] * classes
    for source_class in range(old):
        rows[slots[source_class]] = raw[source_class * row_bytes:(source_class + 1) * row_bytes]
    return b"".join(rows)


def build_variant(src: bytes, classes: int, slots: list[int] | None = None) -> bytes:
    errors = nm.validate(src)
    if errors:
        raise ValueError("source package invalid: " + "; ".join(errors))
    header = nm.read_header(src)
    old = header["class_count"]
    if classes < old:
        raise ValueError(f"cannot shrink {old} classes to {classes}")
    if slots is None:
        slots = list(range(old))
    if len(slots) != old or len(set(slots)) != old or not all(0 <= s < classes for s in slots):
        raise ValueError(f"invalid slot map {slots} for {old} -> {classes} classes")
    descs = [bytearray(src[header["descriptor_offset"] + i * nm.DESC_BYTES:
                           header["descriptor_offset"] + (i + 1) * nm.DESC_BYTES])
             for i in range(header["layer_count"])]
    layers = [nm.decode_layer(src, header["descriptor_offset"] + i * nm.DESC_BYTES)
              for i in range(header["layer_count"])]
    fc_idx = [i for i, layer in enumerate(layers) if layer.op == nm.OP_FC]
    am_idx = [i for i, layer in enumerate(layers) if layer.op == nm.OP_ARGMAX]
    if len(fc_idx) != 1 or len(am_idx) != 1 or am_idx[0] != fc_idx[0] + 1:
        raise ValueError("source package must end with exactly one FC followed by ARGMAX")
    fc, am = fc_idx[0], am_idx[0]
    in_c = layers[fc].input_shape[2]
    fc_zp = layers[fc].weight_zero_point

    w_base, b_base = header["weight_offset"], header["bias_offset"]
    blobs: list[tuple[int, str, bytes]] = []  # (original local offset, kind, data)
    for i, layer in enumerate(layers):
        if layer.weight_bytes:
            raw = src[layer.weight_offset:layer.weight_offset + layer.weight_bytes]
            if i == fc:
                raw = place_rows(raw, in_c, old, classes, slots, bytes([fc_zp & 0xFF]) * in_c)
            blobs.append((layer.weight_offset - w_base, f"w{i}", raw))
        if layer.bias_bytes:
            raw = src[layer.bias_offset:layer.bias_offset + layer.bias_bytes]
            if i == fc:
                raw = place_rows(raw, 4, old, classes, slots, struct.pack("<i", PAD_BIAS))
            blobs.append((layer.bias_offset - b_base, f"b{i}", raw))

    weights, biases = bytearray(), bytearray()
    new_off: dict[str, int] = {}
    for kind_prefix, section in (("w", weights), ("b", biases)):
        for _, name, raw in sorted((b for b in blobs if b[1][0] == kind_prefix), key=lambda b: b[0]):
            section.extend(bytes(nm.align(len(section)) - len(section)))
            new_off[name] = len(section)
            section.extend(raw)

    new_w_off = w_base
    new_b_off = nm.align(new_w_off + len(weights))
    for i, layer in enumerate(layers):
        d = descs[i]
        if layer.weight_bytes:
            struct.pack_into("<I", d, 0x20, new_w_off + new_off[f"w{i}"])
        if layer.bias_bytes:
            struct.pack_into("<I", d, 0x24, new_b_off + new_off[f"b{i}"])
    struct.pack_into("<H", descs[fc], 12, classes)
    struct.pack_into("<I", descs[fc], 0x28, classes * in_c)
    struct.pack_into("<I", descs[fc], 0x2C, classes * 4)
    struct.pack_into("<H", descs[am], 6, classes)
    struct.pack_into("<H", descs[am], 12, classes)

    total = nm.align(new_b_off + len(biases))
    desc_region = b"".join(bytes(d) for d in descs)
    desc_region += bytes(header["descriptor_total_bytes"] - len(desc_region))
    payload = bytearray(desc_region)
    payload += bytes(new_w_off - nm.HEADER_BYTES - len(payload))
    payload += weights
    payload += bytes(new_b_off - nm.HEADER_BYTES - len(payload))
    payload += biases
    payload += bytes(total - nm.HEADER_BYTES - len(payload))

    out_header = bytearray(src[:nm.HEADER_BYTES])
    out_header[0x16] = classes
    struct.pack_into("<I", out_header, 0x24, len(weights))
    struct.pack_into("<I", out_header, 0x28, new_b_off)
    struct.pack_into("<I", out_header, 0x2C, len(biases))
    struct.pack_into("<I", out_header, 0x30, total)
    struct.pack_into("<I", out_header, 0x40, zlib.crc32(bytes(payload)) & 0xFFFFFFFF)
    out = bytes(out_header) + bytes(payload)
    return out


def cmd_build(args: argparse.Namespace) -> int:
    src = args.source.read_bytes()
    old = nm.read_header(src)["class_count"]
    slots = None
    if args.winners_from is not None:
        winners = [row[0] for row in load_expected(args.winners_from)]
        slots = winner_slots(winners, old, args.classes)
    out = build_variant(src, args.classes, slots)
    if slots is None and args.classes == old and out != src:
        raise SystemExit("self-check failed: same-class rebuild differs from source")
    errors = nm.validate(out)
    if errors:
        raise SystemExit("variant invalid: " + "; ".join(errors))
    args.output.write_bytes(out)
    layout = "" if slots is None else f" slots={slots}"
    print(f"NPU_CLASS_VARIANT classes={args.classes} bytes={len(out)} "
          f"crc=0x{nm.read_header(out)['payload_crc']:08X}{layout}")
    return 0


def load_expected(path: Path) -> list[tuple[int, int, int, int]]:
    return [tuple(int(v) for v in line.split()) for line in path.read_text().splitlines() if line.strip()]


def cmd_select(args: argparse.Namespace) -> int:
    """Pick a small ROI subset from a reference directory (golden or smoke)."""
    expected = load_expected(args.reference_dir / "expected32.txt")
    in32 = (args.reference_dir / "inputs32.bin").read_bytes()
    in96 = (args.reference_dir / "inputs96.bin").read_bytes()
    if len(in32) != len(expected) * 4096 or len(in96) != len(expected) * 36864:
        raise SystemExit("reference inputs do not match expected rows")
    if args.golden:
        picked: list[int] = []
        seen: set[int] = set()
        for index, row in enumerate(expected):
            if row[0] not in seen:
                seen.add(row[0])
                picked.append(index)
        for index in range(len(expected)):
            if len(picked) >= args.count:
                break
            if index not in picked:
                picked.append(index)
        picked.sort()
    else:
        picked = list(range(min(args.count, len(expected))))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "in32.bin").write_bytes(b"".join(in32[i * 4096:(i + 1) * 4096] for i in picked))
    (args.output_dir / "in96.bin").write_bytes(b"".join(in96[i * 36864:(i + 1) * 36864] for i in picked))
    (args.output_dir / "expected.txt").write_text(
        "".join("%d %d %d %d\n" % expected[i] for i in picked), encoding="ascii")
    classes = sorted({expected[i][0] for i in picked})
    print(f"NPU_CLASS_SELECT rois={len(picked)} indices={picked} classes={classes}")
    return 0


def cmd_verify(args: argparse.Namespace) -> int:
    """Check with the Python reference that variants answer exactly like the source."""
    src, src_layers = ref.read_model(args.source)
    inputs = args.inputs.read_bytes()
    expected = load_expected(args.expected)
    count = len(inputs) // 4096
    if count != len(expected):
        raise SystemExit("inputs and expected rows differ in count")
    base = [ref.infer(src, src_layers, inputs[i * 4096:(i + 1) * 4096]) for i in range(count)]
    for i in range(count):
        if base[i] != expected[i]:
            raise SystemExit(f"source model disagrees with expected at ROI {i}: {base[i]} vs {expected[i]}")
    for variant in args.variants:
        package, layers = ref.read_model(variant)
        for i in range(count):
            got = ref.infer(package, layers, inputs[i * 4096:(i + 1) * 4096])
            if got != base[i]:
                raise SystemExit(f"{variant.name} differs at ROI {i}: {got} vs {base[i]}")
    note = ""
    if args.remapped is not None:
        package, layers = ref.read_model(args.remapped)
        classes = nm.read_header(args.remapped.read_bytes())["class_count"]
        slots = winner_slots([row[0] for row in expected], nm.read_header(args.source.read_bytes())["class_count"], classes)
        mapped = [(slots[row[0]],) + tuple(row[1:]) for row in base]
        for i in range(count):
            got = ref.infer(package, layers, inputs[i * 4096:(i + 1) * 4096])
            if got != mapped[i]:
                raise SystemExit(f"{args.remapped.name} differs at ROI {i}: {got} vs {mapped[i]}")
        if args.write_expected is not None:
            args.write_expected.write_text("".join("%d %d %d %d\n" % row for row in mapped), encoding="ascii")
        high = sorted({row[0] for row in mapped if row[0] >= 11})
        if 15 not in high:
            raise SystemExit(f"no ROI wins in slot 15 (winner slots >= 11: {high})")
        note = f" remapped=1 winner_slots_ge11={high}"
    print(f"NPU_CLASS_VERIFY_PASS rois={count} variants={len(args.variants)}{note}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("--source", type=Path, required=True)
    build.add_argument("--classes", type=int, required=True)
    build.add_argument("--output", type=Path, required=True)
    build.add_argument("--winners-from", type=Path, default=None,
                       help="expected file; classes that win there take the highest slots")
    build.set_defaults(function=cmd_build)
    select = sub.add_parser("select")
    select.add_argument("--reference-dir", type=Path, required=True)
    select.add_argument("--output-dir", type=Path, required=True)
    select.add_argument("--count", type=int, default=14)
    select.add_argument("--golden", action="store_true")
    select.set_defaults(function=cmd_select)
    verify = sub.add_parser("verify")
    verify.add_argument("--source", type=Path, required=True)
    verify.add_argument("--inputs", type=Path, required=True)
    verify.add_argument("--expected", type=Path, required=True)
    verify.add_argument("--remapped", type=Path, default=None,
                        help="variant built with --winners-from from the same expected file")
    verify.add_argument("--write-expected", type=Path, default=None,
                        help="write the expected rows of the remapped variant (class = slot)")
    verify.add_argument("variants", type=Path, nargs="+")
    verify.set_defaults(function=cmd_verify)
    args = parser.parse_args()
    return args.function(args)


if __name__ == "__main__":
    raise SystemExit(main())
