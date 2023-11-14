`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//  Filename: rx_model.sv
//////////////////////////////////////////////////////////////////////////////////

module rx_model (clk, rst, rx_in, busy, dout);

    input wire logic clk, rx_in, rst;
    output logic busy;
    output logic [7:0] dout;

    parameter CLK_FREQUECY = 100_000_000;
    parameter BAUD_RATE = 19_200;
    parameter PARITY = 1;

    localparam time BAUD_PERIOD_NS = 1s / BAUD_RATE; 
    localparam BAUD_CLOCK_CYCLES = CLK_FREQUECY / BAUD_RATE;
    localparam HALF_BAUD_CLOCK_CYCLES = BAUD_CLOCK_CYCLES / 2;

    logic [7:0] r_char;
    logic parity_calc;
    logic en_baud_counter, rst_baud_counter;

    typedef enum { UNINIT, IDLE, BUSY } state_type_e;
    state_type_e state;

    // Reciever busy condition
    assign busy = ~(state == UNINIT || state == IDLE);

    // Receive simulation initialization (needs a reset)
    always@(posedge rst) begin
        if (state == UNINIT || state == BUSY) begin
            // wait until transmit is high before receiving
            wait(rx_in == 1'b1 );
            @(posedge clk)
            state = IDLE;
        end
    end

    // Delay half of a baud period
    task delay_half_baud();
        repeat(HALF_BAUD_CLOCK_CYCLES)
            @(negedge clk);
    endtask

    // Delay a baud period
    task delay_baud(int baud_periods = 1);
        for (int i=0; i<baud_periods; i=i+1)
            repeat(BAUD_CLOCK_CYCLES)
                @(negedge clk);
    endtask

    // UART Receiver simulation
    always@(rx_in)
    begin
        // Start when tx is low and in idle state
        if (rx_in == 0 && state == IDLE) begin
            state = BUSY;
            delay_half_baud();
            if (rx_in != 0)
                $display("\[%0tns] WARNING: start bit does not stay low: %h", $time/1000,rx_in);
            r_char <= 0;
            // data bits
            for (int i=0; i<8; i=i+1) begin
                delay_baud();
                // Sample bit and shift register
                r_char <= (r_char >> 1) | ({7'd0,rx_in} << 7);
            end

            // parity bit (need to check)
            delay_baud();
            parity_calc = ^r_char[7:0] ^ PARITY;
            if (rx_in != parity_calc)
                $display("\[%0tns] WARNING: Incorrect Parity: received=%h expecting=%h", $time/1000,
                rx_in,parity_calc);

            // stop bit (make sure it is a ones)
            delay_baud();
            if (rx_in != 1)
                $display("\[%0tns] WARNING: stop bit does not stay high: %h", $time/1000,rx_in);
            $display("[%0tns] RX Received 0x%h", $time/1000, r_char);
            dout <= r_char;
            state = IDLE;
        end
    end


endmodule

