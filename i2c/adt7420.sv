`timescale 1ns/1ps
module adt7420 (scl, sda, rst, busy);

    inout wire logic scl;
    input wire logic sda;
    input wire logic rst;
    output wire busy;

    parameter logic[7:0] DEVICE_ADDRESS = 7'h4B; // 0x4B 100 10 A1() A0()

    typedef enum { UNINIT, IDLE, START, I2C_ADDRESS, DIRECTION, I2C_ADDR_ACK, WRITE_ADDRESS, 
        WRITE_ADDRESS_ACK, WRITE_DATA, WRITE_DATA_ACK,
        READ_DATA, READ_DATA_ACK } state_type_t;
    state_type_t state;
    int bit_count;
    logic [6:0] i2c_address_reg = 0; // Holds the i2c bus address
    logic [7:0] address_reg = 0;     // Holds the current device address for reading/writing
    logic [7:0] write_data_reg, read_data_reg = 0; // shift registers for reading and writing
    logic read_operation = 0;
    // Registers
    logic [15:0] cur_temp;
    logic [7:0] config_reg = 0;
    // debug
    //logic [7:0] last_value_read;  // Used by the test bench to query what was read from this model

    // Function to create random temperature value
    function automatic logic [15:0] generate_temp(input int low_range=20, input int high_range=147);
        logic [15:0] intermediate_temp;

        // Set low order bits (flag bits set to zero)
        intermediate_temp[2:0] = 0;

        // Set other bits
        intermediate_temp[15:3] = $urandom_range(high_range,low_range);
        generate_temp = intermediate_temp;
    endfunction

    // Function to read a register from the device
    function automatic logic [7:0] read_reg(input logic [6:0] reg_address);
        string regname;
        case(reg_address)
            8'h00: begin // Temperature MSB
                read_reg = cur_temp[15:8];
                regname = "TEMP MSB";
            end
            8'h01: begin
                read_reg = cur_temp[7:0];    // Temperature LSB
                regname = "TEMP LSB";
            end
            8'h03: begin
                read_reg = config_reg;    // Configuration register
                regname = "Configuration";
            end
            8'h0b: begin
                read_reg = 8'hCB; // Constant ID
                regname = "ID";
            end
            default: begin
                read_reg = 8'hFF;
                regname = "Unknown";
            end
        endcase
        $display("[%0t] ADT7420 Read %s register (0x%h) value=0x%h",$time,
            regname, reg_address,read_reg);

    endfunction

    initial
        // -9=ns, 0 = no decimal points, "ns" => "[10ns]"
        $timeformat(-9,0,"ns");

    // Function to read a register from the device
    function automatic void write_reg(input logic [6:0] reg_address, input logic [7:0] reg_data);
        string regname = "Unknown";
        case(reg_address)
            8'h03: begin
                config_reg = reg_data;    // Configuration register
                regname = "Configuration";
            end
            //default: // Do nothing
        endcase
        $display("[%0t] ADT7420 Write %s register (0x%h) with value=0x%h",$time,
            regname, reg_address,reg_data);
        //write_reg = 0;
    endfunction


    // Start condition
    always@(negedge sda) begin
        if (scl == 1'b1 && state != UNINIT) begin
            if (state == IDLE)
                $display("[%0t] ADT7420 START condition", $time);
            else
                $display("[%0t] ADT7420 RE-START condition", $time);
            //state = I2C_ADDRESS;
            state <= START;
            bit_count <= 0;
        end
    end

    // Stop condition
    always@(posedge sda) begin
        if (scl == 1'b1 && state != UNINIT) begin
            state <= IDLE;
            $display("[%0t] ADT7420 STOP condition", $time);
            cur_temp = generate_temp();
        end
    end

    always@(posedge rst) begin
        // wait until sda and scl are both high
        wait(scl == 1'b1 && (sda == 1'b1 || sda == 1'bz) );
        #20ns // let the signals settle
        state <= IDLE;
        cur_temp = generate_temp();
    end

    assign busy = (state != IDLE);

    // For a register write:
    //  Transaction #1
    //   byte 1: i2C address (write)
    //   byte 2: device register
    //   byte 3: actual data (can write two if you like)
    // Regsiter Reads
    //  Transaction #1
    //   byte 1: i2C address (write)
    //   byte 2: device register
    //  Transaction #2
    //   byte 1: i2C address (read)
    //   byte 2: read data  (can read more than one byte)

    // State
    always@(posedge scl) begin

        case(state)

            START : begin
                // Initialize i2c address register
                i2c_address_reg <= {6'b000000, sda};
                state <= I2C_ADDRESS;
            end

            I2C_ADDRESS: begin
                // If we have copied 7 bits, move to new state
                if (bit_count == 6) begin
                    if (i2c_address_reg == DEVICE_ADDRESS) begin
                        state <= DIRECTION;
                        $display("[%0t] ADT7420 Given correct i2c address 0x%h",
                            $time,i2c_address_reg);
                        // Load the direction
                        read_operation <= sda;
                    end
                    else
                        // Don't change states - just stay here until the transaction is reset
                        $display("[%0t] ADT7420 Given incorrect i2c address 0x%h",
                            $time,i2c_address_reg);
                end
                else begin
                    i2c_address_reg <= {i2c_address_reg[5:0], sda};
                    bit_count <= bit_count + 1;
                end
            end

            DIRECTION: begin
                // Will only get into this state when the address is correct
                state <= I2C_ADDR_ACK;
                if (read_operation) begin
                    // The address_reg was set during a previous cycle so we know what
                    // register we are reading from at this point.
                    read_data_reg <= read_reg(address_reg);
                    $display("[%0t] ADT7420 Read Operation Initiated", $time);
                end
                else begin
                    $display("[%0t] ADT7420 Write Operation Initiated",$time);
                    address_reg <= 0;
                end
            end

            I2C_ADDR_ACK: begin
                bit_count <= 0;
                if (read_operation) begin
                    state <= READ_DATA;
                    read_data_reg <= {read_data_reg[6:0], read_data_reg[7]};
                end
                else begin
                    state <= WRITE_ADDRESS;
                end
            end

            WRITE_ADDRESS: begin
                // If we have copied 7 bits, move to new state
                if (bit_count == 7) begin
                    state <= WRITE_ADDRESS_ACK;
                    $display("[%0t] ADT7420 Write Operation to address 0x%h",$time,address_reg);
                end
                else begin
                    // write device address
                    address_reg <= {address_reg[6:0], sda};
                    bit_count <= bit_count + 1;
                end
            end

            WRITE_ADDRESS_ACK: begin
                bit_count <= 0;
                state <= WRITE_DATA;
                // Load first bit of data on this transition and clear register
                write_data_reg <= {7'b0000000, sda};
            end

            WRITE_DATA: begin
                // If we have copied 7 bits, move to new state
                if (bit_count == 7) begin
                    state <= WRITE_DATA_ACK;
                    $display("[%0t] ADT7420 Write Value 0x%h to address 0x%h",
                        $time,write_data_reg,address_reg);
                    write_reg(address_reg,write_data_reg);
                end
                else begin
                    // write operation
                    write_data_reg <= {write_data_reg[6:0], sda};
                    bit_count <= bit_count + 1;
                end
            end

            WRITE_DATA_ACK: begin
                bit_count <= 0;
                address_reg <= address_reg + 1;
                //write_data_reg = 0;
                state <= WRITE_DATA;
            end

            READ_DATA: begin
                // If we have copied 7 bits, move to new state
                if (bit_count == 7) begin
                    state <= READ_DATA_ACK;
                end
                else begin
                    read_data_reg <= {read_data_reg[6:0], read_data_reg[7]};
                    bit_count <= bit_count + 1;
                end
            end

            READ_DATA_ACK: begin
                //read_data_reg <= read_reg(address_reg);
                bit_count <= 0;
                address_reg <= address_reg + 1;
                if (sda) begin
                    state <= IDLE;       // No acknolwedge so be done
                end else begin
                    state <= READ_DATA;  // Acknowledge - continue
                end
            end
            default:
                state <= IDLE;
        endcase
    end

    logic sda_out=1;

    // SDA signal (either data out acknowledge)
    always@(negedge scl)
        // for data bits
        if (state == READ_DATA || (state == I2C_ADDR_ACK && read_operation))
            #200ns sda_out <= read_data_reg[7];
        //else if (state == I2C_ADDR_ACK)
        // for I2C_ADDR_ACK
        else if (state == DIRECTION)  // Note that this is one state before I2C_ADDR_ACK
            #200ns sda_out <= 0;
        //else if (state == WRITE_ADDRESS_ACK)
        // For WRITE_ADDRESS_ACK
        else if (state == WRITE_ADDRESS && bit_count == 7)  // One state before WRITE_ADDRESS_ACK
            #200ns sda_out <= 0;
        //else if (state == WRITE_DATA_ACK)
        // For WRITE_DATA_ACK
        else if (state == WRITE_DATA && bit_count == 7)
            #200ns sda_out <= 0;
        // For default
        else
            #200ns sda_out <= 1;

    // SDA (can't change SDA until the scl is low)
    assign sda = (~sda_out) ? 1'b0 : 1'bz;

endmodule