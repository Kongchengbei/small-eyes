#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d /tmp/soc-clock-config.XXXXXX)
cleanup() {
    case "$TEST_DIR" in /tmp/soc-clock-config.*) rm -rf -- "$TEST_DIR" ;; esac
}
trap cleanup EXIT HUP INT TERM
TOOL="$ROOT/build/menuconfig/soc_config"
mkdir -p "$TEST_DIR/soc" "$TEST_DIR/cpu" "$TEST_DIR/sim" "$TEST_DIR/bsp"
mkdir -p "$TEST_DIR/soc/flash_boot"
cp "$ROOT/soc/soc_addr_map.vh" "$ROOT/soc/soc_timeout.vh" "$TEST_DIR/soc/"
cp "$ROOT/soc/flash_boot/flash_ddr_loader.v" "$TEST_DIR/soc/flash_boot/"
cp "$ROOT/cpu/Hcsr.v" "$TEST_DIR/cpu/"
cp "$ROOT/sim/tb_soc_clock_config.sv" "$TEST_DIR/sim/"
cp "$ROOT/soc.fdc" "$TEST_DIR/soc.fdc"
SOURCE="$TEST_DIR/soc/soc_addr_map.vh"
CONFIG="$TEST_DIR/.config"
FDC="$TEST_DIR/soc.fdc"
OUT="$TEST_DIR/output"

config_for() {
    hz=$1
    printf '%s\n' 'CONFIG_SOC_PROFILE_FULL=y' '# CONFIG_SOC_PROFILE_BRAM is not set' \
        '# CONFIG_SOC_ENABLE_PREPROCESS is not set' 'CONFIG_SOC_UART_LOCAL=y' \
        '# CONFIG_SOC_UART_REMOTE is not set' 'CONFIG_SOC_FIRMWARE_BIN=""' \
        'CONFIG_SOC_FLASH_BASE=0xA00000' 'CONFIG_SOC_BOOT_IMAGE_BYTES=32768' \
        "CONFIG_SOC_CPU_HZ=$hz" > "$CONFIG"
}
apply_config() {
    "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
        --fdc "$FDC" --bsp-output-dir "$TEST_DIR/bsp" > "$TEST_DIR/apply.log"
}
check_config() {
    "$TOOL" check --source "$SOURCE" --fdc "$FDC" \
        --header "$TEST_DIR/bsp/soc_defs.h" --asm "$TEST_DIR/bsp/soc_defs_asm.inc" > /dev/null || return 1
    cmp "$OUT/soc_defs.h" "$TEST_DIR/bsp/soc_defs.h" || return 1
    # All unrelated constraints, including every LOC/VCCIO/direction/drive/slew
    # line, must remain byte-identical across profiles.
    sed '/# BEGIN SOC_CPU_CLOCK/,/# END SOC_CPU_CLOCK/d; /# BEGIN SOC_JTAG_ROUTE/,/# END SOC_JTAG_ROUTE/d' \
        "$ROOT/soc.fdc" | awk '/^define_attribute \{p:mem_(dqs(_n)?\[[0-3]\]|ck(_n)?)\} \{PAP_IO_STANDARD\}/ {next} {print}' > "$TEST_DIR/other.original"
    sed '/# BEGIN SOC_CPU_CLOCK/,/# END SOC_CPU_CLOCK/d; /# BEGIN SOC_JTAG_ROUTE/,/# END SOC_JTAG_ROUTE/d' \
        "$FDC" | awk '/^define_attribute \{p:mem_(dqs(_n)?\[[0-3]\]|ck(_n)?)\} \{PAP_IO_STANDARD\}/ {next} {print}' > "$TEST_DIR/other.current"
    cmp "$TEST_DIR/other.original" "$TEST_DIR/other.current"
}
check_paths() {
    case "$1" in
        full) pll='g_ddr_profile.u_pll/u_gpll:CLKOUT0'; net='g_ddr_profile.JTAG_TCK_in'; absent='g_bram_profile'; standard=HSTL15D_I ;;
        bram) pll='g_bram_profile.u_bram_profile/u_pll/u_gpll:CLKOUT0'; net='g_bram_profile.u_bram_profile/JTAG_TCK_in'; absent='g_ddr_profile'; standard=HSTL15_I ;;
    esac
    rg -Fqx "    [get_pins {$pll}]" "$FDC"
    rg -Fqx "define_attribute {n:$net} {PAP_CLOCK_DEDICATED_ROUTE} {FALSE}" "$FDC"
    if rg -Fq "$absent" "$FDC"; then echo 'FAIL constraints for inactive profile' >&2; exit 1; fi
    test "$(rg -c "^define_attribute \{p:mem_(dqs(_n)?\[[0-3]\]|ck(_n)?)\} \{PAP_IO_STANDARD\} \{$standard\}$" "$FDC")" -eq 10
    # Disabled reference input constraints and the existing data/control IO
    # standards must not be changed by the narrowly scoped profile adaptation.
    rg -Fqx 'define_attribute {p:clk_p} {PAP_IO_STANDARD} {HSTL15D_I}' "$FDC"
    rg -Fqx 'define_attribute {p:clk_n} {PAP_IO_STANDARD} {HSTL15D_I}' "$FDC"
}

