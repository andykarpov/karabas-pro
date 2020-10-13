-------------------------------------------------------------------[25.07.2019]
-- Loader
--
-- Load data from SPI flash (W25Q16) into RAM on boot
-- 1. Loader process initiates by RESET=1 (asynchronous)
-- 2. Loader progress indicates via LOADER_ACTIVE=1
-- 3. At the end, a LOADER_RESET=1 pulse will be triggered to re-boot the host
--
-- Copyright (c) 2019 Andy Karpov <andy.karpov@gmail.com>
--
-- Datasheets:
-- 	https://www.winbond.com/resource-files/w25q16dv_revi_nov1714_web.pdf
--		https://www.digikey.com/eewiki/pages/viewpage.action?pageId=4096096
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity loader is
generic (
	FLASH_ADDR_START	: std_logic_vector(23 downto 0) := "000010111000000000000000"; -- 753664; -- 24bit address / ROM image start at
	RAM_ADDR_START		: std_logic_vector(20 downto 0) := "100000000000000000000"; -- 21 bit address / RAM address to copy ROM image to
	SIZE_TO_READ		: integer := 262144; -- count of bytes to read (4x 64KB rom) / count of bytes to read
	CFG_ADDR 			: std_logic_vector(23 downto 0) := "000011111000000000000000"; -- 1015808; -- 24bit address / config byte address
	
	SPI_CMD_READ  		: std_logic_vector(7 downto 0) := X"03"; -- W25Q16 read command
	SPI_CMD_POWERON 	: std_logic_vector(7 downto 0) := X"AB" -- W25Q16 power on command
);
port (
	-- bus clock 28 MHz
	CLK   			: in std_logic;
	
	-- global reset
	RESET 			: in std_logic;
	
	-- RAM interface
	RAM_A 			: out std_logic_vector(20 downto 0);
	RAM_DO 			: out std_logic_vector(7 downto 0);
	RAM_WR			: out std_logic;
	
	-- Config byte 
	CFG 				: out std_logic_vector(7 downto 0) := "00000010";

	-- SPI FLASH (M25P16)
	DATA0				: in std_logic;
	NCSO				: out std_logic;
	DCLK				: out std_logic;
	ASDO				: out std_logic;

	-- loader state pulses
	LOADER_ACTIVE 	: out std_logic;
	LOADER_RESET 	: out std_logic
);
end loader;

architecture rtl of loader is

-- SPI
signal spi_page_bus 	: std_logic_vector(15 downto 0);
signal spi_a_bus 		: std_logic_vector(7 downto 0);
signal spi_di_bus		: std_logic_vector(39 downto 0);
signal spi_do_bus		: std_logic_vector(39 downto 0);
signal spi_busy		: std_logic;
signal spi_ena 		: std_logic;
signal spi_continue  : std_logic;
signal spi_si			: std_logic;
signal spi_so			: std_logic;
signal spi_clk			: std_logic;
signal spi_ss_n 		: std_logic_vector(0 downto 0);

-- SDRAM
signal sdr_a_bus 		: std_logic_vector(20 downto 0);
signal sdr_di_bus		: std_logic_vector(7 downto 0);
signal sdr_wr			: std_logic := '0';

-- System
signal loader_act 	: std_logic := '1';
signal reset_cnt  	: std_logic_vector(3 downto 0) := "0000";
signal read_cnt 		: std_logic_vector(20 downto 0) := (others => '0');
signal clear_cnt 		: std_logic_vector(20 downto 0) := (others => '0');

type machine IS(init, release_init, wait_init, 
					 ready, cmd_read, cmd_end_read, do_read, do_next, finish, 
					 cmd_read_cfg, cmd_end_read_cfg, do_read_cfg, finish_cfg,
					 finish2);     --state machine datatype
signal state : machine; --current state

begin
	
-- SPI FLASH 25MHz 
U1: entity work.loader_spi
generic map (
	slaves 	=> 1,
	d_width 	=> 40
)
port map (
	clock 	=> CLK, 
	reset_n 	=> not(RESET),
	enable 	=> spi_ena,
	cpol		=> '0', -- spi mode 0
	cpha 		=> '0',
	cont 		=> spi_continue,
	clk_div 	=> 2, -- CLK divider
	addr 		=> 0,
	tx_data 	=> spi_di_bus,
	miso 		=> spi_so,
	sclk 		=> spi_clk,
	ss_n 		=> spi_ss_n,
	mosi		=> spi_si,
	busy 		=> spi_busy,
	rx_data 	=> spi_do_bus
);
	
