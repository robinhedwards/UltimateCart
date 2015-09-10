/*
 * system.h - SOPC Builder system and BSP software package information
 *
 * Machine generated for CPU 'cpu' in SOPC Builder design 'host'
 * SOPC Builder design path: ../../host.sopcinfo
 *
 * Generated: Thu Sep 10 18:20:21 BST 2015
 */

/*
 * DO NOT MODIFY THIS FILE
 *
 * Changing this file will have subtle consequences
 * which will almost certainly lead to a nonfunctioning
 * system. If you do modify this file, be aware that your
 * changes will be overwritten and lost when this file
 * is generated again.
 *
 * DO NOT MODIFY THIS FILE
 */

/*
 * License Agreement
 *
 * Copyright (c) 2008
 * Altera Corporation, San Jose, California, USA.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * This agreement shall be governed in all respects by the laws of the State
 * of California and by the laws of the United States of America.
 */

#ifndef __SYSTEM_H_
#define __SYSTEM_H_

/* Include definitions from linker script generator */
#include "linker.h"


/*
 * CPU configuration
 *
 */

#define ALT_CPU_ARCHITECTURE "altera_nios2_qsys"
#define ALT_CPU_BIG_ENDIAN 0
#define ALT_CPU_BREAK_ADDR 0x00214820
#define ALT_CPU_CPU_FREQ 50000000u
#define ALT_CPU_CPU_ID_SIZE 1
#define ALT_CPU_CPU_ID_VALUE 0x00000000
#define ALT_CPU_CPU_IMPLEMENTATION "tiny"
#define ALT_CPU_DATA_ADDR_WIDTH 0x16
#define ALT_CPU_DCACHE_LINE_SIZE 0
#define ALT_CPU_DCACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_DCACHE_SIZE 0
#define ALT_CPU_EXCEPTION_ADDR 0x00208020
#define ALT_CPU_FLUSHDA_SUPPORTED
#define ALT_CPU_FREQ 50000000
#define ALT_CPU_HARDWARE_DIVIDE_PRESENT 0
#define ALT_CPU_HARDWARE_MULTIPLY_PRESENT 0
#define ALT_CPU_HARDWARE_MULX_PRESENT 0
#define ALT_CPU_HAS_DEBUG_CORE 1
#define ALT_CPU_HAS_DEBUG_STUB
#define ALT_CPU_HAS_JMPI_INSTRUCTION
#define ALT_CPU_ICACHE_LINE_SIZE 0
#define ALT_CPU_ICACHE_LINE_SIZE_LOG2 0
#define ALT_CPU_ICACHE_SIZE 0
#define ALT_CPU_INST_ADDR_WIDTH 0x16
#define ALT_CPU_NAME "cpu"
#define ALT_CPU_RESET_ADDR 0x00208000


/*
 * CPU configuration (with legacy prefix - don't use these anymore)
 *
 */

#define NIOS2_BIG_ENDIAN 0
#define NIOS2_BREAK_ADDR 0x00214820
#define NIOS2_CPU_FREQ 50000000u
#define NIOS2_CPU_ID_SIZE 1
#define NIOS2_CPU_ID_VALUE 0x00000000
#define NIOS2_CPU_IMPLEMENTATION "tiny"
#define NIOS2_DATA_ADDR_WIDTH 0x16
#define NIOS2_DCACHE_LINE_SIZE 0
#define NIOS2_DCACHE_LINE_SIZE_LOG2 0
#define NIOS2_DCACHE_SIZE 0
#define NIOS2_EXCEPTION_ADDR 0x00208020
#define NIOS2_FLUSHDA_SUPPORTED
#define NIOS2_HARDWARE_DIVIDE_PRESENT 0
#define NIOS2_HARDWARE_MULTIPLY_PRESENT 0
#define NIOS2_HARDWARE_MULX_PRESENT 0
#define NIOS2_HAS_DEBUG_CORE 1
#define NIOS2_HAS_DEBUG_STUB
#define NIOS2_HAS_JMPI_INSTRUCTION
#define NIOS2_ICACHE_LINE_SIZE 0
#define NIOS2_ICACHE_LINE_SIZE_LOG2 0
#define NIOS2_ICACHE_SIZE 0
#define NIOS2_INST_ADDR_WIDTH 0x16
#define NIOS2_RESET_ADDR 0x00208000


/*
 * Define for each module class mastered by the CPU
 *
 */

#define __ALTERA_AVALON_JTAG_UART
#define __ALTERA_AVALON_ONCHIP_MEMORY2
#define __ALTERA_AVALON_PIO
#define __ALTERA_AVALON_SYSID_QSYS
#define __ALTERA_AVALON_TIMER
#define __ALTERA_NIOS2_QSYS
#define __EXT_SRAM_CONTROLLER
#define __SPI_MASTER


