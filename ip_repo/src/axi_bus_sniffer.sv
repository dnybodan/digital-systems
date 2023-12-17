`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Daniel Nybo
// 
// Create Date: 12/12/2023 06:48:37 PM
// Design Name: 
// Module Name: axi_bus_sniffer
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
module axi_dma_sniffer #(
    parameter DATA_WIDTH = 256, // Width of the data bus
    parameter COUNTER_WIDTH = 32, // Width of the counter
    parameter CLK_FREQ = 100_000_000 // default 100 MHz
)(
    input wire clk,  // AXI clock
    input wire reset, // Reset signal

    // AXI Stream interface signals
    input wire [DATA_WIDTH-1:0] data, // Data bus
    input wire valid,                  // Valid signal indicating data is valid
    input wire ready,                  // Ready signal indicating receiver can accept data
    output wire [COUNTER_WIDTH-1:0] debug_output,
    output wire [COUNTER_WIDTH-1:0] valid_clocks,
    // Simple Register Interface for reading the bitrate
    output reg [COUNTER_WIDTH-1:0] bitrate_output // Output register containing the bitrate
);

    // Internal signals
    logic [COUNTER_WIDTH-1:0] counter = 0; // Counter for the number of valid data transfers
    logic [COUNTER_WIDTH-1:0] bit_rate = 0; // Calculated bit rate
    logic [COUNTER_WIDTH-1:0] time_elapsed = 0; // Time elapsed counter
    logic [COUNTER_WIDTH-1:0] debug_counter = 0; // Debug counter
    logic [COUNTER_WIDTH-1:0] num_clocks = 0; // Number of clock cycles

    // debug  logic 
    always_ff @(posedge clk) begin
        debug_counter <= debug_counter + 1;
    end
    assign debug_output = debug_counter;
    assign valid_clocks = num_clocks;
    // calculate how many clock cycles for 1 microsecond depending on input clock frequency
    localparam CLKS_PER_US = CLK_FREQ / 1_000_000;

    // Main Logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
            counter <= 0;
            bit_rate <= 0;
            time_elapsed <= 0;
            bitrate_output <= 0;
            num_clocks <= 0;
        end else begin
            // Increment time_elapsed on each clock cycle
            time_elapsed <= time_elapsed + 1;

            // Increment counter on valid data transfer
            if (valid) begin
                counter <= counter + 1;
                num_clocks <= num_clocks + 1;
                // Calculate bit rate every 100 clock cycles
                // 100 clock cycles is 1 microsecond
                if (counter >= CLKS_PER_US) begin
                    bit_rate <= (counter * DATA_WIDTH);
                    counter <= 0; // Reset counter for next measurement
                    time_elapsed <= 0; // Reset time_elapsed for next measurement
                    // Output logic for the bitrate
                    bitrate_output <= bit_rate;
                end  
            end
        
        end
    end

endmodule
