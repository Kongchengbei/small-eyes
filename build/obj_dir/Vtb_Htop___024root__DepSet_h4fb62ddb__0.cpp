// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_Htop.h for the primary calling header

#include "Vtb_Htop__pch.h"
#include "Vtb_Htop___024root.h"

VL_ATTR_COLD void Vtb_Htop___024root___eval_initial__TOP(Vtb_Htop___024root* vlSelf);
VlCoroutine Vtb_Htop___024root___eval_initial__TOP__Vtiming__0(Vtb_Htop___024root* vlSelf);
VlCoroutine Vtb_Htop___024root___eval_initial__TOP__Vtiming__1(Vtb_Htop___024root* vlSelf);
VlCoroutine Vtb_Htop___024root___eval_initial__TOP__Vtiming__2(Vtb_Htop___024root* vlSelf);

void Vtb_Htop___024root___eval_initial(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_initial\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_Htop___024root___eval_initial__TOP(vlSelf);
    Vtb_Htop___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vtb_Htop___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    Vtb_Htop___024root___eval_initial__TOP__Vtiming__2(vlSelf);
}

void Vtb_Htop___024root___act_sequent__TOP__0(Vtb_Htop___024root* vlSelf);

void Vtb_Htop___024root___eval_act(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_act\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        Vtb_Htop___024root___act_sequent__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtb_Htop___024root___act_sequent__TOP__0(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___act_sequent__TOP__0\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__dbg_mem_ready_go;
    tb_Htop__DOT__dut__DOT__dbg_mem_ready_go = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en;
    tb_Htop__DOT__dut__DOT__u_icache__DOT__way_wr_en = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire;
    tb_Htop__DOT__dut__DOT__u_idu__DOT__id_fire = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en = 0;
    CData/*0:0*/ __VdfgRegularize_h3c5bdd75_0_4;
    __VdfgRegularize_h3c5bdd75_0_4 = 0;
    CData/*0:0*/ __VdfgRegularize_h3c5bdd75_0_6;
    __VdfgRegularize_h3c5bdd75_0_6 = 0;
    // Body
    vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n 
        = (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__rst)));
    vlSelfRef.tb_Htop__DOT__axi_wready = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (4U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__ddr_req_valid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                             & (((1U 
                                                  == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                                 & (2U 
                                                    == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_region))) 
                                                | ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT____VdfgRegularize_h5abff60f_0_5) 
                                                   | (1U 
                                                      == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state)))));
    vlSelfRef.tb_Htop__DOT__axi_awready = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                           & ((0U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                              & ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid)) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state)))));
    vlSelfRef.tb_Htop__DOT__axi_bvalid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (6U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__axi_rvalid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (3U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_to_wb_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid) 
           & (IData)(tb_Htop__DOT__dut__DOT__dbg_mem_ready_go));
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid)) 
               | (IData)(tb_Htop__DOT__dut__DOT__dbg_mem_ready_go)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid)) 
               | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_ex_ready_go) 
                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))));
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

void Vtb_Htop___024root___nba_sequent__TOP__0(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___nba_sequent__TOP__1(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___nba_sequent__TOP__2(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___nba_sequent__TOP__3(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___nba_sequent__TOP__4(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___nba_comb__TOP__0(Vtb_Htop___024root* vlSelf);

void Vtb_Htop___024root___eval_nba(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_nba\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtb_Htop___024root___nba_sequent__TOP__0(vlSelf);
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtb_Htop___024root___nba_sequent__TOP__1(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtb_Htop___024root___nba_sequent__TOP__2(vlSelf);
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtb_Htop___024root___nba_sequent__TOP__3(vlSelf);
    }
    if ((3ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        Vtb_Htop___024root___nba_sequent__TOP__4(vlSelf);
        Vtb_Htop___024root___nba_comb__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtb_Htop___024root___nba_sequent__TOP__0(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___nba_sequent__TOP__0\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*2:0*/ __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state;
    __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state = 0;
    CData/*0:0*/ __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid;
    __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid = 0;
    // Body
    __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid 
        = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid;
    __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state 
        = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state;
    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat 
        = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat;
    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state 
        = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state;
    if (vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) {
        if ((1U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))) {
            __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state = 2U;
        } else if ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))) {
            if (((IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_valid) 
                 & (IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_ready))) {
                __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid = 1U;
                __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state = 3U;
            }
        } else if ((3U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))) {
            if (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid) {
                __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid = 0U;
                __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state = 0U;
            }
        } else if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid)))) {
            __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state = 0U;
        }
    } else {
        __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state = 0U;
        __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid = 0U;
    }
    if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n)))) {
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_read_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_wdata_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_wmask_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_addr_reg = 0U;
    }
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid 
        = __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid;
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state 
        = __Vdly__tb_Htop__DOT__u_mem_backend__DOT__jtag_state;
}

