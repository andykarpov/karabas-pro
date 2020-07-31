-------------------------------------------------------------------[11.09.2015]
-- Soundrive 1.05
-------------------------------------------------------------------------------
-- Engineer: 	MVV <mvvproject@gmail.com>
--
-- 05.10.2011	Initial

-- SOUNDRIVE 1.05 PORTS mode 1
-- #0F = left channel I_ADDR (stereo covox channel 1)
-- #1F = left channel B
-- #4F = right channel C (stereo covox channel 2)
-- #5F = right channel D

-- #FB = right channel D

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity soundrive is
	Port ( 
		I_RESET		: in std_logic;
		I_CLK		: in std_logic;
		I_CS		: in std_logic;
		I_ADDR		: in std_logic_vector(7 downto 0);
		I_DATA		: in std_logic_vector(7 downto 0);
		I_WR_N		: in std_logic;
		I_IORQ_N	: in std_logic;
		I_DOS		: in std_logic;
		O_COVOX_A	: out std_logic_vector(7 downto 0);
		O_COVOX_B	: out std_logic_vector(7 downto 0);
		O_COVOX_C	: out std_logic_vector(7 downto 0);
		O_COVOX_D	: out std_logic_vector(7 downto 0));
end soundrive;
 
architecture soundrive_unit of soundrive is
	signal outa_reg : std_logic_vector (7 downto 0);
	signal outb_reg : std_logic_vector (7 downto 0);
	signal outc_reg : std_logic_vector (7 downto 0);
	signal outd_reg : std_logic_vector (7 downto 0);
begin
	process (I_CLK, I_RESET, I_CS)
	begin
		if I_RESET = '1' or I_CS = '0' then
			O_COVOX_A <= (others => '0');
			O_COVOX_B <= (others => '0');
			O_COVOX_C <= (others => '0');
			O_COVOX_D <= (others => '0');
		elsif I_CLK'event and I_CLK = '1' then
			if I_ADDR = X"0F" and I_IORQ_N = '0' and I_WR_N = '0' and I_DOS = '0' then
				O_COVOX_A <= I_DATA;
			elsif I_ADDR = X"1F" and I_IORQ_N = '0' and I_WR_N = '0' and I_DOS = '0' then
				O_COVOX_B <= I_DATA;
			elsif I_ADDR = X"4F" and I_IORQ_N = '0' and I_WR_N = '0' and I_DOS = '0' then
				O_COVOX_C <= I_DATA;
			elsif I_ADDR = X"5F" and I_IORQ_N = '0' and I_WR_N = '0' and I_DOS = '0' then
				O_COVOX_D <= I_DATA;
			elsif I_ADDR = X"FB" and I_IORQ_N = '0' and I_WR_N = '0' and I_DOS = '0' then
				O_COVOX_D <= I_DATA;
			end if;
		end if;
	end process;
	
end soundrive_unit;