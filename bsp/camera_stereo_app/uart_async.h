#ifndef CAMERA_STEREO_UART_ASYNC_H
#define CAMERA_STEREO_UART_ASYNC_H

#include <stdint.h>

void uart_async_init(uint32_t baud, uint8_t tx_fpioa);
void log_putc(char value);
void log_puts(const char *text);
void log_puthex(uint32_t value);
void log_putdec(uint32_t value);
void uart_async_service(void);
uint32_t uart_async_dropped(void);
void uart_async_flush_blocking(void);

#endif
