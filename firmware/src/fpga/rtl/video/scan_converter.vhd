--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------
-- Video scan converter
--
--	Horizonal Timing
-- _____________              ______________________              _____________________
-- VIDEO (last) |____________|         VIDEO        |____________|         VIDEO (next)
-- -hD----------|-hA-|hB|-hC-|----------hD----------|-hA-|hB|-hC-|----------hD---------
-- __________________|  |________________________________|  |__________________________
-- HSYNC             |__|              HSYNC             |__|              HSYNC

-- Vertical Timing
-- _____________              ______________________              _____________________
-- VIDEO (last)||____________||||||||||VIDEO|||||||||____________||||||||||VIDEO (next)
-- -vD----------|-vA-|vB|-vC-|----------vD----------|-vA-|vB|-vC-|----------vD---------
-- __________________|  |________________________________|  |__________________________
-- VSYNC             |__|              VSYNC             |__|              VSYNC

-- Scan converter input and output timings compared to standard VGA
--	Resolution   - Frame   | Pixel      | Front     | HSYNC      | Back       | Active      | HSYNC    | Front    | VSYNC    | Back     | Active    | VSYNC
--              - Rate    | Clock      | Porch hA  | Pulse hB   | Porch hC   | Video hD    | Polarity | Porch vA | Pulse vB | Porch vC | Video vD  | Polarity
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--  In  256x224 - 59.18Hz |  6.000 MHz | 38 pixels |  32 pixels |  58 pixels |  256 pixels | negative | 16 lines | 8 lines  | 16 lines | 224 lines | negative
--  Out 640x480 - 59.18Hz | 24.000 MHz |  2 pixels |  92 pixels |  34 pixels |  640 pixels | negative | 17 lines | 2 lines  | 29 lines | 480 lines | negative
--  VGA 640x480 - 59.94Hz | 25.175 MHz | 16 pixels |  96 pixels |  48 pixels |  640 pixels | negative | 10 lines | 2 lines  | 33 lines | 480 lines | negative

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity scan_convert is
--	generic (
--		cstart		: integer range 0 to 1023 := 144;	-- composite sync start
--		clength		: integer range 0 to 1023 := 640;	-- composite sync length
--
--		hA				: integer range 0 to 1023 :=  16;	-- h front porch
--		hB				: integer range 0 to 1023 :=  96;	-- h sync
--		hC				: integer range 0 to 1023 :=  48;	-- h back porch
--		hD				: integer range 0 to 1023 := 640;	-- visible video
--
----		vA				: integer range 0 to 1023 :=  16;	-- v front porch
--		vB				: integer range 0 to 1023 :=   2;	-- v sync
--		vC				: integer range 0 to 1023 :=  33;	-- v back porch
--		vD				: integer range 0 to 1023 := 480;	-- visible video
--
--		hpad			: integer range 0 to 1023 :=   0;	-- H black border
--		vpad			: integer range 0 to 1023 :=   0		-- V black border
--	);
	port (
		I_VIDEO				: in  std_logic_vector(8 downto 0);
		I_HSYNC				: in  std_logic;
		I_VSYNC				: in  std_logic;
		mode					: in  std_logic;		
		--
		O_VIDEO				: out std_logic_vector(8 downto 0);
		O_HSYNC				: out std_logic;
		O_VSYNC				: out std_logic;
		O_CMPBLK_N			: out std_logic;
		--
		CLK					: in  std_logic;
		CLK2					: in  std_logic;		
		CLK_x2				: in  std_logic
	);
end;

architecture RTL of scan_convert is
	--
	-- input timing
	--
	signal ivsync_last_x2	: std_logic := '1';
	signal ihsync_last		: std_logic := '1';
	signal hpos_i				: std_logic_vector( 9 downto 0) := (others => '0');

	--
	-- output timing
	--
	signal hpos_o			: std_logic_vector(9 downto 0) := (others => '0');

	signal vcnt				: integer range 0 to 1023 := 0;
	signal hcnt				: integer range 0 to 1023 := 0;
	signal hcnti			: integer range 0 to 1023 := 0;
	
	constant cs0			: integer range 0 to 1023 := 38;		-- composite sync start
	constant cl0			: integer range 0 to 1023 := 352;	-- composite sync length
	
	constant hA0			: integer range 0 to 1023 :=  24;	-- h front porch
	constant hB0			: integer range 0 to 1023 :=  32;	-- h sync
	constant hC0			: integer range 0 to 1023 :=  40;	-- h back porch
	constant hD0			: integer range 0 to 1023 := 352;	-- visible video
--		vA				: integer range 0 to 1023 :=  0;	-- v front porch
	constant vB0			: integer range 0 to 1023 :=   2;	-- v sync
	constant vC0			: integer range 0 to 1023 :=  10;	-- v back porch
	constant vD0			: integer range 0 to 1023 := 284;	-- visible video

	

	constant cs1			: integer range 0 to 1023 := 2;		-- composite sync start
	constant cl1			: integer range 0 to 1023 := 736;	-- composite sync length		
	
	constant hA1			: integer range 0 to 1023 :=  8;	-- h front porch
	constant hB1			: integer range 0 to 1023 :=  64;	-- h sync
	constant hC1			: integer range 0 to 1023 :=  88;	-- h back porch
	constant hD1			: integer range 0 to 1023 := 736;	-- visible video
