#include <stdint.h>
#include "camera_stereo.h"
#include "diag_status.h"
#include "uart_async.h"
#include "../include/soc_defs.h"

extern uint32_t system_cpu_freq;

#define CPU_HZ SOC_CPU_HZ
#define FRAME_PIXELS 307200u
#define FRAME_LINES 480u
#define FRAME_BYTES 614400u
#define CTRL_CAPTURE SOC_CAM_SCCB_CAPTURE_ENABLE_MASK
#define SNAP_VALID SOC_CAM_SNAPSHOT_VALID_MASK
#define SNAP_TIMEOUT SOC_CAM_SNAPSHOT_TIMEOUT_MASK
#define CAM_ERROR_STATUS_MASK SOC_CAM_STATUS_ERROR_MASK
#define MMIO(base, off) (*(volatile uint32_t *)((base) + (off)))

#ifndef DIAG_CAM2_ONLY
#define DIAG_CAM2_ONLY 0
#endif

struct run_stats {
    struct camera_ctx camera;
    struct cam_snapshot latest;
    uint32_t ok_frames, samples, skipped_ready, discarded_old_ready, sample_mix;
    uint32_t sec_ok, sec_dvp, sec_bytes, sec_skipped, sec_pclk, sec_seq;
    uint32_t last_dma_frame, last_dvp_frames, last_pclk, last_sequence;
    uint32_t snapshot_timeouts, poll_timeouts, release_timeouts;
    uint32_t capture_started_at, last_frame_at, last_snapshot_at;
    uint32_t last_report_frame;
    uint8_t configured, enabled, saw_frame, config_failed;
    uint8_t have_sequence, snapshot_fresh, snapshot_valid;
};

static uint32_t read_mtime(void)
{ uint32_t value; __asm__ volatile("csrr %0, 0xB03":"=r"(value)); return value; }
static uint32_t read_mcctr(void)
{ uint32_t value; __asm__ volatile("csrr %0, 0xB88":"=r"(value)); return value; }
static void write_mcctr(uint32_t value)
{ __asm__ volatile("csrw 0xB88, %0"::"r"(value)); }

static void log_name(const struct run_stats *s)
{ log_puts(s->camera.id==1u?"CAM1":"CAM2"); }

static uint32_t age_ms(uint32_t now, uint32_t then)
{ return (uint32_t)(now-then)/70000u; }

static uint32_t capture_readback(const struct run_stats *s)
{ return (MMIO(s->camera.base,SOC_CAM_SCCB_CONTROL_OFFSET)&CTRL_CAPTURE)!=0u; }

static uint32_t dma_readback(const struct run_stats *s)
{ return MMIO(s->camera.base,SOC_CAM_DMA_CONTROL)&SOC_CAM_DMA_ENABLE_MASK; }

static bool descriptor_valid(const struct run_stats *s)
{
    uint32_t slot, expected;
    if(s->latest.complete_buffer>1u || s->latest.pixels!=FRAME_PIXELS ||
       s->latest.bytes!=FRAME_BYTES || s->latest.lines!=FRAME_LINES) return false;
    slot=1u<<s->latest.complete_buffer;
    expected=s->latest.complete_buffer==0u?s->camera.buffer0:s->camera.buffer1;
    return (s->latest.ready_mask&slot)!=0u && s->latest.frame_addr==expected;
}

static bool sample_and_release(struct run_stats *s, uint32_t *mix_out,
                               uint32_t *discard_out)
{
    const volatile uint16_t *p=(const volatile uint16_t *)(uintptr_t)s->latest.frame_addr;
    uint32_t i,slot,release_mask,discard_mask,mix=0u;
    if(!descriptor_valid(s)) return false;
    for(i=0u;i<4u;++i){
        uint32_t index=i==0u?0u:(i==1u?FRAME_PIXELS/3u:
                       (i==2u?2u*FRAME_PIXELS/3u:FRAME_PIXELS-1u));
        mix=(mix<<5)^(mix>>2)^p[index];
    }
    slot=1u<<s->latest.complete_buffer;
    release_mask=s->latest.ready_mask&3u;
    discard_mask=release_mask&~slot;
    if(!cam_release(&s->camera,release_mask)){++s->release_timeouts;return false;}
    *mix_out=mix;
    *discard_out=((discard_mask&1u)!=0u)+((discard_mask&2u)!=0u);
    return true;
}

