#ifndef CAMERA_APP_DVP_H
#define CAMERA_APP_DVP_H

#include <stdbool.h>
#include <stdint.h>

/* CAM_STATUS 位定义，保留与 RTL 接口约定一致的原始状态字。 */
enum cam1_status_bit {
    CAM1_STATUS_ENABLED       = 1u << 0,
    CAM1_STATUS_PCLK_SEEN     = 1u << 1,
    CAM1_STATUS_VSYNC_SEEN    = 1u << 2,
    CAM1_STATUS_HREF_SEEN     = 1u << 3,
    CAM1_STATUS_FRAME_ACTIVE  = 1u << 4,
    CAM1_STATUS_FRAME_DONE    = 1u << 5,
    CAM1_STATUS_FIFO_FULL     = 1u << 6,
    CAM1_STATUS_OVERFLOW      = 1u << 7,
    CAM1_STATUS_DMA_BUSY      = 1u << 8,
    CAM1_STATUS_DMA_DONE      = 1u << 9,
    CAM1_STATUS_DMA_ERROR     = 1u << 10,
    CAM1_STATUS_DDR_READY     = 1u << 11,
    CAM1_STATUS_FIFO_UNDERFLOW = 1u << 13,
    CAM1_STATUS_DVP_ERROR     = 1u << 14
};

/* 一次快照中的控制状态、DVP 诊断和最近完成 DMA 帧元数据。 */
struct cam1_dvp_snapshot {
    uint32_t snapshot_control;
    uint32_t frame_count;
    uint32_t last_frame_pixels;
    uint32_t pclk_count;
    uint32_t error_flags;
    uint32_t last_frame_lines;
    uint32_t status;
    uint32_t last_frame_bytes;
    uint32_t fifo_level;
    uint32_t fifo_max_level;
    uint32_t fifo_error;
    uint32_t dma_status;
    uint32_t dma_error_code;
    uint32_t last_frame_addr;
    uint32_t current_write_buffer;
    uint32_t last_complete_buffer;
    uint32_t frame_checksum;
    uint32_t ready_mask;
    uint32_t dropped_frames;
    uint32_t snapshot_sequence;
    uint32_t dvp_frame_count;
    uint32_t dvp_error_flags;
    uint32_t current_pixel_count;
    uint32_t current_byte_count;
    uint32_t current_line_count;
};

/* 请求完整跨时钟域快照；timeout 以 MMIO 轮询次数计。 */
bool cam1_dvp_snapshot(struct cam1_dvp_snapshot *snapshot,
                       uint32_t timeout);

/* 等待首个带 ready buffer 的 DMA 完成帧；attempts 是毫秒级等待次数。 */
bool cam1_dvp_wait_first_frame(struct cam1_dvp_snapshot *snapshot,
                               uint32_t attempts);

/* DMA 必须先于 DVP capture enable 打开。 */
void cam1_dma_enable(bool enable);

/* 释放快照中由 CPU 持有的缓冲槽；返回 false 表示 mailbox 超时。 */
bool cam1_dvp_release(uint32_t ready_mask, uint32_t timeout);

#endif
