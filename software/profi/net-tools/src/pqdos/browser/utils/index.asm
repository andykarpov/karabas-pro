    include "atoi.asm"
    include "constants.asm"
    include "strutils.asm"
    include "screen.asm"

MEMORY_REG = #7ffd
CONFIG_REG = #28B

turboOff:
    push bc, af
    ld c, MEMORY_REG : in a, (c) : or #08 : out (c), a
    ld c, CONFIG_REG : in a, (c) : and %111111101 : or %000000100 : out (c), a
    pop af, bc
    ret

turboOn:
    push bc, af
    ld c, MEMORY_REG : in a, (c) : or #08 : out (c), a
    ld c, CONFIG_REG : in a, (c) : and %111111011 : or %000000010 : out (c), a
    pop af, bc
    ret