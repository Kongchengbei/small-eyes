CROSS_COMPILE ?= riscv64-unknown-elf-

CC      := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump
SIZE    := $(CROSS_COMPILE)size

BSP      := ../bsp_app
BUILD    := build
APP_SRCS := main.c uart.c camera_sccb.c camera_dvp.c ov5640.c ov5640_regs.c
STARTUP_SRC := $(BSP)/lib/startup/startup.S
INIT_SRC    := $(BSP)/lib/startup/init.c

CFLAGS := --specs=picolibc.specs \
	-march=rv32im -mabi=ilp32 -mcmodel=medlow \
	-ffunction-sections -fdata-sections -Os -Wall -Wextra
LDFLAGS := -T link.lds -nostartfiles \
	-Wl,--gc-sections -Wl,--check-sections

LOCAL_OBJS  := $(addprefix $(BUILD)/local/,$(APP_SRCS:.c=.o)) \
	$(BUILD)/local/init.o $(BUILD)/local/startup.o
REMOTE_OBJS := $(addprefix $(BUILD)/remote/,$(APP_SRCS:.c=.o)) \
	$(BUILD)/remote/init.o $(BUILD)/remote/startup.o
GPIO_LOCAL_OBJS := $(BUILD)/gpio_local/gpio_test.o \
	$(BUILD)/gpio_local/uart.o $(BUILD)/gpio_local/init.o \
	$(BUILD)/gpio_local/startup.o
GPIO_REMOTE_OBJS := $(BUILD)/gpio_remote/gpio_test.o \
	$(BUILD)/gpio_remote/uart.o $(BUILD)/gpio_remote/init.o \
	$(BUILD)/gpio_remote/startup.o

.PHONY: all local remote gpio-test gpio-test-local gpio-test-remote \
	clean check-size-local check-size-remote

# 默认构建两种独立镜像，并将兼容文件名固定复制为本地版本。
all: camera_uart_debug_local.bin camera_uart_debug_local.dump \
	camera_uart_debug_remote.bin camera_uart_debug_remote.dump \
	check-size-local check-size-remote camera_uart_debug.bin

local: camera_uart_debug_local.bin camera_uart_debug_local.dump check-size-local
remote: camera_uart_debug_remote.bin camera_uart_debug_remote.dump check-size-remote

# GPIO 诊断固件独立构建，不改变默认相机固件目标。
gpio-test: gpio-test-local gpio-test-remote
gpio-test-local: camera_gpio_test_local.bin camera_gpio_test_local.dump
gpio-test-remote: camera_gpio_test_remote.bin camera_gpio_test_remote.dump

