-------------------------------------------------------------------[25.07.2019]
-- SPI flash parallel interface
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

entity flash is
generic (
	SPI_CMD_PAGEPRG	: std_logic_vector(7 downto 0) := X"02"; -- W25Q16 page program command
	SPI_CMD_READ  		: std_logic_vector(7 downto 0) := X"03"; -- W25Q16 read command
	SPI_CMD_WRITE_DIS : std_logic_vector(7 downto 0) := X"04"; -- W25Q16 write disable command
	SPI_CMD_STATUSREG : std_logic_vector(7 downto 0) := X"05"; -- W25Q16 read status register command
	SPI_CMD_WRITE_EN 	: std_logic_vector(7 downto 0) := X"06"; -- W25Q16 write enable command
	SPI_CMD_POWERON 	: std_logic_vector(7 downto 0) := X"AB" -- W25Q16 power on command
);
port (
	-- bus clock 28 MHz
	CLK   			: in std_logic;
	
	-- global reset
	RESET 			: in std_logic;
	
	-- parallel interface
	A 					: in std_logic_vector(23 downto 0);
	DI 				: in std_logic_vector(7 downto 0);
	DO 				: out std_logic_vector(7 downto 0);
	WR_N				: in std_logic := '1';
	RD_N				: in std_logic := '1';
	
	-- SPI FLASH physical interface (M25P16)
	DATA0				: in std_logic;
	NCSO				: out std_logic;
	DCLK				: out std_logic;
	ASDO				: out std_logic;

	-- status
	BUSY 				: out std_logic;
	DATA_READY 		: out std_logic
);
end flash;

architecture rtl of flash is

-- SPI
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
type machine IS(init, release_init, wait_init, 
					 idle, 
					 cmd_read, cmd_end_read, do_read, 
					 cmd_write_en, cmd_end_write_en, do_write_en,
					 cmd_write, cmd_end_write, do_write, 
					 cmd_write_dis, end_write_dis, do_write_dis,
					 cmd_erase, cmd_end_erase, do_erase,
					 check_status, cmd_end_status, do_status
);     --state machine datatype
signal state : machine := init; --current state

signal is_busy : std_logic := '1';
signal is_ready : std_logic := '0';

begin
	
-- SPI FLASH 25MHz 
U1: entity work.spi_master
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

NCSO <= spi_ss_n(0);
spi_so <= DATA0;
ASDO <= spi_si;
DCLK <= spi_clk;
	
-------------------------------------------------------------------------------

-- flash read / write state machine
process (RESET, CLK)
VARIABLE spi_busy_cnt : INTEGER := 0;
begin
	if RESET = '1' then
		spi_ena <= '0';
		spi_continue <= '0';
		state <= init;
		is_busy <= '1';
		is_ready <= '0';

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
					state <= idle;
				else 
					state <= wait_init;
				end if;
			
			when idle => -- ready to begin read / write cycle
				is_busy <= '0';
				spi_ena <= '0';
				
				if (RD_N = '0') then 
					state <= cmd_read;
				elsif (WR_N = '0') then 
					state <= cmd_write_en;
				else 
					state <= idle; -- loop here until a real command
				end if;
			
			when cmd_read => -- read command
				spi_ena <= '1';
				is_busy <= '1';
				is_ready <= '0';
				spi_di_bus <= spi_cmd_read & A & "00000000";
				state <= cmd_end_read;
			
			when cmd_end_read => -- end of read command
				spi_ena <= '0';
				state <= do_read;
			
			when do_read => -- wait for spi transfer
				if (spi_busy = '0') then 
					is_ready <= '1';
					DO <= spi_do_bus(7 downto 0); -- todo
					state <= idle;
				else 
					state <= do_read;
				end if;
				
			when cmd_write_en => -- write enable command
				spi_ena <= '1';
				is_busy <= '1';
				spi_di_bus <= spi_cmd_write_en & "0000000000000000" & "00000000" & "00000000";
				state <= cmd_end_write_en;
			
			when cmd_end_write_en => -- end of write enable command
				spi_ena <= '0';
				state <= do_write_en;
			
			when do_write_en => -- wait for spi transfer
				if (spi_busy = '0') then 
					state <= cmd_write;
				else 
					state <= do_write_en;
				end if;
				
			when cmd_write => -- page write command
				spi_ena <= '1';
				spi_di_bus <= spi_cmd_pageprg & A & DI;
				state <= cmd_end_write;
			
			when cmd_end_write => -- end of page write command
				spi_ena <= '0';
				state <= do_write;
			
			when do_write => -- wait for spi transfer
				if (spi_busy = '0') then 
					state <= cmd_write_dis;
				else 
					state <= do_write;
				end if;
				
			when cmd_write_dis => -- write disable command
				spi_ena <= '1';
				spi_di_bus <= spi_cmd_write_dis & "0000000000000000" & "00000000" & "00000000";
				state <= end_write_dis;
			
			when end_write_dis => -- end of write disable command
				spi_ena <= '0';
				state <= do_write_dis;
			
			when do_write_dis => -- wait for spi transfer
				if (spi_busy = '0') then 
					state <= idle;
				else 
					state <= do_write_dis;
				end if;
				
			when check_status => -- check device status by reading it's status register
				spi_ena <= '1';
				spi_di_bus <= spi_cmd_statusreg & "0000000000000000" & "00000000" & "00000000";
				state <= cmd_end_status;
				
			when cmd_end_status =>  -- end if status command
				spi_ena <= '0';
				state <= do_status;
					
			when do_status => -- wait for spi transfer
				if (spi_busy = '0') then 
					if (spi_do_bus(0) = '1') then -- device is busy with some long-running command
						state <= check_status;
					else 
						state <= idle;
					end if;
				else 
					state <= idle;
				end if;
				
			when others => null;
			
		end case;
	
	end if;
end process;

BUSY <= is_busy;
DATA_READY <= is_ready;

end rtl;