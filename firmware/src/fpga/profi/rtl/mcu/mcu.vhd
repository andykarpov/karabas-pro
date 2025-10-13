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
	 CLK			 : in std_logic;
	 RESET 	         : in std_logic;

	 -- spi
    MCU_MOSI    : in std_logic;
    MCU_MISO    : out std_logic := 'Z';
    MCU_SCK     : in std_logic;
	 MCU_CS_N 		 : in std_logic;

	 -- usb mouse
	 MS_X 	 	: out std_logic_vector(7 downto 0) := "00000000";
	 MS_Y 	 	: out std_logic_vector(7 downto 0) := "00000000";
	 MS_B 	   : out std_logic_vector(2 downto 0) := "000";
	 MS_Z 		: out std_logic_vector(3 downto 0) := "0000";
	 MS_UPD		: buffer std_logic := '0'; -- todo: refactor it, move ms event to abs coord into a new module "cursor"
	 
	 -- usb keyboard
	 KB_STATUS : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT0   : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT1   : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT2   : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT3   : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT4   : out std_logic_vector(7 downto 0) := "00000000";
	 KB_DAT5   : out std_logic_vector(7 downto 0) := "00000000";
	 
	 -- ps/2 scancode
	 KB_SCANCODE : out std_logic_vector(7 downto 0) := "00000000";
	 KB_SCANCODE_UPD : buffer std_logic := '0';

	 -- xt scancode (simplified)
	 XT_SCANCODE : out std_logic_vector(7 downto 0) := "00000000";
	 XT_SCANCODE_UPD : buffer std_logic := '0';

	 -- joysticks
	 JOYSTICK	: out std_logic_vector(12 downto 0) := "0000000000000";

    -- rtc	 
	 RTC_A 		: in std_logic_vector(7 downto 0);
	 RTC_DI 		: in std_logic_vector(7 downto 0);
	 RTC_DO 		: out std_logic_vector(7 downto 0);
	 RTC_CS 		: in std_logic := '0';
	 RTC_WR_N 	: in std_logic := '1';
	 
	 -- usb uart
	 USB_UART_RX_DATA			: out std_logic_vector(7 downto 0);
	 USB_UART_RX_IDX	: out std_logic_vector(7 downto 0) := (others => '0');	 
	 USB_UART_TX_DATA			: in std_logic_vector(7 downto 0);
	 USB_UART_TX_WR				: in std_logic := '0';
	 USB_UART_TX_MODE 			: in std_logic := '0'; -- 0 = zifi data @ 115200, 1 = evo rs232 data @ dll/dlm speed
	 
	 -- evo rs232 dlm/dll registers
	 USB_UART_DLM : in std_logic_vector(7 downto 0);
	 USB_UART_DLL : in std_logic_vector(7 downto 0);
	 USB_UART_DLM_WR : in std_logic;
	 USB_UART_DLL_WR : in std_logic;

	 -- esp uart
	 ESP_UART_RX_DATA			: out std_logic_vector(7 downto 0);
	 ESP_UART_RX_IDX	: out std_logic_vector(7 downto 0) := (others => '0');	 
	 ESP_UART_TX_DATA			: in std_logic_vector(7 downto 0);
	 ESP_UART_TX_WR				: in std_logic := '0';
	 
	 -- soft switches command
	 SOFTSW_COMMAND : out std_logic_vector(15 downto 0);

    -- osd command
	 OSD_COMMAND: out std_logic_vector(15 downto 0);
	 
	 -- rom loader
	 ROMLOADER_ACTIVE : buffer std_logic := '0';
	 ROMLOAD_ADDR: buffer std_logic_vector(31 downto 0) := x"FFFFFFFF";
	 ROMLOAD_DATA: out std_logic_vector(7 downto 0) := (others => '0');
	 ROMLOAD_WR : out std_logic := '0';

     FLASH_A : in std_logic_vector(31 downto 0);
     FLASH_DI : in std_logic_vector(7 downto 0);
     FLASH_DO : out std_logic_vector(7 downto 0);
     FLASH_RD_N : in std_logic := '1';
     FLASH_WR_N : in std_logic := '1';
     FLASH_ER_N : in std_logic := '1';
     FLASH_BUSY : out std_logic;
     FLASH_READY : out std_logic;

	 -- debug
	 DEBUG_ADDR : in std_logic_vector(15 downto 0) := (others => '0');
	 DEBUG_DATA : in std_logic_vector(15 downto 0) := (others => '0');
	 
	 -- busy
	 BUSY: buffer std_logic := '1'
	 
	);
    end mcu;
