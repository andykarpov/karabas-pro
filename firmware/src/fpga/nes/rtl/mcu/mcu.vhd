-------------------------------------------------------------------------------
-- MCU SPI comm module
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity mcu is
	port
	(
	 CLK		 : in std_logic;
	 N_RESET 	 : in std_logic := '1';

	 -- spi
	MCU_MOSI	 : in std_logic;
	MCU_MISO	 : out std_logic := '1';
	MCU_SCK		 : in std_logic;
	 MCU_SS 	 : in std_logic;
	 MCU_SPI_SD2_SS	 : in std_logic;

	 -- usb keyboard
	 KB_STATUS	 : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT0	 : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT1	 : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT2	 : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT3	 : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT4	 : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT5	 : out std_logic_vector(7 downto 0) := "00000000";

	 -- joysticks
	 JOY_L		 : out std_logic_vector(12 downto 0) := "0000000000000";
	 JOY_R		 : out std_logic_vector(12 downto 0) := "0000000000000";

	 -- soft switches command
	 SOFTSW_COMMAND	 : out std_logic_vector(15 downto 0);

    -- osd command
	 OSD_COMMAND	 : out std_logic_vector(15 downto 0);

	 -- rom loader
	 ROMLOADER_ACTIVE: buffer std_logic := '0';
	 ROMLOAD_ADDR	 : buffer std_logic_vector(31 downto 0) := x"FFFFFFFF";
	 ROMLOAD_DATA	 : out std_logic_vector(7 downto 0) := (others => '0');
	 ROMLOAD_WR	 : out std_logic := '0';

	 -- file loader
	 FILELOAD_RESET	 : buffer std_logic := '0';
	 FILELOAD_ADDR	 : buffer std_logic_vector(31 downto 0) := x"FFFFFFFF";
	 FILELOAD_DATA	 : out std_logic_vector(7 downto 0) := (others => '0');
	 FILELOAD_WR	 : out std_logic := '0';

	 -- sd2 exclusive access by mcu
	 SD2_SCK	 : out std_logic := '1';
	 SD2_MOSI	 : out std_logic := '1';
	 SD2_MISO	 : in  std_logic := '1';
	 SD2_CS_N	 : out std_logic := '1';

	 -- busy
	 BUSY: buffer std_logic := '1'

	);
    end mcu;
architecture rtl of mcu is

	-- spi commands
	constant CMD_KBD        : std_logic_vector(7 downto 0) := x"01";
	constant CMD_JOY        : std_logic_vector(7 downto 0) := x"03";
	constant CMD_BTNS       : std_logic_vector(7 downto 0) := x"04";
	constant CMD_SWITCHES   : std_logic_vector(7 downto 0) := x"05";
	
	constant CMD_ROMBANK    : std_logic_vector(7 downto 0) := x"06";
	constant CMD_ROMDATA    : std_logic_vector(7 downto 0) := x"07";
	constant CMD_ROMLOADER  : std_logic_vector(7 downto 0) := x"08";
	
	constant CMD_FILEBANK   : std_logic_vector(7 downto 0) := x"0C";
	constant CMD_FILEDATA   : std_logic_vector(7 downto 0) := x"0D";
	constant CMD_FILELOADER : std_logic_vector(7 downto 0) := x"0E";

	constant CMD_OSD        : std_logic_vector(7 downto 0) := x"20";

	constant CMD_INIT_START : std_logic_vector(7 downto 0) := x"FD";
	constant CMD_INIT_DONE  : std_logic_vector(7 downto 0) := x"FE";
	constant CMD_NOPE       : std_logic_vector(7 downto 0) := x"FF";

	 -- spi
	 signal spi_do_valid 	: std_logic := '0';
	 signal prev_spi_do_valid : std_logic := '0';
	 signal spi_di 		: std_logic_vector(23 downto 0);
	 signal spi_do 		: std_logic_vector(23 downto 0);
	 signal spi_di_req 	: std_logic;
	 signal prev_spi_di_req : std_logic := '0';
	 signal spi_miso 	: std_logic;

	 -- romload addr
	 signal tmp_romload_addr    : std_logic_vector(31 downto 0);
	 signal prev_romload_addr   : std_logic_vector(31 downto 0) := x"FFFFFFFF";

	 -- file addr
	 signal tmp_fileload_addr   : std_logic_vector(31 downto 0);
	 signal prev_fileload_addr  : std_logic_vector(31 downto 0) := x"FFFFFFFF";

	--state machine for queue writes
	type qmachine IS(idle, rtc_wr_req, rtc_wr_ack);
	signal qstate : qmachine := idle;

