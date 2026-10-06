CROSS_COMPILE ?= riscv64-unknown-elf-
.DEFAULT_GOAL := all
include ../../../soc_config.mk

CC      := $(CROSS_COMPILE)gcc
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump
SIZE    := $(CROSS_COMPILE)size

BSP    := ../..
TARGET := coremark

ASM_SRCS := $(BSP)/lib/startup/startup.S
C_SRCS   := $(wildcard ./*.c)
C_SRCS   += $(BSP)/lib/startup/init.c
C_SRCS   += $(BSP)/lib/perip/src/core.c
C_SRCS   += $(BSP)/lib/perip/src/fpioa.c
C_SRCS   += $(BSP)/lib/perip/src/uart.c
C_SRCS   += $(BSP)/lib/driver/src/printf.c

OBJS := $(ASM_SRCS:.S=.o) $(C_SRCS:.c=.o)
$(OBJS): $(BSP_SOC_HEADER)

INCLUDES := -I. \
            -I$(BSP)/lib \
            -I$(BSP)/lib/perip/include \
            -I$(BSP)/lib/driver/include

CFLAGS := --specs=picolibc.specs \
          -march=rv32im -mabi=ilp32 -mcmodel=medlow \
          -ffunction-sections -fdata-sections \
          -fno-builtin-printf -fno-builtin-malloc -O2
#--specs=picolibc.specs 
LDFLAGS := -T $(BSP)/link.lds -nostartfiles \
           -Wl,--gc-sections -Wl,--check-sections \
           -Wl,-Map=$(TARGET).map

.PHONY: all clean

all: $(TARGET).elf $(TARGET).bin $(TARGET).dump

$(TARGET).elf: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)
	$(SIZE) -A $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) --disassemble-all $< > $@

%.o: %.S
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET).elf $(TARGET).bin \
	      $(TARGET).dump $(TARGET).map
