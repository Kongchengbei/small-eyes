#!/usr/bin/env python3
"""Focused unit checks for the SoC definition parser and menu configuration."""

from __future__ import annotations

import contextlib
import io
import tempfile
import unittest
from pathlib import Path

import soc_menuconfig as menu


class DefinitionParserTests(unittest.TestCase):
    def test_verilog_literals_aliases_and_arithmetic(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "map.vh"
            source.write_text(
                "`define VALUE 16'h12_34\n"
                "`define ALIAS `VALUE\n"
                "`define SUM (`ALIAS + 8'd2)\n",
                encoding="utf-8",
            )
            values = menu.parse_definitions(source)
            self.assertEqual(values["VALUE"], 0x1234)
            self.assertEqual(values["ALIAS"], 0x1234)
            self.assertEqual(values["SUM"], 0x1236)

    def test_unsupported_and_cyclic_expressions_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "bad.vh"
            source.write_text("`define VALUE 8'hx0\n", encoding="utf-8")
            with self.assertRaises(menu.ConfigError):
                menu.parse_definitions(source)
            source.write_text("`define A `B\n`define B `A\n", encoding="utf-8")
            with self.assertRaises(menu.ConfigError):
                menu.parse_definitions(source)

    def test_repository_defaults_are_the_expected_address_contract(self) -> None:
        values = menu.parse_definitions(menu.DEFAULT_SOURCE)
        menu.validate(values)
        expected = {
            "SOC_IRAM_BASE": 0x80000000,
            "SOC_IRAM_BYTES": 32768,
            "SOC_DRAM_BASE": 0x80008000,
            "SOC_DRAM_BYTES": 16384,
        }
        for name, value in expected.items():
            self.assertEqual(values[name], value, name)
        self.assertIn(values["SOC_CPU_MEM_BRAM"], (0, 1))


class ConfigurationTests(unittest.TestCase):
    def _copy_map(self, root: Path) -> Path:
        path = root / "soc_addr_map.vh"
        path.write_bytes(menu.DEFAULT_SOURCE.read_bytes())
        return path

    def test_bram_profile_autodetects_image_and_writes_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._copy_map(root)
            image = root / "firmware.bin"
            image.write_bytes(b"\x13\x00\x00\x00")
            args = menu.build_parser().parse_args([
                "configure", "--source", str(source), "--profile", "bram",
                "--bin", str(image), "--flash-start-address", "0xA00000",
                "--header-output", str(root / "soc_defs.h"),
                "--asm-output", str(root / "soc_defs.inc"),
                "--output-dir", str(root / "burn"),
            ])
            with contextlib.redirect_stdout(io.StringIO()):
                menu.configure(args)
            values = menu.parse_definitions(source)
            self.assertEqual(values["SOC_CPU_MEM_BRAM"], 1)
            self.assertEqual(values["SOC_BOOT_IMAGE_BYTES"], 4)
            self.assertEqual(values["SOC_ENABLE_ICACHE"], 0)
            self.assertEqual(values["SOC_ENABLE_DCACHE"], 0)
            self.assertEqual(values["SOC_ENABLE_DDR"], 0)
            self.assertEqual(values["SOC_ENABLE_CAMERA"], 0)
            self.assertEqual(values["SOC_ENABLE_PREPROCESS"], 0)
            manifest = (root / "burn" / "flash_manifest.json").read_text(encoding="utf-8")
            self.assertIn('"flash_start_address": "0xA00000"', manifest)
            self.assertIn('"input_bin_bytes": 4', manifest)
            self.assertEqual(image.read_bytes(), b"\x13\x00\x00\x00")

    def test_manual_padding_keeps_input_and_declares_fill_bytes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._copy_map(root)
            image = root / "image.bin"
            image.write_bytes(b"abcd")
            args = menu.build_parser().parse_args([
                "configure", "--source", str(source), "--profile", "full", "--bin", str(image),
                "--boot-image-bytes", "8", "--header-output", str(root / "defs.h"),
                "--output-dir", str(root / "burn"),
            ])
            with contextlib.redirect_stdout(io.StringIO()):
                menu.configure(args)
            padded = root / "burn" / "image.padded-8.bin"
            self.assertEqual(padded.read_bytes(), b"abcd\xff\xff\xff\xff")
            self.assertEqual(image.read_bytes(), b"abcd")
            manifest = (root / "burn" / "flash_manifest.json").read_text(encoding="utf-8")
            self.assertIn('"fill_byte": "0xFF"', manifest)

    def test_invalid_capacity_and_truncation_leave_authority_unchanged(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._copy_map(root)
            before = source.read_bytes()
            image = root / "image.bin"
            image.write_bytes(b"12345678")
            args = menu.build_parser().parse_args([
                "configure", "--source", str(source), "--profile", "full", "--bin", str(image),
                "--boot-image-bytes", "4", "--header-output", str(root / "defs.h"),
                "--output-dir", str(root / "burn"),
            ])
            with self.assertRaises(menu.ConfigError):
                menu.configure(args)
            self.assertEqual(source.read_bytes(), before)
            args.bin = str(root / "missing.bin")
            with self.assertRaises(OSError):
                menu.configure(args)
            self.assertEqual(source.read_bytes(), before)
            with self.assertRaises(menu.ConfigError):
                menu.check(source, image, "0xFFFFFC", "8")
            with self.assertRaises(menu.ConfigError):
                menu.check(source, image, "0xA00001", "8")
            menu.rewrite_source(source, menu.profile_changes("bram", None))
            with self.assertRaises(menu.ConfigError):
                menu.check(source, image, None, "49156")

    def test_incoherent_cache_ddr_camera_flags_are_rejected(self) -> None:
        values = menu.parse_definitions(menu.DEFAULT_SOURCE)
        values["SOC_ENABLE_CAMERA"] = 0
        with self.assertRaises(menu.ConfigError):
            menu.validate(values)

    def test_generated_header_and_assembler_include_match_source(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = self._copy_map(root)
            header, asm = root / "soc_defs.h", root / "soc_defs.inc"
            values = menu.generate_header(source, header)
            asm.write_text(menu.render_asm(values), encoding="utf-8")
            self.assertEqual(menu.main(["check", "--source", str(source), "--header", str(header), "--asm", str(asm)]), 0)
            header.write_text("stale\n", encoding="utf-8")
            with contextlib.redirect_stderr(io.StringIO()):
                status = menu.main(["check", "--source", str(source), "--header", str(header), "--asm", str(asm)])
            self.assertEqual(status, 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
