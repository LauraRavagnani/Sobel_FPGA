----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 05/12/2025 01:31:32 PM
-- Design Name:
-- Module Name: sample_generator - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sample_generator is
    generic (
        baudrate: natural := 115200;
        baudrate_period : natural := 868;       -- number of clk counts in a baudrate period
        baudrate_period_half: natural := 434    -- number of clk counts in half baudrate period
        );
    Port (
        Clk: in std_logic;
        rst: in std_logic;
        uart_rx: in std_logic;
        baudrate_out: out std_logic
    );
end sample_generator;

    architecture rtl of sample_generator is

    type state_t is (IDLE, START, B0, B1, B2, B3, B4, B5, B6, B7);
    signal state: state_t := IDLE;
    signal enable_counter: std_logic := '0';
    signal enable_delay: std_logic := '0';
    signal pulse: std_logic := '0';
    signal baudrate_cnt: natural := 0;
    signal baudrate_delay_cnt: natural := 0;

begin

    pulse_generator: process(Clk)
    begin
    if rising_edge(Clk) then
        if enable_counter = '1' then
            baudrate_cnt <= baudrate_cnt + 1;
            if baudrate_cnt = baudrate_period then
                pulse <= '1';
                baudrate_cnt <= 0;
            else
                pulse <= '0';
            end if;
        else
            baudrate_cnt <= 0;
        end if;
    end if;
end process pulse_generator;

delay_line: process(Clk)
begin
    if rising_edge(Clk) then
        if pulse = '1' then
            enable_delay <= '1';
        end if;
        if enable_delay = '1' then
            baudrate_delay_cnt <= baudrate_delay_cnt + 1;
        else
            baudrate_delay_cnt <= 0;
        end if;
        if baudrate_delay_cnt = baudrate_period_half then
            baudrate_out <= '1';
            enable_delay <= '0';
        else
            baudrate_out <= '0';
        end if;
    end if;
end process;


state_machine: process(Clk)
begin
    if rising_edge(Clk) then
        if rst = '1' then
            state <= IDLE;
        else
            case state is
                when IDLE =>    enable_counter <= '0';
                                if uart_rx = '0' then
                                    state <= START;
                                end if;
                when START =>   enable_counter <= '1';
                                if pulse = '1' then
                                    state <= B0;
                                end if;
                when B0 =>      if pulse = '1' then
                                    state <= B1;
                                end if;
                when B1 =>      if pulse = '1' then
                                    state <= B2;
                                end if;
                when B2 =>      if pulse = '1' then
                                    state <= B3;
                                end if;
                when B3 =>      if pulse = '1' then
                                    state <= B4;
                                end if;
                when B4 =>      if pulse = '1' then
                                    state <= B5;
                                end if;
                when B5 =>      if pulse = '1' then
                                    state <= B6;
                                end if;
                when B6 =>      if pulse = '1' then
                                    state <= B7;
                                end if;
                when B7 =>      if pulse = '1' then
                                    state <= IDLE;
                                end if;
            end case;
        end if;
    end if;
end process;





end rtl;
