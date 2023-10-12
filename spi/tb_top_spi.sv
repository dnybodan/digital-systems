/***************************************************************************
*
* Module: tb_top_spi
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 4, 2023
*
* Description: This module is the testbench for the top-level SPI module.
*              It instantiates the top-level module and the ADXL362 model.
*              It also contains the test sequence.
*
****************************************************************************/
`timescale 1ns/1ps

module tb_top_spi #(
    parameter CLK_FREQUECY = 100_000_000,
    parameter SCLK_FRUQENCY = 500_000
    );

    // Signals for top-level module
    logic CLK100MHZ;
    logic CPU_RESETN;
    logic [15:0] SW;
    logic BTNL, BTNR;
    logic [15:0] LED;
    logic [6:0] segment;
    logic [7:0] AN;
    logic LED16_B;
    logic SPI_SCLK;
    logic SPI_MOSI;
    logic SPI_CS;
    logic SPI_MISO;

    // Free running clock
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ;
    end

    // Top-level design instantiation
    top_spi #(CLK_FREQUECY, SCLK_FRUQENCY) uut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .SW(SW),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .SPI_MISO(SPI_MISO),
        .LED(LED),
        .segment(segment),
        .AN(AN),
        .LED16_B(LED16_B),
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS)
    );

    // ADXL362 Model instantiation
    adxl362_model adxl (
        .sclk(SPI_SCLK),
        .mosi(SPI_MOSI),
        .miso(SPI_MISO),
        .cs(SPI_CS)
    );

    // Test sequence
    initial begin
        // Initialize
        #10;

        // Default values
        CPU_RESETN = 1;  // Low asserted reset
        SW = 16'h0000;
        BTNL = 0;
        BTNR = 0;

        #10;

        // Reset sequence
        CPU_RESETN = 0;
        #20ns;
        CPU_RESETN = 1;
        #20ns;

        // Read DEVICEID register (0x0)
        $display("Starting test sequence");
        $display("Reading DEVICEID register (0x00)");
        $display("Sending op 0x00, Address 0x00, expecting 0x00");
        SW[7:0] = 8'h00;
        BTNR = 1;
        #5ms; // assuming 5ms is enough time for debouncer
        BTNR = 0;
        #5ms; // assuming 5ms is enough time for debouncer
        // transaction should be long over after the 5ms delay

        #10;

        // Read PARTID (0x02)
        $display("Reading PARTID register (0x02)");
        $display("Sending op 0x00, Address 0x02, expecting 0x02");
        SW[7:0] = 8'h02;
        BTNR = 1;
        #5ms; // assuming 5ms is enough time for debouncer
        BTNR = 0;
        #5ms; // assuming 5ms is enough time for debouncer
        // transaction should be long over after the 5ms delay


        // Read status register (0x0b)
        $display("Reading STATUS register (0x0b)");
        $display("Sending op 0x00, Address 0x0b, expecting 0x0b");
        SW[7:0] = 8'h0B;
        BTNR = 1;
        #5ms; // assuming 5ms is enough time for debouncer
        BTNR = 0;
        #5ms; // assuming 5ms is enough time for debouncer
        // transaction should be long over after the 5ms delay

        #10;

        // Write 0x52 to register 0x1F for soft reset
        $display("Writing 0x52 to register 0x1F for soft reset");
        $display("Sending op 0x0A, Address 0x1F, Data 0x52");
        SW[15:8] = 8'h52;
        SW[7:0] = 8'h1F;
        BTNL = 1;
        #5ms;
        BTNL = 0;
        #5ms; // assuming 5ms is enough time for debouncer

        // End simulation
        $finish;
    end

endmodule
