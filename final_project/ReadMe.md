# Daniel Nybo 

**DDR4 DMA Transfer with AXI Bus Sniffer** - *Approx 50 Hours Spent*

**Summary of Major Challenges**

The main challenges for this project came from integrating the DDR4 in the PL RAM, learning to use the Direct Memory Access block, and finally creating/debugging the HDL AXI bus sniffer in system verilog. Each of these tasks took a significant chunk of time but by far the hardest part of this lab was that when I needed to make a change to my IP there was a 30 minute build time before I could test my changes. This made debugging very difficult and time consuming. I ended up adding some extra ports to my IP so that I could debug the design after building the hardware. I ended up using one of these debug signals to execute the behavior I wanted from the IP. 

**Warnings**:

No warnings to report

**Resources**:

29635 LUT, 3108 LUTRAM, 38484 FF, 43 BRAM, 3 DSP, 119 IO, 5 BUFG, 1 MMCM, 3 PLL

**Timing**:

WNS 0.227

## Project Sumary

**Project Name: DMA AXI Bus Sniffer**

**Project Summary**:

The main objective of this project is to detect throughput of a DMA transfer form DDR4 memory in the RFSoC 4x2 in order to predict the maximum bandwidth that can be supplied to the DAC utilizing this techinique. Ideally this achieves a RF bandwidth of 800 MHz with a 256 bit axi bus clocked at 100 MHz and a RFDC which splits each 256 bits into a 16 bit sample buffer. Later I will clock the AXI bus at 200 MHz and get a RF bandwidth of 1.6 GHz.

Right now the interaction the user has with the project is through the software application interfacing directly with the DMA core, GPIOs, custom core, and timers. By default the program will just run through a transfer as soon as the program is started and report the results via stdout(UART). The results of this experiment showed that the DMA transfer is capable of achieving a throughput 168 bits per clock cycle achieving a max bandwidth of around 600 MHz which is around 75% of the theoretical maximum. This is a very good result and shows that the DDR4 memory is capable of supplying the DAC with enough data to achieve the desired RF bandwidth. When clocking at 200 MHz the throughput increases to give around 1.2 GHz of RF bandwidth which is also very good.

The custom core I created is an AXI bus sniffer which was created in Vivado 2023.1 and was tested with a custom test bench I wrote in tandem called tb_axi_bust_sniffer.sv. This core attaches to the transfer lines of an AXI bus and detects the number of bits going through. It also reports the clock cycles and can also read the bytes going through the bus, however this part is not necessary for the simple throughput test. 

I wrote a software application in C which is the principal interface between the hardware and the user. This application is responsible for configuring the DMA core, GPIOs, and timers in bare metal. The application is also responsible for configuring the DMA core to transfer data from the DDR4 memory to the DAC and reporting the bitrate of the transfter from the sniffer core which is accessible via GPIO blocks reading registers directly from the core.

I have included the C file I wrote in the sw directory of this repo. I have also included a screenshot of the results incase the user does not have access to an RFSoC4x2 board. Below is the screenshot. 

The hardware block design can be rebuild and viewed using the .tcl script provided in the hw directory of this repo.

The custom IP can also be rebuilt using the .tcl script provided in the hw directory of this repo.

A bitfile with the embedded software application can also be found in the hw directory of this repo.


