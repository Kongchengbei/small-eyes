#include "sign_confirm.h"

struct sc_cam {
    uint32_t last;              /* 最后一张票的时刻 */
    uint32_t frame;             /* 最后一张票的帧号，用来去重 */
    uint16_t stamp[SC_VOTES];   /* 最近几张票时刻的低 16 位，环形 */
    uint8_t count;              /* stamp 里有效的票数 */
    uint8_t head;               /* 下一张票写入的位置 */
    uint8_t has_frame;
};

struct sc_cls {
    struct sc_cam cam[2];
    uint32_t t_sure;            /* 确定时刻 */
    uint32_t t_last;            /* 确定之后最后一张合格票的时刻 */
    uint8_t active;
};

static struct sc_cls g_cls[SC_CLASSES];
static struct sc_event g_q[SC_EVQ];
static uint8_t g_qhead, g_qcount;
static uint32_t g_lost;

uint32_t sc_lost(void)
{
    return g_lost;
}

void sc_init(void)
{
    uint32_t c, j, i;
    for (c = 0u; c < SC_CLASSES; ++c) {
        struct sc_cls *s = &g_cls[c];
        for (j = 0u; j < 2u; ++j) {
            struct sc_cam *k = &s->cam[j];
            k->last = 0u; k->frame = 0u; k->count = 0u; k->head = 0u; k->has_frame = 0u;
            for (i = 0u; i < SC_VOTES; ++i) k->stamp[i] = 0u;
        }
        s->t_sure = 0u; s->t_last = 0u; s->active = 0u;
    }
    g_qhead = 0u; g_qcount = 0u;
    g_lost = 0u;
}

static void sc_push(uint8_t type, uint32_t cls, uint32_t t, uint32_t held, uint32_t conf,
                    uint8_t cams, uint32_t n1, uint32_t n2)
{
    struct sc_event *e;
    if (g_qcount >= SC_EVQ) { ++g_lost; return; }
    e = &g_q[((uint32_t)g_qhead + g_qcount) % SC_EVQ];
    e->t = t; e->held = held; e->conf = conf;
    e->type = type; e->cls = (uint8_t)cls; e->cams = cams;
    e->n1 = (uint8_t)n1; e->n2 = (uint8_t)n2;
    ++g_qcount;
}

int sc_pop(struct sc_event *ev)
{
    const struct sc_event *e;
    if (g_qcount == 0u) return 0;
    e = &g_q[g_qhead];
    ev->t = e->t; ev->held = e->held; ev->conf = e->conf;
    ev->type = e->type; ev->cls = e->cls; ev->cams = e->cams;
    ev->n1 = e->n1; ev->n2 = e->n2;
    g_qhead = (uint8_t)(((uint32_t)g_qhead + 1u) % SC_EVQ);
    --g_qcount;
    return 1;
}

uint32_t sc_active_mask(void)
{
    uint32_t c, mask = 0u;
    for (c = 1u; c < SC_CLASSES; ++c)
        if (g_cls[c].active != 0u) mask |= 1u << c;
    return mask;
}

void sc_tick(uint32_t now_ms)
{
    for (;;) {
        uint32_t c, best = 0u, best_age = 0u, t;
        for (c = 1u; c < SC_CLASSES; ++c) {
            uint32_t age;
            if (g_cls[c].active == 0u) continue;
            age = now_ms - g_cls[c].t_last;
            if (age <= SC_H_MS) continue;
            /* 票龄越大事件越早；同龄取小类号（严格大于才换） */
            if (best == 0u || age > best_age) { best = c; best_age = age; }
        }
        if (best == 0u) return;
        t = g_cls[best].t_last + SC_H_MS + 1u;
        g_cls[best].active = 0u;
        sc_push(SC_EV_GONE, best, t, t - g_cls[best].t_sure, 0u, 0u, 0u, 0u);
    }
}

static int sc_size_ok(uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1)
{
    uint32_t w, h, l, s;
    if (x1 < x0 || y1 < y0) return 0;
    w = x1 - x0; h = y1 - y0;
    l = w > h ? w : h;
    s = w > h ? h : w;
    return l >= SC_MIN_LONG && s != 0u && l <= SC_MAX_AR * s;
}

/* 最后一张票距今超过 W 就一张都不算，这样 16 位低位戳不会因回绕混淆。 */
static uint32_t sc_count(const struct sc_cam *k, uint32_t now_ms)
{
    uint32_t i, n = 0u;
    if (k->count == 0u || now_ms - k->last > SC_W_MS) return 0u;
    for (i = 0u; i < k->count; ++i)
        if ((uint32_t)(uint16_t)(now_ms - k->stamp[i]) <= SC_W_MS) ++n;
    return n;
}

void sc_feed(uint32_t now_ms, uint32_t cam, uint32_t cls, uint32_t frame, uint32_t conf,
             uint32_t reject, uint32_t error, uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1)
{
    struct sc_cls *c;
    struct sc_cam *k;
    uint32_t n1, n2, kd, ks;

    sc_tick(now_ms);
    if (error != 0u || reject != 0u || cls < 1u || cls >= SC_CLASSES) return;
    if (cam < 1u || cam > 2u) return;
    if (!sc_size_ok(x0, y0, x1, y1)) return;

    c = &g_cls[cls];
    k = &c->cam[cam - 1u];
    if (k->has_frame != 0u && k->frame == frame) return;

    if (k->count != 0u && now_ms - k->last > SC_W_MS) { k->count = 0u; k->head = 0u; }
    k->stamp[k->head] = (uint16_t)now_ms;
    k->head = (uint8_t)(((uint32_t)k->head + 1u) % SC_VOTES);
    if (k->count < SC_VOTES) ++k->count;
    k->last = now_ms;
    k->frame = frame;
    k->has_frame = 1u;

    if (c->active != 0u) { c->t_last = now_ms; return; }

    n1 = sc_count(&c->cam[0], now_ms);
    n2 = sc_count(&c->cam[1], now_ms);
    if (cls >= 2u) { kd = SC_KD; ks = SC_KS; }
    else { kd = SC_KDO; ks = SC_KSO; }
    if (!((n1 >= 1u && n2 >= 1u && n1 + n2 >= kd) || n1 >= ks || n2 >= ks)) return;

    c->active = 1u;
    c->t_sure = now_ms;
    c->t_last = now_ms;
    sc_push(SC_EV_SURE, cls, now_ms, 0u, conf,
            (uint8_t)((n1 != 0u ? 1u : 0u) | (n2 != 0u ? 2u : 0u)), n1, n2);
}
