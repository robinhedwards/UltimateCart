--*****************************************************************************
--*  Copyright (C) 2012 by Michael Fischer
--*
--*  All rights reserved.
--*
--*  Redistribution and use in source and binary forms, with or without 
--*  modification, are permitted provided that the following conditions 
--*  are met:
--*  
--*  1. Redistributions of source code must retain the above copyright 
--*     notice, this list of conditions and the following disclaimer.
--*  2. Redistributions in binary form must reproduce the above copyright
--*     notice, this list of conditions and the following disclaimer in the 
--*     documentation and/or other materials provided with the distribution.
--*  3. Neither the name of the author nor the names of its contributors may 
--*     be used to endorse or promote products derived from this software 
--*     without specific prior written permission.
--*
--*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
--*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
--*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
--*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
--*  THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
--*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
--*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
--*  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
--*  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
--*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
--*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
--*  SUCH DAMAGE.
--*
--*****************************************************************************
--*  History:
--*
--*  26.08.2012  mifi  First Version
--*****************************************************************************


--*****************************************************************************
--*  DEFINE: Library                                                          *
--*****************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


--*****************************************************************************
--*  DEFINE: Entity                                                           *
--*****************************************************************************

entity spi_master_if is
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
end entity spi_master_if;

--*****************************************************************************
--*  DEFINE: Architecture                                                     *
--*****************************************************************************

architecture syn of spi_master_if is

   --
   -- Define all constants here
   --
   
   --
   -- Define all components which are included here
   --
   component spi_master_core is
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
   end component spi_master_core;

   
   --
   -- Define all local signals (like static data) here
   --
   
begin

   inst_spi : spi_master_core
	   port map (
		           clk        => clk,
		           reset      => reset,
                 chipselect => chipselect,
		           address    => address,
                 write      => write,
                 writedata  => writedata,
                 read       => read,
                 readdata   => readdata,
      
                 cs         => cs,
                 sclk       => sclk,
                 mosi       => mosi,
                 miso       => miso,
                 cd         => cd,
                 wp         => wp
	            );
   
end architecture syn;

-- *** EOF ***
