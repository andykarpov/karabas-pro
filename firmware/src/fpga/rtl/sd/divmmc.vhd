-------------------------------------------------------------------[01.04.2014]
-- DivMMC
-------------------------------------------------------------------------------
-- V0.1.0	27.03.2014	Первая версия
-- V0.1.1	30.03.2014	Исправление в генерации automap, не учитывалось моментальное переключение по 3Dxx
-- V0.2.0	01.04.2014	Исправление в переключении после чтения опкода (автор shurik-ua)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divmmc is
port (
	CLK				: in std_logic;
	EN				: in std_logic;
	RESET			: in std_logic;
	ADDR			: in std_logic_vector(15 downto 0);
	DI				: in std_logic_vector(7 downto 0);
	DO				: out std_logic_vector(7 downto 0);
	WR_N			: in std_logic;
	RD_N			: in std_logic;
	IORQ_N			: in std_logic;
	MREQ_N			: in std_logic;
	M1_N			: in std_logic;
	E3REG			: out std_logic_vector(7 downto 0);
	AMAP			: out std_logic;
	CS_N			: out std_logic;
	SCLK			: out std_logic;
	MOSI			: out std_logic;
	MISO			: in std_logic);
	
end divmmc;

architecture rtl of divmmc is
	signal counter		: std_logic_vector(3 downto 0);
	signal shift_reg	: std_logic_vector(8 downto 0);
	signal in_reg		: std_logic_vector(7 downto 0);	
	signal cs			: std_logic := '1';
	signal reg_e7		: std_logic := '0';
	signal automap		: std_logic := '0';
	signal detect		: std_logic := '0';
	signal reg_e3		: std_logic_vector(7 downto 0) := "00000000";
	
begin

process (RESET, CLK, WR_N, ADDR, IORQ_N, EN, DI)
begin
	if (RESET = '1') then
		cs <= '1';
--		reg_e3(5 downto 0) <= (others => '0');
--		reg_e3(7) <= '0';
		reg_e3 <= (others => '0');
	elsif (CLK'event and CLK = '1') then
--		if (IORQ_N = '0' and WR_N = '0' and EN = '1' and ADDR(7 downto 0) = X"E3") then	reg_e3 <= DI(7) & (reg_e3(6) or DI(6)) & DI(5 downto 0); end if;	-- #E3
		if (IORQ_N = '0' and WR_N = '0' and EN = '1' and ADDR(7 downto 0) = X"E3") then	reg_e3 <= DI; end if;	-- #E3
		if (IORQ_N = '0' and WR_N = '0' and EN = '1' and ADDR(7 downto 0) = X"E7") then cs <= DI(0); end if;	-- #E7
	end if;
end process;

process (CLK, M1_N, MREQ_N, ADDR, EN, detect, automap)
begin
	if (CLK'event and CLK = '1') then
		if (M1_N = '0' and MREQ_N = '0' and EN = '1' and (ADDR = X"0000" or ADDR = X"0008" or ADDR = X"0038" or ADDR = X"0066" or ADDR = X"04C6" or ADDR = X"0562" or ADDR(15 downto 8) = X"3D")) then
			detect <= '1';	-- активируется при извлечении кода команды в М1 цикле при совпадении заданных адресов
		elsif (M1_N = '0' and MREQ_N = '0' and EN = '1' and ADDR(15 downto 3) = "0001111111111") then
			detect <= '0';	-- деактивируется при извлечении кода команды в М1 при совпадении адресов 0x1FF8-0x1FFF
		end if;
		if (M1_N = '0' and IORQ_N = '1' and EN = '1' and ADDR(15 downto 8) = X"3D") then
			automap <= '1';	-- моментальное переключение без ожидания чтения опкода
		elsif (MREQ_N = '0' and EN = '1' and WR_N = '1' and RD_N = '1') then
			automap <= detect;	-- переключение после чтения опкода
		end if;
	end if;
end process;

-------------------------------------------------------------------------------
-- SPI Interface
process(CLK, RESET, ADDR, IORQ_N, WR_N)
begin
	if RESET = '1' then
		shift_reg <= (others => '1');
		in_reg <= (others => '1');
		counter <= "1111"; -- Idle
	elsif (CLK'event and CLK = '1') then
		if counter = "1111" then
			in_reg <= shift_reg(7 downto 0);
			if IORQ_N = '0' and ADDR(7 downto 0) = X"EB" and EN = '1' then
				if WR_N = '1' then
					shift_reg <= (others => '1');
				else
					shift_reg <= DI & '1';
				end if;
				counter <= "0000";
			end if;
		else
			counter <= counter + 1;
			if counter(0) = '0' then
				shift_reg(0) <= MISO;
			else
				shift_reg <= shift_reg(7 downto 0) & '1';
			end if;
		end if;
	end if;
end process;
	
DO 	  <= in_reg;
CS_N  <= cs;
MOSI  <= shift_reg(8);
SCLK  <= counter(0);
E3REG <= reg_e3;
AMAP  <= automap;

end rtl;