/***************************************************************************
*
* Module: MMCM
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: November 4, 2023
*
* Description: testbench modul for MMCM circuit with counters, clock domain 
*              crossing, and metastability detection 
*
****************************************************************************/
`timescale 1ns / 1ps
module mmcm_tb();

    // INPUT signals
    logic CLK100MHZ;
    logic RESET; // active low
    logic [16:0] SWITCHES;
    // ouputs
    logic [6:0] LED;
    logic [6:0] AN;
    logic [6:0] segment;

    // create free running clock 5ns up 5ns down
    // Free running clock
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ;
    end
    // DUT mmcm module
    mmcm my_mmcm(.CLK100MHZ(CLK100MHZ),
            .CPU_RESETN(RESET),
            .SW(SWITCHES),
            .LED(LED),
            .AN(AN),
            .segment(segment)
            );


    // start test block by reseting system 
    initial begin
        // let run for 10 ns
        #10 
        // set initial values for inputs
        RESET = 1;
        #50ns
        // reset
        $display("Resetting system");
        RESET = 0;
        SWITCHES = 0;
        // let run for 100 ns
        #100ns
        // set reset to 1
        RESET = 1;
        // let run for 100 ns
        #100
        $display("toggle switches to verify display updates properly");
        // set swtiches different values and verify data switches to proper counters
        SWITCHES = 16'h0001;
        #100
        SWITCHES = 16'h0002;
        #100
        SWITCHES = 16'h0003;
        #100
        SWITCHES = 16'h0004;
        #100
        SWITCHES = 16'h0005;
        #100
        SWITCHES = 16'h0006;
        #100
        SWITCHES = 16'h0007;
        #100
        SWITCHES = 16'h0008;
        #100
        SWITCHES = 16'h0009;
        #100
        SWITCHES = 16'h000A;

        $display("Verify waveform is as expected for 100us");
        // now just let the system run for a while to verify waveform is as expected
        #100000
        // finish simulation
        $display("Simulation complete");
        $finish;
    end

endmodule