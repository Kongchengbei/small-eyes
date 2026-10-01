#ifndef CAMERA_APP_UART_H
#define CAMERA_APP_UART_H

#include <stdint.h>

/* UART0 is routed to one FPIOA pin.  The current board project constrains
 * FPIOA[31] to AB26, which is the already verified serial TX connection. */
#define CAMERA_UART_TX_FPIOA 31u

void uart_init(uint32_t baud, uint8_t tx_fpioa);
void uart_putc(char value);
void uart_puts(const char *text);
void uart_puthex(uint32_t value);
void uart_putdec(uint32_t value);

#endif
