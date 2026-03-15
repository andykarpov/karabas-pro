library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity overlay is
	port (
		CLK_BUS	: in std_logic;
		CLK		: in std_logic;
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);
		HSYNC_I 	: in std_logic;
		VSYNC_I 	: in std_logic;
		OSD_COMMAND 	: in std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of overlay is

    signal video_on : std_logic;

    signal attr, attr2: std_logic_vector(7 downto 0);
    signal bitmap, bitmap2: std_logic_vector(7 downto 0);

    signal char_x: std_logic_vector(2 downto 0);
    signal char_y: std_logic_vector(2 downto 0);

    signal rom_addr: std_logic_vector(10 downto 0);
    signal row_addr: std_logic_vector(2 downto 0);
    signal bit_addr: std_logic_vector(2 downto 0);
    signal font_word: std_logic_vector(7 downto 0);
    signal font_reg : std_logic_vector(7 downto 0);	 
	 signal pixel_reg: std_logic;
    
    signal addr_read: std_logic_vector(9 downto 0);
    signal addr_write: std_logic_vector(9 downto 0);
    signal vram_di: std_logic_vector(15 downto 0);
    signal vram_do: std_logic_vector(15 downto 0);
    signal vram_wr: std_logic := '0';

    signal flash : std_logic;
    signal is_flash : std_logic;
    signal rgb_fg : std_logic_vector(8 downto 0);
    signal rgb_bg : std_logic_vector(8 downto 0);

    signal selector : std_logic_vector(3 downto 0);
	 signal last_osd_command : std_logic_vector(15 downto 0);
	 signal char_buf : std_logic_vector(7 downto 0);
	 signal paper : std_logic := '0';
	 signal paper2 : std_logic := '0';
	 
 	 signal osd_overlay: std_logic := '0';
	 signal osd_popup: std_logic := '0';
	 
	 signal osdfont_addr : std_logic_vector(10 downto 0) := (others => '1');
	 signal osdfont_data : std_logic_vector(7 downto 0);
	 signal osdfont_we : std_logic:= '0';
	 signal osdfont_upd, osdfont_prev_upd : std_logic := '0';	 
	 
	 constant paper_chars_h : natural := 32; -- count of characters in row
	 constant paper_chars_v : natural := 26; -- count of characters in column
	 
	 constant paper_start_h : natural := 0;
	 constant paper_end_h : natural := (paper_chars_h * 8);
	 constant paper_start_v : natural := 0;
	 constant paper_end_v : natural := (paper_chars_v * 8);
	 
	 signal load_pixel : std_logic := '0';
	 signal load_dbl: std_logic; -- load pix doubler shift register
	 signal shift_dbl: std_logic; -- shift the doubler shift register	 
	 
	 signal hcnt, hcnt_i : std_logic_vector(10 downto 0) := (others => '0');
	 signal vcnt, vcnt_i : std_logic_vector(10 downto 0) := (others => '0');	 
	 signal width, height: std_logic_vector(10 downto 0) := (others => '0');

	 signal hsync_pol, vsync_pol : std_logic := '0';
	 signal prev_hsync, prev_vsync : std_logic := '0';
	 signal hsync, vsync : std_logic;
	 
	 signal flash_cnt : std_logic_vector(7 downto 0);
	 
	 constant h_offset : natural := 48;
	 constant v_offset : natural := 32;	
	 
