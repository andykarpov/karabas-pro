    OUTPUT "wget.com"
    org #100
Start:
        ld hl, about
        call putStringZ

        ld a, (CLI_PARAMS_COUNT) : and a
        jp z, noArgs
        call loadArgs

        ld hl, initUart      : call putStringZ : call uartBegin
        ld hl, makingRequest : call putStringZ : ld hl, proto : call putStringZ 

        ld hl, proto : call httpGet

        ld de, fout, a, FMODE_NO_READ : call fcreate
        ld a, b, (fpointer), a
        ld hl, downloading : call putStringZ
downloop:
        ld a, (fpointer), b, a
        ld hl, (bytes_avail)
        ld de, output_buffer
        call fwrite

        ld a, '.' : call putC
        
        ld a, (fpointer), b, a : call fsync
        call getPacket
        jp downloop

loadArgs:
    ld a, (CLI_PARAMS_COUNT), b, a
    ld de, url
    ld hl, CLI_PARAMS + 1 
aLp:    
    dec b : jr z, aE

    ld a,(hl)

    cp CR
    jr z, aE
    

    cp ' '
    jr z, narg

    ld (de), a

    inc de
    inc hl
    jr aLp
aE:
    xor a
    ld (de), a
    ret
narg:
    ld a, CR : ld (de), a

    inc de
    xor a : ld (de), a

    inc hl
    ld de, fout
    jr aLp

noArgs: 
    ld hl, usage
    call putStringZ
    rst 0

closed_callback:
    ld a, (fpointer), b, a
    call fclose
    ld hl,done : call putStringZ
	rst 0	

uartWriteStringZ:
    ld a, (hl)
    and a : ret z
    push hl
    call uartWriteByte
    pop hl
    inc hl 
    jr uartWriteStringZ

about:      db 'wGet v.0.3 (c) 2021 Nihirash', 13, 10, 0
usage:      db 'Usage: wget <url> <outputfile>', 13,10, 0
initUart    db "Initializing UART", 13, 10, 0
makingRequest db "Making request: ", 13,10, 0
downloading db 13, 10, 'Downloading', 0
done:       db 13, 10, 'File saved', 13, 10, 0
proto       db "http://"
url         ds #ff ; 0xd ending is important! Be carefull!
fout        ds #7f
fpointer    db 0

conclosed db 13, 13, "Connection closed", 0
    include "uno-uart.asm"
    include "wifi.asm"
    include "ring.asm"
    include "http.asm"
    include "dos/msxdos.asm"
output_buffer EQU $
