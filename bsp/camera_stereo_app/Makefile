CROSS_COMPILE ?= riscv64-elf-
.DEFAULT_GOAL := all
include ../soc_config.mk
CC := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump
SIZE := $(CROSS_COMPILE)size
BSP := ../bsp_app
BUILD := build
TARGET_BYTES := 16384
COMMON_SRCS := main.c camera_stereo.c uart_async.c ../camera_app/ov5640_regs.c runtime.c
STARTUP_SRCS := $(BSP)/lib/startup/init.c $(BSP)/lib/startup/startup.S
CFLAGS := -march=rv32im_zicsr -mabi=ilp32 -mcmodel=medlow -ffreestanding -fno-builtin \
	-ffunction-sections -fdata-sections -Os -Wall -Wextra -I. -I../camera_app
LDFLAGS := -T link.lds -nostdlib -Wl,--gc-sections -Wl,--check-sections -lgcc
LOCAL_OBJS := $(patsubst %.c,$(BUILD)/local/%.o,$(COMMON_SRCS)) \
	$(BUILD)/local/init.o $(BUILD)/local/startup.o
REMOTE_OBJS := $(patsubst %.c,$(BUILD)/remote/%.o,$(COMMON_SRCS)) \
	$(BUILD)/remote/init.o $(BUILD)/remote/startup.o
$(LOCAL_OBJS) $(REMOTE_OBJS): $(BSP_SOC_HEADER)
DIAG_SRCS := main_diag.c diag_status.c camera_stereo.c uart_async.c runtime.c
DIAG_VARIANTS := stereo_local stereo_remote cam2_local cam2_remote
DIAG_stereo_local_NAME := camera_stereo_diag_local
DIAG_stereo_remote_NAME := camera_stereo_diag_remote
DIAG_cam2_local_NAME := camera_cam2_only_local
DIAG_cam2_remote_NAME := camera_cam2_only_remote
DUMP_local_PIN := 0u
DUMP_remote_PIN := 31u
DUMP_SRCS := main_frame_dump.c camera_stereo.c uart_async.c ../camera_app/ov5640_regs.c runtime.c
NPU_SRCS := main_npu.c camera_stereo.c uart_async.c runtime.c
# NPU_VERBOSE=1 是逐项格式（10/15 第一版），默认 0 每框一行直接写路标名
NPU_VERBOSE ?= 0
NPU_PRINT_BACKGROUND ?= $(NPU_VERBOSE)
NPU_NAMES_GBK ?= 0
NPU_STAT_SECONDS ?= 5
NPU_CAM2_ORIENTATION_AS_CAM1 ?= 1
# 1：两路都写 zzx 调过的自动曝光目标（camera_stereo.c 的 ae_target_regs），0 用基础表
NPU_CAM_AE_TARGET_TUNED ?= 1
# 曝光扫参：NPU_SWEEP=1 扫预设，=2 只走展示时间表；默认 0，下面各行都不起作用
NPU_SWEEP ?= 0
ifneq ($(NPU_SWEEP),0)
NPU_SRCS += sweep.c
override NPU_PRINT_BACKGROUND := 1
endif
NPU_DEFS := -DCAM2_ORIENTATION_AS_CAM1=$(NPU_CAM2_ORIENTATION_AS_CAM1) -DCAM_AE_TARGET_TUNED=$(NPU_CAM_AE_TARGET_TUNED) -DNPU_PRINT_BACKGROUND=$(NPU_PRINT_BACKGROUND) \
    -DNPU_VERBOSE=$(NPU_VERBOSE) -DNPU_NAMES_GBK=$(NPU_NAMES_GBK) -DNPU_STAT_SECONDS=$(NPU_STAT_SECONDS)
