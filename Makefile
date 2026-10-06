.DEFAULT_GOAL := menuconfig

include scripts/config.mk
include scripts/sim.mk

.PHONY: menuconfig kconfig-tools kconfig-test clean distclean
menuconfig: $(SOC_CONFIG_TOOL) kconfig-tools
	@SOC_CONFIG_SOURCE='$(SOC_CONFIG_SOURCE)' SOC_CONFIG_FILE='$(SOC_CONFIG_FILE)' SOC_CONFIG_OUTPUT='$(SOC_CONFIG_OUTPUT)' \
	 SOC_CONFIG_FDC='$(SOC_CONFIG_FDC)' SOC_CONFIG_BSP_OUTPUT='$(SOC_CONFIG_BSP_OUTPUT)' scripts/menuconfig.sh

kconfig-tools:
	@$(MAKE) -s -C scripts/kconfig all

kconfig-test: kconfig-tools
	@sh scripts/test_kconfig_outputs.sh

clean:
	rm -rf build/sim
	rm -rf build/kconfig
	rm -rf build/cpu_bram_checks
	rm -f build/*.vvp
	rm -f build/*log
	@if [ -d build/menuconfig ]; then \
		find build/menuconfig -mindepth 1 -maxdepth 1 \
			! -name '.config' -exec rm -rf {} +; \
	fi

distclean:
	rm -rf build
