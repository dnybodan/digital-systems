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

`timescale 1ns / 1ps

module axi_dma_sniffer #(
    parameter DATA_WIDTH = 256, // Width of the data bus
    parameter COUNTER_WIDTH = 32 // Width of the counter
)(
    input wire clk,  // AXI clock
    input wire reset, // Reset signal

    // AXI Stream interface signals
    input wire [DATA_WIDTH-1:0] data, // Data bus
    input wire valid,                  // Valid signal indicating data is valid
    input wire ready,                  // Ready signal indicating receiver can accept data

    // Simple Register Interface for reading the bitrate
    output reg [COUNTER_WIDTH-1:0] bitrate_output // Output register containing the bitrate
);

    // Internal signals
    reg [COUNTER_WIDTH-1:0] counter = 0; // Counter for the number of valid data transfers
    reg [COUNTER_WIDTH-1:0] bit_rate = 0; // Calculated bit rate
    reg [COUNTER_WIDTH-1:0] time_elapsed = 0; // Time elapsed counter
    assign ready = 1;
    
    // Main Logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset logic
            counter <= 0;
            bit_rate <= 0;
            time_elapsed <= 0;
            bitrate_output <= 0;
        end else begin
            // Increment time_elapsed on each clock cycle
            time_elapsed <= time_elapsed + 1;

            // Increment counter on valid data transfer
            if (valid && ready) begin
                counter <= counter + 1;
            end

            // Calculate bit rate every microsecond
            // Assuming 200 MHz clock, 1 microsecond is 200 clock cycles
            if (time_elapsed >= 200) begin
                bit_rate <= (counter * DATA_WIDTH);
                counter <= 0; // Reset counter for next measurement
                time_elapsed <= 0; // Reset time_elapsed for next measurement
            end

            // Output logic for the bitrate

            bitrate_output <= bit_rate;
        
        end
    end

endmodule
