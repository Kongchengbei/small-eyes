#include "uart.h"
#include "../include/soc_defs.h"

#define UART_CTRL        (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_CTRL_OFFSET))
#define UART_STATUS      (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_STATUS_OFFSET))
#define UART_BAUD        (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_BAUD_OFFSET))
#define UART_TXDATA      (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_TXDATA_OFFSET))

#define FPIOA_OUT_MAP(n) (*(volatile uint8_t *)(SOC_FPIOA_BASE + (uint32_t)(n)))

#define FPIOA_UART_LOCAL_TX SOC_UART_TX_FPIOA
#define FPIOA_UART_REMOTE_TX 31u
#define FPIOA_FUNC_UART0_TX SOC_UART_TX_FPIOA_FUNC
#define UART_CTRL_TX_ENABLE SOC_UART_CTRL_TX_ENABLE
#define UART_STATUS_TX_BUSY SOC_UART_STATUS_TX_BUSY

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

    /* 先关闭本地与远程候选脚，避免旧位流在另一脚继续输出。 */
    FPIOA_OUT_MAP(FPIOA_UART_LOCAL_TX) = 0u;
    FPIOA_OUT_MAP(FPIOA_UART_REMOTE_TX) = 0u;

    if ((baud == 0u) || (tx_fpioa >= 32u)) {
        return;
    }
    if (clock_hz == 0u) {
        clock_hz = SOC_CPU_HZ;
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
