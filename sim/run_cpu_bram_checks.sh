#!/usr/bin/env bash
set -euo pipefail
export CCACHE_DISABLE="${CCACHE_DISABLE:-1}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "usage: $0 <tb_Htop-simulator> [output-directory]" >&2
    exit 2
fi

simulator="$1"
if [[ "$simulator" != /* ]]; then
    simulator="$repo_root/$simulator"
fi
if [[ ! -x "$simulator" ]]; then
    echo "error: simulator is not executable: $simulator" >&2
    exit 2
fi

out_dir="${2:-build/cpu_bram_checks}"
if [[ "$out_dir" != /* ]]; then
    out_dir="$repo_root/$out_dir"
fi
mkdir -p "$out_dir"

gcc_bin="${RISCV_GCC:-riscv64-unknown-elf-gcc}"
objcopy_bin="${RISCV_OBJCOPY:-riscv64-unknown-elf-objcopy}"

make_hex() {
    local name="$1"
    local source="$2"
    local dir="$out_dir/$name"
    mkdir -p "$dir"
    "$gcc_bin" -march=rv32im -mabi=ilp32 -nostdlib -Wl,--no-relax \
        -Wl,-Ttext=0x80000000 "$source" -o "$dir/program.elf"
    "$objcopy_bin" -O binary "$dir/program.elf" "$dir/program.bin"
    "$objcopy_bin" -I binary -O binary --reverse-bytes=4 \
        "$dir/program.bin" "$dir/program.be.bin"
    xxd -p -c 4 "$dir/program.be.bin" > "$dir/program.hex"
}

run_cpu_test() {
    local name="$1"
    local timeout="$2"
    local log="$out_dir/$name/run.log"
    "$simulator" "+PROGRAM=$out_dir/$name/program.hex" "+TIMEOUT=$timeout" >"$log" 2>&1
    if ! rg -q 'TEST_PASS' "$log" || rg -q 'TEST_FAIL|TEST_TIMEOUT' "$log"; then
        cat "$log"
        echo "FAIL: $name" >&2
        exit 1
    fi
    echo "PASS: $name"
}

make_hex mixed_mmio sim/cpu_load_store_mmio.S
run_cpu_test mixed_mmio 200000

make_hex csr_timer sim/cpu_bram_csr_timer.S
run_cpu_test csr_timer 200000

coremark_dir="$out_dir/coremark_iter1"
mkdir -p "$coremark_dir"
"$gcc_bin" --specs=picolibc.specs -march=rv32im -mabi=ilp32 -mcmodel=medlow \
    -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc \
    -O2 -w -DITERATIONS=1 -DCOREMARK_UART_TX_FPIOA=0u \
    -Ibsp/bsp_app/example/coremark -Ibsp/bsp_app/lib \
    -Ibsp/bsp_app/lib/perip/include -Ibsp/bsp_app/lib/driver/include \
    bsp/bsp_app/lib/startup/startup.S \
    bsp/bsp_app/example/coremark/core_list_join.c \
    bsp/bsp_app/example/coremark/core_portme.c \
    bsp/bsp_app/example/coremark/core_matrix.c \
    bsp/bsp_app/example/coremark/core_main.c \
    bsp/bsp_app/example/coremark/core_state.c \
    bsp/bsp_app/example/coremark/core_util.c \
    bsp/bsp_app/lib/startup/init.c \
    bsp/bsp_app/lib/driver/src/printf.c \
    -T bsp/bsp_app/link.lds -nostartfiles -Wl,--gc-sections \
    -Wl,--check-sections -Wl,-Map="$coremark_dir/coremark.map" \
    -o "$coremark_dir/coremark.elf"
"$objcopy_bin" -O binary "$coremark_dir/coremark.elf" "$coremark_dir/coremark.bin"
"$objcopy_bin" -I binary -O binary --reverse-bytes=4 \
    "$coremark_dir/coremark.bin" "$coremark_dir/coremark.be.bin"
xxd -p -c 4 "$coremark_dir/coremark.be.bin" > "$coremark_dir/coremark.hex"

coremark_log="$coremark_dir/run.log"
"$simulator" "+PROGRAM=$coremark_dir/coremark.hex" +COREMARK +UART_PIN=0 \
    +TIMEOUT=10000000 >"$coremark_log" 2>&1
if ! rg -q 'COREMARK_FIRMWARE_PASS pin=0 startup_only=0' "$coremark_log" || \
    ! rg -q 'seedcrc[[:space:]]+: 0xe9f5' "$coremark_log" || \
    ! rg -q '\[0\]crclist[[:space:]]+: 0xe714' "$coremark_log" || \
    ! rg -q '\[0\]crcmatrix[[:space:]]+: 0x1fd7' "$coremark_log" || \
    ! rg -q '\[0\]crcstate[[:space:]]+: 0x8e3a' "$coremark_log" || \
    ! rg -q '\[0\]crcfinal[[:space:]]+: 0xe714' "$coremark_log"; then
    cat "$coremark_log"
    echo "FAIL: CoreMark startup/CRC smoke" >&2
    exit 1
fi
echo "PASS: CoreMark startup and iteration-1 CRC smoke (not a performance score)"
