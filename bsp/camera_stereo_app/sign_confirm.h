#ifndef CAMERA_STEREO_SIGN_CONFIRM_H
#define CAMERA_STEREO_SIGN_CONFIRM_H

#include <stdint.h>

/*
 * 连续几次一致才确认。判定顺序：资格 -> 尺寸门 -> 去重 -> 记票 -> 确定；
 * 不再来票超过 SC_H_MS 就报消失。回放脚本、固件、验收三方共用这一套规则。
 * 时间是 32 位毫秒钟，允许回绕；调用方保证 now_ms 单调不减。
 */

#ifndef SC_W_MS
#define SC_W_MS 1500u   /* 计票窗口：[now-W, now] 内的票，含边界 */
#endif
#ifndef SC_H_MS
#define SC_H_MS 2500u   /* 最后一张合格票之后超过这么久，报消失 */
#endif
#ifndef SC_KD
#define SC_KD 2u        /* 已知路标，两路都有票时的总票数门槛 */
#endif
#ifndef SC_KS
#define SC_KS 3u        /* 已知路标，单路票数门槛 */
#endif
#ifndef SC_KDO
#define SC_KDO 3u       /* 其他路标，两路都有票时的总票数门槛 */
#endif
#ifndef SC_KSO
#define SC_KSO 4u       /* 其他路标，单路票数门槛 */
#endif
#ifndef SC_MIN_LONG
#define SC_MIN_LONG 40u /* 框长边下限，用打印坐标，不加 1 */
#endif
#ifndef SC_MAX_AR
#define SC_MAX_AR 2u    /* 长边不超过这个倍数的短边，短边为 0 不过 */
#endif
#ifndef SC_CLASSES
#define SC_CLASSES 11u  /* 类别总数，须与 main_npu.c 的 CLASS_COUNT 一致 */
#endif
#ifndef SC_EVQ
#define SC_EVQ 8u       /* 事件队列深度 */
#endif

#define SC_VOTES 4u     /* 每（类，路）记住最近几张票 */

/* 16 位毫秒戳只在票龄小于 65536 ms 时才不混淆；最老的票至多比"现在"早 SC_VOTES*SC_W_MS。 */
#if SC_W_MS < 1 || SC_W_MS * SC_VOTES > 65535
#error "SC_W_MS must be 1..16383"
#endif
#if SC_KS < 1 || SC_KS > SC_VOTES || SC_KSO < 1 || SC_KSO > SC_VOTES
#error "SC_KS and SC_KSO must be 1..4 (only the last 4 votes per class and camera are kept)"
#endif
#if SC_CLASSES < 2 || SC_CLASSES > 32
#error "SC_CLASSES must be 2..32"
#endif
#if SC_MAX_AR < 1
#error "SC_MAX_AR must be >= 1"
#endif
#if SC_EVQ < 1 || SC_EVQ > 255
#error "SC_EVQ must be 1..255"
#endif

enum { SC_EV_SURE = 1, SC_EV_GONE = 2 };

struct sc_event {
    uint32_t t;     /* 事件时刻（毫秒钟）；GONE 取最后一张合格票时刻 + SC_H_MS + 1 */
    uint32_t held;  /* GONE：从确定到消失持续的毫秒数 */
    uint32_t conf;  /* SURE：触发确定的那张票的 conf */
    uint8_t type;   /* SC_EV_SURE 或 SC_EV_GONE */
    uint8_t cls;
    uint8_t cams;   /* SURE：窗口内有票的摄像头，bit0 = 1 路，bit1 = 2 路 */
    uint8_t n1, n2; /* SURE：两路窗口内票数 */
};

void sc_init(void);
/* 被事件队列装不下而丢掉的事件数；只丢事件，不影响确定/消失的内部状态。 */
uint32_t sc_lost(void);
/* 一张结果。所有结果都可以喂，不合格的内部自己忽略；先内部 sc_tick 一次再处理这张票。 */
void sc_feed(uint32_t now_ms, uint32_t cam, uint32_t cls, uint32_t frame, uint32_t conf,
             uint32_t reject, uint32_t error, uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1);
/* 检查有没有该报消失的类，按事件时刻升序入队，同刻按类号升序。 */
void sc_tick(uint32_t now_ms);
/* 取队头事件，返回 1；队列空返回 0。 */
int sc_pop(struct sc_event *ev);
/* 当前处于确定状态的类，bit n = 类 n。 */
uint32_t sc_active_mask(void);

#endif