VL_INLINE_OPT void Vtb_Htop___024root___nba_sequent__TOP__2(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___nba_sequent__TOP__2\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*2:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__Vfuncout;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__0__addr = 0;
    CData/*2:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__Vfuncout;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__Vfuncout = 0;
    IData/*31:0*/ __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr;
    __Vfunc_tb_Htop__DOT__u_mem_backend__DOT__region_of__1__addr = 0;
    // Body
    if (vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) {
        if ((8U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 0U;
        } else if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
            if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
                if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 0U;
                } else if (((IData)(vlSelfRef.tb_Htop__DOT__axi_bvalid) 
                            & (IData)(vlSelfRef.tb_Htop__DOT__axi_bready))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 0U;
                }
            } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
                if (((IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_valid) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_ready))) {
                    if (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_last) {
                        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 6U;
                    } else {
                        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat 
                            = (0xffU & ((IData)(1U) 
                                        + (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat)));
                        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 4U;
                    }
                }
            } else if (((IData)(vlSelfRef.tb_Htop__DOT__axi_wvalid) 
                        & (IData)(vlSelfRef.tb_Htop__DOT__axi_wready))) {
                if ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_region))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 5U;
                } else if (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_last) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 6U;
                } else {
                    vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat 
                        = (0xffU & ((IData)(1U) + (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat)));
                }
            }
        } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
            if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
                if (((IData)(vlSelfRef.tb_Htop__DOT__axi_rvalid) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__axi_rready))) {
                    if (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_last) {
                        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 0U;
                    } else {
                        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat 
                            = (0xffU & ((IData)(1U) 
                                        + (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat)));
                        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 1U;
                    }
                }
            } else if (((IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_valid) 
                        & (IData)(vlSelfRef.tb_Htop__DOT__ddr_rsp_ready))) {
                vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg 
                    = vlSelfRef.tb_Htop__DOT__ddr_rsp_rdata;
                vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 3U;
            }
        } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))) {
            if ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_region))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 2U;
            } else if ((1U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_region))) {
                vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg = 0U;
                vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 3U;
            } else {
                vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg = 0U;
                vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 3U;
            }
        } else if (((IData)(vlSelfRef.tb_Htop__DOT__axi_awvalid) 
                    & (IData)(vlSelfRef.tb_Htop__DOT__axi_awready))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat = 0U;
            vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_base_reg 
                = vlSelfRef.tb_Htop__DOT__axi_awaddr;
            vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_len_reg 
                = vlSelfRef.tb_Htop__DOT__axi_awlen;
            vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 4U;
        } else if (((IData)(vlSelfRef.tb_Htop__DOT__axi_arvalid) 
                    & (IData)(vlSelfRef.tb_Htop__DOT__axi_arready))) {
            vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat = 0U;
            vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg 
                = vlSelfRef.tb_Htop__DOT__axi_arid;
            vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_base_reg 
                = vlSelfRef.tb_Htop__DOT__axi_araddr;
            vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_len_reg 
                = vlSelfRef.tb_Htop__DOT__axi_arlen;
            vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 1U;
        }
    } else {
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_base_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_len_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_base_reg = 0U;
        vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_len_reg = 0U;
    }
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat 
        = vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__write_beat;
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state 
        = vlSelfRef.__Vdly__tb_Htop__DOT__u_mem_backend__DOT__state;
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_last 
        = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_len_reg) 
           == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_addr 
        = (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__aw_base_reg 
           + VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_beat), 2U));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_addr 
        = (vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_base_reg 
           + VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat), 2U));
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_last 
        = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_len_reg) 
           == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_beat));
    vlSelfRef.tb_Htop__DOT__ddr_rsp_ready = ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                             | ((5U 
                                                 == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                                | (2U 
                                                   == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))));
    vlSelfRef.tb_Htop__DOT__axi_rvalid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (3U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
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
    vlSelfRef.tb_Htop__DOT__axi_rlast = ((3U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                         & (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_last));
}

VL_INLINE_OPT void Vtb_Htop___024root___nba_sequent__TOP__3(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___nba_sequent__TOP__3\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__dmem_valid;
    tb_Htop__DOT__dut__DOT__dmem_valid = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2 = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v0;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v0 = 0;
    CData/*1:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1 = 0;
    CData/*1:0*/ __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2;
    __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2 = 0;
    CData/*7:0*/ __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2;
    __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2 = 0;
    // Body
    vlSelfRef.tb_Htop__DOT__ddr_rsp_valid = vlSelfRef.__Vdly__tb_Htop__DOT__ddr_rsp_valid;
    if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__rst)))) {
        if (vlSelfRef.tb_Htop__DOT__ddr_req_valid) {
            if (vlSelfRef.tb_Htop__DOT__ddr_addr_valid) {
                if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__ddr_req_write)))) {
                    vlSelfRef.tb_Htop__DOT__ddr_rsp_rdata 
                        = vlSelfRef.tb_Htop__DOT__mem
                        [(0x3fffU & ((vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                      - (IData)(0x80000000U)) 
                                     >> 2U))];
                }
            } else if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__ddr_req_write)))) {
                vlSelfRef.tb_Htop__DOT__ddr_rsp_rdata = 0U;
            }
        }
    }
    if (vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__mem[vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v0] 
            = ((0xffffff00U & vlSelfRef.tb_Htop__DOT__mem
                [vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v0]) 
               | (IData)(vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v0));
    }
    if (vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v1) {
        vlSelfRef.tb_Htop__DOT__mem[vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v1] 
            = ((0xffff00ffU & vlSelfRef.tb_Htop__DOT__mem
                [vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v1]) 
               | ((IData)(vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v1) 
                  << 8U));
    }
    if (vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v2) {
        vlSelfRef.tb_Htop__DOT__mem[vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v2] 
            = ((0xff00ffffU & vlSelfRef.tb_Htop__DOT__mem
                [vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v2]) 
               | ((IData)(vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v2) 
                  << 0x10U));
    }
    if (vlSelfRef.__VdlySet__tb_Htop__DOT__mem__v3) {
        vlSelfRef.tb_Htop__DOT__mem[vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v3] 
            = ((0xffffffU & vlSelfRef.tb_Htop__DOT__mem
                [vlSelfRef.__VdlyDim0__tb_Htop__DOT__mem__v3]) 
               | ((IData)(vlSelfRef.__VdlyVal__tb_Htop__DOT__mem__v3) 
                  << 0x18U));
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__axi_rready = 1U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 0U;
        vlSelfRef.tb_Htop__DOT__axi_arvalid = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state 
            = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 0U;
        vlSelfRef.tb_Htop__DOT__axi_awvalid = 0U;
        vlSelfRef.tb_Htop__DOT__axi_wvalid = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__axi_wlast = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__axi_bready = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U] = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U] = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U] = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U] = 0U;
    } else {
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state) {
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state) {
                if (((IData)(vlSelfRef.tb_Htop__DOT__axi_arready) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__axi_arid))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 0U;
                    vlSelfRef.tb_Htop__DOT__axi_arvalid = 0U;
                } else if (((IData)(vlSelfRef.tb_Htop__DOT__axi_arready) 
                            & (~ (IData)(vlSelfRef.tb_Htop__DOT__axi_arid)))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 0U;
                    vlSelfRef.tb_Htop__DOT__axi_arvalid = 0U;
                }
            }
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_req) {
            if ((0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
                if (((IData)(vlSelfRef.tb_Htop__DOT__axi_bvalid) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__axi_bready))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 1U;
                    vlSelfRef.tb_Htop__DOT__axi_arid = 1U;
                    vlSelfRef.tb_Htop__DOT__axi_araddr 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_addr;
                    vlSelfRef.tb_Htop__DOT__axi_arlen 
                        = ((4U == ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)
                                    ? 2U : 4U)) ? 3U
                            : 0U);
                    vlSelfRef.tb_Htop__DOT__axi_arvalid = 1U;
                }
            } else {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 1U;
                vlSelfRef.tb_Htop__DOT__axi_arid = 1U;
                vlSelfRef.tb_Htop__DOT__axi_araddr 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_addr;
                vlSelfRef.tb_Htop__DOT__axi_arlen = 
                    ((4U == ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)
                              ? 2U : 4U)) ? 3U : 0U);
                vlSelfRef.tb_Htop__DOT__axi_arvalid = 1U;
            }
        } else if ((4U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            if ((0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
                if (((IData)(vlSelfRef.tb_Htop__DOT__axi_bvalid) 
                     & (IData)(vlSelfRef.tb_Htop__DOT__axi_bready))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 1U;
                    vlSelfRef.tb_Htop__DOT__axi_arid = 0U;
                    vlSelfRef.tb_Htop__DOT__axi_araddr 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_addr;
                    vlSelfRef.tb_Htop__DOT__axi_arlen 
                        = ((4U == ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)
                                    ? 2U : 4U)) ? 3U
                            : 0U);
                    vlSelfRef.tb_Htop__DOT__axi_arvalid = 1U;
                }
            } else {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state = 1U;
                vlSelfRef.tb_Htop__DOT__axi_arid = 0U;
                vlSelfRef.tb_Htop__DOT__axi_araddr 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_addr;
                vlSelfRef.tb_Htop__DOT__axi_arlen = 
                    ((4U == ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)
                              ? 2U : 4U)) ? 3U : 0U);
                vlSelfRef.tb_Htop__DOT__axi_arvalid = 1U;
            }
        }
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state 
            = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__read_requst_state;
        if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
            if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
                if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 0U;
                } else if (((IData)(vlSelfRef.tb_Htop__DOT__axi_bvalid) 
                            & (IData)(vlSelfRef.tb_Htop__DOT__axi_bready))) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 0U;
                    vlSelfRef.__Vdly__tb_Htop__DOT__axi_bready = 0U;
                }
            } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
                if (vlSelfRef.tb_Htop__DOT__axi_awready) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 4U;
                    vlSelfRef.tb_Htop__DOT__axi_awvalid = 0U;
                    vlSelfRef.tb_Htop__DOT__axi_wvalid = 1U;
                }
            } else if (vlSelfRef.tb_Htop__DOT__axi_wready) {
                if (vlSelfRef.tb_Htop__DOT__axi_wlast) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 6U;
                    vlSelfRef.tb_Htop__DOT__axi_wvalid = 0U;
                    vlSelfRef.__Vdly__tb_Htop__DOT__axi_wlast = 0U;
                    vlSelfRef.__Vdly__tb_Htop__DOT__axi_bready = 1U;
                } else {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num 
                        = (7U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num) 
                                 - (IData)(1U)));
                    if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_last) {
                        vlSelfRef.__Vdly__tb_Htop__DOT__axi_wlast = 1U;
                    }
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 4U;
                    vlSelfRef.tb_Htop__DOT__axi_wdata 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U];
                    vlSelfRef.tb_Htop__DOT__axi_wvalid = 1U;
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U] 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U];
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U] 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U];
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U] 
                        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U];
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U] = 0U;
                }
            }
        } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 0U;
        } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 0U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_req) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state = 5U;
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer) {
                vlSelfRef.tb_Htop__DOT__axi_awaddr 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_15;
                vlSelfRef.tb_Htop__DOT__axi_wstrb = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb;
            } else {
                vlSelfRef.tb_Htop__DOT__axi_awaddr 
                    = ((0xfffff000U & ((((- (IData)(
                                                    (1U 
                                                     & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way)))) 
                                         << 0xcU) & 
                                        (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
                                         << 0xbU)) 
                                       | (((- (IData)(
                                                      (1U 
                                                       & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
                                                          >> 1U)))) 
                                           << 0xcU) 
                                          & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                                             << 0xbU)))) 
                       | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                          << 4U));
                vlSelfRef.tb_Htop__DOT__axi_wstrb = 0xfU;
            }
            if ((4U == ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer)
                         ? 2U : 4U))) {
                vlSelfRef.tb_Htop__DOT__axi_awlen = 3U;
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num = 3U;
            } else {
                vlSelfRef.tb_Htop__DOT__axi_awlen = 0U;
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num = 0U;
                vlSelfRef.__Vdly__tb_Htop__DOT__axi_wlast = 1U;
            }
            vlSelfRef.tb_Htop__DOT__axi_awvalid = 1U;
            vlSelfRef.tb_Htop__DOT__axi_wdata = vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[0U];
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U] 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[1U];
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U] 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[2U];
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U] 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_data[3U];
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U] = 0U;
        }
    }
    vlSelfRef.tb_Htop__DOT__axi_wlast = vlSelfRef.__Vdly__tb_Htop__DOT__axi_wlast;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U] 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[0U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U] 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[1U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U] 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[2U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U] 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_data[3U];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num;
    vlSelfRef.tb_Htop__DOT__axi_bready = vlSelfRef.__Vdly__tb_Htop__DOT__axi_bready;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_last 
        = (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_buffer_num));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra];
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
        = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem
        [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellinp__tagv_ram_way__BRA__0__KET____DOT__u__addra];
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_replace_way = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num = 0U;
    } else if ((8U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
        if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if ((1U & (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid) 
                           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_last)) 
                          | (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__rd_req_buffer))))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__ret_num_add_one;
        }
    } else if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
        if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__flush) 
                    & (~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_req) 
                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_rdy))))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_rdy) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 8U;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num = 0U;
        }
    } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
        if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__flush) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__cache_hit) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
        } else {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 4U;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
                = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                   >> 0xcU);
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_replace_way 
                = (3U & ((0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in))
                          ? (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way)
                          : ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr))
                              ? ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr))
                                  ? 2U : 8U) : 1U)));
        }
    } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__accept) {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 2U;
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en 
                = (1U & (~ ((0x80000000U <= vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc) 
                            & (0xc0000000U > vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc))));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index 
                = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc 
                            >> 4U));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset 
                = (0xfU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__proc_pc);
        }
    } else {
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state = 1U;
    }
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__k = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en = 0U;
        vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_req = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer = 0U;
        while (VL_GTS_III(32, 0x100U, vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__k)) {
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v0 
                = (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__k);
            vlSelfRef.__VdlyCommitQueuetb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg.enqueue(0U, (IData)(__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v0));
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__k 
                = ((IData)(1U) + vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__k);
        }
    } else {
        if ((0x10U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
            if ((8U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((1U & (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid) 
                               & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_last)) 
                              | (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__rd_req_buffer))))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid) {
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__ret_num_add_one;
            }
        } else if ((8U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
            if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else {
                if (vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_rdy) {
                    vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 0x10U;
                    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num = 0U;
                }
                vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_req = 0U;
            }
        } else if ((4U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
            if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if ((0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 8U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__dc_wr_req = 1U;
            }
        } else if ((2U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
            if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
            } else if (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr) 
                        | (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_d) 
                            & (0U != ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way) 
                                      & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12)))) 
                           & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en))))) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 4U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr;
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way;
            } else {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 8U;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr;
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way;
            }
        } else if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))) {
            if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__accept) {
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 2U;
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wen;
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index 
                    = (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                                >> 4U));
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
                    = (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                       >> 0xcU);
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset 
                    = (0xcU & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result);
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wstrb 
                    = vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wmask;
                vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_wdata 
                    = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_word)
                        ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2
                        : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_half)
                            ? ((0U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                ? (0xffffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)
                                : ((1U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                    ? (0xffff00U & 
                                       (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                                        << 8U)) : (
                                                   (2U 
                                                    == 
                                                    (3U 
                                                     & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                                    ? 
                                                   VL_SHIFTL_III(32,32,32, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2, 0x10U)
                                                    : 
                                                   VL_SHIFTL_III(32,32,32, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2, 0x18U))))
                            : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_byte)
                                ? ((0U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                    ? (0xffU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)
                                    : ((1U == (3U & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                        ? (0xff00U 
                                           & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                                              << 8U))
                                        : ((2U == (3U 
                                                   & vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))
                                            ? (0xff0000U 
                                               & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                                                  << 0x10U))
                                            : VL_SHIFTL_III(32,32,32, vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2, 0x18U))))
                                : 0U)));
                vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en 
                    = (1U & (~ ((0x80000000U <= vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result) 
                                & (0xc0000000U > vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result))));
            }
        } else {
            vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state = 1U;
        }
        if ((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state_is_refill) 
              & (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid) 
                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_last)) 
                 | (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__rd_req_buffer)))) 
             & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)))) {
            __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1 
                = ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg
                    [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index] 
                    & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way))) 
                   | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way) 
                      & (- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op)))));
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index;
            vlSelfRef.__VdlyCommitQueuetb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg.enqueue(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1, (IData)(__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v1));
        } else if (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) {
            __VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2 
                = (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg
                   [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index] 
                   | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way));
            __VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index;
            vlSelfRef.__VdlyCommitQueuetb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg.enqueue(__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2, (IData)(__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg__v2));
        }
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__u_lfsr__DOT__r_lfsr;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in 
        = (3U & (~ ((2U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                           << 1U)) | (1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta))));
    if (vlSelfRef.__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem[vlSelfRef.__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0] 
            = vlSelfRef.__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__0__KET____DOT__u__DOT__mem__v0;
    }
    if (vlSelfRef.__VdlySet__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem[vlSelfRef.__VdlyDim0__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0] 
            = vlSelfRef.__VdlyVal__tb_Htop__DOT__dut__DOT__u_dcache__DOT__tagv_ram_way__BRA__1__KET____DOT__u__DOT__mem__v0;
    }
    vlSelfRef.__VdlyCommitQueuetb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg.commit(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg);
    if (vlSelfRef.tb_Htop__DOT__rst) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__rd_req_buffer = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__rd_req_buffer = 0U;
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 = 0U;
    } else {
        if ((4U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__rd_req_buffer = 1U;
        } else if (((8U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
                    & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid) 
                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_last)))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__rd_req_buffer = 0U;
        }
        if (vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_req) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__rd_req_buffer = 1U;
        } else if (((0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
                    & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid) 
                       & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_last)))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__rd_req_buffer = 0U;
        }
        if ((((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_redirect_valid)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid)) 
             & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin))) {
            vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                = vlSelfRef.tb_Htop__DOT__dut__DOT__id_src2;
        }
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_replace_way;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_axi_bridge__DOT__write_requst_state;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state;
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = 0U;
    if ((1U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = 1U;
    }
    if ((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____Vcellinp__sel_one_invalid__in) 
          >> 1U) & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way)))) {
        vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__invalid_way = 2U;
    }
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__ret_num_add_one 
        = ((2U & (VL_REDXOR_2(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num) 
                  << 1U)) | (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__miss_buffer_ret_num))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_addr = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_uncache_en)
          ? ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
              << 0xcU) | (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index) 
                           << 4U) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_offset)))
          : ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_tag 
              << 0xcU) | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__request_buffer_index) 
                          << 4U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12 
        = ((2U & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__1__KET____DOT__u__douta 
                  << 1U)) | (1U & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____Vcellout__tagv_ram_way__BRA__0__KET____DOT__u__douta));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__ret_num_add_one 
        = ((2U & (VL_REDXOR_2(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num) 
                  << 1U)) | (1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__miss_buffer_ret_num))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_op) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_15 
        = ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
            << 0xcU) | (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                         << 4U) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_offset)));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 0U;
    if ((1U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12)))) {
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 1U;
    }
    if (((~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12) 
             >> 1U)) & (0U == (IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way)))) {
        tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way = 2U;
    }
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state 
        = vlSelfRef.__Vdly__tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state;
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_addr = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)
          ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_15
          : ((vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_tag 
              << 0xcU) | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                          << 4U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_7) 
            << 1U) | (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_4));
    vlSelfRef.tb_Htop__DOT__dut__DOT__id_to_ex_valid 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_id_stall)) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_valid));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_req = (4U 
                                                   == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state));
    vlSelfRef.tb_Htop__DOT__dut__DOT__if_req_ready 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__hold)) 
           & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT____VdfgRegularize_hdb201a2a_0_9 
        = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)) 
           | (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_icache__DOT__main_state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way 
        = (3U & ((0U != (3U & (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_12))))
                  ? (IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__invalid_way)
                  : ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))
                      ? ((0x40U & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__u_lfsr__DOT__r_lfsr))
                          ? 2U : 8U) : 1U)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state_is_refill 
        = (0x10U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_req = (
                                                   (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__uncache_wr_buffer)) 
                                                   & (8U 
                                                      == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)));
    tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_18 
        = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)) 
           | (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__cache_hit 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_uncache_en)) 
           & (0U != (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_hit)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__y_ext 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__mul_y_signed)
            ? (((QData)((IData)((vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2 
                                 >> 0x1fU))) << 0x20U) 
               | (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)))
            : (QData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2)));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__alu_src2 = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2_is_imm)
          ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_imm
          : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_src2);
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_d 
        = (0U != ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__replace_way) 
                  & (vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_d_reg
                     [vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index] 
                     | ((- (IData)((((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__request_buffer_index) 
                                     == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index)) 
                                    & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state)))) 
                        & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_way)))));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_value = 
        ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_mul)
          ? ((1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_op))
              ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[0U]
              : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_mul__DOT__product_q[1U])
          : ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_m_is_div)
              ? ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_3)
                  ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__quotient_reg
                  : vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_div__DOT__remainder_reg)
              : ((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel))
                  ? ((IData)(4U) + vlSelfRef.tb_Htop__DOT__dut__DOT__ex_pc)
                  : ((3U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel))
                      ? vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__u_csr__DOT__csr_read_data
                      : ((0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_wb_sel))
                          ? vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result
                          : 0U)))));
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup 
        = (1U & (~ ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_state) 
                    & (((3U & (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                               >> 2U)) == (3U & ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_offset) 
                                                 >> 2U))) 
                       | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__write_buffer_index) 
                          == (0xffU & (vlSelfRef.tb_Htop__DOT__dut__DOT__ex_result 
                                       >> 4U)))))));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_ex_ready_go));
    tb_Htop__DOT__dut__DOT__dmem_valid = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_to_mem_valid) 
                                          & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT____VdfgRegularize_h18ccc44a_0_0));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__accept 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__hold)) 
           & ((IData)(tb_Htop__DOT__dut__DOT__dmem_valid) 
              & ((IData)(tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_idle2lookup) 
                 & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state)))));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wen = ((IData)(tb_Htop__DOT__dut__DOT__dmem_valid) 
                                                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__ex_is_store));
    tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active 
        = ((IData)(tb_Htop__DOT__dut__DOT__dmem_valid) 
           & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dmem_wen));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_word 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active) 
           & (2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_half 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active) 
           & (1U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__u_exu__DOT__store_byte 
        = ((IData)(tb_Htop__DOT__dut__DOT__u_exu__DOT__store_active) 
           & (0U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_mem_funct3)));
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
}

