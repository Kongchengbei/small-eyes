`timescale 1ns / 1ps

// 小尺寸 CAM DMA 离线测试：覆盖成功发布、DVP/AXI 错误、双槽所有权与超时恢复。
module tb_camera_dma;
reg clk=0, rst_n=0, enable=0, ddr_ready=0, clear_errors=0;
reg release_valid=0; reg [1:0] release_mask=0;
reg fifo_empty=1, fifo_rd_valid=0, fifo_fault=0;
reg [17:0] fifo_rd_data=0;
wire fifo_rd_en;
wire busy, done, error, frame_active;
wire [31:0] error_code, frame_count, last_pixel_count, last_byte_count, last_line_count;
wire [31:0] current_pixel_count, current_byte_count, current_line_count;
wire [31:0] last_frame_addr, current_write_buffer, last_complete_buffer, frame_checksum;
wire [1:0] ready_mask; wire [31:0] dropped_frames;
wire [29:0] axi_awaddr; wire [7:0] axi_awid, axi_awlen;
wire [2:0] axi_awsize; wire [1:0] axi_awburst; wire axi_awvalid;
reg axi_awready=0; wire [255:0] axi_wdata; wire [31:0] axi_wstrb;
wire axi_wlast, axi_wvalid; reg axi_wready=0;
reg [7:0] axi_bid=8'h40; reg [1:0] axi_bresp=0; reg axi_bvalid=0;
wire axi_bready;

Hcamera_dma #(.FRAME_WIDTH(4), .FRAME_HEIGHT(2), .TIMEOUT_CYCLES(24)) dut (
    .clk(clk), .rst_n(rst_n), .enable(enable), .ddr_ready(ddr_ready),
    .clear_errors(clear_errors), .release_valid(release_valid), .release_mask(release_mask),
    .fifo_empty(fifo_empty), .fifo_rd_en(fifo_rd_en), .fifo_rd_valid(fifo_rd_valid),
    .fifo_rd_data(fifo_rd_data), .fifo_fault(fifo_fault), .busy(busy), .done(done),
    .error(error), .error_code(error_code), .frame_active(frame_active),
    .frame_count(frame_count), .last_pixel_count(last_pixel_count),
    .last_byte_count(last_byte_count), .last_line_count(last_line_count),
    .current_pixel_count(current_pixel_count), .current_byte_count(current_byte_count),
    .current_line_count(current_line_count), .last_frame_addr(last_frame_addr),
    .current_write_buffer(current_write_buffer), .last_complete_buffer(last_complete_buffer),
    .frame_checksum(frame_checksum), .ready_mask(ready_mask), .dropped_frames(dropped_frames),
    .axi_awaddr(axi_awaddr), .axi_awid(axi_awid), .axi_awlen(axi_awlen),
    .axi_awsize(axi_awsize), .axi_awburst(axi_awburst), .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready), .axi_wdata(axi_wdata), .axi_wstrb(axi_wstrb),
    .axi_wlast(axi_wlast), .axi_wvalid(axi_wvalid), .axi_wready(axi_wready),
    .axi_bid(axi_bid), .axi_bresp(axi_bresp), .axi_bvalid(axi_bvalid), .axi_bready(axi_bready)
);

always #5 clk=~clk;
integer cycle=0, writes=0, done_count=0, saw_timeout_stall=0;
reg stall_aw=0, inject_b_error=0;
reg aw_hold=0, w_hold=0;
reg [29:0] aw_addr_hold=0;
reg [255:0] w_data_hold=0;
reg [31:0] w_strb_hold=0;
reg [31:0] write_addr_log [0:63];
reg [255:0] write_data_log [0:63];
reg [31:0] write_strb_log [0:63];
reg b_pending=0; integer b_delay=0;
always @(posedge clk) begin
    if (!rst_n) begin
        cycle<=0; axi_awready<=0; axi_wready<=0; axi_bvalid<=0; b_pending<=0;
        b_delay<=0; writes<=0; done_count<=0;
    end else begin
        cycle<=cycle+1;
        // 写通道插入停顿，检查 payload 在 VALID/READY 间保持。
        axi_awready <= !stall_aw && (cycle[1:0] != 2'b01);
        axi_wready <= (cycle[1:0] != 2'b10);
        if (done) done_count<=done_count+1;
        if (aw_hold && (!axi_awvalid || axi_awaddr!=aw_addr_hold))
            $fatal(1,"AW payload changed while stalled");
        if (w_hold && (!axi_wvalid || axi_wdata!=w_data_hold || axi_wstrb!=w_strb_hold))
            $fatal(1,"W payload changed while stalled");
        aw_hold <= axi_awvalid && !axi_awready;
        aw_addr_hold <= axi_awaddr;
        w_hold <= axi_wvalid && !axi_wready;
        w_data_hold <= axi_wdata;
        w_strb_hold <= axi_wstrb;
        if (axi_awvalid && axi_awready) begin
            if (axi_awid!=8'h40 || axi_awlen!=0 || axi_awsize!=5 || axi_awburst!=1)
                $fatal(1,"AW metadata incorrect");
            if (axi_awaddr[4:0]!=0) $fatal(1,"AW alignment incorrect");
        end
        if (axi_wvalid && axi_wready) begin
            if (!axi_wlast) $fatal(1,"single beat must assert WLAST");
            write_addr_log[writes] <= dut.selected_buffer + dut.write_offset - 32'h80000000;
            write_data_log[writes] <= axi_wdata;
            write_strb_log[writes] <= axi_wstrb;
            writes<=writes+1;
            b_pending<=1; b_delay<=2;
        end
        if (axi_bvalid && axi_bready) axi_bvalid<=0;
        else if (b_pending) begin
            if (b_delay!=0) b_delay<=b_delay-1;
            else begin
                b_pending<=0; axi_bvalid<=1; axi_bresp<=inject_b_error ? 2'b10 : 2'b00;
            end
        end
    end
end

task automatic push_token(input [1:0] tag, input [15:0] value);
    integer watchdog;
    begin
        fifo_empty=0;
        #1;
        watchdog=0;
        while (!fifo_rd_en && watchdog<300) begin @(negedge clk); watchdog=watchdog+1; end
        if (watchdog==300) $fatal(1,"FIFO request timeout tag=%0d state=%0d ready=%b active=%b busy=%b pending=%b",tag,dut.state,ready_mask,frame_active,busy,dut.fifo_request_pending);
        // FIFO 在 rd_en 后一拍返回，模拟同步读 FIFO。
        @(negedge clk); fifo_rd_valid=1; fifo_rd_data={tag,value};
        @(negedge clk); fifo_rd_valid=0; fifo_rd_data=0; fifo_empty=1;
    end
endtask

task automatic push_frame(input [15:0] seed, input [3:0] eof_error_bits);
    begin push_token(2'b01,0); push_frame_body(seed,eof_error_bits); end
endtask

task automatic push_frame_body(input [15:0] seed, input [3:0] eof_error_bits);
    integer p;
    begin
        for (p=0;p<8;p=p+1) begin
            push_token(2'b00,seed+p[15:0]);
            if ((p==3)||(p==7)) push_token(2'b11,0);
        end
        push_token(2'b10,{12'b0,eof_error_bits});
    end
endtask

task automatic wait_frames(input integer target);
    integer t;
    begin
        t=0; while (frame_count<target && t<2000) begin @(negedge clk); t=t+1; end
        if (frame_count<target) $fatal(1,"frame timeout target=%0d state=%0d active=%b bad=%b eof=%b pix=%0d lines=%0d code=%0d req=%b empty=%b valid=%b",target,dut.state,frame_active,dut.frame_bad,dut.pending_eof,current_pixel_count,current_line_count,error_code,dut.fifo_request_pending,fifo_empty,fifo_rd_valid);
    end
endtask

task automatic release_slots(input [1:0] mask);
    begin @(negedge clk); release_valid=1; release_mask=mask;
        @(negedge clk); release_valid=0; release_mask=0; end
endtask

integer old_writes;
initial begin
    repeat(4) @(negedge clk); rst_n=1; enable=1; ddr_ready=1;

    // 成功帧：两行各 4 像素，检查 checksum、计数和 partial beat strobes。
    push_frame(16'd10,0); wait_frames(1);
    if (!done || busy) $fatal(1,"DONE must remain visible while idle after completion");
    if (last_pixel_count!=8 || last_byte_count!=16 || last_line_count!=2)
        $fatal(1,"published counters incorrect");
    if (frame_checksum!=108 || ready_mask!=2'b01 || last_complete_buffer!=0 || current_write_buffer!=32'hffff_ffff)
        $fatal(1,"first frame metadata incorrect checksum=%0d ready=%b addr=%h",frame_checksum,ready_mask,last_complete_buffer);
    if (writes!=1 || write_strb_log[0]!=32'h0000ffff)
        $fatal(1,"cross-line partial write incorrect writes=%0d strobe=%h",writes,write_strb_log[0]);
    if (write_addr_log[0]!=32'h38000000 ||
        write_data_log[0][127:0]!=128'h00110010000f000e000d000c000b000a)
        $fatal(1,"little-endian pixel packing or local AW address incorrect");

    // 第二槽可用且被占有；两槽占满时第三帧必须丢弃且不能发 AW。
    // 新 SOF 清除 sticky DONE；重复 SOF 丢弃旧帧并立即从新边界重新计数。
    push_token(2'b01,0);
    if (done) $fatal(1,"new SOF did not clear sticky DONE");
    push_token(2'b00,16'd1); push_token(2'b00,16'd2);
    @(negedge clk); fifo_fault=1; @(negedge clk); fifo_fault=0;
    push_token(2'b01,0);
    push_frame_body(16'd20,0); wait_frames(2);
    if (ready_mask!=2'b11 || last_complete_buffer!=1)
        $fatal(1,"second buffer ownership incorrect");
    if (error_code!=1 || dropped_frames==0) $fatal(1,"overflow/duplicate SOF did not drop and restart frame");
    old_writes=writes; push_frame(16'd30,0); repeat(8) @(negedge clk);
    if (writes!=old_writes || frame_count!=2 || dropped_frames==0)
        $fatal(1,"full buffers did not drop frame");

    // 释放槽 0 后必须可复用。DVP 错帧不得更新完成描述。
    release_slots(2'b01);
    push_frame(16'd40,0); wait_frames(3);
    if (last_complete_buffer!=0 || ready_mask!=2'b11)
        $fatal(1,"released slot was not reused");
    release_slots(2'b10);
    old_writes=writes;
    push_token(2'b01,0);
    for (integer q=0;q<8;q=q+1) begin
        push_token(2'b00,16'd45+q[15:0]);
        if ((q==3)||(q==7)) push_token(2'b11,0);
    end
    push_token(2'b00,16'd999); // 超出配置帧像素数，必须立即禁止任何部分包写入。
    push_token(2'b10,0); repeat(5) @(negedge clk);
    if (writes!=old_writes || frame_count!=3 || last_pixel_count!=8)
        $fatal(1,"excess pixel caused write or published invalid frame");

    old_writes=writes; push_frame(16'd50,4'h1); repeat(8) @(negedge clk);
    if (frame_count!=3 || last_complete_buffer!=0 || frame_checksum!=348 || writes<=old_writes)
        $fatal(1,"DVP error frame was published or not written");

    // B 错误使帧无效；release 两槽后注入 AW 长停顿，超时须保留 VALID。
    @(negedge clk); clear_errors=1; @(negedge clk); clear_errors=0;
    release_slots(2'b11); inject_b_error=1;
    push_frame(16'd60,0); repeat(20) @(negedge clk);
    inject_b_error=0; repeat(20) @(negedge clk);
    if (ready_mask!=0 || error_code!=6) $fatal(1,"AXI B error handling failed code=%0d",error_code);

    @(negedge clk); clear_errors=1; @(negedge clk); clear_errors=0;
    stall_aw=1; old_writes=writes;
    push_frame(16'd70,0);
    // 等待 timeout 记录，同时 AWVALID 仍然保持。
    repeat(35) @(negedge clk);
    if (!axi_awvalid || !error || error_code!=5)
        $fatal(1,"timeout must hold AWVALID code=%0d valid=%b state=%0d ready=%b writes=%0d",error_code,axi_awvalid,dut.state,axi_awready,writes);
    stall_aw=0;
    // B 响应收尾后，超时帧不得发布。
    repeat(40) @(negedge clk);
    if (frame_count!=3 || ready_mask!=0) $fatal(1,"timed-out frame was published");

    // 超时事务排空后重新发送有效帧，证明 FIFO/AXI 状态机恢复。
    push_frame(16'd80,0); wait_frames(4);
    if (last_pixel_count!=8 || frame_checksum!=668 || ready_mask!=2'b01)
        $fatal(1,"frame after timeout did not recover");

    // FIFO 无数据超时后丢弃到下一个 SOF，读请求仍工作且后续帧可成功。
    push_token(2'b01,0); repeat(35) @(negedge clk);
    if (frame_active || error_code!=5) $fatal(1,"FIFO wait timeout did not abort frame");
    push_token(2'b00,16'd123); push_token(2'b10,0);
    push_frame(16'd90,0); wait_frames(5);
    if (frame_checksum!=748 || ready_mask!=2'b11)
        $fatal(1,"FIFO timeout recovery failed");

    // 普通 FIFO 等待时禁用：清掉当前半帧，不改最后完成描述；重启只认新 SOF。
    release_slots(2'b11);
    old_writes=writes;
    push_token(2'b01,0);
    push_token(2'b00,16'd101); push_token(2'b00,16'd102); push_token(2'b00,16'd103);
    @(negedge clk); enable=0; @(negedge clk);
    if (busy || frame_active || current_write_buffer!=32'hffff_ffff || dut.pack_count!=0 ||
        frame_count!=5 || frame_checksum!=748 || last_frame_addr!=32'hB8100000)
        $fatal(1,"disable did not abort partial frame cleanly");
    enable=1;
    push_token(2'b00,16'd999); push_token(2'b10,0); // 禁用前残留数据丢弃。
    push_frame(16'd110,0); wait_frames(6);
    if (frame_checksum!=908 || ready_mask!=2'b01)
        $fatal(1,"SOF resynchronization after FIFO disable failed");

    // AW 已发出时禁用：VALID/地址必须保持到 handshake，W/B 排空后才清除当前槽。
    release_slots(2'b01);
    stall_aw=1;
    push_frame(16'd120,0);
    if (!axi_awvalid) $fatal(1,"expected pending AW before disable test");
    @(negedge clk); enable=0;
    repeat(3) @(negedge clk);
    if (!axi_awvalid || frame_count!=6) $fatal(1,"disable withdrew outstanding AW or published frame");
    stall_aw=0;
    repeat(30) @(negedge clk);
    if (busy || frame_count!=6 || current_write_buffer!=32'hffff_ffff || ready_mask!=0 ||
        frame_checksum!=908)
        $fatal(1,"disable abort did not wait for AXI drain");
    enable=1;
    push_frame(16'd130,0); wait_frames(7);
    if (frame_checksum!=1068 || ready_mask!=2'b01)
        $fatal(1,"frame after AXI-disable drain failed");

    // 分别清除粘滞错误，验证错误码而不让较早 overflow 掩盖后续诊断。
    release_slots(2'b11);
    @(negedge clk); clear_errors=1; @(negedge clk); clear_errors=0;
    push_token(2'b10,0);
    if (error_code!=3) $fatal(1,"unexpected EOF code incorrect: %0d",error_code);

    @(negedge clk); clear_errors=1; @(negedge clk); clear_errors=0;
    push_token(2'b01,0); push_token(2'b00,16'd1); push_token(2'b10,0);
    repeat(20) @(negedge clk);
    if (error_code!=4 || frame_count!=7 || ready_mask!=0)
        $fatal(1,"bad pixel count code/publication incorrect: %0d",error_code);

    @(negedge clk); clear_errors=1; @(negedge clk); clear_errors=0;
    push_token(2'b01,0); push_token(2'b00,16'd1); push_token(2'b11,0);
    push_token(2'b10,0); repeat(10) @(negedge clk);
    if (error_code!=7 || frame_count!=7)
        $fatal(1,"bad line count code/publication incorrect: %0d",error_code);

    @(negedge clk); clear_errors=1; @(negedge clk); clear_errors=0;
    push_token(2'b01,0); push_token(2'b01,0);
    if (error_code!=2) $fatal(1,"unexpected SOF code incorrect: %0d",error_code);
    push_frame_body(16'd140,0); wait_frames(8);
    if (frame_checksum!=1148) $fatal(1,"duplicate SOF recovery incorrect");

    $display("tb_camera_dma PASS frames=%0d dropped=%0d writes=%0d",frame_count,dropped_frames,writes);
    $finish;
end

endmodule
