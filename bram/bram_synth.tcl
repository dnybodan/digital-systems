######################################################################
# Script for generating bitstream for the bram design
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Nov 9, 2023
#
# Description: This script generates a bitstream for the bram design.
#
######################################################################

# Load files
read_verilog rx.v
read_verilog -sv bram.sv oneshot.sv debounce.sv tx.sv
read_vhdl seven_segment.vhd
read_xdc top.xdc

# change siverity of warnings
set_msg_config -new_severity "INFO" -id "Constraints 18-5210"
set_msg_config -new_severity "INFO" -id "DRC RTSTAT-10"
set_msg_config -new_severity "INFO" -id "Synth 8-3331"
set_msg_config -new_severity "INFO" -id "Synth 8-7080"

# Perform synthesis
synth_design -top bram -part xc7a100tcsg324-1

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file bram_timing_summary_routed.rpt -warn_on_violation
report_utilization -file bram_utilization_impl.rpt
report_drc -file bram_drc_routed.rpt

# Generate bitstream
write_bitstream -force bram.bit
