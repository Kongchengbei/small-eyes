#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

# The simulator auto-discovers sources; PDS does not. Keep the synthesis
# project list in sync with every NPU and INT8 front-end module.
for rtl in soc/Hnpu_*.v soc/Hrgb565_int8_*.v; do
    if ! rg -Fq "\"../$rtl\"" project/project.pds; then
        echo "NPU_SOC_LINT_FAIL missing PDS source: $rtl" >&2
        exit 1
    fi
done

mapfile -t rtl_sources < <(find cpu soc jtag -type f \
    \( -name '*.v' -o -name '*.sv' \) \
    ! -path 'cpu/cache_bram.v' \
    ! -path 'soc/Hfpga_soc_bram_profile.v' | sort)

# Board IP is stubbed here. This checks RTL elaboration and the top-level
# signal widths; it is not a replacement for PDS synthesis or timing closure.
for profile_flags in \
    '' \
    '-GPREPROCESS_V04_CANDIDATE=0 -GPREPROCESS_V04_REDBLUE_ONLY=0 -GPREPROCESS_V04_REDBLUE_28=0' \
    '-GPREPROCESS_V04_REDBLUE_ONLY=1' \
    '-GPREPROCESS_V04_REDBLUE_28=1' \
    '-GPREPROCESS_V04_CANDIDATE=1 -GPREPROCESS_V04_REDBLUE_ONLY=0 -GPREPROCESS_V04_REDBLUE_28=0'; do
    read -r -a profile_options <<< "$profile_flags"
    if ! lint_output=$(verilator --lint-only --timing --language 1800-2012 \
        -I. -Isoc -Wno-fatal -Wno-BLKLOOPINIT \
        --top-module Hfpga_soc -GCPU_MEM_BRAM=0 -GPREPROCESS_ENABLE=1 \
        "${profile_options[@]}" "${rtl_sources[@]}" sim/board_ip_lint_stubs.v 2>&1); then
        printf '%s\n' "$lint_output" >&2
        echo "NPU_SOC_LINT_FAIL elaboration: $profile_flags" >&2
        exit 1
    fi

    if printf '%s\n' "$lint_output" |
        rg -q '^%Warning-(WIDTHTRUNC|WIDTHEXPAND): soc/Hfpga_soc.v:'; then
        printf '%s\n' "$lint_output" |
            rg '^%Warning-(WIDTHTRUNC|WIDTHEXPAND): soc/Hfpga_soc.v:' >&2
        echo "NPU_SOC_LINT_FAIL top-level width mismatch: $profile_flags" >&2
        exit 1
    fi
done

echo 'NPU_SOC_LINT_PASS PDS_sources=complete top=Hfpga_soc profiles=default-full-candidate,legacy,redblue-only,redblue-28,full-candidate'
