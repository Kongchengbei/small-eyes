#!/usr/bin/env bash
set -euo pipefail
# Failed assertions must not leave large core dumps in the workspace.
ulimit -c 0

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

list_tests() {
    find sim temp/tests -maxdepth 1 -type f \( -name 'tb_*.sv' -o -name 'tb_*.v' \) \
        -printf '%f\n' | sort
}

selector="${1:-}"
if [[ "$selector" == --list ]]; then
    list_tests
    exit 0
fi
if [[ -z "$selector" ]]; then
    echo 'usage: make all=tb_Hcsrrun [SIM_ARGS="+..."] [SIM_PROGRAM=path/to/program.hex]' >&2
    echo '       make sim-list' >&2
    exit 2
fi

# Accept a basename or sim/basename, optionally followed by .sv/.v and run.
selector="${selector#sim/}"
selector="${selector#temp/tests/}"
selector="${selector%run}"
selector="${selector%.sv}"
selector="${selector%.v}"
if [[ ! "$selector" =~ ^tb_[a-zA-Z0-9_]+$ ]]; then
    echo "error: invalid testbench selector: ${1:-}" >&2
    exit 2
fi
testbench=""
for candidate in "sim/$selector.sv" "sim/$selector.v" \
                "temp/tests/$selector.sv" "temp/tests/$selector.v"; do
    if [[ -f "$candidate" ]]; then
        testbench="$candidate"
        break
    fi
done
if [[ -z "$testbench" ]]; then
    echo "error: testbench not found in sim/ or temp/tests/: $selector.sv/.v; use make sim-list" >&2
    exit 2
fi

if [[ "$selector" == tb_coremark_bram_uart || "$selector" == tb_hfpga_soc_bram_boot ]]; then
    echo "error: $selector is a legacy Flash-to-BRAM startup bench; the production BRAM profile now boots from vendor INIT parameters." >&2
    echo 'Use tb_coremark_bram_ip_uart for production startup, or tb_cpu_bram_ip_mem for the full vendor-memory check.' >&2
    exit 2
fi

simulator="${SIMULATOR:-verilator}"
jobs="${SIM_JOBS:-2}"
timeout_seconds="${SIM_TIMEOUT:-120}"
if [[ ! "$jobs" =~ ^[1-9][0-9]*$ || ! "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
    echo 'error: SIM_JOBS and SIM_TIMEOUT must be positive integers' >&2
    exit 2
fi
if [[ "$simulator" != verilator && "$simulator" != iverilog ]]; then
    echo 'error: SIMULATOR must be verilator or iverilog' >&2
    exit 2
fi
command -v "$simulator" >/dev/null || { echo "error: missing simulator: $simulator" >&2; exit 2; }
command -v timeout >/dev/null || { echo 'error: missing timeout command' >&2; exit 2; }

run_args=()
extra_flags=()
if [[ -n "${SIM_ARGS:-}" ]]; then read -r -a run_args <<< "$SIM_ARGS"; fi
if [[ -n "${SIM_FLAGS:-}" ]]; then read -r -a extra_flags <<< "$SIM_FLAGS"; fi

program="${SIM_PROGRAM:-}"
for arg in "${run_args[@]}"; do
    if [[ "$arg" == +PROGRAM=* ]]; then
        if [[ -n "$program" ]]; then
            echo 'error: specify only one of SIM_PROGRAM or SIM_ARGS=+PROGRAM=...' >&2
            exit 2
        fi
        program="${arg#+PROGRAM=}"
    fi
done
if [[ -n "$program" ]]; then
    if [[ ! -f "$program" ]]; then
        echo "error: program image not found: $program" >&2
        exit 2
    fi
    if [[ -n "${SIM_PROGRAM:-}" ]]; then
        run_args+=("+PROGRAM=$(realpath "$program")")
    fi
fi

if [[ "${SIM_BUILD_ONLY:-0}" != 1 ]]; then
    case "$selector" in
        tb_Htop|tb_Htop_rv32m)
            if [[ -z "$program" && ! -f inst.txt ]]; then
                echo "error: $selector needs a program; pass SIM_PROGRAM=path/to/program.hex" >&2
                exit 2
            fi
            ;;
        tb_camera_diag_firmware|tb_camera_stereo_firmware)
            if [[ -z "$program" ]]; then
                echo "error: $selector requires SIM_PROGRAM=path/to/firmware.hex" >&2
                exit 2
            fi
            ;;
        tb_coremark|tb_coremark_probe)
            if [[ ! -f ../source/soc/coremark.dat ]]; then
                echo "error: legacy $selector hardcodes ../source/soc/coremark.dat; that image is missing" >&2
                echo 'Use the maintained tb_Htop with SIM_PROGRAM=... SIM_ARGS="+COREMARK ..." instead.' >&2
                exit 2
            fi
            ;;
    esac
fi

# Use behavioural cache SRAM instead of the duplicate vendor wrapper.
mapfile -t rtl_sources < <(find cpu soc jtag -type f \
    \( -name '*.v' -o -name '*.sv' \) ! -path cpu/cache_bram.v | sort)
