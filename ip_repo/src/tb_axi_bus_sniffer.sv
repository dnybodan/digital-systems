`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Daniel Nybo
// 
// Create Date: 12/13/2023 01:14:20 PM
// Design Name: 
// Module Name: tb_axi_bus_sniffer
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
`timescale 1ns / 1ps

module axi_dma_sniffer_tb;

    // Testbench parameters
    parameter DATA_WIDTH = 256;
    parameter COUNTER_WIDTH = 32;
    parameter CLOCK_PERIOD = 5; // Corresponding to a 200MHz clock
    parameter NUM_TRANSFERS = 1000; // Number of data transfers
    parameter CLK_FREQ = 200000000; // Clock frequency 200MHz
    parameter CLKS_PER_US = CLK_FREQ / 1000000; // Number of clock cycles per microsecond
    
    // Signals
    reg clk;
    reg reset;
    reg [DATA_WIDTH-1:0] data;
    reg valid;
    wire ready;
    reg read_enable;
    wire [COUNTER_WIDTH-1:0] bitrate_output;
    wire [COUNTER_WIDTH-1:0] debug_out;
    wire [COUNTER_WIDTH-1:0] valid_clocks;
    
    // Instantiate the sniffer
    axi_dma_sniffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .CLK_FREQ(CLK_FREQ)
    ) sniffer (
        .clk(clk),
        .reset(reset),
        .data(data),
        .valid(valid),
        .ready(ready),
        .debug_output(debug_out),
        .bitrate_output(bitrate_output),
        .valid_clocks(valid_clocks)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD / 2) clk = ~clk;
    end
    longint expected_bitrate = 0;
    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        valid = 0;
        data = 0;
        read_enable = 0;

        // Reset the system
        #(CLOCK_PERIOD * 10);
        reset = 0;

        // Start sending data
        @(negedge clk);
        for (int i = 0; i < NUM_TRANSFERS; i++) begin
            valid = 1;
            data = i;
            @(posedge clk);
        end

        // Stop sending data
        @(negedge clk);
        valid = 0;
        data = 0;


        // Calculate expected bitrate
        // Assuming the sniffer calculates the bitrate for every microsecond (100 clock cycles)
        expected_bitrate = (DATA_WIDTH * CLKS_PER_US);

        // Check the bitrate output
        @(posedge clk);
        if (bitrate_output !== expected_bitrate) begin
            $display("Test Failed: Expected bitrate %d, but got %d", expected_bitrate, bitrate_output);
        end else begin
            $display("Test Passed: Bitrate matches expected value %d", expected_bitrate);
        end

        // Finish the simulation
        @(negedge clk);
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time = %t, Bitrate = %d", $time, bitrate_output);
    end

endmodule
