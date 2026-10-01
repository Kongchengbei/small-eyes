#ifndef CAMERA_APP_OV5640_REGS_H
#define CAMERA_APP_OV5640_REGS_H

#include <stdint.h>

struct ov5640_reg {
    uint16_t address;
    uint8_t value;
};

extern const struct ov5640_reg ov5640_vga_rgb565_regs[];
extern const uint32_t ov5640_vga_rgb565_reg_count;

#endif
