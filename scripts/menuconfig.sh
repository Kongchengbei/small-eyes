#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

absolute_path() {
	case "$1" in
		/*) printf '%s\n' "$1" ;;
		*) printf '%s/%s\n' "$ROOT" "$1" ;;
	esac
}

SOC_CONFIG_SOURCE=$(absolute_path "${SOC_CONFIG_SOURCE:-soc/soc_addr_map.vh}")
SOC_CONFIG_FILE=$(absolute_path "${SOC_CONFIG_FILE:-build/menuconfig/.config}")
SOC_CONFIG_OUTPUT=$(absolute_path "${SOC_CONFIG_OUTPUT:-build/menuconfig}")
SOC_CONFIG_FDC=$(absolute_path "${SOC_CONFIG_FDC:-soc.fdc}")
SOC_CONFIG_BSP_OUTPUT=$(absolute_path "${SOC_CONFIG_BSP_OUTPUT:-bsp/include}")

CONFIG_DIR=$(dirname -- "$SOC_CONFIG_FILE")
mkdir -p "$CONFIG_DIR" "$SOC_CONFIG_OUTPUT"

SOC_TOOL="$ROOT/build/menuconfig/soc_config"

# Seed only initializes a missing config; later invocations preserve saved UI state.
"$SOC_TOOL" seed --source "$SOC_CONFIG_SOURCE" --config "$SOC_CONFIG_FILE"

run_conf() (
	cd -- "$SOC_CONFIG_OUTPUT"
	export KCONFIG_CONFIG="$SOC_CONFIG_FILE"
	export KCONFIG_AUTOCONFIG="$SOC_CONFIG_OUTPUT/auto.conf"
	export KCONFIG_AUTOHEADER="$SOC_CONFIG_OUTPUT/autoconf.h"
	export srctree="$ROOT"
	"$ROOT/build/kconfig/conf" --olddefconfig "$ROOT/Kconfig"
)

run_conf

BASELINE=$(mktemp "$SOC_CONFIG_OUTPUT/.menuconfig-baseline.XXXXXX")
cp "$SOC_CONFIG_FILE" "$BASELINE"
BEFORE=$(stat -c '%i:%s:%y' "$SOC_CONFIG_FILE")
cleanup() { rm -f -- "$BASELINE"; }
trap cleanup EXIT HUP INT TERM

# Ask mconf to rewrite the selected default config on explicit Save, even if
# the resulting symbols equal their previous values. Discard never writes it.
export KCONFIG_OVERWRITECONFIG=1
(
	cd -- "$SOC_CONFIG_OUTPUT"
	export KCONFIG_CONFIG="$SOC_CONFIG_FILE"
	export KCONFIG_AUTOCONFIG="$SOC_CONFIG_OUTPUT/auto.conf"
	export KCONFIG_AUTOHEADER="$SOC_CONFIG_OUTPUT/autoconf.h"
	export srctree="$ROOT"
	"$ROOT/build/kconfig/mconf" "$ROOT/Kconfig"
)

# mconf writes the default config only after an explicit Save confirmation.
# Discard, Esc/Esc, and Save As leave this default file unchanged.
AFTER=$(stat -c '%i:%s:%y' "$SOC_CONFIG_FILE")
if ! cmp -s -- "$BASELINE" "$SOC_CONFIG_FILE" || [ "$BEFORE" != "$AFTER" ]; then
	cd "$ROOT"
	"$SOC_TOOL" apply --source "$SOC_CONFIG_SOURCE" --config "$SOC_CONFIG_FILE" \
		--output-dir "$SOC_CONFIG_OUTPUT" --fdc "$SOC_CONFIG_FDC" \
		--bsp-output-dir "$SOC_CONFIG_BSP_OUTPUT"
else
	echo "Configuration unchanged; authoritative address map was not modified."
fi
