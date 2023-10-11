# Daniel Nybo 

**Uart Receiver and Testbench** - *Approx 30 Hours Spent*

**Discussion**

The main challenges I faced were with trying to create the spi controller without existing testbenches. I realize this is a part of the task and so it wasn't that bad considering. I also had a hard time connecting the top level state machine to the spi controller. This used a significant portion of my time. 

## Assignment Specific Responses

**Resources**:
+-------------------------+------+-------+------------+-----------+-------+
| Slice LUTs              |  139 |     0 |          0 |     63400 |  0.22 |
|   LUT as Logic          |  139 |     0 |          0 |     63400 |  0.22 |
|   LUT as Memory         |    0 |     0 |          0 |     19000 |  0.00 |
| Slice Registers         |  204 |     0 |          0 |    126800 |  0.16 |
|   Register as Flip Flop |  204 |     0 |          0 |    126800 |  0.16 |
|   Register as Latch     |    0 |     0 |          0 |    126800 |  0.00 |
| F7 Muxes                |    5 |     0 |          0 |     31700 |  0.02 |
| F8 Muxes                |    0 |     0 |          0 |     15850 |  0.00 |
+-------------------------+------+-------+------------+-----------+-------+

+-----------------------------+------+-------+------------+-----------+-------+
|          Site Type          | Used | Fixed | Prohibited | Available | Util% |
+-----------------------------+------+-------+------------+-----------+-------+
| Bonded IOB                  |   56 |    56 |          0 |       210 | 26.67 |
|   IOB Master Pads           |   29 |       |            |           |       |
|   IOB Slave Pads            |   24 |       |            |           |       |
| Bonded IPADs                |    0 |     0 |          0 |         2 |  0.00 |
| PHY_CONTROL                 |    0 |     0 |          0 |         6 |  0.00 |
| PHASER_REF                  |    0 |     0 |          0 |         6 |  0.00 |
| OUT_FIFO                    |    0 |     0 |          0 |        24 |  0.00 |
| IN_FIFO                     |    0 |     0 |          0 |        24 |  0.00 |
| IDELAYCTRL                  |    0 |     0 |          0 |         6 |  0.00 |
| IBUFDS                      |    0 |     0 |          0 |       202 |  0.00 |
| PHASER_OUT/PHASER_OUT_PHY   |    0 |     0 |          0 |        24 |  0.00 |
| PHASER_IN/PHASER_IN_PHY     |    0 |     0 |          0 |        24 |  0.00 |
| IDELAYE2/IDELAYE2_FINEDELAY |    0 |     0 |          0 |       300 |  0.00 |
| ILOGIC                      |    0 |     0 |          0 |       210 |  0.00 |
| OLOGIC                      |    0 |     0 |          0 |       210 |  0.00 |
+-----------------------------+------+-------+------------+-----------+-------+

**Warnings**:

No warnings to report

**Timing**:

3.689ns