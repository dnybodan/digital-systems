/***************************************************************************
*
* model: tx_model
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 19, 2023
*
* Description: This model creates values to provide as stimulus for the 
*              testing of the receiver module.
*
****************************************************************************/
`timescale 1ns / 1ps

module tx_model (clk,rst,tx_out,din,start_tx, parity_mode);
    input wire clk;
    input wire rst;
    output reg tx_out;
    input [7:0] din;
    input wire start_tx;
    input wire parity_mode;

    parameter CLK_FREQUENCY = 100_000_000;
    parameter BAUD_RATE = 19_200;
    parameter BAUD_CLOCK_CYCLES = CLK_FREQUENCY / BAUD_RATE;
    parameter NUM_DATA_BITS = 8;
    parameter SEVENTH_BIT = 7, SIXTH_BIT = 6, FIFTH_BIT = 5, FOURTH_BIT = 4, THIRD_BIT = 3, SECOND_BIT = 2, FIRST_BIT = 1, ZERO_BIT = 0;
    parameter PERIODS_BIT_WIDTH = 15;
    
    // set timeformat
    initial
        $timeformat(-9,2,"ns");


    reg [7:0] t_char;
    reg parity_calc;
    reg en_baud_counter, rst_baud_counter;

    reg [1:0] state;
    parameter INIT = 2'b00;
    parameter IDLE = 2'b01;
    parameter BUSY = 2'b10;

    integer i; // Moved outside the always block

    // Delay a baud period
    task delay_baud(input[PERIODS_BIT_WIDTH:0] baud_periods);
        reg[PERIODS_BIT_WIDTH:0] j;
        for (j=0; j<baud_periods; j=j+1)
            repeat(BAUD_CLOCK_CYCLES)
                @(negedge clk);
    endtask

    // UART Transmitter simulation
    always @(posedge clk or posedge rst)
    begin
        // reset clause
        if (rst) begin
            state <= INIT;
            tx_out <= 1; // Idle state
        end
        else if (start_tx) begin
            state <= BUSY;
            t_char <= din;
            // print out the character to be transmitted and the parity mode
            if(parity_mode)
                $display("[%0t] TX Parity mode: Odd", $realtime);
            else
                $display("[%0t] TX Parity mode: Even", $realtime);
            tx_out <= 0; // Start bit
            // wait for the duration of one baud period
            delay_baud(1);

            // Transmit data bits
            for (i=0; i<NUM_DATA_BITS; i=i+1) begin
                tx_out <= t_char[i];
                delay_baud(1);
            end

            // Calculate and transmit parity bit
            parity_calc = t_char[SEVENTH_BIT] ^ t_char[SIXTH_BIT] ^ t_char[FIFTH_BIT] ^ t_char[FOURTH_BIT] ^ t_char[THIRD_BIT] ^ t_char[SECOND_BIT] ^ t_char[FIRST_BIT] ^ t_char[ZERO_BIT];
            // if parity mode is odd, and parity_calc is 1, then parity bit is 0
            if(!parity_mode) // odd parity
                tx_out <= parity_calc; // keep it odd
            else
                tx_out <= ~parity_calc; // make it even

            delay_baud(1);

            tx_out <= 1; // Stop bit
            delay_baud(1);

            $display("[%0t] TX Finished transmission of 0x%h", $realtime, t_char);
            state <= IDLE;
        end
    end

endmodule



