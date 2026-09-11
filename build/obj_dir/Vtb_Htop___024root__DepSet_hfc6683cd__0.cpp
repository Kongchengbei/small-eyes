// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_Htop.h for the primary calling header

#include "Vtb_Htop__pch.h"
#include "Vtb_Htop__Syms.h"
#include "Vtb_Htop___024root.h"

VL_INLINE_OPT VlCoroutine Vtb_Htop___024root___eval_initial__TOP__Vtiming__0(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ tb_Htop__DOT__i;
    tb_Htop__DOT__i = 0;
    std::string tb_Htop__DOT__program_file;
    VlWide<3>/*95:0*/ __Vtemp_2;
    // Body
    tb_Htop__DOT__i = 0U;
    while (VL_GTS_III(32, 0x4000U, tb_Htop__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__mem[(0x3fffU & tb_Htop__DOT__i)] = 0U;
        tb_Htop__DOT__i = ((IData)(1U) + tb_Htop__DOT__i);
    }
    tb_Htop__DOT__program_file = std::string{"inst.txt"};
    __Vtemp_2[0U] = 0x4d3d2573U;
    __Vtemp_2[1U] = 0x4f475241U;
    __Vtemp_2[2U] = 0x5052U;
    (void)VL_VALUEPLUSARGS_INN(64, VL_CVT_PACK_STR_NW(3, __Vtemp_2), 
                               tb_Htop__DOT__program_file);
    VL_WRITEF_NX("PROGRAM=%@\n",0,-1,&(tb_Htop__DOT__program_file));
    VL_READMEM_N(true, 32, 16384, 0, VL_CVT_PACK_STR_NN(tb_Htop__DOT__program_file)
                 ,  &(vlSelfRef.tb_Htop__DOT__mem), 0
                 , ~0ULL);
    vlSymsp->_vm_contextp__->dumpfile(std::string{"tb.vcd"});
    VL_PRINTF_MT("-Info: sim/tb_Htop.sv:257: $dumpvar ignored, as Verilated without --trace\n");
    vlSelfRef.tb_Htop__DOT__cycle_count = 0U;
    co_await vlSelfRef.__VtrigSched_hdf5d1d13__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_Htop.clk)", 
                                                         "sim/tb_Htop.sv", 
                                                         260);
    co_await vlSelfRef.__VtrigSched_hdf5d1d13__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_Htop.clk)", 
                                                         "sim/tb_Htop.sv", 
                                                         260);
    co_await vlSelfRef.__VtrigSched_hdf5d1d13__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_Htop.clk)", 
                                                         "sim/tb_Htop.sv", 
                                                         260);
    co_await vlSelfRef.__VtrigSched_hdf5d1d13__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_Htop.clk)", 
                                                         "sim/tb_Htop.sv", 
                                                         260);
    co_await vlSelfRef.__VtrigSched_hdf5d1d13__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_Htop.clk)", 
                                                         "sim/tb_Htop.sv", 
                                                         260);
    vlSelfRef.tb_Htop__DOT__rst = 0U;
}

VL_INLINE_OPT VlCoroutine Vtb_Htop___024root___eval_initial__TOP__Vtiming__1(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ tb_Htop__DOT__timeout_cycles;
    tb_Htop__DOT__timeout_cycles = 0;
    IData/*31:0*/ tb_Htop__DOT__unnamedblk1_2__DOT____Vrepeat1;
    tb_Htop__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0;
    VlWide<3>/*95:0*/ __Vtemp_1;
    // Body
    tb_Htop__DOT__timeout_cycles = 0xf4240U;
    __Vtemp_1[0U] = 0x543d2564U;
    __Vtemp_1[1U] = 0x4d454f55U;
    __Vtemp_1[2U] = 0x5449U;
    (void)VL_VALUEPLUSARGS_INI(32, VL_CVT_PACK_STR_NW(3, __Vtemp_1), 
                               tb_Htop__DOT__timeout_cycles);
    tb_Htop__DOT__unnamedblk1_2__DOT____Vrepeat1 = tb_Htop__DOT__timeout_cycles;
    while (VL_LTS_III(32, 0U, tb_Htop__DOT__unnamedblk1_2__DOT____Vrepeat1)) {
        co_await vlSelfRef.__VtrigSched_hdf5d1d13__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_Htop.clk)", 
                                                             "sim/tb_Htop.sv", 
                                                             287);
        tb_Htop__DOT__unnamedblk1_2__DOT____Vrepeat1 
            = (tb_Htop__DOT__unnamedblk1_2__DOT____Vrepeat1 
               - (IData)(1U));
    }
    VL_WRITEF_NX("TEST_TIMEOUT\n[%0t] %%Fatal: tb_Htop.sv:289: Assertion failed in %Ntb_Htop: TEST_TIMEOUT\n",0,
                 64,VL_TIME_UNITED_Q(1000),-9,vlSymsp->name());
    VL_STOP_MT("sim/tb_Htop.sv", 289, "", false);
}

