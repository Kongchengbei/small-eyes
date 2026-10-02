#include "camera_stereo.h"
#include "../camera_app/ov5640_regs.h"

#define REG(cam, off) (*(volatile uint32_t *)((cam)->base + (off)))
#define CTRL_RESET_N (1u << 0)
#define CTRL_SCL_RELEASE (1u << 1)
#define CTRL_SDA_RELEASE (1u << 2)
#define CTRL_CAPTURE (1u << 3)
#define STATUS_SDA (1u << 2)
#define SNAP_BUSY 1u
#define SNAP_VALID 2u
#define SNAP_TIMEOUT 4u
#define RELEASE_BUSY 1u
#define FRAME_BYTES 614400u

struct verify_reg { uint16_t address; uint8_t expected, mask; };
static const struct verify_reg verify_regs[] = {
    {0x3008u,0x02u,0x42u},{0x300eu,0x58u,0xffu},
    {0x3035u,0x21u,0xffu},{0x3036u,0x46u,0xffu},
    {0x3808u,0x02u,0x0fu},{0x3809u,0x80u,0xffu},
    {0x380au,0x01u,0x07u},{0x380bu,0xe0u,0xffu},
    {0x4740u,0x20u,0x23u},{0x4300u,0x61u,0xffu},
    {0x501fu,0x01u,0x07u}
};

static void write_ctrl(struct camera_ctx *cam) { REG(cam, 0x00u) = cam->ctrl_shadow; }
static void delay_bus(void) { volatile uint32_t i; for (i=0u;i<16u;++i) __asm__ volatile("nop"); }
void cam_delay_ms(uint32_t ms) { uint32_t i; for(i=0u;i<ms*900u;++i) delay_bus(); }

void cam_init(struct camera_ctx *cam,uint32_t base,uint32_t b0,uint32_t b1,uint32_t id)
{
    cam->base=base; cam->buffer0=b0; cam->buffer1=b1; cam->id=id;
    cam->ctrl_shadow=CTRL_SCL_RELEASE|CTRL_SDA_RELEASE;
}

void cam_sccb_init(struct camera_ctx *cam)
{
    cam->ctrl_shadow=CTRL_SCL_RELEASE|CTRL_SDA_RELEASE; write_ctrl(cam);
    cam_delay_ms(5u); cam->ctrl_shadow|=CTRL_RESET_N; write_ctrl(cam); cam_delay_ms(22u);
}

static void scl(struct camera_ctx *cam,bool up)
{ if(up) cam->ctrl_shadow|=CTRL_SCL_RELEASE; else cam->ctrl_shadow&=~CTRL_SCL_RELEASE; write_ctrl(cam); }
static void sda(struct camera_ctx *cam,bool up)
{ if(up) cam->ctrl_shadow|=CTRL_SDA_RELEASE; else cam->ctrl_shadow&=~CTRL_SDA_RELEASE; write_ctrl(cam); }
static bool read_sda(struct camera_ctx *cam) { return (REG(cam,0x04u)&STATUS_SDA)!=0u; }
static void start(struct camera_ctx *cam)
{ sda(cam,true); scl(cam,true); delay_bus(); sda(cam,false); delay_bus(); scl(cam,false); delay_bus(); }
static void stop(struct camera_ctx *cam)
{ sda(cam,false); delay_bus(); scl(cam,true); delay_bus(); sda(cam,true); delay_bus(); }
static bool write_byte(struct camera_ctx *cam,uint8_t val)
{
    uint32_t i; bool ack;
    for(i=0u;i<8u;++i){sda(cam,(val&0x80u)!=0u);delay_bus();scl(cam,true);delay_bus();scl(cam,false);delay_bus();val<<=1;}
    sda(cam,true);delay_bus();scl(cam,true);delay_bus();ack=!read_sda(cam);scl(cam,false);delay_bus();return ack;
}
static uint8_t read_byte(struct camera_ctx *cam)
{
    uint32_t i; uint8_t val=0u; sda(cam,true);
    for(i=0u;i<8u;++i){val<<=1;scl(cam,true);delay_bus();if(read_sda(cam))val|=1u;scl(cam,false);delay_bus();}
    sda(cam,true);delay_bus();scl(cam,true);delay_bus();scl(cam,false);sda(cam,true);delay_bus();return val;
}
bool cam_write_reg(struct camera_ctx *cam,uint16_t reg,uint8_t val)
{
    bool ok; start(cam);ok=write_byte(cam,0x78u);ok=write_byte(cam,(uint8_t)(reg>>8))&&ok;
    ok=write_byte(cam,(uint8_t)reg)&&ok;ok=write_byte(cam,val)&&ok;stop(cam);return ok;
}
bool cam_read_reg(struct camera_ctx *cam,uint16_t reg,uint8_t *val)
{
    bool ok; if(val==0)return false;start(cam);ok=write_byte(cam,0x78u);
    ok=write_byte(cam,(uint8_t)(reg>>8))&&ok;ok=write_byte(cam,(uint8_t)reg)&&ok;
    start(cam);ok=write_byte(cam,0x79u)&&ok;*val=read_byte(cam);stop(cam);return ok;
}
static bool write_retry(struct camera_ctx *cam,uint16_t reg,uint8_t val)
{ uint32_t i;for(i=0u;i<3u;++i){if(cam_write_reg(cam,reg,val))return true;cam_delay_ms(1u);}return false; }

