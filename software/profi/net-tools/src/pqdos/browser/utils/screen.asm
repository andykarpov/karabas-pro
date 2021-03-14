; HL - string pointer
print70Text:
    ld b, 60
.loop
    ld a, (hl)
    and a : ret z
    cp 13 : ret z
    cp 10 : ret z
    push bc
    push hl
    call TextMode.putC
    pop hl
    inc hl
    pop bc
    dec b
    ld a, b : and a: ret z
    jp .loop

; HL - string pointer
print70Goph:
    ld b, 60
.loop
    ld a, (hl) : cp 09 : ret z
    and a : ret z
    push bc
    push hl
    call TextMode.putC
    pop hl
    inc hl
    pop bc
    dec b
    ld a, b : and a: ret z
    jp .loop