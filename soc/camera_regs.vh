`ifndef CAMERA_REGS_VH
`define CAMERA_REGS_VH
// CAM1 MMIO 偏移；0x00/0x04 的低位由 SCCB GPIO 保留。
`define CAM_SNAPSHOT_CTRL       8'h08
`define CAM_FRAME_COUNT         8'h0c
`define CAM_PIXEL_COUNT         8'h10
`define CAM_PCLK_COUNT          8'h14
`define CAM_ERROR_FLAGS         8'h18
`define CAM_LINE_COUNT          8'h1c
`define CAM_STATUS              8'h20
`define CAM_BYTE_COUNT          8'h24
`define CAM_FIFO_LEVEL          8'h28
`define CAM_FIFO_MAX_LEVEL      8'h2c
`define CAM_FIFO_ERROR          8'h30
`define CAM_DMA_STATUS          8'h34
`define CAM_DMA_ERROR_CODE      8'h38
`define CAM_LAST_FRAME_ADDR     8'h3c
`define CAM_CURRENT_WRITE_BUFFER 8'h40
`define CAM_LAST_COMPLETE_BUFFER 8'h44
`define CAM_FRAME_CHECKSUM      8'h48
`define CAM_READY_MASK          8'h4c
`define CAM_DROPPED_FRAMES       8'h50
`define CAM_SNAPSHOT_SEQUENCE   8'h54
`define CAM_DVP_FRAME_COUNT     8'h58
`define CAM_DVP_ERROR_FLAGS     8'h5c
`define CAM_BUFFER_RELEASE      8'h60
`define CAM_DMA_CONTROL         8'h64
`define CAM_BUFFER0_ADDR         8'h68
`define CAM_BUFFER1_ADDR         8'h6c
`define CAM_FRAME_BYTES          8'h70
`define CAM_FRAME_WIDTH          8'h74
`define CAM_FRAME_HEIGHT         8'h78
`define CAM_DDR_READY            8'h7c
`define CAM_CURRENT_PIXEL_COUNT  8'h80
`define CAM_CURRENT_BYTE_COUNT   8'h84
`define CAM_CURRENT_LINE_COUNT   8'h88

`define CAM_ERR_NONE             32'd0
`define CAM_ERR_FIFO_OVERFLOW    32'd1
`define CAM_ERR_UNEXPECTED_SOF   32'd2
`define CAM_ERR_UNEXPECTED_EOF   32'd3
`define CAM_ERR_BAD_PIXEL_COUNT  32'd4
`define CAM_ERR_DDR_TIMEOUT      32'd5
`define CAM_ERR_DDR_WRITE        32'd6
`define CAM_ERR_BAD_LINE_COUNT   32'd7
`define CAM_ERR_DVP              32'd8
`define CAM_ERR_NO_FREE_BUFFER   32'd9
`define CAM_ERR_BAD_CONFIG       32'd10
`define CAM_ERR_FIFO_UNDERFLOW   32'd11
`endif
