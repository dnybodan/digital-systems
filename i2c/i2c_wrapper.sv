/***************************************************************************
*
* Module: i2c_wrapper
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 16, 2023
*
* Description: This module is an i2c controller wrapper which will be used
*              to communicate with the temperature sensor on the Nexys 4 DDR
*              board.
*
****************************************************************************/

`timescale 1ns/1ps
`default_nettype none
module i2c_wrapper#(parameter CLK_FREQ = 100_000_000)(
    input wire logic clk,
    input wire logic rst,
    inout wire logic SDA,
    inout wire logic SCL,
    input wire logic start,
    input wire logic rd_wr,
    input wire logic [7:0] address,
    input wire logic [6:0] bus_address,
    input wire logic [7:0] data_to_send,
    output logic [7:0] data_received,
    output logic busy,
    output logic done,
    output logic error
);
`default_nettype wire

localparam MHZ_TO_NS = 1_000_000_000.0; // 1 ns / 1 MHz
localparam real CYCLE_CONST = CLK_FREQ / MHZ_TO_NS; // clock cycles to complete each timing in 1ns increments(100MHz clock)
localparam REPEAT_HOLD_TIME = 10000 * CYCLE_CONST; // 10000 ns

logic repeat_start, rd_wr_wrapper, continu, clr_timer;
logic[32:0] timer;

i2c_controller #(CLK_FREQ) my_i2c_controller(
    .clk(clk),
    .rst(rst),
    .SDA(SDA),
    .SCL(SCL),
    .start(start),
    .repeat_start(repeat_start),
    .rd_wr(rd_wr_wrapper),
    .address(address),
    .bus_address(bus_address),
    .data_to_send(data_to_send),
    .data_received(data_received),
    .busy(busy),
    .done(done),
    .error(error),
    .continu(continu)
);

// states for different opperations and creating valid reads and writes
typedef enum logic[8:0] {INIT, // start here on reset then go to idle
                        IDLE,  // wait here until start is issued
                        WRITE, // complete steps above for writing
                        READ_SET_REG,  // complete steps above for reading
                        READ_ISSUE_REPEAT, // issue a continue
                        READ_DATA // read the data from the register
                        } state_t;
state_t cs, ns;


// timer    
always_ff @(posedge clk, posedge rst)
begin
    // reset clause
    if (rst)
        timer <= 0;
    else begin
        if (clr_timer)
            timer <= 0;
        else
            timer <= timer + 1;
    end
end

// state register
always_ff @(posedge clk, posedge rst)
begin
    // reset clause
    if (rst)
        cs <= INIT;
    else
        cs <= ns;
end

// next state logic
always_comb begin
ns = cs;
clr_timer = 0;
// reset clause
    if (rst) begin
        ns = cs;
        clr_timer = 1;
    end
    else begin
        case (cs)
            INIT: ns = IDLE;
            IDLE: if (start) begin // wait for a start command then issue rd/wr
                if(!rd_wr)
                    ns = WRITE;
                else  
                    ns = READ_SET_REG;
            end
            WRITE: if (!busy) ns = IDLE; // wait for the write to complete
            READ_SET_REG: begin // set the register by writing to it first
                if (done) begin
                    ns = READ_ISSUE_REPEAT;
                    clr_timer = 1;
                end
            end
            READ_ISSUE_REPEAT: // issue a repeat start command
                if (timer >= REPEAT_HOLD_TIME) begin
                    ns = READ_DATA;
                end
            READ_DATA: if (done) ns = IDLE; // wait for the read to complete
            default: ns = IDLE;
        endcase
    end
end

// continue, rd_wr_wrapper, and repeated start update logic
always_ff @(posedge clk, posedge rst)
begin
    // reset clause
    if (rst) begin
        continu <= 0;
        repeat_start <= 0;
        rd_wr_wrapper <= 0;
    end
    else begin
        if (cs == IDLE) begin
            rd_wr_wrapper <= 0;
        end
        else if (cs == WRITE) begin
            rd_wr_wrapper <= 0;
        end
        else if (cs == READ_SET_REG) begin
            rd_wr_wrapper <= 0;
        end
        else if (cs == READ_ISSUE_REPEAT) begin
            repeat_start <= 1;
            continu <= 1;
            rd_wr_wrapper <= 1;
        end
        else begin
            continu <= 0;
            repeat_start <= 0;
        end 
    end
end
endmodule

