#include "uart.h"
#include "../include/soc_defs.h"

#include <stdint.h>

#define CAM1_CTRL       (*(volatile uint32_t *)(SOC_CAM1_MMIO_BASE + SOC_CAM_SCCB_CONTROL_OFFSET))
#define CAM1_STATUS     (*(volatile uint32_t *)(SOC_CAM1_MMIO_BASE + SOC_CAM_SCCB_STATUS_OFFSET))
#define HOLD_MS         500u
#define CONTROL_MASK    SOC_CAM_SCCB_CONTROL_MASK

extern uint32_t system_cpu_freq;

typedef struct {
    const char *name;
    uint32_t control;
    uint32_t expected_status;
} gpio_step_t;

static const gpio_step_t gpio_steps[] = {
    {"RELEASE", SOC_CAM_SCCB_SCL_RELEASE_MASK | SOC_CAM_SCCB_SDA_RELEASE_MASK,
     SOC_CAM_SCCB_STATUS_SCL_SYNC_MASK | SOC_CAM_SCCB_STATUS_SDA_SYNC_MASK |
     SOC_CAM_SCCB_STATUS_SCL_RELEASE_MASK | SOC_CAM_SCCB_STATUS_SDA_RELEASE_MASK},
    {"SCL_LOW", SOC_CAM_SCCB_SDA_RELEASE_MASK,
     SOC_CAM_SCCB_STATUS_SDA_SYNC_MASK | SOC_CAM_SCCB_STATUS_SDA_RELEASE_MASK},
    {"RELEASE", SOC_CAM_SCCB_SCL_RELEASE_MASK | SOC_CAM_SCCB_SDA_RELEASE_MASK,
     SOC_CAM_SCCB_STATUS_SCL_SYNC_MASK | SOC_CAM_SCCB_STATUS_SDA_SYNC_MASK |
     SOC_CAM_SCCB_STATUS_SCL_RELEASE_MASK | SOC_CAM_SCCB_STATUS_SDA_RELEASE_MASK},
    {"SDA_LOW", SOC_CAM_SCCB_SCL_RELEASE_MASK,
     SOC_CAM_SCCB_STATUS_SCL_SYNC_MASK | SOC_CAM_SCCB_STATUS_SCL_RELEASE_MASK},
};

/* 本项目把递增的 mtime 低 32 位放在 CSR 0xB03，不是标准 MMIO 定时器。
 * 项目 CSR_MCCTR（0xB88）复位值 bit2 为 1，因此 mtime 每个 CPU 周期递增。 */
static uint32_t read_mtime_low(void)
{
    uint32_t value;

    __asm__ volatile ("csrr %0, 0xB03" : "=r"(value));
    return value;
}

static uint32_t read_mcctr(void)
{
    uint32_t value;

    __asm__ volatile ("csrr %0, 0xB88" : "=r"(value));
    return value;
}

static void delay_cycles(uint32_t cycles)
{
    uint32_t start = read_mtime_low();

    while ((uint32_t)(read_mtime_low() - start) < cycles) {
    }
}

static uint32_t cpu_clock_hz(void)
{
    return system_cpu_freq != 0u ? system_cpu_freq : SOC_CPU_HZ;
}

static void delay_settle(void)
{
    uint32_t cycles = cpu_clock_hz() / 200000u; /* 约 5 微秒 */

    if (cycles == 0u) {
        cycles = 1u;
    }
    delay_cycles(cycles);
}

static void delay_hold(void)
{
    uint32_t hz = cpu_clock_hz();
    uint32_t cycles = (hz / 1000u) * HOLD_MS +
                      ((hz % 1000u) * HOLD_MS) / 1000u;

    delay_cycles(cycles);
}

static void print_step(const gpio_step_t *step)
{
    uint32_t control = CAM1_CTRL;
    uint32_t status = CAM1_STATUS;
    uint32_t match = ((control & CONTROL_MASK) == step->control) &&
                     ((status & CONTROL_MASK) == step->expected_status);

    uart_puts("STEP=");
    uart_puts(step->name);
    uart_puts(" CTRL=");
    uart_puthex(control);
    uart_puts(" STATUS=");
    uart_puthex(status);
    uart_puts(" RESET=");
    uart_putdec(control & 1u);
    uart_puts(" SCL=");
    uart_putdec((status >> 1) & 1u);
    uart_puts(" SDA=");
    uart_putdec((status >> 2) & 1u);
    uart_puts(" MATCH=");
    uart_puts(match ? "YES\n" : "NO\n");
}

int main(void)
{
    uint32_t index = 0u;
    uint32_t mtime_enabled;

    uart_init(115200u, CAMERA_UART_TX_FPIOA);
    CAM1_CTRL = 0x06u;
    mtime_enabled = read_mcctr() & 0x04u;

    uart_puts("=== CAM1 GPIO Toggle Test ===\n");
    uart_puts("HOLD MS     : 500\n");

    if (mtime_enabled == 0u) {
        uart_puts("TIMER ERROR : MTIME DISABLED\n");
        for (;;) {
            /* 保持复位和采集关闭，不使用未运行的计数器继续测试。 */
        }
    }

    for (;;) {
        const gpio_step_t *step = &gpio_steps[index];

        /* 仅写 CAM1 CONTROL 的四种既定值，reset 与 capture 始终为低。 */
        CAM1_CTRL = step->control;
        delay_settle();
        print_step(step);
        delay_hold();

        index++;
        if (index >= (uint32_t)(sizeof(gpio_steps) / sizeof(gpio_steps[0]))) {
            index = 0u;
        }
    }
}
