EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A2 23386 16535
encoding utf-8
Sheet 1 1
Title "Karabas Pro"
Date "2020-07-25"
Rev "B"
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L cfcard:CF-CARD CON1
U 1 1 5F3362AF
P 9850 10150
F 0 "CON1" H 9850 11931 50  0000 C CNN
F 1 "CF-CARD" H 9850 11840 50  0000 C CNN
F 2 "footprints:TE_1734451-1" H 9880 10300 20  0001 C CNN
F 3 "" H 9850 10150 60  0000 C CNN
	1    9850 10150
	1    0    0    -1  
$EndComp
$Comp
L Connector:SD_Card CON2
U 1 1 5F337F4E
P 12800 6600
F 0 "CON2" H 12858 7293 60  0000 C CNN
F 1 "SD" H 12858 7187 60  0000 C CNN
F 2 "Connector_Card:SD_TE_2041021" H 12858 7081 60  0001 C CNN
F 3 "" H 12650 6600 60  0000 C CNN
	1    12800 6600
	1    0    0    -1  
$EndComp
$Comp
L Connector:DB15_Female_HighDensity CON3
U 1 1 5F338B53
P 12650 1900
F 0 "CON3" H 12650 2767 50  0000 C CNN
F 1 "VGA" H 12650 2676 50  0000 C CNN
F 2 "Connector_Dsub:DSUB-15-HD_Female_Horizontal_P2.29x1.98mm_EdgePinOffset3.03mm_Housed_MountingHolesOffset4.94mm" H 11700 2300 50  0001 C CNN
F 3 " ~" H 11700 2300 50  0001 C CNN
	1    12650 1900
	1    0    0    -1  
$EndComp
$Comp
L Connector:DB9_Female_MountingHoles CON4
U 1 1 5F3394C4
P 12700 5250
F 0 "CON4" H 12880 5252 50  0000 L CNN
F 1 "Joystick" H 12880 5161 50  0000 L CNN
F 2 "Connector_Dsub:DSUB-9_Male_Horizontal_P2.77x2.84mm_EdgePinOffset4.94mm_Housed_MountingHolesOffset7.48mm" H 12700 5250 50  0001 C CNN
F 3 " ~" H 12700 5250 50  0001 C CNN
	1    12700 5250
	1    0    0    -1  
$EndComp
$Comp
L retro:Mini-DIN-6 CON5
U 1 1 5F33A7DF
P 12650 3250
F 0 "CON5" H 12650 3617 50  0000 C CNN
F 1 "Keyboard" H 12650 3526 50  0000 C CNN
F 2 "footprints:MINI_DIN_6_33PRIMARY" H 12650 3250 50  0001 C CNN
F 3 "http://service.powerdynamics.com/ec/Catalog17/Section%2011.pdf" H 12650 3250 50  0001 C CNN
	1    12650 3250
	1    0    0    -1  
$EndComp
$Comp
L retro:Mini-DIN-6 CON6
U 1 1 5F33B38D
P 12650 4250
F 0 "CON6" H 12650 4617 50  0000 C CNN
F 1 "Mouse" H 12650 4526 50  0000 C CNN
F 2 "footprints:MINI_DIN_6_33PRIMARY" H 12650 4250 50  0001 C CNN
F 3 "http://service.powerdynamics.com/ec/Catalog17/Section%2011.pdf" H 12650 4250 50  0001 C CNN
	1    12650 4250
	1    0    0    -1  
$EndComp
$Comp
L Connector:AudioJack3 CON7
U 1 1 5F33D29B
P 12100 7650
F 0 "CON7" H 12082 7975 50  0000 C CNN
F 1 "Audio" H 12082 7884 50  0000 C CNN
F 2 "Connector_Audio:Jack_3.5mm_CUI_SJ1-3535NG_Horizontal" H 12100 7650 50  0001 C CNN
F 3 "~" H 12100 7650 50  0001 C CNN
	1    12100 7650
	-1   0    0    -1  
$EndComp
$Comp
L Connector:Barrel_Jack_Switch CON8
U 1 1 5F33F556
P 16700 1900
F 0 "CON8" H 16757 2217 50  0000 C CNN
F 1 "5V DC" H 16757 2126 50  0000 C CNN
F 2 "Connector_BarrelJack:BarrelJack_Wuerth_6941xx301002" H 16750 1860 50  0001 C CNN
F 3 "~" H 16750 1860 50  0001 C CNN
	1    16700 1900
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x17_Odd_Even J1
U 1 1 5F345670
P 5850 7800
F 0 "J1" H 5900 8817 50  0000 C CNN
F 1 "Floppy" H 5900 8726 50  0000 C CNN
F 2 "Connector_IDC:IDC-Header_2x17_P2.54mm_Vertical" H 5850 7800 50  0001 C CNN
F 3 "~" H 5850 7800 50  0001 C CNN
	1    5850 7800
	-1   0    0    -1  
$EndComp
$Comp
L retro:MB8877A U6
U 1 1 5F3485A8
P 1900 7850
F 0 "U6" H 1900 9031 50  0000 C CNN
F 1 "MB8877A" H 2000 8950 50  0000 C CNN
F 2 "Package_DIP:DIP-40_W15.24mm" H 1900 6650 50  0001 C CNN
F 3 "https://amaus.net/static/S100/western%20digital/datasheet/Western%20Digital%20FD1771%20Specification%20197710.pdf" H 1900 7850 50  0001 C CNN
	1    1900 7850
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H1
U 1 1 5F34B048
P 17550 14000
F 0 "H1" H 17650 14046 50  0000 L CNN
F 1 "MountingHole" H 17650 13955 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 14000 50  0001 C CNN
F 3 "~" H 17550 14000 50  0001 C CNN
	1    17550 14000
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H2
U 1 1 5F34C3F9
P 17550 14200
F 0 "H2" H 17650 14246 50  0000 L CNN
F 1 "MountingHole" H 17650 14155 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 14200 50  0001 C CNN
F 3 "~" H 17550 14200 50  0001 C CNN
	1    17550 14200
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H3
U 1 1 5F34C76D
P 17550 14400
F 0 "H3" H 17650 14446 50  0000 L CNN
F 1 "MountingHole" H 17650 14355 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 14400 50  0001 C CNN
F 3 "~" H 17550 14400 50  0001 C CNN
	1    17550 14400
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H4
U 1 1 5F34CA0C
P 17550 14600
F 0 "H4" H 17650 14646 50  0000 L CNN
F 1 "MountingHole" H 17650 14555 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 14600 50  0001 C CNN
F 3 "~" H 17550 14600 50  0001 C CNN
	1    17550 14600
	1    0    0    -1  
$EndComp
$Comp
L retro:EP4CE6E22C8N U1
U 1 1 5FE23A00
P 3550 3300
F 0 "U1" H 3550 3350 50  0000 L CNN
F 1 "EP4CE6E22C8N" H 3300 3200 50  0000 L CNN
F 2 "footprints:ALTERA-QFP-145" H 3550 3300 50  0001 C CNN
F 3 "" H 3550 3300 50  0001 C CNN
	1    3550 3300
	1    0    0    -1  
$EndComp
$Comp
L Timer_RTC:DS1307Z+ U9
U 1 1 5EAB43C4
P 9750 7300
F 0 "U9" H 10294 7346 50  0000 L CNN
F 1 "DS1307Z+" H 10294 7255 50  0000 L CNN
F 2 "Package_SO:SOIC-8_3.9x4.9mm_P1.27mm" H 9750 6800 50  0001 C CNN
F 3 "https://datasheets.maximintegrated.com/en/ds/DS1307.pdf" H 9750 7300 50  0001 C CNN
	1    9750 7300
	1    0    0    -1  
$EndComp
$Comp
L Memory_Flash:W25Q32JVSS U3
U 1 1 5EAB52DA
P 7400 6300
F 0 "U3" H 7400 6881 50  0000 C CNN
F 1 "M25P16" H 7400 6790 50  0000 C CNN
F 2 "Package_SO:SOIC-8_5.23x5.23mm_P1.27mm" H 7400 6300 50  0001 C CNN
F 3 "http://www.winbond.com/resource-files/w25q32jv%20revg%2003272018%20plus.pdf" H 7400 6300 50  0001 C CNN
	1    7400 6300
	1    0    0    -1  
$EndComp
$Comp
L Oscillator:SG-7050CAN X1
U 1 1 5EAB6A81
P 7600 5100
F 0 "X1" H 7944 5146 50  0000 L CNN
F 1 "SG-7050CAN" H 7944 5055 50  0000 L CNN
F 2 "Oscillator:Oscillator_SMD_SeikoEpson_SG8002CA-4Pin_7.0x5.0mm" H 8300 4750 50  0001 C CNN
F 3 "https://support.epson.biz/td/api/doc_check.php?dl=brief_SG7050CAN&lang=en" H 7500 5100 50  0001 C CNN
	1    7600 5100
	1    0    0    -1  
$EndComp
$Comp
L Device:Battery_Cell BT1
U 1 1 5EAB86CE
P 10350 6900
F 0 "BT1" V 10500 7050 50  0000 L CNN
F 1 "3V" H 10200 6850 50  0000 L CNN
F 2 "Battery:BatteryHolder_Keystone_103_1x20mm" V 10350 6960 50  0001 C CNN
F 3 "~" V 10350 6960 50  0001 C CNN
	1    10350 6900
	0    -1   -1   0   
$EndComp
$Comp
L Regulator_Linear:AMS1117-3.3 U12
U 1 1 5EAC1E6A
P 17850 1800
F 0 "U12" H 17850 2042 50  0000 C CNN
F 1 "AMS1117-3.3" H 17850 1951 50  0000 C CNN
F 2 "Package_TO_SOT_SMD:SOT-223-3_TabPin2" H 17850 2000 50  0001 C CNN
F 3 "http://www.advanced-monolithic.com/pdf/ds1117.pdf" H 17950 1550 50  0001 C CNN
	1    17850 1800
	1    0    0    -1  
$EndComp
$Comp
L Regulator_Linear:AMS1117-2.5 U13
U 1 1 5EAC347B
P 17850 2550
F 0 "U13" H 17650 2800 50  0000 C CNN
F 1 "AMS1117-2.5" H 17850 2701 50  0000 C CNN
F 2 "Package_TO_SOT_SMD:SOT-223-3_TabPin2" H 17850 2750 50  0001 C CNN
F 3 "http://www.advanced-monolithic.com/pdf/ds1117.pdf" H 17950 2300 50  0001 C CNN
	1    17850 2550
	1    0    0    -1  
$EndComp
$Comp
L Regulator_Linear:AMS1117 U14
U 1 1 5EAC46E9
P 17850 3350
F 0 "U14" H 17850 3592 50  0000 C CNN
F 1 "AMS1117-1.2" H 17850 3501 50  0000 C CNN
F 2 "Package_TO_SOT_SMD:SOT-223-3_TabPin2" H 17850 3550 50  0001 C CNN
F 3 "http://www.advanced-monolithic.com/pdf/ds1117.pdf" H 17950 3100 50  0001 C CNN
	1    17850 3350
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic_Shielded:Conn_02x05_Odd_Even_Shielded J2
U 1 1 5EADFEAD
P 7550 7300
F 0 "J2" H 7600 7715 50  0000 C CNN
F 1 "FPGA JTAG" H 7600 7624 50  0000 C CNN
F 2 "Connector_IDC:IDC-Header_2x05_P2.54mm_Horizontal" H 7550 7300 50  0001 C CNN
F 3 "~" H 7550 7300 50  0001 C CNN
	1    7550 7300
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H5
U 1 1 5ED90FCA
P 17550 14950
F 0 "H5" H 17650 14996 50  0000 L CNN
F 1 "MountingHole" H 17650 14905 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 14950 50  0001 C CNN
F 3 "~" H 17550 14950 50  0001 C CNN
	1    17550 14950
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H6
U 1 1 5ED90FD4
P 17550 15150
F 0 "H6" H 17650 15196 50  0000 L CNN
F 1 "MountingHole" H 17650 15105 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 15150 50  0001 C CNN
F 3 "~" H 17550 15150 50  0001 C CNN
	1    17550 15150
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H7
U 1 1 5ED90FDE
P 17550 15350
F 0 "H7" H 17650 15396 50  0000 L CNN
F 1 "MountingHole" H 17650 15305 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 15350 50  0001 C CNN
F 3 "~" H 17550 15350 50  0001 C CNN
	1    17550 15350
	1    0    0    -1  
$EndComp
$Comp
L Mechanical:MountingHole H8
U 1 1 5ED90FE8
P 17550 15550
F 0 "H8" H 17650 15596 50  0000 L CNN
F 1 "MountingHole" H 17650 15505 50  0000 L CNN
F 2 "MountingHole:MountingHole_3.5mm_Pad_Via" H 17550 15550 50  0001 C CNN
F 3 "~" H 17550 15550 50  0001 C CNN
	1    17550 15550
	1    0    0    -1  
$EndComp
$Comp
L tda1543:TDA1543 U11
U 1 1 5ED9FA08
P 9600 5850
F 0 "U11" H 9625 6175 50  0000 C CNN
F 1 "TDA1543" H 9625 6084 50  0000 C CNN
F 2 "Package_DIP:DIP-8_W7.62mm" H 9600 5850 50  0001 C CNN
F 3 "" H 9600 5850 50  0001 C CNN
	1    9600 5850
	1    0    0    -1  
$EndComp
$Comp
L SparkFun-Connectors:CONN_04 J3
U 1 1 5EDAAADB
P 16700 3200
F 0 "J3" H 16658 3810 45  0000 C CNN
F 1 "Floppy 5V" H 16658 3726 45  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical" H 16700 3700 20  0001 C CNN
F 3 "" H 16700 3200 50  0001 C CNN
F 4 "CONN-09696" H 16658 3631 60  0001 C CNN "Field4"
	1    16700 3200
	1    0    0    -1  
$EndComp
$Comp
L dk_Embedded-Microcontrollers:ATMEGA328-AU U5
U 1 1 5EDB1004
P 10100 2000
F 0 "U5" H 9750 2850 60  0000 L CNN
F 1 "ATMEGA328-AU" H 9750 2750 60  0000 L CNN
F 2 "Package_QFP:TQFP-32_7x7mm_P0.8mm" H 10300 2200 60  0001 L CNN
F 3 "http://www.microchip.com/mymicrochip/filehandler.aspx?ddocname=en608326" H 10300 2300 60  0001 L CNN
F 4 "ATMEGA328-AU-ND" H 10300 2400 60  0001 L CNN "Digi-Key_PN"
F 5 "ATMEGA328-AU" H 10300 2500 60  0001 L CNN "MPN"
F 6 "Integrated Circuits (ICs)" H 10300 2600 60  0001 L CNN "Category"
F 7 "Embedded - Microcontrollers" H 10300 2700 60  0001 L CNN "Family"
F 8 "http://www.microchip.com/mymicrochip/filehandler.aspx?ddocname=en608326" H 10300 2800 60  0001 L CNN "DK_Datasheet_Link"
F 9 "/product-detail/en/microchip-technology/ATMEGA328-AU/ATMEGA328-AU-ND/2271029" H 10300 2900 60  0001 L CNN "DK_Detail_Page"
F 10 "IC MCU 8BIT 32KB FLASH 32TQFP" H 10300 3000 60  0001 L CNN "Description"
F 11 "Microchip Technology" H 10300 3100 60  0001 L CNN "Manufacturer"
F 12 "Active" H 10300 3200 60  0001 L CNN "Status"
	1    10100 2000
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x03_Odd_Even J5
U 1 1 5EDC3E90
P 9450 5000
F 0 "J5" H 9500 5317 50  0000 C CNN
F 1 "AVR JTAG" H 9500 5226 50  0000 C CNN
F 2 "Connector_IDC:IDC-Header_2x03_P2.54mm_Horizontal" H 9450 5000 50  0001 C CNN
F 3 "~" H 9450 5000 50  0001 C CNN
	1    9450 5000
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS06 U17
U 2 1 5EDDACDE
P 4050 10150
F 0 "U17" H 4050 10467 50  0000 C CNN
F 1 "74LS06" H 4050 10376 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 10150 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 4050 10150 50  0001 C CNN
	2    4050 10150
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS06 U17
U 3 1 5EDDB681
P 4050 7550
F 0 "U17" H 4050 7867 50  0000 C CNN
F 1 "74LS06" H 4050 7776 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 7550 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 4050 7550 50  0001 C CNN
	3    4050 7550
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS06 U17
U 4 1 5EDDC011
P 4050 8550
F 0 "U17" H 4050 8867 50  0000 C CNN
F 1 "74LS06" H 4050 8776 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 8550 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 4050 8550 50  0001 C CNN
	4    4050 8550
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS06 U17
U 5 1 5EDDCD63
P 4050 8050
F 0 "U17" H 4050 8367 50  0000 C CNN
F 1 "74LS06" H 4050 8276 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 8050 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 4050 8050 50  0001 C CNN
	5    4050 8050
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS06 U17
U 6 1 5EDDDC57
P 4050 7050
F 0 "U17" H 4050 7367 50  0000 C CNN
F 1 "74LS06" H 4050 7276 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 7050 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 4050 7050 50  0001 C CNN
	6    4050 7050
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS06 U17
U 7 1 5EDDEA20
P 1650 10650
F 0 "U17" H 1880 10696 50  0000 L CNN
F 1 "74LS06" H 1880 10605 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 1650 10650 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 1650 10650 50  0001 C CNN
	7    1650 10650
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS38 U18
U 1 1 5EDE0058
P 4050 9050
F 0 "U18" H 4050 9375 50  0000 C CNN
F 1 "74LS38" H 4050 9284 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 9050 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS38" H 4050 9050 50  0001 C CNN
	1    4050 9050
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS38 U18
U 2 1 5EDE140D
P 4050 9600
F 0 "U18" H 4050 9925 50  0000 C CNN
F 1 "74LS38" H 4050 9834 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 9600 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS38" H 4050 9600 50  0001 C CNN
	2    4050 9600
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS38 U18
U 3 1 5EDE26A6
P 2400 9700
F 0 "U18" H 2400 10025 50  0000 C CNN
F 1 "74LS38" H 2400 9934 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 2400 9700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS38" H 2400 9700 50  0001 C CNN
	3    2400 9700
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS38 U18
U 4 1 5EDE3C5B
P 1650 9700
F 0 "U18" H 1650 10025 50  0000 C CNN
F 1 "74LS38" H 1650 9934 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 1650 9700 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS38" H 1650 9700 50  0001 C CNN
	4    1650 9700
	1    0    0    -1  
$EndComp
$Comp
L 74xx:74LS38 U18
U 5 1 5EDE4EC9
P 2400 10650
F 0 "U18" H 2630 10696 50  0000 L CNN
F 1 "74LS38" H 2630 10605 50  0000 L CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 2400 10650 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS38" H 2400 10650 50  0001 C CNN
	5    2400 10650
	1    0    0    -1  
$EndComp
$Comp
L retro:CY62167ELL U2
U 1 1 5EDF5C3C
P 7650 2850
F 0 "U2" H 7650 4367 50  0000 C CNN
F 1 "CY62167EV30" H 7650 4276 50  0000 C CNN
F 2 "Package_SO:TSOP-I-48_18.4x12mm_P0.5mm" H 7850 4250 50  0001 C CNN
F 3 "" H 7850 4250 50  0001 C CNN
	1    7650 2850
	1    0    0    -1  
$EndComp
$Comp
L Switch:SW_Push SW1
U 1 1 5EE0C4C4
P 12150 8600
F 0 "SW1" H 12150 8885 50  0000 C CNN
F 1 "SW_Push" H 12150 8794 50  0000 C CNN
F 2 "Button_Switch_THT:SW_Tactile_SPST_Angled_PTS645Vx58-2LFS" H 12150 8800 50  0001 C CNN
F 3 "~" H 12150 8800 50  0001 C CNN
	1    12150 8600
	1    0    0    -1  
$EndComp
$Comp
L Switch:SW_Push SW2
U 1 1 5EE0EBA6
P 12150 9050
F 0 "SW2" H 12150 9335 50  0000 C CNN
F 1 "SW_Push" H 12150 9244 50  0000 C CNN
F 2 "Button_Switch_THT:SW_Tactile_SPST_Angled_PTS645Vx58-2LFS" H 12150 9250 50  0001 C CNN
F 3 "~" H 12150 9250 50  0001 C CNN
	1    12150 9050
	1    0    0    -1  
$EndComp
Wire Bus Line
	6500 700  8750 700 
Connection ~ 6500 700 
Wire Bus Line
	8750 700  11050 700 
Connection ~ 8750 700 
Entry Wire Line
	700  1700 800  1800
Entry Wire Line
	700  1800 800  1900
Entry Wire Line
	700  1900 800  2000
Entry Wire Line
	700  2000 800  2100
Entry Wire Line
	700  2100 800  2200
Entry Wire Line
	700  2200 800  2300
Entry Wire Line
	700  2400 800  2500
Entry Wire Line
	700  2500 800  2600
Entry Wire Line
	700  2700 800  2800
Entry Wire Line
	700  2800 800  2900
Entry Wire Line
	700  2900 800  3000
Entry Wire Line
	700  3000 800  3100
Entry Wire Line
	700  3100 800  3200
Entry Wire Line
	700  3200 800  3300
Entry Wire Line
	700  3300 800  3400
Entry Wire Line
	700  3400 800  3500
Entry Wire Line
	700  3500 800  3600
Entry Wire Line
	700  3600 800  3700
Entry Wire Line
	700  3700 800  3800
Entry Wire Line
	700  3800 800  3900
Entry Wire Line
	700  3900 800  4000
Entry Wire Line
	700  4200 800  4300
Entry Wire Line
	700  4300 800  4400
Entry Wire Line
	700  4400 800  4500
Entry Wire Line
	700  4500 800  4600
Entry Wire Line
	700  4600 800  4700
Entry Wire Line
	700  4700 800  4800
Entry Wire Line
	700  4800 800  4900
Entry Wire Line
	700  4900 800  5000
Entry Wire Line
	700  5000 800  5100
Entry Wire Line
	700  5100 800  5200
Entry Wire Line
	700  5200 800  5300
Wire Wire Line
	800  1800 1500 1800
Wire Wire Line
	800  1900 1500 1900
Wire Wire Line
	800  2000 1500 2000
Wire Wire Line
	800  2100 1500 2100
Wire Wire Line
	1500 2200 800  2200
Wire Wire Line
	800  2300 1500 2300
Wire Wire Line
	800  2500 1500 2500
Wire Wire Line
	1500 2600 800  2600
Wire Wire Line
	1500 2800 800  2800
Wire Wire Line
	800  2900 1500 2900
Wire Wire Line
	1500 3000 800  3000
Wire Wire Line
	800  3100 1500 3100
Wire Wire Line
	1500 3200 800  3200
Wire Wire Line
	800  3300 1500 3300
Wire Wire Line
	1500 3400 800  3400
Wire Wire Line
	800  3500 1500 3500
Wire Wire Line
	1500 3600 800  3600
Wire Wire Line
	800  3700 1500 3700
Wire Wire Line
	1500 3800 800  3800
Wire Wire Line
	800  3900 1500 3900
Wire Wire Line
	1500 4000 800  4000
Wire Wire Line
	800  4300 1500 4300
Wire Wire Line
	1500 4400 800  4400
Wire Wire Line
	800  4500 1500 4500
Wire Wire Line
	1500 4600 800  4600
Wire Wire Line
	800  4700 1500 4700
Wire Wire Line
	1500 4800 800  4800
Wire Wire Line
	800  4900 1500 4900
Wire Wire Line
	1500 5000 800  5000
Wire Wire Line
	800  5100 1500 5100
Wire Wire Line
	1500 5200 800  5200
Wire Wire Line
	800  5300 1500 5300
$Comp
L power:VCC #PWR0101
U 1 1 5F40B251
P 17250 1500
F 0 "#PWR0101" H 17250 1350 50  0001 C CNN
F 1 "VCC" H 17265 1673 50  0000 C CNN
F 2 "" H 17250 1500 50  0001 C CNN
F 3 "" H 17250 1500 50  0001 C CNN
	1    17250 1500
	1    0    0    -1  
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0102
U 1 1 5F40BC72
P 18250 1500
F 0 "#PWR0102" H 18250 1350 50  0001 C CNN
F 1 "VCC3_3" H 18267 1673 50  0000 C CNN
F 2 "" H 18250 1500 50  0001 C CNN
F 3 "" H 18250 1500 50  0001 C CNN
	1    18250 1500
	1    0    0    -1  
