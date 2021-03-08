; DE - buffer
; HL - output
atohl:
    ld hl, 0
.loop
    ld a, (de)
    inc de
    ; Sepparators
    push bc, hl
        ld bc, sepparators_len
        ld hl, sepparators
        cpir
    pop hl, bc
    ret z

    sub '0'
    
    push bc
        ld c, l
        ld b, h

        add hl, hl
        add hl, hl
        add hl, bc
        add hl, hl
        ld c, a
        ld b, 0
        add hl, bc
    pop bc
    jr .loop
    