renderGopherScreen:
    call Render.prepareScreen
    ld b, PER_PAGE
.loop
    push bc
    ld a, PER_PAGE : sub b
    
    ld b, a, e, a, a, (page_offset) : add b : ld b, a : call findLine
    ld a, h : or l : jr z, .exit
    ld a, e : call renderRow
.exit
    pop bc 
    djnz .loop
    call showCursor
    ret


checkBorder:
    ld a, (cursor_position) : cp #ff : jp z, pageUp
    ld a, (cursor_position) : cp PER_PAGE : jp z, pageDn
    call showCursor
    jp workLoop

workLoop:
    call Console.getC
    cp Console.KEY_DN : jp z, cursorDown
    cp Console.KEY_UP : jp z, cursorUp
    cp Console.KEY_LT : jp z, pageUp
    cp Console.KEY_RT : jp z, pageDn
    
    cp 'h' : jp z, History.home
    cp 'H' : jp z, History.home

    cp 'b' : jp z, History.back
    cp 'B' : jp z, History.back
    cp BACKSPACE : jp z, History.back

    cp 'd' : jp z, inputHost
    cp 'D' : jp z, inputHost

    cp CR : jp z, navigate
    cp ESC : jp z, exit
    jp workLoop

navigate:
    call hideCursor
    ld a, (page_offset), b, a, a, (cursor_position) : add b : ld b, a : call Render.findLine
    ld a, (hl)
    cp '1' : jp z, .load
    cp '0' : jp z, .load
    cp '9' : jp z, .load
    cp '7' : jp z, .input
    call showCursor
    jp workLoop
.load
    push hl
    call getIcon 
    pop hl
    jp History.navigate
.input
    push hl
    call DialogBox.inputBox
    pop hl
    ld a, (DialogBox.inputBuffer) : and a : jp z, workLoop
    jr .load

showCursor:
    ld a, (cursor_position) : add CURSOR_OFFSET
    jp TextMode.highlightLine

hideCursor:
    ld a, (cursor_position) : add CURSOR_OFFSET
    jp TextMode.usualLine

cursorDown:
    call hideCursor
    ld hl, cursor_position
    inc (hl)
    jp checkBorder

cursorUp:
    call hideCursor
    ld hl, cursor_position
    dec (hl)
    jp checkBorder

pageUp:
    ld a, (page_offset) : and a : jr z, .skip
    ld a, PER_PAGE - 1 : ld (cursor_position), a
    ld a, (page_offset) : sub PER_PAGE : ld (page_offset), a
.exit
    call renderGopherScreen
    jp workLoop
.skip
    xor a : ld (cursor_position), a : call renderGopherScreen : jp workLoop

pageDn:
    xor a : ld (cursor_position), a 
    ld a, (page_offset) : add PER_PAGE : ld (page_offset), a
    jr pageUp.exit