# Daniel Nybo 

**microblaze** - *Approx 10 Hours Spent*

**Summary of Major Challenges**

I mainly faced challenges getting io pins named correctly and coming up with a good final project proposal.

## Assignment Specific Responses

**Resources**:

Design Resources: 
    Slice LUTS: 1531
    Slice Registers: 1352
    Bonded IOB: 41

**Warnings**:

Ignoring warnings

**Timing**:

WNS: 2.44 ns

**Proposed Final Project**:

At a high level I will create a DMA application for transfering bits from DDR4 memory to the RFSoC 4x2 Data Converter to be output on the Vout00 pin. The io I will be using are various clocks(needed for ddr and data converters), the ddr4 access pins collected from Real Digital documentation and the Vout pin for the data converter. 

The IP blocks I will use are the AXI DMA block, the MPSoC IP core for the RFSoC4x2, the ZCU Ultrascale+ RF Data Converter IP Core as well as several other blocks like processor system reset, GPIO, and axi interconnects. 

The RTL portion I intend to write for this project is a scaling and downsampling algorithm which will either scale, downsample, or do nothing to the data I am outputting based on switches on the board. Essentially I will take data into the block, perform the desired algorithm, and then output it to the Data Converter via AXI. This will be useful for quickly seeing the affects of a lower sample rate for specific waveforms(sawtooth or square more likely to ailias) or modelling something like noise and easily being able to toggle the magnitude of the noise floor using the on board switches of the RFSoC4x2. 

Finally the software for this program will utilize several drivers for the different IP cores generated including several GPIO cores, RFDC core, MPSoC core and peripherals as well as a DMA core. I will utilize these drivers to create a custom application which will run the waveform generator continuously upon some basic signals I will upload in DRAM. 