$EndComp
$Comp
L vcc25:VCC2_5 #PWR0103
U 1 1 5F40C9C4
P 18250 2250
F 0 "#PWR0103" H 18250 2100 50  0001 C CNN
F 1 "VCC2_5" H 18267 2423 50  0000 C CNN
F 2 "" H 18250 2250 50  0001 C CNN
F 3 "" H 18250 2250 50  0001 C CNN
	1    18250 2250
	1    0    0    -1  
$EndComp
$Comp
L vcc12:VCC1_2 #PWR0104
U 1 1 5F40CEF4
P 18300 3050
F 0 "#PWR0104" H 18300 2900 50  0001 C CNN
F 1 "VCC1_2" H 18317 3223 50  0000 C CNN
F 2 "" H 18300 3050 50  0001 C CNN
F 3 "" H 18300 3050 50  0001 C CNN
	1    18300 3050
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0105
U 1 1 5F40D3EB
P 17000 2100
F 0 "#PWR0105" H 17000 1850 50  0001 C CNN
F 1 "GND" H 17005 1927 50  0000 C CNN
F 2 "" H 17000 2100 50  0001 C CNN
F 3 "" H 17000 2100 50  0001 C CNN
	1    17000 2100
	1    0    0    -1  
$EndComp
Text Label 800  2100 0    50   ~ 0
GND
Text Label 800  2200 0    50   ~ 0
VCC1_2
Text Label 800  2300 0    50   ~ 0
ASDO
Text Label 800  2500 0    50   ~ 0
NCSO
Text Label 800  2600 0    50   ~ 0
NSTATUS
Text Label 800  2900 0    50   ~ 0
DCLK
Text Label 800  3000 0    50   ~ 0
DATA0
Text Label 800  3100 0    50   ~ 0
NCONFIG
Text Label 800  3200 0    50   ~ 0
TDI1
Text Label 800  3300 0    50   ~ 0
TCK
Text Label 800  3400 0    50   ~ 0
VCC3_3
Text Label 800  3500 0    50   ~ 0
TMS
Text Label 800  3600 0    50   ~ 0
GND
Text Label 800  3700 0    50   ~ 0
TDO
Text Label 800  3800 0    50   ~ 0
GND
Text Label 800  3900 0    50   ~ 0
GND
Text Label 800  4000 0    50   ~ 0
CLK_50MHZ
Text Label 800  4300 0    50   ~ 0
VCC3_3
Text Label 800  4400 0    50   ~ 0
GND
Text Label 800  4600 0    50   ~ 0
VCC1_2
Text Label 800  5200 0    50   ~ 0
VCC2_5
Text Label 800  5300 0    50   ~ 0
GND
Entry Wire Line
	1850 6350 1950 6250
Entry Wire Line
	1950 6350 2050 6250
Entry Wire Line
	2050 6350 2150 6250
Entry Wire Line
	2150 6350 2250 6250
Entry Wire Line
	2250 6350 2350 6250
Entry Wire Line
	2350 6350 2450 6250
Entry Wire Line
	2450 6350 2550 6250
Entry Wire Line
	2550 6350 2650 6250
Entry Wire Line
	2650 6350 2750 6250
Entry Wire Line
	2750 6350 2850 6250
Entry Wire Line
	2850 6350 2950 6250
Entry Wire Line
	2950 6350 3050 6250
Entry Wire Line
	3050 6350 3150 6250
Entry Wire Line
	3150 6350 3250 6250
Entry Wire Line
	3250 6350 3350 6250
Entry Wire Line
	3350 6350 3450 6250
Entry Wire Line
	3450 6350 3550 6250
Entry Wire Line
	3550 6350 3650 6250
Entry Wire Line
	3650 6350 3750 6250
Entry Wire Line
	3750 6350 3850 6250
Entry Wire Line
	3850 6350 3950 6250
Entry Wire Line
	3950 6350 4050 6250
Entry Wire Line
	4050 6350 4150 6250
Entry Wire Line
	4150 6350 4250 6250
Entry Wire Line
	4250 6350 4350 6250
Entry Wire Line
	4350 6350 4450 6250
Entry Wire Line
	4450 6350 4550 6250
Entry Wire Line
	4550 6350 4650 6250
Entry Wire Line
	4650 6350 4750 6250
Entry Wire Line
	4750 6350 4850 6250
Entry Wire Line
	4850 6350 4950 6250
Entry Wire Line
	4950 6350 5050 6250
Entry Wire Line
	5050 6350 5150 6250
Entry Wire Line
	5150 6350 5250 6250
Entry Wire Line
	5250 6350 5350 6250
Entry Wire Line
	5350 6350 5450 6250
Wire Wire Line
	5450 5700 5450 6250
Wire Wire Line
	5350 6250 5350 5700
Wire Wire Line
	5250 5700 5250 6250
Wire Wire Line
	5150 6250 5150 5700
Wire Wire Line
	5050 5700 5050 6250
Wire Wire Line
	4950 6250 4950 5700
Wire Wire Line
	4850 5700 4850 6250
Wire Wire Line
	4750 6250 4750 5700
Wire Wire Line
	4650 5700 4650 6250
Wire Wire Line
	4550 6250 4550 5700
Wire Wire Line
	4450 5700 4450 6250
Wire Wire Line
	4350 6250 4350 5700
Wire Wire Line
	4250 5700 4250 6250
Wire Wire Line
	4150 6250 4150 5700
Wire Wire Line
	4050 5700 4050 6250
Wire Wire Line
	3950 6250 3950 5700
Wire Wire Line
	3850 5700 3850 6250
Wire Wire Line
	3750 6250 3750 5700
Wire Wire Line
	3650 5700 3650 6250
Wire Wire Line
	3550 6250 3550 5700
Wire Wire Line
	3450 5700 3450 6250
Wire Wire Line
	3350 6250 3350 5700
Wire Wire Line
	3250 5700 3250 6250
Wire Wire Line
	3150 6250 3150 5700
Wire Wire Line
	3050 5700 3050 6250
Wire Wire Line
	2950 6250 2950 5700
Wire Wire Line
	2850 5700 2850 6250
Wire Wire Line
	2750 6250 2750 5700
Wire Wire Line
	2650 5700 2650 6250
Wire Wire Line
	2550 6250 2550 5700
Wire Wire Line
	2450 5700 2450 6250
Wire Wire Line
	2350 6250 2350 5700
Wire Wire Line
	2250 5700 2250 6250
Wire Wire Line
	2150 6250 2150 5700
Wire Wire Line
	2050 5700 2050 6250
Wire Wire Line
	1950 6250 1950 5700
Text Label 1950 6250 1    50   ~ 0
VCC1_2
Text Label 2250 6250 1    50   ~ 0
VCC3_3
Text Label 2350 6250 1    50   ~ 0
GND
Text Label 2750 6250 1    50   ~ 0
VCC1_2
Text Label 2950 6250 1    50   ~ 0
VCC3_3
Text Label 3050 6250 1    50   ~ 0
GND
Text Label 3850 6250 1    50   ~ 0
VCC3_3
Text Label 3950 6250 1    50   ~ 0
GND
Text Label 4350 6250 1    50   ~ 0
VCC1_2
Text Label 4450 6250 1    50   ~ 0
VCC3_3
Text Label 4550 6250 1    50   ~ 0
GND
Entry Wire Line
	6500 1500 6600 1600
Entry Wire Line
	6500 1600 6600 1700
Entry Wire Line
	6500 1700 6600 1800
Entry Wire Line
	6500 1800 6600 1900
Entry Wire Line
	6500 1900 6600 2000
Entry Wire Line
	6500 2000 6600 2100
Entry Wire Line
	6500 2100 6600 2200
Entry Wire Line
	6500 2200 6600 2300
Entry Wire Line
	6500 2300 6600 2400
Entry Wire Line
	6500 2400 6600 2500
Entry Wire Line
	6500 2500 6600 2600
Entry Wire Line
	6500 2600 6600 2700
Entry Wire Line
	6500 2700 6600 2800
Entry Wire Line
	6500 2800 6600 2900
Entry Wire Line
	6500 2900 6600 3000
Entry Wire Line
	6500 3000 6600 3100
Entry Wire Line
	6500 3100 6600 3200
Entry Wire Line
	6500 3200 6600 3300
Entry Wire Line
	6500 3300 6600 3400
Entry Wire Line
	6500 3400 6600 3500
Entry Wire Line
	6500 3600 6600 3700
Entry Wire Line
	6500 3900 6600 4000
Entry Wire Line
	6500 4000 6600 4100
Entry Wire Line
	6500 4100 6600 4200
Entry Wire Line
	6500 4200 6600 4300
Entry Wire Line
	8650 1600 8750 1500
Entry Wire Line
	8650 1700 8750 1600
Entry Wire Line
	8650 1800 8750 1700
Entry Wire Line
	8650 1900 8750 1800
Entry Wire Line
	8650 2000 8750 1900
Entry Wire Line
	8650 2100 8750 2000
Entry Wire Line
	8650 2200 8750 2100
Entry Wire Line
	8650 2300 8750 2200
Entry Wire Line
	8650 3350 8750 3250
Entry Wire Line
	8650 4100 8750 4000
Entry Wire Line
	8650 4200 8750 4100
Entry Wire Line
	8650 4300 8750 4200
Wire Wire Line
	6600 1600 7100 1600
Wire Wire Line
	7100 1700 6600 1700
Wire Wire Line
	6600 1800 7100 1800
Wire Wire Line
	7100 1900 6600 1900
Wire Wire Line
	6600 2000 7100 2000
Wire Wire Line
	7100 2100 6600 2100
Wire Wire Line
	6600 2200 7100 2200
Wire Wire Line
	7100 2300 6600 2300
Wire Wire Line
	6600 2400 7100 2400
Wire Wire Line
	7100 2500 6600 2500
Wire Wire Line
	6600 2600 7100 2600
Wire Wire Line
	7100 2700 6600 2700
Wire Wire Line
	6600 2800 7100 2800
Wire Wire Line
	7100 2900 6600 2900
Wire Wire Line
	6600 3000 7100 3000
Wire Wire Line
	7100 3100 6600 3100
Wire Wire Line
	6600 3200 7100 3200
Wire Wire Line
	7100 3300 6600 3300
Wire Wire Line
	6600 3400 7100 3400
Wire Wire Line
	7100 3500 6600 3500
Wire Wire Line
	6600 3700 7100 3700
Wire Wire Line
	7100 4000 6600 4000
Wire Wire Line
	6600 4100 7100 4100
Wire Wire Line
	7100 4200 6600 4200
Wire Wire Line
	6600 4300 7100 4300
Wire Wire Line
	8200 4100 8650 4100
Wire Wire Line
	8650 4200 8200 4200
Wire Wire Line
	8200 4300 8650 4300
Wire Wire Line
	8200 3350 8650 3350
Wire Wire Line
	8200 1600 8650 1600
Wire Wire Line
	8650 1700 8200 1700
Wire Wire Line
	8200 1800 8650 1800
Wire Wire Line
	8650 1900 8200 1900
Wire Wire Line
	8200 2000 8650 2000
Wire Wire Line
	8650 2100 8200 2100
Wire Wire Line
	8200 2200 8650 2200
Wire Wire Line
	8650 2300 8200 2300
NoConn ~ 8200 2650
NoConn ~ 8200 2750
NoConn ~ 8200 2850
NoConn ~ 8200 2950
NoConn ~ 8200 3050
NoConn ~ 8200 3150
NoConn ~ 8200 3250
Text Label 6600 1600 0    50   ~ 0
MA0
Text Label 6600 1700 0    50   ~ 0
MA1
Text Label 6600 1800 0    50   ~ 0
MA2
Text Label 6600 1900 0    50   ~ 0
MA3
Text Label 6600 2000 0    50   ~ 0
MA4
Text Label 6600 2100 0    50   ~ 0
MA5
Text Label 6600 2200 0    50   ~ 0
MA6
Text Label 6600 2300 0    50   ~ 0
MA7
Text Label 6600 2400 0    50   ~ 0
MA8
Text Label 6600 2500 0    50   ~ 0
MA9
Text Label 6600 2600 0    50   ~ 0
MA10
Text Label 6600 2700 0    50   ~ 0
MA11
Text Label 6600 2800 0    50   ~ 0
MA12
Text Label 6600 2900 0    50   ~ 0
MA13
Text Label 6600 3000 0    50   ~ 0
MA14
Text Label 6600 3100 0    50   ~ 0
MA15
Text Label 6600 3200 0    50   ~ 0
MA16
Text Label 6600 3300 0    50   ~ 0
MA17
Text Label 6600 3400 0    50   ~ 0
MA18
Text Label 6600 3500 0    50   ~ 0
MA19
Text Label 8650 3350 2    50   ~ 0
MA20
Text Label 8650 1600 2    50   ~ 0
MD0
Text Label 8650 1700 2    50   ~ 0
MD1
Text Label 8650 1800 2    50   ~ 0
MD2
Text Label 8650 1900 2    50   ~ 0
MD3
Text Label 8650 2000 2    50   ~ 0
MD4
Text Label 8650 2100 2    50   ~ 0
MD5
Text Label 8650 2200 2    50   ~ 0
MD6
Text Label 8650 2300 2    50   ~ 0
MD7
Text Label 8650 4100 2    50   ~ 0
VCC3_3
Text Label 8650 4200 2    50   ~ 0
GND
Text Label 8650 4300 2    50   ~ 0
GND
Text Label 6600 4000 0    50   ~ 0
~MWR
Text Label 6600 4100 0    50   ~ 0
~MRD
Text Label 6600 4200 0    50   ~ 0
GND
Text Label 6600 4300 0    50   ~ 0
VCC3_3
Text Label 6600 3700 0    50   ~ 0
GND
NoConn ~ 7100 3800
NoConn ~ 7100 3900
Entry Wire Line
	6400 1800 6500 1700
Entry Wire Line
	6400 1900 6500 1800
Entry Wire Line
	6400 2000 6500 1900
Entry Wire Line
	6400 2100 6500 2000
Entry Wire Line
	6400 2200 6500 2100
Entry Wire Line
	6400 2300 6500 2200
Entry Wire Line
	6400 2400 6500 2300
Entry Wire Line
	6400 2500 6500 2400
Entry Wire Line
	6400 2600 6500 2500
Entry Wire Line
	6400 2700 6500 2600
Entry Wire Line
	6400 2800 6500 2700
Entry Wire Line
	6400 2900 6500 2800
Entry Wire Line
	6400 3000 6500 2900
Entry Wire Line
	6400 3100 6500 3000
Entry Wire Line
	6400 3200 6500 3100
Entry Wire Line
	6400 3300 6500 3200
Entry Wire Line
	6400 3400 6500 3300
Entry Wire Line
	6400 3600 6500 3500
Entry Wire Line
	6400 3700 6500 3600
Entry Wire Line
	6400 3800 6500 3700
Entry Wire Line
	6400 3900 6500 3800
Entry Wire Line
	6400 4100 6500 4000
Entry Wire Line
	6400 4200 6500 4100
Entry Wire Line
	6400 4300 6500 4200
Entry Wire Line
	6400 4400 6500 4300
Entry Wire Line
	6400 4500 6500 4400
Entry Wire Line
	6400 4600 6500 4500
Entry Wire Line
	6400 4700 6500 4600
Entry Wire Line
	6400 4800 6500 4700
Entry Wire Line
	6400 4900 6500 4800
Entry Wire Line
	6400 5000 6500 4900
Entry Wire Line
	6400 5100 6500 5000
Entry Wire Line
	6400 5200 6500 5100
Entry Wire Line
	6400 5300 6500 5200
Wire Wire Line
	5900 1800 6400 1800
Wire Wire Line
	5900 1900 6400 1900
Wire Wire Line
	5900 2000 6400 2000
Wire Wire Line
	5900 2100 6400 2100
Wire Wire Line
	5900 2200 6400 2200
Wire Wire Line
	6400 2300 5900 2300
Wire Wire Line
	5900 2400 6400 2400
Wire Wire Line
	6400 2500 5900 2500
Wire Wire Line
	5900 2600 6400 2600
Wire Wire Line
	5900 2700 6400 2700
Wire Wire Line
	5900 2800 6400 2800
Wire Wire Line
	5900 2900 6400 2900
Wire Wire Line
	5900 3000 6400 3000
Wire Wire Line
	5900 3100 6400 3100
Wire Wire Line
	5900 3200 6400 3200
Wire Wire Line
	6400 3300 5900 3300
Wire Wire Line
	5900 3400 6400 3400
Wire Wire Line
	5900 3600 6400 3600
Wire Wire Line
	6400 3700 5900 3700
Wire Wire Line
	5900 3800 6400 3800
Wire Wire Line
	6400 3900 5900 3900
Wire Wire Line
	6400 4100 5900 4100
Wire Wire Line
	5900 4200 6400 4200
Wire Wire Line
	6400 4300 5900 4300
Wire Wire Line
	5900 4400 6400 4400
Wire Wire Line
	6400 4500 5900 4500
Wire Wire Line
	5900 4600 6400 4600
Wire Wire Line
	6400 4700 5900 4700
Wire Wire Line
	5900 4800 6400 4800
Wire Wire Line
	6400 4900 5900 4900
Wire Wire Line
	5900 5000 6400 5000
Wire Wire Line
	6400 5100 5900 5100
Wire Wire Line
	5900 5200 6400 5200
Wire Wire Line
	6400 5300 5900 5300
Text Label 6400 1800 2    50   ~ 0
GND
Text Label 6400 1900 2    50   ~ 0
VCC2_5
Text Label 6400 2400 2    50   ~ 0
VCC1_2
Text Label 6400 2900 2    50   ~ 0
GND
Text Label 6400 3000 2    50   ~ 0
VCC2_5
Text Label 6400 3100 2    50   ~ 0
GND
Text Label 6400 3200 2    50   ~ 0
GND
Text Label 6400 3300 2    50   ~ 0
VCC3_3
Text Label 6400 3400 2    50   ~ 0
CONF_DONE
Text Label 6400 4400 2    50   ~ 0
GND
Text Label 6400 4500 2    50   ~ 0
VCC3_3
Text Label 6400 4800 2    50   ~ 0
VCC1_2
Text Label 6400 4700 2    50   ~ 0
GND
Entry Wire Line
	1850 700  1950 800 
Entry Wire Line
	1950 700  2050 800 
Entry Wire Line
	2050 700  2150 800 
Entry Wire Line
	2150 700  2250 800 
Entry Wire Line
	2250 700  2350 800 
Entry Wire Line
	2350 700  2450 800 
Entry Wire Line
	2450 700  2550 800 
Entry Wire Line
	2550 700  2650 800 
Entry Wire Line
	2650 700  2750 800 
Entry Wire Line
	2750 700  2850 800 
Entry Wire Line
	2850 700  2950 800 
Entry Wire Line
	2950 700  3050 800 
Entry Wire Line
	3050 700  3150 800 
Entry Wire Line
	3150 700  3250 800 
Entry Wire Line
	3250 700  3350 800 
Entry Wire Line
	3350 700  3450 800 
Entry Wire Line
	3450 700  3550 800 
Entry Wire Line
	3550 700  3650 800 
Entry Wire Line
	3650 700  3750 800 
Entry Wire Line
	3750 700  3850 800 
Entry Wire Line
	3850 700  3950 800 
Entry Wire Line
	3950 700  4050 800 
Entry Wire Line
	4050 700  4150 800 
Entry Wire Line
	4150 700  4250 800 
Entry Wire Line
	4250 700  4350 800 
Entry Wire Line
	4350 700  4450 800 
Entry Wire Line
	4450 700  4550 800 
Entry Wire Line
	4550 700  4650 800 
Entry Wire Line
	4650 700  4750 800 
Entry Wire Line
	4750 700  4850 800 
Entry Wire Line
	4850 700  4950 800 
Entry Wire Line
	4950 700  5050 800 
Entry Wire Line
	5050 700  5150 800 
Entry Wire Line
	5150 700  5250 800 
Entry Wire Line
	5250 700  5350 800 
Entry Wire Line
	5350 700  5450 800 
Wire Wire Line
	1950 1400 1950 800 
Wire Wire Line
	2050 800  2050 1400
Wire Wire Line
	2150 1400 2150 800 
Wire Wire Line
	2250 800  2250 1400
Wire Wire Line
	2350 1400 2350 800 
Wire Wire Line
	2450 800  2450 1400
Wire Wire Line
	2550 1400 2550 800 
Wire Wire Line
	2650 800  2650 1400
Wire Wire Line
	2750 1400 2750 800 
Wire Wire Line
	2850 800  2850 1400
Wire Wire Line
	2950 1400 2950 800 
Wire Wire Line
	3050 800  3050 1400
Wire Wire Line
	3150 1400 3150 800 
Wire Wire Line
	3250 800  3250 1400
Wire Wire Line
	3350 1400 3350 800 
Wire Wire Line
	3450 800  3450 1400
Wire Wire Line
	3550 1400 3550 800 
Wire Wire Line
	3650 800  3650 1400
Wire Wire Line
	3750 1400 3750 800 
Wire Wire Line
	3850 800  3850 1400
Wire Wire Line
	3950 1400 3950 800 
Wire Wire Line
	4050 800  4050 1400
Wire Wire Line
	4150 1400 4150 800 
Wire Wire Line
	4250 800  4250 1400
Wire Wire Line
	4350 1400 4350 800 
Wire Wire Line
	4450 800  4450 1400
Wire Wire Line
	4550 1400 4550 800 
Wire Wire Line
	4650 800  4650 1400
Wire Wire Line
	4750 1400 4750 800 
Wire Wire Line
	4850 800  4850 1400
Wire Wire Line
	4950 1400 4950 800 
Wire Wire Line
	5050 800  5050 1400
Wire Wire Line
	5150 1400 5150 800 
Wire Wire Line
	5250 800  5250 1400
Wire Wire Line
	5350 1400 5350 800 
Wire Wire Line
	5450 800  5450 1400
Text Label 2350 800  3    50   ~ 0
GND
Text Label 2450 800  3    50   ~ 0
VCC3_3
Text Label 2950 800  3    50   ~ 0
VCC1_2
Text Label 3250 800  3    50   ~ 0
GND
Text Label 3350 800  3    50   ~ 0
VCC3_3
Text Label 4050 800  3    50   ~ 0
GND
Text Label 4150 800  3    50   ~ 0
VCC3_3
Text Label 4550 800  3    50   ~ 0
GND
Text Label 4650 800  3    50   ~ 0
VCC3_3
Text Label 4750 800  3    50   ~ 0
VCC1_2
Text Label 5450 800  3    50   ~ 0
VCC1_2
Text Label 800  5100 0    50   ~ 0
~MRD
Text Label 800  5000 0    50   ~ 0
MA0
Text Label 800  4900 0    50   ~ 0
MD0
Text Label 800  4800 0    50   ~ 0
MD1
Text Label 800  4700 0    50   ~ 0
MD2
Text Label 800  4500 0    50   ~ 0
MD3
Text Label 2050 6250 1    50   ~ 0
MD4
Text Label 2150 6250 1    50   ~ 0
MD5
Text Label 2450 6250 1    50   ~ 0
MD6
Text Label 2550 6250 1    50   ~ 0
MD7
Text Label 2650 6250 1    50   ~ 0
MA20
Text Label 2850 6250 1    50   ~ 0
MA16
Text Label 3150 6250 1    50   ~ 0
MA15
Text Label 3250 6250 1    50   ~ 0
MA14
Text Label 3350 6250 1    50   ~ 0
MA13
Text Label 3450 6250 1    50   ~ 0
MA12
Text Label 3550 6250 1    50   ~ 0
MA11
Text Label 3650 6250 1    50   ~ 0
MA10
Text Label 3750 6250 1    50   ~ 0
MA9
Text Label 4050 6250 1    50   ~ 0
MA8
Text Label 4150 6250 1    50   ~ 0
MA19
Text Label 4250 6250 1    50   ~ 0
~MWR
Text Label 4650 6250 1    50   ~ 0
MA18
Text Label 4750 6250 1    50   ~ 0
MA17
Text Label 4850 6250 1    50   ~ 0
MA7
Text Label 4950 6250 1    50   ~ 0
MA6
Text Label 5050 6250 1    50   ~ 0
MA5
Text Label 5150 6250 1    50   ~ 0
MA4
Text Label 5250 6250 1    50   ~ 0
MA3
Text Label 5350 6250 1    50   ~ 0
MA2
Text Label 5450 6250 1    50   ~ 0
MA1
Entry Wire Line
	6500 4600 6600 4700
