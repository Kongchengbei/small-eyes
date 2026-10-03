#!/usr/bin/env python3
"""Edit SoC build/boot selections and generate C definitions from soc_addr_map.vh.

The Verilog header is the only maintained source for numeric SoC definitions.
This program intentionally parses only a small, arithmetic Verilog-preprocessor
expression subset; it never evaluates source text as Python.
"""

from __future__ import annotations

import argparse
import ast
import curses
import json
import operator
import re
import sys
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / "soc" / "soc_addr_map.vh"
DEFAULT_HEADER = ROOT / "bsp" / "include" / "soc_defs.h"
DEFAULT_ASM = ROOT / "bsp" / "include" / "soc_defs_asm.inc"
DEFAULT_OUTPUT = ROOT / "build" / "menuconfig"

LITERAL_RE = re.compile(
    r"(?<![A-Za-z0-9_])(?:(\d+))?'([sS])?([bBoOdDhH])([0-9a-fA-F_xXzZ?]+)"
)
DEFINE_RE = re.compile(r"^\s*`define\s+([A-Za-z_]\w*)\s+(.+?)\s*$")
EDITABLE = {
    "SOC_CPU_MEM_BRAM",
    "SOC_ENABLE_ICACHE",
    "SOC_ENABLE_DCACHE",
    "SOC_ENABLE_DDR",
    "SOC_ENABLE_CAMERA",
    "SOC_ENABLE_PREPROCESS",
    "SOC_FLASH_BASE",
    "SOC_BOOT_IMAGE_BYTES",
    "SOC_UART_TX_FPIOA",
}

BIN_OPS: dict[type[ast.operator], Callable[[int, int], int]] = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
    ast.LShift: operator.lshift,
    ast.RShift: operator.rshift,
    ast.BitOr: operator.or_,
    ast.BitAnd: operator.and_,
    ast.BitXor: operator.xor,
}
UNARY_OPS: dict[type[ast.unaryop], Callable[[int], int]] = {
    ast.UAdd: operator.pos,
    ast.USub: operator.neg,
    ast.Invert: operator.invert,
}


class ConfigError(Exception):
    pass


def _literal_value(match: re.Match[str]) -> int:
    width, _signed, base_letter, digits = match.groups()
    if any(c in digits.lower() for c in "xz?"):
        raise ConfigError(f"unknown/high-impedance digit is not allowed: {match.group(0)}")
    base = {"b": 2, "o": 8, "d": 10, "h": 16}[base_letter.lower()]
    value = int(digits.replace("_", ""), base)
    if width and int(width) > 0:
        value &= (1 << int(width)) - 1
    return value


def parse_definitions(source: Path) -> dict[str, int]:
    raw: dict[str, str] = {}
    for line_no, line in enumerate(source.read_text(encoding="utf-8").splitlines(), 1):
        line = line.split("//", 1)[0].strip()
        match = DEFINE_RE.match(line)
        if not match:
            continue
        name, expr = match.groups()
        if name in raw:
            raise ConfigError(f"{source}:{line_no}: duplicate definition {name}")
        raw[name] = expr.strip()

    values: dict[str, int] = {}
    resolving: set[str] = set()

    def resolve(name: str) -> int:
        if name in values:
            return values[name]
        if name not in raw:
            raise ConfigError(f"undefined macro {name}")
        if name in resolving:
            raise ConfigError(f"cyclic macro alias/expression involving {name}")
        resolving.add(name)
        try:
            value = evaluate(raw[name], resolve)
            if value < 0:
                raise ConfigError(f"{name} evaluates to negative value {value}")
            values[name] = value
            return value
        finally:
            resolving.remove(name)

    for macro_name in raw:
        resolve(macro_name)
    return values


