/*
 * 曝光扫参固件，只在 NPU_SWEEP=1/2 时编进镜像（见 Makefile）。
 * 1：按时间表给两路摄像头轮流套用预设 P0..P7、P0B，每 SWEEP_PATCH_MS 每路打一行 @@@ PATCH
 *    （画面中心 64x64 的像素统计加寄存器读回）。
 * 2：只走展示时间表（PLAN/SWAP/SHOW/DONE），不读也不写任何寄存器、不取快照，这些代码在该模式下不编进去。
 * @@@ 行都在 uart_async_free()>=160 时才打，不够留到下一圈、不丢；寄存器写读失败只记 @@@ REGFAIL，不停机。
 */
#include <stdint.h>
#include "sweep.h"
#include "camera_stereo.h"
#include "uart_async.h"
#include "../include/soc_defs.h"

#if NPU_SWEEP != 1 && NPU_SWEEP != 2
#error "sweep.c needs NPU_SWEEP=1 or 2"
#endif
#ifndef SWEEP_SWAP_MS
#define SWEEP_SWAP_MS 10000u
#endif
#ifndef SWEEP_IMAGES
#define SWEEP_IMAGES 4u
#endif
#if SWEEP_IMAGES < 1 || SWEEP_IMAGES > 4
#error "SWEEP_IMAGES must be 1..4"
#endif
#if NPU_SWEEP == 1
#ifndef SWEEP_SEG_MS
#define SWEEP_SEG_MS 20000u
#endif
#ifndef SWEEP_SETTLE_MS
#define SWEEP_SETTLE_MS 5000u
#endif
#ifndef SWEEP_PATCH_MS
#define SWEEP_PATCH_MS 5000u
#endif
#ifndef SWEEP_CAM2_FIXED
#define SWEEP_CAM2_FIXED 0
#endif
#if SWEEP_PATCH_MS < 1
#error "SWEEP_PATCH_MS must be >= 1"
#endif
#else
#ifndef SWEEP_BLANK_MS
#define SWEEP_BLANK_MS 120000u
#endif
#ifndef SWEEP_SHOW_MS
#define SWEEP_SHOW_MS 60000u
#endif
#endif

#ifndef SWEEP_MTIME
static uint32_t sweep_mtime(void) { uint32_t v; __asm__ volatile("csrr %0, 0xB03" : "=r"(v)); return v; }
#define SWEEP_MTIME() sweep_mtime()
#endif
#if NPU_SWEEP == 1
#ifndef SWEEP_MEM
#define SWEEP_MEM(a) ((const volatile uint32_t *)(uintptr_t)(a))
#endif
#ifndef SWEEP_FENCE
#define SWEEP_FENCE() __asm__ volatile("fence iorw, iorw" ::: "memory")
#endif
#endif

#define CYC_PER_MS (SOC_CPU_HZ / 1000u)
#define PRINT_MIN 160u

#if NPU_SWEEP == 1
#define NGRP 9u
#define BLK_MS ((uint32_t)SWEEP_SWAP_MS + NGRP * (uint32_t)SWEEP_SEG_MS)
#else
#define BLK_MS ((uint32_t)SWEEP_SWAP_MS + (uint32_t)SWEEP_SHOW_MS)
#endif

#if NPU_SWEEP == 1
struct sw_cam {
    struct camera_ctx *c;
    uint8_t act;
    uint8_t cur[6];                 /* AE 六个寄存器现值（3A0F 3A10 3A11 3A1B 3A1E 3A1F） */
    uint8_t bv[5];                  /* 开机读到的 0x5580 0x5583 0x5584 0x5588 0x3406 */
    uint8_t uv_dirty, awb_dirty, awb_ok;
    uint16_t awb[3];                /* 自动 AWB 增益 R G B，P6/P7 共用 */
};
static struct sw_cam sc[2];
static uint16_t fq[64];
static uint8_t fq_n, fq_o;
#endif

