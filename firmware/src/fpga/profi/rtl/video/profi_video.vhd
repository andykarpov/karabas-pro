-------------------------------------------------------------------------------
-- VIDEO Profi CP/M mode
-------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity profi_video is
	port (
		CLK2X		: in std_logic; -- 24
		CLK		: in std_logic; -- 12					
		ENA		: in std_logic; -- 6
		INTA		: in std_logic;
		INT		: out std_logic;
		BORDER	: in std_logic_vector(3 downto 0);	
		A			: out std_logic_vector(13 downto 0);
		PAL_A 	: out std_logic_vector(3 downto 0);
		BUS_D 	: in std_logic_vector(7 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		RGB		: out std_logic_vector(2 downto 0);	-- RGB
		I 			: out std_logic;
		BLANK 	: out std_logic;
		HSYNC		: out std_logic;
		VSYNC		: out std_logic;		
		HCNT 		: out std_logic_vector(9 downto 0);
		VCNT 		: out std_logic_vector(8 downto 0);	
		DS80 		: in std_logic;
		VBUS_MODE : in std_logic := '0';
		VID_RD : in std_logic
	);
end entity;

architecture rtl of profi_video is
-- Profi-CPM screen mode
	constant pcpm_scr_h			: natural := 512;
	constant pcpm_brd_right		: natural :=  40;	-- для выравнивания из-за задержки на чтение vid_reg и attr_reg задано на 8 точек больше
	constant pcpm_blk_front		: natural :=  48;--32
	constant pcpm_sync_h			: natural :=  64;
	constant pcpm_blk_back		: natural :=  80;--96
	constant pcpm_brd_left		: natural :=  24;	-- для выравнивания из-за задержки на чтение vid_reg и attr_reg задано на 8 точек меньше

	constant pcpm_scr_v			: natural := 240;
	constant pcpm_brd_bot		: natural :=  8;--16
	constant pcpm_blk_down		: natural :=  40;--16
	constant pcpm_sync_v			: natural :=  16;--16
	constant pcpm_blk_up			: natural :=  8;--16
	constant pcpm_brd_top		: natural :=  8;--16

	constant pcpm_h_blk_on		: natural := (pcpm_scr_h + pcpm_brd_right) - 1;
	constant pcpm_h_sync_on		: natural := (pcpm_scr_h + pcpm_brd_right + pcpm_blk_front) - 1;
	constant pcpm_h_sync_off	: natural := (pcpm_scr_h + pcpm_brd_right + pcpm_blk_front + pcpm_sync_h);
	constant pcpm_h_blk_off		: natural := (pcpm_scr_h + pcpm_brd_right + pcpm_blk_front + pcpm_sync_h + pcpm_blk_back);
	constant pcpm_h_end			: natural := 767;

	constant pcpm_v_blk_on		: natural := (pcpm_scr_v + pcpm_brd_bot) - 1;
	constant pcpm_v_sync_on		: natural := (pcpm_scr_v + pcpm_brd_bot + pcpm_blk_down) - 1;
	constant pcpm_v_sync_off	: natural := (pcpm_scr_v + pcpm_brd_bot + pcpm_blk_down + pcpm_sync_v);
	constant pcpm_v_blk_off		: natural := (pcpm_scr_v + pcpm_brd_bot + pcpm_blk_down + pcpm_sync_v + pcpm_blk_up);
	constant pcpm_v_end			: natural := 319;

	constant pcpm_h_int_on		: natural := 752; --pspec_sync_h+8;
	constant pcpm_v_int_on		: natural := 303; --pspec_v_blk_off - 1;
	constant pcpm_h_int_off		: natural := 128;
	constant pcpm_v_int_off		: natural := 304;

-- INT  Y303,X752  - Y304,X128

---------------------------------------------------------------------------------------	

	signal h_cnt			: unsigned(9 downto 0) := (others => '0');
	signal v_cnt			: unsigned(8 downto 0) := (others => '0');
	signal paper			: std_logic;
	signal paper1			: std_logic;
	signal flash			: unsigned(4 downto 0) := (others => '0');
	signal vid_reg			: std_logic_vector(7 downto 0);
	signal pixel_reg		: std_logic_vector(7 downto 0);
	signal at_reg			: std_logic_vector(7 downto 0);	
	signal attr_reg		: std_logic_vector(7 downto 0);
	signal h_sync			: std_logic;
	signal v_sync			: std_logic;
	signal int_sig			: std_logic;
	signal blank_sig		: std_logic;
	signal scan_cnt		: std_logic_vector(9 downto 0);
	signal scan_cnt1		: std_logic_vector(9 downto 0);
	signal rgbi				: std_logic_vector(3 downto 0);
	signal bl_int 			: std_logic;
	signal infp 			: std_logic;
	signal i78				: std_logic;
	signal selector 		: std_logic_vector(2 downto 0);
	signal blank1 			: std_logic;

begin

-- sync, counters
process (CLK2X, CLK)
begin
	if (CLK2X'event and CLK2X = '1') then
			if (CLK = '1') then		-- 12MHz			
				if (h_cnt = pcpm_h_end) then
					h_cnt <= (others => '0');
				else
					h_cnt <= h_cnt + 1;
				end if;
			
				if (h_cnt = pcpm_h_sync_on) then
					if (v_cnt = pcpm_v_end) then
						v_cnt <= (others => '0');
					else
						v_cnt <= v_cnt + 1;
					end if;
				end if;
				if (h_cnt = pcpm_h_sync_on) then
					scan_cnt1 <= (others => '0');
				else
					scan_cnt1 <= scan_cnt1 + 1;
				end if;
				if (v_cnt = pcpm_v_sync_on) then
					v_sync <= '0';
				elsif (v_cnt = pcpm_v_sync_off) then
					v_sync <= '1';
				end if;

				if (h_cnt = pcpm_h_sync_on) then
					h_sync <= '0';
				elsif (h_cnt = pcpm_h_sync_off) then
					h_sync <= '1';
				end if;

				
				if (h_cnt > pcpm_h_int_on  and v_cnt = pcpm_v_int_on) or (h_cnt < pcpm_h_int_off and v_cnt = pcpm_v_int_off) then
					int_sig <= '0'; else	int_sig <= '1';
				end if;				
			end if;
	end if;
end process;

-- pixel / attr registers
process( CLK2X, CLK, h_cnt )
	begin
		if CLK2X'event and CLK2X = '1' then
			if CLK = '1' then
				if h_cnt(2 downto 0) = 7 then
					pixel_reg <= vid_reg;
					attr_reg <= at_reg;
					paper1 <= paper;
					blank1 <= blank_sig;
				end if;
			end if;
		end if;
	end process;

-- memory read
process(CLK2X, CLK, ENA, h_cnt, VBUS_MODE, VID_RD)
begin
	if CLK2X'event and CLK2X='1' then 
		if (CLK = '0' and h_cnt(2 downto 0) < 7) then -- 12 mhz falling edge
			if (VBUS_MODE = '1') then
				if VID_RD = '0' then 
					vid_reg <= DI;
				else 
					at_reg <= DI;
				end if;
			end if;				
		end if;
	end if;
end process;

process (CLK2X, CLK, blank_sig, paper1, pixel_reg, h_cnt, attr_reg, BORDER)
begin 
	if CLK2X'event and CLK2X='1' then 
		if CLK = '1' then
			if (blank1 = '1') then 
				rgbi <= "0000";
			elsif paper1 = '1' and (pixel_reg(7 - to_integer(h_cnt(2 downto 0)))) = '0' then 
				rgbi <= attr_reg(4) & attr_reg(5) & attr_reg(3) & i78;
			elsif paper1 = '1' and (pixel_reg(7 - to_integer(h_cnt(2 downto 0)))) = '1' then 
				rgbi <= attr_reg(1) & attr_reg(2) & attr_reg(0) & attr_reg(6);
			else
				rgbi <= BORDER(1) & BORDER(2) & BORDER(0) & '0';
			end if;
		end if;
	end if;
end process;

selector <= paper1 & infp & pixel_reg(7 - to_integer(h_cnt(2 downto 0)));

-- адрес пикселя палитры до blank
process (CLK2X, CLK, selector, i78, blank_sig, paper1, pixel_reg, h_cnt, attr_reg, BORDER)
begin 
	case (selector) is
		when "100" | "110" => PAL_A <= i78 & attr_reg(5 downto 3);
		when "101" | "111" => PAL_A <= attr_reg(6) & attr_reg(2 downto 0);
		when "010" | "011" => PAL_A <= (not BORDER(3)) & (not BORDER(2 downto 0));
		when "000" | "001" => PAL_A <= (not BORDER(3)) & BORDER(2 downto 0);
		when others => null;
	end case;
end process;

infp <= not blank1 and ds80; -- testing
i78 <= attr_reg(7) when ds80 = '1' else attr_reg(6);
		
A <= std_logic_vector((not h_cnt(3)) & v_cnt(7 downto 6)) & std_logic_vector(v_cnt(2 downto 0)) & std_logic_vector(v_cnt(5 downto 3)) & std_logic_vector(h_cnt(8 downto 4));		
		
blank_sig	<= '1' when (((h_cnt > pcpm_h_blk_on and h_cnt < pcpm_h_blk_off) or (v_cnt > pcpm_v_blk_on and v_cnt < pcpm_v_blk_off))) else '0';
paper			<= '1' when ((h_cnt < pcpm_scr_h and v_cnt < pcpm_scr_v)) else '0';

INT			<= int_sig;
bl_int 		<= int_sig;
RGB 			<= rgbi(3 downto 1);
I 				<= rgbi(0);
HSYNC 		<= h_sync;
VSYNC 		<= v_sync;
HCNT <= std_logic_vector(h_cnt);
VCNT <= std_logic_vector(v_cnt);
BLANK <= blank1;

end architecture;