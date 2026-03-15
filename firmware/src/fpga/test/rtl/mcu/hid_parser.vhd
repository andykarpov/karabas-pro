-------------------------------------------------------------------------------
-- MCU HID keyboard / joystick parser / transformer
-------------------------------------------------------------------------------

-- TODO: bit5 profi
-- TODO: joy l/r mapped to keyboard

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity hid_parser is
	port
	(
	 CLK			 : in std_logic;
	 RESET 		 : in std_logic;
	 
	 KB_STATUS : in std_logic_vector(7 downto 0);
	 KB_DAT0 : in std_logic_vector(7 downto 0);
	 KB_DAT1 : in std_logic_vector(7 downto 0);
	 KB_DAT2 : in std_logic_vector(7 downto 0);
	 KB_DAT3 : in std_logic_vector(7 downto 0);
	 KB_DAT4 : in std_logic_vector(7 downto 0);
	 KB_DAT5 : in std_logic_vector(7 downto 0);

	 JOY_TYPE_L : in std_logic_vector(2 downto 0);
	 JOY_TYPE_R : in std_logic_vector(2 downto 0);
	 JOY_L : in std_logic_vector(11 downto 0);
	 JOY_R : in std_logic_vector(11 downto 0);

	 A : in std_logic_vector(15 downto 8);
	 
	 JOY_DO : out std_logic_vector(7 downto 0);
	 KB_DO : out std_logic_vector(5 downto 0);
	 
	 -- tsconf ps/2 scancode to RTC reg F0
	 KEYCODE: out std_logic_vector(7 downto 0)
	);
end hid_parser;

architecture rtl of hid_parser is

	type matrix IS (ZX_K_CS, ZX_K_A, ZX_K_Q, ZX_K_1, 
						 ZX_K_0, ZX_K_P, ZX_K_ENT, ZX_K_SP,
						 ZX_K_Z, ZX_K_S, ZX_K_W, ZX_K_2,
						 ZX_K_9, ZX_K_O, ZX_K_L, ZX_K_SS,
						 ZX_K_X, ZX_K_D, ZX_K_E, ZX_K_3,
						 ZX_K_8, ZX_K_I, ZX_K_K, ZX_K_M,
						 ZX_K_C, ZX_K_F, ZX_K_R, ZX_K_4,
						 ZX_K_7, ZX_K_U, ZX_K_J, ZX_K_N,
						 ZX_K_V, ZX_K_G, ZX_K_T, ZX_K_5,
						 ZX_K_6, ZX_K_Y, ZX_K_H, ZX_K_B
						 );

	constant SC_CTL_ON : natural := 0;
	constant SC_BTN_UP : natural := 1;
	constant SC_BTN_DOWN: natural := 2;
	constant SC_BTN_LEFT: natural := 3;
   constant	SC_BTN_RIGHT: natural := 4;
	constant SC_BTN_START: natural := 5;
   constant SC_BTN_A : natural := 6;
	constant SC_BTN_B : natural := 7;
	constant SC_BTN_C : natural := 8;
	constant SC_BTN_X : natural := 9;
	constant SC_BTN_Y : natural := 10;
	constant SC_BTN_Z : natural := 11;
	constant SC_BTN_MODE : natural := 12;
						 
	type kb_matrix is array(matrix) of std_logic;						 
	signal kb_data : kb_matrix := (others => '0'); -- 40 keys
	
	signal data : std_logic_vector(47 downto 0);
	
	signal is_macros : std_logic := '0';
	type macros_machine is (MACRO_START, MACRO_CS_ON, MACRO_SS_ON, MACRO_SS_OFF, MACRO_KEY, MACRO_CS_OFF, MACRO_END);
	signal macros_key : matrix;
	signal macros_state : macros_machine := MACRO_START;
	signal macro_cnt : std_logic_vector(21 downto 0) := (others => '0');