begin

	hsync_pol <= '1';
	vsync_pol <= '1';
	
	hsync <= HSYNC_I;
	vsync <= VSYNC_I;
	
	-- hcnt, vcnt, width, height
	process(CLK)
	begin
		if rising_edge(CLK) then
			
				prev_hsync <= hsync;				
				if hsync = hsync_pol and prev_hsync /= hsync then -- new line (start of hsync pulse)
					width <= hcnt_i;
					hcnt_i <= (others => '0');
					vcnt_i <= vcnt_i + 1;
					
					prev_vsync <= vsync;					
					if vsync = vsync_pol and prev_vsync /= vsync then -- start of new frame (vsync pulse)
						height <= vcnt_i;
						vcnt_i <= (others => '0');
						flash_cnt <= flash_cnt + 1;
					end if;
				else 
					hcnt_i <= hcnt_i + 1;
				end if;
		end if;
	end process;

	-- normalize h/v values
	hcnt <= hcnt_i(10 downto 0) - h_offset when width < 500 else 
			  '0' & hcnt_i(10 downto 1) - h_offset when width < 1000 else 
			  "00" & hcnt_i(10 downto 2) - h_offset;

	vcnt <= vcnt_i(10 downto 0) - v_offset when height < 400 else 
			  '0' & vcnt_i(10 downto 1) - v_offset when height < 800 else 
			  "00" & vcnt_i(10 downto 2) - v_offset;

	 -- 8x8 font RAM
	 U_FONT: entity work.font_rom
	 port map(
		clock_a => CLK_BUS,
		address_a => osdfont_addr,
		data_a => osdfont_data,
		wren_a => osdfont_we,
		q_a => open,
		
		clock_b => CLK,
		address_b => rom_addr,
		data_b => "00000000",
		wren_b => '0',
		q_b => font_word
	 );	 

	 -- OSD VRAM
	 U_VRAM: entity work.osd_vram
	 port map(
		clock_a => CLK_BUS,
		address_a => addr_write,
		data_a => vram_di,
		wren_a => vram_wr,
		q_a => open,
		
		clock_b => CLK,
		address_b => addr_read,
		data_b => "0000000000000000",
		wren_b => '0',
		q_b => vram_do
	 );	 

	 flash <= flash_cnt(5);

    char_x <= hcnt(3 downto 1) when OSD_POPUP = '1' else hcnt(2 downto 0);
    char_y <= vcnt(3 downto 1) when OSD_POPUP = '1' else VCNT(2 downto 0);
	 
	 paper2 <= '1' when hcnt >= paper_start_h and hcnt < paper_end_h and vcnt >= paper_start_v and vcnt < paper_end_v else '0'; 
	 paper <= '1' when hcnt >= paper_start_h + 8 and hcnt < paper_end_h + 8 and vcnt >= paper_start_v and vcnt < paper_end_v else '0'; --        (8 px)
    video_on <= '1' when (OSD_OVERLAY = '1' or OSD_POPUP = '1') else '0';
	 
	 -- mem read character / attribute
	 -- paper2 -> load
	 -- paper -> active
	 process (CLK, font_word, osd_popup, paper2, hcnt, vcnt, vram_do)
	 begin
--		if (rising_edge(CLK)) then 
				if (OSD_POPUP = '1') then 
					if paper2 = '1' then
						case (hcnt(3 downto 0)) is
						
							when "1001" => addr_read <= VCNT(8 downto 4) & HCNT(8 downto 4); -- load char from vram
							when "1010" => attr2 <= vram_do(7 downto 0); -- save attribute to tmp reg
												rom_addr <= vram_do(15 downto 8) & VCNT(3 downto 1); -- load bitmap from font ram
							when "1011" => bitmap2 <= font_word; -- save bitmap to tmp reg
							when others => null;		
						end case;
					end if;
				else 
					if paper2 = '1' then
						case (HCNT(2 downto 0)) is -- read every 8 pixels
							when "100" => addr_read <= VCNT(7 downto 3) & HCNT(7 downto 3); -- ??? hcnt(7:3) ???
							when "101" => attr2 <= vram_do(7 downto 0);
											  rom_addr <= vram_do(15 downto 8) & VCNT(2 downto 0);
							when "110" => bitmap2 <= font_word;
							when others => null;						
						end case;
					end if;
				end if;