begin

	--------------------------------------------------------------------------
	-- MCU SPI communication
	--------------------------------------------------------------------------

	U_SPI: entity work.spi_slave
	generic map(
			N             => 24 -- 3 bytes (cmd + addr + data)
	 )
	port map(
		  clk_i          => CLK,
		  spi_sck_i      => MCU_SCK,
		  spi_ssel_i     => MCU_SS,
		  spi_mosi_i     => MCU_MOSI,
		  spi_miso_o     => spi_miso,

		  di_req_o       => spi_di_req,
		  di_i           => spi_di,
		  wren_i         => '1',
		  
		  do_valid_o     => spi_do_valid,
		  do_o           => spi_do,

		  do_transfer_o  => open,
		  wren_o         => open,
		  wren_ack_o     => open,
		  rx_bit_reg_o   => open,
		  state_dbg_o    => open
	);

	spi_di <= CMD_NOPE & x"0000";
	
	MCU_MISO <= 
		SD2_MISO when MCU_SPI_SD2_SS = '0' else
		spi_miso when MCU_SS = '0' else 
		'1';
	
	SD2_SCK <= MCU_SCK;
	SD2_CS_N <= MCU_SPI_SD2_SS;
	SD2_MOSI <= MCU_MOSI;
	
	process (CLK)
	begin
		if (rising_edge(CLK)) then
			prev_spi_do_valid <= spi_do_valid;
			if spi_do_valid = '1' and prev_spi_do_valid = '0' then
				case spi_do(23 downto 16) is 
					-- keyboard
					when CMD_KBD => 
						case spi_do(15 downto 8) is 
							when X"00" => kb_status <= spi_do(7 downto 0);
							when X"01" => kb_dat0 <= spi_do(7 downto 0);
							when X"02" => kb_dat1 <= spi_do(7 downto 0);
							when X"03" => kb_dat2 <= spi_do(7 downto 0);
							when X"04" => kb_dat3 <= spi_do(7 downto 0);
							when X"05" => kb_dat4 <= spi_do(7 downto 0);
							when X"06" => kb_dat5 <= spi_do(7 downto 0);
							when others => null;
						end case;
					-- joy data
					when CMD_JOY => 
						case spi_do(15 downto 8) is
							-- joy L
							when x"00" =>
									  joy_l(0) <= spi_do(0); -- ON
									  joy_l(1) <= spi_do(1); -- UP 
									  joy_l(2) <= spi_do(2); -- DOWN 
									  joy_l(3) <= spi_do(3); -- LEFT
									  joy_l(4) <= spi_do(4); -- RIGHT
									  joy_l(5) <= spi_do(5); -- START
									  joy_l(6) <= spi_do(6); -- A
									  joy_l(7) <= spi_do(7); -- B
							when x"01" =>
									  joy_l(8) <= spi_do(0); -- C 
									  joy_l(9) <= spi_do(1); -- X 
									  joy_l(10) <= spi_do(2); -- Y 
									  joy_l(11) <= spi_do(3); -- Z
									  joy_l(12) <= spi_do(4); -- MODE

							-- joy R
							when x"02" =>
									  joy_r(0) <= spi_do(0); -- ON
									  joy_r(1) <= spi_do(1); -- UP 
									  joy_r(2) <= spi_do(2); -- DOWN 
									  joy_r(3) <= spi_do(3); -- LEFT
									  joy_r(4) <= spi_do(4); -- RIGHT
									  joy_r(5) <= spi_do(5); -- START
									  joy_r(6) <= spi_do(6); -- A
									  joy_r(7) <= spi_do(7); -- B
							when x"03" =>
									  joy_r(8) <= spi_do(0); -- C 
									  joy_r(9) <= spi_do(1); -- X 
									  joy_r(10) <= spi_do(2); -- Y 
									  joy_r(11) <= spi_do(3); -- Z
									  joy_r(12) <= spi_do(4); -- MODE
							when others => null;
						end case;

					-- soft switches
					when CMD_SWITCHES => SOFTSW_COMMAND <= spi_do(15 downto 0);
							
					-- osd commands					
					when CMD_OSD => OSD_COMMAND <= spi_do(15 downto 0);
					
					-- rombank
					when CMD_ROMBANK => 
						case spi_do(15 downto 8) is
							when x"00" => tmp_romload_addr(15 downto 8) <= spi_do(7 downto 0);
							when x"01" => tmp_romload_addr(23 downto 16) <= spi_do(7 downto 0);
							when x"02" => tmp_romload_addr(31 downto 24) <= spi_do(7 downto 0);
							when others => null;
						end case;
						
					-- romdata
					when CMD_ROMDATA => 
						ROMLOAD_ADDR(31 downto 8) <= tmp_romload_addr(31 downto 8);
						ROMLOAD_ADDR(7 downto 0) <= spi_do(15 downto 8);
						ROMLOAD_DATA(7 downto 0) <= spi_do(7 downto 0);
						
					when CMD_ROMLOADER =>
						ROMLOADER_ACTIVE <= spi_do(0);
						
					-- filebank
					when CMD_FILEBANK => 
						case spi_do(15 downto 8) is
							when x"00" => tmp_fileload_addr(15 downto 8) <= spi_do(7 downto 0);
							when x"01" => tmp_fileload_addr(23 downto 16) <= spi_do(7 downto 0);
							when x"02" => tmp_fileload_addr(31 downto 24) <= spi_do(7 downto 0);
							when others => null;
						end case;
						
					-- filedata
					when CMD_FILEDATA => 
						FILELOAD_ADDR(31 downto 8) <= tmp_fileload_addr(31 downto 8);
						FILELOAD_ADDR(7 downto 0) <= spi_do(15 downto 8);
						FILELOAD_DATA(7 downto 0) <= spi_do(7 downto 0);
						
					when CMD_FILELOADER =>
						FILELOAD_RESET <= spi_do(0);

					-- init start
					when CMD_INIT_START => BUSY <= '1';

					-- init done
					when CMD_INIT_DONE => BUSY <= '0';

					-- nope
					when CMD_NOPE => null;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	-- romload wr signal
	process (CLK)
	begin
		if rising_edge(CLK) then 
			ROMLOAD_WR <= '0';
			if (prev_romload_addr /= ROMLOAD_ADDR and ROMLOADER_ACTIVE = '1') then 
				ROMLOAD_WR <= '1';
				prev_romload_addr <= ROMLOAD_ADDR;
			end if;
		end if;
	end process;
	
	-- fileload wr signal
	process (CLK)
	begin
		if rising_edge(CLK) then 
			FILELOAD_WR <= '0';
			if (prev_fileload_addr /= FILELOAD_ADDR) then 
				FILELOAD_WR <= '1';
				prev_fileload_addr <= FILELOAD_ADDR;
			end if;
		end if;
	end process;
	
end RTL;

