`timescale 1ns / 1ps
`include "../soc/soc_addr_map.vh"

// 物理 CAM1 的 OV5640 SCCB 软件模拟接口。
//
// SCL/SDA 均按开漏方式工作：软件写 1 表示释放线路，写 0 表示拉低。
// 摄像头模块提供上拉，FPGA 不主动输出高电平，避免与传感器应答冲突。
//
//   0x00 CONTROL (R/W, low byte)
//        bit 0  CAM1 RESETB output (0 = reset, 1 = run)
//        bit 1  SCL release       (0 = pull low, 1 = high-Z)
//        bit 2  SDA release       (0 = pull low, 1 = high-Z)
//        bit 3  DVP capture enable
//   0x04 STATUS (R)
//        bit 0  RESETB output
//        bit 1  synchronized SCL pin value
//        bit 2  synchronized SDA pin value
//        bit 3  SCL release request
//        bit 4  SDA release request
//        bit 5  DVP capture enable
module Hcamera_sccb_gpio (
    input         clk,
    input         rst_n,
    input         mmio_valid,
    input         mmio_wen,
    input  [7:0]  mmio_addr,
    input  [31:0] mmio_wdata,
    input  [3:0]  mmio_wmask,
    output reg [31:0] mmio_rdata,
    inout         cam1_scl,//Serial Clock Line
    inout         cam1_sda,//Serial Data Line
    output reg    cam1_reset_n,
    output reg    cam1_capture_enable
);
    reg scl_release;
    reg sda_release;
    reg scl_meta;
    reg scl_sync;
    reg sda_meta;
    reg sda_sync;

    assign cam1_scl = scl_release ? 1'bz : 1'b0;
    assign cam1_sda = sda_release ? 1'bz : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cam1_reset_n <= 1'b0;
            cam1_capture_enable <= 1'b0;
            scl_release  <= 1'b1;
            sda_release  <= 1'b1;
            scl_meta     <= 1'b1;
            scl_sync     <= 1'b1;
            sda_meta     <= 1'b1;
            sda_sync     <= 1'b1;
        end else begin
            scl_meta <= cam1_scl;
            scl_sync <= scl_meta;
            sda_meta <= cam1_sda;
            sda_sync <= sda_meta;

            if (mmio_valid && mmio_wen && (mmio_addr == `SOC_CAM_SCCB_CONTROL_OFFSET) &&
                mmio_wmask[0]) begin
                cam1_reset_n <= (mmio_wdata & `SOC_CAM_SCCB_RESET_N_MASK) != 0;
                scl_release  <= (mmio_wdata & `SOC_CAM_SCCB_SCL_RELEASE_MASK) != 0;
                sda_release  <= (mmio_wdata & `SOC_CAM_SCCB_SDA_RELEASE_MASK) != 0;
                cam1_capture_enable <= (mmio_wdata & `SOC_CAM_SCCB_CAPTURE_ENABLE_MASK) != 0;
            end
        end
    end

    always @(*) begin
        mmio_rdata = 32'b0;
        if (mmio_valid && !mmio_wen) begin
            case (mmio_addr)
                `SOC_CAM_SCCB_CONTROL_OFFSET: mmio_rdata =
                    (cam1_capture_enable ? `SOC_CAM_SCCB_CAPTURE_ENABLE_MASK : 32'b0) |
                    (sda_release ? `SOC_CAM_SCCB_SDA_RELEASE_MASK : 32'b0) |
                    (scl_release ? `SOC_CAM_SCCB_SCL_RELEASE_MASK : 32'b0) |
                    (cam1_reset_n ? `SOC_CAM_SCCB_RESET_N_MASK : 32'b0);
                `SOC_CAM_SCCB_STATUS_OFFSET: mmio_rdata =
                    (cam1_capture_enable ? `SOC_CAM_SCCB_STATUS_CAPTURE_MASK : 32'b0) |
                    (sda_release ? `SOC_CAM_SCCB_STATUS_SDA_RELEASE_MASK : 32'b0) |
                    (scl_release ? `SOC_CAM_SCCB_STATUS_SCL_RELEASE_MASK : 32'b0) |
                    (sda_sync ? `SOC_CAM_SCCB_STATUS_SDA_SYNC_MASK : 32'b0) |
                    (scl_sync ? `SOC_CAM_SCCB_STATUS_SCL_SYNC_MASK : 32'b0) |
                    (cam1_reset_n ? `SOC_CAM_SCCB_STATUS_RESET_N_MASK : 32'b0);
                default: mmio_rdata = 32'b0;
            endcase
        end
    end
endmodule
