/****************************************************************************
*  Copyright (C) 2012-2013 by Michael Fischer.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the author nor the names of its contributors may
*     be used to endorse or promote products derived from this software
*     without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
*  THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
*  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
*  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
*  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
*  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
*  SUCH DAMAGE.
*
****************************************************************************
*  History:
*
*  30.08.2012  mifi  First version, tested with an Altera DE1 board.
*  15.08.2013  mifi  The 16 bit access was replaced by 32 bit
*  15.06.2015  Robin Edwards - modified for use with atari SD cartridge
*                              & changed to support petfatfs
****************************************************************************/

#include "diskio.h"

#include "system.h"
#include "io.h"
#include "pfs_interface.h"

/*=========================================================================*/
/*  DEFINE: All Structures and Common Constants                            */
/*=========================================================================*/
/*
 * Simple SPI (pio) defines
 */
#define ADDR_TXDATA     0
#define ADDR_RXDATA     4
#define ADDR_CONTROL    8
#define ADDR_STATUS     12

#define CTRL_SSEL       1
#define CTRL_BIT32      2
#define CTRL_LOOP       4

#define STATUS_DONE     1
#define SELECT()   {                          \
                      Control1 &= ~CTRL_SSEL; \
                      SPI_CTRL  = Control1;   \
                   }


#define DESELECT() {                         \
                      Control1 |= CTRL_SSEL; \
                      SPI_CTRL  = Control1;  \
                   }

#define POWER_ON()
#define POWER_OFF()

#define SPI_BASE     (SPI_MASTER_0_BASE | 0x80000000) /* Set MSB to disable cache */
#define SPI_TXR      *((volatile uint32_t*)(SPI_BASE + ADDR_TXDATA))
#define SPI_RXR      *((volatile uint32_t*)(SPI_BASE + ADDR_RXDATA))
#define SPI_CTRL     *((volatile uint32_t*)(SPI_BASE + ADDR_CONTROL))
#define SPI_SR       *((volatile uint32_t*)(SPI_BASE + ADDR_STATUS))
#define SPI_SR_DONE  STATUS_DONE

/*
 * MMC/SD command (in SPI)
 */
#define CMD0    (0x40+0)   /* GO_IDLE_STATE */
#define CMD1    (0x40+1)   /* SEND_OP_COND (MMC) */
#define ACMD41  (0xC0+41)  /* SEND_OP_COND (SDC) */
#define CMD8    (0x40+8)   /* SEND_IF_COND */
#define CMD9    (0x40+9)   /* SEND_CSD */
#define CMD10   (0x40+10)  /* SEND_CID */
#define CMD12   (0x40+12)  /* STOP_TRANSMISSION */
#define ACMD13  (0xC0+13)  /* SD_STATUS (SDC) */
#define CMD16   (0x40+16)  /* SET_BLOCKLEN */
#define CMD17   (0x40+17)  /* READ_SINGLE_BLOCK */
#define CMD18   (0x40+18)  /* READ_MULTIPLE_BLOCK */
#define CMD23   (0x40+23)  /* SET_BLOCK_COUNT (MMC) */
#define ACMD23  (0xC0+23)  /* SET_WR_BLK_ERASE_COUNT (SDC) */
#define CMD24   (0x40+24)  /* WRITE_BLOCK */
#define CMD25   (0x40+25)  /* WRITE_MULTIPLE_BLOCK */
#define CMD55   (0x40+55)  /* APP_CMD */
#define CMD58   (0x40+58)  /* READ_OCR */

/*
 * Card type flags (CardType)
 */
#define CT_MMC          0x01  /* MMC ver 3 */
#define CT_SD1          0x02  /* SD ver 1 */
#define CT_SD2          0x04  /* SD ver 2 */
#define CT_SDC          (CT_SD1|CT_SD2)   /* SD */
#define CT_BLOCK        0x08  /* Block addressing */


/*
 * Card socket defines
 */
#define SOCK_CD_EMPTY   0x01  /* Card detect switch */
#define SOCK_WP_ACTIVE  0x02  /* Write protect switch */

/*
 * Wait for ready in timeout of 500ms
 */
#define WAIT_READY_TIME_MAX_MS   500
#define WAIT_READY_TIME_RTOS_MS  5
#define WAIT_READY_TIME_CNT_RTOS (WAIT_READY_TIME_MAX_MS / WAIT_READY_TIME_RTOS_MS)
#define WAIT_READY_LOOP_CNT_MAX  16

