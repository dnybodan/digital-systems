/***************************************************************************
*
* Module: MMCM
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: November 4, 2023
*
* Description: MMCM instantiation and configuration circuitry for demonstrating
*              proficiency and  MMCM functionality in the Nexys DDR board.
*
****************************************************************************/

`timescale 1ns/1ps
`default_nettype none
module mmcm(input wire logic CLK100MHZ,
            input wire logic CPU_RESETN,
            input wire logic[15:0] SW,
            output logic[15:0] LED,
            output logic[7:0] AN,
            output logic [6:0] segment
            );
`default_nettype wire

    // constants
    localparam RESET_LOW = 1'b0;

    // create some internal signals
    (* ASYNC_REG = "TRUE" *) logic rst, rst_d;
    logic[15:0] sw, sw_d;
    logic CLKOUT0, CLKOUT1, CLKOUT2, CLKOUT3, CLKOUT4, CLKOUT5, CLKOUT6;
    logic CLKOUT0B, CLKOUT1B, CLKOUT2B, CLKOUT3B;
    logic CLKFBOUTB;
    logic PWRDWN;
    logic CLKOUT0_1, CLKOUT0B_1, CLKOUT1_1, CLKOUT1B_1, CLKOUT2_1, CLKOUT2B_1;
    logic CLKOUT3_1, CLKOUT3B_1, CLKOUT4_1, CLKOUT5_1, CLKOUT6_1;
    logic CLKFBOUTB_1;
    logic PWRDWN_1;

    // bufg signals for first mmcm
    logic CLKIN1;
    logic CLKOUT0_BUFG_IN;
    logic CLKFBIN,CLKFBOUT;
    (* ASYNC_REG = "TRUE" *) logic LOCKED;

    // bufg signals for second mmcm
    logic CLKIN1_1; // output of clkout0 from first mmcm through bufg
    logic CLKOUT0_1_BUFG_IN; // output of second mmcm clk0 into bufg
    logic CLKFBOUT_1; // feedback without bufg
    (* ASYNC_REG = "TRUE" *) logic LOCKED_1;

    // clock crossing reset signals
    (* ASYNC_REG = "TRUE" *) logic rst1, rst1_d, rst1_dd;
    (* ASYNC_REG = "TRUE" *) logic rst2, rst2_d, rst2_dd;
    (* ASYNC_REG = "TRUE" *) logic rst3, rst3_d, rst3_dd;
    (* ASYNC_REG = "TRUE" *) logic rst4, rst4_d, rst4_dd;
    (* ASYNC_REG = "TRUE" *) logic rst5, rst5_d, rst5_dd;
    (* ASYNC_REG = "TRUE" *) logic rst6, rst6_d, rst6_dd;
    
    // add the async reg attribute to the reset signals
    (* ASYNC_REG = "TRUE" *) logic rst0_1, rst0_1_d, rst0_1_dd; // clk0 for second mmcm

    // clock domain 32 bit counters
    logic[31:0] CNT0,CNT1,CNT2,CNT3,CNT4,CNT5,CNT6,CNTB_0,CNT_META;
    logic[31:0] segment_data;

    // pulse signals
    (* ASYNC_REG = "TRUE" *) logic PULSE3, PULSE4;
    (* ASYNC_REG = "TRUE" *) logic[31:0] PULSE3CNT, PULSE4CNT;

    // edge detector and flip flop signals for PULSE3CNT
    (* ASYNC_REG = "TRUE" *) logic PULSE3CNT_d, PULSE3CNT_dd, PULSE3CNT_ddd;

    // edge detector, stretcher and flip flop signals for PULSE4CNT
    (* ASYNC_REG = "TRUE" *) logic PULSE4CNT_d, PULSE4CNT_dd, PULSE4CNT_ddd, en_q;

    // mmcm 2 clk0 toggle signal
    (* ASYNC_REG = "TRUE" *) logic clk0_1_toggle;

    // reset synchronizer
    always_ff @(posedge CLK100MHZ) begin
        rst_d <= !CPU_RESETN;
        rst <= rst_d;
    end

    // switch synchronizer
    always_ff @(posedge CLK100MHZ) begin
        sw_d <= SW;
        sw <= sw_d;
    end

    // instantiate the MMCM
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"), // Bandwidth setting (LOW, OPTIMIZED, HIGH)
        .CLKFBOUT_MULT_F(10.0), // Multiply value for all CLKOUT (2.000-64.000).
        .CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
        .CLKIN1_PERIOD(10.000), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        .CLKOUT1_DIVIDE(10.0),
        .CLKOUT2_DIVIDE(10.0),
        .CLKOUT3_DIVIDE(60.0),
        .CLKOUT4_DIVIDE(4.5),
        .CLKOUT5_DIVIDE(40.0),
        .CLKOUT6_DIVIDE(3.0),
        .CLKOUT0_DIVIDE_F(10.0), // Divide amount for CLKOUT0 (1.000-128.000).
        // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.20),
        .CLKOUT2_DUTY_CYCLE(0.70),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT6_DUTY_CYCLE(0.5),
        // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_PHASE(180.0),
        .CLKOUT2_PHASE(90.0),
        .CLKOUT3_PHASE(18.0),
        .CLKOUT4_PHASE(18.0),
        .CLKOUT5_PHASE(0.0),
        .CLKOUT6_PHASE(0.0),
        .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .DIVCLK_DIVIDE(1), // Master division value (1-106)
        .REF_JITTER1(0.0), // Reference input jitter in UI (0.000-0.999).
        .STARTUP_WAIT("FALSE") // Delays DONE until MMCM is locked (FALSE, TRUE)
        ) MMCME2_BASE_0 (
        // Clock Outputs: 1-bit (each) output: User configurable clock outputs
        .CLKOUT0(CLKOUT0_BUFG_IN), // 1-bit output: CLKOUT0
        .CLKOUT0B(CLKOUT0B), // 1-bit output: Inverted CLKOUT0
        .CLKOUT1(CLKOUT1), // 1-bit output: CLKOUT1
        .CLKOUT1B(CLKOUT1B), // 1-bit output: Inverted CLKOUT1
        .CLKOUT2(CLKOUT2), // 1-bit output: CLKOUT2
        .CLKOUT2B(CLKOUT2B), // 1-bit output: Inverted CLKOUT2
        .CLKOUT3(CLKOUT3), // 1-bit output: CLKOUT3
        .CLKOUT3B(CLKOUT3B), // 1-bit output: Inverted CLKOUT3
        .CLKOUT4(CLKOUT4), // 1-bit output: CLKOUT4
        .CLKOUT5(CLKOUT5), // 1-bit output: CLKOUT5
        .CLKOUT6(CLKOUT6), // 1-bit output: CLKOUT6
        // Feedback Clocks: 1-bit (each) output: Clock feedback ports
        .CLKFBOUT(CLKFBOUT), // 1-bit output: Feedback clock
        .CLKFBOUTB(CLKFBOUTB), // 1-bit output: Inverted CLKFBOUT
        // Status Ports: 1-bit (each) output: MMCM status ports
        .LOCKED(LOCKED), // 1-bit output: LOCK
        // Clock Inputs: 1-bit (each) input: Clock input
        .CLKIN1(CLKIN1), // 1-bit input: Clock
        // Control Ports: 1-bit (each) input: MMCM control ports
        .PWRDWN(PWRDWN), // 1-bit input: Power-down
        .RST(rst), // 1-bit input: Reset
        // Feedback Clocks: 1-bit (each) input: Clock feedback ports
        .CLKFBIN(CLKFBIN) // 1-bit input: Feedback clock
        );

    // 2nd mmcm instance
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"), // Bandwidth setting (LOW, OPTIMIZED, HIGH)
        .CLKFBOUT_MULT_F(10.0), // Multiply value for all CLKOUT (2.000-64.000).
        .CLKFBOUT_PHASE(0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
        .CLKIN1_PERIOD(10.000), // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        .CLKOUT1_DIVIDE(10.0),
        .CLKOUT2_DIVIDE(10.0),
        .CLKOUT3_DIVIDE(60.0),
        .CLKOUT4_DIVIDE(4.5),
        .CLKOUT5_DIVIDE(40.0),
        .CLKOUT6_DIVIDE(3.0),
        .CLKOUT0_DIVIDE_F(10.0), // Divide amount for CLKOUT0 (1.000-128.000).
        // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.20),
        .CLKOUT2_DUTY_CYCLE(0.70),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT6_DUTY_CYCLE(0.5),
        // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_PHASE(180.0),
        .CLKOUT2_PHASE(90.0),
        .CLKOUT3_PHASE(18.0),
        .CLKOUT4_PHASE(18.0),
        .CLKOUT5_PHASE(0.0),
        .CLKOUT6_PHASE(0.0),
        .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .DIVCLK_DIVIDE(1) // Master division value (1-106)
        ) MMCME2_BASE_1 (
        // Clock Outputs: 1-bit (each) output: User configurable clock outputs
        .CLKOUT0(CLKOUT0_1_BUFG_IN), // 1-bit output: CLKOUT0
        .CLKOUT0B(CLKOUT0B_1), // 1-bit output: Inverted CLKOUT0
        .CLKOUT1(CLKOUT1_1), // 1-bit output: CLKOUT1
        .CLKOUT1B(CLKOUT1B_1), // 1-bit output: Inverted CLKOUT1
        .CLKOUT2(CLKOUT2_1), // 1-bit output: CLKOUT2
        .CLKOUT2B(CLKOUT2B_1), // 1-bit output: Inverted CLKOUT2
        .CLKOUT3(CLKOUT3_1), // 1-bit output: CLKOUT3
        .CLKOUT3B(CLKOUT3B_1), // 1-bit output: Inverted CLKOUT3
        .CLKOUT4(CLKOUT4_1), // 1-bit output: CLKOUT4
        .CLKOUT5(CLKOUT5_1), // 1-bit output: CLKOUT5
        .CLKOUT6(CLKOUT6_1), // 1-bit output: CLKOUT6
        // Feedback Clocks: 1-bit (each) output: Clock feedback ports
        .CLKFBOUT(CLKFBOUTB_1), // 1-bit output: Feedback clock
        .CLKFBOUTB(CLKFBOUT_1), // 1-bit output: Inverted CLKFBOUT
        // Status Ports: 1-bit (each) output: MMCM status ports
        .LOCKED(LOCKED_1), // 1-bit output: LOCK
        // Clock Inputs: 1-bit (each) input: Clock input
        .CLKIN1(CLKIN1_1), // 1-bit input: Clock
        // Control Ports: 1-bit (each) input: MMCM control ports
        .PWRDWN(PWRDWN_1), // 1-bit input: Power-down
        .RST(!LOCKED), // 1-bit input: Reset
        // Feedback Clocks: 1-bit (each) input: Clock feedback ports
        .CLKFBIN(CLKFBOUTB_1) // 1-bit input: Feedback clock
        );


    // create BUFGs for the descew circuit on 100MHZ clock. this will make
    // clock 0 in phase with the 100MHZ clock

    // IBUF for CLK100MHZ 
    // BUFG IBUF_100MHZ (
    // .O(CLKIN1), // 1-bit output: Clock output
    // .I(CLK100MHZ) // 1-bit input: Clock input
    // );

    assign CLKIN1 = CLK100MHZ;
    
    // BUFG for clock 0 output
    BUFG BUFG_CLKOUT0 (
    .O(CLKOUT0), // 1-bit output: Clock output
    .I(CLKOUT0_BUFG_IN) // 1-bit input: Clock input
    );

    // BUFG for Feedback
    BUFG BUFG_CLKFB (
    .O(CLKFBIN), // 1-bit output: Clock output
    .I(CLKFBOUT) // 1-bit input: Clock input
    );

    // BUFGS for the second MMCM circuit

    // clock buffer for second MMCM(cascaded from first mmcm)
    BUFG BUFG_CLKIN1_1 (
    .O(CLKIN1_1), // 1-bit output: Clock output
    .I(CLKOUT0) // 1-bit input: hook up output clock from first MMCM
    );

    // output clock 0 of mmcm 2 bufg
    BUFG BUFG_CLKOUT0_1 (
    .O(CLKOUT0_1), // 1-bit output: Clock output
    .I(CLKOUT0_1_BUFG_IN) // 1-bit input: Clock input
    );


    // reset circuits for the 5 other clock outputs using a preset 
    // circuit based on LOCKED to ensure the reset is released when
    // the MMCM is locked 

    // reset circuit for CLKOUT1
    always_ff @(posedge CLKOUT1) begin
        if (!LOCKED) begin
            rst1_dd <= 1'b1;
            rst1_d <= 1'b1;
            rst1 <= 1'b1;
        end else begin
            rst1_dd <= RESET_LOW;
            rst1_d <= rst1_dd;
            rst1 <= rst1_d;
        end
    end

    // reset circuit for CLKOUT2
    always_ff @(posedge CLKOUT2) begin
        if (!LOCKED) begin
            rst2_dd <= 1'b1;
            rst2_d <= 1'b1;
            rst2 <= 1'b1;
        end else begin
            rst2_dd <= RESET_LOW;
            rst2_d <= rst2_dd;
            rst2 <= rst2_d;
        end
    end

    // reset circuit for CLKOUT3
    always_ff @(posedge CLKOUT3) begin
        if (!LOCKED) begin
            rst3_dd <= 1'b1;
            rst3_d <= 1'b1;
            rst3 <= 1'b1;
        end else begin
            rst3_dd <= RESET_LOW;
            rst3_d <= rst3_dd;
            rst3 <= rst3_d;
        end
    end

    // reset circuit for CLKOUT4
    always_ff @(posedge CLKOUT4) begin
        if (!LOCKED) begin
            rst4_dd <= 1'b1;
            rst4_d <= 1'b1;
            rst4 <= 1'b1;
        end else begin
            rst4_dd <= RESET_LOW;
            rst4_d <= rst4_dd;
            rst4 <= rst4_d;
        end
    end

    // reset circuit for CLKOUT5
    always_ff @(posedge CLKOUT5) begin
        if (!LOCKED) begin
            rst5_dd <= 1'b1;
            rst5_d <= 1'b1;
            rst5 <= 1'b1;
        end else begin
            rst5_dd <= RESET_LOW;
            rst5_d <= rst5_dd;
            rst5 <= rst5_d;
        end
    end

    // reset circuit for CLKOUT6
    always_ff @(posedge CLKOUT6) begin
        if (!LOCKED) begin
            rst6_dd <= 1'b1;
            rst6_d <= 1'b1;
            rst6 <= 1'b1;
        end else begin
            rst6_dd <= RESET_LOW;
            rst6_d <= rst6_dd;
            rst6 <= rst6_d;
        end
    end

    // reset circuit for CLKOUT0_1
    always_ff @(posedge CLKOUT0_1) begin
        if (!LOCKED) begin
            rst0_1_dd <= 1'b1;
            rst0_1_d <= 1'b1;
            rst0_1 <= 1'b1;
        end else begin
            rst0_1_dd <= RESET_LOW;
            rst0_1_d <= rst0_1_dd;
            rst0_1 <= rst0_1_d;
        end
    end

    // create 32 bit counters for each of the clock domains
    // each counter is reset with corresponding reset signal
    // and is incremented on the rising edge of the clock
    always_ff @(posedge CLKOUT0) begin
        if (rst) begin
            CNT0 <= 32'b0;
        end else begin
            CNT0 <= CNT0 + 1;
        end
    end
    always_ff @(posedge CLKOUT1) begin
        if (rst1) begin
            CNT1 <= 32'b0;
        end else begin
            CNT1 <= CNT1 + 1;
        end
    end
    always_ff @(posedge CLKOUT2) begin
        if (rst2) begin
            CNT2 <= 32'b0;
        end else begin
            CNT2 <= CNT2 + 1;
        end
    end
    always_ff @(posedge CLKOUT3) begin
        if (rst3) begin
            CNT3 <= 32'b0;
        end else begin
            CNT3 <= CNT3 + 1;
        end
    end
    always_ff @(posedge CLKOUT4) begin
        if (rst4) begin
            CNT4 <= 32'b0;
        end else begin
            CNT4 <= CNT4 + 1;
        end
    end
    always_ff @(posedge CLKOUT5) begin
        if (rst5) begin
            CNT5 <= 32'b0;
        end else begin
            CNT5 <= CNT5 + 1;
        end
    end
    always_ff @(posedge CLKOUT6) begin
        if (rst6) begin
            CNT6 <= 32'b0;
        end else begin
            CNT6 <= CNT6 + 1;
        end
    end
    always_ff @(posedge CLKOUT0_1) begin
        if (rst0_1) begin
            CNTB_0 <= 32'b0;
        end else begin
            CNTB_0 <= CNTB_0 + 1;
        end
    end

    // For this part you will create enable signals in various clock domains and "count" these enable pulses in a different clock domain.

    // Create a single pulse in CLKOUT3 that occurs every 4 clock cycles (PULSE3)
    always_ff @(posedge CLKOUT3) begin
        if (rst3) begin
            PULSE3 <= 1'b0;
        end else begin
            if (CNT3 % 4 == 0) begin
                PULSE3 <= 1'b1;
            end else begin
                PULSE3 <= 1'b0;
            end
        end
    end

    // Create a single pulse in CLKOUT4 that occurs every 100 clock cycles (PULSE4)
    always_ff @(posedge CLKOUT4) begin
        if (rst4) begin
            PULSE4 <= 1'b0;
        end else begin
            if (CNT4 % 100 == 0) begin
                PULSE4 <= 1'b1;
            end else begin
                PULSE4 <= 1'b0;
            end
        end
    end


    // Create a counter in the CLKOUT0 domain that counts the PULSE3 pulses.
    always_ff @(posedge CLKOUT0) begin
        if (rst) begin
            PULSE3CNT <= 32'b0;
        end else begin
            // edge detector
            if (PULSE3CNT_ddd == 1'b0 && PULSE3CNT_dd == 1'b1) begin
                PULSE3CNT <= PULSE3CNT + 1;
            end
            // synchronizer
            PULSE3CNT_d <= PULSE3;
            PULSE3CNT_dd <= PULSE3CNT_d;
            PULSE3CNT_ddd <= PULSE3CNT_dd;
        end
    end


    

    // Create a counter in the CLKOUT0 domain that counts the PULSE4 pulses.
    // stretcher
    always_ff @(posedge PULSE4) begin
        if(PULSE4CNT_dd)
            en_q <= 1'b0;
        else
            en_q <= 1'b1;
    end

    // synchronizer and edge detector
    always_ff @(posedge CLKOUT0) begin
        if (rst) begin
            PULSE4CNT <= 32'b0;
        end else begin
            // synchronizer
            PULSE4CNT_d <= en_q;
            PULSE4CNT_dd <= PULSE4CNT_d;
            PULSE4CNT_ddd <= PULSE4CNT_dd;
            // edge detector
            if (PULSE4CNT_ddd == 1'b0 && PULSE4CNT_dd == 1'b1) begin
                PULSE4CNT <= PULSE4CNT + 1;
            end
        end
    end

    // create a toggle circuit for the second mmcm clk0
    always_ff @(posedge CLKOUT0_1) begin
        if (rst0_1) begin
            clk0_1_toggle <= 1'b0;
        end else begin
            clk0_1_toggle <= ~clk0_1_toggle;
        end
    end


    // create a metastability circuit that detects metastability events from
    // the clk0_1_toggle signal in the clk4 domain.
    logic qa, qb, qc, qd;
    always_ff @(posedge CLKOUT4) begin
        qa <= clk0_1_toggle;
        qb <= qa;
    end
    always_ff @(negedge CLKOUT4) begin
        qc <= qa;
        qd <= (qc ^ qb);
    end

    // create a counter CNT_META that counts the number of metastability events
    // in the clk4 domain based on output of qd
    always_ff @(posedge CLKOUT4) begin
        if (rst4) begin
            CNT_META <= 32'b0;
        end else begin
            if (qd) begin
                CNT_META <= CNT_META + 1;
            end
        end
    end

    // instance seven segment display
    seven_segment seven_segment (
        .clk(CLK100MHZ),
        .data(segment_data),
        .anode(AN), 
        .segment(segment)
    );

    // update seven segment data witht the following mux
    always_ff @(posedge CLK100MHZ) begin
        if(~CPU_RESETN)
            segment_data <= 32'b0;
        else begin
            case (sw[3:0])
                4'h0: segment_data <= CNT0;
                4'h1: segment_data <= CNT1;
                4'h2: segment_data <= CNT2;
                4'h3: segment_data <= CNT3;
                4'h4: segment_data <= CNT4;
                4'h5: segment_data <= CNT5;
                4'h6: segment_data <= CNT6;
                4'h7: segment_data <= PULSE3CNT;
                4'h8: segment_data <= PULSE4CNT;
                4'h9: segment_data <= CNTB_0;
                4'hA: segment_data <= CNT_META;
                default: segment_data <= 32'b0;
            endcase
        end
    end

    // assign leds to switch values
    assign LED = sw;

    // assign pwrdown to 0
    assign PWRDWN = 1'b0;
    assign PWRDWN_1 = 1'b0;

endmodule