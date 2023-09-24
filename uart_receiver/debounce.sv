/***************************************************************************
*
* Module: debounce
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 19, 2023
*
* Description: This module debounces a noisyInput input signal. It also provides
*             a debounced output signal. The module is parameterized for debounce
*             time. The default debounce time is 5ms.
*
****************************************************************************/
`default_nettype none
`timescale 1ns / 1ps

module debounce #(parameter MOD_VALUE = 50000)(
    output logic debounced,
    input wire logic clk, reset, noisyInput);
    
    // logic bits for counting to 499999
    logic[18:0] count;
    // to know if timer is done or if to clear timer
    logic clrTimer, timerDone;
    
    // declaration of states
    typedef enum logic[1:0] {s0, s1, s2, s3, ERR='X} stateType;
    stateType ns, cs;
    
    // decides when timerDone is true
    assign timerDone = (count == MOD_VALUE -1);
    
    // counter to calculate delay of 5ms    
    always_ff @(posedge clk)
    begin
        // reset clause
        if (clrTimer || reset)
            count <= 0;
        else
            count <= count + 1;
    end
    
    
    // always comb logic for calculating next state
    always_comb 
    begin
        // assigning default values for ns debounced clrTimer and timerDone
        ns = ERR;
        debounced = 0;
        clrTimer = 0; 
        // reset clause
        if(reset)
            ns = s0;
        else
            case (cs)
                // state 0 is the initial state and is the only state that
                // can be entered from reset and clears debounce timer
                s0: begin
                    clrTimer = 1'b1; 
                    if (!noisyInput)
                        ns = s0; 
                    else
                        ns = s1;
                end
                // state 1 is the state that is entered when the input is
                // noisyInput and the debounce timer is not done
                s1: if (!noisyInput)
                        ns = s0;
                    else if (!timerDone)
                        ns = s1;
                    else
                        ns = s2;
                // state 2 is the state that is entered when the debounce timer 
                // is done
                s2: begin
                    debounced = 1'b1;
                    clrTimer = 1'b1;    
                    if (!noisyInput)
                        ns = s3;
                    else
                        ns = s2; 
                    end
                // state 3 is the state that is entered when the input is 
                // low and the debounce timer is not done
                s3: begin
                    debounced = 1'b1;
                    if (noisyInput)
                        ns = s2;
                    else if (!timerDone)  
                        ns = s3;
                    else 
                        ns = s0;                   
                    end 
             endcase   
    end
    
    
    //always ff block for state register
    always_ff  @(posedge clk)
        cs <= ns;
    
    
    
endmodule
