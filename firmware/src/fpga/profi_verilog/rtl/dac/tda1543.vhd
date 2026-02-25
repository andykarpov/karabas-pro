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
		CLK_BUS 	: in std_logic;
		CS			: in std_logic;
      DATA_L	: in std_logic_vector (15 downto 0);
      DATA_R	: in std_logic_vector (15 downto 0);
		BCK		: out std_logic;
		WS			: out std_logic;
      DATA		: out std_logic 
);
end tda1543;
 
architecture tda1543_arch of tda1543 is

signal shift_reg : std_logic_vector(47 downto 0) := (others => '0');
signal cnt : std_logic_vector(5 downto 0) := (others => '0');
signal cnt_clk : std_logic_vector(1 downto 0) := (others => '0');

begin

-- clk counter 
process (RESET, CS, CLK_BUS, cnt_clk)
begin 
	if (RESET = '1' or CS = '0') then 
		cnt_clk <= (others => '0');
	elsif (falling_edge(CLK_BUS)) then 
		cnt_clk <= cnt_clk + 1;
	end if;
end process;

-- counter
process (RESET, CS, CLK_BUS, cnt, cnt_clk, DAC_TYPE)
begin 
	if (RESET = '1' or CS = '0') then 
		cnt <= (others => '0');
	elsif (CLK_BUS'event and CLK_BUS = '0' and cnt_clk = "00") then
		case DAC_TYPE is 
			when '0' => 
				if (cnt < 31) then 
					cnt <= cnt + 1;
				else
					cnt <= (others => '0');
				end if;
			when '1' =>
				if (cnt < 47) then 
					cnt <= cnt + 1;
				else
					cnt <= (others => '0');
				end if;
			when others => null;
		end case;
	end if;
end process;

-- WS
process (RESET, CS, CLK_BUS, cnt_clk, cnt, DAC_TYPE)
begin 
	if (RESET = '1' or CS = '0') then 
		WS <= '0';		
	elsif (CLK_BUS'event and CLK_BUS = '0' and cnt_clk = "00") then
		case DAC_TYPE is 
			when '0' => 
				if cnt = 0 then 
					WS <= '0';
				elsif cnt = 16 then 
					WS <= '1';
				end if;
			when '1' =>
				if cnt = 0 then 
					WS <= '1';
				elsif cnt = 24 then 
					WS <= '0';
				end if;
			when others => null;
		end case;
	end if;
end process;

-- shift register
process (RESET, CLK_BUS, cnt_clk, CS, DAC_TYPE, shift_reg, DATA_L, DATA_R)
begin
	if (RESET = '1' or CS = '0') then
		shift_reg <= (others => '0');
	elsif (CLK_BUS'event and CLK_BUS = '0' and cnt_clk = "00") then
		case DAC_TYPE is 
			when '0' =>
				if cnt = 0 then 
					shift_reg(47 downto 16) <= DATA_R(0) & DATA_L(15 downto 1) & DATA_L(0) & DATA_R(15 downto 1); -- LSB R + L + LSB L + R
				else 
					shift_reg <= shift_reg(46 downto 0) & '0';
				end if;
			when '1' => 
				if cnt = 0 then 
					shift_reg <= DATA_L(15 downto 8) & DATA_L & DATA_R(15 downto 8) & DATA_R; -- MSB L + L + MSB R + R
				else 
					shift_reg <= shift_reg(46 downto 0) & '0';
				end if;			
			when others => null;
		end case;
	end if;
end process;

DATA <= shift_reg(47);
BCK <= '0' when cnt_clk(1) = '1' and CS = '1' else '1';

end tda1543_arch;