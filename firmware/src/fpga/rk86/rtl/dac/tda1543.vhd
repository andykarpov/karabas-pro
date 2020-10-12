-------------------------------------------------------------------[23.10.2011]
-- I2S Master Controller
-- Author: MVV
-- Unified by: Andy Karpov 2020-09-20
-------------------------------------------------------------------------------

-- (TDA1543) Mode MSB First
-- STATE     01  02  03  04  05  06  07  08  09  0A  0B  ..  0F  10  11  12  13  14  15  16  17  18  19  1A  1B  ..  1F  00
--      ___  __  __  __  __  __  __  __  __  __  __  __  ..  __  __  __  __  __  __  __  __  __  __  __  __  __  ..  __  __  ____
-- DATA    \/LS\/MS\/  \/  \/  \/  \/  \/  \/  \/  \/  \/  \/  \/  \/LS\/MS\/  \/  \/  \/  \/  \/  \/  \/  \/  \/  \/  \/  \/   
--      ___/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\../\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\../\__/\__/\____
--          -0- -F- -E- -D- -C- -B- -A- -9- -8- -7- -6-  .. -2- -1- -0- -F- -E- -D- -C- -B- -A- -9- -8- -7- -6-  .. -2- -1- 
--        _   _   _   _   _   _   _   _   _   _   _   _  ..   _   _   _   _   _   _   _   _   _   _   _   _   _  ..   _   _   _ 
-- BCK   | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
--      _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
--             |
--      ___    |                                                    _____________________________________________..________ 
-- WS      |   |            LEFT                                   |                RIGHT                                  |
--         |___|_________________________________________..________|                                                       |______
--             |SAMPLE OUT

-- (TDA1543A) Right-Justified Mode
-- STATE  000 001 002 003 004 005 006 007 008 009 010 011..   023 024 025 026 027 028 029 030 031 032 033 034 035..   047
--      ___  __________________________________  __  __  ..  __  __  __________________________________  __  __  ..  __  __  ____
-- DATA    \/               MSB                \/  \/  \/  \/  \/LS\/               MSB                \/  \/  \/  \/  \/LS\/   
--      ___/\__________________________________/\__/\__/\../\__/\__/\__________________________________/\__/\__/\../\__/\__/\____
--          -F- -F- -F- -F- -F- -F- -F- -F- -F- -E- -D-  .. -1- -0- -F- -F- -F- -F- -F- -F- -F- -F- -F- -E- -D-  .. -1- -0- 
--        _   _   _   _   _   _   _   _   _   _   _   _  ..   _   _   _   _   _   _   _   _   _   _   _   _   _  ..   _   _   _ 
-- BCK   | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | | |
--      _| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
--           |
--          _|___________________________________________..________                                                         ______
-- WS      | |              LEFT                                   |                RIGHT                                  |
--      ___| |                                                     |_____________________________________________..________|
--           | SAMPLE OUT

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity tda1543 is
	Port ( 
		RESET		: in std_logic;
		DAC_TYPE : in std_logic := '0'; -- 0 = TDA1543, 1 = TDA1543A
		CLK		: in std_logic;
		CS			: in std_logic;
      DATA_L	: in std_logic_vector (15 downto 0);
      DATA_R	: in std_logic_vector (15 downto 0);
		BCK		: out std_logic;
		WS			: out std_logic;
      DATA		: out std_logic 
);
end tda1543;
 
architecture tda1543_arch of tda1543 is
	signal shift_reg : std_logic_vector (31 downto 0) := "00000000000000000000000000000000";
	signal bit_cnt : std_logic_vector (4 downto 0) := "00000"; -- counter for TDA1543
	signal bit_cnt2 : std_logic_vector (5 downto 0) := "000000"; -- counter for TDA1543A
	signal data1 : std_logic := '0';
begin
	process (RESET, CLK, CS, DAC_TYPE)
	begin
		if (RESET = '1' or CS = '0') then
			shift_reg <= (others => '0');
			bit_cnt <= (others => '0');
			bit_cnt2 <= (others => '0');
		elsif (CLK'event and CLK = '0') then
			if dac_type = '0' then
				-- TDA1543
				bit_cnt <= bit_cnt + "00001";
				shift_reg <= shift_reg(30 downto 0) & '0';
				DATA1 <= shift_reg(31);
				if bit_cnt = "00000" then
					WS <= '0';
					shift_reg <= DATA_L & DATA_R;
				elsif bit_cnt = "10000" then		
					WS <= '1';
				end if;
			else 
				-- TDA1543A
				if (bit_cnt2 = "000000") then
					shift_reg <= DATA_L & DATA_R;
					WS <= '1';
				elsif (bit_cnt2(5 downto 3) = "001" or bit_cnt2(5 downto 3) = "010" or bit_cnt2(5 downto 3) = "100" or bit_cnt2(5 downto 3) = "101") then
					shift_reg <= shift_reg(30 downto 0) & '0';
				elsif bit_cnt2 = "011000" then	-- 024
					WS <= '0';
				end if;
				bit_cnt2 <= bit_cnt2 + 1;
			end if;
		end if;
	end process;
	
	process (dac_type, shift_reg, data1)
	begin
		if (dac_type = '1') then 
			DATA <= shift_reg(31);
		else 
			DATA <= data1;
		end if;
	end process;
	
 	BCK <= CLK when CS = '1' else '1';
 	
end tda1543_arch;