library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity osd is
	generic ( 
		VER 		: string(1 to 8) := "FIRM_VER"
	);
	port (
		CLK		: in std_logic;
		CLK2 		: in std_logic;
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);
		DS80		: in std_logic;
		HCNT_I	: in std_logic_vector(9 downto 0);
		VCNT_I	: in std_logic_vector(8 downto 0);
		BLINK 	: in std_logic;
		LOADED 	: in std_logic;
		
		-- sensors
		TURBO 			: in std_logic := '0';
		SCANDOUBLER_EN : in std_logic := '0';
		MODE60 			: in std_logic := '0';
		ROM_BANK 		: in std_logic_vector := "00";
		KB_MODE 			: in std_logic := '1';
		KB_WAIT 			: in std_logic := '0';
		SSG_MODE 		: in std_logic := '0';
		SSG_STEREO 		: in std_logic := '0';
		COVOX_EN 		: in std_logic := '0';
		TURBO_FDC		: in std_logic := '0'
	);
end entity;

architecture rtl of osd is

	component rom_font
    port (
        address : in std_logic_vector(11 downto 0);
        clock   : in std_logic;
        q       : out std_logic_vector(7 downto 0)
    );
    end component;

	signal hcnt : std_logic_vector(9 downto 0);
	signal vcnt : std_logic_vector(8 downto 0);
	
	signal char_x: std_logic_vector(2 downto 0);
   signal char_y: std_logic_vector(3 downto 0);
	signal hpos : std_logic_vector(2 downto 0);
	signal char:   std_logic_vector(7 downto 0);
	
	signal rom_addr: std_logic_vector(11 downto 0);
	signal font_word: std_logic_vector(7 downto 0);
	signal vpos : std_logic_vector(1 downto 0) := "00";
	signal bit_addr: std_logic_vector(2 downto 0);
	signal pixel: std_logic;
		
	-- Define messages displayed
	constant message_turbo: 	string(1 to 8) 	:= "TURBO   ";
	constant message_vga: 		string(1 to 8) 	:= "VGA     ";
	constant message_rgb: 		string(1 to 8) 	:= "RGB     ";
	constant message_on:	 		string(1 to 8) 	:= "ON      ";
	constant message_off: 		string(1 to 8) 	:= "OFF     ";
	constant message_rombank: 	string(1 to 8) 	:= "ROM BANK";
	constant message_rombank0:	string(1 to 8) 	:= "DEFAULT ";
	constant message_rombank1:	string(1 to 8) 	:= "ALT     ";
	constant message_rombank2:	string(1 to 8) 	:= "FLASHER ";
	constant message_rombank3:	string(1 to 8) 	:= "DIAG ROM";
	constant message_50hz: 		string(1 to 8) 	:= "50 Hz   ";
	constant message_60hz: 		string(1 to 8) 	:= "60 Hz   ";
	constant message_keyboard: string(1 to 8)  := "KEYBOARD";
	constant message_profi:    string(1 to 8)  := "XT-PROFI";
	constant message_spectrum: string(1 to 8)  := "SPECTRUM";
	constant message_pause:    string(1 to 8)  := "PAUSE   ";
	constant message_empty: 	string(1 to 8) 	:= "        ";
	constant message_ssgmode:  string(1 to 8)  := "SSG MODE";
	constant message_ym_abc:	string(1 to 8)  := "YM, ABC ";
	constant message_ym_acb:	string(1 to 8)  := "YM, ACB ";
	constant message_ay_abc:	string(1 to 8)  := "AY, ABC ";
	constant message_ay_acb:	string(1 to 8)  := "AY, ACB ";
	constant message_covox:		string(1 to 8)  := "COVOX   ";
	constant message_turbo_fdc:string(1 to 8)  := "TURBOFDC";
	constant message_karabas:  string(1 to 8)  := "VERSION ";

	-- displayable lines
	signal line1 : string(1 to 8) := message_empty;
	signal line2 : string(1 to 8) := message_empty;
	
	signal last_turbo : std_logic := '0';
	signal last_scandoubler_en : std_logic := '0';
	signal last_mode60 : std_logic := '0';
	signal last_rom_bank : std_logic_vector(1 downto 0) := "00";
	signal last_kb_mode : std_logic := '1';
	signal last_kb_wait : std_logic := '0';
	signal last_ssg_mode : std_logic := '0';
	signal last_ssg_stereo : std_logic := '0';
	signal last_covox : std_logic := '0';
	signal kb_mode_init : std_logic := '0';
	signal last_turbo_fdc : std_logic := '0';
	signal last_loaded : std_logic := '0';
	
	signal cnt : std_logic_vector(3 downto 0) := "1000";
	signal en : std_logic := '0';
	
	signal last_blink : std_logic := '0';
	