architecture rtl of mcu is

	-- spi commands
	constant CMD_KBD		: std_logic_vector(7 downto 0) := x"01";
	constant CMD_MOUSE 		: std_logic_vector(7 downto 0) := x"02";
	constant CMD_JOY   		: std_logic_vector(7 downto 0) := x"03";
	constant CMD_BTNS		: std_logic_vector(7 downto 0) := x"04";
	constant CMD_SWITCHES   : std_logic_vector(7 downto 0) := x"05";
	constant CMD_ROMBANK    : std_logic_vector(7 downto 0) := x"06";
	constant CMD_ROMDATA    : std_logic_vector(7 downto 0) := x"07";
	constant CMD_ROMLOADER  : std_logic_vector(7 downto 0) := x"08";
	constant CMD_PS2_SCANCODE : std_logic_vector(7 downto 0) := x"0B";

	constant CMD_OSD 		: std_logic_vector(7 downto 0) := x"20";
	constant CMD_DEBUG_ADDR : std_logic_vector(7 downto 0) := x"30";
	constant CMD_DEBUG_DATA : std_logic_vector(7 downto 0) := x"31";	
	constant CMD_FLASH    	: std_logic_vector(7 downto 0) := x"f9";
	constant CMD_RTC 			: std_logic_vector(7 downto 0) := x"FA";
	constant CMD_ESP_UART   : std_logic_vector(7 downto 0) := x"FB";
	constant CMD_USB_UART	: std_logic_vector(7 downto 0) := x"FC";
	constant CMD_INIT_START	: std_logic_vector(7 downto 0) := x"FD";
	constant CMD_INIT_DONE	: std_logic_vector(7 downto 0) := x"FE";	
	constant CMD_NOPE			: std_logic_vector(7 downto 0) := x"FF";

	 -- spi
	 signal spi_do_valid 	: std_logic := '0';
	 signal spi_di 			: std_logic_vector(23 downto 0);
	 signal spi_do 			: std_logic_vector(23 downto 0);
	 signal spi_di_req 		: std_logic;
	 signal prev_spi_di_req : std_logic := '0';
	 signal spi_miso 		 	: std_logic;
	 
	 -- rtc 2-port ram signals
	 signal rtcw_di 			: std_logic_vector(7 downto 0);
	 signal rtcw_a 			: std_logic_vector(7 downto 0);
	 signal rtcw_wr 			: std_logic := '0';
	 signal rtcr_do 			: std_logic_vector(7 downto 0);

	-- rtc data from mcu
	 signal rtcr_a 			: std_logic_vector(7 downto 0);
	 signal rtcr_d 			: std_logic_vector(7 downto 0);
	 signal last_rtcr_a 		: std_logic_vector(7 downto 0);
	 signal last_rtcr_d 		: std_logic_vector(7 downto 0);
	 signal rtcr_command    : std_logic := '0';
	 signal last_rtcr_command : std_logic := '0';
	 
	 -- romload addr
	 signal tmp_romload_addr    : std_logic_vector(31 downto 0);
	 signal prev_romload_addr   : std_logic_vector(31 downto 0) := x"FFFFFFFF";
	 
	-- spi fifo 
	signal queue_di			: std_logic_vector(23 downto 0);
	signal queue_wr_req		: std_logic := '0';
	signal queue_wr_full		: std_logic;
		
	signal queue_rd_req		: std_logic := '0';
	signal queue_do			: std_logic_vector(23 downto 0);
	signal queue_rd_empty   : std_logic;
	
	--state machine for queue writes
	type qmachine IS(idle, rtc_wr_req, rtc_wr_ack);
	signal qstate : qmachine := idle;
	
	-- debug
	signal prev_debug_addr  : std_logic_vector(15 downto 0) := (others => '0');
	signal prev_debug_data  : std_logic_vector(15 downto 0) := (others => '0');

    signal prev_flash_a : std_logic_vector(31 downto 0) := (others => '1');
    signal prev_flash_wr_n : std_logic := '1';
    signal prev_flash_rd_n : std_logic := '1';
    signal prev_flash_er_n : std_logic := '1';
		 
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
		  spi_ssel_i     => MCU_CS_N,
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

	spi_di <= queue_do;
	
	MCU_MISO <= spi_miso when MCU_CS_N = '0' else '1';
	
	-- pull queue data  
	process (CLK)
	begin 
		if rising_edge(CLK) then 
			queue_rd_req <= '0';
			if (spi_di_req = '1' and prev_spi_di_req = '0') then 
				queue_rd_req <= '1';
			end if;
			prev_spi_di_req <= spi_di_req;
		end if;
	end process;

	process (CLK)
	begin
		if (rising_edge(CLK)) then
		
			if spi_do_valid = '1' then
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
					-- mouse data
					when CMD_MOUSE => 
						case spi_do(15 downto 8) is
							when X"00" => MS_X(7 downto 0) <= spi_do(7 downto 0);
							when X"01" => MS_Y(7 downto 0) <= spi_do(7 downto 0);
							when X"02" => MS_Z(3 downto 0) <= spi_do(3 downto 0);
							when X"03" => MS_B(2 downto 0) <= spi_do(2 downto 0); MS_UPD <= not(MS_UPD);
							when others => null;
						end case;
					-- joy data
					when CMD_JOY => 
						case spi_do(15 downto 8) is
							-- joy L
							when x"00" =>
									  joystick(0) <= spi_do(0); -- ON
									  joystick(1) <= spi_do(1); -- UP 
									  joystick(2) <= spi_do(2); -- DOWN 
									  joystick(3) <= spi_do(3); -- LEFT
									  joystick(4) <= spi_do(4); -- RIGHT
									  joystick(5) <= spi_do(5); -- START
									  joystick(6) <= spi_do(6); -- A
									  joystick(7) <= spi_do(7); -- B
							when x"01" =>
									  joystick(8) <= spi_do(0); -- C 
									  joystick(9) <= spi_do(1); -- X 
									  joystick(10) <= spi_do(2); -- Y 
									  joystick(11) <= spi_do(3); -- Z
									  joystick(12) <= spi_do(4); -- MODE
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
							
					-- rtc 
					when CMD_RTC =>						
						rtcr_a <= spi_do(15 downto 8);
						rtcr_d <= spi_do(7 downto 0);
						rtcr_command <= not rtcr_command;
						
					-- uart
					when CMD_USB_UART =>
						USB_UART_RX_DATA <= spi_do(7 downto 0);
						USB_UART_RX_IDX <= spi_do(15 downto 8);

					when CMD_ESP_UART =>
					   ESP_UART_RX_DATA <= spi_do(7 downto 0);
					   ESP_UART_RX_IDX <= spi_do(15 downto 8);

				   -- flash emu
				   when CMD_FLASH => 
						FLASH_BUSY <= spi_do(8);
						FLASH_READY <= spi_do(9);
						FLASH_DO <= spi_do(7 downto 0);
					
					-- ps/2 scancode from mcu
					when CMD_PS2_SCANCODE => 
						case spi_do(15 downto 8) is
							when x"00" => KB_SCANCODE <= spi_do(7 downto 0); KB_SCANCODE_UPD <= not(KB_SCANCODE_UPD);
							when x"01" => XT_SCANCODE <= spi_do(7 downto 0); XT_SCANCODE_UPD <= not(XT_SCANCODE_UPD);
							when others => null;
						end case;

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

	--------------------------------------------------------------------------
	-- mc146818a emulation	
	-- http://web.stanford.edu/class/cs140/projects/pintos/specs/mc146818a.pdf
	--------------------------------------------------------------------------
	-- 
	-- 000000 = 00 = Seconds       bin/bcd (0-59)
	-- 000001 = 01 = Seconds Alarm bin/bcd (0-59)
	-- 000010 = 02 = Minutes       bin/bcd (0-59)
	-- 000011 = 03 = Minutes Alarm bin/bcd (0-59)
	-- 000100 = 04 = Hours         bin/bcd (1-12 or 0-23)
   -- 000101 = 05 = Hours Alarm   bin/bcd (1-12 or 0-23)
   -- 000110 = 06 = Day of Week   bin/bcd (1-7, sunday = 1)
   -- 000111 = 07 = Date of Month bin/bcd (1-31)
   -- 001000 = 08 = Month         bin/bcd (1-12)
	-- 001001 = 09 = Year          bin/bcd (0-99)
	-- 001010 = 0A = Register A RW 7-UIP, 6-DV2, 5-DV1, 4-DV0, 3-RS3, 2-RS2, 1-RS1, 0-RS0. (uip = update in progress, dv-dividers, rs-rate selection)
	-- 001011 = 0B = Register B RW 7-SET, 6-PIE, 5-AIE, 4-UIE, 3-SQWE, 2-DM, 1-24/12. 0-DSE (SET=update mode,PIE=int en,AIE=alarm int en,UIE=update int en, SQWE, DM 1=bcd, 0=bin, 24/12 1=24,0=12, DSE=daylight saving mode 1/0)
	-- 001100 = 0C = Register C RO 7-IRFQ, 6-PF, 5-AF, 4-UF, 0000
	-- 001101 = 0D = Register D RO 7-VRT, 0000000 (VRT = valid ram and time)
	-- 001110 = 0E = Register E - memory, 50 bytes
	-- ...
	-- 011111 = 3F = Register 3F
	
	-- memory for rtc registers
    URTC: entity work.rtc
    port map(
	    wrclock => CLK,
	    data => rtcw_di,
	    wraddress => rtcw_a,
	    wren => rtcw_wr,		
	    rdclock => CLK,
	    rdaddress => rtc_a,
	    q => rtcr_do
    );
	RTC_DO <= rtcr_do;
	
	-- fifo for write commands to send them on mcu side 
	UFIFO: entity work.queue
    port map(
	    data => queue_di,
	    wrreq => queue_wr_req,
	    wrclk => CLK,
	    wrfull => queue_wr_full,
	    wrusedw => open,
		    
	    rdreq => queue_rd_req,
	    rdclk => CLK, 
	    q => queue_do,
	    rdempty => queue_rd_empty,
	    rdusedw => open
    );
	
	-- fifo handling / queue commands to mcu side
	process(CLK)
	begin
		if rising_edge(CLK) then
			queue_wr_req <= '0';
	        prev_flash_wr_n <= flash_wr_n;
	        prev_flash_rd_n <= flash_rd_n;
	        prev_flash_er_n <= flash_er_n;
