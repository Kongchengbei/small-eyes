#include "camera_stereo.h"
#include "../camera_app/ov5640_regs.h"
#include "../include/soc_defs.h"
#include "uart_async.h"

#ifndef CAM1_SENSOR_COLORBAR
#define CAM1_SENSOR_COLORBAR 0
#endif

#if (CAM1_SENSOR_COLORBAR != 0) && (CAM1_SENSOR_COLORBAR != 1)
#error "CAM1_SENSOR_COLORBAR must be 0 or 1"
#endif

#define REG(cam, off) (*(volatile uint32_t *)((cam)->base + (off)))
#define CTRL_RESET_N SOC_CAM_SCCB_RESET_N_MASK
#define CTRL_SCL_RELEASE SOC_CAM_SCCB_SCL_RELEASE_MASK
#define CTRL_SDA_RELEASE SOC_CAM_SCCB_SDA_RELEASE_MASK
#define CTRL_CAPTURE SOC_CAM_SCCB_CAPTURE_ENABLE_MASK
#define STATUS_SDA SOC_CAM_SCCB_STATUS_SDA_MASK
#define SNAP_BUSY SOC_CAM_SNAPSHOT_BUSY_MASK
#define SNAP_VALID SOC_CAM_SNAPSHOT_VALID_MASK
#define SNAP_TIMEOUT SOC_CAM_SNAPSHOT_TIMEOUT_MASK
#define RELEASE_BUSY SOC_CAM_RELEASE_BUSY_MASK
#define FRAME_BYTES 614400u

//图像亮度偏移 0x5587、0x5588 在摄像头内部 ISP 中提亮或压暗图像
//自动曝光目标 | 0x3A0F、0x3A10、0x3A1B、0x3A1E、0x3A11、0x3A1F | 让自动曝光调整曝光时间、增益，使画面达到目标亮度 |
struct verify_reg { uint16_t address; uint8_t expected, mask; };
static const struct verify_reg verify_regs[] = {
    {0x3008u,0x02u,0x42u},{0x300eu,0x58u,0xffu},
    {0x3035u,0x21u,0xffu},{0x3036u,0x46u,0xffu},
    {0x3808u,0x02u,0x0fu},{0x3809u,0x80u,0xffu},
    {0x380au,0x01u,0x07u},{0x380bu,0xe0u,0xffu},
    {0x4740u,0x20u,0x23u},{0x4300u,0x61u,0xffu},
    {0x501fu,0x01u,0x07u}
};

static void write_ctrl(struct camera_ctx *cam) { REG(cam, SOC_CAM_SCCB_CONTROL_OFFSET) = cam->ctrl_shadow; }
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
static bool read_sda(struct camera_ctx *cam) { return (REG(cam,SOC_CAM_SCCB_STATUS_OFFSET)&STATUS_SDA)!=0u; }
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
{ uint32_t i;
	for(i=0u;i<3u;++i){
		if(cam_write_reg(cam,reg,val))
			return true;
		cam_delay_ms(1u);
	}
	return false;
}

bool cam_configure_vga(struct camera_ctx *cam,uint16_t *failed,uint32_t *writes)
{
    uint32_t i;uint8_t value,orientation_v,orientation_h,colorbar;
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
	/*	|  位  | 0x3820 的意义      | 0x3821 的意义 |
		|------|--------------------|--------------|
		| bit7 | 调试模式位         | 调试模式位     |
		| bit6 | 调试模式位         | 调试模式位     |
		| bit5 | 调试模式位         | JPEG 使能 	|
		| bit4 | 调试模式位         | 调试模式位 	|
		| bit3 | 调试模式位         | 调试模式位 	|
		| bit2 | 内置 ISP 垂直翻转  | 内置 ISP 水平镜像 
		| bit1 | 传感器垂直翻转     | 传感器水平镜像 |
		| bit0 | 该表没有公开说明   | 水平像素合并（binning）使能 |*/
	//orientation_v，用于寄存器 0x3820
	//orientation_h，用于寄存器 0x3821
	orientation_v=(cam->id==1u)?0x47u:0x41u;
    orientation_h=(cam->id==1u)?0x01u:0x07u;
    if(cam->id==1u){
        if(!write_retry(cam,0x3820u,orientation_v)){*failed=0x3820u;return false;}++*writes;
        if(!write_retry(cam,0x3821u,orientation_h)){*failed=0x3821u;return false;}++*writes;
    }
    colorbar=0u;
#if CAM1_SENSOR_COLORBAR
    if(cam->id==1u)colorbar=0x84u;
#endif
    if(!write_retry(cam,0x503du,colorbar))
		{*failed=0x503du;return false;}++*writes;

    if(!cam_read_reg(cam,0x3820u,&value)){*failed=0x3820u;return false;}
    if(value!=orientation_v){*failed=0x3820u;return false;}
    if(!cam_read_reg(cam,0x3821u,&value)){*failed=0x3821u;return false;}
    if(value!=orientation_h){*failed=0x3821u;return false;}
    if(!cam_read_reg(cam,0x503du,&value)){*failed=0x503du;return false;}
    if(value!=colorbar){*failed=0x503du;return false;}

    log_puts(cam->id==1u?"CAM1_ORIENTATION=180 3820=":"CAM2_ORIENTATION=DEFAULT 3820=");
    log_puthex(orientation_v);log_puts(" 3821=");log_puthex(orientation_h);
    log_puts(" COLORBAR_503D=");log_puthex(colorbar);log_putc('\n');
    return true;
}