static void poll_camera(struct run_stats *s)
{
    uint32_t delta;
    if(!s->enabled) return;
    s->snapshot_fresh=0u;
    if(!cam_snapshot(&s->camera,&s->latest,20000u)){
        s->snapshot_valid=(s->latest.snapshot_control&SNAP_VALID)!=0u;
        ++s->poll_timeouts;
        if((s->latest.snapshot_control&SNAP_TIMEOUT)!=0u)++s->snapshot_timeouts;
        return;
    }
    s->snapshot_valid=(s->latest.snapshot_control&SNAP_VALID)!=0u;
    if(!s->snapshot_valid)return;
    if(!s->have_sequence){
        s->last_sequence=s->latest.sequence;
        s->last_pclk=s->latest.pclk_count;
        s->last_dvp_frames=s->latest.dvp_frames;
        s->have_sequence=1u;
        return;
    }
    delta=s->latest.sequence-s->last_sequence;
    if(delta==0u)return;
    s->snapshot_fresh=1u;
    s->last_snapshot_at=read_mtime();
    s->sec_seq+=delta;
    s->last_sequence=s->latest.sequence;
    s->sec_pclk+=s->latest.pclk_count-s->last_pclk;
    s->last_pclk=s->latest.pclk_count;
    delta=s->latest.dvp_frames-s->last_dvp_frames;
    s->sec_dvp+=delta;
    s->last_dvp_frames=s->latest.dvp_frames;
    if(descriptor_valid(s)&&s->latest.frame_count!=s->last_dma_frame){
        uint32_t mix=0u,discard=0u,lost=0u;
        if(s->last_dma_frame!=0u&&s->latest.frame_count-s->last_dma_frame>1u)
            lost=s->latest.frame_count-s->last_dma_frame-1u;
        if(!sample_and_release(s,&mix,&discard))return;
        if(lost>discard){s->skipped_ready+=lost-discard;s->sec_skipped+=lost-discard;}
        s->discarded_old_ready+=discard;s->sample_mix=mix;
        ++s->samples;++s->ok_frames;++s->sec_ok;s->sec_bytes+=s->latest.bytes;
        s->saw_frame=1u;s->last_dma_frame=s->latest.frame_count;
        s->last_frame_at=read_mtime();
    }
}

static enum diag_state camera_state(const struct run_stats *s,uint32_t now)
{
    struct diag_status_input input;
    input.now=now;input.capture_started_at=s->capture_started_at;
    input.last_frame_at=s->last_frame_at;input.timeout_ticks=2u*CPU_HZ;
    input.configured=s->configured;input.enabled=s->enabled;
    input.saw_frame=s->saw_frame;input.snapshot_fresh=s->snapshot_fresh;
    return diag_status_eval(&input);
}

