######################################################################
# Script for generating bitstream for the mmcm design
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Nov 3, 2023
#
# Description: This script generates a bitstream for the mmcm design.
#
######################################################################

# Load files
read_verilog -sv mmcm.sv
read_vhdl seven_segment.vhd
read_xdc top.xdc

# change siverity of warnings
set_msg_config -new_severity "INFO" -id "Constraints 18-5210"
set_msg_config -new_severity "INFO" -id "DRC RTSTAT-10"
set_msg_config -new_severity "INFO" -id "Synth 8-3331"
set_msg_config -new_severity "INFO" -id "Synth 8-7080"

# Perform synthesis
synth_design -top mmcm -part xc7a100tcsg324-1

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file mmcm_timing_summary_routed.rpt -warn_on_violation
report_utilization -file mmcm_utilization_impl.rpt
report_drc -file mmcm_drc_routed.rpt

# Generate bitstream
write_bitstream -force mmcm.bit
