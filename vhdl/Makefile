sim_rx: rx.vhd
	xvhdl rx.vhd
	xvlog tx_model.v
	xvlog -sv rx_tb.sv
	xelab rx_tb -s rx_tb
	xsim rx_tb --onfinish quit -runall
sim_top: rx.vhd debounce.sv tx.sv top_trx.sv
	xvhdl rx.vhd
	xvlog -sv tx.sv debounce.sv top_trx.sv trx_tb.sv
	xelab trx_tb -s trx_tb -generic_top "BAUD_RATE=19200"
	xsim trx_tb --onfinish quit -runall
gen_bit:
	vivado -mode batch -source trx_synth.tcl
clean: 
	rm -rf .Xil *.bit *.rpt *.str *.jou *.pb *.log *.dir
