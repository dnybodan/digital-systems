/***************************************************************************
*
* Module: tb_spi_controller
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 4, 2023
*
* Description: This module is the testbench for the spi_controller module.
*              It is used to verify the functionality of the spi_controller 
*              module.
*
****************************************************************************/

module tb_spi_controller();

    // Parameters
    parameter CLK_FREQUECY = 100_000_000;
    parameter SCLK_FRUQENCY = 500_000;

    // Clock signal generation
    logic clk;
    always
    begin
        clk <=1; #5ns;
        clk <=0; #5ns;
    end

    // Signals for the SPI Controller
    logic rst;
    logic start;
    logic [7:0] data_to_send;
    logic hold_cs;
    logic [7:0] data_received;
    logic busy;
    logic done;
    logic SPI_SCLK;
    logic SPI_MOSI;
    logic SPI_MISO;
    logic SPI_CS;
    logic [7:0] mosiBUF;
    logic pass;

    // SPI Controller instantiation
    spi_controller uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_to_send(data_to_send),
        .hold_cs(hold_cs),
        .SPI_MISO(SPI_MISO),
        .data_received(data_received),
        .busy(busy),
        .done(done),
        .SPI_SCLK(SPI_SCLK),
        .SPI_MOSI(SPI_MOSI),
        .SPI_CS(SPI_CS)
    );

    // SPI Subnode instantiation
    spi_subunit subnode (
        .sclk(SPI_SCLK),
        .mosi(SPI_MOSI),
        .miso(SPI_MISO),
        .cs(SPI_CS)
    );

    // always block for sampling MOSI
    always_ff@(posedge SPI_SCLK, posedge rst) begin
        if(rst)
            mosiBUF <= 0;
        else
            mosiBUF <= {mosiBUF[6:0], SPI_MOSI};
    end

    initial begin
        // Initial conditions
        rst = 0;
        start = 0;
        data_to_send = 8'h00;
        hold_cs = 0;

        // Let 5+ clocks go by
        #50ns;

        // Issue a reset
        rst = 1;
        #20ns;
        rst = 0;
        #20ns;

        // Send 10 single byte transfers
        for (int i=0; i<10; i++) begin
            start = 1;
            data_to_send = $random & 8'hFF;
            #10ns;
            start = 0;
            while(!done) #10ns; // Wait for done signal
            $display("Sent: %h, Received: %h", data_to_send, mosiBUF);
            if (data_to_send != mosiBUF) $display("Error occurred");
            else $display("Data correctly received.");
            #20ns;
        end
        $display("Single byte transfers complete.\n\nMulti-byte transfers starting.");
        // Send 5 multi-byte transfers
        for (int i=0; i<5; i++) begin
            start = 1;
            hold_cs = 1;  // Holding CS for multi-byte transfer
            data_to_send = $random & 8'hFF;
            #10ns;
            start = 0;
            $display("Sent (1): %h", data_to_send);
            // delay until next byte
            #16020ns;
            if (data_to_send != mosiBUF) $display("Error occurred");
            else $display("Data correctly received.");
            data_to_send = $random & 8'hFF;
            $display("Sent (2): %h", data_to_send);
            // hold cs stays high until second transfer is started
            #400ns;
            hold_cs = 0; // Ending multi-byte transfer
            while(!SPI_CS) #10ns;  // Wait for done signal   
            if (data_to_send != mosiBUF) $display("Error occurred");
            else $display("Data correctly received.");        
            #20ns;
        end
        $display("Multi-byte transfers complete.\n\nTestbench complete.");
        $finish;
    end

endmodule

