// simulation model for a generic SPI subunit.
// This model will print the value received and send a 8-bit counter value that increments each transaction.
`timescale 1ns/1ps
module spi_subunit (sclk, mosi, miso, cs);

    input wire logic sclk;
    input wire logic mosi;
    output logic miso;
    input wire logic cs;

    int transfer_count = 1;  // Initial counter value to send out on each transaction
    logic [7:0] received_value = 0;
    logic [7:0] send_value = 0;
    int bits_received = 0;
    logic active = 0;

    // High impedence if there is not a transaction going on
    assign miso = active ? send_value[7] : 1'bz;

    // Capture data coming in
    always@(posedge sclk)
    begin
        if (cs == 0) begin // Only process sclks when CS is low
            received_value <= {received_value[6:0],mosi};
            bits_received <= bits_received + 1;
            if (bits_received == 0)
                send_value <= transfer_count;
            else
                send_value <= {send_value[6:0],1'b0};
        end
    end

    always@(negedge sclk && bits_received == 8)
    begin
        $display("[%0tns]  SPI Agent received byte 0x%h (#%0d)", $time/1000,
            received_value, transfer_count);
        // Increment transfer count
        transfer_count <= transfer_count + 1;
        // Reset bits received counter
        bits_received <= 0;
    end


    // Reset internal state
    always@(posedge cs) begin
        active <= 1'b0;
    end

    // Setup transfer
    always@(negedge cs) begin
        active <= 1'b1;
        bits_received <= 0;
    end


endmodule