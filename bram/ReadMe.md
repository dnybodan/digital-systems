# Daniel Nybo 

**BRAM**

This project demonstrates two different ways to instantiate a BRAM in an FPGA including usage and integration with custom UART designs. 

**Resources**:
| Site Type             | Used | Fixed | Prohibited | Available | Util% |
|-----------------------|------|-------|------------|-----------|-------|
| Slice LUTs            | 193  | 0     | 0          | 63400     | 0.30  |
| LUT as Logic          | 193  | 0     | 0          | 63400     | 0.30  |
| LUT as Memory         | 0    | 0     | 0          | 19000     | 0.00  |
| Slice Registers       | 287  | 0     | 0          | 126800    | 0.23  |
| Register as Flip Flop | 287  | 0     | 0          | 126800    | 0.23  |
| Register as Latch     | 0    | 0     | 0          | 126800    | 0.00  |
| F7 Muxes              | 1    | 0     | 0          | 31700     | <0.01 |
| F8 Muxes              | 0    | 0     | 0          | 15850     | 0.00  |

| Site Type         | Used | Fixed | Prohibited | Available | Util% |
|-------------------|------|-------|------------|-----------|-------|
| Block RAM Tile    | 1.5  | 0     | 0          | 135       | 1.11  |
| RAMB36/FIFO*      | 1    | 0     | 0          | 135       | 0.74  |
| RAMB36E1 only     | 1    |       |            |           |       |
| RAMB18            | 1    | 0     | 0          | 270       | 0.37  |
| RAMB18E1 only     | 1    |       |            |           |       |

| Site Type                      | Used | Fixed | Prohibited | Available | Util% |
|--------------------------------|------|-------|------------|-----------|-------|
| Bonded IOB                     | 23   | 23    | 0          | 210       | 10.95 |
| IOB Master Pads                | 15   |       |            |           |       |
| IOB Slave Pads                 | 6    |       |            |           |       |
| Bonded IPADs                   | 0    | 0     | 0          | 2         | 0.00  |
| PHY_CONTROL                    | 0    | 0     | 0          | 6         | 0.00  |
| PHASER_REF                     | 0    | 0     | 0          | 6         | 0.00  |
| OUT_FIFO                       | 0    | 0     | 0          | 24        | 0.00  |
| IN_FIFO                        | 0    | 0     | 0          | 24        | 0.00  |
| IDELAYCTRL                     | 0    | 0     | 0          | 6         | 0.00  |
| IBUFDS                         | 0    | 0     | 0          | 202       | 0.00  |
| PHASER_OUT/PHASER_OUT_PHY      | 0    | 0     | 0          | 24        | 0.00  |
| PHASER_IN/PHASER_IN_PHY        | 0    | 0     | 0          | 24        | 0.00  |
| IDELAYE2/IDELAYE2_FINEDELAY    | 0    | 0     | 0          | 300       | 0.00  |
| ILOGIC                         | 0    | 0     | 0          | 210       | 0.00  |
| OLOGIC                         | 0    | 0     | 0          | 210       | 0.00  |


**Warnings**:

No warnings

**Timing**:

WNS 2.696


