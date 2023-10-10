sim_spi_cntrl: spi_controller.sv tb_spi_controller.sv spi_subunit.sv
	xvlog -sv spi_controller.sv tb_spi_controller.sv spi_subunit.sv
	xelab tb_spi_controller -s tb_spi_controller
	xsim tb_spi_controller --onfinish quit -runall
sim_top_115200: rx.v debounce.sv tx.sv top_trx.sv
	xvlog rx.v
	xvlog -sv tx.sv debounce.sv top_trx.sv trx_tb.sv
	xelab trx_tb -s trx_tb -generic_top "BAUD_RATE=115200"
	xsim trx_tb --onfinish quit -runall
gen_bit:
	vivado -mode batch -source trx_synth.tcl
gen_bit_115200:
	vivado -mode batch -source trx_synth_115200.tcl
clean: 
	rm -rf .Xil *.bit *.rpt *.str *.jou *.pb *.log *.dir
