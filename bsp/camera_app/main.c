#include <stdint.h>

#include "camera_sccb.h"
#include "camera_dvp.h"
#include "ov5640.h"
#include "uart.h"
#include "../include/soc_defs.h"

extern uint32_t system_cpu_freq;

#define CAM1_FRAME_BYTES 614400u
#define CAM1_INVALID_ADDR 0xffffffffu
#define CAM1_ERROR_STATUS_MASK (CAM1_STATUS_OVERFLOW | CAM1_STATUS_DMA_ERROR | \
	CAM1_STATUS_FIFO_UNDERFLOW | CAM1_STATUS_DVP_ERROR)

static void print_snapshot(const struct cam1_dvp_snapshot *snapshot)
{
    uart_puts("CAM1 STATUS       : ");
    uart_puthex(snapshot->status);
    uart_putc('\n');
    uart_puts("CAM1 FRAME        : ");
    uart_putdec(snapshot->frame_count);
    uart_puts(" (DVP ");
    uart_putdec(snapshot->dvp_frame_count);
    uart_puts(")\n");
    uart_puts("CAM1 LINES        : ");
    uart_putdec(snapshot->last_frame_lines);
    uart_puts(" (current ");
    uart_putdec(snapshot->current_line_count);
    uart_puts(")\n");
    uart_puts("CAM1 PIXELS       : ");
    uart_putdec(snapshot->last_frame_pixels);
    uart_puts(" (current ");
    uart_putdec(snapshot->current_pixel_count);
    uart_puts(")\n");
    uart_puts("CAM1 BYTES        : ");
    uart_putdec(snapshot->last_frame_bytes);
    uart_puts(" (current ");
    uart_putdec(snapshot->current_byte_count);
    uart_puts(")\n");
    uart_puts("CAM1 FIFO LEVEL   : ");
    uart_putdec(snapshot->fifo_level);
    uart_puts("\nCAM1 FIFO MAX     : ");
    uart_putdec(snapshot->fifo_max_level);
    uart_putc('\n');
    uart_puts("CAM1 OVERFLOW     : ");
    uart_putdec((snapshot->status >> 7) & 1u);
    uart_puts(" FIFO_ERROR=");
    uart_puthex(snapshot->fifo_error);
    uart_puts(" DVP_FLAGS=");
    uart_puthex(snapshot->dvp_error_flags);
    uart_putc('\n');
    uart_puts("CAM1 DMA BUSY     : ");
    uart_putdec((snapshot->dma_status >> 1) & 1u);
    uart_puts(" STATUS=");
    uart_puthex(snapshot->dma_status);
    uart_putc('\n');
    uart_puts("CAM1 DMA DONE     : ");
    uart_putdec((snapshot->dma_status >> 2) & 1u);
    uart_putc('\n');
    uart_puts("CAM1 DMA ERROR    : ");
    uart_putdec((snapshot->dma_status >> 3) & 1u);
    uart_puts(" CODE=");
    uart_puthex(snapshot->dma_error_code);
    uart_putc('\n');
    uart_puts("CAM1 WRITE BUFFER : ");
    uart_puthex(snapshot->current_write_buffer);
    uart_putc('\n');
    uart_puts("CAM1 READY BUFFER : ");
    uart_puthex(snapshot->ready_mask);
    uart_puts(" LAST=");
    uart_puthex(snapshot->last_complete_buffer);
    uart_putc('\n');
    uart_puts("CAM1 FRAME ADDR   : ");
    uart_puthex(snapshot->last_frame_addr);
    uart_putc('\n');
    uart_puts("CAM1 CHECKSUM     : sum16 (not CRC32) ");
    uart_puthex(snapshot->frame_checksum);
    uart_putc('\n');
    uart_puts("CAM1 FIFO ERRORS  : ");
    uart_puthex(snapshot->error_flags);
    uart_puts(" DROPPED=");
    uart_putdec(snapshot->dropped_frames);
    uart_puts(" SEQ=");
    uart_putdec(snapshot->snapshot_sequence);
    uart_putc('\n');
}