begin 

	data <= KB_DAT0 & KB_DAT1 & KB_DAT2 & KB_DAT3 & KB_DAT4 & KB_DAT5;

	process( kb_data, A)
	begin
		KB_DO(0) <=	not(( kb_data(ZX_K_CS)  and not( A(8)  ) ) 
					or    ( kb_data(ZX_K_A)  and not(   A(9)  ) ) 
					or    ( kb_data(ZX_K_Q) and not(    A(10) ) ) 
					or    ( kb_data(ZX_K_1) and not(    A(11) ) ) 
					or    ( kb_data(ZX_K_0) and not(    A(12) ) ) 
					or    ( kb_data(ZX_K_P) and not(    A(13) ) ) 
					or    ( kb_data(ZX_K_ENT) and not(  A(14) ) ) 
					or    ( kb_data(ZX_K_SP) and not(   A(15) ) )  );

		KB_DO(1) <=	not( ( kb_data(ZX_K_Z)  and not(A(8) ) ) 
					or   ( kb_data(ZX_K_S)  and not(A(9) ) ) 
					or   ( kb_data(ZX_K_W) and not(A(10)) ) 
					or   ( kb_data(ZX_K_2) and not(A(11)) ) 
					or   ( kb_data(ZX_K_9) and not(A(12)) ) 
					or   ( kb_data(ZX_K_O) and not(A(13)) ) 
					or   ( kb_data(ZX_K_L) and not(A(14)) ) 
					or   ( kb_data(ZX_K_SS) and not(A(15)) ) );

		KB_DO(2) <=		not( ( kb_data(ZX_K_X) and not( A(8)) ) 
					or   ( kb_data(ZX_K_D) and not( A(9)) ) 
					or   ( kb_data(ZX_K_E) and not(A(10)) ) 
					or   ( kb_data(ZX_K_3) and not(A(11)) ) 
					or   ( kb_data(ZX_K_8) and not(A(12)) ) 
					or   ( kb_data(ZX_K_I) and not(A(13)) ) 
					or   ( kb_data(ZX_K_K) and not(A(14)) ) 
					or   ( kb_data(ZX_K_M) and not(A(15)) ) );

		KB_DO(3) <=		not( ( kb_data(ZX_K_C) and not( A(8)) ) 
					or   ( kb_data(ZX_K_F) and not( A(9)) ) 
					or   ( kb_data(ZX_K_R) and not(A(10)) ) 
					or   ( kb_data(ZX_K_4) and not(A(11)) ) 
					or   ( kb_data(ZX_K_7) and not(A(12)) ) 
					or   ( kb_data(ZX_K_U) and not(A(13)) ) 
					or   ( kb_data(ZX_K_J) and not(A(14)) ) 
					or   ( kb_data(ZX_K_N) and not(A(15)) ) );

		KB_DO(4) <=		not( ( kb_data(ZX_K_V) and not( A(8)) ) 
					or   ( kb_data(ZX_K_G) and not( A(9)) ) 
					or   ( kb_data(ZX_K_T) and not(A(10)) ) 
					or   ( kb_data(ZX_K_5) and not(A(11)) ) 
					or   ( kb_data(ZX_K_6) and not(A(12)) ) 
					or   ( kb_data(ZX_K_Y) and not(A(13)) ) 
					or   ( kb_data(ZX_K_H) and not(A(14)) ) 
					or   ( kb_data(ZX_K_B) and not(A(15)) ) );
	end process;

