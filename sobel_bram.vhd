------------------------------------------------------------------------------------
---- Company: 
---- Engineer: 
---- 
---- Create Date: 07/05/2025 06:21:42 PM
---- Design Name: 
---- Module Name: sobel - Behavioral
---- Project Name: 
---- Target Devices: 
---- Tool Versions: 
---- Description: 
---- 
---- Dependencies: 
---- 
---- Revision:
---- Revision 0.01 - File Created
---- Additional Comments:
---- 
------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

---- Uncomment the following library declaration if using
---- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
library xil_defaultlib;
use xil_defaultlib.globals_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx leaf cells in this code.
----library UNISIM;
----use UNISIM.VComponents.all;

entity sobel_bram is
    Port (
        Clk: in std_logic;
        rst: in std_logic;
        uart_rx: in std_logic;
        uart_tx: out std_logic;
        busy: out std_logic;
        prova: out std_logic_vector(7 downto 0)
        );
end sobel_bram;

architecture Behavioral of sobel_bram is
    
    type kernel_type is array (0 to 2, 0 to 2) of signed(2 downto 0);               -- kernel is a 3x3 matrix
    type state_t is (IDLE, RECEIVING, PROCESSING, TRANSMITTING);
    
    signal valid:           std_logic := '0';
    signal image_received:  std_logic := '0';                            
    signal gx_gy_computed:  std_logic := '0';                                        -- turn on when gx and gy are computed for each pixel
    signal pxl_ready:       std_logic := '0';
    signal busy_internal:   std_logic := '0';
    signal process_done:    std_logic := '0';
    signal image_transmitted: std_logic := '0';
    signal tx_start:        std_logic := '0';
    
    signal received_pxl: std_logic_vector(7 downto 0);
    signal cnt_pxl: natural := 0;                                                   -- signal to debug that counts the number od sent pixels
    signal cnt_pxl_tran: natural := 0;
    signal cnt_row, cnt_col: natural := 0; 
    signal ki, kj: integer := -1;                                                   -- signals to count inside the kernels
    signal i, j: natural := 0;                                                      -- signals to count inside the image when performing convolution
    signal i_send, j_send: natural := 0;                                            -- signals to count inside the image when sending back
    signal gx, gy: signed(13 downto 0);                                             -- to store gx_var and gy_var results ------> 14 bits should be enough to store 2x255x9
    signal pxl: std_logic_vector(7 downto 0) := (others => '0');                                       -- pixel to multiply with the kernel entries
    signal data_buffer: std_logic_vector(7 downto 0);
    signal proc_state: natural := 10;
    signal tran_state: natural := 10;
    
   ------------     image bram signals   ---------------------
   signal img_we: std_logic_vector(0 downto 0) := "0";
   signal img_addr_wr: std_logic_vector(13 downto 0) := (others => '0');
   signal img_data_in: std_logic_vector(7 downto 0) := (others => '0');
   signal img_addr_rd: std_logic_vector(13 downto 0) := (others => '0');
   signal img_dout: std_logic_vector(7 downto 0) := (others => '0');  
   
   ------------     image_out bram signals   ---------------------
   signal out_we: std_logic_vector(0 downto 0) := "0";
   signal out_addr_wr: std_logic_vector(13 downto 0) := (others => '0');
   signal out_data_in: std_logic_vector(7 downto 0) := (others => '0');
   signal out_addr_rd: std_logic_vector(13 downto 0) := (others => '0');
   signal out_dout: std_logic_vector(7 downto 0) := (others => '0');  
    
    -- horizontal kernel
    constant kernel_x: kernel_type := (("111", "110", "111"),           -- -1,  -2, -1     
                                       ("000", "000", "000"),           --  0,   0,  0
                                       ("001", "010", "001"));          --  1,   2,  1
                        
    -- vertical kernel                                    
    constant kernel_y: kernel_type := (("111", "000", "001"),           -- -1,  0,  1     
                                       ("110", "000", "010"),           -- -2,  0,  2
                                       ("111", "000", "001"));          -- -1,  0,  1
                                       
                                      
   
    
    signal state: state_t := IDLE;
    
    
    component receiver is 
        Port(
            Clk:in std_logic;
            rst: in std_logic;
            uart_rx: in std_logic;
            data_valid: out std_logic;
            received_pxl: out std_logic_vector(7 downto 0)
           );
    end component;
    
    component transmitter is
        Port(
            Clk: in std_logic;
            rst: in std_logic;
            data_to_send: in std_logic_vector(7 downto 0);
            data_valid_tx: in std_logic;
            busy: out std_logic;
            uart_tx: out std_logic
            );
    end component;
    
    component blk_mem_gen_0
        port (
            clka   : in  std_logic;
            ena    : in  std_logic;
            wea    : in  std_logic_vector(0 downto 0);
            addra  : in  std_logic_vector(13 downto 0);
            dina   : in  std_logic_vector(7 downto 0);
            clkb   : in  std_logic;
            enb    : in  std_logic;
            addrb  : in  std_logic_vector(13 downto 0);
            doutb  : out std_logic_vector(7 downto 0)
        );
    end component;

    component blk_mem_gen_1
        port (
            clka   : in  std_logic;
            ena    : in  std_logic;
            wea    : in  std_logic_vector(0 downto 0);
            addra  : in  std_logic_vector(13 downto 0);
            dina   : in  std_logic_vector(7 downto 0);
            clkb   : in  std_logic;
            enb    : in  std_logic;
            addrb  : in  std_logic_vector(13 downto 0);
            doutb  : out std_logic_vector(7 downto 0)
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
                
    tx: transmitter
        port map(
                Clk => Clk,
                rst => rst,
                data_to_send => data_buffer,
                data_valid_tx => pxl_ready,
                busy => busy_internal,
                uart_tx => uart_tx
                );
                
    image_bram : blk_mem_gen_0
        port map (
            clka  => Clk,
            ena   => '1',
            wea   => img_we,
            addra => img_addr_wr,
            dina  => img_data_in,
            clkb  => Clk,
            enb   => '1',
            addrb => img_addr_rd,
            doutb => img_dout
        );

    image_out_bram : blk_mem_gen_1
        port map (
            clka  => Clk,
            ena   => '1',
            wea   => out_we,
            addra => out_addr_wr,
            dina  => out_data_in,
            clkb  => Clk,
            enb   => '1',
            addrb => out_addr_rd,
            doutb => out_dout
        );
        
                
    busy <= busy_internal;
    
    
    ------------    FSM ------------------
    process(Clk)
    begin
        if rising_edge(Clk) then
            if rst = '1' then
                state <= IDLE;
            else
            case state is
                when IDLE           =>  if uart_rx = '0' then
                                            state <= RECEIVING;
                                        end if;
                when RECEIVING      =>  if cnt_pxl = dim**2 then
                                            state <= PROCESSING;
                                        end if;
                when PROCESSING     =>  if process_done = '1' then
                                            state <= TRANSMITTING;
                                        end if;
                when TRANSMITTING   =>  if image_transmitted = '1' then
                                            state <= IDLE;
                                        end if;
            end case;
            end if;
        end if;
    end process;
    
    
    
    
    ------------------  RECEIVING   ------------------------------
    process(Clk)
    begin
        if rising_edge(Clk) then
            if rst = '1' then
                cnt_pxl <= 0;
                image_received <= '0';
                --image <= (others => (others => (others => '0')));
                cnt_row <= 0;
                cnt_col <= 0;
                
            elsif state = IDLE then 
                cnt_pxl <= 0;
                image_received <= '0';
                --image <= (others => (others => (others => '0')));
                cnt_row <= 0;
                cnt_col <= 0;
                
            else 
                img_we <= "0";
                if valid = '1' and state = RECEIVING then
                    img_we <= "1";
                    img_addr_wr <= std_logic_vector(to_unsigned(cnt_pxl, 14));      -- write the value of bram address where the incoming pxl is written
                    img_data_in <= received_pxl;
                    
                    cnt_pxl <= cnt_pxl + 1;
                end if;
                if cnt_pxl = dim**2 then
                    cnt_pxl <= 0;
                end if;
            end if;
        end if;
    end process; 
                
                
                
    --------------------    PROCESSING  ---------------------------
    
process(Clk)
    variable gx_var, gy_var: signed(17 downto 0) := (others => '0'); -- 18 bits because result of multiplication of 9bits x 9bits
    --variable pxl: std_logic_vector(7 downto 0)  := (others => '0');
    variable grad: unsigned(13 downto 0)  := (others => '0');
begin
    if rising_edge(Clk) then
        if rst = '1' or state = IDLE then
            i <= 0;
            j <= 0;
            ki <= -1;
            kj <= -1;
            --image_out <= (others => (others => (others => '0')));
            gx_var := (others => '0');
            gy_var := (others => '0');
            gx <= (others => '0');
            gy <= (others => '0');
            gx_gy_computed <= '0';
            process_done <= '0';

        elsif state = PROCESSING and process_done = '0' then

            if gx_gy_computed = '0' then
                
                if ki <= 1 and kj <= 1 then
                    if proc_state = 10 then
                        if (i + ki >= 0 and i + ki <= dim-1 and j + kj >= 0 and j + kj <= dim-1) then
                            img_addr_rd <= std_logic_vector(to_unsigned((i+ki)*dim + (j+kj), 14));
                        end if;
                        proc_state <= 13;
                    end if;
                    if proc_state = 13 then
                        proc_state <= 14;
                    end if;
                    if proc_state = 14 then
                        proc_state <= 15;
                    end if;
                    -- Pad borders with 0
                    if proc_state = 15 then
                        if (i + ki >= 0 and i + ki <= dim-1 and j + kj >= 0 and j + kj <= dim-1) then
                            pxl <= img_dout;
                        else
                            pxl <= (others => '0');
                        end if;
                        proc_state <= 20;
                    end if;
                    
                    if proc_state = 20 then
                        -- update gx_var, gy_var
                        gx_var := gx_var + signed(resize(unsigned(pxl), 9)) * signed(resize(kernel_x(ki+1, kj+1), 9));
                        gy_var := gy_var + signed(resize(unsigned(pxl), 9)) * signed(resize(kernel_y(ki+1, kj+1), 9));
                    
                    -- Advance kernel indices
                        if kj < 1 then
                            kj <= kj + 1;
                        else
                            kj <= -1;
                            ki <= ki + 1;
                        end if;

                        -- Check if kernel window is done
                        if ki = 1 and kj = 1 then
                            gx <= resize(gx_var, 14);
                            gy <= resize(gy_var, 14);
                            gx_gy_computed <= '1';
                        end if;
                        proc_state <= 10;
                    end if;
                end if;

            elsif gx_gy_computed = '1' then
                out_we <= "0";
               
                out_we <= "1";
                out_addr_wr <= std_logic_vector(to_unsigned(i*dim + j, 14));
               
                
                grad := unsigned(abs(gx) + abs(gy));

                if grad < threshold then
                    out_data_in <= (others => '0');
                elsif grad > 255 then
                    out_data_in <= (others => '1');
                else
                    out_data_in <= std_logic_vector(resize(grad, 8));
                end if;

                -- Move to next pixel
                if j = dim - 1 then
                    j <= 0;
                    if i = dim - 1 then
                        process_done <= '1';
                    else
                        i <= i + 1;
                    end if;
                else
                    j <= j + 1;
                end if;

                -- Reset for next convolution
                ki <= -1;
                kj <= -1;
                gx_var := (others => '0');
                gy_var := (others => '0');
                gx_gy_computed <= '0';
                    
         
            end if;
        end if;
    end if;
end process;

  

    ----------------------    TRANSMITTING    ------------------------
    process(Clk)
    begin
    if rising_edge(Clk) then
        if rst = '1' then
            cnt_pxl_tran <= 0;
            pxl_ready <= '0';
            tx_start <= '0';
            image_transmitted <= '0';
            data_buffer <= (others => '0');
            
        elsif state = IDLE then
            cnt_pxl_tran <= 0;
            pxl_ready <= '0';
            tx_start <= '0';
            image_transmitted <= '0';
            data_buffer <= (others => '0');
            
        elsif state = TRANSMITTING then
            
            -- internal FSM
            if tran_state = 10 then
                if busy_internal = '0' then
                    out_addr_rd <= std_logic_vector(to_unsigned(cnt_pxl_tran, 14));
                    
                    tran_state <= 20;
                end if;
            end if;
            
            if tran_state = 20 then
                tran_state <= 21;
            end if;
            
            if tran_state = 21 then
                tran_state <= 30;
            end if;
            
            if tran_state = 30 then
                data_buffer <= out_dout;
                pxl_ready <= '1';
                
                tran_state <= 40;
            end if;
            
            if tran_state = 40 then
                pxl_ready <= '0';
                cnt_pxl_tran <= cnt_pxl_tran + 1;
                
                tran_state <= 50;
            end if;
            
            if tran_state = 50 then
                if cnt_pxl_tran = dim**2+1 then
                    if busy_internal = '0' then
                        image_transmitted <= '1';
                    end if;
                else
                    tran_state <= 10;
                end if;
            end if;
        end if;
    end if;
    end process;
    

    
    prova <= data_buffer;
                
                
                
                
                
                
    
    
       

    
    
end Behavioral;