static void report_camera(const struct run_stats *s,uint32_t now)
{
    uint32_t errors=s->latest.status&CAM_ERROR_STATUS_MASK;
    log_name(s);log_puts(" sec_ok=");log_putdec(s->sec_ok);
    log_puts(" total_ok=");log_putdec(s->ok_frames);
    log_puts(" dvp_frames=");log_putdec(s->latest.dvp_frames);
    log_puts(" sec_dvp=");log_putdec(s->sec_dvp);
    log_puts(" drop=");log_putdec(s->latest.dropped);
    log_puts(" sec_bytes=");log_putdec(s->sec_bytes);
    log_puts(" lines=");log_putdec(s->latest.lines);
    log_puts(" pixels=");log_putdec(s->latest.pixels);
    log_puts(" bytes=");log_putdec(s->latest.bytes);
    log_puts(" fifo=");log_putdec(s->latest.fifo_level);
    log_puts(" fifo_peak=");log_putdec(s->latest.fifo_max);
    log_puts(" status=");log_puthex(s->latest.status);
    log_puts(" errors=");log_puthex(errors);
    log_puts(" fifo_err=");log_puthex(s->latest.fifo_error);
    log_puts(" dvp_err=");log_puthex(s->latest.dvp_flags);
    log_puts(" dma_status=");log_puthex(s->latest.dma_status);
    log_puts(" dma_code=");log_putdec(s->latest.dma_code);
    log_puts(" ready=");log_puthex(s->latest.ready_mask);
    log_puts(" write_slot=");log_puthex(s->latest.write_buffer);
    log_puts(" last_slot=");log_puthex(s->latest.complete_buffer);
    log_puts(" last_addr=");log_puthex(s->latest.frame_addr);
    log_puts(" hw_sum16=");log_puthex(s->latest.hw_sum16);
    log_puts(" pclk_count=");log_putdec(s->latest.pclk_count);
    log_puts(" pclk_delta=");log_putdec(s->sec_pclk);
    log_puts(" seq=");log_putdec(s->latest.sequence);
    log_puts(" seq_delta=");log_putdec(s->sec_seq);
    log_puts(" snap_valid=");log_putdec(s->snapshot_valid);
    log_puts(" fresh=");log_putdec(s->snapshot_fresh);
    log_puts(" age_ms=");log_putdec(s->have_sequence?age_ms(now,s->last_snapshot_at):0xffffffffu);
    log_puts(" cur_dma_pixels=");log_putdec(s->latest.current_pixels);
    log_puts(" cur_dma_bytes=");log_putdec(s->latest.current_bytes);
    log_puts(" cur_dma_lines=");log_putdec(s->latest.current_lines);
    log_puts(" cap_en_live=");log_putdec(capture_readback(s));
    log_puts(" dma_en_live=");log_putdec(dma_readback(s));
    log_puts(" frame_count=");log_putdec(s->latest.frame_count);
    log_puts(" frame_delta=");log_putdec(s->latest.frame_count-s->last_report_frame);
    log_puts(" samples=");log_putdec(s->samples);
    log_puts(" sample_mix=");log_puthex(s->sample_mix);
    log_puts(" skipped_ready=");log_putdec(s->skipped_ready);
    log_puts(" discarded_old_ready=");log_putdec(s->discarded_old_ready);
    log_puts(" sec_skipped=");log_putdec(s->sec_skipped);
    log_puts(" snap_timeout=");log_putdec(s->snapshot_timeouts);
    log_puts(" poll_timeout=");log_putdec(s->poll_timeouts);
    log_puts(" release_timeout=");log_putdec(s->release_timeouts);
    log_puts(" state=");log_puts(diag_status_name(camera_state(s,now)));
    log_putc('\n');
}

static void report_config(struct run_stats *s)
{
    uint8_t idh=0u,idl=0u;uint16_t failed=0u;uint32_t writes=0u;
    bool ackh,ackl;
    cam_sccb_init(&s->camera);
    ackh=cam_read_reg(&s->camera,0x300au,&idh);ackl=cam_read_reg(&s->camera,0x300bu,&idl);
    log_name(s);log_puts(" SCCB=");log_puts(ackh&&ackl?"OK":"NO_ACK");
    log_puts(" PID=");log_puthex(((uint32_t)idh<<8)|idl);log_putc('\n');
    if(!(ackh&&ackl&&idh==0x56u&&idl==0x40u)){
        s->config_failed=1u;log_name(s);log_puts(" OV5640=FAILED_DETECT\n");return;
    }
    if(!cam_configure_vga(&s->camera,&failed,&writes)){
        s->config_failed=1u;log_name(s);log_puts(" CONFIG=FAILED REG=");log_puthex(failed);
        log_puts(" writes=");log_putdec(writes);log_putc('\n');return;
    }
    s->configured=1u;log_name(s);log_puts(" CONFIG=OK VGA_RGB565 writes=");log_putdec(writes);log_putc('\n');
}

