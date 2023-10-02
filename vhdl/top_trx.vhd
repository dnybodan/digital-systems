-- /***************************************************************************
-- *
-- * Module: top_trx
-- *
-- * Author: Daniel Nybo
-- * Class: ECEN 620
-- * Date: September 19, 2023
-- *
-- * Description: Top-level module for transmitter and receiver. Uses a
-- *              debouncer and one-shot circuit for the center button.
-- *              It also uses a two flip-flop synchronizer for the RX input
-- *              signal. The LEDs are connected to the transmitter and
-- *              receiver modules. This is specifically implimented for the
-- *              vhdl_rx project with a seven segment display.
-- *
-- ****************************************************************************/

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top_trx is
    generic (
        CLK_FREQ: integer := 100_000_000;  -- 100 MHz
        BAUD_RATE: integer := 19_200;      -- 19200
        PARITY_MODE: integer := 1          -- Odd Parity
    );
    port(
        CLK100MHZ: in std_logic;
        CPU_RESETN: in std_logic;
        SW: in std_logic_vector(7 downto 0);
        BTNC: in std_logic;
        LED: out std_logic_vector(15 downto 0);
        UART_RXD_OUT: out std_logic;
        UART_TXD_IN: in std_logic;
        LED16_B: out std_logic;
        LED17_R: out std_logic;
        LED17_G: out std_logic;
        segment: out std_logic_vector(6 downto 0);
        AN: out std_logic_vector(7 downto 0)
    );
end entity top_trx;

architecture Behavioral of top_trx is

    -- Signals
    signal led_upper: std_logic_vector(7 downto 0);
    signal btn_debounced: std_logic;
    signal btn_one_shot: std_logic;
    signal btn_prev: std_logic;
    signal reset: std_logic;
    signal update_upper: std_logic;
    signal last_8_chars: std_logic_vector(31 downto 0);
    signal uart_txd_in_sync1, uart_txd_in_sync2: std_logic;
    signal dout_receiver: std_logic_vector(7 downto 0);

    constant SEGMENT_UPDATE_WINDOW_MS: integer := 2;

begin

    -- Instantiate Transmitter
    tx_inst: entity work.tx port map(
        clk => CLK100MHZ,
        rst => reset,
        send => btn_one_shot,
        din => SW,
        busy => LED16_B,
        tx_out => UART_RXD_OUT
    );

    -- Instantiate Receiver
    rx_inst: entity work.rx port map(
        clk => CLK100MHZ,
        rst => reset,
        din => uart_txd_in_sync2,
        dout => dout_receiver,
        busy => LED17_R,
        data_strobe => update_upper,
        rx_error => LED17_G
    );

    -- Debouncer for the center button
    debounce_inst: entity work.debounce port map(
        clk => CLK100MHZ,
        reset => reset,
        noisyInput => BTNC,
        debounced => btn_debounced
    );

    -- Seven segment display
    seven_segment_inst: entity work.seven_segment port map(
        clk => CLK100MHZ,
        data => last_8_chars,
        anode => AN,
        segment => segment
    );

    -- Reset assignment
    reset <= not CPU_RESETN;

    -- One-shot for button
    process(CLK100MHZ,reset)
    begin
        if reset = '1' then
            btn_prev <= '0';
            btn_one_shot <= '0';
        elsif rising_edge(CLK100MHZ) then
            if btn_debounced = '1' and btn_prev = '0' then
                btn_one_shot <= '1';
            else
                btn_one_shot <= '0';
            end if;
            btn_prev <= btn_debounced;
        end if;
    end process;

    -- Two flip-flop synchronizer
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            uart_txd_in_sync1 <= UART_TXD_IN;
            uart_txd_in_sync2 <= uart_txd_in_sync1;
        end if;
    end process;

    -- LED connections
    LED(7 downto 0) <= SW;

    -- Only connect the upper 8 bits of the LED if the receiver has new data
    process(CLK100MHZ,reset)
    begin
        if reset = '1' then
                led_upper <= (others => '0');
                last_8_chars <= (others => '0');
        elsif rising_edge(CLK100MHZ) then
            if update_upper = '1' then
                led_upper <= dout_receiver;
                last_8_chars <= last_8_chars(23 downto 0) & dout_receiver;
            end if;
        end if;
    end process;

    LED(15 downto 8) <= led_upper;

end architecture Behavioral;
