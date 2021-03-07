CR = 13
LF = 10

newLine:
    ld a, CR
    call putC
    ld a, LF
putC:
    ld e, a 
    ld c, 2
    jp BDOS

putStringZ:
    ld a, (hl)
    and a
    ret z
    push hl
    call putC
    pop hl
    inc hl
    jr putStringZ