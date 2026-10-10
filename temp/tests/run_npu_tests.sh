#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

tests=(
    tb_soc_addr_map
    tb_npu_ctrl
    tb_npu_dma
    tb_axi_2m1s_arbiter
    tb_npu_fc_engine
    tb_npu_quant
    tb_npu_service
    tb_npu_service_drop
    tb_npu_result_mmio
    tb_npu_system
)

for testbench in "${tests[@]}"; do
    echo "NPU TEST: $testbench"
    SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
        SIM_JOBS="${SIM_JOBS:-2}" \
        SIMULATOR="${SIMULATOR:-verilator}" \
        bash scripts/run_testbench.sh "$testbench"
done

# Candidate model-driven CNN path.  These are kept in the same A-side
# regression so FC compatibility and the new service path cannot drift apart.
SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
    SIM_JOBS="${SIM_JOBS:-2}" \
    SIMULATOR="${SIMULATOR:-verilator}" \
    bash temp/tests/run_npu_cnn_test.sh
SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
    SIM_JOBS="${SIM_JOBS:-2}" \
    SIMULATOR="${SIMULATOR:-verilator}" \
bash temp/tests/run_npu_cnn_service_test.sh
SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
    SIM_JOBS="${SIM_JOBS:-2}" \
    SIMULATOR="${SIMULATOR:-verilator}" \
    bash temp/tests/run_npu_cnn_system_test.sh

road_golden_dir="temp/路标模型包与前处理金样v0.1"
if [[ -f "$road_golden_dir/model.json" ]]; then
    SIM_TIMEOUT="${SIM_TIMEOUT:-120}" \
        SIM_JOBS="${SIM_JOBS:-2}" \
        SIMULATOR="${SIMULATOR:-verilator}" \
        bash temp/tests/run_npu_road_model_test.sh
    SIM_TIMEOUT="${SIM_TIMEOUT:-600}" \
        SIM_JOBS="${SIM_JOBS:-2}" \
        SIMULATOR="${SIMULATOR:-verilator}" \
        bash temp/tests/run_npu_road_model_all_test.sh
    echo "NPU_TEST_ROAD_GOLDEN=RUN"
    extra_count=2
else
    echo "NPU_TEST_ROAD_GOLDEN=SKIP missing $road_golden_dir/model.json"
    extra_count=0
fi

echo "NPU_TEST_PASS count=$((${#tests[@]} + 3 + extra_count)) simulator=${SIMULATOR:-verilator}"
