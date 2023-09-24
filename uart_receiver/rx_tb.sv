/***************************************************************************
*
* model: rx_testbench
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 19, 2023
*
* Description: Testbench for the rx module
*
****************************************************************************/
`timescale 1ns / 1ps

module rx_tb ();

    reg clk, rst, tb_send;
    reg [7:0] tb_din;
    wire [7:0] rx_data;
    wire tb_rx_out, rx_busy, data_strobe, rx_error;

    parameter NUMBER_OF_CHARS = 10;
    parameter BAUD_RATE = 19200;
    parameter CLK_FREQUECY = 100000000;
    
    // set time format
    initial
        $timeformat(-9,1,"ns");

    localparam BAUD_CLOCKS = CLK_FREQUECY / BAUD_RATE;
    localparam CHAR_CLOCKS = BAUD_CLOCKS * 11;
    // calculate how long one clock cycle is in NS given the clock frequency is in MHz
    localparam CLOCK_PERIOD_NS = 1000 / CLK_FREQUECY;
    localparam BAUD_PERIOD_NS = BAUD_CLOCKS * CLOCK_PERIOD_NS;
    localparam CHAR_PERIOD_NS = CHAR_CLOCKS * CLOCK_PERIOD_NS;
    localparam TWO_CYCLE_DELAY = 2;
    localparam RAND_CLK_LOWER = 100;
    localparam RAND_CLK_HIGHER = 200;

    reg [7:0] char_to_send = 0;
    reg tb_parity_mode;

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate Transmitter simulation model
    //////////////////////////////////////////////////////////////////////////////////
    
    tx_model tx_model(
        .clk(clk),
        .rst(rst),
        .tx_out(tb_rx_out),
        .din(tb_din),
        .start_tx(tb_send),
        .parity_mode(tb_parity_mode)
    );

    //////////////////////////////////////////////////////////////////////////////////
    // Instantiate Design Under Test (DUT) - Receiver
    //////////////////////////////////////////////////////////////////////////////////
    
    rx rx(
        .clk(clk),
        .rst(rst),
        .din(tb_rx_out),
        .dout(rx_data),
        .busy(rx_busy),
        .data_strobe(data_strobe),
        .rx_error(rx_error)
    );

    //////////////////////////////////////////////////////////////////////////////////
    //	Clock Generator
    //////////////////////////////////////////////////////////////////////////////////
    always
    begin
        clk <= 1; #5ns;
        clk <= 0; #5ns;
    end
    
    //////////////////////////////////
    //	Main Test Bench Process
    //////////////////////////////////
    initial begin
        int clocks_to_delay;
        $display("===== RX TB =====");

        // Simulate some time with no stimulus/reset
        #100ns

        // Set some defaults        
        rst = 0;
        tb_send = 0;
        tb_din = 8'hff;
        tb_parity_mode = 1;
        #100ns

        //Test Reset
        $display("[%0tns] Testing Reset", $realtime);
        rst = 1;
        #80ns;
        // Un reset on negative edge
        @(negedge clk)
        rst = 0;

        // Make sure rx is not busy
        @(negedge clk)
        if (rx_busy != 1'b0)
            $display("[%0t] Warning: RX busy after reset", $realtime);

        //////////////////////////////////
        //	Transmit a few characters to design
        //////////////////////////////////
        #10us;
        for(int i = 0; i < NUMBER_OF_CHARS; i++) begin
            char_to_send = $urandom_range(0,255);
            tb_din = char_to_send;
            tb_send = 1;
            // wait a few clock cycles 
            repeat(TWO_CYCLE_DELAY)
                @(negedge clk);

            tb_send = 0;
        
            @(posedge data_strobe); // Wait for one character duration

            repeat(TWO_CYCLE_DELAY)
                @(negedge clk);
            
            // Check received data
            if (rx_data ^ char_to_send) 
                $display("[%0t] ERROR: Sent 0x%h, Received 0x%h", $realtime, char_to_send, rx_data);
            else
                $display("[%0t] SUCCESS: Sent 0x%h and Received 0x%h", $realtime, char_to_send, rx_data);
            
            // Delay a random amount of time
            clocks_to_delay = $urandom_range(RAND_CLK_LOWER,RAND_CLK_HIGHER);
            repeat(clocks_to_delay)
                @(negedge clk);
        end        

        // Test with invalid parity
        $display("[%0t] Testing with invalid parity", $realtime);
        // change the parity mode of the transmitter
        tb_parity_mode = 0;

        char_to_send = $urandom_range(0,255);
        tb_send = 1;
        repeat(TWO_CYCLE_DELAY)
            @(negedge clk);
        tb_send = 0;
        tb_din = char_to_send;
        // wait for the transmission of the the character to complete
        @(posedge data_strobe); // Wait for one character duration
        repeat(TWO_CYCLE_DELAY)
            @(negedge clk);

        if (rx_error) 
            $display("[%0t] SUCCESS: Parity error detected properly", $realtime);
        else
            $display("[%0t] ERROR: Parity error not detected", $realtime);

        $finish;
    end
    
endmodule