static uint32_t t_last, t_frac, t_ms;
static uint32_t st, blk;
#if NPU_SWEEP == 1
static uint32_t grp, smp;
#endif

static uint32_t can_print(void) { return uart_async_free() >= PRINT_MIN; }
static void put_kv(const char *name, uint32_t v) { log_puts(name); log_putdec(v); }

#if NPU_SWEEP == 1
static void fail(uint16_t reg) { if (fq_n < 64u) fq[fq_n++] = reg; }

static uint8_t rd1(struct sw_cam *s, uint16_t reg, uint8_t dflt)
{
    uint8_t v = 0u;
    if (!cam_read_reg(s->c, reg, &v)) { fail(reg); return dflt; }
    return v;
}

/* 连续 n 个寄存器按大端拼成一个数。 */
static uint32_t rd_seq(struct sw_cam *s, uint16_t reg, uint32_t n)
{
    uint32_t v = 0u, i;
    for (i = 0u; i < n; ++i) v = (v << 8) | rd1(s, (uint16_t)(reg + i), 0u);
    return v;
}

/* 连读两次，不一致再读第三次取最后一次，防跨帧读花。 */
static uint32_t rd_twice(struct sw_cam *s, uint16_t reg, uint32_t n)
{
    uint32_t a = rd_seq(s, reg, n), b = rd_seq(s, reg, n);
    return a == b ? b : rd_seq(s, reg, n);
}

/* 读 0x519F–A4 的三个 12 位 AWB 增益 R、G、B；六次读都成功返回 1。 */
static uint32_t awb_read(struct sw_cam *s, uint32_t *g)
{
    uint8_t v[6];
    uint32_t i, ok = 1u;
    for (i = 0u; i < 6u; ++i) {
        v[i] = 0u;
        if (!cam_read_reg(s->c, (uint16_t)(0x519Fu + i), &v[i])) { fail((uint16_t)(0x519Fu + i)); v[i] = 0u; ok = 0u; }
    }
    for (i = 0u; i < 3u; ++i) g[i] = ((uint32_t)(v[2u * i] & 0x0Fu) << 8) | v[2u * i + 1u];
    return ok;
}

static void hx(uint32_t v, uint32_t n)
{
    while (n-- != 0u) { uint32_t d = (v >> (n * 4u)) & 15u; log_putc((char)(d < 10u ? '0' + d : 'A' + d - 10u)); }
}
static void put_grp(uint32_t g)
{
    log_putc('P');
    if (g < 8u) log_putc((char)('0' + g)); else log_puts("0B");
}

/* ---------- 中心 64x64 像素统计 ---------- */
/* v[0..2] 三通道和，v[3] blue40，v[4] blue30，v[5] red，v[6] yel，v[7] clip，v[8] dark */
static void px(uint32_t p, uint32_t *v)
{
    uint32_t r = ((p >> 8) & 0xF8u) | ((p >> 13) & 7u);
    uint32_t g = ((p >> 3) & 0xFCu) | ((p >> 9) & 3u);
    uint32_t b = ((p << 3) & 0xF8u) | ((p >> 2) & 7u);
    v[0] += r; v[1] += g; v[2] += b;
    if (2u * r <= b && 8u * g <= 5u * b) {
        if (b >= 0x40u) ++v[3];
        if (b >= 0x30u) ++v[4];
    } else if (r >= 0x40u) {
        if (8u * g <= 5u * r && 8u * b <= 5u * r) ++v[5];
        else if (g >= 0x40u && r >= b + 0x40u && g >= b + 0x40u) ++v[6];
    }
    if (r >= 0xF8u || g >= 0xF8u || b >= 0xF8u) ++v[7];
    if (r < 0x20u && g < 0x20u && b < 0x20u) ++v[8];
}

static void stats(uint32_t base, uint32_t *v)
{
    const volatile uint32_t *p = SWEEP_MEM(base + 208u * 1280u + 576u);
    uint32_t y, x, w;
    SWEEP_FENCE();
    for (y = 0u; y < 64u; ++y, p += 320u)
        for (x = 0u; x < 32u; ++x) { w = p[x]; px(w & 0xFFFFu, v); px(w >> 16, v); }
}