--		vA				: integer range 0 to 1023 :=  0;	-- v front porch
	constant vB1			: integer range 0 to 1023 :=   2;	-- v sync
	constant vC1			: integer range 0 to 1023 :=  10;	-- v back porch
	constant vD1			: integer range 0 to 1023 := 284;	-- visible video	
	
	
	constant hpad			: integer range 0 to 1023 :=   0;	-- H black border
	constant vpad			: integer range 0 to 1023 :=   0;	-- V black border	

begin
	-- dual port line buffer, max line of 1024 pixels
	u_run : entity work.ram_scan
	PORT MAP (
		clock_a	 	=> CLK2,
		address_a	=> hpos_i,
		data_a		=> I_VIDEO,
		wren_a	 	=> CLK,
		q_a	 		=> open,
		--
		clock_b	 	=> CLK_x2,
		address_b	=> hpos_o,
		data_b	 	=> "000000000",
		wren_b	 	=> '0',
		q_b	 		=> O_VIDEO
	);
	
	-- horizontal counter for input video
	p_hcounter : process (CLK, I_HSYNC, ihsync_last, hcnti)
	begin
		if CLK'event and CLK = '0' then
			ihsync_last <= I_HSYNC;
			-- trigger off rising hsync
			if I_HSYNC = '1' and ihsync_last = '0' then
				hcnti <= 0;
			else
				hcnti <= hcnti + 1;
			end if;
		end if;
	end process;

	-- increment write position during active video
	p_ram_in : process (CLK, hcnti)
	begin
		if (CLK'event and CLK = '0') then
			if (((hcnti < cs0) or (hcnti >= (cs0 + cl0))) and mode = '0') or (((hcnti < cs1) or (hcnti >= (cs1 + cl1))) and mode = '1')  then
				hpos_i <= (others => '0');
			else
				hpos_i <= hpos_i + 1;
			end if;
		end if;
	end process;

	-- VGA H and V counters, synchronized to input frame V sync, then H sync
	p_out_ctrs : process (CLK_x2, I_VSYNC, ivsync_last_x2, hcnt)
		variable trigger : boolean;
	begin
		if CLK_x2'event and CLK_x2 = '1' then
			ivsync_last_x2 <= I_VSYNC;
			if (I_VSYNC = '0') and (ivsync_last_x2 = '1') then
				trigger := true;
			elsif trigger and I_HSYNC = '0' then
				trigger := false;
				hcnt <= 0;
				vcnt <= 0;
			else
				hcnt <= hcnt + 1;
				if ((hcnt = (hA0+hB0+hC0+hD0+hpad+hpad-1)) and mode='0')or((hcnt = (hA1+hB1+hC1+hD1+hpad+hpad-1)) and mode='1')  then
					hcnt <= 0;
					vcnt <= vcnt + 1;
				end if;
			end if;
		end if;
	end process;
	
	-- generate hsync
	p_gen_hsync : process (CLK_x2)
	begin
		if CLK_x2'event and CLK_x2 = '1' then
		-- H sync timing
			if ((hcnt < hB0) and mode='0') or ((hcnt < hB1) and mode='1') then
				O_HSYNC <= '0';
			else
				O_HSYNC <= '1';
			end if;
		end if;
	end process;

	-- generate vsync
	p_gen_vsync : process (CLK_x2)
	begin
		if CLK_x2'event and CLK_x2 = '1' then
		-- V sync timing
			if ((vcnt < vB0) and mode='0') or ((vcnt < vB1) and mode='1') then
				O_VSYNC <= '0';
			else
				O_VSYNC <= '1';
			end if;
		end if;
	end process;

	-- generate active output video
	p_gen_active_vid : process (CLK_x2)
	begin
		if CLK_x2'event and CLK_x2 = '1' then
			-- visible video area doubled from the original game
			if ((((hcnt >= (hB0 + hC0 + hpad)) and (hcnt < (hB0 + hC0 + hD0 + hpad))) and ((vcnt > 2*(vB0 + vC0 + vpad)) and (vcnt <= 2*(vB0 + vC0 + vD0 + vpad)))) and mode='0') or
			   ((((hcnt >= (hB1 + hC1 + hpad)) and (hcnt < (hB1 + hC1 + hD1 + hpad))) and ((vcnt > 2*(vB1 + vC1 + vpad)) and (vcnt <= 2*(vB1 + vC1 + vD1 + vpad)))) and mode='1') then

				hpos_o <= hpos_o + 1;
			else
				hpos_o <= (others => '0');
			end if;
		end if;
	end process;
	
	-- generate blanking signal including additional borders to pad the input signal to standard VGA resolution
	p_gen_blank : process (CLK_x2)
	begin
		if CLK_x2'event and CLK_x2 = '1' then
			-- active video area 640x480 (VGA) after padding with blank borders
			if ((((hcnt >= (hB0 + hC0)) and (hcnt < (hB0 + hC0 + hD0 + 2*hpad))) and ((vcnt > 2*(vB0 + vC0)) and (vcnt <= 2*(vB0 + vC0 + vD0 + 2*vpad))))and mode='0') or 
				((((hcnt >= (hB1 + hC1)) and (hcnt < (hB1 + hC1 + hD1 + 2*hpad))) and ((vcnt > 2*(vB1 + vC1)) and (vcnt <= 2*(vB1 + vC1 + vD1 + 2*vpad))))and mode='1') then
				O_CMPBLK_N <= '1';
			else
				O_CMPBLK_N <= '0';
			end if;
		end if;
	end process;

end architecture RTL;