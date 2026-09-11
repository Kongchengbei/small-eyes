// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_Htop.h for the primary calling header

#include "Vtb_Htop__pch.h"
#include "Vtb_Htop___024root.h"

VL_ATTR_COLD void Vtb_Htop___024root___eval_static__TOP(Vtb_Htop___024root* vlSelf);

VL_ATTR_COLD void Vtb_Htop___024root___eval_static(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_static\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_Htop___024root___eval_static__TOP(vlSelf);
    vlSelfRef.__Vtrigprevexpr___TOP__tb_Htop__DOT__clk__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n__0 
        = vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n;
}

VL_ATTR_COLD void Vtb_Htop___024root___eval_static__TOP(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_static__TOP\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_Htop__DOT__clk = 0U;
    vlSelfRef.tb_Htop__DOT__rst = 1U;
    vlSelfRef.tb_Htop__DOT__ddr_rsp_valid = 0U;
    vlSelfRef.tb_Htop__DOT__ddr_rsp_rdata = 0U;
}

VL_ATTR_COLD void Vtb_Htop___024root___eval_initial__TOP(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_initial__TOP\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i = 0;
    // Body
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__i);
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta = 0U;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i = 0U;
    while (VL_GTS_III(32, 0x100U, tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i)) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem[(0xffU 
                                                                                & tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i)] = 0U;
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i 
            = ((IData)(1U) + tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__i);
    }
}