Entry Wire Line
	6500 5000 6600 5100
Entry Wire Line
	6500 5400 6600 5500
Entry Wire Line
	8650 5100 8750 5000
Wire Wire Line
	7300 5100 6600 5100
Wire Wire Line
	6600 4700 7600 4700
Wire Wire Line
	7600 4700 7600 4800
Wire Wire Line
	7900 5100 8650 5100
Wire Wire Line
	6600 5500 7600 5500
Wire Wire Line
	7600 5500 7600 5400
Text Label 6600 4700 0    50   ~ 0
VCC3_3
Text Label 6600 5100 0    50   ~ 0
VCC3_3
Text Label 6600 5500 0    50   ~ 0
GND
Text Label 8650 5100 2    50   ~ 0
CLK_50MHZ
Entry Wire Line
	6500 7950 6600 8050
Entry Wire Line
	6500 6100 6600 6200
Entry Wire Line
	6500 6300 6600 6400
Entry Wire Line
	6500 6600 6600 6700
Entry Wire Line
	8650 6100 8750 6000
Entry Wire Line
	8650 6200 8750 6100
Entry Wire Line
	8650 6500 8750 6400
Wire Wire Line
	7900 6100 8650 6100
Wire Wire Line
	6900 6200 6600 6200
Wire Wire Line
	6900 6400 6600 6400
Wire Wire Line
	7400 6700 7000 6700
Wire Wire Line
	7200 8050 6900 8050
Text Label 6600 8050 0    50   ~ 0
VCC3_3
Text Label 6600 6200 0    50   ~ 0
NCSO
Text Label 6600 6400 0    50   ~ 0
DCLK
Text Label 6600 6700 0    50   ~ 0
GND
Text Label 8650 6100 2    50   ~ 0
ASDO
Text Label 8650 6200 2    50   ~ 0
DATA0
$Comp
L Device:R R5
U 1 1 5F89F248
P 8150 6500
F 0 "R5" V 8357 6500 50  0000 C CNN
F 1 "10k" V 8266 6500 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 8080 6500 50  0001 C CNN
F 3 "~" H 8150 6500 50  0001 C CNN
	1    8150 6500
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8300 6500 8650 6500
Wire Wire Line
	7900 6400 8000 6400
Wire Wire Line
	8000 6400 8000 6500
Wire Wire Line
	7900 6500 8000 6500
Connection ~ 8000 6500
Text Label 8650 6500 2    50   ~ 0
VCC3_3
$Comp
L Device:R R4
U 1 1 5F8F2A04
P 8150 6200
F 0 "R4" V 8357 6200 50  0000 C CNN
F 1 "27" V 8266 6200 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 8080 6200 50  0001 C CNN
F 3 "~" H 8150 6200 50  0001 C CNN
	1    8150 6200
	0    -1   -1   0   
$EndComp
Wire Wire Line
	7900 6200 8000 6200
Wire Wire Line
	8300 6200 8650 6200
NoConn ~ 7600 7700
NoConn ~ 7850 7400
NoConn ~ 7850 7300
NoConn ~ 7350 7400
Entry Wire Line
	6500 7000 6600 7100
Entry Wire Line
	6500 7100 6600 7200
Entry Wire Line
	6500 7200 6600 7300
Entry Wire Line
	6500 7400 6600 7500
Entry Wire Line
	8650 7100 8750 7000
Entry Wire Line
	8650 7500 8750 7400
Wire Wire Line
	7850 7100 8650 7100
Wire Wire Line
	7850 7500 8650 7500
Wire Wire Line
	7350 7100 7000 7100
Wire Wire Line
	7350 7500 7200 7500
Text Label 8650 7100 2    50   ~ 0
GND
Text Label 8650 7500 2    50   ~ 0
GND
Text Label 6600 7100 0    50   ~ 0
TCK
Text Label 6600 7200 0    50   ~ 0
TDO
Text Label 6600 7300 0    50   ~ 0
TMS
Text Label 6600 7500 0    50   ~ 0
TDI
$Comp
L Device:R R2
U 1 1 5F9C962B
P 7000 6950
F 0 "R2" H 7070 6996 50  0000 L CNN
F 1 "2k4" H 7070 6905 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 6930 6950 50  0001 C CNN
F 3 "~" H 7000 6950 50  0001 C CNN
	1    7000 6950
	1    0    0    -1  
$EndComp
Connection ~ 7000 7100
Wire Wire Line
	7000 7100 6600 7100
Wire Wire Line
	7000 6800 7000 6700
Connection ~ 7000 6700
Wire Wire Line
	7000 6700 6600 6700
Entry Wire Line
	8650 7200 8750 7100
Wire Wire Line
	7850 7200 8650 7200
Text Label 8650 7200 2    50   ~ 0
VCC3_3
$Comp
L Device:R R1
U 1 1 5F9F3306
P 6900 7750
F 0 "R1" H 6970 7796 50  0000 L CNN
F 1 "2k4" H 6970 7705 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 6830 7750 50  0001 C CNN
F 3 "~" H 6900 7750 50  0001 C CNN
	1    6900 7750
	1    0    0    -1  
$EndComp
$Comp
L Device:R R3
U 1 1 5F9F3970
P 7200 7750
F 0 "R3" H 7270 7796 50  0000 L CNN
F 1 "2k4" H 7270 7705 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 7130 7750 50  0001 C CNN
F 3 "~" H 7200 7750 50  0001 C CNN
	1    7200 7750
	1    0    0    -1  
$EndComp
Wire Wire Line
	7200 7600 7200 7500
Connection ~ 7200 7500
Wire Wire Line
	7200 7500 6600 7500
Wire Wire Line
	6600 7200 7350 7200
Wire Wire Line
	6900 7600 6900 7300
Wire Wire Line
	6600 7300 6900 7300
Connection ~ 6900 7300
Wire Wire Line
	6900 7300 7350 7300
Wire Wire Line
	7200 8050 7200 7900
Wire Wire Line
	6900 7900 6900 8050
Connection ~ 6900 8050
Wire Wire Line
	6900 8050 6600 8050
Entry Wire Line
	6500 5650 6600 5750
Wire Wire Line
	6600 5750 7400 5750
Text Label 6600 5750 0    50   ~ 0
VCC3_3
Wire Wire Line
	7400 5750 7400 5900
Connection ~ 700  6350
Entry Wire Line
	700  6950 800  7050
Entry Wire Line
	700  7050 800  7150
Entry Wire Line
	700  7150 800  7250
Entry Wire Line
	700  7250 800  7350
Entry Wire Line
	700  7350 800  7450
Entry Wire Line
	700  7450 800  7550
Entry Wire Line
	700  7550 800  7650
Entry Wire Line
	700  7650 800  7750
Entry Wire Line
	700  7750 800  7850
Entry Wire Line
	700  7850 800  7950
Entry Wire Line
	700  7950 800  8050
Entry Wire Line
	700  8050 800  8150
Entry Wire Line
	700  8150 800  8250
Entry Wire Line
	700  8250 800  8350
Entry Wire Line
	700  8350 800  8450
Entry Wire Line
	700  8450 800  8550
Entry Wire Line
	700  8550 800  8650
Entry Wire Line
	700  8650 800  8750
Wire Wire Line
	800  7050 1400 7050
Wire Wire Line
	800  7150 1400 7150
Wire Wire Line
	800  7250 1400 7250
Wire Wire Line
	800  7350 1400 7350
Wire Wire Line
	800  7450 1400 7450
Wire Wire Line
	800  7550 1400 7550
Wire Wire Line
	800  7650 1400 7650
Wire Wire Line
	800  7750 1400 7750
Wire Wire Line
	800  7850 1400 7850
Wire Wire Line
	800  7950 1400 7950
Wire Wire Line
	800  8050 1400 8050
Wire Wire Line
	800  8150 1400 8150
Wire Wire Line
	800  8250 1400 8250
Wire Wire Line
	800  8350 1400 8350
Wire Wire Line
	800  8450 1400 8450
Wire Wire Line
	800  8550 1400 8550
Wire Wire Line
	800  8650 1400 8650
Wire Wire Line
	800  8750 1400 8750
Text Label 800  7050 0    50   ~ 0
~WR
Text Label 800  7150 0    50   ~ 0
~FDC_CS
Text Label 800  7250 0    50   ~ 0
~RD
Text Label 800  7350 0    50   ~ 0
FDC_A0
Text Label 800  7450 0    50   ~ 0
FDC_A1
Text Label 800  7550 0    50   ~ 0
D0
Text Label 800  7650 0    50   ~ 0
D1
Text Label 800  7750 0    50   ~ 0
D2
Text Label 800  7850 0    50   ~ 0
D3
Text Label 800  7950 0    50   ~ 0
D4
Text Label 800  8050 0    50   ~ 0
D5
Text Label 800  8150 0    50   ~ 0
D6
Text Label 800  8250 0    50   ~ 0
D7
Text Label 800  8350 0    50   ~ 0
FDC_STEP
Text Label 800  8450 0    50   ~ 0
FDC_DIR
Text Label 800  8550 0    50   ~ 0
FDC_SL
Text Label 800  8650 0    50   ~ 0
FDC_SR
Text Label 800  8750 0    50   ~ 0
~FDC_RST
Connection ~ 3150 6350
Entry Wire Line
	3050 7050 3150 6950
Entry Wire Line
	3050 7150 3150 7050
Entry Wire Line
	3050 7250 3150 7150
Entry Wire Line
	3050 7350 3150 7250
Entry Wire Line
	3050 7450 3150 7350
Entry Wire Line
	3050 7550 3150 7450
Entry Wire Line
	3050 7650 3150 7550
Entry Wire Line
	3050 7750 3150 7650
Entry Wire Line
	3050 7850 3150 7750
Entry Wire Line
	3050 7950 3150 7850
Entry Wire Line
	3050 8050 3150 7950
Entry Wire Line
	3050 8150 3150 8050
Entry Wire Line
	3050 8250 3150 8150
Entry Wire Line
	3050 8350 3150 8250
Entry Wire Line
	3050 8550 3150 8450
Entry Wire Line
	3050 8650 3150 8550
Entry Wire Line
	3050 8750 3150 8650
Wire Wire Line
	2400 7050 3050 7050
Wire Wire Line
	3050 7150 2400 7150
Wire Wire Line
	2400 7250 3050 7250
Wire Wire Line
	3050 7350 2400 7350
Wire Wire Line
	2400 7450 3050 7450
Wire Wire Line
	3050 7550 2400 7550
Wire Wire Line
	2400 7650 3050 7650
Wire Wire Line
	3050 7750 2400 7750
Wire Wire Line
	2400 7850 3050 7850
Wire Wire Line
	3050 7950 2400 7950
Wire Wire Line
	2400 8050 3050 8050
Wire Wire Line
	3050 8150 2400 8150
Wire Wire Line
	2400 8250 3050 8250
Wire Wire Line
	3050 8350 2400 8350
Wire Wire Line
	3050 8550 2400 8550
Wire Wire Line
	2400 8650 3050 8650
Wire Wire Line
	3050 8750 2400 8750
Text Label 3050 7050 2    50   ~ 0
FDC_INTRQ
Text Label 3050 7150 2    50   ~ 0
FDC_DRQ
Text Label 3050 7250 2    50   ~ 0
GND
Text Label 3050 7350 2    50   ~ 0
~FDC_WPRT
Text Label 3050 7450 2    50   ~ 0
FDC_IP
Text Label 3050 7550 2    50   ~ 0
~FDC_TR00
Text Label 3050 7650 2    50   ~ 0
FDC_WF_DE
Text Label 3050 7750 2    50   ~ 0
FDC_RDY
Text Label 3050 7850 2    50   ~ 0
FDC_WD
Text Label 3050 7950 2    50   ~ 0
FDC_WGATE
Text Label 3050 8050 2    50   ~ 0
FDC_TR43
Text Label 3050 8150 2    50   ~ 0
FDC_RDY
Text Label 3050 8250 2    50   ~ 0
~FDC_RAWR
Text Label 3050 8350 2    50   ~ 0
FDC_RCLK
NoConn ~ 2400 8450
Text Label 3050 8550 2    50   ~ 0
FDC_CLK
Text Label 3050 8650 2    50   ~ 0
FDC_HLT
Text Label 3050 8750 2    50   ~ 0
VCC
$Comp
L power:GND #PWR0106
U 1 1 6008A7FB
P 1850 9050
F 0 "#PWR0106" H 1850 8800 50  0001 C CNN
F 1 "GND" H 1855 8877 50  0000 C CNN
F 2 "" H 1850 9050 50  0001 C CNN
F 3 "" H 1850 9050 50  0001 C CNN
	1    1850 9050
	1    0    0    -1  
$EndComp
Wire Wire Line
	1800 8950 1800 9050
Wire Wire Line
	1800 9050 1850 9050
Wire Wire Line
	1900 8950 1900 9050
Wire Wire Line
	1900 9050 1850 9050
Connection ~ 1850 9050
$Comp
L power:VCC #PWR0107
U 1 1 600C269A
P 1750 6750
F 0 "#PWR0107" H 1750 6600 50  0001 C CNN
F 1 "VCC" H 1765 6923 50  0000 C CNN
F 2 "" H 1750 6750 50  0001 C CNN
F 3 "" H 1750 6750 50  0001 C CNN
	1    1750 6750
	1    0    0    -1  
$EndComp
Wire Wire Line
	1900 6850 1800 6850
Wire Wire Line
	1800 6850 1750 6850
Wire Wire Line
	1750 6850 1750 6750
Connection ~ 1800 6850
$Comp
L Device:R R7
U 1 1 60105894
P 2100 9250
F 0 "R7" H 2170 9296 50  0000 L CNN
F 1 "4k7" H 2170 9205 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 2030 9250 50  0001 C CNN
F 3 "~" H 2100 9250 50  0001 C CNN
	1    2100 9250
	1    0    0    -1  
$EndComp
$Comp
L Device:R R8
U 1 1 6010BDA4
P 2800 9250
F 0 "R8" H 2870 9296 50  0000 L CNN
F 1 "4k7" H 2870 9205 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 2730 9250 50  0001 C CNN
F 3 "~" H 2800 9250 50  0001 C CNN
	1    2800 9250
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0108
U 1 1 6010CB36
P 2800 9000
F 0 "#PWR0108" H 2800 8850 50  0001 C CNN
F 1 "VCC" H 2815 9173 50  0000 C CNN
F 2 "" H 2800 9000 50  0001 C CNN
F 3 "" H 2800 9000 50  0001 C CNN
	1    2800 9000
	1    0    0    -1  
$EndComp
Wire Wire Line
	2100 9100 2100 9000
Wire Wire Line
	2100 9000 2800 9000
Wire Wire Line
	2800 9100 2800 9000
Connection ~ 2800 9000
Wire Wire Line
	1950 9700 2100 9700
Wire Wire Line
	2100 9700 2100 9600
Wire Wire Line
	2100 9400 2100 9600
Connection ~ 2100 9600
Wire Wire Line
	2100 9700 2100 9800
Connection ~ 2100 9700
Wire Wire Line
	2700 9700 2800 9700
Wire Wire Line
	2800 9700 2800 9400
$Comp
L Device:R R6
U 1 1 601B991C
P 1150 9250
F 0 "R6" H 1220 9296 50  0000 L CNN
F 1 "1k" H 1220 9205 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 1080 9250 50  0001 C CNN
F 3 "~" H 1150 9250 50  0001 C CNN
	1    1150 9250
	1    0    0    -1  
$EndComp
Wire Wire Line
	1350 9600 1150 9600
Wire Wire Line
	1150 9600 1150 9400
$Comp
L power:VCC #PWR0109
U 1 1 601EAAC5
P 1150 9100
F 0 "#PWR0109" H 1150 8950 50  0001 C CNN
F 1 "VCC" H 1165 9273 50  0000 C CNN
F 2 "" H 1150 9100 50  0001 C CNN
F 3 "" H 1150 9100 50  0001 C CNN
	1    1150 9100
	1    0    0    -1  
$EndComp
Entry Wire Line
	700  9700 800  9800
Wire Wire Line
	800  9800 1350 9800
Entry Wire Line
	700  9500 800  9600
Wire Wire Line
	800  9600 1150 9600
Connection ~ 1150 9600
Text Label 800  9600 0    50   ~ 0
~FDC_INDEX
Text Label 800  9800 0    50   ~ 0
FDC_HLT
Entry Wire Line
	3050 9700 3150 9600
Wire Wire Line
	3050 9700 2800 9700
Connection ~ 2800 9700
Text Label 3050 9700 2    50   ~ 0
FDC_IP
Connection ~ 4850 6350
Entry Wire Line
	3150 6950 3250 7050
Entry Wire Line
	3150 7450 3250 7550
Entry Wire Line
	3150 7950 3250 8050
Entry Wire Line
	3150 8450 3250 8550
Entry Wire Line
	3150 8850 3250 8950
Entry Wire Line
	3150 9400 3250 9500
Entry Wire Line
	3150 10050 3250 10150
Entry Wire Line
	3150 10550 3250 10650
Wire Wire Line
	3250 7050 3750 7050
Wire Wire Line
	3250 7550 3750 7550
Wire Wire Line
	3250 8050 3750 8050
Wire Wire Line
	3250 8550 3650 8550
Wire Wire Line
	3250 8950 3750 8950
Wire Wire Line
	3250 9500 3750 9500
Wire Wire Line
	3250 10150 3750 10150
Wire Wire Line
	3250 10650 3750 10650
Wire Wire Line
	3750 9700 3650 9700
Wire Wire Line
	3650 9700 3650 9150
Wire Wire Line
	3650 9150 3750 9150
Wire Wire Line
	3650 9150 3650 8550
Connection ~ 3650 9150
Connection ~ 3650 8550
Wire Wire Line
	3650 8550 3750 8550
Entry Wire Line
	4750 7050 4850 6950
Entry Wire Line
	4750 7550 4850 7450
Entry Wire Line
	4750 8050 4850 7950
Entry Wire Line
	4750 8550 4850 8450
Entry Wire Line
	4750 9050 4850 8950
Entry Wire Line
	4750 9600 4850 9500
Entry Wire Line
	4750 10150 4850 10050
Entry Wire Line
	4750 10650 4850 10550
Wire Wire Line
	4350 7050 4750 7050
Wire Wire Line
	4350 7550 4750 7550
Wire Wire Line
	4350 8050 4750 8050
Wire Wire Line
	4350 8550 4750 8550
Wire Wire Line
	4350 9050 4750 9050
Wire Wire Line
	4350 9600 4750 9600
Wire Wire Line
	4350 10650 4750 10650
Text Label 3250 7050 0    50   ~ 0
FDC_STEP
Text Label 3250 7550 0    50   ~ 0
FDC_DIR
Text Label 3250 8050 0    50   ~ 0
FDC_WGATE
Text Label 3250 8550 0    50   ~ 0
FDC_RDY
Text Label 3250 8950 0    50   ~ 0
FDC_DS0
Text Label 3250 9500 0    50   ~ 0
FDC_DS1
Text Label 3250 10150 0    50   ~ 0
FDC_WDATA
Text Label 3250 10650 0    50   ~ 0
~FDC_SIDE
Text Label 4750 7050 2    50   ~ 0
~FDC_STEP
Text Label 4750 7550 2    50   ~ 0
~FDC_DIR
Text Label 4750 8050 2    50   ~ 0
~FDC_WGATE
Text Label 4750 8550 2    50   ~ 0
~FDC_MOTOR
Text Label 4750 9050 2    50   ~ 0
~FDC_DRIVE0
Text Label 4750 9600 2    50   ~ 0
~FDC_DRIVE1
Text Label 4750 10150 2    50   ~ 0
~FDC_WDATA
Wire Wire Line
	4350 10150 4750 10150
Text Label 4750 10650 2    50   ~ 0
FDC_SIDE
$Comp
L power:GND #PWR0110
U 1 1 604F897F
P 6200 8800
F 0 "#PWR0110" H 6200 8550 50  0001 C CNN
F 1 "GND" H 6205 8627 50  0000 C CNN
F 2 "" H 6200 8800 50  0001 C CNN
F 3 "" H 6200 8800 50  0001 C CNN
	1    6200 8800
	1    0    0    -1  
$EndComp
Wire Wire Line
	6050 7000 6200 7000
Wire Wire Line
	6200 7000 6200 7100
Wire Wire Line
	6050 7100 6200 7100
Connection ~ 6200 7100
Wire Wire Line
	6200 7100 6200 7200
Wire Wire Line
	6050 7200 6200 7200
Connection ~ 6200 7200
Wire Wire Line
	6200 7200 6200 7300
Wire Wire Line
	6050 7300 6200 7300
Connection ~ 6200 7300
Wire Wire Line
	6200 7300 6200 7400
Wire Wire Line
	6050 7400 6200 7400
Connection ~ 6200 7400
Wire Wire Line
	6200 7400 6200 7500
Wire Wire Line
	6050 7500 6200 7500
Connection ~ 6200 7500
Wire Wire Line
	6200 7500 6200 7600
Wire Wire Line
	6050 7600 6200 7600
Connection ~ 6200 7600
Wire Wire Line
	6200 7600 6200 7700
Wire Wire Line
	6050 7700 6200 7700
Connection ~ 6200 7700
Wire Wire Line
	6200 7700 6200 7800
Wire Wire Line
	6050 7800 6200 7800
Connection ~ 6200 7800
Wire Wire Line
	6200 7800 6200 7900
Wire Wire Line
	6050 7900 6200 7900
Connection ~ 6200 7900
Wire Wire Line
	6200 7900 6200 8000
Wire Wire Line
	6050 8000 6200 8000
Connection ~ 6200 8000
Wire Wire Line
	6200 8000 6200 8100
Wire Wire Line
	6050 8100 6200 8100
Connection ~ 6200 8100
Wire Wire Line
	6200 8100 6200 8200
Wire Wire Line
	6050 8200 6200 8200
Connection ~ 6200 8200
Wire Wire Line
	6200 8200 6200 8300
Wire Wire Line
	6050 8300 6200 8300
Connection ~ 6200 8300
Wire Wire Line
	6200 8300 6200 8400
Wire Wire Line
	6050 8400 6200 8400
Connection ~ 6200 8400
Wire Wire Line
	6200 8400 6200 8500
Wire Wire Line
	6050 8500 6200 8500
Connection ~ 6200 8500
Wire Wire Line
	6200 8500 6200 8600
Wire Wire Line
	6050 8600 6200 8600
Connection ~ 6200 8600
Wire Wire Line
	6200 8600 6200 8800
NoConn ~ 5550 7000
NoConn ~ 5550 7100
NoConn ~ 5550 7200
NoConn ~ 5550 7600
NoConn ~ 5550 8600
Entry Wire Line
	4850 7200 4950 7300
Entry Wire Line
	4850 7300 4950 7400
Entry Wire Line
	4850 7400 4950 7500
Entry Wire Line
	4850 7600 4950 7700
Entry Wire Line
	4850 7700 4950 7800
Entry Wire Line
	4850 7800 4950 7900
Entry Wire Line
	4850 7900 4950 8000
Entry Wire Line
	4850 8000 4950 8100
Entry Wire Line
	4850 8100 4950 8200
Entry Wire Line
	4850 8200 4950 8300
Entry Wire Line
	4850 8300 4950 8400
Entry Wire Line
	4850 8400 4950 8500
Wire Wire Line
	4950 7300 5550 7300
Wire Wire Line
	4950 7400 5550 7400
Wire Wire Line
	4950 7500 5550 7500
Wire Wire Line
	4950 7700 5550 7700
Wire Wire Line
	4950 7800 5550 7800
Wire Wire Line
	4950 7900 5550 7900
Wire Wire Line
	4950 8000 5550 8000
Wire Wire Line
	4950 8100 5550 8100
Wire Wire Line
	4950 8200 5550 8200
Wire Wire Line
	4950 8300 5550 8300
Wire Wire Line
	4950 8400 5550 8400
Wire Wire Line
	4950 8500 5550 8500
