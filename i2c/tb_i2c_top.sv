/***************************************************************************
*
* Module: tb_i2c_top
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 25, 2023
*
* Description: This is a testbench for the top module of the I2C controller
*              It is used to test the I2C controller and the ADT7420
*              temperature sensor.
*
****************************************************************************/
`timescale 1ns/1ps
module tb_i2c_top();

    // Parameters
    parameter CLK_FREQ = 100_000_000;
    
    // Free Clock Generation
    logic CLK100MHZ;
    always
    begin
        CLK100MHZ <=1; #5ns;
        CLK100MHZ <=0; #5ns;
    end

    // Signals
    logic CPU_RESETN;
    tri TMP_SDA, TMP_SCL;
    logic BTNL, BTNR;
    logic [15:0] SW,LED;
    logic sense_busy;
    logic busy, done, error;
    logic [6:0] segment;
    logic [7:0] digit;

    // Logic to emulate the tri-state behavior
    pullup mypullupSCL(TMP_SCL);
    pullup mypullupSDA(TMP_SDA);

    // I2C Controller Instance
    i2c_top my_i2c_top(
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .TMP_SDA(TMP_SDA),
        .TMP_SCL(TMP_SCL),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .SW(SW),
        .segment(segment),
        .AN(digit),
        .LED(LED),
        .LED16_B(busy),
        .LED16_G(done),
        .LED16_R(error)
    );

    // I2C Model Instance
    adt7420 u_adt7420 (
        .scl(TMP_SCL),
        .sda(TMP_SDA),
        .rst(~CPU_RESETN),
        .busy(sense_busy)
    );

    // Stimulus
    initial begin
        #50ns; // wait a few clock cycles before doing anything

        // Initialize signals
        CPU_RESETN = 1;
        SW = 0;
        BTNL = 0;
        BTNR = 0;

        #20ns;

        // reset the controller
        CPU_RESETN = 0;
        // wait a few clock cycles

        #100ns
        CPU_RESETN = 1;
        // give time for i2c controller to initialize(1400ns for bus free)
        #1500ns; 

        // read from ID address 0B
        // set lower 8 switches to 0B
        $display("\nReading from address 0x0B");
        SW = 16'h000B;
        // press the right button for a read
        BTNR = 1;
        // wait for debounce to finish
        #5ms; // assuming 5ms is enough time for debouncer
        // release the button for 5ms which will give transaction
        // enough time to complete
        BTNR = 0;
        #5ms; 

        // read from STATUS address 02
        // set lower 8 switches to 02
        $display("\nReading from address 0x02");
        SW = 16'h0002;
        // press the right button for a read
        BTNR = 1;
        // wait for debounce to finish
        #5ms; // assuming 5ms is enough time for debouncer
        // release the button for 5ms which will give transaction
        // enough time to complete
        BTNR = 0;
        #5ms; 

        // read from TEMP register address 00
        // set lower 8 switches to 00
        $display("\nReading from address 0x00");
        SW = 16'h0000;
        // press the right button for a read
        BTNR = 1;
        // wait for debounce to finish
        #5ms; // assuming 5ms is enough time for debouncer
        // release the button for 5ms which will give transaction
        // enough time to complete
        BTNR = 0;
        #5ms; 

        // read from STATUS address 01
        // set lower 8 switches to 01
        $display("\nReading from address 0x01");
        SW = 16'h0001;
        // press the right button for a read
        BTNR = 1;
        // wait for debounce to finish
        #5ms; // assuming 5ms is enough time for debouncer
        // release the button for 5ms which will give transaction
        // enough time to complete
        BTNR = 0;
        #5ms; 
        
        // testbench complete
        $display("\nTestbench complete");

        // Finish the simulation
        $finish;
    end

endmodule
