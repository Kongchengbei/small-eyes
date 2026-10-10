`timescale 1ns / 1ps
`include "soc_addr_map.vh"

//提供 CPU 控制、状态读取、跨时钟域同步和统计快照
module Hrgb565_int8_regs (
    input cpu_clk, input ddr_clk, input rst_n,
    input mmio_valid, input mmio_wen, input [7:0] mmio_addr,
    input [31:0] mmio_wdata, input [3:0] mmio_wstrb,
    output wire mmio_ready, output reg [31:0] mmio_rdata,
    input [1:0] busy_ddr, input [1:0] wait_slot_ddr,
    input [1:0] wait_ddr_ddr, input [1:0] wait_handoff_ddr,
    input [1:0] error_ddr, input ddr_ready_ddr,
    input [1023:0] stats_ddr,
    output wire enable_ddr, output wire clear_errors_ddr
);
    reg enable_cpu, stop_cpu;
    reg clear_toggle_cpu;
    reg enable_meta_ddr, enable_sync_ddr;
    reg clear_meta_ddr, clear_sync_ddr;
    reg clear_seen_ddr, clear_pulse_ddr;
//实时状态位是独立同步的;多比特统计信息使用下方的请求/确认快照
//矢量使用下方的请求/确认快照
    reg [1:0] busy_meta_cpu, busy_sync_cpu;
    reg [1:0] slot_meta_cpu, slot_sync_cpu;
    reg [1:0] ddrwait_meta_cpu, ddrwait_sync_cpu;
    reg [1:0] handoff_meta_cpu, handoff_sync_cpu;
    reg [1:0] error_meta_cpu, error_sync_cpu;
    reg ready_meta_cpu, ready_sync_cpu;

    reg snapshot_req_toggle_cpu, snapshot_waiting_cpu, snapshot_ready_cpu;
    reg snapshot_ack_meta_cpu, snapshot_ack_sync_cpu;
    reg snapshot_req_meta_ddr, snapshot_req_sync_ddr;
    reg snapshot_req_seen_ddr, snapshot_ack_toggle_ddr;
    reg [1023:0] snapshot_stats_ddr, snapshot_stats_cpu;

    wire stats_read = mmio_valid && !mmio_wen &&
        ((mmio_addr>=`SOC_INT8_CAM1_STATS_BASE && mmio_addr<(`SOC_INT8_CAM1_STATS_BASE+8'h40)) ||
         (mmio_addr>=`SOC_INT8_CAM2_STATS_BASE && mmio_addr<(`SOC_INT8_CAM2_STATS_BASE+8'h40)));
    assign mmio_ready = !stats_read || snapshot_ready_cpu;
    assign enable_ddr = enable_sync_ddr;
    assign clear_errors_ddr = clear_pulse_ddr;

    always @(posedge cpu_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_cpu<=0; stop_cpu<=0; clear_toggle_cpu<=0;
            busy_meta_cpu<=0; busy_sync_cpu<=0; slot_meta_cpu<=0; slot_sync_cpu<=0;
            ddrwait_meta_cpu<=0; ddrwait_sync_cpu<=0;
            handoff_meta_cpu<=0; handoff_sync_cpu<=0;
            error_meta_cpu<=0; error_sync_cpu<=0; ready_meta_cpu<=0; ready_sync_cpu<=0;
            snapshot_req_toggle_cpu<=0; snapshot_waiting_cpu<=0; snapshot_ready_cpu<=0;
            snapshot_ack_meta_cpu<=0; snapshot_ack_sync_cpu<=0; snapshot_stats_cpu<=0;
        end else begin
            busy_meta_cpu<=busy_ddr; busy_sync_cpu<=busy_meta_cpu;
            slot_meta_cpu<=wait_slot_ddr; slot_sync_cpu<=slot_meta_cpu;
            ddrwait_meta_cpu<=wait_ddr_ddr; ddrwait_sync_cpu<=ddrwait_meta_cpu;
            handoff_meta_cpu<=wait_handoff_ddr; handoff_sync_cpu<=handoff_meta_cpu;
            error_meta_cpu<=error_ddr; error_sync_cpu<=error_meta_cpu;
            ready_meta_cpu<=ddr_ready_ddr; ready_sync_cpu<=ready_meta_cpu;
            snapshot_ack_meta_cpu<=snapshot_ack_toggle_ddr;
            snapshot_ack_sync_cpu<=snapshot_ack_meta_cpu;

            if (mmio_valid && mmio_wen && mmio_addr==`SOC_INT8_CTRL_OFFSET && mmio_wstrb[0]) begin
                stop_cpu<=mmio_wdata[1];
                enable_cpu<=mmio_wdata[0] && !mmio_wdata[1];
                if (mmio_wdata[2]) clear_toggle_cpu<=~clear_toggle_cpu;
            end

            if (stats_read && !snapshot_ready_cpu && !snapshot_waiting_cpu) begin
                snapshot_req_toggle_cpu<=~snapshot_req_toggle_cpu;
                snapshot_waiting_cpu<=1;
            end
            if (snapshot_waiting_cpu && snapshot_ack_sync_cpu==snapshot_req_toggle_cpu) begin
                snapshot_stats_cpu<=snapshot_stats_ddr;
                snapshot_waiting_cpu<=0;
                snapshot_ready_cpu<=1;
            end
            if (stats_read && mmio_ready) snapshot_ready_cpu<=0;
        end
    end

    always @(posedge ddr_clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化所有寄存器
            enable_meta_ddr<=0; enable_sync_ddr<=0;
            clear_meta_ddr<=0; clear_sync_ddr<=0; clear_seen_ddr<=0; clear_pulse_ddr<=0;
            snapshot_req_meta_ddr<=0; snapshot_req_sync_ddr<=0;
            snapshot_req_seen_ddr<=0; snapshot_ack_toggle_ddr<=0; snapshot_stats_ddr<=0;
        end else begin
/*两级寄存器： enable_meta_ddr -> enable_sync_ddr 
enable_meta_ddr <= enable_cpu;       // 第一级采样源信号
enable_sync_ddr <= enable_meta_ddr;  // 第二级采样第一
*/
            enable_meta_ddr<=enable_cpu; enable_sync_ddr<=enable_meta_ddr;//enable_cpu 在 CPU 时钟域更新，而两级接收寄存器在 DDR 时钟域更新
            clear_meta_ddr<=clear_toggle_cpu; clear_sync_ddr<=clear_meta_ddr;
            clear_pulse_ddr<=0;
            if (clear_sync_ddr!=clear_seen_ddr) begin
                clear_seen_ddr<=clear_sync_ddr; clear_pulse_ddr<=1;
            end
            snapshot_req_meta_ddr<=snapshot_req_toggle_cpu;
            snapshot_req_sync_ddr<=snapshot_req_meta_ddr;
            if (snapshot_req_sync_ddr!=snapshot_req_seen_ddr) begin
                snapshot_stats_ddr<=stats_ddr;
                snapshot_req_seen_ddr<=snapshot_req_sync_ddr;
                snapshot_ack_toggle_ddr<=snapshot_req_sync_ddr;
            end
        end
    end

    always @* begin
        mmio_rdata=0;
        if (mmio_addr==`SOC_INT8_CTRL_OFFSET)
            mmio_rdata={29'b0,1'b0,stop_cpu,enable_cpu};
        else if (mmio_addr==`SOC_INT8_STATUS_OFFSET)
            mmio_rdata={26'b0,ready_sync_cpu,|error_sync_cpu,|handoff_sync_cpu,
                        |ddrwait_sync_cpu,|slot_sync_cpu,|busy_sync_cpu};
        else if (mmio_addr>=`SOC_INT8_CAM1_STATS_BASE &&
                 mmio_addr<(`SOC_INT8_CAM1_STATS_BASE+8'h40) && mmio_addr[1:0]==0)
            mmio_rdata=snapshot_stats_cpu[((({24'b0,mmio_addr}-32'h0000_0040)>>2))*32+:32];
        else if (mmio_addr>=`SOC_INT8_CAM2_STATS_BASE &&
                 mmio_addr<(`SOC_INT8_CAM2_STATS_BASE+8'h40) && mmio_addr[1:0]==0)
            mmio_rdata=snapshot_stats_cpu[512+((({24'b0,mmio_addr}-32'h0000_0080)>>2))*32+:32];
    end
endmodule
