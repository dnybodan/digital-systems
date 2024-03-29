# DDR4 DMA Transfer with AXI Bus Sniffer 

## Project Summary

The main objective of this project is to create a direct memory transfer from DDR4 memory to RFSoC DAC. After the transfer is complete, the objective then becomes detect throughput of a DMA transfer form DDR4 memory in the RFSoC 4x2 in order to predict the maximum bandwidth that can be supplied to the DAC utilizing this techinique. Ideally this achieves a RF bandwidth of 800 MHz with a 256 bit axi bus clocked at 100 MHz and a RFDC which splits each 256 bits into a 16 sample deep buffer. Later I will clock the AXI bus at 200 MHz and get a RF bandwidth of 1.6 GHz.

Right now the interaction the user has with the project is through the software application interfacing directly with the DMA core, GPIOs, custom core, and timers. By default the program will just run through a transfer as soon as the program is started and report the results via stdout(UART). The results of this experiment showed that the DMA transfer is capable of achieving a throughput 168 bits per clock cycle achieving a max bandwidth of around 600 MHz which is around 75% of the theoretical maximum. This is a very good result and shows that the DDR4 memory is capable of supplying the DAC with enough data to achieve the desired RF bandwidth. When clocking at 200 MHz the throughput increases to give around 1.2 GHz of RF bandwidth which is also very good.

Here is a screenshot of the block design.

<img width="1546" alt="Screenshot 2023-12-17 at 1 41 45 AM" src="https://github.com/dnybodan/ECEN_620_Nybo/assets/46764329/161852d9-0d85-4579-9806-5741fe86aeec">

The custom core I created is an AXI bus sniffer which was created in Vivado 2023.1 and was tested with a custom test bench I wrote in tandem called tb_axi_bust_sniffer.sv. This core attaches to the transfer lines of an AXI bus and detects the number of bits going through. It also reports the clock cycles and can also read the bytes going through the bus, however this part is not necessary for the simple throughput test. 

I wrote a software application in C which is the principal interface between the hardware and the user. This application is responsible for configuring the DMA core, GPIOs, and timers in bare metal. The application is also responsible for configuring the DMA core to transfer data from the DDR4 memory to the DAC and reporting the bitrate of the transfter from the sniffer core which is accessible via GPIO blocks reading registers directly from the core. Bellow is the result of one software application run incase the user does not have access to a RFSoC4x2 to run this design.

<img width="903" alt="Screenshot 2023-12-17 at 1 55 01 AM" src="https://github.com/dnybodan/ECEN_620_Nybo/assets/46764329/70cf263c-211e-4a78-abfd-01e444707f7f">

The result here shows about 16.2 Gbps which translates to about 162 bits per cycle which either lowers the bit precision for the full 800 MHz or lowers the bandwidth to about 5-600 MHz. Either way these are acceptable numbers. When clocking the AXI bus with 200 MHz the possible bandwidth goes up to about 1.2 Ghz bandwidth. 

**File Summary**

[/hw/axi_bus_sniffer.sv](/hw/axi_bus_sniffer.sv) - the system verilog definition of my custom IP core

[/hw/tb_axi_bus_sniffer.sv](/hw/tb_axi_bus_sniffer.sv) - the system verilog definition of the testbench of the IP core

[/hw/dma_axi_bus_sniffer_block_design.tcl](/hw/dma_axi_bus_sniffer_block_design.tcl) - the tcl script for building the hardware design including the block design for the full hardware system

[/hw/axi_bus_sniffer_ip.tcl](/hw/axi_bus_sniffer_ip.tcl) - the tcl script for building the custom IP core project in Vivado

[/hw/axi_bus_sniffer_dma_hw.bit](/hw/axi_bus_sniffer_dma_hw.bit) - bitstream for the hardware system

[/hw/axi_bus_sniffer_dma_hw.xsa](/hw/axi_bus_sniffer_dma_hw.xsa) - .xsa file for creating a new platform project for software application 

[/sw/dma_axi_sniffer.c](/sw/dma_axi_sniffer.c) - the bare metal application script for running the hardware and measuring throughput

[/sw/axi_bus_sniffer_app.elf](/sw/axi_bus_sniffer_app.elf) - the project excecutable and linker format file

[axi_bus_sniffer_dma_bd.pdf](axi_bus_sniffer_dma_bd.pdf) - a pdf of the block design already shown in the readme file but in a different layout

The project was created using Vivado 2023.1 and Vitis 2023.1. To run this project it the bit file will need to be downloaded as well as the .elf file run. The way to do this properly would be to create a new software application with a platform project created from the .xsa file in the /hw/ directory of this repo, then copy in the .c file in the /sw/ directory of this repo. Then build the project and run on the board. For some reason creating a .bit file with the software embedded was not generating using Vitis 2023.1, so the above procedure will need to be followed if you want to run this on an RFSoC 4x2. Otherwise the output is pictured above. 


**Warnings**:

No warnings to report

**Resources**:

29635 LUT, 3108 LUTRAM, 38484 FF, 43 BRAM, 3 DSP, 119 IO, 5 BUFG, 1 MMCM, 3 PLL

**Timing**:

WNS 0.227


