######################################################################
# Script for generating bitstream for the I2C modules
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Oct 27, 2023
#
# Description: This script will generate a bitstream for the I2C
#
######################################################################

# Load files
read_vhdl seven_segment.vhd
read_verilog -sv i2c_top.sv
read_verilog -sv debounce.sv oneshot.sv i2c_controller.sv i2c_wrapper.sv
read_xdc top.xdc

# change siverity of warnings
set_msg_config -new_severity "INFO" -id "Constraints 18-5210"
set_msg_config -new_severity "INFO" -id "DRC RTSTAT-10"
set_msg_config -new_severity "INFO" -id "Synth 8-3331"
set_msg_config -new_severity "INFO" -id "Synth 8-7080"

# Perform synthesis
synth_design -top i2c_top -part xc7a100tcsg324-1 -generic {CLK_FREQ=100000000}

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file i2c_top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file i2c_top_utilization_impl.rpt
report_drc -file i2c_top_drc_routed.rpt

# Generate bitstream
write_bitstream -force i2c.bit
