#include "sign_confirm.h"

#define SC_TRACKS_PER_CAM 6u
#define SC_HISTORY 15u          /* 票环容量；只数最近 SC_VOTE_AGE_MS 以内的票 */
#define SC_VOTE_AGE_MS 2500u
#define SC_CONFIRM_VOTES 3u     /* 确认：标签至少 3 票 */
#define SC_CONFIRM_PERCENT 60u  /* 且占有效票 60% 以上（5 票里 3 票即 60%） */
#define SC_LEAD_PERCENT 30u     /* 且领先第二名有效票的 30% 以上 */
#define SC_LEAD_MIN 2u          /* 领先票数不少于 2 */
#define SC_SWITCH_VOTES 4u      /* 改判：新标签至少 4 票 */
#define SC_SWITCH_PERCENT 75u   /* 且占有效票 75% 以上 */
#define SC_MIN_SPAN_MS 500u     /* 首次确认：有效票至少跨这么久，帧率高时不被一小串连续帧骗 */
#define SC_REPEAT_MS 1000u
#define SC_TRACK_TIMEOUT_MS 2500u
#define SC_IOU_PERCENT 40u

struct sc_vote {
    uint32_t t;
    uint8_t cls;
};

struct sc_track {
    struct sc_vote votes[SC_HISTORY];
    uint32_t x0, y0, x1, y1;
    uint32_t last_seen, last_frame, last_report;
    uint32_t id;
    uint8_t count, head, camera, label, active, confirmed, uncertain, has_frame;
};

static struct sc_track g_tracks[2][SC_TRACKS_PER_CAM];
static struct sc_event g_q[SC_EVQ];
static uint8_t g_qhead, g_qcount;
static uint32_t g_lost, g_next_id;

uint32_t sc_lost(void)
{
    return g_lost;
}

void sc_init(void)
{
    uint32_t cam, i, j;
    for (cam = 0u; cam < 2u; ++cam) {
        for (i = 0u; i < SC_TRACKS_PER_CAM; ++i) {
            struct sc_track *track = &g_tracks[cam][i];
            track->x0 = 0u; track->y0 = 0u; track->x1 = 0u; track->y1 = 0u;
            track->last_seen = 0u; track->last_frame = 0u; track->last_report = 0u;
            track->id = 0u; track->count = 0u; track->head = 0u;
            track->camera = (uint8_t)(cam + 1u); track->label = 0u;
            track->active = 0u; track->confirmed = 0u; track->uncertain = 0u;
            track->has_frame = 0u;
            for (j = 0u; j < SC_HISTORY; ++j) {
                track->votes[j].t = 0u;
                track->votes[j].cls = 0u;
            }
        }
    }
    g_qhead = 0u; g_qcount = 0u; g_lost = 0u; g_next_id = 1u;
}

static void sc_push(uint8_t type, const struct sc_track *track, uint32_t now_ms,
                    uint32_t cls, uint32_t votes, uint32_t count, uint32_t conf)
{
    struct sc_event *event;
    if (g_qcount >= SC_EVQ) { ++g_lost; return; }
    event = &g_q[((uint32_t)g_qhead + g_qcount) % SC_EVQ];
    event->t = now_ms; event->votes = votes; event->conf = conf; event->id = track->id;
    event->type = type; event->cls = (uint8_t)cls; event->camera = track->camera;
    event->count = (uint8_t)count;
    ++g_qcount;
}

int sc_pop(struct sc_event *ev)
{
    const struct sc_event *event;
    if (g_qcount == 0u) return 0;
    event = &g_q[g_qhead];
    ev->t = event->t; ev->votes = event->votes; ev->conf = event->conf; ev->id = event->id;
    ev->type = event->type; ev->cls = event->cls; ev->camera = event->camera;
    ev->count = event->count;
    g_qhead = (uint8_t)(((uint32_t)g_qhead + 1u) % SC_EVQ);
    --g_qcount;
    return 1;
}

