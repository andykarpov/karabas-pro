-------------------------------------------------------------------------------
-- Memory controller
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity memory is
generic (
		enable_bus_n_romcs : boolean := true
);
port (
	CLK2X 		: in std_logic;
	CLKX	   	: in std_logic;
	CLK_CPU 		: in std_logic;

	A           : in std_logic_vector(15 downto 0); -- address bus
	D 				: in std_logic_vector(7 downto 0);
	N_MREQ		: in std_logic;
	N_IORQ 		: in std_logic;
	N_WR 			: in std_logic;
	N_RD 			: in std_logic;
	N_M1 			: in std_logic;
	
	loader_act 	: in std_logic := '0';
	loader_ram_a: in std_logic_vector(20 downto 0);
	loader_ram_do: in std_logic_vector(7 downto 0);
	loader_ram_wr: in std_logic := '0';
	
	DO 			: out std_logic_vector(7 downto 0);
	N_OE 			: out std_logic;
	
	MA 			: out std_logic_vector(20 downto 0);
	MD 			: inout std_logic_vector(7 downto 0) := "ZZZZZZZZ";
	N_MRD 		: out std_logic;
	N_MWR 		: out std_logic;
	
	RAM_BANK		: in std_logic_vector(2 downto 0);
	RAM_EXT 		: in std_logic_vector(2 downto 0);
	
	TRDOS 		: in std_logic;
	
	VA				: in std_logic_vector(13 downto 0);
	VID_PAGE 	: in std_logic := '0';
	VID_DO 		: out std_logic_vector(7 downto 0);
	VID_RD 		: in std_logic;

	DS80			: in std_logic := '0';
	CPM 			: in std_logic := '0';
	SCO			: in std_logic := '0';
	SCR 			: in std_logic := '0';
	WOROM 		: in std_logic := '0';
	
	ROM_BANK : in std_logic := '0';
	EXT_ROM_BANK : in std_logic_vector(1 downto 0) := "00"
);
end memory;

architecture RTL of memory is

	signal is_rom : std_logic := '0';
	signal is_ram : std_logic := '0';
	
	signal rom_page : std_logic_vector(1 downto 0) := "00";
	signal ram_page : std_logic_vector(6 downto 0) := "0000000";

	signal vid_wr 		: std_logic;
	signal vid_scr 	: std_logic;
	signal vid_bank 	: std_logic := '0';
	signal vid_aw_bus	: std_logic_vector(14 downto 0);
	signal vid_ar_bus	: std_logic_vector(14 downto 0);
	
	signal mux : std_logic_vector(1 downto 0);

begin

	-- ША видеопамяти на запись
	vid_aw_bus <= vid_bank & A(13 downto 0) when DS80 = '1' else '0' & vid_scr & A(12 downto 0);

	-- ША видеопамяти на чтение
	vid_ar_bus <= vid_rd & VA(13 downto 0) when DS80 = '1' else '0' & vid_page & VA(12 downto 0);
	
	-- банк видеопамяти для пикселей или атрибутов для профи режима (1 - атрибуты, 0 - пиксели)
	vid_bank <= '1' when (ram_page = "0111000" and VID_PAGE='0') or (ram_page = "0111010" and VID_PAGE='1') else '0';

	-- видеопамять 32кБ
	U_VRAM: entity work.altram1
	port map(
		clock_a => CLK2X,
		clock_b => CLK2X,
		address_a => vid_aw_bus,
		address_b => vid_ar_bus,
		data_a => D,
		data_b => "11111111",
		q_a => open,
		q_b => VID_DO,
		wren_a => vid_wr,
		wren_b => '0'
	);

	is_rom <= '1' when N_MREQ = '0' and A(15 downto 14)  = "00" and WOROM = '0' else '0';
	is_ram <= '1' when N_MREQ = '0' and is_rom = '0' else '0';

	-- сигнал записи в видеопамять (в зависимости от видеорежима DS80)
	vid_wr <= '1' when N_MREQ = '0' and N_WR = '0' and 
	(
		(DS80 = '1' and ((ram_page = "0000100" and VID_PAGE='0') or (ram_page = "0000110" and VID_PAGE='1'))) or -- profi pixel
		(DS80 = '1' and ((ram_page = "0111000" and VID_PAGE='0') or (ram_page = "0111010" and VID_PAGE='1'))) or -- profi attr
		(DS80 = '0' and ((ram_page = "0000101" or ram_page = "0000111" ) and A(13) = '0')) -- spectrum screen
	) else '0';
	
	-- видеостраница при записи в память в спектрум-режиме
	vid_scr <= '1' when ram_page = "0000111" and A(13) = '0' else '0';
		
	-- 00 - bank 0, CPM
	-- 01 - bank 1, TRDOS
	-- 10 - bank 2, Basic-128
	-- 11 - bank 3, Basic-48
	rom_page <= (not(TRDOS)) & ROM_BANK;
				
	N_MRD <= '1' when loader_act = '1' else 
				'0' when (is_rom = '1' and N_RD = '0') or
							(N_RD = '0' and N_MREQ = '0') 
				else '1';

	N_MWR <= not loader_ram_wr when loader_act = '1' else 
				'0' when is_ram = '1' and N_WR = '0' else 
				'1';

	DO <= MD;
	
	N_OE <= '0' when (is_ram = '1' or is_rom = '1') and N_RD = '0' else '1';
		
	mux <= A(15 downto 14);
		
	process (mux, RAM_EXT, RAM_BANK, SCR, SCO)
	begin
		case mux is
			when "00" => ram_page <= "0000000";                 -- Seg0 ROM 0000-3FFF or Seg0 RAM 0000-3FFF	
			when "01" => if SCO='0' then 
								ram_page <= "0000101";
							 else 
								ram_page <= "0" & RAM_EXT(2 downto 0) & RAM_BANK(2 downto 0); 
							 end if;	                               -- Seg1 RAM 4000-7FFF	
			when "10" => if SCR='0' then 
								ram_page <= "0000010"; 	
							 else 
								ram_page <= "0000110"; 
							 end if;                                -- Seg2 RAM 8000-BFFF
			when "11" => if SCO='0' then 
								ram_page <= "0" & RAM_EXT(2 downto 0) & RAM_BANK(2 downto 0);	
							 else 
								ram_page <= "0000111";               -- Seg3 RAM C000-FFFF	
							 end if;
			when others => null;
		end case;
	end process;
		
	MA(20 downto 0) <= 
		loader_ram_a(20 downto 0) when loader_act = '1' else -- loader ram
		"100" & EXT_ROM_BANK(1 downto 0) & rom_page(1 downto 0) & A(13 downto 0) when is_rom = '1' else -- rom from sram high bank 
		ram_page(6 downto 0) & A(13 downto 0);
	
	MD(7 downto 0) <= 
		loader_ram_do when loader_act = '1' else -- loader DO
		D(7 downto 0) when (is_ram = '1' and N_WR = '0') else 
		(others => 'Z');
			
end RTL;