static uint32_t checksum_ddr(uint32_t frame_addr)
{
    const volatile uint32_t *words =
        (const volatile uint32_t *)(uintptr_t)frame_addr;
    uint32_t sum = 0u;
    uint32_t i;

    /* 两个小端 uint16_t 像素按 32 位读取，累计结果按 2^32 回绕。 */
    for (i = 0u; i < (CAM1_FRAME_BYTES / 4u); ++i) {
        uint32_t packed = words[i];
        sum += packed & 0xffffu;
        sum += packed >> 16;
    }
    return sum;
}

static void inspect_ddr_frame(const struct cam1_dvp_snapshot *snapshot)
{
    const volatile uint16_t *pixels =
        (const volatile uint16_t *)(uintptr_t)snapshot->last_frame_addr;
    uint32_t i;
    uint32_t ddr_checksum;

    uart_puts("CAM1 RGB565 SAMPLES:");
    for (i = 0u; i < 8u; ++i) {
        uart_putc(' ');
        uart_puthex(pixels[i]);
    }
    uart_putc('\n');

    ddr_checksum = checksum_ddr(snapshot->last_frame_addr);
    uart_puts("CAM1 DDR CHECKSUM : sum16 (not CRC32) ");
    uart_puthex(ddr_checksum);
    uart_puts(" MATCH=");
    uart_puts(ddr_checksum == snapshot->frame_checksum ? "YES\n" : "NO\n");
}

static bool valid_frame_descriptor(const struct cam1_dvp_snapshot *snapshot)
{
    uint32_t slot_mask;
    uint32_t expected_address;

    if ((snapshot->last_frame_pixels != 307200u) ||
        (snapshot->last_frame_bytes != CAM1_FRAME_BYTES) ||
        (snapshot->last_frame_lines != 480u) ||
        (snapshot->last_complete_buffer > 1u)) {
        return false;
    }

    slot_mask = 1u << snapshot->last_complete_buffer;
    expected_address = (snapshot->last_complete_buffer == 0u) ?
                       SOC_CAM1_BUFFER0_BASE : SOC_CAM1_BUFFER1_BASE;
    return ((snapshot->ready_mask & slot_mask) != 0u) &&
           (snapshot->last_frame_addr == expected_address);
}

