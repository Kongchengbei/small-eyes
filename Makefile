.DEFAULT_GOAL := menuconfig

include scripts/config.mk
include scripts/sim.mk

.PHONY: menuconfig kconfig-tools kconfig-test
menuconfig: $(SOC_CONFIG_TOOL) kconfig-tools
	@SOC_CONFIG_SOURCE='$(SOC_CONFIG_SOURCE)' SOC_CONFIG_FILE='$(SOC_CONFIG_FILE)' SOC_CONFIG_OUTPUT='$(SOC_CONFIG_OUTPUT)' scripts/menuconfig.sh

kconfig-tools:
	@$(MAKE) -s -C scripts/kconfig all

kconfig-test: kconfig-tools
	@sh scripts/test_kconfig_outputs.sh
