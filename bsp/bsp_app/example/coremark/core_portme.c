#include "coremark.h"
#include "system.h"
#include "../../../include/soc_defs.h"

#if VALIDATION_RUN
	volatile ee_s32 seed1_volatile=0x3415;
	volatile ee_s32 seed2_volatile=0x3415;
	volatile ee_s32 seed3_volatile=0x66;
#endif

#if PERFORMANCE_RUN
	volatile ee_s32 seed1_volatile=0x0;
	volatile ee_s32 seed2_volatile=0x0;
	volatile ee_s32 seed3_volatile=0x66;
#endif

#if PROFILE_RUN
	volatile ee_s32 seed1_volatile=0x8;
	volatile ee_s32 seed2_volatile=0x8;
	volatile ee_s32 seed3_volatile=0x8;
#endif

volatile ee_s32 seed4_volatile=ITERATIONS;
volatile ee_s32 seed5_volatile=0;

static CORE_TICKS t0, t1;

static CORE_TICKS board_ticks(void)
{
    uint32_t hi, lo, next_hi;
    do {
        hi = read_csr(mtimeh);
        lo = read_csr(mtime);
        next_hi = read_csr(mtimeh);
    } while (hi != next_hi);
    return ((CORE_TICKS)hi << 32) | lo;
}

void start_time(void)
{
  t0 = board_ticks();
}

void stop_time(void)
{
  t1 = board_ticks();
}

CORE_TICKS get_time(void)
{
  return t1 - t0;
}

secs_ret time_in_secs(CORE_TICKS ticks)
{
  return (double)ticks / (double)system_cpu_freq;
}
void portable_init(core_portable *p, int *argc, char *argv[])
{
    (void)argc;
    (void)argv;
    if (system_cpu_freq == 0u) {
        system_cpu_freq = SOC_CPU_HZ;
        system_cpu_freqM = SOC_CPU_HZ / 1000000u;
    }
    /* Huart_tx counts divider + 1 clocks per bit. */
    SYS_RWMEM_B(FPIOA_OT_BASE + 0u) = 0u;
    SYS_RWMEM_B(FPIOA_OT_BASE + 31u) = 0u;
    SYS_RWMEM_B(FPIOA_OT_BASE + COREMARK_UART_TX_FPIOA) = UART0_TX;
    SYS_RWMEM_W(UART_BAUD(UART0)) = system_cpu_freq / 115200u - 1u;
    SYS_RWMEM_W(UART_CTRL(UART0)) = 1u;
    set_csr(mcctr, 4u);
    *p = 1;
    ee_printf("Start CoreMark CPU=%lu Hz UART=115200 TX_FPIOA=%u\r\n",
              (unsigned long)system_cpu_freq, (unsigned)COREMARK_UART_TX_FPIOA);
    if (sizeof(ee_ptr_int) != sizeof(void *) || sizeof(ee_u32) != 4u) {
        ee_printf("ERROR: CoreMark data type configuration\r\n");
    }
}