Text Label 4950 7300 0    50   ~ 0
~FDC_INDEX
Text Label 4950 7400 0    50   ~ 0
~FDC_DRIVE0
Text Label 4950 7500 0    50   ~ 0
~FDC_DRIVE1
Text Label 4950 7700 0    50   ~ 0
~FDC_MOTOR
Text Label 4950 7800 0    50   ~ 0
~FDC_DIR
Text Label 4950 7900 0    50   ~ 0
~FDC_STEP
Text Label 4950 8000 0    50   ~ 0
~FDC_WDATA
Text Label 4950 8100 0    50   ~ 0
~FDC_WGATE
Text Label 4950 8200 0    50   ~ 0
~FDC_TR00
Text Label 4950 8300 0    50   ~ 0
~FDC_WPRT
Text Label 4950 8400 0    50   ~ 0
~FDC_RDATA
Text Label 4950 8500 0    50   ~ 0
FDC_SIDE
$Comp
L power:VCC #PWR0111
U 1 1 609C2FC1
P 1650 10150
F 0 "#PWR0111" H 1650 10000 50  0001 C CNN
F 1 "VCC" H 1665 10323 50  0000 C CNN
F 2 "" H 1650 10150 50  0001 C CNN
F 3 "" H 1650 10150 50  0001 C CNN
	1    1650 10150
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0112
U 1 1 609C446B
P 2400 10150
F 0 "#PWR0112" H 2400 10000 50  0001 C CNN
F 1 "VCC" H 2415 10323 50  0000 C CNN
F 2 "" H 2400 10150 50  0001 C CNN
F 3 "" H 2400 10150 50  0001 C CNN
	1    2400 10150
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0113
U 1 1 609C4B89
P 1650 11150
F 0 "#PWR0113" H 1650 10900 50  0001 C CNN
F 1 "GND" H 1655 10977 50  0000 C CNN
F 2 "" H 1650 11150 50  0001 C CNN
F 3 "" H 1650 11150 50  0001 C CNN
	1    1650 11150
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0114
U 1 1 609C5169
P 2400 11150
F 0 "#PWR0114" H 2400 10900 50  0001 C CNN
F 1 "GND" H 2405 10977 50  0000 C CNN
F 2 "" H 2400 11150 50  0001 C CNN
F 3 "" H 2400 11150 50  0001 C CNN
	1    2400 11150
	1    0    0    -1  
$EndComp
Wire Wire Line
	17250 1500 17250 1800
Wire Wire Line
	17000 1800 17250 1800
Connection ~ 17250 1800
Wire Wire Line
	17250 1800 17450 1800
Wire Wire Line
	17000 1900 17000 2000
Wire Wire Line
	17000 2100 17000 2000
Connection ~ 17000 2000
Wire Wire Line
	18150 1800 18250 1800
Wire Wire Line
	18250 1800 18250 1500
Wire Wire Line
	18150 2550 18250 2550
Wire Wire Line
	18250 2550 18250 2250
Wire Wire Line
	18150 3350 18300 3350
Wire Wire Line
	18300 3350 18300 3050
$Comp
L power:GND #PWR0115
U 1 1 61862104
P 17850 2100
F 0 "#PWR0115" H 17850 1850 50  0001 C CNN
F 1 "GND" H 17855 1927 50  0000 C CNN
F 2 "" H 17850 2100 50  0001 C CNN
F 3 "" H 17850 2100 50  0001 C CNN
	1    17850 2100
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0116
U 1 1 61862530
P 17850 2850
F 0 "#PWR0116" H 17850 2600 50  0001 C CNN
F 1 "GND" H 17855 2677 50  0000 C CNN
F 2 "" H 17850 2850 50  0001 C CNN
F 3 "" H 17850 2850 50  0001 C CNN
	1    17850 2850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0117
U 1 1 61862A41
P 17850 3650
F 0 "#PWR0117" H 17850 3400 50  0001 C CNN
F 1 "GND" H 17855 3477 50  0000 C CNN
F 2 "" H 17850 3650 50  0001 C CNN
F 3 "" H 17850 3650 50  0001 C CNN
	1    17850 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	17550 3350 17450 3350
Wire Wire Line
	17450 3350 17450 2550
Connection ~ 17450 1800
Wire Wire Line
	17450 1800 17550 1800
Wire Wire Line
	17550 2550 17450 2550
Connection ~ 17450 2550
Wire Wire Line
	17450 2550 17450 1800
Text Label 6400 5300 2    50   ~ 0
SD15
Text Label 6400 5200 2    50   ~ 0
SD14
Text Label 6400 5100 2    50   ~ 0
SD13
Text Label 6400 5000 2    50   ~ 0
SD12
Text Label 6400 4900 2    50   ~ 0
SD11
Text Label 6400 4600 2    50   ~ 0
SD10
Text Label 6400 4300 2    50   ~ 0
SD9
Text Label 6400 4200 2    50   ~ 0
SD8
Text Label 6400 4100 2    50   ~ 0
SD7
Text Label 6400 2800 2    50   ~ 0
SD6
Text Label 6400 2700 2    50   ~ 0
SD5
Text Label 6400 2600 2    50   ~ 0
SD4
Text Label 6400 2500 2    50   ~ 0
SD3
Text Label 6400 2300 2    50   ~ 0
SD2
Text Label 6400 2200 2    50   ~ 0
SD1
Text Label 6400 2100 2    50   ~ 0
SD0
Text Label 6400 2000 2    50   ~ 0
SA1
Text Label 5350 800  3    50   ~ 0
SA0
Text Label 5250 800  3    50   ~ 0
SDIR
Text Label 5150 800  3    50   ~ 0
CPLD_CLK2
Text Label 5050 800  3    50   ~ 0
CPLD_CLK
Text Label 3850 800  3    50   ~ 0
VGA_HS
Text Label 3950 800  3    50   ~ 0
VGA_VS
Text Label 2850 800  3    50   ~ 0
VGA_R0
Text Label 2750 800  3    50   ~ 0
VGA_R1
Text Label 3450 800  3    50   ~ 0
VGA_G0
Text Label 3150 800  3    50   ~ 0
VGA_G1
Text Label 3750 800  3    50   ~ 0
VGA_B0
Text Label 3650 800  3    50   ~ 0
VGA_B1
Text Label 2150 800  3    50   ~ 0
LSND_DAT
Text Label 2050 800  3    50   ~ 0
LSND_WS
Text Label 1950 800  3    50   ~ 0
LSND_BS
Text Label 6400 3600 2    50   ~ 0
LAVR_MOSI
Text Label 6400 3700 2    50   ~ 0
LAVR_SCK
Text Label 6400 3900 2    50   ~ 0
LAVR_MISO
Entry Wire Line
	11050 6600 11150 6700
Wire Wire Line
	11150 6700 11900 6700
Entry Wire Line
	11050 6800 11150 6900
Wire Wire Line
	11150 6900 11900 6900
Entry Wire Line
	11050 6200 11150 6300
Entry Wire Line
	11050 6300 11150 6400
Wire Wire Line
	11150 6300 11550 6300
Wire Wire Line
	11150 6400 11900 6400
Text Label 11150 6300 0    50   ~ 0
~SD_CS
Text Label 11150 6400 0    50   ~ 0
ASDO
Text Label 11150 6700 0    50   ~ 0
DCLK
Text Label 11150 6900 0    50   ~ 0
DATA0
Text Label 800  2800 0    50   ~ 0
~SD_CS
Text Label 6400 3800 2    50   ~ 0
~LAVR_CS
Entry Wire Line
	8750 8750 8850 8850
Entry Wire Line
	8750 8650 8850 8750
Entry Wire Line
	8750 8850 8850 8950
$Comp
L power:GND #PWR0126
U 1 1 5EF82329
P 9000 9650
F 0 "#PWR0126" H 9000 9400 50  0001 C CNN
F 1 "GND" H 9005 9477 50  0000 C CNN
F 2 "" H 9000 9650 50  0001 C CNN
F 3 "" H 9000 9650 50  0001 C CNN
	1    9000 9650
	0    1    1    0   
$EndComp
Wire Wire Line
	8850 8750 9150 8750
Wire Wire Line
	8850 8850 9150 8850
Wire Wire Line
	8850 8950 9150 8950
Wire Wire Line
	9150 9750 9150 9650
Wire Wire Line
	9150 9650 9150 9550
Connection ~ 9150 9650
Wire Wire Line
	9150 9550 9150 9450
Connection ~ 9150 9550
Wire Wire Line
	9150 9450 9150 9350
Connection ~ 9150 9450
Wire Wire Line
	9150 9350 9150 9250
Connection ~ 9150 9350
Wire Wire Line
	9150 9250 9150 9150
Connection ~ 9150 9250
Wire Wire Line
	9150 9150 9150 9050
Connection ~ 9150 9150
Entry Wire Line
	8750 9850 8850 9950
Entry Wire Line
	8750 9950 8850 10050
$Comp
L power:GND #PWR0127
U 1 1 5F26EF2F
P 9000 10550
F 0 "#PWR0127" H 9000 10300 50  0001 C CNN
F 1 "GND" H 9005 10377 50  0000 C CNN
F 2 "" H 9000 10550 50  0001 C CNN
F 3 "" H 9000 10550 50  0001 C CNN
	1    9000 10550
	0    1    1    0   
$EndComp
Wire Wire Line
	9000 9650 9150 9650
Wire Wire Line
	8850 9950 9150 9950
Wire Wire Line
	8850 10050 9150 10050
Wire Wire Line
	9000 10550 9150 10550
Wire Wire Line
	9150 10650 9150 10550
Connection ~ 9150 10550
NoConn ~ 9150 10850
NoConn ~ 9150 11050
Entry Wire Line
	8750 11050 8850 11150
Entry Wire Line
	8750 11150 8850 11250
Wire Wire Line
	8850 11150 9150 11150
Wire Wire Line
	8850 11250 9150 11250
Entry Wire Line
	8750 11450 8850 11550
Wire Wire Line
	8850 11550 9150 11550
$Comp
L power:GND #PWR0128
U 1 1 5F5B427D
P 9850 11850
F 0 "#PWR0128" H 9850 11600 50  0001 C CNN
F 1 "GND" H 9855 11677 50  0000 C CNN
F 2 "" H 9850 11850 50  0001 C CNN
F 3 "" H 9850 11850 50  0001 C CNN
	1    9850 11850
	1    0    0    -1  
$EndComp
Wire Wire Line
	9750 11750 9750 11850
Wire Wire Line
	9750 11850 9850 11850
Wire Wire Line
	9950 11750 9950 11850
Wire Wire Line
	9950 11850 9850 11850
Connection ~ 9850 11850
Entry Wire Line
	10950 8750 11050 8650
Entry Wire Line
	10950 8850 11050 8750
Entry Wire Line
	10950 8950 11050 8850
Entry Wire Line
	10950 9050 11050 8950
Entry Wire Line
	10950 9150 11050 9050
Entry Wire Line
	10950 9250 11050 9150
Entry Wire Line
	10950 9350 11050 9250
Entry Wire Line
	10950 9450 11050 9350
Entry Wire Line
	10950 9550 11050 9450
Entry Wire Line
	10950 9650 11050 9550
Entry Wire Line
	10950 9750 11050 9650
Entry Wire Line
	10950 9850 11050 9750
Entry Wire Line
	10950 9950 11050 9850
Entry Wire Line
	10950 10050 11050 9950
Entry Wire Line
	10950 10150 11050 10050
Entry Wire Line
	10950 10250 11050 10150
NoConn ~ 10550 10450
NoConn ~ 10550 10550
NoConn ~ 10550 10750
NoConn ~ 10550 10850
NoConn ~ 10550 10950
NoConn ~ 10550 11050
NoConn ~ 10550 11150
NoConn ~ 10550 11350
NoConn ~ 10550 11450
NoConn ~ 10550 11550
Wire Wire Line
	10550 8750 10950 8750
Wire Wire Line
	10550 8850 10950 8850
Wire Wire Line
	10550 8950 10950 8950
Wire Wire Line
	10550 9050 10950 9050
Wire Wire Line
	10550 9150 10950 9150
Wire Wire Line
	10550 9250 10950 9250
Wire Wire Line
	10550 9350 10950 9350
Wire Wire Line
	10550 9450 10950 9450
Wire Wire Line
	10550 9550 10950 9550
Wire Wire Line
	10550 9650 10950 9650
Wire Wire Line
	10550 9750 10950 9750
Wire Wire Line
	10550 9850 10950 9850
Wire Wire Line
	10550 9950 10950 9950
Wire Wire Line
	10550 10050 10950 10050
Wire Wire Line
	10550 10150 10950 10150
Wire Wire Line
	10550 10250 10950 10250
$Comp
L power:VCC #PWR0129
U 1 1 5FD951D4
P 10200 8450
F 0 "#PWR0129" H 10200 8300 50  0001 C CNN
F 1 "VCC" H 10215 8623 50  0000 C CNN
F 2 "" H 10200 8450 50  0001 C CNN
F 3 "" H 10200 8450 50  0001 C CNN
	1    10200 8450
	1    0    0    -1  
$EndComp
Wire Wire Line
	9750 8550 9950 8550
Wire Wire Line
	9950 8550 10200 8550
Wire Wire Line
	10200 8550 10200 8450
Connection ~ 9950 8550
Text Label 8850 8750 0    50   ~ 0
WA0
Text Label 8850 8850 0    50   ~ 0
WA1
Text Label 8850 8950 0    50   ~ 0
WA2
Text Label 8850 9950 0    50   ~ 0
~WCS0
Text Label 8850 10050 0    50   ~ 0
~WCS1
Text Label 8850 11150 0    50   ~ 0
~WRD
Text Label 8850 11250 0    50   ~ 0
~WWR
Text Label 8850 11550 0    50   ~ 0
~WRESET
Text Label 10950 8750 2    50   ~ 0
WD0
Text Label 10950 8850 2    50   ~ 0
WD1
Text Label 10950 8950 2    50   ~ 0
WD2
Text Label 10950 9050 2    50   ~ 0
WD3
Text Label 10950 9150 2    50   ~ 0
WD4
Text Label 10950 9250 2    50   ~ 0
WD5
Text Label 10950 9350 2    50   ~ 0
WD6
Text Label 10950 9450 2    50   ~ 0
WD7
Text Label 10950 9550 2    50   ~ 0
WD8
Text Label 10950 9650 2    50   ~ 0
WD9
Text Label 10950 9750 2    50   ~ 0
WD10
Text Label 10950 9850 2    50   ~ 0
WD11
Text Label 10950 9950 2    50   ~ 0
WD12
Text Label 10950 10050 2    50   ~ 0
WD13
Text Label 10950 10150 2    50   ~ 0
WD14
Text Label 10950 10250 2    50   ~ 0
WD15
Text Label 3550 800  3    50   ~ 0
VGA_B2
Text Label 3050 800  3    50   ~ 0
VGA_G2
Text Label 2650 800  3    50   ~ 0
VGA_R2
Text Label 800  1900 0    50   ~ 0
UART_RX
Text Label 800  1800 0    50   ~ 0
UART_TX
Text Label 800  2000 0    50   ~ 0
UART_CTS
Entry Wire Line
	8750 5650 8850 5750
Entry Wire Line
	8750 5750 8850 5850
Entry Wire Line
	8750 5850 8850 5950
Wire Wire Line
	8850 5750 9150 5750
Wire Wire Line
	8850 5850 9150 5850
Wire Wire Line
	8850 5950 9150 5950
Text Label 8850 5750 0    50   ~ 0
SND_BS
Text Label 8850 5850 0    50   ~ 0
SND_WS
Text Label 8850 5950 0    50   ~ 0
SND_DAT
Wire Bus Line
	11050 700  14200 700 
Connection ~ 11050 700 
$Comp
L retro:EPM7128STC100 U4
U 1 1 5F04E529
P 17400 7750
F 0 "U4" H 17350 7900 50  0000 L CNN
F 1 "EPM3128ATC100-5" H 17100 7800 50  0000 L CNN
F 2 "Package_QFP:LQFP-100_14x14mm_P0.5mm" H 17400 7750 50  0001 C CNN
F 3 "" H 17400 7750 50  0001 C CNN
	1    17400 7750
	1    0    0    -1  
$EndComp
Entry Wire Line
	16100 10200 16200 10100
Entry Wire Line
	16200 10200 16300 10100
Entry Wire Line
	16300 10200 16400 10100
Entry Wire Line
	16400 10200 16500 10100
Entry Wire Line
	16500 10200 16600 10100
Entry Wire Line
	16600 10200 16700 10100
Entry Wire Line
	16700 10200 16800 10100
Entry Wire Line
	16800 10200 16900 10100
Entry Wire Line
	16000 10200 16100 10100
Wire Wire Line
	16100 9250 16100 10100
Wire Wire Line
	16200 9250 16200 10100
Wire Wire Line
	16300 9250 16300 10100
Wire Wire Line
	16400 9250 16400 10100
Wire Wire Line
	16500 9250 16500 10100
Wire Wire Line
	16600 9250 16600 10100
Wire Wire Line
	16700 9250 16700 10100
Wire Wire Line
	16800 9250 16800 10100
Wire Wire Line
	16900 9250 16900 10100
Text Label 16200 10100 1    50   ~ 0
WD3
Text Label 16300 10100 1    50   ~ 0
WD11
Text Label 16400 10100 1    50   ~ 0
WD4
Text Label 16500 10100 1    50   ~ 0
WD12
Text Label 16600 10100 1    50   ~ 0
WD5
Text Label 16700 10100 1    50   ~ 0
WD13
Entry Wire Line
	16900 10200 17000 10100
Entry Wire Line
	17000 10200 17100 10100
Entry Wire Line
	17100 10200 17200 10100
Entry Wire Line
	17200 10200 17300 10100
Entry Wire Line
	17300 10200 17400 10100
Entry Wire Line
	17400 10200 17500 10100
Entry Wire Line
	17500 10200 17600 10100
Entry Wire Line
	17600 10200 17700 10100
Entry Wire Line
	17700 10200 17800 10100
Entry Wire Line
	17800 10200 17900 10100
Entry Wire Line
	17900 10200 18000 10100
Entry Wire Line
	18000 10200 18100 10100
Entry Wire Line
	18100 10200 18200 10100
Entry Wire Line
	18200 10200 18300 10100
Entry Wire Line
	18300 10200 18400 10100
Entry Wire Line
	18400 10200 18500 10100
Wire Wire Line
	17000 9250 17000 10100
Wire Wire Line
	17100 10100 17100 9250
Wire Wire Line
	17200 9250 17200 10100
Wire Wire Line
	17300 10100 17300 9250
Wire Wire Line
	17400 9250 17400 10100
Wire Wire Line
	17500 10100 17500 9250
Wire Wire Line
	17600 10100 17600 9250
Wire Wire Line
	17700 10100 17700 9250
Wire Wire Line
	17800 9250 17800 10100
Wire Wire Line
	17900 10100 17900 9250
Wire Wire Line
	18000 9250 18000 10100
Wire Wire Line
	18100 10100 18100 9250
Wire Wire Line
	18200 9250 18200 10100
Wire Wire Line
	18300 10100 18300 9250
Wire Wire Line
	18400 9250 18400 10100
Wire Wire Line
	18500 10100 18500 9250
Text Label 17000 10100 1    50   ~ 0
WD6
Text Label 17100 10100 1    50   ~ 0
WD14
Text Label 17200 10100 1    50   ~ 0
WD7
Text Label 17500 10100 1    50   ~ 0
WD15
Text Label 17600 10100 1    50   ~ 0
~WCS0
Text Label 17700 10100 1    50   ~ 0
~WCS1
Text Label 17900 10100 1    50   ~ 0
~WRD
Text Label 18000 10100 1    50   ~ 0
~WWR
Text Label 18100 10100 1    50   ~ 0
~WRESET
Text Label 18200 10100 1    50   ~ 0
WA2
Text Label 18300 10100 1    50   ~ 0
WA1
Text Label 18400 10100 1    50   ~ 0
WA0
Text Label 18500 10100 1    50   ~ 0
WD0
Entry Wire Line
	20250 8800 20350 8700
Entry Wire Line
	20250 8700 20350 8600
Entry Wire Line
	20250 8600 20350 8500
Entry Wire Line
	20250 8500 20350 8400
Entry Wire Line
	20250 8400 20350 8300
Entry Wire Line
	20250 8300 20350 8200
Entry Wire Line
	20250 8200 20350 8100
Entry Wire Line
	20250 8100 20350 8000
Entry Wire Line
	20250 8000 20350 7900
Entry Wire Line
	20250 7900 20350 7800
Entry Wire Line
	20250 7800 20350 7700
Entry Wire Line
	20250 7700 20350 7600
Entry Wire Line
	20250 7600 20350 7500
Entry Wire Line
	20250 7500 20350 7400
Entry Wire Line
	20250 7400 20350 7300
Entry Wire Line
	20250 7300 20350 7200
Entry Wire Line
	20250 7200 20350 7100
Entry Wire Line
	20250 7100 20350 7000
Entry Wire Line
	20250 7000 20350 6900
Entry Wire Line
	20250 6900 20350 6800
Entry Wire Line
	20250 6800 20350 6700
Entry Wire Line
	20250 6700 20350 6600
Entry Wire Line
	20250 6600 20350 6500
Entry Wire Line
	20250 6500 20350 6400
Entry Wire Line
	20250 6400 20350 6300
Wire Wire Line
	19000 6400 20250 6400
Wire Wire Line
	20250 6500 19000 6500
Wire Wire Line
	19000 6600 20250 6600
Wire Wire Line
	20250 6700 19000 6700
Wire Wire Line
	19000 6800 20250 6800
Wire Wire Line
	20250 6900 19000 6900
Wire Wire Line
	19000 7000 20250 7000
Wire Wire Line
	20250 7100 19000 7100
Wire Wire Line
	19000 7200 20250 7200
Wire Wire Line
	20250 7300 19000 7300
Wire Wire Line
	19000 7400 20250 7400
Wire Wire Line
	20250 7500 19000 7500
Wire Wire Line
	19000 7600 20250 7600
Wire Wire Line
	20250 7700 19000 7700
Wire Wire Line
	19000 7800 20250 7800
Wire Wire Line
	20250 7900 19000 7900
Wire Wire Line
	19000 8000 20250 8000
Wire Wire Line
	20250 8100 19000 8100
Wire Wire Line
	19000 8200 20250 8200
Wire Wire Line
	20250 8300 19000 8300
Wire Wire Line
	19000 8400 20250 8400
Wire Wire Line
	20250 8500 19000 8500
Wire Wire Line
	19000 8600 20250 8600
Wire Wire Line
	20250 8700 19000 8700
Wire Wire Line
	19000 8800 20250 8800
Text Label 20250 8700 2    50   ~ 0
WD1
Text Label 20250 8500 2    50   ~ 0
WD8
Text Label 20250 8400 2    50   ~ 0
WD2
Text Label 20250 8300 2    50   ~ 0
WD9
Text Label 20250 8200 2    50   ~ 0
WD10
Text Label 20250 8100 2    50   ~ 0
~FDC_RST
Text Label 20250 7900 2    50   ~ 0
FDC_SR
Text Label 20250 7800 2    50   ~ 0
FDC_SL
Text Label 20250 7600 2    50   ~ 0
D7
Text Label 20250 7500 2    50   ~ 0
D6
Text Label 20250 7200 2    50   ~ 0
D5
Text Label 20250 7100 2    50   ~ 0
D4
Text Label 20250 7000 2    50   ~ 0
D3
Text Label 20250 6900 2    50   ~ 0
D2
Text Label 20250 6800 2    50   ~ 0
D1
Text Label 20250 6700 2    50   ~ 0
D0
Text Label 20250 6400 2    50   ~ 0
FDC_A1
Entry Wire Line
	16000 4950 16100 5050
Entry Wire Line
	16100 4950 16200 5050
Entry Wire Line
	16200 4950 16300 5050
Entry Wire Line
	16300 4950 16400 5050
Entry Wire Line
	16400 4950 16500 5050
Entry Wire Line
	16500 4950 16600 5050
Entry Wire Line
	16600 4950 16700 5050
Entry Wire Line
	16700 4950 16800 5050
Entry Wire Line
	16800 4950 16900 5050
Entry Wire Line
	16900 4950 17000 5050
Entry Wire Line
	17000 4950 17100 5050
Entry Wire Line
	17100 4950 17200 5050
Entry Wire Line
	17200 4950 17300 5050
Entry Wire Line
	17300 4950 17400 5050
Entry Wire Line
	17400 4950 17500 5050
Entry Wire Line
	17500 4950 17600 5050
Entry Wire Line
	17600 4950 17700 5050
Entry Wire Line
	17700 4950 17800 5050
Entry Wire Line
	17800 4950 17900 5050
Entry Wire Line
	17900 4950 18000 5050
Entry Wire Line
	18000 4950 18100 5050
Entry Wire Line
	18100 4950 18200 5050
Entry Wire Line
	18200 4950 18300 5050