bool cam_configure_vga(struct camera_ctx *cam,uint16_t *failed,uint32_t *writes)
{
    uint32_t i;uint8_t value;
    if(failed==0||writes==0)return false;
    *failed=0u;
    *writes=0u;
    if(!write_retry(cam,0x3103u,0x11u)){*failed=0x3103u;return false;}++*writes;
    if(!write_retry(cam,0x3008u,0x82u)){*failed=0x3008u;return false;}++*writes;cam_delay_ms(5u);
    for(i=0u;i<ov5640_vga_rgb565_reg_count;++i){
        if(!write_retry(cam,ov5640_vga_rgb565_regs[i].address,ov5640_vga_rgb565_regs[i].value)){*failed=ov5640_vga_rgb565_regs[i].address;return false;}++*writes;
    }
    for(i=0u;i<sizeof(verify_regs)/sizeof(verify_regs[0]);++i){
        if(!cam_read_reg(cam,verify_regs[i].address,&value)){*failed=verify_regs[i].address;return false;}
        if((value&verify_regs[i].mask)!=(verify_regs[i].expected&verify_regs[i].mask)){*failed=verify_regs[i].address;return false;}
    }
    return true;
}

bool cam_snapshot(struct camera_ctx *cam,struct cam_snapshot *s,uint32_t timeout)
{
    uint32_t ctl; if(s==0)return false;REG(cam,0x08u)=1u;s->snapshot_control=0u;
    while(timeout--!=0u){ctl=REG(cam,0x08u);s->snapshot_control=ctl;if(ctl&SNAP_TIMEOUT)return false;
        if((ctl&SNAP_BUSY)==0u&&(ctl&SNAP_VALID)!=0u){
            s->frame_count=REG(cam,0x0cu);s->pixels=REG(cam,0x10u);s->pclk_count=REG(cam,0x14u);s->error_flags=REG(cam,0x18u);
            s->lines=REG(cam,0x1cu);s->status=REG(cam,0x20u);s->bytes=REG(cam,0x24u);s->fifo_level=REG(cam,0x28u);s->fifo_max=REG(cam,0x2cu);
            s->fifo_error=REG(cam,0x30u);s->dma_status=REG(cam,0x34u);s->dma_code=REG(cam,0x38u);s->frame_addr=REG(cam,0x3cu);
            s->write_buffer=REG(cam,0x40u);s->complete_buffer=REG(cam,0x44u);s->hw_sum16=REG(cam,0x48u);s->ready_mask=REG(cam,0x4cu);
            s->dropped=REG(cam,0x50u);s->sequence=REG(cam,0x54u);s->dvp_frames=REG(cam,0x58u);s->dvp_flags=REG(cam,0x5cu);
            s->current_pixels=REG(cam,0x80u);s->current_bytes=REG(cam,0x84u);s->current_lines=REG(cam,0x88u);return true;
        }
    }
    s->snapshot_control=REG(cam,0x08u);return false;
}

bool cam_release(struct camera_ctx *cam,uint32_t mask)
{
    uint32_t timeout=100000u;while((REG(cam,0x60u)&RELEASE_BUSY)!=0u&&timeout--!=0u){}
    if(timeout==0u)return false;REG(cam,0x60u)=mask&3u;timeout=100000u;
    while((REG(cam,0x60u)&RELEASE_BUSY)!=0u&&timeout--!=0u){}return (REG(cam,0x60u)&RELEASE_BUSY)==0u;
}
void cam_capture_enable(struct camera_ctx *cam,bool enable)
{ if(enable)cam->ctrl_shadow|=CTRL_CAPTURE;else cam->ctrl_shadow&=~CTRL_CAPTURE;write_ctrl(cam); }
void cam_dma_enable(struct camera_ctx *cam,bool enable) { REG(cam,0x64u)=enable?1u:0u; }