# 路标确认层（sign_confirm.c）：NPU_CONFIRM=1 默认打开，=0 时 main_npu.c 里新代码一行都不编进去
NPU_CONFIRM ?= 1
# NPU_CONFIRM_TRACE=1 每张结果多打一行 ### VOTE（仿真对拍用）；NPU_QUIET=1 不打 >>> 和 ??? 行
NPU_CONFIRM_TRACE ?= 0
NPU_QUIET ?= 0
# 原样追加到 npu 的编译参数，例如 NPU_SC_FLAGS=-DSC_MIN_LONG=48
NPU_SC_FLAGS ?=
NPU_SRCS += sign_confirm.c
NPU_DEFS += -DNPU_CONFIRM=$(NPU_CONFIRM) -DNPU_CONFIRM_TRACE=$(NPU_CONFIRM_TRACE) -DNPU_QUIET=$(NPU_QUIET) $(NPU_SC_FLAGS)
ifneq ($(NPU_SWEEP),0)
# 命令行给了 SWEEP_xxx 就原样传给 sweep.c（时间表各段毫秒数、图数、SWEEP_CAM2_FIXED），没给用 sweep.c 里的默认值
NPU_DEFS += -DNPU_SWEEP=$(NPU_SWEEP) $(foreach m,SWEEP_SEG_MS SWEEP_SETTLE_MS SWEEP_PATCH_MS SWEEP_SWAP_MS SWEEP_IMAGES SWEEP_BLANK_MS SWEEP_SHOW_MS SWEEP_CAM2_FIXED,$(if $($(m)),-D$(m)=$($(m))))
endif
ifeq ($(NPU_SWEEP),1)
# 确认层加扫参超过 16384 字节：只放宽这两个 NPU 固件的 CPU 镜像上限到 SOC_BOOT_IMAGE_BYTES（32768），整片 _flash.bin 为 96096 字节
camera_stereo_npu_local.bin camera_stereo_npu_remote.bin: TARGET_BYTES := 32768
endif
NPU_MODEL ?= ../../models/basic-sign-v0.2-ctsu-candidate/model.npu
LANE_ARROW_MODEL ?= ../../models/lane-arrow-v0.8-normal-qat-candidate/model.npu
LANE_ARROW_CPU_BYTES ?= 32768
LANE_ARROW_SRCS := main_npu.c camera_stereo.c uart_async.c runtime.c ../camera_app/ov5640_regs.c sign_confirm.c

.PHONY: all local remote diagnostics frame-dump frame-dump-local frame-dump-remote npu npu-local npu-remote lane-arrow-flash lane-arrow-flash-local lane-arrow-flash-remote clean
all: camera_stereo_local.bin camera_stereo_remote.bin camera_stereo.bin
local: camera_stereo_local.bin
remote: camera_stereo_remote.bin
diagnostics: $(foreach v,$(DIAG_VARIANTS),$(DIAG_$(v)_NAME).bin)
frame-dump: frame-dump-local frame-dump-remote
frame-dump-local: camera_frame_uart_dump_local.bin
frame-dump-remote: camera_frame_uart_dump_remote.bin
npu: npu-local npu-remote
npu-local: camera_stereo_npu_local.bin camera_stereo_npu_local_flash.bin
npu-remote: camera_stereo_npu_remote.bin camera_stereo_npu_remote_flash.bin
lane-arrow-flash: lane-arrow-flash-local lane-arrow-flash-remote
lane-arrow-flash-local: camera_stereo_lane_arrow_local_flash.bin
lane-arrow-flash-remote: camera_stereo_lane_arrow_remote_flash.bin

DUMP_local_OBJS := $(patsubst %.c,$(BUILD)/dump/local/%.o,$(DUMP_SRCS)) \
	$(BUILD)/dump/local/init.o $(BUILD)/dump/local/startup.o
DUMP_remote_OBJS := $(patsubst %.c,$(BUILD)/dump/remote/%.o,$(DUMP_SRCS)) \
	$(BUILD)/dump/remote/init.o $(BUILD)/dump/remote/startup.o
$(DUMP_local_OBJS) $(DUMP_remote_OBJS): $(BSP_SOC_HEADER)