process (RESET, CLK)

	variable is_shift : std_logic := '0';
	variable is_cs_used : std_logic := '0';
	variable is_ss_used : std_logic := '0';

	begin
		if RESET = '1' then
			kb_data <= (others => '0');
			is_shift := '0';
			is_cs_used := '0';
			is_ss_used := '0';
			KEYCODE <= (others => '1');
			macro_cnt <= (others => '0');
			
		elsif CLK'event and CLK = '1' then
				
			-- TODO: add delay (counter?) between presses
			if is_macros = '1' then 
					macro_cnt <= macro_cnt + 1;
					if (macro_cnt = "1111111111111111111111") then 
					case macros_state is 
						when MACRO_START  => kb_data <= (others => '0'); macros_state <= MACRO_CS_ON;
						when MACRO_CS_ON  => kb_data(ZX_K_CS) <= '1';    macros_state <= MACRO_SS_ON;
						when MACRO_SS_ON  => kb_data(ZX_K_SS) <= '1';    macros_state <= MACRO_SS_OFF;
						when MACRO_SS_OFF => kb_data(ZX_K_SS) <= '0';    macros_state <= MACRO_KEY;
						when MACRO_KEY    => kb_data(macros_key) <= '1'; macros_state <= MACRO_CS_OFF;
						when MACRO_CS_OFF => kb_data(ZX_K_CS) <= '0'; kb_data(macros_key) <= '0'; macros_state <= MACRO_END;
						when MACRO_END    => kb_data <= (others => '0'); is_macros <= '0';        macros_state <= MACRO_START;
						when others => null;
					end case;
					end if;
			else
				macro_cnt <= (others => '0');
				kb_data <= (others => '0');
				KEYCODE <= (others => '1');
				is_shift := '0';
				is_cs_used := '0';
				is_ss_used := '0';
				
				-- L Shift -> CS
				if KB_STATUS(1) = '1' then kb_data(ZX_K_CS) <= '1'; is_shift := '1'; KEYCODE <= X"12"; end if;
				-- R Shift -> CS
				if KB_STATUS(5) = '1' then kb_data(ZX_K_CS) <= '1'; is_shift := '1'; KEYCODE <= X"59"; end if;				
							
				-- L Ctrl -> SS
				if KB_STATUS(0) = '1' then kb_data(ZX_K_SS) <= '1'; KEYCODE <= X"14"; end if;
				-- R Ctrl -> SS
				if KB_STATUS(4) = '1' then kb_data(ZX_K_SS) <= '1'; KEYCODE <= X"14"; end if;
							
				-- Alt -> SS+CS
				if KB_STATUS(2) = '1' or KB_STATUS(6) = '1' then kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_SS) <= '1'; is_cs_used := '1'; KEYCODE <= X"11"; end if;
				
				-- Win
				if KB_STATUS(7) = '1' then KEYCODE <= x"27"; end if;

				for II in 0 to 5 loop		
				case data((II+1)*8-1 downto II*8) is							
					-- DEL -> SS + C
					when X"4c" => if (is_shift = '0') then kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_C) <= '1'; end if;	KEYCODE <= x"71";				
					-- INS -> SS + A
					when X"49" => if (is_shift = '0') then kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_A) <= '1'; end if; KEYCODE <= x"70";
					-- Cursor -> CS + 5,6,7,8
					when X"50" =>	if (is_shift = '0') then kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_5) <= '1'; is_cs_used := '1'; end if; KEYCODE <= x"6b";
					when X"51" =>	if (is_shift = '0') then kb_data(ZX_K_CS) <= '1'; kb_Data(ZX_K_6) <= '1'; is_cs_used := '1'; end if; KEYCODE <= x"72";
					when X"52" =>	if (is_shift = '0') then kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_7) <= '1'; is_cs_used := '1'; end if; KEYCODE <= x"75";
					when X"4f" =>	if (is_shift = '0') then kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_8) <= '1'; is_cs_used := '1'; end if; KEYCODE <= x"74";
					-- ESC -> CS + Space 
					when X"29" => kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_SP) <= '1'; is_cs_used := '1'; KEYCODE <= x"76";					
					-- Backspace -> CS + 0
					when X"2a" => kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_0) <= '1'; is_cs_used := '1'; KEYCODE <= x"66";
					-- Enter
					when X"28" =>	kb_data(ZX_K_ENT) <= '1'; KEYCODE <= x"5a"; -- normal
					when X"58" =>  kb_data(ZX_K_ENT) <= '1'; KEYCODE <= x"5a"; -- keypad 					
					-- Space 
					when X"2c" =>	kb_data(ZX_K_SP) <= '1'; KEYCODE <= x"29";
					-- Letters
					when X"04" =>	kb_data(ZX_K_A) <= '1'; KEYCODE <= x"1c"; -- A
					when X"05" =>	kb_data(ZX_K_B) <= '1'; KEYCODE <= x"32"; -- B								
					when X"06" =>	kb_data(ZX_K_C) <= '1'; KEYCODE <= x"21"; -- C
					when X"07" =>	kb_data(ZX_K_D) <= '1'; KEYCODE <= x"23"; -- D
					when X"08" =>	kb_data(ZX_K_E) <= '1'; KEYCODE <= x"24"; -- E
					when X"09" =>	kb_data(ZX_K_F) <= '1'; KEYCODE <= x"2b"; -- F
					when X"0a" =>	kb_data(ZX_K_G) <= '1'; KEYCODE <= x"34"; -- G
					when X"0b" =>	kb_data(ZX_K_H) <= '1'; KEYCODE <= x"33"; -- H
					when X"0c" =>	kb_data(ZX_K_I) <= '1'; KEYCODE <= x"43"; -- I
					when X"0d" =>	kb_data(ZX_K_J) <= '1'; KEYCODE <= x"3b"; -- J
					when X"0e" =>	kb_data(ZX_K_K) <= '1'; KEYCODE <= x"42"; -- K
					when X"0f" =>	kb_data(ZX_K_L) <= '1'; KEYCODE <= x"4b"; -- L
					when X"10" =>	kb_data(ZX_K_M) <= '1'; KEYCODE <= x"3a"; -- M
					when X"11" =>	kb_data(ZX_K_N) <= '1'; KEYCODE <= x"31"; -- N
					when X"12" =>	kb_data(ZX_K_O) <= '1'; KEYCODE <= x"44"; -- O
					when X"13" =>	kb_data(ZX_K_P) <= '1'; KEYCODE <= x"4d"; -- P
					when X"14" =>	kb_data(ZX_K_Q) <= '1'; KEYCODE <= x"15"; -- Q
					when X"15" =>	kb_data(ZX_K_R) <= '1'; KEYCODE <= x"2d"; -- R
					when X"16" =>	kb_data(ZX_K_S) <= '1'; KEYCODE <= x"1b"; -- S
					when X"17" =>	kb_data(ZX_K_T) <= '1'; KEYCODE <= x"2c"; -- T
					when X"18" =>	kb_data(ZX_K_U) <= '1'; KEYCODE <= x"3c"; -- U
					when X"19" =>	kb_data(ZX_K_V) <= '1'; KEYCODE <= x"2a"; -- V
					when X"1a" =>	kb_data(ZX_K_W) <= '1'; KEYCODE <= x"1d"; -- W
					when X"1b" =>	kb_data(ZX_K_X) <= '1'; KEYCODE <= x"22"; -- X
					when X"1c" =>	kb_data(ZX_K_Y) <= '1'; KEYCODE <= x"35"; -- Y
					when X"1d" =>	kb_data(ZX_K_Z) <= '1'; KEYCODE <= x"1a"; -- Z
					-- Digits
					when X"1e" =>	kb_data(ZX_K_1) <= '1'; KEYCODE <= x"16"; -- 1
					when X"1f" =>	kb_data(ZX_K_2) <= '1'; KEYCODE <= x"1e"; -- 2
					when X"20" =>	kb_data(ZX_K_3) <= '1'; KEYCODE <= x"26"; -- 3
					when X"21" =>	kb_data(ZX_K_4) <= '1'; KEYCODE <= x"25"; -- 4
					when X"22" =>	kb_data(ZX_K_5) <= '1'; KEYCODE <= x"2e"; -- 5
					when X"23" =>	kb_data(ZX_K_6) <= '1'; KEYCODE <= x"36"; -- 6
					when X"24" =>	kb_data(ZX_K_7) <= '1'; KEYCODE <= x"3d"; -- 7
					when X"25" =>	kb_data(ZX_K_8) <= '1'; KEYCODE <= x"3e"; -- 8
					when X"26" =>	kb_data(ZX_K_9) <= '1'; KEYCODE <= x"46"; -- 9
					when X"27" =>	kb_data(ZX_K_0) <= '1'; KEYCODE <= x"45"; -- 0
					-- Numpad digits
					when X"59" =>	kb_data(ZX_K_1) <= '1'; KEYCODE <= x"16"; -- 1
					when X"5A" =>	kb_data(ZX_K_2) <= '1'; KEYCODE <= x"1e"; -- 2
					when X"5B" =>	kb_data(ZX_K_3) <= '1'; KEYCODE <= x"26"; -- 3
					when X"5C" =>	kb_data(ZX_K_4) <= '1'; KEYCODE <= x"25"; -- 4
					when X"5D" =>	kb_data(ZX_K_5) <= '1'; KEYCODE <= x"2e"; -- 5
					when X"5E" =>	kb_data(ZX_K_6) <= '1'; KEYCODE <= x"36"; -- 6
					when X"5F" =>	kb_data(ZX_K_7) <= '1'; KEYCODE <= x"3d"; -- 7
					when X"60" =>	kb_data(ZX_K_8) <= '1'; KEYCODE <= x"3e"; -- 8
					when X"61" =>	kb_data(ZX_K_9) <= '1'; KEYCODE <= x"46"; -- 9
					when X"62" =>	kb_data(ZX_K_0) <= '1'; KEYCODE <= x"45"; -- 0
					-- Special keys 					
					-- '/" -> SS+P / SS+7
					when X"34" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"52"; if is_shift = '1' then kb_data(ZX_K_P) <= '1'; else kb_data(ZX_K_7) <= '1'; end if; is_ss_used := is_shift;					
					-- ,/< -> SS+N / SS+R
					when X"36" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"41"; if is_shift = '1' then kb_data(ZX_K_R) <= '1'; else kb_data(ZX_K_N) <= '1'; end if; is_ss_used := is_shift;					
					-- ./> -> SS+M / SS+T
					when X"37" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"49"; if is_shift = '1' then kb_data(ZX_K_T) <= '1'; else kb_data(ZX_K_M) <= '1'; end if; is_ss_used := is_shift;					
					-- ;/: -> SS+O / SS+Z
					when X"33" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"4c"; if is_shift = '1' then kb_data(ZX_K_Z) <= '1'; else kb_data(ZX_K_O) <= '1'; end if; is_ss_used := is_shift;					
					
					-- Macroses
					-- [,{ -> SS+Y / SS+F
					when X"2F" => is_macros <= '1'; KEYCODE <= x"54"; if is_shift = '1' then macros_key <= ZX_K_F; else macros_key <= ZX_K_Y; end if; 					
					-- ],} -> SS+U / SS+G
					when X"30" => is_macros <= '1'; KEYCODE <= x"5b"; if is_shift = '1' then macros_key <= ZX_K_G; else macros_key <= ZX_K_U; end if; 					
					
					-- /,? -> SS+V / SS+C
					when X"38" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"4a"; if is_shift = '1' then kb_data(ZX_K_C) <= '1'; else kb_data(ZX_K_V) <= '1'; end if; is_ss_used := is_shift;					
					-- \,| -> SS+D / SS+S
					when X"31" => is_macros <= '1'; KEYCODE <= x"5d"; if is_shift = '1' then macros_key <= ZX_K_S; else macros_key <= ZX_K_D; end if; 					
					-- =,+ -> SS+L / SS+K
					when X"2E" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"55"; if is_shift = '1' then kb_data(ZX_K_K) <= '1'; else kb_data(ZX_K_L) <= '1'; end if; is_ss_used := is_shift;					
					-- -,_ -> SS+J / SS+0
					when X"2D" => kb_data(ZX_K_SS) <= '1'; KEYCODE <= x"4e"; if is_shift = '1' then kb_data(ZX_K_0) <= '1'; else kb_data(ZX_K_J) <= '1'; end if; is_ss_used := is_shift;
					-- `,~ -> SS+X / SS+A
					when X"35" => 
						KEYCODE <= x"0e";
						if (is_shift = '1') then 
							is_macros <= '1'; macros_key <= ZX_K_A; 
						else
							kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_X) <= '1'; 
						end if;
						is_ss_used := '1';
					-- Keypad * -> SS+B
					when X"55" => kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_B) <= '1'; 					
					-- Keypad - -> SS+J
					when X"56" => kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_J) <= '1';					
					-- Keypad + -> SS+K
					when X"57" => kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_K) <= '1';					
					-- Tab -> CS + I
					when X"2B" => kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_I) <= '1'; is_cs_used := '1'; KEYCODE <= x"0d";				
					-- CapsLock -> CS + SS
					when X"39" => kb_data(ZX_K_SS) <= '1'; kb_data(ZX_K_CS) <= '1'; is_cs_used := '1'; KEYCODE <= x"58";
					-- PgUp -> CS+3 for ZX
					when X"4B" => kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_3) <= '1'; is_cs_used := '1'; KEYCODE <= x"7d";
					-- PgDown -> CS+4 for ZX
					when X"4E" => kb_data(ZX_K_CS) <= '1'; kb_data(ZX_K_4) <= '1'; is_cs_used := '1'; KEYCODE <= x"7a";
					
					-- Fx keys
					when X"3a" =>	KEYCODE <= x"05";	-- F1
					when X"3b" =>	KEYCODE <= x"06";	-- F2
					when X"3c" =>	KEYCODE <= x"04";	-- F3
					when X"3d" =>	KEYCODE <= x"0c";	-- F4
					when X"3e" =>	KEYCODE <= x"03";	-- F5
					when X"3f" =>	KEYCODE <= x"0b";	-- F6
					when X"40" =>	KEYCODE <= x"83";	-- F7
					when X"41" =>	KEYCODE <= x"0a";	-- F8
					when X"42" =>	KEYCODE <= x"01";	-- F9
					when X"43" =>	KEYCODE <= x"09";	-- F10
					when X"44" =>	KEYCODE <= x"78";	-- F11
					when X"45" =>	KEYCODE <= x"07";	-- F12
	 
					-- Soft keys
					when X"46" =>	KEYCODE <= x"7c";	-- PrtScr
					when X"47" =>	KEYCODE <= x"7e";	-- Scroll Lock
					when X"48" =>	KEYCODE <= x"77";	-- Pause
					when X"65" =>	KEYCODE <= x"2f";	-- WinMenu
					when X"4a" =>	KEYCODE <= x"6c";	-- Home
					when X"4d" =>	KEYCODE <= x"69";	-- End
					
					when others => null;
				end case;
				end loop;
							
				-- map joysticks to keyboard
				-- sega joy:  Mode Z Y X C B A Start R L D U On
				
				-- sinclair 1
				if joy_type_l = "001" then 
					if (joy_l(SC_BTN_UP) = '1') then kb_data(ZX_K_4) <= '1'; end if; -- up
					if (joy_l(SC_BTN_DOWN) = '1') then kb_data(ZX_K_3) <= '1'; end if; -- down
					if (joy_l(SC_BTN_LEFT) = '1') then kb_data(ZX_K_1) <= '1'; end if; -- left
					if (joy_l(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_2) <= '1'; end if; -- right
					if (joy_l(SC_BTN_B) = '1') then kb_data(ZX_K_5) <= '1'; end if; -- fire
				end if;
				if joy_type_r = "001" then
					if (joy_r(SC_BTN_UP) = '1') then kb_data(ZX_K_4) <= '1'; end if; -- up
					if (joy_r(SC_BTN_DOWN) = '1') then kb_data(ZX_K_3) <= '1'; end if; -- down
					if (joy_r(SC_BTN_LEFT) = '1') then kb_data(ZX_K_1) <= '1'; end if; -- left
					if (joy_r(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_2) <= '1'; end if; -- right
					if (joy_r(SC_BTN_B) = '1') then kb_data(ZX_K_5) <= '1'; end if; -- fire					
				end if;
				
				-- sinclair 2
				if joy_type_l = "010" then 
					if (joy_l(SC_BTN_UP) = '1') then kb_data(ZX_K_9) <= '1'; end if; -- up
					if (joy_l(SC_BTN_DOWN) = '1') then kb_data(ZX_K_8) <= '1'; end if; -- down
					if (joy_l(SC_BTN_LEFT) = '1') then kb_data(ZX_K_6) <= '1'; end if; -- left
					if (joy_l(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_7) <= '1'; end if; -- right
					if (joy_l(SC_BTN_B) = '1') then kb_data(ZX_K_0) <= '1'; end if; -- fire	
				end if;
				if joy_type_r = "010" then
					if (joy_r(SC_BTN_UP) = '1') then kb_data(ZX_K_9) <= '1'; end if; -- up
					if (joy_r(SC_BTN_DOWN) = '1') then kb_data(ZX_K_8) <= '1'; end if; -- down
					if (joy_r(SC_BTN_LEFT) = '1') then kb_data(ZX_K_6) <= '1'; end if; -- left
					if (joy_r(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_7) <= '1'; end if; -- right
					if (joy_r(SC_BTN_B) = '1') then kb_data(ZX_K_0) <= '1'; end if; -- fire					
				end if;
				
				-- cursor
				if joy_type_l = "011" then 
					if (joy_l(SC_BTN_UP) = '1') then kb_data(ZX_K_7) <= '1'; end if; -- up
					if (joy_l(SC_BTN_DOWN) = '1') then kb_data(ZX_K_6) <= '1'; end if; -- down
					if (joy_l(SC_BTN_LEFT) = '1') then kb_data(ZX_K_5) <= '1'; end if; -- left
					if (joy_l(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_8) <= '1'; end if; -- right
					if (joy_l(SC_BTN_B) = '1') then kb_data(ZX_K_0) <= '1'; end if; -- fire	
				end if;
				if joy_type_r = "011" then
					if (joy_r(SC_BTN_UP) = '1') then kb_data(ZX_K_7) <= '1'; end if; -- up
					if (joy_r(SC_BTN_DOWN) = '1') then kb_data(ZX_K_6) <= '1'; end if; -- down
					if (joy_r(SC_BTN_LEFT) = '1') then kb_data(ZX_K_5) <= '1'; end if; -- left
					if (joy_r(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_8) <= '1'; end if; -- right
					if (joy_r(SC_BTN_B) = '1') then kb_data(ZX_K_0) <= '1'; end if; -- fire					
				end if;
				
				-- qaopm
				if joy_type_l = "100" then 
					if (joy_l(SC_BTN_UP) = '1') then kb_data(ZX_K_Q) <= '1'; end if; -- up
					if (joy_l(SC_BTN_DOWN) = '1') then kb_data(ZX_K_A) <= '1'; end if; -- down
					if (joy_l(SC_BTN_LEFT) = '1') then kb_data(ZX_K_O) <= '1'; end if; -- left
					if (joy_l(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_P) <= '1'; end if; -- right
					if (joy_l(SC_BTN_B) = '1') then kb_data(ZX_K_M) <= '1'; end if; -- fire	
				end if;
				if joy_type_r = "100" then
					if (joy_r(SC_BTN_UP) = '1') then kb_data(ZX_K_Q) <= '1'; end if; -- up
					if (joy_r(SC_BTN_DOWN) = '1') then kb_data(ZX_K_A) <= '1'; end if; -- down
					if (joy_r(SC_BTN_LEFT) = '1') then kb_data(ZX_K_O) <= '1'; end if; -- left
					if (joy_r(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_P) <= '1'; end if; -- right
					if (joy_r(SC_BTN_B) = '1') then kb_data(ZX_K_M) <= '1'; end if; -- fire					
				end if;

				-- quaps
				if joy_type_l = "101" then 
					if (joy_l(SC_BTN_UP) = '1') then kb_data(ZX_K_Q) <= '1'; end if; -- up
					if (joy_l(SC_BTN_DOWN) = '1') then kb_data(ZX_K_A) <= '1'; end if; -- down
					if (joy_l(SC_BTN_LEFT) = '1') then kb_data(ZX_K_O) <= '1'; end if; -- left
					if (joy_l(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_P) <= '1'; end if; -- right
					if (joy_l(SC_BTN_B) = '1') then kb_data(ZX_K_SP) <= '1'; end if; -- fire	
				end if;
				if joy_type_r = "101" then
					if (joy_r(SC_BTN_UP) = '1') then kb_data(ZX_K_Q) <= '1'; end if; -- up
					if (joy_r(SC_BTN_DOWN) = '1') then kb_data(ZX_K_A) <= '1'; end if; -- down
					if (joy_r(SC_BTN_LEFT) = '1') then kb_data(ZX_K_O) <= '1'; end if; -- left
					if (joy_r(SC_BTN_RIGHT) = '1') then kb_data(ZX_K_P) <= '1'; end if; -- right
					if (joy_r(SC_BTN_B) = '1') then kb_data(ZX_K_SP) <= '1'; end if; -- fire					
				end if;

				
				-- cleanup CS key when SS is marked
				if (is_ss_used = '1' and is_cs_used = '0') then 
					kb_data(ZX_K_CS) <= '0';
				end if;
							
			end if;
		end if;
	end process;

	-- map L/R joysticks to kempston joy bus 
	process (RESET, CLK)
	begin
		if (RESET = '1') then 
			joy_do <= (others => '0');
		elsif rising_edge(CLK) then
			if joy_type_l = "000" then 
				joy_do(0) <= joy_l(SC_BTN_RIGHT);
				joy_do(1) <= joy_l(SC_BTN_LEFT);
				joy_do(2) <= joy_l(SC_BTN_DOWN);
				joy_do(3) <= joy_l(SC_BTN_UP);
				joy_do(4) <= joy_l(SC_BTN_B);
				joy_do(5) <= joy_l(SC_BTN_A);
				joy_do(6) <= joy_l(SC_BTN_X);
				joy_do(7) <= joy_l(SC_BTN_Y);
			elsif joy_type_r = "000" then
				joy_do(0) <= joy_r(SC_BTN_RIGHT);
				joy_do(1) <= joy_r(SC_BTN_LEFT);
				joy_do(2) <= joy_r(SC_BTN_DOWN);
				joy_do(3) <= joy_r(SC_BTN_UP);
				joy_do(4) <= joy_r(SC_BTN_B);
				joy_do(5) <= joy_r(SC_BTN_A);
				joy_do(6) <= joy_r(SC_BTN_X);
				joy_do(7) <= joy_r(SC_BTN_Y);
			else
				joy_do <= (others => '0');
			end if;
		end if;
	end process;

end rtl;