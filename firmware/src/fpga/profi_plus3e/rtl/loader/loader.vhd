-------------------------------------------------------------------[25.07.2019]
-- Loader
--
-- Load data from SPI flash (W25Q16) into RAM on boot
-- 1. Loader process initiates by RESET=1 (asynchronous)
-- 2. Loader progress indicates via LOADER_ACTIVE=1
-- 3. At the end, a LOADER_RESET=1 pulse will be triggered to re-boot the host
--
-- Copyright (c) 2019, 2020 Andy Karpov <andy.karpov@gmail.com>
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
	FLASH_ADDR_START	: std_logic_vector(23 downto 0) := "000100000000000000000000"; -- 0x100000; -- 24bit address / ROM image start at
	RAM_ADDR_START		: std_logic_vector(20 downto 0) := "100000000000000000000"; -- 21 bit address / RAM address to copy ROM image to
	SIZE_TO_READ		: integer := 262144; -- count of bytes to read (4x 64KB rom) / count of bytes to read
	CFG_ADDR 			: std_logic_vector(23 downto 0) := "000111110000000000000000"; -- 0x1F0000; -- 24bit address / config byte address
	
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

	-- Parallel flash interface
	FLASH_A 			: out std_logic_vector(23 downto 0);
	FLASH_DO 		: in std_logic_vector(7 downto 0);
	FLASH_RD_N 		: out std_logic;
	FLASH_BUSY 		: in std_logic;
	FLASH_READY 	: in std_logic;
	
	-- loader state pulses
	LOADER_ACTIVE 	: out std_logic;
	LOADER_RESET 	: out std_logic
);
end loader;

architecture rtl of loader is

-- SPI
signal spi_page_bus 	: std_logic_vector(15 downto 0);
signal spi_a_bus 		: std_logic_vector(7 downto 0);

-- RAM
signal ram_a_bus 		: std_logic_vector(20 downto 0);

-- System
signal loader_act 	: std_logic := '1';
signal reset_cnt  	: std_logic_vector(3 downto 0) := "0000";
signal read_cnt 		: std_logic_vector(20 downto 0) := (others => '0');
signal clear_cnt 		: std_logic_vector(20 downto 0) := (others => '0');

type machine IS( 
					 ready, cmd_read, do_read, do_next, finish, 
					 cmd_read_cfg, do_read_cfg, finish_cfg,
					 finish2
);     --state machine datatype
signal state : machine; --current state

begin
	
-------------------------------------------------------------------------------

-- loading state machine
process (RESET, CLK, loader_act)
VARIABLE spi_busy_cnt : INTEGER := 0;
begin
	if RESET = '1' then
		loader_act <= '1';
		spi_page_bus <= FLASH_ADDR_START(23 downto 8);
		spi_a_bus <= FLASH_ADDR_START(7 downto 0);
		ram_a_bus <= RAM_ADDR_START;
		state <= ready;
		read_cnt <= (others => '0');
	elsif CLK'event and CLK = '1' then
		
		case state is 
			
			when ready => -- ready to begin / finish
				if (flash_busy = '1') then 
					state <= ready;
				elsif (read_cnt < SIZE_TO_READ) then 
					state <= cmd_read;
				else 
					state <= finish;
				end if;
			
			when cmd_read => -- read command
				FLASH_RD_N <= '0';
				if (flash_busy = '1') then 
					state <= do_read;
				end if;
			
			when do_read => -- wait for spi transfer
				FLASH_RD_N <= '1';
				if (flash_ready = '1') then
					RAM_WR <= '1'; -- begin ram write
					RAM_DO <= FLASH_DO;
					state <= do_next;
				else 
					state <= do_read;
				end if;
			
			when do_next => -- increment address / page
				RAM_WR <= '0'; -- end ram write
				read_cnt <= read_cnt + 1; -- increment read counter
				if (spi_a_bus = X"FF") then -- increment flash page
					spi_page_bus <= spi_page_bus + 1;
				end if;
				spi_a_bus <= spi_a_bus + 1; -- increment flash address 
				ram_a_bus <= ram_a_bus + 1; -- increment ram address
				state <= ready;

			when finish => -- finish of reading rom images fro flash to ram
				state <= cmd_read_cfg;
			
			-- read cfg byte from spi flash
			when cmd_read_cfg => 
				FLASH_RD_N <= '0';
				spi_page_bus <= CFG_ADDR(23 downto 8);
				spi_a_bus <= CFG_ADDR(7 downto 0);
				if (flash_busy = '1') then
					state <= do_read_cfg;
				end if;
			when do_read_cfg => -- wait for spi transfer
				FLASH_RD_N <= '1';
				if (flash_ready = '1') then 
					CFG <= FLASH_DO;
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
FLASH_A <= spi_page_bus & spi_a_bus;
RAM_A <= ram_a_bus;

end rtl;