/*
 * System configuration
 *
 */

#define ALT_DEVICE_FAMILY "MAX 10"
#define ALT_ENHANCED_INTERRUPT_API_PRESENT
#define ALT_IRQ_BASE NULL
#define ALT_LOG_PORT "/dev/null"
#define ALT_LOG_PORT_BASE 0x0
#define ALT_LOG_PORT_DEV null
#define ALT_LOG_PORT_TYPE ""
#define ALT_NUM_EXTERNAL_INTERRUPT_CONTROLLERS 0
#define ALT_NUM_INTERNAL_INTERRUPT_CONTROLLERS 1
#define ALT_NUM_INTERRUPT_CONTROLLERS 1
#define ALT_STDERR "/dev/jtag_uart_0"
#define ALT_STDERR_BASE 0x215088
#define ALT_STDERR_DEV jtag_uart_0
#define ALT_STDERR_IS_JTAG_UART
#define ALT_STDERR_PRESENT
#define ALT_STDERR_TYPE "altera_avalon_jtag_uart"
#define ALT_STDIN "/dev/jtag_uart_0"
#define ALT_STDIN_BASE 0x215088
#define ALT_STDIN_DEV jtag_uart_0
#define ALT_STDIN_IS_JTAG_UART
#define ALT_STDIN_PRESENT
#define ALT_STDIN_TYPE "altera_avalon_jtag_uart"
#define ALT_STDOUT "/dev/jtag_uart_0"
#define ALT_STDOUT_BASE 0x215088
#define ALT_STDOUT_DEV jtag_uart_0
#define ALT_STDOUT_IS_JTAG_UART
#define ALT_STDOUT_PRESENT
#define ALT_STDOUT_TYPE "altera_avalon_jtag_uart"
#define ALT_SYSTEM_NAME "host"


/*
 * atari_d500_byte configuration
 *
 */

#define ALT_MODULE_CLASS_atari_d500_byte altera_avalon_pio
#define ATARI_D500_BYTE_BASE 0x215050
#define ATARI_D500_BYTE_BIT_CLEARING_EDGE_REGISTER 0
#define ATARI_D500_BYTE_BIT_MODIFYING_OUTPUT_REGISTER 0
#define ATARI_D500_BYTE_CAPTURE 0
#define ATARI_D500_BYTE_DATA_WIDTH 8
#define ATARI_D500_BYTE_DO_TEST_BENCH_WIRING 0
#define ATARI_D500_BYTE_DRIVEN_SIM_VALUE 0
#define ATARI_D500_BYTE_EDGE_TYPE "NONE"
#define ATARI_D500_BYTE_FREQ 50000000
#define ATARI_D500_BYTE_HAS_IN 1
#define ATARI_D500_BYTE_HAS_OUT 0
#define ATARI_D500_BYTE_HAS_TRI 0
#define ATARI_D500_BYTE_IRQ -1
#define ATARI_D500_BYTE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define ATARI_D500_BYTE_IRQ_TYPE "NONE"
#define ATARI_D500_BYTE_NAME "/dev/atari_d500_byte"
#define ATARI_D500_BYTE_RESET_VALUE 0
#define ATARI_D500_BYTE_SPAN 16
#define ATARI_D500_BYTE_TYPE "altera_avalon_pio"


/*
 * cart_memory configuration
 *
 */

#define ALT_MODULE_CLASS_cart_memory altera_avalon_onchip_memory2
#define CART_MEMORY_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define CART_MEMORY_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define CART_MEMORY_BASE 0x212000
#define CART_MEMORY_CONTENTS_INFO ""
#define CART_MEMORY_DUAL_PORT 1
#define CART_MEMORY_GUI_RAM_BLOCK_TYPE "AUTO"
#define CART_MEMORY_INIT_CONTENTS_FILE "boot_rom"
#define CART_MEMORY_INIT_MEM_CONTENT 1
#define CART_MEMORY_INSTANCE_ID "NONE"
#define CART_MEMORY_IRQ -1
#define CART_MEMORY_IRQ_INTERRUPT_CONTROLLER_ID -1
#define CART_MEMORY_NAME "/dev/cart_memory"
#define CART_MEMORY_NON_DEFAULT_INIT_FILE_ENABLED 1
#define CART_MEMORY_RAM_BLOCK_TYPE "AUTO"
#define CART_MEMORY_READ_DURING_WRITE_MODE "DONT_CARE"
#define CART_MEMORY_SINGLE_CLOCK_OP 1
#define CART_MEMORY_SIZE_MULTIPLE 1
#define CART_MEMORY_SIZE_VALUE 8192
#define CART_MEMORY_SPAN 8192
#define CART_MEMORY_TYPE "altera_avalon_onchip_memory2"
#define CART_MEMORY_WRITABLE 1


