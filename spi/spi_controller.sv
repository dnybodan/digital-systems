/***************************************************************************
*
* Module: spi_controller
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 4, 2023
*
* Description: This module creates a spi controller which impliments the 
*              spi protocol. It is used to communicate with the spi subunit
*              module.
*
****************************************************************************/
`timescale 1ps/1ps
`default_nettype none
module spi_controller (
    input wire logic clk,
    input wire logic rst,
    input wire logic start,
    input wire logic [7:0] data_to_send,
    input wire logic hold_cs,
    input wire logic SPI_MISO,
    output logic [7:0] data_received,
    output logic busy,
    output logic done,
    output logic SPI_SCLK,
    output logic SPI_MOSI,
    output logic SPI_CS
);

    parameter CLK_FREQUECY = 100_000_000;
    parameter SCLK_FRUQENCY = 500_000;
    localparam HALF_SCLK_PERIOD = (CLK_FREQUECY / SCLK_FRUQENCY) / 2; // half the total sclock period
    localparam DELAY_100NS = CLK_FREQUECY / 10_000_000; 
    localparam DELAY_20NS = CLK_FREQUECY / 50_000_000;
    localparam DELAY_30NS = CLK_FREQUECY /  33_333_333;
    localparam DELAY_40NS = CLK_FREQUECY / 25_000_000;

    typedef enum {
        IDLE, 
        START_TRANSFER,
        SCLK_HIGH, 
        SCLK_LOW,
        END_TRANSFER
    } state_t;

    state_t current_state, next_state;

    logic [7:0] receive_data;
    logic [31:0] sclk_counter;
    logic [2:0] bit_counter = 3'd7;  // Start with the MSB
    logic incBit,doneBit,clrSTimer,updateMOSI;

    // Outputs driven by FFs
    logic ff_SPI_CS, ff_SPI_SCLK, ff_SPI_MOSI, ff_busy, ff_done;
    logic [7:0] ff_data_received;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            receive_data <= 8'b0;
            ff_SPI_CS <= 1;
            ff_SPI_SCLK <= 0;
            ff_SPI_MOSI <= 0;
            ff_busy <= 0;
            ff_done <= 0;
            ff_data_received <= 8'b0;
        end else begin
            ff_SPI_CS <= (next_state == IDLE) ? 1 : 0;
            ff_SPI_SCLK <= (next_state == SCLK_HIGH) ? 1 : 0;
            ff_SPI_MOSI <= (updateMOSI) ? data_to_send[bit_counter] : ff_SPI_MOSI;
            ff_busy <= (next_state != IDLE);
            ff_done <= doneBit; 
            if(next_state == SCLK_LOW) ff_data_received[bit_counter] <= SPI_MISO;
        end
    end


    // sclk_counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_counter <= 0;
        end else begin
            if (clrSTimer) begin
                sclk_counter <= 0;
            end else if (sclk_counter == HALF_SCLK_PERIOD - 1) begin
                sclk_counter <= 0;
            end else begin
                sclk_counter <= sclk_counter + 1;
            end
        end
    end

    // bit counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 3'd7; // Start with the MSB
        end else begin
            if (next_state == START_TRANSFER)begin
                bit_counter <= 3'd7; // Start with the MSB
            end else if (incBit) begin
                if (bit_counter == 0) begin
                    bit_counter <= 3'd7; // Start with the MSB
                end else begin
                    bit_counter <= bit_counter - 1;
                end
            end
        end
    end



    always_comb begin
        incBit = 0;
        doneBit = 0;
        clrSTimer = 0;
        updateMOSI = 0;
        if (rst) begin
            next_state = IDLE;
            incBit = 0;
            doneBit = 0;
            clrSTimer = 0;
            updateMOSI = 0;
        end else begin
            // case (current_state)
            //     IDLE: 
            //         next_state = start ? START_TRANSFER : IDLE;
            //     START_TRANSFER:
            //         next_state = (sclk_counter == DELAY_100NS - 1) ? SCLK_HIGH : START_TRANSFER;
            //     SCLK_HIGH_SETUP:
            //         next_state = (sclk_counter == DELAY_20NS - 1) ? SCLK_HIGH : SCLK_HIGH_SETUP;
            //     SCLK_HIGH:
            //         next_state = (sclk_counter == HALF_SCLK_PERIOD - 1) ? SCLK_LOW_HOLD : SCLK_HIGH;
            //     SCLK_LOW_HOLD:
            //         next_state = (sclk_counter == DELAY_20NS - 1) ? SCLK_LOW : SCLK_LOW_HOLD;
            //     SCLK_LOW:
            //         next_state = (sclk_counter == HALF_SCLK_PERIOD - DELAY_20NS - DELAY_20NS - 1) ? SCLK_HIGH_SETUP : (bit_counter == 7 && !hold_cs) ? END_TRANSFER : SCLK_LOW;
            //     END_TRANSFER:
            //         next_state = IDLE;


            case(current_state)
                IDLE: begin
                    // When a start signal is detected, begin transfer
                    if(start) begin
                        clrSTimer = 1;
                        next_state = START_TRANSFER;
                    end
                end

                START_TRANSFER: begin
                    if(sclk_counter == DELAY_40NS - 1) begin
                        updateMOSI = 1;
                    end
                    // After setup delay, set up the SCLK high state
                    if(sclk_counter == DELAY_100NS - 1) begin
                        next_state = SCLK_HIGH;
                        clrSTimer = 1;
                    end;
                end

                SCLK_HIGH: begin
                    // At the end of SCLK high period, hold the data for MOSI
                    if(sclk_counter == HALF_SCLK_PERIOD - 1) begin
                        next_state = SCLK_LOW;
                    end
                end

                SCLK_LOW: begin
                    // force setup timing, implicit hold timing due to this being the 
                    // only update to bit increment
                    if(sclk_counter == HALF_SCLK_PERIOD - DELAY_40NS - 1) begin
                        incBit = 1;
                    end
                    // inc MOSI, again implicit hold timing
                    if(sclk_counter == HALF_SCLK_PERIOD - DELAY_30NS - 1) begin
                        updateMOSI = 1;
                    end
                    // If we're at the end of a byte, decide next action based on hold_cs
                    if(sclk_counter == HALF_SCLK_PERIOD - 1) begin
                        if(bit_counter == 7) begin
                            // If multi-byte, loop to setup state, otherwise end transfer
                            next_state = hold_cs ? SCLK_HIGH : END_TRANSFER;
                        end else begin
                            // Otherwise, continue with the next bit
                            next_state = SCLK_HIGH;
                        end
                    end
                end
                END_TRANSFER: begin
                    // After finishing transfer, return to idle state
                    next_state = IDLE;
                    doneBit = 1;
                end


            endcase
        end
    end

    // Assign FF-driven outputs to module outputs
    assign SPI_CS = ff_SPI_CS;
    assign SPI_SCLK = ff_SPI_SCLK;
    assign SPI_MOSI = ff_SPI_MOSI;
    assign busy = ff_busy;
    assign done = ff_done;
    assign data_received = ff_data_received;

endmodule

