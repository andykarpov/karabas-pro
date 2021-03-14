    MODULE Fetcher

fetchFromNet:
    call Gopher.makeRequest : jr c, .error
    call Gopher.loadBuffer
    jp MediaProcessor.processResource
.error
    ld hl, .err : call DialogBox.msgBox 
    jp History.back
    
.err db "Document fetch error! Check your connection or hostname!", 0


fetchFromFS:
    call UrlEncoder.extractPath
loadFile
    ld de, nameBuffer, a, FMODE_NO_WRITE
    call Dos.fopen
    ld a, b, (.fp), a
    ld de, outputBuffer, hl, #c000 - outputBuffer
    call Dos.fread
    ld a, (.fp), b, a
    call Dos.fclose
    jp MediaProcessor.processResource
.fp db 0
    ENDMODULE