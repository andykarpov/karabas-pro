	DEVICE ZXSPECTRUM128

	ORG 0x6000
START:  
    di
    im 1
	ld sp,0xc000
	ld hl,FFBIN
	ld de,0xc000
	ld bc,FFBINEND-FFBIN
	ldir
	ei
	call SAMPLESTART
	di
	halt
	include sample.asm
FFBIN: 
	incbin "../fatfs/out.bin"
FFBINEND:
ENDPROG:
	SAVEHOB  "fssample.$C","fssample.C",START,ENDPROG-START
	SAVEBIN  "fss",START,ENDPROG-START
