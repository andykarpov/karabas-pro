; A - row number
; HL - pointer to row
renderRow:
    add CURSOR_OFFSET
    ld d, a, e, 0 : call TextMode.gotoXY
    ld a, (hl)
    push hl
    call getIcon
    call TextMode.putC
    pop hl
    inc hl
    jp print70Goph

; A - gopher id char
getIcon:
    cp 'i' : jr z, .info
    cp '9' : jr z, .down
    cp '1' : jr z, .page
    cp '0' : jr z, .text
    cp '7' : jr z, .input
    ld a, ' '
    ret 
.info
    ld a, 32 : ret
.down
    ld de, hl
    ld bc, #ff, a, 9 : cpir
    ld a, b : or c : jr z, .downExit
    push de
.nameLoop
    ld a, (hl) : and a : jr z, .check
    cp 9 : jr z, .check
    cp 13 : jr z, .check
    push hl
    call CompareBuff.push
    pop hl 
    inc hl
    jr .nameLoop
.check
;    ld hl, scrExt1 : call CompareBuff.search : and a : jr nz, .image
;    ld hl, scrExt2 : call CompareBuff.search : and a : jr nz, .image
    ld a, 3 : ld (VTPL.SETUP), a ; 0 bit - looping, 1 bit - pt2 file
    ld hl, pt2Ext1 : call CompareBuff.search : and a : jr nz, .music 
    ld hl, pt2Ext2 : call CompareBuff.search : and a : jr nz, .music 
    ld a, 1 : ld (VTPL.SETUP), a
    ld hl, pt3Ext1 : call CompareBuff.search : and a : jr nz, .music 
    ld hl, pt3Ext2 : call CompareBuff.search : and a : jr nz, .music 
.checkExit
    pop hl
.downExit 
    ld a, MIME_DOWNLOAD : ret
.page
    ld a, MIME_LINK : ret
.text
    ld a, MIME_TEXT : ret
.input
    ld a, MIME_INPUT : ret
;.image
;    pop hl : ld a, MIME_IMAGE : ret
.music
    pop hl : ld a, MIME_MUSIC : ret

;scrExt1 db ".scr", 0
;scrExt2 db ".SCR", 0

pt3Ext1 db ".pt3", 0
pt3Ext2 db ".PT3", 0
pt2Ext1 db ".pt2", 0
pt2Ext2 db ".PT2", 0
