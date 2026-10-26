#include <stdint.h>
#include "camera_stereo.h"
#include "uart_async.h"
#include "../include/soc_defs.h"

/*
 * 全流程上板测试：两路 OV5640 -> 前处理找框 -> INT8 -> NPU -> 串口。
 * 找框、INT8、NPU 都由硬件自动跑（参数在 Hfpga_soc.v 里写死，上电自动使能），
 * CPU 只配置两颗摄像头、打开采集，再从 NPU 结果队列逐条取出打印。
 */

extern uint32_t system_cpu_freq;

#define CPU_HZ SOC_CPU_HZ
#define REG32(addr) (*(volatile uint32_t *)(uintptr_t)(addr))

/* 结果队列寄存器见 soc/Hnpu_result_mmio.v，soc_defs.h 没有生成这几项。 */
#define NPU_RESULT_STATUS REG32(SOC_NPU_MMIO_BASE+0x20u)
#define NPU_RESULT_DATA(i) REG32(SOC_NPU_MMIO_BASE+0x24u+4u*(uint32_t)(i))
#define NPU_RESULT_POP REG32(SOC_NPU_MMIO_BASE+0x44u)
#define NPU_RESULT_ERROR_CODE REG32(SOC_NPU_MMIO_BASE+0x50u)
#define RESULT_EMPTY (1u<<16)
#define RESULT_COUNT_MASK 0xffffu

#define INT8_REG(off) REG32(SOC_INT8_MMIO_BASE+(off))
#define INT8_STAT(id,off) INT8_REG(((id)==1u?SOC_INT8_CAM1_STATS_BASE:SOC_INT8_CAM2_STATS_BASE)+(off))

/* flash_ddr_loader 上电时把 model.npu 搬到这里；文件头格式见 scripts/npu_model.py。 */
#define MODEL_WORD(off) REG32(SOC_NPU_WEIGHT_BASE+(off))
#define MODEL_MAGIC 0x3155504eu

/*
 * 0（默认）：每个框一行，直接写认出的路标名；每 NPU_STAT_SECONDS 秒一行汇总，出问题另起一行写原因。
 * 1：逐项格式，每框一行 NPU cam=... 加每秒 STAT、INT8、CAM1、CAM2 四行，对金样、查问题用。
 */
#ifndef NPU_VERBOSE
#define NPU_VERBOSE 0
#endif
/* 0：不逐条打印背景框，只计数。 */
#ifndef NPU_PRINT_BACKGROUND
#define NPU_PRINT_BACKGROUND 0
#endif
/* 曝光扫参（sweep.c）：0（默认）不编进去；1 扫预设；2 只走展示时间表。非 0 时必须打印背景框（Makefile 已强制）。 */
#ifndef NPU_SWEEP
#define NPU_SWEEP 0
#endif
#if NPU_SWEEP < 0 || NPU_SWEEP > 2
#error "NPU_SWEEP must be 0..2"
#endif
#if NPU_SWEEP && !NPU_PRINT_BACKGROUND
#error "NPU_SWEEP needs NPU_PRINT_BACKGROUND=1"
#endif
#if NPU_SWEEP
#include "sweep.h"
#endif
/* 1：路标名用 GBK 中文（串口终端按 GBK/ANSI 显示时用），默认英文。只管默认格式。 */
#ifndef NPU_NAMES_GBK
#define NPU_NAMES_GBK 0
#endif
/* 默认格式的汇总间隔（秒）。mtime 是 32 位，70 MHz 下最多 30 秒。 */
#ifndef NPU_STAT_SECONDS
#define NPU_STAT_SECONDS 5
#endif
#if NPU_STAT_SECONDS < 1 || NPU_STAT_SECONDS > 30
#error "NPU_STAT_SECONDS must be 1..30"
#endif
/* 1（默认）：路标确认层，连续几次一致才算确认，只新增 ### 开头的行；0：新代码一行都不编进去。只管默认格式。 */
#ifndef NPU_CONFIRM
#define NPU_CONFIRM 1
#endif
/* 1：每张结果多打一行 ### VOTE，仿真对拍用，串口放不下时会等。 */
#ifndef NPU_CONFIRM_TRACE
#define NPU_CONFIRM_TRACE 0
#endif
/* 1：不打 >>> 和 ??? 行，其余照打。 */
#ifndef NPU_QUIET
#define NPU_QUIET 0
#endif
#if (!NPU_CONFIRM || NPU_VERBOSE) && (NPU_CONFIRM_TRACE || NPU_QUIET)
#error "NPU_CONFIRM_TRACE and NPU_QUIET need NPU_CONFIRM=1 and NPU_VERBOSE=0"
#endif

#define CLASS_COUNT 12u
/* 一条结果最长约 150 字节；队列不够就只计数不打印，不拖住结果队列。 */
#define LINE_RESERVE 200u

#if NPU_CONFIRM && !NPU_VERBOSE
#include "sign_confirm.h"
#if SC_CLASSES != CLASS_COUNT
#error "SC_CLASSES must equal CLASS_COUNT"
#endif
#endif

