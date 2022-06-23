library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity icons is
	port (
		CLK		: in std_logic;
		CLK2 		: in std_logic;
		CLK4 		: in std_logic;
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);
		DS80		: in std_logic;
		HCNT		: in std_logic_vector(9 downto 0);
		VCNT		: in std_logic_vector(8 downto 0);
		
		STATUS_SD : in std_logic := '0'; -- SD card r/w status
		STATUS_CF : in std_logic := '0'; -- CF card r/w status
		STATUS_FD : in std_logic := '0'; -- FDD r/w status
		OSD_ICONS : in std_logic := '0' -- enable OSD icons
	);
end entity;

architecture rtl of icons is

	 component rom_font2
    port (
        address : in std_logic_vector(10 downto 0);
        clock   : in std_logic;
        q       : out std_logic_vector(0 downto 0)
    );
    end component;	 

	 signal icon_addr : std_logic_vector(10 downto 0);
	 
	 signal paper_icon_fd : std_logic := '0';
	 signal paper_icon_sd : std_logic := '0';
	 signal paper_icon_cf : std_logic := '0';
	 signal paper2_icon_fd : std_logic := '0';
	 signal paper2_icon_sd : std_logic := '0';
	 signal paper2_icon_cf : std_logic := '0';	 
	 signal icon_x : std_logic_vector(3 downto 0);
	 signal icon_y : std_logic_vector(3 downto 0);
	 signal icon_pixel : std_logic_vector(0 downto 0);
	 signal icon_pixel_reg: std_logic;	 
	 signal is_icon_fd : std_logic := '0';
	 signal is_icon_sd : std_logic := '0';
	 signal is_icon_cf : std_logic := '0';	 

	 constant icon_color: std_logic_vector(8 downto 0) := "000011001";
	 
	 constant icons_start_profi_h : natural := 264;
	 constant icons_start_spec_h : natural := 288;
	 constant icons_start_v : natural := 0;
	 constant icon_w : natural := 16;
	 constant icon_h : natural := 16;
	 
	 signal icons_h : std_logic := '0';
	 signal icons_h8 : std_logic := '0';
	 
	 signal icon_pos : std_logic_vector(2 downto 0);
	 
	 signal cnt_icon_fd : std_logic_vector(20 downto 0) := (others => '1');
	 signal cnt_icon_sd : std_logic_vector(20 downto 0) := (others => '1'); 
	 signal cnt_icon_cf : std_logic_vector(20 downto 0) := (others => '1');
	 
begin

	 -- иконки
	 U_FONT_ICONS: rom_font2
    port map (
        address => icon_addr,
        clock   => CLK,
        q       => icon_pixel
    );
		
	 icon_x <= hcnt(3 downto 0);
	 icon_y <= vcnt(3 downto 0);

	 icons_h <= '1' when ((DS80='1' and hcnt >= icons_start_profi_h and hcnt < icons_start_profi_h + icon_w) 
									 or (DS80='0' and hcnt >= icons_start_spec_h and hcnt < icons_start_spec_h + icon_w)) else '0';
									 
	 paper_icon_fd <= '1' when icons_h = '1' and vcnt >= icons_start_v and vcnt < icons_start_v + icon_h else '0';
	 paper_icon_sd <= '1' when icons_h = '1' and vcnt >= icons_start_v + icon_h and vcnt < icons_start_v + 2*icon_h else '0';
	 paper_icon_cf <= '1' when icons_h = '1' and vcnt >= icons_start_v + 2*icon_h and vcnt < icons_start_v + 3*icon_h else '0';
	 
	 icon_pos <= "000" when paper_icon_fd = '1' else
					 "001" when paper_icon_sd = '1' else 
					 "010" when paper_icon_cf = '1' else 
					 icon_pos;
	 
	 -- адрес иконок для чтения
	 -- 0-1: 0...63,      0-2: 64...127,    1-1: 128...191,   1-2: 192...255,   2-1: 256...319,   2-2: 320...384,
	 -- 0-3: 1024...1087, 0-4: 1088...1151, 1-3: 1152...1215, 1-4: 1216...1279, 2-3: 1280...1343, 2-4: 1344...1408

	 -- icon:
	 --      y3 pos x3 y2-y0 x2-x0
	 
	 -- icon 0:
	 -- 0:    0 000 0 000 000
	 -- 64:   0 000 1 000 000
	 -- 1024: 1 000 0 000 000
	 -- 1088: 1 000 1 000 000
	 
	 -- icon 1:
	 -- 128:  0 001 0 000 000
	 -- 192:  0 001 1 000 000
	 -- 1152: 1 001 0 000 000
	 -- 1216: 1 001 1 000 000
	 
	 -- icon 2:
	 -- 256:  0 010 0 000 000
	 -- 320:  0 010 1 000 000
	 -- 1280: 1 010 0 000 000
	 -- 1344: 1 010 1 000 000
	 
	 icon_addr <= icon_y(3) & icon_pos &  not(icon_x(3)) & icon_y(2 downto 0) & icon_x(2 downto 0) when DS80='1' else 
					  icon_y(3) & icon_pos &  icon_x(3) & icon_y(2 downto 0) & icon_x(2 downto 0); --spectrum pos shifter 8 px

	 process(CLK, CLK2, STATUS_FD, STATUS_SD, STATUS_CF)
	 begin 
		if (rising_edge(CLK)) then
			if (CLK2 = '0') then
				if (STATUS_FD = '1') then 
					cnt_icon_fd <= (others => '0');
				elsif (cnt_icon_fd < "111111111111111111111") then 
					cnt_icon_fd <= cnt_icon_fd + 1;
				end if;
				if (STATUS_SD = '1') then 
					cnt_icon_sd <= (others => '0');
				elsif (cnt_icon_sd < "111111111111111111111") then 
					cnt_icon_sd <= cnt_icon_sd + 1;
				end if;
				if (STATUS_CF = '1') then 
					cnt_icon_cf <= (others => '0');
				elsif (cnt_icon_cf < "111111111111111111111") then 
					cnt_icon_cf <= cnt_icon_cf + 1;
				end if;
			end if;
		end if;
	 end process;
	 
	 is_icon_fd <= '1' when cnt_icon_fd < "111111111111111111111" else '0';
	 is_icon_sd <= '1' when cnt_icon_sd < "111111111111111111111" else '0';
	 is_icon_cf <= '1' when cnt_icon_cf < "111111111111111111111" else '0';

    -- формирование RGB
    RGB_O <= 
				icon_color when paper_icon_fd = '1' and icon_pixel(0) = '1' and is_icon_fd = '1' else 
				icon_color when paper_icon_sd = '1' and icon_pixel(0) = '1' and is_icon_sd = '1' else 
				icon_color when paper_icon_cf = '1' and icon_pixel(0) = '1' and is_icon_cf = '1' else
				RGB_I;

end architecture;