camera_stereo_local.elf: $(LOCAL_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(LOCAL_OBJS) -o $@ $(LDFLAGS) -Wl,-Map=camera_stereo_local.map
	$(SIZE) -A $@
camera_stereo_remote.elf: $(REMOTE_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(REMOTE_OBJS) -o $@ $(LDFLAGS) -Wl,-Map=camera_stereo_remote.map
	$(SIZE) -A $@

$(BUILD)/local/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=0u -c -o $@ $<
$(BUILD)/remote/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=31u -c -o $@ $<
$(BUILD)/local/init.o: $(BSP)/lib/startup/init.c Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=0u -c -o $@ $<
$(BUILD)/remote/init.o: $(BSP)/lib/startup/init.c Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=31u -c -o $@ $<
$(BUILD)/local/startup.o: $(BSP)/lib/startup/startup.S Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<
$(BUILD)/remote/startup.o: $(BSP)/lib/startup/startup.S Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/dump/local/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=$(DUMP_local_PIN) -c -o $@ $<
$(BUILD)/dump/remote/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=$(DUMP_remote_PIN) -c -o $@ $<
$(BUILD)/dump/local/init.o: $(BSP)/lib/startup/init.c Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=$(DUMP_local_PIN) -c -o $@ $<
$(BUILD)/dump/remote/init.o: $(BSP)/lib/startup/init.c Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DSTEREO_UART_TX_FPIOA=$(DUMP_remote_PIN) -c -o $@ $<
$(BUILD)/dump/local/startup.o: $(BSP)/lib/startup/startup.S Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<
$(BUILD)/dump/remote/startup.o: $(BSP)/lib/startup/startup.S Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

camera_frame_uart_dump_local.elf: $(DUMP_local_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(DUMP_local_OBJS) -o $@ $(LDFLAGS) -Wl,-Map=camera_frame_uart_dump_local.map
	$(SIZE) -A $@
camera_frame_uart_dump_remote.elf: $(DUMP_remote_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(DUMP_remote_OBJS) -o $@ $(LDFLAGS) -Wl,-Map=camera_frame_uart_dump_remote.map
	$(SIZE) -A $@

define DUMP_BIN_RULE
camera_frame_uart_dump_$(1).bin: camera_frame_uart_dump_$(1).elf
	@set -eu; raw="$(BUILD)/camera_frame_uart_dump_$(1).raw.bin"; $(OBJCOPY) -O binary $$< "$$$$raw"; bytes=$$$$(wc -c < "$$$$raw"); if [ "$$$$bytes" -eq 0 ] || [ "$$$$bytes" -gt $(TARGET_BYTES) ] || [ $$$$((bytes % 4)) -ne 0 ]; then echo "ERROR: invalid complete frame-dump image size: $$$$bytes"; exit 1; fi; echo "CAMERA_FRAME_UART_DUMP_$(1)_RAW_BYTES=$$$$bytes"; $(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=$(TARGET_BYTES) "$$$$raw" $$@; test $$$$(wc -c < $$@) -eq $(TARGET_BYTES)
endef
$(eval $(call DUMP_BIN_RULE,local))
$(eval $(call DUMP_BIN_RULE,remote))

define DIAG_VARIANT_RULES
DIAG_$(1)_MODE := $(2)
DIAG_$(1)_PIN := $(3)
DIAG_$(1)_SRCS := $(patsubst %.c,$(BUILD)/diag/$(1)/%.o,$(DIAG_SRCS))
DIAG_$(1)_OBJS := $$(DIAG_$(1)_SRCS) $(BUILD)/diag/$(1)/ov5640_regs.o $(BUILD)/diag/$(1)/init.o $(BUILD)/diag/$(1)/startup.o
$$(DIAG_$(1)_OBJS): $(BSP_SOC_HEADER)

$(BUILD)/diag/$(1)/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(DIAG_$(1)_PIN) -DDIAG_CAM2_ONLY=$$(DIAG_$(1)_MODE) -c -o $$@ $$<
$(BUILD)/diag/$(1)/ov5640_regs.o: ../camera_app/ov5640_regs.c ../camera_app/ov5640_regs.h Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(DIAG_$(1)_PIN) -DDIAG_CAM2_ONLY=$$(DIAG_$(1)_MODE) -c -o $$@ $$<
$(BUILD)/diag/$(1)/init.o: $(BSP)/lib/startup/init.c Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(DIAG_$(1)_PIN) -c -o $$@ $$<
$(BUILD)/diag/$(1)/startup.o: $(BSP)/lib/startup/startup.S Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -c -o $$@ $$<

$$(DIAG_$(1)_NAME).elf: $$(DIAG_$(1)_OBJS) link.lds Makefile
	$$(CC) $$(CFLAGS) $$(DIAG_$(1)_OBJS) -o $$@ $$(LDFLAGS) -Wl,-Map=$$(DIAG_$(1)_NAME).map
	$$(SIZE) -A $$@

$$(DIAG_$(1)_NAME).bin: $$(DIAG_$(1)_NAME).elf
	@set -eu; raw="$(BUILD)/$$(DIAG_$(1)_NAME).raw.bin"; $$(OBJCOPY) -O binary $$< "$$$$raw"; bytes=$$$$(wc -c < "$$$$raw"); if [ "$$$$bytes" -eq 0 ] || [ "$$$$bytes" -gt $$(TARGET_BYTES) ] || [ $$$$((bytes % 4)) -ne 0 ]; then echo "ERROR: invalid complete $$(DIAG_$(1)_NAME) raw image size: $$$$bytes"; exit 1; fi; echo "$$(DIAG_$(1)_NAME)_RAW_BYTES=$$$$bytes"; $$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=$$(TARGET_BYTES) "$$$$raw" $$@; test $$$$(wc -c < $$@) -eq $$(TARGET_BYTES)
endef

$(eval $(call DIAG_VARIANT_RULES,stereo_local,0,0u))
$(eval $(call DIAG_VARIANT_RULES,stereo_remote,0,31u))
$(eval $(call DIAG_VARIANT_RULES,cam2_local,1,0u))
$(eval $(call DIAG_VARIANT_RULES,cam2_remote,1,31u))

define NPU_VARIANT_RULES
NPU_$(1)_PIN := $(2)
NPU_$(1)_SRCS := $(patsubst %.c,$(BUILD)/npu/$(1)/%.o,$(NPU_SRCS))
NPU_$(1)_OBJS := $$(NPU_$(1)_SRCS) $(BUILD)/npu/$(1)/ov5640_regs.o $(BUILD)/npu/$(1)/init.o $(BUILD)/npu/$(1)/startup.o
$$(NPU_$(1)_OBJS): $(BSP_SOC_HEADER)

$(BUILD)/npu/$(1)/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(NPU_$(1)_PIN) $$(NPU_DEFS) -c -o $$@ $$<
$(BUILD)/npu/$(1)/ov5640_regs.o: ../camera_app/ov5640_regs.c ../camera_app/ov5640_regs.h Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(NPU_$(1)_PIN) $$(NPU_DEFS) -c -o $$@ $$<
$(BUILD)/npu/$(1)/init.o: $(BSP)/lib/startup/init.c Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(NPU_$(1)_PIN) -c -o $$@ $$<
$(BUILD)/npu/$(1)/startup.o: $(BSP)/lib/startup/startup.S Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -c -o $$@ $$<

camera_stereo_npu_$(1).elf: $$(NPU_$(1)_OBJS) link.lds Makefile
	$$(CC) $$(CFLAGS) $$(NPU_$(1)_OBJS) -o $$@ $$(LDFLAGS) -Wl,-Map=camera_stereo_npu_$(1).map
	$$(SIZE) -A $$@

camera_stereo_npu_$(1).bin: camera_stereo_npu_$(1).elf
	@set -eu; raw="$(BUILD)/camera_stereo_npu_$(1).raw.bin"; $$(OBJCOPY) -O binary $$< "$$$$raw"; bytes=$$$$(wc -c < "$$$$raw"); if [ "$$$$bytes" -eq 0 ] || [ "$$$$bytes" -gt $$(TARGET_BYTES) ] || [ $$$$((bytes % 4)) -ne 0 ]; then echo "ERROR: invalid complete camera_stereo_npu_$(1) raw image size: $$$$bytes"; exit 1; fi; echo "CAMERA_STEREO_NPU_$(1)_RAW_BYTES=$$$$bytes"; $$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=$$(TARGET_BYTES) "$$$$raw" $$@; test $$$$(wc -c < $$@) -eq $$(TARGET_BYTES)

# 整片 Flash 镜像：[CPU 程序补到 32 KiB][model.npu]，从 Flash 0x00A00000 起整份写入。
camera_stereo_npu_$(1)_flash.bin: camera_stereo_npu_$(1).bin $$(NPU_MODEL) ../../soc/soc_addr_map.vh ../../scripts/make_npu_flash_image.sh
	bash ../../scripts/make_npu_flash_image.sh $$< "$$(NPU_MODEL)" $$@
endef

$(eval $(call NPU_VARIANT_RULES,local,0u))
$(eval $(call NPU_VARIANT_RULES,remote,31u))

$(BUILD)/lane_arrow/model_padded.npu: $(LANE_ARROW_MODEL) ../../scripts/pad_npu_model.py ../../scripts/npu_model.py ../../soc/soc_addr_map.vh
	@set -eu; model_bytes=$$(sed -n "s/^\`define SOC_NPU_MODEL_BYTES[[:space:]]*32'd\([0-9][0-9]*\).*/\1/p" ../../soc/soc_addr_map.vh); \
	python3 ../../scripts/pad_npu_model.py --input "$(LANE_ARROW_MODEL)" --output "$@" --size "$$model_bytes"

define LANE_ARROW_VARIANT_RULES
LANE_ARROW_$(1)_PIN := $(2)
LANE_ARROW_$(1)_OBJS := $(patsubst %.c,$(BUILD)/lane_arrow/$(1)/%.o,$(LANE_ARROW_SRCS)) \
	$(BUILD)/lane_arrow/$(1)/init.o $(BUILD)/lane_arrow/$(1)/startup.o
$$(LANE_ARROW_$(1)_OBJS): $$(BSP_SOC_HEADER)

$$(BUILD)/lane_arrow/$(1)/%.o: %.c $$(wildcard *.h) Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(LANE_ARROW_$(1)_PIN) -DCAM2_ORIENTATION_AS_CAM1=$$(NPU_CAM2_ORIENTATION_AS_CAM1) -DCAM_AE_TARGET_TUNED=$$(NPU_CAM_AE_TARGET_TUNED) -DNPU_LANE_ARROW=1 -DNPU_VERBOSE=0 -DNPU_PRINT_BACKGROUND=0 -DNPU_CONFIRM=0 -DNPU_CONFIRM_TRACE=0 -DNPU_QUIET=0 -DNPU_NAMES_GBK=0 -DNPU_STAT_SECONDS=$$(NPU_STAT_SECONDS) -c -o $$@ $$<
$$(BUILD)/lane_arrow/$(1)/ov5640_regs.o: ../camera_app/ov5640_regs.c ../camera_app/ov5640_regs.h Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(LANE_ARROW_$(1)_PIN) -c -o $$@ $$<
$$(BUILD)/lane_arrow/$(1)/init.o: $$(BSP)/lib/startup/init.c Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -DSTEREO_UART_TX_FPIOA=$$(LANE_ARROW_$(1)_PIN) -c -o $$@ $$<
$$(BUILD)/lane_arrow/$(1)/startup.o: $$(BSP)/lib/startup/startup.S Makefile
	mkdir -p $$(@D)
	$$(CC) $$(CFLAGS) -c -o $$@ $$<

camera_stereo_lane_arrow_$(1).elf: $$(LANE_ARROW_$(1)_OBJS) link.lds Makefile
	$$(CC) $$(CFLAGS) $$(LANE_ARROW_$(1)_OBJS) -o $$@ $$(LDFLAGS) -Wl,-Map=camera_stereo_lane_arrow_$(1).map
	$$(SIZE) -A $$@
camera_stereo_lane_arrow_$(1).bin: camera_stereo_lane_arrow_$(1).elf
	@set -eu; raw="$$(BUILD)/camera_stereo_lane_arrow_$(1).raw.bin"; $$(OBJCOPY) -O binary $$< "$$$$raw"; bytes=$$$$(wc -c < "$$$$raw"); if [ "$$$$bytes" -eq 0 ] || [ "$$$$bytes" -gt $$(LANE_ARROW_CPU_BYTES) ] || [ $$$$((bytes % 4)) -ne 0 ]; then echo "ERROR: invalid camera_stereo_lane_arrow_$(1) raw image size: $$$$bytes"; exit 1; fi; echo "CAMERA_STEREO_LANE_ARROW_$(1)_RAW_BYTES=$$$$bytes"; $$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=$$(LANE_ARROW_CPU_BYTES) "$$$$raw" $$@; test $$$$(wc -c < $$@) -eq $$(LANE_ARROW_CPU_BYTES)
camera_stereo_lane_arrow_$(1)_flash.bin: camera_stereo_lane_arrow_$(1).bin $$(BUILD)/lane_arrow/model_padded.npu ../../soc/soc_addr_map.vh ../../scripts/make_npu_flash_image.sh
	bash ../../scripts/make_npu_flash_image.sh $$< "$$(BUILD)/lane_arrow/model_padded.npu" $$@
endef

$(eval $(call LANE_ARROW_VARIANT_RULES,local,0u))
$(eval $(call LANE_ARROW_VARIANT_RULES,remote,31u))

camera_stereo_local.bin: camera_stereo_local.elf
	@set -eu; raw="$(BUILD)/camera_stereo_local.raw.bin"; \
	$(OBJCOPY) -O binary $< "$$raw"; bytes=$$(wc -c < "$$raw"); \
	if [ "$$bytes" -eq 0 ] || [ "$$bytes" -gt $(TARGET_BYTES) ] || [ $$((bytes % 4)) -ne 0 ]; then \
		echo "ERROR: invalid complete local raw image size: $$bytes"; exit 1; fi; \
	echo "CAMERA_STEREO_LOCAL_RAW_BYTES=$$bytes"; \
	$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=$(TARGET_BYTES) "$$raw" $@; \
	test $$(wc -c < $@) -eq $(TARGET_BYTES)
camera_stereo_remote.bin: camera_stereo_remote.elf
	@set -eu; raw="$(BUILD)/camera_stereo_remote.raw.bin"; \
	$(OBJCOPY) -O binary $< "$$raw"; bytes=$$(wc -c < "$$raw"); \
	if [ "$$bytes" -eq 0 ] || [ "$$bytes" -gt $(TARGET_BYTES) ] || [ $$((bytes % 4)) -ne 0 ]; then \
		echo "ERROR: invalid complete remote raw image size: $$bytes"; exit 1; fi; \
	echo "CAMERA_STEREO_REMOTE_RAW_BYTES=$$bytes"; \
	$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=$(TARGET_BYTES) "$$raw" $@; \
	test $$(wc -c < $@) -eq $(TARGET_BYTES)
camera_stereo.bin: camera_stereo_local.bin
	cp $< $@

%.dump: %.elf
	$(OBJDUMP) --disassemble-all $< > $@

clean:
	rm -rf $(BUILD) *.elf *.bin *.dump *.map
