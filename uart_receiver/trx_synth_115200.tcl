######################################################################
# Script for generating bitstream for the RTX modules with a 115200 baud
# rate.
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Septemer 23, 2023
#
# Description: This script generates a bitstream for the RTX modules.
# The modules are synthesized, placed, and routed. The timing summary,
# utilization, and DRC reports are generated. The bitstream is then
# generated.
#
######################################################################

# Load files
read_verilog rx.v
read_verilog -sv tx.sv
read_verilog -sv debounce.sv
read_verilog -sv top_trx.sv
read_xdc top.xdc

# Perform synthesis
synth_design -top top_trx -part xc7a100tcsg324-1 -generic {BAUD_RATE=115200}

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file tx_top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file tx_top_utilization_impl.rpt
report_drc -file tx_top_drc_routed.rpt

# Generate bitstream
write_bitstream -force uart_115200.bit
