/***************************************************************************
*
* Module: BRAM
*
* Author: Daniel Nybo
* Class: ECEN 620
* Date: November 9, 2023
*
* Description: BRAM instantiation using primitive as well as inferred
*              BRAM. The first BRAM will transmit over the uart, the second
*              will receive from the uart. 
*
****************************************************************************/

`timescale 1ns/1ps
`default_nettype none
module bram(input wire logic CLK100MHZ,
            input wire logic CPU_RESETN,
            input wire logic BTNL,
            input wire logic BTNR,
            input wire logic UART_TXD_IN,
            output logic UART_RXD_OUT,
            output logic LED16_B,
            output logic LED16_G,
            output logic[7:0] AN,
            output logic [6:0] segment
            );
`default_nettype wire
    localparam STOP_CHAR = 8'h04; // stop character for UART TX
    // create some internal signals
    logic rst, rst_d;         // reset
    logic[31:0] segment_data; // data for the seven segment display
    logic[7:0] output_buffer; // output buffer for UART TX
    logic[15:0] DOADO;         // read output data
    logic[1:0] DOPADOP;       // read output parity (only one bit used in this case)
    logic[13:0] ADDRARDADDR;  // read address
    logic ENARDEN;            // enable read
    logic uart_tx_busy;       // UART transmitter busy
    logic send_byte;          // send byte to UART
    logic[7:0] uart_rx_buffer;// UART receiver buffer
    logic uart_rx_busy;       // UART receiver busy
    logic uart_rx_data_ready; // UART receiver data ready
    logic uart_rx_error;      // UART receiver error
    

    // state machine for reading from the BRAMs
    typedef enum logic [3:0] {IDLE, READ, TRANSMIT_READ, READ_BRAM2, TRANSMIT_BRAM2, DONE} state_type;
    state_type cs, ns;
 
    // reset synchronizer
    always_ff @(posedge CLK100MHZ) begin
        rst_d <= !CPU_RESETN;
        rst <= rst_d;
    end

    // instance seven segment display
    seven_segment seven_segment (
        .clk(CLK100MHZ),
        .data(segment_data),
        .anode(AN), 
        .segment(segment)
    );

    // instantiate the UART receiver
    rx my_rx(.clk(CLK100MHZ),
             .rst(rst),
             .din(UART_TXD_IN),
             .dout(uart_rx_buffer),
             .busy(uart_rx_busy),
             .data_strobe(uart_rx_data_ready),
             .rx_error(uart_rx_error));
    
    // hook up rx busy signal to LED15_B
    assign LED16_G = uart_rx_busy;

    // RAMB18E1: 18K-bit Configurable Synchronous Block RAM
    // 7 Series
    // Xilinx HDL Language Template, version 2019.1
    RAMB18E1 #(
        // Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
        .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
        // Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
        .SIM_COLLISION_CHECK("ALL"),
        // DOA_REG, DOB_REG: Optional output register (0 or 1)
        .DOA_REG(0),
        .DOB_REG(0),
        // INITP_00 to INITP_07: Initial contents of parity memory array
        .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
        // INIT_00 to INIT_3F: Initial contents of data memory array
        .INIT_00(256'h206c72756820646e612073726167756f43206c61796f6c206c6c612065736952),
        .INIT_01(256'h7720756f590a0d656f6620656874206f742065676e656c6c6168632072756f79),
        .INIT_02(256'h726f206e696172202c746867696e20726f20796164202c7468676966206c6c69),
        .INIT_03(256'h0d6575727420646e61202c676e6f727473202c6c61796f4c0a0d2e776f6e7320),
        .INIT_04(256'h656c6968570a0d2e65756c6220646e612065746968772065687420726165570a),
        .INIT_05(256'h6f430a0d2e676e69727073206f742074657320746567202c676e697320657720),
        .INIT_06(256'h684f202e756f79206f7420707520732774692073726167756f43206e6f20656d),
        .INIT_07(256'h6874202c74756f687320646e6120657369520a0d3a7375726f68430a0d0a0d21),
        .INIT_08(256'h6172742065687420676e6f6c610a0d74756f206572612073726167756f432065),
        .INIT_09(256'h20646e6120657369520a0d2e79726f6c6720646e6120656d6166206f74206c69),
        .INIT_0A(256'h0d74756f20676e6972206c6c6977207372656568632072756f202c74756f6873),
        .INIT_0B(256'h726f747320792772746369762072756f7920646c6f666e7520756f792073410a),
        .INIT_0C(256'h206568742068736975716e6176206f74206f6720756f79206e4f0a0d0a0d2e79),
        .INIT_0D(256'h616420646e6120736e6f73207327726574614d20616d6c4120726f6620656f66),
        .INIT_0E(256'h6e69202c676e6f73206e69206e696f6a2065772073410a0d2e73726574686775),
        .INIT_0F(256'h7274732073692068746961662072756f202c756f7920666f2065736961727020),
        .INIT_10(256'h6769682073726f6c6f632072756f206573696172206c6c2765570a0d2e676e6f),
        .INIT_11(256'h756f432072756f20726565686320646e410a0d65756c6220656874206e692068),
        .INIT_12(256'h00000000000000000000000000000000000000042e55594220666f2073726167),
        .INIT_13(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_14(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_15(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_16(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_17(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_18(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_19(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_20(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_21(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_22(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_23(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_24(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_25(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_26(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_27(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_28(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_29(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_30(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_31(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_32(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_33(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_34(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_35(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_36(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_37(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_38(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_39(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        // INIT_A, INIT_B: Initial values on output ports
        .INIT_A(18'h00000),
        .INIT_B(18'h00000),
        // Initialization File: RAM initialization file
        .INIT_FILE("NONE"),
        // RAM Mode: "SDP" or "TDP"
        .RAM_MODE("TDP"),
        // READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
        .READ_WIDTH_A(9), // 0-72
        .READ_WIDTH_B(9), // 0-18
        .WRITE_WIDTH_A(9), // 0-18
        .WRITE_WIDTH_B(9), // 0-72
        // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
        .RSTREG_PRIORITY_A("RSTREG"),
        .RSTREG_PRIORITY_B("RSTREG"),
        // SRVAL_A, SRVAL_B: Set/reset value for output
        .SRVAL_A(18'h00050),
        .SRVAL_B(18'h00050),
        // Simulation Device: Must be set to "7SERIES" for simulation behavior
        .SIM_DEVICE("7SERIES"),
        // WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        .WRITE_MODE_A("WRITE_FIRST"),
        .WRITE_MODE_B("WRITE_FIRST")
        )
        RAMB18E1_inst (
        // Port A Data: 16-bit (each) output: Port A data
        .DOADO(DOADO), // 16-bit output: A port data/LSB data
        .DOPADOP(DOPADOP), // 2-bit output: A port parity/LSB parity
        // Port B Data: 16-bit (each) output: Port B data
        .DOBDO(), // 16-bit output: B port data/MSB data
        .DOPBDOP(), // 2-bit output: B port parity/MSB parity
        // Port A Address/Control Signals: 14-bit (each) input: Port A address and control signals (read port
        // when RAM_MODE="SDP")
        .ADDRARDADDR(ADDRARDADDR), // 14-bit input: A port address/Read address
        .CLKARDCLK(CLK100MHZ), // 1-bit input: A port clock/Read clock
        .ENARDEN(ENARDEN), // 1-bit input: A port enable/Read enable
        .REGCEAREGCE(), // 1-bit input: A port register enable/Register enable
        .RSTRAMARSTRAM(rst), // 1-bit input: A port set/reset
        .RSTREGARSTREG(rst), // 1-bit input: A port register set/reset
        .WEA(), // 2-bit input: A port write enable
        // Port A Data: 16-bit (each) input: Port A data
        .DIADI(), // 16-bit input: A port data/LSB data
        .DIPADIP(), // 2-bit input: A port parity/LSB parity
        // Port B Address/Control Signals: 14-bit (each) input: Port B address and control signals (write port
        // when RAM_MODE="SDP")
        .ADDRBWRADDR(), // 14-bit input: B port address/Write address
        .CLKBWRCLK(), // 1-bit input: B port clock/Write clock
        .ENBWREN(), // 1-bit input: B port enable/Write enable
        .REGCEB(), // 1-bit input: B port register enable
        .RSTRAMB(), // 1-bit input: B port set/reset
        .RSTREGB(), // 1-bit input: B port register set/reset
        .WEBWE(), // 4-bit input: B port write enable/Write enable
        // Port B Data: 16-bit (each) input: Port B data
        .DIBDI(), // 16-bit input: B port data/MSB data
        .DIPBDIP() // 2-bit input: B port parity/MSB parity
        );
        // End of RAMB18E1_inst instantiation


    // infer a second BRAM which will load all the bytes from the UART_RECEIVER
    logic[7:0] bram2 [4095:0];
    logic bram2_WRE;
    logic[7:0] bram2_byte_in;
    logic[7:0] bram2_byte_out;
    logic[13:0] bram2_write_address;
    logic[13:0] bram2_read_address;
    logic inc_bram2_wrtie_address;
    logic inc_bram2_read_address;
    logic clr_bram2_address;
    logic[13:0] bram2_num_bytes_loaded;

    initial begin
        // initialize all values of bram2 to 0
        for (int i = 0; i < 4096; i++) begin
            bram2[i] <= 8'h00;
        end
    end

    // ram read/write signal
    always_ff@(posedge CLK100MHZ) begin
        if (bram2_WRE)
            bram2[bram2_write_address] <= bram2_byte_in;
        bram2_byte_out <= bram2[bram2_read_address];
    end

    //  data path for the bram2 data in and address handling
    always_ff @(posedge CLK100MHZ) begin
        if (rst) begin
            bram2_WRE <= 1'b0;
            bram2_write_address <= 14'h0000;
            bram2_num_bytes_loaded <= 14'h0000;
            bram2_read_address <= 14'h0000;
        end
        else begin
            if (clr_bram2_address) begin
                bram2_write_address <= 14'h0000;
                bram2_num_bytes_loaded <= 14'h0000;
                bram2_read_address <= 14'h0000;
            end
            if (inc_bram2_wrtie_address) begin
                bram2_write_address <= bram2_write_address + 14'h01;
                bram2_num_bytes_loaded <= bram2_num_bytes_loaded + 14'h01;
            end
            if (inc_bram2_read_address) begin
                bram2_read_address <= bram2_read_address + 14'h01;
            end
            if (uart_rx_data_ready) begin
                bram2_WRE <= 1'b1;
                bram2_byte_in <= uart_rx_buffer;
                inc_bram2_wrtie_address <= 1'b1;
            end
            else begin
                bram2_WRE <= 1'b0;
                inc_bram2_wrtie_address <= 1'b0;
            end
        end
    end

    // Debouncer for the left button (debounced_BTNL)
    logic debounced_BTNL;
    debounce left_button_debouncer (
        .debounced(debounced_BTNL),
        .clk(CLK100MHZ),
        .reset(rst),
        .noisyInput(BTNL)
    );
    // oneshot circuit for the left button
    logic btnl_one_shot;
    oneshot btnl_oneshot (
        .clk(CLK100MHZ),
        .rst(rst),
        .trigger(debounced_BTNL),
        .one_out(btnl_one_shot)
    );

    // Debouncer for the right button (debounced_BTNR)
    logic debounced_BTNR;
    debounce right_button_debouncer (
        .debounced(debounced_BTNR),
        .clk(CLK100MHZ),
        .reset(rst),
        .noisyInput(BTNR)
    );
    
    // oneshot circuit for the right button
    logic btnr_one_shot;
    oneshot btnr_oneshot (
        .clk(CLK100MHZ),
        .rst(rst),
        .trigger(debounced_BTNR),
        .one_out(btnr_one_shot)
    );

    // UART transmitter
    tx my_tx(
        .clk(CLK100MHZ), 
        .rst(rst), 
        .send(send_byte),
        .din(output_buffer),
        .busy(uart_tx_busy), 
        .tx_out(UART_RXD_OUT)
    );
    assign LED16_B = uart_tx_busy;
    
    // byte address counter for bram1
    logic [13:0] bram1_byte_address;
    logic clr_byte;
    logic inc_byte;
    always_ff @(posedge CLK100MHZ) begin
        if (rst) begin
            bram1_byte_address <= 14'h0000;
        end
        else begin
            if(clr_byte)
                bram1_byte_address <= 14'h0000;
            else if(inc_byte)
                bram1_byte_address <= bram1_byte_address + 14'h08;
        end
    end

    // state update register
    always_ff @(posedge CLK100MHZ) begin
        cs <= ns;
    end

    // state machine combinational logic for outputing BRAMS over UART TX
    always_comb begin
        ns = cs;
        clr_byte = 1'b0;
        inc_byte = 1'b0;
        send_byte = 1'b0;
        inc_bram2_read_address = 1'b0;
        clr_bram2_address = 1'b0;
        if (rst) begin
            ns = IDLE;
            clr_byte = 1'b0;
            inc_byte = 1'b0;
            send_byte = 1'b0;
            inc_bram2_read_address = 1'b0;
            clr_bram2_address = 1'b0;
        end
        else begin
            case(cs)
                IDLE: begin
                    if (btnl_one_shot) begin
                        ns = READ;
                    end
                    else if (btnr_one_shot) begin
                        ns = READ_BRAM2;
                    end
                end
                READ: begin
                    // 8'04 is the stop character
                    if (DOADO[7:0] == STOP_CHAR) begin
                        ns = DONE;
                        clr_byte = 1'b1;
                    end
                    else begin
                        ns = TRANSMIT_READ;
                        send_byte = 1'b1;
                    end
                end
                TRANSMIT_READ:
                    // 8'04 is the stop character
                    if (DOADO[7:0] == STOP_CHAR) begin
                        ns = DONE;
                        clr_byte = 1'b1;
                    end
                    else if (~uart_tx_busy) begin
                        ns = READ;
                        inc_byte = 1'b1;
                    end
                    else
                        ns = cs;
                READ_BRAM2: begin
                    if (bram2_read_address >= bram2_num_bytes_loaded)begin
                        ns = DONE;
                        clr_bram2_address = 1'b1;
                    end
                    else begin
                        ns = TRANSMIT_BRAM2;
                        send_byte = 1'b1;
                        inc_bram2_read_address = 1'b1;
                    end
                end
                TRANSMIT_BRAM2: begin
                    if (~uart_tx_busy)begin 
                        ns = READ_BRAM2;
                    end
                    else
                        ns = cs;
                end
                DONE:
                    ns = IDLE;
            endcase
        end
    end

    // assign the address output for reads
    assign ADDRARDADDR = bram1_byte_address;

    // datapath out for UART TX
    always_ff@(posedge CLK100MHZ)
    begin
        if (rst)
        begin
            ENARDEN <= 1'b0;
        end
        else begin
            // if the left button is pressed, outuput all the bytes in the BRAM starting with the first byte until eof or stop character is 
            // . Output these bytes over the UART
            if (ns == IDLE)
                output_buffer <= 8'h00;
            if (ns == READ_BRAM2)
            begin
                output_buffer <= bram2_byte_out;
            end
            if (ns == TRANSMIT_READ)
            begin
                ENARDEN <= 1'b1;
                output_buffer <= DOADO;
            end
            else begin
                ENARDEN <= 1'b0;
            end

        end
    end

    // update segment data with num bytes loaded in bram2
    always_ff@(posedge CLK100MHZ)
    begin
        if (rst)
        begin
            segment_data <= 32'h00000000;
        end
        else begin
            segment_data <= bram2_num_bytes_loaded;
        end
    end


endmodule