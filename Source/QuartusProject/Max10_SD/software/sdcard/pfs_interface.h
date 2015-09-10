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

#ifndef PFS_INTERFACE_H_
#define PFS_INTERFACE_H_

#include "diskio.h"

/*
 * Some types
 */
typedef unsigned char   FFS_U8;  /* 8-bit unsigned data  */
typedef signed char     FFS_S8;  /* 8-bit signed data    */

typedef unsigned short  FFS_U16; /* 16-bit unsigned data */
typedef short           FFS_S16; /* 16-bit signed data   */

typedef unsigned long   FFS_U32; /* 32-bit unsigned data */
typedef long            FFS_S32; /* 32-bit signed data   */
typedef unsigned long	uint32_t;
/*
 * Result of a FFS function
 */
typedef short           FFS_RESULT;

/*
 * And the values for FFS_RESULT
 */
#define FFS_OK          0
#define FFS_ERROR       -1

/*
 * And here, the own TRUE and FALSE
 */
#define FFS_TRUE        1
#define FFS_FALSE       0


void ffs_DiskIOTimerproc();
void ffs_DiskIOInit();
DSTATUS ffs_DiskIOInitialize();
DRESULT ffs_DiskIORead(FFS_U8 * buff, FFS_U32 sector, FFS_U16 offset, FFS_U16 count);


#endif /* PFS_INTERFACE_H_ */