def evaluate(expr: str, resolve: Callable[[str], int]) -> int:
    expr = LITERAL_RE.sub(lambda m: str(_literal_value(m)), expr)
    expr = re.sub(r"`([A-Za-z_]\w*)", r"\1", expr)
    try:
        tree = ast.parse(expr, mode="eval")
    except SyntaxError as exc:
        raise ConfigError(f"unsupported Verilog expression {expr!r}") from exc

    def visit(node: ast.AST) -> int:
        if isinstance(node, ast.Expression):
            return visit(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, int):
            return node.value
        if isinstance(node, ast.Name):
            return resolve(node.id)
        if isinstance(node, ast.BinOp) and type(node.op) in BIN_OPS:
            left, right = visit(node.left), visit(node.right)
            if isinstance(node.op, (ast.FloorDiv, ast.Mod)) and right == 0:
                raise ConfigError("division by zero in Verilog definition")
            if isinstance(node.op, (ast.LShift, ast.RShift)) and not 0 <= right < 64:
                raise ConfigError("shift count outside supported range 0..63")
            return BIN_OPS[type(node.op)](left, right)
        if isinstance(node, ast.UnaryOp) and type(node.op) in UNARY_OPS:
            return UNARY_OPS[type(node.op)](visit(node.operand))
        raise ConfigError(f"unsupported expression node {type(node).__name__} in {expr!r}")

    return visit(tree)


def validate(values: dict[str, int]) -> None:
    required = {
        "SOC_CPU_MEM_BRAM", "SOC_FLASH_BASE", "SOC_FLASH_ADDRESS_BYTES",
        "SOC_BOOT_IMAGE_BYTES", "SOC_IRAM_BASE", "SOC_IRAM_BYTES",
        "SOC_DRAM_BASE", "SOC_DRAM_BYTES", "SOC_UART_TX_FPIOA",
        "SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR",
        "SOC_ENABLE_CAMERA", "SOC_ENABLE_PREPROCESS", "SOC_DDR_BASE",
        "SOC_DDR_BYTES",
    }
    missing = sorted(required - values.keys())
    if missing:
        raise ConfigError("missing required definitions: " + ", ".join(missing))
    if values["SOC_CPU_MEM_BRAM"] not in (0, 1):
        raise ConfigError("SOC_CPU_MEM_BRAM must be 0 (DDR) or 1 (BRAM)")
    for name in ("SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR",
                 "SOC_ENABLE_CAMERA", "SOC_ENABLE_PREPROCESS"):
        if values[name] not in (0, 1):
            raise ConfigError(f"{name} must be 0 or 1")
    expected_hardware = 0 if values["SOC_CPU_MEM_BRAM"] else 1
    for name in ("SOC_ENABLE_ICACHE", "SOC_ENABLE_DCACHE", "SOC_ENABLE_DDR", "SOC_ENABLE_CAMERA"):
        if values[name] != expected_hardware:
            mode = "BRAM" if values["SOC_CPU_MEM_BRAM"] else "full DDR"
            raise ConfigError(f"{name}={values[name]} is unsupported for the {mode} profile")
    if values["SOC_CPU_MEM_BRAM"] and values["SOC_ENABLE_PREPROCESS"]:
        raise ConfigError("the CoreMark BRAM profile requires preprocessing disabled")
    if values["SOC_UART_TX_FPIOA"] not in (0, 31):
        raise ConfigError("SOC_UART_TX_FPIOA must be 0 (local) or 31 (remote)")

    flash_base = values["SOC_FLASH_BASE"]
    flash_bytes = values["SOC_FLASH_ADDRESS_BYTES"]
    image_bytes = values["SOC_BOOT_IMAGE_BYTES"]
    if flash_base % 4:
        raise ConfigError("SOC_FLASH_BASE must be 4-byte aligned")
    if not image_bytes:
        raise ConfigError("SOC_BOOT_IMAGE_BYTES must be greater than zero")
    if image_bytes % 4:
        raise ConfigError("SOC_BOOT_IMAGE_BYTES must be a multiple of 4 bytes")
    if flash_base >= flash_bytes or image_bytes > flash_bytes - flash_base:
        raise ConfigError(
            f"flash image range 0x{flash_base:06X}..0x{flash_base + image_bytes:06X} "
            f"exceeds the 24-bit flash address space (0x{flash_bytes:06X})"
        )
    for base_name, size_name in (("SOC_IRAM_BASE", "SOC_IRAM_BYTES"),
                                 ("SOC_DRAM_BASE", "SOC_DRAM_BYTES")):
        base, size = values[base_name], values[size_name]
        if base % 4 or size == 0 or size % 4:
            raise ConfigError(f"{base_name}/{size_name} must be nonzero and 4-byte aligned")
        if base + size > 0x1_0000_0000:
            raise ConfigError(f"{base_name}+{size_name} overflows 32-bit address space")
    if values["SOC_IRAM_BASE"] + values["SOC_IRAM_BYTES"] != values["SOC_DRAM_BASE"]:
        raise ConfigError("the BRAM layout must be contiguous: IRAM end must equal DRAM base")
    local_ram_end = values["SOC_DRAM_BASE"] + values["SOC_DRAM_BYTES"]
    ddr_end = values["SOC_DDR_BASE"] + values["SOC_DDR_BYTES"]
    if values["SOC_IRAM_BASE"] < values["SOC_DDR_BASE"] or local_ram_end > ddr_end:
        raise ConfigError("the IRAM/DRAM image layout exceeds the DDR address window")
    if values["SOC_CPU_MEM_BRAM"]:
        local_capacity = values["SOC_IRAM_BYTES"] + values["SOC_DRAM_BYTES"]
        if image_bytes > local_capacity:
            raise ConfigError(
                f"BRAM profile can hold at most {local_capacity} bytes across IRAM and DRAM"
            )
    elif image_bytes > values["SOC_DDR_BYTES"]:
        raise ConfigError("boot image exceeds configured DDR capacity")


