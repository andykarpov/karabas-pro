; RTC issues patch for PQDOS BIOS on Karabas Pro 
; 28.09.2025 @Itolp

        DEVICE zxspectrum128
        LUA pass1
                infile   = assert(io.open("bios_pqdos.rom", "rb"))
                assert(infile:seek("set",2))
                local data = assert(infile:read(2))
                assert(infile:close())
                
                local b1, b2 = string.byte(data, 1, 2)
                
                local address = b1 + 256*b2

                sj.insert_label("SPVALUE", address)
                print("As text:", word)
        ENDLUA

;SPVALUE  = #XXXX        ; will be read from the file by LUA script above

RTC_AS = #00BF
RTC_AD = #009F

P1_ADR = #0001
P2_ADR = #2F00

EXIT_ADR = #0004


        ORG P1_ADR
P1:
        jp P2_ADR
P1end:

        ORG P2_ADR 
P2:
        DI
        ld sp,#FFFF

        call wait       ; emulated RTC on Karabas Pro requires some delay

        call rtc_exist  ; not implemented
        jp nz,exit

        call chk_bcdbin
        jp nz,exit

        call set_bin
        jp exit

wait:                   ; ~ 0.25s on 3.5
        ld a,12
loop:
        ld hl,#8000
        ld de,#8000
        ld bc,#1000
        ldir
        dec a
        cp 0
        jr nz,loop
        ret

chk_bcdbin:
        ld d, #0B
        call get_ad
        and #04         ; The data mode (DM ) bit indicates whether time and calendar updates are to use binary or BCD formats.
                        ; '1' in DM signifies binary data, while a '0' in DM specifies binary-coded-decimal (BCD) data.
        ret
set_bin:
        ld d, #0B
        call get_ad
        set 2,a         
                        
        call set_ad
        ret

get_ad:                 ; a - RTC_AD data, d - RTC_AS register number
        ld bc,RTC_AS
        out (c),d
        ld bc,RTC_AD
        in a,(c)
        ret

set_ad:                 ; a - RTC_AD data, d - RTC_AS register number
        ld bc,RTC_AS
        out (c),d
        ld bc,RTC_AD
        out (c),a
        ret

rtc_exist:
        xor a
        ret        
exit:
        ld SP,SPVALUE
        jp EXIT_ADR
P2end:

        SAVEBIN "pqdos_rtc_patch_p1",P1,P1end - P1
        SAVEBIN "pqdos_rtc_patch_p2",P2,P2end - P2

        DISPLAY "Patch1 address = ",P1_ADR," len = ",P1end - P1
        DISPLAY "Patch2 address = ",P2_ADR," len = ",P2end - P2
        DISPLAY "SP reg value = ", SPVALUE

        LUA
            infile   = assert(io.open("bios_pqdos.rom", "rb"))
            outfile  = assert(io.open("bios_pqdos_patched_rtc.rom", "wb"))
            content  = assert(infile:read("*all"))
            assert(outfile:write(content))
            assert(infile:close())
            
            p        = sj.get_label("P1")
            pe       = sj.get_label("P1end") - 1;
            assert(outfile:seek("set",p))
            for i = p, pe, 1 do
                assert(outfile:write(string.char(sj.get_byte(i))))
            end

            p        = sj.get_label("P2")
            pe       = sj.get_label("P2end") - 1;
            assert(outfile:seek("set",p))
            for i = p, pe, 1 do
                assert(outfile:write(string.char(sj.get_byte(i))))
            end

            assert(outfile:flush())
            assert(outfile:close())
        ENDLUA