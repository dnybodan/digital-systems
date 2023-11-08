sim_top: mmcm.sv mmcm_tb.sv seven_segment.vhd
	xvhdl seven_segment.vhd
	xvlog -sv mmcm.sv mmcm_tb.sv
	xvlog --nolog -sv /opt/Xilinx/Vivado/2023.1/data/verilog/src/glbl.v
	xelab mmcm_tb -L unisims_ver glbl -relax -s mmcm_tb
	xsim mmcm_tb --onfinish quit -runall
gen_bit:
	vivado -mode batch -source mmcm_synth.tcl
clean: 
	rm -rf .Xil *.bit *.rpt *.str *.jou *.pb *.log *.dir tight_setup_hold_pins.txt
