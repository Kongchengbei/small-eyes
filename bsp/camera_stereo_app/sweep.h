#ifndef CAMERA_STEREO_SWEEP_H
#define CAMERA_STEREO_SWEEP_H

#include <stdint.h>
#include "camera_stereo.h"

/* 曝光扫参（NPU_SWEEP=1）/ 只走展示时间表（NPU_SWEEP=2）。
 * on1、on2：对应摄像头是否已开始采集（struct cam_run 的 streaming）。 */
void sweep_init(struct camera_ctx *cam1, struct camera_ctx *cam2, uint32_t on1, uint32_t on2);
/* 主循环每圈调一次；每次最多做一小步（一路的套用或一路的 PATCH），打印排队、不丢。 */
void sweep_step(void);

#endif
