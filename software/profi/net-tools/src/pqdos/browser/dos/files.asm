FMODE_RW       = %000
FMODE_NO_WRITE = %001
FMODE_NO_READ  = %010
FMODE_INHERIT  = %100

ATTR_NOTHING   = #00
ATTR_RDONLY    = #01
ATTR_HIDDEN    = #02
ATTR_SYSTEM    = #04
ATTR_VOLUME    = #08
ATTR_DIRECTORY = #10
ATTR_ARCHIVE   = #20
ATTR_DEVICE    = #80

    module Dos
; DE -> filename
; A -> mode
;
; A <- Error
; B <- Handle
fopen:
    ld c, #43
    jp BDOS

; DE -> filename
; A  -> mode
; B  -> attribute
;
; A <- error
; B <- handle
fcreate:
    ld c, #44
    jp BDOS

; B <- Handle
; 
; A <- Error
fclose:
    ld c, #45
    jp BDOS

; B <- Handle
fsync:
    ld c, #46
    jp BDOS

; B <- Handle
; DE <- buffer
; HL <- Count
;
; A <- error
; HL <- actually read
fread: 
    ld c, #48
    jp BDOS
; B <- Handle
; DE <- Buffer
; HL <- Count
;
; HL <- actully written
; A <- Error
fwrite:
    ld c, #49
    jp BDOS
    endmodule