for hz in 70000000 90000000 100000000 70500000 1000000 327670000; do
    config_for "$hz"
    apply_config
    check_config
    check_paths full
    rg -q "SOC_CPU_HZ +32'd$hz$" "$SOURCE"
    rg -q "\"cpu_hz\": $hz," "$OUT/clock_config.json"
    case "$hz" in
        70000000) mult=70; div=27 ;;
        90000000) mult=10; div=3 ;;
        100000000) mult=100; div=27 ;;
        70500000) mult=47; div=18 ;;
        1000000) mult=1; div=27 ;;
        327670000) mult=32767; div=2700 ;;
    esac
    rg -q -- "-multiply_by $mult " "$FDC"
    rg -q -- "-divide_by $div " "$FDC"
    boot=$(((hz+699)/700))
    snap=$(((hz+69)/70))
    rg -q "\"boot_timeout_cpu_cycles\": $boot," "$OUT/clock_config.json"
    rg -q "\"camera_snapshot_timeout_cpu_cycles\": $snap," "$OUT/clock_config.json"
    rg -q "\"ddr_init_timeout_cpu_cycles\": $hz," "$OUT/clock_config.json"
    (cd "$TEST_DIR"; iverilog -g2012 -I. -Isoc -s tb_soc_clock_config \
        -Ptb_soc_clock_config.EXPECTED_HZ="$hz" \
        -Ptb_soc_clock_config.EXPECTED_BOOT_TIMEOUT="$boot" \
        -Ptb_soc_clock_config.EXPECTED_SNAPSHOT_TIMEOUT="$snap" \
        -o clock.vvp cpu/Hcsr.v soc/flash_boot/flash_ddr_loader.v sim/tb_soc_clock_config.sv)
    vvp "$TEST_DIR/clock.vvp"
done

# Repeated generation must not force all firmware objects to rebuild.
before=$(stat -c '%y' "$TEST_DIR/bsp/soc_defs.h")
"$TOOL" generate-header --source "$SOURCE" --output-dir "$TEST_DIR/bsp"
test "$before" = "$(stat -c '%y' "$TEST_DIR/bsp/soc_defs.h")"

# Reject invalid frequency, malformed FDC and unwritable output layout before
# changing any existing authority/header output.
config_for 70000000
apply_config
sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/before.sha"
for hz in 0 999000 70000001 327680000; do
    config_for "$hz"
    if apply_config 2> "$TEST_DIR/error.log"; then echo "FAIL accepted invalid Hz $hz" >&2; exit 1; fi
    sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/after.sha"
    cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
done
config_for 90000000
cc -shared -fPIC -Wall -Wextra -Werror "$ROOT/scripts/tests/rename_fault.c" \
    -ldl -o "$TEST_DIR/rename_fault.so"
if LD_PRELOAD="$TEST_DIR/rename_fault.so" SOC_CONFIG_TEST_FAIL_RENAME_TARGET="$SOURCE" \
    "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
    --fdc "$FDC" --bsp-output-dir "$TEST_DIR/bsp" > /dev/null 2> "$TEST_DIR/rollback.log"; then exit 1; fi