static void patch(struct sw_cam *s, uint32_t g)
{
    struct cam_snapshot sn;
    uint32_t v[9] = {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};
    uint32_t aw[3], ex, ga, avg, uv, i;
    if (cam_snapshot(s->c, &sn, 20000u) && sn.complete_buffer <= 1u && sn.pixels == 307200u)
        stats(sn.complete_buffer == 0u ? s->c->buffer0 : s->c->buffer1, v);
    ex = rd_twice(s, 0x3500u, 3u);
    ga = rd_twice(s, 0x350Au, 2u);
    avg = rd1(s, 0x56A1u, 0u);
    uv = rd1(s, 0x558Cu, 0u);
    awb_read(s, aw);
    log_puts("@@@ PATCH ");
    log_putdec(s->c->id); log_putc(' '); put_grp(g); log_putc(' '); log_putdec(blk + 1u);
    for (i = 0u; i < 9u; ++i) { log_putc(' '); log_putdec(i < 3u ? v[i] >> 12 : v[i]); }
    log_putc(' '); hx(ex, 6u); log_putc(' '); hx(ga, 4u); log_putc(' '); hx(avg, 2u); log_putc(' '); hx(uv, 2u);
    for (i = 0u; i < 3u; ++i) { log_putc(' '); hx(aw[i], 3u); }
    log_putc('\n');
}

/* ---------- 预设与寄存器写入 ---------- */
static const uint16_t ae_reg[6] = {0x3A0Fu, 0x3A10u, 0x3A11u, 0x3A1Bu, 0x3A1Eu, 0x3A1Fu};
static const uint8_t ae_tab[5][6] = {
    {0x40u, 0x38u, 0x71u, 0x40u, 0x38u, 0x10u},   /* P0 T60 */
    {0x50u, 0x48u, 0x90u, 0x50u, 0x48u, 0x20u},   /* P1 T76 */
    {0x78u, 0x68u, 0xD0u, 0x78u, 0x68u, 0x40u},   /* P2 T112 */
    {0x30u, 0x28u, 0x60u, 0x30u, 0x26u, 0x14u},   /* P3 T44 */
    {0x20u, 0x18u, 0x41u, 0x20u, 0x18u, 0x10u},   /* P4 T28 */
};
/* 组 0..8 = P0..P7、P0B：用哪一行 AE 表、是否 UV 固定、是否 AWB 手动 */
static const uint8_t grp_ae[NGRP] = {0u, 1u, 2u, 3u, 4u, 0u, 0u, 1u, 0u};
static const uint8_t grp_fl[NGRP] = {0u, 0u, 0u, 0u, 0u, 1u, 2u, 3u, 0u};
#define F_UV 1u
#define F_AWB 2u

/* 写 reg 再读回，只比 mask 里的位；写、读失败或读回不符都只记一条 REGFAIL。返回读回值，读不到就返回写入值。 */
static uint8_t wr_chk(struct sw_cam *s, uint16_t reg, uint8_t val, uint8_t mask)
{
    uint8_t rb = val;
    uint32_t bad = cam_write_reg(s->c, reg, val) ? 0u : 1u;
    if (!cam_read_reg(s->c, reg, &rb)) { bad = 1u; rb = val; }
    else if (((rb ^ val) & mask) != 0u) bad = 1u;
    if (bad != 0u) fail(reg);
    return rb;
}

static void ae_w(struct sw_cam *s, const uint8_t *v, uint32_t i) { s->cur[i] = wr_chk(s, ae_reg[i], v[i], 0xFFu); }

