MODULE SAVELIJ  ;25190
  PUBLIC disk_initialize
  PUBLIC _disk_read
  PUBLIC _disk_write
  PUBLIC disk_status 
  
	RSEG CODE
	
disk_status:
	ld a,0xff
ds_m=$-1
	ret
	        
	
get_params
	push ix
	ld ix,6
	add ix,sp
	ld a,(ix+0)
	ex af,af
	ld a,(ix+4)
	ld h,(ix+3)
	ld l,(ix+2)
	pop ix
	ret
	
;Драйвер SD карты
;LAST UPDATE 14.04.2009 savelij
;Входные параметры общие:
;HL-адрес загрузки в память
;BCDE-32-х битный номер сектора
;A-количество блоков (блок=512 байт) - только для многоблочной записи/чтения
;Ошибки выдаваемые на выходе:
;A=0 - инициализация прошла успешно
;A=1 - карта не найдена или не ответила
;A=2 - карта защищена от записи
;A=3 - попытка записи в сектор 0 карты
P_DATA    EQU 0x0057    ;порт данных
;P_CONF    EQU 0x8057    ;порт конфигурации
P_CONF    EQU 0x0077    ;порт конфигурации
CMD_12    EQU 0x4C    ;STOP_TRANSMISSION
CMD_17    EQU 0x51    ;READ_SINGLE_BLOCK
CMD_18    EQU 0x52    ;READ_MULTIPLE_BLOCK
CMD_24    EQU 0x58    ;WRITE_BLOCK
CMD_25    EQU 0x59    ;WRITE_MULTIPLE_BLOCK
CMD_55    EQU 0x77    ;APP_CMD
CMD_58    EQU 0x7A    ;READ_OCR
CMD_59    EQU 0x7B    ;CRC_ON_OFF
ACMD_41   EQU 0x69   ;SD_SEND_OP_COND


disk_initialize:
    ld a,(ds_m)
    or a
    ret z
    CALL CS_HIGH    ;включаем питание карты при снятом выборе
    LD BC,P_DATA
    LD DE,0x20FF    ;бит выбора карты в <1>
SD_INITloop
    OUT (C),E    ;записываем в порт много единичек
    DEC D    ;количество единичек несколько больше
    JR NZ,SD_INITloop    ;чем надо
    XOR A    ;запускаем счетчик на 256
    EX AF,AF    ;для ожидания инициализации карты
ZAW001    
    LD HL,CMD00    ;даем команду сброса
    CALL OUTCOM    ;этой командой карточка переводится в режим SPI
    CALL IN_OOUT    ;читаем ответ карты
    EX AF,AF
    DEC A
    JP Z,ZAW003    ;если карта 256 раз не ответила, то карты нет
    EX AF,AF
    DEC A
    JR NZ,ZAW001    ;ответ карты <1>, перевод в SPI прошел успешно
    LD HL,CMD08    ;запрос на поддерживаемые напряжения
    CALL OUTCOM    ;команда поддерживается начиная со спецификации
    CALL IN_OOUT    ;версии 2.0 и только SDHC, мини и микро SD картами
    IN H,(C)    ;в A=код ответа карты
    NOP    ;считываем 4 байта длинного ответа
    IN H,(C)    ;но не используем
    NOP
    IN H,(C)
    NOP
    IN H,(C)
    LD HL,0    ;HL=аргумент для команды инициализации
    BIT 2,A    ;если бит 2 установлен, то карта стандартная
    JR NZ,ZAW006    ;стандартная карта выдаст <ошибка команды>
    LD H,0x40    ;если ошибки не было, то карта SDHC, мини или микро SD
ZAW006    
    LD A,CMD_55    ;запускаем процесс внутренней инициализации
    CALL OUT_COM    ;для карт MMC здесь должна быть другая команда
    CALL IN_OOUT    ;соответственно наличие в слоте MMC-карты
    in (c)
    in (c)
	LD A,ACMD_41    ;вызовет зависание драйвера, от применения
    OUT (C),A    ;общей команды запуска инициализации я отказался
    NOP    ;бит 6 установлен для инициализации SDHC карты
    OUT (C),H    ;для стандартной сброшен
    NOP
    OUT (C),L
    NOP
    OUT (C),L
    NOP
    OUT (C),L
    LD A,0xFF
    OUT (C),A
    CALL IN_OOUT    ;ждем перевода карты в режим готовности
    AND A    ;время ожидания примерно 1 секунда
    JR NZ,ZAW006
ZAW004    LD A,CMD_59    ;принудительно отключаем CRC16
    CALL OUT_COM
    CALL IN_OOUT
    AND A
    JR NZ,ZAW004
ZAW005    LD HL,CMD16    ;принудительно задаем размер блока 512 байт
    CALL OUTCOM
    CALL IN_OOUT
    AND A
    JR NZ,ZAW005
	
;запомним размер блока
	ld a,CMD_58 ;READ_OCR
	ld bc,P_DATA
    CALL OUT_COM
    CALL IN_OOUT
	in a,(C)
	nop
	in h,(C) 
	nop
	in h,(C) 
	nop
	in h,(C)
	and 0x40
	ld (zsd_blsize),a
;включение питания карты при снятом сигнале выбора карты
CS_HIGH    
    PUSH AF
    ld bc,P_CONF
    LD A,3
    OUT (c),A    ;включаем питание, снимаем выбор карты
    XOR A
    ld bc,P_DATA
    OUT (c),A    ;обнуляем порт данных
    POP AF    ;обнуление порта можно не делать, просто последний
    ld a,0
	ld (ds_m),a
    RET    ;записанный бит всегда 1, а при сбросе через вывод
        ;данных карты напряжение попадает на вывод питания
        ;карты и светодиод на питании подсвечивается
