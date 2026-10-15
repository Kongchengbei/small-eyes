/* CPU instruction regression for the Cache/ID timing changes.
 * Run in the existing tb_Htop, DDR/Cache profile. No new testbench is needed.
 * The three callees and four data regions deliberately share Cache indices
 * while using different Tags. A wrong-path store makes flush errors visible.
 * The harness checks x27 at the terminal jal; x3 identifies a failing phase.
 */
.option norvc
.option norelax
.section .text
.globl _start
_start:
    li x27, 0
    li x3, 1
    li s0, 0x80008000
    li s1, 0x80009000
    li s2, 0x8000a000
    li s3, 0x8000b000
    li s4, 0
    li s5, 16

/* Repeated dirty replacements and load-to-branch/ALU forwarding. */
data_round:
    li t0, 0x12345678
    add t0, t0, s4
    sw t0, 0(s0)
    li t1, 0x23456789
    add t1, t1, s4
    sw t1, 0(s1)
    li t2, 0x3456789a
    add t2, t2, s4
    sw t2, 0(s2)
    li t3, 0x456789ab
    add t3, t3, s4
    sw t3, 0(s3)
    lw t4, 0(s0)
    bne t4, t0, fail
    lw t4, 0(s1)
    bne t4, t1, fail
    lw t4, 0(s2)
    bne t4, t2, fail
    lw t4, 0(s3)
    bne t4, t3, fail
    lw t4, 0(s0)
    add t5, t4, t1
    add t6, t0, t1
    bne t5, t6, fail
    addi s4, s4, 1
    blt s4, s5, data_round

/* Load width, byte masks, and signed/unsigned extension. */
    li x3, 2
    li t0, 0x80ff7f01
    sw t0, 16(s0)
    lb t1, 19(s0)
    li t2, -128
    bne t1, t2, fail
    lbu t1, 18(s0)
    li t2, 255
    bne t1, t2, fail
    lh t1, 18(s0)
    li t2, -32513
    bne t1, t2, fail
    lhu t1, 18(s0)
    li t2, 0x80ff
    bne t1, t2, fail
    li t1, 0x55
    sb t1, 17(s0)
    li t1, 0x1234
    sh t1, 18(s0)
    lw t1, 16(s0)
    li t2, 0x12345501
    bne t1, t2, fail

/* One JALR site sees changing load-forwarded targets, stressing BTB recovery
 * and instruction Cache conflicts. Targets include bit 0 set (JALR clears it).
 */
    li x3, 3
    la t0, callee_a
    ori t0, t0, 1
    sw t0, 32(s0)
    la t0, callee_b
    ori t0, t0, 1
    sw t0, 36(s0)
    la t0, callee_c
    ori t0, t0, 1
    sw t0, 40(s0)
    sw zero, 44(s0)
    li s4, 0
    li s5, 12
    li s6, 0
    li s7, 0
call_round:
    addi t0, s0, 32
    add t0, t0, s6
    lw t1, 0(t0)
    jalr ra, 0(t1)
    add s7, s7, a0
    addi s6, s6, 4
    li t0, 12
    bltu s6, t0, call_continue
    li s6, 0
call_continue:
    addi s4, s4, 1
    blt s4, s5, call_round
    li t0, 24
    bne s7, t0, fail
    lw t0, 44(s0)
    bne t0, zero, fail

/* Forwarding must select the youngest write to the same register. */
    li x3, 4
    li t0, 10
    li t0, 20
    addi t1, t0, 1
    li t2, 21
    bne t1, t2, fail
    sw t2, 48(s0)
    li t0, 99
    lw t0, 48(s0)
    addi t1, t0, 1
    li t2, 22
    bne t1, t2, fail
    lw zero, 48(s0)
    addi t1, zero, 7
    li t2, 7
    bne t1, t2, fail

    li x27, 1
    li x26, 1
pass:
    jal zero, pass
fail:
    li x27, 0
    li x26, 0
fail_stop:
    jal zero, fail_stop

/* Keep the offsets fixed so calls contend for the same ICache sets. */
.org 0x4000
callee_a:
    li a0, 1
    jalr zero, 0(ra)
    li t0, 1
    sw t0, 44(s0)
.org 0x5000
callee_b:
    li a0, 2
    jalr zero, 0(ra)
    li t0, 1
    sw t0, 44(s0)
.org 0x6000
callee_c:
    li a0, 3
    jalr zero, 0(ra)
    li t0, 1
    sw t0, 44(s0)
