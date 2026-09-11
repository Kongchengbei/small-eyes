// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtb_Htop__pch.h"

//============================================================
// Constructors

Vtb_Htop::Vtb_Htop(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtb_Htop__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtb_Htop::Vtb_Htop(const char* _vcname__)
    : Vtb_Htop(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtb_Htop::~Vtb_Htop() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtb_Htop___024root___eval_debug_assertions(Vtb_Htop___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_Htop___024root___eval_static(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___eval_initial(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___eval_settle(Vtb_Htop___024root* vlSelf);
void Vtb_Htop___024root___eval(Vtb_Htop___024root* vlSelf);

void Vtb_Htop::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtb_Htop::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtb_Htop___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtb_Htop___024root___eval_static(&(vlSymsp->TOP));
        Vtb_Htop___024root___eval_initial(&(vlSymsp->TOP));
        Vtb_Htop___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtb_Htop___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtb_Htop::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vtb_Htop::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtb_Htop::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtb_Htop___024root___eval_final(Vtb_Htop___024root* vlSelf);

VL_ATTR_COLD void Vtb_Htop::final() {
    Vtb_Htop___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtb_Htop::hierName() const { return vlSymsp->name(); }
const char* Vtb_Htop::modelName() const { return "Vtb_Htop"; }
unsigned Vtb_Htop::threads() const { return 1; }
void Vtb_Htop::prepareClone() const { contextp()->prepareClone(); }
void Vtb_Htop::atClone() const {
    contextp()->threadPoolpOnClone();
}
