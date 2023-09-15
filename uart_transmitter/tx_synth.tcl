######################################################################
# Script for generating bitstream for the TX module
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Septemer 14, 2023
#
# Description: This script will generate a bitstream for the TX module. 
#              It will also generate reports for timing, utilization, 
#              and DRC.
#
######################################################################

# Load files
read_verilog -sv tx.sv
read_verilog -sv debounce.sv
read_verilog -sv tx_top.sv
read_xdc top.xdc

# Perform synthesis
synth_design -top tx_top -part xc7a100tcsg324-1

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file tx_top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file tx_top_utilization_impl.rpt
report_drc -file tx_top_drc_routed.rpt

# Generate bitstream
write_bitstream -force tx.bit
