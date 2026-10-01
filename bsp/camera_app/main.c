#include <stdint.h>

#include "camera_sccb.h"
#include "camera_dvp.h"
#include "ov5640.h"
#include "uart.h"

extern uint32_t system_cpu_freq;

int main(void)
{
    uint8_t pidh = 0u;
    uint8_t pidl = 0u;
    bool pidh_ack;
    bool pidl_ack;
    bool detected;
    struct ov5640_config_result config_result;
    struct cam1_dvp_snapshot dvp_snapshot;

    uart_init(115200u, CAMERA_UART_TX_FPIOA);

    uart_puts("=== Small Eyes Camera Bring-up ===\n\n");
    uart_puts("UART TEST OK\n");

    /* The CPU is released from reset only after the boot loader has written
     * the image to DDR and read every word back successfully. */
    uart_puts("DDR INIT OK\n");
    uart_puts("CPU CLOCK   : ");
    uart_putdec(system_cpu_freq);
    uart_puts(" Hz\n");
    uart_puts("UART MMIO   : ");
    uart_puthex(0x40000000u);
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
            uart_puts("CAM1 START  : OK\n");
            cam1_capture_enable(true);
            if (cam1_dvp_wait_first_frame(&dvp_snapshot, 200u)) {
                uart_puts("CAM1 STATUS : ");
                uart_puthex(dvp_snapshot.status);
                uart_putc('\n');
                uart_puts("CAM1 FRAMES : ");
                uart_putdec(dvp_snapshot.frame_count);
                uart_putc('\n');
                uart_puts("CAM1 PIXELS : ");
                uart_putdec(dvp_snapshot.last_frame_pixels);
                uart_putc('\n');
                uart_puts("CAM1 LINES  : ");
                uart_putdec(dvp_snapshot.last_frame_lines);
                uart_putc('\n');
                uart_puts("CAM1 ERRORS : ");
                uart_puthex(dvp_snapshot.error_flags);
                uart_putc('\n');
            } else {
                uart_puts("CAM1 FRAME  : TIMEOUT\n");
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
