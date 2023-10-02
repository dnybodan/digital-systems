-- /***************************************************************************
-- *
-- * Module: rx
-- *
-- * Author: Daniel Nybo
-- * Class: ECEN 620
-- * Date: September 25, 2023
-- *
-- * Description: this is a parameterized UART receiver which can be used to 
-- *              receive data from a UART transmitter. It is implemented
-- *              strictly in VHDL. This module has parameters for the
-- *              Clock frequency, the baud rate, and the parity bit. The 
-- *              module recieves a single byte of data and a parity bit.
-- *
-- ****************************************************************************/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rx is
    generic (
        CLK_FREQ : integer := 100000000;
        BAUD_RATE : integer := 19200;
        PARITY_MODE : integer := 1
    );
    port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           din : in STD_LOGIC;
           dout : out STD_LOGIC_VECTOR(7 downto 0);
           busy : out STD_LOGIC;
           data_strobe : out STD_LOGIC;
           rx_error : out STD_LOGIC);
end entity rx;

architecture Behavioral of rx is
    constant HALF_CONSTANT : integer := 2;
    constant BIT_COUNTER_MAX : integer := 7;
    constant BAUD_TIMER_MAX : integer := CLK_FREQ / BAUD_RATE;
    constant IDLE : std_logic_vector(2 downto 0) := "000";
    constant SRT : std_logic_vector(2 downto 0) := "001";
    constant BITS : std_logic_vector(2 downto 0) := "010";
    constant PAR : std_logic_vector(2 downto 0) := "011";
    constant STP : std_logic_vector(2 downto 0) := "100";
    constant ACK : std_logic_vector(2 downto 0) := "101";
    constant INIT : std_logic_vector(2 downto 0) := "110";
    constant ERR : std_logic_vector(2 downto 0) := "111";

    signal dataBuffer : std_logic_vector(10 downto 0) := (others => '0');
    signal cs, ns : std_logic_vector(2 downto 0) := ERR;
    signal baudTimer : integer := 0;
    signal timerDone, halfTimerDone : std_logic;
    signal clrTimer : std_logic := '0';
    signal bitCounter : integer := 0;
    signal bitDone : std_logic;
    signal clrBit, incBit : std_logic := '0';
    signal startBit, parityBit, ackBit, stopBit, dataBit : std_logic := '0';
    signal parityCalc : std_logic := '0';

    function shift_left_std_logic(signal s: std_logic; shift_amount: integer; size: integer) return std_logic_vector is
        variable result: std_logic_vector(size-1 downto 0);
    begin
        result := (others => '0');
        result(shift_amount) := s;
        return result;
    end function;

