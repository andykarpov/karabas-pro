-------------------------------------------------------------------------------
-- VIDEO Pentagon mode
-------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity pentagon_video is
	port (
		CLK2X 	: in std_logic; -- 28 MHz
		CLK		: in std_logic; -- 14 MHz
		ENA		: in std_logic; -- 7 MHz 
		BORDER	: in std_logic_vector(2 downto 0);	-- bordr color (port #xxFE)
		DI			: in std_logic_vector(7 downto 0);	-- video data from memory
		TURBO 	: in std_logic_vector := "00"; -- 01 = turbo 2x mode, 10 - turbo 4x mode, 11 - turbo 8x mode, 00 = normal mode
		INTA		: in std_logic := '0'; -- int request for turbo mode
		INT		: out std_logic; -- int output
		MODE60	: in std_logic := '0'; -- '0'
		pFF_CS	: out std_logic; -- port FF select
		ATTR_O	: out std_logic_vector(7 downto 0); -- attribute register output
		A			: out std_logic_vector(13 downto 0); -- video address
		RGB		: out std_logic_vector(2 downto 0);	-- RGB
		I			: out std_logic; -- brightness
		HSYNC		: out std_logic;
		VSYNC		: out std_logic;
		HCNT 		: out std_logic_vector(9 downto 0);
		VCNT 		: out std_logic_vector(8 downto 0);	
		ISPAPER 	: out std_logic := '0';
		BLINK 	: out std_logic;
		SCREEN_MODE : in std_logic_vector(1 downto 0) := "00"; -- screen mode: 00 = pentagon, 01 - 128 classic, 10, 11 - reserver
		COUNT_BLOCK : out std_logic;
		COUNT_BLOCKIO : out std_logic;
		
		-- sram vram
		VBUS_MODE : in std_logic := '0'; -- 1 = video bus, 2 = cpu bus
		VID_RD : in std_logic -- 1 = read attribute, 0 = read pixel data
	);
end entity;

architecture rtl of pentagon_video is

	signal invert   : unsigned(4 downto 0) := "00000";	-- Flash counter

	signal chr_col_cnt : unsigned(2 downto 0) := "000"; -- Character column counter
	signal chr_row_cnt : unsigned(2 downto 0) := "000"; -- Character row counter

	signal hor_cnt  : unsigned(5 downto 0) := "000000"; -- Horizontal char counter
	signal ver_cnt  : unsigned(5 downto 0) := "000000"; -- Vertical char counter

	signal vid_reg  : std_logic_vector(7 downto 0);	
	signal attr     : std_logic_vector(7 downto 0);
	signal bitmap   : std_logic_vector(7 downto 0);
	signal bORatr   : std_logic_vector(7 downto 0);
	signal bORatr_r : std_logic_vector(7 downto 0);
	
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
		
	signal int_sig : std_logic;
	signal COUNT_BLOCK128 : std_logic;
	signal COUNT_BLOCKio128 : std_logic;
	signal COUNT_BLOCK48 : std_logic;
	
	signal zx128 : std_logic;
	signal zx48 : std_logic;
	
begin

	-- sync, counters
	process( CLK2X, CLK, ENA, chr_col_cnt, hor_cnt, chr_row_cnt, ver_cnt, TURBO, INTA)
	begin
		if CLK2X'event and CLK2X = '1' then --28
		
			if CLK = '1' and ENA = '1' then --14 7 = 7
			
				if chr_col_cnt = 7 then --8 pixels 0.142*8 = 1.138 us
				---20.10.2023:OCH: 456 * 0.142 us for row in Classic 128 mode "10"
					if (hor_cnt = 55 and (SCREEN_MODE = "00" or SCREEN_MODE = "01")) or (hor_cnt = 56 and SCREEN_MODE = "10")  then 
						hor_cnt <= (others => '0');
					else
						hor_cnt <= hor_cnt + 1;
					end if;
					
					if hor_cnt = 39 then -- 
						if chr_row_cnt = 7 then
							if (ver_cnt = 39 and MODE60 = '0' and SCREEN_MODE = "00") or -- pentagon 50 Hz 
								(ver_cnt = 32 and MODE60 = '1' and SCREEN_MODE = "00") or -- pentagon 60 Hz
								(ver_cnt = 38 and MODE60 = '0' and (SCREEN_MODE = "01" or SCREEN_MODE = "10")) or -- classic or Classic 128 50 Hz 
								(ver_cnt = 31 and MODE60 = '1' and (SCREEN_MODE = "01" or SCREEN_MODE = "10"))    -- classic or Classic 128 60 Hz
							then
								ver_cnt <= (others => '0');
								invert <= invert + 1;
							else
								ver_cnt <= ver_cnt + 1;
							end if;
						end if;
						if ver_cnt = 37 and MODE60 = '0' and SCREEN_MODE = "10" and chr_row_cnt = 5 then  
							chr_row_cnt <= chr_row_cnt + 2; -- skip one row
						else
							chr_row_cnt <= chr_row_cnt + 1;
						end if;
					end if;
				end if;

				-- h/v sync

				if chr_col_cnt = 7 then

					if hor_cnt(5 downto 2) = "1010" then
						HSYNC <= '0';
					else 
						HSYNC <= '1';
					end if;
					
					if (ver_cnt /= 31 and MODE60 = '0') or (ver_cnt /= 27 and MODE60 = '1') then
						VSYNC <= '1';
					elsif chr_row_cnt = 3 or chr_row_cnt = 4 or ( chr_row_cnt = 5 and ( hor_cnt >= 40 or hor_cnt < 12 ) ) then
						VSYNC<= '0';
					else 
						VSYNC <= '1';
					end if;
					
				end if;
			
				-- int
				if TURBO = "01" then
					-- TURBO 2x int
					if chr_col_cnt = 6 and hor_cnt(1 downto 0) = "11" then
						if ver_cnt = 29 and chr_row_cnt = 7 and hor_cnt(5 downto 2) = "1001" then
							int_sig <= '0';
						else
							int_sig <= '1';
						end if;
					end if;
				elsif TURBO = "10" then 
					-- TURBO 4x int
					if chr_col_cnt = 6 and hor_cnt(0) = '1' then
						if ver_cnt = 29 and chr_row_cnt = 7 and hor_cnt(5 downto 1) = "10011" then
							int_sig <= '0';
						else
							int_sig <= '1';
						end if;
					end if;
				elsif TURBO = "11" then 
					-- TURBO 8x int
					if chr_col_cnt = 6 then
						if ver_cnt = 29 and chr_row_cnt = 7 and hor_cnt(5 downto 0) = "100111" then
							int_sig <= '0';
						else
							int_sig <= '1';
						end if;
					end if;
				else 
					-- PENTAGON int
					if (SCREEN_MODE = "00") then 
						if chr_col_cnt = 6 and hor_cnt(2 downto 0) = "111" then
							if ver_cnt = 29 and chr_row_cnt = 7 and hor_cnt(5 downto 3) = "100" then
								int_sig <= '0';
							else
								int_sig <= '1';
							end if;
						end if;
					-- CLASSIC int
					elsif (SCREEN_MODE = "01") then 
						if chr_col_cnt = 0 then
							if ver_cnt = 31 and chr_row_cnt = 0 and hor_cnt(5 downto 3) = "000" then
								int_sig <= '0';
							else
								int_sig <= '1';
							end if;
						end if;
					-- 128 int
					elsif (SCREEN_MODE = "10") then 
						if chr_col_cnt = 4 then
							if ver_cnt = 31 and chr_row_cnt = 0 and hor_cnt(5 downto 3) = "000" then
								int_sig <= '0';
							else
								int_sig <= '1';
							end if;
						end if;
					end if;

				end if;

				chr_col_cnt <= chr_col_cnt + 1; -- column counter 0.142 us per column/pixel
			end if;
		end if;
	end process;

	-- r/g/b/i
	process( CLK2X, CLK, ENA, paper_r, shift_r, attr_r, invert, blank_r, BORDER )
	begin
		if CLK2X'event and CLK2X = '1' then
		if CLK = '1' and ENA = '1' then
			if paper_r = '0' then -- paper
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
			else -- not paper
				if blank_r = '0' then
					-- blank
					VIDEO_B <= '0';
					VIDEO_R <= '0';
					VIDEO_G <= '0';
					VIDEO_I <= '0';
				else -- std border
					-- standard RGB
					VIDEO_B <= BORDER(0);
					VIDEO_R <= BORDER(1);
					VIDEO_G <= BORDER(2);
					VIDEO_I <= '0';
				end if;
			end if;
		end if;
		end if;
	end process;

	-- paper, blank
	process( CLK2X, CLK, ENA, chr_col_cnt, hor_cnt, ver_cnt, shift_hr_r, attr, bitmap, paper, shift_r )
	begin
		if CLK2X'event and CLK2X = '1' then
			if CLK = '1' then		
				if ENA = '1' then
					if chr_col_cnt = 7 then
						-- PENTAGON blank
						if SCREEN_MODE = "00" and ((hor_cnt(5 downto 0) > 38 and hor_cnt(5 downto 0) < 48) or ((ver_cnt(5 downto 1) = 15 and MODE60 = '0') or (ver_cnt(5 downto 1) = 14 and MODE60 = '1'))) then	-- 15 = for 320 lines, 13 = for 264 lines
							blank_r <= '0';
						-- CLASSIC blank
						elsif (SCREEN_MODE = "01" or SCREEN_MODE = "10") and (hor_cnt(5 downto 2) = 10 or hor_cnt(5 downto 2) = 11 or (ver_cnt = 31 and MODE60 = '0') or (ver_cnt = 30 and MODE60 = '1')) then
							blank_r <= '0';
						else 
							blank_r <= '1';
						end if;							
						paper_r <= paper;
					end if;
				end if;
			end if;
		end if;
	end process;	
	
	-- bitmap shift registers
	process( CLK2X, CLK, ENA, chr_col_cnt, hor_cnt, ver_cnt, shift_hr_r, attr, bitmap, paper, shift_r )
	begin
		if CLK2X'event and CLK2X = '1' then

			if CLK = '1' then
					-- standard shift register 
					if ENA = '1' then
						if chr_col_cnt = 7 then
							attr_r <= attr;
							shift_r <= bitmap;
						else
							shift_r(7 downto 1) <= shift_r(6 downto 0);
							shift_r(0) <= '0';
						end if;
					end if;
			end if;
		end if;
	end process;
	
	-- video mem read cycle
	process (CLK2X, CLK, chr_col_cnt, VBUS_MODE, VID_RD)
	begin 
		if (CLK2X'event and CLK2X = '1') then 
			if (chr_col_cnt(0) = '1' and CLK = '0') then
				if VBUS_MODE = '1' then
					if VID_RD = '0' then 
						bitmap <= DI;
					else 
						attr <= DI;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	A <= 
		-- data address
		std_logic_vector( '0' & ver_cnt(4 downto 3) & chr_row_cnt & ver_cnt(2 downto 0) & hor_cnt(4 downto 0)) when VBUS_MODE = '1' and VID_RD = '0' else 
		-- standard attribute address
		std_logic_vector( '0' & "110" & ver_cnt(4 downto 0) & hor_cnt(4 downto 0));
	
	paper <= '0' when hor_cnt(5) = '0' and ver_cnt(5) = '0' and ( ver_cnt(4) = '0' or ver_cnt(3) = '0' ) else '1';
	
	RGB <= VIDEO_R & VIDEO_G & VIDEO_B;
	I <= VIDEO_I;
	pFF_CS	<= not paper;
	
	ATTR_O <= attr_r;
	
	INT <= int_sig;
	
	HCNT <= '0' & std_logic_vector(hor_cnt) & std_logic_vector(chr_col_cnt);
	VCNT <= std_logic_vector(ver_cnt) & std_logic_vector(chr_row_cnt);
	ISPAPER <= '1' when paper = '0' and blank_r = '1' else '0';

	BLINK <= invert(4);
	
	zx128 <= '1' when SCREEN_MODE = "10" else '0';
	zx48 <= '1' when SCREEN_MODE = "01" else '0';	
	
	COUNT_BLOCK48 <= '1' when paper = '0' and (chr_col_cnt(2) = '0' or hor_cnt(0) = '0') else '0';
	COUNT_BLOCK128 <= '1' when paper = '0' and (hor_cnt(0) & chr_col_cnt > 3)  else '0';
	 
	COUNT_BLOCKIO128 <= '1' when paper = '0' and (chr_col_cnt(2) = '0' or hor_cnt(0) = '0') else '0';
	
--	process (CLK2X)
--	begin
--		if rising_edge(clk2X) then
--			if zx48 = '1' then
--				COUNT_BLOCK <= COUNT_BLOCK48;
--				COUNT_BLOCKIO <= COUNT_BLOCK48;
--			elsif zx128 = '1' then
--				COUNT_BLOCK <= COUNT_BLOCK128;
--				COUNT_BLOCKIO <= COUNT_BLOCK48;
--			else
--				COUNT_BLOCK <= '0';
--				COUNT_BLOCKIO <= '0';
--			end if;
--		end if;
--	end process;

	COUNT_BLOCKIO <= COUNT_BLOCK48 when zx48 = '1' else COUNT_BLOCKIO128 when zx128 = '1' else '0';
	COUNT_BLOCK <= COUNT_BLOCK48 when zx48 = '1' else COUNT_BLOCK128 when zx128 = '1' else '0';
end architecture;