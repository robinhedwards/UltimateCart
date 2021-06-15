/* Ultimate SD Cartridge - Atari 400/800/XL/XE Multi-Cartridge
   Copyright (C) 2015 Robin Edwards

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#include <stdio.h>
#include <string.h>
#include "io.h"
#include <system.h>
#include <sys/alt_alarm.h>
#include "system.h"

#include "pff.h"
#include "pfs_interface.h"

static alt_alarm alarm;
static unsigned long Systick = 0;
static int ledVal = 0x1E;

#define CART_TYPE_BOOT				0	// 8k
#define CART_TYPE_8K				1	// 8k
#define CART_TYPE_16K				2	// 16k
#define CART_TYPE_ATARIMAX_1MBIT	3	// 128k
#define CART_TYPE_ATARIMAX_8MBIT	4	// 1024k
#define CART_TYPE_XEGS_32K			5	// 32k
#define CART_TYPE_XEGS_64K			6	// 64k
#define CART_TYPE_XEGS_128K			7	// 128k
#define CART_TYPE_XEGS_256K			8	// 256k
#define CART_TYPE_XEGS_512K			9	// 512k
#define CART_TYPE_XEGS_1024K		10	// 1024k
#define CART_TYPE_SW_XEGS_32K		11	// 32k
#define CART_TYPE_SW_XEGS_64K		12	// 64k
#define CART_TYPE_SW_XEGS_128K		13	// 128k
#define CART_TYPE_SW_XEGS_256K		14	// 256k
#define CART_TYPE_SW_XEGS_512K		15	// 512k
#define CART_TYPE_SW_XEGS_1024K		16	// 1024k
#define CART_TYPE_MEGACART_16K		17	// 16k
#define CART_TYPE_MEGACART_32K		18	// 32k
#define CART_TYPE_MEGACART_64K		19	// 64k
#define CART_TYPE_MEGACART_128K		20	// 128k
#define CART_TYPE_MEGACART_256K		21	// 256k
#define CART_TYPE_MEGACART_512K		22	// 512k
#define CART_TYPE_MEGACART_1024K	23	// 1024k
#define CART_TYPE_BOUNTY_BOB		24	// 40k
#define CART_TYPE_WILLIAMS_64K		25	// 32,64k
#define CART_TYPE_OSS_16K_034M		26	// 16k
#define CART_TYPE_OSS_16K_043M		27	// 16k
#define CART_TYPE_OSS_16K_TYPE_B	28	// 16k
#define CART_TYPE_OSS_8K			29	// 8k
#define CART_TYPE_SIC				30	// 128k,256k,512k
#define CART_TYPE_SDX_64K			31	// 64k
#define CART_TYPE_DIAMOND_64K		32	// 64k
#define CART_TYPE_EXPRESS_64K		33	// 64k
#define CART_TYPE_SDX_128K			34	// 128k
#define CART_TYPE_BLIZZARD_16K		35	// 16k
#define CART_TYPE_TURBOSOFT 		36	// 64k,128k
#define CART_TYPE_ATRAX_128K		37	// 128k
#define CART_TYPE_XEX				254
#define CART_TYPE_NONE				255

#define CART_DIR_ENTRIES	0x1000
#define DIR_ENTRIES_PER_PAGE	20

#define CART_ERROR_BUFFER	0x1300

/* FPGA -> Atari command (in CART_CMD_BYTE)
; 0 nothing to do
; 1 atari should display new directory entries (atari sends ack back to say done)
; 2 error (message at $B300)
; 255 reboot
*/

#define CART_CMD_BYTE			0x0FF0
#define CART_CMD_IDLE			0
#define CART_CMD_DISPLAY_DIR	1
#define CART_CMD_ERROR			2
#define CART_CMD_XEX_LOADER		3
#define CART_CMD_REBOOT			255

/* Directory flag byte FGPA -> Atari
; bit 0 - more files above, bit 1 - more files below
*/
#define CART_LIST_FLAG_BYTE		0x0FF1
#define LIST_FLAG_ABOVE			1
#define LIST_FLAG_BELOW			2

