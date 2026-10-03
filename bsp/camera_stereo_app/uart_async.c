#include "uart_async.h"
#include "../include/soc_defs.h"

#define UART_STATUS (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_STATUS_OFFSET))
#define UART_BAUD (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_BAUD_OFFSET))
#define UART_TXDATA (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_TXDATA_OFFSET))
#define UART_CTRL (*(volatile uint32_t *)(SOC_UART0_BASE + SOC_UART_CTRL_OFFSET))
#define FPIOA_MAP(n) (*(volatile uint8_t *)(SOC_FPIOA_BASE + (uint32_t)(n)))
#define UART_BUSY SOC_UART_STATUS_TX_BUSY
#define LOG_CAPACITY 2048u

extern uint32_t system_cpu_freq;
static char log_ring[LOG_CAPACITY];
static volatile uint32_t log_head;
static volatile uint32_t log_tail;
static volatile uint32_t log_dropped;

void uart_async_init(uint32_t baud, uint8_t tx_fpioa)
{
    uint32_t clock = system_cpu_freq != 0u ? system_cpu_freq : SOC_CPU_HZ;
    FPIOA_MAP(SOC_UART_TX_FPIOA) = 0u;
    FPIOA_MAP(31u) = 0u;
    if (baud == 0u || tx_fpioa >= 32u) return;
    FPIOA_MAP(tx_fpioa) = SOC_UART_TX_FPIOA_FUNC;
    UART_BAUD = clock / baud - 1u;
    UART_CTRL = SOC_UART_CTRL_TX_ENABLE;
}

void log_putc(char value)
{
    uint32_t next;
    if (value == '\n') log_putc('\r');
    next = (log_head + 1u) % LOG_CAPACITY;
    if (next == log_tail) {
        ++log_dropped;
        return;
    }
    log_ring[log_head] = value;
    log_head = next;
}

void log_puts(const char *text)
{
    if (text == 0) return;
    while (*text != '\0') log_putc(*text++);
}

void log_puthex(uint32_t value)
{
    static const char digits[] = "0123456789ABCDEF";
    int shift;
    log_puts("0x");
    for (shift = 28; shift >= 0; shift -= 4)
        log_putc(digits[(value >> (uint32_t)shift) & 15u]);
}

void log_putdec(uint32_t value)
{
    char digits[10];
    uint32_t count = 0u;
    if (value == 0u) { log_putc('0'); return; }
    while (value != 0u) { digits[count++] = (char)('0' + value % 10u); value /= 10u; }
    while (count != 0u) log_putc(digits[--count]);
}

void uart_async_service(void)
{
    if (log_tail != log_head && (UART_STATUS & UART_BUSY) == 0u) {
        UART_TXDATA = (uint8_t)log_ring[log_tail];
        log_tail = (log_tail + 1u) % LOG_CAPACITY;
    }
}

uint32_t uart_async_dropped(void) { return log_dropped; }

void uart_async_flush_blocking(void)
{
    while (log_tail != log_head) {
        if ((UART_STATUS & UART_BUSY) == 0u) {
            UART_TXDATA = (uint8_t)log_ring[log_tail];
            log_tail = (log_tail + 1u) % LOG_CAPACITY;
        }
    }
    while ((UART_STATUS & UART_BUSY) != 0u) { }
}
