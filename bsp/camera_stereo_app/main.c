#include <stdint.h>
#include "camera_stereo.h"
#include "uart_async.h"
#include "../include/soc_defs.h"

extern uint32_t system_cpu_freq;

#define CPU_HZ SOC_CPU_HZ
#define FRAME_PIXELS 307200u
#define FRAME_LINES 480u
#define FRAME_BYTES 614400u
#define INVALID_ADDR 0xffffffffu
#define CAM_ERROR_STATUS_MASK SOC_CAM_STATUS_ERROR_MASK

struct run_stats {
    struct camera_ctx camera;
    struct cam_snapshot latest;
    uint32_t ok_frames, samples, skipped_ready, discarded_old_ready, sample_mix;
    uint32_t last_dropped, sec_ok, sec_dvp, sec_bytes;
    uint32_t sec_skipped, last_dma_frame, last_frame_count, snapshot_timeouts;
    uint32_t release_timeouts;
    uint32_t last_report_drop;
    uint8_t configured, streaming, saw_frame, config_failed;
};

static uint32_t read_mtime(void) { uint32_t value; __asm__ volatile("csrr %0, 0xB03":"=r"(value)); return value; }
static uint32_t read_mcctr(void) { uint32_t value; __asm__ volatile("csrr %0, 0xB88":"=r"(value)); return value; }
static void write_mcctr(uint32_t value) { __asm__ volatile("csrw 0xB88, %0"::"r"(value)); }

static void log_name(const struct run_stats *s)
{ log_puts(s->camera.id==1u?"CAM1":"CAM2"); }

static bool descriptor_valid(const struct run_stats *s)
{
    uint32_t slot, expected;
    if(s->latest.complete_buffer>1u || s->latest.pixels!=FRAME_PIXELS ||
       s->latest.bytes!=FRAME_BYTES || s->latest.lines!=FRAME_LINES) return false;
    slot=1u<<s->latest.complete_buffer;
    expected=s->latest.complete_buffer==0u?s->camera.buffer0:s->camera.buffer1;
    return (s->latest.ready_mask&slot)!=0u && s->latest.frame_addr==expected;
}

static bool sample_frame(struct run_stats *s, uint32_t *sample_mix,
                         uint32_t *discard_count)
{
    const volatile uint16_t *p;
    uint32_t i,slot,release_mask,discard_mask,mix=0u;
    if(!descriptor_valid(s)) return false;
    p=(const volatile uint16_t *)(uintptr_t)s->latest.frame_addr;
    /* 仅取4个分散样本，不扫描整帧；硬件 sum16 仅作DMA报告。 */
    for(i=0u;i<4u;++i){uint32_t index=i==0u?0u:(i==1u?FRAME_PIXELS/3u:(i==2u?2u*FRAME_PIXELS/3u:FRAME_PIXELS-1u));mix=(mix<<5)^(mix>>2)^p[index];}
    slot=1u<<s->latest.complete_buffer;
    release_mask=s->latest.ready_mask&0x3u;
    discard_mask=release_mask&~slot;
    /*
     * 这是快速调试消费者：验证最新完整描述符后，可丢弃 snapshot 中较旧的
     * ready 槽，避免漏过描述符时旧槽永久占用。AI/保帧消费者不能照搬此策略。
     * ready 位代表硬件已完成；旧槽不读内容，只在确认 latest 后一并归还。
     */
    if(!cam_release(&s->camera,release_mask)){
        ++s->release_timeouts;
        return false;
    }
    *sample_mix=mix;
    *discard_count=((discard_mask&1u)!=0u)+((discard_mask&2u)!=0u);
    return true;
}

static void poll_camera(struct run_stats *s)
{
    uint32_t delta;
    if(!s->streaming)return;
    if(!cam_snapshot(&s->camera,&s->latest,20000u)){
        /* 快照超时只记录状态，下一轮继续服务另一路。 */
        ++s->snapshot_timeouts;
        return;
    }
    if(s->latest.dvp_frames!=s->last_frame_count){
        delta=s->latest.dvp_frames-s->last_frame_count;
        s->sec_dvp+=delta;s->last_frame_count=s->latest.dvp_frames;
    }
    if(s->latest.dropped!=s->last_dropped){s->last_dropped=s->latest.dropped;}
    if(descriptor_valid(s)){
        if(s->latest.frame_count!=s->last_dma_frame){
            uint32_t lost=0u,sample_mix=0u,discard_count=0u;
            if(s->last_dma_frame!=0u && s->latest.frame_count-s->last_dma_frame>1u){
                lost=s->latest.frame_count-s->last_dma_frame-1u;
            }
            /* 释放失败时不提交消费统计/帧号；下一轮可重试同一描述符。 */
            if(!sample_frame(s,&sample_mix,&discard_count))return;
            if(lost>discard_count){s->skipped_ready+=lost-discard_count;s->sec_skipped+=lost-discard_count;}
            s->discarded_old_ready+=discard_count;
            s->sample_mix=sample_mix;
            ++s->samples; ++s->ok_frames; ++s->sec_ok; s->sec_bytes+=s->latest.bytes;
            s->saw_frame=1u;
            s->last_dma_frame=s->latest.frame_count;
        }
    }
}

