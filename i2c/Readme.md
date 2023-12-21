# Daniel Nybo 

**I2C Controller** - 
## Resources
| Site Type             | Used | Fixed | Prohibited | Available | Util% |
|-----------------------|------|-------|------------|-----------|-------|
| Slice LUTs            | 224  | 0     | 0          | 63400     | 0.35  |
| LUT as Logic          | 224  | 0     | 0          | 63400     | 0.35  |
| LUT as Memory         | 0    | 0     | 0          | 19000     | 0.00  |
| Slice Registers       | 208  | 0     | 0          | 126800    | 0.16  |
| Register as Flip Flop | 208  | 0     | 0          | 126800    | 0.16  |
| Register as Latch     | 0    | 0     | 0          | 126800    | 0.00  |
| F7 Muxes              | 5    | 0     | 0          | 31700     | 0.02  |
| F8 Muxes              | 0    | 0     | 0          | 15850     | 0.00  |

| Site Type                      | Used | Fixed | Prohibited | Available | Util% |
|--------------------------------|------|-------|------------|-----------|-------|
| Bonded IOB                     | 56   | 56    | 0          | 210       | 26.67 |
| IOB Master Pads                | 28   |       |            |           |       |
| IOB Slave Pads                 | 25   |       |            |           |       |
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


## Warnings

No warnings to report

## Timing

3.439 WNS

When I speed up the clock frequency I am able to get it to 200MHz with a WNS of 0.561 which is close to 0 meaning an increase in clock speed may still be possible but could lead to error as soon as I pass to a negatave slack time. 

## Assignment Specific Responses

# Timing analysis

Max Delay Paths:

What is the worst negative slack of your design? (WNS)  
* 3.439 ns

With this number, determine the maximum clock frequency of your design
What is the name of the signal that contains the WNS? 
* The max clock frequency is theoretically 152.3 MHz with this WNS since max clk freq is 1/(10ns - 3.439ns) = 152.3 MHz

What percentage of this signal delay is routing and what percentage is logic?
* 61.842% of the delay is routing and 38.157% is logic

What is the clock skew between the source clock and the destination clock?
* -0.038ns


Min Delay Paths:

What is the slack between the worst case hold time constraint?
* 0.121ns

What is the clock skew between the source clock and the destination clock?
* 0.00 ns


For implementation_fast:

Max Delay Paths:

What is the clock rate you achieved with this design?
* 200 MHz
What is the worst negative slack of your design? (WNS)
* 0.561 ns
How does this compare with your estimate of the maximum clock frequency in the previous set of questions?
* This is a larger clock rate than the estimate I made based on the previous design. This is proably due to optimizations like pipelining registers.
