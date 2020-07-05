-------------------------------------------------------------------[25.07.2019]
-- u16-Loader
-- DEVBOARD ReVerSE-U16
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
	FLASH_ADDR_START	: std_logic_vector(23 downto 0) := "000010111000000000000000"; -- 753664; -- 24bit address
	RAM_ADDR_START		: std_logic_vector(20 downto 0) := "110000000000000000000"; -- 21 bit address
	SIZE_TO_READ		: integer := 73728; -- count of bytes to read (64 rom + 8kb esxdos)
	
--	RAM_CLEAR_ADDR_START	: std_logic_vector(24 downto 0) := "1000000000000000000000000"; 
--	SIZE_TO_CLEAR 		: integer := 524288; -- count of bytes to clear

	RAM_CLEAR_ADDR_START	: std_logic_vector(20 downto 0) := "000000000000000000000"; 
	SIZE_TO_CLEAR 		: integer := 131072; -- count of bytes to clear
	
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
	RAM_DI 			: out std_logic_vector(7 downto 0);
	RAM_DO 			: in std_logic_vector(7 downto 0);
	RAM_WR			: out std_logic;
	RAM_RD			: out std_logic;
	RAM_RFSH			: out std_logic;

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
signal sdr_do_bus		: std_logic_vector(7 downto 0);
signal sdr_wr			: std_logic;
signal sdr_rd			: std_logic;
signal sdr_rfsh		: std_logic;

-- System
signal loader_act 	: std_logic := '1';
signal reset_cnt  	: std_logic_vector(3 downto 0) := "0000";
signal read_cnt 		: std_logic_vector(16 downto 0) := (others => '0');
signal clear_cnt 		: std_logic_vector(20 downto 0) := (others => '0');

type machine IS(init, release_init, wait_init, 
					 ready, cmd_read, cmd_end_read, do_read, do_next, finish, 
					 clear, do_clear, do_next_clear, 
					 finish2);     --state machine datatype
signal state 			: machine; --current state

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
sdr_rd <= '0';
sdr_rfsh <= '0';

RAM_A <= sdr_a_bus;
RAM_DI <= sdr_di_bus;
sdr_do_bus <= RAM_DO;
RAM_WR <= sdr_wr;
RAM_RD <= sdr_rd;
RAM_RFSH <= sdr_rfsh;

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
			when finish => -- finish of reading flash to ram
				-- state <= clear;
				state <= finish2;
			when clear => -- clear ready state
				if (clear_cnt < SIZE_TO_CLEAR) then 
					state <= do_clear;
				else 
					state <= finish2;
				end if;
			when do_clear => 
				sdr_wr <= '1'; -- begin ram write
				sdr_di_bus <= "00000000"; 
				state <= do_next_clear;
			when do_next_clear => 
				sdr_wr <= '0'; -- end ram write
				clear_cnt <= clear_cnt + 1; -- increment read counter
				state <= clear;		
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