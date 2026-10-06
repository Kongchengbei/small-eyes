# Shared by firmware builds. Check/generate the authoritative headers on every
# build, but preserve their timestamps if the contents did not change.
BSP_SOC_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
BSP_SOC_SOURCE := $(BSP_SOC_ROOT)/soc/soc_addr_map.vh
BSP_SOC_TOOL := $(BSP_SOC_ROOT)/build/menuconfig/soc_config
BSP_SOC_HEADER := $(BSP_SOC_ROOT)/bsp/include/soc_defs.h
BSP_SOC_ASM_HEADER := $(BSP_SOC_ROOT)/bsp/include/soc_defs_asm.inc

.PHONY: bsp-soc-config-force
bsp-soc-config-force:

$(BSP_SOC_TOOL): $(BSP_SOC_ROOT)/scripts/soc_config.c
	@$(MAKE) --no-print-directory -C '$(BSP_SOC_ROOT)' build/menuconfig/soc_config

$(BSP_SOC_HEADER): bsp-soc-config-force $(BSP_SOC_SOURCE) $(BSP_SOC_TOOL)
	@'$(BSP_SOC_TOOL)' generate-header --source '$(BSP_SOC_SOURCE)' \
	 --output-dir '$(dir $(BSP_SOC_HEADER))'

$(BSP_SOC_ASM_HEADER): $(BSP_SOC_HEADER)
	@test -f '$@' || '$(BSP_SOC_TOOL)' generate-header --source '$(BSP_SOC_SOURCE)' \
	 --output-dir '$(dir $(BSP_SOC_HEADER))'