#if NPU_VERBOSE
/* 编号同 temp/路标模型文件v0.3_10月10日/classes.csv。 */
static const char *const class_names[CLASS_COUNT]={
    "background","unknown","pne","pn","p11","pl40","pl60","pl80","pl120","i5","w57","i2"
};
#endif
/* Hpreprocess_color.v：1 红、2 黄、3 蓝、4 黑。 */
static const char *const color_names[8]={"none","red","yellow","blue","black","c5","c6","c7"};

#if NPU_VERBOSE
enum verdict { VERDICT_SIGN, VERDICT_UNKNOWN, VERDICT_BACKGROUND, VERDICT_ERROR };
#define REPORT_CYCLES CPU_HZ
#else
/* 默认格式的显示分类和行首标记；reject=1 时最高分只算猜测，最高分是背景的照样算背景。 */
enum shown { SHOWN_SIGN, SHOWN_OTHER, SHOWN_UNSURE, SHOWN_BACKGROUND, SHOWN_ERROR, SHOWN_KINDS };
static const char *const shown_tags[SHOWN_KINDS]={">>> ","??? ","??? ","... ","!!! "};
static const char *const shown_labels[SHOWN_KINDS]={"sign","other","unsure","bg","err"};
#define REPORT_CYCLES (CPU_HZ*NPU_STAT_SECONDS)
#define NAME_WIDTH 20u
/* 显示用路标名，编号同 classes.csv。 */
#if NPU_NAMES_GBK
static const char *const sign_names[CLASS_COUNT]={
    "\xb1\xb3\xbe\xb0",                                              /* 背景 */
    "\xce\xb4\xd6\xaa\xb1\xea\xd6\xbe",                              /* 未知标志 */
    "\xbd\xfb\xd6\xb9\xca\xbb\xc8\xeb",                              /* 禁止驶入 */
    "\xbd\xfb\xd6\xb9\xcd\xa3\xb3\xb5",                              /* 禁止停车 */
    "\xbd\xfb\xd6\xb9\xc3\xf9\xc0\xae\xb0\xc8",                      /* 禁止鸣喇叭 */
    "\xcf\xde\xcb\xd9""40",                                          /* 限速40 */
    "\xcf\xde\xcb\xd9""60",                                          /* 限速60 */
    "\xcf\xde\xcb\xd9""80",                                          /* 限速80 */
    "\xcf\xde\xcb\xd9""120",                                         /* 限速120 */
    "\xbf\xbf\xd3\xd2\xb2\xe0\xb5\xc0\xc2\xb7\xd0\xd0\xca\xbb",      /* 靠右侧道路行驶 */
    "\xd7\xa2\xd2\xe2\xd0\xd0\xc8\xcb",                              /* 注意行人 */
    "\xcf\xf2\xd7\xf3\xd7\xaa\xcd\xe4"                              /* 向左转弯 */
};
#define UNSURE_BEFORE "\xd2\xc9\xcb\xc6"                             /* 疑似 */
#define UNSURE_AFTER ""
#else
static const char *const sign_names[CLASS_COUNT]={
    "background","other sign","NO ENTRY","NO PARKING","NO HONKING","SPEED LIMIT 40",
    "SPEED LIMIT 60","SPEED LIMIT 80","SPEED LIMIT 120","KEEP RIGHT","WATCH PEDESTRIANS","TURN LEFT"
};
#define UNSURE_BEFORE "maybe "
#define UNSURE_AFTER "?"
#endif
/* 没模型时提示烧哪个文件：local 版串口在 FPIOA0，remote 版在 FPIOA31。 */
#if STEREO_UART_TX_FPIOA == 31
#define FLASH_IMAGE "camera_stereo_npu_remote_flash.bin"
#else
#define FLASH_IMAGE "camera_stereo_npu_local_flash.bin"
#endif
#endif

struct npu_result {
    uint32_t camera, frame, roi, x0, y0, x1, y1, color, cls;
    uint32_t confidence, error, score, reject;
};

#if NPU_VERBOSE
struct npu_stats {
    uint32_t total, sec, sign, unknown, background, error, unprinted;
    uint32_t per_class[CLASS_COUNT];
};
#else
/* kind、per_class、unprinted 只算本汇总周期，打完清零。 */
struct npu_stats {
    uint32_t kind[SHOWN_KINDS], per_class[CLASS_COUNT], unprinted, npu_err;
};
#endif

struct cam_run {
    struct camera_ctx camera;
    struct cam_snapshot latest;
    uint32_t last_dvp, last_dma, snapshot_timeouts;
    uint8_t configured, streaming, config_failed;
};

static uint32_t read_mtime(void) { uint32_t value; __asm__ volatile("csrr %0, 0xB03":"=r"(value)); return value; }
static uint32_t read_mcctr(void) { uint32_t value; __asm__ volatile("csrr %0, 0xB88":"=r"(value)); return value; }
static void write_mcctr(uint32_t value) { __asm__ volatile("csrw 0xB88, %0"::"r"(value)); }