/*
 * ext_sram_controller_0 configuration
 *
 */

#define ALT_MODULE_CLASS_ext_sram_controller_0 ext_sram_controller
#define EXT_SRAM_CONTROLLER_0_BASE 0x100000
#define EXT_SRAM_CONTROLLER_0_IRQ -1
#define EXT_SRAM_CONTROLLER_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define EXT_SRAM_CONTROLLER_0_NAME "/dev/ext_sram_controller_0"
#define EXT_SRAM_CONTROLLER_0_SPAN 1048576
#define EXT_SRAM_CONTROLLER_0_TYPE "ext_sram_controller"


/*
 * hal configuration
 *
 */

#define ALT_MAX_FD 32
#define ALT_SYS_CLK TIMER_0
#define ALT_TIMESTAMP_CLK none


/*
 * jtag_uart_0 configuration
 *
 */

#define ALT_MODULE_CLASS_jtag_uart_0 altera_avalon_jtag_uart
#define JTAG_UART_0_BASE 0x215088
#define JTAG_UART_0_IRQ 0
#define JTAG_UART_0_IRQ_INTERRUPT_CONTROLLER_ID 0
#define JTAG_UART_0_NAME "/dev/jtag_uart_0"
#define JTAG_UART_0_READ_DEPTH 64
#define JTAG_UART_0_READ_THRESHOLD 8
#define JTAG_UART_0_SPAN 8
#define JTAG_UART_0_TYPE "altera_avalon_jtag_uart"
#define JTAG_UART_0_WRITE_DEPTH 64
#define JTAG_UART_0_WRITE_THRESHOLD 8


/*
 * led configuration
 *
 */

#define ALT_MODULE_CLASS_led altera_avalon_pio
#define LED_BASE 0x215070
#define LED_BIT_CLEARING_EDGE_REGISTER 0
#define LED_BIT_MODIFYING_OUTPUT_REGISTER 0
#define LED_CAPTURE 0
#define LED_DATA_WIDTH 5
#define LED_DO_TEST_BENCH_WIRING 0
#define LED_DRIVEN_SIM_VALUE 0
#define LED_EDGE_TYPE "NONE"
#define LED_FREQ 50000000
#define LED_HAS_IN 0
#define LED_HAS_OUT 1
#define LED_HAS_TRI 0
#define LED_IRQ -1
#define LED_IRQ_INTERRUPT_CONTROLLER_ID -1
#define LED_IRQ_TYPE "NONE"
#define LED_NAME "/dev/led"
#define LED_RESET_VALUE 0
#define LED_SPAN 16
#define LED_TYPE "altera_avalon_pio"


/*
 * memory configuration
 *
 */

#define ALT_MODULE_CLASS_memory altera_avalon_onchip_memory2
#define MEMORY_ALLOW_IN_SYSTEM_MEMORY_CONTENT_EDITOR 0
#define MEMORY_ALLOW_MRAM_SIM_CONTENTS_ONLY_FILE 0
#define MEMORY_BASE 0x208000
#define MEMORY_CONTENTS_INFO ""
#define MEMORY_DUAL_PORT 0
#define MEMORY_GUI_RAM_BLOCK_TYPE "AUTO"
#define MEMORY_INIT_CONTENTS_FILE "host_memory"
#define MEMORY_INIT_MEM_CONTENT 1
#define MEMORY_INSTANCE_ID "NONE"
#define MEMORY_IRQ -1
#define MEMORY_IRQ_INTERRUPT_CONTROLLER_ID -1
#define MEMORY_NAME "/dev/memory"
#define MEMORY_NON_DEFAULT_INIT_FILE_ENABLED 0
#define MEMORY_RAM_BLOCK_TYPE "AUTO"
#define MEMORY_READ_DURING_WRITE_MODE "DONT_CARE"
#define MEMORY_SINGLE_CLOCK_OP 0
#define MEMORY_SIZE_MULTIPLE 1
#define MEMORY_SIZE_VALUE 28672
#define MEMORY_SPAN 28672
#define MEMORY_TYPE "altera_avalon_onchip_memory2"
#define MEMORY_WRITABLE 1


/*
 * reset_d500 configuration
 *
 */

