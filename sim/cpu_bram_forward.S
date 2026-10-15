    .option norvc
    .option norelax
    .include "bsp/include/soc_defs_asm.inc"
    .section .text
    .globl _start
_start:
    li      x27, 0
    li      x3, 1
    li      s0, 0x80008000
    li      t0, 0x80ff7f01
    sw      t0, 0(s0)
    li      t0, 37
    sw      t0, 4(s0)
    sw      zero, 8(s0)

    # Younger EX load must override an older MEM writer of the same register.
    li      t1, 99
    lw      t1, 4(s0)
    addi    t2, t1, 5
    li      t3, 42
    bne     t2, t3, fail

    # Exercise rs2 and both source operands, followed by EX-to-ID forwarding.
    li      t0, 5
    lw      t1, 4(s0)
    add     t2, t0, t1
    addi    t4, t2, 1
    li      t3, 43
    bne     t4, t3, fail
    lw      t1, 4(s0)
    add     t2, t1, t1
    li      t3, 74
    bne     t2, t3, fail

    li      x3, 2
    lb      t1, 3(s0)
    addi    t2, t1, 1
    li      t3, -127
    bne     t2, t3, fail
    lbu     t1, 3(s0)
    addi    t2, t1, 1
    li      t3, 129
    bne     t2, t3, fail
    lh      t1, 2(s0)
    addi    t2, t1, 1
    li      t3, -32512
    bne     t2, t3, fail
    lhu     t1, 2(s0)
    addi    t2, t1, 1
    li      t3, 33024
    bne     t2, t3, fail
    lw      zero, 4(s0)
    addi    t2, zero, 9
    li      t3, 9
    bne     t2, t3, fail

    # ID branches must still wait; stores must consume the correct load value.
    li      x3, 3
    li      t3, 37
    lw      t1, 4(s0)
    bne     t1, t3, fail
    lw      t1, 4(s0)
    sw      t1, 12(s0)
    lw      t1, 12(s0)
    addi    t2, t1, 5
    li      t3, 42
    bne     t2, t3, fail

    # A delayed MMIO load may enter MEM while its ALU consumer waits in EX.
    li      x3, 4
    li      t0, SOC_CAM1_MMIO_BASE
    lw      t1, 0(t0)
    addi    t2, t1, 1
    li      t3, 7
    bne     t2, t3, fail
    addi    t4, t2, 2
    li      t3, 9
    bne     t4, t3, fail

    # Independent and chained DIV/REM instructions, including ISA corner cases.
    li      x3, 5
    li      t0, 32
    li      t1, 5
    div     t2, t0, t1
    addi    t3, t2, 1
    li      t4, 7
    bne     t3, t4, fail
    rem     t2, t0, t1
    li      t4, 2
    bne     t2, t4, fail
    divu    t2, t0, t1
    remu    t3, t0, t1
    add     t4, t2, t3
    li      t5, 8
    bne     t4, t5, fail
    li      t0, -32
    div     t2, t0, t1
    li      t4, -6
    bne     t2, t4, fail
    rem     t2, t0, t1
    li      t4, -2
    bne     t2, t4, fail
    div     t2, t0, zero
    li      t4, -1
    bne     t2, t4, fail
    rem     t2, t0, zero
    bne     t2, t0, fail
    li      t0, 0x80000000
    li      t1, -1
    div     t2, t0, t1
    bne     t2, t0, fail
    rem     t2, t0, t1
    bnez    t2, fail

    # Alternating targets repeatedly redirect the same JALR instruction.
    # Wrong-path stores must never execute, even if a new target fetch is issued.
    li      x3, 6
    li      s1, 24
    li      s2, 0
    li      s3, 0
redirect_loop:
    xori    s2, s2, 1
    beqz    s2, select_b
    la      t0, target_a
    j       invoke
select_b:
    la      t0, target_b
invoke:
    jalr    ra, 0(t0)
    add     s3, s3, a0
    addi    s1, s1, -1
    bnez    s1, redirect_loop
    li      t0, 36
    bne     s3, t0, fail
    lw      t0, 8(s0)
    bnez    t0, fail

    # Repeated load-use pairs make the before/after cycle saving observable.
    li      x3, 7
    li      s1, 128
    li      s2, 0
