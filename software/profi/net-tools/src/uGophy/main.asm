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
    jp begin
    ds #7f
stack_pointer = $

begin:
    di
    res 4, (iy+1)
    xor a : out (#fe), a : call changeBank
    ld sp, $ ; We don't care about anything before
    call renderHeader
    
    ld hl, init1 : call putStringZ

    call Dos.init
    ld de, work_dir : call Dos.cwd
    or a : jp nz, .dirError

    ld hl, init2 : call putStringZ
    ; Read player from disk
    ld l, Dos.FA_READ, bc, player_name : call Dos.fopen
    ld bc, #4000, de, 3061 : call Dos.fread
    call Dos.fclose

    xor a : ld (#5c6a), a  ; Thank you, Mario Prato, for feedback
    ei

    ld hl, init3 : call putStringZ
    call initWifi
    
    call wSec

    ld de, path : ld hl, server : ld bc, port : call openPage

    jp showPage
.dirError
    ld hl, .err : call putStringZ
    jr $

.err db "Can't enter 'wifi' directory",13,"Computer halted",0

init1 db "Initing sd card", 13, 0
init2 db "Loading PT3 player", 13, 0
init3 db "Initing Wifi module", 13, 0

wSec: ei : ld b, 50
wsLp  halt : djnz wsLp
    include "screen64.asm"
    include "keyboard.asm"
    include "utils.asm"
    include "gopher.asm"
    include "render.asm"
    include "textrender.asm"
    include "ring.asm"
    include "uno-uart.asm"
    include "wifi.asm"

work_dir db "wifi",0

player_name db "player.bin", 0

open_lbl db 'Opening connection to ', 0

path    db '/uhello'
        defs 248              
server  db 'nihirash.net'
        defs 58    
port    db '70'
        defs 5
        db 0

    include "dos/ochkodos.asm"

page_buffer equ Dos.bin
    display "PAGE buffer:", $

    savehob "ugophy.$c", "ugophy.C", Start, $ - Start
    