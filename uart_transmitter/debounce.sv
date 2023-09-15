/***************************************************************************
*
* Module: debounce
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: September 13, 2023
*
* Description: This module debounces a noisy input signal. It also provides
*             a debounced output signal.
*
****************************************************************************/
`default_nettype none

module debounce #(parameter MOD_VALUE = 50000)(
    output logic debounced,
    input wire logic clk, reset, noisy);
    
    //logic bits for counting to 499999
    logic[18:0] count;
    //to know if timer is done or if to clear timer
    logic clrTimer, timerDone;
    
    //declaration of states
    typedef enum logic[1:0] {s0, s1, s2, s3, ERR='X} stateType;
    stateType ns, cs;
    
    //decides when timerDone is true
    assign timerDone = (count == MOD_VALUE -1);
    
    //counter to calculate delay of 5ms    
    always_ff @(posedge clk)
    begin
        if (clrTimer || reset)
            count <= 0;
        else
            count <= count + 1;
    end
    
    
    //always comb logic for calculating next state
    always_comb 
    begin
        //assigning default values for ns debounced clrTimer and timerDone
        ns = ERR;
        debounced = 0;
        clrTimer = 0; 
    
        if(reset)
            ns = s0;
        else
            case (cs)
            
                s0: begin
                    clrTimer = 1'b1; 
                    if (!noisy)
                        ns = s0; 
                    else
                        ns = s1;
                end
                s1: if (!noisy)
                        ns = s0;
                    else if (!timerDone)
                        ns = s1;
                    else
                        ns = s2;
                s2: begin
                    debounced = 1'b1;
                    clrTimer = 1'b1;    
                    if (!noisy)
                        ns = s3;
                    else
                        ns = s2; 
                    end
                s3: begin
                    debounced = 1'b1;
                    if (noisy)
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
