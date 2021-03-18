    module Gopher
extractRequest:
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
    xor a
    ld (de), a
    ret


makeRequest:
    call extractRequest

    ld hl, historyBlock.host
    ld de, historyBlock.port
    call Wifi.openTCP
    ret c

    ld hl, requestbuffer
    call Wifi.tcpSendZ
    xor a : ld (Wifi.closed), a
    ret


loadBuffer:
    ld hl, outputBuffer
    ld (Wifi.buffer_pointer), hl
.loop
    call Wifi.getPacket
    ld a, (Wifi.closed) : and a : ret nz
    jr .loop

download:

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
    ld hl, outputBuffer, (Wifi.buffer_pointer), hl
    call Wifi.getPacket
    call turboOn
    ld a, (Wifi.closed) : and a : jr nz, .exit
    
    ld a, (.fp), b, a, de, outputBuffer, hl, (Wifi.bytes_avail)
    call Dos.fwrite

    jp .loop
.exit
    ld a, (.fp), b, a
    call Dos.fclose
    jp History.back
.error
    ld a, (.fp), b, a
    call Dos.fclose
    ld hl, .err
    call DialogBox.msgBox
    jp History.back
.err db "Operation failed! Sorry! Check filename or disk space!",0
.progress db "Downloading in progress! Wait a bit!", 0
.fp db 0

socket db 0

requestbuffer ds #ff
    endmodule
    