/* Atari -> FPGA commands (Sent as D5xx access)
; 1-20 select item n
; 64 disable cart
; 127 prev page
; 128 next page
; 129 up directory
; 130 reset
; 255 acknowledge
*/

#define ATARI_CMD_DISABLE	64
#define ATARI_CMD_PREV_PAGE	127
#define ATARI_CMD_NEXT_PAGE	128
#define ATARI_CMD_UP_DIR	129
#define ATARI_CMD_RESET		130

static alt_u32 TimerFunction (void *context)
{
	(void) context;
	Systick++;

	if (Systick % 10 == 0)
		ffs_DiskIOTimerproc();  /* Drive timer procedure of low level disk I/O module */

	if (Systick % 200 < 10)
		IOWR(LED_BASE, 0, ledVal);
	else
		IOWR(LED_BASE, 0, ledVal | 1);

	return (1);
}

char *get_filename_ext(char *filename) {
    char *dot = strrchr(filename, '.');
    if(!dot || dot == filename) return "";
    return dot + 1;
}

typedef struct {
	char isDir;
	char filename[13];
	char long_filename[32];
} DIR_ENTRY;

int num_dir_entries = 0;	// how many entries in the current directory
int dir_offset = 0;			// start index of the chunk of files being displayed by atari

int entry_compare(const void* p1, const void* p2)
{
	DIR_ENTRY* e1 = (DIR_ENTRY*)p1;
	DIR_ENTRY* e2 = (DIR_ENTRY*)p2;
	if (e1->isDir && !e2->isDir) return -1;
	else if (!e1->isDir && e2->isDir) return 1;
	else return stricmp(e1->long_filename, e2->long_filename);
}

FRESULT read_directory(char* path)
{
    FRESULT res;
    FILINFO fno;
    DIR dir;
    DIR_ENTRY entry;

    num_dir_entries = 0;
    dir_offset = 0;
    DIR_ENTRY *dst = (DIR_ENTRY *)EXT_SRAM_CONTROLLER_0_BASE;

	//printf("PATH = %s\n", path);

    res = pf_opendir(&dir, path);
    if (res == FR_OK)
    {
        while (1) {
        	res = pf_readdir(&dir, &fno);
            if (res != FR_OK || fno.fname[0] == 0)
            	break;
            if (fno.fattrib & (AM_HID | AM_SYS))
            	continue;
            int entry_type = 0;
            if (fno.fattrib & AM_DIR)
            { // a directory
            	entry_type = 2;
            }
            else
            {	// a file - check its a ROM, CAR or a XEX file
                char *ext = get_filename_ext(fno.fname);
                if (strcmp(ext, "CAR") != 0 && strcmp(ext, "ROM") != 0 && strcmp(ext, "XEX") != 0) continue;
                entry_type = 1;
            }
            // valid entry
            //printf("%s, %s\n", fno.fname, fno.lfname);
            // create a record
            entry.isDir = (entry_type == 2 ? 1 : 0);
            strcpy(entry.filename, fno.fname);
            strncpy(entry.long_filename, fno.lfname, 31);
            entry.long_filename[31] = 0;
            // copy to SRAM
            memcpy(&dst[num_dir_entries], &entry, sizeof(DIR_ENTRY));
            num_dir_entries++;
        }
        qsort(dst, num_dir_entries, sizeof(DIR_ENTRY), entry_compare);
    }
    return res;
}

#define ENTRY_TYPE_NONE	0
#define ENTRY_TYPE_ROM	1
#define ENTRY_TYPE_DIR	2
#define ENTRY_TYPE_XEX	3

