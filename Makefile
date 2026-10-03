SHELL := /bin/sh
.DEFAULT_GOAL := sim

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
CAMERA_ASYNC_FIFO_BIN := $(BUILD_DIR)/obj_camera_async_fifo/Vtb_camera_async_fifo
CAMERA_DVP_FIFO_BIN := $(BUILD_DIR)/obj_camera_dvp_fifo/Vtb_camera_dvp_fifo
CAMERA_DMA_BIN := $(BUILD_DIR)/obj_camera_dma/Vtb_camera_dma
CAMERA_SNAPSHOT_BIN := $(BUILD_DIR)/obj_camera_snapshot/Vtb_camera_snapshot
CAMERA_PIPELINE_BIN := $(BUILD_DIR)/obj_camera_pipeline/Vtb_camera_pipeline
CAMERA_STEREO_BIN := $(BUILD_DIR)/obj_camera_stereo/Vtb_camera_stereo
CAMERA_STEREO_FW_BIN := $(BUILD_DIR)/obj_camera_stereo_firmware/Vtb_camera_stereo_firmware
CAMERA_DIAG_FW_BIN := $(BUILD_DIR)/obj_camera_diag_firmware/Vtb_camera_diag_firmware
FPIOA_UART_PROFILES_BIN := $(BUILD_DIR)/tb_fpioa_uart_profiles.vvp
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
SIM_RTL += soc/Hfpioa_simple.v
CAMERA_SIM_RTL := soc/Hcamera_sccb_gpio.v soc/Hcamera_dvp_rx.v \
	soc/Hcamera_dvp_regs.v soc/Hcamera_async_fifo.v soc/Hcamera_dma.v \
	soc/Hcamera_subsystem.v soc/Haxi_2m1s_arbiter.v soc/ddr_axi_bridge.v \
	sim/camera_ddr_model.sv sim/ov5640_sccb_model.sv
CAMERA_SIM_HEADERS := soc/camera_regs.vh soc/soc_addr_map.vh
DCACHE_TB_RTL := cpu/dcache.v cpu/cache_util.v cpu/cache_sram_beh.v
NPU_CTRL_TB_RTL := soc/Hnpu_ctrl.v
NPU_DMA_TB_RTL := soc/Hnpu_dma.v
NPU_ARBITER_TB_RTL := soc/Haxi_2m1s_arbiter.v
PREPROCESS_RTL := soc/Hpreprocess_color.v soc/Hpreprocess_regions.v \
	soc/Hcamera_preprocess.v soc/Hpreprocess_stereo.v

.PHONY: menuconfig manuconfig
menuconfig:
	@$(PYTHON) tools/soc_menuconfig.py menu

manuconfig: menuconfig

.PHONY: preprocess-test preprocess-lint preprocess-color-test
preprocess-color-test:
	@mkdir -p "$(BUILD_DIR)"
	iverilog -g2012 -s tb_preprocess_color -o "$(BUILD_DIR)/tb_preprocess_color.vvp" \
		soc/Hpreprocess_color.v sim/tb_preprocess_color.sv
	vvp "$(BUILD_DIR)/tb_preprocess_color.vvp"
PREPROCESS_TEST_RTL := $(PREPROCESS_RTL) soc/Haxi_2m1s_arbiter.v \
	soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v soc/Hcamera_dma.v soc/Hcamera_subsystem.v
preprocess-test:
	$(VERILATOR) --binary --timing -Isoc --language 1800-2012 \
		--top-module tb_preprocess_stereo --Mdir "$(BUILD_DIR)/obj_preprocess_stereo" \
		$(PREPROCESS_TEST_RTL) sim/tb_preprocess_stereo.sv
	@"$(BUILD_DIR)/obj_preprocess_stereo/Vtb_preprocess_stereo"

.PHONY: preprocess-camera-test preprocess-640x480-test
preprocess-camera-test:
	$(VERILATOR) --binary --timing -Isoc --language 1800-2012 \
		"-GSOURCE_FROM_CAMERA=1'b1" --top-module tb_preprocess_stereo \
		--Mdir "$(BUILD_DIR)/obj_preprocess_camera" \
		$(PREPROCESS_TEST_RTL) sim/tb_preprocess_stereo.sv
	@"$(BUILD_DIR)/obj_preprocess_camera/Vtb_preprocess_stereo"