--		end if;
	 end process;
	 
	 process (clk) 
	 begin
		if rising_edge(clk) then
			if (OSD_POPUP = '1' and paper2 = '1' and HCNT(3 downto 0) = "1111") or (OSD_POPUP = '0' and paper2 = '1' and HCNT(2 downto 0) = "111") then
					attr <= attr2; bitmap <= bitmap2; -- move attribute and bitmap
			end if;
		end if;
	 end process;	 

	 -- pix doubler load
	 process (CLK) 
	 begin
		if rising_edge(CLK) then
			load_dbl <= '0';
			shift_dbl <= '0';
			-- load
			if ((OSD_POPUP = '0' and HCNT(2 downto 0) = "111" and paper2 = '1') or 
			    (OSD_POPUP = '1' and HCNT(3 downto 0) = "1111" and paper2 = '1')) 
				 then 
				load_dbl <= '1';
			end if;
			-- do
			if ((OSD_POPUP = '0' and HCNT(2 downto 0) /= "111" and paper = '1') or 
			    (OSD_POPUP = '1' and HCNT(3 downto 0) /= "1111" and paper = '1')) 
				 then 
				shift_dbl <= '1';
			end if;
		end if;
	 end process;
	
	-- pix doubler shifter
	 U_DBL: entity work.pix_doubler
	 port map(
		CLK => CLK,
		LOAD => load_dbl,
		SHIFT => shift_dbl,
		D => bitmap,
		QUAD => '1' & OSD_POPUP,
		DOUT => pixel_reg
	 );
	 
    is_flash <= '1' when attr(3 downto 0) = "0001" else '0';
    selector <= video_on & pixel_reg & flash & is_flash;
	 
    rgb_fg <= 
		(attr(7) and attr(4)) & attr(7) & attr(7) &
		(attr(6) and attr(4)) & attr(6) & attr(6) &
		(attr(5) and attr(4)) & attr(5) & attr(5) ;

    rgb_bg <= 
		(attr(3) and attr(0)) & attr(3) & attr(3) &
		(attr(2) and attr(0)) & attr(2) & attr(2) &
		(attr(1) and attr(0)) & attr(1) & attr(1) ;

    RGB_O <= 
				rgb_fg(8 downto 0) when rgb_fg /= 0 and paper = '1' and (selector="1111" or selector="1001" or selector="1100" or selector="1110") else
				rgb_bg(8 downto 0) when rgb_bg /= 0 and paper = '1' and (selector="1011" or selector="1101" or selector="1000" or selector="1010") else
				"0" & RGB_I(8 downto 7) & "0" & RGB_I(5 downto 4) & "0" & RGB_I(2 downto 1) when video_on = '1' else
				RGB_I;

	process(CLK_BUS)
	begin
		  if rising_edge(CLK_BUS) then
				 vram_wr <= '0';
				 last_osd_command <= osd_command;
				 if (osd_command /= last_osd_command) then 
					case osd_command(15 downto 8) is 
					  when x"01" => vram_wr <= '0'; osd_overlay <= osd_command(0); -- osd
					  when x"02" => vram_wr <= '0'; osd_popup <= osd_command(0); -- popup						
					  when X"10"  => vram_wr <= '0'; addr_write(4 downto 0) <= osd_command(4 downto 0); -- x: 0...32
					  when X"11" => vram_wr <= '0'; addr_write(9 downto 5) <= osd_command(4 downto 0); -- y: 0...32
					  when X"12"  => vram_wr <= '0'; char_buf <= osd_command(7 downto 0); -- char
					  when X"13"  => vram_wr <= '1'; vram_di <= char_buf & osd_command(7 downto 0); -- attrs
					  when x"20" => 
								-- reset font address
								if (OSD_COMMAND(0) = '1') then 
									osdfont_addr <= (others => '1');
									osdfont_upd <= '0';
									osdfont_prev_upd <= '0';
								end if;
					  when x"21" => 
								-- new font data
								osdfont_addr <= osdfont_addr + 1;
								osdfont_data <= OSD_COMMAND(7 downto 0);
								osdfont_upd <= not osdfont_upd;
					  when others => vram_wr <= '0';
					end case;
				 end if;
				 
				 -- wr signal / osd font loader
				 osdfont_we <= '0';
				 if (osdfont_prev_upd /= osdfont_upd) then 
					 osdfont_prev_upd <= osdfont_upd;
					 osdfont_we <= '1';
				 end if;
				 
		  end if;
	end process;

end architecture;
