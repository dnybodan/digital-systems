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
`define DEF_CLK_FREQUENCY = 100000000;
`define DEF_BAUD_RATE = 19200;
`define HALF_CONSTANT = 2;
`define DEF_PARITY_BIT = 1;
`define BIT_COUNTER_MAX = 7;
`define IDLE = 3'b000;
`define SRT = 3'b001;
`define BITS = 3'b010;
`define PAR = 3'b011;
`define STP = 3'b100;
`define ACK = 3'b101;
`define ERR = 'X;
module rx(clk,rst,din,dout,busy,data_strobe,rx_error);
    // port definitions
    input clk,rst,din;
    output[7:0] dout;
    output busy,data_strobe,rx_error;
    
    // parameter definitions
    parameter CLK_FREQUENCY = DEF_CLK_FREQUENCY;
    parameter BAUD_RATE = DEF_BAUD_RATE;
    parameter PARITY_BIT = DEF_PARITY_BIT;

    // constants
    reg[32:0] BAUD_TIMER_MAX;
    // sets BAUD_TIMER_MAX based on input clock and baud rate
    initial begin
        BAUD_TIMER_MAX <= (CLK_FREQUENCY/BAUD_RATE);
    end

    // internal signal definitions

    // full signal including start/stop and parity bits 11 bits total
    reg[10:0] fullStream;

    reg busy_r,data_strobe_r,rx_error_r;

    // state signals
    reg[2:0] cs,ns;

    // baud timer and control signals
    reg[32:0] baudTimer;
    wire timerDone;
    wire clrTimer;
    wire halfTimerDone;

    // data bit counter and control signals
    reg[4:0] bitCounter;
    wire bitDone;
    wire clrBit;
    wire incBit;

    // datapath control signals
    wire startBit;
    wire parityBit;
    wire busyBit;
    wire ackBit;
    
    // Baud timer done logic
    assign timerDone = (baudTimer == BAUD_TIMER_MAX) ? 1 : 0;
    // Half baud period done logic
    assign halfTimerDone = (baudTimer == (BAUD_TIMER_MAX/HALF_CONSTANT)) ? 1 : 0;
    // baud timer update block
    always @(clk) begin
        // reset clause
        if (rst) 
            baudTimer <= 0;
        else
            if (clrTimer || timerDone)
                baudTimer <= 0;
            else
                baudTimer <= baudTimer + 1'b1;
    end

    // Bit counter 
    assign bitDone = (bitCounter == BIT_COUNTER_MAX) ? 1 : 0;
    // counter update block
    always @(clk) begin
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
    always @(clk) begin
        if (startBit)
            fullStream <= din;
        else if (dataBit)
            fullStream <= ((fullStream << 1) & din);
        else if (parityBit)
            fullStream <= ((fullStream << 1) & din);
        else if (stopBit)
            fullStream <= ((fullStream << 1) & din);
        else if (ackBit) begin
            dout <= fullStream[10:3];
            data_strobe <= 1;
        end
        else
            data_strobe <= 0;
    end

    // error handling logic
    always @(clk) begin
        if (startBit)
            rx_error <= 0;
        if (ackBit) begin
            // check valid start bit
            if (fullStream[10])
                rx_error <= 1;
            // check valid stop bit
            else if (~fullStream[0])
                rx_error <= 1;
            // odd parity if this reduces to 1
            else if (^fullStream[9:1])
                if (~PARITY_BIT)
                    rx_error <= 1;
            // if the above is not true then it was even
            else
                if (PARITY_BIT)
                    rx_error <= 1;
        end
    end

    // busy output
    always @(busyBit)
        busy = busyBit;

    // FSM logic including mealy and moore outputs
    always begin
        // defaults
        ns = ERR;
        startBit = 0;
        dataBit = 0;
        incBit = 0;
        parityBit = 0;
        stopBit = 0;
        data_strobe = 0;
        ackBit = 0;

        // reset clause
        if (rst) begin
            ns = IDLE;
            clrBit = 1;
            clrTimer = 1;
            startBit = 0;
            dataBit = 0;
            incBit = 0;
            parityBit = 0;
            stopBit = 0;
            data_strobe = 0;
            busyBit = 0;
            ackBit = 0;
        end
        else begin
            // state cases
            case(cs)
                // IDLE state, where the state machine rests
                IDLE:
                    if (din)
                        ns = IDLE;
                    else begin
                        ns = SRT;
                        busyBit = 1;
                        clrTimer = 1;
                    end
                // SRT state, start bit recieved start timer/offset
                SRT:
                    // check if the baud period is over for the
                    // start bit
                    if (timerDone) begin
                        ns = BITS;
                        clrBit = 1;
                    end
                    // sample in middle of baud period
                    else if(halfTimerDone) begin
                        ns = cs;
                        startBit = 1;
                    end
                    // otherwise stay here
                    else
                        ns = cs;
                // BITS state, receive data bits into dout
                BITS:
                    // If bits are all loaded and timer is done
                    // then finished in this state
                    if (timerDone && bitDone)
                        ns = PAR;
                    // check if bit should be incremented
                    else if (timerDone && ~bitDone) begin
                        incBit = 1;
                        ns = cs;
                    end
                    // sample in middle of baud period if bits
                    // havent all been loaded
                    else if (halfTimerDone && ~bitDone) begin
                        dataBit = 1;
                        ns = cs;
                    end
                    // otherwise just wait in this state
                    else
                        ns => cs;
                    
                // PAR state, waits for parity bit to come through
                PAR:
                    // if timer is done then move to stop
                    if(timerDone)
                        ns = STP;
                    // check in middle of baud period
                    // for parity bit value
                    else if (halfTimerDone) begin
                        parityBit = 1;
                        ns = cs;
                    end
                    // otherwise just stay here
                    else
                        ns = cs;
                // Stop state, verify stop signal received, output
                // error if necessary
                STP:
                    // if the timer is done go to ack state
                    if(timerDone)
                        ns = ACK;
                    // sample in middle of baud period
                    else if(halfTimerDone) begin
                        stopBit = 1;
                        ns = cs;
                    end
                    // otherwise stay here
                    else
                        ns = cs;
                // ACK state, stay here if input is not set back
                // to high
                ACK:
                    ackBit = 1;
                    // if the input is low, wait until its high
                    // to go back to IDLE state
                    if (~din) 
                        ns = cs;
                    // otherwise go to IDLE and set busy low
                    else begin
                        busyBit = 0;
                        ns = IDLE;
                    end
            endcase
        end
    end

    // state register
    always @(clk) begin
        // update currents state with next state
        cs <= ns;
    end

endmodule 