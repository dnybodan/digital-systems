######################################################################
# Script for generating bitstream for the RTX modules
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Septemer 27, 2023
#
# Description: This script generates a bitstream for the RTX modules.
#
######################################################################

# Load files
read_vhdl rx.vhd
read_vhdl seven_segment.vhd
read_vhdl top_trx.vhd
read_verilog -sv tx.sv
read_verilog -sv debounce.sv
read_xdc top.xdc

# Perform synthesis
synth_design -top top_trx -part xc7a100tcsg324-1

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file tx_top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file tx_top_utilization_impl.rpt
report_drc -file tx_top_drc_routed.rpt

# Generate bitstream
write_bitstream -force vhdl.bit
