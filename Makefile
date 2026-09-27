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
DCACHE_BYPASS_BIN := $(BUILD_DIR)/obj_dcache_npu_bypass/Vtb_dcache_npu_bypass
NPU_CTRL_BIN := $(BUILD_DIR)/obj_npu_ctrl/Vtb_npu_ctrl
NPU_DMA_BIN := $(BUILD_DIR)/obj_npu_dma/Vtb_npu_dma
NPU_ARBITER_BIN := $(BUILD_DIR)/obj_npu_arbiter/Vtb_axi_2m1s_arbiter
FLASH_BOOT_BIN := $(BUILD_DIR)/obj_flash_boot/Vtb_flash_ddr_smoke
SPI_FLASH_READER_BIN := $(BUILD_DIR)/obj_spi_flash_reader/Vtb_spi_flash_byte_reader
FLASH_DDR_BOOT_BIN := $(BUILD_DIR)/obj_flash_ddr_boot_e2e/Vtb_flash_ddr_boot
ISA_DIR   ?= sim/test
ISA_OUT   := $(BUILD_DIR)/isa

# Htop exposes an AXI master, so the testbench also needs the serialized
# memory backend used by the SoC.
CPU_RTL := $(filter-out cpu/cache_bram.v cpu/cache_sram_beh.v,$(wildcard cpu/*.v))
SIM_RTL := soc/axi_mem_backend.v cpu/cache_sram_beh.v
DCACHE_TB_RTL := cpu/dcache.v cpu/cache_util.v cpu/cache_sram_beh.v
NPU_CTRL_TB_RTL := soc/Hnpu_ctrl.v
NPU_DMA_TB_RTL := soc/Hnpu_dma.v
NPU_ARBITER_TB_RTL := soc/Haxi_2m1s_arbiter.v

.PHONY: sim lint addr-map dcache-bypass npu-ctrl npu-dma npu-arbiter \
	flash-boot-smoke spi-flash-reader-test flash-ddr-boot-test clean

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
		--Wno-BLKLOOPINIT \
		--top-module tb_Htop \
		--Mdir "$(OBJ_DIR)" \
		$(CPU_RTL) $(SIM_RTL) $(SIM_TB)

lint:
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--Wno-BLKLOOPINIT \
		--top-module Htop \
		$(CPU_RTL) $(SIM_RTL)
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--top-module flash_ddr_boot \
		soc/flash_boot/spi_flash_byte_reader.v \
		soc/flash_boot/flash_ddr_loader.v \
		soc/flash_boot/flash_ddr_boot.v
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--top-module ddr_axi_bridge \
		soc/ddr_axi_bridge.v

# 只检查地址常量的连续性、边界和 256-bit 对齐要求，不编译完整 SoC。
addr-map:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		-Isoc \
		--top-module tb_soc_addr_map \
		--Mdir "$(BUILD_DIR)/obj_addr_map" \
		sim/tb_soc_addr_map.sv
	@"$(BUILD_DIR)/obj_addr_map/Vtb_soc_addr_map"

# DCache 对 NPU 共享区旁路的专用回归。dcache 的数组复位写法会触发
# Verilator 的 BLKLOOPINIT 限制，故仅对这一条已有实现限制加豁免。
dcache-bypass:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--Wno-BLKLOOPINIT \
		--top-module tb_dcache_npu_bypass \
		--Mdir "$(BUILD_DIR)/obj_dcache_npu_bypass" \
		$(DCACHE_TB_RTL) sim/tb_dcache_npu_bypass.sv
	@"$(DCACHE_BYPASS_BIN)"

# NPU 控制寄存器的独立验证；TB 以简化 engine_done 模型检查 start/busy/done/IRQ。
npu-ctrl:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_npu_ctrl \
		--Mdir "$(BUILD_DIR)/obj_npu_ctrl" \
		$(NPU_CTRL_TB_RTL) sim/tb_npu_ctrl.sv
	@"$(NPU_CTRL_BIN)"

# NPU 256-bit DMA 的独立 AXI 协议与数据搬运验证。
npu-dma:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_npu_dma \
		--Mdir "$(BUILD_DIR)/obj_npu_dma" \
		$(NPU_DMA_TB_RTL) sim/tb_npu_dma.sv
	@"$(NPU_DMA_BIN)"

# CPU/NPU 两主机共用 DDR AXI4 端口的独立仲裁与路由验证。
npu-arbiter:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_axi_2m1s_arbiter \
		--Mdir "$(BUILD_DIR)/obj_npu_arbiter" \
		$(NPU_ARBITER_TB_RTL) sim/tb_axi_2m1s_arbiter.sv
	@"$(NPU_ARBITER_BIN)"

# Flash->DDR smoke: byte-addressed behavioral Flash, shared DDR model, and the
# real Htop CPU. This validates loader ordering and reset release in simulation;
# it does not model PDS/X8 physical Flash mapping or a board-specific QSPI PHY.
flash-boot-smoke:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--Wno-BLKLOOPINIT \
		--top-module tb_flash_ddr_smoke \
		--Mdir "$(BUILD_DIR)/obj_flash_boot" \
		$(CPU_RTL) $(SIM_RTL) soc/flash_boot/flash_ddr_loader.v \
		sim/tb_flash_ddr_smoke.sv
	@"$(FLASH_BOOT_BIN)"
	@"$(FLASH_BOOT_BIN)" +EXPECT_FAILURE

# True mode-0 SPI byte reader tested against a serial Flash behavior model.
spi-flash-reader-test:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_spi_flash_byte_reader \
		--Mdir "$(BUILD_DIR)/obj_spi_flash_reader" \
		soc/flash_boot/spi_flash_byte_reader.v sim/tb_spi_flash_byte_reader.sv
	@"$(SPI_FLASH_READER_BIN)"

# End-to-end composition of the production Flash boot wrapper, SPI reader,
# loader, AXI backend, DDR bridge, and Htop CPU. Only the serial Flash and the
# external DDR-controller 256-bit AXI pins are behavioral models; this target
# does not instantiate Hfpga_soc's board primitives or verify its pin wiring.
flash-ddr-boot-test:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--Wno-BLKLOOPINIT \
		--top-module tb_flash_ddr_boot \
		--Mdir "$(BUILD_DIR)/obj_flash_ddr_boot_e2e" \
		$(CPU_RTL) $(SIM_RTL) soc/ddr_axi_bridge.v \
		soc/flash_boot/spi_flash_byte_reader.v \
		soc/flash_boot/flash_ddr_loader.v \
		soc/flash_boot/flash_ddr_boot.v sim/tb_flash_ddr_boot.sv
	@"$(FLASH_DDR_BOOT_BIN)"

clean:
	rm -rf -- "$(BUILD_DIR)" tb.vcd tb.view
