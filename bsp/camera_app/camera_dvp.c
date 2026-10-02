#include "camera_dvp.h"

#include "camera_sccb.h"

#define CAM1_MMIO_BASE          0x40000300u
#define CAM1_SNAPSHOT_CTRL      (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x08u))
#define CAM1_FRAME_COUNT        (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x0cu))
#define CAM1_PIXEL_COUNT        (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x10u))
#define CAM1_PCLK_COUNT         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x14u))
#define CAM1_ERROR_FLAGS        (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x18u))
#define CAM1_LINE_COUNT         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x1cu))
#define CAM1_STATUS             (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x20u))
#define CAM1_BYTE_COUNT         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x24u))
#define CAM1_FIFO_LEVEL         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x28u))
#define CAM1_FIFO_MAX_LEVEL     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x2cu))
#define CAM1_FIFO_ERROR         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x30u))
#define CAM1_DMA_STATUS         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x34u))
#define CAM1_DMA_ERROR_CODE     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x38u))
#define CAM1_LAST_FRAME_ADDR    (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x3cu))
#define CAM1_CURRENT_WRITE_BUF  (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x40u))
#define CAM1_LAST_COMPLETE_BUF  (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x44u))
#define CAM1_FRAME_CHECKSUM     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x48u))
#define CAM1_READY_MASK         (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x4cu))
#define CAM1_DROPPED_FRAMES     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x50u))
#define CAM1_SNAPSHOT_SEQUENCE  (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x54u))
#define CAM1_DVP_FRAME_COUNT    (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x58u))
#define CAM1_DVP_ERROR_FLAGS    (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x5cu))
#define CAM1_BUFFER_RELEASE     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x60u))
#define CAM1_DMA_CONTROL        (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x64u))
#define CAM1_CURRENT_PIXELS     (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x80u))
#define CAM1_CURRENT_BYTES      (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x84u))
#define CAM1_CURRENT_LINES      (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x88u))

#define CAM1_SNAPSHOT_BUSY      (1u << 0)
#define CAM1_SNAPSHOT_VALID     (1u << 1)
#define CAM1_SNAPSHOT_TIMEOUT   (1u << 2)
#define CAM1_RELEASE_BUSY       (1u << 0)

bool cam1_dvp_snapshot(struct cam1_dvp_snapshot *snapshot,
                       uint32_t timeout)
{
    uint32_t control;

    if (snapshot == 0) {
        return false;
    }

    CAM1_SNAPSHOT_CTRL = 1u;
    snapshot->snapshot_control = 0u;
    while (timeout != 0u) {
        control = CAM1_SNAPSHOT_CTRL;
        snapshot->snapshot_control = control;
        if ((control & CAM1_SNAPSHOT_TIMEOUT) != 0u) {
            return false;
        }
        if (((control & CAM1_SNAPSHOT_BUSY) == 0u) &&
            ((control & CAM1_SNAPSHOT_VALID) != 0u)) {
            /* 所有字段在硬件快照握手期间保持冻结，可按合同顺序读取。 */
            snapshot->frame_count = CAM1_FRAME_COUNT;
            snapshot->last_frame_pixels = CAM1_PIXEL_COUNT;
            snapshot->pclk_count = CAM1_PCLK_COUNT;
            snapshot->error_flags = CAM1_ERROR_FLAGS;
            snapshot->last_frame_lines = CAM1_LINE_COUNT;
            snapshot->status = CAM1_STATUS;
            snapshot->last_frame_bytes = CAM1_BYTE_COUNT;
            snapshot->fifo_level = CAM1_FIFO_LEVEL;
            snapshot->fifo_max_level = CAM1_FIFO_MAX_LEVEL;
            snapshot->fifo_error = CAM1_FIFO_ERROR;
            snapshot->dma_status = CAM1_DMA_STATUS;
            snapshot->dma_error_code = CAM1_DMA_ERROR_CODE;
            snapshot->last_frame_addr = CAM1_LAST_FRAME_ADDR;
            snapshot->current_write_buffer = CAM1_CURRENT_WRITE_BUF;
            snapshot->last_complete_buffer = CAM1_LAST_COMPLETE_BUF;
            snapshot->frame_checksum = CAM1_FRAME_CHECKSUM;
            snapshot->ready_mask = CAM1_READY_MASK;
            snapshot->dropped_frames = CAM1_DROPPED_FRAMES;
            snapshot->snapshot_sequence = CAM1_SNAPSHOT_SEQUENCE;
            snapshot->dvp_frame_count = CAM1_DVP_FRAME_COUNT;
            snapshot->dvp_error_flags = CAM1_DVP_ERROR_FLAGS;
            snapshot->current_pixel_count = CAM1_CURRENT_PIXELS;
            snapshot->current_byte_count = CAM1_CURRENT_BYTES;
            snapshot->current_line_count = CAM1_CURRENT_LINES;
            return true;
        }
        --timeout;
    }

    snapshot->snapshot_control = CAM1_SNAPSHOT_CTRL;
    return false;
}

bool cam1_dvp_wait_first_frame(struct cam1_dvp_snapshot *snapshot,
                               uint32_t attempts)
{
    while (attempts != 0u) {
        if (cam1_dvp_snapshot(snapshot, 100000u) &&
            (snapshot->ready_mask != 0u) &&
            (snapshot->last_frame_addr != 0xffffffffu)) {
            return true;
        }
        cam1_delay_ms(1u);
        --attempts;
    }
    return false;
}

void cam1_dma_enable(bool enable)
{
    /* 先打开 DDR 域 DMA，再开启 DVP，避免首帧进入无消费者的 FIFO。 */
    CAM1_DMA_CONTROL = enable ? 1u : 0u;
}

bool cam1_dvp_release(uint32_t ready_mask, uint32_t timeout)
{
    while (((CAM1_BUFFER_RELEASE & CAM1_RELEASE_BUSY) != 0u) &&
           (timeout != 0u)) {
        --timeout;
    }
    if (timeout == 0u) {
        return false;
    }

    CAM1_BUFFER_RELEASE = ready_mask & 0x3u;
    while (timeout != 0u) {
        if ((CAM1_BUFFER_RELEASE & CAM1_RELEASE_BUSY) == 0u) {
            return true;
        }
        --timeout;
    }
    return (CAM1_BUFFER_RELEASE & CAM1_RELEASE_BUSY) == 0u;
}