VL_INLINE_OPT void Vtb_Htop___024root___nba_sequent__TOP__4(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___nba_sequent__TOP__4\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_Htop__DOT__ddr_req_addr = ((1U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))
                                             ? vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_addr_reg
                                             : ((4U 
                                                 == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state))
                                                 ? vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_addr
                                                 : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_addr));
    vlSelfRef.tb_Htop__DOT__axi_wready = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (4U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__axi_awready = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                           & ((0U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
                                              & ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_rsp_valid)) 
                                                 & (0U 
                                                    == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state)))));
    vlSelfRef.tb_Htop__DOT__axi_bvalid = ((IData)(vlSelfRef.tb_Htop__DOT____Vcellinp__u_mem_backend__rst_n) 
                                          & (6U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_last = 
        ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg)) 
         & (IData)(vlSelfRef.tb_Htop__DOT__axi_rlast));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_ret_valid 
        = ((~ (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg)) 
           & (IData)(vlSelfRef.tb_Htop__DOT__axi_rvalid));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_last = 
        ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg) 
         & (IData)(vlSelfRef.tb_Htop__DOT__axi_rlast));
    vlSelfRef.tb_Htop__DOT__dut__DOT__dc_ret_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__ar_id_reg) 
           & (IData)(vlSelfRef.tb_Htop__DOT__axi_rvalid));
    vlSelfRef.tb_Htop__DOT__ddr_addr_valid = ((0x80000000U 
                                               <= vlSelfRef.tb_Htop__DOT__ddr_req_addr) 
                                              & (0x4000U 
                                                 > 
                                                 VL_SHIFTR_III(32,32,32, 
                                                               (vlSelfRef.tb_Htop__DOT__ddr_req_addr 
                                                                - (IData)(0x80000000U)), 2U)));
}