def render_header(source: Path, values: dict[str, int]) -> str:
    guard = "SOC_DEFS_H"
    lines = [
        "/* Generated from soc/soc_addr_map.vh by tools/soc_menuconfig.py. */",
        "/* Do not edit this file by hand; regenerate it from the Verilog source. */",
        f"#ifndef {guard}", f"#define {guard}", "#include <stdint.h>", "",
    ]
    for name, value in values.items():
        lines.append(f"#define {name:<34} UINT32_C(0x{value:08X})")
    lines.extend(["", "#endif", ""])
    return "\n".join(lines)


def render_asm(values: dict[str, int]) -> str:
    lines = [
        "/* Generated from soc/soc_addr_map.vh; do not edit by hand. */",
    ]
    lines.extend(f".equ {name}, 0x{value:X}" for name, value in values.items())
    return "\n".join(lines) + "\n"


def generate_header(source: Path, output: Path) -> dict[str, int]:
    values = parse_definitions(source)
    validate(values)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(render_header(source, values), encoding="utf-8")
    return values


def parse_int(text: str, label: str) -> int:
    try:
        return int(text, 0)
    except ValueError as exc:
        raise ConfigError(f"{label} must be an integer such as 32768 or 0xA00000") from exc


def rewrite_source(source: Path, changes: dict[str, int]) -> None:
    text = source.read_text(encoding="utf-8")
    for name, value in changes.items():
        if name not in EDITABLE:
            raise ConfigError(f"{name} is not an editable menu setting")
        pattern = re.compile(rf"(?m)^(\s*`define\s+{re.escape(name)}\s+)([^\r\n]+)$")
        text, count = pattern.subn(lambda m: f"{m.group(1)}{value}", text)
        if count != 1:
            raise ConfigError(f"expected exactly one `{name} definition in {source}, found {count}")
    source.write_text(text, encoding="utf-8")


def profile_changes(profile: str, preprocess: bool | None) -> dict[str, int]:
    if profile == "full":
        flags = {"SOC_CPU_MEM_BRAM": 0, "SOC_ENABLE_ICACHE": 1,
                 "SOC_ENABLE_DCACHE": 1, "SOC_ENABLE_DDR": 1,
                 "SOC_ENABLE_CAMERA": 1}
        default_preprocess = 0
    else:
        flags = {"SOC_CPU_MEM_BRAM": 1, "SOC_ENABLE_ICACHE": 0,
                 "SOC_ENABLE_DCACHE": 0, "SOC_ENABLE_DDR": 0,
                 "SOC_ENABLE_CAMERA": 0}
        default_preprocess = 0
    selected_preprocess = default_preprocess if preprocess is None else int(preprocess)
    if profile == "bram" and selected_preprocess:
        raise ConfigError("the CoreMark BRAM profile requires preprocessing disabled")
    flags["SOC_ENABLE_PREPROCESS"] = selected_preprocess
    return flags


