#ifndef CAMERA_STEREO_SIGN_CONFIRM_H
#define CAMERA_STEREO_SIGN_CONFIRM_H

#include <stdint.h>

/* 每路摄像头独立按框跟踪；对最近 2.5 秒内、至多 15 个结果作类别投票，票数按窗口内实际票数折算。 */

#ifndef SC_MIN_LONG
#define SC_MIN_LONG 40u /* 框长边下限，用打印坐标，不加 1 */
#endif
#ifndef SC_MAX_AR
#define SC_MAX_AR 2u    /* 长边不超过这个倍数的短边，短边为 0 不过 */
#endif
#ifndef SC_CLASSES
#define SC_CLASSES 20u  /* 类别总数，须与 main_npu.c 的 CLASS_COUNT 一致 */
#endif
#ifndef SC_EVQ
#define SC_EVQ 16u      /* 事件队列深度 */
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

enum { SC_EV_SURE = 1, SC_EV_UNCERTAIN = 2, SC_EV_GONE = 3, SC_EV_TARGET = 4 };

struct sc_event {
    uint32_t t;
    uint32_t votes;
    uint32_t conf;
    uint32_t id;
    uint8_t type;
    uint8_t cls;
    uint8_t camera;
    uint8_t count;
};

void sc_init(void);
/* 被事件队列装不下而丢掉的事件数；只丢事件，不影响确定/消失的内部状态。 */
uint32_t sc_lost(void);
/* 每个摄像头目标每帧最多记一票；reject/error 作为 unknown 参与滚动投票。 */
void sc_feed(uint32_t now_ms, uint32_t cam, uint32_t cls, uint32_t frame, uint32_t conf,
             uint32_t reject, uint32_t error, uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1);
/* 检查目标是否消失，并每秒重新输出仍在场的已确认目标。 */
void sc_tick(uint32_t now_ms);
/* 取队头事件，返回 1；队列空返回 0。 */
int sc_pop(struct sc_event *ev);
/* 当前处于确认状态的类别集合，bit n = 类 n。 */
uint32_t sc_active_mask(void);

#endif
