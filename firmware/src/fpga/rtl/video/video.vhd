-------------------------------------------------------------------[16.07.2019]
-- VIDEO Pentagon mode
-------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity video is
	port (
		CLK		: in std_logic;							-- системная частота
		ENA7		: in std_logic;							-- 7MHz ticks
		ENA14 	: in std_logic; 							-- 14MHz ticks
		BORDER	: in std_logic_vector(2 downto 0);	-- цвет бордюра (порт #xxFE)
		TIMEXCFG : in std_logic_vector(7 downto 0);  -- порт Timex (#xxFF)
		DI			: in std_logic_vector(7 downto 0);	-- видеоданные
		TURBO 	: in std_logic := '0';
		INTA		: in std_logic;
		INT		: out std_logic;
		ATTR_O	: out std_logic_vector(7 downto 0);
		A			: out std_logic_vector(13 downto 0);
		BLANK		: out std_logic;							-- BLANK
		RGB		: out std_logic_vector(8 downto 0);	-- RRRGGGBBB
		HSYNC		: out std_logic;
		VSYNC		: out std_logic;
		INVERT_O : out std_logic;
		HCNT_O	: out std_logic_vector(8 downto 0);
		VCNT_O	: out std_logic_vector(8 downto 0)
		);
end entity;

architecture rtl of video is

	signal invert   : unsigned(4 downto 0) := "00000";

	signal chr_col_cnt : unsigned(2 downto 0) := "000"; -- Character column counter
	signal chr_row_cnt : unsigned(2 downto 0) := "000"; -- Character row counter

	signal hor_cnt  : unsigned(5 downto 0) := "000000"; -- Horizontal char counter
	signal ver_cnt  : unsigned(5 downto 0) := "000000"; -- Vertical char counter
	
	signal hcnt 	: unsigned(8 downto 0) := "000000000";
	signal vcnt 	: unsigned(8 downto 0) := "000000000";

	signal attr     : std_logic_vector(7 downto 0);
	signal bitmap    : std_logic_vector(7 downto 0);
	signal shift_hr : std_logic_vector(15 downto 0);
	
	signal paper_r  : std_logic;
	signal blank_r  : std_logic;
	signal attr_r   : std_logic_vector(7 downto 0);
	signal shift_r  : std_logic_vector(7 downto 0);
	signal shift_hr_r : std_logic_vector(15 downto 0);

	signal paper     : std_logic;
	
	signal VIDEO_R 	: std_logic;
	signal VIDEO_G 	: std_logic;
	signal VIDEO_B 	: std_logic;
	signal VIDEO_I 	: std_logic;	
	
	signal timex_page : std_logic;
	signal timex_hicolor : std_logic;
	signal timex_hires : std_logic;
	signal timex_pallette : std_logic_vector(2 downto 0);
	signal clkhalf14 : std_logic;
	
	signal int_sig : std_logic;
	
begin

	timex_page <= TIMEXCFG(0);
	timex_hicolor <= TIMEXCFG(1);
	timex_hires <= TIMEXCFG(2);
	timex_pallette <= TIMEXCFG(5 downto 3);
	
	INVERT_O <= invert(0);
	
	-- 14 mhz half clock
	process(CLK, ENA14, clkhalf14)
	begin
		if (CLK'event and CLK = '1') then 
			if ENA14 = '1' then 
				clkhalf14 <= not clkhalf14;
			end if;
		end if;
	end process;

	-- sync, counters
	process( CLK, ENA7, chr_col_cnt, hor_cnt, chr_row_cnt, ver_cnt, TURBO, INTA)
	begin
		if CLK'event and CLK = '1' then
		
			if ENA7 = '1' then
			
				if chr_col_cnt = 7 then
				
					if hor_cnt = 55 then
						hor_cnt <= (others => '0');
					else
						hor_cnt <= hor_cnt + 1;
					end if;
					
					if hor_cnt = 39 then
						if chr_row_cnt = 7 then
							if ver_cnt = 39 then
								ver_cnt <= (others => '0');
								invert <= invert + 1;
							else
								ver_cnt <= ver_cnt + 1;
							end if;
						end if;
						chr_row_cnt <= chr_row_cnt + 1;
					end if;
				end if;

				-- h/v sync

				if chr_col_cnt = 7 then

					if (hor_cnt(5 downto 2) = "1010") then 
						HSYNC <= '0';
					else 
						HSYNC <= '1';
					end if;
					
					if ver_cnt /= 31 then
						VSYNC <= '1';
					elsif chr_row_cnt = 3 or chr_row_cnt = 4 or ( chr_row_cnt = 5 and ( hor_cnt >= 40 or hor_cnt < 12 ) ) then
						VSYNC<= '0';
					else 
						VSYNC <= '1';
					end if;
					
				end if;
			
				-- int
				if TURBO = '1' then
					-- TURBO int
					if hcnt = 318 and vcnt = 239 then
						int_sig <= '0';
					elsif INTA = '0' then
						int_sig <= '1';
					end if;
				else 
					-- PENTAGON int
--					if hcnt = 318 and vcnt = 239 then
--						int_sig <= '0';
--					elsif hcnt = 382 and vcnt = 239 then 
--						int_sig <= '1';
--					end if;

					if chr_col_cnt = 6 and hor_cnt(2 downto 0) = "111" then
						if ver_cnt = 29 and chr_row_cnt = 7 and hor_cnt(5 downto 3) = "100" then
							int_sig <= '0';
						else
							int_sig <= '1';
						end if;
					end if;

				end if;

				chr_col_cnt <= chr_col_cnt + 1;
			end if;
		end if;
	end process;

	-- r/g/b/i
	process( CLK, ENA7, ENA14, paper_r, shift_r, attr_r, invert, blank_r, timex_hires, timex_pallette, BORDER )
	begin
		if CLK'event and CLK = '1' then
			if paper_r = '0' then -- paper
				if (timex_hires = '1' and ENA14 = '1') then
					-- timex hires RGB
					if (shift_hr_r(15) = '1') then --fg pixel
						VIDEO_R <= timex_pallette(2);
						VIDEO_G <= timex_pallette(1);
						VIDEO_B <= timex_pallette(0); 
						VIDEO_I <= '0';
					else -- bg pixel
						VIDEO_R <= not timex_pallette(2);
						VIDEO_G <= not timex_pallette(1);
						VIDEO_B <= not timex_pallette(0); 
						VIDEO_I <= '0';
					end if;
				
				elsif (timex_hires = '0' and ENA7 = '1') then 
					-- standard RGB
					if( shift_r(7) xor ( attr_r(7) and invert(4) ) ) = '1' then -- fg pixel
						VIDEO_B <= attr_r(0);
						VIDEO_R <= attr_r(1);
						VIDEO_G <= attr_r(2);
					else	-- bg pixel
						VIDEO_B <= attr_r(3);
						VIDEO_R <= attr_r(4);
						VIDEO_G <= attr_r(5);
					end if;
					VIDEO_I <= attr_r(6);
				end if;
			else -- not paper
				if blank_r = '0' then
					-- blank
					VIDEO_B <= '0';
					VIDEO_R <= '0';
					VIDEO_G <= '0';
					VIDEO_I <= '0';
				elsif ENA14 = '1' and timex_hires = '1' then -- hires border
					-- timex hires RGB
					VIDEO_B <= not timex_pallette(2);
					VIDEO_R <= not timex_pallette(1);
					VIDEO_G <= not timex_pallette(0);
					VIDEO_I <= '0';
				elsif ENA7 = '1' and timex_hires = '0' then -- std border
					-- standard RGB
					VIDEO_B <= BORDER(0);
					VIDEO_R <= BORDER(1);
					VIDEO_G <= BORDER(2);
					VIDEO_I <= '0';
				end if;
			end if;
		end if;
	end process;

	-- paper, blank, bitmap shift registers
	process( CLK, ENA7, ENA14, chr_col_cnt, hor_cnt, ver_cnt, clkhalf14, shift_hr_r, attr, bitmap, paper, shift_r )
	begin
		if CLK'event and CLK = '1' then

			-- timex hires shift register
			if ENA14 = '1' then 
				if chr_col_cnt = 7 and clkhalf14 = '1' then 
					shift_hr_r <= bitmap & attr;
				else 
					shift_hr_r(15 downto 1) <= shift_hr_r(14 downto 0);
					shift_hr_r(0) <= '0';
				end if;
			end if;

			-- standard shift register 
			if ENA7 = '1' then
				if chr_col_cnt = 7 then
					attr_r <= attr;
					shift_r <= bitmap;

					if ((hor_cnt(5 downto 0) > 38 and hor_cnt(5 downto 0) < 48) or ver_cnt(5 downto 1) = 15) then
						blank_r <= '0';
					else 
						blank_r <= '1';
					end if;
					
					paper_r <= paper;
				else
					shift_r(7 downto 1) <= shift_r(6 downto 0);
					shift_r(0) <= '0';
				end if;

			end if;
		end if;
	end process;
	
	-- video mem read cycle
	process (CLK, ENA7, chr_col_cnt, timex_page, ver_cnt, chr_row_cnt, hor_cnt, DI)
	begin 
		if (CLK'event and CLK = '1') then 
			if (ENA7 = '1') then 
				case chr_col_cnt(2 downto 0) is
					when "000" => -- data request
							A <= std_logic_vector( timex_page & ver_cnt(4 downto 3) & chr_row_cnt & ver_cnt(2 downto 0) & hor_cnt(4 downto 0) );
					when "001" => -- read bitmap data
						bitmap <= DI;
					when "010" => -- attribute request 
						if timex_hicolor = '1' then
							A <= std_logic_vector( '1' & ver_cnt(4 downto 3) & chr_row_cnt & ver_cnt(2 downto 0) & hor_cnt(4 downto 0) );
						else 
							A <= std_logic_vector( timex_page & "110" & ver_cnt(4 downto 0) & hor_cnt(4 downto 0) );
						end if;
					when "011" => -- read attributes
						attr <= DI;
					when others => null;
				end case;
			end if;
		end if;
	end process;

U9BIT: entity work.rgbi_9bit
port map(
	I_RED => VIDEO_R,
	I_GREEN => VIDEO_G,
	I_BLUE => VIDEO_B,
	I_BRIGHT => VIDEO_I,
	O_RGB => RGB 
);
	
ATTR_O	<= attr_r;
BLANK	<= blank_r;
paper <= '0' when hor_cnt(5) = '0' and ver_cnt(5) = '0' and ( ver_cnt(4) = '0' or ver_cnt(3) = '0' ) else '1';

hcnt(8 downto 0) <= hor_cnt(5 downto 0) & chr_col_cnt(2 downto 0);
vcnt(8 downto 0) <= ver_cnt(5 downto 0) & chr_row_cnt(2 downto 0);

HCNT_O <= std_logic_vector(hcnt);
VCNT_O <= std_logic_vector(vcnt);

INT <= int_sig;

end architecture;