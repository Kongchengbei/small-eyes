#include <stdint.h>
#include "camera_stereo.h"
#include "uart_async.h"
#include "../camera_app/ov5640.h"
#include "../include/soc_defs.h"

#define FRAME_WIDTH 640u
#define FRAME_HEIGHT 480u
#define FRAME_STRIDE (FRAME_WIDTH * 2u)
#define FRAME_BYTES (FRAME_STRIDE * FRAME_HEIGHT)
#define CPU_HZ SOC_CPU_HZ
#define CAM_ERROR_STATUS_MASK SOC_CAM_STATUS_ERROR_MASK
#define DMA_STATUS_ENABLE 0x1u
#define DMA_STATUS_BUSY 0x2u

extern uint32_t system_cpu_freq;

#define UART_STATUS (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_STATUS_OFFSET))
#define UART_TXDATA (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_TXDATA_OFFSET))
#define UART_BUSY SOC_UART_STATUS_TX_BUSY

static uint32_t read_mtime(void)
{
    uint32_t value;
    __asm__ volatile("csrr %0, 0xB03" : "=r"(value));
    return value;
}

static uint32_t read_mcctr(void)
{
    uint32_t value;
    __asm__ volatile("csrr %0, 0xB88" : "=r"(value));
    return value;
}

static void write_mcctr(uint32_t value)
{
    __asm__ volatile("csrw 0xB88, %0" :: "r"(value));
}

static void put_le16(uint8_t *dst, uint16_t value)
{
    dst[0] = (uint8_t)value;
    dst[1] = (uint8_t)(value >> 8);
}

static void put_le32(uint8_t *dst, uint32_t value)
{
    dst[0] = (uint8_t)value;
    dst[1] = (uint8_t)(value >> 8);
    dst[2] = (uint8_t)(value >> 16);
    dst[3] = (uint8_t)(value >> 24);
}

static uint32_t crc32_ieee(const volatile uint8_t *data, uint32_t length)
{
    uint32_t crc = 0xffffffffu;
    uint32_t i;
    for (i = 0u; i < length; ++i) {
        uint32_t bit;
        crc ^= data[i];
        for (bit = 0u; bit < 8u; ++bit)
            crc = (crc >> 1) ^ ((crc & 1u) ? 0xedb88320u : 0u);
    }
    return crc ^ 0xffffffffu;
}

static void raw_put(uint8_t value)
{
    while ((UART_STATUS & UART_BUSY) != 0u) { }
    UART_TXDATA = value;
}

static void raw_write(const uint8_t *data, uint32_t length)
{
    uint32_t i;
    for (i = 0u; i < length; ++i) raw_put(data[i]);
}

static void raw_flush(void)
{
    while ((UART_STATUS & UART_BUSY) != 0u) { }
}

static void report_error(uint32_t code)
{
    log_puts("DUMP_ERROR code=");
    log_putdec(code);
    log_putc('\n');
    uart_async_flush_blocking();
}

static uint32_t wait_frame(struct camera_ctx *cam, struct cam_snapshot *snap)
{
    uint32_t start = read_mtime();
    uint32_t limit = CPU_HZ * 20u;
    for (;;) {
        if (cam_snapshot(cam, snap, 20000u) &&
            snap->frame_count != 0u && snap->ready_mask != 0u)
            return 1u;
        if ((uint32_t)(read_mtime() - start) >= limit) return 0u;
    }
}

static uint32_t stop_camera_and_drain(struct camera_ctx *cam,
                                      struct cam_snapshot *snap)
{
    uint32_t start, timeout = CPU_HZ * 3u;
    cam_capture_enable(cam, false);
    cam_dma_enable(cam, false);
    start = read_mtime();
    for (;;) {
        if (cam_snapshot(cam, snap, 20000u) &&
            (snap->dma_status & (DMA_STATUS_ENABLE | DMA_STATUS_BUSY)) == 0u)
            break;
        if ((uint32_t)(read_mtime() - start) >= timeout) return 0u;
    }
    /* Let the disable CDC and any pending async-FIFO response settle. */
    start = read_mtime();
    while ((uint32_t)(read_mtime() - start) < (CPU_HZ / 1000u)) { }
    __asm__ volatile("fence iorw, iorw" ::: "memory");
    return 1u;
}

static uint32_t validate_snapshot(const struct camera_ctx *cam,
                                  const struct cam_snapshot *snap,
                                  uint32_t *slot_mask)
{
    uint32_t slot, expected;
    if (snap->complete_buffer > 1u || snap->pixels != FRAME_WIDTH * FRAME_HEIGHT ||
        snap->bytes != FRAME_BYTES || snap->lines != FRAME_HEIGHT ||
        (snap->status & CAM_ERROR_STATUS_MASK) != 0u || snap->fifo_error != 0u ||
        snap->dvp_flags != 0u || snap->error_flags != 0u || snap->dma_code != 0u)
        return 0u;
    slot = 1u << snap->complete_buffer;
    expected = snap->complete_buffer == 0u ? cam->buffer0 : cam->buffer1;
    if ((snap->ready_mask & slot) == 0u || snap->frame_addr != expected ||
        (snap->frame_addr & 31u) != 0u || snap->frame_addr < SOC_DDR_BASE ||
        (uint64_t)snap->frame_addr + FRAME_BYTES > SOC_DDR_END)
        return 0u;
    *slot_mask = slot;
    return 1u;
}

