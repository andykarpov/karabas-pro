## Generated SDC file "karabas_pro.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"

## DATE    "Sun Aug  2 15:53:18 2020"

##
## DEVICE  "EP4CE6E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLK_50MHZ} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK_50MHZ}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {U1|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {U1|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 14 -divide_by 25 -master_clock {CLK_50MHZ} [get_pins {U1|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {U1|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {U1|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 12 -divide_by 25 -master_clock {CLK_50MHZ} [get_pins {U1|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {U2|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {U2|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 4 -divide_by 25 -master_clock {CLK_50MHZ} [get_pins {U2|altpll_component|auto_generated|pll1|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}]  0.150  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {U1|altpll_component|auto_generated|pll1|clk[0]}]  0.030  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_clocks {CLK_50MHZ}] -to [get_ports {AVR_SCK}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[11]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|Req_Inhibit}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[12]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[0]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[6]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[6]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[2]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[6]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[7]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|IORQ_n_i}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[3]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|IORQ_n_i}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[9][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[9][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[4]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[3]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[6]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[6]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[3]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[9][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[10][0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[9][1]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[4]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[10][1]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ssg}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|Req_Inhibit}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[4]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[7][1]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[11]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|IORQ_n_i}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[0]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[4]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|Req_Inhibit}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[2]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {soundrive:U12|out3f_reg[0]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[11]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[6]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|IORQ_n_i}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[0]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[12]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|Req_Inhibit}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[3]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[4]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[7][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IntCycle}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[6]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[8][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[11]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|IORQ_n_i}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[3]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[11][1]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {cpld_kbd:U14|days_reg[3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[0]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IntCycle}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[3]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[2]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[1]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[14]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IntCycle}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[3]}] -to [get_keepers {cpld_kbd:U14|minutes_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IntCycle}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[4][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[10][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[2]}] -to [get_keepers {cpld_kbd:U14|hours_reg[2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[1]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[6]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[6][7]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg0|ymreg[9][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|IR[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][5]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {cpld_kbd:U14|seconds_reg[3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|A[9]}] -to [get_keepers {turbosound:U11|ym2149:ssg1|ymreg[9][4]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[0]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[1][2]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|MCycle[2]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[7][3]}]
set_false_path -from [get_keepers {T80aw:U4|T80a:u0|T80:u0|F[7]}] -to [get_keepers {T80aw:U4|T80a:u0|T80:u0|T80_Reg:Regs|RegsH[3][2]}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