uint32_t sc_active_mask(void)
{
    uint32_t cam, i, mask = 0u;
    for (cam = 0u; cam < 2u; ++cam) {
        for (i = 0u; i < SC_TRACKS_PER_CAM; ++i) {
            const struct sc_track *track = &g_tracks[cam][i];
            if (track->active != 0u && track->confirmed != 0u && track->label < 32u)
                mask |= 1u << track->label;
        }
    }
    return mask;
}

static int sc_size_ok(uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1)
{
    uint32_t width, height, longest, shortest;
    if (x1 < x0 || y1 < y0) return 0;
    width = x1 - x0; height = y1 - y0;
    longest = width > height ? width : height;
    shortest = width > height ? height : width;
    return longest >= SC_MIN_LONG && shortest != 0u && longest <= SC_MAX_AR * shortest;
}

static uint32_t sc_iou_match(const struct sc_track *track,
                            uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1)
{
    uint32_t left = track->x0 > x0 ? track->x0 : x0;
    uint32_t top = track->y0 > y0 ? track->y0 : y0;
    uint32_t right = track->x1 < x1 ? track->x1 : x1;
    uint32_t bottom = track->y1 < y1 ? track->y1 : y1;
    uint32_t intersection, area_a, area_b, united;
    if (right <= left || bottom <= top) return 0u;
    intersection = (right - left) * (bottom - top);
    area_a = (track->x1 - track->x0) * (track->y1 - track->y0);
    area_b = (x1 - x0) * (y1 - y0);
    united = area_a + area_b - intersection;
    if (united == 0u) return 0u;
    return intersection * 100u / united;
}

static uint32_t sc_counts(const struct sc_track *track, uint32_t now_ms, uint8_t counts[SC_CLASSES])
{
    uint32_t i, total = 0u;
    for (i = 0u; i < SC_CLASSES; ++i) counts[i] = 0u;
    for (i = 0u; i < track->count; ++i) {
        const struct sc_vote *vote = &track->votes[i];
        if (now_ms - vote->t > SC_VOTE_AGE_MS) continue;
        if (vote->cls < SC_CLASSES) {
            ++counts[vote->cls];
            ++total;
        }
    }
    return total;
}

static uint32_t sc_span(const struct sc_track *track, uint32_t now_ms)
{
    uint32_t i, oldest = track->last_seen;
    for (i = 0u; i < track->count; ++i) {
        uint32_t t = track->votes[i].t;
        if (now_ms - t <= SC_VOTE_AGE_MS && t < oldest) oldest = t;
    }
    return track->last_seen - oldest;
}

static int sc_supported(uint32_t best, uint32_t runner, uint32_t total)
{
    uint32_t lead = (total * SC_LEAD_PERCENT + 99u) / 100u;
    if (lead < SC_LEAD_MIN) lead = SC_LEAD_MIN;
    return best >= SC_CONFIRM_VOTES && best * 100u >= total * SC_CONFIRM_PERCENT &&
           best >= runner + lead;
}

static void sc_refresh(struct sc_track *track, uint32_t now_ms, uint32_t conf)
{
    uint8_t counts[SC_CLASSES];
    uint32_t cls, winner = 0u, total;
    uint32_t best = 0u, runner = 0u;
    total = sc_counts(track, now_ms, counts);
    for (cls = 0u; cls < SC_CLASSES; ++cls) {
        if (counts[cls] > best) {
            runner = best; best = counts[cls]; winner = cls;
        } else if (counts[cls] > runner) {
            runner = counts[cls];
        }
    }
    if (track->confirmed == 0u) {
        if (winner >= 2u && sc_supported(best, runner, total) &&
            sc_span(track, now_ms) >= SC_MIN_SPAN_MS) {
            track->label = (uint8_t)winner;
            track->confirmed = 1u;
            track->uncertain = 0u;
            track->last_report = now_ms;
            sc_push(SC_EV_SURE, track, now_ms, winner, best, total, conf);
        }
        return;
    }
    if (winner >= 2u && winner != track->label && best >= SC_SWITCH_VOTES &&
        best * 100u >= total * SC_SWITCH_PERCENT) {
        track->label = (uint8_t)winner;
        track->uncertain = 0u;
        track->last_report = now_ms;
        sc_push(SC_EV_SURE, track, now_ms, winner, best, total, conf);
    } else if (winner == track->label && sc_supported(best, runner, total)) {
        if (track->uncertain != 0u) {
            track->uncertain = 0u;
            track->last_report = now_ms;
            sc_push(SC_EV_SURE, track, now_ms, track->label,
                    counts[track->label], total, conf);
        }
    } else if (track->uncertain == 0u) {
        track->uncertain = 1u;
        track->last_report = now_ms;
        sc_push(SC_EV_UNCERTAIN, track, now_ms, track->label,
                counts[track->label], total, conf);
    }
}

