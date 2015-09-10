-- ****************************************************************************
-- *  Copyright (C) 2012 by Michael Fischer
-- *  All rights reserved.
-- *
-- *  Many thanks to Lothar Miller who has provided the basic example of
--    the SPI device:
-- *  http://www.lothar-miller.de/s9y/archives/50-Einfacher-SPI-Master-Mode-0.html
-- *
-- *  Redistribution and use in source and binary forms, with or without 
-- *  modification, are permitted provided that the following conditions 
-- *  are met:
-- *  
-- *  1. Redistributions of source code must retain the above copyright 
-- *     notice, this list of conditions and the following disclaimer.
-- *  2. Redistributions in binary form must reproduce the above copyright
-- *     notice, this list of conditions and the following disclaimer in the 
-- *     documentation and/or other materials provided with the distribution.
-- *  3. Neither the name of the author nor the names of its contributors may 
-- *     be used to endorse or promote products derived from this software 
-- *     without specific prior written permission.
-- *
-- *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
-- *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
-- *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
-- *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
-- *  THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
-- *  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
-- *  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
-- *  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
-- *  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
-- *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
-- *  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
-- *  SUCH DAMAGE.
-- *
-- ****************************************************************************
-- *  History:
-- *
-- *  26.08.2012  mifi  First Version,
-- *                    based on the basic SPI device from Lothar Miller.
-- *  15.08.2013  mifi  The 16 bit access was replaced by 32 bit.  
-- *  17.08.2013  mifi  Added CD and WP support.
-- ****************************************************************************


-- ****************************************************************************
-- *  Library                                                                 *
-- ****************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


-- ****************************************************************************
-- *  Entity                                                                  *
-- ****************************************************************************

entity spi_master_core is
   port (
          --
          -- Avalon Slave bus
          --
          clk        : in  std_logic := '0';
          reset      : in  std_logic := '0';
          chipselect : in  std_logic := '0';
          address    : in  std_logic_vector(2 downto 0) := (others => '0');
          write      : in  std_logic := '0';
          writedata  : in  std_logic_vector(31 downto 0) := (others => '0');
          read       : in  std_logic := '0';
          readdata   : out std_logic_vector(31 downto 0);
      
          -- 
          -- External bus
          --
          cs         : out std_logic;
          sclk       : out std_logic;
          mosi       : out std_logic;
          miso       : in  std_logic := '0';
          cd         : in  std_logic := '0';
          wp         : in  std_logic := '0'
        );
end entity spi_master_core;

-- *****************************************************************************
-- *  Architecture                                                             *
-- *****************************************************************************

architecture syn of spi_master_core is

   --
   -- Define all constants here
   --
   
   constant ADDR_TXDATA : integer := 0;   -- Write
   constant ADDR_RXDATA : integer := 1;   -- Read
   constant ADDR_CTRL_1 : integer := 2;   -- Read / Write
   constant ADDR_STATUS : integer := 3;   -- Read


   --
   -- Define all components which are included here
   --

   
   --
   -- Define all local signals (like static data) here
   --
   
   -- Read Multiplexer
   signal read_mux    : std_logic_vector(31 downto 0) := (others => '0');
   
   -- Register File
   signal tx_data     : std_logic_vector(31 downto 0) := (others => '0');
   signal rx_data     : std_logic_vector(31 downto 0) := (others => '0');
   signal control_1   : std_logic_vector(31 downto 0) := std_logic_vector'(x"FFFFFFFF");
   signal status      : std_logic_vector(31 downto 0) := (others => '0');
   
   -- Prescale counter
   signal pre_cnt     : integer range 0 to (2**8)-1 := 0;
   signal pre_cnt_max : integer range 0 to (2**8)-1 := 0;

   -- Bit counter
   signal bit_cnt     : integer range 0 to (2**6)-1 := 0;
   signal bit_cnt_max : integer range 0 to (2**6)-1 := 0;
   
   -- Some control_1 values
   signal ssel        : std_logic;  -- Slave select
   signal bit32       : std_logic;  -- Bit count: 0 = 8 / 1 = 32
   signal loop_enable : std_logic;  -- Loopback:  0 = disable / 1 = enable
   
   -- Possible SPI states
   type   spitx_states is (spi_stx,spi_txactive,spi_etx);
   signal spitxstate  : spitx_states := spi_stx;

   -- SPI clock and last clock
   signal spiclk      : std_logic;
   signal spiclklast  : std_logic;

   -- TX and RX value
   signal tx_reg      : std_logic_vector(31 downto 0) := (others=>'0');
   signal rx_reg      : std_logic_vector(31 downto 0) := (others=>'0');   

   -- Some internal SPI signals   
   signal tx_done     : std_logic := '0';
   signal tx_start    : std_logic := '0';
   signal write_s1    : std_logic := '0';
   signal mosi_int    : std_logic := '0';
   signal miso_int    : std_logic := '0';
   
