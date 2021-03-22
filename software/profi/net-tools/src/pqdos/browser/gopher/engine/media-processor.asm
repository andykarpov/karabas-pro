    MODULE MediaProcessor
processResource:
    call turboOn
    call UrlEncoder.extractHostName
    ld a, (historyBlock.mediaType)
    cp MIME_LINK  : jr z, processPage
    cp MIME_INPUT : jr z, processPage
    cp MIME_MUSIC : jr z, processPT
; Fallback to plain text
processText:
    call Render.renderPlainTextScreen
    jp   Render.plainTextLoop

processPT:
    call VortexProcessor.play
    jp History.back

processPage:
    call Render.renderGopherScreen
    jp   Render.workLoop

    ENDMODULE