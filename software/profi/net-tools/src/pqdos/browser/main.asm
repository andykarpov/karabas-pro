    output "moonr.com"
    org 100h
    jp start
    include "vdp/driver.asm"
    include "utils/index.asm"
    include "gopher/render/index.asm"
    include "dos/msxdos.asm"
    include "gopher/engine/history/index.asm"
    include "gopher/engine/urlencoder.asm"
    include "gopher/engine/fetcher.asm"
    include "gopher/engine/media-processor.asm"
    include "gopher/gopher.asm"
    include "player/vortex-processor.asm"

start:  
    call TextMode.init
    call History.home
    jp exit

outputBuffer:


    display "ENDS: ", $
    display "Buff size", #c000 - $