sources=("${rtl_sources[@]}" sim/camera_ddr_model.sv sim/ov5640_sccb_model.sv)
if [[ "$selector" == tb_cpu_bram_ip_mem || "$selector" == tb_coremark_bram_ip_uart ]]; then
    pds_sim_dir="${PDS_SIM_DIR:-/mnt/f/PDS_2022.2-SP6.4/arch/vendor/pango/verilog/simulation}"
    for required_file in \
        "$pds_sim_dir/GTP_DRM36K_E1.v" "$pds_sim_dir/GTP_GRS.v" \
        IP/imem/imem.v IP/imem/rtl/ipm2l_dpram_v1_9_imem.v IP/imem/rtl/imem_init_param.v IP/imem/rtl/imem_init_words.hex \
        IP/dmem/dmem.v IP/dmem/rtl/ipm2l_dpram_v1_9_dmem.v IP/dmem/rtl/dmem_init_param.v \
        cpu/cpu_bram_ip_mem.v; do
        if [[ ! -f "$required_file" ]]; then
            echo "error: vendor BRAM simulation input missing: $required_file" >&2
            echo 'Set PDS_SIM_DIR to the PDS Verilog simulation-model directory if needed.' >&2
            exit 2
        fi
    done
    sources+=(
        IP/imem/imem.v IP/imem/rtl/ipm2l_dpram_v1_9_imem.v
        IP/dmem/dmem.v IP/dmem/rtl/ipm2l_dpram_v1_9_dmem.v
        "$pds_sim_dir/GTP_DRM36K_E1.v" "$pds_sim_dir/GTP_GRS.v"
    )
    extra_flags+=(-IIP/imem/rtl -IIP/dmem/rtl)
fi
if [[ "$selector" == tb_coremark_bram_ip_uart ]]; then
    pds_sim_dir="${PDS_SIM_DIR:-/mnt/f/PDS_2022.2-SP6.4/arch/vendor/pango/verilog/simulation}"
    if [[ ! -f "$pds_sim_dir/GTP_CFGCLK.v" ]]; then
        echo "error: vendor BRAM simulation input missing: $pds_sim_dir/GTP_CFGCLK.v" >&2
        echo 'Set PDS_SIM_DIR to the PDS Verilog simulation-model directory if needed.' >&2
        exit 2
    fi
    sources+=(sim/stubs/bram_profile_clock_stubs.v "$pds_sim_dir/GTP_CFGCLK.v")
    extra_flags+=(-DBRAM_VENDOR_IP_SIM -DBRAM_UART_REAL_CLOCK)
fi
sources+=("$testbench")

out_dir="$repo_root/build/sim/$selector/$simulator"
mkdir -p "$out_dir"
echo "SIM BUILD: $testbench ($simulator)"
if [[ "$simulator" == verilator ]]; then
    # A warning is still recorded in build.log; unsupported RTL remains fatal.
    # BLKLOOPINIT is the established workaround for array-reset loop elaboration.
    if ! CCACHE_DISABLE="${CCACHE_DISABLE:-1}" "$simulator" --binary --timing --assert \
        --language 1800-2012 -Wno-fatal -Wno-BLKLOOPINIT \
        -I. -Isoc -Icpu --top-module "$selector" -j "$jobs" \
        --Mdir "$out_dir/obj" -o simulator "${extra_flags[@]}" "${sources[@]}" \
        >"$out_dir/build.log" 2>&1; then
        tail -n 100 "$out_dir/build.log" >&2
        echo "error: compilation failed; full log: $out_dir/build.log" >&2
        exit 1
    fi
    command=("$out_dir/obj/simulator")
else
    command -v vvp >/dev/null || { echo 'error: missing vvp' >&2; exit 2; }
    if ! "$simulator" -g2012 -I. -Isoc -Icpu -s "$selector" \
        -o "$out_dir/simulator.vvp" "${extra_flags[@]}" "${sources[@]}" \
        >"$out_dir/build.log" 2>&1; then
        tail -n 100 "$out_dir/build.log" >&2
        echo "error: compilation failed; full log: $out_dir/build.log" >&2
        exit 1
    fi
    command=(vvp "$out_dir/simulator.vvp")
fi
echo "SIM BUILD LOG: $out_dir/build.log"
if [[ "${SIM_BUILD_ONLY:-0}" == 1 ]]; then exit 0; fi

echo "SIM RUN: $selector (timeout ${timeout_seconds}s)"
if timeout --foreground "$timeout_seconds" "${command[@]}" "${run_args[@]}" \
    2>&1 | tee "$out_dir/run.log"; then
    :
else
    status=$?
    if [[ "$status" == 124 ]]; then
        echo "error: simulation exceeded ${timeout_seconds}s; log: $out_dir/run.log" >&2
    else
        echo "error: simulator failed (exit $status); log: $out_dir/run.log" >&2
    fi
    exit "$status"
fi
if rg -q 'TEST_FAIL|TEST_TIMEOUT|(^|[[:space:]])FAIL([[:space:]:]|$)' "$out_dir/run.log"; then
    echo "error: testbench reported failure; log: $out_dir/run.log" >&2
    exit 1
fi
echo "SIM RUN LOG: $out_dir/run.log"