;возврат при не ответе карты с кодом ошибки 1
ZAW003    
    CALL zsd_off
    ld a,3
    RET
zsd_off    ;patch
	ld bc,P_CONF
    XOR A
    OUT (c),A    ;выключение питания карты
	dec b		;P_DATA
    OUT (c),A    ;обнуление порта данных
    RET
;выбираем карту сигналом 0
CS__LOW    ;patch
    PUSH AF
	ld bc,P_CONF
    LD A,1
    OUT (c),A
    POP AF
    RET
;запись в карту команды с неизменяемым параметром из памяти
;адрес команды в <HL>
OUTCOM    ;patch
    CALL CS__LOW
    LD BC,0x600+P_DATA
    OTIR    ;передаем 6 байт команды из памяти
    RET
;запись в карту команды с нулевыми аргументами
;А-код команды, аргумент команды равен 0
OUT_COM    ;patch
    CALL CS__LOW
    LD BC,P_DATA
    in (c)
    in (c)
    OUT (C),A
    XOR A
    OUT (C),A
    NOP
    OUT (C),A
    NOP
    OUT (C),A
    NOP
    OUT (C),A
    DEC A
    OUT (C),A    ;пишем пустой CRC7 и стоповый бит
    RET
;запись команды чтения/записи с номером сектора в BCDE для карт стандартного размера
;при изменяемом размере сектора номер сектора нужно умножать на его размер, для карт 
;SDHC, мини и микро размер сектора не требует умножения
SECM200    PUSH HL  ;patch
    PUSH AF
	ld h,b
	ld l,c
	call CS__LOW
    LD BC,P_DATA
	ld a,0x00
zsd_blsize=$-1
	or a        
    JR NZ,SECN200    ;не требуется
    EX DE,HL    ;при сброшенном бите соответственно
    ADD HL,HL    ;умножаем номер сектора на 512 (0x200)
    EX DE,HL
    ADC HL,HL
    LD H,L
    LD L,D
    LD D,E
    LD E,0
SECN200    
    POP AF    ;заготовленный номер сектора находится в <HLDE>
    in (c)
    in (c)
    OUT (C),A    ;пишем команду из <А> на SD карту
    NOP    ;записываем 4 байта аргумента
    OUT (C),H    ;пишем номер сектора от старшего
    NOP
    OUT (C),L
    NOP
    OUT (C),D
    NOP
    OUT (C),E    ;до младшего байта
    LD A,0xFF
    OUT (C),A    ;пишем пустой CRC7 и стоповый бит
    POP HL
    RET
;чтение ответа карты до 32 раз, если ответ не 0xFF - немедленный выход
IN_OOUT    ;patch
    push de
    LD DE,0x20FF
	ld bc,P_DATA
IN_WAIT    IN A,(c)
    CP E
    JR NZ,IN_EXIT
IN_NEXT    DEC D
    JR NZ,IN_WAIT
IN_EXIT    POP DE
    RET
CMD00    DEFB  0x40,0x00,0x00,0x00,0x00,0x95 ;GO_IDLE_STATE
    ;команда сброса и перевода карты в SPI режим после включения питания
CMD08    DEFB  0x48,0x00,0x00,0x01,0xAA,0x87 ;SEND_IF_COND
    ;запрос поддерживаемых напряжений
CMD16    DEFB 0x50,0x00,0x00,0x02,0x00,0xFF ;SET_BLOCKEN
    ;команда изменения размера 
;многосекторное чтение

_disk_read:
    call get_params 
    LD A,CMD_18
    CALL SECM200    ;даем команду многосекторного чтения
    EX AF,AF
RDMULT1    EX AF,AF
RDMULT2
    CALL IN_OOUT
    CP 0xFE
    JR NZ,RDMULT2    ;ждем маркер готовности 0xFE для начала чтения
    LD BC,P_DATA
    INIR
    nop
    INIR
	nop
    IN A,(C)
    NOP
    IN A,(C)
    EX AF,AF
    DEC A
    JR NZ,RDMULT1    ;продолжаем пока не обнулится счетчик
    LD A,CMD_12    ;по окончании чтения даем команду карте <СТОП>
    CALL OUT_COM    ;команда мультичтения не имеет счетчика и
RDMULT3
    CALL IN_OOUT    ;должна останавливаться здесь командой 12
    INC A
    JR NZ,RDMULT3    ;ждем освобождения карты
    JP CS_HIGH    ;снимаем выбор с карты и выходим с кодом 0

;многосекторная запись

_disk_write:
    call get_params 
    LD A,CMD_25 ;даем команду мультисекторной записи
    CALL SECM200
WRMULTI2
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI2 ;ждем освобождения карты
    EX AF,AF
WRMULT1 EX AF,AF
    LD A,0xFC ;пишем стартовый маркер, сам блок и пустое CRC16
    LD BC,P_DATA
    OUT (C),A
    LD B,0x80
    OTIR
    LD B,0x80
    OTIR
    LD B,0x80
    OTIR
    LD B,0x80
    OTIR
    LD A,0xFF
    OUT (C),A
    NOP
    OUT (C),A
WRMULTI3
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI3 ;ждем освобождения карты
    EX AF,AF
    DEC A
    JR NZ,WRMULT1 ;продолжаем пока счетчик не обнулится
    LD C,P_DATA
    LD A,0xFD
    OUT (C),A ;даем команду остановки записи
WRMULTI4
    CALL IN_OOUT
    INC A
    JR NZ,WRMULTI4 ;ждем освобождения карты
    JP CS_HIGH ;снимаем выбор карты и выходим с кодом 0

END


