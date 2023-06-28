    MODULE Uart
UART_DATA_REG = #c6
UART_STAT_REG = #c7
UART_BYTE_RECIVED = #80
UART_BYTE_SENDING = #40
SCANDBLCTRL_REG = #0B
ZXUNO_ADDR = #FC3B
ZXUNO_REG = #FD3B


; Enable UART
; Cleaning all flags by reading UART regs
; Wastes AF and BC
init:
    ld bc, ZXUNO_ADDR : ld a, UART_STAT_REG : out (c), a
    ld bc, ZXUNO_REG : in A, (c)
    ld bc, ZXUNO_ADDR : ld a, UART_DATA_REG : out (c), a
    ld bc, ZXUNO_REG : in A, (c)
    ld b, #ff
.loop
    push bc
    call uartRead
    pop bc
    djnz .loop
    ret

read:
    ld a, #2 : out (#fe), a
    call turboOff
.loop
    call uartRead
    jr nc, .loop

    ld b, a
    xor a: out (#fe), a
    ld a, b
    ret

; Write single byte to UART
; A - byte to write
; BC will be wasted
write:    
    call turboOff
    push af
    ld a, 3 : out (#fe), a
    ld bc, ZXUNO_ADDR : ld a, UART_STAT_REG : out (c), a
    ld bc, ZXUNO_REG : in A, (c) : and UART_BYTE_RECIVED
    jr nz, .is_recvF
.checkSent
    ld bc, ZXUNO_REG : in A, (c) : and UART_BYTE_SENDING
    jr nz, .checkSent

    ld bc, ZXUNO_ADDR : ld a, UART_DATA_REG : out (c), a

    ld bc, ZXUNO_REG : pop af : out (c), a
    xor a : out (#fe), a
    ret
.is_recvF
    push af : push hl
    ld hl, is_recv : ld a, 1 : ld (hl), a 
    
    pop hl : pop af
    jr .checkSent

; Read byte from UART
; A: byte
; B:
;     1 - Was read
;     0 - Nothing to read
uartRead:
    ld a, (poked_byte) : and 1 : jr nz, .retBuff

    ld a, (is_recv) : and 1 : jr nz, recvRet

    ld bc, ZXUNO_ADDR : ld a, UART_STAT_REG : out (c), a
    ld bc, ZXUNO_REG : in a, (c) : and UART_BYTE_RECIVED
    jr nz, retReadByte

    or a
    ret
.retBuff
    ld a, 0 : ld (poked_byte), a : ld a, (byte_buff)
    scf 
    ret

retReadByte:
    xor a : ld (poked_byte), a : ld (is_recv), a

    ld bc, ZXUNO_ADDR : ld a, UART_DATA_REG : out (c), a
    ld bc, ZXUNO_REG : in a, (c)

    scf
    ret

recvRet:
    ld bc, ZXUNO_ADDR : ld a,  UART_DATA_REG : out (c),a

    ld bc, ZXUNO_REG : in a, (c)
    ld hl, is_recv : ld (hl), 0
    ld hl, poked_byte : ld (hl), 0
    
    scf
    ret

poked_byte defb 0
byte_buff defb 0
is_recv defb 0

    ENDMODULE