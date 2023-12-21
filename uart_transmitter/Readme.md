# Uart Transmitter** 

Custom built UART transmitter

**Resources**:

| Site Type         | Used | Fixed | Prohibited | Available | Util% |
|-------------------|------|-------|------------|-----------|-------|
| Slice LUTs        | 39   | 0     | 0          | 63400     | 0.06  |
| LUT as Logic      | 39   | 0     | 0          | 63400     | 0.06  |
| LUT as Memory     | 0    | 0     | 0          | 19000     | 0.00  |
| Slice Registers   | 47   | 0     | 0          | 126800    | 0.04  |
| Register as Flip  | 47   | 0     | 0          | 126800    | 0.04  |
| Register as Latch | 0    | 0     | 0          | 126800    | 0.00  |
| F7 Muxes          | 1    | 0     | 0          | 31700     | <0.01 |
| F8 Muxes          | 0    | 0     | 0          | 15850     | 0.00  |


| Site Type             | Used | Fixed | Prohibited | Available | Util%  |
|-----------------------|------|-------|------------|-----------|-------|
| Bonded IOB            | 21   | 21    | 0          | 210       | 10.00 |
| IOB Master Pads       | 10   |       |            |           |       |
| IOB Slave Pads        | 11   |       |            |           |       |
| Bonded IPADs          | 0    | 0     | 0          | 2         | 0.00  |
| PHY_CONTROL           | 0    | 0     | 0          | 6         | 0.00  |
| PHASER_REF            | 0    | 0     | 0          | 6         | 0.00  |
| OUT_FIFO              | 0    | 0     | 0          | 24        | 0.00  |
| IN_FIFO               | 0    | 0     | 0          | 24        | 0.00  |
| IDELAYCTRL            | 0    | 0     | 0          | 6         | 0.00  |
| IBUFDS                | 0    | 0     | 0          | 202       | 0.00  |
| PHASER_OUT/PHASER_OUT | 0    | 0     | 0          | 24        | 0.00  |
| PHASER_IN/PHASER_IN   | 0    | 0     | 0          | 24        | 0.00  |
| IDELAYE2/IDELAYE2     | 0    | 0     | 0          | 300       | 0.00  |
| ILOGIC                | 0    | 0     | 0          | 210       | 0.00  |
| OLOGIC                | 0    | 0     | 0          | 210       | 0.00  |



**Warnings**:

WARNING: [DRC CFGBVS-1] Missing CFGBVS and CONFIG_VOLTAGE Design Properties: Neither the CFGBVS nor CONFIG_VOLTAGE voltage property is set in the current_design.  Configuration bank voltage select (CFGBVS) must be set to VCCO or GND, and CONFIG_VOLTAGE must be set to the correct configuration voltage, in order to determine the I/O voltage support for the pins in bank 0. 

**Timing**:

WNS: 5.284ns