void sc_tick(uint32_t now_ms)
{
    uint32_t cam, i;
    for (cam = 0u; cam < 2u; ++cam) {
        for (i = 0u; i < SC_TRACKS_PER_CAM; ++i) {
            struct sc_track *track = &g_tracks[cam][i];
            if (track->active == 0u) continue;
            if (now_ms - track->last_seen > SC_TRACK_TIMEOUT_MS) {
                if (track->confirmed != 0u)
                    sc_push(SC_EV_GONE, track, track->last_seen + SC_TRACK_TIMEOUT_MS + 1u,
                            track->label, 0u, 0u, 0u);
                track->active = 0u;
                continue;
            }
            sc_refresh(track, now_ms, 0u);
            if (track->confirmed != 0u && now_ms - track->last_report >= SC_REPEAT_MS) {
                uint8_t counts[SC_CLASSES];
                uint32_t total = sc_counts(track, now_ms, counts);
                sc_push(track->uncertain != 0u ? SC_EV_UNCERTAIN : SC_EV_TARGET, track, now_ms,
                        track->label, counts[track->label], total, 0u);
                track->last_report = now_ms;
            }
        }
    }
}

void sc_feed(uint32_t now_ms, uint32_t cam, uint32_t cls, uint32_t frame, uint32_t conf,
             uint32_t reject, uint32_t error, uint32_t x0, uint32_t y0, uint32_t x1, uint32_t y1)
{
    struct sc_track *best_track = 0, *free_track = 0;
    uint32_t i, best_iou = 0u, camera_index, vote_cls;
    sc_tick(now_ms);
    if (cam < 1u || cam > 2u || !sc_size_ok(x0, y0, x1, y1)) return;
    camera_index = cam - 1u;
    vote_cls = (error != 0u || reject != 0u || cls >= SC_CLASSES) ? 1u : cls;
    for (i = 0u; i < SC_TRACKS_PER_CAM; ++i) {
        struct sc_track *track = &g_tracks[camera_index][i];
        uint32_t iou;
        if (track->active == 0u) {
            if (free_track == 0) free_track = track;
            continue;
        }
        if (now_ms - track->last_seen > SC_TRACK_TIMEOUT_MS) {
            if (free_track == 0) free_track = track;
            continue;
        }
        iou = sc_iou_match(track, x0, y0, x1, y1);
        if (iou >= SC_IOU_PERCENT && iou > best_iou) {
            best_iou = iou;
            best_track = track;
        }
    }
    if (best_track == 0) {
        if (vote_cls == 0u || free_track == 0) return;
        best_track = free_track;
        best_track->active = 1u;
        best_track->confirmed = 0u;
        best_track->uncertain = 0u;
        best_track->count = 0u;
        best_track->head = 0u;
        best_track->label = 0u;
        best_track->has_frame = 0u;
        best_track->last_report = now_ms;
        best_track->id = g_next_id++;
        if (g_next_id == 0u) g_next_id = 1u;
    }
    if (best_track->has_frame != 0u && best_track->last_frame == frame) return;
    best_track->x0 = x0; best_track->y0 = y0; best_track->x1 = x1; best_track->y1 = y1;
    best_track->last_seen = now_ms;
    best_track->last_frame = frame;
    best_track->has_frame = 1u;
    best_track->votes[best_track->head].t = now_ms;
    best_track->votes[best_track->head].cls = (uint8_t)vote_cls;
    best_track->head = (uint8_t)(((uint32_t)best_track->head + 1u) % SC_HISTORY);
    if (best_track->count < SC_HISTORY) ++best_track->count;
    sc_refresh(best_track, now_ms, conf);
}
