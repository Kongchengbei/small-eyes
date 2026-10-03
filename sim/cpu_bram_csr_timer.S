    .option norvc
    .include "bsp/include/soc_defs_asm.inc"
    .section .text
    .globl _start
_start:
    /* Use DRAM as a sentinel so the test also exercises local SRAM accesses. */
    li      t0, SOC_DRAM_BASE
    sw      zero, 0(t0)

    la      t0, timer_trap
    csrw    mtvec, t0

    /* Program a future compare, then enable MTIE and global MIE. */
    csrw    0xB84, zero
    li      t0, 5000
    csrw    0xB04, t0
    li      t0, 0x80
    csrw    mie, t0
    li      t0, 8
    csrs    mstatus, t0

    li      s0, 0
wait_for_timer:
    addi    s0, s0, 1
    li      t0, SOC_DRAM_BASE
    lw      t1, 0(t0)
    beqz    t1, wait_for_timer
    li      x27, 1
pass:
    jal     zero, pass

timer_trap:
    csrr    t0, mcause
    li      t1, 0x80000007
    bne     t0, t1, fail

    /* Move mtimecmp forward before mret so the timer does not retrap. */
    csrr    t0, 0xB03
    li      t1, 10000
    add     t0, t0, t1
    csrw    0xB04, t0
    li      t0, SOC_DRAM_BASE
    li      t1, 1
    sw      t1, 0(t0)
    mret

fail:
    li      x27, 0
    li      x3, 1
    jal     zero, pass