#if NPU_VERBOSE
static void log_putsdec(uint32_t value)
{ if((value&0x80000000u)!=0u){log_putc('-');log_putdec(0u-value);}else log_putdec(value); }
#endif

static void log_name(const struct cam_run *s)
{ log_puts(s->camera.id==1u?"CAM1":"CAM2"); }

/* 从 256 位记录（w[0] 是最低 32 位）取 [lsb, lsb+width) 位，width 不超过 32。 */
static uint32_t field(const uint32_t *w,uint32_t lsb,uint32_t width)
{
    uint32_t index=lsb>>5,shift=lsb&31u,value=w[index]>>shift;
    if(shift!=0u&&shift+width>32u)value|=w[index+1u]<<(32u-shift);
    return width>=32u?value:value&((1u<<width)-1u);
}

/* 布局见 soc/Hnpu_image_service.v 的 result_record；框是前处理的 {y1,x1,y0,x0}，含端点。 */
static void decode_result(const uint32_t *w,struct npu_result *r)
{
    r->camera=field(w,0u,8u);
    r->frame=field(w,8u,32u);
    r->roi=field(w,41u,8u);
    r->x0=field(w,49u,16u);
    r->y0=field(w,65u,16u);
    r->x1=field(w,81u,16u);
    r->y1=field(w,97u,16u);
    r->color=field(w,113u,3u);
    r->cls=field(w,116u,8u);
    r->confidence=field(w,124u,16u);
    r->error=field(w,140u,8u);
    r->score=field(w,148u,32u);
    r->reject=field(w,180u,1u);
}

#if NPU_VERBOSE
/* reject=1 表示最高分和第二名差距低于模型门槛，按未知处理。 */
static enum verdict verdict_of(const struct npu_result *r)
{
    if(r->error!=0u||r->cls>=CLASS_COUNT)return VERDICT_ERROR;
    if(r->reject!=0u||r->cls==1u)return VERDICT_UNKNOWN;
    if(r->cls==0u)return VERDICT_BACKGROUND;
    return VERDICT_SIGN;
}

static void print_result(const struct npu_result *r,enum verdict v)
{
    log_puts("NPU cam=");log_putdec(r->camera);
    log_puts(" frame=");log_putdec(r->frame);
    log_puts(" roi=");log_putdec(r->roi);
    log_puts(" result=");
    if(v==VERDICT_ERROR)log_puts("error");
    else if(v==VERDICT_UNKNOWN)log_puts("unknown");
    else log_puts(class_names[r->cls]);
    log_puts(" class=");log_putdec(r->cls);
    log_puts(" reject=");log_putdec(r->reject);
    log_puts(" conf=");log_putdec(r->confidence);
    log_puts(" score=");log_putsdec(r->score);
    log_puts(" err=");log_putdec(r->error);
    log_puts(" color=");log_puts(color_names[r->color&7u]);
    log_puts(" box=");log_putdec(r->x0);log_putc(',');log_putdec(r->y0);
    log_putc(',');log_putdec(r->x1);log_putc(',');log_putdec(r->y1);
    log_putc('\n');
}

/* 每轮最多取一条，队头不空就读 6 个字（第 181 位以上全是 0）再弹出。 */
static void poll_result(struct npu_stats *n)
{
    uint32_t w[6],i; struct npu_result r; enum verdict v;
    if((NPU_RESULT_STATUS&RESULT_EMPTY)!=0u)return;
    for(i=0u;i<6u;++i)w[i]=NPU_RESULT_DATA(i);
    NPU_RESULT_POP=1u;
    decode_result(w,&r);
    v=verdict_of(&r);
    ++n->total;++n->sec;
    if(r.cls<CLASS_COUNT)++n->per_class[r.cls];
    if(v==VERDICT_SIGN)++n->sign;
    else if(v==VERDICT_UNKNOWN)++n->unknown;
    else if(v==VERDICT_BACKGROUND)++n->background;
    else ++n->error;
    if(v==VERDICT_BACKGROUND&&!NPU_PRINT_BACKGROUND)return;
    if(uart_async_free()<LINE_RESERVE){++n->unprinted;return;}
    print_result(&r,v);
}

static void report_npu(const struct npu_stats *n,uint32_t seconds)
{
    uint32_t status=NPU_RESULT_STATUS,i;
    log_puts("STAT t=");log_putdec(seconds);
    log_puts(" npu_sec=");log_putdec(n->sec);
    log_puts(" npu_total=");log_putdec(n->total);
    log_puts(" sign=");log_putdec(n->sign);
    log_puts(" unknown=");log_putdec(n->unknown);
    log_puts(" background=");log_putdec(n->background);
    log_puts(" error=");log_putdec(n->error);
    log_puts(" unprinted=");log_putdec(n->unprinted);
    log_puts(" queue=");log_putdec(status&RESULT_COUNT_MASK);
    log_puts(" queue_status=");log_puthex(status);
    log_puts(" npu_err=");log_puthex(NPU_RESULT_ERROR_CODE);
    log_puts(" classes=");
    for(i=0u;i<CLASS_COUNT;++i){if(i!=0u)log_putc('/');log_putdec(n->per_class[i]);}
    log_putc('\n');
}

