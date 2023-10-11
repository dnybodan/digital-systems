/***************************************************************************
*
* Module: top_spi
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 4, 2023
*
* Description: This module instances a spi controller as well as the adxl
*              accelerometer. It will allow the controller to write and
*              read from the accelerometer.
*
****************************************************************************/
`default_nettype none
`timescale 1ns / 1ps
module top_spi #(parameter CLK_FREQUECY=100_000_000, // System Clock 
                 parameter SCLK_FRUQENCY=500_000     // SPI Controller Clock
                 )(
    input wire logic CLK100MHZ,
    input wire logic CPU_RESETN,
    input wire logic [15:0] SW,
    input wire logic BTNL,
    input wire logic BTNR,
    input wire logic SPI_MISO,
    output logic [15:0] LED,
    output logic [6:0] segment,
    output logic [7:0] AN,
    output logic LED16_B,
    output logic SPI_MOSI,
    output logic SPI_SCLK,
    output logic SPI_CS
);

    // SPI Controller Signals
    logic spi_busy, spi_done, hold_cs;
    logic [7:0] data_received, data_to_send;

    // state machine states
    // FSM states
    typedef enum {
        IDLE, READ_CMD, READ_ADD, READ_DATA, WRITE_CMD, WRITE_ADD, WRITE_DATA
    } fsm_state_t;
    fsm_state_t current_state, next_state;

    // SPI Controller Instantiation
    spi_controller spic (
        .clk(CLK100MHZ),
        .rst(~CPU_RESETN),
        .start((current_state == READ_CMD) || 
               (current_state == WRITE_CMD)),
        .data_to_send(data_to_send),
        .hold_cs(hold_cs),
        .SPI_MISO(SPI_MISO),
        .data_received(data_received),
        .busy(spi_busy),
        .done(spi_done),
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS)
    );

    // 7-segment display controller instantiation
    logic [31:0] recBuffer;
    seven_segment display_controller (
        .clk(CLK100MHZ),
        .data(recBuffer),
        .anode(AN),
        .segment(segment)
    );

    // Debouncer for the left button (debounced_BTNL)
    logic debounced_BTNL;
    debounce left_button_debouncer (
        .debounced(debounced_BTNL),
        .clk(CLK100MHZ),
        .reset(~CPU_RESETN),
        .noisyInput(BTNL)
    );
    // oneshot circuit for the left button
    logic btnl_one_shot;
    oneshot btnl_oneshot (
        .clk(CLK100MHZ),
        .rst(~CPU_RESETN),
        .trigger(debounced_BTNL),
        .one_out(btnl_one_shot)
    );

    // Debouncer for the right button (debounced_BTNR)
    logic debounced_BTNR;
    debounce right_button_debouncer (
        .debounced(debounced_BTNR),
        .clk(CLK100MHZ),
        .reset(~CPU_RESETN),
        .noisyInput(BTNR)
    );
    
    // oneshot circuit for the right button
    logic btnr_one_shot;
    oneshot btnr_oneshot (
        .clk(CLK100MHZ),
        .rst(~CPU_RESETN),
        .trigger(debounced_BTNR),
        .one_out(btnr_one_shot)
    );
    
    // datapath logic for data to send and data recieved from spi controller
    always_ff @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            data_to_send <= 0;
            recBuffer <=0;
        end else begin
            case (current_state)
                IDLE: begin
                    data_to_send <= 0;
                end
                READ_CMD: begin
                    data_to_send <= 8'h0B;  // issue read command 0x0b;
                end
                READ_ADD: begin             // read switches for address
                    data_to_send <= SW[7:0];
                end
                READ_DATA: begin            // read data recieved by spi controller
                    if (spi_done)
                        recBuffer <= {recBuffer[23:0],data_received};
                end
                WRITE_CMD: begin
                    data_to_send <= 8'h0A;  // issue write command 0x0a;
                end
                WRITE_ADD: begin            // write switches for address
                    data_to_send <= SW[7:0]; 
                end
                WRITE_DATA: begin           // write top 8 bits of switches for data
                    data_to_send <= SW[15:8];
                end
                default: begin
                    data_to_send <= 0;
                end
            endcase
        end
    end

    // FSM
    always_comb begin
        hold_cs = 0;
        next_state = IDLE;
        if(!CPU_RESETN) begin
            next_state = IDLE;
        end else begin
            case (current_state)
                IDLE: begin
                    if (btnr_one_shot) begin
                        next_state = READ_CMD;
                    end else if (btnl_one_shot) begin
                        next_state = WRITE_CMD;
                    end else begin
                        next_state = IDLE;
                    end
                end
                READ_CMD: begin
                    hold_cs = 1;
                    //wait for done
                    if (spi_done) begin
                        next_state = READ_ADD;
                    end else begin
                        next_state = READ_CMD;
                    end
                end
                READ_ADD: begin
                    hold_cs = 1;
                    //wait for done
                    if (spi_done) begin
                        next_state = READ_DATA;
                    end else begin
                        next_state = READ_ADD;
                    end
                end
                READ_DATA: begin
                    //wait for done
                    if (spi_done) begin
                        next_state = IDLE;
                    end else begin
                        next_state = READ_DATA;
                    end
                end
                WRITE_CMD: begin
                    hold_cs = 1;
                    //wait for done
                    if (spi_done) begin
                        next_state = WRITE_ADD;
                    end else begin
                        next_state = WRITE_CMD;
                    end
                end
                WRITE_ADD: begin
                    hold_cs = 1;
                    //wait for done
                    if (spi_done) begin
                        next_state = WRITE_DATA;
                    end else begin
                        next_state = WRITE_ADD;
                    end
                end
                WRITE_DATA: begin
                    //wait for done
                    if (spi_done) begin
                        next_state = IDLE;
                    end else begin
                        next_state = WRITE_DATA;
                    end
                end
                default: begin
                    next_state = IDLE;
                end
            endcase 
        end
    end

    // state register
    always_ff @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Map the rest of the connections
    assign LED = SW;
    assign LED16_B = spi_busy;

endmodule


