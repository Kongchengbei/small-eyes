#!/usr/bin/env python3
"""Build, inspect, and validate the candidate NPU-CNN V1 model package.

The package layout is intentionally shared by model tooling, reference tests,
and the future RTL model fetcher. All integers are little-endian and all
payload offsets are relative to the package base address.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from dataclasses import dataclass
from pathlib import Path


ALIGN = 32
HEADER_BYTES = 128
DESC_BYTES = 64
MAGIC = 0x3155504E  # bytes: NPU1
PACKAGE_VERSION = 1
INTERFACE_VERSION = 1
LAYOUT_CHW = 1
LAYOUT_HWC4 = 2
COLOR_RGB = 1
SIGNED_INT8 = 1

OP_CONV2D = 1
OP_RELU = 2
OP_MAXPOOL = 3
OP_GAP = 4
OP_FC = 5
OP_ARGMAX = 6


def align(value: int, boundary: int = ALIGN) -> int:
    return (value + boundary - 1) // boundary * boundary


def signed_byte(value: int) -> int:
    if not -128 <= value <= 127:
        raise ValueError(f"signed INT8 out of range: {value}")
    return value & 0xFF


@dataclass
class Layer:
    op: int
    input_shape: tuple[int, int, int]
    output_shape: tuple[int, int, int]
    kernel: tuple[int, int] = (1, 1)
    stride: tuple[int, int] = (1, 1)
    padding: tuple[int, int, int, int] = (0, 0, 0, 0)
    input_slot: int = 0
    output_slot: int = 1
    weight_offset: int = 0
    bias_offset: int = 0
    weight_bytes: int = 0
    bias_bytes: int = 0
    multiplier: int = 1
    shift: int = 0
    input_zero_point: int = 0
    weight_zero_point: int = 0
    output_zero_point: int = 0
    activation: int = 0


def put_u16(buf: bytearray, offset: int, value: int) -> None:
    struct.pack_into("<H", buf, offset, value)


def put_u32(buf: bytearray, offset: int, value: int) -> None:
    struct.pack_into("<I", buf, offset, value)


def put_i32(buf: bytearray, offset: int, value: int) -> None:
    struct.pack_into("<i", buf, offset, value)


def get_u16(buf: bytes, offset: int) -> int:
    return struct.unpack_from("<H", buf, offset)[0]


def get_u32(buf: bytes, offset: int) -> int:
    return struct.unpack_from("<I", buf, offset)[0]


def get_i32(buf: bytes, offset: int) -> int:
    return struct.unpack_from("<i", buf, offset)[0]


def encode_layer(layer: Layer) -> bytes:
    buf = bytearray(DESC_BYTES)
    buf[0] = layer.op
    buf[1] = layer.activation
    for offset, value in zip((2, 4, 6), layer.input_shape):
        put_u16(buf, offset, value)
    for offset, value in zip((8, 10, 12), layer.output_shape):
        put_u16(buf, offset, value)
    buf[14:18] = bytes((*layer.kernel, *layer.stride))
    buf[18:22] = bytes(layer.padding)
    buf[22] = layer.input_slot
    buf[23] = layer.output_slot
    put_u32(buf, 0x20, layer.weight_offset)
    put_u32(buf, 0x24, layer.bias_offset)
    put_u32(buf, 0x28, layer.weight_bytes)
    put_u32(buf, 0x2C, layer.bias_bytes)
    put_i32(buf, 0x30, layer.multiplier)
    buf[0x34] = signed_byte(layer.shift)
    buf[0x35] = signed_byte(layer.input_zero_point)
    buf[0x36] = signed_byte(layer.weight_zero_point)
    buf[0x37] = signed_byte(layer.output_zero_point)
    buf[0x38] = layer.activation
    return bytes(buf)


def decode_layer(buf: bytes, offset: int) -> Layer:
    desc = buf[offset : offset + DESC_BYTES]
    if len(desc) != DESC_BYTES:
        raise ValueError("truncated layer descriptor")

    def s8(value: int) -> int:
        return value - 256 if value & 0x80 else value

    return Layer(
        op=desc[0],
        input_shape=(get_u16(desc, 2), get_u16(desc, 4), get_u16(desc, 6)),
        output_shape=(get_u16(desc, 8), get_u16(desc, 10), get_u16(desc, 12)),
        kernel=(desc[14], desc[15]),
        stride=(desc[16], desc[17]),
        padding=tuple(desc[18:22]),
        input_slot=desc[22],
        output_slot=desc[23],
        weight_offset=get_u32(desc, 0x20),
        bias_offset=get_u32(desc, 0x24),
        weight_bytes=get_u32(desc, 0x28),
        bias_bytes=get_u32(desc, 0x2C),
        multiplier=get_i32(desc, 0x30),
        shift=s8(desc[0x34]),
        input_zero_point=s8(desc[0x35]),
        weight_zero_point=s8(desc[0x36]),
        output_zero_point=s8(desc[0x37]),
        activation=desc[0x38],
    )


def build_header(*, input_shape: tuple[int, int, int], layer_count: int,
                 class_count: int, descriptor_offset: int,
                 descriptor_bytes: int, weight_offset: int, weight_bytes: int,
                 bias_offset: int, bias_bytes: int, total_bytes: int,
                 scratch_bytes: int, input_bytes: int, input_stride: int,
                 payload_crc: int, category_version: int = 0,
                 layout: int = LAYOUT_CHW,
                 margin_threshold: int = 0) -> bytes:
    buf = bytearray(HEADER_BYTES)
    put_u32(buf, 0x00, MAGIC)
    put_u16(buf, 0x04, PACKAGE_VERSION)
    put_u16(buf, 0x06, INTERFACE_VERSION)
    put_u16(buf, 0x08, HEADER_BYTES)
    put_u16(buf, 0x0A, DESC_BYTES)
    put_u16(buf, 0x0C, input_shape[0])
    put_u16(buf, 0x0E, input_shape[1])
    put_u16(buf, 0x10, input_shape[2])
    buf[0x12] = layout
    buf[0x13] = COLOR_RGB
    buf[0x14] = SIGNED_INT8
    buf[0x15] = layer_count
    buf[0x16] = class_count
    put_u32(buf, 0x18, descriptor_offset)
    put_u32(buf, 0x1C, descriptor_bytes)
    put_u32(buf, 0x20, weight_offset)
    put_u32(buf, 0x24, weight_bytes)
    put_u32(buf, 0x28, bias_offset)
    put_u32(buf, 0x2C, bias_bytes)
    put_u32(buf, 0x30, total_bytes)
    put_u32(buf, 0x34, scratch_bytes)
    put_u32(buf, 0x38, input_bytes)
    put_u32(buf, 0x3C, input_stride)
    put_u32(buf, 0x40, payload_crc)
    put_u32(buf, 0x48, category_version)
    put_u32(buf, 0x4C, margin_threshold)
    return bytes(buf)


def make_demo_package() -> bytes:
    """Create a tiny deterministic CNN package for RTL and parser tests."""
    input_shape = (4, 4, 1)
    class_count = 4
    layers: list[Layer] = []
    weights = bytearray()
    biases = bytearray()

    def add_weights(values: list[int]) -> tuple[int, int]:
        aligned = align(len(weights))
        weights.extend(bytes(aligned - len(weights)))
        offset = len(weights)
        values_bytes = bytes(signed_byte(v) for v in values)
        weights.extend(values_bytes)
        return offset, len(values_bytes)

    def add_bias(values: list[int]) -> tuple[int, int]:
        aligned = align(len(biases))
        biases.extend(bytes(aligned - len(biases)))
        offset = len(biases)
        for value in values:
            biases.extend(struct.pack("<i", value))
        return offset, len(values) * 4

    # Offsets are finalized after the package sections are placed.
    conv_weights = [1, -1]
    conv_weight_local, conv_weight_bytes = add_weights(conv_weights)
    conv_bias_local, conv_bias_bytes = add_bias([0, 1])
    layers.append(Layer(OP_CONV2D, input_shape, (4, 4, 2), kernel=(1, 1),
                        weight_bytes=conv_weight_bytes, bias_bytes=conv_bias_bytes))
    layers.append(Layer(OP_RELU, (4, 4, 2), (4, 4, 2)))
    layers.append(Layer(OP_MAXPOOL, (4, 4, 2), (2, 2, 2), kernel=(2, 2),
                        stride=(2, 2)))
    layers.append(Layer(OP_GAP, (2, 2, 2), (1, 1, 2)))
    fc_weights = [1, 0, 0, 1, -1, 1, 1, -1]
    fc_weight_local, fc_weight_bytes = add_weights(fc_weights)
    fc_bias_local, fc_bias_bytes = add_bias([0, 0, 1, -1])
    layers.append(Layer(OP_FC, (1, 1, 2), (1, 1, class_count),
                        weight_bytes=fc_weight_bytes, bias_bytes=fc_bias_bytes))
    layers.append(Layer(OP_ARGMAX, (1, 1, class_count),
                        (1, 1, class_count)))

    descriptor_offset = HEADER_BYTES
    descriptor_total = align(len(layers) * DESC_BYTES)
    weight_offset = align(descriptor_offset + descriptor_total)
    bias_offset = align(weight_offset + len(weights))
    total_bytes = align(bias_offset + len(biases))
    scratch_bytes = 2 * align(4 * 4 * 2)

    for layer in layers:
        if layer.weight_bytes:
            layer.weight_offset = weight_offset + (conv_weight_local if layer is layers[0] else fc_weight_local)
        if layer.bias_bytes:
            layer.bias_offset = bias_offset + (conv_bias_local if layer is layers[0] else fc_bias_local)

    descriptors = b"".join(encode_layer(layer) for layer in layers)
    descriptors += bytes(descriptor_total - len(descriptors))
    payload = descriptors + bytes(weight_offset - descriptor_offset - len(descriptors)) + bytes(weights)
    payload += bytes(bias_offset - weight_offset - len(weights)) + bytes(biases)
    payload += bytes(total_bytes - bias_offset - len(biases))
    payload_crc = zlib.crc32(payload) & 0xFFFFFFFF
    header = build_header(
        input_shape=input_shape, layer_count=len(layers), class_count=class_count,
        descriptor_offset=descriptor_offset, descriptor_bytes=descriptor_total,
        weight_offset=weight_offset, weight_bytes=len(weights),
        bias_offset=bias_offset, bias_bytes=len(biases), total_bytes=total_bytes,
        # The tensor has 16 meaningful bytes, but the DMA contract is one
        # 32-byte beat.  The remaining bytes are explicit zero padding.
        scratch_bytes=scratch_bytes, input_bytes=32, input_stride=32,
        payload_crc=payload_crc,
    )
    return header + payload


def make_96_demo_package() -> bytes:
    """Create a small 96x96 HWC4 package for the A-side data-path tests.

    This is deliberately a deterministic demonstration package, not B's
    trained road-sign model. It exercises the production input contract and
    keeps the simulation short enough to run in every checkout.
    """
    input_shape = (96, 96, 4)
    class_count = 2
    layers: list[Layer] = []
    weights = bytearray()
    biases = bytearray()

    def add_blob(buf: bytearray, raw: bytes) -> tuple[int, int]:
        local = align(len(buf))
        buf.extend(bytes(local - len(buf)))
        offset = len(buf)
        buf.extend(raw)
        return offset, len(raw)

    conv_local, conv_bytes = add_blob(weights, bytes((1, 0, 0, 0, 0, 1, 0, 0)))
    conv_bias_local, conv_bias_bytes = add_blob(biases, struct.pack("<ii", 0, 0))
    layers.append(Layer(
        OP_CONV2D, input_shape, (96, 96, 2), kernel=(1, 1),
        weight_bytes=conv_bytes, bias_bytes=conv_bias_bytes,
    ))
    layers.append(Layer(OP_GAP, (96, 96, 2), (1, 1, 2)))
    fc_local, fc_bytes = add_blob(weights, bytes((1, 0, 0, 1)))
    fc_bias_local, fc_bias_bytes = add_blob(biases, struct.pack("<ii", 0, 0))
    layers.append(Layer(
        OP_FC, (1, 1, 2), (1, 1, class_count),
        weight_bytes=fc_bytes, bias_bytes=fc_bias_bytes,
    ))
    layers.append(Layer(OP_ARGMAX, (1, 1, class_count), (1, 1, class_count)))

    descriptor_offset = HEADER_BYTES
    descriptor_total = align(len(layers) * DESC_BYTES)
    weight_offset = align(descriptor_offset + descriptor_total)
    bias_offset = align(weight_offset + len(weights))
    total_bytes = align(bias_offset + len(biases))
    scratch_bytes = 2 * align(96 * 96 * 2)
    for layer in layers:
        if layer is layers[0]:
            layer.weight_offset = weight_offset + conv_local
            layer.bias_offset = bias_offset + conv_bias_local
        elif layer.op == OP_FC:
            layer.weight_offset = weight_offset + fc_local
            layer.bias_offset = bias_offset + fc_bias_local

    descriptors = b"".join(encode_layer(layer) for layer in layers)
    descriptors += bytes(descriptor_total - len(descriptors))
    payload = descriptors
    payload += bytes(weight_offset - descriptor_offset - len(descriptors))
    payload += bytes(weights)
    payload += bytes(bias_offset - weight_offset - len(weights))
    payload += bytes(biases)
    payload += bytes(total_bytes - bias_offset - len(biases))
    payload_crc = zlib.crc32(payload) & 0xFFFFFFFF
    header = build_header(
        input_shape=input_shape, layer_count=len(layers), class_count=class_count,
        descriptor_offset=descriptor_offset, descriptor_bytes=descriptor_total,
        weight_offset=weight_offset, weight_bytes=len(weights),
        bias_offset=bias_offset, bias_bytes=len(biases), total_bytes=total_bytes,
        scratch_bytes=scratch_bytes, input_bytes=96 * 96 * 4,
        input_stride=96 * 96 * 4, payload_crc=payload_crc,
        layout=LAYOUT_HWC4,
    )
    return header + payload


def make_32_demo_package() -> bytes:
    """Create a 32x32 HWC4 package for the image-service contract.

    The DDR-side image is still 96x96x4.  Hnpu_cnn_engine performs the
    (y,x)=(0,3,6,...) decimation before this package sees the tensor.
    """
    input_shape = (32, 32, 4)
    class_count = 2
    layers: list[Layer] = []
    weights = bytearray()
    biases = bytearray()

    def add_blob(buf: bytearray, raw: bytes) -> tuple[int, int]:
        local = align(len(buf))
        buf.extend(bytes(local - len(buf)))
        offset = len(buf)
        buf.extend(raw)
        return offset, len(raw)

    conv_local, conv_bytes = add_blob(weights, bytes((1, 0, 0, 0, 0, 1, 0, 0)))
    conv_bias_local, conv_bias_bytes = add_blob(biases, struct.pack("<ii", 0, 0))
    layers.append(Layer(
        OP_CONV2D, input_shape, (32, 32, 2), kernel=(1, 1),
        weight_bytes=conv_bytes, bias_bytes=conv_bias_bytes,
    ))
    layers.append(Layer(OP_GAP, (32, 32, 2), (1, 1, 2)))
    fc_local, fc_bytes = add_blob(weights, bytes((1, 0, 0, 1)))
    fc_bias_local, fc_bias_bytes = add_blob(biases, struct.pack("<ii", 0, 0))
    layers.append(Layer(
        OP_FC, (1, 1, 2), (1, 1, class_count),
        weight_bytes=fc_bytes, bias_bytes=fc_bias_bytes,
    ))
    layers.append(Layer(OP_ARGMAX, (1, 1, class_count), (1, 1, class_count)))

    descriptor_offset = HEADER_BYTES
    descriptor_total = align(len(layers) * DESC_BYTES)
    weight_offset = align(descriptor_offset + descriptor_total)
    bias_offset = align(weight_offset + len(weights))
    total_bytes = align(bias_offset + len(biases))
    scratch_bytes = 2 * align(32 * 32 * 2)
    for layer in layers:
        if layer is layers[0]:
            layer.weight_offset = weight_offset + conv_local
            layer.bias_offset = bias_offset + conv_bias_local
        elif layer.op == OP_FC:
            layer.weight_offset = weight_offset + fc_local
            layer.bias_offset = bias_offset + fc_bias_local

    descriptors = b"".join(encode_layer(layer) for layer in layers)
    descriptors += bytes(descriptor_total - len(descriptors))
    payload = descriptors
    payload += bytes(weight_offset - descriptor_offset - len(descriptors))
    payload += bytes(weights)
    payload += bytes(bias_offset - weight_offset - len(weights))
    payload += bytes(biases)
    payload += bytes(total_bytes - bias_offset - len(biases))
    payload_crc = zlib.crc32(payload) & 0xFFFFFFFF
    header = build_header(
        input_shape=input_shape, layer_count=len(layers), class_count=class_count,
        descriptor_offset=descriptor_offset, descriptor_bytes=descriptor_total,
        weight_offset=weight_offset, weight_bytes=len(weights),
        bias_offset=bias_offset, bias_bytes=len(biases), total_bytes=total_bytes,
        scratch_bytes=scratch_bytes, input_bytes=32 * 32 * 4,
        input_stride=32 * 32 * 4, payload_crc=payload_crc,
        layout=LAYOUT_HWC4,
    )
    return header + payload


def make_road_model(source: Path) -> bytes:
    """Build the model package described by B's S32 v0.1 golden directory."""
    meta = json.loads((source / "model.json").read_text(encoding="utf-8-sig"))
    input_size = int(meta["input"]["size"])
    if "HWC4 int8" not in meta["input"]["layout"] or "R,G,B,0" not in meta["input"]["layout"]:
        raise ValueError("unsupported road-model input layout")
    if meta["input"]["value"] != "u8 XOR 0x80 = u8-128":
        raise ValueError("unsupported road-model input quantization")

    input_shape = (input_size, input_size, 4)
    class_count = len(meta["classes"])
    layers: list[Layer] = []
    weights = bytearray()
    biases = bytearray()

    def add_blob(buf: bytearray, raw: bytes) -> tuple[int, int]:
        local = align(len(buf))
        buf.extend(bytes(local - len(buf)))
        offset = len(buf)
        buf.extend(raw)
        return offset, len(raw)

    h, w, c = input_shape
    for index, spec in enumerate(meta["layers"], start=1):
        shape = tuple(spec["weight_shape"])
        out_c, kh, kw, in_c = shape
        if (kh, kw) != (3, 3) or in_c != c:
            raise ValueError(f"L{index}: weight shape does not match preceding tensor")
        weight_raw = (source / f"L{index}_w.bin").read_bytes()
        bias_raw = (source / f"L{index}_b.bin").read_bytes()
        expected_weight = out_c * kh * kw * in_c
        expected_bias = out_c * 4
        if len(weight_raw) != expected_weight or len(bias_raw) != expected_bias:
            raise ValueError(f"L{index}: binary size does not match model.json")
        weight_local, weight_bytes = add_blob(weights, weight_raw)
        bias_local, bias_bytes = add_blob(biases, bias_raw)
        layers.append(Layer(
            OP_CONV2D, (h, w, c), (h, w, out_c), kernel=(3, 3),
            stride=(1, 1), padding=(1, 1, 1, 1),
            weight_bytes=weight_bytes, bias_bytes=bias_bytes,
            multiplier=1, shift=int(spec["shift"]),
            input_zero_point=0, weight_zero_point=0, output_zero_point=0,
            activation=0x03,  # bit0: clamp/ReLU, bit1: bias-includes-rounding
        ))
        c = out_c
        if spec.get("pool_after", False):
            if h % 2 or w % 2:
                raise ValueError(f"L{index}: pooling requires even spatial shape")
            layers.append(Layer(
                OP_MAXPOOL, (h, w, c), (h // 2, w // 2, c),
                kernel=(2, 2), stride=(2, 2), padding=(0, 0, 0, 0),
            ))
            h //= 2
            w //= 2

    gap_round4 = h == 4 and w == 4
    layers.append(Layer(
        OP_GAP, (h, w, c), (1, 1, c), kernel=(h, w),
        activation=0x04 if gap_round4 else 0,
    ))

    fc_weight_raw = (source / "FC_w.bin").read_bytes()
    fc_bias_raw = (source / "FC_b.bin").read_bytes()
    if len(fc_weight_raw) != class_count * c or len(fc_bias_raw) != class_count * 4:
        raise ValueError("FC binary size does not match model.json")
    fc_weight_local, fc_weight_bytes = add_blob(weights, fc_weight_raw)
    fc_bias_local, fc_bias_bytes = add_blob(biases, fc_bias_raw)
    layers.append(Layer(
        OP_FC, (1, 1, c), (1, 1, class_count),
        weight_bytes=fc_weight_bytes, bias_bytes=fc_bias_bytes,
    ))
    layers.append(Layer(
        OP_ARGMAX, (1, 1, class_count), (1, 1, class_count),
    ))

    descriptor_offset = HEADER_BYTES
    descriptor_total = align(len(layers) * DESC_BYTES)
    weight_offset = align(descriptor_offset + descriptor_total)
    bias_offset = align(weight_offset + len(weights))
    total_bytes = align(bias_offset + len(biases))
    scratch_bytes = 2 * align(h * w * c)

    # Rebuild the section-local offsets deterministically after descriptors exist.
    weight_locals: list[int] = []
    bias_locals: list[int] = []
    temp_w = bytearray()
    temp_b = bytearray()
    for index, spec in enumerate(meta["layers"], start=1):
        weight_locals.append(align(len(temp_w)))
        temp_w.extend(bytes(weight_locals[-1] - len(temp_w)))
        temp_w.extend((source / f"L{index}_w.bin").read_bytes())
        bias_locals.append(align(len(temp_b)))
        temp_b.extend(bytes(bias_locals[-1] - len(temp_b)))
        temp_b.extend((source / f"L{index}_b.bin").read_bytes())
    weight_locals.append(align(len(temp_w)))
    temp_w.extend(bytes(weight_locals[-1] - len(temp_w)))
    temp_w.extend(fc_weight_raw)
    bias_locals.append(align(len(temp_b)))
    temp_b.extend(bytes(bias_locals[-1] - len(temp_b)))
    temp_b.extend(fc_bias_raw)

    conv_index = 0
    for layer in layers:
        if layer.op == OP_CONV2D:
            layer.weight_offset = weight_offset + weight_locals[conv_index]
            layer.bias_offset = bias_offset + bias_locals[conv_index]
            conv_index += 1
        elif layer.op == OP_FC:
            layer.weight_offset = weight_offset + weight_locals[-1]
            layer.bias_offset = bias_offset + bias_locals[-1]

    descriptors = b"".join(encode_layer(layer) for layer in layers)
    descriptors += bytes(descriptor_total - len(descriptors))
    payload = descriptors
    payload += bytes(weight_offset - descriptor_offset - len(descriptors))
    payload += bytes(temp_w)
    payload += bytes(bias_offset - weight_offset - len(temp_w))
    payload += bytes(temp_b)
    payload += bytes(total_bytes - bias_offset - len(temp_b))
    payload_crc = zlib.crc32(payload) & 0xFFFFFFFF
    header = build_header(
        input_shape=input_shape, layer_count=len(layers), class_count=class_count,
        descriptor_offset=descriptor_offset, descriptor_bytes=descriptor_total,
        weight_offset=weight_offset, weight_bytes=len(temp_w),
        bias_offset=bias_offset, bias_bytes=len(temp_b), total_bytes=total_bytes,
        scratch_bytes=scratch_bytes, input_bytes=input_size * input_size * 4,
        input_stride=input_size * input_size * 4, payload_crc=payload_crc,
        layout=LAYOUT_HWC4,
        margin_threshold=int(meta["margin_threshold_counts"]),
    )
    return header + payload


def read_header(data: bytes) -> dict[str, int]:
    if len(data) < HEADER_BYTES:
        raise ValueError("model package is shorter than header")
    return {
        "magic": get_u32(data, 0x00),
        "package_version": get_u16(data, 0x04),
        "interface_version": get_u16(data, 0x06),
        "header_bytes": get_u16(data, 0x08),
        "descriptor_bytes": get_u16(data, 0x0A),
        "input_h": get_u16(data, 0x0C),
        "input_w": get_u16(data, 0x0E),
        "input_c": get_u16(data, 0x10),
        "layout": data[0x12],
        "color": data[0x13],
        "signedness": data[0x14],
        "layer_count": data[0x15],
        "class_count": data[0x16],
        "descriptor_offset": get_u32(data, 0x18),
        "descriptor_total_bytes": get_u32(data, 0x1C),
        "weight_offset": get_u32(data, 0x20),
        "weight_bytes": get_u32(data, 0x24),
        "bias_offset": get_u32(data, 0x28),
        "bias_bytes": get_u32(data, 0x2C),
        "total_bytes": get_u32(data, 0x30),
        "scratch_bytes": get_u32(data, 0x34),
        "input_bytes": get_u32(data, 0x38),
        "input_stride": get_u32(data, 0x3C),
        "payload_crc": get_u32(data, 0x40),
        "category_version": get_u32(data, 0x48),
        "margin_threshold": get_u32(data, 0x4C),
    }


def validate(data: bytes) -> list[str]:
    errors: list[str] = []
    try:
        h = read_header(data)
    except ValueError as exc:
        return [str(exc)]
    if h["magic"] != MAGIC:
        errors.append("bad magic")
    if h["package_version"] != PACKAGE_VERSION:
        errors.append("unsupported package version")
    if h["interface_version"] != INTERFACE_VERSION:
        errors.append("unsupported interface version")
    if h["header_bytes"] != HEADER_BYTES or h["descriptor_bytes"] != DESC_BYTES:
        errors.append("unsupported header or descriptor size")
    if h["layout"] not in {LAYOUT_CHW, LAYOUT_HWC4} or h["color"] != COLOR_RGB or h["signedness"] != SIGNED_INT8:
        errors.append("unsupported input format")
    if h["layout"] == LAYOUT_HWC4 and h["input_c"] != 4:
        errors.append("HWC4 layout requires input_c=4")
    if not 1 <= h["layer_count"] <= 64:
        errors.append("layer count out of range")
    if not 1 <= h["class_count"] <= 255:
        errors.append("class count out of range")
    if h["total_bytes"] != len(data):
        errors.append("total bytes does not match file size")
    if h["input_bytes"] == 0 or h["input_bytes"] % ALIGN:
        errors.append("input bytes is not a non-zero 32-byte multiple")
    if h["input_stride"] < h["input_bytes"] or h["input_stride"] % ALIGN:
        errors.append("input stride is smaller than input bytes or not aligned")
    for label in ("descriptor_offset", "descriptor_total_bytes", "weight_offset", "bias_offset"):
        if h[label] % ALIGN:
            errors.append(f"{label} is not 32-byte aligned")
    for label in ("descriptor_offset", "weight_offset", "bias_offset"):
        if h[label] > len(data):
            errors.append(f"{label} is outside package")
    if h["descriptor_offset"] + h["descriptor_total_bytes"] > len(data):
        errors.append("descriptor range exceeds package")
    if h["descriptor_offset"] != HEADER_BYTES:
        errors.append("unsupported descriptor offset")
    if h["descriptor_total_bytes"] < h["layer_count"] * DESC_BYTES:
        errors.append("descriptor table is shorter than layer count")
    descriptor_end = h["descriptor_offset"] + h["descriptor_total_bytes"]
    weight_end = h["weight_offset"] + h["weight_bytes"]
    bias_end = h["bias_offset"] + h["bias_bytes"]
    if h["weight_offset"] < descriptor_end:
        errors.append("weight section overlaps descriptor table")
    if h["bias_offset"] < weight_end:
        errors.append("bias section overlaps weight section")
    if weight_end > len(data):
        errors.append("weight range exceeds package")
    if bias_end > len(data):
        errors.append("bias range exceeds package")
    if h["payload_crc"]:
        payload = data[HEADER_BYTES:]
        if zlib.crc32(payload) & 0xFFFFFFFF != h["payload_crc"]:
            errors.append("payload CRC mismatch")
    expected_shape = (h["input_h"], h["input_w"], h["input_c"])
    for index in range(h["layer_count"]):
        offset = h["descriptor_offset"] + index * DESC_BYTES
        try:
            layer = decode_layer(data, offset)
        except ValueError as exc:
            errors.append(f"layer {index}: {exc}")
            continue
        if layer.op not in {OP_CONV2D, OP_RELU, OP_MAXPOOL, OP_GAP, OP_FC, OP_ARGMAX}:
            errors.append(f"layer {index}: unsupported op {layer.op}")
        if any(value == 0 for value in (*layer.input_shape, *layer.output_shape)):
            errors.append(f"layer {index}: zero shape")
        if layer.input_shape != expected_shape:
            errors.append(f"layer {index}: input shape {layer.input_shape} does not follow {expected_shape}")
        if not 0 <= layer.shift <= 31:
            errors.append(f"layer {index}: shift outside 0..31")
        if layer.weight_bytes and layer.weight_offset % ALIGN:
            errors.append(f"layer {index}: weight offset is not aligned")
        if layer.bias_bytes and layer.bias_offset % ALIGN:
            errors.append(f"layer {index}: bias offset is not aligned")
        if layer.weight_bytes:
            layer_weight_end = layer.weight_offset + layer.weight_bytes
            if layer.weight_offset < h["weight_offset"] or layer_weight_end > weight_end:
                errors.append(f"layer {index}: weight range is outside weight section")
        elif layer.weight_offset:
            errors.append(f"layer {index}: weight offset must be zero when weight_bytes is zero")
        if layer.bias_bytes:
            layer_bias_end = layer.bias_offset + layer.bias_bytes
            if layer.bias_offset < h["bias_offset"] or layer_bias_end > bias_end:
                errors.append(f"layer {index}: bias range is outside bias section")
        elif layer.bias_offset:
            errors.append(f"layer {index}: bias offset must be zero when bias_bytes is zero")
        ih, iw, ic = layer.input_shape
        oh, ow, oc = layer.output_shape
        if layer.op == OP_CONV2D:
            kh, kw = layer.kernel
            sh, sw = layer.stride
            if kh == 0 or kw == 0 or sh == 0 or sw == 0:
                errors.append(f"layer {index}: invalid convolution parameters")
            elif (oh, ow) != ((ih + layer.padding[0] + layer.padding[2] - kh) // sh + 1,
                              (iw + layer.padding[1] + layer.padding[3] - kw) // sw + 1):
                errors.append(f"layer {index}: convolution output shape mismatch")
            if layer.weight_bytes != oh * 0 + oc * kh * kw * ic:
                errors.append(f"layer {index}: convolution weight size mismatch")
            if layer.bias_bytes != oc * 4:
                errors.append(f"layer {index}: convolution bias size mismatch")
        elif layer.op == OP_MAXPOOL:
            kh, kw = layer.kernel
            sh, sw = layer.stride
            if kh == 0 or kw == 0 or sh == 0 or sw == 0:
                errors.append(f"layer {index}: invalid pooling parameters")
            elif (oh, ow, oc) != ((ih - kh) // sh + 1, (iw - kw) // sw + 1, ic):
                errors.append(f"layer {index}: pool output shape mismatch")
            if layer.weight_bytes or layer.bias_bytes:
                errors.append(f"layer {index}: pool must not carry parameters")
        elif layer.op == OP_GAP:
            if (oh, ow, oc) != (1, 1, ic):
                errors.append(f"layer {index}: GAP output shape mismatch")
        elif layer.op == OP_FC:
            if (ih, iw) != (1, 1) or layer.weight_bytes != oc * ic or layer.bias_bytes != oc * 4:
                errors.append(f"layer {index}: FC shape or parameter size mismatch")
        elif layer.op == OP_ARGMAX:
            if layer.input_shape != (1, 1, h["class_count"]):
                errors.append(f"layer {index}: Argmax class shape mismatch")
        elif layer.op in {OP_RELU, OP_GAP}:
            if layer.weight_bytes or layer.bias_bytes:
                errors.append(f"layer {index}: activation-only op must not carry parameters")
        expected_shape = layer.output_shape
    if expected_shape != (1, 1, h["class_count"]):
        errors.append("final tensor shape does not match class count")
    return errors


def print_info(data: bytes) -> None:
    header = read_header(data)
    print("NPU_MODEL_INFO")
    for key, value in header.items():
        print(f"{key}={value}")
    for index in range(header["layer_count"]):
        layer = decode_layer(data, header["descriptor_offset"] + index * DESC_BYTES)
        print(
            f"layer={index} op={layer.op} input={layer.input_shape} output={layer.output_shape} "
            f"kernel={layer.kernel} stride={layer.stride} padding={layer.padding} "
            f"weight_offset=0x{layer.weight_offset:x} weight_bytes={layer.weight_bytes} "
            f"bias_offset=0x{layer.bias_offset:x} bias_bytes={layer.bias_bytes} "
            f"shift={layer.shift} flags=0x{layer.activation:02x}"
        )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build-demo")
    build.add_argument("--output", required=True, type=Path)
    demo96 = sub.add_parser("build-demo-96")
    demo96.add_argument("--output", required=True, type=Path)
    demo32 = sub.add_parser("build-demo-32")
    demo32.add_argument("--output", required=True, type=Path)
    road = sub.add_parser("build-road")
    road.add_argument("--source", required=True, type=Path)
    road.add_argument("--output", required=True, type=Path)
    inspect = sub.add_parser("inspect")
    inspect.add_argument("package", type=Path)
    check = sub.add_parser("check")
    check.add_argument("package", type=Path)
    args = parser.parse_args(argv)

    if args.command == "build-demo":
        package = make_demo_package()
        args.output.write_bytes(package)
        print(f"NPU_MODEL_BUILD_PASS bytes={len(package)} output={args.output}")
        return 0
    if args.command == "build-demo-96":
        package = make_96_demo_package()
        args.output.write_bytes(package)
        print(f"NPU_MODEL_BUILD_PASS bytes={len(package)} output={args.output}")
        return 0
    if args.command == "build-demo-32":
        package = make_32_demo_package()
        args.output.write_bytes(package)
        print(f"NPU_MODEL_BUILD_PASS bytes={len(package)} output={args.output}")
        return 0
    if args.command == "build-road":
        package = make_road_model(args.source)
        args.output.write_bytes(package)
        print(f"NPU_MODEL_BUILD_PASS bytes={len(package)} output={args.output}")
        return 0
    data = args.package.read_bytes()
    errors = validate(data)
    if args.command == "check":
        if errors:
            for error in errors:
                print(f"NPU_MODEL_ERROR {error}", file=sys.stderr)
            return 1
        print(f"NPU_MODEL_CHECK_PASS bytes={len(data)}")
        return 0
    if errors:
        for error in errors:
            print(f"NPU_MODEL_ERROR {error}")
        return 1
    print_info(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
