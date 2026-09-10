#!/usr/bin/env python3
"""Run every generated RISC-V ISA image as an independent CPU test."""

import argparse
import re
import subprocess
import sys
from pathlib import Path


CASE_RE = re.compile(r"TEST_FAIL testnum=(\d+)")
GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"


def format_status(status: str) -> str:
    label = f"[{status}]"
    if status == "PASS":
        return f"{GREEN}{label}{RESET}"
    if status == "FAIL":
        return f"{RED}{label}{RESET}"
    return label


def bin_to_hex_words(source: Path, destination: Path) -> None:
    data = source.read_bytes()
    if len(data) % 4:
        raise ValueError(f"{source} is not a multiple of four bytes")

    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="ascii", newline="\n") as output:
        for offset in range(0, len(data), 4):
            word = int.from_bytes(data[offset : offset + 4], byteorder="little")
            output.write(f"{word:08x}\n")


def run_test(simulator: Path, program: Path, timeout: int) -> tuple[str, str]:
    command = [
        str(simulator),
        f"+PROGRAM={program}",
        f"+TIMEOUT={timeout}",
    ]
    result = subprocess.run(command, text=True, capture_output=True)
    output = result.stdout + result.stderr

    if "TEST_PASS" in output and "TEST_FAIL" not in output:
        return "PASS", ""

    match = CASE_RE.search(output)
    if match:
        return "FAIL", f"case={match.group(1)}"
    if "TEST_TIMEOUT" in output:
        return "TIMEOUT", ""
    return "ERROR", f"exit={result.returncode}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sim", required=True, type=Path)
    parser.add_argument("--tests", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--timeout", type=int, default=100000)
    args = parser.parse_args()

    simulator = args.sim.resolve()
    tests_dir = args.tests.resolve()
    output_dir = args.output.resolve()

    if not simulator.is_file():
        print(f"error: simulator not found: {simulator}", file=sys.stderr)
        return 2
    if not tests_dir.is_dir():
        print(f"error: ISA directory not found: {tests_dir}", file=sys.stderr)
        return 2

    binaries = sorted(tests_dir.glob("*.bin"))
    if not binaries:
        print(f"error: no .bin files found in {tests_dir}", file=sys.stderr)
        return 2

    passed = failed = timed_out = errors = 0
    print(f"Running {len(binaries)} ISA programs")
    for binary in binaries:
        image = output_dir / f"{binary.stem}.txt"
        try:
            bin_to_hex_words(binary, image)
            status, detail = run_test(simulator, image, args.timeout)
        except (OSError, ValueError) as error:
            status, detail = "ERROR", str(error)

        suffix = f" {detail}" if detail else ""
        print(f"{format_status(status)} {binary.stem}{suffix}")
        if status == "PASS":
            passed += 1
        elif status == "FAIL":
            failed += 1
        elif status == "TIMEOUT":
            timed_out += 1
        else:
            errors += 1

    total = len(binaries)
    summary = (
        f"Summary: PASS={passed} FAIL={failed} "
        f"TIMEOUT={timed_out} ERROR={errors} TOTAL={total}"
    )
    summary_color = GREEN if passed == total else RED
    print(f"{summary_color}{summary}{RESET}")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
