    include "atoi.asm"
    include "constants.asm"
    include "strutils.asm"
    include "screen.asm"

MEMORY_REG = #7ffd
CONFIG_REG = #28B
CPM_REG = #dffd

turboOff:
    di
    push bc, af
    ld bc, MEMORY_REG : in a, (c) : ld (.old7ffd + 1), a : or 16 : out (c), a
   ld bc, CPM_REG : in a, (c) : ld (.olddffd + 1), a : or 32 : out (c), a
    ld bc, CONFIG_REG : ld a, 96: out (c), a
    ld bc, MEMORY_REG 
.old7ffd    
    ld a, 0
    out (c), a
    
    ld bc, CPM_REG 
.olddffd
    ld a, 0
    out (c), a

    pop af, bc
    ei
    ret

turboOn:
    di
    push bc, af
    ld bc, MEMORY_REG : in a, (c)  : ld (.old7ffd + 1), a : or 16 : out (c), a
    ld bc, CPM_REG : in a, (c) : ld (.olddffd + 1), a : or 32 : out (c), a
    ld bc, CONFIG_REG : ld a, 64 : out (c), a
    ld bc, MEMORY_REG 
.old7ffd    
    ld a, 0
    out (c), a
    ld bc, CPM_REG 
.olddffd
    ld a, 0
    out (c), a
    pop af, bc
    ei
    ret