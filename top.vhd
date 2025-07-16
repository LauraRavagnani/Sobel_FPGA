----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/14/2025 03:54:21 PM
-- Design Name: 
-- Module Name: top - Behavioral
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

entity top is
    Port (
        Clk: in std_logic;
        rst: in std_logic;
        uart_rx: in std_logic;
        led_100: out std_logic;
        display_byte: out std_logic_vector(7 downto 0)
        );
end top;

architecture Behavioral of top is
    
    constant dim: natural := 10;                                                    -- image dimension
    
    type image_t is array(0 to dim-1, 0 to dim-1) of std_logic_vector(7 downto 0);  --  full image matrix (10x10)
    
    signal valid: std_logic := '0';
    signal received_pxl: std_logic_vector(7 downto 0);
    signal image: image_t := (others => (others => (others => '0')));               -- initialize all the image signal to 0
    signal cnt_pxl: natural := 0;                                                   -- signal to debug that counts the number od sent pixels
    signal cnt_row, cnt_col: natural := 0;                                          -- signal to access the matrix
    
    

    component receiver is 
        Port(
            Clk:in std_logic;
            rst: in std_logic;
            uart_rx: in std_logic;
            data_valid: out std_logic;
            received_pxl: out std_logic_vector(7 downto 0)
           );
    end component;

begin

    rx: receiver
        port map(
                Clk => Clk,
                rst => rst,
                uart_rx => uart_rx,
                data_valid => valid,
                received_pxl => received_pxl
                );
                
    process(Clk)
    begin
        if rising_edge(Clk) then
            if rst = '1' then
                cnt_pxl <= 0;
                led_100 <= '0';
                display_byte <= (others => '0');
                image <= (others => (others => (others => '0')));
                cnt_row <= 0;
                cnt_col <= 0;
            else 
                if valid = '1' then
                    image(cnt_row, cnt_col) <= received_pxl;
                    cnt_pxl <= cnt_pxl + 1;
                    cnt_col <= cnt_col + 1;
                    if cnt_col = dim-1 then
                        if cnt_row < dim-1 then
                            cnt_row <= cnt_row + 1;
                            cnt_col <= 0;
                        end if;
                    end if;
                    if cnt_pxl = dim**2-1 then
                        led_100 <= '1';
                    end if;
                end if;
                display_byte <= image(9, 9);
            end if;
        end if;
    end process;
    
  
    
    
  
    

end Behavioral;