static void report_int8(void)
{
    uint32_t id;
    log_puts("INT8 ctrl=");log_puthex(INT8_REG(SOC_INT8_CTRL_OFFSET));
    log_puts(" status=");log_puthex(INT8_REG(SOC_INT8_STATUS_OFFSET));
    for(id=1u;id<=2u;++id){
        log_puts(id==1u?" cam1":" cam2");
        log_puts(" images=");log_putdec(INT8_STAT(id,SOC_INT8_IMAGES_DONE_OFFSET));
        log_puts(" usage=");log_putdec(INT8_STAT(id,SOC_INT8_USAGE_OFFSET));
        log_puts(" peak=");log_putdec(INT8_STAT(id,SOC_INT8_PEAK_USAGE_OFFSET));
        log_puts(" failed=");log_putdec(INT8_STAT(id,SOC_INT8_FAILED_BATCHES_OFFSET));
        log_puts(" ddr_err=");log_putdec(INT8_STAT(id,SOC_INT8_DDR_ERROR_COUNT_OFFSET));
        log_puts(" bad_release=");log_putdec(INT8_STAT(id,SOC_INT8_BAD_RELEASE_OFFSET));
    }
    log_putc('\n');
}

static void report_camera(struct cam_run *s)
{
    uint32_t errors;
    log_name(s);
    if(s->config_failed){log_puts(" state=FAILED_CONFIG\n");return;}
    if(!cam_snapshot(&s->camera,&s->latest,20000u)){
        ++s->snapshot_timeouts;
        log_puts(" SNAPSHOT_TIMEOUT ctl=");log_puthex(s->latest.snapshot_control);
        log_puts(" count=");log_putdec(s->snapshot_timeouts);log_putc('\n');
        return;
    }
    errors=s->latest.status&SOC_CAM_STATUS_ERROR_MASK;
    log_puts(" dvp_frames=");log_putdec(s->latest.dvp_frames);
    log_puts(" sec_dvp=");log_putdec(s->latest.dvp_frames-s->last_dvp);
    log_puts(" dma_frames=");log_putdec(s->latest.frame_count);
    log_puts(" sec_dma=");log_putdec(s->latest.frame_count-s->last_dma);
    log_puts(" drop=");log_putdec(s->latest.dropped);
    log_puts(" lines=");log_putdec(s->latest.lines);
    log_puts(" bytes=");log_putdec(s->latest.bytes);
    log_puts(" fifo_peak=");log_putdec(s->latest.fifo_max);
    log_puts(" status=");log_puthex(s->latest.status);
    log_puts(" errors=");log_puthex(errors);
    log_puts(" dvp_err=");log_puthex(s->latest.dvp_flags);
    log_puts(" dma_code=");log_putdec(s->latest.dma_code);
    log_puts(" ready=");log_puthex(s->latest.ready_mask);
    log_puts(" state=");
    if(s->latest.pclk_count==0u)log_puts("FAILED_NO_PCLK");
    else if(s->latest.frame_count==0u)log_puts("FAILED_NO_FRAME");
    else log_puts("RUNNING");
    log_putc('\n');
    s->last_dvp=s->latest.dvp_frames;s->last_dma=s->latest.frame_count;
}
#else
static uint32_t put_len(const char *text)
{ uint32_t n=0u; while(text[n]!='\0')log_putc(text[n++]); return n; }

static uint32_t model_ok(void) { return MODEL_WORD(0x00u)==MODEL_MAGIC; }

/* 错误码见 soc/Hnpu_cnn_engine.v 的 ERR_*。 */
static const char *npu_error_name(uint32_t code)
{
    static const char *const engine[6]={"?","bad config","DDR read resp","DDR read id","DDR read last","range"};
    static const char *const model[9]={"model magic","model version","model format","model CRC",
        "model layer","model shape","unsupported op","tensor range","model quant"};
    if(code<6u)return engine[code];
    if(code>=0x20u&&code<0x29u)return model[code-0x20u];
    return "?";
}

static enum shown shown_of(const struct npu_result *r)
{
    if(r->error!=0u||r->cls>=CLASS_COUNT)return SHOWN_ERROR;
    if(r->cls==0u)return SHOWN_BACKGROUND;
    if(r->reject!=0u)return SHOWN_UNSURE;
    return r->cls==1u?SHOWN_OTHER:SHOWN_SIGN;
}

