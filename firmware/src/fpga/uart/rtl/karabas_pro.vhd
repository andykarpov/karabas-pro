-------------------------------------------------------------------------------------------------------------------
-- 
-- 
-- #       #######                                                 #                                               
-- #                                                               #                                               
-- #                                                               #                                               
-- ############### ############### ############### ############### ############### ############### ############### 
-- #             #               # #                             # #             #               # #               
-- #             # ############### #               ############### #             # ############### ############### 
-- #             # #             # #               #             # #             # #             #               # 
-- #             # ############### #               ############### ############### ############### ############### 
--                                                                                                                 
--         ####### ####### ####### #######                         ############### ############### ############### 
--                                                                 #             # #               #             # 
--                                                                 ############### #               #             # 
--                                                                 #               #               #             # 
-- https://github.com/andykarpov/karabas-pro                       #               #               ############### 
--
-- FPGA firmware for Karabas-Pro/ Debug bridge for ESP8266 :)
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- Slovakia, 2023
-------------------------------------------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity karabas_pro is
port (
	-- Clock (50MHz)
	CLK_50MHZ	: in std_logic;

	-- UART / header
	UART2_TX		: out std_logic;
	UART2_CTS 	: in std_logic;
	UART2_RX 	: in std_logic;
	
	-- UART / ESP8266
	UART_RX 		: in std_logic;
	UART_TX 		: out std_logic;
	UART_CTS 	: out std_logic
	
);
end karabas_pro;

architecture rtl of karabas_pro is

begin

UART2_TX <= UART_RX;
UART_TX <= UART2_RX;
UART_CTS <= '0'; --UART2_CTS;

end rtl;