static void reset_second(struct run_stats *s)
{
    s->sec_ok=s->sec_dvp=s->sec_bytes=s->sec_skipped=s->sec_pclk=s->sec_seq=0u;
    s->last_report_frame=s->latest.frame_count;
}

int main(void)
{
    struct run_stats a={0},b={0};
    uint32_t start,next,cam1_report_at=0u,drop_notice=0u;
    uint8_t uart_pin=STEREO_UART_TX_FPIOA,cam2_pending=0u,initial_pending=0u;
    uart_async_init(115200u,uart_pin);
    log_puts("=== Camera Diagnostic ===\nCAMERA_DIAG BOOT MODE=");
    log_puts(DIAG_CAM2_ONLY?"CAM2_ONLY":"STEREO_DIAG");
    log_puts(" TX_FPIOA=");log_putdec(uart_pin);log_putc('\n');
    cam_init(&a.camera,SOC_CAM1_MMIO_BASE,SOC_CAM1_BUFFER0_BASE,SOC_CAM1_BUFFER1_BASE,1u);
    cam_init(&b.camera,SOC_CAM2_MMIO_BASE,SOC_CAM2_BUFFER0_BASE,SOC_CAM2_BUFFER1_BASE,2u);
    report_config(&a);report_config(&b);
    uart_async_flush_blocking();
    write_mcctr(read_mcctr()|(1u<<2));
    if(a.configured&&!DIAG_CAM2_ONLY){
        cam_dma_enable(&a.camera,true);cam_capture_enable(&a.camera,true);
    }else{
        cam_dma_enable(&a.camera,false);cam_capture_enable(&a.camera,false);
    }
    a.enabled=(uint8_t)!DIAG_CAM2_ONLY;
    b.enabled=1u;
    if(b.configured){cam_dma_enable(&b.camera,true);cam_capture_enable(&b.camera,true);}
    start=read_mtime();a.capture_started_at=b.capture_started_at=start;
    a.last_snapshot_at=b.last_snapshot_at=start;
    next=start+CPU_HZ;
    log_puts("CAMERA_DIAG CAPTURE_STARTED\n");
    for(;;){
        uint32_t now;
        poll_camera(&a);poll_camera(&b);
        now=read_mtime();
        if(!initial_pending&&(!a.enabled||!a.configured||a.saw_frame)&&
           (!b.enabled||!b.configured||b.saw_frame)&&
           (a.saw_frame||b.saw_frame)){
            log_puts("CAMERA_DIAG INITIAL_STATUS\n");
            report_camera(&a,now);reset_second(&a);
            cam1_report_at=now;cam2_pending=1u;initial_pending=1u;
        }
        if((uint32_t)(now-next)<0x80000000u){
            if(!cam2_pending){
                report_camera(&a,now);reset_second(&a);
                cam1_report_at=now;cam2_pending=1u;
            }
            next+=CPU_HZ;
        }
        /* 两路长摘要分次入环形队列；UART 每轮发送一字节，留出传输窗口。 */
        if(cam2_pending&&(uint32_t)(now-cam1_report_at)>=CPU_HZ/8u){
            report_camera(&b,now);reset_second(&b);
            cam2_pending=0u;
        }
        if(uart_async_dropped()!=drop_notice){
            drop_notice=uart_async_dropped();log_puts("LOG_DROPPED=");log_putdec(drop_notice);log_putc('\n');
        }
        uart_async_service();
    }
}