begin

   ----------------------------------------------
   -- Register File
   ----------------------------------------------

   process (clk)
   begin
      if rising_edge(clk) then
         if (write = '1') then
         
            if (ADDR_TXDATA = unsigned(address)) then -- ADDR_TXDATA
               if (bit32 = '0') then
                  tx_data <= writedata;
               else
                  tx_data <= writedata(7 downto 0) & writedata(15 downto 8) & writedata(23 downto 16) & writedata(31 downto 24);
               end if;
            end if;             
            
            if (ADDR_CTRL_1 = unsigned(address)) then -- ADDR_CTRL_1
               control_1 <= writedata;
            end if;             
            
         end if;
      end if; 
   end process;


   ----------------------------------------------
   -- Read Multiplexer
   ----------------------------------------------
     
   read_mux <= rx_data   when (ADDR_RXDATA = unsigned(address)) else 
               control_1 when (ADDR_CTRL_1 = unsigned(address)) else 
               status    when (ADDR_STATUS = unsigned(address)) else (others => '0');

   process (clk)
   begin
      if rising_edge(clk) then
         if (read = '1') then
            readdata <= read_mux;
         end if;
      end if;
   end process;      


   ----------------------------------------------
   -- Decode control_1 register
   ----------------------------------------------
   
   ssel        <= control_1(0);
   bit32       <= control_1(1);
   loop_enable <= control_1(2);
   pre_cnt_max <= to_integer(unsigned(control_1(15 downto 8)));
   
   bit_cnt_max <= 32 when (bit32 = '1') else 8;


   ----------------------------------------------
   -- Generate tx_start
   ----------------------------------------------
   
   process (clk)
   begin
      if rising_edge(clk) then
         write_s1 <= write;

         if (ADDR_TXDATA = unsigned(address)) then
            -- Check rising edge write
            if (write_s1 = '0') and (write = '1') then
               tx_start <= '0';      
            end if;

            -- Check falling edge write
            if (write_s1 = '1') and (write = '0') then
               tx_start <= '1';      
            end if;
         end if;               
      end if; 
   end process;
    
    
   ----------------------------------------------
   -- SPI generation
   ----------------------------------------------
   
   process (clk)
   begin
      if rising_edge(clk) then      
         --
         -- Clock prescaler
         -- SPI clock = clk / ((pre_cnt_max+1)*2)
         --
         if (pre_cnt > 0) then
            pre_cnt <= pre_cnt - 1;
         else
            pre_cnt <= pre_cnt_max;
         end if;   
         
         -- Generate SPI signals
         spiclklast <= spiclk;
         case spitxstate is
            when spi_stx =>
               bit_cnt <= bit_cnt_max;
               spiclk  <= '0';
               if (tx_start = '1') then 
                  spitxstate <= spi_txactive; 
                  pre_cnt    <= pre_cnt_max; 
               end if;

            when spi_txactive =>             -- Data phase
               if (pre_cnt = 0) then         -- Shift if pre_cnt is 0
                  spiclk <= not spiclk;
                  if (bit_cnt = 0) then      -- All bits was transfered?
                     spiclk     <= '0';
                     spitxstate <= spi_etx;
                  end if;
                  if (spiclk = '1') then
                     bit_cnt <= bit_cnt - 1;  
                  end if;  
               end if;

            when spi_etx =>
               tx_done <= '1';
               if (tx_start = '0') then      -- Done was set, wait for next start
                  tx_done    <= '0';
                  spitxstate <= spi_stx;
               end if;
         end case;
      end if;
   end process;      

   --
   -- RX shift register
   --
   process (clk)
   begin 
      if rising_edge(clk) then
         if (spiclk = '1' and  spiclklast = '0') then
            rx_reg <= rx_reg(30 downto 0) & miso_int;
         end if;
      end if;
   end process;   
     
   --
   -- TX shift register
   --
   process (clk)
   begin 
      if rising_edge(clk) then
         if (spitxstate = spi_stx) then
            tx_reg <= tx_data;
         end if;
         if (spiclk = '0') and (spiclklast='1') then
             tx_reg <= tx_reg(30 downto 0) & tx_reg(0);
         end if;
      end if;         
   end process;     

   status(0) <= tx_done;
   status(1) <= cd;
   status(2) <= wp;
   
   mosi_int  <= tx_reg(bit_cnt_max-1);
   
   rx_data   <= rx_reg when (bit32 = '0') else 
                rx_reg(7 downto 0) & rx_reg(15 downto 8) & rx_reg(23 downto 16) & rx_reg(31 downto 24);


   ----------------------------------------------
   -- External bus
   ----------------------------------------------
   cs       <= ssel     when (loop_enable = '0') else '1'; 
   sclk     <= spiclk   when (loop_enable = '0') else '0'; 
   
   mosi     <= mosi_int when (loop_enable = '0') else '0'; 
   miso_int <= miso     when (loop_enable = '0') else mosi_int;

end architecture syn;

-- *** EOF ***
