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
	 
	 RTC_A 		: in std_logic_vector(5 downto 0);
	 RTC_DI 		: in std_logic_vector(7 downto 0);
	 RTC_DO 		: out std_logic_vector(7 downto 0);
	 RTC_CS 		: in std_logic := '0';
	 RTC_WR_N 	: in std_logic := '1';
	 
	 RESET		: out std_logic := '0';
	 TURBO		: out std_logic := '0';
	 MAGICK		: out std_logic := '0';
	 
	 JOY			: out std_logic_vector(4 downto 0) := "00000"
	 
	);
    end cpld_kbd;
architecture RTL of cpld_kbd is

	 -- keyboard state
	 signal kb_data : std_logic_vector(40 downto 0) := (others => '0'); -- 40 keys + bit6
	 signal ms_flag : std_logic := '0';
	 
	 -- mouse
	 signal mouse_x : signed(7 downto 0) := "00000000";
	 signal mouse_y : signed(7 downto 0) := "00000000";
	 signal mouse_z : signed(3 downto 0) := "0000";
	 signal buttons   : std_logic_vector(2 downto 0) := "000";
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
	signal leap_reg				: std_logic_vector(1 downto 0);
	signal seconds_reg			: std_logic_vector(7 downto 0); -- 00
	signal seconds_alarm_reg	: std_logic_vector(7 downto 0); -- 01
	signal minutes_reg			: std_logic_vector(7 downto 0); -- 02
	signal minutes_alarm_reg	: std_logic_vector(7 downto 0); -- 03
	signal hours_reg			: std_logic_vector(7 downto 0); -- 04
	signal hours_alarm_reg		: std_logic_vector(7 downto 0); -- 05
	signal weeks_reg			: std_logic_vector(7 downto 0); -- 06
	signal days_reg				: std_logic_vector(7 downto 0); -- 07
	signal month_reg			: std_logic_vector(7 downto 0); -- 08
	signal year_reg				: std_logic_vector(7 downto 0); -- 09
	signal a_reg				: std_logic_vector(7 downto 0); -- 0A
	signal b_reg				: std_logic_vector(7 downto 0); -- 0B
	signal c_reg				: std_logic_vector(7 downto 0); -- 0C
