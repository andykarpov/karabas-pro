-------------------------------------------------------------------[19.03.2011]
-- Z-Controller
-------------------------------------------------------------------------------
-- V0.1	05.11.2011

-- Config port 77h
-- Write:
-- 	bit 0 	= SD card power (0 - off, 1 - on)
-- 	bit 1 	= control CS signal
-- 	bit 2-7	= NC
-- Read:
-- 	bit 0	   = SD card detect, 0 - in slot, 1 - absent
-- 	bit 1	   = SD read only, 0 - read/write access, 1 - read only
-- 	bit 2-6	= NC
--	   bit 7	   = 0 - loading, 1 - buffer contains a new data
--
-- Data port 57h
-- Read/write port to exchange data by SPI.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity zcontroller is
	port (
		RESET	: in std_logic;
		CLK     : in std_logic;
		A       : in std_logic;
		DI		: in std_logic_vector(7 downto 0);
		DO		: out std_logic_vector(7 downto 0);
		RD		: in std_logic;
		WR		: in std_logic;
		SDDET	: in std_logic;
		SDPROT	: in std_logic;
		CS_n	: out std_logic;
		SCLK	: out std_logic;
		MOSI	: out std_logic;
		MISO	: in std_logic );
end;

architecture rtl of zcontroller is
	signal cnt			: std_logic_vector(3 downto 0);
	signal shift_in		: std_logic_vector(7 downto 0);
	signal shift_out	: std_logic_vector(7 downto 0);
	signal cnt_en		: std_logic;
	signal csn			: std_logic;
	
begin

	process (RESET, CLK, A, WR, DI)
	begin
		if RESET = '1' then
			csn <= '1';
		elsif (CLK'event and CLK = '1') then
			if (A = '1' and WR = '1') then
				csn <= DI(1);
			end if;
		end if;
	end process;

	cnt_en <= not cnt(3) or cnt(2) or cnt(1) or cnt(0);
	
	process (CLK, cnt_en, A, RD, WR, SDPROT)
	begin
		if (A = '0' and (WR = '1' or RD = '1')) then
			cnt <= "1110";
		else 
			if (CLK'event and CLK = '0') then			
				if cnt_en = '1' then
					cnt <= cnt + 1;
				end if;
			end if;
		end if;
	end process;

	process (CLK)
	begin
		if (CLK'event and CLK = '0') then			
			if (A = '0' and WR = '1') then
				shift_out <= DI;
			else
				if cnt(3) = '0' then
					shift_out(7 downto 0) <= shift_out(6 downto 0) & '1';
				end if;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if (CLK'event and CLK = '0') then			
			if cnt(3) = '0' then
				shift_in <= shift_in(6 downto 0) & MISO;
			end if;
		end if;
	end process;
	
	SCLK  <= CLK and not cnt(3);
	MOSI  <= shift_out(7);
	CS_n  <= csn;
	DO    <= cnt(3) & "11111" & SDPROT & '0' when A = '1' else shift_in;
	
end rtl;