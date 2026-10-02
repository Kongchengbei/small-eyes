#ifndef CAMERA_DIAG_STATUS_H
#define CAMERA_DIAG_STATUS_H

#include <stdint.h>

enum diag_state {
    DIAG_DISABLED = 0,
    DIAG_FAILED_CONFIG,
    DIAG_WAIT_FRAME,
    DIAG_STALE_SNAPSHOT,
    DIAG_STALLED,
    DIAG_RUNNING
};

struct diag_status_input {
    uint32_t now;
    uint32_t capture_started_at;
    uint32_t last_frame_at;
    uint32_t timeout_ticks;
    uint8_t configured;
    uint8_t enabled;
    uint8_t saw_frame;
    uint8_t snapshot_fresh;
};

enum diag_state diag_status_eval(const struct diag_status_input *input);
const char *diag_status_name(enum diag_state state);

#endif
