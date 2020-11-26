library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity osd is
	port (
		CLK		: in std_logic;
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);
		DS80		: in std_logic;
		HCNT_I	: in std_logic_vector(9 downto 0);
		VCNT_I	: in std_logic_vector(8 downto 0);
		BLINK 	: in std_logic;
		
		-- sensors
		TURBO 			: in std_logic := '0';
		SCANDOUBLER_EN : in std_logic := '0';
		MODE60 			: in std_logic := '0';
		ROM_BANK 		: in std_logic_vector := "00"

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
	signal char:   std_logic_vector(7 downto 0);
	
	signal rom_addr: std_logic_vector(11 downto 0);
	signal font_word: std_logic_vector(7 downto 0);
	signal vpos : std_logic_vector(1 downto 0) := "00";
	signal bit_addr: std_logic_vector(2 downto 0);
	signal pixel: std_logic;
	
	-- 8 characters
	type lcd_line_type is array(0 to 7) of character;
	
	-- Define messages displayed
	constant message_turbo: 	lcd_line_type 	:= "TURBO   ";
	constant message_vga: 		lcd_line_type 	:= "VGA     ";
	constant message_rgb: 		lcd_line_type 	:= "RGB     ";
	constant message_on:	 		lcd_line_type 	:= "ON      ";
	constant message_off: 		lcd_line_type 	:= "OFF     ";
	constant message_rombank: 	lcd_line_type 	:= "ROM BANK";
	constant message_rombank0:	lcd_line_type 	:= "FATALL  ";
	constant message_rombank1:	lcd_line_type 	:= "STANDARD";
	constant message_rombank2:	lcd_line_type 	:= "FLASHER ";
	constant message_rombank3:	lcd_line_type 	:= "DIAG ROM";
	constant message_50hz: 		lcd_line_type 	:= "50 Hz   ";
	constant message_60hz: 		lcd_line_type 	:= "60 Hz   ";
	constant message_empty: 	lcd_line_type 	:= "        ";

	-- displayable lines
	signal line1 : lcd_line_type := message_empty;
	signal line2 : lcd_line_type := message_empty;
	
	signal last_turbo : std_logic := '0';
	signal last_scandoubler_en : std_logic := '0';
	signal last_mode60 : std_logic := '0';
	signal last_rom_bank : std_logic_vector(1 downto 0) := "00";
	
	signal cnt : std_logic_vector(2 downto 0) := "100";
	signal en : std_logic := '0';
	
	signal last_blink : std_logic := '0';
	
begin

	hcnt <= HCNT_I;
	vcnt <= VCNT_I;
	
	-- font rom
	U_FONT: rom_font
   port map (
		address => rom_addr,
      clock   => CLK,
      q       => font_word
   );
	 
	char_x <= hcnt(2 downto 0);
   char_y <= vcnt(3 downto 0);
	rom_addr <= char & char_y;

	-- vertical bounds for line1 / line2
	vpos(0) <= '1' when (DS80='0' and vcnt >= 288 and vcnt < 304) or (DS80='1' and vcnt >= 16 and vcnt < 32) else '0';
	vpos(1) <= '1' when (DS80='0' and vcnt >= 304 and vcnt < 320) or (DS80='1' and vcnt >= 32 and vcnt < 48) else '0';

	-- character to request from the ROM depends on the line1 / line2 horizontal position
	char <= std_logic_vector(to_unsigned(character'pos(line1(to_integer(unsigned(hcnt(5 downto 3))))), 8)) when vpos(0) = '1' and hcnt < 64 else 
			  std_logic_vector(to_unsigned(character'pos(line2(to_integer(unsigned(hcnt(5 downto 3))))), 8)) when vpos(1) = '1' and hcnt < 64 else 
			  (others => '0');

	-- pixel 
	bit_addr <= char_x(2 downto 0);
   pixel <=  font_word(7) when bit_addr = "000" else 
				 font_word(6) when bit_addr = "001" else 
				 font_word(5) when bit_addr = "010" else 
				 font_word(4) when bit_addr = "011" else 
				 font_word(3) when bit_addr = "100" else 
				 font_word(2) when bit_addr = "101" else 
				 font_word(1) when bit_addr = "110" else 
				 font_word(0) when bit_addr = "111";

	RGB_O <= "000111000" when en = '1' and pixel = '1' else RGB_I;

	-- display messages for changed sensors
	process (CLK, BLINK, cnt, TURBO, SCANDOUBLER_EN, MODE60, ROM_BANK, last_turbo, last_scandoubler_en, last_mode60, last_rom_bank)
	begin 
		if rising_edge(CLK) then 

			-- turbo mode switch
			if (TURBO /= last_turbo) then
				last_turbo <= TURBO;
				cnt <= "000";
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
				cnt <= "000";
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
				cnt <= "000";
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
		
			-- enable counter
			last_blink <= BLINK;
			if (BLINK = '1' and last_blink = '0' and cnt /= "100") then 
				cnt <= cnt + 1;
			end if;
			
		end if;
	end process;
	
	en <= '1' when cnt /= "100" else '0';

end architecture;