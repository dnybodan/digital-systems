/***************************************************************************
*
* Module: BRAM test bench
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: November 9, 2023
*
* Description: testbench modul for BRAM circuit
*
****************************************************************************/
`timescale 1ns / 1ps
module bram_tb();

    // INPUT signals
    logic CLK100MHZ;
    logic RESET; // active low
    logic BTNL;
    logic BTNR;
    logic UART_TXD_IN;
    logic rx_busy;
    logic[7:0] rx_data;
    // ouputs
    logic [7:0] AN;
    logic [6:0] segment;
    logic UART_RXD_OUT;
    // tx model signals
    logic [7:0] tx_data_buffer;
    logic start_tx;



    

    // create free running clock 5ns up 5ns down
    // Free running clock
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ;
    end

    
    // DUT mmcm module
    bram my_bram(.CLK100MHZ(CLK100MHZ),
            .CPU_RESETN(RESET),
            .BTNL(BTNL),
            .BTNR(BTNR),
            .UART_TXD_IN(UART_TXD_IN),
            .UART_RXD_OUT(UART_RXD_OUT),
            .AN(AN),
            .segment(segment)
            );

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate RX simulation model
    //////////////////////////////////////////////////////////////////////////////////
    
    rx_model rx_model(
        .clk(CLK100MHZ),
        .rst(RESET),
        .rx_in(UART_RXD_OUT),
        .busy(rx_busy),
        .dout(rx_data)
    );

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate TX simulation model
    //////////////////////////////////////////////////////////////////////////////////
    tx_model tx_model(
        .clk(CLK100MHZ),
        .rst(~RESET),
        .din(tx_data_buffer),
        .start_tx(start_tx),
        .tx_out(UART_TXD_IN),
        .parity_mode(1'b1)
    );

    // start test block by reseting system 
    initial begin
        
        // let run for 10 ns
        #10 
        // set initial values for inputs
        RESET = 1;
        BTNL = 0;
        BTNR = 0;
    
        #50ns
        // reset
        $display("Resetting system");
        RESET = 0;
        // let run for 100 ns
        #100ns
        // set reset to 1
        RESET = 1;
        // let run for 500 ns for locked and reset signals to propogate 
        #500
        
        $display("BRAM Test Bench: First Test is to input characters over UART and save them to BRAM 2 Then read them back using BTNR");
        $display("The second test is to output initialized characters in BRAM1 over UART, these should be the first several characters of the BYU fight song");
        

        // now starting the writing of the inferred bram
        $display("Starting BRAM 2 Test");
        $display("Inputting Characters over UART to be written to BRAM");

        // tx uart buffer
        tx_data_buffer = 8'h55;

        // start tx
        start_tx = 1;
        #10
        start_tx = 0;

        // wait for tx to finish 
        #5ms

        // send another byte
        tx_data_buffer = 8'hAA;
        start_tx = 1;
        #10
        start_tx = 0;
        #5ms

        // send another byte
        tx_data_buffer = 8'h44;
        start_tx = 1;
        #10
        start_tx = 0;
        #5ms

        // send another byte
        tx_data_buffer = 8'h11;
        start_tx = 1;
        #10
        start_tx = 0;
        #5ms

        // now send all those bytes back using btnr
        $display("Reading from BRAM2");
        $display("Pressing BTNR to read from BRAM2");
        $display("Expecting 0x55, 0xAA, 0x44, 0x11");
        BTNR = 1;
        #10ms
        BTNR = 0;
        #10ms
        $display("BRAM 2 Test complete \n\n");


        // now just set BTNL to 1 for 10 ms to see what transmits
        $display("Setting BTNL to 1");
        BTNL = 1;

        $display("Sending First several characters of the BYU fight song");
        $display("Trinsmitting 0x52, 0x69, 0x73, 0x65, 0x20, \n0x61, 0x6c, 0x6c, 0x6f, 0x79, \n0x61, 0x6c, 0x20, 0x43");
        #10ms
        $display("BRAM 1 Test complete");

        // finish simulation
        $display("Simulation complete");
        $finish;
    end

endmodule