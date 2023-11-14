sim_top: bram.sv bram_tb.sv oneshot.sv debounce.sv seven_segment.vhd tx.sv rx_model.sv rx.v tx_model.v
	xvhdl seven_segment.vhd
	xvlog rx.v tx_model.v
	xvlog -sv bram.sv bram_tb.sv oneshot.sv debounce.sv tx.sv rx_model.sv
	xvlog --nolog -sv /opt/Xilinx/Vivado/2023.1/data/verilog/src/glbl.v
	xelab bram_tb -L unisims_ver glbl -relax -s bram_tb
	xsim bram_tb --onfinish quit -runall
gen_bit:
	vivado -mode batch -source bram_synth.tcl
clean: 
	rm -rf .Xil *.bit *.rpt *.str *.jou *.pb *.log *.dir tight_setup_hold_pins.txt
