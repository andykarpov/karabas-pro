-------------------------------------------------------------------------------
-- MCU HID keyboard / joystick parser / transformer
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity hid_parser is
	generic (
		NUM_KEYS : integer := 2
	);	
	port
	(
	 CLK			 : in std_logic;
	 RESET 		 : in std_logic;
	 
	 -- incoming usb hid report data
	 KB_STATUS : in std_logic_vector(7 downto 0);
	 KB_DAT0 : in std_logic_vector(7 downto 0);
	 KB_DAT1 : in std_logic_vector(7 downto 0);
	 KB_DAT2 : in std_logic_vector(7 downto 0);
	 KB_DAT3 : in std_logic_vector(7 downto 0);
	 KB_DAT4 : in std_logic_vector(7 downto 0);
	 KB_DAT5 : in std_logic_vector(7 downto 0);
	 
	 -- joy data from mcu
	 JOY_L : in std_logic_vector(12 downto 0);
	 JOY_R : in std_logic_vector(12 downto 0);

	 -- nes joy output data
	 JOY_L_DO : out std_logic_vector(7 downto 0) := "00000000";
	 JOY_R_DO : out std_logic_vector(7 downto 0) := "00000000"
	);
end hid_parser;

architecture rtl of hid_parser is

	constant SC_CTL_ON : natural := 0;
	constant SC_BTN_UP : natural := 1;
	constant SC_BTN_DOWN: natural := 2;
	constant SC_BTN_LEFT: natural := 3;
	constant SC_BTN_RIGHT: natural := 4;
	constant SC_BTN_START: natural := 5;
	constant SC_BTN_A : natural := 6;
	constant SC_BTN_B : natural := 7;
	constant SC_BTN_C : natural := 8;
	constant SC_BTN_X : natural := 9;
	constant SC_BTN_Y : natural := 10;
	constant SC_BTN_Z : natural := 11;
	constant SC_BTN_MODE : natural := 12;

	signal data : std_logic_vector(47 downto 0);
	signal kb_l: std_logic_vector(12 downto 0) := (others => '0');
	signal kb_r: std_logic_vector(12 downto 0) := (others => '0');	

	signal cnt_autofire : std_logic_vector(20 downto 0) := (others => '0');
	signal autofire_freq : std_logic := '0';
	signal autofire_l : std_logic_vector(1 downto 0) := "00";
	signal autofire_r : std_logic_vector(1 downto 0) := "00";

