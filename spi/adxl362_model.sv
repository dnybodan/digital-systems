// simple simulation model for the adxl345 accelerometer spi interface

module adxl362_model (sclk, mosi, miso, cs);

    input wire logic sclk;
    input wire logic mosi;
    output miso;
    input wire logic cs;

    const logic [7:0] WRITE_COMMAND = 8'h0A;
    const logic [7:0] READ_COMMAND = 8'h0B;
    const logic [7:0] FIFO_COMMAND = 8'h0D;
    typedef enum {COMMAND, ADDRESS, DATA} current_byte_e;

    current_byte_e current_byte = COMMAND;
    typedef enum {WRITE_OP, READ_OP, UNKNOWN} transaction_type_e;
    transaction_type_e current_transaction;

    logic [7:0] current_address = 0;
    int current_byte_num;  // Indicates which byte is being transferred

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
            // using blocking so I have the updated values
            received_value = {received_value[6:0],mosi};
            bits_received = bits_received + 1;

            if (bits_received == 8) begin
                // First byte is the command
                if (received_value == WRITE_COMMAND) begin
                    current_transaction = WRITE_OP;
                    $display("[%0tns]  SPI sub unit: Write operation", $time/1000);
                end
                else if (received_value == READ_COMMAND) begin
                    current_transaction = READ_OP;
                    $display("[%0tns]  SPI sub unit: Read operation", $time/1000);
                end
                else begin
                    current_transaction = UNKNOWN;
                    $display("[%0tns]  SPI sub unit: Unknown operation", $time/1000);
                end
            end
            else if (bits_received == 16) begin
                // Second byte is the address
                current_address = received_value;
                $display("[%0tns]  SPI sub unit: Address 0x%h", $time/1000, current_address);
                if (current_transaction == READ_OP) begin
                    send_value = current_address; // for now, just send back the address
                    $display("[%0tns]  SPI sub unit: Sending Value 0x%h", $time/1000, send_value);
                end
            end
            else if (bits_received >= 24 && bits_received % 8 == 0) begin
                if (current_transaction == WRITE_OP) begin
                    $display("[%0tns]  SPI sub unit: Received Value 0x%h", $time/1000, received_value);
                end
            end
            else
                send_value <= {send_value[6:0],1'b0};
        end
    end

    // Reset internal state
    always@(posedge cs) begin
        active <= 1'b0;
    end

    // Setup transfer
    always@(negedge cs) begin
        active <= 1'b1;
        send_value <= 0;
        bits_received <= 0;
        current_byte = COMMAND;
    end


endmodule