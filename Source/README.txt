The Quartus project needs Quartus II 15.1 or above.

Some notes
==========
You should be able to just compile to product a valid sof file.
To generate a pof from the sof file, select File/Convert Programming Files, then Mode: Internal Configuration.

The nios cpu build files are in the host directory, but can be regenerated from the host.qsys project.

The boot_rom.hex file can be updated with a new Atari 8k boot ROM file (see Source/AtariBootROM).
Do Processing/Update Memory Initialization File then Re-assemble after doing this.

To change the fpga Nios firmware, use Nios II software build tools for Eclipse. Both sdcard and sdcard_bsp projects need to be added to the workspace.
Make Targets/Build/mem_init_generate will generate the firmware hex file.
Then do Processing/Update Memory Initialization File and Re-assemble after doing this.

You can also debug the firmware in Eclipse with using the JTAG UART. Run as/Nios II Hardware and the console will display debug output.

