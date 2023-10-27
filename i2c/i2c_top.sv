/***************************************************************************
*
* Module: i2c_top
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 16, 2023
*
* Description: This module is an i2c controller top module which is used
*              to communicate with the temperature sensor on the Nexys 4 DDR
*              board.
*
****************************************************************************/

`timescale 1ns/1ps
`default_nettype none
module i2c_top #(parameter CLK_FREQ=100_000_000)(
    input wire logic CLK100MHZ,
    input wire logic CPU_RESETN,
    inout wire logic TMP_SDA,
    inout wire logic TMP_SCL,
    input wire logic BTNL,
    input wire logic BTNR,
    input wire logic [15:0] SW,
    output logic [15:0] LED,
    output logic [6:0] segment,
    output logic [7:0] AN,
    output logic LED16_B,
    output logic LED16_R,
    output logic LED16_G
);
`default_nettype wire

    localparam HARD_CODED_ADT_ADDRESS = 7'b1001011; // hard coded address for the ADT7410 temperature sensor

    logic rst, start, rd_wr;
    logic [6:0] bus_address;
    logic [7:0] data_received_reg;
    logic btnr_one_shot;
    logic debounced_BTNR;
    logic btnl_one_shot;
    logic debounced_BTNL;
    logic [31:0] recBuffer;

    // invert the reset signal
    assign rst = ~CPU_RESETN;

    // assign rd_wr to read(1) if button right is pressed, else it is write(0)
    assign rd_wr = btnr_one_shot;

    // assign start to 1 if button left or right is pressed
    assign start = btnl_one_shot | btnr_one_shot;

    // assign the LEDs tot the switches
    assign LED = SW;

    // instantiate the i2c_wrapper module
    i2c_wrapper #(CLK_FREQ) my_i2c_wrapper(
        .clk(CLK100MHZ),
        .rst(rst),
        .SDA(TMP_SDA),
        .SCL(TMP_SCL),
        .start(start),
        .rd_wr(rd_wr),
        .address(SW[7:0]),
        .bus_address(HARD_CODED_ADT_ADDRESS),
        .data_to_send(SW[15:8]),
        .data_received(data_received_reg),
        .busy(LED16_B),
        .done(LED16_G),
        .error(LED16_R)
    );

    // 7-segment display controller instantiation
    seven_segment display_controller (
        .clk(CLK100MHZ),
        .data(recBuffer),
        .anode(AN),
        .segment(segment)
    );

    // Debouncer for the left button (debounced_BTNL)
    debounce left_button_debouncer (
        .debounced(debounced_BTNL),
        .clk(CLK100MHZ),
        .reset(rst),
        .noisyInput(BTNL)
    );

    // oneshot circuit for the left button
    oneshot btnl_oneshot (
        .clk(CLK100MHZ),
        .rst(rst),
        .trigger(debounced_BTNL),
        .one_out(btnl_one_shot)
    );

    // Debouncer for the right button (debounced_BTNR)
    debounce right_button_debouncer (
        .debounced(debounced_BTNR),
        .clk(CLK100MHZ),
        .reset(rst),
        .noisyInput(BTNR)
    );
    
    // oneshot circuit for the right button
    oneshot btnr_oneshot (
        .clk(CLK100MHZ),
        .rst(rst),
        .trigger(debounced_BTNR),
        .one_out(btnr_one_shot)
    );

    // create small state machine to read inputs
    logic reading;
    // Seven segment display data updates when a read command is issued and 
    // the busy signal goes low
    always_ff @(posedge CLK100MHZ) begin
        // read command issued(write a byte to seven segment) 
        // when rd_wr is 1 and start is 1
        if (rd_wr == 1 && start) 
            reading <= 1;
        // wait for a new byte to come through(ie wait for the 
        // busy signal to go low)) and turn reading off
        if (reading && my_i2c_wrapper.busy == 0) begin
            recBuffer <= {recBuffer[23:0], data_received_reg}; 
            reading <= 0;
        end  

    end

endmodule