int main(void)
{
    uint8_t pidh = 0u;
    uint8_t pidl = 0u;
    bool pidh_ack;
    bool pidl_ack;
    bool detected;
    struct ov5640_config_result config_result;
    struct cam1_dvp_snapshot snapshot;
    uint32_t quiet_polls = 999u;
    uint32_t last_error_status = 0u;
    uint32_t last_error_dma_status = 0u;
    uint32_t last_error_dma_code = 0u;
    uint32_t last_error_fifo = 0u;
    uint32_t last_error_dvp = 0u;
    bool error_signature_valid = false;
    bool error_active;
    bool error_signature_changed;

    uart_init(115200u, CAMERA_UART_TX_FPIOA);

    uart_puts("=== Small Eyes Camera Bring-up ===\n\n");
    uart_puts("UART TEST OK\n");

    /* CPU 仅在引导程序完成 DDR 写入和逐字回读后才会离开复位。 */
    uart_puts("DDR INIT OK\n");
    uart_puts("CPU CLOCK   : ");
    uart_putdec(system_cpu_freq);
    uart_puts(" Hz\n");
    uart_puts("UART MMIO   : ");
    uart_puthex(SOC_UART0_BASE);
    uart_putc('\n');
    uart_puts("SYSTEM READY\n");

    uart_puts("CAM1 probe...\n");
    cam1_sccb_init();
    pidh_ack = cam1_ov5640_read_reg(0x300au, &pidh);
    pidl_ack = cam1_ov5640_read_reg(0x300bu, &pidl);

    if (pidh_ack && pidl_ack) {
        uart_puts("CAM1 SCCB    : OK\n");
    } else {
        uart_puts("CAM1 SCCB    : NO ACK\n");
    }
    uart_puts("CAM1 PIDH    : ");
    uart_puthex(pidh);
    uart_putc('\n');
    uart_puts("CAM1 PIDL    : ");
    uart_puthex(pidl);
    uart_putc('\n');

    detected = pidh_ack && pidl_ack && (pidh == 0x56u) && (pidl == 0x40u);
    if (detected) {
        uart_puts("CAM1 OV5640 : DETECTED\n");
    } else {
        uart_puts("CAM1 OV5640 : NOT DETECTED\n");
    }

    if (detected) {
        uart_puts("CAM1 RESET  : OK\n");
        if (cam1_ov5640_configure_vga_rgb565(&config_result)) {
            uart_puts("CAM1 CONFIG : 640x480 RGB565\n");
            uart_puts("REG WRITE   : OK\n");
            cam1_dma_enable(true);
            uart_puts("CAM1 DMA    : ENABLED\n");
            uart_puts("CAM1 START  : OK\n");
            cam1_capture_enable(true);

            /* 每次只处理完成快照指向的已锁定缓冲区，再归还其 ready 位。 */
            for (;;) {
                if (!cam1_dvp_snapshot(&snapshot, 100000u)) {
                    uart_puts("CAM1 SNAPSHOT TIMEOUT CTRL=");
                    uart_puthex(snapshot.snapshot_control);
                    uart_puts("\n");
                    cam1_delay_ms(1u);
                    continue;
                }

                error_active =
                    (((snapshot.status & CAM1_ERROR_STATUS_MASK) != 0u) ||
                     ((snapshot.dma_status & (1u << 3)) != 0u) ||
                     (snapshot.dma_error_code != 0u) ||
                     (snapshot.fifo_error != 0u) ||
                     (snapshot.dvp_error_flags != 0u));
                /* 错误签名只比较错误位，忽略帧活动、busy/done 等动态位。 */
                error_signature_changed = error_active &&
                    (!error_signature_valid ||
                     ((snapshot.status & CAM1_ERROR_STATUS_MASK) !=
                      last_error_status) ||
                     ((snapshot.dma_status & (1u << 3)) !=
                      last_error_dma_status) ||
                     (snapshot.dma_error_code != last_error_dma_code) ||
                     (snapshot.fifo_error != last_error_fifo) ||
                     (snapshot.dvp_error_flags != last_error_dvp));

                if (error_active) {
                    if (error_signature_changed) {
                        uart_puts("CAM1 ERROR SNAPSHOT\n");
                        print_snapshot(&snapshot);
                    }
                    last_error_status = snapshot.status & CAM1_ERROR_STATUS_MASK;
                    last_error_dma_status = snapshot.dma_status & (1u << 3);
                    last_error_dma_code = snapshot.dma_error_code;
                    last_error_fifo = snapshot.fifo_error;
                    last_error_dvp = snapshot.dvp_error_flags;
                    error_signature_valid = true;
                } else {
                    error_signature_valid = false;
                }

                if ((snapshot.ready_mask != 0u) &&
                    (snapshot.last_frame_addr != CAM1_INVALID_ADDR)) {
                    quiet_polls = 0u;
                    if (!error_signature_changed) {
                        print_snapshot(&snapshot);
                    }
                    if (!valid_frame_descriptor(&snapshot)) {
                        uart_puts("CAM1 INVALID FRAME DESCRIPTOR\n");
                    } else {
                        inspect_ddr_frame(&snapshot);
                        uart_puts("CAM1 RELEASE MASK : ");
                        uart_puthex(snapshot.ready_mask);
                        if (cam1_dvp_release(snapshot.ready_mask, 100000u)) {
                            uart_puts(" RELEASED\n");
                        } else {
                            uart_puts(" RELEASE TIMEOUT\n");
                        }
                    }
                } else if (++quiet_polls >= 1000u) {
                    /* 无完成帧时也输出探活状态，避免有 PCLK 却无 VSYNC 时静默。 */
                    if (!error_signature_changed) {
                        print_snapshot(&snapshot);
                    }
                    quiet_polls = 0u;
                }
                cam1_delay_ms(1u);
            }
        } else {
            uart_puts("CAM1 CONFIG : FAILED\n");
            uart_puts("FAIL REG    : ");
            uart_puthex(config_result.failed_reg);
            uart_putc('\n');
            uart_puts("ERROR CODE  : ");
            uart_putdec((uint32_t)config_result.error);
            uart_putc('\n');
            uart_puts("EXPECTED    : ");
            uart_puthex(config_result.expected);
            uart_putc('\n');
            uart_puts("ACTUAL      : ");
            uart_puthex(config_result.actual);
            uart_putc('\n');
        }
    }

    for (;;) {
    }
}
