SOC_CONFIG_SOURCE ?= soc/soc_addr_map.vh
SOC_CONFIG_FILE ?= build/menuconfig/.config
SOC_CONFIG_OUTPUT ?= build/menuconfig
SOC_CONFIG_CC ?= gcc

SOC_CONFIG_TOOL := build/menuconfig/soc_config

$(SOC_CONFIG_TOOL): scripts/soc_config.c
	@mkdir -p "$(dir $@)"
	$(SOC_CONFIG_CC) -std=c11 -O2 -Wall -Wextra -Werror "$<" -o "$@"