--			if USB_UART_TX_WR = '1' then -- send USB UART byte
--				queue_wr_req <= '1';
--				if (USB_UART_TX_MODE = '1') then
--					queue_di <= CMD_USB_UART & "00000011" & USB_UART_TX_DATA;
--				else 
--					queue_di <= CMD_USB_UART & "00000000" & USB_UART_TX_DATA;
--				end if;
--			elsif ESP_UART_TX_WR = '1' then -- send ESP UART byte
--				queue_wr_req <= '1';
--				queue_di <= CMD_ESP_UART & "00000000" & ESP_UART_TX_DATA;
--			elsif USB_UART_DLL_WR = '1' then -- send USB UART DLL reg
--				queue_wr_req <= '1';
--				queue_di <= CMD_USB_UART & "00000001" & USB_UART_DLL;
--			elsif USB_UART_DLM_WR = '1' then -- send USB UART RLM reg
--				queue_wr_req <= '1';
--				queue_di <= CMD_USB_UART & "00000010" & USB_UART_DLM;
			if RTC_WR_N = '0' AND RTC_CS = '1' and BUSY = '0' and (RTC_A /= x"0C" and RTC_A < x"F0") then -- add rtc register write to queue
				queue_wr_req <= '1';
				queue_di <= CMD_RTC & RTC_A & RTC_DI;

