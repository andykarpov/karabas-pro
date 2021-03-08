    module Gopher
; HL - gopher row
extractRequest:
/*
    ld hl, historyBlock.locator
    ld de, requestbuffer
.loop
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    cp 0 
    jr z, .search
    jr .loop
.search
    dec de
    ld a, (historyBlock.mediaType)
    cp MIME_INPUT
    jr nz, .exit
    ld hl, historyBlock.search
    ld a, TAB
    ld (de), a
    inc de
.searchCopy
    ld a, (hl) 
    and a : jr z, .exit
    ld (de), a
    inc hl : inc de
    jr .searchCopy
.exit
    ld a, CR : ld (de), a : inc de
    ld a, LF : ld (de), a : inc de
    xor a
    ld (de), a*/
    ret


makeRequest:
/*
    call TcpIP.closeAll
    call extractRequest
    ld de, historyBlock.port
    call atohl
    ld (.port + 1), hl

    ld hl, historyBlock.host
    call TcpIP.resolveIp
    jp nc, .error
.port  
    ld bc, #beaf
    call TcpIP.openTcp
    jp nz, .error

    ld a, b
    ld (socket), a

    ld de, requestbuffer
    push de
    call strlen
    pop de
    ld a, (socket)
    call TcpIP.sendTCP
    or a
    ret
.error*/
    scf
    ret

loadBuffer:
    scf
    ret
/*
    ld hl, outputBuffer
    ld (.pointer), hl
.loop
    ld a, (socket)
    call TcpIP.stateTcp
    and a : ret nz ; If there some error
    ld a, h : or l : jr nz, .getPacket ; if there some data
    ld a, b : cp 4 : ret nz ; If there no established status
    jr .loop
.getPacket
    ld hl, 512
    ld a, (socket)
    call TcpIP.recvTCP
    push bc
        ld hl, (.pointer)
        add hl, bc : ld a, h : cp #c0 : jp nc, .skiploop
        ld de, (.pointer), hl, TcpIP.tcpBuff
        ldir
    pop bc
    ld hl, (.pointer)
    add hl, bc
    ld (.pointer), hl
    jp .loop
.skiploop
    pop bc
    call TcpIP.closeAll
    jp .loop
.pointer dw outputBuffer
*/
download:
    /*
    ld de, historyBlock.locator
    ld hl, de
.findFileName
    ld a, (de) : inc de
    cp '/' : jr nz, .skip
    ld hl, de
.skip
    and a : jr nz, .findFileName
.copy
    ;; HL - filename pointer
    ld de, DialogBox.inputBuffer
.copyFileName
    ld a, (hl) : and a : jr z, .finishCopy

    ld (de), a : inc hl, de
    jr .copyFileName
.finishCopy
    ld (de), a
    call DialogBox.inputBox.noclear
    ld a, (DialogBox.inputBuffer) : and a : jp z, History.back
    
    call makeRequest : jp c, Fetcher.fetchFromNet.error

    ld a, FMODE_NO_READ, b, ATTR_NOTHING, de, DialogBox.inputBuffer
    call Dos.fcreate
    and a : jr nz, .error
    ld a, b : ld (.fp), a
    ld hl, .progress : call DialogBox.msgNoWait
.loop
    ld a, (socket)
    call TcpIP.stateTcp
    and a : jp nz, .exit ; If there some error
    ld a, h : or l : jr nz, .getPacket ; if there some data
    ld a, b : cp 4 : jp nz, .exit ; If there no established status
    jr .loop
.getPacket
    ld hl, 512
    ld a, (socket)
    call TcpIP.recvTCP
    ld hl, bc, a, (.fp), b, a, de, TcpIP.tcpBuff
    call Dos.fwrite
    jp .loop
.exit
    ld a, (.fp), b, a
    call Dos.fclose
    call TcpIP.closeAll
    jp History.back
.error
    ld a, (.fp), b, a
    call Dos.fclose
    call TcpIP.closeAll
    ld hl, .err
    call DialogBox.msgBox
    */
    jp History.back
.err db "Operation failed! Sorry! Check filename or disk space!",0
.progress db "Downloading in progress! Wait a bit!", 0
.fp db 0

socket db 0

requestbuffer ds #ff
    endmodule
    