/***************************************************************************
*
* Module: tx
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 13, 2023
*
* Description: this is a parameterized asynchronous transmitter which takes 
* an 8 bit data value and outputs the serial out signal. The serial out 
* signal is a 1 start bit, 8 data bits, 1 parity bit, and 1 stop bit.
* The parameters for this module are the clock frequency, the baud rate,
* and the parity type. The parity type is either odd or even parity.
*
*
****************************************************************************/
`default_nettype none
`timescale 1ns / 1ps
`define DEFAULT_CLK_FREQUENCY 100_000_000
`define DEFAULT_BAUD_RATE 19_200
`define DEFAULT_PARITY 1
module tx #(parameter CLK_FREQUENCY=DEFAULT_CLK_FREQUENCY, parameter BAUD_RATE=DEFAULT_BAUD_RATE, parameter PARITY=DEFAULT_PARITY) (
    input wire logic clk, rst, send,
    input wire logic[7:0] din,
    output logic busy, tx_out);
    
    // state type for transmitter FSM
    typedef enum logic[2:0] {idle, start, bits, par, stop, ack, ERR='X} stateType;
    stateType ns, cs;
    
    // logic signals for data path section of transmitter
    logic startBit, dataBit, parityBit, busyBit;

    // bit counter signals
    logic[2:0] bitNum;
    logic incBit, clrBit, bitDone;
   
    // logic signal for baud rate timer
    logic timerDone, clrTimer;
    logic[12:0] baudTimer;
 
    // constants
    localparam BAUD_TIMER_MAX = (CLK_FREQUENCY/BAUD_RATE);

    localparam BIT_CTR_MAX = 3'd7;

    // Busy report
    assign busy = busyBit;
    
    //transmiter datapath code
    always_ff @(posedge clk)
        if(startBit)
            tx_out <= 0;
        else if(dataBit)
            tx_out <= din[bitNum];
        else if(parityBit)
            if(!PARITY)
                tx_out <= ^din; //parity calculation for even parity
            else
                tx_out <= ~^din; //parity calculation for odd parity
        else 
            tx_out <= 1; //idle
     
    // Baud Rate Timer
    assign timerDone = (baudTimer == BAUD_TIMER_MAX)?1:0;
    // Timer update logic
    always_ff @(posedge clk)
        // reset clause
        if (rst)
            baudTimer <= 0;
        else
            if (clrTimer || timerDone)
                baudTimer <= 0;
            else
                baudTimer <= baudTimer + 1; 
              
    // Bit Counter
    assign bitDone = (bitNum == BIT_CTR_MAX)?1:0;
    // Counter update logic
    always_ff @(posedge clk)
        // reset clause
        if (rst)
            bitNum <= 0;
        else
            if (clrBit)
                bitNum <= 0;
            else if (incBit)
                bitNum <= bitNum + 1;

    // transmitter FSM 
    always_comb
        begin 
        ns = ERR;
        clrTimer = 0;
        startBit = 0;
        incBit =0;
        clrBit = 0;
        dataBit = 0;
        parityBit = 0;
        busyBit = 0;
        
        // reset clause
        if (rst)
        begin
            ns = idle;
            clrTimer = 0;
            startBit = 0;
            incBit =0;
            clrBit = 0;
            dataBit = 0;
            parityBit = 0;
            busyBit = 0;
        end
        else
            case (cs)
                // idle state is the default state
                // the transmitter will stay in this state
                // until the send signal is asserted
                idle:
                begin
                    busyBit = 0;
                    clrTimer = 1;
                    if (send)
                        ns = start;
                    else 
                        ns = cs;
                end
                // start state is the first state of the transmitter
                // it asserts the start bit and sets the bit counter to 0
                // it also starts the baud rate timer
                start:
                begin
                    busyBit = 1;
                    startBit = 1;
                    if (timerDone)
                    begin
                        clrBit = 1;
                        ns = bits;
                    end
                    else
                        ns = cs;
                end
                // bits state is the state where the data bits are sent
                // it asserts the data bit and increments the bit counter
                // it starts the bit counter and check baud and bit counters
                bits:
                begin
                    dataBit = 1;
                    if (timerDone && ~bitDone)
                    begin
                        incBit = 1;
                        ns = cs;
                    end
                    else if (~timerDone)
                        ns = cs;
                    else 
                        ns = par;
                end
                // the parity state is where the parity bit is sent     
                par:
                begin
                    parityBit = 1;
                    if (~timerDone)
                        ns = cs;
                    else 
                        ns = stop;
                end
                // the stop state is where the stop bit is sent
                stop:
                begin
                    if (~timerDone)
                        ns = cs;
                    else
                        ns = ack;
                end
                // the ack state is where the busy signal is deasserted
                // and the next state is set to idle
                ack:
                begin
                    busyBit = 0;
                    if(send)
                        ns = cs;
                    else
                        ns = idle;
                end  
            endcase
    end      
     
    //state register for transmitter FSM
    always_ff @(posedge clk)
        cs <= ns;       
    
    
endmodule
