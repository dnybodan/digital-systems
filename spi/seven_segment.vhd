-- /***************************************************************************
-- *
-- * Module: seven_segment
-- *
-- * Author: Daniel Nybo
-- * Class: ECEN 620
-- * Date: September 27, 2023
-- *
-- * Description: this is the seven segment display module for the Nexys DDR
-- *              board. It takes in a 32 bit vector and displays it on the
-- *              seven segment display.
-- *
-- ****************************************************************************/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment is
    Generic(
        CLK_FREQ: integer := 100000000; -- Default for Nexys DDR board
        MIN_DIGIT_DISPLAY_TIME_MS: integer := 2;
        MS_PER_SEC: integer := 1000
    );
    Port(
        clk: in std_logic;
        data: in std_logic_vector(31 downto 0); -- 8 x 4 bits for each seven-segment digit
        anode: out std_logic_vector(7 downto 0);
        segment: out std_logic_vector(6 downto 0)
    );
end seven_segment;

architecture Behavioral of seven_segment is
    signal counter: integer := 0;
    signal display_count: integer := (CLK_FREQ * MIN_DIGIT_DISPLAY_TIME_MS) / MS_PER_SEC;
    signal current_digit: integer := 0; -- To select which digit to display
    signal segment_data: std_logic_vector(3 downto 0);
    signal rst: std_logic := '0';
    -- Segment decoder
    function get_segment_pattern(digit: std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case digit is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000000"; -- B
            when "1100" => return "1000110"; -- C
            when "1101" => return "1000000"; -- D
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1000000"; -- Default case
        end case;
    end function;

begin
    -- Process for multiplexing the display
    process(clk, rst)
    begin
        if rst = '1' then
            counter <= 0;
            current_digit <= 0;
        elsif rising_edge(clk) then
            counter <= counter + 1;
            if counter = display_count then
                counter <= 0;
                if current_digit = 7 then
                    current_digit <= 0;
                else
                    current_digit <= current_digit + 1;
                end if;
            end if;
        end if;
    end process;

    -- selecting the segment data
    segment_data <= data((4 * current_digit + 3) downto (4 * current_digit));
    segment <= get_segment_pattern(segment_data);
    -- select which anode is on
    anode <= "11111110" when current_digit = 0 else -- MSB digit on
             "11111101" when current_digit = 1 else -- second digit on
             "11111011" when current_digit = 2 else -- third digit on
             "11110111" when current_digit = 3 else -- fourth digit on
             "11101111" when current_digit = 4 else -- fifth digit on
             "11011111" when current_digit = 5 else -- sixth digit on
             "10111111" when current_digit = 6 else -- seventh digit on
             "01111111" when current_digit = 7 else -- LSB digit on
             "11111111";                            -- all off
             
        
end Behavioral;