/*=========================================================================*/
/*  DEFINE: Definition of all local Data                                   */
/*=========================================================================*/
static volatile DSTATUS Stat = STA_NOINIT;   /* Disk status */
static FFS_U8           CardType = 0;        /* b0:MMC, b1:SDv1, b2:SDv2, b3:Block addressing */
static volatile FFS_U16 Timer1 = 0;          /* 100Hz decrement timers */
static volatile FFS_U16 Timer2 = 0;          /* 100Hz decrement timers */
static uint32_t Control1 = 0;
/*=========================================================================*/
/*  DEFINE: Definition of all local Procedures                             */
/*=========================================================================*/
/***************************************************************************/
/*  SetLowSpeed                                                            */
/*                                                                         */
/*  Set SPI port speed to 200 KHz. Provided that the CPU is                */
/*  running with 100 MHz.                                                  */
/*                                                                         */
/*  In    : none                                                           */
/*  Out   : none                                                           */
/*  Return: none                                                           */
/***************************************************************************/
static void SetLowSpeed(void)
{
   Control1 &= ~0xFF00;
   Control1 |= (124 << 8); // 124 for 50Mhz CPU (was 249)
   SPI_CTRL  = Control1;
} /* SetLowSpeed */

/***************************************************************************/
/*  SetHighSpeed                                                           */
/*                                                                         */
/*  Set SPI port speed to 25 MHz. Provided that the CPU is                 */
/*  running with 100 MHz.                                                  */
/*                                                                         */
/*  Note: 25MHz works only with SD cards, MMC need 20MHz max.              */
/*                                                                         */
/*  In    : none                                                           */
/*  Out   : none                                                           */
/*  Return: none                                                           */
/***************************************************************************/
static void SetHighSpeed(void)
{
   Control1 &= ~0xFF00;

   if (0 == (CardType & 0x01))
   {
      /* SD card 25 MHz */
	  Control1 |= (1 << 8); // should be 0 for 50Mhz CPU, but doesn't work on SanDisk ultra
   }
   else
   {
      /* MMC card 16 MHz */
      Control1 |= (2 << 8);
   }
   SPI_CTRL  = Control1;
} /* SetHighSpeed */

/***************************************************************************/
/*  Now here comes some macros to speed up the transfer performance.       */
/*                                                                         */
/*            Be careful if you port this part to an other CPU.            */
/*             !!! This part is high platform dependent. !!!               */
/***************************************************************************/

/*
 * Transmit data only, without to store the receive data.
 * This function will be used normally to send an U8.
 */
#define TRANSMIT_U8(_dat)  SPI_TXR = (uint32_t)(_dat);     \
                           while(!(SPI_SR & SPI_SR_DONE));

/*
 * The next function transmit the data "very fast", becasue
 * we do not need to take care of receive data. This function
 * will be used to transmit data in 16 bit mode.
 */
#define TRANSMIT_FAST(_dat) SPI_TXR = (uint32_t)(_dat);     \
                            while(!(SPI_SR & SPI_SR_DONE));

/*
 * RECEIVE_FAST will be used in ReceiveDatablock only.
 */
#define RECEIVE_FAST(_dest)   SPI_TXR = (uint32_t)0xffffffff;     \
                              while( !( SPI_SR & SPI_SR_DONE ) ); \
                              *_dest++  = SPI_RXR;

/***************************************************************************/
/*  Set8BitTransfer                                                        */
/*                                                                         */
/*  Set Data Size of the SPI bus to 8 bit.                                 */
/*                                                                         */
/*  In    : none                                                           */
/*  Out   : none                                                           */
/*  Return: none                                                           */
/***************************************************************************/
static void Set8BitTransfer(void)
{
   Control1 &= ~CTRL_BIT32;
   SPI_CTRL  = Control1;
} /* Set8BitTransfer */

/***************************************************************************/
/*  Set32BitTransfer                                                       */
/*                                                                         */
/*  Set Data Size of the SPI bus to 32 bit.                                */
/*                                                                         */
/*  In    : none                                                           */
/*  Out   : none                                                           */
/*  Return: none                                                           */
/***************************************************************************/
static void Set32BitTransfer(void)
{
   Control1 |= CTRL_BIT32;
   SPI_CTRL  = Control1;
} /* Set32BitTransfer */

/***************************************************************************/
/*  ReceiveU8                                                              */
/*                                                                         */
/*  Send a dummy value to the SPI bus and wait to receive the data.        */
/*                                                                         */
/*  In    : none                                                           */
/*  Out   : none                                                           */
/*  Return: Data                                                           */
/***************************************************************************/
static FFS_U8 ReceiveU8 (void)
{
   SPI_TXR = (uint32_t) 0xff;

   /* wait for char */
   while (!(SPI_SR & SPI_SR_DONE)) ;

   return(SPI_RXR);
} /* ReceiveU8 */

