`timescale 1ns / 1ps
`include "soc_addr_map.vh"
// 行为仿真 zzx 的 Hrgb565_int8_lane（CAM1 一路）：带随机等待的 AXI 内存模型 + 随机背压的下游。
// 输入小图由 run_lane_tb.py 放在 in_b<批>_<序>.hex；每交付一张就把 36,864 字节写到 out_b<批>_<序>.hex，
// 描述符、归还和计数写进 tb.log，由 run_lane_tb.py 逐项核对。
module tb_int8_lane;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst_n = 0;
    integer seed = 12345;
    integer log;

    reg desc_valid = 0;
    wire desc_ready;
    reg [7:0] desc_camera = 8'd1;
    reg [31:0] desc_frame = 0;
    reg desc_rgb_bank = 0;
    reg [31:0] desc_rgb_base = 0, desc_count = 0, desc_rgb_stride = 32'd32768;
    reg [15:0] desc_width = 16'd96, desc_height = 16'd96;
    reg [8*64-1:0] desc_boxes = 0;
    reg [8*3-1:0] desc_colors = 0;

    wire image_valid;
    reg image_ready = 0;
    wire [7:0] image_camera, image_batch_count, image_index;
    wire [31:0] image_frame, image_generation, image_data_addr, image_data_bytes;
    wire [63:0] image_box;
    wire [2:0] image_color;
    wire [1:0] image_block;
    wire [3:0] image_position;
    wire [15:0] image_width, image_height;

    reg release_valid = 0;
    wire release_ready;
    reg [7:0] release_camera = 0;
    reg [31:0] release_frame = 0, release_generation = 0;
    reg [1:0] release_block = 0;
    reg [3:0] release_position = 0;

    wire roi_release_valid, roi_release_bank;
    wire [31:0] roi_release_frame;
    wire busy, error, wait_slot, wait_ddr, wait_handoff;
    wire [31:0] images_done, batch_cycles, slot_wait_cycles, read_addr_wait_cycles, read_data_wait_cycles,
                write_addr_wait_cycles, write_data_wait_cycles, write_resp_wait_cycles, handoff_wait_cycles,
                used_slots, peak_slots, ddr_error_count, bad_release_count, failed_batches, last_failure_frame;
    wire [7:0] last_failure_index, last_failure_cause;

    wire [29:0] araddr, awaddr;
    wire [7:0] arid, arlen, awid, awlen;
    wire [2:0] arsize, awsize;
    wire [1:0] arburst, awburst;
    wire arvalid, rready, awvalid, wvalid, wlast, bready;
    wire [255:0] wdata;
    wire [31:0] wstrb;
    reg arready = 0, rvalid = 0, rlast = 0, awready = 0, wready = 0, bvalid = 0;
    reg [255:0] rdata = 0;
    reg [7:0] rid = 0, bid = 0;
    reg [1:0] rresp = 0, bresp = 0;

    Hrgb565_int8_lane #(.CAMERA(1'b0)) dut (
        .clk(clk), .rst_n(rst_n), .enable(1'b1), .clear_errors(1'b0),
        .desc_valid(desc_valid), .desc_ready(desc_ready), .desc_camera(desc_camera), .desc_frame(desc_frame),
        .desc_rgb_bank(desc_rgb_bank), .desc_rgb_base(desc_rgb_base), .desc_count(desc_count),
        .desc_width(desc_width), .desc_height(desc_height), .desc_rgb_stride(desc_rgb_stride),
        .desc_boxes(desc_boxes), .desc_colors(desc_colors),
        .image_valid(image_valid), .image_ready(image_ready), .image_camera(image_camera), .image_frame(image_frame),
        .image_batch_count(image_batch_count), .image_index(image_index), .image_box(image_box),
        .image_color(image_color), .image_block(image_block), .image_position(image_position),
        .image_generation(image_generation), .image_data_addr(image_data_addr), .image_width(image_width),
        .image_height(image_height), .image_data_bytes(image_data_bytes),
        .release_valid(release_valid), .release_ready(release_ready), .release_camera(release_camera),
        .release_frame(release_frame), .release_block(release_block), .release_position(release_position),
        .release_generation(release_generation),
        .roi_release_valid(roi_release_valid), .roi_release_bank(roi_release_bank), .roi_release_frame(roi_release_frame),
        .busy(busy), .error(error), .wait_slot(wait_slot), .wait_ddr(wait_ddr), .wait_handoff(wait_handoff),
        .images_done(images_done), .batch_cycles(batch_cycles), .slot_wait_cycles(slot_wait_cycles),
        .read_addr_wait_cycles(read_addr_wait_cycles), .read_data_wait_cycles(read_data_wait_cycles),
        .write_addr_wait_cycles(write_addr_wait_cycles), .write_data_wait_cycles(write_data_wait_cycles),
        .write_resp_wait_cycles(write_resp_wait_cycles), .handoff_wait_cycles(handoff_wait_cycles),
        .used_slots(used_slots), .peak_slots(peak_slots), .ddr_error_count(ddr_error_count),
        .bad_release_count(bad_release_count), .failed_batches(failed_batches),
        .last_failure_frame(last_failure_frame), .last_failure_index(last_failure_index),
        .last_failure_cause(last_failure_cause),
        .axi_araddr(araddr), .axi_arid(arid), .axi_arlen(arlen), .axi_arsize(arsize), .axi_arburst(arburst),
        .axi_arvalid(arvalid), .axi_arready(arready), .axi_rdata(rdata), .axi_rid(rid), .axi_rresp(rresp),
        .axi_rlast(rlast), .axi_rvalid(rvalid), .axi_rready(rready),
        .axi_awaddr(awaddr), .axi_awid(awid), .axi_awlen(awlen), .axi_awsize(awsize), .axi_awburst(awburst),
        .axi_awvalid(awvalid), .axi_awready(awready), .axi_wdata(wdata), .axi_wstrb(wstrb), .axi_wlast(wlast),
        .axi_wvalid(wvalid), .axi_wready(wready), .axi_bid(bid), .axi_bresp(bresp), .axi_bvalid(bvalid),
        .axi_bready(bready));

    // ---------------- DDR 模型 ----------------
    // 读区：CAM1 两个 RGB565 bank（local 0x3840_0000 起 2 MiB），写区：CAM1 四个 INT8 块（local 0x3880_0000 起 2 MiB）
    localparam [29:0] RBASE = 30'h3840_0000, WBASE = 30'h3880_0000;
    reg [255:0] rmem [0:65535];
    reg [255:0] wmem [0:65535];
    integer protocol_errors = 0;
    integer inject_beat = -1;          // >=0 时，第 inject_beat 个读拍返回 SLVERR
    integer read_beats = 0;

    reg r_pending = 0;
    integer r_delay = 0;
    reg [29:0] r_addr = 0;
    reg [7:0] r_id = 0;
    reg aw_pending = 0, b_pending = 0;
    integer w_beat = 0, b_delay = 0;
    reg [29:0] aw_addr = 0;
    reg [7:0] aw_id = 0;

    always @(posedge clk) begin
        if (!rst_n) begin
            arready <= 0; rvalid <= 0; rlast <= 0; r_pending <= 0;
            awready <= 0; wready <= 0; bvalid <= 0; aw_pending <= 0; b_pending <= 0;
        end else begin
            // AR
            if (arvalid && arready) begin
                arready <= 0; r_pending <= 1; r_addr <= araddr; r_id <= arid;
                r_delay <= $unsigned($random(seed)) % 12;
                if (arlen != 0 || arsize != 3'd5 || arburst != 2'b01 || araddr[4:0] != 0 ||
                    araddr < RBASE || araddr >= RBASE + 30'h20_0000) begin
                    protocol_errors = protocol_errors + 1;
                    $fdisplay(log, "PROTO AR addr=%h len=%0d size=%0d burst=%0d", araddr, arlen, arsize, arburst);
                end
            end else if (arvalid && !r_pending && ($unsigned($random(seed)) % 4) != 0)
                arready <= 1;
            // R
            if (rvalid && rready) begin
                rvalid <= 0; rlast <= 0; rresp <= 0; r_pending <= 0;
            end else if (r_pending && !rvalid) begin
                if (r_delay == 0) begin
                    rvalid <= 1; rlast <= 1; rid <= r_id;
                    rdata <= rmem[(r_addr - RBASE) >> 5];
                    rresp <= (read_beats == inject_beat) ? 2'b10 : 2'b00;
                    read_beats = read_beats + 1;
                end else r_delay <= r_delay - 1;
            end
            // AW
            if (awvalid && awready) begin
                awready <= 0; aw_pending <= 1; aw_addr <= awaddr; aw_id <= awid; w_beat <= 0;
                if (awlen != 1 || awsize != 3'd5 || awburst != 2'b01 || awaddr[5:0] != 0 ||
                    awaddr < WBASE || awaddr >= WBASE + 30'h20_0000) begin
                    protocol_errors = protocol_errors + 1;
                    $fdisplay(log, "PROTO AW addr=%h len=%0d size=%0d burst=%0d", awaddr, awlen, awsize, awburst);
                end
            end else if (awvalid && !aw_pending && !b_pending && ($unsigned($random(seed)) % 3) != 0)
                awready <= 1;
            // W
            wready <= aw_pending && ($unsigned($random(seed)) % 3) != 0;
            if (wvalid && wready) begin
                if (!aw_pending || wstrb != 32'hffff_ffff || wlast != (w_beat == 1)) begin
                    protocol_errors = protocol_errors + 1;
                    $fdisplay(log, "PROTO W beat=%0d last=%0d strb=%h aw_pending=%0d", w_beat, wlast, wstrb, aw_pending);
                end
                wmem[((aw_addr - WBASE) >> 5) + w_beat] <= wdata;
                w_beat <= w_beat + 1;
                if (wlast) begin
                    aw_pending <= 0; wready <= 0; b_pending <= 1; b_delay <= $unsigned($random(seed)) % 6;
                end
            end
            // B
            if (bvalid && bready) begin
                bvalid <= 0; b_pending <= 0;
            end else if (b_pending && !bvalid) begin
                if (b_delay == 0) begin bvalid <= 1; bid <= aw_id; bresp <= 0; end
                else b_delay <= b_delay - 1;
            end
        end
    end

    // ---------------- 下游（志勇一侧）：随机接收 ----------------
    integer batch_no = 0;
    integer got = 0;
    integer stall_until = 0;
    integer cyc = 0;
    reg [8*64-1:0] cur_boxes;
    reg [8*3-1:0] cur_colors;
    // 已交付图像的归还信息
    reg [1:0] rb_block [0:63];
    reg [3:0] rb_pos [0:63];
    reg [31:0] rb_gen [0:63];
    reg [31:0] rb_frame [0:63];
    integer n_deliv = 0;
    reg [8*40-1:0] fname;
    always @(posedge clk) cyc <= cyc + 1;

    always @(posedge clk) begin
        if (image_valid && image_ready) begin
            $fdisplay(log, "IMG batch=%0d frame=%h index=%0d count=%0d camera=%0d block=%0d position=%0d gen=%0d addr=%h box=%h color=%0d w=%0d h=%0d bytes=%0d expbox=%h expcolor=%0d cyc=%0d",
                      batch_no, image_frame, image_index, image_batch_count, image_camera, image_block, image_position,
                      image_generation, image_data_addr, image_box, image_color, image_width, image_height, image_data_bytes,
                      cur_boxes[image_index*64 +: 64], cur_colors[image_index*3 +: 3], cyc);
            $sformat(fname, "out_b%0d_%0d.hex", batch_no, image_index);
            $writememh(fname, wmem, ((image_data_addr - 32'h8000_0000) - WBASE) >> 5,
                       (((image_data_addr - 32'h8000_0000) - WBASE) >> 5) + 1151);
            rb_block[n_deliv] = image_block; rb_pos[n_deliv] = image_position;
            rb_gen[n_deliv] = image_generation; rb_frame[n_deliv] = image_frame;
            n_deliv = n_deliv + 1;
            got = got + 1;
        end
        if (cyc < stall_until) image_ready <= 0;
        else image_ready <= ($unsigned($random(seed)) % 3) == 0;
        if (roi_release_valid)
            $fdisplay(log, "ROIREL batch=%0d bank=%0d frame=%h busy=%0d cyc=%0d", batch_no, roi_release_bank, roi_release_frame, busy, cyc);
    end

    `include "tb_load.vh"

    task send_desc(input integer b, input [31:0] frame, input bank, input [31:0] count);
        integer i;
        begin
            load_batch(b);
            batch_no = b;
            for (i = 0; i < 8; i = i + 1) begin
                cur_boxes[i*64 +: 64] = {16'(16'h0B00 + b), 16'(16'h0100 + i), 16'(16'h0200 + i * 3), 16'(16'h0300 + b * 16 + i)};
                cur_colors[i*3 +: 3] = (i + b) % 8;
            end
            @(negedge clk);
            desc_frame = frame; desc_rgb_bank = bank; desc_count = count;
            desc_rgb_base = bank ? `SOC_PRE1_BANK1_BASE : `SOC_PRE1_BANK0_BASE;
            desc_boxes = cur_boxes; desc_colors = cur_colors; desc_valid = 1;
            @(posedge clk);
            while (!desc_ready) @(posedge clk);
            $fdisplay(log, "DESC batch=%0d frame=%h bank=%0d count=%0d cyc=%0d", b, frame, bank, count, cyc);
            @(negedge clk);
            desc_valid = 0;
        end
    endtask

    task release_one(input integer k, input [31:0] gen_delta, input [7:0] cam);
        begin
            @(negedge clk);
            release_valid = 1; release_camera = cam; release_block = rb_block[k]; release_position = rb_pos[k];
            release_generation = rb_gen[k] + gen_delta; release_frame = rb_frame[k];
            @(posedge clk);
            $fdisplay(log, "REL k=%0d cam=%0d block=%0d position=%0d gen=%0d frame=%h ready=%0d", k, cam, rb_block[k], rb_pos[k],
                      rb_gen[k] + gen_delta, rb_frame[k], release_ready);
            @(negedge clk);
            release_valid = 0;
        end
    endtask

    task wait_images(input integer n);
        integer t;
        begin
            t = 0;
            while (got < n && t < 4000000) begin @(posedge clk); t = t + 1; end
            if (got < n) $fdisplay(log, "TIMEOUT waiting images got=%0d want=%0d", got, n);
            repeat (50) @(posedge clk);
        end
    endtask

    task stats;
        $fdisplay(log, "STATS images_done=%0d used=%0d peak=%0d ddr_err=%0d bad_release=%0d failed=%0d last_fail_frame=%h last_fail_index=%0d last_fail_cause=%0d error=%0d busy=%0d protocol_errors=%0d",
                  images_done, used_slots, peak_slots, ddr_error_count, bad_release_count, failed_batches,
                  last_failure_frame, last_failure_index, last_failure_cause, error, busy, protocol_errors);
    endtask

    integer i, k;
    initial begin
        log = $fopen("tb.log", "w");
        for (i = 0; i < 65536; i = i + 1) begin rmem[i] = 0; wmem[i] = {8{32'hDEADBEEF}}; end
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);

        // 批 1：8 张，bank 0；下游中途停 3000 拍，让 FIFO 堆满
        stall_until = cyc + 3000;
        send_desc(1, 32'h0000_0011, 1'b0, 8);
        wait_images(8);
        stats;
        // 归还 8 张中的 7 张（留第 4 张），再发一条代次不对的、一条重复的、一条摄像头号不对的
        for (k = 0; k < 8; k = k + 1) if (k != 3) release_one(k, 0, 8'd1);
        release_one(0, 0, 8'd1);           // 重复：应记非法
        release_one(3, 1, 8'd1);           // 代次不对：应记非法，第 4 张仍占用
        release_one(3, 0, 8'd2);           // 摄像头号不对：应记非法
        repeat (5) @(posedge clk);
        stats;
        // 批 2：8 张，bank 1，应复用已归还的 7 个位置（代次 2）再加一个新位置
        send_desc(2, 32'h0000_0022, 1'b1, 8);
        wait_images(16);
        stats;
        // 批 3：空批次，应直接归还 bank；批 4：9 张，非法，应记错并归还 bank
        send_desc(3, 32'h0000_0033, 1'b0, 0);
        repeat (20) @(posedge clk);
        send_desc(4, 32'h0000_0044, 1'b1, 9);
        repeat (20) @(posedge clk);
        stats;
        // 批 5：3 张，bank 0
        send_desc(5, 32'h0000_0055, 1'b0, 3);
        wait_images(19);
        stats;
        // 批 6：2 张，bank 1，第 2 张读到一半返回 SLVERR：第 1 张照常交付，第 2 张作废、位置收回
        inject_beat = read_beats + 576 + 100;
        send_desc(6, 32'h0000_0066, 1'b1, 2);
        wait_images(20);
        k = 0;
        while (busy && k < 400000) begin @(posedge clk); k = k + 1; end
        if (busy) $fdisplay(log, "TIMEOUT waiting idle after batch 6");
        repeat (20) @(posedge clk);
        stats;
        $fdisplay(log, "END cyc=%0d", cyc);
        $fclose(log);
        $finish;
    end
endmodule