VL_INLINE_OPT void Vtb_Htop___024root___nba_comb__TOP__0(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___nba_comb__TOP__0\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
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
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_valid = 0;
    CData/*0:0*/ tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret;
    tb_Htop__DOT__dut__DOT__u_exu__DOT__csr_is_mret = 0;
    CData/*1:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__way_wr_en = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data;
    tb_Htop__DOT__dut__DOT__u_dcache__DOT__refill_data = 0;
    IData/*31:0*/ tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata;
    tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata = 0;
    CData/*0:0*/ __VdfgRegularize_h3c5bdd75_0_4;
    __VdfgRegularize_h3c5bdd75_0_4 = 0;
    CData/*0:0*/ __VdfgRegularize_h3c5bdd75_0_6;
    __VdfgRegularize_h3c5bdd75_0_6 = 0;
    // Body
    if ((1U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_state))) {
        vlSelfRef.tb_Htop__DOT__ddr_req_wdata = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_wdata_reg;
        vlSelfRef.tb_Htop__DOT__ddr_req_wstrb = vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__jtag_wmask_reg;
    } else {
        vlSelfRef.tb_Htop__DOT__ddr_req_wdata = vlSelfRef.tb_Htop__DOT__axi_wdata;
        vlSelfRef.tb_Htop__DOT__ddr_req_wstrb = vlSelfRef.tb_Htop__DOT__axi_wstrb;
    }
    vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT____VdfgRegularize_h5abff60f_0_5 
        = ((4U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__state)) 
           & ((2U == (IData)(vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__write_region)) 
              & (IData)(vlSelfRef.tb_Htop__DOT__axi_wvalid)));
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
    tb_Htop__DOT__dut__DOT__dmem_rdata = ((2U == (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT__main_state))
                                           ? (((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_4))) 
                                               & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_10) 
                                              | ((- (IData)((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_7))) 
                                                 & vlSelfRef.tb_Htop__DOT__dut__DOT__u_dcache__DOT____VdfgRegularize_ha35c69cd_0_11))
                                           : vlSelfRef.tb_Htop__DOT__u_mem_backend__DOT__read_data_reg);
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
    tb_Htop__DOT__dut__DOT__u_memu__DOT__shifted_rdata 
        = VL_SHIFTR_III(32,32,32, tb_Htop__DOT__dut__DOT__dmem_rdata, 
                        VL_SHIFTL_III(32,32,32, (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_offset), 3U));
    vlSelfRef.tb_Htop__DOT__dut__DOT__ic_rd_rdy = (
                                                   (~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_req)) 
                                                   & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dc_rd_rdy));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_to_wb_valid 
        = ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid) 
           & (IData)(tb_Htop__DOT__dut__DOT__dbg_mem_ready_go));
    vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_memu__DOT__mem_valid)) 
               | (IData)(tb_Htop__DOT__dut__DOT__dbg_mem_ready_go)));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__ex_allowin = 
        (1U & ((~ (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__ex_valid)) 
               | ((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__dbg_ex_ready_go) 
                  & (IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__mem_allowin))));
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
    vlSelfRef.tb_Htop__DOT__dut__DOT__btb_update_taken 
        = ((0x63U != (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
           | (IData)(tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken));
    vlSelfRef.tb_Htop__DOT__dut__DOT__actual_next_pc 
        = (((IData)(vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT____VdfgRegularize_hf3337949_0_11) 
            | ((0x63U == (0x7fU & vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_ins_reg)) 
               & (IData)(tb_Htop__DOT__dut__DOT__u_idu__DOT__branch_taken)))
            ? vlSelfRef.tb_Htop__DOT__dut__DOT__id_redirect_pc
            : ((IData)(4U) + vlSelfRef.tb_Htop__DOT__dut__DOT__u_idu__DOT__id_pc_reg));
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

void Vtb_Htop___024root___timing_resume(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___timing_resume\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VtrigSched_hdf5d1d13__0.resume(
                                                   "@(posedge tb_Htop.clk)");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vtb_Htop___024root___timing_commit(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___timing_commit\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((! (1ULL & vlSelfRef.__VactTriggered.word(0U)))) {
        vlSelfRef.__VtrigSched_hdf5d1d13__0.commit(
                                                   "@(posedge tb_Htop.clk)");
    }
}

void Vtb_Htop___024root___eval_triggers__act(Vtb_Htop___024root* vlSelf);

bool Vtb_Htop___024root___eval_phase__act(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_phase__act\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    VlTriggerVec<3> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtb_Htop___024root___eval_triggers__act(vlSelf);
    Vtb_Htop___024root___timing_commit(vlSelf);
    __VactExecute = vlSelfRef.__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelfRef.__VactTriggered, vlSelfRef.__VnbaTriggered);
        vlSelfRef.__VnbaTriggered.thisOr(vlSelfRef.__VactTriggered);
        Vtb_Htop___024root___timing_resume(vlSelf);
        Vtb_Htop___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtb_Htop___024root___eval_phase__nba(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_phase__nba\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelfRef.__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtb_Htop___024root___eval_nba(vlSelf);
        vlSelfRef.__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__nba(Vtb_Htop___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_Htop___024root___dump_triggers__act(Vtb_Htop___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_Htop___024root___eval(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY(((0x64U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtb_Htop___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("sim/tb_Htop.sv", 3, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelfRef.__VactIterCount = 0U;
        vlSelfRef.__VactContinue = 1U;
        while (vlSelfRef.__VactContinue) {
            if (VL_UNLIKELY(((0x64U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                Vtb_Htop___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("sim/tb_Htop.sv", 3, "", "Active region did not converge.");
            }
            vlSelfRef.__VactIterCount = ((IData)(1U) 
                                         + vlSelfRef.__VactIterCount);
            vlSelfRef.__VactContinue = 0U;
            if (Vtb_Htop___024root___eval_phase__act(vlSelf)) {
                vlSelfRef.__VactContinue = 1U;
            }
        }
        if (Vtb_Htop___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtb_Htop___024root___eval_debug_assertions(Vtb_Htop___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_Htop___024root___eval_debug_assertions\n"); );
    Vtb_Htop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
