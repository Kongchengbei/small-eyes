#!/usr/bin/env python3
"""Run configuration checks and the offline full-DDR or BRAM validation suites."""

from __future__ import annotations

import argparse
import os
import pty
import select
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PYTHON = sys.executable
MAKE = os.environ.get("MAKE", "make")
VERILATOR_ASSIGNMENT = "VERILATOR=verilator -Isoc"
os.environ.setdefault("CCACHE_DISABLE", "1")

FULL_TARGETS = [
    "sim",
    "cpu-load-store-test",
    "addr-map",
    "dcache-bypass",
    "npu-ctrl",
    "npu-dma",
    "npu-arbiter",
    "spi-flash-reader-test",
    "flash-ddr-boot-test",
    "camera-sccb-gpio-test",
    "camera-dvp-rx-test",
    "camera-async-fifo-test",
    "camera-dvp-fifo-test",
    "camera-dma-test",
    "camera-snapshot-test",
    "camera-pipeline-test",
    "camera-stereo-test",
    "preprocess-color-test",
    "preprocess-test",
]


def run(command: list[str], label: str) -> None:
    print(f"\n== {label} ==", flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def config_suite(menu_smoke: bool) -> None:
    run([PYTHON, "-B", "tools/test_soc_menuconfig.py"], "SoC menu/parser/config tests")
    run([
        PYTHON, "-B", "tools/soc_menuconfig.py", "check",
        "--source", "soc/soc_addr_map.vh",
        "--header", "bsp/include/soc_defs.h",
        "--asm", "bsp/include/soc_defs_asm.inc",
    ], "authoritative map and generated headers")
    run([
        "riscv64-unknown-elf-gcc", "--specs=picolibc.specs", "-march=rv32im", "-mabi=ilp32",
        "-std=gnu11", "-fsyntax-only", "-Ibsp/camera_app",
        "bsp/camera_app/uart.c", "bsp/camera_app/camera_dvp.c",
        "bsp/camera_app/camera_sccb.c", "bsp/camera_app/gpio_test.c",
    ], "camera BSP address and mask C syntax")
    run([
        "riscv64-unknown-elf-gcc", "--specs=picolibc.specs", "-march=rv32im", "-mabi=ilp32",
        "-std=gnu11", "-fsyntax-only", "-Ibsp/bsp_app/lib",
        "-Ibsp/bsp_app/lib/perip/include", "-Ibsp/bsp_app/lib/driver/include",
        "bsp/bsp_app/lib/perip/src/uart.c",
    ], "BSP UART compatibility C syntax")
    run([
        "riscv64-unknown-elf-gcc", "--specs=picolibc.specs", "-march=rv32im", "-mabi=ilp32",
        "-std=gnu11", "-fsyntax-only", "-Ibsp/bsp_iap/lib",
        "-Ibsp/bsp_iap/lib/perip/include", "-Ibsp/bsp_iap/lib/driver/include",
        "bsp/bsp_iap/lib/perip/src/uart.c",
    ], "IAP UART compatibility C syntax")
    if menu_smoke:
        curses_smoke()


def curses_smoke() -> None:
    """Open the real curses menu on a pseudo-terminal, then exit without edits."""
    master_fd, slave_fd = pty.openpty()
    env = os.environ.copy()
    env["TERM"] = env.get("TERM", "xterm-256color")
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    before = (ROOT / "soc" / "soc_addr_map.vh").read_bytes()
    process = subprocess.Popen(
        [PYTHON, "-B", "tools/soc_menuconfig.py", "menu"],
        cwd=ROOT, stdin=slave_fd, stdout=slave_fd, stderr=slave_fd,
        env=env, close_fds=True,
    )
    os.close(slave_fd)
    try:
        # Let curses enter raw mode before sending q; drain terminal output to
        # keep the pseudo-terminal from filling on narrow CI buffers.
        deadline = time.monotonic() + 5.0
        saw_screen = False
        while time.monotonic() < deadline and process.poll() is None:
            ready, _, _ = select.select([master_fd], [], [], 0.1)
            if ready:
                try:
                    output = os.read(master_fd, 8192)
                except OSError:
                    output = b""
                saw_screen |= b"SoC menuconfig" in output
            if saw_screen:
                os.write(master_fd, b"q")
                break
        if process.poll() is None:
            try:
                process.wait(timeout=3.0)
            except subprocess.TimeoutExpired:
                process.terminate()
                raise RuntimeError("curses menu did not exit after the q key")
        if process.returncode != 0:
            raise RuntimeError(f"curses menu exited with status {process.returncode}")
        if not saw_screen:
            raise RuntimeError("curses menu did not render its menu title on the pseudo-terminal")
    finally:
        os.close(master_fd)
    if (ROOT / "soc" / "soc_addr_map.vh").read_bytes() != before:
        raise RuntimeError("curses menu changed the map during the read-only startup smoke")
    print("PASS: curses menu opened and exited without changing configuration", flush=True)


def full_suite() -> None:
    for target in FULL_TARGETS:
        run([MAKE, VERILATOR_ASSIGNMENT, target], f"full DDR: make {target}")
    run(["iverilog", "-g2012", "-s", "tb_Hcsr", "-o", "build/tb_hcsr_ddr.vvp",
         "cpu/Hcsr.v", "sim/tb_Hcsr.sv"], "compile Hcsr CSR/trap bench")
    run(["vvp", "build/tb_hcsr_ddr.vvp"], "run Hcsr CSR/trap bench")
    run(["bash", "sim/run_cpu_bram_checks.sh", "build/obj_cpu_regression/Vtb_Htop",
         "build/cpu_ddr_checks"], "DDR mixed access, CSR timer, and isolated CoreMark CRC checks")
    run([
        "verilator", "--lint-only", "--timing", "-Isoc", "--language", "1800-2012",
        "--top-module", "tb_fpioa_uart_profiles", "soc/Hfpioa_simple.v",
        "sim/tb_fpioa_uart_profiles.sv",
    ], "FPIOA UART profile lint")
    run([
        "iverilog", "-g2012", "-Isoc", "-s", "tb_fpioa_uart_profiles",
        "-o", "build/tb_fpioa_uart_profiles.vvp", "soc/Hfpioa_simple.v",
        "sim/tb_fpioa_uart_profiles.sv",
    ], "FPIOA UART profiles compile")
    run(["vvp", "build/tb_fpioa_uart_profiles.vvp"], "FPIOA UART profiles run")
    run([
        "iverilog", "-g2012", "-Isoc", "-s", "tb_fpioa_camera_reserved",
        "-o", "build/tb_fpioa_camera_reserved.vvp", "soc/Hfpioa_simple.v",
        "sim/tb_fpioa_camera_reserved.sv",
    ], "FPIOA camera reserved pins compile")
    run(["vvp", "build/tb_fpioa_camera_reserved.vvp"], "FPIOA camera reserved pins run")


def compile_bram_cpu_sim() -> Path:
    build_dir = ROOT / "build"
    object_dir = build_dir / "obj_bram_regression"
    object_dir.mkdir(parents=True, exist_ok=True)
    cpu_rtl = sorted(
        str(path.relative_to(ROOT)) for path in (ROOT / "cpu").glob("*.v")
        if path.name not in ("cache_bram.v", "cache_sram_beh.v")
    )
    sim_rtl = ["soc/axi_mem_backend.v", "soc/Huart_tx.v", "cpu/cache_sram_beh.v", "soc/Hfpioa_simple.v"]
    camera_rtl = [
        "soc/Hcamera_sccb_gpio.v", "soc/Hcamera_dvp_rx.v", "soc/Hcamera_dvp_regs.v",
        "soc/Hcamera_async_fifo.v", "soc/Hcamera_dma.v", "soc/Hcamera_subsystem.v",
        "soc/Haxi_2m1s_arbiter.v", "soc/ddr_axi_bridge.v", "sim/camera_ddr_model.sv",
        "sim/ov5640_sccb_model.sv",
    ]
    command = [
        "verilator", "--binary", "--timing", "-Isoc", "--language", "1800-2012",
        "--Wno-WIDTHTRUNC", "--Wno-BLKLOOPINIT",
        "-GBRAM_MODE=1", "--top-module", "tb_Htop", "--Mdir", str(object_dir),
        *cpu_rtl, *sim_rtl, *camera_rtl, "sim/tb_Htop.sv",
    ]
    run(command, "build BRAM Htop regression simulator")
    return object_dir / "Vtb_Htop"


def compile_and_run_iverilog(top: str, output: Path, sources: list[str]) -> None:
    run(["iverilog", "-g2012", "-Isoc", "-s", top, "-o", str(output), *sources],
        f"compile {top}")
    run(["vvp", str(output)], f"run {top}")


def bram_suite() -> None:
    run(["bash", "sim/run_bram_boot_checks.sh"], "BRAM boot path and mode lint")
    simulator = compile_bram_cpu_sim()
    run([
        PYTHON, "-B", "sim/test.py", "--sim", str(simulator), "--tests", "sim/test",
        "--output", "build/isa_bram", "--timeout", "100000",
    ], "BRAM mode shared 46-case ISA suite")
    compile_and_run_iverilog("tb_cpu_bram_mem", ROOT / "build/tb_cpu_bram_mem.vvp",
                            ["sim/tb_cpu_bram_mem.sv", "cpu/cpu_bram_mem.v"])
    compile_and_run_iverilog("tb_hifu_bram", ROOT / "build/tb_hifu_bram.vvp",
                            ["sim/tb_hifu_bram.sv", "cpu/Hifu.v"])
    compile_and_run_iverilog("tb_memu_load_stall", ROOT / "build/tb_memu_load_stall.vvp",
                            ["sim/tb_memu_load_stall.sv", "cpu/Hmemu.v"])
    compile_and_run_iverilog("tb_Hcsr", ROOT / "build/tb_hcsr_bram.vvp",
                            ["cpu/Hcsr.v", "sim/tb_Hcsr.sv"])
    run(["bash", "sim/run_cpu_bram_checks.sh", str(simulator)],
        "BRAM mixed access, CSR timer, and isolated CoreMark CRC checks")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", choices=("config", "full", "bram", "all"), nargs="?", default="all")
    parser.add_argument("--no-menu-smoke", action="store_true",
                        help="skip the pseudo-terminal curses startup/exit check")
    args = parser.parse_args()
    try:
        config_suite(not args.no_menu_smoke)
        if args.suite in ("full", "all"):
            full_suite()
        if args.suite in ("bram", "all"):
            bram_suite()
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"run_soc_tests: FAIL: {exc}", file=sys.stderr)
        return 1
    print(f"\nPASS: {args.suite} suite", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
