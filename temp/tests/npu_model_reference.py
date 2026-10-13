#!/usr/bin/env python3
"""Small, dependency-free reference runner for the delivered model.npu."""

from __future__ import annotations

import argparse
import csv
import struct
from pathlib import Path


OP_CONV2D = 1
OP_RELU = 2
OP_MAXPOOL = 3
OP_GAP = 4
OP_FC = 5
OP_ARGMAX = 6


def u16(data: bytes, offset: int) -> int:
    return struct.unpack_from("<H", data, offset)[0]


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def i32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<i", data, offset)[0]


def s8(value: int) -> int:
    return value - 256 if value & 0x80 else value


def i32_value(value: int) -> int:
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value & 0x80000000 else value


def trunc_zero(value: int, divisor: int) -> int:
    return value // divisor if value >= 0 else -((-value) // divisor)


def read_model(path: Path) -> tuple[bytes, list[dict[str, int]]]:
    data = path.read_bytes()
    layers = []
    layer_count = data[0x15]
    for index in range(layer_count):
        offset = 128 + index * 64
        layers.append(
            {
                "op": data[offset],
                "flags": data[offset + 1],
                "ih": u16(data, offset + 2),
                "iw": u16(data, offset + 4),
                "ic": u16(data, offset + 6),
                "oh": u16(data, offset + 8),
                "ow": u16(data, offset + 10),
                "oc": u16(data, offset + 12),
                "kh": data[offset + 14],
                "kw": data[offset + 15],
                "sh": data[offset + 16],
                "sw": data[offset + 17],
                "pt": data[offset + 18],
                "pl": data[offset + 19],
                "pb": data[offset + 20],
                "pr": data[offset + 21],
                "weight": u32(data, offset + 32),
                "bias": u32(data, offset + 36),
                "shift": s8(data[offset + 52]),
                "input_zp": s8(data[offset + 53]),
                "weight_zp": s8(data[offset + 54]),
                "output_zp": s8(data[offset + 55]),
                "multiplier": i32(data, offset + 48),
                "weight_bytes": u32(data, offset + 40),
                "bias_bytes": u32(data, offset + 44),
            }
        )
    return data, layers


def requantize(value: int, layer: dict[str, int]) -> int:
    product = value * layer["multiplier"]
    shift = layer["shift"]
    if layer["flags"] & 0x02:
        scaled = product if shift == 0 else product >> shift
    elif shift == 0:
        scaled = product
    elif product < 0:
        scaled = -(((-product) + (1 << (shift - 1))) >> shift)
    else:
        scaled = (product + (1 << (shift - 1))) >> shift
    result = scaled + layer["output_zp"]
    if layer["flags"] & 0x01 and result < layer["output_zp"]:
        result = layer["output_zp"]
    return max(-128, min(127, result))


def conv(data: list[int], layer: dict[str, int], package: bytes) -> list[int]:
    ih, iw, ic = layer["ih"], layer["iw"], layer["ic"]
    oh, ow, oc = layer["oh"], layer["ow"], layer["oc"]
    kh, kw = layer["kh"], layer["kw"]
    weights = [s8(value) for value in package[layer["weight"] : layer["weight"] + layer["weight_bytes"]]]
    biases = [i32(package, layer["bias"] + index * 4) for index in range(oc)]
    output = [0] * (oh * ow * oc)
    kernel_size = kh * kw * ic
    for oy in range(oh):
        for ox in range(ow):
            for out_c in range(oc):
                total = biases[out_c]
                for ky in range(kh):
                    iy = oy * layer["sh"] + ky - layer["pt"]
                    if iy < 0 or iy >= ih:
                        continue
                    for kx in range(kw):
                        ix = ox * layer["sw"] + kx - layer["pl"]
                        if ix < 0 or ix >= iw:
                            continue
                        input_base = (iy * iw + ix) * ic
                        weight_base = out_c * kernel_size + (ky * kw + kx) * ic
                        for in_c in range(ic):
                            total += (
                                data[input_base + in_c] - layer["input_zp"]
                            ) * (
                                weights[weight_base + in_c] - layer["weight_zp"]
                            )
                output[(oy * ow + ox) * oc + out_c] = requantize(total, layer)
    return output


