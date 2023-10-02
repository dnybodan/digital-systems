# Daniel Nybo 

**Uart Receiver and Testbench** - *Approx 13 Hours Spent*

**Summary of Major Challenges**

My major challenges were just getting used to vhdl and how the syntax works. It wasn't super difficult but there were a few hicups as I went through translating and then also creating the seven-segment controller.

## Assignment Specific Responses

**Resources**:

| Site Type                  | Used | Fixed | Prohibited | Available | Util% |
|----------------------------|------|-------|------------|-----------|-------|
| Slice LUTs                 |  196 |     0 |          0 |     63400 |  0.31 |
| LUT as Logic               |  196 |     0 |          0 |     63400 |  0.31 |
| LUT as Memory              |    0 |     0 |          0 |     19000 |  0.00 |
| Slice Registers            |  243 |     0 |          0 |    126800 |  0.19 |
| Register as Flip Flop      |  243 |     0 |          0 |    126800 |  0.19 |
| Register as Latch          |    0 |     0 |          0 |    126800 |  0.00 |
| F7 Muxes                   |    5 |     0 |          0 |     31700 |  0.01 |
| F8 Muxes                   |    0 |     0 |          0 |     15850 |  0.00 |

| Site Type                  | Used | Fixed | Prohibited | Available | Util% |
|----------------------------|------|-------|------------|-----------|-------|
| Bonded IOB                 |   47 |    47 |          0 |       210 | 22.38 |
| IOB Master Pads            |   22 |       |            |           |       |
| IOB Slave Pads             |   22 |       |            |           |       |
| Bonded IPADs               |    0 |     0 |          0 |         2 |  0.00 |
| PHY_CONTROL                |    0 |     0 |          0 |         6 |  0.00 |
| PHASER_REF                 |    0 |     0 |          0 |         6 |  0.00 |
| OUT_FIFO                   |    0 |     0 |          0 |        24 |  0.00 |
| IN_FIFO                    |    0 |     0 |          0 |        24 |  0.00 |
| IDELAYCTRL                 |    0 |     0 |          0 |         6 |  0.00 |
| IBUFDS                     |    0 |     0 |          0 |       202 |  0.00 |
| PHASER_OUT/PHASER_OUT_PHY  |    0 |     0 |          0 |        24 |  0.00 |
| PHASER_IN/PHASER_IN_PHY    |    0 |     0 |          0 |        24 |  0.00 |
| IDELAYE2/IDELAYE2_FINEDELAY|    0 |     0 |          0 |       300 |  0.00 |
| ILOGIC                     |    0 |     0 |          0 |       210 |  0.00 |
| OLOGIC                     |    0 |     0 |          0 |       210 |  0.00 |


**Warnings**:

WARNING: [Synth 8-7080] Parallel synthesis criteria is not met
Not an important warning to the design of the digital system

**Timing**:

WNS: 3.938ns

**Discussion**:

I think that vhdl is a little more verbose and requires some uneccessary characters. I think that it could use an update potentially. That said its more explicit and avoids some of the confusion of verilog. I didn't love coding in VHDL but it wasn't all bad. 