rg -q 'commit failed' "$TEST_DIR/rollback.log"
if rg -q 'ROLLBACK FAILED' "$TEST_DIR/rollback.log"; then exit 1; fi
sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/after.sha"
cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
printf '%s\n' '# no managed clock block' > "$TEST_DIR/bad.fdc"
if "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
    --fdc "$TEST_DIR/bad.fdc" --bsp-output-dir "$TEST_DIR/bsp" > /dev/null 2>&1; then exit 1; fi
# Missing/duplicated JTAG ownership markers, missing/duplicated endpoint or
# route commands and overlapping blocks must fail without any partial write.
for bad in jtag_missing jtag_duplicate pin_missing pin_duplicate route_missing route_duplicate overlap io_missing io_duplicate io_invalid; do
    case "$bad" in
        jtag_missing) sed '/# BEGIN SOC_JTAG_ROUTE/d' "$FDC" ;;
        jtag_duplicate) sed '/# BEGIN SOC_JTAG_ROUTE/p' "$FDC" ;;
        pin_missing) sed '/\[get_pins {/d' "$FDC" ;;
        pin_duplicate) sed '/\[get_pins {/p' "$FDC" ;;
        route_missing) sed '/^define_attribute {n:/d' "$FDC" ;;
        route_duplicate) sed '/^define_attribute {n:/p' "$FDC" ;;
        overlap) sed '/# END SOC_JTAG_ROUTE/d; /# END SOC_CPU_CLOCK/a # END SOC_JTAG_ROUTE' "$FDC" ;;
        io_missing) sed '/^define_attribute {p:mem_ck} {PAP_IO_STANDARD}/d' "$FDC" ;;
        io_duplicate) sed '/^define_attribute {p:mem_ck} {PAP_IO_STANDARD}/p' "$FDC" ;;
        io_invalid) sed '/^define_attribute {p:mem_ck} {PAP_IO_STANDARD}/s/HSTL15D_I/LVCMOS33/' "$FDC" ;;
    esac > "$TEST_DIR/bad.fdc"
    sha256sum "$TEST_DIR/bad.fdc" > "$TEST_DIR/bad.before.sha"
    if "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
        --fdc "$TEST_DIR/bad.fdc" --bsp-output-dir "$TEST_DIR/bsp" > /dev/null 2>&1; then
        echo "FAIL accepted malformed FDC $bad" >&2; exit 1
    fi
    sha256sum "$TEST_DIR/bad.fdc" > "$TEST_DIR/bad.after.sha"
    cmp "$TEST_DIR/bad.before.sha" "$TEST_DIR/bad.after.sha"
    sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/after.sha"
    cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
done
mkdir -p "$TEST_DIR/broken/soc_defs.h"
if "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
    --fdc "$FDC" --bsp-output-dir "$TEST_DIR/broken" > /dev/null 2>&1; then exit 1; fi
sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/after.sha"
cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
test -z "$(find "$TEST_DIR" -name '*.tmp.*' -print)"

# Legacy .config migration must seed from current RTL, not reset it to 70 MHz.
# Verify the real firmware dependency helper too: no-op build does not rebuild,
# then a changed frequency/header does rebuild the dependent object.
printf '%s\n' '.DEFAULT_GOAL := all' "include $ROOT/bsp/soc_config.mk" \
    'all: object' 'object: $(BSP_SOC_HEADER)' \
    ' recipe-placeholder' > "$TEST_DIR/firmware.mk"
sed -i 's/^ recipe-placeholder/\t@printf "built\\n" >> "$@"/' "$TEST_DIR/firmware.mk"
firmware_make() {
    make --no-print-directory -C "$TEST_DIR" -f firmware.mk \
        BSP_SOC_SOURCE="$SOURCE" BSP_SOC_HEADER="$TEST_DIR/bsp/soc_defs.h" > /dev/null
}
firmware_make
firmware_make
test "$(wc -l < "$TEST_DIR/object")" -eq 1
apply_config
firmware_make
test "$(wc -l < "$TEST_DIR/object")" -eq 2
sed '/^CONFIG_SOC_CPU_HZ=/d' "$CONFIG" > "$TEST_DIR/legacy.config"
"$TOOL" seed --source "$SOURCE" --config "$TEST_DIR/legacy.config"
rg -q '^CONFIG_SOC_CPU_HZ=90000000$' "$TEST_DIR/legacy.config"
rg -q '^CONFIG_SOC_PROFILE_FULL=y$' "$TEST_DIR/legacy.config"
(cd "$TEST_DIR"; KCONFIG_CONFIG="$TEST_DIR/legacy.config" KCONFIG_AUTOCONFIG="$TEST_DIR/auto.conf" \
    KCONFIG_AUTOHEADER="$TEST_DIR/autoconf.h" srctree="$ROOT" \
    "$ROOT/build/kconfig/conf" --olddefconfig "$ROOT/Kconfig" > /dev/null)
