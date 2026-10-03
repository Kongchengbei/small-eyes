#ifndef CAMERA_APP_UART_H
#define CAMERA_APP_UART_H

#include <stdint.h>
#include "../include/soc_defs.h"

/* 默认使用本地串口 FPIOA[0]（C24）；可用编译参数 -D 覆盖。 */
#ifndef CAMERA_UART_TX_FPIOA
#define CAMERA_UART_TX_FPIOA SOC_UART_TX_FPIOA
#endif

void uart_init(uint32_t baud, uint8_t tx_fpioa);
void uart_putc(char value);
void uart_puts(const char *text);
void uart_puthex(uint32_t value);
void uart_putdec(uint32_t value);

#endif
