/***************************************************************************
*
* Module: rx
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 19, 2023
*
* Description: this is a parameterized UART receiver which can be used to 
*              receive data from a UART transmitter. It is implimented
*              strictly in Verilog 95. This module has parameters for the
*              Clock frequency, the baud rate, and the parity bit. The 
*              module recieves a single byte of data and a parity bit.
*
****************************************************************************/
`timescale 1ns / 1ps
`define HALF_CONSTANT 2
module rx(clk,rst,din,dout,busy,data_strobe,rx_error);
    // port definitions
    input wire clk,rst,din;
    output reg[7:0] dout;
    output wire busy,data_strobe,rx_error;
    
    // parameter definitions
    parameter CLK_FREQ = 100000000;
    parameter BAUD_RATE = 19200;
    parameter PARITY_MODE = 1;
    parameter BIT_COUNTER_MAX = 7;
    parameter BAUD_TIMER_MAX = (CLK_FREQ/BAUD_RATE);
    parameter IDLE = 3'b000, SRT = 3'b001, BITS = 3'b010, PAR = 3'b011, STP = 3'b100, ACK = 3'b101, INIT = 3'b110, ERR = 3'b111;
    parameter STARTBIT = 10, DATABIT = 9, PARITYBIT = 2, BAUD_BIT_WIDTH = 32, COUNTER_BIT_WIDTH = 4;
    // internal signal definitions

    // full data buffer including start/stop and parity bits 11 bits total
    reg[10:0] dataBuffer;

    // output signal buffers
    reg busy_r,data_strobe_r,rx_error_r;

    // state signals
    reg[PARITYBIT:0] cs,ns;

    // baud timer and control signals
    reg[BAUD_BIT_WIDTH:0] baudTimer;
    wire timerDone;
    reg clrTimer;
    wire halfTimerDone;

    // data bit counter and control signals
    reg[COUNTER_BIT_WIDTH:0] bitCounter;
    wire bitDone;
    reg clrBit;
    reg incBit;

    // datapath control signals
    reg startBit;
    reg parityBit;
    reg ackBit;
    reg stopBit;
    reg dataBit;
    
    // assign wire outputs to reg internal regs
    assign busy = busy_r;
    assign data_strobe = data_strobe_r;
    assign rx_error = rx_error_r;
    
    // Baud timer done logic
    assign timerDone = (baudTimer == BAUD_TIMER_MAX) ? 1 : 0;
    // Half baud period done logic
    assign halfTimerDone = (baudTimer == (BAUD_TIMER_MAX/`HALF_CONSTANT)) ? 1 : 0;
    // baud timer update block
    always @(posedge clk or posedge rst) begin
        // reset clause
        if (rst) 
            baudTimer <= 0;
        else
            if (clrTimer || timerDone)
                baudTimer <= 0;
            else
                baudTimer <= baudTimer + 1;
    end

    // Bit counter 
    assign bitDone = (bitCounter == BIT_COUNTER_MAX) ? 1 : 0;
    // counter update block
    always @(posedge clk or posedge rst) begin
        // reset clause
        if (rst)
            bitCounter <= 0;
        else
            if(clrBit)
                bitCounter <= 0;
            else if(incBit)
                bitCounter <= bitCounter + 1;
    end

    // datapath for data stream
    always @(posedge clk or posedge rst) begin
        // rst clause
        if (rst) begin
            dataBuffer <= 0;
            dout <= 0;
            data_strobe_r <= 0;
        end
        else begin
            // if start bit is received then start loading the data buffer
            if (startBit && halfTimerDone)
                dataBuffer <= din; 
            else if (dataBit && halfTimerDone)
                dataBuffer <= ((dataBuffer) | (din << (bitCounter)));
            else if (parityBit && halfTimerDone)
                dataBuffer <= ((dataBuffer << 1) | din);
            else if (stopBit && halfTimerDone)
                dataBuffer <= ((dataBuffer << 1) | din);
            if (ackBit) begin
                dout <= dataBuffer[DATABIT:PARITYBIT];
                data_strobe_r <= 1;
            end
            else
                data_strobe_r <= 0; 
        end
    end

    // error handling logic
    always @(posedge clk) begin
        if (rst)
            rx_error_r <= 0;
        else begin
            // if start bit is received then reset error
            if (startBit)
                rx_error_r <= 0;
            // if ack bit is received then check for errors
            if (ackBit) begin
                // check valid start bit
                if (dataBuffer[STARTBIT])
                    rx_error_r <= 1;
                // check valid stop bit
                if (~dataBuffer[0])
                    rx_error_r <= 1;
                // check if parity mode is odd
                if (PARITY_MODE) begin
                    // this recues to 1 if even
                    if (~^dataBuffer[DATABIT:1])
                        rx_error_r <= 1;
                end
                // check if parity mode is even
                else if (!PARITY_MODE) begin
                    // this reduces to 1 if odd parity
                    if (^dataBuffer[DATABIT:1])
                        rx_error_r <= 1;
                end
            end
        end
    end

    // busy signal logic
    always @(posedge clk) begin
        // reset clause
        if (rst)
            busy_r <= 0;
        else begin
            if (startBit)
                busy_r <= 1;
            else if (ackBit)
                busy_r <= 0;
        end
    end
    
    // FSM logic including mealy and moore outputs
    always @(cs or din or timerDone or halfTimerDone or bitDone or rst or startBit or dataBit) begin
        // defaults
        ns = ERR;
        startBit = 0;
        dataBit = 0;
        incBit = 0;
        parityBit = 0;
        stopBit = 0;
        ackBit = 0;
        clrBit = 0;
        clrTimer = 0;

        // reset clause
        if (rst) begin
            ns = INIT;
            clrBit = 1;
            clrTimer = 1;
            startBit = 0;
            dataBit = 0;
            incBit = 0;
            parityBit = 0;
            stopBit = 0;
            ackBit = 0;
        end
        else begin
            // state cases
            case(cs)
                // INIT state, where the state machine waits
                // for the input to go high to avoid glitch
                INIT: begin
                    if (din) begin
                        ns = IDLE; 
                    end
                    else
                        ns = cs;
                end
                // IDLE state, where the state machine rests
                IDLE: begin
                    if (din) begin
                        ns = IDLE;
                    end
                    else begin
                        ns = SRT;
                        clrTimer = 1;
                    end
                end
                // SRT state, start bit recieved start timer/offset
                SRT: begin
                    startBit = 1;
                    // check if the baud period is over for the
                    // start bit
                    if (timerDone) begin
                        ns = BITS;
                        clrBit = 1;
                    end
                    // otherwise stay here
                    else
                        ns = cs;
                end
                // BITS state, receive data bits into dout
                BITS: begin
                    dataBit = 1;
                    // If bits are all loaded and timer is done
                    // then finished in this state
                    if (timerDone && bitDone)
                        ns = PAR;
                    // check if bit should be incremented
                    else if (timerDone && ~bitDone) begin
                        incBit = 1;
                        ns = cs;
                    end
                    // otherwise just wait in this state
                    else
                        ns = cs;
                end 
                // PAR state, waits for parity bit to come through
                PAR: begin
                    parityBit = 1;
                    // if timer is done then move to stop
                    if(timerDone)
                        ns = STP;
                    // otherwise just stay here
                    else
                        ns = cs;
                end
                // Stop state, verify stop signal received, output
                // error if necessary
                STP: begin
                    stopBit = 1;
                    // if the timer is done go to ack state
                    if(timerDone) 
                        ns = ACK;
                    // otherwise stay here
                    else
                        ns = cs;
                end
                // ACK state, output data ready signal
                ACK: begin
                    ackBit = 1;
                    ns = IDLE;
                end
                // ERR state, stay here until reset
                ERR: begin
                    ns = cs;
                end
            endcase
        end
    end

    // state register
    always @(posedge clk) begin
        // update currents state with next state
        cs <= ns;
    end

endmodule 