VL_INLINE_OPT VlCoroutine Vtb_Htop___024root___eval_initial__TOP__Vtiming__2(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_initial__TOP__Vtiming__2\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x1388ULL, 
                                             nullptr, 
                                             "sim/tb_Htop.sv", 
                                             97);
        vlSelfRef.tb_Htop__DOT__clk = (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__clk)));
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__act(Vtb_Htop___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_Htop___024root___eval_triggers__act(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_triggers__act\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered.setBit(0U, ((IData)(vlSelfRef.tb_Htop__DOT__clk) 
                                          & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_Htop__DOT__clk__0))));
    vlSelfRef.__VactTriggered.setBit(1U, ((~ (IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n)) 
                                          & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n__0)));
    vlSelfRef.__VactTriggered.setBit(2U, vlSelfRef.__VdlySched.awaitingCurrentTime());
    vlSelfRef.__Vtrigprevexpr___TOP__tb_Htop__DOT__clk__0 
        = vlSelfRef.tb_Htop__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n__0 
        = vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_Htop___024root___dump_triggers__act(vlSelf);
    }
#endif
}

extern const VlUnpacked<CData/*3:0*/, 4096> Vtb_Htop__ConstPool__TABLE_ha0a8fb9d_0;

VL_INLINE_OPT void Vtb_Htop___024root___nba_sequent__TOP__1(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___nba_sequent__TOP__1\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__btb_lookup_hit;
    tb_Htop__DOT__dut__DOT__btb_lookup_hit = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed = 0;
    QData/*32:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit = 0;
    SData/*11:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    CData/*0:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending;
    __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending = 0;
    CData/*0:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid;
    __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid = 0;
    CData/*0:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative = 0;
    CData/*0:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative = 0;
    CData/*5:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count = 0;
    CData/*0:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg = 0;
    QData/*63:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime = 0;
    QData/*63:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret = 0;
    CData/*7:0*/ __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr;
    __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    IData/*20:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    IData/*20:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v0 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v0 = 0;
    IData/*25:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v0 = 0;
    IData/*31:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v0 = 0;
    CData/*1:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 = 0;
    CData/*1:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 = 0;
    CData/*1:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v0 = 0;
    CData/*0:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 = 0;
    CData/*3:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v0 = 0;
    IData/*31:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 = 0;
    CData/*4:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0;
    CData/*7:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    CData/*0:0*/ __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0;
    VlWide<3>/*95:0*/ __Vtemp_3;
    VlWide<3>/*95:0*/ __Vtemp_4;
    VlWide<3>/*95:0*/ __Vtemp_5;
    VlWide<3>/*95:0*/ __Vtemp_6;
    VlWide<3>/*95:0*/ __Vtemp_7;
    VlWide<3>/*95:0*/ __Vtemp_8;
    VlWide<3>/*95:0*/ __Vtemp_9;
    // Body
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr;
    vlSelfRef.__Vdly__tb_Htop__DOT__ddr_rsp_valid = vlSelfRef.tb_Htop__DOT__ddr_rsp_valid;
    __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr;
    vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v0 = 0U;
    vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v1 = 0U;
    vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v2 = 0U;
    vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 0U;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state;
    vlSelfRef.__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 0U;
    vlSelfRef.__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 0U;
    vlSelfRef.__Vdly__tb_Htop__DOT__axi_wlast = vlSelfRef.tb_Htop__DOT__axi_wlast;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U];
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U];
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U];
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U];
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num;
    vlSelfRef.__Vdly__tb_Htop__DOT__axi_bready = vlSelfRef.tb_Htop__DOT__axi_bready;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way;
    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state;
    __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending;
    __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 = 0U;
    if (((~ (IData)(vlSelfRef.tb_Htop__DOT__rst)) & 
         (0x6fU == vlSelfRef.tb_Htop__DOT__dut__DOT__wb_ins))) {
        if ((1U == vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf
             [0x1bU])) {
            VL_WRITEF_NX("TEST_PASS\ncycle_count=%0d\n",0,
                         32,vlSelfRef.tb_Htop__DOT__cycle_count);
            VL_FINISH_MT("sim/tb_Htop.sv", 276, "");
        } else {
            VL_WRITEF_NX("TEST_FAIL testnum=%0#\n[%0t] %%Fatal: tb_Htop.sv:279: Assertion failed in %Ntb_Htop: TEST_FAIL\n",0,
                         32,vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf
                         [3U],64,VL_TIME_UNITED_Q(1000),
                         -9,vlSymsp->name());
            VL_STOP_MT("sim/tb_Htop.sv", 279, "", false);
        }
    }
    __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v0 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 = 0U;
    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19 = 0U;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime;
    __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret;
    if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__rst)))) {
        vlSelfRef.tb_Htop__DOT__cycle_count = ((IData)(1U) 
                                               + vlSelfRef.tb_Htop__DOT__cycle_count);
        if (vlSelfRef.tb_Htop__DOT__ddr_req_valid) {
            if (vlSelfRef.tb_Htop__DOT__ddr_addr_valid) {
                if (vlSelfRef.tb_Htop__DOT__ddr_req_write) {
                    if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__ddr_req_wstrb))) {
                        vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v0 
                            = (0xffU & vlSelfRef.tb_Htop__DOT__ddr_req_wdata);
                        vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v0 
                            = (0x3fffU & ((vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                           - (IData)(0x80000000U)) 
                                          >> 2U));
                        vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v0 = 1U;
                    }
                    if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__ddr_req_wstrb))) {
                        vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v1 
                            = (0xffU & (vlSelfRef.tb_Htop__DOT__ddr_req_wdata 
                                        >> 8U));
                        vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v1 
                            = (0x3fffU & ((vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                           - (IData)(0x80000000U)) 
                                          >> 2U));
                        vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v1 = 1U;
                    }
                    if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__ddr_req_wstrb))) {
                        vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v2 
                            = (0xffU & (vlSelfRef.tb_Htop__DOT__ddr_req_wdata 
                                        >> 0x10U));
                        vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v2 
                            = (0x3fffU & ((vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                           - (IData)(0x80000000U)) 
                                          >> 2U));
                        vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v2 = 1U;
                    }
                    if ((8U & (IData)(vlSelfRef.tb_Htop__DOT__ddr_req_wstrb))) {
                        vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v3 
                            = (vlSelfRef.tb_Htop__DOT__ddr_req_wdata 
                               >> 0x18U);
                        vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v3 
                            = (0x3fffU & ((vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                           - (IData)(0x80000000U)) 
                                          >> 2U));
                        vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v3 = 1U;
                    }
                }
            }
        }
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][0U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][0U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][0U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][0U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][1U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][1U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][1U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][1U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][2U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][2U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][2U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][2U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][3U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][3U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [0U][3U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [0U][3U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][0U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][0U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][0U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][0U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][1U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][1U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][1U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][1U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][2U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][2U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][2U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][2U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][3U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][3U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
                        [1U][3U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina
               [1U][3U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][0U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][0U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][0U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][0U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][1U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][1U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][1U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][1U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][2U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][2U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][2U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][2U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][3U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][3U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [0U][3U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [0U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [0U][3U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [0U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][0U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][0U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][0U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][0U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][0U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][0U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][1U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][1U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][1U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][1U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][1U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][1U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][2U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][2U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][2U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][2U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][2U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][2U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if ((1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][3U]);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if ((2U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][3U] >> 8U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1 = 1U;
    }
    if ((4U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
                        [1U][3U] >> 0x10U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2 = 1U;
    }
    if ((8U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea
         [1U][3U])) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina
               [1U][3U] >> 0x18U);
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
            [1U][3U];
        __VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3 = 1U;
    }
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__wea) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 
            = (1U | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
                     << 1U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__1__KET____DOT__u__wea) {
        __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 
            = (1U | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
                     << 1U));
        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__wea) {
        vlSelfRef.__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 
            = (1U | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
                     << 1U));
        vlSelfRef.__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra;
        vlSelfRef.__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__1__KET____DOT__u__wea) {
        vlSelfRef.__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 
            = (1U | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
                     << 1U));
        vlSelfRef.__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra;
        vlSelfRef.__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 1U;
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [0U][0U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [0U][1U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [0U][2U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [0U][3U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [1U][0U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [1U][1U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [1U][2U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra
        [1U][3U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__wb_valid = ((1U 
                                                   & (~ (IData)(vlSelfRef.tb_Htop__DOT__rst))) 
                                                  && (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_to_wb_valid));
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr = 1U;
        vlSelfRef.__Vdly__tb_Htop__DOT__ddr_rsp_valid = 0U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr = 1U;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v0 = 1U;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v0 = 1U;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v0 = 1U;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v0 = 1U;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v0 = 1U;
        __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v0 = 1U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime = 0ULL;
        __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret = 0ULL;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold_pc = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__force_fetch = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__forced_fetch_pc = 0x80000000U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_predict_next_pc = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_started = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_csr = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_imm = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_ex_wb_value = 0U;
    } else {
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0xf8U & (IData)(vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr)) 
               | ((4U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr) 
                         << 1U)) | ((2U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr) 
                                           << 1U)) 
                                    | (1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr) 
                                             >> 7U)))));
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0xe7U & (IData)(vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr)) 
               | ((0x10U & (VL_REDXOR_8((0x88U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr))) 
                            << 4U)) | (8U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr) 
                                             << 1U))));
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0x9fU & (IData)(vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr)) 
               | ((0x40U & (VL_REDXOR_8((0xa0U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr))) 
                            << 6U)) | (0x20U & (VL_REDXOR_8(
                                                            (0x90U 
                                                             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr))) 
                                                << 5U))));
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0x7fU & (IData)(vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr)) 
               | (0x80U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr) 
                           << 1U)));
        if (((IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_valid) 
             & (IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_ready))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__ddr_rsp_valid = 0U;
        }
        if (vlSelfRef.tb_Htop__DOT__ddr_req_valid) {
            vlSelfRef.__Vdly__tb_Htop__DOT__ddr_rsp_valid = 1U;
        }
        __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0xf8U & (IData)(__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr)) 
               | ((4U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr) 
                         << 1U)) | ((2U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr) 
                                           << 1U)) 
                                    | (1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr) 
                                             >> 7U)))));
        __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0xe7U & (IData)(__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr)) 
               | ((0x10U & (VL_REDXOR_8((0x88U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))) 
                            << 4U)) | (8U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr) 
                                             << 1U))));
        __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0x9fU & (IData)(__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr)) 
               | ((0x40U & (VL_REDXOR_8((0xa0U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))) 
                            << 6U)) | (0x20U & (VL_REDXOR_8(
                                                            (0x90U 
                                                             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))) 
                                                << 5U))));
        __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr 
            = ((0x7fU & (IData)(__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr)) 
               | (0x80U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr) 
                           << 1U)));
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__btb_update_valid) {
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16 
                = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                           >> 2U));
            __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16 = 1U;
            __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 
                = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                   >> 6U);
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 
                = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                           >> 2U));
            __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16 = 1U;
            __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_redirect_pc;
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 
                = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                           >> 2U));
            __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16 = 1U;
            __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 
                = (0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg));
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 
                = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                           >> 2U));
            __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16 = 1U;
            if ((0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))) {
                if ((1U & (((~ vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid
                             [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                       >> 2U))]) | 
                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag
                             [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                       >> 2U))] != 
                             (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                              >> 6U))) | (~ vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional
                                          [(0xfU & 
                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                             >> 2U))])))) {
                    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 
                        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__btb_update_taken)
                            ? 2U : 1U);
                    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 
                        = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                   >> 2U));
                    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16 = 1U;
                } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__btb_update_taken) {
                    if ((3U != vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction
                         [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                   >> 2U))])) {
                        __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 
                            = (3U & ((IData)(1U) + 
                                     vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction
                                     [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                               >> 2U))]));
                        __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 
                            = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                       >> 2U));
                        __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17 = 1U;
                    }
                } else if ((0U != vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction
                            [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                      >> 2U))])) {
                    __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 
                        = (3U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction
                                 [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                           >> 2U))] 
                                 - (IData)(1U)));
                    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 
                        = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                                   >> 2U));
                    __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18 = 1U;
                }
            } else {
                __VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19 
                    = (0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                               >> 2U));
                __VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19 = 1U;
            }
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__wb_reg_wen) 
             & (0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg)))) {
            __VdlyVal__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_data_reg;
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg;
            __VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32 = 1U;
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
             & (0xb03U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
                = ((0xffffffff00000000ULL & __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime) 
                   | (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data)));
        } else if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
                    & (0xb83U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
                = ((0xffffffffULL & __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime) 
                   | ((QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data)) 
                      << 0x20U));
        } else if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcctr))) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
                = (1ULL + vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime);
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
             & (0xb02U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret 
                = ((0xffffffff00000000ULL & __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret) 
                   | (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data)));
        } else if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
                    & (0xb82U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret 
                = ((0xffffffffULL & __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret) 
                   | ((QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data)) 
                      << 0x20U));
        } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcctr))) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret 
                = (1ULL + vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret);
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__accept) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold_pc 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_pc;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold = 1U;
        } else if ((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_resp_valid) 
                     | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush) 
                        & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
                    | (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush) 
                        & (4U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) 
                       & (~ ((4U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_rdy)))))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold = 0U;
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__flush) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__force_fetch = 1U;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__forced_fetch_pc 
                = vlSelfRef.tb_Htop__DOT__debug_flush_pc;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid = 0U;
        } else {
            if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_valid) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_ready))) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__force_fetch = 0U;
            }
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__id_allowin) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid;
            }
        }
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_predict_next_pc 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__btb_predict_next_pc;
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid) 
             | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_started = 0U;
        } else if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_done_fire)))) {
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_start) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_started = 1U;
            }
        }
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_csr 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_is_csr;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_imm 
                = (0x1fU & vlSelfRef.tb_Htop__DOT__dut__DOT__id_imm);
        }
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_ex_wb_value 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_value;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_offset = 0U;
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_offset 
            = (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result);
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_done = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op = 0xfU;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[0U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__done_q = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_imm = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__divisor_work = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_work = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_work = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg = 0U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative = 0U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative = 0U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count = 0U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_mret = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_ecall = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3 = 0U;
    } else {
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__accept) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold = 1U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_rsp_valid) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold = 0U;
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid) 
             | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_done = 0U;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done = 0U;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started = 0U;
        } else {
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_done_fire) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_done = 1U;
            }
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done = 1U;
            }
            if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire)))) {
                if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start) {
                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started = 1U;
                }
            }
        }
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_alu_op;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_imm 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_imm;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op 
                = ((0x73U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                    ? (7U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                             >> 0xcU)) : 0U);
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_mret 
                = (0x30200073U == vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg);
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_ecall 
                = (0x73U == vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg);
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store 
                = (0x23U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg));
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__stage1_valid) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__done_q = 1U;
            __Vtemp_3[0U] = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p00_q;
            __Vtemp_3[1U] = 0U;
            __Vtemp_3[2U] = 0U;
            __Vtemp_4[0U] = (IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q 
                                     << 0x10U));
            __Vtemp_4[1U] = (((- (IData)((1U & (IData)(
                                                       (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q 
                                                        >> 0x21U))))) 
                              << 0x12U) | (IData)((
                                                   (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q 
                                                    << 0x10U) 
                                                   >> 0x20U)));
            __Vtemp_4[2U] = (3U & ((- (IData)((1U & (IData)(
                                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q 
                                                             >> 0x21U))))) 
                                   >> 0xeU));
            __Vtemp_5[0U] = (IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q 
                                     << 0x10U));
            __Vtemp_5[1U] = (((- (IData)((1U & (IData)(
                                                       (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q 
                                                        >> 0x21U))))) 
                              << 0x12U) | (IData)((
                                                   (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q 
                                                    << 0x10U) 
                                                   >> 0x20U)));
            __Vtemp_5[2U] = (3U & ((- (IData)((1U & (IData)(
                                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q 
                                                             >> 0x21U))))) 
                                   >> 0xeU));
            __Vtemp_6[0U] = 0U;
            __Vtemp_6[1U] = (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p11_q);
            __Vtemp_6[2U] = (IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p11_q 
                                     >> 0x20U));
            VL_ADD_W(3, __Vtemp_7, __Vtemp_5, __Vtemp_6);
            VL_ADD_W(3, __Vtemp_8, __Vtemp_4, __Vtemp_7);
            VL_ADD_W(3, __Vtemp_9, __Vtemp_3, __Vtemp_8);
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[0U] 
                = __Vtemp_9[0U];
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[1U] 
                = __Vtemp_9[1U];
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[2U] 
                = (3U & __Vtemp_9[2U]);
        } else {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__done_q = 0U;
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid;
        }
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg = 0U;
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_next;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_work 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_next;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_work 
                = (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_next);
            if ((0x1fU == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count))) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg 
                    = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative)
                        ? ((IData)(1U) + (~ vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_next))
                        : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_next);
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg 
                    = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative)
                        ? ((IData)(1U) + (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_next)))
                        : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_next));
                __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg = 0U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg = 1U;
            } else {
                __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count 
                    = (0x3fU & ((IData)(1U) + (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count)));
            }
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_start) {
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative 
                = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed) 
                   & ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 
                       ^ vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2) 
                      >> 0x1fU));
            __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative 
                = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed) 
                   & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 
                      >> 0x1fU));
            if ((0U == vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg = 0xffffffffU;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg = 1U;
            } else if ((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed) 
                         & (0x80000000U == vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1)) 
                        & (0xffffffffU == vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2))) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg = 0x80000000U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg = 0U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg = 1U;
            } else {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work 
                    = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed) 
                        & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 
                           >> 0x1fU)) ? ((IData)(1U) 
                                         + (~ vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1))
                        : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1);
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__divisor_work 
                    = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed) 
                        & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                           >> 0x1fU)) ? ((IData)(1U) 
                                         + (~ vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2))
                        : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2);
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_work = 0U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_work = 0U;
                __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count = 0U;
                __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg = 1U;
            }
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid = 0U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid;
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) {
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) {
                if ((((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit)) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = 1U;
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index;
                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb;
                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata;
                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset;
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit;
                } else {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = 0U;
                }
            } else {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = 0U;
            }
        } else if ((((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit)) 
                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = 1U;
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset;
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit;
        }
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_pc = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_zero = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp = 0xffffffffffffffffULL;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mstatus = 0x1800U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mie = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcause = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtvec = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2_is_imm = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_en = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_wb_sel = 0U;
    } else {
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_pc 
                = ((0x17U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                   | (0x6fU == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_zero 
                = (0x37U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg));
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load 
                = (3U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2_is_imm 
                = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i) 
                   | ((0x23U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                      | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u) 
                         | (0x6fU == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)))));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_en 
                = (((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_m)) 
                    & (0x33U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))) 
                   | (((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_jalr)) 
                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i)) 
                      | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u) 
                         | (0x23U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)))));
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
             & (0xb04U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp 
                = ((0xffffffff00000000ULL & vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp) 
                   | (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data)));
        } else if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
                    & (0xb84U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp 
                = ((0xffffffffULL & vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp) 
                   | ((QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data)) 
                      << 0x20U));
        }
        if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall)))) {
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) {
                if ((0x300U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mstatus 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data;
                }
                if ((0x300U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                    if ((0x304U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mie 
                            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data;
                    }
                    if ((0x304U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                        if ((0x305U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtvec 
                                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data;
                        }
                    }
                }
            }
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcause = 0xbU;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) {
            if ((0x300U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                if ((0x304U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                    if ((0x305U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                        if ((0x341U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                            if ((0x342U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                                vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcause 
                                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data;
                            }
                        }
                    }
                }
            }
        }
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_wb_sel 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_is_load = 0U;
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_is_load 
            = (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel));
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_reg_wen_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mepc = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__wb_ins = 0x13U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_data_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcctr = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p00_q = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q = 0ULL;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q = 0ULL;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p11_q = 0ULL;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3 = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__mem_reg_wen = 0U;
    } else {
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__mem_to_wb_valid) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_reg_wen_reg 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__mem_reg_wen;
            vlSelfRef.tb_Htop__DOT__dut__DOT__wb_ins 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__mem_ins;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_data_reg 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__mem_wb_data;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__mem_rd_addr;
        }
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op 
                = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_m)
                    ? ((0U == (7U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                     >> 0xcU))) ? 1U
                        : ((1U == (7U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                         >> 0xcU)))
                            ? 2U : ((2U == (7U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                  >> 0xcU)))
                                     ? 3U : ((3U == 
                                              (7U & 
                                               (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                >> 0xcU)))
                                              ? 4U : 
                                             ((4U == 
                                               (7U 
                                                & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                   >> 0xcU)))
                                               ? 5U
                                               : ((5U 
                                                   == 
                                                   (7U 
                                                    & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                       >> 0xcU)))
                                                   ? 6U
                                                   : 
                                                  ((6U 
                                                    == 
                                                    (7U 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0xcU)))
                                                    ? 7U
                                                    : 8U)))))))
                    : 0U);
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1;
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3 
                = (7U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                         >> 0xcU));
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel 
                = ((3U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                    ? 1U : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_11)
                             ? 2U : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_is_csr)
                                      ? 3U : 0U)));
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mepc 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) {
            if ((0x300U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                if ((0x304U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                    if ((0x305U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                        if ((0x341U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))) {
                            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mepc 
                                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data;
                        }
                    }
                }
            }
        }
        if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen) 
             & (0xb88U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr)))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcctr 
                = (0x1fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data);
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p00_q 
                = ((0xffffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__x_ext)) 
                   * (0xffffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext)));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q 
                = (0x3ffffffffULL & VL_MULS_QQQ(34, 
                                                (0x3ffffffffULL 
                                                 & VL_EXTENDS_QI(34,17, 
                                                                 (0xffffU 
                                                                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__x_ext)))), 
                                                (0x3ffffffffULL 
                                                 & VL_EXTENDS_QI(34,17, 
                                                                 (0x1ffffU 
                                                                  & (IData)(
                                                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext 
                                                                             >> 0x10U)))))));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q 
                = (0x3ffffffffULL & VL_MULS_QQQ(34, 
                                                (0x3ffffffffULL 
                                                 & VL_EXTENDS_QI(34,17, 
                                                                 (0x1ffffU 
                                                                  & (IData)(
                                                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__x_ext 
                                                                             >> 0x10U))))), 
                                                (0x3ffffffffULL 
                                                 & VL_EXTENDS_QI(34,17, 
                                                                 (0xffffU 
                                                                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext))))));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p11_q 
                = (0x3ffffffffULL & VL_MULS_QQQ(34, 
                                                (0x3ffffffffULL 
                                                 & VL_EXTENDS_QI(34,17, 
                                                                 (0x1ffffU 
                                                                  & (IData)(
                                                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__x_ext 
                                                                             >> 0x10U))))), 
                                                (0x3ffffffffULL 
                                                 & VL_EXTENDS_QI(34,17, 
                                                                 (0x1ffffU 
                                                                  & (IData)(
                                                                            (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext 
                                                                             >> 0x10U)))))));
        }
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__mem_reg_wen 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_reg_wen;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__mem_ins = 0x13U;
    } else if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
                & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc = vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg;
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__mem_ins = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_ins;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__mem_rd_addr = 0U;
    }
    if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__mem_rd_addr 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_reg_wen = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_ins = 0x13U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg = 0x13U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg = 0x7ffffffcU;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_ins_reg = 0x13U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending = 0U;
        __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pc_reg = 0U;
    } else {
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr 
                = ((0x73U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                    ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                       >> 0x14U) : 0U);
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_reg_wen 
                = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_8) 
                   | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u) 
                      | ((0x6fU == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                         | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_is_csr))));
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_ins 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg;
            vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr 
                = (0x1fU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                            >> 7U));
        }
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_ins_reg;
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__flush) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                = (vlSelfRef.tb_Htop__DOT__debug_flush_pc 
                   - (IData)(4U));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_ins_reg = 0x13U;
            __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending = 0U;
            __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid = 0U;
        } else {
            if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_allowin))) {
                __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid = 0U;
            }
            if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_valid) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_ready))) {
                __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending = 1U;
            }
            if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_resp_valid) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending))) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pc_reg;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_ins_reg 
                    = ((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))
                        ? (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_1))) 
                            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_6) 
                           | ((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_3))) 
                              & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_7))
                        : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
                __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending = 0U;
                __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid = 1U;
            }
        }
        if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush)))) {
            if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_valid) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_ready))) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pc_reg 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_pc;
            }
        }
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [0U][0U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [0U][1U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [0U][2U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [0U][3U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [1U][0U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [1U][1U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [1U][2U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra
        [1U][3U]];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr;
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[3U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[4U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[5U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[6U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[7U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[8U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[9U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0xaU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0xbU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0xcU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0xdU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0xeU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[0xfU] = 0U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__target__v16;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[3U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[4U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[5U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[6U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[7U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[8U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[9U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0xaU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0xbU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0xcU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0xdU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0xeU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0xfU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x10U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x11U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x12U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x13U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x14U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x15U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x16U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x17U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x18U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x19U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x1aU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x1bU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x1cU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x1dU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x1eU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[0x1fU] = 0U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf__v32;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[3U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[4U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[5U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[6U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[7U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[8U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[9U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0xaU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0xbU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0xcU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0xdU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0xeU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[0xfU] = 0U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__valid__v16] = 1U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[3U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[4U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[5U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[6U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[7U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[8U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[9U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0xaU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0xbU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0xcU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0xdU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0xeU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[0xfU] = 0U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__tag__v16;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[3U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[4U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[5U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[6U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[7U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[8U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[9U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0xaU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0xbU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0xcU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0xdU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0xeU] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[0xfU] = 0U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional__v16;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[1U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[2U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[3U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[4U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[5U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[6U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[7U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[8U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[9U] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0xaU] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0xbU] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0xcU] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0xdU] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0xeU] = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[0xfU] = 1U;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v16;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v17;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v18;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_btb__DOT__direction__v19] = 3U;
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret;
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0] 
            = __VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0;
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0]) 
               | (IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v0));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v1) 
                  << 8U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v2) 
                  << 0x10U));
    }
    if (__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem
                [__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3]) 
               | ((IData)(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem__v3) 
                  << 0x18U));
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[0U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[0U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[0U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[0U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[1U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[1U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[1U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[1U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__stage1_valid 
        = ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__rst))) 
           && (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[0U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[0U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[0U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[0U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[1U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[1U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[1U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[1U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_next 
        = VL_SHIFTL_III(32,32,32, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work, 1U);
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift 
        = (((QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_work)) 
            << 1U) | (QData)((IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work 
                                      >> 0x1fU))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_0 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load) 
           | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store));
    vlSelfRef.tb_Htop__DOT__dut__DOT__wb_reg_wen = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_reg_wen_reg) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__wb_valid));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed 
        = ((5U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
           | (7U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_3 
        = ((5U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
           | (6U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed 
        = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
           | (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
           & (0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[0U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [0U][0U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[0U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [0U][1U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[0U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [0U][2U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[0U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [0U][3U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[1U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [1U][0U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[1U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [1U][1U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[1U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [1U][2U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[1U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta
        [1U][3U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[0U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [0U][0U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[0U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [0U][1U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[0U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [0U][2U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[0U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [0U][3U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[1U][0U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [1U][0U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[1U][1U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [1U][1U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[1U][2U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [1U][2U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[1U][3U] 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta
        [1U][3U];
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit 
        = (tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift 
           >= (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__divisor_work)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed) 
           | (3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_3) 
              | ((7U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
                 | (8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_next 
        = ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_work 
            << 1U) | (IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_next 
        = (0x1ffffffffULL & ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit)
                              ? (tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift 
                                 - (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__divisor_work)))
                              : tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_src 
        = ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op))
            ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_imm)
            : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__x_ext 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed)
            ? (((QData)((IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 
                                 >> 0x1fU))) << 0x20U) 
               | (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1)))
            : (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid) 
           & ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed) 
              | (4U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_done_fire 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_started) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_start 
        = ((~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_done) 
               | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_started))) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_7 
        = (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div)) 
                 | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_done)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_pc)
            ? vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc
            : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_zero)
                ? 0U : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start 
        = ((~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done) 
               | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started))) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__done_q)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_forward_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_reg_wen) 
              & (0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_rd_addr))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data 
        = ((0x800U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
            ? ((0x400U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                ? ((0x200U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                    ? ((0x100U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                        ? ((0x80U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                            ? 0U : ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                     ? 0U : ((0x20U 
                                              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                              ? 0U : 
                                             ((0x10U 
                                               & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                               ? ((8U 
                                                   & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                   ? 0U
                                                   : 
                                                  ((4U 
                                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                    ? 0U
                                                    : 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0x10202328U
                                                      : 0U)
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0x114514U
                                                      : 0U))))
                                               : 0U))))
                        : 0U) : 0U) : ((0x200U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                        ? ((0x100U 
                                            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                            ? ((0x80U 
                                                & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                ? (
                                                   (0x40U 
                                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                    ? 0U
                                                    : 
                                                   ((0x20U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 0U
                                                     : 
                                                    ((0x10U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0U
                                                      : 
                                                     ((8U 
                                                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                       ? 
                                                      ((4U 
                                                        & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                        ? 0U
                                                        : 
                                                       ((2U 
                                                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                         ? 0U
                                                         : 
                                                        ((1U 
                                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                          ? 0U
                                                          : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcctr))))
                                                       : 
                                                      ((4U 
                                                        & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                        ? 
                                                       ((2U 
                                                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                         ? 0U
                                                         : 
                                                        ((1U 
                                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                          ? 0U
                                                          : (IData)(
                                                                    (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp 
                                                                     >> 0x20U))))
                                                        : 
                                                       ((2U 
                                                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                         ? 
                                                        ((1U 
                                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                          ? (IData)(
                                                                    (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
                                                                     >> 0x20U))
                                                          : (IData)(
                                                                    (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret 
                                                                     >> 0x20U)))
                                                         : 0U))))))
                                                : (
                                                   (0x40U 
                                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                    ? 0U
                                                    : 
                                                   ((0x20U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 0U
                                                     : 
                                                    ((0x10U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0U
                                                      : 
                                                     ((8U 
                                                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                       ? 0U
                                                       : 
                                                      ((4U 
                                                        & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                        ? 
                                                       ((2U 
                                                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                         ? 0U
                                                         : 
                                                        ((1U 
                                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                          ? 0U
                                                          : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp)))
                                                        : 
                                                       ((2U 
                                                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                         ? 
                                                        ((1U 
                                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                          ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime)
                                                          : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret))
                                                         : 0U)))))))
                                            : 0U) : 0U))
            : ((0x400U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                ? 0U : ((0x200U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                         ? ((0x100U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                             ? ((0x80U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                 ? 0U : ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                          ? ((0x20U 
                                              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                              ? 0U : 
                                             ((0x10U 
                                               & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                               ? 0U
                                               : ((8U 
                                                   & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                   ? 0U
                                                   : 
                                                  ((4U 
                                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                    ? 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 0U
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0U
                                                      : 
                                                     ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime 
                                                       >= vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp) 
                                                      << 7U)))
                                                    : 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0U
                                                      : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcause)
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mepc
                                                      : 0U))))))
                                          : ((0x20U 
                                              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                              ? 0U : 
                                             ((0x10U 
                                               & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                               ? 0U
                                               : ((8U 
                                                   & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                   ? 0U
                                                   : 
                                                  ((4U 
                                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                    ? 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 0U
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtvec
                                                      : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mie))
                                                    : 
                                                   ((2U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                     ? 0U
                                                     : 
                                                    ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr))
                                                      ? 0x40000100U
                                                      : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mstatus))))))))
                             : 0U) : 0U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_6 
        = (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul)) 
                 | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done) 
                    | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_forward_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_reg_wen) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
              & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load)) 
                 & ((0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr)) 
                    & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_6) 
                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_7))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_m 
        = (IData)((0x2000033U == (0xfe00007fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)));
    __Vtableidx1 = (((0x20U == (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                >> 0x19U)) << 0xbU) 
                    | (((0U == (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                >> 0x19U)) << 0xaU) 
                       | ((0x380U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                     >> 5U)) | (0x7fU 
                                                & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_alu_op = Vtb_Htop__ConstPool__TABLE_ha0a8fb9d_0
        [__Vtableidx1];
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_is_csr = (
                                                   (0x73U 
                                                    == 
                                                    (0x7fU 
                                                     & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                                                   & (0U 
                                                      != 
                                                      (7U 
                                                       & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                          >> 0xcU))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u 
        = ((0x37U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | (0x17U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i 
        = ((0x13U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | ((3U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
              | (0x67U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_8 
        = ((0x33U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_imm = ((0x73U 
                                                 == 
                                                 (0x7fU 
                                                  & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                                                 ? 
                                                (0x1fU 
                                                 & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                    >> 0xfU))
                                                 : 
                                                ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i)
                                                  ? 
                                                 (((- (IData)(
                                                              (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                               >> 0x1fU))) 
                                                   << 0xcU) 
                                                  | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                     >> 0x14U))
                                                  : 
                                                 ((0x63U 
                                                   == 
                                                   (0x7fU 
                                                    & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                                                   ? 
                                                  (((- (IData)(
                                                               (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                                >> 0x1fU))) 
                                                    << 0xcU) 
                                                   | ((0x800U 
                                                       & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                          << 4U)) 
                                                      | ((0x7e0U 
                                                          & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                             >> 0x14U)) 
                                                         | (0x1eU 
                                                            & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                               >> 7U)))))
                                                   : 
                                                  ((0x23U 
                                                    == 
                                                    (0x7fU 
                                                     & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                                                    ? 
                                                   (((- (IData)(
                                                                (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                                 >> 0x1fU))) 
                                                     << 0xcU) 
                                                    | ((0xfe0U 
                                                        & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                           >> 0x14U)) 
                                                       | (0x1fU 
                                                          & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                             >> 7U))))
                                                    : 
                                                   ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u)
                                                     ? 
                                                    (0xfffff000U 
                                                     & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)
                                                     : 
                                                    ((0x6fU 
                                                      == 
                                                      (0x7fU 
                                                       & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))
                                                      ? 
                                                     (((- (IData)(
                                                                  (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                                   >> 0x1fU))) 
                                                       << 0x14U) 
                                                      | (((0xff000U 
                                                           & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg) 
                                                          | (0x800U 
                                                             & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                                >> 9U))) 
                                                         | (0x7feU 
                                                            & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                               >> 0x14U))))
                                                      : 0U))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_jalr 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i) 
           & (0x67U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid 
        = __Vdly__tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid;
    vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_id_stall 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load) 
              & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
                 & ((0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr)) 
                    & ((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_8) 
                         | ((0x23U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                            | ((0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                               | ((~ (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                      >> 0xeU)) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_is_csr))))) 
                        & ((0x1fU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                     >> 0xfU)) == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr))) 
                       | (((0x33U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                           | ((0x23U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                              | (0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)))) 
                          & ((0x1fU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                       >> 0x14U)) == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_11 
        = ((0x6fU == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_jalr));
    tb_Htop__DOT__dut__DOT__btb_lookup_hit = ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__valid
                                               [(0xfU 
                                                 & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                                                    >> 2U))] 
                                               & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__tag
                                                  [
                                                  (0xfU 
                                                   & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                                                      >> 2U))] 
                                                  == 
                                                  (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                                                   >> 6U))) 
                                              & ((~ 
                                                  vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional
                                                  [
                                                  (0xfU 
                                                   & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                                                      >> 2U))]) 
                                                 | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__direction
                                                    [
                                                    (0xfU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                                                        >> 2U))] 
                                                    >> 1U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__btb_predict_next_pc 
        = ((IData)(tb_Htop__DOT__dut__DOT__btb_lookup_hit)
            ? ((IData)(tb_Htop__DOT__dut__DOT__btb_lookup_hit)
                ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target
               [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                         >> 2U))] : 0U) : ((IData)(4U) 
                                           + vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg));
}