void populate_cart_file_list()
{
	int i;
    DIR_ENTRY *dir_entries = (DIR_ENTRY *)EXT_SRAM_CONTROLLER_0_BASE;
    unsigned char *cart_dir_mem_base = (unsigned char *)(CART_MEMORY_BASE + CART_DIR_ENTRIES);

	for (i = 0; i < DIR_ENTRIES_PER_PAGE; i++)
	{
		int entry_type = 0;
		if (dir_offset + i < num_dir_entries)
		{
			DIR_ENTRY *entry = &dir_entries[dir_offset + i];
			if (entry->isDir)
				entry_type = ENTRY_TYPE_DIR;
			else
			{
				char *ext = get_filename_ext(entry->filename);
				if (strcmp(ext, "XEX") == 0)
					entry_type = ENTRY_TYPE_XEX;
				else
					entry_type = ENTRY_TYPE_ROM;
			}
			strncpy(cart_dir_mem_base+(i*32)+1, entry->long_filename, 31);
		}
		*(cart_dir_mem_base+(i*32)) = entry_type;
	}
}

void set_cart_cmd_byte(unsigned char byte) {
	*(unsigned char *)(CART_MEMORY_BASE + CART_CMD_BYTE) = byte;
}

void set_cart_list_flag_byte(unsigned char byte) {
	*(unsigned char *)(CART_MEMORY_BASE + CART_LIST_FLAG_BYTE) = byte;
}

void set_cart_error(char *errorStr) {
	strncpy(CART_MEMORY_BASE + CART_ERROR_BUFFER, errorStr, 32);
	set_cart_cmd_byte(CART_CMD_ERROR);
}

unsigned char recieve_atari_byte()
{
	unsigned char atari_ret = 0;
	while (!atari_ret)
		atari_ret = IORD(ATARI_D500_BYTE_BASE, 0);
	IOWR(RESET_D500_BASE, 0, 1);
	IOWR(RESET_D500_BASE, 0, 0);
	return atari_ret;
}

void atari_reboot_with_cart(int cart_type)
{
	set_cart_cmd_byte(cart_type == CART_TYPE_XEX ? CART_CMD_XEX_LOADER : CART_CMD_REBOOT);
	recieve_atari_byte();
	set_cart_cmd_byte(CART_CMD_IDLE);
	// wait 10ms to ensure the atari is running from ram before we switch the ROM
	int start = Systick; while (Systick < start + 10) {}
	// swap the cart bus to SRAM
	IOWR(SEL_CARTRIDGE_TYPE_BASE, 0, cart_type);
}