def make_manifest(source: Path, bin_path: Path, output_dir: Path,
                  flash_base: int, load_bytes: int, profile: str) -> Path:
    data_bytes = bin_path.stat().st_size
    if data_bytes <= 0:
        raise ConfigError("selected BIN is empty")
    if load_bytes < data_bytes:
        raise ConfigError(
            f"configured boot length {load_bytes} is smaller than BIN length {data_bytes}; "
            "refusing to truncate"
        )
    padded_name: str | None = None
    if load_bytes > data_bytes:
        padded = output_dir / f"{bin_path.stem}.padded-{load_bytes}.bin"
        output_dir.mkdir(parents=True, exist_ok=True)
        with bin_path.open("rb") as src, padded.open("wb") as dst:
            while block := src.read(1024 * 1024):
                dst.write(block)
            dst.write(b"\xff" * (load_bytes - data_bytes))
        padded_name = str(padded)
    output_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "format": "soc-flash-burn-manifest-v1",
        "profile": profile,
        "address_source": str(source),
        "flash_start_address": f"0x{flash_base:06X}",
        "input_bin": str(bin_path.resolve()),
        "input_bin_bytes": data_bytes,
        "loader_image_bytes": load_bytes,
        "padded_bin": padded_name,
        "padding": {"fill_byte": "0xFF", "bytes": load_bytes - data_bytes},
        "flash_end_exclusive": f"0x{flash_base + load_bytes:06X}",
        "action": "Use the listed BIN artifact and address in the PDS Flash burn flow; this tool does not invoke PDS.",
    }
    path = output_dir / "flash_manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return path


def configure(args: argparse.Namespace) -> None:
    source = Path(args.source).resolve()
    values = parse_definitions(source)
    changes = profile_changes(args.profile, args.preprocess)
    if args.flash_start_address is not None:
        changes["SOC_FLASH_BASE"] = parse_int(args.flash_start_address, "flash start address")
    bin_path = Path(args.bin).resolve() if args.bin else None
    if args.boot_image_bytes is not None:
        changes["SOC_BOOT_IMAGE_BYTES"] = parse_int(args.boot_image_bytes, "boot image bytes")
    elif bin_path:
        changes["SOC_BOOT_IMAGE_BYTES"] = bin_path.stat().st_size
    if args.uart_tx_fpioa is not None:
        changes["SOC_UART_TX_FPIOA"] = parse_int(args.uart_tx_fpioa, "UART TX FPIOA pin")
    preview = dict(values)
    preview.update(changes)
    validate(preview)
    if bin_path:
        length = bin_path.stat().st_size
        if length == 0:
            raise ConfigError("selected BIN is empty")
        if length > preview["SOC_BOOT_IMAGE_BYTES"]:
            raise ConfigError(
                f"configured boot length {preview['SOC_BOOT_IMAGE_BYTES']} is smaller than "
                f"BIN length {length}; refusing to truncate"
            )
    rewrite_source(source, changes)
    values = parse_definitions(source)
    validate(values)
    header_path = Path(args.header_output).resolve() if args.header_output else DEFAULT_HEADER
    generate_header(source, header_path)
    asm_path = Path(args.asm_output).resolve() if args.asm_output else (
        DEFAULT_ASM if source == DEFAULT_SOURCE else None
    )
    if asm_path:
        asm_path.parent.mkdir(parents=True, exist_ok=True)
        asm_path.write_text(render_asm(values), encoding="utf-8")
    if bin_path:
        out = Path(args.output_dir).resolve()
        manifest = make_manifest(source, bin_path, out, values["SOC_FLASH_BASE"],
                                 values["SOC_BOOT_IMAGE_BYTES"], args.profile)
        print(f"PDS manifest: {manifest}")
        print(f"Image: {values['SOC_BOOT_IMAGE_BYTES']} bytes at 0x{values['SOC_FLASH_BASE']:06X}")
    print(f"Updated {source}")
    print(f"Generated {header_path}")


