    .option norvc
    .section .text
    .globl _start
_start:
    /* GPIO 控制寄存器复位值为 6。先写哨兵值，确认后续 sw 真正覆盖。 */
    li t0, 0x40000300
    li t1, 0x80008040
    li t2, 0x13579bdf
    sw t2, 0(t1)

    /* MMIO lw 的结果直接作为下一条 sw 的数据。 */
    lw t3, 0(t0)
    sw t3, 0(t1)
    lw t4, 0(t1)
    li t5, 6
    bne t4, t5, fail

    /* 再覆盖一次，防止只在首次 cache miss 时偶然通过。 */
    li t2, 0x2468ace0
    sw t2, 4(t1)
    lw t3, 0(t0)
    sw t3, 4(t1)
    lw t4, 4(t1)
    bne t4, t5, fail

    /* store 数据走 byte/halfword 格式化时也必须使用新加载值。 */
    li t2, -1
    sw t2, 8(t1)
    lw t3, 0(t0)
    sb t3, 8(t1)
    lw t4, 8(t1)
    li t5, -250
    bne t4, t5, fail

    sw t2, 12(t1)
    lw t3, 0(t0)
    sh t3, 12(t1)
    lw t4, 12(t1)
    li t5, -65530
    bne t4, t5, fail

    /* 普通 DDR load 的结果紧接着用于 store 地址。 */
    li t1, 0x80008100
    li t2, 0x80008200
    sw t2, 0(t1)
    li t3, 0x55aa33cc
    lw t4, 0(t1)
    sw t3, 0(t4)
    lw t5, 0(t2)
    bne t5, t3, fail

    li x27, 1
pass:
    jal x0, pass

fail:
    li x27, 0
    li x3, 1
    jal x0, pass