camera_uart_debug_local.elf: $(LOCAL_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(LOCAL_OBJS) -o $@ $(LDFLAGS) \
		-Wl,-Map=camera_uart_debug_local.map
	$(SIZE) -A $@

camera_uart_debug_remote.elf: $(REMOTE_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(REMOTE_OBJS) -o $@ $(LDFLAGS) \
		-Wl,-Map=camera_uart_debug_remote.map
	$(SIZE) -A $@

camera_gpio_test_local.elf: $(GPIO_LOCAL_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(GPIO_LOCAL_OBJS) -o $@ $(LDFLAGS) \
		-Wl,-Map=camera_gpio_test_local.map
	$(SIZE) -A $@

camera_gpio_test_remote.elf: $(GPIO_REMOTE_OBJS) link.lds Makefile
	$(CC) $(CFLAGS) $(GPIO_REMOTE_OBJS) -o $@ $(LDFLAGS) \
		-Wl,-Map=camera_gpio_test_remote.map
	$(SIZE) -A $@

# 检查完整 ELF 原始镜像后，以 binary 输入补零到当前 6956 字节 loader 长度。
$(BUILD)/local/camera_uart_debug_local.raw.bin: camera_uart_debug_local.elf
	mkdir -p $(@D)
	$(OBJCOPY) -O binary $< $@
	@set -eu; bytes=$$(wc -c < $@); \
	if [ "$$bytes" -eq 0 ] || [ "$$bytes" -gt 6956 ] || \
		[ $$((bytes % 4)) -ne 0 ]; then \
		echo "ERROR: invalid local camera raw image size: $$bytes"; exit 1; \
	fi; \
	echo "CAMERA_LOCAL_RAW_BYTES=$$bytes"

$(BUILD)/remote/camera_uart_debug_remote.raw.bin: camera_uart_debug_remote.elf
	mkdir -p $(@D)
	$(OBJCOPY) -O binary $< $@
	@set -eu; bytes=$$(wc -c < $@); \
	if [ "$$bytes" -eq 0 ] || [ "$$bytes" -gt 6956 ] || \
		[ $$((bytes % 4)) -ne 0 ]; then \
		echo "ERROR: invalid remote camera raw image size: $$bytes"; exit 1; \
	fi; \
	echo "CAMERA_REMOTE_RAW_BYTES=$$bytes"

camera_uart_debug_local.bin: $(BUILD)/local/camera_uart_debug_local.raw.bin
	$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=6956 $< $@
	@test $$(wc -c < $@) -eq 6956 || \
		{ echo "ERROR: local camera image must be exactly 6956 bytes"; exit 1; }

camera_uart_debug_remote.bin: $(BUILD)/remote/camera_uart_debug_remote.raw.bin
	$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=6956 $< $@
	@test $$(wc -c < $@) -eq 6956 || \
		{ echo "ERROR: remote camera image must be exactly 6956 bytes"; exit 1; }

# 原样导出 ELF 的全部 LOAD 内容，再填充到当前 6956 字节 loader 长度。
# 先检查完整原始镜像；此长度只适用于当前 loader 配置。
camera_gpio_test_local.bin: camera_gpio_test_local.elf
	@set -eu; \
	raw="$(BUILD)/gpio_local/camera_gpio_test_local.raw.bin"; \
	$(OBJCOPY) -O binary $< "$$raw"; \
	bytes=$$(wc -c < "$$raw"); \
	if [ "$$bytes" -eq 0 ] || [ "$$bytes" -gt 6956 ] || \
		[ $$((bytes % 4)) -ne 0 ]; then \
		echo "ERROR: invalid local raw GPIO image size: $$bytes"; \
		rm -f "$$raw"; exit 1; \
	fi; \
	echo "GPIO_LOCAL_RAW_BYTES=$$bytes"; \
	$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=6956 \
		"$$raw" $@; \
	padded=$$(wc -c < $@); \
	if [ "$$padded" -ne 6956 ]; then \
		echo "ERROR: local padded GPIO image must be 6956 bytes, got $$padded"; \
		exit 1; \
	fi; \
	rm -f "$$raw"; \
	echo "GPIO_LOCAL_PADDED_BYTES=$$padded"

camera_gpio_test_remote.bin: camera_gpio_test_remote.elf
	@set -eu; \
	raw="$(BUILD)/gpio_remote/camera_gpio_test_remote.raw.bin"; \
	$(OBJCOPY) -O binary $< "$$raw"; \
	bytes=$$(wc -c < "$$raw"); \
	if [ "$$bytes" -eq 0 ] || [ "$$bytes" -gt 6956 ] || \
		[ $$((bytes % 4)) -ne 0 ]; then \
		echo "ERROR: invalid remote raw GPIO image size: $$bytes"; \
		rm -f "$$raw"; exit 1; \
	fi; \
	echo "GPIO_REMOTE_RAW_BYTES=$$bytes"; \
	$(OBJCOPY) -I binary -O binary --gap-fill=0 --pad-to=6956 \
		"$$raw" $@; \
	padded=$$(wc -c < $@); \
	if [ "$$padded" -ne 6956 ]; then \
		echo "ERROR: remote padded GPIO image must be 6956 bytes, got $$padded"; \
		exit 1; \
	fi; \
	rm -f "$$raw"; \
	echo "GPIO_REMOTE_PADDED_BYTES=$$padded"

camera_uart_debug_local.dump: camera_uart_debug_local.elf
	$(OBJDUMP) --disassemble-all $< > $@

camera_uart_debug_remote.dump: camera_uart_debug_remote.elf
	$(OBJDUMP) --disassemble-all $< > $@

camera_gpio_test_local.dump: camera_gpio_test_local.elf
	$(OBJDUMP) --disassemble-all $< > $@

camera_gpio_test_remote.dump: camera_gpio_test_remote.elf
	$(OBJDUMP) --disassemble-all $< > $@

camera_uart_debug.bin: camera_uart_debug_local.bin
	cp $< $@

check-size-local: camera_uart_debug_local.bin
	@test $$(( $$(wc -c < $<) % 4 )) -eq 0 || \
		{ echo "ERROR: local boot image must be a multiple of four bytes"; exit 1; }
	@echo "LOCAL_BOOT_IMAGE_BYTES=$$(wc -c < $<)"

check-size-remote: camera_uart_debug_remote.bin
	@test $$(( $$(wc -c < $<) % 4 )) -eq 0 || \
		{ echo "ERROR: remote boot image must be a multiple of four bytes"; exit 1; }
	@echo "REMOTE_BOOT_IMAGE_BYTES=$$(wc -c < $<)"

$(BUILD)/local/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=0u -I. -c -o $@ $<

$(BUILD)/remote/%.o: %.c $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=31u -I. -c -o $@ $<

$(BUILD)/local/init.o: $(INIT_SRC) $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=0u -I. -c -o $@ $<

$(BUILD)/remote/init.o: $(INIT_SRC) $(wildcard *.h) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=31u -I. -c -o $@ $<

$(BUILD)/local/startup.o: $(STARTUP_SRC) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/remote/startup.o: $(STARTUP_SRC) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/gpio_local/gpio_test.o: gpio_test.c uart.h Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=0u -I. -c -o $@ $<

$(BUILD)/gpio_remote/gpio_test.o: gpio_test.c uart.h Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=31u -I. -c -o $@ $<

$(BUILD)/gpio_local/uart.o: uart.c uart.h Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=0u -I. -c -o $@ $<

$(BUILD)/gpio_remote/uart.o: uart.c uart.h Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -DCAMERA_UART_TX_FPIOA=31u -I. -c -o $@ $<

$(BUILD)/gpio_local/init.o: $(INIT_SRC) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/gpio_remote/init.o: $(INIT_SRC) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/gpio_local/startup.o: $(STARTUP_SRC) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/gpio_remote/startup.o: $(STARTUP_SRC) Makefile
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(BUILD)/local $(BUILD)/remote $(BUILD)/gpio_local $(BUILD)/gpio_remote
	rm -f camera_uart_debug_local.elf camera_uart_debug_local.bin \
		camera_uart_debug_local.dump camera_uart_debug_local.map \
		camera_uart_debug_remote.elf camera_uart_debug_remote.bin \
		camera_uart_debug_remote.dump camera_uart_debug_remote.map \
		camera_uart_debug.bin camera_gpio_test_local.elf \
		camera_gpio_test_local.bin camera_gpio_test_local.dump \
		camera_gpio_test_local.map camera_gpio_test_remote.elf \
		camera_gpio_test_remote.bin camera_gpio_test_remote.dump \
		camera_gpio_test_remote.map
