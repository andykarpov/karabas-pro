-------------------------------------------------------------------------------
-- AVR link v2 (docs/AVR_LINK_V2.md): the VHDL face of avr_link.v for the top.
--
-- The link itself is avr_link.v (Verilog, simulated with iverilog: sim/run_avr_link.sh). This
-- file only binds its ports bit by bit (SOFT_SW is 1 to 10 here, 9 downto 0 there; the mouse
-- deltas are signed here) and holds message_rom (the build id, an altsyncram with the MIF of
-- the build). The binding is checked by reading it and on the board, not by a bench.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity avr is
	port
	(
	 CLK			 : in std_logic;
	 N_RESET 	 : in std_logic := '1';
	 A           : in std_logic_vector(15 downto 8);     -- address bus for kbd
	 KB          : out std_logic_vector(5 downto 0);     -- data bus for kbd + extended bit (b6)
	 AVR_MOSI    : in std_logic;
	 AVR_MISO    : out std_logic;
	 AVR_SCK     : in std_logic;
	 AVR_SS 		 : in std_logic;

	 MS_X 	 	: out std_logic_vector(7 downto 0);
	 MS_Y 	 	: out std_logic_vector(7 downto 0);
	 MS_BTNS 	: out std_logic_vector(2 downto 0);
	 MS_Z 		: out std_logic_vector(3 downto 0);
	 MS_PRESET  : out std_logic;
	 MS_EVENT 	: out std_logic;
	 MS_DELTA_X : out signed(7 downto 0);
	 MS_DELTA_Y : out signed(7 downto 0);

	 RTC_A 		: in std_logic_vector(7 downto 0);
	 RTC_DI 		: in std_logic_vector(7 downto 0);
	 RTC_DO 		: out std_logic_vector(7 downto 0);
	 RTC_CS 		: in std_logic := '0';
	 RTC_WR_N 	: in std_logic := '1';

	 LOADER_DONE : in std_logic := '0';

	 LED1			: in std_logic := '0';
	 LED2 		: in std_logic := '0';
	 LED1_OWR	: in std_logic := '0';
	 LED2_OWR 	: in std_logic := '0';

	 CFG 			: in std_logic_vector(7 downto 0);
	 MAX_TURBO  : in std_logic_vector(1 downto 0) := "11";

	 SOFT_SW 	: out std_logic_vector(1 to 10);
	 KB_MODE 	: out std_logic;
	 RESET		: out std_logic;
	 TURBO		: out std_logic_vector(1 downto 0);
	 MAGICK		: out std_logic;
	 WAIT_CPU 	: out std_logic;
	 JOY_TYPE 	: out std_logic; -- 0 - atari, 1 - sega
	 JOY_MODE 	: out std_logic_vector(2 downto 0); -- 000 - kempston, 001 - sinclair 1, 010 - sinclair 2, 011 - cursor, 100 - qaop
	 OSD_OVERLAY: out std_logic;
	 OSD_POPUP 	: out std_logic;
	 SCREEN_MODE : out std_logic_vector(1 downto 0); -- 00 - pentagon, 01 - 128 classic
	 DIVMMC_EN  : out std_logic;
	 NEMOIDE_EN : out std_logic;
	 PLUS3E     : out std_logic; -- ROM bank +3e selected

	 -- OSD video memory writes
	 OSD_WR     : out std_logic;
	 OSD_A      : out std_logic_vector(9 downto 0);
	 OSD_D      : out std_logic_vector(15 downto 0); -- character & attribute

	 JOY			: out std_logic_vector(7 downto 0);  -- Kempston: 0 right, 1 left, 2 down, 3 up, 4 fire, 5 fire 2, 6 A, 7 Start
	 JOY_BTN		: out std_logic_vector(15 downto 0)  -- all buttons (docs/AVR_LINK_V2.md 4.2)
	);
end avr;

