OUTPUT_ARCH("riscv")
ENTRY(_start)

__stack_size = 4K;
MEMORY
{
    iram (rx) : ORIGIN = 0x80000000, LENGTH = 32K
    sram (rw) : ORIGIN = 0x80008000, LENGTH = 16K
}
SECTIONS
{
    .init : { KEEP(*(SORT_NONE(.init))) } > iram
    .text :
    {
        *(.text.unlikely .text.unlikely.*)
        *(.text.startup .text.startup.*)
        *(.text .text.*) *(.gnu.linkonce.t.*)
        *(.rodata .rodata.*) *(.srodata .srodata.*) *(.gnu.linkonce.r.*)
        . = ALIGN(4); PROVIDE(_etext = .);
    } > iram
    .data :
    {
        . = ALIGN(4); PROVIDE(_data = .); PROVIDE(__global_pointer$ = . + 0x800);
        *(.data .data.*) *(.sdata .sdata.*) *(.gnu.linkonce.d.*) *(.gnu.linkonce.s.*)
        . = ALIGN(4); PROVIDE(_edata = .);
    } > sram AT> iram
    PROVIDE(_data_lma = LOADADDR(.data));
    .bss (NOLOAD) :
    {
        . = ALIGN(4); PROVIDE(__bss_start = .); *(.sbss .sbss.*) *(.bss .bss.*) *(COMMON)
        . = ALIGN(4); PROVIDE(_end = .);
    } > sram
    ASSERT(_end <= ORIGIN(sram) + LENGTH(sram) - __stack_size,
           "camera_stereo data/bss overlaps stack")
    .stack ORIGIN(sram) + LENGTH(sram) - __stack_size (NOLOAD) :
    { PROVIDE(_heap_end = .); . = . + __stack_size; PROVIDE(_sp = .); } > sram
}
