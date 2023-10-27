/***************************************************************************
*
* Module: tb_i2c_controller
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 25, 2023
*
* Description: This is a testbench for conntecting i2c controller with adt7420
*              model.
*
****************************************************************************/
`timescale 1ns/1ps
module tb_i2c_controller;

    // Parameters
    parameter CLK_FREQ = 100_000_000;

    localparam HARD_CODED_ADT_ADDRESS = 7'b1001011; // hard coded address for the ADT7410 temperature sensor

    // Clock Generation
    logic clk;
    always
    begin
        clk <=1; #5ns;
        clk <=0; #5ns;
    end

    // Signals
    logic rst;
    tri TMP_SDA, TMP_SCL;
    logic start;
    logic [7:0] address, data_to_send;
    logic [7:0] data_received;
    logic sense_busy,controller_busy, rd_wr, done, error;
    logic [6:0] bus_address;

    // Logic to emulate the tri-state behavior
    pullup mypullupSCL(TMP_SCL);
    pullup mypullupSDA(TMP_SDA);

    // I2C Controller Instance
    i2c_wrapper #(CLK_FREQ) u_i2c_wrapper (
        .clk(clk),
        .rst(rst),
        .SDA(TMP_SDA),
        .SCL(TMP_SCL),
        .start(start),
        .rd_wr(rd_wr),
        .address(address),
        .bus_address(bus_address),
        .data_to_send(data_to_send),
        .data_received(data_received),
        .busy(controller_busy),
        .done(done),
        .error(error)
    );

    // I2C Model Instance
    adt7420 u_adt7420 (
        .scl(TMP_SCL),
        .sda(TMP_SDA),
        .rst(rst),
        .busy(sense_busy)
    );

    // Stimulus
    initial begin
        rst = 1;
        #20ns
        rst = 0;

        #1500ns; // give time for i2c controller to initialize(1400ns for bus free)

        // Valid I2C transaction sequences
        bus_address = HARD_CODED_ADT_ADDRESS; // hard coded address for the ADT7410 temperature sensor
        
        // write sequence, write a 1 to 0A
        rd_wr = 0;
        address = 8'h0A;
        data_to_send = 8'h1;
        #10ns;  
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // print what was sent
        $display("Data sent to adt7420: %h", data_to_send);

        // write sequence, write a 0 to 0x04
        rd_wr = 0;
        address = 8'h04;
        data_to_send = 8'h05;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // print what was sent
        $display("Data sent to adt7420: %h", data_to_send);

        // write sequence, write a 0 to 0x05
        rd_wr = 0;
        address = 8'h05;
        data_to_send = 8'h02;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // print what was sent
        $display("Data sent to adt7420: %h", data_to_send);

        // write sequence, write a 0 to 0x06
        rd_wr = 0;
        address = 8'h06;
        data_to_send = 8'h04;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // print what was sent
        $display("Data sent to adt7420: %h", data_to_send);

        // write sequence, write a 0 to 0x07
        rd_wr = 0;
        address = 8'h07;
        data_to_send = 8'h06;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // print what was sent
        $display("Data sent to adt7420: %h", data_to_send);



        // read sequence, read from 0B
        rd_wr = 1;
        address = 8'h0B;
        data_to_send = 8'b00000000;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // check data received
        $display("Data received from adt7420: %h", data_received);

        // read sequence, read from 0A
        rd_wr = 1;
        address = 8'h0A;
        data_to_send = 8'b00000000;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // check data received
        $display("Data received from adt7420: %h", data_received);

        // read sequence, read from 04
        rd_wr = 1;
        address = 8'h04;
        data_to_send = 8'b00000000;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // check data received
        $display("Data received from adt7420: %h", data_received);
        
        // read sequence, read from 05
        rd_wr = 1;
        address = 8'h05;
        data_to_send = 8'b00000000;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        // check data received
        $display("Data received from adt7420: %h", data_received);


        // write to wrong bus address
        bus_address = 8'h00;
        rd_wr = 0;
        address = 8'h0A;
        data_to_send = 8'h1;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        $display("Should have stopped mid write due to no ack from sensor");

        // read from wrong bus address
        bus_address = 8'h00;
        rd_wr = 1;
        address = 8'h0A;
        data_to_send = 8'b00000000;
        #10ns;
        start = 1;
        #100ns;
        start = 0;
        // Wait for transaction to complete
        @(negedge controller_busy);
        $display("Should have stopped mid read due to no ack from sensor");
        
        // testbench complete
        $display("\nTestbench complete");

        // Finish the simulation
        $finish;
    end

endmodule