int load_cart(char *filename)
{
	int i,cart_type = -1;	// default to file error
	int car_file = 0, xex_file = 0;
	if (strncmp(filename+strlen(filename)-4, ".CAR", 4) == 0)
		car_file = 1;
	if (strncmp(filename+strlen(filename)-4, ".XEX", 4) == 0)
		xex_file = 1;

	//printf("loading %s\n", filename);
	if (pf_open(filename) == FR_OK) {
		cart_type = CART_TYPE_8K;	// default to 8K ROM
		int start = Systick;
		int length = 0;

		unsigned char *dst = (unsigned char *)EXT_SRAM_CONTROLLER_0_BASE;
		unsigned int *dst32 = (unsigned int *)dst;
		unsigned char buf[512];	// for file read

		if (xex_file == 1)
			dst32++;	// leave 4 bytes for the file size when we're copying a XEX

		UINT numBytesRead;
		// always read file in 512 byte chunks, since the SPI code is optimised for that
		while (pf_read(buf, 512, &numBytesRead) == FR_OK)
		{
			int bytesToCopy = numBytesRead;
			unsigned int *src32 = (unsigned int *)buf;

			if (car_file == 1 && (void*)dst32 == (void*)dst)
			{
				// read cartridge type from header
				int car_type = buf[7];
				if (car_type == 1) cart_type = CART_TYPE_8K;
				else if (car_type == 2) cart_type = CART_TYPE_16K;
				else if (car_type == 3) cart_type = CART_TYPE_OSS_16K_034M;
				else if (car_type == 8 || car_type == 22) cart_type = CART_TYPE_WILLIAMS_64K;
				else if (car_type == 9) cart_type =  CART_TYPE_EXPRESS_64K;
				else if (car_type == 10) cart_type = CART_TYPE_DIAMOND_64K;
				else if (car_type == 11) cart_type =  CART_TYPE_SDX_64K;
				else if (car_type == 12) cart_type = CART_TYPE_XEGS_32K;
				else if (car_type == 13) cart_type = CART_TYPE_XEGS_64K;
				else if (car_type == 14) cart_type = CART_TYPE_XEGS_128K;
				else if (car_type == 15) cart_type = CART_TYPE_OSS_16K_TYPE_B;
				else if (car_type == 17) cart_type = CART_TYPE_ATRAX_128K;
				else if (car_type == 18) cart_type = CART_TYPE_BOUNTY_BOB;
				else if (car_type >= 23 && car_type <= 25) cart_type = (car_type - 23) + CART_TYPE_XEGS_256K;
				else if (car_type >= 26 && car_type <= 32) cart_type = (car_type - 26) + CART_TYPE_MEGACART_16K;
				else if (car_type >= 33 && car_type <= 38) cart_type = (car_type - 33) + CART_TYPE_SW_XEGS_32K;
				else if (car_type == 40) cart_type = CART_TYPE_BLIZZARD_16K;
				else if (car_type == 41) cart_type = CART_TYPE_ATARIMAX_1MBIT;
				else if (car_type == 42) cart_type = CART_TYPE_ATARIMAX_8MBIT;
				else if (car_type == 43) cart_type =  CART_TYPE_SDX_128K;
				else if (car_type == 44) cart_type = CART_TYPE_OSS_8K;
				else if (car_type == 45) cart_type = CART_TYPE_OSS_16K_043M;
				else if (car_type == 50 || car_type == 51) cart_type = CART_TYPE_TURBOSOFT;
				else if (car_type >= 54 && car_type <=56) cart_type = CART_TYPE_SIC;
				else { cart_type = -2; break; }	// unsupported car type
				bytesToCopy -= 16;
				src32 += 4;
			}

			// copy 4 bytes at a time
			for (i=0; i<bytesToCopy/4; i++)
				*dst32++ = *src32++;

			// if we're at the end of a XEX file, there might be 1-3 trailing bytes left uncopied by the above
			if (bytesToCopy % 4 != 0)
				*dst32++ = *src32++;

			length += bytesToCopy;
			if (numBytesRead < 512)
				break;
		}

		if (xex_file == 1)
			cart_type = CART_TYPE_XEX;
		else if (car_file == 0) {
			// not a CAR file, try to guess the type
			if (length == 16*1024) cart_type = CART_TYPE_16K;
			else if (length == 32*1024) cart_type = CART_TYPE_XEGS_32K;
			else if (length == 64*1024) cart_type = CART_TYPE_XEGS_64K;
			else if (length == 128*1024) cart_type = CART_TYPE_XEGS_128K;
			else if (length == 256*1024) cart_type = CART_TYPE_SIC;
			else if (length == 512*1024) cart_type = CART_TYPE_SIC;
			else if (length == 1024*1024) cart_type = CART_TYPE_ATARIMAX_8MBIT;
		}

		if (xex_file == 0 && (length % 1024 != 0)) {
			// if ROM length not a multiple of 1024 bytes, must be a bad file
			cart_type = -1;
		}

		// add the file length when we've copied a xex file
		if (xex_file == 1)
			*(unsigned int *)dst = length;

		//printf("cart type=%d\n", cart_type);
		//printf("copied %d bytes to SRAM\n", length);
		//printf("took %d ms\n", (Systick - start));
	}
	return cart_type;
}