--	        elsif flash_a(31 downto 24) /= prev_flash_a(31 downto 24) then
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000000" & flash_a(31 downto 24); 
--                prev_flash_a(31 downto 24) <= flash_a(31 downto 24);
--	        elsif flash_a(23 downto 16) /= prev_flash_a(23 downto 16) then
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000001" & flash_a(23 downto 16); 
--                prev_flash_a(23 downto 16) <= flash_a(23 downto 16);
--	        elsif flash_a(15 downto 8) /= prev_flash_a(15 downto 8) then
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000010" & flash_a(15 downto 8); 
--                prev_flash_a(15 downto 8) <= flash_a(15 downto 8);
--	        elsif flash_a(7 downto 0) /= prev_flash_a(7 downto 0) then
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000011" & flash_a(7 downto 0); 
--                prev_flash_a(7 downto 0) <= flash_a(7 downto 0);
--            elsif flash_wr_n = '0' and prev_flash_wr_n = '1' then 
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000100" & flash_di(7 downto 0); 
--            elsif flash_rd_n = '0' and prev_flash_rd_n = '1' then 
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000101" & "00000000"; 
--            elsif flash_er_n = '0' and prev_flash_er_n = '1' then 
--                queue_wr_req <= '1'; 
--                queue_di <= CMD_FLASH & "00000110" & "00000000"; 

			elsif DEBUG_ADDR /= prev_debug_addr then -- debug address
				queue_wr_req <= '1';
				queue_di <= CMD_DEBUG_ADDR & DEBUG_ADDR;
				prev_debug_addr <= DEBUG_ADDR;
			elsif DEBUG_DATA /= prev_debug_data then -- debug data
				queue_wr_req <= '1';
				queue_di <= CMD_DEBUG_DATA & DEBUG_DATA;
				prev_debug_data <= DEBUG_DATA;
			elsif queue_rd_empty = '1' then -- anti-empty queue
				queue_wr_req <= '1';
				queue_di <= CMD_NOPE & x"0000";
			end if;
						
		end if;
	end process;
	
	-- write RTC registers into ram from host / mcu
	process (CLK) 
	begin 
		if rising_edge(CLK) then
			rtcw_wr <= '0';
			if RTC_WR_N = '0' AND RTC_CS = '1' and BUSY = '0' then
				-- rtc mem write by host
				rtcw_wr <= '1';
				rtcw_a <= RTC_A;
				rtcw_di <= RTC_DI;
			elsif last_rtcr_command /= rtcr_command then
				-- rtc mem write by mcu
				rtcw_wr <= '1';
				rtcw_a <= rtcr_a;
				rtcw_di <= rtcr_d;
				last_rtcr_command <= rtcr_command;
			end if;
		end if;
	end process;

end RTL;

