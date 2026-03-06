-------------------------------------------------------------------[13.08.2016]
-- VGA
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE; 
	use IEEE.std_logic_1164.all; 
	use IEEE.std_logic_unsigned.all;
	use IEEE.numeric_std.all;
	
entity vga is
port (
	I_CLK		: in std_logic;
	I_CLK_VGA	: in std_logic;
	I_COLOR		: in std_logic_vector(5 downto 0);
	I_HCNT		: in std_logic_vector(8 downto 0);
	I_VCNT		: in std_logic_vector(8 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_RED		: out std_logic_vector(2 downto 0);
	O_GREEN		: out std_logic_vector(2 downto 0);
	O_BLUE		: out std_logic_vector(2 downto 0);
	O_HCNT		: out std_logic_vector(9 downto 0);
	O_VCNT		: out std_logic_vector(9 downto 0);
	O_H		: out std_logic_vector(9 downto 0);
	O_BLANK		: out std_logic);
end vga;

architecture rtl of vga is
	signal rgb		: std_logic_vector(8 downto 0);
	signal pixel_out	: std_logic_vector(5 downto 0);
	signal addr_rd		: std_logic_vector(15 downto 0);
	signal addr_wr		: std_logic_vector(15 downto 0);
	signal wren		: std_logic;
	signal picture		: std_logic;
	signal window_hcnt	: std_logic_vector(8 downto 0) := "000000000";
	signal hcnt		: std_logic_vector(9 downto 0) := "0000000000";
	signal h		: std_logic_vector(9 downto 0) := "0000000000";
	signal vcnt		: std_logic_vector(9 downto 0) := "0000000000";
	signal hsync		: std_logic;
	signal vsync		: std_logic;
	signal blank		: std_logic;

-- ModeLine "640x480@60Hz"  25,175  640  656  752  800 480 490 492 525 -HSync -VSync
	-- Horizontal Timing constants  
	constant h_pixels_across	: integer := 640 - 1;
	constant h_sync_on		: integer := 656 - 1;
	constant h_sync_off		: integer := 752 - 1;
	constant h_end_count		: integer := 800 - 1;
	-- Vertical Timing constants
	constant v_pixels_down		: integer := 480 - 1;
	constant v_sync_on		: integer := 490 - 1;
	constant v_sync_off		: integer := 492 - 1;
	constant v_end_count		: integer := 525 - 1;
	
begin
	
	altsram: entity work.framebuffer -- 64k x 6bit
	port map(
		clock_a => I_CLK,
		wren_a => wren,
		address_a => addr_wr,
		data_a => I_COLOR,
		q_a => open,
		
		clock_b => I_CLK_VGA,
		address_b => addr_rd,
		wren_b => '0',
		data_b => (others => '0'),
		q_b => pixel_out
	);

	-- NES Palette -> RGB333 conversion (http://www.thealmightyguru.com/Games/Hacking/Wiki/index.php?title=NES_Palette)
	process (pixel_out)
   begin
    case pixel_out is
        when "000000" => rgb <= "011011011";
        when "000001" => rgb <= "000000111";
        when "000010" => rgb <= "000000101";
        when "000011" => rgb <= "010001101";
        when "000100" => rgb <= "100000100";
        when "000101" => rgb <= "101000001";
        when "000110" => rgb <= "101000000";
        when "000111" => rgb <= "100000000";
        when "001000" => rgb <= "010001000";
        when "001001" => rgb <= "000011000";
        when "001010" => rgb <= "000011000";
        when "001011" => rgb <= "000010000";
        when "001100" => rgb <= "000010010";
        when "001101" => rgb <= "000000000";
        when "001110" => rgb <= "000000000";
        when "001111" => rgb <= "000000000";

        when "010000" => rgb <= "101101101";
        when "010001" => rgb <= "000011111";
        when "010010" => rgb <= "000010111";
        when "010011" => rgb <= "011010111";
        when "010100" => rgb <= "110000110";
        when "010101" => rgb <= "111000010";
        when "010110" => rgb <= "111001000";
        when "010111" => rgb <= "111010000";
        when "011000" => rgb <= "101011000";
        when "011001" => rgb <= "000101000";
        when "011010" => rgb <= "000101000";
        when "011011" => rgb <= "000101010";
        when "011100" => rgb <= "000100100";
        when "011101" => rgb <= "000000000";
        when "011110" => rgb <= "000000000";
        when "011111" => rgb <= "000000000";

        when "100000" => rgb <= "111111111";
        when "100001" => rgb <= "001101111";
        when "100010" => rgb <= "011100111";
        when "100011" => rgb <= "100011111";
        when "100100" => rgb <= "111011111";
        when "100101" => rgb <= "111010100";
        when "100110" => rgb <= "111011010";
        when "100111" => rgb <= "111101010";
        when "101000" => rgb <= "111101000";
        when "101001" => rgb <= "101111000";
        when "101010" => rgb <= "010110010";
        when "101011" => rgb <= "010111100";
        when "101100" => rgb <= "000111110";
        when "101101" => rgb <= "011011011";
        when "101110" => rgb <= "000000000";
        when "101111" => rgb <= "000000000";

        when "110000" => rgb <= "111111111";
        when "110001" => rgb <= "101111111";
        when "110010" => rgb <= "101101111";
        when "110011" => rgb <= "110101111";
        when "110100" => rgb <= "111101111";
        when "110101" => rgb <= "111101110";
        when "110110" => rgb <= "111110101";
        when "110111" => rgb <= "111111101";
        when "111000" => rgb <= "111110011";
        when "111001" => rgb <= "110111011";
        when "111010" => rgb <= "101111101";
        when "111011" => rgb <= "101111110";
        when "111100" => rgb <= "000111111";
        when "111101" => rgb <= "111110111";
        when "111110" => rgb <= "000000000";
        when "111111" => rgb <= "000000000";

        when others => null;
    end case;
    end process;
	
	process (I_CLK_VGA)
	begin
		if I_CLK_VGA'event and I_CLK_VGA = '1' then
			if h = h_end_count then
				h <= (others => '0');
			else
				h <= h + 1;
			end if;
		
			if h = 7 then
				hcnt <= (others => '0');
			else
				hcnt <= hcnt + 1;
				if hcnt = 63 then
					window_hcnt <= (others => '0');
				else
					window_hcnt <= window_hcnt + 1;
				end if;
			end if;
			if hcnt = h_sync_on then
				if vcnt = v_end_count then
					vcnt <= (others => '0');
				else
					vcnt <= vcnt + 1;
				end if;
			end if;
		end if;
	end process;
	
	wren	<= '1' when (I_HCNT < 256) and (I_VCNT < 240) else '0';
	addr_wr	<= I_VCNT(7 downto 0) & I_HCNT(7 downto 0);
	addr_rd	<= vcnt(8 downto 1) & window_hcnt(8 downto 1);
	blank	<= '1' when (hcnt > h_pixels_across) or (vcnt > v_pixels_down) else '0';
	picture	<= '1' when (blank = '0') and (hcnt > 64 and hcnt < 576) else '0';

	O_HSYNC	<= '1' when (hcnt <= h_sync_on) or (hcnt > h_sync_off) else '0';
	O_VSYNC	<= '1' when (vcnt <= v_sync_on) or (vcnt > v_sync_off) else '0';
	O_RED	<= rgb(8 downto 6) when picture = '1' else (others => '0');
	O_GREEN	<= rgb(5 downto 3) when picture = '1' else (others => '0');
	O_BLUE	<= rgb(2 downto 0) when picture = '1' else (others => '0');
	O_BLANK	<= blank;
	O_HCNT	<= hcnt;
	O_VCNT	<= vcnt;
	O_H	<= h;
	
end rtl;
