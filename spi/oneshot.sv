/***************************************************************************
*
* Module: oneshot
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: October 4, 2023
*
* Description: oneshot cirucit. Takes an input and outputs a pulse of a
*              one clock cycle duration. Until the button is pressed again
*
****************************************************************************/
`timescale 1ns/1ps
`default_nettype none
module oneshot(
    input wire logic clk,
    input wire logic rst,
    input wire logic trigger,
    output logic one_out
);
`default_nettype wire

    logic q0, q1;
    // q0 feeds q1 meaning that q1 is one clock cycle behind q0 and, the 
    // ouput is high for one clock cycle when trigger is pressed
    always @(posedge clk) begin
        if (rst) begin
            q0 <= 0;
            q1 <= 0;
        end
        else begin
            q0 <= trigger;
            q1 <= q0;
        end
    end

    assign one_out = q0 & ~q1; // Output is high for one clock cycle when trigger is pressed

endmodule