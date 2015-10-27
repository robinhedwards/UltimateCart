-- Ultimate SD Cartridge - Atari 400/800/XL/XE Multi-Cartridge
-- Copyright (C) 2015 Robin Edwards
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY atari_rom IS
	PORT (
				CLK: in std_logic;
				LED: out std_logic_vector(4 downto 0);
				
				CART_ADDR: in std_logic_vector(12 downto 0);
				CART_DATA: inout std_logic_vector(7 downto 0);
				CART_RD5: out std_logic;
				CART_RD4: out std_logic;
				CART_S5: in std_logic;
				CART_S4: in std_logic;
				CART_PHI2: in std_logic;
				CART_CTL: in std_logic;
				CART_RW: in std_logic;
				
				SD_CARD_cs: out std_logic;
				SD_CARD_sclk: out std_logic;
				SD_CARD_mosi: out std_logic;
				SD_CARD_miso: in std_logic;
				
				EXT_SRAM_ADDR: out std_logic_vector(19 downto 0);
				EXT_SRAM_DATA: inout std_logic_vector(7 downto 0);
				EXT_SRAM_CE: out std_logic;
				EXT_SRAM_OE: out std_logic;
				EXT_SRAM_WE: out std_logic
			);
END atari_rom;

ARCHITECTURE structure OF atari_rom IS
	constant CART_TYPE_BOOT	: integer := 0;
	constant CART_TYPE_8K	: integer := 1;
	constant CART_TYPE_16K	: integer := 2;
	constant CART_TYPE_ATARIMAX_1MBIT : integer := 3;
	constant CART_TYPE_ATARIMAX_8MBIT : integer := 4;
	constant CART_TYPE_XEGS_32K : integer := 5;
	constant CART_TYPE_XEGS_64K : integer := 6;
	constant CART_TYPE_XEGS_128K : integer := 7;
	constant CART_TYPE_XEGS_256K : integer := 8;
	constant CART_TYPE_XEGS_512K : integer := 9;
	constant CART_TYPE_XEGS_1024K : integer := 10;
	constant CART_TYPE_SW_XEGS_32K : integer := 11;
	constant CART_TYPE_SW_XEGS_64K : integer := 12;
	constant CART_TYPE_SW_XEGS_128K : integer := 13;
	constant CART_TYPE_SW_XEGS_256K : integer := 14;
	constant CART_TYPE_SW_XEGS_512K : integer := 15;
	constant CART_TYPE_SW_XEGS_1024K : integer := 16;
	constant CART_TYPE_MEGACART_16K : integer := 17;
	constant CART_TYPE_MEGACART_32K : integer := 18;
	constant CART_TYPE_MEGACART_64K : integer := 19;
	constant CART_TYPE_MEGACART_128K : integer := 20;
	constant CART_TYPE_MEGACART_256K : integer := 21;
	constant CART_TYPE_MEGACART_512K : integer := 22;
	constant CART_TYPE_MEGACART_1024K : integer := 23;
	constant CART_TYPE_BOUNTY_BOB : integer := 24;
	constant CART_TYPE_WILLIAMS_64K : integer := 25;
	constant CART_TYPE_OSS_16K_034M	: integer :=  26;
	constant CART_TYPE_OSS_16K_043M : integer := 27;
	constant CART_TYPE_OSS_16K_TYPE_B : integer := 28;
	constant CART_TYPE_OSS_8K : integer := 29;
	constant CART_TYPE_SIC : integer := 30;
	constant CART_TYPE_SDX_64K : integer := 31;
	constant CART_TYPE_DIAMOND_64K : integer := 32;
	constant CART_TYPE_EXPRESS_64K : integer := 33;
	constant CART_TYPE_SDX_128K : integer := 34;
	constant CART_TYPE_BLIZZARD_16K : integer := 35;
	constant CART_TYPE_NONE	: integer := 255;

	signal fpga_data_out : std_logic_vector (7 downto 0);
	signal sram_data_out : std_logic_vector (7 downto 0);
	signal data_out : std_logic_vector (7 downto 0);
	
	signal fpga_address_in : std_logic_vector (12 downto 0);
	signal sram_address_in : std_logic_vector (19 downto 0);
	
	signal cart_type_in: std_logic_vector (7 downto 0);
	signal cart_type: integer range 0 to 255 := CART_TYPE_BOOT;
	
	signal sram_cart_bus_enabled: std_logic;
	signal sram_ce: std_logic;
	
	signal nios_led_out: std_logic_vector(4 downto 0);
	
	-- High (0xA000) / Low (0x8000) cartridge bank enable flags
	signal high_bank_enabled: std_logic := '1';
	signal low_bank_enabled: std_logic := '0';
	
	signal bank_out: std_logic_vector (6 downto 0);
	
	-- Used for sending data from atari to FPGA/NIOS cpu
	signal atari_d500_byte: std_logic_vector(7 downto 0) := "00000000";
	signal reset_d500_byte: std_logic;
	
	-- Bounty bob cartridge selected 4k banks
	signal bounty_bob_bank8 : std_logic_vector (1 downto 0);
	signal bounty_bob_bank9 : std_logic_vector (1 downto 0);

	-- OSS 4k banks
	signal oss_bank : std_logic_vector (1 downto 0);
	
	-- SIC d500 byte
	signal sic_d500_byte : std_logic_vector(7 downto 0);
	signal sic_read_d500 : boolean := false;
	
	-- Register some cartridge bus signals on the rising edge
	signal cart_addr_reg : std_logic_vector (12 downto 0);
	signal cart_ctl_reg : std_logic := '1';
	signal cart_s4_reg : std_logic := '1';
	signal cart_s5_reg : std_logic := '1';
	signal cart_rw_reg : std_logic := '1';
	
	signal cart_data_reg : std_logic_vector(7 downto 0);
	signal count: integer range 0 to 255;
	
	component host is
		port (
			cart_memory_s2_address            : in    std_logic_vector(12 downto 0) := (others => 'X'); -- address
			cart_memory_s2_chipselect         : in    std_logic                     := 'X';             -- chipselect
			cart_memory_s2_clken              : in    std_logic                     := 'X';             -- clken
			cart_memory_s2_write              : in    std_logic                     := 'X';             -- write
			cart_memory_s2_readdata           : out   std_logic_vector(7 downto 0);                     -- readdata
			cart_memory_s2_writedata          : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- writedata
			clk_clk                           : in    std_logic                     := 'X';             -- clk
			ext_sram_atari_bus_driven_export  : in    std_logic                     := 'X';             -- atari_bus_driven_export
			ext_sram_atari_sram_addr_export   : in    std_logic_vector(19 downto 0) := (others => 'X'); -- atari_sram_addr_export
			ext_sram_atari_sram_data_export   : out   std_logic_vector(7 downto 0);                     -- atari_sram_data_export
			ext_sram_atari_sram_enable_export : in    std_logic                     := 'X';             -- atari_sram_enable_export
			ext_sram_sram_addr_export         : out   std_logic_vector(19 downto 0);                    -- sram_addr_export
			ext_sram_sram_dq_export           : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- sram_dq_export
			ext_sram_sram_ce_export           : out   std_logic;                                        -- sram_ce_export
			ext_sram_sram_oe_n_export         : out   std_logic;                                        -- sram_oe_n_export
			ext_sram_sram_we_n_export         : out   std_logic;                                        -- sram_we_n_export
			led_external_connection_export    : out   std_logic_vector(4 downto 0);                     -- export
			sel_cartridge_type_export         : out   std_logic_vector(7 downto 0);                     -- export
			reset_reset_n                     : in    std_logic                     := 'X';             -- reset_n
			spi_master_0_cs                   : out   std_logic;                                        -- cs
			spi_master_0_sclk                 : out   std_logic;                                        -- sclk
			spi_master_0_mosi                 : out   std_logic;                                        -- mosi
			spi_master_0_miso                 : in    std_logic                     := 'X';             -- miso
			spi_master_0_cd                   : in    std_logic                     := 'X';             -- cd
			spi_master_0_wp                   : in    std_logic                     := 'X';             -- wp
			atari_d500_byte_export            : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			reset_d500_export                 : out   std_logic                                         -- export
		);
	end component host;
	

