-----------------------------------------------------------------[Rev.20110625]
-- I2S Master Controller (TDA1543A) Right-Justified Mode
-------------------------------------------------------------------------------
-- 41LE

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
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;
 
entity tda1543a is
	Port ( 
		RESET	: in std_logic;
		CLK		: in std_logic;
		CS		: in std_logic;
        DATA_L	: in std_logic_vector (15 downto 0);
        DATA_R	: in std_logic_vector (15 downto 0);
		BCK		: out std_logic;
		WS		: out std_logic;
        DATA	: out std_logic );
end tda1543a;

architecture tda1543a_arch of tda1543a is
	signal data_i : std_logic_vector (31 downto 0);
	signal bit_cnt : std_logic_vector (5 downto 0);
begin
	process (RESET, CLK, CS)
	begin
		if (RESET = '1' or CS = '0') then
			bit_cnt <= (others => '0');
			data_i <= (others => '0');
		elsif (CLK'event and CLK = '0') then
			if (bit_cnt = "000000") then
				data_i <= DATA_L & DATA_R;
				WS <= '1';
			elsif (bit_cnt(5 downto 3) = "001" or bit_cnt(5 downto 3) = "010" or bit_cnt(5 downto 3) = "100" or bit_cnt(5 downto 3) = "101") then
				data_i <= data_i(30 downto 0) & '0';
			elsif bit_cnt = "011000" then	-- 024
				WS <= '0';
			end if;
			bit_cnt <= bit_cnt + 1;
		end if;
	end process;

	DATA <= data_i(31);
	BCK <= CLK when CS = '1' else '1';

end tda1543a_arch;