VL_ATTR_COLD void Vtb_Htop___024root___eval_final(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_final\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__stl(Vtb_Htop___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_Htop___024root___eval_phase__stl(Vtb_Htop___024root* vlSelf);

VL_ATTR_COLD void Vtb_Htop___024root___eval_settle(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_settle\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY(((0x64U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vtb_Htop___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("sim/tb_Htop.sv", 3, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtb_Htop___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__stl(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___dump_triggers__stl\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_Htop___024root___stl_sequent__TOP__0(Vtb_Htop___024root* vlSelf);

VL_ATTR_COLD void Vtb_Htop___024root___eval_stl(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_stl\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vtb_Htop___024root___stl_sequent__TOP__0(vlSelf);
    }
}

extern const VlUnpacked<CData/*3:0*/, 4096> Vtb_Htop__ConstPool__TABLE_ha0a8fb9d_0;

VL_ATTR_COLD void Vtb_Htop___024root___stl_sequent__TOP__0(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___stl_sequent__TOP__0\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__btb_lookup_hit;
    tb_Htop__DOT__dut__DOT__btb_lookup_hit = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__dmem_valid;
    tb_Htop__DOT__dut__DOT__dmem_valid = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__dmem_rdata;
    tb_Htop__DOT__dut__DOT__dmem_rdata = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__dbg_mem_ready_go;
    tb_Htop__DOT__dut__DOT__dbg_mem_ready_go = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken;
    tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire;
    tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2 = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active = 0;
    QData/*32:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18 = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata;
    tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata = 0;
    CData/*0:0*/ __VdfgRegularize_h3c5bdd75_0_4;
    __VdfgRegularize_h3c5bdd75_0_4 = 0;
    CData/*0:0*/ __VdfgRegularize_h3c5bdd75_0_6;
    __VdfgRegularize_h3c5bdd75_0_6 = 0;
    CData/*2:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__Vfuncout;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr = 0;
    CData/*2:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__Vfuncout;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr = 0;
    SData/*11:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_req = (4U 
                                                   == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__ret_num_add_one 
        = ((2U & (VL_REDXOR_2(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num) 
                  << 1U)) | (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed 
        = ((5U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
           | (7U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state_is_refill 
        = (0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__ret_num_add_one 
        = ((2U & (VL_REDXOR_2(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num) 
                  << 1U)) | (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_m 
        = (IData)((0x2000033U == (0xfe00007fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_next 
        = VL_SHIFTL_III(32,32,32, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work, 1U);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_last 
        = (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num));
    vlSelfRef.tb_Htop__DOT__ddr_rsp_ready = ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                             | ((5U 
                                                 == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                                | (2U 
                                                   == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_last 
        = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_len_reg) 
           == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat));
    __Vtableidx1 = (((0x20U == (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                >> 0x19U)) << 0xbU) 
                    | (((0U == (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                >> 0x19U)) << 0xaU) 
                       | ((0x380U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                     >> 5U)) | (0x7fU 
                                                & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_alu_op = Vtb_Htop__ConstPool__TABLE_ha0a8fb9d_0
        [__Vtableidx1];
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_addr = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)
          ? ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
              << 0xcU) | (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index) 
                           << 4U) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset)))
          : ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
              << 0xcU) | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index) 
                          << 4U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in 
        = (3U & (~ ((2U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                           << 1U)) | (1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_ready 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold)) 
           & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_req = (
                                                   (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer)) 
                                                   & (8U 
                                                      == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_9 
        = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
           | (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)));
    tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18 
        = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
           | (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[0U][0U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[0U][1U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[0U][2U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[0U][3U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[1U][0U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[1U][1U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[1U][2U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[1U][3U] 
        = ((- (IData)((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)))) 
           & vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_src 
        = ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op))
            ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_imm)
            : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_15 
        = ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
            << 0xcU) | (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                         << 4U) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift 
        = (((QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_work)) 
            << 1U) | (QData)((IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work 
                                      >> 0x1fU))));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_addr 
        = (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_base_reg 
           + VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat), 2U));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12 
        = ((2U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                  << 1U)) | (1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta));
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
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_addr 
        = (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_base_reg 
           + VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat), 2U));
    if ((1U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))) {
        vlSelfRef.tb_Htop__DOT__ddr_req_wstrb = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_wmask_reg;
        vlSelfRef.tb_Htop__DOT__ddr_req_wdata = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_wdata_reg;
        vlSelfRef.tb_Htop__DOT__ddr_req_addr = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_addr_reg;
    } else {
        vlSelfRef.tb_Htop__DOT__ddr_req_wstrb = vlSelfRef.tb_Htop__DOT__axi_wstrb;
        vlSelfRef.tb_Htop__DOT__ddr_req_wdata = vlSelfRef.tb_Htop__DOT__axi_wdata;
        vlSelfRef.tb_Htop__DOT__ddr_req_addr = ((4U 
                                                 == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))
                                                 ? vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_addr
                                                 : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_addr);
    }
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_last 
        = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_len_reg) 
           == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat));
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op) 
            & ((3U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                      >> 2U)) == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num)))
            ? (((((8U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb))
                   ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata 
                      >> 0x18U) : (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg 
                                   >> 0x18U)) << 0x18U) 
                | (0xff0000U & (((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb))
                                  ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata 
                                     >> 0x10U) : (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg 
                                                  >> 0x10U)) 
                                << 0x10U))) | ((0xff00U 
                                                & (((2U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb))
                                                     ? 
                                                    (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata 
                                                     >> 8U)
                                                     : 
                                                    (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg 
                                                     >> 8U)) 
                                                   << 8U)) 
                                               | (0xffU 
                                                  & ((1U 
                                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb))
                                                      ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata
                                                      : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg))))
            : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[0U][0U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way)) 
           & (0U == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[0U][1U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way)) 
           & (4U == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[0U][2U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way)) 
           & (8U == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[0U][3U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way)) 
           & (0xcU == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[1U][0U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way) 
               >> 1U)) & (0U == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[1U][1U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way) 
               >> 1U)) & (4U == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[1U][2U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way) 
               >> 1U)) & (8U == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[1U][3U] 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
            & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way) 
               >> 1U)) & (0xcU == (0xcU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u 
        = ((0x37U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | (0x17U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__wb_reg_wen = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_reg_wen_reg) 
         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__wb_valid));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i 
        = ((0x13U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | ((3U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
              | (0x67U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_0 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load) 
           | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store));
    vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n 
        = (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__rst)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2 = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2_is_imm)
          ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_imm
          : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_pc)
            ? vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc
            : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_zero)
                ? 0U : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_4 
        = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
           & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
              == (0xfffffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
                              >> 1U))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_7 
        = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
           & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
              == (0xfffffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                              >> 1U))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_3 
        = ((5U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
           | (6U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed 
        = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)) 
           | (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
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
    tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
           & (0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = 0U;
    if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = 1U;
    }
    if ((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in) 
          >> 1U) & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way)))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = 2U;
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_addr = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)
          ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_15
          : ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
              << 0xcU) | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                          << 4U)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_bit 
        = (tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_shift 
           >= (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__divisor_work)));
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr 
        = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_addr;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__Vfuncout 
        = (((0x40000000U <= __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr) 
            & (0x40001000U > __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr))
            ? 1U : (((0x80000000U <= __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr) 
                     & (0xc0000000U > __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr))
                     ? 2U : 0U));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_region 
        = __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__Vfuncout;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 0U;
    if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12)))) {
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 1U;
    }
    if (((~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12) 
             >> 1U)) & (0U == (IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way)))) {
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 2U;
    }
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
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr 
        = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_addr;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__Vfuncout 
        = (((0x40000000U <= __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr) 
            & (0x40001000U > __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr))
            ? 1U : (((0x80000000U <= __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr) 
                     & (0xc0000000U > __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr))
                     ? 2U : 0U));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_region 
        = __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__Vfuncout;
    vlSelfRef.tb_Htop__DOT__axi_rlast = ((3U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                         & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_last));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[0U][0U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[0U][1U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[0U][2U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[0U][3U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[1U][0U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[1U][1U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[1U][2U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[1U][3U] 
        = (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state))) 
            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata) 
           | ((- (IData)((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))) 
              & tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data));
    vlSelfRef.tb_Htop__DOT__dut__DOT__btb_predict_next_pc 
        = ((IData)(tb_Htop__DOT__dut__DOT__btb_lookup_hit)
            ? ((IData)(tb_Htop__DOT__dut__DOT__btb_lookup_hit)
                ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_btb__DOT__target
               [(0xfU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg 
                         >> 2U))] : 0U) : ((IData)(4U) 
                                           + vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg));
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
    vlSelfRef.tb_Htop__DOT__axi_wready = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (4U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__axi_awready = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                           & ((0U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                              & ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid)) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state)))));
    vlSelfRef.tb_Htop__DOT__axi_bvalid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (6U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__axi_rvalid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (3U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result = 0U;
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_en) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
            = ((8U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                ? ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                    ? 0U : ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                             ? 0U : ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                                      ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                                         & tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)
                                      : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                                         | tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2))))
                : ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                    ? ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                        ? ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                            ? VL_SHIFTRS_III(32,32,5, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1, 
                                             (0x1fU 
                                              & tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2))
                            : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                               >> (0x1fU & tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)))
                        : ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                            ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                               ^ tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)
                            : ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                                < tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)
                                ? 1U : 0U))) : ((2U 
                                                 & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                                                 ? 
                                                ((1U 
                                                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                                                  ? 
                                                 (VL_LTS_III(32, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1, tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)
                                                   ? 1U
                                                   : 0U)
                                                  : 
                                                 (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                                                  << 
                                                  (0x1fU 
                                                   & tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)))
                                                 : 
                                                ((1U 
                                                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op))
                                                  ? 
                                                 ((IData)(1U) 
                                                  + 
                                                  (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                                                   + 
                                                   (~ tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)))
                                                  : 
                                                 (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 
                                                  + tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2)))));
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_7) 
            << 1U) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_4));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed)
            ? (((QData)((IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                                 >> 0x1fU))) << 0x20U) 
               | (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)))
            : (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_x_signed 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed) 
           | (3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op)));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way 
        = (3U & ((0U != (3U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12))))
                  ? (IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way)
                  : ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))
                      ? ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))
                          ? 2U : 8U) : 1U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_6 
        = (((0U == (0x1fU & VL_SHIFTL_III(7,7,32, (3U 
                                                   & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                      >> 2U)), 5U)))
             ? 0U : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data
                     [0U][(((IData)(0x1fU) + (0x7fU 
                                              & VL_SHIFTL_III(7,7,32, 
                                                              (3U 
                                                               & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                                  >> 2U)), 5U))) 
                           >> 5U)] << ((IData)(0x20U) 
                                       - (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                                (3U 
                                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                                    >> 2U)), 5U))))) 
           | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data
              [0U][(3U & (VL_SHIFTL_III(7,7,32, (3U 
                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                    >> 2U)), 5U) 
                          >> 5U))] >> (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                             (3U 
                                                              & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                                 >> 2U)), 5U))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_7 
        = (((0U == (0x1fU & VL_SHIFTL_III(7,7,32, (3U 
                                                   & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                      >> 2U)), 5U)))
             ? 0U : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data
                     [1U][(((IData)(0x1fU) + (0x7fU 
                                              & VL_SHIFTL_III(7,7,32, 
                                                              (3U 
                                                               & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                                  >> 2U)), 5U))) 
                           >> 5U)] << ((IData)(0x20U) 
                                       - (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                                (3U 
                                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                                    >> 2U)), 5U))))) 
           | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data
              [1U][(3U & (VL_SHIFTL_III(7,7,32, (3U 
                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                    >> 2U)), 5U) 
                          >> 5U))] >> (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                             (3U 
                                                              & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                                                 >> 2U)), 5U))));
    vlSelfRef.tb_Htop__DOT__ddr_addr_valid = ((0x80000000U 
                                               <= vlSelfRef.tb_Htop__DOT__ddr_req_addr) 
                                              & (0x4000U 
                                                 > 
                                                 VL_SHIFTR_III(32,32,32, 
                                                               (vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                                                - (IData)(0x80000000U)), 2U)));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT____VdfgRegularize_h5abff60f_0_5 
        = ((4U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
           & ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_region)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__axi_wvalid)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_last = 
        ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg)) 
         & (IData)(vlSelfRef.tb_Htop__DOT__axi_rlast));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_last = 
        ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg) 
         & (IData)(vlSelfRef.tb_Htop__DOT__axi_rlast));
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
    vlSelfRef.tb_Htop__DOT__axi_arready = ((~ (IData)(vlSelfRef.tb_Htop__DOT__axi_awvalid)) 
                                           & (IData)(vlSelfRef.tb_Htop__DOT__axi_awready));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_rdy = (1U 
                                                   & (~ 
                                                      ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state) 
                                                       | ((~ 
                                                           ((IData)(vlSelfRef.tb_Htop__DOT__axi_bready) 
                                                            & (IData)(vlSelfRef.tb_Htop__DOT__axi_bvalid))) 
                                                          & (0U 
                                                             != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg)) 
           & (IData)(vlSelfRef.tb_Htop__DOT__axi_rvalid));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg) 
           & (IData)(vlSelfRef.tb_Htop__DOT__axi_rvalid));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra 
        = (0xffU & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18)
                     ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                        >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[0U][0U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [0U][0U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[0U][1U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [0U][1U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[0U][2U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [0U][2U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[0U][3U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [0U][3U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[1U][0U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [1U][0U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[1U][1U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [1U][1U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[1U][2U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [1U][2U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[1U][3U] 
        = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                    [1U][3U] ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)
                     : ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                         ? (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                            >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index))));
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup 
        = (1U & (~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
                    & (((3U & (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                               >> 2U)) == (3U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset) 
                                                 >> 2U))) 
                       | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index) 
                          == (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                                       >> 4U)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)) 
           & (0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit)));
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
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[0U] 
            = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata;
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[1U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[2U] = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[3U] = 0U;
    } else {
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[0U] 
            = (((- (IData)((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way)))) 
                & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                [0U][0U]) | ((- (IData)((1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
                                               >> 1U)))) 
                             & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                             [1U][0U]));
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[1U] 
            = (((- (IData)((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way)))) 
                & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                [0U][1U]) | ((- (IData)((1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
                                               >> 1U)))) 
                             & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                             [1U][1U]));
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[2U] 
            = (((- (IData)((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way)))) 
                & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                [0U][2U]) | ((- (IData)((1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
                                               >> 1U)))) 
                             & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                             [1U][2U]));
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[3U] 
            = (((- (IData)((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way)))) 
                & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                [0U][3U]) | ((- (IData)((1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
                                               >> 1U)))) 
                             & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                             [1U][3U]));
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_10 
        = (((0U == (0x1fU & VL_SHIFTL_III(7,7,32, (3U 
                                                   & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                      >> 2U)), 5U)))
             ? 0U : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                     [0U][(((IData)(0x1fU) + (0x7fU 
                                              & VL_SHIFTL_III(7,7,32, 
                                                              (3U 
                                                               & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                                  >> 2U)), 5U))) 
                           >> 5U)] << ((IData)(0x20U) 
                                       - (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                                (3U 
                                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                                    >> 2U)), 5U))))) 
           | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
              [0U][(3U & (VL_SHIFTL_III(7,7,32, (3U 
                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                    >> 2U)), 5U) 
                          >> 5U))] >> (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                             (3U 
                                                              & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                                 >> 2U)), 5U))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_11 
        = (((0U == (0x1fU & VL_SHIFTL_III(7,7,32, (3U 
                                                   & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                      >> 2U)), 5U)))
             ? 0U : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
                     [1U][(((IData)(0x1fU) + (0x7fU 
                                              & VL_SHIFTL_III(7,7,32, 
                                                              (3U 
                                                               & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                                  >> 2U)), 5U))) 
                           >> 5U)] << ((IData)(0x20U) 
                                       - (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                                (3U 
                                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                                    >> 2U)), 5U))))) 
           | (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data
              [1U][(3U & (VL_SHIFTL_III(7,7,32, (3U 
                                                 & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                    >> 2U)), 5U) 
                          >> 5U))] >> (0x1fU & VL_SHIFTL_III(7,7,32, 
                                                             (3U 
                                                              & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                                                 >> 2U)), 5U))));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_d 
        = (0U != ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way) 
                  & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg
                     [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index] 
                     | ((- (IData)((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                                     == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)) 
                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state)))) 
                        & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way)))));
    vlSelfRef.tb_Htop__DOT__ddr_req_write = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT____VdfgRegularize_h5abff60f_0_5) 
                                             | ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_read_reg)) 
                                                & (1U 
                                                   == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))));
    vlSelfRef.tb_Htop__DOT__ddr_req_valid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                             & (((1U 
                                                  == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_region))) 
                                                | ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT____VdfgRegularize_h5abff60f_0_5) 
                                                   | (1U 
                                                      == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state)))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_id_stall)) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_rdy = (
                                                   (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_req)) 
                                                   & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_rdy));
    __VdfgRegularize_h3c5bdd75_0_6 = ((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                                      & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)) 
                                         & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_last) 
                                            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid))));
    tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_replace_way) 
           & (- (IData)(((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)) 
                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid)))));
    __VdfgRegularize_h3c5bdd75_0_4 = ((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                      & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)) 
                                         & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_last) 
                                            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid))));
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
           & (- (IData)(((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)) 
                         & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid)))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_rsp_valid 
        = ((((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit)) 
            | (((4U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer) 
                   & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state)))) 
               | ((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                  & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid) 
                     & (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num) 
                         == (3U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset) 
                                   >> 2U))) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)))))) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold));
    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start 
            = (1U & (~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done) 
                        | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started))));
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_value 
            = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op))
                ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[0U]
                : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[1U]);
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire 
            = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started) 
               & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__done_q));
    } else {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_value 
            = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div)
                ? ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_3)
                    ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg
                    : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg)
                : ((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel))
                    ? ((IData)(4U) + vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc)
                    : ((3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel))
                        ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data
                        : ((0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel))
                            ? vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result
                            : 0U))));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire = 0U;
    }
    tb_Htop__DOT__dut__DOT__dmem_rdata = ((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                                           ? (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_4))) 
                                               & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_10) 
                                              | ((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_7))) 
                                                 & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_11))
                                           : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__wea 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_replace_way) 
           & (IData)(__VdfgRegularize_h3c5bdd75_0_6));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__1__KET____DOT__u__wea 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_replace_way) 
            >> 1U) & (IData)(__VdfgRegularize_h3c5bdd75_0_6));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[0U][0U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & ((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                 & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[0U][1U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & ((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                 & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[0U][2U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & ((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                 & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[0U][3U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & ((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                 & (3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[1U][0U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & (((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                  >> 1U) & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[1U][1U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & (((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                  >> 1U) & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[1U][2U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & (((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                  >> 1U) & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[1U][3U] 
        = (0xfU & (- (IData)(((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                              & (((IData)(tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en) 
                                  >> 1U) & (3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num)))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__wea 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
           & (IData)(__VdfgRegularize_h3c5bdd75_0_4));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__1__KET____DOT__u__wea 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
            >> 1U) & (IData)(__VdfgRegularize_h3c5bdd75_0_4));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[0U][0U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [0U][0U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                    & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[0U][1U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [0U][1U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                    & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[0U][2U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [0U][2U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                    & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[0U][3U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [0U][3U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                    & (3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[1U][0U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [1U][0U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & (((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                     >> 1U) & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[1U][1U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [1U][1U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & (((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                     >> 1U) & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[1U][2U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [1U][2U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & (((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                     >> 1U) & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[1U][3U] 
        = (0xfU & (((- (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank
                               [1U][3U])) & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb)) 
                   | (- (IData)(((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                                 & (((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en) 
                                     >> 1U) & (3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))))))));
    tb_Htop__DOT__dut__DOT__dbg_mem_ready_go = (1U 
                                                & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid)) 
                                                   | ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_is_load)) 
                                                      | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_rsp_valid))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_6 
        = (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul)) 
                 | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done) 
                    | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire))));
    tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata 
        = VL_SHIFTR_III(32,32,32, tb_Htop__DOT__dut__DOT__dmem_rdata, 
                        VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_offset), 3U));
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_to_wb_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid) 
           & (IData)(tb_Htop__DOT__dut__DOT__dbg_mem_ready_go));
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid)) 
               | (IData)(tb_Htop__DOT__dut__DOT__dbg_mem_ready_go)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_forward_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_reg_wen) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
              & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_is_load)) 
                 & ((0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr)) 
                    & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_6) 
                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_7))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_ex_ready_go 
        = (1U & (((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid)) 
                  | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_6)) 
                 & (((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid)) 
                     | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_7)) 
                    & ((~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
                           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_0))) 
                       | ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                          & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup) 
                             & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_wb_data = 
        ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_wb_sel))
          ? ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3))
              ? ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3))
                  ? 0U : ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3))
                           ? (0xffffU & tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata)
                           : (0xffU & tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata)))
              : ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3))
                  ? ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3))
                      ? 0U : tb_Htop__DOT__dut__DOT__dmem_rdata)
                  : ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3))
                      ? (((- (IData)((1U & (tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata 
                                            >> 0xfU)))) 
                          << 0x10U) | (0xffffU & tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata))
                      : (((- (IData)((1U & (tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata 
                                            >> 7U)))) 
                          << 8U) | (0xffU & tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata)))))
          : vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_ex_wb_value);
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_ex_ready_go));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid)) 
               | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_ex_ready_go) 
                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2 = (((0U 
                                                   != 
                                                   (0x1fU 
                                                    & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                       >> 0x14U))) 
                                                  & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_forward_valid) 
                                                     & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr) 
                                                        == 
                                                        (0x1fU 
                                                         & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                            >> 0x14U)))))
                                                  ? vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_value
                                                  : 
                                                 (((0U 
                                                    != 
                                                    (0x1fU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0x14U))) 
                                                   & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_forward_valid) 
                                                      & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_rd_addr) 
                                                         == 
                                                         (0x1fU 
                                                          & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                             >> 0x14U)))))
                                                   ? vlSelfRef.tb_Htop__DOT__dut__DOT__mem_wb_data
                                                   : 
                                                  ((0U 
                                                    == 
                                                    (0x1fU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0x14U)))
                                                    ? 0U
                                                    : 
                                                   (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__wb_reg_wen) 
                                                     & ((0x1fU 
                                                         & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                            >> 0x14U)) 
                                                        == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg)))
                                                     ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_data_reg
                                                     : 
                                                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf
                                                    [
                                                    (0x1fU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0x14U))]))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1 = (((0U 
                                                   != 
                                                   (0x1fU 
                                                    & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                       >> 0xfU))) 
                                                  & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_forward_valid) 
                                                     & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_rd_addr) 
                                                        == 
                                                        (0x1fU 
                                                         & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                            >> 0xfU)))))
                                                  ? vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_value
                                                  : 
                                                 (((0U 
                                                    != 
                                                    (0x1fU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0xfU))) 
                                                   & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_forward_valid) 
                                                      & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_rd_addr) 
                                                         == 
                                                         (0x1fU 
                                                          & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                             >> 0xfU)))))
                                                   ? vlSelfRef.tb_Htop__DOT__dut__DOT__mem_wb_data
                                                   : 
                                                  ((0U 
                                                    == 
                                                    (0x1fU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0xfU)))
                                                    ? 0U
                                                    : 
                                                   (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__wb_reg_wen) 
                                                     & ((0x1fU 
                                                         & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                            >> 0xfU)) 
                                                        == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg)))
                                                     ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_data_reg
                                                     : 
                                                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf
                                                    [
                                                    (0x1fU 
                                                     & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg 
                                                        >> 0xfU))]))));
    tb_Htop__DOT__dut__DOT__dmem_valid = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_0));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid)) 
               | ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_id_stall)) 
                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
         & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_csr) 
            & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin)));
    tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid) 
                                                   & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_ecall) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_mret) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_redirect_pc 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_jalr)
            ? (0xfffffffeU & (vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1 
                              + vlSelfRef.tb_Htop__DOT__dut__DOT__id_imm))
            : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg 
               + vlSelfRef.tb_Htop__DOT__dut__DOT__id_imm));
    tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken 
        = ((IData)((0x63U == (0x707fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)))
            ? (vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1 
               == vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2)
            : ((IData)((0x1063U == (0x707fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)))
                ? (vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1 
                   != vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2)
                : ((0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                   & ((IData)(((0x5000U == (0x7000U 
                                            & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                               & VL_GTES_III(32, vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1, vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2))) 
                      | ((IData)(((0x7000U == (0x7000U 
                                               & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                                  & (vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1 
                                     >= vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2))) 
                         | ((IData)(((0x4000U == (0x7000U 
                                                  & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                                     & VL_LTS_III(32, vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1, vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2))) 
                            | (IData)(((0x6000U == 
                                        (0x7000U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
                                       & (vlSelfRef.tb_Htop__DOT__dut__DOT__id_src1 
                                          < vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2)))))))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__accept 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold)) 
           & ((IData)(tb_Htop__DOT__dut__DOT__dmem_valid) 
              & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup) 
                 & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wen = ((IData)(tb_Htop__DOT__dut__DOT__dmem_valid) 
                                                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen = 0U;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data;
    if (tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen 
            = ((1U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op) 
                      >> 1U)) || (1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op)));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data 
            = ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op))
                ? ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op))
                    ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data 
                       & (~ vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_src))
                    : (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data 
                       | vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_src))
                : ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op))
                    ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_src
                    : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data));
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall) 
           | (IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret));
    vlSelfRef.tb_Htop__DOT__dut__DOT__btb_update_taken 
        = ((0x63U != (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | (IData)(tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken));
    vlSelfRef.tb_Htop__DOT__dut__DOT__actual_next_pc 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_11) 
            | ((0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
               & (IData)(tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken)))
            ? vlSelfRef.tb_Htop__DOT__dut__DOT__id_redirect_pc
            : ((IData)(4U) + vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active 
        = ((IData)(tb_Htop__DOT__dut__DOT__dmem_valid) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wen));
    vlSelfRef.tb_Htop__DOT__dut__DOT__btb_update_valid 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
           & ((IData)(tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire) 
              & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_11) 
                 | (0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)))));
    vlSelfRef.tb_Htop__DOT__debug_flush_pc = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)
                                               ? ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall)
                                                   ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtvec
                                                   : 
                                                  ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret)
                                                    ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mepc
                                                    : 0U))
                                               : vlSelfRef.tb_Htop__DOT__dut__DOT__actual_next_pc);
    vlSelfRef.tb_Htop__DOT__dut__DOT__flush = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid) 
                                               | ((IData)(tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire) 
                                                  & (vlSelfRef.tb_Htop__DOT__dut__DOT__actual_next_pc 
                                                     != vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_predict_next_pc)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_word 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active) 
           & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_half 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active) 
           & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_byte 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active) 
           & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_valid 
        = (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush)) 
                 & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending)) 
                    & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid)) 
                       | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_allowin)))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_pc = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush)
                                                    ? vlSelfRef.tb_Htop__DOT__debug_flush_pc
                                                    : 
                                                   ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__force_fetch)
                                                     ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_ifu__DOT__forced_fetch_pc
                                                     : vlSelfRef.tb_Htop__DOT__dut__DOT__btb_predict_next_pc));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wmask = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_word)
          ? 0xfU : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_half)
                     ? ((0U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                         ? 3U : ((1U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                  ? 6U : ((2U == (3U 
                                                  & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                           ? 0xcU : 8U)))
                     : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_byte)
                         ? ((0U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                             ? 1U : ((1U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                      ? 2U : ((2U == 
                                               (3U 
                                                & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                               ? 4U
                                               : 8U)))
                         : 0U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__accept 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_valid) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_ready));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold)
            ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold_pc
            : vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_pc);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra 
        = (0xffU & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_9)
                     ? (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U) : (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index)));
    if ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][0U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][1U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][2U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][3U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][0U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][1U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][2U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][3U] 
            = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                        >> 4U));
    } else {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][0U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][1U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][2U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[0U][3U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][0U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][1U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][2U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[1U][3U] 
            = (0xffU & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index));
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_1 
        = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
           & ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
               >> 0xcU) == (0xfffffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
                                        >> 1U))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_3 
        = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
           & ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
               >> 0xcU) == (0xfffffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                                        >> 1U))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__cache_hit 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)) 
           & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_3) 
              | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_1)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__if_resp_valid 
        = ((((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__cache_hit)) 
            | ((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
               & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid) 
                  & (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num) 
                      == (3U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset) 
                                >> 2U))) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en))))) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold));
}

VL_ATTR_COLD void Vtb_Htop___024root___eval_triggers__stl(Vtb_Htop___024root* vlSelf);

VL_ATTR_COLD bool Vtb_Htop___024root___eval_phase__stl(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_phase__stl\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtb_Htop___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vtb_Htop___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__act(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___dump_triggers__act\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge tb_Htop.clk)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(negedge tb_Htop.__Vcellinp__u_mem_backend__rst_n)\n");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__nba(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___dump_triggers__nba\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge tb_Htop.clk)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(negedge tb_Htop.__Vcellinp__u_mem_backend__rst_n)\n");
    }
    if ((4ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_Htop___024root___ctor_var_reset(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___ctor_var_reset\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->name());
    vlSelf->tb_Htop__DOT__clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17967191666815220217ull);
    vlSelf->tb_Htop__DOT__rst = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6313632773963242916ull);
    vlSelf->tb_Htop__DOT__axi_awaddr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2807996582593450716ull);
    vlSelf->tb_Htop__DOT__axi_awlen = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 14588592058888671260ull);
    vlSelf->tb_Htop__DOT__axi_awvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2834071932864326073ull);
    vlSelf->tb_Htop__DOT__axi_awready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18106783560979154422ull);
    vlSelf->tb_Htop__DOT__axi_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6727401227484298508ull);
    vlSelf->tb_Htop__DOT__axi_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 3094505674833692548ull);
    vlSelf->tb_Htop__DOT__axi_wlast = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 386255368731708352ull);
    vlSelf->tb_Htop__DOT__axi_wvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6466921918570340021ull);
    vlSelf->tb_Htop__DOT__axi_wready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9190823710620449305ull);
    vlSelf->tb_Htop__DOT__axi_bvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14316383526662439491ull);
    vlSelf->tb_Htop__DOT__axi_bready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9924332847346792116ull);
    vlSelf->tb_Htop__DOT__axi_arid = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15163338554125793413ull);
    vlSelf->tb_Htop__DOT__axi_araddr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10697291901529761243ull);
    vlSelf->tb_Htop__DOT__axi_arlen = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 12881481074356023687ull);
    vlSelf->tb_Htop__DOT__axi_arvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8854015454132693692ull);
    vlSelf->tb_Htop__DOT__axi_arready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9155531595502614642ull);
    vlSelf->tb_Htop__DOT__axi_rlast = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14107938611310032690ull);
    vlSelf->tb_Htop__DOT__axi_rvalid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13727594681569460645ull);
    vlSelf->tb_Htop__DOT__axi_rready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10130446941037788380ull);
    vlSelf->tb_Htop__DOT__ddr_req_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2359967575781805225ull);
    vlSelf->tb_Htop__DOT__ddr_req_write = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15394340870956594340ull);
    vlSelf->tb_Htop__DOT__ddr_req_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17599656920571533136ull);
    vlSelf->tb_Htop__DOT__ddr_req_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8180595347228374123ull);
    vlSelf->tb_Htop__DOT__ddr_req_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 8937979644284240113ull);
    vlSelf->tb_Htop__DOT__ddr_rsp_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2895571889833171172ull);
    vlSelf->tb_Htop__DOT__ddr_rsp_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2874449399084428000ull);
    vlSelf->tb_Htop__DOT__ddr_rsp_rdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3049108943997412275ull);
    for (int __Vi0 = 0; __Vi0 < 16384; ++__Vi0) {
        vlSelf->tb_Htop__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10528041085173420772ull);
    }
    vlSelf->tb_Htop__DOT__ddr_addr_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16093606226352276062ull);
    vlSelf->tb_Htop__DOT__cycle_count = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5658307143809975446ull);
    vlSelf->tb_Htop__DOT__debug_flush_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13946928873234665122ull);
    vlSelf->tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15720743261563061142ull);
    vlSelf->tb_Htop__DOT__dut__DOT__if_req_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15573176042621596913ull);
    vlSelf->tb_Htop__DOT__dut__DOT__if_req_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5177780625091382798ull);
    vlSelf->tb_Htop__DOT__dut__DOT__if_req_ready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6845078442694754457ull);
    vlSelf->tb_Htop__DOT__dut__DOT__if_resp_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16276544633959460858ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_allowin = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3530003225598517722ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_to_ex_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16244681767313392131ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_src1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2653285534977179428ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_src2 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3170844637825851872ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_imm = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8998920374042224628ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_alu_op = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 6600136680793344242ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_is_csr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4676754302176249099ull);
    vlSelf->tb_Htop__DOT__dut__DOT__id_redirect_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 479222761534889583ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3491868301814983463ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_ins = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14837261428357975368ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6966778539706601744ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_allowin = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17667028655634982705ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_to_mem_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6883129849538622211ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_rd_addr = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 14508359759283554035ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_is_load = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14596203471975627170ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_mem_funct3 = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 8660489020604797309ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_reg_wen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10592353175231819597ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_wb_sel = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 5004930566297688746ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_result = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10633759667815782912ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_wb_value = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17650076468499325859ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ex_forward_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9616145488652271359ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_ins = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2502979469935474294ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_allowin = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15643337699558557362ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_to_wb_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16212747382921140674ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_rd_addr = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 18068984577529090783ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_reg_wen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5898175771168318663ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_wb_data = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13005392292891357026ull);
    vlSelf->tb_Htop__DOT__dut__DOT__mem_forward_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4727818792406623454ull);
    vlSelf->tb_Htop__DOT__dut__DOT__wb_ins = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2115328436580751013ull);
    vlSelf->tb_Htop__DOT__dut__DOT__wb_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2302585286627843743ull);
    vlSelf->tb_Htop__DOT__dut__DOT__wb_reg_wen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11155131544206816966ull);
    vlSelf->tb_Htop__DOT__dut__DOT__flush = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4856985180408644107ull);
    vlSelf->tb_Htop__DOT__dut__DOT__btb_update_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11819534291157667986ull);
    vlSelf->tb_Htop__DOT__dut__DOT__btb_update_taken = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16847172002782074023ull);
    vlSelf->tb_Htop__DOT__dut__DOT__btb_predict_next_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7591013697411910712ull);
    vlSelf->tb_Htop__DOT__dut__DOT__actual_next_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 998167991593412521ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dmem_wen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1967028406465478447ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dmem_wmask = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7938725429172341540ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dmem_rsp_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16429756621288516589ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dc_rd_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12518962979432282979ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dc_rd_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14320837697856379738ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dc_rd_rdy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 416647551268931902ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dc_ret_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8209331130481030617ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dc_ret_last = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16489649254589394455ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dc_wr_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1531167021425263501ull);
    VL_SCOPED_RAND_RESET_W(128, vlSelf->tb_Htop__DOT__dut__DOT__dc_wr_data, __VscopeHash, 6849404764522433803ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ic_rd_req = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 185462058849750219ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ic_rd_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5017131240599396033ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ic_rd_rdy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16144027937541114701ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ic_ret_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16743238967883153091ull);
    vlSelf->tb_Htop__DOT__dut__DOT__ic_ret_last = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6435594981218376186ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dbg_id_stall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13500564180067083837ull);
    vlSelf->tb_Htop__DOT__dut__DOT__dbg_ex_ready_go = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16099100191453558793ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_pc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16957597796893701183ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_ins_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 18201361848793538737ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3355171222860842905ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__fetch_pending = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12993321687724821678ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__forced_fetch_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12734125584442057704ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__force_fetch = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7712848341841739617ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_ifu__DOT__if_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16895361751800489272ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__hold = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6802220572212455339ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__hold_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10575414814812957682ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3688530012775843482ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 14794688989501977997ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__accept = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4514323678850165671ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2849080202503465794ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 9825675988102416731ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag = VL_SCOPED_RAND_RESET_I(20, __VscopeHash, 6454137228617958602ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 18370622868386795639ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_replace_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 13605644335962509311ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4719352540839791919ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__ret_num_add_one = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 2105751743521035725ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__rd_req_buffer = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7097472269364050779ull);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_addra[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 18384221595997163077ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_dina[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1946837488771441590ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_douta[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10235505407438861502ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__way_bank_wea[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 4036346262178186741ull);
        }
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__cache_hit = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12745171868398644662ull);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        VL_SCOPED_RAND_RESET_W(128, vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__way_data[__Vi0], __VscopeHash, 5605981139812301529ull);
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 18071222212430089532ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 1772289129783120139ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9223427349785320832ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7695375827203785044ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15024877332502993020ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6374032259382067872ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17692403230515108770ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5750457621462623396ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1047160436212271541ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7981696329301081419ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__wea = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17079410166078421568ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 2244711873611260369ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 1156952898126104838ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__tagv_ram_way__BRA__1__KET____DOT__u__wea = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10364466834296527110ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 423773325393372496ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_1 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14452996995503891612ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_3 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6079164081513338280ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_6 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7773412566764239950ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_7 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14758613932552406496ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_9 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6498185738424749952ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 13158680336167026140ull);
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3934681966792578965ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5065362471121254672ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9242081954155418778ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10104086720289615137ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5819410791318368651ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12177966511866340701ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4911741410654577416ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16359748645074053804ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 1828458725886537648ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_icache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 17678166930063814190ull);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_btb__DOT__valid[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12264646704508060084ull);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_btb__DOT__tag[__Vi0] = VL_SCOPED_RAND_RESET_I(26, __VscopeHash, 10452507966517165711ull);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_btb__DOT__target[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17095264808459137568ull);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_btb__DOT__direction[__Vi0] = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3646528471321802000ull);
    }
    for (int __Vi0 = 0; __Vi0 < 16; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_btb__DOT__is_conditional[__Vi0] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14033873823203929831ull);
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 314903803230314421ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4334262536557946211ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 6549329932851431617ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_jalr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2459123532155061101ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__id_predict_next_pc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12077706646568924636ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__type_i = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6519181528143291566ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__type_u = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4991643204705555159ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__id_is_m = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9320045696168656985ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_8 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10370944558941015096ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_11 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8267658863657217564ull);
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_idu__DOT__u_rf__DOT__rf[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4019361006478121635ull);
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 786823693631964263ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_started = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5678248756810815333ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_div_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2030835966077462000ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_started = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15357286702042017967ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_mul_done = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17448436235030644305ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_imm = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4785773079464748336ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17816569602056270550ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17948777176152328477ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_op = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 9164727900681493141ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_alu_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9490103024802903203ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_pc = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12409540605626148221ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src1_is_zero = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9235284785198258594ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2_is_imm = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 17013160325545695880ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14088699094955774955ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_csr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10941768385265785393ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_op = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 13267447518611188289ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_addr = VL_SCOPED_RAND_RESET_I(12, __VscopeHash, 2824545568026758594ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_csr_imm = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 12843130818515857854ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_ecall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9297560909725215832ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_mret = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11814816252884571864ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16004273516119214196ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9983528043039056361ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_start = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6139051218257803960ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_done_fire = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1897125349862510503ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14221644486506476160ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__div_start = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14354743792472270106ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__div_done_fire = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1407736920433447541ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__div_signed = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10218364187809619383ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src1 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2700018795621908691ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_ecall = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2639889202232596728ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14940298009398394832ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__store_byte = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3950916929229774184ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__store_half = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 635098022240979005ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__store_word = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10001520812905660221ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_0 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1939505769213869723ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_3 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5306316929431838917ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_6 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14475179528913050800ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_7 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16463641611276635273ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__x_ext = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 4769817227990304802ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 9582887852263475333ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p00_q = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5735784328563509120ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p01_q = VL_SCOPED_RAND_RESET_Q(34, __VscopeHash, 15202586860174892901ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p10_q = VL_SCOPED_RAND_RESET_Q(34, __VscopeHash, 3776690930700112688ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__p11_q = VL_SCOPED_RAND_RESET_Q(34, __VscopeHash, 3492431460461209017ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__stage1_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1624768987617717114ull);
    VL_SCOPED_RAND_RESET_W(66, vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q, __VscopeHash, 16362808123051036435ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__done_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5560821238581679763ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_work = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 69432622594558849ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__divisor_work = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9133966793688992504ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_work = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 5677061424348396428ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_work = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10354600463841411905ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 28128751234524605ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16132107481639797279ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_negative = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1594855844764060965ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_negative = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 353325662775078812ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__count = VL_SCOPED_RAND_RESET_I(6, __VscopeHash, 5180058356977351773ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__busy_reg = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 5870292423377993024ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__done_reg = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2983146393459725641ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_next = VL_SCOPED_RAND_RESET_Q(33, __VscopeHash, 3950109889098203800ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_next = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10315309962389565986ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__dividend_next = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7255281941921371097ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mstatus = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12793213329909939582ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mie = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1378540124441115275ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mepc = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 13934849339138776801ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtvec = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2828570825262042977ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcause = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7421137042254773476ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtime = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 1452159201514849985ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mtimecmp = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 5615413388708787569ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_minstret = VL_SCOPED_RAND_RESET_Q(64, __VscopeHash, 11463152940206119881ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_mcctr = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 14275715125618587934ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_wen = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1381588780603913386ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3698566698355141385ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_write_data = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16893697002764296811ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_src = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8537174981155864408ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 14220643437867941819ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9485611250447438278ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state_is_refill = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6976834373712784663ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4389901631267340555ull);
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg[__Vi0] = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 12199514069766755670ull);
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_addra[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 10309305097462472264ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_dina[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11803616933814820017ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_douta[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 2803901306245063468ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_bank_wea[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 852311170388055292ull);
        }
    }
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        for (int __Vi1 = 0; __Vi1 < 4; ++__Vi1) {
            vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__wr_match_way_bank[__Vi0][__Vi1] = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3947250592774361407ull);
        }
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 15387539808947183177ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2307119507670970036ull);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        VL_SCOPED_RAND_RESET_W(128, vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_data[__Vi0], __VscopeHash, 4026625719339124467ull);
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 12948176170658610295ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_d = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14992625762658310573ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3316297683745017116ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10419540050069258927ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__k = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8271655867824973945ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13627035641972307223ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 7679951334075041522ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag = VL_SCOPED_RAND_RESET_I(20, __VscopeHash, 15876303609794317778ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 17251231736429751913ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 16819284544434456969ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17897145231073432148ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10317591841068644339ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 5053991535644019719ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4546971983002171676ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__ret_num_add_one = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 644190864419728245ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 8436977052934176882ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wstrb = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 610213744630345859ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_wdata = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 10372597487689900321ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3189754422076338944ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7068911473462785024ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__rd_req_buffer = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 2365286740610506687ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__accept = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 14534064376210700136ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 738133016524963485ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11802839664279077901ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3981560530754967877ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15342779678552206169ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 7392514463150870360ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 15981537852410940574ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8245951853716018393ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 1741850572570417586ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__wea = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 3705405032069551291ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 7879053251973779070ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 8762522466857396322ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__1__KET____DOT__u__wea = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10474573285889334317ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 9496589009801849325ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_4 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 164050151460940089ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_7 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15011109213813267164ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_10 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9595138695058928465ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_11 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3375609349617556745ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12 = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 16469208051155012300ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_15 = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12358391491529649390ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 17485908206039663085ull);
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 4430060306034224613ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11657338968907792699ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 17348651661263852167ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__0__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11237389283023891521ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__0__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8596451964526747423ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__1__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12726714665913495832ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__2__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 9910503099528081358ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__data_ram_way__BRA__1__KET____DOT__data_ram_bank__BRA__3__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14939621479629360991ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 1229579756097689322ull);
    }
    for (int __Vi0 = 0; __Vi0 < 256; ++__Vi0) {
        vlSelf->tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem[__Vi0] = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 3958595678482364955ull);
    }
    vlSelf->tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11668699562646841791ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_funct3 = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 10011013885264350873ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_wb_sel = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 6990022323351373706ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_offset = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 4015416910456248347ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_is_load = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 188773377090061619ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_ex_wb_value = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16337907142327940013ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_reg_wen_reg = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 4165535602310065427ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_rd_addr_reg = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 17534316537654520698ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_wbu__DOT__wb_data_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 16984891420357579668ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 11785696581055006766ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 4956908419074208992ull);
    VL_SCOPED_RAND_RESET_W(128, vlSelf->tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data, __VscopeHash, 4577196826780540ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 11885108404315909903ull);
    vlSelf->tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_last = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 1105116994776499138ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18318155435300527543ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__state = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15827587283605572345ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__jtag_state = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 4748982411775202649ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 15744799630425120928ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__ar_base_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 12811007276243860203ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__ar_len_reg = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 9822764936863628579ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__read_beat = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 8791800387136650319ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__read_data_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11177142110645599532ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__aw_base_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 11479816132910817758ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__aw_len_reg = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 17277394155380425053ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__write_beat = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 1165240914411852692ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__jtag_addr_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 8658927272075586115ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__jtag_read_reg = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13273983235768656287ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__jtag_wdata_reg = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 18270394252639848003ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__jtag_wmask_reg = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 12647802272824667574ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__read_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 14911533287863005143ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__write_addr = VL_SCOPED_RAND_RESET_I(32, __VscopeHash, 3979176952911244344ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__read_last = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6773958178485047261ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__write_last = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8415578309144321451ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__read_region = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 17383994166085246015ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT__write_region = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 6352266706277980246ull);
    vlSelf->tb_Htop__DOT__u_mem_backend__DOT____VdfgRegularize_h5abff60f_0_5 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 18313674262859631790ull);
    vlSelf->__Vdly__tb_Htop__DOT__ddr_rsp_valid = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8024587828659431322ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 14947173260773103137ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 3320358847960187662ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = VL_SCOPED_RAND_RESET_I(5, __VscopeHash, 17249424698784705417ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 13480408175619000683ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 12191952042058661924ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 9419809401795314812ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 3182134799509691151ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 10484175508778843943ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 12656966928341578847ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way = VL_SCOPED_RAND_RESET_I(2, __VscopeHash, 9044443716925355354ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16090907418038379949ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 4369890177256506351ull);
    vlSelf->__Vdly__tb_Htop__DOT__axi_wlast = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15710530549673041573ull);
    vlSelf->__Vdly__tb_Htop__DOT__axi_bready = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12459917480946971971ull);
    vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num = VL_SCOPED_RAND_RESET_I(3, __VscopeHash, 1249684050450684096ull);
    VL_SCOPED_RAND_RESET_W(128, vlSelf->__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data, __VscopeHash, 7692727927268502665ull);
    vlSelf->__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = VL_SCOPED_RAND_RESET_I(4, __VscopeHash, 7952514294663847108ull);
    vlSelf->__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 10929133355648788849ull);
    vlSelf->__VdlyVal__tb_Htop__DOT__mem__v0 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 5989267048423277283ull);
    vlSelf->__VdlyDim0__tb_Htop__DOT__mem__v0 = VL_SCOPED_RAND_RESET_I(14, __VscopeHash, 9792757423706810387ull);
    vlSelf->__VdlySet__tb_Htop__DOT__mem__v0 = 0;
    vlSelf->__VdlyVal__tb_Htop__DOT__mem__v1 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 16344186484061215947ull);
    vlSelf->__VdlyDim0__tb_Htop__DOT__mem__v1 = VL_SCOPED_RAND_RESET_I(14, __VscopeHash, 14216218971280838529ull);
    vlSelf->__VdlySet__tb_Htop__DOT__mem__v1 = 0;
    vlSelf->__VdlyVal__tb_Htop__DOT__mem__v2 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 12241311946318775855ull);
    vlSelf->__VdlyDim0__tb_Htop__DOT__mem__v2 = VL_SCOPED_RAND_RESET_I(14, __VscopeHash, 4647615309661526214ull);
    vlSelf->__VdlySet__tb_Htop__DOT__mem__v2 = 0;
    vlSelf->__VdlyVal__tb_Htop__DOT__mem__v3 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 14489588853618370811ull);
    vlSelf->__VdlyDim0__tb_Htop__DOT__mem__v3 = VL_SCOPED_RAND_RESET_I(14, __VscopeHash, 4027700712543628918ull);
    vlSelf->__VdlySet__tb_Htop__DOT__mem__v3 = 0;
    vlSelf->__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 10545597555975073990ull);
    vlSelf->__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 10562617138791984297ull);
    vlSelf->__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0 = 0;
    vlSelf->__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = VL_SCOPED_RAND_RESET_I(21, __VscopeHash, 12315398937294899497ull);
    vlSelf->__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 9161616399646292821ull);
    vlSelf->__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__tb_Htop__DOT__clk__0 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 16528076876973853593ull);
    vlSelf->__Vtrigprevexpr___TOP__tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n__0 = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15080281135676278128ull);
}