/* 标记 摄像头 路标名 conf= frame= 颜色 box=x0,y0,x1,y1；conf 是第一名比第二名高出的分数。 */
static void print_result(const struct npu_result *r,enum shown k)
{
    uint32_t n=0u;
    log_puts(shown_tags[k]);log_puts("CAM");log_putdec(r->camera);log_putc(' ');
    if(k==SHOWN_ERROR){
        log_puts("NPU error ");log_putdec(r->error);
        log_puts(" (");log_puts(r->error!=0u?npu_error_name(r->error):"bad class");log_putc(')');
    }else{
        if(k==SHOWN_UNSURE)n+=put_len(UNSURE_BEFORE);
        n+=put_len(sign_names[r->cls]);
        if(k==SHOWN_UNSURE)n+=put_len(UNSURE_AFTER);
        while(n<NAME_WIDTH){log_putc(' ');++n;}
        log_puts(" conf=");log_putdec(r->confidence);
    }
    log_puts(" frame=");log_putdec(r->frame);
    log_putc(' ');log_puts(color_names[r->color&7u]);
    log_puts(" box=");log_putdec(r->x0);log_putc(',');log_putdec(r->y0);
    log_putc(',');log_putdec(r->x1);log_putc(',');log_putdec(r->y1);
    log_putc('\n');
}

#if NPU_CONFIRM
/* 路标确认层的接线：只多打 ### 开头的行，上面 >>> ??? !!! 各行的内容不动。 */
#if NPU_NAMES_GBK
#define CF_SURE "\xc8\xb7\xb6\xa8"                                   /* 确定 */
#define CF_GONE "\xcf\xfb\xca\xa7"                                   /* 消失 */
#define CF_NOW "\xb5\xb1\xc7\xb0"                                    /* 当前 */
#define CF_NONE "\xce\xde"                                           /* 无 */
#define CF_OTHER "\xc6\xe4\xcb\xfb\xc2\xb7\xb1\xea"                  /* 其他路标 */
#else
#define CF_SURE "SURE"
#define CF_GONE "GONE"
#define CF_NOW "NOW"
#define CF_NONE "none"
#define CF_OTHER "OTHER SIGN"
#endif
/* 事件、NOW、VOTE 每行都不到 128 字节（含回车）。 */
#define CF_LINE_MIN 128u
#define CF_CYCLES_PER_MS (CPU_HZ/1000u)

/* 毫秒钟：mtime 差值累加，不足 1 ms 的余数留到下次。 */
static uint32_t cf_mt0,cf_ms,cf_rem;
/* proc：每路上一个帧号和本周期帧号变化次数；cf_proc 是上个周期定下的值，等 NOW 行用。 */
static uint32_t cf_frame[2],cf_count[2],cf_proc[2],cf_seen,cf_now_due;

static uint32_t ms_now(void)
{
    uint32_t mt=read_mtime(),d=mt-cf_mt0+cf_rem;
    cf_mt0=mt;
    cf_ms+=d/CF_CYCLES_PER_MS;
    cf_rem=d%CF_CYCLES_PER_MS;
    return cf_ms;
}

static const char *cf_name(uint32_t cls)
{ return cls==1u?CF_OTHER:sign_names[cls]; }

static void cf_put_tenths(uint32_t frames)
{
    uint32_t tenths=frames*10u/NPU_STAT_SECONDS;
    log_putdec(tenths/10u);log_putc('.');log_putdec(tenths%10u);
}

static void cf_start(void)
{
    sc_init();
    log_puts("### CONFIRM W=");log_putdec(SC_W_MS);
    log_puts(" H=");log_putdec(SC_H_MS);
    log_puts(" KD=");log_putdec(SC_KD);
    log_puts(" KS=");log_putdec(SC_KS);
    log_puts(" KDO=");log_putdec(SC_KDO);
    log_puts(" KSO=");log_putdec(SC_KSO);
    log_puts(" MINL=");log_putdec(SC_MIN_LONG);
    log_puts(" AR=");log_putdec(SC_MAX_AR);log_putc('\n');
    cf_mt0=read_mtime();
}

#if NPU_CONFIRM_TRACE
/* 仿真对拍用：先打一行票；串口放不下就等，既不丢这一行，也不挤掉后面的结果行。 */
static void cf_trace(uint32_t ms,const struct npu_result *r)
{
    if(uart_async_free()<LINE_RESERVE+CF_LINE_MIN)uart_async_flush_blocking();
    log_puts("### VOTE t=");log_putdec(ms);
    log_puts(" cam=");log_putdec(r->camera);
    log_puts(" cls=");log_putdec(r->cls);
    log_puts(" frame=");log_putdec(r->frame);
    log_puts(" conf=");log_putdec(r->confidence);
    log_puts(" rej=");log_putdec(r->reject);
    log_puts(" err=");log_putdec(r->error);
    log_puts(" box=");log_putdec(r->x0);log_putc(',');log_putdec(r->y0);
    log_putc(',');log_putdec(r->x1);log_putc(',');log_putdec(r->y1);
    log_putc('\n');
}
#endif

/* 每张结果都过一遍：记帧号变化，再喂确认层（不合格的它自己忽略）。 */
static void cf_result(const struct npu_result *r)
{
    uint32_t ms=ms_now(),i=r->camera-1u;
    if(i<2u&&((cf_seen&(1u<<i))==0u||cf_frame[i]!=r->frame)){cf_seen|=1u<<i;cf_frame[i]=r->frame;++cf_count[i];}
#if NPU_CONFIRM_TRACE
    cf_trace(ms,r);
#endif
    sc_feed(ms,r->camera,r->cls,r->frame,r->confidence,r->reject,r->error,r->x0,r->y0,r->x1,r->y1);
}

