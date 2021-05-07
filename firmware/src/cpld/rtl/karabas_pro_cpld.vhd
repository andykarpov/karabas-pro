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
-- CPLD firmware for Karabas-Pro
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- @author Oleg Starichenko <solegstar@ukr.net>
-- Ukraine, 2021
-------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity karabas_pro_cpld is 
port (
	-- Master clock
	CLK : in std_logic;
	CLK2: in std_logic;
	
	-- FPGA interface signals
	NRESET : in std_logic;
	SA: in std_logic_vector(1 downto 0);
	SDIR: in std_logic;
	SD: inout std_logic_vector(15 downto 0);

	-- BDI signals
	FDC_NWR: out std_logic;
	FDC_NRD: out std_logic;
	FDC_D: inout std_logic_vector(7 downto 0);	
	FDC_NCS: out std_logic;
	FDC_A: out std_logic_vector(1 downto 0);
	FDC_SL : in std_logic;
	FDC_SR : in std_logic;
	FDC_NRESET: out std_logic;
	FDC_INTRQ: in std_logic;
	FDC_DRQ: in std_logic;
	FDC_WF_DE: in std_logic;
	FDC_WD: in std_logic;
	FDC_TR43: in std_logic;
	FDC_NRAWR: out std_logic;
	FDC_RCLK : out std_logic;
	FDC_CLK: out std_logic;
	FDC_HLT: out std_logic;
	FDC_DS0: out std_logic;
	FDC_DS1: out std_logic;
	FDC_SIDE: out std_logic;
	FDC_RDATA: in std_logic;
	FDC_WDATA: out std_logic;
	
	-- HDD signals
	HDD_D: inout std_logic_vector(15 downto 0);
	HDD_A: out std_logic_vector(2 downto 0);
	HDD_NCS0: buffer std_logic;
	HDD_NCS1: out std_logic;
	HDD_NWR: out std_logic;
	HDD_NRD: out std_logic;
	HDD_NRESET: out std_logic
);
end karabas_pro_cpld;

architecture rtl of karabas_pro_cpld is 

signal rx_buf: std_logic_vector(7 downto 0);

signal bus_a : std_logic_vector(15 downto 0);
signal bus_di: std_logic_vector(7 downto 0);
signal bus_do: std_logic_vector(7 downto 0);
signal bus_wr_n : std_logic := '1';
signal bus_rd_n : std_logic := '1';
signal ide_oe_n : std_logic := '1';
signal fdd_oe_n : std_logic := '1';
signal fdd_bus_do : std_logic_vector(7 downto 0);
signal ide_bus_do : std_logic_vector(7 downto 0);

begin 

	SD(15 downto 8) <= bus_do;
	
	-- rx
	process (CLK, SA)
	begin 
		if rising_edge(CLK) then
			case SA is 
				when "00" => 
					rx_buf <= SD(7 downto 0); -- rx
				when "01" => 
					bus_a(15 downto 8) <= rx_buf;
					bus_a(7 downto 0) <= SD(7 downto 0);
				when "10" =>
					bus_di <= SD(7 downto 0);
				when "11" =>
					bus_di <= bus_di;
			end case;
		end if;
	end process;
	
	U1: entity work.ide_controller 
	port map (
		CLK => CLK,
		NRESET => NRESET,
		
		BUS_DI => bus_di,
		BUS_DO => ide_bus_do,
		BUS_A => bus_a(4 downto 2),
		BUS_RD_N => bus_a(6),
		BUS_WR_N => bus_a(5),
		cs3fx => bus_a(12),
		profi_ebl => bus_a(15),
		wwc => bus_a(8),
		wwe => bus_a(9),
		rwe => bus_a(11),
		rww => bus_a(10),
		
		OE_N => ide_oe_n,
		
		IDE_A => HDD_A,
		IDE_D => HDD_D,
		IDE_CS0_N => HDD_NCS0,
		IDE_CS1_N => HDD_NCS1,
		IDE_RD_N => HDD_NRD,
		IDE_WR_N => HDD_NWR,
		IDE_RESET_N => HDD_NRESET
	);
	
	U2: entity work.fdd_controller
	port map (
		CLK => CLK,
		CLK8 => CLK2,
		NRESET => NRESET,
		
		BUS_DI => bus_di,
		BUS_DO => fdd_bus_do,
		BUS_A => bus_a(1 downto 0),
		BUS_RD_N => bus_a(6),
		BUS_WR_N => bus_a(5),
		csff => bus_a(13),
		FDC_NCS => bus_a(14),
		FDC_STEP => bus_a(7),
		FDD_CHNG => SDIR,
		OE_N => fdd_oe_n,
		
		FDC_NWR => FDC_NWR,
		FDC_NRD => FDC_NRD,
		FDC_D => FDC_D,	
		FDC_A => FDC_A,
		FDC_SL => FDC_SL,
		FDC_SR => FDC_SR,
		FDC_NRESET => FDC_NRESET,
		FDC_INTRQ => FDC_INTRQ,
		FDC_DRQ => FDC_DRQ,
		FDC_WF_DE => FDC_WF_DE,
		FDC_WD => FDC_WD,
		FDC_TR43 => FDC_TR43,
		FDC_NRAWR => FDC_NRAWR,
		FDC_RCLK => FDC_RCLK,
		FDC_CLK => FDC_CLK,
		FDC_HLT => FDC_HLT,
		FDC_DS0 => FDC_DS0,
		FDC_DS1 => FDC_DS1,
		FDC_SIDE => FDC_SIDE,
		FDC_RDATA => FDC_RDATA,
		FDC_WDATA => FDC_WDATA
	);
	
--SDIR <= '1' when HDD_NCS0 = '0' else '0';
--HDD_NCS1 <= '1';

FDC_NCS <= bus_a(14);

bus_do <= 
			fdd_bus_do when fdd_oe_n = '0' else 	
			ide_bus_do when ide_oe_n = '0' else 
			"11111111";
end rtl;
