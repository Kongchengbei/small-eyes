SHELL := /bin/sh

VERILATOR ?= verilator
PYTHON    ?= python3

# 当前环境通过 g++ 调用 ccache，但缓存目录可能只读；关闭缓存避免构建失败。
export CCACHE_DISABLE ?= 1

BUILD_DIR := build
OBJ_DIR   := $(BUILD_DIR)/obj_cpu_regression
SIM_BIN   := $(OBJ_DIR)/Vtb_Htop
CAMERA_UART_SIM_BIN := $(BUILD_DIR)/obj_camera_uart/Vtb_Htop
CAMERA_SCCB_GPIO_BIN := $(BUILD_DIR)/obj_camera_sccb_gpio/Vtb_camera_sccb_gpio
CAMERA_DVP_RX_BIN := $(BUILD_DIR)/obj_camera_dvp_rx/Vtb_camera_dvp_rx
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

# Htop 输出 AXI 主机接口，测试平台同时接入 SoC 使用的串行内存后端。
CPU_RTL := $(filter-out cpu/cache_bram.v cpu/cache_sram_beh.v,$(wildcard cpu/*.v))
SIM_RTL := soc/axi_mem_backend.v soc/Huart_tx.v cpu/cache_sram_beh.v
CAMERA_SIM_RTL := soc/Hcamera_sccb_gpio.v soc/Hcamera_dvp_rx.v \
	soc/Hcamera_dvp_regs.v sim/ov5640_sccb_model.sv
DCACHE_TB_RTL := cpu/dcache.v cpu/cache_util.v cpu/cache_sram_beh.v
NPU_CTRL_TB_RTL := soc/Hnpu_ctrl.v
NPU_DMA_TB_RTL := soc/Hnpu_dma.v
NPU_ARBITER_TB_RTL := soc/Haxi_2m1s_arbiter.v

.PHONY: sim lint addr-map dcache-bypass npu-ctrl npu-dma npu-arbiter \
	flash-boot-smoke spi-flash-reader-test flash-ddr-boot-test \
	camera-uart-fw-test camera-sccb-fw-test camera-sccb-gpio-test \
	camera-dvp-rx-test cpu-load-store-test clean

sim: $(SIM_BIN)
	@$(PYTHON) -B sim/test.py \
		--sim "$(abspath $(SIM_BIN))" \
		--tests "$(abspath $(ISA_DIR))" \
		--output "$(abspath $(ISA_OUT))"

# 在真实 CPU RTL 上执行 Camera 探活固件，并逐字节核对 UART0 输出。
# 此测试完全离线，不启动 PDS，也不访问物理串口。
camera-uart-fw-test: $(CAMERA_UART_SIM_BIN) bsp/camera_app/camera_uart_debug.bin
	@mkdir -p "$(BUILD_DIR)/camera_uart"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_uart_debug.bin \
		"$(BUILD_DIR)/camera_uart/camera_uart_debug.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_uart/camera_uart_debug.be.bin" \
		> "$(BUILD_DIR)/camera_uart/camera_uart_debug.hex"
	@"$(CAMERA_UART_SIM_BIN)" \
		+PROGRAM="$(abspath $(BUILD_DIR)/camera_uart/camera_uart_debug.hex)" \
		+UART_SMOKE +TIMEOUT=30000000

# 新名称强调该固件除 UART 外，还执行 CAM1 SCCB 芯片 ID 探测。
camera-sccb-fw-test: camera-uart-fw-test

# 真正运行 lw(MMIO) 紧接 sw(DDR) 的指令序列，覆盖流水线数据冒险。
cpu-load-store-test: $(SIM_BIN) sim/cpu_load_store_mmio.S
	@mkdir -p "$(BUILD_DIR)/cpu_load_store_test"
	riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib \
		-Wl,--no-relax -Wl,-Ttext=0x80000000 \
		sim/cpu_load_store_mmio.S \
		-o "$(BUILD_DIR)/cpu_load_store_test/program.elf"
	riscv64-unknown-elf-objcopy -O binary \
		"$(BUILD_DIR)/cpu_load_store_test/program.elf" \
		"$(BUILD_DIR)/cpu_load_store_test/program.bin"
	@$(PYTHON) -B sim/test.py \
		--sim "$(abspath $(SIM_BIN))" \
		--tests "$(abspath $(BUILD_DIR)/cpu_load_store_test)" \
		--output "$(abspath $(BUILD_DIR)/cpu_load_store_test/hex)" \
		--timeout=200000

bsp/camera_app/camera_uart_debug.bin: \
		bsp/camera_app/main.c bsp/camera_app/uart.c bsp/camera_app/uart.h \
		bsp/camera_app/camera_sccb.c bsp/camera_app/camera_sccb.h \
		bsp/camera_app/camera_dvp.c bsp/camera_app/camera_dvp.h \
		bsp/camera_app/ov5640.c bsp/camera_app/ov5640.h \
		bsp/camera_app/ov5640_regs.c bsp/camera_app/ov5640_regs.h \
		bsp/camera_app/link.lds
	$(MAKE) -C bsp/camera_app all

camera-sccb-gpio-test:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_camera_sccb_gpio \
		--Mdir "$(BUILD_DIR)/obj_camera_sccb_gpio" \
		soc/Hcamera_sccb_gpio.v sim/tb_camera_sccb_gpio.sv
	@"$(CAMERA_SCCB_GPIO_BIN)"

camera-dvp-rx-test:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_camera_dvp_rx \
		--Mdir "$(BUILD_DIR)/obj_camera_dvp_rx" \
		soc/Hcamera_dvp_rx.v sim/tb_camera_dvp_rx.sv
	@"$(CAMERA_DVP_RX_BIN)"

$(CAMERA_UART_SIM_BIN): $(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(SIM_TB)
	@mkdir -p "$(BUILD_DIR)/obj_camera_uart"
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--Wno-BLKLOOPINIT \
		--top-module tb_Htop \
		--Mdir "$(BUILD_DIR)/obj_camera_uart" \
		$(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(SIM_TB)


$(SIM_BIN): $(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(SIM_TB)
	@mkdir -p "$(OBJ_DIR)"
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--Wno-BLKLOOPINIT \
		--top-module tb_Htop \
		--Mdir "$(OBJ_DIR)" \
		$(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(SIM_TB)

lint:
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--top-module Hcamera_sccb_gpio \
		soc/Hcamera_sccb_gpio.v
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--top-module Hcamera_dvp_rx \
		soc/Hcamera_dvp_rx.v
	$(VERILATOR) --lint-only \
		--language 1800-2012 \
		--top-module Hcamera_dvp_regs \
		soc/Hcamera_dvp_regs.v
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
