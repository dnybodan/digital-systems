/***************************************************************************
*
* Module: top_trx
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 19, 2023
*
* Description: Top-level module for transmitter and receiver. Uses a
*              debouncer and one-shot circuit for the center button.
*              It also uses a two flip-flop synchronizer for the RX input
*              signal. The LEDs are connected to the transmitter and
*              receiver modules. This is specifically implimented for the
*              vhdl_rx project with a seven segment display.
*
****************************************************************************/
`timescale 1ns / 1ps
module top_trx #(
    parameter CLK_FREQ = 100_000_000,  // 100 MHz
    parameter BAUD_RATE = 19_200,      // 19200
    parameter PARITY_MODE = 1          // Odd Parity
) (
    input wire logic CLK100MHZ,
    input wire logic CPU_RESETN,
    input wire logic [7:0] SW,
    input wire logic BTNC,
    output logic [15:0] LED,
    output logic UART_RXD_OUT,
    input wire logic UART_TXD_IN,
    output logic LED16_B,
    output logic LED17_R,
    output logic LED17_G
);

    logic [7:0] led_upper;
    logic btn_debounced;
    logic btn_one_shot;
    logic btn_prev;
    logic reset;
    logic update_upper;

    assign reset = ~CPU_RESETN;
    logic [7:0] dout_receiver;

    // Instantiate Transmitter
    tx transmitter (
        .clk(CLK100MHZ),
        .rst(reset),
        .send(btn_one_shot),
        .din(SW),
        .busy(LED16_B),
        .tx_out(UART_RXD_OUT)
    );

    // Instantiate Receiver
    rx receiver (
        .clk(CLK100MHZ),
        .rst(reset),
        .din(uart_txd_in_sync2),
        .dout(dout_receiver),
        .busy(LED17_R),
        .data_strobe(update_upper),
        .rx_error(LED17_G)
    );

    // Debouncer for the center button
    debounce btn_debouncer (
        .clk(CLK100MHZ),
        .reset(reset),
        .noisyInput(BTNC),
        .debounced(btn_debounced)
    );

    // Set all the baud rates, parity modes, and clock frequencies
    defparam transmitter.BAUD_RATE = BAUD_RATE;
    defparam transmitter.CLK_FREQ = CLK_FREQ;
    defparam transmitter.PARITY_MODE = PARITY_MODE;

    defparam receiver.BAUD_RATE = BAUD_RATE;
    defparam receiver.CLK_FREQ = CLK_FREQ;
    defparam receiver.PARITY_MODE = PARITY_MODE;

    // One-shot circuit for button
    always_ff@(posedge CLK100MHZ) begin
        if(reset) begin
            btn_prev <= 0;
            btn_one_shot <= 0;
        end else begin
            if(btn_debounced && !btn_prev) 
                btn_one_shot <= 1;
            else
                btn_one_shot <= 0;
            btn_prev <= btn_debounced;
        end
    end

    // Two flip-flop synchronizer for RX input signal
    reg uart_txd_in_sync1, uart_txd_in_sync2;
    always_ff@(posedge CLK100MHZ) begin
        uart_txd_in_sync1 <= UART_TXD_IN;
        uart_txd_in_sync2 <= uart_txd_in_sync1;
    end

    // Connect LEDs
    assign LED[7:0] = SW;

    // only connect the upper 8 bits of the LED if the receiver has new data
    always_ff@(posedge CLK100MHZ) begin
        if (reset)
            led_upper <= 0;
        else if (update_upper)
            led_upper <= dout_receiver;
    end
    assign LED[15:8] = led_upper;
    
endmodule
