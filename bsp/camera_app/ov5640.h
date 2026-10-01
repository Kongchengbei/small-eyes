#ifndef CAMERA_APP_OV5640_H
#define CAMERA_APP_OV5640_H

#include <stdbool.h>
#include <stdint.h>

enum ov5640_config_error {
    OV5640_CONFIG_OK = 0,
    OV5640_CONFIG_WRITE_NACK,
    OV5640_CONFIG_READ_NACK,
    OV5640_CONFIG_VERIFY_MISMATCH
};

struct ov5640_config_result {
    enum ov5640_config_error error;
    uint16_t failed_reg;
    uint8_t expected;
    uint8_t actual;
    uint32_t writes_completed;
};

/* 配置物理 CAM1 为 640×480、RGB565、标称 15 fps。 */
bool cam1_ov5640_configure_vga_rgb565(struct ov5640_config_result *result);

#endif
