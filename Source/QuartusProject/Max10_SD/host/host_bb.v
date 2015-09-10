
module host (
	atari_d500_byte_export,
	cart_memory_s2_address,
	cart_memory_s2_chipselect,
	cart_memory_s2_clken,
	cart_memory_s2_write,
	cart_memory_s2_readdata,
	cart_memory_s2_writedata,
	clk_clk,
	ext_sram_atari_bus_driven_export,
	ext_sram_atari_sram_addr_export,
	ext_sram_atari_sram_data_export,
	ext_sram_atari_sram_enable_export,
	ext_sram_sram_addr_export,
	ext_sram_sram_dq_export,
	ext_sram_sram_ce_export,
	ext_sram_sram_oe_n_export,
	ext_sram_sram_we_n_export,
	led_external_connection_export,
	reset_reset_n,
	reset_d500_export,
	sel_cartridge_type_export,
	spi_master_0_cs,
	spi_master_0_sclk,
	spi_master_0_mosi,
	spi_master_0_miso,
	spi_master_0_cd,
	spi_master_0_wp);	

	input	[7:0]	atari_d500_byte_export;
	input	[12:0]	cart_memory_s2_address;
	input		cart_memory_s2_chipselect;
	input		cart_memory_s2_clken;
	input		cart_memory_s2_write;
	output	[7:0]	cart_memory_s2_readdata;
	input	[7:0]	cart_memory_s2_writedata;
	input		clk_clk;
	input		ext_sram_atari_bus_driven_export;
	input	[19:0]	ext_sram_atari_sram_addr_export;
	output	[7:0]	ext_sram_atari_sram_data_export;
	input		ext_sram_atari_sram_enable_export;
	output	[19:0]	ext_sram_sram_addr_export;
	inout	[7:0]	ext_sram_sram_dq_export;
	output		ext_sram_sram_ce_export;
	output		ext_sram_sram_oe_n_export;
	output		ext_sram_sram_we_n_export;
	output	[4:0]	led_external_connection_export;
	input		reset_reset_n;
	output		reset_d500_export;
	output	[7:0]	sel_cartridge_type_export;
	output		spi_master_0_cs;
	output		spi_master_0_sclk;
	output		spi_master_0_mosi;
	input		spi_master_0_miso;
	input		spi_master_0_cd;
	input		spi_master_0_wp;
endmodule
