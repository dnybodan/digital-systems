`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// TX top-level testbench
//////////////////////////////////////////////////////////////////////////////////

module top_tb ();

    logic clk, rst_n, rst, btnc;
    logic [7:0] sw;
    logic [15:0] led_i;
    logic [7:0] led_sw;
    logic led_tx_busy;
    logic tx_out;
    logic rx_busy;
    logic [7:0] rx_data;
    logic [7:0] char_to_send = 0;

    int bounce_delay_clocks, bounces;
    //int NUMBER_OF_CHARS = 2;

    parameter time BOUNCE_TIME = 1ms;
    parameter time CLOCK_PERIOD = 10ns;
    parameter BOUNCE_CLOCKS = BOUNCE_TIME / CLOCK_PERIOD;
    parameter BOUNCE_CLOCKS_LOW_RANGE = 1000;
    parameter BOUNCE_CLOCKS_HIGH_RANGE = 10000;
    parameter NUM_BOUNCES_LOW_RANGE = 2;
    parameter NUM_BOUNCES_HIGH_RANGE = 5;
    parameter NUMBER_OF_CHARS = 3;

    // Instantiate Top-level design    
    tx_top tx_top(
        .CLK100MHZ(clk),
        .CPU_RESETN(rst_n),
        .SW(sw),
        .BTNC(btnc),
        .LED(led_i),
        .UART_RXD_OUT(tx_out)
    );

    // Instantiate RX simulation model    
    rx_model rx_model(
        .clk(clk),
        .rst(rst),
        .rx_in(tx_out),
        .busy(rx_busy),
        .dout(rx_data)
    );

    //	Clock Generator
    always
    begin
        clk <=1; #5ns;
        clk <=0; #5ns;
    end

    // reset
    assign rst = ~rst_n;
    // LEDs
    assign led_sw = led_i[7:0];
    assign led_tx_busy = led_i[15];

    // Task for generating a bouncy signal
	task bounce_btnc( input end_result);
        //$display("[%0tns] Starting bouncy btnc", $time/1000.0);
        bounces = $urandom_range(NUM_BOUNCES_LOW_RANGE,NUM_BOUNCES_HIGH_RANGE);
        for(int i = 0; i < bounces; i++) begin
            // Bounce to end result
            btnc = end_result;
            bounce_delay_clocks = $urandom_range(BOUNCE_CLOCKS_LOW_RANGE,BOUNCE_CLOCKS_HIGH_RANGE);
            repeat(bounce_delay_clocks)
                @(negedge clk);
            // Bounce to opposite of end result
            btnc = ~end_result;
            bounce_delay_clocks = $urandom_range(BOUNCE_CLOCKS_LOW_RANGE,BOUNCE_CLOCKS_HIGH_RANGE);
            repeat(bounce_delay_clocks)
                @(negedge clk);
        end
        // Done bouncing. Set to end result
        btnc = end_result;
    endtask

	task test_led( input [7:0] sw_val);
        sw = sw_val;
        repeat(3) @(negedge clk);
        if (led_sw != sw)
            $display("[%0tns] ERROR: LEDs do not follow switches LED=%h != SW=%h", $time/1000, led_sw, sw_val);
        repeat(3) @(negedge clk);
    endtask

    // Task for initiating a transfer
	task initiate_tx( input [7:0] char_value );

        // set switches
        sw = char_value;
        repeat(10)
            @(negedge clk)

        // Make sure btnc is low
        if (btnc != 0) begin
            bounce_btnc(0);
            // repeat(BOUNCE_CLOCKS)
            //     @(negedge clk);
        end
            
        // Create a bouncy signal
        $display("[%0tns] Transmitting 0x%h", $time/1000.0, char_value);
        bounce_btnc(1);

        // Wait until busy goes high
        wait (rx_busy == 1'b1);

    endtask    

    //////////////////////////////////
    //	Main Test Bench Process
    //////////////////////////////////
    initial begin
        int clocks_to_delay;
        $display("===== TX TB =====");

        // Simulate some time with no stimulus/reset
        #100ns

        // Set some defaults        
        rst_n = 1;
        btnc = 0;
        sw = 8'h00;
        #100ns

        //Test Reset
        $display("[%0tns] Reset", $time/1000.0);
        rst_n = 0;
        #80ns;
        // Un reset on negative edge
        @(negedge clk)
        rst_n = 1;

        // Make sure the LEDs follow the switches
        #100ns;
        test_led(8'ha5);
        #100ns;
        test_led(8'h5a);
        #100ns;
        sw = 8'h00;

        //	Send some bounces. Should not transmit.
        $display("[%0tns] Sending some bounces. Should not transmit", $time/1000.0);
    	bounce_btnc(1);
    	bounce_btnc(0);
        #10us;

        //	Transmit a few characters to design
        #10us;
        for(int i = 0; i < NUMBER_OF_CHARS; i++) begin
            char_to_send = $urandom_range(0,255);
            initiate_tx(char_to_send);
            // Wait until transmission is over
            wait (rx_busy == 1'b0);

            // Wait some more to make sure that we don't start a new transfer
            repeat(5000)
                @(negedge clk);

            // Lower the button
        	bounce_btnc(0);
            // Wait long enough for button 0 to propagate
            repeat(2*BOUNCE_CLOCKS)
                @(negedge clk);
        end
        
        $finish;
    end
    
endmodule