architecture RTL of avr is

	component avr_link
	port (
		clk         : in std_logic;
		n_reset     : in std_logic;
		avr_sck     : in std_logic;
		avr_mosi    : in std_logic;
		avr_miso    : out std_logic;
		avr_ss      : in std_logic;
		a           : in std_logic_vector(15 downto 8);
		kb          : out std_logic_vector(5 downto 0);
		ms_x        : out std_logic_vector(7 downto 0);
		ms_y        : out std_logic_vector(7 downto 0);
		ms_btns     : out std_logic_vector(2 downto 0);
		ms_z        : out std_logic_vector(3 downto 0);
		ms_preset   : out std_logic;
		ms_event    : out std_logic;
		ms_delta_x  : out std_logic_vector(7 downto 0);
		ms_delta_y  : out std_logic_vector(7 downto 0);
		rtc_a       : in std_logic_vector(7 downto 0);
		rtc_di      : in std_logic_vector(7 downto 0);
		rtc_do      : out std_logic_vector(7 downto 0);
		rtc_cs      : in std_logic;
		rtc_wr_n    : in std_logic;
		loader_done : in std_logic;
		led1        : in std_logic;
		led2        : in std_logic;
		led1_owr    : in std_logic;
		led2_owr    : in std_logic;
		cfg         : in std_logic_vector(7 downto 0);
		max_turbo   : in std_logic_vector(1 downto 0);
		build_a     : out std_logic_vector(2 downto 0);
		build_q     : in std_logic_vector(7 downto 0);
		soft_sw     : out std_logic_vector(9 downto 0);
		kb_mode     : out std_logic;
		reset       : out std_logic;
		turbo       : out std_logic_vector(1 downto 0);
		magick      : out std_logic;
		wait_cpu    : out std_logic;
		joy_type    : out std_logic;
		joy_mode    : out std_logic_vector(2 downto 0);
		osd_overlay : out std_logic;
		osd_popup   : out std_logic;
		screen_mode : out std_logic_vector(1 downto 0);
		divmmc_en   : out std_logic;
		nemoide_en  : out std_logic;
		plus3e      : out std_logic;
		joy         : out std_logic_vector(7 downto 0);
		joy_btn     : out std_logic_vector(15 downto 0);
		osd_wr      : out std_logic;
		osd_a       : out std_logic_vector(9 downto 0);
		osd_d       : out std_logic_vector(15 downto 0)
	);
	end component;

	signal soft_sw_v : std_logic_vector(9 downto 0);
	signal ms_dx, ms_dy : std_logic_vector(7 downto 0);
	signal build_a : std_logic_vector(2 downto 0);
	signal build_q : std_logic_vector(7 downto 0);

begin

	U_LINK: avr_link
	port map (
		clk         => CLK,
		n_reset     => N_RESET,
		avr_sck     => AVR_SCK,
		avr_mosi    => AVR_MOSI,
		avr_miso    => AVR_MISO,
		avr_ss      => AVR_SS,
		a           => A,
		kb          => KB,
		ms_x        => MS_X,
		ms_y        => MS_Y,
		ms_btns     => MS_BTNS,
		ms_z        => MS_Z,
		ms_preset   => MS_PRESET,
		ms_event    => MS_EVENT,
		ms_delta_x  => ms_dx,
		ms_delta_y  => ms_dy,
		rtc_a       => RTC_A,
		rtc_di      => RTC_DI,
		rtc_do      => RTC_DO,
		rtc_cs      => RTC_CS,
		rtc_wr_n    => RTC_WR_N,
		loader_done => LOADER_DONE,
		led1        => LED1,
		led2        => LED2,
		led1_owr    => LED1_OWR,
		led2_owr    => LED2_OWR,
		cfg         => CFG,
		max_turbo   => MAX_TURBO,
		build_a     => build_a,
		build_q     => build_q,
		soft_sw     => soft_sw_v,
		kb_mode     => KB_MODE,
		reset       => RESET,
		turbo       => TURBO,
		magick      => MAGICK,
		wait_cpu    => WAIT_CPU,
		joy_type    => JOY_TYPE,
		joy_mode    => JOY_MODE,
		osd_overlay => OSD_OVERLAY,
		osd_popup   => OSD_POPUP,
		screen_mode => SCREEN_MODE,
		divmmc_en   => DIVMMC_EN,
		nemoide_en  => NEMOIDE_EN,
		plus3e      => PLUS3E,
		joy         => JOY,
		joy_btn     => JOY_BTN,
		osd_wr      => OSD_WR,
		osd_a       => OSD_A,
		osd_d       => OSD_D
	);

	-- SOFT_SW(1) is soft_sw_v(0) ... SOFT_SW(10) is soft_sw_v(9)
	SOFT_SW(1)  <= soft_sw_v(0);
	SOFT_SW(2)  <= soft_sw_v(1);
	SOFT_SW(3)  <= soft_sw_v(2);
	SOFT_SW(4)  <= soft_sw_v(3);
	SOFT_SW(5)  <= soft_sw_v(4);
	SOFT_SW(6)  <= soft_sw_v(5);
	SOFT_SW(7)  <= soft_sw_v(6);
	SOFT_SW(8)  <= soft_sw_v(7);
	SOFT_SW(9)  <= soft_sw_v(8);
	SOFT_SW(10) <= soft_sw_v(9);

	MS_DELTA_X <= signed(ms_dx);
	MS_DELTA_Y <= signed(ms_dy);

	-- build id (8 ASCII characters of the build time)
	U_MESSAGES: entity work.message_rom
	port map (
		address => build_a,
		clock   => CLK,
		q       => build_q
	);

end RTL;