static void report_camera(const struct run_stats *s)
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
    log_puts(" skipped_ready=");log_putdec(s->skipped_ready);
    log_puts(" discarded_old_ready=");log_putdec(s->discarded_old_ready);
    log_puts(" sec_skipped=");log_putdec(s->sec_skipped);
    log_puts(" snap_timeout=");log_putdec(s->snapshot_timeouts);
    log_puts(" release_timeout=");log_putdec(s->release_timeouts);
    log_puts(" samples=");log_putdec(s->samples);
    log_puts(" sample_mix=");log_puthex(s->sample_mix);
    log_puts(" state=");
    if(s->config_failed)log_puts("FAILED_CONFIG");
    else if(!s->saw_frame && s->latest.pclk_count==0u)log_puts("FAILED_NO_PCLK");
    else if(!s->saw_frame)log_puts("FAILED_NO_FRAME");
    else log_puts("RUNNING");
    if(s->latest.dma_code==9u)log_puts(" DMA_STICKY_NO_FREE_BUFFER");
    log_putc('\n');
}

static void report_config(struct run_stats *s)
{
    uint8_t idh=0u,idl=0u; uint16_t failed=0u; uint32_t writes=0u;
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

int main(void)
{
    struct run_stats a={0},b={0}; uint32_t start,next,drop_notice=0u;
    uint8_t uart_pin=STEREO_UART_TX_FPIOA;
    uart_async_init(115200u,uart_pin);
    log_puts("=== Stereo Camera Bring-up ===\n");
    log_puts("CAMERA_STEREO BOOT\nDDR INIT OK\nCPU CLOCK=");log_putdec(system_cpu_freq);
    log_puts(" UART=115200 TX_FPIOA=");log_putdec(uart_pin);log_putc('\n');
    log_puts("CAM1 BASE="); log_puthex(SOC_CAM1_MMIO_BASE); log_puts(" BUFS=");
    log_puthex(SOC_CAM1_BUFFER0_BASE); log_puts(","); log_puthex(SOC_CAM1_BUFFER1_BASE); log_putc('\n');
    log_puts("CAM2 BASE="); log_puthex(SOC_CAM2_MMIO_BASE); log_puts(" BUFS=");
    log_puthex(SOC_CAM2_BUFFER0_BASE); log_puts(","); log_puthex(SOC_CAM2_BUFFER1_BASE); log_putc('\n');
    cam_init(&a.camera,SOC_CAM1_MMIO_BASE,SOC_CAM1_BUFFER0_BASE,SOC_CAM1_BUFFER1_BASE,1u);
    cam_init(&b.camera,SOC_CAM2_MMIO_BASE,SOC_CAM2_BUFFER0_BASE,SOC_CAM2_BUFFER1_BASE,2u);
    report_config(&a);report_config(&b);
    /* 配置阶段允许串口阻塞；采集开始前把启动日志完全排空。 */
    uart_async_flush_blocking();
    /* CSR B88 bit2 开启本工程 0xB03 mtime，每个 CPU 周期递增。 */
    write_mcctr(read_mcctr() | (1u<<2));
    if(a.configured){cam_dma_enable(&a.camera,true);cam_capture_enable(&a.camera,true);a.streaming=1u;}
    if(b.configured){cam_dma_enable(&b.camera,true);cam_capture_enable(&b.camera,true);b.streaming=1u;}
    log_puts("CAMERA_STEREO CAPTURE_STARTED\n");
    start=read_mtime();next=start+CPU_HZ;
    {
        uint8_t initial_reported=0u;
        for(;;){
            poll_camera(&a);poll_camera(&b);
            // 正常双目首报等两路各有一帧；一路失效仍由每秒摘要诊断。
            if(!initial_reported && (!a.streaming||a.saw_frame) &&
               (!b.streaming||b.saw_frame) && (a.saw_frame||b.saw_frame)){
                log_puts("CAMERA_STEREO INITIAL_STATUS\n");report_camera(&a);report_camera(&b);initial_reported=1u;
            }
            if((uint32_t)(read_mtime()-next)<0x80000000u){
                report_camera(&a);report_camera(&b);
                a.sec_ok=a.sec_dvp=a.sec_bytes=a.sec_skipped=0u;
                b.sec_ok=b.sec_dvp=b.sec_bytes=b.sec_skipped=0u;
                next+=CPU_HZ;
            }
            if(uart_async_dropped()!=drop_notice){drop_notice=uart_async_dropped();log_puts("LOG_DROPPED=");log_putdec(drop_notice);log_putc('\n');}
            uart_async_service();
        }
    }
}