/***************************************************************************/
/*  ReceiveDatablock                                                       */
/*                                                                         */
/*  Receive a data packet from MMC/SD card. Number of "btr" bytes will be  */
/*  store in the given buffer "buff". The byte count "btr" must be         */
/*  a multiple of 8.                                                       */
/*                                                                         */
/*  In    : buff, btr                                                      */
/*  Out   : none                                                           */
/*  Return: In case of an error return FALSE                               */
/***************************************************************************/
static int ReceiveDatablock(FFS_U8 * buff, uint32_t btr)
{
   FFS_U8 token, cnt;
   FFS_U32 *buff32 = (FFS_U32*)buff;

   Timer1 = 10;
   do /* Wait for data packet in timeout of 100ms */
   {
      token = ReceiveU8();
   }
   while ((token == 0xFF) && Timer1);

   if (token != 0xFE)
      return(FFS_FALSE);  /* If not valid data token, return with error */

   /* Receive the data block into buffer */
   Set32BitTransfer();

   /* Divide by 8 */
   cnt = btr >> 3;

   do /* Receive the data block into buffer */
   {
      RECEIVE_FAST(buff32);
      RECEIVE_FAST(buff32);
   }
   while (--cnt);

   Set8BitTransfer();
   ReceiveU8();   /* Discard CRC */
   ReceiveU8();   /* Discard CRC */

   return(FFS_TRUE);  /* Return with success */
} /* ReceiveDatablock */

/*-----------------------------------------------------------------------*/
/* Wait for card ready                                                   */
/*-----------------------------------------------------------------------*/
static FFS_U8 WaitReady(void)
{
   FFS_U8 res;

   Timer2 = (WAIT_READY_TIME_MAX_MS / 10);
   ReceiveU8();
   do
   {
      res = ReceiveU8();
   }
   while ((res != 0xFF) && Timer2);

   return(res);
} /* WaitReady */

/*-----------------------------------------------------------------------*/
/* Deselect the card and release SPI bus                                 */
/*-----------------------------------------------------------------------*/
static void ReleaseBus(void)
{
   /*
    * First deselect the CS line, and now make a dummy transmission.
    *
    * In SPI, each slave device is selected with separated CS signals,
    * and plural devices can be attached to an SPI bus. Generic SPI slave
    * device drives/releases its DO signal by CS signal asynchronously to
    * share an SPI bus. However MMC/SDC drives/releases DO signal in
    * synchronising to SCLK. There is a posibility of bus conflict when
    * attach MMC/SDC and any other SPI slaves to an SPI bus. Right image
    * shows the drive/release timing of MMC/SDC (DO is pulled to 1/2 vcc to
    * see the bus state). Therefore to make MMC/SDC release DO signal, the
    * master device must send a byte after deasserted CS signal.
    *
    * More information can be found here:
    * http://elm-chan.org/docs/mmc/mmc_e.html
    */
   DESELECT();
   ReceiveU8();
} /* ReleaseBus */

/*-----------------------------------------------------------------------*/
/* Send a command packet to MMC                                          */
/*-----------------------------------------------------------------------*/
static FFS_U8 SendCMD(FFS_U8 cmd,   /* Command byte */
                       FFS_U32 arg)  /* Argument */
{
   FFS_U8 n, res;

   if (cmd & 0x80)   /* ACMD<n> is the command sequense of CMD55-CMD<n> */
   {
      cmd &= 0x7F;
      res = SendCMD(CMD55, 0);
      if (res > 1)
         return res;
   }

   /* Select the card and wait for ready */
   DESELECT();
   SELECT();

   if (WaitReady() != 0xFF)
      return 0xFF;

   /* Send command packet */
   TRANSMIT_U8(cmd); /* Start + Command index */
   TRANSMIT_U8((FFS_U8) (arg >> 24));  /* Argument[31..24] */
   TRANSMIT_U8((FFS_U8) (arg >> 16));  /* Argument[23..16] */
   TRANSMIT_U8((FFS_U8) (arg >> 8));   /* Argument[15..8] */
   TRANSMIT_U8((FFS_U8) arg); /* Argument[7..0] */

   n = 0x01;   /* Dummy CRC + Stop */
   if (cmd == CMD0)
      n = 0x95;   /* Valid CRC for CMD0(0) */
   if (cmd == CMD8)
      n = 0x87;   /* Valid CRC for CMD8(0x1AA) */
   TRANSMIT_U8(n);

   /* Receive command response */
   if (cmd == CMD12)
      ReceiveU8();   /* Skip a stuff byte when stop reading */

   n = 10;  /* Wait for a valid response in timeout of 10 attempts */
   do
   {
      res = ReceiveU8();
   }
   while ((res & 0x80) && --n);

   return(res); /* Return with the response value */
} /* SendCMD */