begin

    -- Baud timer logic
    timerDone <= '1' when baudTimer = BAUD_TIMER_MAX else '0';
    halfTimerDone <= '1' when baudTimer = (BAUD_TIMER_MAX / HALF_CONSTANT) else '0';
    -- Baud timer update block
    process(clk, rst)
    begin
        if rst = '1' then
            baudTimer <= 0;
        elsif rising_edge(clk) then
            if clrTimer = '1' then
                baudTimer <= 0;
            elsif timerDone = '1' then
                baudTimer <= 0;
            else
                baudTimer <= baudTimer + 1;
            end if;
        end if;
    end process;

    -- Counter Logic
    bitDone <= '0' when bitCounter < BIT_COUNTER_MAX else '1';
    -- Counter update block
    process(clk, rst) 
    begin
        if rst = '1' then
            bitCounter <= 0;
        elsif rising_edge(clk) then
            if clrBit = '1' then
                bitCounter <= 0;
            elsif incBit = '1' then
                bitCounter <= bitCounter + 1;
            end if;
        end if;
    end process;

    -- Datapath for data stream
    process(clk, rst)
    begin
        if rst = '1' then
            dataBuffer <= (others => '0');
            dout <= (others => '0');
            data_strobe <= '0';
        elsif rising_edge(clk) then
            if startBit = '1' and halfTimerDone = '1' then
                -- clear data buffer and restart loading the data
                dataBuffer <= (others => '0');
                dataBuffer(0) <= din;
            elsif dataBit = '1' and halfTimerDone = '1' then
                dataBuffer <= (dataBuffer or shift_left_std_logic(din, bitCounter, dataBuffer'length));
            elsif parityBit = '1' and halfTimerDone = '1' then
                dataBuffer <= (dataBuffer(9 downto 0) & din);
            elsif stopBit = '1' and halfTimerDone = '1' then
                dataBuffer <= (dataBuffer(9 downto 0) & din);
            end if;
            if ackBit = '1' then
                dout <= dataBuffer(9 downto 2);
                data_strobe <= '1';
                -- clear the data buffer
            else
                data_strobe <= '0';
            end if;
        end if;
    end process;

    -- Error handling logic
    process(clk, rst)
    begin
        if rst = '1' then
            rx_error <= '0';
        elsif rising_edge(clk) then
            if startBit = '1' then
                rx_error <= '0';
            end if;
            if stopBit = '1' then
                -- calculate the parity error here since it will have been recieved
                -- calculate the parity bit of the bits 9-1 since these are the data bits
                -- with the parity bit included hence the magic numbers
                parityCalc <= dataBuffer(9) xor dataBuffer(8) xor dataBuffer(7) xor dataBuffer(6) xor dataBuffer(5) xor dataBuffer(4) xor dataBuffer(3) xor dataBuffer(2) xor dataBuffer(1);
            end if;
            if ackBit = '1' then
                if dataBuffer(10) = '1' then
                    rx_error <= '1';
                end if;
                if dataBuffer(0) = '0' then
                    rx_error <= '1';
                end if;
                if PARITY_MODE = 1 then
                    if parityCalc = '0' then
                        rx_error <= '1';
                    end if;
                else
                    if parityCalc = '1' then
                        rx_error <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Busy signal logic
    process(clk,rst)
    begin
        if rst = '1' then
            busy <= '0';
        elsif rising_edge(clk) then
            if startBit = '1' then
                busy <= '1';
            elsif ackBit = '1' then
                busy <= '0';
            end if;
        end if;
    end process;
    
  
    process(cs, din, timerDone, halfTimerDone, startBit, dataBit, bitDone, rst)
    begin
        -- Defaults
        ns <= INIT;
        startBit <= '0';
        dataBit <= '0';
        incBit <= '0';
        parityBit <= '0';
        stopBit <= '0';
        ackBit <= '0';
        clrBit <= '0';
        clrTimer <= '0';

        -- Reset clause
        if rst = '1' then
            ns <= INIT;
            clrBit <= '1';
            clrTimer <= '1';
            startBit <= '0';
            dataBit <= '0';
            incBit <= '0';
            parityBit <= '0';
            stopBit <= '0';
            ackBit <= '0';
        else
            case cs is
                when INIT =>
                    if din = '1' then
                        ns <= IDLE;
                    else
                        ns <= cs;
                    end if;
                
                when IDLE =>
                    if din = '1' then
                        ns <= IDLE;
                    else
                        ns <= SRT;
                        clrTimer <= '1';
                    end if;

                when SRT =>
                    startBit <= '1';
                    if timerDone = '1' then
                        ns <= BITS;
                        clrBit <= '1';
                    else
                        ns <= cs;
                    end if;

                when BITS =>
                    dataBit <= '1';
                    if (timerDone = '1' and bitDone = '1') then
                        ns <= PAR;
                    elsif (timerDone = '1' and bitDone = '0') then
                        incBit <= '1';
                        ns <= cs;
                    else
                        ns <= cs;
                    end if;

                when PAR =>
                    parityBit <= '1';
                    if timerDone = '1' then
                        ns <= STP;
                    else
                        ns <= cs;
                    end if;

                when STP =>
                    stopBit <= '1';
                    if timerDone = '1' then
                        ns <= ACK;
                    else
                        ns <= cs;
                    end if;

                when ACK =>
                    ackBit <= '1';
                    ns <= IDLE;

                when ERR =>
                    ns <= cs;
                -- others clause
                when others =>
                    ns <= ERR;
            end case;
        end if;
    end process;

    -- State register update
    process (clk, rst)
    begin
        if rst = '1' then
            cs <= INIT;
        elsif rising_edge(clk) then
            cs <= ns;
        end if;
    end process;

end Behavioral;