Entry Wire Line
	18300 4950 18400 5050
Entry Wire Line
	18400 4950 18500 5050
Wire Wire Line
	18500 5050 18500 5950
Wire Wire Line
	18400 5950 18400 5050
Wire Wire Line
	18300 5050 18300 5950
Wire Wire Line
	18200 5950 18200 5050
Wire Wire Line
	18100 5050 18100 5950
Wire Wire Line
	18000 5950 18000 5050
Wire Wire Line
	17900 5050 17900 5950
Wire Wire Line
	17800 5950 17800 5050
Wire Wire Line
	17700 5050 17700 5950
Wire Wire Line
	17600 5950 17600 5050
Wire Wire Line
	17500 5050 17500 5950
Wire Wire Line
	17400 5950 17400 5050
Wire Wire Line
	17300 5050 17300 5950
Wire Wire Line
	17200 5950 17200 5050
Wire Wire Line
	17100 5050 17100 5950
Wire Wire Line
	17000 5950 17000 5050
Wire Wire Line
	16900 5050 16900 5950
Wire Wire Line
	16800 5950 16800 5050
Wire Wire Line
	16700 5050 16700 5950
Wire Wire Line
	16600 5950 16600 5050
Wire Wire Line
	16500 5050 16500 5950
Wire Wire Line
	16400 5950 16400 5050
Wire Wire Line
	16300 5050 16300 5950
Wire Wire Line
	16200 5950 16200 5050
Wire Wire Line
	16100 5050 16100 5950
Text Label 18500 5050 3    50   ~ 0
FDC_A0
Text Label 18400 5050 3    50   ~ 0
~RD
Text Label 18200 5050 3    50   ~ 0
~FDC_CS
Text Label 18100 5050 3    50   ~ 0
~WR
Text Label 18000 5050 3    50   ~ 0
FDC_HLT
Text Label 17800 5050 3    50   ~ 0
FDC_CLK
Text Label 17700 5050 3    50   ~ 0
FDC_TR43
Text Label 17600 5050 3    50   ~ 0
~FDC_RDATA
Text Label 17400 5050 3    50   ~ 0
CPLD_CLK
Text Label 17300 5050 3    50   ~ 0
FDC_WD
Text Label 17200 5050 3    50   ~ 0
FDC_WF_DE
Text Label 17100 5050 3    50   ~ 0
CPLD_CLK2
Text Label 16900 5050 3    50   ~ 0
FDC_DRQ
Text Label 16800 5050 3    50   ~ 0
FDC_INTRQ
Text Label 16700 5050 3    50   ~ 0
~FDC_RAWR
Text Label 16500 5050 3    50   ~ 0
FDC_RCLK
Text Label 16400 5050 3    50   ~ 0
~FDC_SIDE
Text Label 16300 5050 3    50   ~ 0
FDC_WDATA
Text Label 16200 5050 3    50   ~ 0
FDC_DS0
Text Label 16100 5050 3    50   ~ 0
FDC_DS1
Entry Wire Line
	14200 6300 14300 6400
Entry Wire Line
	14200 6400 14300 6500
Entry Wire Line
	14200 6500 14300 6600
Entry Wire Line
	14200 6600 14300 6700
Entry Wire Line
	14200 6700 14300 6800
Entry Wire Line
	14200 6800 14300 6900
Entry Wire Line
	14200 6900 14300 7000
Entry Wire Line
	14200 7000 14300 7100
Entry Wire Line
	14200 7100 14300 7200
Entry Wire Line
	14200 7200 14300 7300
Entry Wire Line
	14200 7300 14300 7400
Entry Wire Line
	14200 7400 14300 7500
Entry Wire Line
	14200 7500 14300 7600
Entry Wire Line
	14200 7600 14300 7700
Entry Wire Line
	14200 7700 14300 7800
Entry Wire Line
	14200 7800 14300 7900
Entry Wire Line
	14200 7900 14300 8000
Entry Wire Line
	14200 8000 14300 8100
Entry Wire Line
	14200 8100 14300 8200
Entry Wire Line
	14200 8200 14300 8300
Entry Wire Line
	14200 8300 14300 8400
Entry Wire Line
	14200 8400 14300 8500
Entry Wire Line
	14200 8500 14300 8600
Entry Wire Line
	14200 8600 14300 8700
Entry Wire Line
	14200 8700 14300 8800
Wire Wire Line
	14300 8800 15600 8800
Wire Wire Line
	15600 8700 14300 8700
Wire Wire Line
	14300 8600 15600 8600
Wire Wire Line
	15600 8500 14300 8500
Wire Wire Line
	14300 8400 15600 8400
Wire Wire Line
	15600 8300 14300 8300
Wire Wire Line
	14300 8200 15600 8200
Wire Wire Line
	15600 8100 14300 8100
Wire Wire Line
	14300 8000 15600 8000
Wire Wire Line
	15600 7900 14300 7900
Wire Wire Line
	14300 7800 15600 7800
Wire Wire Line
	15600 7700 14300 7700
Wire Wire Line
	14300 7600 15600 7600
Wire Wire Line
	15600 7500 14300 7500
Wire Wire Line
	14300 7400 15600 7400
Wire Wire Line
	15600 7300 14300 7300
Wire Wire Line
	14300 7200 15600 7200
Wire Wire Line
	15600 7100 14300 7100
Wire Wire Line
	14300 7000 15600 7000
Wire Wire Line
	15600 6900 14300 6900
Wire Wire Line
	14300 6800 15600 6800
Wire Wire Line
	15600 6700 14300 6700
Wire Wire Line
	14300 6600 15600 6600
Wire Wire Line
	15600 6500 15000 6500
Wire Wire Line
	14300 6400 15350 6400
Text Label 14300 8800 0    50   ~ 0
SD15
Text Label 14300 8700 0    50   ~ 0
SD14
Text Label 14300 8600 0    50   ~ 0
SD13
Text Label 14300 8500 0    50   ~ 0
SD12
Text Label 14300 8400 0    50   ~ 0
SD11
Text Label 14300 8300 0    50   ~ 0
SD10
Text Label 14300 8200 0    50   ~ 0
SD9
Text Label 14300 8000 0    50   ~ 0
SD8
Text Label 14300 7900 0    50   ~ 0
SD7
Text Label 14300 7700 0    50   ~ 0
SD6
Text Label 14300 7600 0    50   ~ 0
SD5
Text Label 14300 7500 0    50   ~ 0
SD4
Text Label 14300 7300 0    50   ~ 0
SD3
Text Label 14300 7200 0    50   ~ 0
SD2
Text Label 14300 7100 0    50   ~ 0
SD1
Text Label 14300 7000 0    50   ~ 0
SD0
Text Label 14300 6900 0    50   ~ 0
SA1
Text Label 14300 6800 0    50   ~ 0
SA0
Text Label 14300 6500 0    50   ~ 0
SDIR
Text Label 14300 6400 0    50   ~ 0
~RESET
$Comp
L 74xx:74LS06 U17
U 1 1 5EDD7FC8
P 4050 10650
F 0 "U17" H 4050 10967 50  0000 C CNN
F 1 "74LS06" H 4050 10876 50  0000 C CNN
F 2 "Package_DIP:DIP-14_W7.62mm" H 4050 10650 50  0001 C CNN
F 3 "http://www.ti.com/lit/gpn/sn74LS06" H 4050 10650 50  0001 C CNN
	1    4050 10650
	1    0    0    -1  
$EndComp
$Comp
L Device:R R10
U 1 1 6338A1BA
P 11650 1200
F 0 "R10" V 11700 1000 50  0000 C CNN
F 1 "2k" V 11700 850 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 1200 50  0001 C CNN
F 3 "~" H 11650 1200 50  0001 C CNN
	1    11650 1200
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R11
U 1 1 633910D6
P 11650 1350
F 0 "R11" V 11700 1150 50  0000 C CNN
F 1 "1k" V 11700 1000 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 1350 50  0001 C CNN
F 3 "~" H 11650 1350 50  0001 C CNN
	1    11650 1350
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R12
U 1 1 63391549
P 11650 1500
F 0 "R12" V 11600 1300 50  0000 C CNN
F 1 "510" V 11600 1150 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 1500 50  0001 C CNN
F 3 "~" H 11650 1500 50  0001 C CNN
	1    11650 1500
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R13
U 1 1 6339189A
P 11650 1800
F 0 "R13" V 11700 1600 50  0000 C CNN
F 1 "2k" V 11700 1450 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 1800 50  0001 C CNN
F 3 "~" H 11650 1800 50  0001 C CNN
	1    11650 1800
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R14
U 1 1 63391B7A
P 11650 1950
F 0 "R14" V 11700 1750 50  0000 C CNN
F 1 "1k" V 11700 1600 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 1950 50  0001 C CNN
F 3 "~" H 11650 1950 50  0001 C CNN
	1    11650 1950
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R15
U 1 1 63391EA9
P 11650 2100
F 0 "R15" V 11600 1900 50  0000 C CNN
F 1 "510" V 11600 1750 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 2100 50  0001 C CNN
F 3 "~" H 11650 2100 50  0001 C CNN
	1    11650 2100
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R16
U 1 1 63392253
P 11650 2400
F 0 "R16" V 11700 2200 50  0000 C CNN
F 1 "2k" V 11700 2050 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 2400 50  0001 C CNN
F 3 "~" H 11650 2400 50  0001 C CNN
	1    11650 2400
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R17
U 1 1 63392627
P 11650 2550
F 0 "R17" V 11700 2350 50  0000 C CNN
F 1 "1k" V 11700 2200 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 2550 50  0001 C CNN
F 3 "~" H 11650 2550 50  0001 C CNN
	1    11650 2550
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R18
U 1 1 63392A40
P 11650 2700
F 0 "R18" V 11700 2500 50  0000 C CNN
F 1 "510" V 11700 2350 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11580 2700 50  0001 C CNN
F 3 "~" H 11650 2700 50  0001 C CNN
	1    11650 2700
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R19
U 1 1 63392E3B
P 13350 1900
F 0 "R19" V 13557 1900 50  0000 C CNN
F 1 "75" V 13466 1900 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13280 1900 50  0001 C CNN
F 3 "~" H 13350 1900 50  0001 C CNN
	1    13350 1900
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R20
U 1 1 633931B7
P 13350 2100
F 0 "R20" V 13250 2100 50  0000 C CNN
F 1 "75" V 13150 2100 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13280 2100 50  0001 C CNN
F 3 "~" H 13350 2100 50  0001 C CNN
	1    13350 2100
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R21
U 1 1 633935FA
P 13150 2850
F 0 "R21" V 13357 2850 50  0000 C CNN
F 1 "4k7" V 13266 2850 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13080 2850 50  0001 C CNN
F 3 "~" H 13150 2850 50  0001 C CNN
	1    13150 2850
	-1   0    0    1   
$EndComp
$Comp
L Device:R R22
U 1 1 6339398D
P 13450 2850
F 0 "R22" V 13657 2850 50  0000 C CNN
F 1 "4k7" V 13566 2850 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13380 2850 50  0001 C CNN
F 3 "~" H 13450 2850 50  0001 C CNN
	1    13450 2850
	-1   0    0    1   
$EndComp
$Comp
L Device:R R23
U 1 1 63393D02
P 13150 3900
F 0 "R23" V 13357 3900 50  0000 C CNN
F 1 "4k7" V 13266 3900 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13080 3900 50  0001 C CNN
F 3 "~" H 13150 3900 50  0001 C CNN
	1    13150 3900
	-1   0    0    1   
$EndComp
$Comp
L Device:R R24
U 1 1 6339410F
P 13450 3900
F 0 "R24" V 13657 3900 50  0000 C CNN
F 1 "4k7" V 13566 3900 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13380 3900 50  0001 C CNN
F 3 "~" H 13450 3900 50  0001 C CNN
	1    13450 3900
	-1   0    0    1   
$EndComp
$Comp
L Device:R R9
U 1 1 633A3A16
P 9400 1400
F 0 "R9" V 9607 1400 50  0000 C CNN
F 1 "10k" V 9516 1400 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 9330 1400 50  0001 C CNN
F 3 "~" H 9400 1400 50  0001 C CNN
	1    9400 1400
	0    -1   -1   0   
$EndComp
$Comp
L RF_Module:ESP-12E U10
U 1 1 61EDA355
P 12500 11000
F 0 "U10" H 12500 11981 50  0000 C CNN
F 1 "ESP-12E" H 12500 11890 50  0000 C CNN
F 2 "RF_Module:ESP-12E" H 12500 11000 50  0001 C CNN
F 3 "http://wiki.ai-thinker.com/_media/esp8266/esp8266_series_modules_user_manual_v1.1.pdf" H 12150 11100 50  0001 C CNN
	1    12500 11000
	1    0    0    -1  
$EndComp
$Comp
L Logic_LevelTranslator:TXB0104PW U7
U 1 1 5EF177A0
P 7600 9050
F 0 "U7" H 7900 9850 50  0000 C CNN
F 1 "TXB0104PW" H 8050 9750 50  0000 C CNN
F 2 "Package_SO:TSSOP-14_4.4x5mm_P0.65mm" H 7600 8300 50  0001 C CNN
F 3 "http://www.ti.com/lit/ds/symlink/txb0104.pdf" H 7710 9145 50  0001 C CNN
	1    7600 9050
	1    0    0    -1  
$EndComp
$Comp
L Logic_LevelTranslator:TXB0104PW U8
U 1 1 5EF19104
P 7600 11000
F 0 "U8" H 7900 11800 50  0000 C CNN
F 1 "TXB0104PW" H 8050 11700 50  0000 C CNN
F 2 "Package_SO:TSSOP-14_4.4x5mm_P0.65mm" H 7600 10250 50  0001 C CNN
F 3 "http://www.ti.com/lit/ds/symlink/txb0104.pdf" H 7710 11095 50  0001 C CNN
	1    7600 11000
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0118
U 1 1 5EF9878B
P 7700 8350
F 0 "#PWR0118" H 7700 8200 50  0001 C CNN
F 1 "VCC" H 7715 8523 50  0000 C CNN
F 2 "" H 7700 8350 50  0001 C CNN
F 3 "" H 7700 8350 50  0001 C CNN
	1    7700 8350
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0119
U 1 1 5EF99214
P 7700 10300
F 0 "#PWR0119" H 7700 10150 50  0001 C CNN
F 1 "VCC" H 7715 10473 50  0000 C CNN
F 2 "" H 7700 10300 50  0001 C CNN
F 3 "" H 7700 10300 50  0001 C CNN
	1    7700 10300
	1    0    0    -1  
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0120
U 1 1 5EF9E550
P 7500 8350
F 0 "#PWR0120" H 7500 8200 50  0001 C CNN
F 1 "VCC3_3" H 7450 8500 50  0000 C CNN
F 2 "" H 7500 8350 50  0001 C CNN
F 3 "" H 7500 8350 50  0001 C CNN
	1    7500 8350
	1    0    0    -1  
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0121
U 1 1 5EFA4F46
P 7500 10300
F 0 "#PWR0121" H 7500 10150 50  0001 C CNN
F 1 "VCC3_3" H 7450 10450 50  0000 C CNN
F 2 "" H 7500 10300 50  0001 C CNN
F 3 "" H 7500 10300 50  0001 C CNN
	1    7500 10300
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0122
U 1 1 5EFF7882
P 7600 9750
F 0 "#PWR0122" H 7600 9500 50  0001 C CNN
F 1 "GND" H 7605 9577 50  0000 C CNN
F 2 "" H 7600 9750 50  0001 C CNN
F 3 "" H 7600 9750 50  0001 C CNN
	1    7600 9750
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0123
U 1 1 5EFF7FB3
P 7600 11700
F 0 "#PWR0123" H 7600 11450 50  0001 C CNN
F 1 "GND" H 7605 11527 50  0000 C CNN
F 2 "" H 7600 11700 50  0001 C CNN
F 3 "" H 7600 11700 50  0001 C CNN
	1    7600 11700
	1    0    0    -1  
$EndComp
Wire Wire Line
	7200 8550 7200 8350
Wire Wire Line
	7200 8350 7500 8350
Connection ~ 7500 8350
Wire Wire Line
	7200 10500 7200 10300
Wire Wire Line
	7200 10300 7500 10300
Connection ~ 7500 10300
Entry Wire Line
	6500 8850 6600 8950
Entry Wire Line
	6500 9050 6600 9150
Entry Wire Line
	6500 9250 6600 9350
Entry Wire Line
	6500 10600 6600 10700
Entry Wire Line
	6500 10800 6600 10900
Entry Wire Line
	6500 11000 6600 11100
Entry Wire Line
	6500 11200 6600 11300
Wire Wire Line
	6600 10700 7200 10700
Wire Wire Line
	7200 10900 6600 10900
Wire Wire Line
	6600 11100 7200 11100
Wire Wire Line
	7200 11300 6600 11300
Wire Wire Line
	6600 9350 7200 9350
Wire Wire Line
	7200 9150 6600 9150
Wire Wire Line
	6600 8950 7200 8950
Entry Wire Line
	8650 8950 8750 8850
Entry Wire Line
	8650 9150 8750 9050
Entry Wire Line
	8650 9350 8750 9250
Entry Wire Line
	8650 10700 8750 10600
Entry Wire Line
	8650 10900 8750 10800
Entry Wire Line
	8650 11100 8750 11000
Entry Wire Line
	8650 11300 8750 11200
Wire Wire Line
	8000 10700 8650 10700
Wire Wire Line
	8650 10900 8000 10900
Wire Wire Line
	8000 11100 8650 11100
Wire Wire Line
	8650 11300 8000 11300
Wire Wire Line
	8650 8950 8000 8950
Wire Wire Line
	8000 9150 8650 9150
Wire Wire Line
	8650 9350 8000 9350
Text Label 6600 8950 0    50   ~ 0
LSND_BS
Text Label 6600 9350 0    50   ~ 0
LSND_DAT
Text Label 6600 9150 0    50   ~ 0
LSND_WS
Text Label 8650 9350 2    50   ~ 0
SND_DAT
Text Label 8650 9150 2    50   ~ 0
SND_WS
Text Label 8650 8950 2    50   ~ 0
SND_BS
Text Label 6600 10700 0    50   ~ 0
LAVR_MOSI
Text Label 6600 10900 0    50   ~ 0
LAVR_SCK
Text Label 6600 11100 0    50   ~ 0
~LAVR_CS
Text Label 6600 11300 0    50   ~ 0
LAVR_MISO
Text Label 8650 10700 2    50   ~ 0
AVR_MOSI
Text Label 8650 10900 2    50   ~ 0
AVR_SCK
Text Label 8650 11100 2    50   ~ 0
~AVR_CS
Text Label 8650 11300 2    50   ~ 0
AVR_MISO
$Comp
L Device:R R25
U 1 1 5F614B1C
P 10150 6300
F 0 "R25" H 9950 6400 50  0000 L CNN
F 1 "820" H 9950 6300 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 10080 6300 50  0001 C CNN
F 3 "~" H 10150 6300 50  0001 C CNN
	1    10150 6300
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0124
U 1 1 5F66A4E2
P 10200 5650
F 0 "#PWR0124" H 10200 5500 50  0001 C CNN
F 1 "VCC" H 10215 5823 50  0000 C CNN
F 2 "" H 10200 5650 50  0001 C CNN
F 3 "" H 10200 5650 50  0001 C CNN
	1    10200 5650
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0125
U 1 1 5F67DB82
P 9150 6050
F 0 "#PWR0125" H 9150 5800 50  0001 C CNN
F 1 "GND" H 9155 5877 50  0000 C CNN
F 2 "" H 9150 6050 50  0001 C CNN
F 3 "" H 9150 6050 50  0001 C CNN
	1    9150 6050
	1    0    0    -1  
$EndComp
$Comp
L Device:R R26
U 1 1 5F688144
P 10300 6300
F 0 "R26" H 10300 6550 50  0000 L CNN
F 1 "750" H 10300 6450 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 10230 6300 50  0001 C CNN
F 3 "~" H 10300 6300 50  0001 C CNN
	1    10300 6300
	1    0    0    -1  
$EndComp
$Comp
L Device:R R27
U 1 1 5F688557
P 10450 6300
F 0 "R27" H 10520 6346 50  0000 L CNN
F 1 "750" H 10520 6255 50  0000 L CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 10380 6300 50  0001 C CNN
F 3 "~" H 10450 6300 50  0001 C CNN
	1    10450 6300
	1    0    0    -1  
$EndComp
Wire Wire Line
	10100 5850 10150 5850
Wire Wire Line
	10150 5850 10150 6150
Wire Wire Line
	10100 6050 10200 6050
Wire Wire Line
	10200 6050 10200 5650
Wire Wire Line
	10100 5950 10300 5950
Wire Wire Line
	10300 5950 10300 6150
Wire Wire Line
	10100 5750 10350 5750
$Comp
L power:GND #PWR0130
U 1 1 5F7CB139
P 10150 6450
F 0 "#PWR0130" H 10150 6200 50  0001 C CNN
F 1 "GND" H 10155 6277 50  0000 C CNN
F 2 "" H 10150 6450 50  0001 C CNN
F 3 "" H 10150 6450 50  0001 C CNN
	1    10150 6450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0131
U 1 1 5F7CB607
P 10300 6450
F 0 "#PWR0131" H 10300 6200 50  0001 C CNN
F 1 "GND" H 10305 6277 50  0000 C CNN
F 2 "" H 10300 6450 50  0001 C CNN
F 3 "" H 10300 6450 50  0001 C CNN
	1    10300 6450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0132
U 1 1 5F7CBA6A
P 10450 6450
F 0 "#PWR0132" H 10450 6200 50  0001 C CNN
F 1 "GND" H 10455 6277 50  0000 C CNN
F 2 "" H 10450 6450 50  0001 C CNN
F 3 "" H 10450 6450 50  0001 C CNN
	1    10450 6450
	1    0    0    -1  
$EndComp
$Comp
L Device:C C1
U 1 1 5F884DC3
P 10600 5750
F 0 "C1" V 10852 5750 50  0000 C CNN
F 1 "10uF" V 10761 5750 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 10638 5600 50  0001 C CNN
F 3 "~" H 10600 5750 50  0001 C CNN
	1    10600 5750
	0    -1   -1   0   
$EndComp
$Comp
L Device:C C2
U 1 1 5F8D8414
P 10600 5950
F 0 "C2" V 10550 5850 50  0000 C CNN
F 1 "10uF" V 10450 5850 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 10638 5800 50  0001 C CNN
F 3 "~" H 10600 5950 50  0001 C CNN
	1    10600 5950
	0    -1   -1   0   
$EndComp
Entry Wire Line
	10950 5750 11050 5650
Entry Wire Line
	10950 5950 11050 5850
Wire Wire Line
	10750 5750 10950 5750
Wire Wire Line
	10750 5950 10950 5950
Text Label 10950 5750 2    50   ~ 0
SND_R
Text Label 10950 5950 2    50   ~ 0
SND_L
Wire Wire Line
	10450 5950 10300 5950
Connection ~ 10300 5950
Wire Wire Line
	10450 6150 10450 6000
Wire Wire Line
	10450 6000 10350 6000
Wire Wire Line
	10350 6000 10350 5750
Connection ~ 10350 5750
Wire Wire Line
	10350 5750 10450 5750
Entry Wire Line
	11050 7650 11150 7750
Entry Wire Line
	11050 7550 11150 7650
Entry Wire Line
	11050 7450 11150 7550
Wire Wire Line
	11150 7550 11900 7550
Wire Wire Line
	11900 7650 11150 7650
Wire Wire Line
	11150 7750 11900 7750
Text Label 11150 7750 0    50   ~ 0
SND_L
Text Label 11150 7650 0    50   ~ 0
SND_R
Text Label 11150 7550 0    50   ~ 0
GND
$Comp
L power:VCC #PWR0133
U 1 1 5F01D5C6
P 9650 6800
F 0 "#PWR0133" H 9650 6650 50  0001 C CNN
F 1 "VCC" H 9665 6973 50  0000 C CNN
F 2 "" H 9650 6800 50  0001 C CNN
F 3 "" H 9650 6800 50  0001 C CNN
	1    9650 6800
	1    0    0    -1  
$EndComp
Wire Wire Line
	9750 6900 10150 6900
$Comp
L power:GND #PWR0134
U 1 1 5F0C40A6
P 10550 6900
F 0 "#PWR0134" H 10550 6650 50  0001 C CNN
F 1 "GND" H 10555 6727 50  0000 C CNN
F 2 "" H 10550 6900 50  0001 C CNN
F 3 "" H 10550 6900 50  0001 C CNN
	1    10550 6900
	1    0    0    -1  
