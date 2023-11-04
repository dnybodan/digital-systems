sim_top: mmcm.sv mmcm_tb.sv debounce.sv oneshot.sv seven_segment.vhd
	xvhdl seven_segment.vhd
	xvlog -sv mmcm.sv mmcm_tb.sv debounce.sv oneshot.sv
	xelab mmcm_tb -s mmcm_tb
	xsim mmcm_tb --onfinish quit -runall
gen_bit:
	vivado -mode batch -source mmcm_synth.tcl
clean: 
	rm -rf .Xil *.bit *.rpt *.str *.jou *.pb *.log *.dir