BEGIN

	u0 : component host
		port map (
			clk_clk                        => CLK,
			led_external_connection_export => nios_led_out,
			reset_reset_n                  => '1',
			cart_memory_s2_address         => fpga_address_in,
			cart_memory_s2_chipselect      => '1',
			cart_memory_s2_clken           => '1',
			cart_memory_s2_write           => '0',
			cart_memory_s2_readdata        => fpga_data_out,
			cart_memory_s2_writedata       => "ZZZZZZZZ",
			ext_sram_sram_addr_export      => EXT_SRAM_ADDR,
			ext_sram_sram_ce_export        => EXT_SRAM_CE,
			ext_sram_sram_oe_n_export      => EXT_SRAM_OE,
			ext_sram_sram_we_n_export      => EXT_SRAM_WE,
			ext_sram_sram_dq_export        => EXT_SRAM_DATA,
			ext_sram_atari_bus_driven_export => sram_cart_bus_enabled,
			ext_sram_atari_sram_addr_export => sram_address_in,
			ext_sram_atari_sram_data_export => sram_data_out,
			ext_sram_atari_sram_enable_export => sram_ce,
			sel_cartridge_type_export 		 => cart_type_in,
			spi_master_0_cs                => SD_CARD_cs,
			spi_master_0_sclk              => SD_CARD_sclk,
			spi_master_0_mosi              => SD_CARD_mosi,
			spi_master_0_miso              => SD_CARD_miso,
			spi_master_0_cd                => '0',
			spi_master_0_wp                => '0',
			atari_d500_byte_export         => atari_d500_byte,
			reset_d500_export              => reset_d500_byte
		);
		
	CART_RD5 <= high_bank_enabled;
	CART_RD4 <= low_bank_enabled;
	
	CART_DATA <= data_out when (CART_S5 = '0' or CART_S4 = '0' or (CART_CTL = '0' and sic_read_d500))
					 else "ZZZZZZZZ";
	
	sram_cart_bus_enabled <= '0' when cart_type = CART_TYPE_BOOT else '1';
	LED <= nios_led_out when cart_type = CART_TYPE_BOOT else "0000" & not (high_bank_enabled or low_bank_enabled);
	
	-- store the cartridge bus address on rising edge of phi2
	-- since it may be invalid by the falling edge (outside spec 6502s)
	process (CART_PHI2)
	begin
		if (rising_edge(CART_PHI2)) then
			cart_addr_reg <= CART_ADDR;
			cart_ctl_reg <= CART_CTL;
			cart_s4_reg <= CART_S4;
			cart_s5_reg <= CART_S5;
			cart_rw_reg <= CART_RW;
			-- SIC D500-D51F read ?
			sic_read_d500 <= (cart_type = CART_TYPE_SIC and CART_CTL = '0'
									and CART_RW = '1' and CART_ADDR(7 downto 5) = "000");
		end if;
	end process;

	-- the cartridge data bus appears to be invalid on the falling edge of phi2 on some XLs
	-- so sample it approx 160ms after the rising edge (about 80ms before falling edge)
	process (CLK)
	begin
		if (CART_PHI2 = '0') then
			count <= 0;
		else
			if (rising_edge(CLK)) then
				count <= count + 1;
				if (count = 8) then
					cart_data_reg <= CART_DATA;
				end if;
			end if;
		end if;
	end process;
	
	process (CART_PHI2, reset_d500_byte)
		variable new_cart_type : integer;
	begin
		if (reset_d500_byte = '1') then
			atari_d500_byte <= "00000000";
		else
			if (falling_edge(CART_PHI2)) then
				-- uses _reg signals (captured on rising edge) in place of actual cartridge signals (except data bus)
				
				-- Change of cartridge type?
				if (cart_type /= to_integer(unsigned(cart_type_in))) then
					new_cart_type := to_integer(unsigned(cart_type_in));
					-- Default to high bank only
					low_bank_enabled <= '0';
					high_bank_enabled <= '1';
					bank_out <= "0000000";
					-- Cartridge type specific initialisation
					if (new_cart_type = CART_TYPE_NONE) then
						high_bank_enabled <= '0';
					elsif (new_cart_type = CART_TYPE_16K or new_cart_type = CART_TYPE_BLIZZARD_16K) then
						low_bank_enabled <= '1';
					elsif (new_cart_type = CART_TYPE_ATARIMAX_8MBIT) then
						bank_out <= "1111111";
					elsif (new_cart_type >= CART_TYPE_XEGS_32K and new_cart_type <= CART_TYPE_XEGS_1024K) then
						low_bank_enabled <= '1';
					elsif (new_cart_type >= CART_TYPE_SW_XEGS_32K and new_cart_type <= CART_TYPE_SW_XEGS_1024K) then
						low_bank_enabled <= '1';
					elsif (new_cart_type >= CART_TYPE_MEGACART_16K and new_cart_type <= CART_TYPE_MEGACART_1024K) then
						low_bank_enabled <= '1';
					elsif (new_cart_type = CART_TYPE_BOUNTY_BOB) then
						low_bank_enabled <= '1';
						bounty_bob_bank8 <= "00";
						bounty_bob_bank9 <= "00";
					elsif (new_cart_type = CART_TYPE_OSS_16K_TYPE_B or new_cart_type = CART_TYPE_OSS_8K) then
						oss_bank <= "01";
					elsif (new_cart_type = CART_TYPE_OSS_16K_034M or new_cart_type = CART_TYPE_OSS_16K_043M) then
						oss_bank <= "00";
					elsif (new_cart_type = CART_TYPE_SIC) then
						low_bank_enabled <= '1';
						sic_d500_byte <= (others => '0');
					end if;
					cart_type <= new_cart_type;
				end if;
				
				-- CCTL set?
				if (cart_ctl_reg = '0') then
					case cart_type is
						-- boot ROM 
						when CART_TYPE_BOOT =>
							if (cart_addr_reg(7 downto 0) = x"10") then
								-- restrict to D510 only for compatability with Ultimate 1meg
								atari_d500_byte <= cart_data_reg;
							end if;
						-- atarimax 1mbit bankswitching
						when CART_TYPE_ATARIMAX_1MBIT =>
							if (cart_addr_reg(7 downto 5) = "000") then
								high_bank_enabled <= not cart_addr_reg(4);
								bank_out <= "000" & cart_addr_reg(3 downto 0);
							end if;
						-- atarimax 8mbit bankswitching
						when CART_TYPE_ATARIMAX_8MBIT => 
							high_bank_enabled <= not cart_addr_reg(7);
							bank_out <= cart_addr_reg(6 downto 0);
						-- xegs carts - schematic has RW as NC
						when CART_TYPE_XEGS_32K => bank_out <= "00000" & cart_data_reg(1 downto 0);
						when CART_TYPE_XEGS_64K => bank_out <= "0000" & cart_data_reg(2 downto 0);
						when CART_TYPE_XEGS_128K => bank_out <= "000" & cart_data_reg(3 downto 0);
						when CART_TYPE_XEGS_256K => bank_out <= "00" & cart_data_reg(4 downto 0);
						when CART_TYPE_XEGS_512K => bank_out <= "0" & cart_data_reg(5 downto 0);
						when CART_TYPE_XEGS_1024K => bank_out <= cart_data_reg(6 downto 0);
						-- williams
						when CART_TYPE_WILLIAMS_64K =>
							if (cart_addr_reg(7 downto 4) = "0000") then
								high_bank_enabled <= not cart_addr_reg(3);
								bank_out <= "0000" & cart_addr_reg(2 downto 0);
							end if;
						-- oss type b 16k/8k
						when CART_TYPE_OSS_16K_TYPE_B | CART_TYPE_OSS_8K =>
							high_bank_enabled <= not (cart_addr_reg(3) and not cart_addr(0));
							if (cart_addr_reg(0) = '0' and cart_addr_reg(3) = '0') then
								oss_bank <= "01";
							elsif (cart_addr_reg(0) = '1' and cart_addr_reg(3) = '1') then
								oss_bank <= "10";
							elsif (cart_addr_reg(0) = '1' and cart_addr_reg(3) = '0') then
								oss_bank <= "11";
							end if;
						-- oss 043M
						when CART_TYPE_OSS_16K_043M =>
							high_bank_enabled <= not cart_addr_reg(3);
							case cart_addr_reg(2 downto 0) is
								when "000" => oss_bank <= "00";
								when "011" | "111" => oss_bank <= "10";
								when "100" => oss_bank <= "01";
								when others => null;
							end case;
						-- oss 043M
						when CART_TYPE_OSS_16K_034M =>
							high_bank_enabled <= not cart_addr_reg(3);
							case cart_addr_reg(2 downto 0) is
								when "000" => oss_bank <= "00";
								when "011" | "111" => oss_bank <= "01";
								when "100" => oss_bank <= "10";
								when others => null;
							end case;
						-- sdx 64
						when CART_TYPE_SDX_64K =>
							if (cart_addr_reg(7 downto 4) = x"E") then
								high_bank_enabled <= not cart_addr_reg(3);
								bank_out <= "0000" & not cart_addr_reg(2 downto 0);
							end if;
						when CART_TYPE_DIAMOND_64K =>
							if (cart_addr_reg(7 downto 4) = x"D") then
								high_bank_enabled <= not cart_addr_reg(3);
								bank_out <= "0000" & not cart_addr_reg(2 downto 0);
							end if;
						when CART_TYPE_EXPRESS_64K =>
							if (cart_addr_reg(7 downto 4) = x"7") then
								high_bank_enabled <= not cart_addr_reg(3);
								bank_out <= "0000" & not cart_addr_reg(2 downto 0);
							end if;
						when CART_TYPE_SDX_128K =>
							if (cart_addr_reg(7 downto 4) = x"F") then
								high_bank_enabled <= not cart_addr_reg(3);
								bank_out <= "0000" & not cart_addr_reg(2 downto 0);
							end if;
							if (cart_addr_reg(7 downto 4) = x"E") then
								high_bank_enabled <= not cart_addr_reg(3);
								bank_out <= "0001" & not cart_addr_reg(2 downto 0);
							end if;
						when CART_TYPE_BLIZZARD_16K =>
							high_bank_enabled <= '0';
							low_bank_enabled <= '0';
						when others => null;
					end case;
					
					-- carts that require a data write
					if (cart_rw_reg = '0') then
						case cart_type is
							-- switchable xegs
							when CART_TYPE_SW_XEGS_32K => bank_out <= "00000" & cart_data_reg(1 downto 0);
							when CART_TYPE_SW_XEGS_64K => bank_out <= "0000" & cart_data_reg(2 downto 0);
							when CART_TYPE_SW_XEGS_128K => bank_out <= "000" & cart_data_reg(3 downto 0);
							when CART_TYPE_SW_XEGS_256K => bank_out <= "00" & cart_data_reg(4 downto 0);
							when CART_TYPE_SW_XEGS_512K => bank_out <= "0" & cart_data_reg(5 downto 0);
							when CART_TYPE_SW_XEGS_1024K => bank_out <= cart_data_reg(6 downto 0);
							-- megacart
							when CART_TYPE_MEGACART_32K => bank_out <= "000000" & cart_data_reg(0);
							when CART_TYPE_MEGACART_64K => bank_out <= "00000" & cart_data_reg(1 downto 0);
							when CART_TYPE_MEGACART_128K => bank_out <= "0000" & cart_data_reg(2 downto 0);
							when CART_TYPE_MEGACART_256K => bank_out <= "000" & cart_data_reg(3 downto 0);
							when CART_TYPE_MEGACART_512K => bank_out <= "00" & cart_data_reg(4 downto 0);
							when CART_TYPE_MEGACART_1024K => bank_out <= "0" & cart_data_reg(5 downto 0);
							-- sic (all sizes)
							when CART_TYPE_SIC =>
								if (cart_addr_reg(7 downto 5) = "000") then
									high_bank_enabled <= not cart_data_reg(6);
									low_bank_enabled <= cart_data_reg(5);
									bank_out <= "00" & cart_data_reg(4 downto 0);
									sic_d500_byte <= cart_data_reg;
								end if;
							when others => null;
						end case;
						
						-- switchable XEGS or megacart disable/enable
						if (cart_type >= CART_TYPE_SW_XEGS_32K and cart_type <= CART_TYPE_SW_XEGS_1024K) then
							high_bank_enabled <= not cart_data_reg(7);
							low_bank_enabled <= not cart_data_reg(7);
						end if;
						if (cart_type >= CART_TYPE_MEGACART_16K and cart_type <= CART_TYPE_MEGACART_1024K) then
							high_bank_enabled <= not cart_data_reg(7);
							low_bank_enabled <= not cart_data_reg(7);
						end if;
						
					end if; -- (cart_rw_reg = '0')
					
				end if; -- (cart_ctl_reg = '0')
				
				-- bounty bob looks for specific accesses to the low bank
				if (cart_type = CART_TYPE_BOUNTY_BOB and cart_s4_reg = '0') then
					case ("000" & cart_addr_reg) is
						when X"0FF6" => bounty_bob_bank8 <= "00";
						when X"0FF7" => bounty_bob_bank8 <= "01";
						when X"0FF8" => bounty_bob_bank8 <= "10";
						when X"0FF9" => bounty_bob_bank8 <= "11";
						when X"1FF6" => bounty_bob_bank9 <= "00";
						when X"1FF7" => bounty_bob_bank9 <= "01";
						when X"1FF8" => bounty_bob_bank9 <= "10";
						when X"1FF9" => bounty_bob_bank9 <= "11";
						when others => null;
					end case;
				end if;
				
			end if; -- falling_edge(CART_PHI2)
		end if;
	end process;
	
	-- When we get a new address from the cartridge port, set up the RAM address bus
	-- to get the correct data
	process (cart_addr_reg, cart_s4_reg, cart_s5_reg, cart_ctl_reg,
				cart_type, bank_out, bounty_bob_bank8, bounty_bob_bank9, oss_bank)
	begin
		fpga_address_in <= (others => '0');
		sram_address_in <= (others => '0');
		sram_ce <= '0';
		
		if (cart_type = CART_TYPE_BOOT) then
			fpga_address_in <= cart_addr_reg;
			
		elsif (cart_type /= CART_TYPE_NONE) then
		
			if (cart_s5_reg = '0' or cart_s4_reg = '0') then
				sram_ce <= '1';
			end if;
			
			-- default case
			sram_address_in <= bank_out & cart_addr_reg;

			-- special cases (i.e. cartridges mapping both banks)
			case cart_type is
				when CART_TYPE_16K | CART_TYPE_BLIZZARD_16K =>
					if (cart_s4_reg = '0') then 
						sram_address_in <= "0000000" & cart_addr_reg;
					else
						sram_address_in <= "0000001" & cart_addr_reg;
					end if;
				when CART_TYPE_XEGS_32K | CART_TYPE_SW_XEGS_32K =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "0000011" & cart_addr_reg;
					end if;
				when CART_TYPE_XEGS_64K | CART_TYPE_SW_XEGS_64K =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "0000111" & cart_addr_reg;
					end if;
				when CART_TYPE_XEGS_128K | CART_TYPE_SW_XEGS_128K =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "0001111" & cart_addr_reg;
					end if;
				when CART_TYPE_XEGS_256K | CART_TYPE_SW_XEGS_256K =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "0011111" & cart_addr_reg;
					end if;
				when CART_TYPE_XEGS_512K | CART_TYPE_SW_XEGS_512K =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "0111111" & cart_addr_reg;
					end if;
				when CART_TYPE_XEGS_1024K | CART_TYPE_SW_XEGS_1024K =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "1111111" & cart_addr_reg;
					end if;
				when CART_TYPE_BOUNTY_BOB =>
					if (cart_s5_reg = '0') then
						sram_address_in <= "0000100" & cart_addr_reg;
					else
						if (cart_addr_reg(12) = '0') then
							sram_address_in <= "000000" & bounty_bob_bank8 & cart_addr_reg(11 downto 0); -- 0x8000 access
						else
							sram_address_in <= "000001" & bounty_bob_bank9 & cart_addr_reg(11 downto 0); -- 0x9000 access
						end if;
					end if;
				when CART_TYPE_OSS_16K_TYPE_B | CART_TYPE_OSS_8K =>
					if (cart_addr_reg(12) = '0') then
						if (cart_type = CART_TYPE_OSS_8K) then
							sram_address_in <= "0000000" & oss_bank(0) & cart_addr_reg(11 downto 0); -- 8k, 0xA000 access
						else
							sram_address_in <= "000000" & oss_bank & cart_addr_reg(11 downto 0); -- 16k, 0xA000 access
						end if;
					else
						sram_address_in <= "00000000" & cart_addr_reg(11 downto 0); -- 0xB000 access
					end if;
				when CART_TYPE_OSS_16K_034M | CART_TYPE_OSS_16K_043M =>
					if (cart_addr_reg(12) = '0') then
						sram_address_in <= "000000" & oss_bank & cart_addr_reg(11 downto 0); -- 16k, 0xA000 access
					else
						sram_address_in <= "00000011" & cart_addr_reg(11 downto 0); -- 0xB000 access
					end if;
				when CART_TYPE_SIC | CART_TYPE_MEGACART_16K | CART_TYPE_MEGACART_32K | CART_TYPE_MEGACART_64K |
						CART_TYPE_MEGACART_128K | CART_TYPE_MEGACART_256K | CART_TYPE_MEGACART_512K | CART_TYPE_MEGACART_1024K =>
					if (cart_s4_reg = '0') then
						sram_address_in <= bank_out(5 downto 0) & "0" & cart_addr_reg;
					else
						sram_address_in <= bank_out(5 downto 0) & "1" & cart_addr_reg;
					end if;
				when others => null;
			end case;
			
		end if; -- cart_type /= CART_TYPE_NONE
	end process;

	-- When we get new data from RAM, pass it on to the cartridge port
	process (fpga_data_out, sram_data_out, cart_type, sic_read_d500)
	begin
		case cart_type is
			when CART_TYPE_NONE => data_out <= "00000000";
			when CART_TYPE_BOOT => data_out <= fpga_data_out;
			when others => data_out <= sram_data_out;
		end case;
		if (sic_read_d500) then
			data_out <= sic_d500_byte;
		end if;
	end process;
	
END structure;
