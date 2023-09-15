/***************************************************************************
*
* Module: tx_top
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 13, 2023
*
* Description: This module is the top level module for the UART transmitter
*             project. It instantiates the UART transmitter and debounce
*             module. It also ties the UART output to the LED16_B output
*             and the UART input to the SW input. It also ties the BTNC
*             input to the debounce module.
*
****************************************************************************/
`default_nettype none
`timescale 1ns / 1ps

/* tx_top module
*   Ports: 
*       CLK100MHZ: 100 MHz clock input
*       CPU_RESETN: CPU reset input
*       SW: 8-bit input from switches
*       BTNC: Button input
*       LED: 8-bit output to LEDs
*       UART_RXD_OUT: UART output
*       LED16_B: UART busy output
*/
module tx_top(
    input wire logic CLK100MHZ,CPU_RESETN,
    input wire logic[7:0] SW,
    input wire BTNC,
    output logic[7:0] LED,
    output logic UART_RXD_OUT, LED16_B);
    
    // intermediate signals
    logic syncOut;
    logic debSend;
    logic reset;
    logic send_character;

    // Button synchronizer signals
    logic btnc_r;
    logic btnc_r2;

    // tie reset to cpu resetn
    assign reset = ~CPU_RESETN;
    
    // tie LEDs to Switches 
    assign LED = SW;

    // Button synchronizaer
    always_ff@(posedge CLK100MHZ)
    begin
       btnc_r <= BTNC;
       btnc_r2 <= btnc_r;
    end
    
    always_ff@(posedge CLK100MHZ)
        UART_RXD_OUT <= syncOut;
    
    tx uart_tx(.clk(CLK100MHZ),.rst(reset),.send(debSend),.din(SW),.tx_out(syncOut),.busy(LED16_B));
    
    debounce debounce_fsm(.clk(CLK100MHZ),.reset(reset),.noisy(btnc_r2),.debounced(debSend));
    
endmodule
    