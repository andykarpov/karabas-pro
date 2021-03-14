SET_MODE = #21
CLS = #22
CURSOR_MASK = #23
GOTO_XY = #24
PUTC = #26
PUTC_TTY = #27
SET_COLOR = #2A
FILL_LINE = #2F

    macro PQBIOS func
    ld c, func
    rst 8
    endm

    module TextMode
init:
    ld e, 1
    PQBIOS SET_MODE

cls:
    ld de, 0 : call gotoXY
    xor a
    ld de, #0107 : PQBIOS SET_COLOR
    PQBIOS CLS
    ret

; A - line
usualLine:
   ld e,a, h, #0f, b, 3 
   jr fill 
; A - line
highlightLine:
   ld e,a, h, #1f, b, 3 
fill:
    ld d, 0
    ld l, 64
    xor a
    PQBIOS FILL_LINE
    ret

printZ:
    ld a, (hl) : and a : ret z
    push hl
    call putC
    pop hl
    inc hl
    jr printZ


; A - char
putC:
    cp 13 : jr z, nl
    PQBIOS PUTC_TTY
    ret

nl:
    ld a, CR : PQBIOS PUTC_TTY
    ld a, LF : PQBIOS PUTC_TTY
    ret

; L - line 
; A - char
fillLine:
    push hl, af
    ld d, h, e, 0
    call gotoXY
    pop af, hl

    ld e, a
    ld d, 64
    xor a
    ld b, a
    PQBIOS FILL_LINE
    ret


gotoXY:
    ld a, e
    ld e, d
    ld d, a
    PQBIOS GOTO_XY
    ret

    endmodule

exit:
    ld e, 1
    PQBIOS SET_MODE
    PQBIOS CLS
    rst 0