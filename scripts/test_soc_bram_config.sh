#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d /tmp/soc-bram-config.XXXXXX)
cleanup() {
    case "$TEST_DIR" in /tmp/soc-bram-config.*) rm -rf -- "$TEST_DIR" ;; esac
}
trap cleanup EXIT HUP INT TERM
TOOL="$ROOT/build/menuconfig/soc_config"
mkdir -p "$TEST_DIR/soc" "$TEST_DIR/IP/imem/rtl" "$TEST_DIR/bsp"
cp "$ROOT/soc/soc_addr_map.vh" "$TEST_DIR/soc/"
cp "$ROOT/soc.fdc" "$TEST_DIR/soc.fdc"
cp "$ROOT/IP/imem/imem.v" "$TEST_DIR/IP/imem/"
cp "$ROOT/scripts/tests/bram_config.hex" "$TEST_DIR/program.dat"
SOURCE="$TEST_DIR/soc/soc_addr_map.vh"
CONFIG="$TEST_DIR/.config"
OUT="$TEST_DIR/output"
INIT="$TEST_DIR/IP/imem/rtl"
image="$TEST_DIR/program.dat"
config_bram() {
    # Hidden DDR/Flash fields are deliberately absent, just as in Kconfig.
    printf '%s\n' '# CONFIG_SOC_PROFILE_FULL is not set' 'CONFIG_SOC_PROFILE_BRAM=y' \
        '# CONFIG_SOC_ENABLE_PREPROCESS is not set' 'CONFIG_SOC_UART_LOCAL=y' \
        '# CONFIG_SOC_UART_REMOTE is not set' "CONFIG_SOC_CPU_HZ=${test_hz:-70000000}" \
        "CONFIG_SOC_FIRMWARE_HEX=\"$image\"" > "$CONFIG"
}
apply_config() {
    "$TOOL" apply --source "$SOURCE" --config "$CONFIG" --output-dir "$OUT" \
        --fdc "$TEST_DIR/soc.fdc" --bsp-output-dir "$TEST_DIR/bsp" \
        --bram-init-dir "$INIT" > "$TEST_DIR/apply.log"
}
snapshot() {
    sha256sum "$SOURCE" "$TEST_DIR/soc.fdc" "$TEST_DIR/IP/imem/imem.v" \
        "$INIT"/* "$OUT"/* "$TEST_DIR/bsp"/*
}
config_bram
apply_config
rg -q "SOC_BOOT_IMAGE_BYTES +32'd0$" "$SOURCE"
rg -q '"input_words": 3,' "$OUT/bram_init_manifest.json"
rg -q '"decoded_program_bytes": 12,' "$OUT/bram_init_manifest.json"
rg -q '"user_load_required": false' "$OUT/flash_manifest.json"
rg -q '"input_bin": null' "$OUT/flash_manifest.json"
test "$(wc -l < "$INIT/imem_init_words.hex")" -eq 8192
test "$(sed -n '2p' "$INIT/imem_init_words.hex")" = 00100093
test "$(sed -n '8192p' "$INIT/imem_init_words.hex")" = 00000013
"$TOOL" check --source "$SOURCE" --fdc "$TEST_DIR/soc.fdc" \
    --header "$TEST_DIR/bsp/soc_defs.h" --asm "$TEST_DIR/bsp/soc_defs_asm.inc" > /dev/null

# Identical saves preserve source/header/IP mtimes. A new image at the same
# path changes the listed wrapper's fingerprint as well as RAM parameters.
before=$(stat -c '%y' "$INIT/imem_init_param.v" "$TEST_DIR/IP/imem/imem.v")
apply_config
test "$before" = "$(stat -c '%y' "$INIT/imem_init_param.v" "$TEST_DIR/IP/imem/imem.v")"
old_marker=$(rg 'SOC_BRAM_IMAGE_FINGERPRINT:' "$TEST_DIR/IP/imem/imem.v")
printf '%s\n' '00000013' '00200093' '0000006f' > "$image"
apply_config
test "$old_marker" != "$(rg 'SOC_BRAM_IMAGE_FINGERPRINT:' "$TEST_DIR/IP/imem/imem.v")"

# Reject malformed/missing/raw input without partially changing outputs.
snapshot > "$TEST_DIR/before.sha"
for invalid in malformed empty missing binary oversize; do
    image="$TEST_DIR/$invalid.dat"
    case "$invalid" in
        malformed) printf '%s\n' 1234 > "$image" ;;
        empty) : > "$image" ;;
        missing) : ;;
        binary) printf '\000\023\000\000' > "$image" ;;
        oversize) awk 'BEGIN {for(i=0;i<8193;i++) print "00000013"}' > "$image" ;;
    esac
    config_bram
    if apply_config 2> "$TEST_DIR/error.log"; then echo "FAIL accepted $invalid DAT" >&2; exit 1; fi
    snapshot > "$TEST_DIR/after.sha"
    cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
done
image="$INIT/imem_init_words.hex"
config_bram
if apply_config 2> "$TEST_DIR/error.log"; then echo 'FAIL overwrote input image' >&2; exit 1; fi
snapshot > "$TEST_DIR/after.sha"
cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"

# A commit failure after the large INIT files have been replaced rolls those
# files and the listed wrapper back along with the authority and headers.
image="$TEST_DIR/program.dat"
printf '%s\n' '00000013' '00300093' '0000006F' > "$image"
test_hz=70500000
config_bram
cc -shared -fPIC -Wall -Wextra -Werror "$ROOT/scripts/tests/rename_fault.c" \
    -ldl -o "$TEST_DIR/rename_fault.so"
if LD_PRELOAD="$TEST_DIR/rename_fault.so" SOC_CONFIG_TEST_FAIL_RENAME_TARGET="$SOURCE" \
    apply_config 2> "$TEST_DIR/error.log"; then
    echo 'FAIL accepted injected commit error' >&2; exit 1
fi
snapshot > "$TEST_DIR/after.sha"
cmp "$TEST_DIR/before.sha" "$TEST_DIR/after.sha"
unset test_hz

# Switching to DDR must leave initialized BRAM files untouched and restore
# the normal nonzero Flash-loader configuration.
sha256sum "$INIT"/* "$TEST_DIR/IP/imem/imem.v" > "$TEST_DIR/init.before.sha"
printf '%s\n' 'CONFIG_SOC_PROFILE_FULL=y' '# CONFIG_SOC_PROFILE_BRAM is not set' \
    '# CONFIG_SOC_ENABLE_PREPROCESS is not set' 'CONFIG_SOC_UART_LOCAL=y' \
    '# CONFIG_SOC_UART_REMOTE is not set' \
    'CONFIG_SOC_CPU_HZ=70000000' 'CONFIG_SOC_FIRMWARE_BIN=""' \
    'CONFIG_SOC_FLASH_BASE=0xA00000' 'CONFIG_SOC_BOOT_IMAGE_BYTES=32768' > "$CONFIG"
apply_config
rg -q "SOC_BOOT_IMAGE_BYTES +32'd32768$" "$SOURCE"
sha256sum "$INIT"/* "$TEST_DIR/IP/imem/imem.v" > "$TEST_DIR/init.after.sha"
cmp "$TEST_DIR/init.before.sha" "$TEST_DIR/init.after.sha"
printf '%s\n' 'PASS BRAM menu configuration, image fingerprint, input rejection, and DDR isolation'
