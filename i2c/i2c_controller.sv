/***************************************************************************
*
* Module: i2c_controller
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 16, 2023
*
* Description: This module implements the i2c controller which will be used
*              to communicate with the temperature sensor on the Nexys 4 DDR
*              board.
*
****************************************************************************/
`timescale 1ns / 1ps
`default_nettype none
module i2c_controller #(parameter CLK_FREQ=100_000_000) (
    input wire logic clk,
    input wire logic rst,
    inout wire logic SDA,
    inout wire logic SCL,
    input wire logic start,
    input wire logic repeat_start,
    input wire logic [7:0] address,
    input wire logic [6:0] bus_address,
    input wire logic rd_wr,
    input wire logic [7:0] data_to_send,
    input wire logic continu,
    output logic [7:0] data_received,
    output logic busy,
    output logic done,
    output logic error
);
`default_nettype wire

localparam MHZ_TO_NS = 1_000_000_000.0; // 1 ns / 1 MHz
localparam real CYCLE_CONST = CLK_FREQ / MHZ_TO_NS; // clock cycles to complete each timing in 1ns increments(100MHz clock)

// clock cycles to complete each timing in 10ns increments(100MHz clock)
localparam TRISE = 300 * CYCLE_CONST;  // 300 ns
localparam TFALL = 300 * CYCLE_CONST; // 300 ns
localparam BUS_FREE_TIME = 1400 * CYCLE_CONST; // 1400 ns
localparam START_HOLD_TIME = 900 * CYCLE_CONST; // 600 ns + tfall(300ns) = 900 ns
localparam DATA_SETUP_TIME = 20 * CYCLE_CONST; // 20 ns
localparam DATA_HOLD_TIME = 0; // 0 ns
localparam SCL_LOW_TIME = 1300 * CYCLE_CONST; // 1300 ns
localparam SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME = SCL_LOW_TIME + TFALL - DATA_SETUP_TIME; // 1.3 us + tfall(300ns) - tdatsetup(20ns) = 1.68 us
localparam DATA_SETUP_AND_TRISE = DATA_SETUP_TIME + TRISE; // 20 ns + 300 ns = 320 ns
localparam SCL_HIGH_TIME = 700 * CYCLE_CONST; // 700 ns 600 ns is minimum but add 100 ns for safety
localparam STOP_SETUP_TIME = 600 * CYCLE_CONST; // 600 ns
localparam BITS_PER_BYTE = 8; // 8 bits per byte

// States
typedef enum logic[7:0] {INIT, // initialize state
    BUS_FREE,                  // stay here untill bus free time is over then go to IDLE
    IDLE,                      // wait here for a start condition(SCL is high and SDA goes low)
    START_HOLD,                // add some time after the start is initiated before letting SCL go low
    ADDRESS_SCL_LOW_HOLD,      // SCL low hold + time for tfall sda time for address bit
    ADDRESS_SETUP,             // change the address bit to next bit for setup plus trise time
    ADDRESS_SCL_HIGH,          // SCL high for address bits, go to ack bit after 8 bits
    ADDRESS_ACK_SCL_LOW,       // SCL low hold + time for tfall sda time for ACK bit
    ADDRESS_ACK_SCL_HIGH,      // SCL high, check for ACK at the end of 8 bit transfer
    REG_ADDRESS_SCL_LOW_HOLD,  // SCL low hold + time for tfall sda time for address bit
    REG_ADDRESS_SETUP,         // change the address bit to next bit for setup plus trise time
    REG_ADDRESS_SCL_HIGH,      // SCL high for address bits, go to ack bit after 8 bits
    REG_ADDRESS_ACK_SCL_LOW,   // SCL low hold + time for tfall sda time for ACK bit
    REG_ADDRESS_ACK_SCL_HIGH,  // SCL high, check for ACK at the end of 8 bit transfer
    RECIEVE_ACK_SCL_LOW,       // SCL low hold + time for tfall sda time for ACK bit
    RECIEVE_ACK_SCL_HIGH,      // SCL high, check for ACK at the end of 8 bit transfer
    DRIVE_ACK_SCL_LOW_HOLD,    // SCL low hold + time for tfall sda time for ACK bit
    DRIVE_ACK_SCL_SETUP,       // SCL low hold + time for tfall sda time for ACK bit
    DRIVE_ACK_SCL_HIGH,        // SCL high, check for ACK at the end of 8 bit transfer
    DATA_RD_SCL_LOW_HOLD,      // SCL low state but first half of this state is data hold time also add tfall time
    DATA_RD_SETUP,             // data setup time state with trise, SCL low until setup time is over
    DATA_RD_SCL_HIGH,          // SCL high, check for ACK after 8 bit transfer, also check for stop condition(if stop condition go to bus free)
    DATA_WR_SCL_LOW_HOLD,      // SCL low state but first half of this state is data hold time also add tfall time
    DATA_WR_SETUP,             // data setup time state with trise, SCL low until setup time is over
    DATA_WR_SCL_HIGH,          // SCL high, check for ACK after 8 bit transfer, also check for stop condition(if stop condition go to bus free)
    STOP_SCL_LOW,              // SCL low for stop condition
    STOP_SCL_HIGH_SETUP,       // SCL stop setup time + trise before sending stop bit
    STOP_CONDITION,            // SCL high for stop condition and SDA goes high, then send to bus free
    ERR='X} state_t;           // error state
state_t cs,ns; 

// Internal signals
logic [7:0] data_to_send_reg;
logic [7:0] data_received_reg;
logic [7:0] address_reg;
logic sda_out, scl_out, done_bit, error_bit, continue_bit; // internal output flags
logic [7:0] timer; // timer will run to max value and then wrap around if its not cleared
logic clr_timer; // clear timer flag
logic [3:0] bit_counter; // counter for indexing data to send and data to recieve
logic inc_bit; // increment bit counter flag
logic clr_bit; // clear bit counter flag
logic sample_sda; // sample sda flag

// Drive SDA and SCL using tri-state buffers
assign SDA = (sda_out==0) ? 1'b0 : 1'bz;
assign SCL = (scl_out==0) ? 1'b0 : 1'bz;

// assign continue_bit to the input continu
assign continue_bit = continu;

// assign data_to_send_reg to the input data_to_send
assign data_to_send_reg = data_to_send;

// assign data_received to the data_received_reg
assign data_received = data_received_reg;

// assign address_reg to the input address
assign address_reg = address;

// create a timer to be updated depending on state and clock
always_ff @(posedge clk, posedge rst) begin
    // reset clause
    if (rst) begin
        timer <= 0;
    end else begin
        if (clr_timer)
            timer <= 0;
        else
            timer <= timer + 1; 
    end
end

// create bit counter for indexing data to send and data to recieve
always_ff @(posedge clk, posedge rst) begin
    // reset clause
    if (rst) begin
        bit_counter <= 0;
    end else begin
        if (clr_bit) 
            bit_counter <= BITS_PER_BYTE;
        else if (inc_bit) begin
            bit_counter <= bit_counter - 1;
        end
    end
end

// create state update register
always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        cs <= INIT;
    end else begin
        cs <= ns;
    end
end

// create state update logic
always_comb begin
    // default values to cover all cases
    ns = INIT;
    done_bit = 0;
    error_bit = 0;
    clr_timer = 0;
    clr_bit = 0;
    inc_bit = 0;
    sample_sda = 0;
    // reset clause
    if (rst) begin
        ns = INIT;
        done_bit = 0;
        error_bit = 0;
        clr_timer = 1;
        clr_bit = 1;
        inc_bit = 0;
        sample_sda = 0;
    end
    else begin
        // state update logic
        case(cs) 
            INIT: begin
                ns = BUS_FREE;
                clr_timer = 1;
                clr_bit = 1;
            end
            BUS_FREE: begin
                if (timer >= BUS_FREE_TIME) begin
                    ns = IDLE;
                end
                else 
                    ns = cs;
            end
            IDLE: begin
                if (start) begin
                    ns = START_HOLD;
                    clr_timer = 1;
                    clr_bit = 1;
                end
                else 
                    ns = cs;
            end
            START_HOLD: begin
                if (timer >= START_HOLD_TIME) begin
                    ns = ADDRESS_SCL_LOW_HOLD;
                    clr_timer = 1;
                end
                else 
                    ns = cs;
            end
            ADDRESS_SCL_LOW_HOLD: begin
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME) begin
                    ns = ADDRESS_SETUP;
                    clr_timer = 1;
                    inc_bit = 1;
                end
                else 
                    ns = cs;
            end
            ADDRESS_SETUP: begin
                if (timer >= DATA_SETUP_AND_TRISE) begin
                    ns = ADDRESS_SCL_HIGH;
                    clr_timer = 1;
                end
                else 
                    ns = cs;
            end
            ADDRESS_SCL_HIGH: begin
                if (timer >= SCL_HIGH_TIME) begin
                    if (bit_counter == 0) begin // if this is the last bit then next bit is ACK bit
                        ns = ADDRESS_ACK_SCL_LOW;
                        clr_timer = 1;
                    end
                    else begin // if this is not the last bit then next bit is address bit
                        ns = ADDRESS_SCL_LOW_HOLD;
                        clr_timer = 1;
                    end
                end
                else 
                    ns = cs;
            end
            REG_ADDRESS_SCL_LOW_HOLD: begin
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME) begin
                    ns = REG_ADDRESS_SETUP;
                    clr_timer = 1;
                    inc_bit = 1;
                end
                else 
                    ns = cs;
            end
            REG_ADDRESS_SETUP: begin
                if (timer >= DATA_SETUP_AND_TRISE) begin
                    ns = REG_ADDRESS_SCL_HIGH;
                    clr_timer = 1;
                end
                else 
                    ns = cs;
            end
            REG_ADDRESS_SCL_HIGH: begin
                if (timer >= SCL_HIGH_TIME) begin
                    if (bit_counter == 0) begin // if this is the last bit then next bit is ACK bit
                        ns = REG_ADDRESS_ACK_SCL_LOW;
                        clr_timer = 1;
                    end
                    else begin // if this is not the last bit then next bit is address bit
                        ns = REG_ADDRESS_SCL_LOW_HOLD;
                        clr_timer = 1;
                    end
                end
                else 
                    ns = cs;
            end
            DATA_RD_SCL_LOW_HOLD: begin
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME) begin
                    ns = DATA_RD_SETUP;
                    clr_timer = 1;
                    inc_bit = 1;
                end
                else 
                    ns = cs;
            end
            DATA_RD_SETUP: begin
                if (timer >= DATA_SETUP_AND_TRISE) begin
                    ns = DATA_RD_SCL_HIGH;
                    sample_sda = 1;
                    clr_timer = 1;
                end
                else 
                    ns = cs;
            end

            DATA_RD_SCL_HIGH: begin
                if (timer >= SCL_HIGH_TIME) begin
                    if(bit_counter == 0) begin // if this is the last bit then next bit is ACK bit
                        ns = DRIVE_ACK_SCL_LOW_HOLD;
                        clr_timer = 1;
                    end
                    else begin // if this is not the last bit then next bit is data bit
                        ns = DATA_RD_SCL_LOW_HOLD;
                        clr_timer = 1;
                    end
                end
                else if (timer >= TRISE) begin // check for repeated start condition
                    if (repeat_start) begin
                        ns = START_HOLD;
                        clr_timer = 1;
                        clr_bit = 1;
                    end
                    else
                        ns = cs;
                end
                else 
                    ns = cs;
            end
            DATA_WR_SCL_LOW_HOLD: begin
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME) begin
                    ns = DATA_WR_SETUP;
                    clr_timer = 1;
                    inc_bit = 1;
                end
                else 
                    ns = cs;
            end
            DATA_WR_SETUP: begin
                if (timer >= DATA_SETUP_AND_TRISE) begin
                    ns = DATA_WR_SCL_HIGH;
                    clr_timer = 1;
                end
                else
                    ns = cs;
            end
            DATA_WR_SCL_HIGH: begin
                if (timer >= SCL_HIGH_TIME) begin
                    if(bit_counter == 0) begin // if this is the last bit then next bit is ACK bit
                        ns = RECIEVE_ACK_SCL_LOW;
                        clr_timer = 1;
                    end
                    else begin // if this is not the last bit then next bit is data bit
                        ns = DATA_WR_SCL_LOW_HOLD;
                        clr_timer = 1;
                    end
                end
                else if (timer >= TRISE)begin // check for repeated start
                    if (repeat_start) begin
                        ns = START_HOLD;
                        clr_timer = 1;
                        clr_bit = 1;
                    end
                    else
                        ns = cs;
                end
                else 
                    ns = cs;
            end
            ADDRESS_ACK_SCL_LOW: begin // wait for clock low period and then go high to check ack
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME + DATA_SETUP_AND_TRISE) begin
                    if(SDA == 1) // check if SDA is high at this point, if so then there was no ack
                        ns = STOP_SCL_LOW;
                    else begin
                        ns = ADDRESS_ACK_SCL_HIGH;
                        clr_timer = 1;
                    end
                end
                else
                    ns = cs;
            end
            ADDRESS_ACK_SCL_HIGH: begin // check if the ack was pulled down by the slave
                if (timer >= SCL_HIGH_TIME) begin
                    if(!rd_wr)
                        ns = REG_ADDRESS_SCL_LOW_HOLD;
                    else 
                        ns = DATA_RD_SCL_LOW_HOLD;
                    clr_timer = 1;
                    clr_bit = 1;
                end
                else 
                    ns = cs;
            end

            REG_ADDRESS_ACK_SCL_LOW: begin // wait for clock low period and then go high to check ack
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME + DATA_SETUP_AND_TRISE) begin
                    done_bit = 1;
                    if(SDA == 1) // check if SDA is high at this point, if so then there was no ack
                        ns = STOP_SCL_LOW;
                    else begin
                        ns = REG_ADDRESS_ACK_SCL_HIGH;
                        clr_timer = 1;
                    end
                end
                else
                    ns = cs;
            end

            REG_ADDRESS_ACK_SCL_HIGH: begin // check if the ack was pulled down by the slave
                if (timer >= SCL_HIGH_TIME) begin
                    if (rd_wr) begin
                        ns = DATA_RD_SCL_LOW_HOLD;
                        clr_timer = 1;
                        clr_bit = 1;
                    end
                    else begin
                        ns = DATA_WR_SCL_LOW_HOLD;
                        clr_timer = 1;
                        clr_bit = 1;
                    end
                end
                else 
                    ns = cs;
            end
            
            RECIEVE_ACK_SCL_LOW: begin // wait for clock low period and then go high to check ack
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME + DATA_SETUP_AND_TRISE) begin
                    done_bit = 1;
                    if(SDA == 1) // check if SDA is high at this point, if so then there was no ack
                        ns = STOP_SCL_LOW;
                    else begin
                        ns = RECIEVE_ACK_SCL_HIGH;
                        clr_timer = 1;
                    end
                end
                else
                    ns = cs;
            end

            RECIEVE_ACK_SCL_HIGH: begin // check if the ack was pulled down by the slave
                if (timer >= SCL_HIGH_TIME) begin
                    // check if continue bit is asserted, if so then go back to read or write
                    if (continue_bit) begin
                        if (rd_wr) begin
                            ns = DATA_RD_SCL_LOW_HOLD;
                            clr_timer = 1;
                            clr_bit = 1;
                        end
                        else begin
                            ns = DATA_WR_SCL_LOW_HOLD;
                            clr_timer = 1;
                            clr_bit = 1;
                        end
                    end
                    else begin
                        ns = STOP_SCL_LOW;
                        clr_timer = 1;
                    end
                end
                else 
                    ns = cs;
            end
            DRIVE_ACK_SCL_LOW_HOLD: begin
                if (timer >= SCL_LOW_AND_TFALL_BEFORE_SETUP_TIME) begin
                    done_bit = 1;
                    ns = DRIVE_ACK_SCL_SETUP;
                    clr_timer = 1;
                end
                else 
                    ns = cs;
            end
            DRIVE_ACK_SCL_SETUP: begin
                if (timer >= DATA_SETUP_AND_TRISE) begin
                    ns = DRIVE_ACK_SCL_HIGH;
                    clr_timer = 1;
                    clr_bit = 1;
                end
                else
                    ns = cs;
            end
            DRIVE_ACK_SCL_HIGH: begin
                if (timer >= SCL_HIGH_TIME) begin
                    // if continue is asserted then go back to read or write
                    if (continue_bit) begin
                        if (rd_wr) begin
                            ns = DATA_RD_SCL_LOW_HOLD;
                            clr_timer = 1;
                            clr_bit = 1;
                        end
                        else begin
                            ns = DATA_WR_SCL_LOW_HOLD;
                            clr_timer = 1;
                            clr_bit = 1;
                        end
                    end
                    else begin
                        ns = STOP_SCL_LOW;
                        clr_timer = 1;
                    end
                end
                else
                    ns = cs;
            end
            STOP_SCL_LOW: begin
                if (timer >= SCL_LOW_TIME+TFALL) begin
                    ns = STOP_SCL_HIGH_SETUP;
                    clr_timer = 1;
                end
                else 
                    ns = cs;
            end
            STOP_SCL_HIGH_SETUP: begin
                if (timer >= STOP_SETUP_TIME+TRISE) begin
                    ns = BUS_FREE;
                    clr_timer = 1;
                    clr_bit = 1;
                end
                else 
                    ns = cs;
            end
            ERR: begin
                ns = INIT;
                clr_timer = 1;
                error_bit = 1;
            end
        endcase
    end
end

// create a read buffer for data comming in read when sample sda goes high in the state 
// machine
always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
        data_received_reg <= 0;
    end else begin
        if (sample_sda) begin
            data_received_reg <= {data_received_reg[6:0], SDA};
        end
    end
end

// create output forming logic for sda and scl
always_ff@(posedge clk or posedge rst) begin
    // reset clause
    if (rst) begin
        sda_out <= 1;
        scl_out <= 1;
    end
    else begin
        case(cs)
            INIT: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            BUS_FREE: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            IDLE: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            START_HOLD: begin
                sda_out <= 0;
                scl_out <= 1;
            end
            ADDRESS_SCL_LOW_HOLD: begin
                if (bit_counter == 0) // output rd_wr for the last bit
                    sda_out <= rd_wr;
                else
                    sda_out <= bus_address[bit_counter - 1];
                scl_out <= 0;
            end
            ADDRESS_SETUP: begin
                if (bit_counter == 0) // output rd_wr for the last bit
                    sda_out <= rd_wr;
                else
                    sda_out <= bus_address[bit_counter - 1];
                scl_out <= 0;
            end
            ADDRESS_SCL_HIGH: begin
                if (bit_counter == 0) // output rd_wr for the last bit
                    sda_out <= rd_wr;
                else
                    sda_out <= bus_address[bit_counter - 1];
                scl_out <= 1;
            end


            REG_ADDRESS_SCL_LOW_HOLD: begin
                sda_out <= address_reg[bit_counter];
                scl_out <= 0;
            end
            REG_ADDRESS_SETUP: begin
                sda_out <= address_reg[bit_counter];
                scl_out <= 0;
            end
            REG_ADDRESS_SCL_HIGH: begin
                sda_out <= address_reg[bit_counter];
                scl_out <= 1;
            end


            DATA_RD_SCL_LOW_HOLD: begin
                sda_out <= 1;
                scl_out <= 0;
            end
            DATA_RD_SETUP: begin
                sda_out <= 1;
                scl_out <= 0;
            end
            DATA_RD_SCL_HIGH: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            DATA_WR_SCL_LOW_HOLD: begin
                sda_out <= data_to_send_reg[bit_counter];
                scl_out <= 0;
            end
            DATA_WR_SETUP: begin
                sda_out <= data_to_send_reg[bit_counter];
                scl_out <= 0;
            end
            DATA_WR_SCL_HIGH: begin
                sda_out <= data_to_send_reg[bit_counter];
                scl_out <= 1;
            end
            REG_ADDRESS_ACK_SCL_LOW: begin
                sda_out <= 1;
                scl_out <= 0;
            end
            REG_ADDRESS_ACK_SCL_HIGH: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            ADDRESS_ACK_SCL_LOW: begin
                sda_out <= 1;
                scl_out <= 0;
            end
            ADDRESS_ACK_SCL_HIGH: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            RECIEVE_ACK_SCL_LOW: begin
                sda_out <= 1;
                scl_out <= 0;
            end
            RECIEVE_ACK_SCL_HIGH: begin
                sda_out <= 1;
                scl_out <= 1;
            end
            DRIVE_ACK_SCL_LOW_HOLD: begin
                sda_out <= 0;
                scl_out <= 0;
            end
            DRIVE_ACK_SCL_SETUP: begin
                if (continu)
                    sda_out <= 0;
                else
                    sda_out <= 1;
                scl_out <= 0;
            end
            DRIVE_ACK_SCL_HIGH: begin
                if (continu)
                    sda_out <= 0;
                else
                    sda_out <= 1;
                scl_out <= 1;
            end
            STOP_SCL_LOW: begin
                sda_out <= 0;
                scl_out <= 0;
            end
            STOP_SCL_HIGH_SETUP: begin
                sda_out <= 0;
                scl_out <= 1;
            end
            default: begin
                sda_out <= 1;
                scl_out <= 1;
            end
        endcase
    end
end

// for busy the signal should always be high except for the IDLE state
assign busy = (cs == IDLE) ? 0 : 1;

// assign done bit, and error bit
assign done = done_bit;
assign error = error_bit;



endmodule