begin 

	-- incoming data of pressed keys from usb hid report
	data <= KB_DAT5 & KB_DAT4 & KB_DAT3 & KB_DAT2 & KB_DAT1 & KB_DAT0;

	-- map usb hid to keyboard joysticks
	process(RESET, CLK)
	begin
		if (RESET = '1') then 
			
			kb_l <= (others => '0');
			kb_r <= (others => '0');
			
		elsif rising_edge(CLK) then

			kb_l <= (others => '0');
			kb_r <= (others => '0');

			for II in 0 to 5 loop
				case data((II+1)*8-1 downto II*8) is

					-- Cursor -> kb_l U/D/L/R
					when X"50" => kb_l(SC_BTN_LEFT) <= '1';
					when X"51" => kb_l(SC_BTN_DOWN) <= '1';
					when X"52" => kb_l(SC_BTN_UP) <= '1';
					when X"4f" => kb_l(SC_BTN_RIGHT) <= '1';

					-- Space -> kb_l B
					when X"2c" => kb_l(SC_BTN_B) <= '1';
					
					-- Enter -> kb_l A
					when X"28" => kb_l(SC_BTN_A) <= '1';
					
					-- Letters
					when X"1a" => kb_l(SC_BTN_UP) <= '1'; -- W
					when X"04" => kb_l(SC_BTN_LEFT) <= '1'; -- A
					when X"16" => kb_l(SC_BTN_DOWN) <= '1'; -- S
					when X"07" => kb_l(SC_BTN_RIGHT) <= '1'; -- D
					when X"1d" => kb_l(SC_BTN_A) <= '1'; -- Z
					when X"1b" => kb_l(SC_BTN_B) <= '1'; -- X
					when X"06" => kb_l(SC_BTN_START) <= '1'; -- C
					when X"19" => kb_l(SC_BTN_C) <= '1';	-- V

					when X"0c" => kb_r(SC_BTN_UP) <= '1'; -- I
					when X"0d" => kb_r(SC_BTN_LEFT) <= '1'; -- J
					when X"0e" => kb_r(SC_BTN_DOWN) <= '1'; -- K
					when X"0f" => kb_r(SC_BTN_RIGHT) <= '1'; -- L
					when X"12" => kb_r(SC_BTN_A) <= '1'; -- O
					when X"13" => kb_r(SC_BTN_B) <= '1'; -- P
					when X"10" => kb_r(SC_BTN_START) <= '1'; -- M
					when X"11" => kb_r(SC_BTN_C) <= '1'; -- N
					
					when others => null;
				end case;
				end loop;
		end if;
	end process;

	-- map L/R MD joysticks and keyboatd to nes joy bus 
	-- (active 0)
	process (RESET, CLK)
	begin
		if (RESET = '1') then 
			joy_l_do <= (others => '0');
			joy_r_do <= (others => '0');
		elsif rising_edge(CLK) then
		-- A B Sel St U D L R 
			joy_l_do(0) <= joy_l(SC_BTN_B) or kb_l(SC_BTN_B) or autofire_l(1);
			joy_l_do(1) <= joy_l(SC_BTN_A) or kb_l(SC_BTN_A) or autofire_l(0);
			joy_l_do(2) <= joy_l(SC_BTN_C) or kb_l(SC_BTN_C);
			joy_l_do(3) <= joy_l(SC_BTN_START) or kb_l(SC_BTN_START);
			joy_l_do(4) <= joy_l(SC_BTN_UP) or kb_l(SC_BTN_UP);
			joy_l_do(5) <= joy_l(SC_BTN_DOWN) or kb_l(SC_BTN_DOWN);
			joy_l_do(6) <= joy_l(SC_BTN_LEFT) or kb_l(SC_BTN_LEFT);
			joy_l_do(7) <= joy_l(SC_BTN_RIGHT) or kb_l(SC_BTN_RIGHT);

			joy_r_do(0) <= joy_r(SC_BTN_B) or kb_r(SC_BTN_B) or autofire_r(1);
			joy_r_do(1) <= joy_r(SC_BTN_A) or kb_r(SC_BTN_A) or autofire_r(0);
			joy_r_do(2) <= joy_r(SC_BTN_C) or kb_r(SC_BTN_C);
			joy_r_do(3) <= joy_r(SC_BTN_START) or kb_r(SC_BTN_START);
			joy_r_do(4) <= joy_r(SC_BTN_UP) or kb_r(SC_BTN_UP);
			joy_r_do(5) <= joy_r(SC_BTN_DOWN) or kb_r(SC_BTN_DOWN);
			joy_r_do(6) <= joy_r(SC_BTN_LEFT) or kb_r(SC_BTN_LEFT);
			joy_r_do(7) <= joy_r(SC_BTN_RIGHT) or kb_r(SC_BTN_RIGHT);
		end if;
	end process;
	
	-- autofire
	process (RESET, CLK)
	begin
		if (RESET = '1') then 
			autofire_l <= "00";
			autofire_r <= "00";
		elsif rising_edge(CLK) then
		
			-- 12.5 Hz counter
			if (cnt_autofire = "110010000000000000000") then 
				cnt_autofire <= (others => '0');
				autofire_freq <= not autofire_freq;
			else 
				cnt_autofire <= cnt_autofire + 1; 				
			end if;
		
			-- assign autofire on x,y buttons
			autofire_l(0) <= joy_l(SC_BTN_X) and autofire_freq;
			autofire_l(1) <= joy_l(SC_BTN_Y) and autofire_freq;
			autofire_r(0) <= joy_r(SC_BTN_X) and autofire_freq;
			autofire_r(1) <= joy_r(SC_BTN_Y) and autofire_freq;
		
		end if;
	end process;

end rtl;