$EndComp
Wire Wire Line
	10450 6900 10550 6900
Wire Wire Line
	9650 6900 9650 6800
NoConn ~ 10250 7300
Entry Wire Line
	8750 7000 8850 7100
Entry Wire Line
	8750 7100 8850 7200
Wire Wire Line
	8850 7100 9250 7100
Wire Wire Line
	8850 7200 9250 7200
Text Label 8850 7100 0    50   ~ 0
I2C_SCL
Text Label 8850 7200 0    50   ~ 0
I2C_SDA
$Comp
L Device:Crystal_GND3 Y1
U 1 1 5F262AD2
P 9000 7600
F 0 "Y1" H 9000 7868 50  0000 C CNN
F 1 "32768Hz" H 9000 7777 50  0000 C CNN
F 2 "Crystal:Crystal_AT310_D3.0mm_L10.0mm_Horizontal_1EP_style2" H 9000 7600 50  0001 C CNN
F 3 "~" H 9000 7600 50  0001 C CNN
	1    9000 7600
	1    0    0    -1  
$EndComp
Wire Wire Line
	8850 7400 8850 7600
Wire Wire Line
	8850 7400 9250 7400
Wire Wire Line
	9250 7500 9250 7600
Wire Wire Line
	9250 7600 9150 7600
$Comp
L power:GND #PWR0135
U 1 1 5F40E841
P 9750 7700
F 0 "#PWR0135" H 9750 7450 50  0001 C CNN
F 1 "GND" H 9755 7527 50  0000 C CNN
F 2 "" H 9750 7700 50  0001 C CNN
F 3 "" H 9750 7700 50  0001 C CNN
	1    9750 7700
	1    0    0    -1  
$EndComp
Wire Wire Line
	12350 1500 12000 1500
Wire Wire Line
	11800 1350 12000 1350
Wire Wire Line
	12000 1350 12000 1500
Connection ~ 12000 1500
Wire Wire Line
	12000 1500 11800 1500
Wire Wire Line
	11800 1200 12000 1200
Wire Wire Line
	12000 1200 12000 1350
Connection ~ 12000 1350
Wire Wire Line
	12350 1700 12000 1700
Wire Wire Line
	12000 1700 12000 1800
Wire Wire Line
	12000 2100 11800 2100
Wire Wire Line
	11800 1950 12000 1950
Connection ~ 12000 1950
Wire Wire Line
	12000 1950 12000 2100
Wire Wire Line
	11800 1800 12000 1800
Connection ~ 12000 1800
Wire Wire Line
	12000 1800 12000 1950
Wire Wire Line
	12350 1900 12100 1900
Wire Wire Line
	12100 1900 12100 2400
Wire Wire Line
	12100 2700 11800 2700
Wire Wire Line
	11800 2550 12100 2550
Connection ~ 12100 2550
Wire Wire Line
	12100 2550 12100 2700
Wire Wire Line
	11800 2400 12100 2400
Connection ~ 12100 2400
Wire Wire Line
	12100 2400 12100 2550
Wire Wire Line
	12350 1400 12250 1400
Wire Wire Line
	12250 1400 12250 1600
Wire Wire Line
	12250 1600 12350 1600
Wire Wire Line
	12350 1800 12250 1800
Wire Wire Line
	12250 1800 12250 1600
Connection ~ 12250 1600
Wire Wire Line
	12350 2200 12250 2200
Wire Wire Line
	12250 2200 12250 1800
Connection ~ 12250 1800
$Comp
L power:GND #PWR0136
U 1 1 5FB63D74
P 12250 2600
F 0 "#PWR0136" H 12250 2350 50  0001 C CNN
F 1 "GND" H 12255 2427 50  0000 C CNN
F 2 "" H 12250 2600 50  0001 C CNN
F 3 "" H 12250 2600 50  0001 C CNN
	1    12250 2600
	1    0    0    -1  
$EndComp
Wire Wire Line
	12250 2200 12250 2300
Connection ~ 12250 2200
Wire Wire Line
	12350 2300 12250 2300
Connection ~ 12250 2300
Wire Wire Line
	12250 2300 12250 2600
Wire Wire Line
	12950 1900 13200 1900
Wire Wire Line
	12950 2100 13200 2100
NoConn ~ 12950 1500
NoConn ~ 12950 1700
NoConn ~ 12950 2300
NoConn ~ 12350 2100
NoConn ~ 12350 2000
Entry Wire Line
	11050 1100 11150 1200
Entry Wire Line
	11050 1250 11150 1350
Entry Wire Line
	11050 1400 11150 1500
Entry Wire Line
	11050 1700 11150 1800
Entry Wire Line
	11050 1850 11150 1950
Entry Wire Line
	11050 2000 11150 2100
Entry Wire Line
	11050 2300 11150 2400
Entry Wire Line
	11050 2450 11150 2550
Entry Wire Line
	11050 2600 11150 2700
Wire Wire Line
	11150 1200 11500 1200
Wire Wire Line
	11500 1350 11150 1350
Wire Wire Line
	11150 1500 11500 1500
Wire Wire Line
	11500 1800 11150 1800
Wire Wire Line
	11150 1950 11500 1950
Wire Wire Line
	11500 2100 11150 2100
Wire Wire Line
	11150 2400 11500 2400
Wire Wire Line
	11500 2550 11150 2550
Wire Wire Line
	11150 2700 11500 2700
Entry Wire Line
	14100 1900 14200 1800
Entry Wire Line
	14100 2100 14200 2000
Wire Wire Line
	13500 1900 14100 1900
Wire Wire Line
	13500 2100 14100 2100
Text Label 12100 1500 0    50   ~ 0
R
Text Label 12100 1700 0    50   ~ 0
G
Text Label 12100 1900 0    50   ~ 0
B
Text Label 13000 1900 0    50   ~ 0
HS
Text Label 13000 2100 0    50   ~ 0
VS
Text Label 11150 1200 0    50   ~ 0
VGA_R0
Text Label 11150 1350 0    50   ~ 0
VGA_R1
Text Label 11150 1500 0    50   ~ 0
VGA_R2
Text Label 11150 1800 0    50   ~ 0
VGA_G0
Text Label 11150 1950 0    50   ~ 0
VGA_G1
Text Label 11150 2100 0    50   ~ 0
VGA_G2
Text Label 11150 2400 0    50   ~ 0
VGA_B0
Text Label 11150 2550 0    50   ~ 0
VGA_B1
Text Label 11150 2700 0    50   ~ 0
VGA_B2
Text Label 14100 1900 2    50   ~ 0
VGA_HS
Text Label 14100 2100 2    50   ~ 0
VGA_VS
$Comp
L power:GND #PWR0137
U 1 1 6043121C
P 17050 3000
F 0 "#PWR0137" H 17050 2750 50  0001 C CNN
F 1 "GND" H 17055 2827 50  0000 C CNN
F 2 "" H 17050 3000 50  0001 C CNN
F 3 "" H 17050 3000 50  0001 C CNN
	1    17050 3000
	0    -1   -1   0   
$EndComp
$Comp
L power:VCC #PWR0138
U 1 1 60492124
P 17050 3200
F 0 "#PWR0138" H 17050 3050 50  0001 C CNN
F 1 "VCC" H 17065 3373 50  0000 C CNN
F 2 "" H 17050 3200 50  0001 C CNN
F 3 "" H 17050 3200 50  0001 C CNN
	1    17050 3200
	0    1    1    0   
$EndComp
Wire Wire Line
	16800 3000 16900 3000
Wire Wire Line
	16800 3100 16900 3100
Wire Wire Line
	16900 3100 16900 3000
Connection ~ 16900 3000
Wire Wire Line
	16900 3000 17050 3000
Wire Wire Line
	16800 3200 17050 3200
NoConn ~ 16800 2900
Wire Wire Line
	13150 3150 13150 3000
Wire Wire Line
	12950 3150 13150 3150
$Comp
L power:GND #PWR0139
U 1 1 608CA405
P 12950 3250
F 0 "#PWR0139" H 12950 3000 50  0001 C CNN
F 1 "GND" H 12955 3077 50  0000 C CNN
F 2 "" H 12950 3250 50  0001 C CNN
F 3 "" H 12950 3250 50  0001 C CNN
	1    12950 3250
	0    -1   -1   0   
$EndComp
$Comp
L power:VCC #PWR0140
U 1 1 60931B05
P 12350 3250
F 0 "#PWR0140" H 12350 3100 50  0001 C CNN
F 1 "VCC" H 12365 3423 50  0000 C CNN
F 2 "" H 12350 3250 50  0001 C CNN
F 3 "" H 12350 3250 50  0001 C CNN
	1    12350 3250
	0    -1   -1   0   
$EndComp
NoConn ~ 12350 3150
NoConn ~ 12350 3350
Entry Wire Line
	14100 3000 14200 2900
Entry Wire Line
	14100 3350 14200 3250
Text Label 14100 3350 2    50   ~ 0
PS2_KB_DATA
Text Label 14100 3000 2    50   ~ 0
PS2_KB_CLK
$Comp
L power:GND #PWR0141
U 1 1 60B9F5B1
P 12950 4250
F 0 "#PWR0141" H 12950 4000 50  0001 C CNN
F 1 "GND" H 12955 4077 50  0000 C CNN
F 2 "" H 12950 4250 50  0001 C CNN
F 3 "" H 12950 4250 50  0001 C CNN
	1    12950 4250
	0    -1   -1   0   
$EndComp
$Comp
L power:VCC #PWR0142
U 1 1 60B9FB17
P 12350 4250
F 0 "#PWR0142" H 12350 4100 50  0001 C CNN
F 1 "VCC" H 12365 4423 50  0000 C CNN
F 2 "" H 12350 4250 50  0001 C CNN
F 3 "" H 12350 4250 50  0001 C CNN
	1    12350 4250
	0    -1   -1   0   
$EndComp
Wire Wire Line
	13150 4150 12950 4150
Wire Wire Line
	13150 3150 13700 3150
Wire Wire Line
	13700 3150 13700 3000
Wire Wire Line
	13700 3000 14100 3000
Connection ~ 13150 3150
Wire Wire Line
	12950 3350 13450 3350
Wire Wire Line
	13450 3000 13450 3350
Connection ~ 13450 3350
Wire Wire Line
	13450 3350 14100 3350
$Comp
L power:VCC #PWR0143
U 1 1 60ED4E78
P 13300 2600
F 0 "#PWR0143" H 13300 2450 50  0001 C CNN
F 1 "VCC" H 13315 2773 50  0000 C CNN
F 2 "" H 13300 2600 50  0001 C CNN
F 3 "" H 13300 2600 50  0001 C CNN
	1    13300 2600
	1    0    0    -1  
$EndComp
Wire Wire Line
	13150 2700 13150 2600
Wire Wire Line
	13150 2600 13300 2600
Wire Wire Line
	13300 2600 13450 2600
Wire Wire Line
	13450 2600 13450 2700
Connection ~ 13300 2600
$Comp
L power:VCC #PWR0144
U 1 1 610EE0E3
P 13300 3650
F 0 "#PWR0144" H 13300 3500 50  0001 C CNN
F 1 "VCC" H 13315 3823 50  0000 C CNN
F 2 "" H 13300 3650 50  0001 C CNN
F 3 "" H 13300 3650 50  0001 C CNN
	1    13300 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	13150 3750 13150 3650
Wire Wire Line
	13150 3650 13300 3650
Wire Wire Line
	13300 3650 13450 3650
Wire Wire Line
	13450 3650 13450 3750
Connection ~ 13300 3650
Wire Wire Line
	13150 4050 13150 4150
Wire Wire Line
	13450 4350 13450 4050
Wire Wire Line
	12950 4350 13450 4350
Entry Wire Line
	14100 4150 14200 4050
Entry Wire Line
	14100 4350 14200 4250
Wire Wire Line
	13150 4150 14100 4150
Connection ~ 13150 4150
Wire Wire Line
	13450 4350 14100 4350
Connection ~ 13450 4350
Text Label 14100 4150 2    50   ~ 0
PS2_MS_CLK
Text Label 14100 4350 2    50   ~ 0
PS2_MS_DATA
Entry Wire Line
	8750 1500 8850 1600
Entry Wire Line
	8750 1600 8850 1700
Entry Wire Line
	8750 1700 8850 1800
Entry Wire Line
	8750 1800 8850 1900
Entry Wire Line
	8750 1900 8850 2000
Entry Wire Line
	8750 2000 8850 2100
Entry Wire Line
	8750 2100 8850 2200
Entry Wire Line
	8750 2200 8850 2300
Entry Wire Line
	8750 2300 8850 2400
Entry Wire Line
	8750 2400 8850 2500
Entry Wire Line
	8750 2500 8850 2600
Entry Wire Line
	8750 2600 8850 2700
Entry Wire Line
	8750 2700 8850 2800
Entry Wire Line
	8750 2800 8850 2900
Entry Wire Line
	8750 2900 8850 3000
Entry Wire Line
	8750 3000 8850 3100
Entry Wire Line
	8750 3100 8850 3200
Entry Wire Line
	8750 3200 8850 3300
Entry Wire Line
	8750 3300 8850 3400
Entry Wire Line
	8750 3400 8850 3500
Entry Wire Line
	8750 3500 8850 3600
Entry Wire Line
	8750 3600 8850 3700
Entry Wire Line
	8750 3700 8850 3800
Entry Wire Line
	8750 3800 8850 3900
Entry Wire Line
	8750 4000 8850 4100
Wire Wire Line
	9600 3600 8850 3600
Wire Wire Line
	8850 3700 9600 3700
Text Label 8850 3600 0    50   ~ 0
AVR_RX
Text Label 8850 3700 0    50   ~ 0
AVR_TX
Wire Wire Line
	8850 3300 9600 3300
Wire Wire Line
	8850 3400 9600 3400
Text Label 8850 3300 0    50   ~ 0
I2C_SDA
Text Label 8850 3400 0    50   ~ 0
I2C_SCL
Wire Wire Line
	8850 3800 9600 3800
Wire Wire Line
	8850 1600 9600 1600
Text Label 8850 3800 0    50   ~ 0
PS2_KB_CLK
Text Label 8850 1600 0    50   ~ 0
PS2_MS_CLK
Wire Wire Line
	8850 1700 9600 1700
Wire Wire Line
	9600 2000 8850 2000
Text Label 8850 1700 0    50   ~ 0
PS2_KB_DATA
Text Label 8850 2000 0    50   ~ 0
PS2_MS_DATA
$Comp
L Device:Crystal Y2
U 1 1 617844F9
P 10550 4750
F 0 "Y2" H 10550 5018 50  0000 C CNN
F 1 "16MHz" H 10550 4927 50  0000 C CNN
F 2 "Crystal:Crystal_HC49-U_Vertical" H 10550 4750 50  0001 C CNN
F 3 "~" H 10550 4750 50  0001 C CNN
	1    10550 4750
	1    0    0    -1  
$EndComp
$Comp
L Device:C C4
U 1 1 6178F375
P 10300 5050
F 0 "C4" V 10552 5050 50  0000 C CNN
F 1 "22p" V 10461 5050 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 10338 4900 50  0001 C CNN
F 3 "~" H 10300 5050 50  0001 C CNN
	1    10300 5050
	-1   0    0    1   
$EndComp
$Comp
L Device:C C5
U 1 1 6178FDE4
P 10800 5000
F 0 "C5" V 11052 5000 50  0000 C CNN
F 1 "22p" V 10961 5000 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 10838 4850 50  0001 C CNN
F 3 "~" H 10800 5000 50  0001 C CNN
	1    10800 5000
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0145
U 1 1 6187A79B
P 10300 5200
F 0 "#PWR0145" H 10300 4950 50  0001 C CNN
F 1 "GND" H 10305 5027 50  0000 C CNN
F 2 "" H 10300 5200 50  0001 C CNN
F 3 "" H 10300 5200 50  0001 C CNN
	1    10300 5200
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0146
U 1 1 6187BAA4
P 10800 5150
F 0 "#PWR0146" H 10800 4900 50  0001 C CNN
F 1 "GND" H 10805 4977 50  0000 C CNN
F 2 "" H 10800 5150 50  0001 C CNN
F 3 "" H 10800 5150 50  0001 C CNN
	1    10800 5150
	1    0    0    -1  
$EndComp
Entry Wire Line
	10950 4750 11050 4850
Entry Wire Line
	10950 4450 11050 4550
Wire Wire Line
	10950 4750 10800 4750
Wire Wire Line
	10800 4850 10800 4750
Connection ~ 10800 4750
Wire Wire Line
	10800 4750 10700 4750
Wire Wire Line
	10300 4900 10300 4750
Wire Wire Line
	10300 4750 10400 4750
Wire Wire Line
	10300 4750 10300 4450
Wire Wire Line
	10300 4450 10950 4450
Connection ~ 10300 4750
Text Label 10950 4450 2    50   ~ 0
AVR_XT1
Text Label 10950 4750 2    50   ~ 0
AVR_XT2
Wire Wire Line
	8850 1800 9600 1800
Wire Wire Line
	9600 1900 8850 1900
Text Label 8850 1800 0    50   ~ 0
AVR_XT1
Text Label 8850 1900 0    50   ~ 0
AVR_XT2
Wire Wire Line
	9600 2800 8850 2800
Wire Wire Line
	9600 2700 8850 2700
Wire Wire Line
	8850 2600 9600 2600
Wire Wire Line
	9600 2500 8850 2500
Text Label 8850 2800 0    50   ~ 0
AVR_SCK
Text Label 8850 2700 0    50   ~ 0
AVR_MISO
Text Label 8850 2600 0    50   ~ 0
AVR_MOSI
Wire Wire Line
	9600 2200 8850 2200
Text Label 8850 2200 0    50   ~ 0
~AVR_CS
Wire Wire Line
	9600 3500 8850 3500
Text Label 8850 3500 0    50   ~ 0
~AVR_RESET
$Comp
L power:VCC #PWR0147
U 1 1 61DD46AC
P 9600 1150
F 0 "#PWR0147" H 9600 1000 50  0001 C CNN
F 1 "VCC" H 9615 1323 50  0000 C CNN
F 2 "" H 9600 1150 50  0001 C CNN
F 3 "" H 9600 1150 50  0001 C CNN
	1    9600 1150
	1    0    0    -1  
$EndComp
Wire Wire Line
	9550 1400 9600 1400
Wire Wire Line
	10100 1400 10200 1400
Wire Wire Line
	10200 1400 10300 1400
Connection ~ 10100 1400
Connection ~ 10200 1400
Wire Wire Line
	9600 1150 9600 1400
Connection ~ 9600 1400
Wire Wire Line
	9600 1400 10100 1400
Entry Wire Line
	8750 1300 8850 1400
Wire Wire Line
	8850 1400 9250 1400
Text Label 8850 1400 0    50   ~ 0
~AVR_RESET
Wire Wire Line
	8850 2100 9600 2100
Wire Wire Line
	8850 2300 9600 2300
Wire Wire Line
	8850 2400 9600 2400
Wire Wire Line
	8850 2900 9600 2900
Wire Wire Line
	8850 3000 9600 3000
Wire Wire Line
	8850 3100 9600 3100
Wire Wire Line
	8850 3200 9600 3200
Wire Wire Line
	8850 3900 9600 3900
Wire Wire Line
	8850 4100 9600 4100
$Comp
L Device:C C3
U 1 1 62473681
P 9400 4200
F 0 "C3" V 9652 4200 50  0000 C CNN
F 1 "1uF" V 9561 4200 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 9438 4050 50  0001 C CNN
F 3 "~" H 9400 4200 50  0001 C CNN
	1    9400 4200
	-1   0    0    1   
$EndComp
Wire Wire Line
	9600 4000 9400 4000
Wire Wire Line
	9400 4000 9400 4050
$Comp
L power:GND #PWR0148
U 1 1 624EDED6
P 9400 4350
F 0 "#PWR0148" H 9400 4100 50  0001 C CNN
F 1 "GND" H 9405 4177 50  0000 C CNN
F 2 "" H 9400 4350 50  0001 C CNN
F 3 "" H 9400 4350 50  0001 C CNN
	1    9400 4350
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0149
U 1 1 624EEF04
P 9950 4350
F 0 "#PWR0149" H 9950 4100 50  0001 C CNN
F 1 "GND" H 9955 4177 50  0000 C CNN
F 2 "" H 9950 4350 50  0001 C CNN
F 3 "" H 9950 4350 50  0001 C CNN
	1    9950 4350
	1    0    0    -1  
$EndComp
Wire Wire Line
	9950 4350 10100 4350
Wire Wire Line
	10100 4350 10100 4300
Wire Wire Line
	10100 4300 10200 4300
Connection ~ 10100 4300
Wire Wire Line
	10200 4300 10300 4300
Connection ~ 10200 4300
Text Label 8850 3900 0    50   ~ 0
BTN1
Text Label 8850 4100 0    50   ~ 0
BTN2
Text Label 8850 3200 0    50   ~ 0
JOY_FIRE2
Text Label 8850 3100 0    50   ~ 0
LED1
Text Label 8850 3000 0    50   ~ 0
LED2
Text Label 8850 2100 0    50   ~ 0
JOY_UP
Text Label 8850 2300 0    50   ~ 0
JOY_DOWN
Text Label 8850 2400 0    50   ~ 0
JOY_LEFT
Text Label 8850 2500 0    50   ~ 0
JOY_RIGHT
Text Label 8850 2900 0    50   ~ 0
JOY_FIRE1
$Comp
L power:VCC #PWR0150
U 1 1 6267350C
P 9850 4850
F 0 "#PWR0150" H 9850 4700 50  0001 C CNN
F 1 "VCC" H 9865 5023 50  0000 C CNN
F 2 "" H 9850 4850 50  0001 C CNN
F 3 "" H 9850 4850 50  0001 C CNN
	1    9850 4850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0151
U 1 1 62673C74
P 9850 5150
F 0 "#PWR0151" H 9850 4900 50  0001 C CNN
F 1 "GND" H 9855 4977 50  0000 C CNN
F 2 "" H 9850 5150 50  0001 C CNN
F 3 "" H 9850 5150 50  0001 C CNN
	1    9850 5150
	1    0    0    -1  
$EndComp
Entry Wire Line
	8750 4800 8850 4900
Entry Wire Line
	8750 4900 8850 5000
Entry Wire Line
	8750 5000 8850 5100
Entry Wire Line
	8750 5100 8850 5200
Wire Wire Line
	8850 4900 9250 4900
Wire Wire Line
	9250 5000 8850 5000
Wire Wire Line
	8850 5100 9250 5100
Wire Wire Line
	9750 5100 9850 5100
Wire Wire Line
	9850 5100 9850 5150
Wire Wire Line
	9750 4900 9850 4900
Wire Wire Line
	9850 4900 9850 4850
Wire Wire Line
	9750 5000 9800 5000
Wire Wire Line
	9800 5000 9800 5150
Wire Wire Line
	9800 5150 9750 5150
Wire Wire Line
	9750 5150 9750 5200
Wire Wire Line
	9750 5200 8850 5200
Text Label 8850 4900 0    50   ~ 0
AVR_MISO
Text Label 8850 5000 0    50   ~ 0
AVR_SCK
Text Label 8850 5100 0    50   ~ 0
~AVR_RESET
Text Label 8850 5200 0    50   ~ 0
AVR_MOSI
Entry Wire Line
	11050 4750 11150 4850
Entry Wire Line
	11050 4850 11150 4950
Entry Wire Line
	11050 4950 11150 5050
Entry Wire Line
	11050 5150 11150 5250
Entry Wire Line
	11050 5250 11150 5350
Entry Wire Line
	11050 5350 11150 5450
Entry Wire Line
	11050 5450 11150 5550
Wire Wire Line
	11150 4850 12400 4850
Wire Wire Line
	12400 4950 11150 4950
Wire Wire Line
	11150 5050 12400 5050
Wire Wire Line
	12400 5250 11150 5250
Wire Wire Line
	11150 5350 12400 5350
Wire Wire Line
	12400 5450 11150 5450
Wire Wire Line
	11150 5550 12400 5550
