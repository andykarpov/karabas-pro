	include ff.equ
SAMPLESTART:
;монтируем SD карту
	ld l,1			;сразу проверить том на валидность
	push hl
	ld bc,drpath_zsd
	ld de,ffs		
	call FF_MOUNT
	pop hl
	or a
	ret nz			;возврат, если ошибка
	
;зайдем в директорию zx_images
	ld de,dirname
	call FF_CHDIR
	cp 5
	call z,create_cat	;не найден каталог
	or a
	ret nz			;возврат, если ошибка
;найдём файл с картинкой
find6912
	ld de,dir
	ld bc,nullname ;пустой путь
	call FF_OPENDIR
	or a
	ret nz			;возврат, если ошибка
.l1
	ld de,dir
	ld bc,finfo
	call FF_READDIR
	or a
	ret nz			;возврат, если ошибка
	ld a,(finfo.fname) 
	or a
	ret z ;если первый символ имени ноль, то каталог кончился
	ld a,(finfo.fattrib)
	and AM_DIR
	jr nz,.l1	;это папка, пропустим
	ld hl,(finfo.fsize+2)	;проверим размер
	ld a,h
	or l
	jr nz,.l1
	ld hl,(finfo.fsize)
	ld bc,6912
	sbc hl,bc
	ld a,l
	or h
	jr nz,.l1	;нетот размерчик
;напечатаем имя файла
	ld bc,finfo.fname
	;call print_bc
;покажем картинку
	ld l,FA_READ
	push hl
	ld de,file	;в BC имя файла осталось
	call FF_OPEN 
	pop hl
	or a
	ret nz			;возврат, если ошибка
	ld hl,rwres		;указатель на ворд, там будет реально прочитанное количество байт
	push hl
	;указатель на file попрежнему в DE
	ld hl,6912	;сколько читать
	push hl
	ld bc,0x4000	;куда читать
	call FF_READ
	pop hl
	pop hl
	call FF_CLOSE	;закроем файл(указатель на file попрежнему в DE)
	;ждём эникей
	ld bc,0x00fe
.l3
	in a,(c)
	inc a
	jr z,.l3
	jr .l1 ;покажем следующую картинку
	
;создадим каталог и картинку
create_cat
	ld de,dirname
	call FF_MKDIR
	or a
	ret nz			;возврат, если ошибка
	ld l,FA_READ|FA_WRITE|FA_CREATE_ALWAYS ;флаги открытия файла
	push hl
	ld bc,file_name
	ld de,file
	call FF_OPEN ;создадим файл
	pop hl
	or a
	ret nz			;возврат, если ошибка
	ld hl,rwres		;указатель на ворд, там будет реально записанное количество байт
	push hl
	ld de,file	;указатель на file
	ld hl,6912	;сколько записать
	push hl
	ld bc,testbin	;откуда брать
	call FF_WRITE
	pop hl
	pop hl
	call FF_CLOSE	;закроем файл(указатель на file попрежнему в DE)
	
;зайдем в директорию zx_images
	ld de,dirname
	call FF_CHDIR
	ret
;КОНЕЦ ПРИМЕРА
	
	
ffs			defs	FATFS_SIZE
file		defs	FIL_SIZE
rwres		defw	0
drpath_zsd	defb 	'0:',0	;путь девайса для монтирования. В данном случае Z-SD
dir			defs	DIR_SIZE
finfo		FILINFO
dirname		defb	'zximages',0
nullname	defb 0
file_name	defb	'zximages/hotcold.scr',0

testbin
	incbin	"hotcold.scr"
endtestbin
