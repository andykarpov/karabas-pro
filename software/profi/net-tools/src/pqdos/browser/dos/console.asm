    module Console
KEY_UP = #19
KEY_DN = #1A
KEY_LT = #8
KEY_RT = #18

newLine:
    ld a, CR
    call putC
    ld a, LF
putC:
    ld e, a 
    ld c, 2
    jp BDOS

getC:
peekC:
    ld c, 6, e, #ff
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

waitForKeyUp:
    ret
    endmodule