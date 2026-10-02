#ifndef CAMERA_STEREO_H
#define CAMERA_STEREO_H

#include <stdbool.h>
#include <stdint.h>

struct camera_ctx {
    uint32_t base;
    uint32_t ctrl_shadow;
    uint32_t buffer0;
    uint32_t buffer1;
    uint32_t id;
};

struct cam_snapshot {
    uint32_t snapshot_control, frame_count, pixels, pclk_count, error_flags;
    uint32_t lines, status, bytes, fifo_level, fifo_max, fifo_error;
    uint32_t dma_status, dma_code, frame_addr, write_buffer, complete_buffer;
    uint32_t hw_sum16, ready_mask, dropped, sequence, dvp_frames, dvp_flags;
    uint32_t current_pixels, current_bytes, current_lines;
};

void cam_init(struct camera_ctx *cam, uint32_t base, uint32_t buffer0,
              uint32_t buffer1, uint32_t id);
void cam_sccb_init(struct camera_ctx *cam);
bool cam_write_reg(struct camera_ctx *cam, uint16_t reg, uint8_t value);
bool cam_read_reg(struct camera_ctx *cam, uint16_t reg, uint8_t *value);
void cam_capture_enable(struct camera_ctx *cam, bool enable);
void cam_dma_enable(struct camera_ctx *cam, bool enable);
bool cam_snapshot(struct camera_ctx *cam, struct cam_snapshot *s,
                  uint32_t timeout);
bool cam_release(struct camera_ctx *cam, uint32_t mask);
bool cam_configure_vga(struct camera_ctx *cam, uint16_t *failed_reg,
                       uint32_t *writes_completed);
void cam_delay_ms(uint32_t milliseconds);

#endif
