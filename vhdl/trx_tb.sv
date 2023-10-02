/***************************************************************************
*
* Module: trx_tb
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 19, 2023
*
* Description: Testbench for the TRX module specifically implimented for the
*              Nexys 4 DDR board using a vhdl rx module and a verilog tx
*
****************************************************************************/
`timescale 1ns/1ps

module trx_tb();

    // Signals
    logic CLK100MHZ;
    logic CPU_RESETN;
    logic BTNC_T;
    logic [7:0] SW;
    logic [15:0] LED;
    logic UART_RXD_OUT, UART_TXD_IN;
    logic LED16_B, LED17_R, LED17_G;

    // create parameters for clockrat and baudrate and parity mode
    parameter CLK_FREQ = 100000000;
    parameter BAUD_RATE = 19200;
    parameter PARITY_MODE = 1;

    // Create a free-running clock
    always
    begin
        CLK100MHZ <=1; #5ns;
        CLK100MHZ <=0; #5ns;
    end

    // Constants
    localparam RAND_BITMASK = 8'd255;
    localparam CHARS_TO_SEND = 3;

    // Instantiate top-level design
    top_trx uut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .SW(SW),
        .BTNC(BTNC_T),
        .LED(LED),
        .UART_RXD_OUT(UART_RXD_OUT),
        .UART_TXD_IN(UART_TXD_IN),
        .LED16_B(LED16_B),
        .LED17_R(LED17_R),
        .LED17_G(LED17_G)
    );

    // set the internal parameters of the top-level design
    defparam uut.CLK_FREQ = CLK_FREQ;
    defparam uut.BAUD_RATE = BAUD_RATE;
    defparam uut.PARITY_MODE = PARITY_MODE;

    // Connect transmitter output to receiver input
    assign UART_TXD_IN = UART_RXD_OUT;

    // Test sequence
    initial begin
        // Default signals
        CPU_RESETN = 1; // Active low reset
        BTNC_T = 0;
        SW = 8'd0;
        
        // Wait for a few clock cycles
        #20;

        // Assert reset
        CPU_RESETN = 0;
        #20;

        // De-assert reset
        CPU_RESETN = 1;
        #20;

        // Character transfer sequences
        for(int i = 0; i < CHARS_TO_SEND; i++) begin
            // Random value
            SW = $random & RAND_BITMASK;
            #10ns;

            // Press BTNC
            BTNC_T = 1;
            #5ms; // Assuming 5ms is enough for debouncer
            BTNC_T = 0;
            #5ms // assuming 5ms is enough for debouncer to go low

            // Wait until the transmitter reciever is no longer busy
            wait(!LED16_B && !LED17_R);
            #20ns;
        
            // Check
            if(LED[15:8] != SW) $display("Error: Sent and received values do not match!");
            else if(LED17_G) $display("Error: Receiver error!");
            else $display("Success: Sent and received values match and transmitted without error!");

            #10;
        end

        $stop;  // Terminate simulation
    end

endmodule

