library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_receiver is
end tb_receiver;

architecture Behavioral of tb_receiver is

    -- Component declaration
    component receiver
        Port (
            Clk: in std_logic;
            rst: in std_logic;
            uart_rx: in std_logic;
            data_valid: out std_logic;
            received_pxl: out std_logic_vector(7 downto 0)
        );
    end component;

    -- Internal signals
    signal Clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal uart_rx : std_logic := '1';  -- UART line idle is high
    signal data_valid : std_logic;
    signal received_pxl : std_logic_vector(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant BAUD_PERIOD : time := 8.68 us;  -- Simulated baud tick ~115200 baud

    -- Test byte to send
    constant DATA_BYTE : std_logic_vector(7 downto 0) := "10101001";  -- 0xA9

begin

    Clk <= not Clk after CLK_PERIOD / 2;

    -- Instantiate DUT
    DUT: receiver
        port map (
            Clk => Clk,
            rst => rst,
            uart_rx => uart_rx,
            data_valid => data_valid,
            received_pxl => received_pxl
        );

    -- Simulate sample_generator behavior
    baud_proc: process
    begin
        -- Wait for initial setup
        wait for 200 us;

        -- Send start bit
        uart_rx <= '0';
        wait for BAUD_PERIOD;

        -- Send data 
        for i in 0 to 7 loop
            uart_rx <= DATA_BYTE(i);
            wait for BAUD_PERIOD;
        end loop;

        -- Stop bit
        uart_rx <= '1';

        wait;
    end process;

end Behavioral;