preprocess-640x480-test:
	$(VERILATOR) --binary --timing -Isoc --language 1800-2012 \
		-GW=640 -GH=480 --top-module tb_preprocess_stereo \
		--Mdir "$(BUILD_DIR)/obj_preprocess_640x480" \
		$(PREPROCESS_TEST_RTL) sim/tb_preprocess_stereo.sv
	@"$(BUILD_DIR)/obj_preprocess_640x480/Vtb_preprocess_stereo" +RAW_640X480

preprocess-lint:
	$(VERILATOR) --lint-only -Isoc --language 1800-2012 \
		--top-module Hpreprocess_stereo $(PREPROCESS_RTL) soc/Haxi_2m1s_arbiter.v

.PHONY: sim lint addr-map dcache-bypass npu-ctrl npu-dma npu-arbiter \
	flash-boot-smoke spi-flash-reader-test flash-ddr-boot-test \
	camera-uart-fw-test camera-sccb-fw-test camera-sccb-gpio-test \
	camera-dvp-rx-test camera-async-fifo-test camera-dvp-fifo-test \
	camera-dma-test camera-snapshot-test camera-pipeline-test camera-board-lint \
	camera-firmware-profiles camera-uart-local-fw-test camera-uart-remote-fw-test \
	fpioa-uart-profiles-test \
	camera-gpio-firmware camera-gpio-fw-test camera-gpio-local-fw-test \
	camera-gpio-remote-fw-test camera-gpio-stuck-low-fw-test \
	camera-error-report-fw-test \
	cpu-load-store-test clean

.PHONY: camera-stereo-firmware camera-stereo-test camera-stereo-fw-test \
	camera-stereo-local-fw-test camera-stereo-remote-fw-test fpioa-camera-reserved-test \
	camera-stereo-throughput-fw-test

# 双目使用四个独立槽；以下测试均离线，不操作 PDS/实板。
.PHONY: camera-diagnostic-firmware camera-diagnostic-status-test \
	camera-diagnostic-stereo-fw-test camera-diagnostic-cam2-fw-test \
	camera-diagnostic-stereo-remote-fw-test camera-diagnostic-cam2-remote-fw-test \
	camera-diagnostic-fw-test camera-diagnostic-stall-fw-test

camera-diagnostic-firmware:
	$(MAKE) -C bsp/camera_stereo_app diagnostics

camera-diagnostic-fw-test: camera-diagnostic-stereo-fw-test camera-diagnostic-cam2-fw-test \
	camera-diagnostic-stereo-remote-fw-test camera-diagnostic-cam2-remote-fw-test

camera-diagnostic-status-test:
	@mkdir -p "$(BUILD_DIR)"
	$(CC) -std=c11 -Wall -Wextra -Werror -Ibsp/camera_stereo_app \
		sim/test_camera_diag_status.c bsp/camera_stereo_app/diag_status.c \
		-o "$(BUILD_DIR)/test_camera_diag_status"
	@"$(BUILD_DIR)/test_camera_diag_status"

