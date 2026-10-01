#ifndef CAMERA_APP_DVP_H
#define CAMERA_APP_DVP_H

#include <stdbool.h>
#include <stdint.h>

enum cam1_dvp_status {
    CAM1_DVP_ENABLED    = 1u << 0,
    CAM1_DVP_PCLK_SEEN  = 1u << 1,
    CAM1_DVP_VSYNC_SEEN = 1u << 2,
    CAM1_DVP_HREF_SEEN  = 1u << 3,
    CAM1_DVP_FRAME_SEEN = 1u << 4
};

struct cam1_dvp_snapshot {
    uint32_t status;
    uint32_t frame_count;
    uint32_t last_frame_pixels;
    uint32_t last_frame_lines;
    uint32_t pclk_count;
    uint32_t error_flags;
};

/* 请求 PCLK 域冻结一组一致统计；无 PCLK 时按 timeout 返回 false。 */
bool cam1_dvp_snapshot(struct cam1_dvp_snapshot *snapshot,
                       uint32_t timeout);

/* 等待至少一帧完成，并返回完成帧的快照。 */
bool cam1_dvp_wait_first_frame(struct cam1_dvp_snapshot *snapshot,
                              uint32_t attempts);

#endif
