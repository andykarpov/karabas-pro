-------------------------------------------------------------------[11.09.2015]
-- Soundrive 1.05
-------------------------------------------------------------------------------
-- Engineer: 	MVV <mvvproject@gmail.com>
--
-- 05.10.2011	Initial

-- SOUNDRIVE 1.05 PORTS mode 1
-- #0F = left channel I_ADDR (stereo covox channel 1)
-- #1F = left channel B
-- #3F = profi left channel
-- #4F = right channel C (stereo covox channel 2)
-- #5F = right channel D / profi right channel
-- #FB = single port covox

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 
 
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
		I_CPM 	: in std_logic; -- https://zx-pk.ru/printthread.php?t=609&pp=10&page=135
		I_ROM14	: in std_logic;
		
		O_LEFT 		: out std_logic_vector(15 downto 0);
		O_RIGHT 		: out std_logic_vector(15 downto 0));		
end soundrive;
 
architecture soundrive_unit of soundrive is
	signal out0f_reg : std_logic_vector (7 downto 0);
	signal out1f_reg : std_logic_vector (7 downto 0);
	signal out3f_reg : std_logic_vector (7 downto 0);
	signal out4f_reg : std_logic_vector (7 downto 0);
	signal out5f_reg : std_logic_vector (7 downto 0);
	signal outfb_reg : std_logic_vector (7 downto 0);
	signal outb3_reg : std_logic_vector (7 downto 0);
begin

	process (I_CLK, I_RESET, I_CS, I_DOS, I_CPM, I_IORQ_N, I_WR_N)
	begin
		if I_RESET = '1' or I_CS = '0' then
			out0f_reg <= (others => '0');
			out1f_reg <= (others => '0');
			out3f_reg <= (others => '0');
			out4f_reg <= (others => '0');
			out5f_reg <= (others => '0');
			outfb_reg <= (others => '0');			
		elsif I_CLK'event and I_CLK = '1' and I_DOS = '0' and I_CPM='0' and I_CS = '1' and  I_IORQ_N = '0' and I_WR_N = '0' then
			if I_ADDR = X"0F" then -- soundrive 4 left
				out0f_reg <= I_DATA;
			elsif I_ADDR = X"1F" then -- soundrive 4 left2 
				out1f_reg <= I_DATA;
			elsif I_ADDR = X"3F" then -- profi left 
				out3f_reg <= I_DATA;
			elsif I_ADDR = X"4F" then -- soundrive 4 right 
				out4f_reg <= I_DATA;
			elsif I_ADDR = X"5F" then -- profi right / soundrive 4 right2
				out5f_reg <= I_DATA;
			elsif I_ADDR = X"B3" then -- ?
				outb3_reg <= I_DATA;
			elsif I_ADDR = X"FB" then -- single covox 1
				outfb_reg <= I_DATA;
			end if;
		end if;
	end process;
	
	O_LEFT <= ("000" & out0f_reg   & "00000") + ("000" & out1f_reg   & "00000") + ("000" & out3f_reg   & "00000") + ("000" & outfb_reg   & "00000") + ("000" & outb3_reg   & "00000");
	O_RIGHT <= ("000" & out4f_reg   & "00000") + ("000" & out5f_reg   & "00000") + ("000" & outfb_reg   & "00000");
	
end soundrive_unit;