def relu(data: list[int], layer: dict[str, int]) -> list[int]:
    zero_point = layer["output_zp"]
    return [max(zero_point, value) for value in data]


def maxpool(data: list[int], layer: dict[str, int]) -> list[int]:
    ih, iw, ic = layer["ih"], layer["iw"], layer["ic"]
    oh, ow = layer["oh"], layer["ow"]
    output = [0] * (oh * ow * ic)
    for oy in range(oh):
        for ox in range(ow):
            for channel in range(ic):
                values = []
                for ky in range(layer["kh"]):
                    iy = oy * layer["sh"] + ky - layer["pt"]
                    for kx in range(layer["kw"]):
                        ix = ox * layer["sw"] + kx - layer["pl"]
                        if 0 <= iy < ih and 0 <= ix < iw:
                            values.append(data[(iy * iw + ix) * ic + channel])
                output[(oy * ow + ox) * ic + channel] = max(values or [-128])
    return output


def gap(data: list[int], layer: dict[str, int]) -> list[int]:
    count = layer["ih"] * layer["iw"]
    output = []
    for channel in range(layer["ic"]):
        total = sum(data[position * layer["ic"] + channel] for position in range(count))
        if layer["flags"] & 0x04:
            value = (total + 8) >> 4
        else:
            value = trunc_zero(total, count)
        output.append(max(-128, min(127, value)))
    return output


def fully_connected(data: list[int], layer: dict[str, int], package: bytes) -> list[int]:
    features, classes = layer["ic"], layer["oc"]
    weights = [s8(value) for value in package[layer["weight"] : layer["weight"] + layer["weight_bytes"]]]
    output = []
    for out_c in range(classes):
        total = i32(package, layer["bias"] + out_c * 4)
        base = out_c * features
        for feature in range(features):
            total += (data[feature] - layer["input_zp"]) * (
                weights[base + feature] - layer["weight_zp"]
            )
        output.append(i32_value(total))
    return output


def infer(
    package: bytes,
    layers: list[dict[str, int]],
    raw_input: bytes,
    trace: bytearray | None = None,
) -> tuple[int, int, int, int]:
    data = [s8(value) for value in raw_input]
    logits: list[int] | None = None
    for layer in layers:
        if layer["op"] == OP_CONV2D:
            data = conv(data, layer, package)
        elif layer["op"] == OP_RELU:
            data = relu(data, layer)
        elif layer["op"] == OP_MAXPOOL:
            data = maxpool(data, layer)
        elif layer["op"] == OP_GAP:
            data = gap(data, layer)
        elif layer["op"] == OP_FC:
            logits = fully_connected(data, layer, package)
        elif layer["op"] == OP_ARGMAX:
            if logits is None:
                logits = data
        if trace is not None:
            if layer["op"] == OP_FC:
                assert logits is not None
                for score in logits:
                    trace.extend(struct.pack("<i", score))
            elif layer["op"] != OP_ARGMAX:
                trace.extend(value & 0xFF for value in data)
    if logits is None:
        logits = data
    best_class = max(range(len(logits)), key=lambda index: (logits[index], -index))
    best_score = logits[best_class]
    second_score = max((score for index, score in enumerate(logits) if index != best_class), default=best_score)
    margin = max(0, best_score - second_score)
    threshold = u32(package, 0x4C)
    return best_class, margin, int(margin < threshold), best_score


