SOC_CONFIG_SOURCE ?= soc/soc_addr_map.vh
SOC_CONFIG_FILE ?= build/menuconfig/.config
SOC_CONFIG_OUTPUT ?= build/menuconfig
SOC_CONFIG_FDC ?= soc.fdc
SOC_CONFIG_BSP_OUTPUT ?= bsp/include
SOC_CONFIG_CC ?= gcc

SOC_CONFIG_TOOL := build/menuconfig/soc_config

$(SOC_CONFIG_TOOL): scripts/soc_config.c
	@mkdir -p "$(dir $@)"
	$(SOC_CONFIG_CC) -std=c11 -O2 -Wall -Wextra -Werror "$<" -o "$@"

.PHONY: config-headers config-check config-test
config-headers: $(SOC_CONFIG_TOOL)
	@$(SOC_CONFIG_TOOL) generate-header --source '$(SOC_CONFIG_SOURCE)' --output-dir '$(SOC_CONFIG_BSP_OUTPUT)'

config-check: $(SOC_CONFIG_TOOL)
	@$(SOC_CONFIG_TOOL) check --source '$(SOC_CONFIG_SOURCE)' --fdc '$(SOC_CONFIG_FDC)' \
	 --header '$(SOC_CONFIG_BSP_OUTPUT)/soc_defs.h' --asm '$(SOC_CONFIG_BSP_OUTPUT)/soc_defs_asm.inc'

config-test: $(SOC_CONFIG_TOOL) kconfig-tools
	@sh scripts/test_soc_clock_config.sh
