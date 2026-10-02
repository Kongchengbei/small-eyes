#include "diag_status.h"

enum diag_state diag_status_eval(const struct diag_status_input *input)
{
    if (input == 0 || input->enabled == 0u)
        return DIAG_DISABLED;
    if (input->configured == 0u)
        return DIAG_FAILED_CONFIG;
    if (input->snapshot_fresh == 0u)
        return DIAG_STALE_SNAPSHOT;
    if (input->saw_frame != 0u) {
        if ((uint32_t)(input->now - input->last_frame_at) >=
            input->timeout_ticks)
            return DIAG_STALLED;
        return DIAG_RUNNING;
    }
    if ((uint32_t)(input->now - input->capture_started_at) >=
        input->timeout_ticks)
        return DIAG_STALLED;
    return DIAG_WAIT_FRAME;
}

const char *diag_status_name(enum diag_state state)
{
    switch (state) {
    case DIAG_DISABLED: return "DISABLED";
    case DIAG_FAILED_CONFIG: return "FAILED_CONFIG";
    case DIAG_WAIT_FRAME: return "WAIT_FRAME";
    case DIAG_STALE_SNAPSHOT: return "STALE_SNAPSHOT";
    case DIAG_STALLED: return "STALLED";
    case DIAG_RUNNING: return "RUNNING";
    default: return "UNKNOWN";
    }
}