--	signal d_reg				: std_logic_vector(7 downto 0); -- 0D
	signal e_reg				: std_logic_vector(7 downto 0); -- 0E
	signal f_reg				: std_logic_vector(7 downto 0); -- 0F
	signal reg10				: std_logic_vector(7 downto 0); 
	signal reg11				: std_logic_vector(7 downto 0);
	signal reg12				: std_logic_vector(7 downto 0);
	signal reg13				: std_logic_vector(7 downto 0);
	signal reg14				: std_logic_vector(7 downto 0);
	signal reg15				: std_logic_vector(7 downto 0);
	signal reg16				: std_logic_vector(7 downto 0);
	signal reg17				: std_logic_vector(7 downto 0);
	signal reg18				: std_logic_vector(7 downto 0);
	signal reg19				: std_logic_vector(7 downto 0);
	signal reg1a				: std_logic_vector(7 downto 0);
	signal reg1b				: std_logic_vector(7 downto 0);
	signal reg1c				: std_logic_vector(7 downto 0);
	signal reg1d				: std_logic_vector(7 downto 0);
	signal reg1e				: std_logic_vector(7 downto 0);
	signal reg1f				: std_logic_vector(7 downto 0);
	signal reg20				: std_logic_vector(7 downto 0);
	signal reg21				: std_logic_vector(7 downto 0);
	signal reg22				: std_logic_vector(7 downto 0);
	signal reg23				: std_logic_vector(7 downto 0);
	signal reg24				: std_logic_vector(7 downto 0);
	signal reg25				: std_logic_vector(7 downto 0);
	signal reg26				: std_logic_vector(7 downto 0);
	signal reg27				: std_logic_vector(7 downto 0);
	signal reg28				: std_logic_vector(7 downto 0);
	signal reg29				: std_logic_vector(7 downto 0);
	signal reg2a				: std_logic_vector(7 downto 0);
	signal reg2b				: std_logic_vector(7 downto 0);
	signal reg2c				: std_logic_vector(7 downto 0);
	signal reg2d				: std_logic_vector(7 downto 0);
	signal reg2e				: std_logic_vector(7 downto 0);
	signal reg2f				: std_logic_vector(7 downto 0);
	signal reg30				: std_logic_vector(7 downto 0);
	signal reg31				: std_logic_vector(7 downto 0);
	signal reg32				: std_logic_vector(7 downto 0);
	signal reg33				: std_logic_vector(7 downto 0);
	signal reg34				: std_logic_vector(7 downto 0);
	signal reg35				: std_logic_vector(7 downto 0);
	signal reg36				: std_logic_vector(7 downto 0);
	signal reg37				: std_logic_vector(7 downto 0);
	signal reg38				: std_logic_vector(7 downto 0);
	signal reg39				: std_logic_vector(7 downto 0);
	signal reg3a				: std_logic_vector(7 downto 0);
	signal reg3b				: std_logic_vector(7 downto 0);
	signal reg3c				: std_logic_vector(7 downto 0);
	signal reg3d				: std_logic_vector(7 downto 0);
	signal reg3e				: std_logic_vector(7 downto 0);
	signal reg3f				: std_logic_vector(7 downto 0);	

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
								  RESET <= spi_do(1);
								  TURBO <= spi_do(2);
								  MAGICK <= spi_do(3);

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
				MS_BTNS(2) <= buttons(2);
				MS_BTNS(1) <= buttons(1);
				MS_BTNS(0) <= buttons(0);	
				MS_PRESET <= '1';
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
process(CLK, RTC_A, seconds_reg, seconds_alarm_reg, minutes_reg, minutes_alarm_reg, hours_reg, hours_alarm_reg, weeks_reg, days_reg, month_reg, year_reg,
			a_reg, b_reg, c_reg, e_reg, f_reg, reg10, reg11, reg12, reg13, reg14, reg15, reg16, reg17, reg18, reg19, reg1a, reg1b, reg1c, reg1d,
			reg1e, reg1f, reg20, reg21, reg22, reg23, reg24, reg25, reg26, reg27, reg28, reg29, reg2a, reg2b, reg2c, reg2d, reg2e, reg2f, reg30,
			reg31, reg32, reg33, reg34, reg35, reg36, reg37, reg38, reg39, reg3a, reg3b, reg3c, reg3d, reg3e, reg3f
			)
	begin
		-- RTC register read
		case RTC_A(5 downto 0) is
			when "000000" => RTC_DO <= seconds_reg;
			when "000001" => RTC_DO <= seconds_alarm_reg;
			when "000010" => RTC_DO <= minutes_reg;
			when "000011" => RTC_DO <= minutes_alarm_reg;
			when "000100" => RTC_DO <= hours_reg;
			when "000101" => RTC_DO <= hours_alarm_reg;
			when "000110" => RTC_DO <= weeks_reg;
			when "000111" => RTC_DO <= days_reg;
			when "001000" => RTC_DO <= month_reg;
			when "001001" => RTC_DO <= year_reg;
			when "001010" => RTC_DO <= a_reg;
			when "001011" => RTC_DO <= b_reg;
			when "001100" => RTC_DO <= c_reg;
			when "001101" => RTC_DO <= "10000000";
			when "001110" => RTC_DO <= e_reg;
			when "001111" => RTC_DO <= f_reg;
			when "010000" => RTC_DO <= reg10;
			when "010001" => RTC_DO <= reg11;
			when "010010" => RTC_DO <= reg12;
			when "010011" => RTC_DO <= reg13;
			when "010100" => RTC_DO <= reg14;
			when "010101" => RTC_DO <= reg15;
			when "010110" => RTC_DO <= reg16;
			when "010111" => RTC_DO <= reg17;
			when "011000" => RTC_DO <= reg18;
			when "011001" => RTC_DO <= reg19;
			when "011010" => RTC_DO <= reg1a;
			when "011011" => RTC_DO <= reg1b;
			when "011100" => RTC_DO <= reg1c;
			when "011101" => RTC_DO <= reg1d;
			when "011110" => RTC_DO <= reg1e;
			when "011111" => RTC_DO <= reg1f;
			when "100000" => RTC_DO <= reg20;
			when "100001" => RTC_DO <= reg21;
			when "100010" => RTC_DO <= reg22;
			when "100011" => RTC_DO <= reg23;
			when "100100" => RTC_DO <= reg24;
			when "100101" => RTC_DO <= reg25;
			when "100110" => RTC_DO <= reg26;
			when "100111" => RTC_DO <= reg27;
			when "101000" => RTC_DO <= reg28;
			when "101001" => RTC_DO <= reg29;
			when "101010" => RTC_DO <= reg2a;
			when "101011" => RTC_DO <= reg2b;
			when "101100" => RTC_DO <= reg2c;
			when "101101" => RTC_DO <= reg2d;
			when "101110" => RTC_DO <= reg2e;
			when "101111" => RTC_DO <= reg2f;
			when "110000" => RTC_DO <= reg30;
			when "110001" => RTC_DO <= reg31;
			when "110010" => RTC_DO <= reg32;
			when "110011" => RTC_DO <= reg33;
			when "110100" => RTC_DO <= reg34;
			when "110101" => RTC_DO <= reg35;
			when "110110" => RTC_DO <= reg36;
			when "110111" => RTC_DO <= reg37;
			when "111000" => RTC_DO <= reg38;
			when "111001" => RTC_DO <= reg39;
			when "111010" => RTC_DO <= reg3a;
			when "111011" => RTC_DO <= reg3b;
			when "111100" => RTC_DO <= reg3c;
			when "111101" => RTC_DO <= reg3d;
			when "111110" => RTC_DO <= reg3e;
			when "111111" => RTC_DO <= reg3f;
		end case;
	end process;
		
	process(CLK, N_RESET)
	begin
		if CLK'event and CLK = '1' then

			if N_RESET='0' then
				a_reg <= "00100110";
				b_reg <= (others => '0');
				c_reg <= (others => '0');
			else 
			
				-- RTC register set
				if RTC_WR_N = '0' AND RTC_CS = '1' then
					case RTC_A(5 downto 0) is
						when "000000" => seconds_reg <= RTC_DI;
						when "000001" => seconds_alarm_reg <= RTC_DI;
						when "000010" => minutes_reg <= RTC_DI;
						when "000011" => minutes_alarm_reg <= RTC_DI;
						when "000100" => hours_reg <= RTC_DI;
						when "000101" => hours_alarm_reg <= RTC_DI;
						when "000110" => weeks_reg <= RTC_DI;
						when "000111" => days_reg <= RTC_DI;
						when "001000" => month_reg <= RTC_DI;
						when "001001" => year_reg <= RTC_DI;
							if b_reg(2) = '0' then -- BCD to BIN convertion
								if RTC_DI(4) = '0' then
									leap_reg <= RTC_DI(1 downto 0);
								else
									leap_reg <= (not RTC_DI(1)) & RTC_DI(0);
								end if;
							else 
								leap_reg <= RTC_DI(1 downto 0);
							end if;
						when "001010" => a_reg <= RTC_DI;
						when "001011" => b_reg <= RTC_DI;
	--					when "001100" => c_reg <= RTC_DI;
	--					when "001101" => d_reg <= RTC_DI;
						when "001110" => e_reg <= RTC_DI;
						when "001111" => f_reg <= RTC_DI;
						when "010000" => reg10 <= RTC_DI;
						when "010001" => reg11 <= RTC_DI;
						when "010010" => reg12 <= RTC_DI;
						when "010011" => reg13 <= RTC_DI;
						when "010100" => reg14 <= RTC_DI;
						when "010101" => reg15 <= RTC_DI;
						when "010110" => reg16 <= RTC_DI;
						when "010111" => reg17 <= RTC_DI;
						when "011000" => reg18 <= RTC_DI;
						when "011001" => reg19 <= RTC_DI;
						when "011010" => reg1a <= RTC_DI;
						when "011011" => reg1b <= RTC_DI;
						when "011100" => reg1c <= RTC_DI;
						when "011101" => reg1d <= RTC_DI;
						when "011110" => reg1e <= RTC_DI;
						when "011111" => reg1f <= RTC_DI;
						when "100000" => reg20 <= RTC_DI;
						when "100001" => reg21 <= RTC_DI;
						when "100010" => reg22 <= RTC_DI;
						when "100011" => reg23 <= RTC_DI;
						when "100100" => reg24 <= RTC_DI;
						when "100101" => reg25 <= RTC_DI;
						when "100110" => reg26 <= RTC_DI;
						when "100111" => reg27 <= RTC_DI;
						when "101000" => reg28 <= RTC_DI;
						when "101001" => reg29 <= RTC_DI;
						when "101010" => reg2a <= RTC_DI;
						when "101011" => reg2b <= RTC_DI;
						when "101100" => reg2c <= RTC_DI;
						when "101101" => reg2d <= RTC_DI;
						when "101110" => reg2e <= RTC_DI;
						when "101111" => reg2f <= RTC_DI;
						when "110000" => reg30 <= RTC_DI;
						when "110001" => reg31 <= RTC_DI;
						when "110010" => reg32 <= RTC_DI;
						when "110011" => reg33 <= RTC_DI;
						when "110100" => reg34 <= RTC_DI;
						when "110101" => reg35 <= RTC_DI;
						when "110110" => reg36 <= RTC_DI;
						when "110111" => reg37 <= RTC_DI;
						when "111000" => reg38 <= RTC_DI;
						when "111001" => reg39 <= RTC_DI;
						when "111010" => reg3a <= RTC_DI;
						when "111011" => reg3b <= RTC_DI;
						when "111100" => reg3c <= RTC_DI;
						when "111101" => reg3d <= RTC_DI;
						when "111110" => reg3e <= RTC_DI;
						when "111111" => reg3f <= RTC_DI;
						when others => null;
					end case;
--					spi_di <= "10" & RTC_A & RTC_DI;
				
				-- RTC incoming time from atmega (every seconds)
				elsif rtc_cmd(7 downto 6) = "01" then 
					case rtc_cmd(5 downto 0) is 
						when "000000" => seconds_reg <= "00" & rtc_data(5 downto 0);
						when "000010" => minutes_reg <= "00" & rtc_data(5 downto 0);
						when "000100" => hours_reg <= "000" & rtc_data(4 downto 0);
						when "000110" => weeks_reg <= "00000" & rtc_data(2 downto 0);
						when "000111" => days_reg <= "000" & rtc_data(4 downto 0);
						when "001000" => month_reg <= "0000" & rtc_data(3 downto 0);
						when "001001" => year_reg <= '0' & rtc_data(6 downto 0);
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;

end RTL;

