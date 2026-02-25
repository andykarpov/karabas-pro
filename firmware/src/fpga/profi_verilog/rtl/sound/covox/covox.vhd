-------------------------------------------------------------------[16.10.2020]
-- Profi Covox
-------------------------------------------------------------------------------
-- PORTS
-- #3F = profi left channel
-- #5F = profi right channel
-- #FB = single port covox

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 
 
entity covox is
	Port ( 
		I_RESET		: in std_logic;
		I_CLK			: in std_logic;
		I_CS			: in std_logic;
		I_ADDR		: in std_logic_vector(7 downto 0);
		I_DATA		: in std_logic_vector(7 downto 0);
		I_WR_N		: in std_logic;
		I_IORQ_N		: in std_logic;

		I_DOS			: in std_logic;
		I_CPM 		: in std_logic; -- https://zx-pk.ru/printthread.php?t=609&pp=10&page=135
		I_ROM14		: in std_logic;
		
		O_A	 		: out std_logic_vector(7 downto 0);
		O_B	 		: out std_logic_vector(7 downto 0);
		O_C	 		: out std_logic_vector(7 downto 0);
		O_D	 		: out std_logic_vector(7 downto 0);
		O_FB 			: out std_logic_vector(7 downto 0)
);		
end covox;
 
architecture covox_unit of covox is

	signal outa_reg : std_logic_vector (7 downto 0);
	signal outb_reg : std_logic_vector (7 downto 0);
	signal outc_reg : std_logic_vector (7 downto 0);
	signal outd_reg : std_logic_vector (7 downto 0);
	signal outfb_reg 		: std_logic_vector (7 downto 0);
	
begin

	process (I_CLK, I_RESET, I_CS, I_DOS, I_CPM, I_IORQ_N, I_WR_N)
	begin
		if I_RESET = '1' or I_CS = '0' then
			outa_reg <= (others => '0');
			outb_reg <= (others => '0');		
			outc_reg <= (others => '0');
			outd_reg <= (others => '0');
			outfb_reg <= (others => '0');	
		elsif I_CLK'event and I_CLK = '1' and I_DOS = '0' and I_CPM='0' and I_CS = '1' and  I_IORQ_N = '0' and I_WR_N = '0' then
			case I_ADDR is 
				when x"0F" => outa_reg <= I_DATA;
				when x"1F" => outb_reg <= I_DATA;
				when x"3F" => outb_reg <= I_DATA;
				when x"4F" => outc_reg <= I_DATA;
				when x"5F" => outd_reg <= I_DATA;
				when x"FB" => outfb_reg <= I_DATA;
				when others => null;
			end case;
		end if;
	end process;
	
	O_A <= outa_reg;
	O_B <= outb_reg;
	O_C <= outc_reg;
	O_D <= outd_reg;
	O_FB <= outfb_reg;
	
end covox_unit;