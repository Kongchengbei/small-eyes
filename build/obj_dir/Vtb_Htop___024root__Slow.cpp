// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_Htop.h for the primary calling header

#include "Vtb_Htop__pch.h"
#include "Vtb_Htop__Syms.h"
#include "Vtb_Htop___024root.h"

void Vtb_Htop___024root___ctor_var_reset(Vtb_Htop___024root* vlSelf);

Vtb_Htop___024root::Vtb_Htop___024root(Vtb_Htop__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtb_Htop___024root___ctor_var_reset(this);
}

void Vtb_Htop___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vtb_Htop___024root::~Vtb_Htop___024root() {
}
