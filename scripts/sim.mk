# Preserve plain `make` as menuconfig; the user's all= selector runs simulation.
ifneq ($(strip $(all)),)
.DEFAULT_GOAL := sim-run
endif

SIMULATOR ?= verilator
SIM_JOBS ?= 2
SIM_TIMEOUT ?= 120
SIM_ARGS ?=
SIM_FLAGS ?=
SIM_PROGRAM ?=
SIM_BUILD_ONLY ?= 0

.PHONY: sim-run sim-list run all \
	npu-test npu-ctrl npu-dma npu-arbiter npu-fc-engine \
	npu-service npu-service-drop npu-result-mmio npu-system npu-model npu-quant npu-cnn npu-cnn-96-cache npu-image-service npu-image-system npu-cnn-service npu-cnn-system npu-road-all
sim-run:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 SIM_ARGS='$(SIM_ARGS)' SIM_FLAGS='$(SIM_FLAGS)' SIM_PROGRAM='$(SIM_PROGRAM)' \
	 SIM_BUILD_ONLY='$(SIM_BUILD_ONLY)' bash scripts/run_testbench.sh '$(all)'

run all: sim-run

# Examples: make tb_Hcsrrun; make tb_Hcsr.svrun.
%run:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 SIM_ARGS='$(SIM_ARGS)' SIM_FLAGS='$(SIM_FLAGS)' SIM_PROGRAM='$(SIM_PROGRAM)' \
	 SIM_BUILD_ONLY='$(SIM_BUILD_ONLY)' bash scripts/run_testbench.sh '$@'

sim-list:
	@bash scripts/run_testbench.sh --list

# A-side V1 regression. These aliases intentionally cover only the existing
# independent NPU boundary tests; they do not claim Hfpga_soc CNN integration.
npu-test:
	@CCACHE_DISABLE='$(CCACHE_DISABLE)' SIMULATOR='$(SIMULATOR)' \
	 SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/test_npu_model.sh
	@CCACHE_DISABLE='$(CCACHE_DISABLE)' SIMULATOR='$(SIMULATOR)' \
	 SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_tests.sh

npu-model:
	@bash temp/tests/test_npu_model.sh

npu-quant:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_quant

npu-cnn:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_cnn_test.sh

npu-cnn-96-cache:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_cnn_96_cache_test.sh

npu-image-service:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_image_service_test.sh

npu-image-system:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_image_system_test.sh

npu-cnn-service:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_cnn_service_test.sh

npu-cnn-system:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_cnn_system_test.sh

npu-road-all:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash temp/tests/run_npu_road_model_all_test.sh

npu-ctrl:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_ctrl

npu-dma:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_dma

npu-arbiter:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_axi_2m1s_arbiter

npu-fc-engine:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_fc_engine

npu-service:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_service

npu-service-drop:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_service_drop

npu-result-mmio:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_result_mmio

npu-system:
	@SIMULATOR='$(SIMULATOR)' SIM_JOBS='$(SIM_JOBS)' SIM_TIMEOUT='$(SIM_TIMEOUT)' \
	 bash scripts/run_testbench.sh tb_npu_system
