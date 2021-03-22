-------------------------------------------------------------------[13.10.2020]
-- Simplified Loader
--
-- Copyright (c) 2020 Andy Karpov <andy.karpov@gmail.com>
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
	CFG_ADDR 			: std_logic_vector(23 downto 0) := "000111110000000000000000"; -- 0x1F0000; -- 24bit address / config byte address
	SPI_CMD_READ  		: std_logic_vector(7 downto 0) := X"03"; -- W25Q16 read command
	SPI_CMD_POWERON 	: std_logic_vector(7 downto 0) := X"AB" -- W25Q16 power on command
);
port (
	CLK   			: in std_logic;
	RESET 			: in std_logic;
	CFG 				: out std_logic_vector(7 downto 0) := "00000010";
	DATA0				: in std_logic;
	NCSO				: out std_logic;
	DCLK				: out std_logic;
	ASDO				: out std_logic
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

-- System
signal loader_act 	: std_logic := '1';
signal reset_cnt  	: std_logic_vector(3 downto 0) := "0000";
signal read_cnt 		: std_logic_vector(20 downto 0) := (others => '0');
signal clear_cnt 		: std_logic_vector(20 downto 0) := (others => '0');

type machine IS(init, release_init, wait_init, 
					 ready, 
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

-- loading state machine
process (RESET, CLK, loader_act)
VARIABLE spi_busy_cnt : INTEGER := 0;
begin
	if RESET = '1' then
		loader_act <= '1';
		spi_ena <= '0';
		spi_continue <= '0';
		state <= init;
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

end rtl;