int main(void)
{
    struct camera_ctx cam;
    struct cam_snapshot snap, stopped;
    uint8_t header[44] = {0};
    uint8_t footer[12] = {0};
    uint32_t pin = STEREO_UART_TX_FPIOA;
    uint32_t slot_mask, checksum, i;
    const volatile uint8_t *frame;
    uint16_t failed_reg = 0u;
    uint32_t writes = 0u;

    uart_async_init(115200u, (uint8_t)pin);
    log_puts("CAMERA_FRAME_DUMP BOOT\n");
    log_puts("UART=115200 TX_FPIOA="); log_putdec(pin); log_putc('\n');

    cam_init(&cam, SOC_CAM1_MMIO_BASE, SOC_CAM1_BUFFER0_BASE,
             SOC_CAM1_BUFFER1_BASE, 1u);
    cam_sccb_init(&cam);
    {
        uint8_t idh = 0u, idl = 0u;
        if (!cam_read_reg(&cam, 0x300au, &idh) || !cam_read_reg(&cam, 0x300bu, &idl) ||
            idh != 0x56u || idl != 0x40u) {
            report_error(1u); return 1;
        }
    }
    if (!cam_configure_vga(&cam, &failed_reg, &writes)) {
        log_puts("CAM1_CONFIG_FAILED reg="); log_puthex(failed_reg);
        log_puts(" writes="); log_putdec(writes); log_putc('\n');
        uart_async_flush_blocking();
        report_error(2u); return 2;
    }
    log_puts("CAM1_CONFIG_OK VGA_RGB565\n");
    uart_async_flush_blocking();

    write_mcctr(read_mcctr() | (1u << 2));
    cam_dma_enable(&cam, true);
    cam_capture_enable(&cam, true);
    if (!wait_frame(&cam, &snap)) {
        cam_capture_enable(&cam, false); cam_dma_enable(&cam, false);
        report_error(3u); return 3;
    }
    if (!validate_snapshot(&cam, &snap, &slot_mask)) {
        cam_capture_enable(&cam, false); cam_dma_enable(&cam, false);
        report_error(4u); return 4;
    }
    if (!stop_camera_and_drain(&cam, &stopped)) {
        report_error(5u); return 5;
    }
    if (!cam_snapshot(&cam, &stopped, 20000u) ||
        (stopped.ready_mask & slot_mask) == 0u ||
        stopped.frame_addr != snap.frame_addr || stopped.frame_count < snap.frame_count ||
        (stopped.status & CAM_ERROR_STATUS_MASK) != 0u || stopped.fifo_error != 0u ||
        stopped.dvp_flags != 0u || stopped.error_flags != 0u || stopped.dma_code != 0u) {
        report_error(6u); return 6;
    }
    if ((stopped.dma_status & (DMA_STATUS_ENABLE | DMA_STATUS_BUSY)) != 0u) {
        report_error(7u); return 7;
    }

    frame = (const volatile uint8_t *)(uintptr_t)snap.frame_addr;
    __asm__ volatile("fence iorw, iorw" ::: "memory");
    checksum = crc32_ieee(frame, FRAME_BYTES);

    /* Build the fixed 44-byte little-endian binary descriptor. */
    header[0]='R'; header[1]='5'; header[2]='6'; header[3]='5';
    header[4]='D'; header[5]='M'; header[6]='P'; header[7]='1';
    put_le16(&header[8], 1u); put_le16(&header[10], sizeof(header));
    header[12] = 1u; /* CAM1 */
    header[13] = 1u; /* RGB565 little-endian */
    put_le16(&header[14], 1u); /* CRC32 present */
    put_le32(&header[16], snap.frame_count);
    put_le32(&header[20], snap.frame_addr);
    put_le16(&header[24], FRAME_WIDTH); put_le16(&header[26], FRAME_HEIGHT);
    put_le32(&header[28], FRAME_STRIDE); put_le32(&header[32], FRAME_BYTES);
    put_le32(&header[36], checksum); put_le32(&header[40], 0u);
    footer[0]='E'; footer[1]='N'; footer[2]='D'; footer[3]='5';
    footer[4]='6'; footer[5]='5'; footer[6]='D'; footer[7]='1';
    put_le32(&footer[8], checksum);

    log_puts("DUMP_READY\n");
    uart_async_flush_blocking();
    raw_write(header, sizeof(header));
    for (i = 0u; i < FRAME_BYTES; ++i) raw_put(frame[i]);
    raw_write(footer, sizeof(footer));
    raw_flush();

    /* The single owned camera slot is returned only after the complete wire frame. */
    if (!cam_release(&cam, slot_mask)) {
        /* Stream already contains a valid CRC/footer; host can retain the image. */
        return 8;
    }
    return 0;
}
