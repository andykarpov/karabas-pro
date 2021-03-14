prepareScreen:
    call TextMode.cls
    ld hl, header : call TextMode.printZ
    ld hl, toolbox : call TextMode.printZ
    ld hl, hostName : call TextMode.printZ
    ld de, #1D00 : call TextMode.gotoXY : ld hl, footer : call TextMode.printZ

    xor a : call TextMode.highlightLine
    ld a, 1 : call TextMode.highlightLine
    ld a, #1D : call TextMode.highlightLine
    ret

header db "    Moon Rabbit 1.0 for PQ-DOS (c) 2021 Alexander Nihirash",13, 0
toolbox db " [D]omain: ", 0
footer db "  Cursor - movement  [B]ack to prev.    page ESC - Quit    ", 0

inputHost:
.loop
    ld de, #010B : call TextMode.gotoXY : ld hl, hostName : call TextMode.printZ
    ld a, MIME_INPUT : call TextMode.putC
    ld a, ' ' : call TextMode.putC
.wait
    call Console.getC
    cp BACKSPACE : jr z, .removeChar
    cp CR : jp z, inputNavigate
    cp 32 : jr c, .wait
    jr .putC
.putC
    ld e, a
    xor a : ld hl, hostName, bc, 48 : cpir
    ld (hl), a : dec hl : ld (hl), e 
    jr .loop
.removeChar
    xor a
    ld hl, hostName, bc, 48 : cpir
    dec hl : dec hl : ld (hl), a 
    jr .loop

inputNavigate:
    ld hl, hostName, de, domain
.loop
    ld a, (hl) : and a : jr z, .complete
    ld (de), a : inc hl, de
    jr .loop
.complete
    ld a, 9 : ld (de), a : inc de
    ld a, '7' : ld (de), a : inc de
    ld a, '0' : ld (de), a : inc de
    ld a, 13 : ld (de), a : inc de
    ld a, 10 : ld (de), a : inc de
    ld hl, navRow : call History.navigate

navRow db "1 ", TAB, "/", TAB
domain db "nihirash.net" 
    ds 64 - ($ - domain)
