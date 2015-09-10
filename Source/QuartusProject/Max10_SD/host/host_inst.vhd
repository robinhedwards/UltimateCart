	component host is
		port (
			atari_d500_byte_export            : in    std_logic_vector(7 downto 0)  := (others => 'X'); -- export
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
			reset_reset_n                     : in    std_logic                     := 'X';             -- reset_n
			reset_d500_export                 : out   std_logic;                                        -- export
			sel_cartridge_type_export         : out   std_logic_vector(7 downto 0);                     -- export
			spi_master_0_cs                   : out   std_logic;                                        -- cs
			spi_master_0_sclk                 : out   std_logic;                                        -- sclk
			spi_master_0_mosi                 : out   std_logic;                                        -- mosi
			spi_master_0_miso                 : in    std_logic                     := 'X';             -- miso
			spi_master_0_cd                   : in    std_logic                     := 'X';             -- cd
			spi_master_0_wp                   : in    std_logic                     := 'X'              -- wp
		);
	end component host;

	u0 : component host
		port map (
			atari_d500_byte_export            => CONNECTED_TO_atari_d500_byte_export,            --         atari_d500_byte.export
			cart_memory_s2_address            => CONNECTED_TO_cart_memory_s2_address,            --          cart_memory_s2.address
			cart_memory_s2_chipselect         => CONNECTED_TO_cart_memory_s2_chipselect,         --                        .chipselect
			cart_memory_s2_clken              => CONNECTED_TO_cart_memory_s2_clken,              --                        .clken
			cart_memory_s2_write              => CONNECTED_TO_cart_memory_s2_write,              --                        .write
			cart_memory_s2_readdata           => CONNECTED_TO_cart_memory_s2_readdata,           --                        .readdata
			cart_memory_s2_writedata          => CONNECTED_TO_cart_memory_s2_writedata,          --                        .writedata
			clk_clk                           => CONNECTED_TO_clk_clk,                           --                     clk.clk
			ext_sram_atari_bus_driven_export  => CONNECTED_TO_ext_sram_atari_bus_driven_export,  --                ext_sram.atari_bus_driven_export
			ext_sram_atari_sram_addr_export   => CONNECTED_TO_ext_sram_atari_sram_addr_export,   --                        .atari_sram_addr_export
			ext_sram_atari_sram_data_export   => CONNECTED_TO_ext_sram_atari_sram_data_export,   --                        .atari_sram_data_export
			ext_sram_atari_sram_enable_export => CONNECTED_TO_ext_sram_atari_sram_enable_export, --                        .atari_sram_enable_export
			ext_sram_sram_addr_export         => CONNECTED_TO_ext_sram_sram_addr_export,         --                        .sram_addr_export
			ext_sram_sram_dq_export           => CONNECTED_TO_ext_sram_sram_dq_export,           --                        .sram_dq_export
			ext_sram_sram_ce_export           => CONNECTED_TO_ext_sram_sram_ce_export,           --                        .sram_ce_export
			ext_sram_sram_oe_n_export         => CONNECTED_TO_ext_sram_sram_oe_n_export,         --                        .sram_oe_n_export
			ext_sram_sram_we_n_export         => CONNECTED_TO_ext_sram_sram_we_n_export,         --                        .sram_we_n_export
			led_external_connection_export    => CONNECTED_TO_led_external_connection_export,    -- led_external_connection.export
			reset_reset_n                     => CONNECTED_TO_reset_reset_n,                     --                   reset.reset_n
			reset_d500_export                 => CONNECTED_TO_reset_d500_export,                 --              reset_d500.export
			sel_cartridge_type_export         => CONNECTED_TO_sel_cartridge_type_export,         --      sel_cartridge_type.export
			spi_master_0_cs                   => CONNECTED_TO_spi_master_0_cs,                   --            spi_master_0.cs
			spi_master_0_sclk                 => CONNECTED_TO_spi_master_0_sclk,                 --                        .sclk
			spi_master_0_mosi                 => CONNECTED_TO_spi_master_0_mosi,                 --                        .mosi
			spi_master_0_miso                 => CONNECTED_TO_spi_master_0_miso,                 --                        .miso
			spi_master_0_cd                   => CONNECTED_TO_spi_master_0_cd,                   --                        .cd
			spi_master_0_wp                   => CONNECTED_TO_spi_master_0_wp                    --                        .wp
		);

