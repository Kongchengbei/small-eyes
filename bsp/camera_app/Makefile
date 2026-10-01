CROSS_COMPILE ?= riscv64-unknown-elf-

CC      := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump
SIZE    := $(CROSS_COMPILE)size

BSP     := ../bsp_app
TARGET  := camera_uart_debug

ASM_SRCS := $(BSP)/lib/startup/startup.S
C_SRCS   := main.c uart.c camera_sccb.c camera_dvp.c ov5640.c ov5640_regs.c \
	$(BSP)/lib/startup/init.c
OBJS     := $(ASM_SRCS:.S=.o) $(C_SRCS:.c=.o)

CFLAGS  := --specs=picolibc.specs \
	-march=rv32im -mabi=ilp32 -mcmodel=medlow \
	-ffunction-sections -fdata-sections -Os -Wall -Wextra
LDFLAGS := -T link.lds -nostartfiles \
	-Wl,--gc-sections -Wl,--check-sections -Wl,-Map=$(TARGET).map

.PHONY: all clean check-size

all: $(TARGET).elf $(TARGET).bin $(TARGET).dump check-size

$(TARGET).elf: $(OBJS) link.lds
	$(CC) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)
	$(SIZE) -A $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) --disassemble-all $< > $@

check-size: $(TARGET).bin
	@test $$(( $$(wc -c < $(TARGET).bin) % 4 )) -eq 0 || \
		{ echo "ERROR: boot image must be a multiple of four bytes"; exit 1; }
	@echo "BOOT_IMAGE_BYTES=$$(wc -c < $(TARGET).bin)"

%.o: %.S
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -I. -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).bin $(TARGET).dump $(TARGET).map