int main()
{
	FATFS fs;
	int i;
	char path[256] = "";

	/* Init timer system */
	alt_alarm_start(&alarm, 1, &TimerFunction, NULL);

	IOWR(SEL_CARTRIDGE_TYPE_BASE, 0, CART_TYPE_BOOT);
	IOWR(RESET_D500_BASE, 0, 0);

	ffs_DiskIOInit();
	if (pf_mount(&fs) != FR_OK) {
	//	printf("terminating");
		set_cart_error("No SD Card? Insert then reboot.");
		return 0;
	}

	// check for a different boot image
	if (pf_open("_BOOT.ROM") == FR_OK) {
		unsigned char buf[512];	// for file read
		unsigned int *dst32 = (unsigned int *)CART_MEMORY_BASE;
		UINT br;
		while (pf_read(buf, 512, &br) == FR_OK && br == 512)
		{
			unsigned int *src32 = (unsigned int *)buf;
			for (i=0; i<512/4; i++)
				*dst32++ = *src32++;
		}
	}

	FRESULT res = read_directory(path);
	DIR_ENTRY *dir_entries = (DIR_ENTRY *)EXT_SRAM_CONTROLLER_0_BASE;
	// main loop
	while (1)
	{
		if (res != FR_OK) {
			set_cart_error("Reading directory from SD card");
			break;
		}
		populate_cart_file_list();
		// tell the atari if there are pages above/below
		unsigned char list_flag = 0;
		if (dir_offset > 0) list_flag |= LIST_FLAG_ABOVE;
		if (dir_offset + DIR_ENTRIES_PER_PAGE < num_dir_entries) list_flag |= LIST_FLAG_BELOW;
		set_cart_list_flag_byte(list_flag);

		// tell the atari to redisplay directory
		set_cart_cmd_byte(CART_CMD_DISPLAY_DIR);
		recieve_atari_byte();
		set_cart_cmd_byte(CART_CMD_IDLE);

		// wait for a menu selection from atari
		unsigned char atari_ret = recieve_atari_byte();
		if (atari_ret >=1 && atari_ret <=20) {
			// item selected
			DIR_ENTRY *entry = &dir_entries[dir_offset + atari_ret-1];
			strcat(path, "/");
			strcat(path, entry->filename);
			if (entry->isDir)
			{	// directory selected
				res = read_directory(path);
			}
			else
			{	// file selected
				int cart_type = load_cart(path);
				if (cart_type > 0)
				{
					atari_reboot_with_cart(cart_type);
					break;
				}
				else
				{
					if (cart_type == -2)
						set_cart_error("Unsupported cartridge type");
					else
						set_cart_error("Bad ROM/CAR file?");
					recieve_atari_byte();
					set_cart_cmd_byte(CART_CMD_IDLE);
					// remove the filename from the path, so we get the current directory again when we loop
					int len = strlen(path);
					while (len && path[--len] != '/');
					path[len] = 0;
					// we need to read the directory again, since the SRAM contents may have been overwritten
					int old_dir_offset = dir_offset;
					res = read_directory(path);
					dir_offset = old_dir_offset;
				}
			}
		}
		else if (atari_ret == ATARI_CMD_DISABLE) {
			// disable cartridge
			atari_reboot_with_cart(CART_TYPE_NONE);
			break;
		}
		else if (atari_ret == ATARI_CMD_NEXT_PAGE) {
			// next page
			if (dir_offset + DIR_ENTRIES_PER_PAGE < num_dir_entries)
				dir_offset += DIR_ENTRIES_PER_PAGE;
		}
		else if (atari_ret == ATARI_CMD_PREV_PAGE) {
			// prev page
			if (dir_offset >= DIR_ENTRIES_PER_PAGE)
				dir_offset -= DIR_ENTRIES_PER_PAGE;
		}
		else if (atari_ret == ATARI_CMD_UP_DIR) {
			// up a directory
			int len = strlen(path);
			while (len && path[--len] != '/');
			path[len] = 0;
			res = read_directory(path);
		}
		else if (atari_ret == ATARI_CMD_RESET) {
			// atari sends this cmd in reset key trap
			path[0] = 0;
			res = read_directory(path);
		}
	}
	return 0;
}
