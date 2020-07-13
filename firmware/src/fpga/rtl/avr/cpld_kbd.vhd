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
	 
	 MS_X 	 	: out std_logic_vector(7 downto 0);
	 MS_Y 	 	: out std_logic_vector(7 downto 0);
	 MS_BTNS 	 	: out std_logic_vector(2 downto 0);
	 MS_Z 		: out std_logic_vector(3 downto 0);
	 
	 RTC_A 		: in std_logic_vector(5 downto 0);
	 RTC_DI 		: in std_logic_vector(7 downto 0);
	 RTC_DO 		: out std_logic_vector(7 downto 0);
	 RTC_WR_N 	: in std_logic := '1';
	 
	 RESET		: out std_logic;
	 TURBO		: out std_logic;
	 MAGICK		: out std_logic;
	 
	 JOY			: out std_logic_vector(4 downto 0)
	 
	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

	 -- keyboard state
	 signal kb_data : std_logic_vector(40 downto 0) := (others => '0'); -- 40 keys + bit6
	 signal ms_flag : std_logic := '0';
	 
	 -- mouse
	 signal mouse_x : signed(7 downto 0);
	 signal mouse_y : signed(7 downto 0);
	 signal mouse_z : signed(3 downto 0);
	 signal buttons   : std_logic_vector(2 downto 0);
	 signal newPacket : std_logic := '0';

	 signal currentX 	: unsigned(7 downto 0);
	 signal currentY 	: unsigned(7 downto 0);
	 signal cursorX 		: signed(7 downto 0) := X"7F";
	 signal cursorY 		: signed(7 downto 0) := X"7F";
	 signal deltaX		: signed(8 downto 0);
	 signal deltaY		: signed(8 downto 0);
	 signal deltaZ		: signed(3 downto 0);
	 signal trigger 	: std_logic := '0';
	 
	 -- spi
	 signal spi_do_valid : std_logic := '0';
	 signal spi_do : std_logic_vector(15 downto 0);
--	 signal spi_di : std_logic_vector(15 downto 0);
	 
	 -- rtc 
	 signal rtc_cmd : std_logic_vector(7 downto 0);
	 signal rtc_data : std_logic_vector(7 downto 0);
	 
	 -- mc146818a emulation
	 signal seconds_reg			: std_logic_vector(5 downto 0); -- 00
	 signal minutes_reg			: std_logic_vector(5 downto 0); -- 02
	 signal hours_reg			: std_logic_vector(4 downto 0); -- 04
	 signal week_reg 			: std_logic_vector(2 downto 0); --06
	 signal days_reg				: std_logic_vector(4 downto 0); -- 07
	 signal month_reg			: std_logic_vector(3 downto 0); -- 08
	 signal year_reg				: std_logic_vector(6 downto 0); -- 09

begin

U_SPI: entity work.spi_slave
    generic map(
        N              => 16 -- 2 bytes (cmd + data)       
    )
    port map(
        clk_i          => CLK,
        spi_sck_i      => AVR_SCK,
        spi_ssel_i     => AVR_SS,
        spi_mosi_i     => AVR_MOSI,
        spi_miso_o     => AVR_MISO,

        di_req_o       => open,
        di_i           => open, --spi_di,
        wren_i         => '0', --'1',
        do_valid_o     => spi_do_valid,
        do_o           => spi_do,

        do_transfer_o  => open,
        wren_o         => open,
        wren_ack_o     => open,
        rx_bit_reg_o   => open,
        state_dbg_o    => open
        );


		  
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
								  RESET <= not spi_do(1);
								  TURBO <= not spi_do(2);
								  MAGICK <= not spi_do(3);

				-- mouse data
				when X"0A" => mouse_x(7 downto 0) <= signed(spi_do(7 downto 0));
				when X"0B" => mouse_y(7 downto 0) <= signed(spi_do(7 downto 0));
				when X"0C" => mouse_z(3 downto 0) <= signed(spi_do(3 downto 0)); buttons(2 downto 0) <= spi_do(6 downto 4); newPacket <= spi_do(7);
				
				-- joy data
				when X"0D" => joy(4 downto 0) <= spi_do(5 downto 1);
				
				when others => 
						rtc_cmd <= spi_do(15 downto 8);
						rtc_data <= spi_do(7 downto 0);
			end case;	
		end if;
	end if;
end process;		  
		  
--    
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
				MS_BTNS(2) <= not(buttons(2));
				MS_BTNS(1) <= not(buttons(1));
				MS_BTNS(0) <= not(buttons(0));				
				ms_flag <= newPacket;
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
	
-- mc146818a emulation	
process(RTC_A, seconds_reg, minutes_reg, hours_reg, days_reg, month_reg, year_reg--,
			--seconds_alarm_reg, minutes_alarm_reg, hours_alarm_reg, weeks_reg,
			--a_reg, b_reg, c_reg, e_reg, f_reg
			)
	begin
		-- RTC register read
		case RTC_A(5 downto 0) is
			when "000000" => RTC_DO <= "00" & seconds_reg;
			when "000010" => RTC_DO <= "00" & minutes_reg;
			when "000100" => RTC_DO <= "000" & hours_reg;
			when "000110" => RTC_DO <= "00000" & week_reg;
			when "000111" => RTC_DO <= "000" & days_reg;
			when "001000" => RTC_DO <= "0000" & month_reg;
			when "001001" => RTC_DO <= "0" & year_reg;
			
			when "001010" => RTC_DO <= "00100110"; -- a_reg;
			when "001011" => RTC_DO <= "00000110"; -- b_reg;
			when "001101" => RTC_DO <= "10000000"; -- hardcoded d_reg
			when others => RTC_DO <= "00000000";
		end case;
	end process;
		
	process(CLK, N_RESET)
	begin
		if CLK'event and CLK = '1' then

			if N_RESET='0' then

			else 
			
				-- RTC register set
				if RTC_WR_N = '0' then
--					case RTC_A(5 downto 0) is
--						when "000000" => seconds_reg <= RTC_DI(5 downto 0);  
--						when "000010" => minutes_reg <= RTC_DI(5 downto 0);
--						when "000100" => hours_reg <= RTC_DI(4 downto 0);
--						when "000110" => week_reg <= RTC_DI(2 downto 0);
--						when "000111" => days_reg <= RTC_DI(4 downto 0);
--						when "001000" => month_reg <= RTC_DI(3 downto 0);
--						when "001001" => year_reg <= RTC_DI(6 downto 0);
--						when others => null; -- nop
--					end case;
--					spi_di <= "10" & RTC_A & RTC_DI;
				
				-- RTC incoming time from atmega (every seconds)
				elsif rtc_cmd(7 downto 6) = "01" then 
					case rtc_cmd(5 downto 0) is 
						when "000000" => seconds_reg <= rtc_data(5 downto 0);
						when "000010" => minutes_reg <= rtc_data(5 downto 0);
						when "000100" => hours_reg <= rtc_data(4 downto 0);
						when "000110" => week_reg <= rtc_data(2 downto 0);
						when "000111" => days_reg <= rtc_data(4 downto 0);
						when "001000" => month_reg <= rtc_data(3 downto 0);
						when "001001" => year_reg <= rtc_data(6 downto 0);
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;

end RTL;

