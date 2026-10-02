#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "diag_status.h"

int main(void)
{
    struct diag_status_input s = {
        .now = 100u, .capture_started_at = 100u,
        .last_frame_at = 100u, .timeout_ticks = 140000000u,
        .configured = 1u, .enabled = 1u,
        .saw_frame = 0u, .snapshot_fresh = 1u
    };

    assert(diag_status_eval(&s) == DIAG_WAIT_FRAME);
    s.now += s.timeout_ticks - 1u;
    assert(diag_status_eval(&s) == DIAG_WAIT_FRAME);
    ++s.now;
    assert(diag_status_eval(&s) == DIAG_STALLED);

    /* 最近完整帧用于判断停滞，不用历史总成功数代替活跃状态。 */
    s.saw_frame = 1u;
    s.last_frame_at = s.now;
    assert(diag_status_eval(&s) == DIAG_RUNNING);
    s.now += s.timeout_ticks - 1u;
    assert(diag_status_eval(&s) == DIAG_RUNNING);
    ++s.now;
    assert(diag_status_eval(&s) == DIAG_STALLED);
    s.last_frame_at = s.now;
    assert(diag_status_eval(&s) == DIAG_RUNNING);

    /* 当前快照失败优先报告；以后恢复新快照，不被历史超时锁死。 */
    s.snapshot_fresh = 0u;
    assert(diag_status_eval(&s) == DIAG_STALE_SNAPSHOT);
    s.snapshot_fresh = 1u;
    assert(diag_status_eval(&s) == DIAG_RUNNING);
    s.configured = 0u;
    assert(diag_status_eval(&s) == DIAG_FAILED_CONFIG);
    s.enabled = 0u;
    assert(diag_status_eval(&s) == DIAG_DISABLED);

    /* CSR 低32位绕回也必须保持2秒边界正确。 */
    s.enabled = s.configured = s.snapshot_fresh = 1u;
    s.capture_started_at = s.last_frame_at = UINT32_MAX - 500u;
    s.now = s.last_frame_at + s.timeout_ticks - 1u;
    assert(diag_status_eval(&s) == DIAG_RUNNING);
    ++s.now;
    assert(diag_status_eval(&s) == DIAG_STALLED);
    s.saw_frame = 0u;
    assert(diag_status_eval(&s) == DIAG_STALLED);
    --s.now;
    assert(diag_status_eval(&s) == DIAG_WAIT_FRAME);

    assert(strcmp(diag_status_name(DIAG_STALLED), "STALLED") == 0);
    assert(strcmp(diag_status_name(DIAG_DISABLED), "DISABLED") == 0);
    puts("PASS camera diagnostic state: freshness, recovery, 2s boundary, wraparound");
    return 0;
}