NCSO <= spi_ss_n(0) when loader_act = '1' else '1';
spi_so <= DATA0;
ASDO <= spi_si;
DCLK <= spi_clk;
	
-------------------------------------------------------------------------------

-- RAM
RAM_A <= sdr_a_bus;
RAM_DO <= sdr_di_bus;
RAM_WR <= sdr_wr;

-- loading state machine
process (RESET, CLK, loader_act)
VARIABLE spi_busy_cnt : INTEGER := 0;
begin
	if RESET = '1' then
		loader_act <= '1';
		spi_page_bus <= FLASH_ADDR_START(23 downto 8);
		spi_a_bus <= FLASH_ADDR_START(7 downto 0);
		sdr_a_bus <= RAM_ADDR_START;
		spi_ena <= '0';
		sdr_wr <= '0';
		spi_continue <= '0';
		state <= init;
		read_cnt <= (others => '0');
	elsif CLK'event and CLK = '1' then
		
		case state is 
			when init => -- power on command
				spi_ena <='1'; -- spi ena pulse
				spi_di_bus <= spi_cmd_poweron & "0000000000000000" & "00000000" & "00000000";
				state <= release_init;
			when release_init => -- end spi ena pulse
				spi_ena <='0';
				state <= wait_init;
			when wait_init => -- wait for power on command complete
				if (spi_busy = '0') then 
					state <= ready;
				else 
					state <= wait_init;
				end if;
			when ready => -- ready to begin / finish
				spi_ena <= '0';
				if (read_cnt < SIZE_TO_READ) then 
					state <= cmd_read;
				else 
					state <= finish;
				end if;
			when cmd_read => -- read command
				spi_ena <= '1';
				spi_di_bus <= spi_cmd_read & spi_page_bus & spi_a_bus & "00000000";
				state <= cmd_end_read;
			when cmd_end_read => -- end of read command
				spi_ena <= '0';
				state <= do_read;
			when do_read => -- wait for spi transfer
				if (spi_busy = '0') then 
					sdr_wr <= '1'; -- begin ram write
					sdr_di_bus <= spi_do_bus(7 downto 0); -- todo
					state <= do_next;
				else 
					state <= do_read;
				end if;
			when do_next => -- increment address / page
				sdr_wr <= '0'; -- end ram write
				read_cnt <= read_cnt + 1; -- increment read counter
				if (spi_a_bus = X"FF") then -- increment flash page
					spi_page_bus <= spi_page_bus + 1;
				end if;
				spi_a_bus <= spi_a_bus + 1; -- increment flash address 
				sdr_a_bus <= sdr_a_bus + 1; -- increment ram address
				state <= ready;
			when finish => -- finish of reading rom images fro flash to ram
				state <= cmd_read_cfg;
			
			-- read cfg byte from spi flash
			when cmd_read_cfg => 
				spi_ena <= '1';
				spi_di_bus <= spi_cmd_read & CFG_ADDR & "00000000";
				state <= cmd_end_read_cfg;
			when cmd_end_read_cfg => 
				spi_ena <= '0';
				state <= do_read_cfg;
			when do_read_cfg => -- wait for spi transfer
				if (spi_busy = '0') then 
					CFG <= spi_do_bus(7 downto 0);
					state <= finish_cfg;
				else 
					state <= do_read_cfg;
				end if;
			when finish_cfg => 
				state <= finish2;
			
			when finish2 => -- read all the required data from SPI flash
				state <= finish2; -- infinite loop here
				loader_act <= '0'; -- loader finished
		end case;
	
	end if;
end process;

-- reset signal at the end
process (RESET, CLK, reset_cnt, loader_act)
begin
	if RESET = '1' then
		reset_cnt <= "0000";
	elsif CLK'event and CLK = '1' then
		if (loader_act = '0' and reset_cnt /= "1000") then 
			reset_cnt <= reset_cnt + 1;
		end if;
	end if;
end process;

-------------------------------------------------------------------------------

LOADER_ACTIVE <= loader_act;
LOADER_RESET <= reset_cnt(2);

end rtl;