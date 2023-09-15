sim_tx: tx.sv
	xvlog -sv tx.sv tx_tb.sv rx_model.sv
	xelab tx_tb -s tx_tb
	xsim tx_tb --onfinish quit -runall
sim_top: tx.sv debounce.sv tx_top.sv 
	xvlog -sv tx.sv debounce.sv tx_top.sv top_tb.sv rx_model.sv
	xelab top_tb -s top_tb
	xsim top_tb --onfinish quit -runall
gen_bit:
	vivado -mode batch -source tx_synth.tcl
clean: 
	rm -rf *.bit *.rpt *.str *.jou *.pb *.log *.dir
