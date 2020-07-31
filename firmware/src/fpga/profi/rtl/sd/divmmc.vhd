-------------------------------------------------------------------[29.07.2019]
-- DivMMC
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>
-- Modified by: Andy Karpov <andy.karpov@gmail.com>

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity divmmc is
port (
	I_CLK				 : in std_logic;
	I_CS				 : in std_logic;

	I_RESET			 : in std_logic;
	I_ADDR			 : in std_logic_vector(15 downto 0);
	I_DATA			 : in std_logic_vector(7 downto 0);
	O_DATA			 : out std_logic_vector(7 downto 0);
	O_WR 				 : out std_logic;
	I_WR_N			 : in std_logic;
	I_RD_N			 : in std_logic;
	I_IORQ_N			 : in std_logic;
	I_MREQ_N			 : in std_logic;
	I_M1_N			 : in std_logic;

	O_DISABLE_ZXROM : out std_logic;
	O_EEPROM_CS_N 	 : out std_logic;
	O_EEPROM_WE_N 	 : out std_logic;
	O_SRAM_CS_N 	 : out std_logic;
	O_SRAM_WE_N 	 : out std_logic;
	O_SRAM_HIADDR	 : out std_logic_vector(5 downto 0);
	
	O_CS_N			 : out std_logic;
	O_SCLK			 : out std_logic;
	O_MOSI			 : out std_logic;
	I_MISO			 : in std_logic);
end divmmc;

architecture rtl of divmmc is
	signal cnt		: std_logic_vector(3 downto 0);
	signal cnt_en		: std_logic;
	signal cs		: std_logic := '1';
	signal reg_e3		: std_logic_vector(7 downto 0) := "00000000";
	signal automap		: std_logic := '0';
	signal detect		: std_logic := '0';
	signal shift_in	: std_logic_vector(7 downto 0);
	signal shift_out	: std_logic_vector(7 downto 0);
	signal mapram 		: std_logic;
	signal conmem 	 	: std_logic;
	
begin

process (I_RESET, I_CLK, I_WR_N, I_ADDR, I_IORQ_N, I_CS, I_DATA)
begin
	if (I_RESET = '1') then
		cs <= '1';
		reg_e3 <= (others => '0');
	elsif (I_CLK'event and I_CLK = '1') then
		if (I_IORQ_N = '0' and I_WR_N = '0' and I_CS = '1' and I_ADDR(7 downto 0) = X"E3") then	reg_e3 <= I_DATA; end if;	-- #E3
		if (I_IORQ_N = '0' and I_WR_N = '0' and I_CS = '1' and I_ADDR(7 downto 0) = X"E7") then cs <= I_DATA(0); end if;	-- #E7
	end if;
end process;

process (I_RESET, I_CLK, I_M1_N, I_MREQ_N, I_ADDR, I_CS, I_RD_N, detect)
begin
	--if (I_RESET = '1') then 
	--	detect <= '0';
	--	automap <= '0';
	if (I_CLK'event and I_CLK = '1') then
		if (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and (I_CS = '1' or mapram = '1') and (I_ADDR = X"0000" or I_ADDR = X"0008" or I_ADDR = X"0038" or I_ADDR = X"0066" or I_ADDR = X"04C6" or I_ADDR = X"0562")) then
			detect <= '1';	-- активируется при извлечении кода команды в М1 цикле при совпадении заданных адресов
		elsif (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and (I_CS = '1' or mapram = '1') and I_ADDR(15 downto 8) = X"3D") then
			automap <= '1';
			detect <= '1';
		elsif (I_M1_N = '0' and I_MREQ_N = '0' and I_RD_N = '0' and (I_CS = '1' or mapram = '1') and I_ADDR(15 downto 3) = "0001111111111") then
			detect <= '0';	-- деактивируется при извлечении кода команды в М1 при совпадении адресов 0x1FF8-0x1FFF
		end if;
		
		if (I_M1_N = '1') then
			automap <= detect;	-- переключение после чтения опкода
		end if;
	end if;
end process;

mapram <= reg_e3(6);
conmem <= reg_e3(7);

O_DISABLE_ZXROM <= (automap or conmem);
O_WR <= '1' when I_IORQ_N = '0' and I_RD_N = '0' and I_M1_N = '1' and I_ADDR(7 downto 0) = X"EB" else '0';

process (I_MREQ_N, automap, conmem, I_ADDR, mapram, I_WR_N, I_CS, reg_e3)
begin
	O_EEPROM_CS_N <= '1';
	O_SRAM_CS_N <= '1';
	O_SRAM_HIADDR <= reg_e3(5 downto 0);
	O_SRAM_WE_N <= '1';
	O_EEPROM_WE_N <= '1';
	if (I_MREQ_N = '0') then 
		if (automap = '1' or conmem = '1') then 
			if (I_ADDR(15 downto 13) = "000") then 
				if (conmem = '1' or mapram = '0') then 
					O_EEPROM_CS_N <= '0';
					if (I_WR_N = '0' and I_CS = '1') then 
						O_EEPROM_WE_N <= '0';
					end if;
				else 
					O_SRAM_CS_N <= '0';
					O_SRAM_HIADDR <= "000011";
				end if;
			elsif (I_ADDR(15 downto 13) = "001") then 
				O_SRAM_CS_N <= '0';
				if (conmem = '1' or mapram = '0' or (mapram = '1' and reg_e3(3 downto 0) /= "0011")) then 
					O_SRAM_WE_N <= I_WR_N;
				end if;
			end if;
		end if;
	end if;
end process;

O_CS_N  <= cs;

-------------------------------------------------------------------------------
-- SPI Interface
cnt_en <= not cnt(3) or cnt(2) or cnt(1) or cnt(0);

process (I_CLK, cnt_en, I_ADDR, I_IORQ_N, I_RD_N, I_WR_N, I_CS)
begin
	if (I_ADDR(7 downto 0) = X"EB" and I_IORQ_N = '0' and I_CS = '1' and (I_WR_N = '0' or I_RD_N = '0')) then
		cnt <= "1110";
	else 
		if (I_CLK'event and I_CLK = '0') then			
			if cnt_en = '1' then 
				cnt <= cnt + 1;
			end if;
		end if;
	end if;
end process;

process (I_CLK)
begin
	if (I_CLK'event and I_CLK = '0') then			
		if (I_ADDR(7 downto 0) = X"EB" and I_WR_N = '0' and I_IORQ_N = '0' and I_CS = '1') then
			shift_out <= I_DATA;
		else
			if cnt(3) = '0' then
				shift_out(7 downto 0) <= shift_out(6 downto 0) & '1';
			end if;
		end if;
	end if;
end process;

process (I_CLK)
begin
	if (I_CLK'event and I_CLK = '0') then			
		if cnt(3) = '0' then
			shift_in <= shift_in(6 downto 0) & I_MISO;
		end if;
	end if;
end process;

O_SCLK  <= I_CLK and not cnt(3);
O_MOSI  <= shift_out(7);
O_DATA  <= shift_in;


end rtl;