/*-----------------------------------------------------------------------/
/  Low level disk interface modlue include file   (C)ChaN, 2014          /
/-----------------------------------------------------------------------*/

#ifndef _DISKIO_DEFINED
#define _DISKIO_DEFINED

#ifdef __cplusplus
extern "C" {
#endif

#define _USE_WRITE	1	/* 1: Enable disk_write function */
#define _USE_IOCTL	0	/* 1: Enable disk_ioctl fucntion */

/* Status of Disk Functions */
typedef unsigned char	DSTATUS;

/* Results of Disk Functions */
typedef enum {
	RES_OK = 0,		/* 0: Successful */
	RES_ERROR,		/* 1: R/W Error */
	RES_WRPRT,		/* 2: Write Protected */
	RES_NOTRDY,		/* 3: Not Ready */
	RES_PARERR		/* 4: Invalid Parameter */
} DRESULT;


/*---------------------------------------*/
/* Prototypes for disk control functions */


DSTATUS disk_initialize (unsigned char pdrv);
DSTATUS disk_status (unsigned char pdrv);
DRESULT _disk_read (unsigned long sector, unsigned char count, unsigned char* buff, unsigned char pdrv);
#define disk_read(dp,db,ds,dc) _disk_read(ds,dc,db,dp)
DRESULT _disk_write (unsigned long sector, unsigned char count, const unsigned char* buff, unsigned char pdrv);
#define disk_write(dp,db,ds,dc) _disk_write(ds,dc,db,dp)
#if _USE_IOCTL
	DRESULT disk_ioctl (unsigned char pdrv, unsigned char cmd, void* buff);
#else
	#define disk_ioctl(a,b,c) RES_OK
#endif


/* Disk Status Bits (DSTATUS) */

#define STA_NOINIT		0x01	/* Drive not initialized */
#define STA_NODISK		0x02	/* No medium in the drive */
#define STA_PROTECT		0x04	/* Write protected */


/* Command code for disk_ioctrl fucntion */

/* Generic command (Used by FatFs) */
#define CTRL_SYNC			0	/* Complete pending write process (needed at _FS_READONLY == 0) */
#define GET_SECTOR_COUNT	1	/* Get media size (needed at _USE_MKFS == 1) */
#define GET_SECTOR_SIZE		2	/* Get sector size (needed at _MAX_SS != _MIN_SS) */
#define GET_BLOCK_SIZE		3	/* Get erase block size (needed at _USE_MKFS == 1) */
#define CTRL_TRIM			4	/* Inform device that the data on the block of sectors is no longer used (needed at _USE_TRIM == 1) */

#ifdef __cplusplus
}
#endif

#endif