static void cf_period(void)
{
    uint32_t i;
    for(i=0u;i<2u;++i){cf_proc[i]=cf_count[i];cf_count[i]=0u;}
    cf_now_due=1u;
}

static void cf_print_event(const struct sc_event *e)
{
    uint32_t n;
    if(e->type==SC_EV_SURE){
        log_puts("### " CF_SURE " ");
        n=put_len(cf_name(e->cls));
        while(n<NAME_WIDTH){log_putc(' ');++n;}
        log_puts(" cam=");log_puts(e->cams==1u?"1":e->cams==2u?"2":"1+2");
        log_puts(" votes=");log_putdec(e->n1);log_putc('+');log_putdec(e->n2);
        log_puts(" conf=");log_putdec(e->conf);
    }else{
        log_puts("### " CF_GONE " ");log_puts(cf_name(e->cls));
        log_puts(" held=");log_putdec(e->held);
    }
    log_puts(" t=");log_putdec(e->t);log_putc('\n');
}

/* 当前确定的类（类号从小到大，最多 4 个，多的写 ,+N）和上个周期两路的处理帧率。 */
static void cf_print_now(void)
{
    uint32_t mask=sc_active_mask(),i,shown=0u,total=0u;
    log_puts("### " CF_NOW " ");
    for(i=1u;i<CLASS_COUNT;++i){
        if((mask&(1u<<i))==0u)continue;
        ++total;
        if(shown<4u){if(shown!=0u)log_putc(',');log_puts(cf_name(i));++shown;}
    }
    if(total==0u)log_puts(CF_NONE);
    else if(total>shown){log_puts(",+");log_putdec(total-shown);}
    log_puts(" | proc ");cf_put_tenths(cf_proc[0]);log_putc('/');cf_put_tenths(cf_proc[1]);log_puts(" fps");
    if(sc_lost()!=0u){log_puts(" lost=");log_putdec(sc_lost());}
    log_putc('\n');
}

/* 每圈：先追上时间；串口有余量就打一条队头事件，队列空了才轮到 NOW，所以 NOW 总和已打的 SURE/GONE 一致。 */
static void cf_service(void)
{
    struct sc_event e;
    sc_tick(ms_now());
    if(uart_async_free()<CF_LINE_MIN)return;
    if(sc_pop(&e))cf_print_event(&e);
    else if(cf_now_due){cf_now_due=0u;cf_print_now();}
}
#endif

/* 每轮最多取一条，队头不空就读 6 个字（第 181 位以上全是 0）再弹出。 */
static void poll_result(struct npu_stats *n)
{
    uint32_t w[6],i; struct npu_result r; enum shown k;
    if((NPU_RESULT_STATUS&RESULT_EMPTY)!=0u)return;
    for(i=0u;i<6u;++i)w[i]=NPU_RESULT_DATA(i);
    NPU_RESULT_POP=1u;
    decode_result(w,&r);
    k=shown_of(&r);
    ++n->kind[k];
    if(k==SHOWN_SIGN)++n->per_class[r.cls];
#if NPU_CONFIRM
    cf_result(&r);
#if NPU_QUIET
    if(k==SHOWN_SIGN||k==SHOWN_OTHER||k==SHOWN_UNSURE)return;
#endif
#endif
#if !NPU_PRINT_BACKGROUND
    if(k==SHOWN_BACKGROUND)return;
#endif
    if(uart_async_free()<LINE_RESERVE){++n->unprinted;return;}
    print_result(&r,k);
}

static void warn_model(void)
{
    log_puts("!!! NO MODEL in DDR (magic=");log_puthex(MODEL_WORD(0x00u));
    log_puts("): burn the whole " FLASH_IMAGE " (CPU program + model) at Flash 0x00A00000;"
             " the 16 KB .bin has no model\n");
}

static void print_legend(void)
{
    log_puts("OUTPUT >>> sign, ??? other sign or unsure, ");
#if NPU_PRINT_BACKGROUND
    log_puts("... background, ");
#endif
    log_puts("!!! error or warning");
    if(model_ok()){log_puts("; conf = lead over 2nd class, unsure below ");log_putdec(MODEL_WORD(0x4cu));}
    log_puts("; summary every ");log_putdec(NPU_STAT_SECONDS);log_puts("s\n");
}

/* 本周期摄像头收到的帧（dvp）和进了缓存的帧（dma）；返回 0 没开起来，1 读快照超时，2 正常。 */
static uint32_t sample_camera(struct cam_run *s,uint32_t *dvp,uint32_t *dma)
{
    if(!s->streaming)return 0u;
    if(!cam_snapshot(&s->camera,&s->latest,20000u)){++s->snapshot_timeouts;return 1u;}
    *dvp=s->latest.dvp_frames-s->last_dvp;*dma=s->latest.frame_count-s->last_dma;
    s->last_dvp=s->latest.dvp_frames;s->last_dma=s->latest.frame_count;
    return 2u;
}

