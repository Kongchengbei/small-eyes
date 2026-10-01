#ifndef CAMERA_APP_SCCB_H
#define CAMERA_APP_SCCB_H

#include <stdbool.h>
#include <stdint.h>

/* 释放物理 CAM1 复位，并等待 OV5640 满足上电时序。 */
void cam1_sccb_init(void);

/* 使用当前 90 MHz CPU 的保守忙等待；用于 OV5640 复位和模式切换。 */
void cam1_delay_ms(uint32_t milliseconds);

/* 写入 OV5640 的 16 位寄存器地址；返回 false 表示任一字节未应答。 */
bool cam1_ov5640_write_reg(uint16_t reg, uint8_t value);

/* 读取 OV5640 的 16 位寄存器地址；返回 false 表示任一字节未应答。 */
bool cam1_ov5640_read_reg(uint16_t reg, uint8_t *value);

/* 打开或关闭 DVP 接收；不会改变 RESETB 和 SCCB 开漏状态。 */
void cam1_capture_enable(bool enable);

#endif
