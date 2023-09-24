# Daniel Nybo 

**Uart Receiver and Testbench** - *Approx 30 Hours Spent*

**Summary of Major Challenges**

The main challenges I faced were with trying to test my Verilog 95 code without an existing testbench and tx model. This made it difficult to decide whether my test bench, my tx model, or my reciever was the culprit of bugs during development. I also had a bit of a hard time debugging the test benches, but not nearly as much time as it took to just get the reciever working.

## Assignment Specific Responses

**Resources**:

| Site Type               | Used | Fixed | Prohibited | Available | Util%  |
|-------------------------|------|-------|------------|-----------|--------|
| Slice LUTs              | 111  | 0     | 0          | 63400     | 0.18   |
| LUT as Logic            | 111  | 0     | 0          | 63400     | 0.18   |
| LUT as Memory           | 0    | 0     | 0          | 19000     | 0.00   |
| Slice Registers         | 123  | 0     | 0          | 126800    | 0.10   |
| Register as Flip Flop   | 123  | 0     | 0          | 126800    | 0.10   |
| Register as Latch       | 0    | 0     | 0          | 126800    | 0.00   |
| F7 Muxes                | 1    | 0     | 0          | 31700     | <0.01  |
| F8 Muxes                | 0    | 0     | 0          | 15850     | 0.00   |

| Site Type                     | Used | Fixed | Prohibited | Available | Util%  |
|-------------------------------|------|-------|------------|-----------|--------|
| Bonded IOB                    | 32   | 32    | 0          | 210       | 15.24  |
| IOB Master Pads               | 13   |       |            |           |        |
| IOB Slave Pads                | 18   |       |            |           |        |

**Warnings**:

No warnings, no warnings were downgraded either. 

**Timing**:

WNS: 4.525ns