static void put_rate(uint32_t frames)
{
    uint32_t tenths=frames*10u/NPU_STAT_SECONDS;
    log_putdec(tenths/10u);log_putc('.');log_putdec(tenths%10u);log_puts("fps");
}

/* 摄像头收不到帧，或者收到了却一帧都进不了缓存（后级卡住），打一行原因和相关计数。 */
static void warn_camera(const struct cam_run *s,uint32_t state,uint32_t dvp,uint32_t dma)
{
    uint32_t id=s->camera.id;
    if(state==2u&&s->latest.pclk_count!=0u&&dvp!=0u&&dma!=0u)return;
    log_puts("!!! ");log_name(s);
    if(state==0u)log_puts(" not running: OV5640 not found or config failed at boot, check cable/power and reset");
    else if(state==1u){log_puts(" status snapshot timed out, count=");log_putdec(s->snapshot_timeouts);}
    else if(s->latest.pclk_count==0u)log_puts(" no PCLK from the sensor");
    else if(dvp==0u){log_puts(" no frames from the sensor in ");log_putdec(NPU_STAT_SECONDS);log_putc('s');}
    else{
        log_puts(" stuck: sensor sent ");log_putdec(dvp);log_puts(" frames in ");log_putdec(NPU_STAT_SECONDS);
        log_puts("s, none reached the buffers (dma_frames=");log_putdec(s->latest.frame_count);
        log_puts(" drop=");log_putdec(s->latest.dropped);
        log_puts(" ready=");log_puthex(s->latest.ready_mask);
        log_puts(" dma_code=");log_putdec(s->latest.dma_code);
        log_puts("; INT8 status=");log_puthex(INT8_REG(SOC_INT8_STATUS_OFFSET));
        log_puts(" images=");log_putdec(INT8_STAT(id,SOC_INT8_IMAGES_DONE_OFFSET));
        log_puts(" usage=");log_putdec(INT8_STAT(id,SOC_INT8_USAGE_OFFSET));
        log_puts(" failed=");log_putdec(INT8_STAT(id,SOC_INT8_FAILED_BATCHES_OFFSET));
        log_putc(')');
    }
    log_putc('\n');
}

/* INT8 失败、DDR 错误、错误释放计数一涨就报，带最后一次失败的帧号和原因（Hrgb565_int8_lane.v）。 */
static void warn_int8(void)
{
    static uint32_t seen[2];
    static const char *const causes[5]={"?","bad descriptor","DDR read error","DDR write error","timeout"};
    uint32_t id,failed,ddr,bad,info,cause;
    for(id=1u;id<=2u;++id){
        failed=INT8_STAT(id,SOC_INT8_FAILED_BATCHES_OFFSET);
        ddr=INT8_STAT(id,SOC_INT8_DDR_ERROR_COUNT_OFFSET);
        bad=INT8_STAT(id,SOC_INT8_BAD_RELEASE_OFFSET);
        if(failed+ddr+bad==seen[id-1u])continue;
        seen[id-1u]=failed+ddr+bad;
        log_puts("!!! INT8 cam");log_putdec(id);
        log_puts(" failed=");log_putdec(failed);
        log_puts(" ddr_err=");log_putdec(ddr);
        log_puts(" bad_release=");log_putdec(bad);
        if(failed!=0u){
            info=INT8_STAT(id,SOC_INT8_LAST_FAILURE_INFO_OFFSET);cause=(info>>8)&0xffu;
            log_puts(", last failure frame ");log_putdec(INT8_STAT(id,SOC_INT8_LAST_FAILURE_FRAME_OFFSET));
            if((info&0xffu)!=0xffu){log_puts(" box ");log_putdec(info&0xffu);}
            log_puts(" cause ");log_putdec(cause);
            log_puts(" (");log_puts(causes[cause<5u?cause:0u]);log_putc(')');
        }
        log_putc('\n');
    }
}

