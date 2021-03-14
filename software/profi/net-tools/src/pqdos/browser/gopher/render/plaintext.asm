renderPlainTextScreen:
    call prepareScreen
    ld b, PER_PAGE
.loop
    push bc
    ld a, PER_PAGE : sub b
    
    ld b, a, e, a, a, (page_offset) : add b : ld b, a : call Render.findLine
    ld a, h : or l : jr z, .exit
    ld a, e
    add CURSOR_OFFSET : ld d, a, e, 1 : call TextMode.gotoXY
    call print70Text
    pop bc 
    djnz .loop
    ret
.exit
    pop bc
    ret

plainTextLoop:
    call Console.getC
    cp Console.KEY_DN : jp z, textDown
    cp Console.KEY_UP : jp z, textUp
    
    cp 'h' : jp z, History.home
    cp 'H' : jp z, History.home

    cp 'b' : jp z, History.back
    cp 'B' : jp z, History.back
    cp BACKSPACE : jp z, History.back

    cp CR : jp z, navigate
    cp ESC : jp z, exit
    jr plainTextLoop

textDown:
    ld a, (page_offset) : add PER_PAGE : ld (page_offset), a
    call renderPlainTextScreen
    jp plainTextLoop

textUp:
    ld hl, page_offset 
    ld a, (hl) : and a : jr z, plainTextLoop
    sub PER_PAGE : ld (hl), a
    call renderPlainTextScreen
    jp plainTextLoop