def check(source: Path, bin_path: Path | None = None,
          flash_start: str | None = None, image_bytes: str | None = None) -> dict[str, int]:
    values = parse_definitions(source)
    if flash_start is not None:
        values["SOC_FLASH_BASE"] = parse_int(flash_start, "flash start address")
    if image_bytes is not None:
        values["SOC_BOOT_IMAGE_BYTES"] = parse_int(image_bytes, "boot image bytes")
    validate(values)
    if bin_path:
        length = bin_path.stat().st_size
        if length == 0:
            raise ConfigError("selected BIN is empty")
        if length > values["SOC_BOOT_IMAGE_BYTES"]:
            raise ConfigError(
                f"BIN has {length} bytes but SOC_BOOT_IMAGE_BYTES is "
                f"{values['SOC_BOOT_IMAGE_BYTES']}; refusing silent truncation"
            )
    return values


def prompt(stdscr: curses.window, label: str, initial: str) -> str:
    curses.echo()
    stdscr.addstr(curses.LINES - 2, 0, (label + " [" + initial + "]: ")[:curses.COLS - 1])
    stdscr.clrtoeol()
    stdscr.refresh()
    raw = stdscr.getstr(curses.LINES - 2, min(len(label) + len(initial) + 4, curses.COLS - 2), 4096)
    curses.noecho()
    typed = raw.decode("utf-8", "replace").strip()
    return typed or initial


