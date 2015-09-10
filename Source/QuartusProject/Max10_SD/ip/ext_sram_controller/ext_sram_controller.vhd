LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity ext_sram_controller is
	port (
		clk, reset: in std_logic;
		-- Avalon MM slave interface
		address: in std_logic_vector(19 downto 0);
		chipselect_n: in std_logic;
		read_n: in std_logic; 
		write_n: in std_logic; 
		writedata: in std_logic_vector(7 downto 0);
		readdata: out std_logic_vector(7 downto 0);
		-- Conduit from Atari cart bus
		atari_bus_driven: in std_logic;
		atari_sram_addr: in std_logic_vector(19 downto 0);
		atari_sram_data: out std_logic_vector(7 downto 0);
		atari_sram_enable: in std_logic;
		-- Conduit to/from SRAM
		sram_addr: out std_logic_vector(19 downto 0);
		sram_dq: inout std_logic_vector(7 downto 0);
		sram_ce: out std_logic;
		sram_oe_n: out std_logic;
		sram_we_n: out std_logic
	);
end ext_sram_controller;

architecture arch of ext_sram_controller is
begin
	-- to Avalon
	readdata <= sram_dq;
	-- to atari
	atari_sram_data <= sram_dq;
	-- to SRAM
	sram_addr <= address when atari_bus_driven = '0' else atari_sram_addr;
	sram_ce <= not chipselect_n when atari_bus_driven = '0' else atari_sram_enable;
	sram_oe_n <= read_n when atari_bus_driven = '0' else not atari_sram_enable;
	sram_we_n <= write_n when atari_bus_driven = '0' else '1';
	-- SRAM tristate data bus
	sram_dq <= writedata when (atari_bus_driven = '0' and write_n = '0') else (others => 'Z');
end arch;