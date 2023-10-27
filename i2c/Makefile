sim_i2c_cntrl: i2c_wrapper.sv i2c_controller.sv tb_i2c_controller.sv adt7420.sv
	xvlog -sv i2c_controller.sv i2c_wrapper.sv tb_i2c_controller.sv adt7420.sv
	xelab tb_i2c_controller -s tb_i2c_controller
	xsim tb_i2c_controller --onfinish quit -runall
sim_top: tb_i2c_top.sv i2c_top.sv i2c_controller.sv i2c_wrapper.sv adt7420.sv seven_segment.vhd debounce.sv oneshot.sv
	xvhdl seven_segment.vhd
	xvlog -sv tb_i2c_top.sv i2c_top.sv i2c_controller.sv i2c_wrapper.sv adt7420.sv debounce.sv oneshot.sv
	xelab tb_i2c_top -s tb_i2c_top
	xsim tb_i2c_top --onfinish quit -runall
implementation_fast:
	vivado -mode batch -source i2c_implementation_fast_synth.tcl
gen_bit:
	vivado -mode batch -source i2c_synth.tcl
clean: 
	rm -rf .Xil *.swp *.bit *.rpt *.str *.jou *.pb *.log *.dir
