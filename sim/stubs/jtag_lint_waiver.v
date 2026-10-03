// These existing JTAG RTL files are outside the boot-profile test scope. They
// have known implicit-net, incomplete-case, and UNOPTFLAT warnings; JTAG pins
// remain idle in the profile smoke, so waive only these files during lint.
/* verilator lint_off IMPLICIT */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off UNOPTFLAT */
`include "jtag/full_handshake_rx.v"
`include "jtag/full_handshake_tx.v"
`include "jtag/jtag_dm.v"
`include "jtag/jtag_driver.v"
`include "jtag/jtag_top.v"
/* verilator lint_on UNOPTFLAT */
/* verilator lint_on CASEINCOMPLETE */
/* verilator lint_on IMPLICIT */
