SHELL := /bin/sh

VERILATOR ?= verilator
PYTHON    ?= python3

# The managed environment exposes ccache through g++, but its cache directory
# may be read-only. Verilator's generated makefile honors this switch.
export CCACHE_DISABLE ?= 1

BUILD_DIR := build
OBJ_DIR   := $(BUILD_DIR)/obj_dir
SIM_BIN   := $(OBJ_DIR)/Vtb_Htop
SIM_TB    := sim/tb_Htop.sv
ISA_DIR   ?= sim/test
ISA_OUT   := $(BUILD_DIR)/isa

# Htop exposes an AXI master, so the testbench also needs the serialized
# memory backend used by the SoC.
CPU_RTL := $(filter-out cpu/cache_bram.v cpu/cache_sram_beh.v,$(wildcard cpu/*.v))
SIM_RTL := soc/axi_mem_backend.v cpu/cache_sram_beh.v

.PHONY: sim lint clean

sim: $(SIM_BIN)
	@$(PYTHON) -B sim/test.py \
		--sim "$(abspath $(SIM_BIN))" \
		--tests "$(abspath $(ISA_DIR))" \
		--output "$(abspath $(ISA_OUT))"


$(SIM_BIN): $(CPU_RTL) $(SIM_RTL) $(SIM_TB)
	@mkdir -p "$(OBJ_DIR)"
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--top-module tb_Htop \
		--Mdir "$(OBJ_DIR)" \
		$(CPU_RTL) $(SIM_RTL) $(SIM_TB)

lint:
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--top-module Htop \
		$(CPU_RTL) $(SIM_RTL)

clean:
	rm -rf -- "$(BUILD_DIR)" tb.vcd tb.view