Text Label 11150 4850 0    50   ~ 0
JOY_UP
Text Label 11150 4950 0    50   ~ 0
JOY_FIRE1
Text Label 11150 5050 0    50   ~ 0
JOY_DOWN
Text Label 11150 5250 0    50   ~ 0
JOY_LEFT
Text Label 11150 5350 0    50   ~ 0
GND
Text Label 11150 5450 0    50   ~ 0
JOY_RIGHT
Text Label 11150 5550 0    50   ~ 0
JOY_FIRE2
NoConn ~ 12400 5150
NoConn ~ 12400 5650
Entry Wire Line
	11050 8500 11150 8600
Entry Wire Line
	11050 8950 11150 9050
Wire Wire Line
	11150 8600 11950 8600
Wire Wire Line
	11950 9050 11150 9050
$Comp
L power:GND #PWR0152
U 1 1 6304EEEE
P 12500 9150
F 0 "#PWR0152" H 12500 8900 50  0001 C CNN
F 1 "GND" H 12505 8977 50  0000 C CNN
F 2 "" H 12500 9150 50  0001 C CNN
F 3 "" H 12500 9150 50  0001 C CNN
	1    12500 9150
	1    0    0    -1  
$EndComp
Wire Wire Line
	12350 8600 12500 8600
Wire Wire Line
	12500 8600 12500 9050
Wire Wire Line
	12350 9050 12500 9050
Connection ~ 12500 9050
Wire Wire Line
	12500 9050 12500 9150
Text Label 11150 8600 0    50   ~ 0
BTN1
Text Label 11150 9050 0    50   ~ 0
BTN2
Text Label 14300 6600 0    50   ~ 0
VCC3_3
Text Label 14300 6700 0    50   ~ 0
TDI
Text Label 14300 7400 0    50   ~ 0
GND
Text Label 14300 7800 0    50   ~ 0
TMS
Text Label 14300 8100 0    50   ~ 0
VCC3_3
Text Label 16100 10100 1    50   ~ 0
GND
Text Label 16800 10100 1    50   ~ 0
GND
Text Label 16900 10100 1    50   ~ 0
VCC3_3
Text Label 17300 10100 1    50   ~ 0
GND
Text Label 17400 10100 1    50   ~ 0
VCC3_3
Text Label 17800 10100 1    50   ~ 0
GND
Text Label 20250 8800 2    50   ~ 0
VCC3_3
Text Label 20250 8600 2    50   ~ 0
GND
Text Label 20250 8000 2    50   ~ 0
GND
Text Label 20250 7700 2    50   ~ 0
TCK
Text Label 20250 7400 2    50   ~ 0
GND
Text Label 20250 7300 2    50   ~ 0
VCC3_3
Text Label 20250 6600 2    50   ~ 0
TDI1
Text Label 20250 6500 2    50   ~ 0
GND
Text Label 17900 5050 3    50   ~ 0
VCC3_3
Text Label 18300 5050 3    50   ~ 0
GND
Text Label 17500 5050 3    50   ~ 0
GND
Text Label 17000 5050 3    50   ~ 0
VCC3_3
Text Label 16600 5050 3    50   ~ 0
GND
$Comp
L Device:LED D1
U 1 1 63476C53
P 15450 1050
F 0 "D1" H 15443 1267 50  0000 C CNN
F 1 "LED1" H 15443 1176 50  0000 C CNN
F 2 "LED_SMD:LED_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15450 1050 50  0001 C CNN
F 3 "~" H 15450 1050 50  0001 C CNN
	1    15450 1050
	-1   0    0    -1  
$EndComp
$Comp
L Device:R R28
U 1 1 635034EF
P 15150 1050
F 0 "R28" V 15357 1050 50  0000 C CNN
F 1 "470" V 15266 1050 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 15080 1050 50  0001 C CNN
F 3 "~" H 15150 1050 50  0001 C CNN
	1    15150 1050
	0    -1   -1   0   
$EndComp
Entry Wire Line
	14200 950  14300 1050
Wire Wire Line
	14300 1050 15000 1050
$Comp
L Device:LED D2
U 1 1 6358E103
P 15450 1400
F 0 "D2" H 15443 1617 50  0000 C CNN
F 1 "LED2" H 15443 1526 50  0000 C CNN
F 2 "LED_SMD:LED_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15450 1400 50  0001 C CNN
F 3 "~" H 15450 1400 50  0001 C CNN
	1    15450 1400
	-1   0    0    -1  
$EndComp
$Comp
L Device:R R29
U 1 1 6358E10D
P 15150 1400
F 0 "R29" V 15357 1400 50  0000 C CNN
F 1 "470" V 15266 1400 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 15080 1400 50  0001 C CNN
F 3 "~" H 15150 1400 50  0001 C CNN
	1    15150 1400
	0    -1   -1   0   
$EndComp
Entry Wire Line
	14200 1300 14300 1400
Wire Wire Line
	14300 1400 15000 1400
Text Label 14300 1050 0    50   ~ 0
LED1
Text Label 14300 1400 0    50   ~ 0
LED2
$Comp
L power:GND #PWR0153
U 1 1 63619442
P 15750 1500
F 0 "#PWR0153" H 15750 1250 50  0001 C CNN
F 1 "GND" H 15755 1327 50  0000 C CNN
F 2 "" H 15750 1500 50  0001 C CNN
F 3 "" H 15750 1500 50  0001 C CNN
	1    15750 1500
	1    0    0    -1  
$EndComp
Wire Wire Line
	15600 1050 15750 1050
Wire Wire Line
	15750 1050 15750 1400
Wire Wire Line
	15600 1400 15750 1400
Connection ~ 15750 1400
Wire Wire Line
	15750 1400 15750 1500
$Comp
L power:GND #PWR0154
U 1 1 63739963
P 9000 7800
F 0 "#PWR0154" H 9000 7550 50  0001 C CNN
F 1 "GND" H 9005 7627 50  0000 C CNN
F 2 "" H 9000 7800 50  0001 C CNN
F 3 "" H 9000 7800 50  0001 C CNN
	1    9000 7800
	1    0    0    -1  
$EndComp
NoConn ~ 13700 6400
NoConn ~ 13700 6500
$Comp
L power:GND #PWR0155
U 1 1 6390E3D1
P 13800 6850
F 0 "#PWR0155" H 13800 6600 50  0001 C CNN
F 1 "GND" H 13805 6677 50  0000 C CNN
F 2 "" H 13800 6850 50  0001 C CNN
F 3 "" H 13800 6850 50  0001 C CNN
	1    13800 6850
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0156
U 1 1 6390EBE9
P 12550 5850
F 0 "#PWR0156" H 12550 5600 50  0001 C CNN
F 1 "GND" H 12555 5677 50  0000 C CNN
F 2 "" H 12550 5850 50  0001 C CNN
F 3 "" H 12550 5850 50  0001 C CNN
	1    12550 5850
	1    0    0    -1  
$EndComp
Wire Wire Line
	12550 5850 12700 5850
Wire Wire Line
	13700 6700 13800 6700
Wire Wire Line
	13800 6700 13800 6800
Wire Wire Line
	13700 6800 13800 6800
Connection ~ 13800 6800
Wire Wire Line
	13800 6800 13800 6850
$Comp
L power:GND #PWR0157
U 1 1 63ABEDCC
P 12650 3450
F 0 "#PWR0157" H 12650 3200 50  0001 C CNN
F 1 "GND" H 12655 3277 50  0000 C CNN
F 2 "" H 12650 3450 50  0001 C CNN
F 3 "" H 12650 3450 50  0001 C CNN
	1    12650 3450
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0158
U 1 1 63ABF299
P 12650 4450
F 0 "#PWR0158" H 12650 4200 50  0001 C CNN
F 1 "GND" H 12655 4277 50  0000 C CNN
F 2 "" H 12650 4450 50  0001 C CNN
F 3 "" H 12650 4450 50  0001 C CNN
	1    12650 4450
	1    0    0    -1  
$EndComp
NoConn ~ 12350 4150
NoConn ~ 12350 4350
$Comp
L power:GND #PWR0159
U 1 1 63C0720B
P 12500 11700
F 0 "#PWR0159" H 12500 11450 50  0001 C CNN
F 1 "GND" H 12505 11527 50  0000 C CNN
F 2 "" H 12500 11700 50  0001 C CNN
F 3 "" H 12500 11700 50  0001 C CNN
	1    12500 11700
	1    0    0    -1  
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0160
U 1 1 63C0EB63
P 12050 10050
F 0 "#PWR0160" H 12050 9900 50  0001 C CNN
F 1 "VCC3_3" H 12000 10200 50  0000 C CNN
F 2 "" H 12050 10050 50  0001 C CNN
F 3 "" H 12050 10050 50  0001 C CNN
	1    12050 10050
	1    0    0    -1  
$EndComp
Wire Wire Line
	12050 10200 12500 10200
$Comp
L Device:R R31
U 1 1 63CA6B25
P 11750 10250
F 0 "R31" V 11957 10250 50  0000 C CNN
F 1 "10k" V 11866 10250 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11680 10250 50  0001 C CNN
F 3 "~" H 11750 10250 50  0001 C CNN
	1    11750 10250
	-1   0    0    1   
$EndComp
Wire Wire Line
	11900 10400 11750 10400
Wire Wire Line
	12050 10100 12050 10050
Wire Wire Line
	11750 10100 12050 10100
Wire Wire Line
	12050 10200 12050 10100
Connection ~ 12050 10100
$Comp
L Device:R R30
U 1 1 63FF90BE
P 11400 10250
F 0 "R30" V 11607 10250 50  0000 C CNN
F 1 "10k" V 11516 10250 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11330 10250 50  0001 C CNN
F 3 "~" H 11400 10250 50  0001 C CNN
	1    11400 10250
	-1   0    0    1   
$EndComp
Wire Wire Line
	11900 10600 11400 10600
Wire Wire Line
	11400 10600 11400 10400
Wire Wire Line
	11400 10100 11750 10100
Connection ~ 11750 10100
$Comp
L Device:R R32
U 1 1 641A4FFC
P 13300 11650
F 0 "R32" V 13507 11650 50  0000 C CNN
F 1 "10k" V 13416 11650 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 13230 11650 50  0001 C CNN
F 3 "~" H 13300 11650 50  0001 C CNN
	1    13300 11650
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0161
U 1 1 641A5969
P 13300 11800
F 0 "#PWR0161" H 13300 11550 50  0001 C CNN
F 1 "GND" H 13305 11627 50  0000 C CNN
F 2 "" H 13300 11800 50  0001 C CNN
F 3 "" H 13300 11800 50  0001 C CNN
	1    13300 11800
	1    0    0    -1  
$EndComp
Wire Wire Line
	13100 11300 13300 11300
Wire Wire Line
	13300 11300 13300 11500
NoConn ~ 11900 10800
NoConn ~ 11900 11000
NoConn ~ 11900 11100
NoConn ~ 11900 11200
NoConn ~ 11900 11300
NoConn ~ 11900 11400
NoConn ~ 11900 11500
NoConn ~ 13100 11400
NoConn ~ 13100 11200
NoConn ~ 13100 10800
NoConn ~ 13100 10900
NoConn ~ 13100 11000
NoConn ~ 13100 10400
NoConn ~ 13100 10600
Connection ~ 14200 10200
Entry Wire Line
	14100 11100 14200 11000
Entry Wire Line
	14100 10700 14200 10600
Entry Wire Line
	14100 10500 14200 10400
Wire Wire Line
	13100 10500 14100 10500
Wire Wire Line
	14100 10700 13100 10700
Wire Wire Line
	13100 11100 14100 11100
Text Label 14100 10500 2    50   ~ 0
UART_RX
Text Label 14100 10700 2    50   ~ 0
UART_TX
Text Label 14100 11100 2    50   ~ 0
UART_CTS
$Comp
L vcc33:VCC3_3 #PWR0162
U 1 1 64FCE43B
P 11700 5800
F 0 "#PWR0162" H 11700 5650 50  0001 C CNN
F 1 "VCC3_3" H 11650 5950 50  0000 C CNN
F 2 "" H 11700 5800 50  0001 C CNN
F 3 "" H 11700 5800 50  0001 C CNN
	1    11700 5800
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0163
U 1 1 64FD3918
P 11800 7050
F 0 "#PWR0163" H 11800 6800 50  0001 C CNN
F 1 "GND" H 11805 6877 50  0000 C CNN
F 2 "" H 11800 7050 50  0001 C CNN
F 3 "" H 11800 7050 50  0001 C CNN
	1    11800 7050
	1    0    0    -1  
$EndComp
Wire Wire Line
	11900 6600 11700 6600
Wire Wire Line
	11700 6600 11700 5900
Wire Wire Line
	11900 6500 11800 6500
Wire Wire Line
	11800 6500 11800 6800
Wire Wire Line
	11800 6800 11900 6800
Wire Wire Line
	11800 6800 11800 7050
Connection ~ 11800 6800
NoConn ~ 11900 6200
$Comp
L Device:R R33
U 1 1 65383D7A
P 5550 9250
F 0 "R33" V 5757 9250 50  0000 C CNN
F 1 "10k" V 5666 9250 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 9250 50  0001 C CNN
F 3 "~" H 5550 9250 50  0001 C CNN
	1    5550 9250
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R34
U 1 1 653883A0
P 5550 9550
F 0 "R34" V 5757 9550 50  0000 C CNN
F 1 "10k" V 5666 9550 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 9550 50  0001 C CNN
F 3 "~" H 5550 9550 50  0001 C CNN
	1    5550 9550
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R35
U 1 1 65388BA2
P 5550 9850
F 0 "R35" V 5757 9850 50  0000 C CNN
F 1 "10k" V 5666 9850 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 9850 50  0001 C CNN
F 3 "~" H 5550 9850 50  0001 C CNN
	1    5550 9850
	0    -1   -1   0   
$EndComp
Entry Wire Line
	4850 9150 4950 9250
Entry Wire Line
	4850 9450 4950 9550
Entry Wire Line
	4850 9750 4950 9850
Wire Wire Line
	4950 9250 5400 9250
Wire Wire Line
	4950 9550 5400 9550
Wire Wire Line
	4950 9850 5400 9850
Text Label 4950 9250 0    50   ~ 0
CONF_DONE
Text Label 4950 9550 0    50   ~ 0
NCONFIG
Text Label 4950 9850 0    50   ~ 0
NSTATUS
$Comp
L vcc33:VCC3_3 #PWR0164
U 1 1 655503DC
P 5900 9150
F 0 "#PWR0164" H 5900 9000 50  0001 C CNN
F 1 "VCC3_3" H 5850 9300 50  0000 C CNN
F 2 "" H 5900 9150 50  0001 C CNN
F 3 "" H 5900 9150 50  0001 C CNN
	1    5900 9150
	1    0    0    -1  
$EndComp
Wire Wire Line
	5900 9850 5700 9850
Wire Wire Line
	5700 9550 5900 9550
Connection ~ 5900 9550
Wire Wire Line
	5900 9550 5900 9850
Wire Wire Line
	5700 9250 5900 9250
Connection ~ 5900 9250
Wire Wire Line
	5900 9250 5900 9550
Wire Wire Line
	5900 9150 5900 9250
$Comp
L Device:R R37
U 1 1 6585618A
P 11550 7000
F 0 "R37" V 11757 7000 50  0000 C CNN
F 1 "10k" V 11666 7000 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11480 7000 50  0001 C CNN
F 3 "~" H 11550 7000 50  0001 C CNN
	1    11550 7000
	0    -1   -1   0   
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0165
U 1 1 6585FAE5
P 11400 7000
F 0 "#PWR0165" H 11400 6850 50  0001 C CNN
F 1 "VCC3_3" H 11350 7150 50  0000 C CNN
F 2 "" H 11400 7000 50  0001 C CNN
F 3 "" H 11400 7000 50  0001 C CNN
	1    11400 7000
	0    -1   -1   0   
$EndComp
Wire Wire Line
	11700 7000 11900 7000
$Comp
L Device:R R36
U 1 1 6598F43A
P 11550 6050
F 0 "R36" V 11757 6050 50  0000 C CNN
F 1 "10k" V 11666 6050 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 11480 6050 50  0001 C CNN
F 3 "~" H 11550 6050 50  0001 C CNN
	1    11550 6050
	-1   0    0    1   
$EndComp
Wire Wire Line
	11550 6200 11550 6300
Connection ~ 11550 6300
Wire Wire Line
	11550 6300 11900 6300
Wire Wire Line
	11550 5900 11700 5900
Connection ~ 11700 5900
Wire Wire Line
	11700 5900 11700 5800
$Comp
L Device:CP C6
U 1 1 65D41610
P 14850 10900
F 0 "C6" H 14968 10946 50  0000 L CNN
F 1 "10uF" H 14968 10855 50  0000 L CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-7343-31_Kemet-D" H 14888 10750 50  0001 C CNN
F 3 "~" H 14850 10900 50  0001 C CNN
	1    14850 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C7
U 1 1 65D41FC8
P 14850 11700
F 0 "C7" H 14968 11746 50  0000 L CNN
F 1 "10uF" H 14968 11655 50  0000 L CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-7343-31_Kemet-D" H 14888 11550 50  0001 C CNN
F 3 "~" H 14850 11700 50  0001 C CNN
	1    14850 11700
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C8
U 1 1 65D4246F
P 14850 12500
F 0 "C8" H 14968 12546 50  0000 L CNN
F 1 "10uF" H 14968 12455 50  0000 L CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-7343-31_Kemet-D" H 14888 12350 50  0001 C CNN
F 3 "~" H 14850 12500 50  0001 C CNN
	1    14850 12500
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C9
U 1 1 65D42814
P 14850 13250
F 0 "C9" H 14968 13296 50  0000 L CNN
F 1 "10uF" H 14968 13205 50  0000 L CNN
F 2 "Capacitor_Tantalum_SMD:CP_EIA-7343-31_Kemet-D" H 14888 13100 50  0001 C CNN
F 3 "~" H 14850 13250 50  0001 C CNN
	1    14850 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C10
U 1 1 65D4CDBB
P 15350 10900
F 0 "C10" V 15602 10900 50  0000 C CNN
F 1 "100n" V 15511 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15388 10750 50  0001 C CNN
F 3 "~" H 15350 10900 50  0001 C CNN
	1    15350 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C14
U 1 1 65E87A65
P 15750 10900
F 0 "C14" V 16002 10900 50  0000 C CNN
F 1 "100n" V 15911 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15788 10750 50  0001 C CNN
F 3 "~" H 15750 10900 50  0001 C CNN
	1    15750 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C18
U 1 1 65E87D32
P 16150 10900
F 0 "C18" V 16402 10900 50  0000 C CNN
F 1 "100n" V 16311 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16188 10750 50  0001 C CNN
F 3 "~" H 16150 10900 50  0001 C CNN
	1    16150 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C22
U 1 1 65E9C487
P 16550 10900
F 0 "C22" V 16802 10900 50  0000 C CNN
F 1 "100n" V 16711 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16588 10750 50  0001 C CNN
F 3 "~" H 16550 10900 50  0001 C CNN
	1    16550 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C25
U 1 1 65E9D577
P 16950 10900
F 0 "C25" V 17202 10900 50  0000 C CNN
F 1 "100n" V 17111 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16988 10750 50  0001 C CNN
F 3 "~" H 16950 10900 50  0001 C CNN
	1    16950 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C29
U 1 1 65E9E564
P 17400 10900
F 0 "C29" V 17652 10900 50  0000 C CNN
F 1 "100n" V 17561 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 17438 10750 50  0001 C CNN
F 3 "~" H 17400 10900 50  0001 C CNN
	1    17400 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C31
U 1 1 65E9F58D
P 17850 10900
F 0 "C31" V 18102 10900 50  0000 C CNN
F 1 "100n" V 18011 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 17888 10750 50  0001 C CNN
F 3 "~" H 17850 10900 50  0001 C CNN
	1    17850 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C33
U 1 1 65EA0554
P 18300 10900
F 0 "C33" V 18552 10900 50  0000 C CNN
F 1 "100n" V 18461 10900 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 18338 10750 50  0001 C CNN
F 3 "~" H 18300 10900 50  0001 C CNN
	1    18300 10900
	1    0    0    -1  
$EndComp
$Comp
L Device:C C11
U 1 1 65EB14DD
P 15350 11700
F 0 "C11" V 15602 11700 50  0000 C CNN
F 1 "100n" V 15511 11700 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15388 11550 50  0001 C CNN
F 3 "~" H 15350 11700 50  0001 C CNN
	1    15350 11700
	1    0    0    -1  
$EndComp
$Comp
L Device:C C15
U 1 1 65EB39C7
P 15750 11700
F 0 "C15" V 16002 11700 50  0000 C CNN
F 1 "100n" V 15911 11700 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15788 11550 50  0001 C CNN
F 3 "~" H 15750 11700 50  0001 C CNN
	1    15750 11700
	1    0    0    -1  
$EndComp
$Comp
L Device:C C19
U 1 1 65EB4315
P 16150 11700
F 0 "C19" V 16402 11700 50  0000 C CNN
F 1 "100n" V 16311 11700 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16188 11550 50  0001 C CNN
F 3 "~" H 16150 11700 50  0001 C CNN
	1    16150 11700
	1    0    0    -1  
$EndComp
$Comp
L Device:C C23
U 1 1 65EB47A2
P 16550 11700
F 0 "C23" V 16802 11700 50  0000 C CNN
F 1 "100n" V 16711 11700 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16588 11550 50  0001 C CNN
F 3 "~" H 16550 11700 50  0001 C CNN
	1    16550 11700
	1    0    0    -1  
$EndComp
$Comp
L Device:C C26
U 1 1 65EB4B3C
P 16950 11700
F 0 "C26" V 17202 11700 50  0000 C CNN
F 1 "100n" V 17111 11700 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16988 11550 50  0001 C CNN
F 3 "~" H 16950 11700 50  0001 C CNN
	1    16950 11700
	1    0    0    -1  
$EndComp
$Comp
L Device:C C12
U 1 1 65EB5563
P 15350 12500
F 0 "C12" V 15602 12500 50  0000 C CNN
F 1 "100n" V 15511 12500 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15388 12350 50  0001 C CNN
F 3 "~" H 15350 12500 50  0001 C CNN
	1    15350 12500
	1    0    0    -1  
$EndComp
$Comp
L Device:C C16
U 1 1 65EB5955
P 15750 12500
F 0 "C16" V 16002 12500 50  0000 C CNN
F 1 "100n" V 15911 12500 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15788 12350 50  0001 C CNN
F 3 "~" H 15750 12500 50  0001 C CNN
	1    15750 12500
	1    0    0    -1  
$EndComp
$Comp
L Device:C C20
U 1 1 65EB5D94
P 16150 12500
F 0 "C20" V 16402 12500 50  0000 C CNN
F 1 "100n" V 16311 12500 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16188 12350 50  0001 C CNN
F 3 "~" H 16150 12500 50  0001 C CNN
	1    16150 12500
	1    0    0    -1  
$EndComp
$Comp
L Device:C C13
U 1 1 65EB6854
P 15350 13250
F 0 "C13" V 15602 13250 50  0000 C CNN
F 1 "100n" V 15511 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15388 13100 50  0001 C CNN
F 3 "~" H 15350 13250 50  0001 C CNN
	1    15350 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C17
U 1 1 65EB6C26
P 15750 13250
F 0 "C17" V 16002 13250 50  0000 C CNN
F 1 "100n" V 15911 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 15788 13100 50  0001 C CNN
F 3 "~" H 15750 13250 50  0001 C CNN
	1    15750 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C21
U 1 1 65EB704B
P 16150 13250
F 0 "C21" V 16402 13250 50  0000 C CNN
F 1 "100n" V 16311 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16188 13100 50  0001 C CNN
F 3 "~" H 16150 13250 50  0001 C CNN
	1    16150 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C24
U 1 1 65EB73A3
P 16550 13250
F 0 "C24" V 16802 13250 50  0000 C CNN
F 1 "100n" V 16711 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16588 13100 50  0001 C CNN
F 3 "~" H 16550 13250 50  0001 C CNN
	1    16550 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C27
U 1 1 65EB7902
P 16950 13250
F 0 "C27" V 17202 13250 50  0000 C CNN
F 1 "100n" V 17111 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 16988 13100 50  0001 C CNN
F 3 "~" H 16950 13250 50  0001 C CNN
	1    16950 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C28
U 1 1 65EB7D26
P 17350 13250
F 0 "C28" V 17602 13250 50  0000 C CNN
F 1 "100n" V 17511 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 17388 13100 50  0001 C CNN
F 3 "~" H 17350 13250 50  0001 C CNN
	1    17350 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C30