rg -q '^CONFIG_SOC_CPU_HZ=90000000$' "$TEST_DIR/legacy.config"
"$TOOL" seed --source "$SOURCE" --config "$TEST_DIR/new.config"
rg -q '^CONFIG_SOC_CPU_HZ=90000000$' "$TEST_DIR/new.config"

# BRAM selection updates both paths, retaining frequency and unrelated clocks.
sed 's/^CONFIG_SOC_PROFILE_FULL=y$/# CONFIG_SOC_PROFILE_FULL is not set/;s/^# CONFIG_SOC_PROFILE_BRAM is not set$/CONFIG_SOC_PROFILE_BRAM=y/' \
    "$CONFIG" > "$TEST_DIR/bram.config"
cp "$TEST_DIR/bram.config" "$CONFIG"
# A profile change without a matching FDC update is unsafe even at the same Hz.
sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/before.sha"
if "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
    --bsp-output-dir "$TEST_DIR/bsp" > /dev/null 2> "$TEST_DIR/error.log"; then exit 1; fi
rg -q 'changing hardware profile requires --fdc' "$TEST_DIR/error.log"
sha256sum "$SOURCE" "$FDC" "$OUT"/* "$TEST_DIR/bsp"/* > "$TEST_DIR/after.sha"
cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
apply_config
check_config
check_paths bram
rg -q 'SOC_CPU_MEM_BRAM +1$' "$SOURCE"

# Independently stale JTAG and PLL paths must be detected (not just the ratio).
cp "$FDC" "$TEST_DIR/good.fdc"
for endpoint in jtag pll io; do
    case "$endpoint" in
        jtag) sed 's@g_bram_profile.u_bram_profile/JTAG_TCK_in@JTAG_TCK_in@' "$TEST_DIR/good.fdc" ;;
        pll) sed 's@g_bram_profile.u_bram_profile/u_pll/u_gpll:CLKOUT0@u_pll/u_gpll:CLKOUT0@' "$TEST_DIR/good.fdc" ;;
        io) sed '/^define_attribute {p:mem_ck} {PAP_IO_STANDARD}/s/HSTL15_I/HSTL15D_I/' "$TEST_DIR/good.fdc" ;;
    esac > "$FDC"
    if check_config 2> "$TEST_DIR/error.log"; then echo "FAIL accepted stale $endpoint path" >&2; exit 1; fi
    rg -q 'CPU/JTAG FDC paths or clock ratio or DDR IO standards are stale' "$TEST_DIR/error.log"
    apply_config
    check_config
    check_paths bram
done

# Repeat both directions and frequencies; no-op apply must preserve FDC mtime.
for hz in 70000000 90000000; do
    config_for "$hz"
    apply_config
    check_config
    check_paths full
    rg -q 'SOC_CPU_MEM_BRAM +0$' "$SOURCE"
    sed 's/^CONFIG_SOC_PROFILE_FULL=y$/# CONFIG_SOC_PROFILE_FULL is not set/;s/^# CONFIG_SOC_PROFILE_BRAM is not set$/CONFIG_SOC_PROFILE_BRAM=y/' \
        "$CONFIG" > "$TEST_DIR/bram.config"
    cp "$TEST_DIR/bram.config" "$CONFIG"
    apply_config
    check_config
    check_paths bram
    before=$(stat -c '%y' "$FDC")
    apply_config
    test "$before" = "$(stat -c '%y' "$FDC")"
done
echo SOC_CLOCK_CONFIG_PASS