#define ALT_MODULE_CLASS_reset_d500 altera_avalon_pio
#define RESET_D500_BASE 0x215040
#define RESET_D500_BIT_CLEARING_EDGE_REGISTER 0
#define RESET_D500_BIT_MODIFYING_OUTPUT_REGISTER 0
#define RESET_D500_CAPTURE 0
#define RESET_D500_DATA_WIDTH 1
#define RESET_D500_DO_TEST_BENCH_WIRING 0
#define RESET_D500_DRIVEN_SIM_VALUE 0
#define RESET_D500_EDGE_TYPE "NONE"
#define RESET_D500_FREQ 50000000
#define RESET_D500_HAS_IN 0
#define RESET_D500_HAS_OUT 1
#define RESET_D500_HAS_TRI 0
#define RESET_D500_IRQ -1
#define RESET_D500_IRQ_INTERRUPT_CONTROLLER_ID -1
#define RESET_D500_IRQ_TYPE "NONE"
#define RESET_D500_NAME "/dev/reset_d500"
#define RESET_D500_RESET_VALUE 0
#define RESET_D500_SPAN 16
#define RESET_D500_TYPE "altera_avalon_pio"


/*
 * sel_cartridge_type configuration
 *
 */

#define ALT_MODULE_CLASS_sel_cartridge_type altera_avalon_pio
#define SEL_CARTRIDGE_TYPE_BASE 0x215060
#define SEL_CARTRIDGE_TYPE_BIT_CLEARING_EDGE_REGISTER 0
#define SEL_CARTRIDGE_TYPE_BIT_MODIFYING_OUTPUT_REGISTER 0
#define SEL_CARTRIDGE_TYPE_CAPTURE 0
#define SEL_CARTRIDGE_TYPE_DATA_WIDTH 8
#define SEL_CARTRIDGE_TYPE_DO_TEST_BENCH_WIRING 0
#define SEL_CARTRIDGE_TYPE_DRIVEN_SIM_VALUE 0
#define SEL_CARTRIDGE_TYPE_EDGE_TYPE "NONE"
#define SEL_CARTRIDGE_TYPE_FREQ 50000000
#define SEL_CARTRIDGE_TYPE_HAS_IN 0
#define SEL_CARTRIDGE_TYPE_HAS_OUT 1
#define SEL_CARTRIDGE_TYPE_HAS_TRI 0
#define SEL_CARTRIDGE_TYPE_IRQ -1
#define SEL_CARTRIDGE_TYPE_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SEL_CARTRIDGE_TYPE_IRQ_TYPE "NONE"
#define SEL_CARTRIDGE_TYPE_NAME "/dev/sel_cartridge_type"
#define SEL_CARTRIDGE_TYPE_RESET_VALUE 0
#define SEL_CARTRIDGE_TYPE_SPAN 16
#define SEL_CARTRIDGE_TYPE_TYPE "altera_avalon_pio"


/*
 * spi_master_0 configuration
 *
 */

#define ALT_MODULE_CLASS_spi_master_0 spi_master
#define SPI_MASTER_0_BASE 0x215000
#define SPI_MASTER_0_IRQ -1
#define SPI_MASTER_0_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SPI_MASTER_0_NAME "/dev/spi_master_0"
#define SPI_MASTER_0_SPAN 32
#define SPI_MASTER_0_TYPE "spi_master"


/*
 * sysid_2466 configuration
 *
 */

#define ALT_MODULE_CLASS_sysid_2466 altera_avalon_sysid_qsys
#define SYSID_2466_BASE 0x215080
#define SYSID_2466_ID 9318
#define SYSID_2466_IRQ -1
#define SYSID_2466_IRQ_INTERRUPT_CONTROLLER_ID -1
#define SYSID_2466_NAME "/dev/sysid_2466"
#define SYSID_2466_SPAN 8
#define SYSID_2466_TIMESTAMP 1441905348
#define SYSID_2466_TYPE "altera_avalon_sysid_qsys"


/*
 * timer_0 configuration
 *
 */

#define ALT_MODULE_CLASS_timer_0 altera_avalon_timer
#define TIMER_0_ALWAYS_RUN 0
#define TIMER_0_BASE 0x215020
#define TIMER_0_COUNTER_SIZE 32
#define TIMER_0_FIXED_PERIOD 0
#define TIMER_0_FREQ 50000000
#define TIMER_0_IRQ 1
#define TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID 0
#define TIMER_0_LOAD_VALUE 49999
#define TIMER_0_MULT 0.001
#define TIMER_0_NAME "/dev/timer_0"
#define TIMER_0_PERIOD 1
#define TIMER_0_PERIOD_UNITS "ms"
#define TIMER_0_RESET_OUTPUT 0
#define TIMER_0_SNAPSHOT 1
#define TIMER_0_SPAN 32
#define TIMER_0_TICKS_PER_SEC 1000
#define TIMER_0_TIMEOUT_PULSE_OUTPUT 0
#define TIMER_0_TYPE "altera_avalon_timer"

#endif /* __SYSTEM_H_ */
