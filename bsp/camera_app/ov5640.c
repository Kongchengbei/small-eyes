#include "ov5640.h"

#include "camera_sccb.h"
#include "ov5640_regs.h"

#define OV5640_WRITE_RETRIES 3u

struct ov5640_verify_reg {
    uint16_t address;
    uint8_t expected;
    uint8_t mask;
};

static const struct ov5640_verify_reg verify_regs[] = {
    {0x3008u, 0x02u, 0x42u}, /* 已退出软件待机 */
    {0x300eu, 0x58u, 0xffu}, /* DVP 已使能 */
    {0x3035u, 0x21u, 0xffu},
    {0x3036u, 0x46u, 0xffu},
    {0x3808u, 0x02u, 0x0fu},
    {0x3809u, 0x80u, 0xffu},
    {0x380au, 0x01u, 0x07u},
    {0x380bu, 0xe0u, 0xffu},
    {0x4740u, 0x21u, 0x23u}, /* VSYNC/PCLK/HREF 极性 */
    {0x4300u, 0x61u, 0xffu}, /* 标准高字节在前的 RGB565 */
    {0x501fu, 0x01u, 0x07u}  /* ISP RGB 路径 */
};

static bool write_with_retry(uint16_t address, uint8_t value)
{
    uint32_t attempt;

    for (attempt = 0u; attempt < OV5640_WRITE_RETRIES; ++attempt) {
        if (cam1_ov5640_write_reg(address, value)) {
            return true;
        }
        cam1_delay_ms(1u);
    }
    return false;
}

static void clear_result(struct ov5640_config_result *result)
{
    result->error = OV5640_CONFIG_OK;
    result->failed_reg = 0u;
    result->expected = 0u;
    result->actual = 0u;
    result->writes_completed = 0u;
}

bool cam1_ov5640_configure_vga_rgb565(struct ov5640_config_result *result)
{
    uint32_t index;
    uint8_t actual;

    if (result == 0) {
        return false;
    }
    clear_result(result);

    /* 先切到外部 24 MHz 时钟，再执行软件复位并满足手册的 5 ms 延时。 */
    if (!write_with_retry(0x3103u, 0x11u)) {
        result->error = OV5640_CONFIG_WRITE_NACK;
        result->failed_reg = 0x3103u;
        return false;
    }
    ++result->writes_completed;
    if (!write_with_retry(0x3008u, 0x82u)) {
        result->error = OV5640_CONFIG_WRITE_NACK;
        result->failed_reg = 0x3008u;
        return false;
    }
    ++result->writes_completed;
    cam1_delay_ms(5u);

    for (index = 0u; index < ov5640_vga_rgb565_reg_count; ++index) {
        if (!write_with_retry(ov5640_vga_rgb565_regs[index].address,
                              ov5640_vga_rgb565_regs[index].value)) {
            result->error = OV5640_CONFIG_WRITE_NACK;
            result->failed_reg = ov5640_vga_rgb565_regs[index].address;
            result->expected = ov5640_vga_rgb565_regs[index].value;
            return false;
        }
        ++result->writes_completed;
    }

    /* ACK 只表示总线接收；关键模式寄存器还要读回核对。 */
    for (index = 0u; index < (uint32_t)(sizeof(verify_regs) /
                                        sizeof(verify_regs[0])); ++index) {
        if (!cam1_ov5640_read_reg(verify_regs[index].address, &actual)) {
            result->error = OV5640_CONFIG_READ_NACK;
            result->failed_reg = verify_regs[index].address;
            return false;
        }
        if ((actual & verify_regs[index].mask) !=
            (verify_regs[index].expected & verify_regs[index].mask)) {
            result->error = OV5640_CONFIG_VERIFY_MISMATCH;
            result->failed_reg = verify_regs[index].address;
            result->expected = verify_regs[index].expected;
            result->actual = actual;
            return false;
        }
    }

    return true;
}