$(CAMERA_DIAG_FW_BIN): $(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(CAMERA_SIM_HEADERS) sim/tb_camera_diag_firmware.sv
	@mkdir -p "$(BUILD_DIR)/obj_camera_diag_firmware"
	$(VERILATOR) --binary --timing -Isoc --language 1800-2012 \
		--Wno-WIDTHTRUNC --Wno-BLKLOOPINIT \
		--top-module tb_camera_diag_firmware \
		--Mdir "$(BUILD_DIR)/obj_camera_diag_firmware" \
		$(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) sim/tb_camera_diag_firmware.sv

# readmemh专用换序只发生在build中，不改变Flash交付bin。
camera-diagnostic-stereo-fw-test: $(CAMERA_DIAG_FW_BIN) camera-diagnostic-firmware
	@mkdir -p "$(BUILD_DIR)/camera_diag/stereo"
	@objcopy -I binary -O binary --reverse-bytes=4 bsp/camera_stereo_app/camera_stereo_diag_local.bin "$(BUILD_DIR)/camera_diag/stereo/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_diag/stereo/program.be.bin" > "$(BUILD_DIR)/camera_diag/stereo/program.hex"
	@if "$(CAMERA_DIAG_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_diag/stereo/program.hex)" +UART_PIN=0 +TIMEOUT=180000000 > "$(BUILD_DIR)/camera_diag_stereo.log" 2>&1; then \
		tail -n 8 "$(BUILD_DIR)/camera_diag_stereo.log"; \
	else cat "$(BUILD_DIR)/camera_diag_stereo.log"; exit 1; fi

camera-diagnostic-cam2-fw-test: $(CAMERA_DIAG_FW_BIN) camera-diagnostic-firmware
	@mkdir -p "$(BUILD_DIR)/camera_diag/cam2"
	@objcopy -I binary -O binary --reverse-bytes=4 bsp/camera_stereo_app/camera_cam2_only_local.bin "$(BUILD_DIR)/camera_diag/cam2/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_diag/cam2/program.be.bin" > "$(BUILD_DIR)/camera_diag/cam2/program.hex"
	@if "$(CAMERA_DIAG_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_diag/cam2/program.hex)" +UART_PIN=0 +CAM2_ONLY +TIMEOUT=180000000 > "$(BUILD_DIR)/camera_diag_cam2_only.log" 2>&1; then \
		tail -n 8 "$(BUILD_DIR)/camera_diag_cam2_only.log"; \
	else cat "$(BUILD_DIR)/camera_diag_cam2_only.log"; exit 1; fi

# 远程版本核对FPIOA31的真实串口输出，不访问物理串口。
camera-diagnostic-stereo-remote-fw-test: $(CAMERA_DIAG_FW_BIN) camera-diagnostic-firmware
	@mkdir -p "$(BUILD_DIR)/camera_diag/stereo_remote"
	@objcopy -I binary -O binary --reverse-bytes=4 bsp/camera_stereo_app/camera_stereo_diag_remote.bin "$(BUILD_DIR)/camera_diag/stereo_remote/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_diag/stereo_remote/program.be.bin" > "$(BUILD_DIR)/camera_diag/stereo_remote/program.hex"
	@if "$(CAMERA_DIAG_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_diag/stereo_remote/program.hex)" +UART_PIN=31 +TIMEOUT=180000000 > "$(BUILD_DIR)/camera_diag_stereo_remote.log" 2>&1; then \
		tail -n 8 "$(BUILD_DIR)/camera_diag_stereo_remote.log"; \
	else cat "$(BUILD_DIR)/camera_diag_stereo_remote.log"; exit 1; fi

camera-diagnostic-cam2-remote-fw-test: $(CAMERA_DIAG_FW_BIN) camera-diagnostic-firmware
	@mkdir -p "$(BUILD_DIR)/camera_diag/cam2_remote"
	@objcopy -I binary -O binary --reverse-bytes=4 bsp/camera_stereo_app/camera_cam2_only_remote.bin "$(BUILD_DIR)/camera_diag/cam2_remote/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_diag/cam2_remote/program.be.bin" > "$(BUILD_DIR)/camera_diag/cam2_remote/program.hex"
	@if "$(CAMERA_DIAG_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_diag/cam2_remote/program.hex)" +UART_PIN=31 +CAM2_ONLY +TIMEOUT=180000000 > "$(BUILD_DIR)/camera_diag_cam2_only_remote.log" 2>&1; then \
		tail -n 8 "$(BUILD_DIR)/camera_diag_cam2_only_remote.log"; \
	else cat "$(BUILD_DIR)/camera_diag_cam2_only_remote.log"; exit 1; fi

# 故障注入仍按真实70MHz CPU计时，不能通过缩短固件2秒阈值制造通过。
camera-diagnostic-stall-fw-test: camera-diagnostic-stereo-fw-test
	@if "$(CAMERA_DIAG_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_diag/stereo/program.hex)" +UART_PIN=0 +CAM2_INPUT_STALL +TIMEOUT=360000000 > "$(BUILD_DIR)/camera_diag_input_stall.log" 2>&1; then \
		tail -n 8 "$(BUILD_DIR)/camera_diag_input_stall.log"; \
	else cat "$(BUILD_DIR)/camera_diag_input_stall.log"; exit 1; fi

camera-stereo-firmware:
	$(MAKE) -C bsp/camera_stereo_app all

camera-stereo-test:
	$(VERILATOR) --binary --timing -Isoc --language 1800-2012 \
		--top-module tb_camera_stereo --Mdir "$(BUILD_DIR)/obj_camera_stereo" \
		soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v soc/Hcamera_dma.v \
		soc/Hcamera_subsystem.v soc/Haxi_2m1s_arbiter.v \
		sim/camera_ddr_model.sv sim/tb_camera_stereo.sv
	@"$(CAMERA_STEREO_BIN)"

fpioa-camera-reserved-test:
	@mkdir -p "$(BUILD_DIR)"
	iverilog -g2012 -s tb_fpioa_camera_reserved \
		-o "$(BUILD_DIR)/tb_fpioa_camera_reserved.vvp" \
		soc/Hfpioa_simple.v sim/tb_fpioa_camera_reserved.sv
	@vvp "$(BUILD_DIR)/tb_fpioa_camera_reserved.vvp"

$(CAMERA_STEREO_FW_BIN): $(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(CAMERA_SIM_HEADERS) sim/tb_camera_stereo_firmware.sv
	@mkdir -p "$(BUILD_DIR)/obj_camera_stereo_firmware"
	$(VERILATOR) --binary --timing -Isoc --language 1800-2012 \
		--Wno-WIDTHTRUNC --Wno-BLKLOOPINIT \
		--top-module tb_camera_stereo_firmware \
		--Mdir "$(BUILD_DIR)/obj_camera_stereo_firmware" \
		$(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) sim/tb_camera_stereo_firmware.sv

camera-stereo-fw-test: camera-stereo-local-fw-test camera-stereo-remote-fw-test

# 仅将仿真输入转换为 readmemh 的字序；交付 Flash bin 保持原始字节。
camera-stereo-local-fw-test: $(CAMERA_STEREO_FW_BIN) camera-stereo-firmware
	@mkdir -p "$(BUILD_DIR)/camera_stereo/local"
	@objcopy -I binary -O binary --reverse-bytes=4 bsp/camera_stereo_app/camera_stereo_local.bin "$(BUILD_DIR)/camera_stereo/local/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_stereo/local/program.be.bin" > "$(BUILD_DIR)/camera_stereo/local/program.hex"
	@"$(CAMERA_STEREO_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_stereo/local/program.hex)" +UART_PIN=0 +TIMEOUT=180000000

# 执行未修改的固件真实1秒周期摘要，持续双路输入，不用软件延时替身。
camera-stereo-throughput-fw-test: camera-stereo-local-fw-test
	@"$(CAMERA_STEREO_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_stereo/local/program.hex)" +UART_PIN=0 +LONG_RUN +TIMEOUT=180000000

camera-stereo-remote-fw-test: $(CAMERA_STEREO_FW_BIN) camera-stereo-firmware
	@mkdir -p "$(BUILD_DIR)/camera_stereo/remote"
	@objcopy -I binary -O binary --reverse-bytes=4 bsp/camera_stereo_app/camera_stereo_remote.bin "$(BUILD_DIR)/camera_stereo/remote/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_stereo/remote/program.be.bin" > "$(BUILD_DIR)/camera_stereo/remote/program.hex"
	@"$(CAMERA_STEREO_FW_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_stereo/remote/program.hex)" +UART_PIN=31 +TIMEOUT=180000000

sim: $(SIM_BIN)
	@$(PYTHON) -B sim/test.py \
		--sim "$(abspath $(SIM_BIN))" \
		--tests "$(abspath $(ISA_DIR))" \
		--output "$(abspath $(ISA_OUT))"

# 在真实 CPU RTL 上执行两套 Camera 固件，并从 FPIOA TX 脚逐字节解码核对。
# 此测试完全离线，不启动 PDS，也不访问物理串口。
camera-uart-fw-test: camera-uart-local-fw-test camera-uart-remote-fw-test

camera-firmware-profiles:
	$(MAKE) -C bsp/camera_app all

# 原始交付 bin 直接执行，验证 500 ms 保持、开漏引脚、UART 与恒低故障。
camera-gpio-firmware:
	$(MAKE) -C bsp/camera_app gpio-test

camera-gpio-fw-test: camera-gpio-local-fw-test camera-gpio-remote-fw-test camera-gpio-stuck-low-fw-test

camera-gpio-local-fw-test: $(CAMERA_UART_SIM_BIN) camera-gpio-firmware
	@mkdir -p "$(BUILD_DIR)/camera_gpio/local"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_gpio_test_local.bin "$(BUILD_DIR)/camera_gpio/local/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_gpio/local/program.be.bin" > "$(BUILD_DIR)/camera_gpio/local/program.hex"
	@"$(CAMERA_UART_SIM_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_gpio/local/program.hex)" \
		+GPIO_SMOKE +UART_PIN=0 +TIMEOUT=150000000

camera-gpio-remote-fw-test: $(CAMERA_UART_SIM_BIN) camera-gpio-firmware
	@mkdir -p "$(BUILD_DIR)/camera_gpio/remote"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_gpio_test_remote.bin "$(BUILD_DIR)/camera_gpio/remote/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_gpio/remote/program.be.bin" > "$(BUILD_DIR)/camera_gpio/remote/program.hex"
	@"$(CAMERA_UART_SIM_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_gpio/remote/program.hex)" \
		+GPIO_SMOKE +UART_PIN=31 +TIMEOUT=150000000

camera-gpio-stuck-low-fw-test: $(CAMERA_UART_SIM_BIN) camera-gpio-firmware
	@mkdir -p "$(BUILD_DIR)/camera_gpio/stuck_low"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_gpio_test_local.bin "$(BUILD_DIR)/camera_gpio/stuck_low/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_gpio/stuck_low/program.be.bin" > "$(BUILD_DIR)/camera_gpio/stuck_low/program.hex"
	@"$(CAMERA_UART_SIM_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_gpio/stuck_low/program.hex)" \
		+GPIO_SMOKE +GPIO_SDA_STUCK_LOW +UART_PIN=0 +TIMEOUT=150000000

camera-uart-local-fw-test: $(CAMERA_UART_SIM_BIN) camera-firmware-profiles
	@mkdir -p "$(BUILD_DIR)/camera_uart/local"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_uart_debug_local.bin \
		"$(BUILD_DIR)/camera_uart/local/camera_uart_debug.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_uart/local/camera_uart_debug.be.bin" \
		> "$(BUILD_DIR)/camera_uart/local/camera_uart_debug.hex"
	@"$(CAMERA_UART_SIM_BIN)" \
		+PROGRAM="$(abspath $(BUILD_DIR)/camera_uart/local/camera_uart_debug.hex)" \
		+UART_SMOKE +UART_PIN=0 +TIMEOUT=80000000

camera-uart-remote-fw-test: $(CAMERA_UART_SIM_BIN) camera-firmware-profiles
	@mkdir -p "$(BUILD_DIR)/camera_uart/remote"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_uart_debug_remote.bin \
		"$(BUILD_DIR)/camera_uart/remote/camera_uart_debug.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_uart/remote/camera_uart_debug.be.bin" \
		> "$(BUILD_DIR)/camera_uart/remote/camera_uart_debug.hex"
	@"$(CAMERA_UART_SIM_BIN)" \
		+PROGRAM="$(abspath $(BUILD_DIR)/camera_uart/remote/camera_uart_debug.hex)" \
		+UART_SMOKE +UART_PIN=31 +TIMEOUT=80000000

# 注入479行帧，核对错误快照的尺寸、UART真实输出及稳定错误不刷屏。
camera-error-report-fw-test: $(CAMERA_UART_SIM_BIN) camera-firmware-profiles
	@mkdir -p "$(BUILD_DIR)/camera_uart/bad_frame"
	@objcopy -I binary -O binary --reverse-bytes=4 \
		bsp/camera_app/camera_uart_debug_local.bin "$(BUILD_DIR)/camera_uart/bad_frame/program.be.bin"
	@xxd -p -c 4 "$(BUILD_DIR)/camera_uart/bad_frame/program.be.bin" > "$(BUILD_DIR)/camera_uart/bad_frame/program.hex"
	@"$(CAMERA_UART_SIM_BIN)" +PROGRAM="$(abspath $(BUILD_DIR)/camera_uart/bad_frame/program.hex)" \
		+UART_SMOKE +CAMERA_BAD_FRAME +UART_PIN=0 +TIMEOUT=80000000

fpioa-uart-profiles-test:
	$(VERILATOR) --lint-only --timing --language 1800-2012 \
		--top-module tb_fpioa_uart_profiles \
		soc/Hfpioa_simple.v sim/tb_fpioa_uart_profiles.sv
	@mkdir -p "$(BUILD_DIR)"
	iverilog -g2012 -s tb_fpioa_uart_profiles -o "$(FPIOA_UART_PROFILES_BIN)" \
		soc/Hfpioa_simple.v sim/tb_fpioa_uart_profiles.sv
	@vvp "$(FPIOA_UART_PROFILES_BIN)"

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
		bsp/camera_app/Makefile \
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

# 独立时钟与背压下检查像素/帧事件 FIFO；生产顶层由 Camera DMA 消费。
camera-async-fifo-test:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_camera_async_fifo \
		--Mdir "$(BUILD_DIR)/obj_camera_async_fifo" \
		soc/Hcamera_async_fifo.v sim/tb_camera_async_fifo.sv
	@"$(CAMERA_ASYNC_FIFO_BIN)"

# CAM1 DVP 生成完整 VGA 帧，像素及帧标记经异步 FIFO 后在系统时钟域核对。
camera-dvp-fifo-test:
	$(VERILATOR) --binary --timing \
		--language 1800-2012 \
		--top-module tb_camera_dvp_fifo \
		--Mdir "$(BUILD_DIR)/obj_camera_dvp_fifo" \
		soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v sim/tb_camera_dvp_fifo.sv
	@"$(CAMERA_DVP_FIFO_BIN)"

camera-dma-test:
	$(VERILATOR) --binary --timing -Isoc \
		--language 1800-2012 --top-module tb_camera_dma \
		--Mdir "$(BUILD_DIR)/obj_camera_dma" \
		soc/Hcamera_dma.v sim/tb_camera_dma.sv
	@"$(CAMERA_DMA_BIN)"

camera-snapshot-test:
	$(VERILATOR) --binary --timing -Isoc \
		--language 1800-2012 --top-module tb_camera_snapshot \
		--Mdir "$(BUILD_DIR)/obj_camera_snapshot" \
		soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v soc/Hcamera_dma.v \
		soc/Hcamera_subsystem.v sim/tb_camera_snapshot.sv
	@"$(CAMERA_SNAPSHOT_BIN)"

camera-pipeline-test:
	$(VERILATOR) --binary --timing -Isoc \
		--language 1800-2012 --top-module tb_camera_pipeline \
		--Mdir "$(BUILD_DIR)/obj_camera_pipeline" \
		soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v soc/Hcamera_dma.v \
		soc/Hcamera_subsystem.v sim/camera_ddr_model.sv sim/tb_camera_pipeline.sv
	@"$(CAMERA_PIPELINE_BIN)"

# 用本地 IP 端口声明替身检查顶层连线；豁免仅用于旧 CPU/JTAG/外设告警。
camera-board-lint:
	$(VERILATOR) --lint-only -Isoc --language 1800-2012 \
		$(BOARD_LINT_EXTRA) \
		--Wno-BLKLOOPINIT --Wno-IMPLICIT --Wno-WIDTHTRUNC --Wno-CASEINCOMPLETE \
		--top-module Hfpga_soc \
		$(CPU_RTL) cpu/cache_sram_beh.v $(wildcard jtag/*.v) \
		soc/Hfpga_soc.v soc/Debug_core.v soc/Hled.v soc/Hfpioa_simple.v \
		soc/Hnpu_ctrl.v soc/axi_mem_backend.v soc/Huart_tx.v \
		soc/Hcamera_sccb_gpio.v soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v \
		soc/Hcamera_dma.v soc/Hcamera_subsystem.v soc/Haxi_2m1s_arbiter.v \
		$(PREPROCESS_RTL) \
		soc/ddr_axi_bridge.v soc/flash_boot/spi_flash_byte_reader.v \
		soc/flash_boot/flash_ddr_loader.v soc/flash_boot/flash_ddr_boot.v \
		sim/board_ip_lint_stubs.v

$(CAMERA_UART_SIM_BIN): $(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(CAMERA_SIM_HEADERS) $(SIM_TB)
	@mkdir -p "$(BUILD_DIR)/obj_camera_uart"
	$(VERILATOR) --binary --timing -Isoc \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--Wno-BLKLOOPINIT \
		--top-module tb_Htop \
		--Mdir "$(BUILD_DIR)/obj_camera_uart" \
		$(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(SIM_TB)


$(SIM_BIN): $(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(CAMERA_SIM_HEADERS) $(SIM_TB)
	@mkdir -p "$(OBJ_DIR)"
	$(VERILATOR) --binary --timing -Isoc \
		--language 1800-2012 \
		--Wno-WIDTHTRUNC \
		--Wno-BLKLOOPINIT \
		--top-module tb_Htop \
		--Mdir "$(OBJ_DIR)" \
		$(CPU_RTL) $(SIM_RTL) $(CAMERA_SIM_RTL) $(SIM_TB)

lint:
	$(VERILATOR) --lint-only -Isoc \
		--language 1800-2012 --top-module Hcamera_subsystem \
		soc/Hcamera_dvp_rx.v soc/Hcamera_async_fifo.v soc/Hcamera_dma.v \
		soc/Hcamera_subsystem.v
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
		--top-module Hcamera_async_fifo \
		soc/Hcamera_async_fifo.v
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
