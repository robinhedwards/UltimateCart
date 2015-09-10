	host u0 (
		.atari_d500_byte_export            (<connected-to-atari_d500_byte_export>),            //         atari_d500_byte.export
		.cart_memory_s2_address            (<connected-to-cart_memory_s2_address>),            //          cart_memory_s2.address
		.cart_memory_s2_chipselect         (<connected-to-cart_memory_s2_chipselect>),         //                        .chipselect
		.cart_memory_s2_clken              (<connected-to-cart_memory_s2_clken>),              //                        .clken
		.cart_memory_s2_write              (<connected-to-cart_memory_s2_write>),              //                        .write
		.cart_memory_s2_readdata           (<connected-to-cart_memory_s2_readdata>),           //                        .readdata
		.cart_memory_s2_writedata          (<connected-to-cart_memory_s2_writedata>),          //                        .writedata
		.clk_clk                           (<connected-to-clk_clk>),                           //                     clk.clk
		.ext_sram_atari_bus_driven_export  (<connected-to-ext_sram_atari_bus_driven_export>),  //                ext_sram.atari_bus_driven_export
		.ext_sram_atari_sram_addr_export   (<connected-to-ext_sram_atari_sram_addr_export>),   //                        .atari_sram_addr_export
		.ext_sram_atari_sram_data_export   (<connected-to-ext_sram_atari_sram_data_export>),   //                        .atari_sram_data_export
		.ext_sram_atari_sram_enable_export (<connected-to-ext_sram_atari_sram_enable_export>), //                        .atari_sram_enable_export
		.ext_sram_sram_addr_export         (<connected-to-ext_sram_sram_addr_export>),         //                        .sram_addr_export
		.ext_sram_sram_dq_export           (<connected-to-ext_sram_sram_dq_export>),           //                        .sram_dq_export
		.ext_sram_sram_ce_export           (<connected-to-ext_sram_sram_ce_export>),           //                        .sram_ce_export
		.ext_sram_sram_oe_n_export         (<connected-to-ext_sram_sram_oe_n_export>),         //                        .sram_oe_n_export
		.ext_sram_sram_we_n_export         (<connected-to-ext_sram_sram_we_n_export>),         //                        .sram_we_n_export
		.led_external_connection_export    (<connected-to-led_external_connection_export>),    // led_external_connection.export
		.reset_reset_n                     (<connected-to-reset_reset_n>),                     //                   reset.reset_n
		.reset_d500_export                 (<connected-to-reset_d500_export>),                 //              reset_d500.export
		.sel_cartridge_type_export         (<connected-to-sel_cartridge_type_export>),         //      sel_cartridge_type.export
		.spi_master_0_cs                   (<connected-to-spi_master_0_cs>),                   //            spi_master_0.cs
		.spi_master_0_sclk                 (<connected-to-spi_master_0_sclk>),                 //                        .sclk
		.spi_master_0_mosi                 (<connected-to-spi_master_0_mosi>),                 //                        .mosi
		.spi_master_0_miso                 (<connected-to-spi_master_0_miso>),                 //                        .miso
		.spi_master_0_cd                   (<connected-to-spi_master_0_cd>),                   //                        .cd
		.spi_master_0_wp                   (<connected-to-spi_master_0_wp>)                    //                        .wp
	);

