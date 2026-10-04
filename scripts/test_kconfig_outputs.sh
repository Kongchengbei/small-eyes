#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d /tmp/soc-kconfig-outputs.XXXXXX)
cleanup() {
	case "$TEST_DIR" in
		/tmp/soc-kconfig-outputs.*) rm -rf -- "$TEST_DIR" ;;
	esac
}
trap cleanup EXIT HUP INT TERM

cd -- "$TEST_DIR"
export KCONFIG_CONFIG="$TEST_DIR/.config"
export KCONFIG_AUTOCONFIG="$TEST_DIR/auto.conf"
export KCONFIG_AUTOHEADER="$TEST_DIR/autoconf.h"
export srctree="$ROOT"
CONF="$ROOT/build/kconfig/conf"

check_outputs() {
	test -s "$KCONFIG_CONFIG"
	test -s "$KCONFIG_AUTOCONFIG"
	test -s "$KCONFIG_AUTOHEADER"
	if [ -d include/config ]; then
		if find include/config -type f -name '*.h' | rg -q .; then
			echo "FAIL: per-symbol header stamps were generated" >&2
			exit 1
		fi
	fi
}

# First generation: no previous configuration or dependency stamps exist.
"$CONF" --alldefconfig "$ROOT/Kconfig"
check_outputs
rg -q '^CONFIG_SOC_PROFILE_FULL=y$' "$KCONFIG_AUTOCONFIG"
rg -q '^#define CONFIG_SOC_PROFILE_FULL 1$' "$KCONFIG_AUTOHEADER"

# Changed settings must still update the real configuration outputs.
"$CONF" --allyesconfig "$ROOT/Kconfig"
"$CONF" --syncconfig "$ROOT/Kconfig"
check_outputs
rg -q '^#define CONFIG_SOC_ENABLE_PREPROCESS 1$' "$KCONFIG_AUTOHEADER"
"$CONF" --alldefconfig "$ROOT/Kconfig"
"$CONF" --syncconfig "$ROOT/Kconfig"
check_outputs
if rg -q '^#define CONFIG_SOC_ENABLE_PREPROCESS ' "$KCONFIG_AUTOHEADER"; then
	echo "FAIL: disabled configuration remained in autoconf.h" >&2
	exit 1
fi

# Removing a symbol exercises the second conf_touch_dep call site.
"$CONF" --alldefconfig "$ROOT/scripts/kconfig/tests/obsolete.Kconfig"
"$CONF" --syncconfig "$ROOT/scripts/kconfig/tests/obsolete.Kconfig"
check_outputs
rg -q '^CONFIG_SOC_OBSOLETE_STAMP_TEST=y$' "$KCONFIG_AUTOCONFIG"
"$CONF" --alldefconfig "$ROOT/Kconfig"
"$CONF" --syncconfig "$ROOT/Kconfig"
check_outputs
if rg -q 'CONFIG_SOC_OBSOLETE_STAMP_TEST' "$KCONFIG_AUTOCONFIG" "$KCONFIG_AUTOHEADER"; then
	echo "FAIL: obsolete configuration remained in generated outputs" >&2
	exit 1
fi

echo "KCONFIG_OUTPUTS_PASS"
