;; (c) 2023 Andy Karpov
;; (c) 2019 Alexander Sharikhin
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

    DEVICE ZXSPECTRUM128
    org #6000
Start: 
    di
stack_pointer = #5aff
    xor a : out (#fe), a : call changeBank
    ld sp, $ ; We don't care about anything before
    ld sp, stack_pointer
    xor a : ld (#5c6a), a : 
    ei

    call clearScreen
    push hl : ld hl, about : call putStringZ : pop hl

    call initWifi

    ; clear status / prev_status
    ld a, 7 : call changeBank ; change bank to video page
    xor a : ld (status_pointer), a
    add 1 : ld (prev_status_pointer), a

get_status:
    ld a, 7 : call changeBank ; change bank to video page
    ld a, 1 : ld (op_pointer), a ; 1 = status fetch operation
    ld hl, stproto : ld de, sturl : call httpGet ; status api
    ld de, (status_pointer) ; destination = status_pointer

stdownloop:
    ld bc, (bytes_avail) : ld hl, output_buffer : ldir ; repeat transfer from HL to DE with incrementing HL and decrementing BC
    ; todo: check bytes_avail, if 1 - goto close_callback
    push de : call getPacket : pop de
    jp stdownloop

get_data:
    ld a, 7 : call changeBank ; change bank to video page
    ld a, 0 : ld (op_pointer), a ; 0 = data fetch operation
    ld hl, status_pointer : ld a, (prev_status_pointer) : cp (hl) : jp z, closed_callback
    ld a, (status_pointer) : ld (prev_status_pointer), a ; update previous status

    ld hl, proto : ld de, url : call httpGet ; picture api
    ld de, (data_pointer)

downloop:
    ld bc, (bytes_avail) : ld hl, output_buffer : ldir ; repeat transfer from HL to DE with incrementing HL and decrementing BC
    push de : call getPacket : pop de
    jp downloop

closed_callback
    ;xor a : call changeBank
    ld a, (op_pointer) : cp 1 : jp z, get_data ; jump to fetch data in case of status fetch op

    ld a, 3 ; 15 seconds delay
end2:
    ld b, 0
end:
    halt : djnz end
    dec a : cp 0 : jp nz, end2    
    jp get_status
	ret	

about db "Initing Wifi module", 13, 0
done db "Done", 13, 0

proto db "http://"
    IFDEF PROFISCR
url   db "www.karabas.uk/api/zx/alerts/profi", 13, 0
    ELSE
url   db "www.karabas.uk/api/zx/alerts/spectrum", 13, 0
    ENDIF

stproto db "http://"
sturl db "www.karabas.uk/api/zx/alerts/status", 13, 0

retAddr     defw 0

data_pointer    defw #c000 ; screen start

status_pointer  defw #dfe0 ; current status
prev_status_pointer  defw #dfe1 ; previous status
op_pointer      defw #dfee ; current op state
data_recv       defw 0
connectionOpen  db 0

;wSec: ei : ld b, 50
;wsLp  halt : djnz wsLp

    IFDEF PROFISCR
    include "profiscreen.asm"
    ELSE
    include "screen64.asm"
    ENDIF
    include "utils.asm"
    include "http.asm"
    include "ring.asm"
    IFDEF UNO
    include "uno-uart.asm"
    ENDIF
    IFDEF ZIFI
    include "zifi-uart.asm"
    ENDIF
    include "wifi.asm"

page_buffer equ $

    display "PAGE buffer:", $

eop equ $

    SAVEBIN "alerts.bin", Start, $ - Start
    SAVEHOB "alerts.$c", "weather.C", Start, $ - Start
    IFDEF DEBUG
    SAVESNA "alerts.sna", Start
    ENDIF
