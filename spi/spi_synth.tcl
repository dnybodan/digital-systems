######################################################################
# Script for generating bitstream for the SPI modules
#
# Author: Daniel Nybo
# Class: ECEN 620
# Date: Oct 9, 2023
#
# Description: This script will generate a bitstream for the SPI
#
######################################################################

# Load files
read_vhdl seven_segment.vhd
read_verilog -sv top_spi.sv
read_verilog -sv debounce.sv oneshot.sv spi_controller.sv
read_xdc top.xdc

# Perform synthesis
synth_design -top top_spi -part xc7a100tcsg324-1

# Perform Implementation
opt_design
place_design
route_design

# Generate reports
report_timing_summary -max_paths 10 -report_unconstrained -file spi_top_timing_summary_routed.rpt -warn_on_violation
report_utilization -file spi_top_utilization_impl.rpt
report_drc -file spi_top_drc_routed.rpt

# Generate bitstream
write_bitstream -force spi_adx3621.bit
