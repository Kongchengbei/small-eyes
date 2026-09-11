// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_HTOP__SYMS_H_
#define VERILATED_VTB_HTOP__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_Htop.h"

// INCLUDE MODULE CLASSES
#include "Vtb_Htop___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vtb_Htop__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_Htop* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_Htop___024root             TOP;

    // CONSTRUCTORS
    Vtb_Htop__Syms(VerilatedContext* contextp, const char* namep, Vtb_Htop* modelp);
    ~Vtb_Htop__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