/* 写序：3A0F>3A10、3A1B>3A1E 任何时刻成立。新值比现值高先写 3A0F、3A1B 再写 3A10、3A1E，低则反过来，3A11、3A1F 最后。 */
static void ae_set(struct sw_cam *s, const uint8_t *v)
{
    uint32_t up = 0u, p;
    for (p = 0u; p < 2u; ++p) if (v[3u * p] >= s->cur[3u * p]) up |= 1u << p;
    for (p = 0u; p < 2u; ++p) if (((up >> p) & 1u) != 0u) ae_w(s, v, 3u * p);
    for (p = 0u; p < 2u; ++p) if (((up >> p) & 1u) == 0u) ae_w(s, v, 3u * p + 1u);
    for (p = 0u; p < 2u; ++p) if (((up >> p) & 1u) != 0u) ae_w(s, v, 3u * p + 1u);
    for (p = 0u; p < 2u; ++p) if (((up >> p) & 1u) == 0u) ae_w(s, v, 3u * p);
    ae_w(s, v, 2u);
    ae_w(s, v, 5u);
}

static void uv_fix(struct sw_cam *s)
{
    s->uv_dirty = 1u;
    if ((s->bv[0] & 2u) == 0u) wr_chk(s, 0x5580u, (uint8_t)(s->bv[0] | 2u), 0xFFu);
    wr_chk(s, 0x5583u, 0x40u, 0xFFu);
    wr_chk(s, 0x5584u, 0x40u, 0xFFu);
    wr_chk(s, 0x5588u, (uint8_t)(rd1(s, 0x5588u, s->bv[3]) | 0x40u), 0xFFu);
}

static void gain_w(struct sw_cam *s, uint16_t reg, uint32_t g)
{
    wr_chk(s, reg, (uint8_t)(g >> 8), 0x0Fu);
    wr_chk(s, (uint16_t)(reg + 1u), (uint8_t)g, 0xFFu);
}

static void awb_manual(struct sw_cam *s)
{
    s->awb_dirty = 1u;
    gain_w(s, 0x3400u, s->awb[0]);
    gain_w(s, 0x3402u, (uint32_t)s->awb[1] * 17u / 20u);
    gain_w(s, 0x3404u, s->awb[2]);
    wr_chk(s, 0x3406u, (uint8_t)(rd1(s, 0x3406u, s->bv[4]) | 1u), 0xFFu);
}

/* 先恢复 P0（AE 回 P0，UV、AWB 手动按脏标记写回开机值），再套本组改动，中间不等待。 */
static void apply_cam(struct sw_cam *s, uint32_t g)
{
    ae_set(s, ae_tab[0]);
    if (s->uv_dirty != 0u) {
        wr_chk(s, 0x5580u, s->bv[0], 0xFFu);
        wr_chk(s, 0x5583u, s->bv[1], 0xFFu);
        wr_chk(s, 0x5584u, s->bv[2], 0xFFu);
        wr_chk(s, 0x5588u, s->bv[3], 0xFFu);
        s->uv_dirty = 0u;
    }
    if (s->awb_dirty != 0u) { wr_chk(s, 0x3406u, s->bv[4], 0xFFu); s->awb_dirty = 0u; }
    if (grp_ae[g] != 0u) ae_set(s, ae_tab[grp_ae[g]]);
    if ((grp_fl[g] & F_UV) != 0u) uv_fix(s);
    if ((grp_fl[g] & F_AWB) != 0u) awb_manual(s);
}

/* 开机值：读失败就记 REGFAIL 并用手册/配置表里的默认值顶上。 */
static void boot_read(struct sw_cam *s)
{
    static const uint8_t bdef[5] = {0x06u, 0x40u, 0x10u, 0x01u, 0x00u};
    static const uint16_t breg[5] = {0x5580u, 0x5583u, 0x5584u, 0x5588u, 0x3406u};
    uint32_t i;
    for (i = 0u; i < 6u; ++i) s->cur[i] = rd1(s, ae_reg[i], ae_tab[0][i]);
    for (i = 0u; i < 5u; ++i) s->bv[i] = rd1(s, breg[i], bdef[i]);
}

