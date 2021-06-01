-------------------------------------------------------------------------------
-- AVR SPI comm module
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity avr is
	port
	(
	 CLK			 : in std_logic;
	 CLKEN 		 : in std_logic;
	 N_RESET 	 : in std_logic := '1';
    A           : in std_logic_vector(15 downto 8);     -- address bus for kbd
    KB          : out std_logic_vector(5 downto 0) := "111111";     -- data bus for kbd + extended bit (b6)
    AVR_MOSI    : in std_logic;
    AVR_MISO    : out std_logic := 'Z';
    AVR_SCK     : in std_logic;
	 AVR_SS 		 : in std_logic;
	 
	 MS_X 	 	: out std_logic_vector(7 downto 0) := "00000000";
	 MS_Y 	 	: out std_logic_vector(7 downto 0) := "00000000";
	 MS_BTNS 	 	: out std_logic_vector(2 downto 0) := "000";
	 MS_Z 		: out std_logic_vector(3 downto 0) := "0000";
	 MS_PRESET  : out std_logic := '0';
	 MS_EVENT 	: out std_logic;
	 MS_DELTA_X : out signed(7 downto 0) := "00000000";
	 MS_DELTA_Y : out signed(7 downto 0) := "00000000";
	 
	 RTC_A 		: in std_logic_vector(5 downto 0);
	 RTC_DI 		: in std_logic_vector(7 downto 0);
	 RTC_DO 		: out std_logic_vector(7 downto 0);
	 RTC_CS 		: in std_logic := '0';
	 RTC_WR_N 	: in std_logic := '1';
	 
	 INIT 		: in std_logic := '0';
	 
	 LED1			: in std_logic := '0';
	 LED2 		: in std_logic := '0';
	 LED1_OWR	: in std_logic := '0';
	 LED2_OWR 	: in std_logic := '0';
	 
	 CFG 			: in std_logic_vector(7 downto 0);
	 
	 SOFT_SW 	: out std_logic_vector(1 to 10) := (others => '0');
	 
	 KB_MODE 	: out std_logic := '0';
	 
	 KB_SCANCODE: out std_logic_vector(9 downto 0);
	 
	 RESET		: out std_logic := '0';
	 TURBO		: out std_logic := '0';
	 MAGICK		: out std_logic := '0';
	 WAIT_CPU 	: out std_logic := '0';
	 JOY_TYPE 	: out std_logic := '0';
	 
	 LOADED 		: out std_logic := '0';
	 	 
	 JOY			: out std_logic_vector(7 downto 0) := "00000000"
	 
	);
    end avr;
architecture RTL of avr is

	 -- keyboard state
	 signal kb_data_tmp 		: std_logic_vector(39 downto 0) := (others => '0');
	 signal kb_data 			: std_logic_vector(40 downto 0) := (others => '0'); -- 40 keys + bit6
	 signal ms_flag 			: std_logic := '0';
	 
	 -- mouse
	 signal mouse_x 			: signed(7 downto 0) := "00000000";
	 signal mouse_y 			: signed(7 downto 0) := "00000000";
	 signal mouse_z 			: signed(3 downto 0) := "0000";
	 signal buttons   		: std_logic_vector(2 downto 0) := "000";
	 signal newPacket 		: std_logic := '0';

	 signal currentX 			: unsigned(7 downto 0);
	 signal currentY 			: unsigned(7 downto 0);
	 signal cursorX 			: signed(7 downto 0) := X"7F";
	 signal cursorY 			: signed(7 downto 0) := X"7F";
	 signal deltaX				: signed(8 downto 0);
	 signal deltaY				: signed(8 downto 0);
	 signal deltaZ				: signed(3 downto 0);
	 signal trigger 			: std_logic := '0';
	 
	 -- spi
	 signal spi_do_valid 	: std_logic := '0';
	 signal spi_di 			: std_logic_vector(15 downto 0);
	 signal spi_do 			: std_logic_vector(15 downto 0);
	 signal spi_di_req 		: std_logic;
	 signal spi_miso 		 	: std_logic;
	 
	 -- rtc rx spi data
	 signal rtc_cmd 			: std_logic_vector(7 downto 0);  -- spi cmd
	 signal rtc_data 			: std_logic_vector(7 downto 0); -- spi data 
	 
	 -- rtc 2-port ram signals
	 signal rtcw_di 			: std_logic_vector(7 downto 0);
	 signal rtcw_a 			: std_logic_vector(5 downto 0);
	 signal rtcw_wr 			: std_logic := '0';
	 signal rtcr_do 			: std_logic_vector(7 downto 0);
	
	-- rtc fifo 
	signal queue_di			: std_logic_vector(15 downto 0);
	signal queue_wr_req		: std_logic := '0';
	signal queue_wr_full		: std_logic;
		
	signal queue_rd_req		: std_logic := '0';
	signal queue_do			: std_logic_vector(15 downto 0);
	signal queue_rd_empty   : std_logic;
	
	signal last_queue_di 	: std_logic_vector(15 downto 0) := (others => '1');	
	signal cnt_led 			: unsigned(10 downto 0) := (others=> '0');
	
	signal scancode_tmp		: std_logic_vector(7 downto 0) := (others => '0');
	signal is_up 				: std_logic := '0';
	
	type qmachine IS(q_idle, q_init, q_init_done, q_rtcw, q_rtcw_done, q_avrw, q_avrw_done, q_led, q_led_done, q_nop, q_nop_done); --state machine for queue writes
	signal qstate : qmachine := q_idle;

		 
