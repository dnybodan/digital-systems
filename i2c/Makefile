sim_i2c_cntrl: i2c_controller.sv tb_i2c_controller.sv adt7420.sv
	xvlog -sv i2c_controller.sv tb_i2c_controller.sv adt7420.sv
	xelab tb_i2c_controller -s tb_i2c_controller
	xsim tb_i2c_controller --onfinish quit -runall
sim_top: top_spi.sv spi_controller.sv adxl362_model.sv seven_segment.vhd debounce.sv oneshot.sv
	xvhdl seven_segment.vhd
	xvlog -sv tb_top_spi.sv top_spi.sv spi_controller.sv adxl362_model.sv debounce.sv oneshot.sv
	xelab tb_top_spi -s tb_top_spi
	xsim tb_top_spi --onfinish quit -runall
gen_bit:
	vivado -mode batch -source spi_synth.tcl
clean: 
	rm -rf .Xil *.bit *.rpt *.str *.jou *.pb *.log *.dir