def interactive(source: Path) -> None:
    original = parse_definitions(source)
    state = {
        "profile": "full" if original["SOC_CPU_MEM_BRAM"] == 0 else "bram",
        "bin": "",
        "flash": f"0x{original['SOC_FLASH_BASE']:06X}",
        "bytes": str(original["SOC_BOOT_IMAGE_BYTES"]),
        "pin": str(original["SOC_UART_TX_FPIOA"]),
        "preprocess": bool(original.get("SOC_ENABLE_PREPROCESS", 0)),
    }
    entries = ["Profile", "Preprocessing", "Firmware BIN", "Flash start address",
               "Boot image bytes", "UART TX FPIOA pin", "Save / generate", "Quit"]
    selected = 0

    def draw(stdscr: curses.window) -> None:
        nonlocal selected
        curses.curs_set(0)
        while True:
            stdscr.erase()
            stdscr.addstr(0, 0, "SoC menuconfig — WSL terminal configuration")
            stdscr.addstr(1, 0, "Arrow keys select, Enter edits, q quits. Values are written to soc_addr_map.vh.")
            vals = [
                "Full application (I/D cache + DDR + Camera)" if state["profile"] == "full"
                else "CoreMark BRAM (no I/D cache, DDR, Camera or preprocessing)",
                "Enabled" if state["preprocess"] else "Disabled",
                state["bin"] or "<select by entering a path>", state["flash"], state["bytes"],
                state["pin"], "", "",
            ]
            for index, (name, value) in enumerate(zip(entries, vals)):
                marker = ">" if selected == index else " "
                row = f"{marker} {name:<24} {value}"
                if index + 3 < curses.LINES:
                    stdscr.addnstr(index + 3, 0, row, curses.COLS - 1,
                                   curses.A_REVERSE if selected == index else curses.A_NORMAL)
            stdscr.refresh()
            key = stdscr.getch()
            if key in (curses.KEY_UP, ord("k")):
                selected = (selected - 1) % len(entries)
            elif key in (curses.KEY_DOWN, ord("j")):
                selected = (selected + 1) % len(entries)
            elif key in (ord("q"), 27):
                return
            elif key in (10, 13, curses.KEY_ENTER):
                if selected == 0:
                    state["profile"] = "bram" if state["profile"] == "full" else "full"
                    if state["profile"] == "bram":
                        state["preprocess"] = False
                elif selected == 1:
                    state["preprocess"] = not state["preprocess"]
                elif selected == 2:
                    candidate = prompt(stdscr, "Firmware BIN path", state["bin"])
                    try:
                        if candidate:
                            detected_bytes = Path(candidate).stat().st_size
                            if detected_bytes <= 0:
                                raise ConfigError("selected BIN is empty")
                            state["bin"] = candidate
                            state["bytes"] = str(detected_bytes)
                    except (OSError, ConfigError) as exc:
                        stdscr.addnstr(curses.LINES - 2, 0, f"Error: {exc}", curses.COLS - 1)
                        stdscr.addstr(curses.LINES - 1, 0, "Press any key to continue")
                        stdscr.getch()
                elif selected == 3:
                    state["flash"] = prompt(stdscr, "Flash start address", state["flash"])
                elif selected == 4:
                    state["bytes"] = prompt(stdscr, "Loader image length in bytes", state["bytes"])
                elif selected == 5:
                    state["pin"] = prompt(stdscr, "UART TX FPIOA pin (0 local or 31 remote)", state["pin"])
                elif selected == 6:
                    args = argparse.Namespace(
                        source=source, profile=state["profile"],
                        preprocess=state["preprocess"], bin=state["bin"] or None,
                        flash_start_address=state["flash"], boot_image_bytes=state["bytes"],
                        uart_tx_fpioa=state["pin"], header_output=None,
                        asm_output=None,
                        output_dir=str(DEFAULT_OUTPUT),
                    )
                    try:
                        configure(args)
                    except (ConfigError, OSError, ValueError) as exc:
                        stdscr.addnstr(curses.LINES - 2, 0, f"Error: {exc}", curses.COLS - 1)
                        stdscr.addstr(curses.LINES - 1, 0, "Press any key to continue")
                        stdscr.getch()
                    else:
                        stdscr.addnstr(curses.LINES - 2, 0, "Saved. Press any key to continue.", curses.COLS - 1)
                        stdscr.getch()
                elif selected == 7:
                    return

    curses.wrapper(draw)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    gen = sub.add_parser("generate-header", help="generate C definitions from the Verilog source")
    gen.add_argument("--source", default=str(DEFAULT_SOURCE))
    gen.add_argument("--output", default=str(DEFAULT_HEADER))
    gen.add_argument("--asm-output", help="also generate a GNU assembler .inc constants file")
    chk = sub.add_parser("check", help="validate definitions and optional firmware length")
    chk.add_argument("--source", default=str(DEFAULT_SOURCE))
    chk.add_argument("--bin")
    chk.add_argument("--flash-start-address")
    chk.add_argument("--boot-image-bytes")
    chk.add_argument("--header", help="also require the generated C header to be current")
    chk.add_argument("--asm", help="also require the generated assembler include to be current")
    cfg = sub.add_parser("configure", help="apply a profile/configuration and emit a burn manifest")
    cfg.add_argument("--source", default=str(DEFAULT_SOURCE))
    cfg.add_argument("--profile", choices=("full", "bram"), required=True)
    cfg.add_argument("--bin")
    cfg.add_argument("--flash-start-address")
    cfg.add_argument("--boot-image-bytes")
    cfg.add_argument("--uart-tx-fpioa")
    cfg.add_argument("--preprocess", action=argparse.BooleanOptionalAction, default=None)
    cfg.add_argument("--header-output")
    cfg.add_argument("--asm-output")
    cfg.add_argument("--output-dir", default=str(DEFAULT_OUTPUT))
    ui = sub.add_parser("menu", help="open the curses menuconfig interface")
    ui.add_argument("--source", default=str(DEFAULT_SOURCE))
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "generate-header":
            source = Path(args.source).resolve()
            output = Path(args.output).resolve()
            values = generate_header(source, output)
            asm_target = args.asm_output
            if asm_target is None and output == DEFAULT_HEADER:
                asm_target = str(DEFAULT_ASM)
            if asm_target:
                asm_output = Path(asm_target).resolve()
                asm_output.parent.mkdir(parents=True, exist_ok=True)
                asm_output.write_text(render_asm(values), encoding="utf-8")
            print(f"Generated {args.output} ({len(values)} definitions)")
        elif args.command == "check":
            source = Path(args.source).resolve()
            values = check(source, Path(args.bin).resolve() if args.bin else None,
                           args.flash_start_address, args.boot_image_bytes)
            if args.header and Path(args.header).read_text(encoding="utf-8") != render_header(source, values):
                raise ConfigError(f"generated C header is stale: {args.header}")
            if args.asm and Path(args.asm).read_text(encoding="utf-8") != render_asm(values):
                raise ConfigError(f"generated assembler include is stale: {args.asm}")
            print(f"Configuration valid: {len(values)} definitions; flash image "
                  f"0x{values['SOC_FLASH_BASE']:06X}+{values['SOC_BOOT_IMAGE_BYTES']} bytes")
        elif args.command == "configure":
            configure(args)
        elif args.command == "menu":
            interactive(Path(args.source).resolve())
    except (ConfigError, OSError, ValueError) as exc:
        print(f"soc_menuconfig: error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
