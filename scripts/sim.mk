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

.PHONY: sim-run sim-list run all
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
