`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Daniel Nybo
// 
// Create Date: 09/11/2023 10:34:18 AM
// Design Name: 
// Module Name: tx_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`default_nettype none


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
    
    debounce debounce_fsm(.clk(CLK100MHZ),.reset(reset),.noisyInput(btnc_r2),.debounced(debSend));
    
endmodule
    