def make_case(case_index: int) -> bytes:
    result = bytearray(32 * 32 * 4)
    for y in range(32):
        for x in range(32):
            base = (y * 32 + x) * 4
            if case_index == 0:
                values = (0, 0, 0, 0)
            elif case_index == 1:
                values = (255, 255, 255, 0)
            elif case_index == 2:
                values = ((x * 7 + y * 13 + 17) & 0xFF,
                          (x * 11 + y * 5 + 43) & 0xFF,
                          (x * 3 + y * 19 + 71) & 0xFF, 0)
            elif case_index == 3:
                band = (x // 4 + y // 4) & 0x07
                values = ((band * 31 + 19) & 0xFF,
                          (band * 17 + 83) & 0xFF,
                          (band * 47 + 5) & 0xFF, 0)
            elif case_index == 4:
                values = (128, 128, 128, 0)  # signed INT8 minimum
            elif case_index == 5:
                values = (127, 127, 127, 0)  # signed INT8 maximum
            elif case_index == 6:
                palette = ((127, 127, 127), (127, 127, 128),
                           (128, 127, 127), (128, 127, 128),
                           (127, 128, 127), (127, 128, 128),
                           (128, 128, 127), (128, 128, 128))
                values = (*palette[x // 4], 0)
            elif case_index == 7:
                value = 127 if (x + y) & 1 else 128
                values = (value, value, value, 0)
            else:
                values = (((x * (case_index + 3) + y * 17 + case_index * 11) & 0xFF),
                          ((x * 13 + y * (case_index + 5) + case_index * 23) & 0xFF),
                          ((x * 7 + y * 19 + case_index * 29) & 0xFF), 0)
            result[base : base + 4] = bytes(values)
    return bytes(result)


def expand_96(image32: bytes) -> bytes:
    result = bytearray(96 * 96 * 4)
    for y in range(32):
        for x in range(32):
            pixel = image32[(y * 32 + x) * 4 : (y * 32 + x + 1) * 4]
            for dy in range(3):
                for dx in range(3):
                    offset = ((y * 3 + dy) * 96 + x * 3 + dx) * 4
                    result[offset : offset + 4] = pixel
    return bytes(result)


def write_expected(path: Path, rows: list[tuple[int, int, int, int]]) -> None:
    path.write_text("".join(f"{c} {m} {r} {s}\n" for c, m, r, s in rows), encoding="ascii")


def generate_smoke(args: argparse.Namespace) -> int:
    package, layers = read_model(args.model)
    inputs32 = bytearray()
    inputs96 = bytearray()
    layer_trace = bytearray() if args.layers else None
    rows = []
    for case_index in range(args.cases):
        image32 = make_case(case_index)
        inputs32.extend(image32)
        inputs96.extend(expand_96(image32))
        rows.append(infer(package, layers, image32, layer_trace))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "inputs32.bin").write_bytes(inputs32)
    (args.output_dir / "inputs96.bin").write_bytes(inputs96)
    if layer_trace is not None:
        (args.output_dir / "layers.bin").write_bytes(layer_trace)
    write_expected(args.output_dir / "expected32.txt", rows)
    write_expected(args.output_dir / "expected96.txt", rows)
    print(f"NPU_REFERENCE_SMOKE_PASS cases={args.cases}")
    return 0


def generate_golden(args: argparse.Namespace) -> int:
    source = args.source
    package, _ = read_model(args.model)
    rows = list(csv.DictReader((source / "golden_output.csv").read_text(encoding="utf-8-sig").splitlines()))
    inputs32 = bytearray()
    inputs96 = bytearray()
    expected = []
    for row in rows:
        name = f"{row['frame']}_roi{row['roi']}"
        inputs32.extend((source / "golden_input" / "rois" / f"{name}.bin").read_bytes())
        image96 = source / "golden_input" / "rois" / f"{name}_96_int8.bin"
        if not image96.exists():
            image96 = source / "golden_input" / "rois" / f"{name}_96.bin"
        inputs96.extend(image96.read_bytes())
        class_id = int(row["class"])
        expected.append((class_id, int(row["margin"]), int(row["reject"]), int(row[f"l{class_id}"])))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "inputs32.bin").write_bytes(inputs32)
    (args.output_dir / "inputs96.bin").write_bytes(inputs96)
    write_expected(args.output_dir / "expected32.txt", expected)
    write_expected(args.output_dir / "expected96.txt", expected)
    print(f"NPU_REFERENCE_GOLDEN_PASS cases={len(rows)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    smoke = sub.add_parser("smoke")
    smoke.add_argument("--model", type=Path, required=True)
    smoke.add_argument("--output-dir", type=Path, required=True)
    smoke.add_argument("--cases", type=int, default=4)
    smoke.add_argument("--layers", action="store_true")
    smoke.set_defaults(function=generate_smoke)
    golden = sub.add_parser("golden")
    golden.add_argument("--model", type=Path, required=True)
    golden.add_argument("--source", type=Path, required=True)
    golden.add_argument("--output-dir", type=Path, required=True)
    golden.set_defaults(function=generate_golden)
    args = parser.parse_args()
    return args.function(args)


if __name__ == "__main__":
    raise SystemExit(main())