/* P6/P7 套用前取自动 AWB 增益：没动过 AWB 就现读，已手动（P7 紧跟 P6）就沿用缓存，免得 ×0.85 叠两次。 */
static uint32_t awb_ready(struct sw_cam *s)
{
    uint32_t g[3];
    if (s->awb_dirty == 0u) {
        s->awb_ok = (uint8_t)(awb_read(s, g) && g[0] != 0u && g[1] != 0u && g[2] != 0u);
        s->awb[0] = (uint16_t)g[0]; s->awb[1] = (uint16_t)g[1]; s->awb[2] = (uint16_t)g[2];
    }
    return s->awb_ok;
}

static uint32_t rw(uint32_t i) { return sc[i].act != 0u && !(i == 1u && SWEEP_CAM2_FIXED != 0); }
#endif

/* ---------- 时间表 ---------- */
enum { S_PLAN, S_SWAP, S_SHOW,
#if NPU_SWEEP == 1
       S_PRESET, S_PRECHK, S_APPLY1, S_APPLY2, S_PATCH1, S_PATCH2, S_FIN1, S_FIN2,
#endif
       S_DONE, S_END };

static const char *const img_name[4] = {"TURN_LEFT", "KEEP_RIGHT", "SPEED_LIMIT_40", "BLANK"};

#if NPU_SWEEP == 1
static uint32_t grp_t(void) { return blk * BLK_MS + (uint32_t)SWEEP_SWAP_MS + grp * (uint32_t)SWEEP_SEG_MS; }
#endif

static uint32_t end_ms(void)
{
#if NPU_SWEEP == 1
    return (uint32_t)SWEEP_IMAGES * BLK_MS;
#else
    return ((uint32_t)SWEEP_IMAGES - 1u) * BLK_MS + (uint32_t)SWEEP_SWAP_MS
           + (SWEEP_IMAGES == 4u ? (uint32_t)SWEEP_BLANK_MS : (uint32_t)SWEEP_SHOW_MS);
#endif
}

static uint32_t due(void)
{
    switch (st) {
    case S_PLAN: return 0u;
    case S_SWAP: return blk * BLK_MS;
    case S_SHOW: return blk * BLK_MS + (uint32_t)SWEEP_SWAP_MS;
#if NPU_SWEEP == 1
    case S_PRESET: case S_PRECHK: case S_APPLY1: case S_APPLY2: return grp_t();
    case S_PATCH1: case S_PATCH2: return grp_t() + (uint32_t)SWEEP_SETTLE_MS + smp * (uint32_t)SWEEP_PATCH_MS;
#endif
    default: return end_ms();
    }
}

/* 套用和收尾几步不打印，不用等串口队列有空。 */
static uint32_t prints(void)
{
#if NPU_SWEEP == 1
    if (st == S_APPLY1 || st == S_APPLY2 || st == S_FIN1 || st == S_FIN2) return 0u;
#endif
    return 1u;
}

#if NPU_SWEEP == 1
static void next_grp(void)
{
    smp = 0u;
    if (++grp < NGRP) { st = S_PRESET; return; }
    grp = 0u;
    if (++blk < (uint32_t)SWEEP_IMAGES) { st = S_SWAP; return; }
    st = S_FIN1;
}

/* 进入第 smp 次 PATCH；本段放不下就换组。 */
static void to_patch(void)
{
    if ((uint32_t)SWEEP_SETTLE_MS + smp * (uint32_t)SWEEP_PATCH_MS < (uint32_t)SWEEP_SEG_MS) st = S_PATCH1;
    else next_grp();
}
#endif

