;
;	$Id: Cstartup.s01 1.24 2001/01/04 12:19:06 IPEO Exp $
;

;----------------------------------------------------------;
;						      	   ;
;		    CSTARTUP.S01		      	   ;
;						      	   ;
; This file contains the Z80/HD64180 C startup routine     ;
; and must usually be tailored to suit customer's hardware.;
;						      	   ;
; Version:  4.00 [ 28/Apr/94 IJAR]                         ;
;----------------------------------------------------------;

	NAME	CSTARTUP

  EXTERN f_mount
  EXTERN f_open
  EXTERN f_read
  EXTERN f_lseek
  EXTERN f_close
  EXTERN f_opendir
  EXTERN f_readdir
  EXTERN f_write
  EXTERN f_getfree
  EXTERN f_sync
  EXTERN f_unlink
  EXTERN f_mkdir
  EXTERN f_rename
  EXTERN f_chdir
  EXTERN f_getcwd
  EXTERN disk_initialize
  EXTERN _disk_read
  EXTERN _disk_write
  EXTERN f_filstate
	PUBLIC FatFs,Fsid
	
	RSEG	UDATA0
	
	RSEG	IDATA0
	RSEG	ECSTR
	RSEG	TEMP
	RSEG	DATA0
	RSEG	WCSTR

	RSEG	CDATA0
	RSEG	CCSTR
	RSEG	CONST
	RSEG	CSTR

	ASEG
	ORG	0xc000
init_A
	jp f_mount
	jp f_open
	jp f_unlink
	jp f_read
	jp f_lseek
	jp f_write
	jp f_sync
	jp f_chdir
	jp f_readdir
	jp f_opendir
	jp f_close
	jp f_mkdir
	jp f_rename
	jp f_getcwd
	jp f_filstate
	jp	disk_initialize
	jp	_disk_read
	jp	_disk_write
	

	RSEG	RCODE
FatFs:
	DEFW	0
Fsid:
	DEFW	0
	ENDMOD	init_A

	END