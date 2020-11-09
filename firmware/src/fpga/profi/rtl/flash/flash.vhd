-------------------------------------------------------------------[25.07.2019]
-- SPI flash parallel interface
--
-- Copyright (c) 2020 Andy Karpov <andy.karpov@gmail.com>
--
-- Datasheets:
-- 	https://www.winbond.com/resource-files/w25q16dv_revi_nov1714_web.pdf
--    https://www.micron.com/-/media/client/global/documents/products/data-sheet/nor-flash/serial-nor/m25p/m25p16.pdf
--		https://www.digikey.com/eewiki/pages/viewpage.action?pageId=4096096
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity flash is
generic (
	SPI_CMD_SETSTATUS   : std_logic_vector(7 downto 0) := X"01"; -- W25Q16 set status register command
	SPI_CMD_PAGEPRG	  : std_logic_vector(7 downto 0) := X"02"; -- W25Q16 page program command
	SPI_CMD_READ  		  : std_logic_vector(7 downto 0) := X"03"; -- W25Q16 read command
	SPI_CMD_WRITE_DIS   : std_logic_vector(7 downto 0) := X"04"; -- W25Q16 write disable command
	SPI_CMD_STATUSREG   : std_logic_vector(7 downto 0) := X"05"; -- W25Q16 read status register command
	SPI_CMD_WRITE_EN 	  : std_logic_vector(7 downto 0) := X"06"; -- W25Q16 write enable command
	SPI_CMD_BLOCK_ERASE : std_logic_vector(7 downto 0) := X"D8"; -- W25Q16 64k block erase command
	SPI_CMD_POWERON 	  : std_logic_vector(7 downto 0) := X"AB" -- W25Q16 power on command
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
	ER_N 				: in std_logic := '1';
	
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
signal spi_di_bus		: std_logic_vector(7 downto 0);
signal spi_do_bus		: std_logic_vector(7 downto 0);

signal spi_busy		: std_logic;
signal spi_busy_prev : std_logic;
signal spi_ena 		: std_logic;
signal spi_cont	   : std_logic;

signal spi_si			: std_logic;
signal spi_so			: std_logic;
signal spi_clk			: std_logic;
signal spi_ss_n 		: std_logic_vector(0 downto 0);

signal prev_rd_n 		: std_logic;
signal prev_wr_n 		: std_logic;
signal prev_er_n 		: std_logic;

-- System
type machine IS( --state machine datatype
	init, 
	idle, 
	cmd_read, 	 
	cmd_wp_off, 
	cmd_write_en,
	cmd_erase_block,
	cmd_write, 
	cmd_check_status, 
	cmd_write_dis, 
	cmd_wp_on
					 
);

signal state 			: machine := init; -- current state
signal next_state 	: machine := init; -- state to return after some operations

signal is_busy : std_logic := '1';
signal is_ready : std_logic := '0';

begin
	
-- SPI FLASH 25MHz 
U1: entity work.spi_master
generic map (
	slaves 	=> 1,
	d_width 	=> 8
)
port map (
	clock 	=> CLK, 
	reset_n 	=> not(RESET),
	enable 	=> spi_ena,
	cpol		=> '0', -- spi mode 0
	cpha 		=> '0',
	cont 		=> spi_cont,
	clk_div 	=> 1, --2, -- CLK divider
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
VARIABLE count : INTEGER := 0;
begin
	if RESET = '1' then
		spi_ena <= '0';
		spi_cont <= '0';
		spi_di_bus <= (others => '0');
		count := 0;
		state <= init;
		is_busy <= '1';
		is_ready <= '0';

	elsif CLK'event and CLK = '1' then
		
		case state is 
			
			when init => -- power on command
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						spi_ena <= '1';
						spi_di_bus <= SPI_CMD_POWERON;
					when 1 => 
						spi_ena <= '0';
					when 2 =>
						count := 0;
						state <= idle;
					when others => null;
				end case;
				
			when idle => -- ready to begin read / write cycle
				is_busy <= '0';
				spi_ena <= '0';
				spi_cont <= '0';
				count := 0;
				spi_busy_prev <= '0';
				prev_wr_n <= WR_N;
				prev_rd_n <= RD_N;
				prev_er_n <= ER_N;
				
				if (RD_N = '0') then 
					state <= cmd_read;
				elsif (WR_N = '0' and prev_wr_n = '1') then 
					state <= cmd_write_en;
					next_state <= cmd_write;
				elsif (ER_N = '0' and prev_er_n = '1') then
					state <= cmd_write_en;
					next_state <= cmd_erase_block;
				end if;
			
			when cmd_read => -- read command
				is_busy <= '1';
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						if (spi_busy = '0') then 
							spi_cont <= '1';
							spi_ena <= '1';
							is_ready <= '0';
							spi_di_bus <= SPI_CMD_READ;
						else
							spi_di_bus <= A(23 downto 16);
						end if;
					when 1 => 
						spi_di_bus <= A(15 downto 8);
					when 2 => 
						spi_di_bus <= A(7 downto 0);
					when 3 => 
						spi_di_bus <= "00000000";
					when 4 =>
						spi_cont <= '0';
						spi_ena <= '0';
					when 5 =>
						count := 0;
						is_ready <= '1';
						DO <= spi_do_bus;
						state <= idle;
					when others => null;						
				end case;
				
			when cmd_write_en => -- write enable
				is_busy <= '1';
				is_ready <= '0';
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						spi_ena <= '1';
						spi_cont <= '0';
						spi_di_bus <= SPI_CMD_WRITE_EN;
					when 1 => 
						spi_ena <= '0';
					when 2 =>
						count := 0;
						state <= next_state;
					when others => null;
				end case;
				
			when cmd_erase_block => -- erase 64k block command
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						if (spi_busy = '0') then 
							spi_cont <= '1';
							spi_ena <= '1';
							spi_di_bus <= SPI_CMD_BLOCK_ERASE;
						else
							spi_di_bus <= A(23 downto 16);
						end if;
					when 1 => 
						spi_di_bus <= A(15 downto 8);
					when 2 => 
						spi_di_bus <= A(7 downto 0);
					when 3 =>
						spi_cont <= '0';
						spi_ena <= '0';
					when 4 =>
						count := 0;
						state <= cmd_check_status;
						next_state <= cmd_write_dis;
					when others => null;					
				end case;
				
			when cmd_write => -- write command
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						if (spi_busy = '0') then 
							spi_cont <= '1';
							spi_ena <= '1';
							spi_di_bus <= SPI_CMD_PAGEPRG;
						else
							spi_di_bus <= A(23 downto 16);
						end if;
					when 1 => 
						spi_di_bus <= A(15 downto 8);
					when 2 => 
						spi_di_bus <= A(7 downto 0);
					when 3 => 
						spi_di_bus <= DI;
					when 4 =>
						spi_cont <= '0';
						spi_ena <= '0';
					when 5 =>
						count := 0;
						state <= cmd_check_status;
						next_state <= cmd_write_dis;
					when others => null;						
				end case;
				
			when cmd_check_status => -- check status (after write or erase)
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						if (spi_busy = '0') then 
							spi_cont <= '1';
							spi_ena <= '1';
							is_ready <= '0';
							spi_di_bus <= SPI_CMD_STATUSREG;
						else
							spi_di_bus <= "00000000";
						end if;
					when 1 => 
						spi_cont <= '0';
						spi_ena <= '0';
					when 2 =>
						count := 0;
						if spi_do_bus(0) = '1' then 
							state <= cmd_check_status;
						else 
							state <= next_state;
						end if;
					when others => null;
				end case;
				
			when cmd_write_dis => -- write disable
				spi_busy_prev <= spi_busy;
				if (spi_busy_prev = '1' and spi_busy = '0') then 
					count := count + 1;
				end if;
				case count is 
					when 0 => 
						spi_ena <= '1';
						spi_cont <= '0';
						spi_di_bus <= SPI_CMD_WRITE_DIS;
					when 1 => 
						spi_ena <= '0';
					when 2 =>
						count := 0;
						state <= idle;
					when others => null;
				end case;
				
			when others => null;
			
		end case;
	
	end if;
end process;

BUSY <= is_busy;
DATA_READY <= is_ready;

end rtl;