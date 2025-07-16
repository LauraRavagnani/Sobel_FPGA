----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/13/2025 04:08:18 PM
-- Design Name: 
-- Module Name: uart_rx_bit - Behavioral
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

entity uart_rx is
    Port (
        clk: in std_logic;
        rst: in std_logic;
        uart_rx_bit: in std_logic;
        valid: out std_logic;
        received_pxl: out std_logic_vector(7 downto 0)
        );
end uart_rx;

architecture Behavioral of uart_rx is

    type state_t is (idle_s, start_s, bit0_s, bit1_s, bit2_s, bit3_s, bit4_s, bit5_s, bit6_s, bit7_s, stop_s);
    signal state : state_t := idle_s;

    signal baudrate_out : std_logic;
    signal received_pxl_s : std_logic_vector(7 downto 0);

begin

    sampler_generator: entity work.sampler_generator
        port map(
                clock           => clk,
                uart_rx         => uart_rx_bit,
                baudrate_out    => baudrate_out
                );
                
                
    main : process(clk) is
    begin  -- process main
    if rising_edge(clk) then          -- rising clock edge
        if rst = '1' then
            state <= idle_s;
            valid <= '0';
            -- received_pxl_s <= (others => '0');    
        elsif rst = '0' then
            case state is
                when idle_s =>
                -- received_pxl_s <= (others => '0');
                valid         <= '0';
                if uart_rx_bit = '0' then
                    state <= start_s;
                end if;
                when start_s =>
                    if baudrate_out = '1' then
                        state <= bit0_s;
                    end if;
                when bit0_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(0) <= uart_rx_bit;
                        state            <= bit1_s;
                    end if;
                when bit1_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(1) <= uart_rx_bit;
                        state            <= bit2_s;
                    end if;
                when bit2_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(2) <= uart_rx_bit;
                        state            <= bit3_s;
                    end if;
                when bit3_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(3) <= uart_rx_bit;
                        state            <= bit4_s;
                    end if;
                when bit4_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(4) <= uart_rx_bit;
                        state            <= bit5_s;
                    end if;
                when bit5_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(5) <= uart_rx_bit;
                        state            <= bit6_s;
                    end if;
                when bit6_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(6) <= uart_rx_bit;
                        state            <= bit7_s;
                    end if;
                when bit7_s =>
                    if baudrate_out = '1' then
                        received_pxl_s(7) <= uart_rx_bit;
                        state            <= stop_s;
                    end if;
                when stop_s =>
                    if baudrate_out = '1' then
                        if uart_rx_bit = '1' then  -- stop bit must be 1
                            valid <= '1';
                            received_pxl <= received_pxl_s;
                        end if;
                        state <= idle_s;
                    end if;
                when others => null;
            end case;
        end if;
    end if;
  end process main;


end Behavioral;
