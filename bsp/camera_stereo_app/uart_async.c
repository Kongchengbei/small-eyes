#include "uart_async.h"

#define UART0_BASE 0x40000000u
#define UART_STATUS (*(volatile uint32_t *)(UART0_BASE + 0x04u))
#define UART_BAUD (*(volatile uint32_t *)(UART0_BASE + 0x08u))
#define UART_TXDATA (*(volatile uint32_t *)(UART0_BASE + 0x0cu))
#define UART_CTRL (*(volatile uint32_t *)(UART0_BASE + 0x00u))
#define FPIOA_MAP(n) (*(volatile uint8_t *)(0x40000f00u + (uint32_t)(n)))
#define UART_BUSY 1u
#define LOG_CAPACITY 2048u

extern uint32_t system_cpu_freq;
static char log_ring[LOG_CAPACITY];
static volatile uint32_t log_head;
static volatile uint32_t log_tail;
static volatile uint32_t log_dropped;

void uart_async_init(uint32_t baud, uint8_t tx_fpioa)
{
    uint32_t clock = system_cpu_freq != 0u ? system_cpu_freq : 70000000u;
    FPIOA_MAP(0u) = 0u;
    FPIOA_MAP(31u) = 0u;
    if (baud == 0u || tx_fpioa >= 32u) return;
    FPIOA_MAP(tx_fpioa) = 7u;
    UART_BAUD = clock / baud - 1u;
    UART_CTRL = 1u;
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