begin
	
	--------------------------------------------------------------------------
	-- AVR SPI communication
	--------------------------------------------------------------------------		  
	
	U_SPI: entity work.spi_slave
	generic map(
			N             => 16 -- 2 bytes (cmd + data)       
	 )
	port map(
		  clk_i          => CLK,
		  spi_sck_i      => AVR_SCK,
		  spi_ssel_i     => AVR_SS,
		  spi_mosi_i     => AVR_MOSI,
		  spi_miso_o     => spi_miso,

		  di_req_o       => spi_di_req,
		  di_i           => spi_di,
		  wren_i         => not queue_rd_empty,
		  
		  do_valid_o     => spi_do_valid,
		  do_o           => spi_do,

		  do_transfer_o  => open,
		  wren_o         => open,
		  wren_ack_o     => open,
		  rx_bit_reg_o   => open,
		  state_dbg_o    => open
	);

	spi_di <= queue_do;
	queue_rd_req <= spi_di_req;	
	AVR_MISO	<= spi_miso when AVR_SS = '0' else 'Z';
		  
	process (CLK, spi_do_valid, spi_do)
	begin
		if (rising_edge(CLK)) then
			if spi_do_valid = '1' then
				case spi_do(15 downto 8) is 
					-- keyboard matrix
					when X"01" => kb_data_tmp(7 downto 0) <= spi_do (7 downto 0);
					when X"02" => kb_data_tmp(15 downto 8) <= spi_do (7 downto 0);
					when X"03" => kb_data_tmp(23 downto 16) <= spi_do (7 downto 0);
					when X"04" => kb_data_tmp(31 downto 24) <= spi_do (7 downto 0);
					when X"05" => kb_data_tmp(39 downto 32) <= spi_do (7 downto 0);
					-- misc signals
					when X"06" => kb_data(40 downto 0) <= spi_do (0) & kb_data_tmp(39 downto 0); -- kbd 5th bit + the rest 
									  -- misc signals
									  RESET <= spi_do(1); -- reset signal
									  TURBO <= spi_do(2); -- turbo signal
									  MAGICK <= spi_do(3); -- magick signal 
									  is_up <= spi_do(4); -- keyboard key is up
									  WAIT_CPU <= spi_do(5); -- cpu wait signal 
									  SOFT_SW(1) <= spi_do(6); -- soft switch 1
									  SOFT_SW(2) <= spi_do(7); -- soft switch 2
					-- keyboard scancode mixed vector
					when X"07" => 
									  scancode_tmp <= spi_do(7 downto 0);
					when X"08" => 
									  KB_SCANCODE <= is_up & spi_do(0) & scancode_tmp;
									  SOFT_SW(3) <= spi_do(1); -- soft switch 3
									  SOFT_SW(4) <= spi_do(2); -- soft switch 4
									  SOFT_SW(5) <= spi_do(3); -- soft switch 5
									  KB_MODE <= spi_do(4); -- profi / standard kbd layout
									  SOFT_SW(6) <= spi_do(5); -- soft switch 6
									  SOFT_SW(7) <= spi_do(6); -- soft switch 7
									  SOFT_SW(8) <= spi_do(7); -- soft switch 8
					when X"09" => 
									  SOFT_SW(9) <= spi_do(0);
									  SOFT_SW(10) <= spi_do(1);
									  JOY_TYPE <= spi_do(2);
									  LOADED <= '1'; -- loaded
									  -- 5 free signals
					-- mouse data
					when X"0A" => mouse_x(7 downto 0) <= signed(spi_do(7 downto 0));
					when X"0B" => mouse_y(7 downto 0) <= signed(spi_do(7 downto 0));
					when X"0C" => mouse_z(3 downto 0) <= signed(spi_do(3 downto 0)); buttons(2 downto 0) <= spi_do(6 downto 4); newPacket <= spi_do(7);					
					-- joy data
					when X"0D" => joy(0) <= spi_do(5); -- right 
									  joy(1) <= spi_do(4); -- left 
									  joy(2) <= spi_do(3); -- down 
									  joy(3) <= spi_do(2); -- up
									  joy(4) <= spi_do(0); -- fire
									  joy(5) <= spi_do(1); -- fire2
									  joy(6) <= spi_do(6); -- A
									  joy(7) <= spi_do(7); -- B
					-- rtc registers
					when others => 
							rtc_cmd <= spi_do(15 downto 8);
							rtc_data <= spi_do(7 downto 0);
				end case;
			end if;
		end if;
	end process;		  
		      
	--------------------------------------------------------------------------
	-- Keyboard
	--------------------------------------------------------------------------
				
	process( kb_data, A)
	begin

	--    -- if an address line is low then set the databus to the bit value for that column
	--    -- so if multiple address lines are low
	--    -- the up/down status of MULTIPLE 'keybits' will be passeds

			--if (rising_edge(CLK)) then
					KB(0) <=	not(( kb_data(0)  and not(A(8)  ) ) 
								or 	( kb_data(1)  and not(A(9)  ) ) 
								or 	( kb_data(2) and not(A(10) ) ) 
								or 	( kb_data(3) and not(A(11) ) ) 
								or 	( kb_data(4) and not(A(12) ) ) 
								or 	( kb_data(5) and not(A(13) ) ) 
								or 	( kb_data(6) and not(A(14) ) ) 
								or 	( kb_data(7) and not(A(15) ) )  );

					KB(1) <=	not( ( kb_data(8)  and not(A(8) ) ) 
								or   ( kb_data(9)  and not(A(9) ) ) 
								or   ( kb_data(10) and not(A(10)) ) 
								or   ( kb_data(11) and not(A(11)) ) 
								or   ( kb_data(12) and not(A(12)) ) 
								or   ( kb_data(13) and not(A(13)) ) 
								or   ( kb_data(14) and not(A(14)) ) 
								or   ( kb_data(15) and not(A(15)) ) );

					KB(2) <=		not( ( kb_data(16) and not( A(8)) ) 
								or   ( kb_data(17) and not( A(9)) ) 
								or   ( kb_data(18) and not(A(10)) ) 
								or   ( kb_data(19) and not(A(11)) ) 
								or   ( kb_data(20) and not(A(12)) ) 
								or   ( kb_data(21) and not(A(13)) ) 
								or   ( kb_data(22) and not(A(14)) ) 
								or   ( kb_data(23) and not(A(15)) ) );

					KB(3) <=		not( ( kb_data(24) and not( A(8)) ) 
								or   ( kb_data(25) and not( A(9)) ) 
								or   ( kb_data(26) and not(A(10)) ) 
								or   ( kb_data(27) and not(A(11)) ) 
								or   ( kb_data(28) and not(A(12)) ) 
								or   ( kb_data(29) and not(A(13)) ) 
								or   ( kb_data(30) and not(A(14)) ) 
								or   ( kb_data(31) and not(A(15)) ) );

					KB(4) <=		not( ( kb_data(32) and not( A(8)) ) 
								or   ( kb_data(33) and not( A(9)) ) 
								or   ( kb_data(34) and not(A(10)) ) 
								or   ( kb_data(35) and not(A(11)) ) 
								or   ( kb_data(36) and not(A(12)) ) 
								or   ( kb_data(37) and not(A(13)) ) 
								or   ( kb_data(38) and not(A(14)) ) 
								or   ( kb_data(39) and not(A(15)) ) );

					KB(5) <= not(kb_data(40));
			--end if;

	end process;

	--------------------------------------------------------------------------
	-- Mouse 
	--------------------------------------------------------------------------
	
	process (CLK, kb_data) 
	begin
			if (rising_edge(CLK)) then
				trigger <= '0';
				-- update mouse only on ms flag changed
				if (ms_flag /= newPacket) then 
					deltaX(7 downto 0) <= mouse_x(7 downto 0);
					deltaY(7 downto 0) <= mouse_y(7 downto 0);
					deltaZ(3 downto 0) <= mouse_z(3 downto 0);
					MS_BTNS(2) <= buttons(2);
					MS_BTNS(1) <= buttons(1);
					MS_BTNS(0) <= buttons(0);
					MS_DELTA_X <= mouse_x;
					MS_DELTA_Y <= mouse_y; 
					MS_PRESET <= '1';
					ms_flag <= newPacket;
					MS_EVENT <= newPacket;
					trigger <= '1';
				end if;
			end if;
	end process;

	process (CLK)
		variable newX : signed(7 downto 0);
		variable newY : signed(7 downto 0);
	begin
		if rising_edge (CLK) then

			newX := cursorX + deltaX(7 downto 0);
			newY := cursorY + deltaY(7 downto 0);

			if trigger = '1' then
				cursorX <= newX;
				cursorY <= newY;
			end if;
		end if;
	end process;
	
	MS_X 		<= std_logic_vector(cursorX);
	MS_Y 		<= std_logic_vector(cursorY);
	MS_Z		<= std_logic_vector(deltaZ);	

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
	port map (
		wrclock	 => CLK,
		data		 => rtcw_di,
		wraddress => rtcw_a,
		wren 		 => rtcw_wr,
		
		rdclock 	 => CLK,
		rdaddress => RTC_A,
		q			 => rtcr_do
	);
	RTC_DO <= rtcr_do;
	
	-- fifo for write commands to send them on avr side 
	UFIFO: entity work.queue 
	port map (
		data 		=> queue_di,
		wrreq 	=> queue_wr_req,
		wrclk 	=> CLK,
		wrfull 	=> queue_wr_full,
		
		rdreq 	=> queue_rd_req,
		rdclk 	=> CLK,
		q 			=> queue_do,
		rdempty 	=> queue_rd_empty
	);
		
	-- fifo handling / queue commands to avr side
	process(CLK, CLKEN, N_RESET, INIT, CFG, RTC_WR_N, RTC_CS, last_queue_di, queue_wr_full, RTC_A, RTC_DI, cnt_led, LED1, LED2, LED1_OWR, LED2_OWR, queue_wr_req, queue_rd_empty)
	begin
		if CLK'event and CLK = '1' then
			
			if INIT = '1' then -- and last_queue_di /= x"FC00" then 
				queue_di <= x"FD" & CFG;
				last_queue_di <= x"FD" & CFG;
				queue_wr_req <= '1';
			elsif CLKEN = '0' and RTC_WR_N = '0' AND RTC_CS = '1' then -- and last_queue_di /= ("10" & RTC_A & RTC_DI) then 
				-- push address and data into the FIFO queue to send via SPI
				queue_di <= "10" & RTC_A & RTC_DI;
				last_queue_di <= "10" & RTC_A & RTC_DI;
				queue_wr_req <= '1';
			else
				cnt_led <= cnt_led + 1;
				if queue_wr_full = '0' and cnt_led = "00000000000" then -- and last_queue_di /= x"0E" & "0000" & LED2_OWR & LED1_OWR & LED2 & LED1 then
					queue_di <= x"0E" & "0000" & LED2_OWR & LED1_OWR & LED2 & LED1;
					last_queue_di <= x"0E" & "0000" & LED2_OWR & LED1_OWR & LED2 & LED1;
					queue_wr_req <= '1';
				elsif queue_rd_empty = '1' then 
					queue_di <= x"FFFF"; -- nop
					last_queue_di <= x"FFFF";
					queue_wr_req <= '1';
				else 
					queue_wr_req <= '0';
					queue_di <= x"FFFF"; -- nop
				end if;
			end if;
		end if;
	end process;
	
	-- write RTC registers into ram from host / atmega
	process (N_RESET, CLK, RTC_WR_N, RTC_CS, RTC_A, RTC_DI, rtc_cmd, rtc_data) 
	begin 
		if rising_edge(CLK) then
			rtcw_wr <= '0';
			if INIT = '0' and RTC_WR_N = '0' AND RTC_CS = '1' then
				-- rtc mem write by host
				rtcw_wr <= '1';
				rtcw_a <= RTC_A;
				rtcw_di <= RTC_DI;								
			elsif rtc_cmd(7 downto 6) = "01" then
				-- rtc from avr
				rtcw_wr <= '1';
				rtcw_a <= rtc_cmd(5 downto 0);
				rtcw_di <= rtc_data;
			end if;
		end if;
	end process;

end RTL;