static void report_period(struct npu_stats *n,struct cam_run *a,struct cam_run *b,uint32_t seconds)
{
    struct cam_run *cam[2]={a,b};
    uint32_t state[2],dvp[2]={0u,0u},dma[2]={0u,0u},i,first=1u,err;
    for(i=0u;i<2u;++i)state[i]=sample_camera(cam[i],&dvp[i],&dma[i]);
    log_puts("--- t=");log_putdec(seconds);log_putc('s');
    for(i=0u;i<2u;++i){
        log_puts(i==0u?" cam1 ":" cam2 ");
        if(state[i]==0u)log_puts("FAILED");
        else if(state[i]==1u)log_puts("no-status");
        else put_rate(dvp[i]);
    }
    log_puts(" | last ");log_putdec(NPU_STAT_SECONDS);log_putc('s');
    for(i=0u;i<SHOWN_KINDS;++i){log_putc(i==0u?':':',');log_putc(' ');log_puts(shown_labels[i]);log_putc(' ');log_putdec(n->kind[i]);}
    if(n->unprinted!=0u){log_puts(", not printed ");log_putdec(n->unprinted);}
    for(i=2u;i<CLASS_COUNT;++i){
        if(n->per_class[i]==0u)continue;
        log_puts(first?" | seen ":", ");first=0u;
        log_puts(sign_names[i]);log_puts(" x");log_putdec(n->per_class[i]);
    }
    if(!model_ok())log_puts(" | NO MODEL");
    log_putc('\n');
    if(!model_ok())warn_model();
    for(i=0u;i<2u;++i)warn_camera(cam[i],state[i],dvp[i],dma[i]);
    warn_int8();
    err=NPU_RESULT_ERROR_CODE;
    if(err!=n->npu_err){
        n->npu_err=err;
        if(err!=0u){log_puts("!!! NPU error register ");log_puthex(err);log_putc('\n');}
    }
    for(i=0u;i<SHOWN_KINDS;++i)n->kind[i]=0u;
    for(i=0u;i<CLASS_COUNT;++i)n->per_class[i]=0u;
    n->unprinted=0u;
}
#endif

static void report_model(void)
{
    uint32_t magic=MODEL_WORD(0x00u);
    log_puts("MODEL base=");log_puthex(SOC_NPU_WEIGHT_BASE);
    log_puts(" magic=");log_puthex(magic);
    if(magic!=MODEL_MAGIC){log_puts(" MODEL=BAD_MAGIC\n");return;}
    log_puts(" classes=");log_putdec((MODEL_WORD(0x14u)>>16)&0xffu);
    log_puts(" bytes=");log_putdec(MODEL_WORD(0x30u));
    log_puts(" crc=");log_puthex(MODEL_WORD(0x40u));
    log_puts(" reject_margin=");log_putdec(MODEL_WORD(0x4cu));
    log_putc('\n');
}

static void report_config(struct cam_run *s)
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
    struct cam_run a={0},b={0}; struct npu_stats n={0};
    uint32_t next,seconds=0u,drop_notice=0u;
    uint8_t uart_pin=STEREO_UART_TX_FPIOA;
    uart_async_init(115200u,uart_pin);
    log_puts("=== Road Sign NPU Pipeline ===\n");
    log_puts("NPU_PIPELINE BOOT\nCPU CLOCK=");log_putdec(system_cpu_freq);
    log_puts(" UART=115200 TX_FPIOA=");log_putdec(uart_pin);
    log_puts(" PRINT_BACKGROUND=");log_putdec(NPU_PRINT_BACKGROUND);log_putc('\n');
    report_model();
#if !NPU_VERBOSE
    if(!model_ok())warn_model();
#endif
    cam_init(&a.camera,SOC_CAM1_MMIO_BASE,SOC_CAM1_BUFFER0_BASE,SOC_CAM1_BUFFER1_BASE,1u);
    cam_init(&b.camera,SOC_CAM2_MMIO_BASE,SOC_CAM2_BUFFER0_BASE,SOC_CAM2_BUFFER1_BASE,2u);
    report_config(&a);report_config(&b);
    uart_async_flush_blocking();
    /* CSR B88 bit2 开启 0xB03 mtime，每个 CPU 周期加一。 */
    write_mcctr(read_mcctr() | (1u<<2));
    if(a.configured){cam_dma_enable(&a.camera,true);cam_capture_enable(&a.camera,true);a.streaming=1u;}
    if(b.configured){cam_dma_enable(&b.camera,true);cam_capture_enable(&b.camera,true);b.streaming=1u;}
    log_puts("INT8 ctrl=");log_puthex(INT8_REG(SOC_INT8_CTRL_OFFSET));
    log_puts(" status=");log_puthex(INT8_REG(SOC_INT8_STATUS_OFFSET));log_putc('\n');
    log_puts("NPU_PIPELINE CAPTURE_STARTED\n");
#if !NPU_VERBOSE
    print_legend();
#endif
#if NPU_CONFIRM && !NPU_VERBOSE
    cf_start();
#endif
#if NPU_SWEEP
    sweep_init(&a.camera,&b.camera,a.streaming,b.streaming);
#endif
    next=read_mtime()+REPORT_CYCLES;
    for(;;){
#if NPU_CONFIRM && !NPU_VERBOSE
        cf_service();
#endif
        poll_result(&n);
        if((uint32_t)(read_mtime()-next)<0x80000000u){
#if NPU_VERBOSE
            ++seconds;
            report_npu(&n,seconds);report_int8();report_camera(&a);report_camera(&b);
            n.sec=0u;
#else
            seconds+=NPU_STAT_SECONDS;
            report_period(&n,&a,&b,seconds);
#if NPU_CONFIRM
            cf_period();
#endif
#endif
            next+=REPORT_CYCLES;
        }
        if(uart_async_dropped()!=drop_notice){drop_notice=uart_async_dropped();log_puts("LOG_DROPPED=");log_putdec(drop_notice);log_putc('\n');}
#if NPU_SWEEP
        sweep_step();
#endif
        uart_async_service();
    }
}
