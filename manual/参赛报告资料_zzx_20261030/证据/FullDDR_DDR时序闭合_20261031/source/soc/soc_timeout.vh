`ifndef SOC_TIMEOUT_VH
`define SOC_TIMEOUT_VH
`include "../soc/soc_addr_map.vh"

// CPU-domain error-detection deadlines only. Preserve the original 70 MHz
// wall-time budgets, rounding up by less than one CPU cycle. These constants
// are elaborated at build time: no runtime divider or mandatory delay.
// Do NOT use them for SPI/SCCB rate limiting or DDR-domain DMA timeouts.
`define SOC_BOOT_TIMEOUT_CYCLES ((`SOC_CPU_HZ + 32'd699) / 32'd700)
`define SOC_CAM_SNAPSHOT_TIMEOUT_CYCLES ((`SOC_CPU_HZ + 32'd69) / 32'd70)
`define SOC_DDR_INIT_TIMEOUT_CYCLES `SOC_CPU_HZ

`endif
