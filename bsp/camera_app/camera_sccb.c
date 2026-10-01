#include "camera_sccb.h"

#define CAM1_MMIO_BASE 0x40000300u
#define CAM1_CONTROL   (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x00u))
#define CAM1_STATUS    (*(volatile uint32_t *)(CAM1_MMIO_BASE + 0x04u))

#define CAM1_CTRL_RESET_N     (1u << 0)
#define CAM1_CTRL_SCL_RELEASE (1u << 1)
#define CAM1_CTRL_SDA_RELEASE (1u << 2)
#define CAM1_CTRL_CAPTURE_ENABLE (1u << 3)
#define CAM1_STATUS_SDA       (1u << 2)

#define OV5640_ADDR_WRITE 0x78u
#define OV5640_ADDR_READ  0x79u

static uint32_t cam1_control = CAM1_CTRL_SCL_RELEASE |
                               CAM1_CTRL_SDA_RELEASE;

static void cam1_write_control(void)
{
    CAM1_CONTROL = cam1_control;
}

/* 90 MHz 下产生保守的低速 SCCB 半周期，便于首次上板观察。 */
static void sccb_delay(void)
{
    volatile uint32_t count;

    for (count = 0u; count < 16u; ++count) {
        __asm__ volatile ("nop");
    }
}

void cam1_delay_ms(uint32_t milliseconds)
{
    uint32_t half_cycles;

    /* 半周期约数微秒；每毫秒留出较大裕量。 */
    for (half_cycles = 0u; half_cycles < milliseconds * 900u;
         ++half_cycles) {
        sccb_delay();
    }
}

static void set_scl(bool release)
{
    if (release) {
        cam1_control |= CAM1_CTRL_SCL_RELEASE;
    } else {
        cam1_control &= ~CAM1_CTRL_SCL_RELEASE;
    }
    cam1_write_control();
}

static void set_sda(bool release)
{
    if (release) {
        cam1_control |= CAM1_CTRL_SDA_RELEASE;
    } else {
        cam1_control &= ~CAM1_CTRL_SDA_RELEASE;
    }
    cam1_write_control();
}

static bool read_sda(void)
{
    return (CAM1_STATUS & CAM1_STATUS_SDA) != 0u;
}

static void sccb_start(void)
{
    set_sda(true);
    set_scl(true);
    sccb_delay();
    set_sda(false);
    sccb_delay();
    set_scl(false);
    sccb_delay();
}

static void sccb_stop(void)
{
    set_sda(false);
    sccb_delay();
    set_scl(true);
    sccb_delay();
    set_sda(true);
    sccb_delay();
}

static bool sccb_write_byte(uint8_t value)
{
    uint32_t bit_index;
    bool acknowledged;

    for (bit_index = 0u; bit_index < 8u; ++bit_index) {
        set_sda((value & 0x80u) != 0u);
        sccb_delay();
        set_scl(true);
        sccb_delay();
        set_scl(false);
        sccb_delay();
        value <<= 1;
    }

    /* 第九个时钟由从机拉低 SDA 表示应答。 */
    set_sda(true);
    sccb_delay();
    set_scl(true);
    sccb_delay();
    acknowledged = !read_sda();
    set_scl(false);
    sccb_delay();
    return acknowledged;
}

static uint8_t sccb_read_byte(bool acknowledge)
{
    uint32_t bit_index;
    uint8_t value = 0u;

    set_sda(true);
    for (bit_index = 0u; bit_index < 8u; ++bit_index) {
        value <<= 1;
        set_scl(true);
        sccb_delay();
        if (read_sda()) {
            value |= 1u;
        }
        set_scl(false);
        sccb_delay();
    }

    /* 单字节读结束时发送 NACK；保留 ACK 参数供后续连续读使用。 */
    set_sda(!acknowledge);
    sccb_delay();
    set_scl(true);
    sccb_delay();
    set_scl(false);
    set_sda(true);
    sccb_delay();
    return value;
}

void cam1_sccb_init(void)
{
    cam1_control = CAM1_CTRL_SCL_RELEASE | CAM1_CTRL_SDA_RELEASE;
    cam1_write_control();
    cam1_delay_ms(5u);

    cam1_control |= CAM1_CTRL_RESET_N;
    cam1_write_control();
    /* 旧板级例程在 RESETB 拉高后等待约 21 ms。 */
    cam1_delay_ms(22u);
}

bool cam1_ov5640_write_reg(uint16_t reg, uint8_t value)
{
    bool ok;

    sccb_start();
    ok = sccb_write_byte(OV5640_ADDR_WRITE);
    ok = sccb_write_byte((uint8_t)(reg >> 8)) && ok;
    ok = sccb_write_byte((uint8_t)reg) && ok;
    ok = sccb_write_byte(value) && ok;
    sccb_stop();
    return ok;
}

bool cam1_ov5640_read_reg(uint16_t reg, uint8_t *value)
{
    bool ok;

    if (value == 0) {
        return false;
    }

    sccb_start();
    ok = sccb_write_byte(OV5640_ADDR_WRITE);
    ok = sccb_write_byte((uint8_t)(reg >> 8)) && ok;
    ok = sccb_write_byte((uint8_t)reg) && ok;

    sccb_start();
    ok = sccb_write_byte(OV5640_ADDR_READ) && ok;
    *value = sccb_read_byte(false);
    sccb_stop();
    return ok;
}

void cam1_capture_enable(bool enable)
{
    if (enable) {
        cam1_control |= CAM1_CTRL_CAPTURE_ENABLE;
    } else {
        cam1_control &= ~CAM1_CTRL_CAPTURE_ENABLE;
    }
    cam1_write_control();
}