static void print_plan(void)
{
    put_kv("@@@ PLAN mode=", NPU_SWEEP);
    put_kv(" images=", SWEEP_IMAGES);
#if NPU_SWEEP == 1
    put_kv(" seg=", SWEEP_SEG_MS);
    put_kv(" settle=", SWEEP_SETTLE_MS);
    put_kv(" patch=", SWEEP_PATCH_MS);
    put_kv(" swap=", SWEEP_SWAP_MS);
    put_kv(" cam2fixed=", SWEEP_CAM2_FIXED != 0);
#else
    put_kv(" show=", SWEEP_SHOW_MS);
    put_kv(" blank=", SWEEP_BLANK_MS);
    put_kv(" swap=", SWEEP_SWAP_MS);
#endif
    log_putc('\n');
}

static void run(void)
{
    switch (st) {
    case S_PLAN:
        print_plan(); st = S_SWAP; break;
    case S_SWAP:
        put_kv("@@@ SWAP ", blk + 1u); log_putc(' '); log_puts(img_name[blk]); log_putc('\n');
        st = S_SHOW; break;
    case S_SHOW:
        put_kv("@@@ SHOW ", blk + 1u); log_putc('\n');
#if NPU_SWEEP == 1
        grp = 0u; smp = 0u;
        st = S_PRESET;
#else
        st = ++blk < (uint32_t)SWEEP_IMAGES ? S_SWAP : S_DONE;
#endif
        break;
#if NPU_SWEEP == 1
    case S_PRESET:
        log_puts("@@@ PRESET "); put_grp(grp); log_putc('\n');
        st = (grp == 6u || grp == 7u) ? S_PRECHK : S_APPLY1; break;
    case S_PRECHK: {
        uint32_t bad = 0u, i;
        for (i = 0u; i < 2u; ++i) if (rw(i) && !awb_ready(&sc[i])) bad = 1u;
        if (bad != 0u) { log_puts("@@@ SKIP "); put_grp(grp); log_putc('\n'); next_grp(); }
        else st = S_APPLY1;
        break;
    }
    case S_APPLY1:
        if (rw(0u)) apply_cam(&sc[0], grp);
        st = S_APPLY2; break;
    case S_APPLY2:
        if (rw(1u)) apply_cam(&sc[1], grp);
        smp = 0u; to_patch(); break;
    case S_PATCH1:
        if (sc[0].act != 0u) patch(&sc[0], grp);
        st = S_PATCH2; break;
    case S_PATCH2:
        if (sc[1].act != 0u) patch(&sc[1], grp);
        ++smp; to_patch(); break;
    case S_FIN1:
        if (rw(0u)) apply_cam(&sc[0], 0u);
        st = S_FIN2; break;
    case S_FIN2:
        if (rw(1u)) apply_cam(&sc[1], 0u);
        st = S_DONE; break;
#endif
    case S_DONE:
        log_puts("@@@ DONE\n"); st = S_END; break;
    default:
        break;
    }
}

void sweep_init(struct camera_ctx *cam1, struct camera_ctx *cam2, uint32_t on1, uint32_t on2)
{
#if NPU_SWEEP == 1
    sc[0].c = cam1; sc[1].c = cam2;
    sc[0].act = on1 != 0u; sc[1].act = on2 != 0u;
    if (rw(0u)) boot_read(&sc[0]);
    if (rw(1u)) boot_read(&sc[1]);
    grp = 0u; smp = 0u;
#else
    (void)cam1; (void)cam2; (void)on1; (void)on2;
#endif
    st = S_PLAN; blk = 0u;
    t_ms = 0u; t_frac = 0u; t_last = SWEEP_MTIME();
}

void sweep_step(void)
{
    uint32_t t = SWEEP_MTIME(), d = (t - t_last) + t_frac;
    t_last = t; t_ms += d / CYC_PER_MS; t_frac = d % CYC_PER_MS;
#if NPU_SWEEP == 1
    if (fq_o < fq_n && can_print()) {
        log_puts("@@@ REGFAIL "); hx(fq[fq_o++], 4u); log_putc('\n');
        if (fq_o == fq_n) fq_o = fq_n = 0u;
        return;
    }
#endif
    if (st == S_END || t_ms < due()) return;
    if (prints() != 0u && !can_print()) return;
    run();
}
