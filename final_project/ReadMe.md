# Daniel Nybo 

**DDR4 DMA Transfer with AXI Bus Sniffer** - *Approx 50 Hours Spent*

**Summary of Major Challenges**

The main challenges for this project came from integrating the DDR4 in the PL RAM, learning to use the Direct Memory Access block, and finally creating the HDL AXI bus sniffer in system verilog. Each of these tasks took a significant chunk of time. 


**Warnings**:

No warnings to report

**Timing**:

WNS 0.227

## Project Sumary

**Project Name: DMA AXI Bus Sniffer**

**Project Summary**:

The main objective of this project is to detect throughput of a DMA transfer form DDR4 memory in the RFSoC 4x2 in order to predict the maximum bandwidth that can be supplied to the DAC utilizing this techinique. Theoretically if the AXI bus is clocked at 200 MHz and the bitwidth fo the data bus is 256 then 256 bits can be transfered to the DAC every clock cycle. The DDR4 memory should be capable of achieving this data rate utilizing 64 bit data reads at 1200 MHz filling a data buffer which then gets transfered to the device over AXI bus. Ideally this achieves a bandwidth of 1.6 GHz. 

The way I will be measuring this is in two ways. One will be to simply time the transfer using a timer staring before the transfer is initiated and after the transfer completes. I will then divide the number of bits transfered to get the bit rate. The other way I will measure this is using a custom IP block which counts the number of bits transfered on the axi bus while tvalid is asserted outputing a bit rate throughout the transfer. This will be reported to the processing system utilizing a GPIO block connected directly to my custom AXI sniffer IP. 

The AXI bus sniffer was created in Vivado 2023.1 and was tested with a custom test bench I wrote in tandem.
The block design can be rebuild and viewed using the .tcl script provided. 
