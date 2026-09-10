`timescale 1ns/1ps
module tb_coremark_probe;
    reg clk=0, rst=1;
    always #5 clk=~clk;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    reg [31:0] imem_rdata, dmem_rdata;
    wire dmem_valid, dmem_wen;
    wire [3:0] dmem_wmask;
    wire [31:0] pc, ins;
    wire is_ebreak;
    reg [31:0] mem[0:8191];
    integer i, cyc;
    Htop #(.RESET_PC(32'h0)) dut(
      .clk(clk), .rst(rst), .imem_addr(imem_addr), .imem_rdata(imem_rdata),
      .dmem_valid(dmem_valid), .dmem_wen(dmem_wen), .dmem_addr(dmem_addr),
      .dmem_wdata(dmem_wdata), .dmem_wmask(dmem_wmask), .dmem_rdata(dmem_rdata),
      .dmem_ready(1'b1), .pc(pc), .ins(ins), .is_ebreak(is_ebreak));
    always @(*) begin
      imem_rdata = 32'h00000013;
      dmem_rdata = 32'b0;
      if (imem_addr[31:2] < 8192) imem_rdata = mem[imem_addr[14:2]];
      if (dmem_addr[31:2] < 8192) dmem_rdata = mem[dmem_addr[14:2]];
    end
    always @(posedge clk) begin
      if (!rst && dmem_valid && dmem_wen && dmem_addr[31:28] != 4'h4 && dmem_addr[31:28] != 4'h2)
        mem[dmem_addr[14:2]] <= dmem_wdata;
      if (!rst) begin
        cyc = cyc + 1;
        if (cyc >= 45 && cyc <= 65) begin
          $display("CTRL c=%0d IFv=%b IFai=%b IDv=%b IDai=%b IDfire=%b IDstall=%b EXv=%b EXai=%b EXgo=%b EXmem=%b EXins=%08x DIVop=%b DIVstart=%b DIVstarted=%b DIVdone=%b DIVdone_fire=%b MEMv=%b MEMai=%b WBv=%b flush=%b idfl=%b exfl=%b", cyc, dut.u_ifu.if_valid, dut.u_ifu.if_allowin, dut.u_idu.id_valid, dut.u_idu.id_allowin, dut.u_idu.id_fire, dut.u_idu.id_stall, dut.u_exu.ex_valid, dut.u_exu.ex_allowin, dut.u_exu.ex_ready_go, dut.u_exu.ex_mem_req, dut.u_exu.ex_ins, dut.u_exu.ex_m_is_div, dut.u_exu.div_start, dut.u_exu.ex_div_started, dut.u_exu.ex_div_done, dut.u_exu.div_done_fire, dut.u_memu.mem_valid, dut.u_memu.mem_allowin, dut.u_wbu.wb_valid, dut.flush, dut.id_flush_req, dut.ex_flush_req);
        end
        if (dut.u_idu.id_valid || dut.u_btb.valid[dut.btb_lookup_pc[5:2]]) begin
          $display("DBG c=%0d IF=%08x IDv=%b ID=%08x ins=%08x br=%b jal=%b jalr=%b pred=%08x act=%08x mis=%b fl=%b hit=%b tgt=%08x upd=%b upc=%08x utgt=%08x taken=%b dir=%b", cyc, dut.u_ifu.if_pc_reg, dut.u_idu.id_valid, dut.u_idu.id_pc_reg, dut.u_idu.id_ins_reg, dut.u_idu.id_is_branch, dut.u_idu.id_is_jal, dut.u_idu.id_is_jalr, dut.u_idu.id_predict_next_pc, dut.actual_next_pc, dut.dbg_mispredict, dut.flush, dut.btb_lookup_hit, dut.btb_look_up_target, dut.btb_update_valid, dut.btb_update_pc, dut.btb_update_target, dut.btb_update_taken, dut.u_btb.direction[dut.btb_lookup_pc[5:2]]);
        end
      end
    end
    initial begin
      cyc=0;
      for(i=0;i<8192;i=i+1) mem[i]=32'h00000013;
      $readmemh("../source/soc/coremark.dat",mem);
      repeat(8) @(posedge clk); rst=0;
      repeat(3000) @(posedge clk);
      $finish;
    end
endmodule
