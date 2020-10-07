library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;

entity cpld_kbd is
	port
	(
	 CLK			 : in std_logic;
	 N_RESET 	 : in std_logic := '1';
    A           : in std_logic_vector(15 downto 8);     -- address bus for kbd
    KB          : out std_logic_vector(5 downto 0) := "111111";     -- data bus for kbd + extended bit (b6)
    AVR_MOSI    : in std_logic;
    AVR_MISO    : out std_logic;
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
	 RTC_INIT 	: in std_logic := '0';
	 
	 LED1			: in std_logic := '0';
	 LED2 		: in std_logic := '0';
	 LED1_OWR	: in std_logic := '0';
	 LED2_OWR 	: in std_logic := '0';
	 
	 RESET		: out std_logic := '0';
	 TURBO		: out std_logic := '0';
	 MAGICK		: out std_logic := '0';
	 WAIT_CPU 	: out std_logic := '0';
	 
	 JOY			: out std_logic_vector(4 downto 0) := "00000"
	 
	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

	 -- keyboard state
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
	 signal spi_do 			: std_logic_vector(15 downto 0);
	 signal spi_di_req 		: std_logic;
--	 signal spi_di 			: std_logic_vector(15 downto 0);
	 
	 -- rtc rx spi data
	 signal rtc_cmd 			: std_logic_vector(7 downto 0);  -- spi cmd
	 signal rtc_data 			: std_logic_vector(7 downto 0); -- spi data 
	 
	 -- rtc 2-port ram signals
	 signal rtcw_di 			: std_logic_vector(7 downto 0);
	 signal rtcw_a 			: std_logic_vector(5 downto 0);
	 signal rtcw_wr 			: std_logic := '0';
	 signal rtcr_do 			: std_logic_vector(7 downto 0);
	 
	 -- rtc dedicated registers
	signal a_reg				: std_logic_vector(7 downto 0); -- 0A
	signal b_reg				: std_logic_vector(7 downto 0); -- 0B
	signal c_reg				: std_logic_vector(7 downto 0); -- 0C
--	signal d_reg				: std_logic_vector(7 downto 0); -- 0D
	signal e_reg				: std_logic_vector(7 downto 0); -- 0E
	signal f_reg				: std_logic_vector(7 downto 0); -- 0F	 
	
	-- rtc fifo 
	signal queue_di			: std_logic_vector(15 downto 0);
	signal queue_wr_req		: std_logic := '0';
	signal queue_wr_full		: std_logic;
		
	signal queue_rd_req		: std_logic := '0';
	signal queue_do			: std_logic_vector(15 downto 0);
	signal queue_rd_empty   : std_logic;
	
	signal last_queue_di 	: std_logic_vector(15 downto 0) := (others => '1');	
	signal cnt_led 			: unsigned(12 downto 0) := "0000000000000";
	 
begin
	
	U_SPI: entity work.spi_slave
	generic map(
			N             => 16 -- 2 bytes (cmd + data)       
	 )
	port map(
		  clk_i          => CLK,
		  spi_sck_i      => AVR_SCK,
		  spi_ssel_i     => AVR_SS,
		  spi_mosi_i     => AVR_MOSI,
		  spi_miso_o     => AVR_MISO,

		  di_req_o       => spi_di_req,
		  di_i           => queue_do,
		  wren_i         => not queue_rd_empty,
		  
		  do_valid_o     => spi_do_valid,
		  do_o           => spi_do,

		  do_transfer_o  => open,
		  wren_o         => open,
		  wren_ack_o     => open,
		  rx_bit_reg_o   => open,
		  state_dbg_o    => open
	);
	
	queue_rd_req <= '1' when spi_di_req = '1' and queue_rd_empty = '0' else '0';
		  
	process (CLK, spi_do_valid, spi_do)
	begin
		if (rising_edge(CLK)) then
			if spi_do_valid = '1' then
				case spi_do(15 downto 8) is 
					-- keyboard matrix
					when X"01" => kb_data(7 downto 0) <= spi_do (7 downto 0);
					when X"02" => kb_data(15 downto 8) <= spi_do (7 downto 0);
					when X"03" => kb_data(23 downto 16) <= spi_do (7 downto 0);
					when X"04" => kb_data(31 downto 24) <= spi_do (7 downto 0);
					when X"05" => kb_data(39 downto 32) <= spi_do (7 downto 0);
					when X"06" => kb_data(40) <= spi_do (0); 
									  RESET <= spi_do(1);
									  TURBO <= spi_do(2);
									  MAGICK <= spi_do(3);
									  WAIT_CPU <= spi_do(5);
					-- when X"06" (4 - is_up), X"07", X"08" - scancode
					-- mouse data
					when X"0A" => mouse_x(7 downto 0) <= signed(spi_do(7 downto 0));
					when X"0B" => mouse_y(7 downto 0) <= signed(spi_do(7 downto 0));
					when X"0C" => mouse_z(3 downto 0) <= signed(spi_do(3 downto 0)); buttons(2 downto 0) <= spi_do(6 downto 4); newPacket <= spi_do(7);
					
					-- joy data
					when X"0D" => joy(4 downto 0) <= spi_do(5 downto 2) & spi_do(0); -- right, left,  down, up, fire2, fire
					
					when others => 
							rtc_cmd <= spi_do(15 downto 8);
							rtc_data <= spi_do(7 downto 0);
				end case;	
			end if;
		end if;
	end process;		  
		      
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
								
					-- по мотивам http://zx-pk.ru/archive/index.php/t-21356.html

					-- как оказалось, 6-й бит выставляется при чтении полуряда "пробел". 
					-- Т.е. если мы нажимали расширенную клавишу, то при чтении этого полуряда (7F) будет сброшен бит 6. 
					-- Я такой тупости не понял (тупость заложили авторы контроллера в Кондоре, Caro повторил для совместимости XT контроллер по логике).
					
					-- Бит 6, в адаптере клавиатуры XT и в программной поддержке оного, а это - ПЗУ от Кондора и в системе МикроДОС от того же Кондора 
					-- означал если он в 0, то это использование доп. кнопок. Но очень и очень хитро. Если мы нажали, скажем F1. То, адаптер клавиатуры 
					-- выставлял 0 при прочитывании полуряда, который отвечает за букву А. И всё! 6-й бит при этом не активируется, 
					-- а активировался он только тогда, когда мы читали состояние "последнего" полуряда, с пробелом. 
					-- Если до этого было хотя бы одно нажатие доп. кнопки (F1-F10 и ещё 6 которые Ins Del и т.д.) тогда адаптер выставляет 6-й бит равным 0. 
					-- Если нажимались только обычные клавиши, которые мы можем транслировать как комбинацию нажатых клавишь из набора 40 ключей, то 6-й бит=1

					-- Иными словами, за один конкретный момент, адаптер клавы, может нам сообщить 6-м битом, о нажатии лишь одной из 16-и доп. клавишь, 
					-- которые он понимает. Т.е. одна кнопка в 1 момент времени. Иначе никак.

						if (A(15)='0') then
							KB(5) <= not(kb_data(40));
						end if;
			--end if;

	end process;

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

	-- mc146818a emulation	
	process(CLK, RTC_A, a_reg, b_reg, c_reg, e_reg, f_reg, rtcr_do)
	begin
		-- RTC register read
		case RTC_A(5 downto 0) is
			when "001010" => RTC_DO <= a_reg;
			when "001011" => RTC_DO <= b_reg;
			when "001100" => RTC_DO <= c_reg;
			when "001101" => RTC_DO <= "10000000"; -- (not is_busy) & "0000000";
			when "001110" => RTC_DO <= e_reg;
			when "001111" => RTC_DO <= f_reg;
			when others => RTC_DO <= rtcr_do;
		end case;
	end process;
		
	process(CLK, N_RESET, RTC_INIT, queue_wr_full, RTC_WR_N, RTC_CS, rtc_cmd, rtc_data, led1, led2, led1_OWR, led2_OWR, queue_wr_req)
	begin
		if CLK'event and CLK = '1' then

			queue_wr_req <= '0';
			queue_di <= x"FFFF"; -- nop
		
--			-- init request to avr rtc
--			if RTC_INIT = '1' and last_queue_di /= x"FC" & "00000000" and queue_wr_full = '0' then 
--		
--				queue_di <= x"FC" & "00000000";
--				last_queue_di <= x"FC" & "00000000";
--				queue_wr_req <= '1';
		
			-- host reset
			if N_RESET='0' then
				a_reg <= "00100110";
				b_reg <= (others => '0');
				c_reg <= (others => '0');		
				cnt_led <= (others => '0');
			else 
			
				-- RTC register set by ZX
				if RTC_WR_N = '0' AND RTC_CS = '1' then

					-- mem write signals
					rtcw_wr <= '1';
					rtcw_a <= RTC_A;
					rtcw_di <= RTC_DI;
					
					case RTC_A is 
						when "001010" => a_reg <= RTC_DI;
						when "001011" => b_reg <= RTC_DI;
	--					when "001100" => c_reg <= RTC_DI;
	--					when "001101" => d_reg <= RTC_DI;
						when "001110" => e_reg <= RTC_DI;
						when "001111" => f_reg <= RTC_DI;
						when others => null;
					end case;
					
					-- push address and data into the FIFO queue to send via SPI
					if queue_wr_full = '0' and last_queue_di /= ("10" & RTC_A & RTC_DI) then 
						queue_di <= "10" & RTC_A & RTC_DI;
						last_queue_di <= "10" & RTC_A & RTC_DI;
						queue_wr_req <= '1';
					end if;
					
				else
				
					-- RTC incoming time from atmega (every seconds)
					if rtc_cmd(7 downto 6) = "01" then 
						rtcw_wr <= '1';
						rtcw_a <= rtc_cmd(5 downto 0);
						case rtc_cmd(5 downto 0) is 
							when "000000" => rtcw_di <= "00" & rtc_data(5 downto 0);     -- seconds
							when "000010" => rtcw_di <= "00" & rtc_data(5 downto 0);		 -- minutes
							when "000100" => rtcw_di <= "000" & rtc_data(4 downto 0);	 -- hours
							when "000110" => rtcw_di <= "00000" & rtc_data(2 downto 0);	 -- weeks
							when "000111" => rtcw_di <= "000" & rtc_data(4 downto 0);	 -- days
							when "001000" => rtcw_di <= "0000" & rtc_data(3 downto 0);	 -- month
							when "001001" => rtcw_di <= '0' & rtc_data(6 downto 0);		 -- year
							when others   => rtcw_di <= rtc_data;
						end case;
					else 
						rtcw_wr <= '0';
					end if;
					
					cnt_led <= cnt_led + 1;
					
					-- sending led status on every 256th tick
					if queue_wr_full = '0' and cnt_led = "0000000000000" then 
						queue_di <= x"0E" & "0000" & LED2_OWR & LED1_OWR & LED2 & LED1;
						queue_wr_req <= '1';
					end if;
					
				end if;
			end if;
			
		end if;
	end process;

end RTL;

