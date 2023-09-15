/***************************************************************************
*
* Module: tx
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 13, 2023
*
* Description: this is an asynchronous transmitter which takes an 8 bit 
* data value and outputs the serial out signal. The serial out signal is
* a 1 start bit, 8 data bits, 1 parity bit, and 1 stop bit. The parity bit
* is odd parity.
*
*
****************************************************************************/
`default_nettype none
`timescale 1ns / 1ps

module tx(
    input wire logic clk, rst, send,
    input wire logic[7:0] din,
    output logic busy, tx_out);
    
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
    localparam BAUD_TIMER_MAX = 13'd5209;
    localparam BIT_CTR_MAX = 3'd7;
    
    //transmiter datapath code
    always_ff @(posedge clk)
        if(startBit)
            tx_out <= 0;
        else if(dataBit)
            tx_out <= din[bitNum];
        else if(parityBit)
            tx_out <= ~^din; //parity calculation for odd parity
        else 
            tx_out <= 1; //idle
     
    // Baud Rate Timer
    assign timerDone = (baudTimer == BAUD_TIMER_MAX)?1:0;
    // Timer update logic
    always_ff @(posedge clk)
        if (clrTimer || rst)
            baudTimer <= 0;
        else if(timerDone)
            baudTimer <= 0;
        else
            baudTimer <= baudTimer + 1; 
              
    // Bit Counter
    assign bitDone = (bitNum == BIT_CTR_MAX)?1:0;
    // Counter update logic
    always_ff @(posedge clk)
        if (clrBit || rst)
            bitNum <= 0;
        else if (incBit)
            bitNum <= bitNum + 1;

    //Busy report
    assign busy = busyBit;
    
    //transmitter FSM      
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
            idle:
            begin
                busyBit = 0;
                clrTimer = 1;
                if (send)
                    ns = start;
                else 
                    ns = cs;
            end
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
            par:
            begin
                parityBit = 1;
                if (~timerDone)
                    ns = cs;
                else 
                    ns = stop;
            end
            stop:
            begin
                if (~timerDone)
                    ns = cs;
                else
                    ns = ack;
            end
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
     
     
    //state register 
    always_ff @(posedge clk)
        cs <= ns;       
    
    
endmodule