bool cam_snapshot(struct camera_ctx *cam,struct cam_snapshot *s,uint32_t timeout)
{
    uint32_t ctl; if(s==0)return false;REG(cam,SOC_CAM_SNAPSHOT_CTRL)=SOC_CAM_SNAPSHOT_START_MASK;s->snapshot_control=0u;
    while(timeout--!=0u){ctl=REG(cam,SOC_CAM_SNAPSHOT_CTRL);s->snapshot_control=ctl;if(ctl&SNAP_TIMEOUT)return false;
        if((ctl&SNAP_BUSY)==0u&&(ctl&SNAP_VALID)!=0u){
            s->frame_count=REG(cam,SOC_CAM_FRAME_COUNT);s->pixels=REG(cam,SOC_CAM_PIXEL_COUNT);s->pclk_count=REG(cam,SOC_CAM_PCLK_COUNT);s->error_flags=REG(cam,SOC_CAM_ERROR_FLAGS);
            s->lines=REG(cam,SOC_CAM_LINE_COUNT);s->status=REG(cam,SOC_CAM_STATUS);s->bytes=REG(cam,SOC_CAM_BYTE_COUNT);s->fifo_level=REG(cam,SOC_CAM_FIFO_LEVEL);s->fifo_max=REG(cam,SOC_CAM_FIFO_MAX_LEVEL);
            s->fifo_error=REG(cam,SOC_CAM_FIFO_ERROR);s->dma_status=REG(cam,SOC_CAM_DMA_STATUS);s->dma_code=REG(cam,SOC_CAM_DMA_ERROR_CODE);s->frame_addr=REG(cam,SOC_CAM_LAST_FRAME_ADDR);
            s->write_buffer=REG(cam,SOC_CAM_CURRENT_WRITE_BUFFER);s->complete_buffer=REG(cam,SOC_CAM_LAST_COMPLETE_BUFFER);s->hw_sum16=REG(cam,SOC_CAM_FRAME_CHECKSUM);s->ready_mask=REG(cam,SOC_CAM_READY_MASK);
            s->dropped=REG(cam,SOC_CAM_DROPPED_FRAMES);s->sequence=REG(cam,SOC_CAM_SNAPSHOT_SEQUENCE);s->dvp_frames=REG(cam,SOC_CAM_DVP_FRAME_COUNT);s->dvp_flags=REG(cam,SOC_CAM_DVP_ERROR_FLAGS);
            s->current_pixels=REG(cam,SOC_CAM_CURRENT_PIXEL_COUNT);s->current_bytes=REG(cam,SOC_CAM_CURRENT_BYTE_COUNT);s->current_lines=REG(cam,SOC_CAM_CURRENT_LINE_COUNT);return true;
        }
    }
    s->snapshot_control=REG(cam,SOC_CAM_SNAPSHOT_CTRL);return false;
}

bool cam_release(struct camera_ctx *cam,uint32_t mask)
{
    uint32_t timeout=100000u;while((REG(cam,SOC_CAM_BUFFER_RELEASE)&RELEASE_BUSY)!=0u&&timeout--!=0u){}
    if(timeout==0u)return false;REG(cam,SOC_CAM_BUFFER_RELEASE)=mask&SOC_CAM_BUFFER_RELEASE_MASK;timeout=100000u;
    while((REG(cam,SOC_CAM_BUFFER_RELEASE)&RELEASE_BUSY)!=0u&&timeout--!=0u){}return (REG(cam,SOC_CAM_BUFFER_RELEASE)&RELEASE_BUSY)==0u;
}
void cam_capture_enable(struct camera_ctx *cam,bool enable)
{ if(enable)cam->ctrl_shadow|=CTRL_CAPTURE;else cam->ctrl_shadow&=~CTRL_CAPTURE;write_ctrl(cam); }
void cam_dma_enable(struct camera_ctx *cam,bool enable) { REG(cam,SOC_CAM_DMA_CONTROL)=enable?SOC_CAM_DMA_ENABLE_MASK:0u; }