void ffs_DiskIOTimerproc()
{
   FFS_U32 n;

   /* 100Hz decrement timer */
   n = Timer1;
   if (n)
      Timer1 = (FFS_U16)-- n;
   n = Timer2;
   if (n)
      Timer2 = (FFS_U16)-- n;
}

void ffs_DiskIOInit()
{
	   /*
	    * Deselct before to prevent glitch
	    */
	   DESELECT();

	   /* Slow during init */
	   SetLowSpeed();
}

DSTATUS ffs_DiskIOInitialize()
{
   FFS_U8 n, ty, cmd, ocr[4];

   if (Stat & STA_NODISK)  /* No card in the socket */
        return Stat;

     /* low speed during init */
     SetLowSpeed();

     POWER_ON(); /* Force socket power ON */
     for (n = 10; n; n--)
        ReceiveU8();   /* 80 dummy clocks */

     ty = 0;
     if (SendCMD(CMD0, 0) == 1)
     {  /* Enter Idle state */
        Timer1 = 100;  /* Initialization timeout of 1000 msec */
        if (SendCMD(CMD8, 0x1AA) == 1)
        {  /* SDC ver 2.00 */
           for (n = 0; n < 4; n++)
              ocr[n] = ReceiveU8();
           if (ocr[2] == 0x01 && ocr[3] == 0xAA)
           {  /* The card can work at vdd range of 2.7-3.6V */
              while (Timer1 && SendCMD(ACMD41, 1UL << 30)) ;  /* ACMD41 with HCS bit */
              if (Timer1 && SendCMD(CMD58, 0) == 0)
              {  /* Check CCS bit */
                 for (n = 0; n < 4; n++)
                    ocr[n] = ReceiveU8();
                 ty = (ocr[0] & 0x40) ? CT_SD2 | CT_BLOCK : CT_SD2; /* Card id SDv2 */
              }
           }
        }
        else
        {  /* SDC ver 1.XX or MMC */
           if (SendCMD(ACMD41, 0) <= 1)
           {
              ty  = CT_SD1;
              cmd = ACMD41;  /* SDC ver 1.XX */
           }
           else
           {
              ty  = CT_MMC;
              cmd = CMD1; /* MMC */
           }
           while (Timer1 && SendCMD(cmd, 0)) ; /* Wait for leaving idle state */
           if (!Timer1 || SendCMD(CMD16, 512) != 0)  /* Select R/W block length */
              ty = 0;
        }
     }
     CardType = ty;
     ReleaseBus();

     if (ty)
     {  /* Initialization succeded */
        Stat &= ~STA_NOINIT; /* Clear STA_NOINIT */

        SetHighSpeed();
     }
     else
     {  /* Initialization failed */
        POWER_OFF();
     }

     return(Stat);
} /* ffs_DiskIOInitialize */

DRESULT ffs_DiskIORead(FFS_U8 * buff, FFS_U32 sector, FFS_U16 offset, FFS_U16 count)
{
//	printf("o=%d c=%d\n", offset, count);
   if (!count)
      return RES_PARERR;
   if (Stat & STA_NOINIT)
      return RES_NOTRDY;

   FFS_U8 rc;
   DRESULT res = RES_ERROR;

   if (!(CardType & CT_BLOCK))
      sector *= 512; /* Convert LBA to byte address if needed */

   if (SendCMD(CMD17, sector) == 0) { /* READ_SINGLE_BLOCK */
	   if (offset == 0 && count==512) {
		   // fast path
		   if (ReceiveDatablock(buff, 512))
			   res = RES_OK;
	   }
	   else
	   {	// original path
		   FFS_U16 bc = 40000;
		   do { /* Wait for data packet */
			   rc = ReceiveU8();
		   } while (rc == 0xFF && --bc);

		   if (rc == 0xFE) { /* A data packet arrived */
			   bc = 514 - offset - count;

			   /* Skip leading bytes */
			   if (offset) {
				   do
					   ReceiveU8();
				   while (--offset);
			   }

			   /* Receive a part of the sector */
			   do {
				   *buff++ = ReceiveU8();
			   } while (--count);

			   /* Skip trailing bytes and CRC */
			   do
				   ReceiveU8();
			   while (--bc);
		   }
           res = RES_OK;
       }
   }

   ReleaseBus();

   return res;
} /* ffs_DiskIORead */

