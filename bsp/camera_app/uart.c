#include "uart.h"

#define UART0_BASE       0x40000000u
#define UART_CTRL        (*(volatile uint32_t *)(UART0_BASE + 0x00u))
#define UART_STATUS      (*(volatile uint32_t *)(UART0_BASE + 0x04u))
#define UART_BAUD        (*(volatile uint32_t *)(UART0_BASE + 0x08u))
#define UART_TXDATA      (*(volatile uint32_t *)(UART0_BASE + 0x0cu))

#define FPIOA_BASE       0x40000f00u
#define FPIOA_OUT_MAP(n) (*(volatile uint8_t *)(FPIOA_BASE + (uint32_t)(n)))

#define FPIOA_FUNC_UART0_TX 7u
#define UART_CTRL_TX_ENABLE 0x1u
#define UART_STATUS_TX_BUSY 0x1u

extern uint32_t system_cpu_freq;

static void uart_putc_raw(char value)
{
    while ((UART_STATUS & UART_STATUS_TX_BUSY) != 0u) {
    }
    UART_TXDATA = (uint8_t)value;
}

void uart_init(uint32_t baud, uint8_t tx_fpioa)
{
    uint32_t clock_hz = system_cpu_freq;

    if ((baud == 0u) || (tx_fpioa >= 32u)) {
        return;
    }
    if (clock_hz == 0u) {
        clock_hz = 90000000u;
    }

    FPIOA_OUT_MAP(tx_fpioa) = FPIOA_FUNC_UART0_TX;
    UART_BAUD = (clock_hz / baud) - 1u;
    UART_CTRL = UART_CTRL_TX_ENABLE;
}

void uart_putc(char value)
{
    if (value == '\n') {
        uart_putc_raw('\r');
    }
    uart_putc_raw(value);
}

void uart_puts(const char *text)
{
    if (text == 0) {
        return;
    }
    while (*text != '\0') {
        uart_putc(*text++);
    }
}

void uart_puthex(uint32_t value)
{
    static const char digits[] = "0123456789ABCDEF";
    int shift;

    uart_puts("0x");
    for (shift = 28; shift >= 0; shift -= 4) {
        uart_putc(digits[(value >> (uint32_t)shift) & 0x0fu]);
    }
}

void uart_putdec(uint32_t value)
{
    char buffer[10];
    unsigned int count = 0u;

    if (value == 0u) {
        uart_putc('0');
        return;
    }

    while (value != 0u) {
        buffer[count++] = (char)('0' + (value % 10u));
        value /= 10u;
    }
    while (count != 0u) {
        uart_putc(buffer[--count]);
    }
}