begin

	hcnt <= HCNT_I;
	vcnt <= VCNT_I;
	
	-- font rom
	U_FONT: rom_font
   port map (
		address => rom_addr,
      clock   => CLK2,
      q       => font_word
   );
	 
	char_x <= hcnt(3 downto 1) when DS80='1' else hcnt(2 downto 0);
   char_y <= vcnt(3 downto 0);
	rom_addr <= char & char_y;

	-- vertical bounds for line1 / line2
	vpos(0) <= '1' when (DS80='0' and MODE60 = '0' and vcnt >= 288 and vcnt < 304) or -- spectrum screen 50 Hz vpos 
							  (DS80='0' and MODE60 = '1' and vcnt >= 0 and vcnt < 16) or    -- spectrum screen 60 Hz vpos 
							  (DS80='1' and vcnt >= 16 and vcnt < 32) else '0';             -- profi 50/60 Hz vpos
	vpos(1) <= '1' when (DS80='0' and MODE60 = '0' and vcnt >= 304 and vcnt < 320) or -- spectrum screen 50 Hz vpos
	                    (DS80='0' and MODE60 = '1' and vcnt >= 16 and vcnt < 32) or   -- spectrum screen 60 Hz vpos 
	                    (DS80='1' and vcnt >= 32 and vcnt < 48) else '0';             -- profi 50/60 Hz vpos

	hpos <= hcnt(6 downto 4) when DS80 = '1' else hcnt(5 downto 3);
	
	-- character to request from the ROM depends on the line1 / line2 horizontal position
	char <= std_logic_vector(to_unsigned(character'pos(line1(to_integer(unsigned(hpos(2 downto 0)))+1)), 8)) when vpos(0) = '1' and ((DS80 = '0' and hcnt < 64) or (DS80 = '1' and hcnt < 128)) else 
			  std_logic_vector(to_unsigned(character'pos(line2(to_integer(unsigned(hpos(2 downto 0)))+1)), 8)) when vpos(1) = '1' and ((DS80 = '0' and hcnt < 64) or (DS80 = '1' and hcnt < 128)) else 
			  (others => '0');

	-- pixel 
	bit_addr <= char_x(2 downto 0);
   pixel <=  font_word(0) when bit_addr = "000" else 
				 font_word(7) when bit_addr = "001" else 
				 font_word(6) when bit_addr = "010" else 
				 font_word(5) when bit_addr = "011" else 
				 font_word(4) when bit_addr = "100" else 
				 font_word(3) when bit_addr = "101" else 
				 font_word(2) when bit_addr = "110" else 
				 font_word(1) when bit_addr = "111";

	RGB_O <= "000111000" when en = '1' and pixel = '1' else RGB_I;

	-- display messages for changed sensors
	process (CLK, BLINK, cnt, KB_WAIT, KB_MODE, TURBO, SCANDOUBLER_EN, MODE60, ROM_BANK, SSG_MODE, SSG_STEREO, last_ssg_mode, last_ssg_stereo, last_kb_wait, last_kb_mode, LOADED, last_loaded, last_turbo, last_scandoubler_en, last_mode60, last_rom_bank, COVOX_EN, last_covox, TURBO_FDC, last_turbo_fdc)
	begin 
		if rising_edge(CLK) then 
		
			if CLK2 = '1' then

			-- init signal from AVR
			if (LOADED = '1' and last_loaded = '0') then
				last_loaded <= '1';
				last_kb_wait <= KB_WAIT;
				last_kb_mode <= KB_MODE;
				last_turbo <= TURBO;
				last_mode60 <= MODE60;
				last_scandoubler_en <= SCANDOUBLER_EN;
				last_rom_bank <= ROM_BANK;
				last_ssg_mode <= SSG_MODE;
				last_ssg_stereo <= SSG_STEREO;
				last_covox <= COVOX_EN;
				last_turbo_fdc <= TURBO_FDC;
				cnt <= "0000";
				line1 <= message_karabas;
				line2 <= VER;
			elsif (LOADED = '1') then
			
				-- wait switch
				if (KB_WAIT /= last_kb_wait) then
					last_kb_wait <= KB_WAIT;
					cnt <= "0000";
					line1 <= message_pause;
					if (kb_wait = '0') then 
						line2 <= message_off;
					else 
						line2 <= message_on;
					end if;
				end if;
				
				-- keyboard mode switch
				if (KB_MODE /= last_kb_mode) then
					last_kb_mode <= KB_MODE;
					cnt <= "0000";
					line1 <= message_keyboard;
					if (kb_mode = '0') then 
						line2 <= message_spectrum;
					else 
						line2 <= message_profi;
					end if;
				end if;
				
				-- turbo mode switch
				if (TURBO /= last_turbo) then
					last_turbo <= TURBO;
					cnt <= "0000";
					line1 <= message_turbo;
					if (turbo = '0') then 
						line2 <= message_on;
					else 
						line2 <= message_off;
					end if;
				end if;
				
				-- vga/rgb 50/60 hz switches
				if (MODE60 /= last_mode60 or scandoubler_en /= last_scandoubler_en) then 
					last_mode60 <= mode60;
					last_scandoubler_en <= scandoubler_en;
					cnt <= "0000";
					if (scandoubler_en = '1') then 
						line1 <= message_vga;
					else 
						line1 <= message_rgb;
					end if;
					if (mode60 = '1') then 
						line2 <= message_60hz;
					else 
						line2 <= message_50hz;
					end if;
				end if;
				
				-- rombank switch
				if (ROM_BANK /= last_rom_bank) then
					last_rom_bank <= ROM_BANK;
					cnt <= "0000";
					line1 <= message_rombank;
					if (ROM_BANK = "00") then 
						line2 <= message_rombank0;
					elsif (ROM_BANK = "01") then 
						line2 <= message_rombank1;
					elsif (ROM_BANK = "10") then 
						line2 <= message_rombank2;
					else 
						line2 <= message_rombank3;
					end if;
				end if;
				
				-- ssg mode switch
				if (SSG_MODE /= last_ssg_mode or SSG_STEREO /= last_ssg_stereo) then
					last_ssg_mode <= SSG_MODE;
					last_ssg_stereo <= SSG_STEREO;
					cnt <= "0000";
					line1 <= message_ssgmode;
					if (SSG_MODE = '0' and SSG_STEREO = '0') then 
						line2 <= message_ym_acb;
					elsif (SSG_MODE = '0' and SSG_STEREO = '1') then 
						line2 <= message_ym_abc;
					elsif (SSG_MODE = '1' and SSG_STEREO = '0') then 
						line2 <= message_ay_acb;
					else 
						line2 <= message_ay_abc;
					end if;
				end if;
				
				-- turbo fdc mode switch
				if (TURBO_FDC /= last_turbo_fdc) then
					last_turbo_fdc <= TURBO_FDC;
					cnt <= "0000";
					line1 <= message_turbo_fdc;
					if (turbo_fdc = '0') then 
						line2 <= message_off;
					else 
						line2 <= message_on;
					end if;
				end if;
				
				-- covox mode switch
				if (COVOX_EN /= last_covox) then
					last_covox <= COVOX_EN;
					cnt <= "0000";
					line1 <= message_covox;
					if (covox_en = '0') then 
						line2 <= message_off;
					else 
						line2 <= message_on;
					end if;
				end if;
			end if;

			-- enable counter
			last_blink <= BLINK;
			if (BLINK = '1' and last_blink = '0' and cnt /= "1000") then 
				cnt <= cnt + 1;
			end if;
			
			end if;
			
		end if;
	end process;
	
	en <= '1' when cnt /= "1000" else '0';

end architecture;