load_loop:
    lw      t1, 4(s0)
    add     s2, s2, t1
    addi    s1, s1, -1
    bnez    s1, load_loop
    li      t0, 4736
    bne     s2, t0, fail

    # Forward word, byte and halfword store data from an adjacent load.
    li      x3, 8
    lw      t1, 0(s0)
    sw      t1, 12(s0)
    lw      t2, 12(s0)
    li      t3, 0x80ff7f01
    bne     t2, t3, fail
    lb      t1, 3(s0)
    sb      t1, 14(s0)
    lw      t2, 12(s0)
    li      t3, 0x80807f01
    bne     t2, t3, fail
    lhu     t1, 2(s0)
    sh      t1, 12(s0)
    lw      t2, 12(s0)
    li      t3, 0x808080ff
    bne     t2, t3, fail

    # Forward a load result used as a second memory operation's address.
    li      x3, 9
    addi    t0, s0, 24
    sw      t0, 20(s0)
    li      t2, 0x13579bdf
    lw      t1, 20(s0)
    sw      t2, 0(t1)
    lw      t1, 20(s0)
    lw      t3, 0(t1)
    bne     t3, t2, fail
    lw      t1, 20(s0)
    sw      t1, 0(t1)
    lw      t3, 24(s0)
    bne     t3, t0, fail

    # Delay MUL/DIV launch until pending operands arrive, then retain them
    # while the multi-cycle unit holds EX after the producer has left MEM.
    li      x3, 10
    li      t1, 99
    lw      t1, 4(s0)
    mul     t2, t1, t1
    li      t3, 1369
    bne     t2, t3, fail
    li      t0, 5
    lw      t1, 4(s0)
    mul     t2, t0, t1
    li      t3, 185
    bne     t2, t3, fail
    lw      t1, 4(s0)
    div     t2, t1, t0
    li      t3, 7
    bne     t2, t3, fail
    li      t0, 100
    lw      t1, 4(s0)
    remu    t2, t0, t1
    li      t3, 26
    bne     t2, t3, fail
    lw      t1, 4(s0)
    divu    t2, t1, t1
    li      t3, 1
    bne     t2, t3, fail
    li      t0, SOC_CAM1_MMIO_BASE
    li      t3, 3
    li      t1, 99
    lw      t1, 0(t0)
    mul     t2, t1, t3
    li      t4, 18
    bne     t2, t4, fail
    lw      t1, 0(t0)
    div     t2, t1, t3
    li      t4, 2
    bne     t2, t4, fail

    # A valid load result must survive a busy MMIO write channel.
    li      x3, 11
    li      t2, 6
    sw      t2, 28(s0)
    li      t1, 99
    sw      t2, 0(t0)
    lw      t1, 28(s0)
    sw      t1, 0(t0)
    lw      t3, 0(t0)
    bne     t3, t2, fail

    # CSR register sources consume the resolved EX operand; immediate CSR
    # sources retain their instruction-immediate semantics.
    li      x3, 12
    csrw    mscratch, zero
    lw      t1, 4(s0)
    csrrw   t2, mscratch, t1
    bnez    t2, fail
    csrr    t2, mscratch
    li      t3, 37
    bne     t2, t3, fail
    li      t0, 64
    sw      t0, 32(s0)
    lw      t1, 32(s0)
    csrrs   t2, mscratch, t1
    bne     t2, t3, fail
    li      t3, 101
    csrr    t2, mscratch
    bne     t2, t3, fail
    li      t0, 1
    sw      t0, 32(s0)
    lw      t1, 32(s0)
    csrrc   t2, mscratch, t1
    bne     t2, t3, fail
    li      t3, 100
    csrr    t2, mscratch
    bne     t2, t3, fail
    lw      t0, 4(s0)
    csrrwi  t2, mscratch, 5
    bne     t2, t3, fail
    csrr    t2, mscratch
    li      t3, 5
    bne     t2, t3, fail

    # Repeated load-to-store pairs measure the newly removed ID bubble.
    li      x3, 13
    li      s1, 128
copy_loop:
    lw      t1, 4(s0)
    sw      t1, 36(s0)
    addi    s1, s1, -1
    bnez    s1, copy_loop
    lw      t2, 36(s0)
    li      t3, 37
    bne     t2, t3, fail

    li      x3, 0
    li      x27, 1
pass:
    jal     zero, pass

target_a:
    li      a0, 1
    ret
    sw      a0, 8(s0)
target_b:
    li      a0, 2
    ret
    sw      a0, 8(s0)

fail:
    li      x27, 0
    jal     zero, pass
