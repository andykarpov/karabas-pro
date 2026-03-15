## Generated SDC file "karabas_pro_ep4ce22.out.sdc"

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

## DATE    "Tue Jan 27 11:52:45 2026"

##
## DEVICE  "EP4CE22E22C8"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLK_50MHZ} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK_50MHZ}]
create_clock -name {MCU_SCK} -period 62.500 -waveform { 0.000 31.250 } [get_ports {MCU_SCK}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {U2|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {U2|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 4 -master_clock {U1|altpll_component|auto_generated|pll1|clk[0]} [get_pins {U2|altpll_component|auto_generated|pll1|clk[2]}] 
create_generated_clock -name {U2|altpll_component|auto_generated|pll1|clk[3]} -source [get_pins {U2|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 3 -divide_by 14 -master_clock {U1|altpll_component|auto_generated|pll1|clk[0]} [get_pins {U2|altpll_component|auto_generated|pll1|clk[3]}] 
create_generated_clock -name {U2|altpll_component|auto_generated|pll1|clk[4]} -source [get_pins {U2|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 14 -master_clock {U1|altpll_component|auto_generated|pll1|clk[0]} [get_pins {U2|altpll_component|auto_generated|pll1|clk[4]}] 
create_generated_clock -name {U1|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {U1|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 56 -divide_by 25 -master_clock {CLK_50MHZ} [get_pins {U1|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {clk_14} -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[2]}] -divide_by 2 -master_clock {U2|altpll_component|auto_generated|pll1|clk[2]} [get_registers {clk_div2}] -add
create_generated_clock -name {clk_7} -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[2]}] -divide_by 4 -master_clock {U2|altpll_component|auto_generated|pll1|clk[2]} [get_registers {clk_div4}] -add
create_generated_clock -name {clk_12} -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[3]}] -divide_by 2 -master_clock {U2|altpll_component|auto_generated|pll1|clk[3]} [get_registers {clk_div2}] -add
create_generated_clock -name {clk_6} -source [get_pins {U2|altpll_component|auto_generated|pll1|clk[3]}] -divide_by 4 -master_clock {U2|altpll_component|auto_generated|pll1|clk[3]} [get_registers {clk_div4}] -add


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clk_6}] -rise_to [get_clocks {clk_6}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -fall_to [get_clocks {clk_6}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_6}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -rise_to [get_clocks {clk_6}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -fall_to [get_clocks {clk_6}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_6}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_12}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_12}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_12}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_12}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_12}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_12}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_12}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_12}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_12}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_12}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_12}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_12}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_14}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_14}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_14}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_14}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_14}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_14}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_14}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_14}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_14}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_14}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_14}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_14}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -rise_to [get_clocks {clk_7}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -fall_to [get_clocks {clk_7}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {clk_7}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -rise_to [get_clocks {clk_7}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -fall_to [get_clocks {clk_7}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {clk_7}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -rise_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_12}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clk_14}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[4]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {MCU_SCK}] -setup 0.150  
set_clock_uncertainty -fall_from [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {MCU_SCK}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -hold 0.150  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -hold 0.150  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.150  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.150  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -hold 0.150  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] -hold 0.150  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -rise_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.150  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {MCU_SCK}] -fall_to [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -hold 0.150  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -exclusive -group [get_clocks {CLK_50MHZ}] -group [get_clocks {MCU_SCK}] 
set_clock_groups -exclusive -group [get_clocks {clk_14}] -group [get_clocks {clk_12}] 
set_clock_groups -exclusive -group [get_clocks {clk_7}] -group [get_clocks {clk_6}] 
set_clock_groups -exclusive -group [get_clocks {U2|altpll_component|auto_generated|pll1|clk[0]}] -group [get_clocks {U2|altpll_component|auto_generated|pll1|clk[1]}] 
set_clock_groups -exclusive -group [get_clocks {U2|altpll_component|auto_generated|pll1|clk[2]}] -group [get_clocks {U2|altpll_component|auto_generated|pll1|clk[3]}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_b09:dffpipe16|dffe17a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_a09:dffpipe13|dffe14a*}]
set_false_path -from [get_registers {port_dffd_reg[*]}] 
set_false_path -to [get_ports {VGA_*}]


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

