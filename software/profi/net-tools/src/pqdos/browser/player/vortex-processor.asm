    MODULE VortexProcessor
play:
    call Console.waitForKeyUp

    ld hl, message : call DialogBox.msgNoWait

    ld hl, outputBuffer  : call VTPL.INIT
.loop
    halt : di : call VTPL.PLAY : ei
    xor a : in a, (#fe) : cpl : and 31 : jp nz, .stop
    ld a, (VTPL.SETUP) : rla : jr nc, .loop 
.stop
    call VTPL.MUTE
    call Console.waitForKeyUp
    ret

message db "Press key to stop...", 0
    ENDMODULE
    include "player.asm"
    