U 1 1 65EB8103
P 17750 13250
F 0 "C30" V 18002 13250 50  0000 C CNN
F 1 "100n" V 17911 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 17788 13100 50  0001 C CNN
F 3 "~" H 17750 13250 50  0001 C CNN
	1    17750 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C32
U 1 1 65EB84C1
P 18150 13250
F 0 "C32" V 18402 13250 50  0000 C CNN
F 1 "100n" V 18311 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 18188 13100 50  0001 C CNN
F 3 "~" H 18150 13250 50  0001 C CNN
	1    18150 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C34
U 1 1 65EDD6D7
P 18550 13250
F 0 "C34" V 18802 13250 50  0000 C CNN
F 1 "100n" V 18711 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 18588 13100 50  0001 C CNN
F 3 "~" H 18550 13250 50  0001 C CNN
	1    18550 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C35
U 1 1 65EDDBCA
P 18950 13250
F 0 "C35" V 19202 13250 50  0000 C CNN
F 1 "100n" V 19111 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 18988 13100 50  0001 C CNN
F 3 "~" H 18950 13250 50  0001 C CNN
	1    18950 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C36
U 1 1 65EDDF3D
P 19350 13250
F 0 "C36" V 19602 13250 50  0000 C CNN
F 1 "100n" V 19511 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 19388 13100 50  0001 C CNN
F 3 "~" H 19350 13250 50  0001 C CNN
	1    19350 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C37
U 1 1 65EDE3F8
P 19750 13250
F 0 "C37" V 20002 13250 50  0000 C CNN
F 1 "100n" V 19911 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 19788 13100 50  0001 C CNN
F 3 "~" H 19750 13250 50  0001 C CNN
	1    19750 13250
	1    0    0    -1  
$EndComp
$Comp
L power:VCC #PWR0166
U 1 1 65EE900F
P 14850 10750
F 0 "#PWR0166" H 14850 10600 50  0001 C CNN
F 1 "VCC" H 14865 10923 50  0000 C CNN
F 2 "" H 14850 10750 50  0001 C CNN
F 3 "" H 14850 10750 50  0001 C CNN
	1    14850 10750
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0167
U 1 1 65EF5C2F
P 14850 11050
F 0 "#PWR0167" H 14850 10800 50  0001 C CNN
F 1 "GND" H 14855 10877 50  0000 C CNN
F 2 "" H 14850 11050 50  0001 C CNN
F 3 "" H 14850 11050 50  0001 C CNN
	1    14850 11050
	1    0    0    -1  
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0168
U 1 1 65EF9DA3
P 14850 13100
F 0 "#PWR0168" H 14850 12950 50  0001 C CNN
F 1 "VCC3_3" H 14800 13250 50  0000 C CNN
F 2 "" H 14850 13100 50  0001 C CNN
F 3 "" H 14850 13100 50  0001 C CNN
	1    14850 13100
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0169
U 1 1 65EFC459
P 14850 12650
F 0 "#PWR0169" H 14850 12400 50  0001 C CNN
F 1 "GND" H 14855 12477 50  0000 C CNN
F 2 "" H 14850 12650 50  0001 C CNN
F 3 "" H 14850 12650 50  0001 C CNN
	1    14850 12650
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0170
U 1 1 65EFC82F
P 14850 11850
F 0 "#PWR0170" H 14850 11600 50  0001 C CNN
F 1 "GND" H 14855 11677 50  0000 C CNN
F 2 "" H 14850 11850 50  0001 C CNN
F 3 "" H 14850 11850 50  0001 C CNN
	1    14850 11850
	1    0    0    -1  
$EndComp
$Comp
L vcc25:VCC2_5 #PWR0171
U 1 1 65FAE817
P 14850 11550
F 0 "#PWR0171" H 14850 11400 50  0001 C CNN
F 1 "VCC2_5" H 14867 11723 50  0000 C CNN
F 2 "" H 14850 11550 50  0001 C CNN
F 3 "" H 14850 11550 50  0001 C CNN
	1    14850 11550
	1    0    0    -1  
$EndComp
$Comp
L vcc12:VCC1_2 #PWR0172
U 1 1 660FD499
P 14850 12350
F 0 "#PWR0172" H 14850 12200 50  0001 C CNN
F 1 "VCC1_2" H 14867 12523 50  0000 C CNN
F 2 "" H 14850 12350 50  0001 C CNN
F 3 "" H 14850 12350 50  0001 C CNN
	1    14850 12350
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0173
U 1 1 6624598B
P 14850 13400
F 0 "#PWR0173" H 14850 13150 50  0001 C CNN
F 1 "GND" H 14855 13227 50  0000 C CNN
F 2 "" H 14850 13400 50  0001 C CNN
F 3 "" H 14850 13400 50  0001 C CNN
	1    14850 13400
	1    0    0    -1  
$EndComp
Wire Wire Line
	14850 10750 15350 10750
Connection ~ 14850 10750
Wire Wire Line
	15350 10750 15750 10750
Connection ~ 15350 10750
Wire Wire Line
	15750 10750 16150 10750
Connection ~ 15750 10750
Wire Wire Line
	16150 10750 16550 10750
Connection ~ 16150 10750
Wire Wire Line
	16550 10750 16950 10750
Connection ~ 16550 10750
Wire Wire Line
	16950 10750 17400 10750
Connection ~ 16950 10750
Connection ~ 17400 10750
Wire Wire Line
	17400 10750 17850 10750
Wire Wire Line
	17850 10750 18300 10750
Connection ~ 17850 10750
Wire Wire Line
	18300 11050 17850 11050
Connection ~ 14850 11050
Connection ~ 15350 11050
Wire Wire Line
	15350 11050 14850 11050
Connection ~ 15750 11050
Wire Wire Line
	15750 11050 15350 11050
Connection ~ 16150 11050
Wire Wire Line
	16150 11050 15750 11050
Connection ~ 16550 11050
Wire Wire Line
	16550 11050 16150 11050
Connection ~ 16950 11050
Wire Wire Line
	16950 11050 16550 11050
Connection ~ 17400 11050
Wire Wire Line
	17400 11050 16950 11050
Connection ~ 17850 11050
Wire Wire Line
	17850 11050 17400 11050
Wire Wire Line
	14850 11550 15350 11550
Connection ~ 14850 11550
Connection ~ 15350 11550
Wire Wire Line
	15350 11550 15750 11550
Connection ~ 15750 11550
Wire Wire Line
	15750 11550 16150 11550
Connection ~ 16150 11550
Wire Wire Line
	16150 11550 16550 11550
Connection ~ 16550 11550
Wire Wire Line
	16550 11550 16950 11550
Wire Wire Line
	16950 11850 16550 11850
Connection ~ 14850 11850
Connection ~ 15350 11850
Wire Wire Line
	15350 11850 14850 11850
Connection ~ 15750 11850
Wire Wire Line
	15750 11850 15350 11850
Connection ~ 16150 11850
Wire Wire Line
	16150 11850 15750 11850
Connection ~ 16550 11850
Wire Wire Line
	16550 11850 16150 11850
Wire Wire Line
	14850 12350 15350 12350
Connection ~ 14850 12350
Connection ~ 15350 12350
Wire Wire Line
	15350 12350 15750 12350
Connection ~ 15750 12350
Wire Wire Line
	15750 12350 16150 12350
Wire Wire Line
	16150 12650 15750 12650
Connection ~ 14850 12650
Connection ~ 15350 12650
Wire Wire Line
	15350 12650 14850 12650
Connection ~ 15750 12650
Wire Wire Line
	15750 12650 15350 12650
Wire Wire Line
	14850 13100 15350 13100
Connection ~ 14850 13100
Connection ~ 15350 13100
Wire Wire Line
	15350 13100 15750 13100
Connection ~ 15750 13100
Wire Wire Line
	15750 13100 16150 13100
Connection ~ 16150 13100
Wire Wire Line
	16150 13100 16550 13100
Connection ~ 16550 13100
Wire Wire Line
	16550 13100 16950 13100
Connection ~ 16950 13100
Wire Wire Line
	16950 13100 17350 13100
Connection ~ 17350 13100
Wire Wire Line
	17350 13100 17750 13100
Connection ~ 17750 13100
Wire Wire Line
	17750 13100 18150 13100
Connection ~ 18150 13100
Wire Wire Line
	18150 13100 18550 13100
Connection ~ 18550 13100
Wire Wire Line
	18550 13100 18950 13100
Connection ~ 18950 13100
Wire Wire Line
	18950 13100 19350 13100
Connection ~ 19350 13100
Wire Wire Line
	19350 13100 19750 13100
Connection ~ 14850 13400
Connection ~ 15350 13400
Wire Wire Line
	15350 13400 14850 13400
Connection ~ 15750 13400
Wire Wire Line
	15750 13400 15350 13400
Connection ~ 16150 13400
Wire Wire Line
	16150 13400 15750 13400
Connection ~ 16550 13400
Wire Wire Line
	16550 13400 16150 13400
Connection ~ 16950 13400
Wire Wire Line
	16950 13400 16550 13400
Connection ~ 17350 13400
Wire Wire Line
	17350 13400 16950 13400
Connection ~ 17750 13400
Wire Wire Line
	17750 13400 17350 13400
Connection ~ 18150 13400
Wire Wire Line
	18150 13400 17750 13400
Connection ~ 18550 13400
Wire Wire Line
	18550 13400 18150 13400
Connection ~ 18950 13400
Wire Wire Line
	18950 13400 18550 13400
Connection ~ 19350 13400
Wire Wire Line
	19350 13400 18950 13400
$Comp
L power:GND #PWR0174
U 1 1 66B84A73
P 5750 5700
F 0 "#PWR0174" H 5750 5450 50  0001 C CNN
F 1 "GND" H 5755 5527 50  0000 C CNN
F 2 "" H 5750 5700 50  0001 C CNN
F 3 "" H 5750 5700 50  0001 C CNN
	1    5750 5700
	1    0    0    -1  
$EndComp
Wire Wire Line
	19350 13400 19750 13400
$Comp
L Device:C C38
U 1 1 66C51121
P 20150 13250
F 0 "C38" V 20402 13250 50  0000 C CNN
F 1 "100n" V 20311 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 20188 13100 50  0001 C CNN
F 3 "~" H 20150 13250 50  0001 C CNN
	1    20150 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C39
U 1 1 66C51522
P 20550 13250
F 0 "C39" V 20802 13250 50  0000 C CNN
F 1 "100n" V 20711 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 20588 13100 50  0001 C CNN
F 3 "~" H 20550 13250 50  0001 C CNN
	1    20550 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C40
U 1 1 66C518B3
P 20950 13250
F 0 "C40" V 21202 13250 50  0000 C CNN
F 1 "100n" V 21111 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 20988 13100 50  0001 C CNN
F 3 "~" H 20950 13250 50  0001 C CNN
	1    20950 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C41
U 1 1 66C51B93
P 21350 13250
F 0 "C41" V 21602 13250 50  0000 C CNN
F 1 "100n" V 21511 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 21388 13100 50  0001 C CNN
F 3 "~" H 21350 13250 50  0001 C CNN
	1    21350 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C42
U 1 1 66C51EA7
P 21750 13250
F 0 "C42" V 22002 13250 50  0000 C CNN
F 1 "100n" V 21911 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 21788 13100 50  0001 C CNN
F 3 "~" H 21750 13250 50  0001 C CNN
	1    21750 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C43
U 1 1 66C5220E
P 22150 13250
F 0 "C43" V 22402 13250 50  0000 C CNN
F 1 "100n" V 22311 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 22188 13100 50  0001 C CNN
F 3 "~" H 22150 13250 50  0001 C CNN
	1    22150 13250
	1    0    0    -1  
$EndComp
$Comp
L Device:C C44
U 1 1 66C524DB
P 22550 13250
F 0 "C44" V 22802 13250 50  0000 C CNN
F 1 "100n" V 22711 13250 50  0000 C CNN
F 2 "Capacitor_SMD:C_0805_2012Metric_Pad1.15x1.40mm_HandSolder" H 22588 13100 50  0001 C CNN
F 3 "~" H 22550 13250 50  0001 C CNN
	1    22550 13250
	1    0    0    -1  
$EndComp
Wire Wire Line
	22550 13100 22150 13100
Connection ~ 19750 13100
Connection ~ 20150 13100
Wire Wire Line
	20150 13100 19750 13100
Connection ~ 20550 13100
Wire Wire Line
	20550 13100 20150 13100
Connection ~ 20950 13100
Wire Wire Line
	20950 13100 20550 13100
Connection ~ 21350 13100
Wire Wire Line
	21350 13100 20950 13100
Connection ~ 21750 13100
Wire Wire Line
	21750 13100 21350 13100
Connection ~ 22150 13100
Wire Wire Line
	22150 13100 21750 13100
Wire Wire Line
	22550 13400 22150 13400
Connection ~ 19750 13400
Connection ~ 20150 13400
Wire Wire Line
	20150 13400 19750 13400
Connection ~ 20550 13400
Wire Wire Line
	20550 13400 20150 13400
Connection ~ 20950 13400
Wire Wire Line
	20950 13400 20550 13400
Connection ~ 21350 13400
Wire Wire Line
	21350 13400 20950 13400
Connection ~ 21750 13400
Wire Wire Line
	21750 13400 21350 13400
Connection ~ 22150 13400
Wire Wire Line
	22150 13400 21750 13400
NoConn ~ 8000 8750
NoConn ~ 7200 8750
Text Label 4950 800  3    50   ~ 0
~RESET
Text Label 2250 800  3    50   ~ 0
PIN_141
Text Label 2550 800  3    50   ~ 0
PIN_138
Text Label 4250 800  3    50   ~ 0
PIN_121
Text Label 4350 800  3    50   ~ 0
PIN_120
Text Label 4450 800  3    50   ~ 0
PIN_119
Text Label 4850 800  3    50   ~ 0
PIN_115
$Comp
L Connector_Generic:Conn_02x04_Odd_Even J4
U 1 1 5EFB3B95
P 5600 10650
F 0 "J4" H 5650 10967 50  0000 C CNN
F 1 "uBus" H 5650 10876 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x04_P2.54mm_Vertical" H 5600 10650 50  0001 C CNN
F 3 "~" H 5600 10650 50  0001 C CNN
	1    5600 10650
	1    0    0    -1  
$EndComp
Entry Wire Line
	4850 10750 4950 10850
Entry Wire Line
	4850 10650 4950 10750
Entry Wire Line
	4850 10550 4950 10650
Entry Wire Line
	4850 10450 4950 10550
Wire Wire Line
	4950 10550 5400 10550
Wire Wire Line
	5400 10650 4950 10650
Wire Wire Line
	4950 10750 5400 10750
Wire Wire Line
	5400 10850 4950 10850
Entry Wire Line
	6400 10550 6500 10450
Entry Wire Line
	6400 10650 6500 10550
Entry Wire Line
	6400 10750 6500 10650
Entry Wire Line
	6400 10850 6500 10750
Wire Wire Line
	5900 10550 6400 10550
Wire Wire Line
	6400 10650 5900 10650
Wire Wire Line
	5900 10750 6400 10750
Wire Wire Line
	6400 10850 5900 10850
Text Label 4950 10550 0    50   ~ 0
GND
Text Label 6400 10550 2    50   ~ 0
VCC
Text Label 4950 10650 0    50   ~ 0
PIN_141
Text Label 6400 10650 2    50   ~ 0
PIN_138
Text Label 4950 10750 0    50   ~ 0
PIN_121
Text Label 6400 10750 2    50   ~ 0
PIN_120
Text Label 4950 10850 0    50   ~ 0
PIN_119
Text Label 6400 10850 2    50   ~ 0
PIN_115
NoConn ~ 5900 4000
NoConn ~ 5900 3500
NoConn ~ 1500 4100
NoConn ~ 1500 4200
NoConn ~ 1500 2400
NoConn ~ 1500 2700
Entry Wire Line
	11050 3400 11150 3500
Entry Wire Line
	11050 3500 11150 3600
Entry Wire Line
	11050 3600 11150 3700
Entry Wire Line
	11050 3700 11150 3800
Wire Wire Line
	11550 3800 11150 3800
Wire Wire Line
	11150 3700 11550 3700
Wire Wire Line
	11550 3600 11150 3600
Wire Wire Line
	11150 3500 11550 3500
$Comp
L Connector_Generic:Conn_01x04 J6
U 1 1 5FBC1848
P 11750 3600
F 0 "J6" H 11830 3592 50  0000 L CNN
F 1 "AVR UART" H 11830 3501 50  0000 L CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_1x04_P2.54mm_Vertical" H 11750 3600 50  0001 C CNN
F 3 "~" H 11750 3600 50  0001 C CNN
	1    11750 3600
	1    0    0    -1  
$EndComp
Text Label 11150 3500 0    50   ~ 0
VCC
Text Label 11150 3600 0    50   ~ 0
GND
Text Label 11150 3800 0    50   ~ 0
AVR_RX
Text Label 11150 3700 0    50   ~ 0
AVR_TX
$Comp
L Device:R R39
U 1 1 5EFD4192
P 15350 6150
F 0 "R39" V 15557 6150 50  0000 C CNN
F 1 "10k" V 15466 6150 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 15280 6150 50  0001 C CNN
F 3 "~" H 15350 6150 50  0001 C CNN
	1    15350 6150
	-1   0    0    1   
$EndComp
$Comp
L power:GND #PWR0175
U 1 1 5EFD6432
P 15350 6000
F 0 "#PWR0175" H 15350 5750 50  0001 C CNN
F 1 "GND" H 15355 5827 50  0000 C CNN
F 2 "" H 15350 6000 50  0001 C CNN
F 3 "" H 15350 6000 50  0001 C CNN
	1    15350 6000
	-1   0    0    1   
$EndComp
Wire Wire Line
	15350 6300 15350 6400
Connection ~ 15350 6400
Wire Wire Line
	15350 6400 15600 6400
$Comp
L Device:R R38
U 1 1 5F203B49
P 15000 6150
F 0 "R38" V 15207 6150 50  0000 C CNN
F 1 "10k" V 15116 6150 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 14930 6150 50  0001 C CNN
F 3 "~" H 15000 6150 50  0001 C CNN
	1    15000 6150
	-1   0    0    1   
$EndComp
$Comp
L vcc33:VCC3_3 #PWR0176
U 1 1 5F204E83
P 15000 6000
F 0 "#PWR0176" H 15000 5850 50  0001 C CNN
F 1 "VCC3_3" H 14950 6150 50  0000 C CNN
F 2 "" H 15000 6000 50  0001 C CNN
F 3 "" H 15000 6000 50  0001 C CNN
	1    15000 6000
	1    0    0    -1  
$EndComp
Wire Wire Line
	15000 6300 15000 6500
Connection ~ 15000 6500
Wire Wire Line
	15000 6500 14300 6500
$Comp
L Device:CP C45
U 1 1 5F3013A0
P 18750 10900
F 0 "C45" H 18868 10946 50  0000 L CNN
F 1 "470uF" H 18868 10855 50  0000 L CNN
F 2 "Capacitor_THT:CP_Radial_D12.5mm_P7.50mm" H 18788 10750 50  0001 C CNN
F 3 "~" H 18750 10900 50  0001 C CNN
	1    18750 10900
	1    0    0    -1  
$EndComp
Wire Wire Line
	18750 10750 18300 10750
Connection ~ 18300 10750
Wire Wire Line
	18750 11050 18300 11050
Connection ~ 18300 11050
$Comp
L Device:R R40
U 1 1 5F2B5155
P 5550 11250
F 0 "R40" V 5757 11250 50  0000 C CNN
F 1 "10k" V 5666 11250 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 11250 50  0001 C CNN
F 3 "~" H 5550 11250 50  0001 C CNN
	1    5550 11250
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R41
U 1 1 5F2B9DA6
P 5550 11600
F 0 "R41" V 5757 11600 50  0000 C CNN
F 1 "10k" V 5666 11600 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 11600 50  0001 C CNN
F 3 "~" H 5550 11600 50  0001 C CNN
	1    5550 11600
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R42
U 1 1 5F2BA24B
P 5550 11950
F 0 "R42" V 5757 11950 50  0000 C CNN
F 1 "10k" V 5666 11950 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 11950 50  0001 C CNN
F 3 "~" H 5550 11950 50  0001 C CNN
	1    5550 11950
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R43
U 1 1 5F2BA5B2
P 5550 12300
F 0 "R43" V 5757 12300 50  0000 C CNN
F 1 "10k" V 5666 12300 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 12300 50  0001 C CNN
F 3 "~" H 5550 12300 50  0001 C CNN
	1    5550 12300
	0    -1   -1   0   
$EndComp
$Comp
L Device:R R44
U 1 1 5F2BA8BE
P 5550 12650
F 0 "R44" V 5757 12650 50  0000 C CNN
F 1 "10k" V 5666 12650 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 12650 50  0001 C CNN
F 3 "~" H 5550 12650 50  0001 C CNN
	1    5550 12650
	0    -1   -1   0   
$EndComp
$Comp
L power:VCC #PWR0177
U 1 1 5F2C0719
P 5900 11200
F 0 "#PWR0177" H 5900 11050 50  0001 C CNN
F 1 "VCC" H 5915 11373 50  0000 C CNN
F 2 "" H 5900 11200 50  0001 C CNN
F 3 "" H 5900 11200 50  0001 C CNN
	1    5900 11200
	1    0    0    -1  
$EndComp
Wire Wire Line
	5900 11200 5900 11250
Wire Wire Line
	5900 12650 5700 12650
Wire Wire Line
	5700 12300 5900 12300
Connection ~ 5900 12300
Wire Wire Line
	5900 12300 5900 12650
Connection ~ 5900 11950
Wire Wire Line
	5900 11950 5900 12300
Wire Wire Line
	5700 11950 5900 11950
Wire Wire Line
	5700 11600 5900 11600
Connection ~ 5900 11600
Wire Wire Line
	5900 11600 5900 11950
Wire Wire Line
	5700 11250 5900 11250
Connection ~ 5900 11250
Wire Wire Line
	5900 11250 5900 11600
Entry Wire Line
	4850 11150 4950 11250
Entry Wire Line
	4850 11500 4950 11600
Entry Wire Line
	4850 11850 4950 11950
Entry Wire Line
	4850 12200 4950 12300
Entry Wire Line
	4850 12550 4950 12650
Wire Wire Line
	4950 11250 5400 11250
Wire Wire Line
	4950 11600 5400 11600
Wire Wire Line
	4950 11950 5400 11950
Wire Wire Line
	4950 12300 5400 12300
Wire Wire Line
	4950 12650 5400 12650
Text Label 4950 11250 0    50   ~ 0
~FDC_RDATA
Text Label 4950 11600 0    50   ~ 0
~FDC_WPRT
Text Label 4950 11950 0    50   ~ 0
~FDC_TR00
Text Label 4950 12300 0    50   ~ 0
FDC_INTRQ
Text Label 4950 12650 0    50   ~ 0
FDC_DRQ
$Comp
L Device:R R45
U 1 1 5FD6B17A
P 5550 10150
F 0 "R45" V 5757 10150 50  0000 C CNN
F 1 "10k" V 5666 10150 50  0000 C CNN
F 2 "Resistor_SMD:R_0805_2012Metric_Pad1.15x1.40mm_HandSolder" V 5480 10150 50  0001 C CNN
F 3 "~" H 5550 10150 50  0001 C CNN
	1    5550 10150
	0    -1   -1   0   
$EndComp
Wire Wire Line
	5700 10150 5900 10150
Wire Wire Line
	5900 10150 5900 9850
Connection ~ 5900 9850
Entry Wire Line
	4850 10050 4950 10150
Wire Wire Line
	4950 10150 5400 10150
Text Label 4950 10150 0    50   ~ 0
~LAVR_CS
Wire Bus Line
	14200 10200 14200 11000
Wire Bus Line
	4850 6350 5350 6350
Wire Bus Line
	700  6350 3150 6350
Wire Bus Line
	3150 6350 3150 10550
Wire Bus Line
	700  6350 700  9700
Wire Bus Line
	3150 6350 4850 6350
Wire Bus Line
	14200 10200 20350 10200
Wire Bus Line
	20350 4950 20350 10200
Wire Bus Line
	16000 4950 20350 4950
Wire Bus Line
	14200 700  14200 10200
Wire Bus Line
	4850 6350 4850 12550
Wire Bus Line
	700  700  6500 700 
Wire Bus Line
	700  700  700  6350
Wire Bus Line
	11050 700  11050 10150
Wire Bus Line
	6500 700  6500 11200
Wire Bus Line
	8750 700  8750 11450
$EndSCHEMATC
