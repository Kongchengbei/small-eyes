#include "camera_dvp.h"

#include "camera_sccb.h"

#define CAM1_MMIO_BASE       0x40000300u
#define CAM1_STATUS          (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x04u))
#define CAM1_SNAPSHOT_CTRL   (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x08u))
#define CAM1_FRAME_COUNT     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x0cu))
#define CAM1_PIXEL_COUNT     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x10u))
#define CAM1_PCLK_COUNT      (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x14u))
#define CAM1_ERROR_FLAGS     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x18u))
#define CAM1_LINE_COUNT      (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x1cu))

#define CAM1_SNAPSHOT_BUSY   (1u << 0)
#define CAM1_SNAPSHOT_VALID  (1u << 1)

bool cam1_dvp_snapshot(struct cam1_dvp_snapshot *snapshot,
                       uint32_t timeout)
{
    uint32_t control;

    if (snapshot == 0) {
        return false;
    }

    CAM1_SNAPSHOT_CTRL = 1u;
    do {
        control = CAM1_SNAPSHOT_CTRL;
        if (((control & CAM1_SNAPSHOT_BUSY) == 0u) &&
            ((control & CAM1_SNAPSHOT_VALID) != 0u)) {
            snapshot->status = (CAM1_STATUS >> 8) & 0x1fu;
            snapshot->frame_count = CAM1_FRAME_COUNT;
            snapshot->last_frame_pixels = CAM1_PIXEL_COUNT;
            snapshot->pclk_count = CAM1_PCLK_COUNT;
            snapshot->error_flags = CAM1_ERROR_FLAGS;
            snapshot->last_frame_lines = CAM1_LINE_COUNT;
            return true;
        }
        --timeout;
    } while (timeout != 0u);

    return false;
}

bool cam1_dvp_wait_first_frame(struct cam1_dvp_snapshot *snapshot,
                              uint32_t attempts)
{
    while (attempts != 0u) {
        if (cam1_dvp_snapshot(snapshot, 10000u) &&
            (snapshot->frame_count != 0u)) {
            return true;
        }
        cam1_delay_ms(1u);
        --attempts;
    }
    return false;
}
