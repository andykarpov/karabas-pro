-- avr_link (rtl/avr/avr_link.v) for GHDL benches of the whole core that do not use the AVR
-- (tb_boot): GHDL does not read Verilog. The lines stay idle: no keys, menu values and controls
-- at their reset values, the RTC registers read 0. The link is simulated with iverilog
-- (run_avr_link.sh).
library ieee;
use ieee.std_logic_1164.all;

entity avr_link is
	port (
		clk, n_reset, avr_sck, avr_mosi, avr_ss : in std_logic;
		avr_miso    : out std_logic := 'Z';
		a           : in std_logic_vector(15 downto 8);
		kb          : out std_logic_vector(5 downto 0) := (others => '1');
		ms_x, ms_y  : out std_logic_vector(7 downto 0) := x"7F";
		ms_btns     : out std_logic_vector(2 downto 0) := "000";
		ms_z        : out std_logic_vector(3 downto 0) := "0000";
		ms_preset, ms_event : out std_logic := '0';
		ms_delta_x, ms_delta_y : out std_logic_vector(7 downto 0) := x"00";
		rtc_a, rtc_di : in std_logic_vector(7 downto 0);
		rtc_do      : out std_logic_vector(7 downto 0) := x"00";
		rtc_cs, rtc_wr_n, loader_done, led1, led2, led1_owr, led2_owr : in std_logic;
		cfg         : in std_logic_vector(7 downto 0);
		max_turbo   : in std_logic_vector(1 downto 0);
		build_a     : out std_logic_vector(2 downto 0) := "000";
		build_q     : in std_logic_vector(7 downto 0);
		soft_sw     : out std_logic_vector(9 downto 0) := (others => '0');
		kb_mode, reset : out std_logic := '0';
		turbo       : out std_logic_vector(1 downto 0) := "00";
		magick, wait_cpu, joy_type : out std_logic := '0';
		joy_mode    : out std_logic_vector(2 downto 0) := "000";
		osd_overlay, osd_popup : out std_logic := '0';
		screen_mode : out std_logic_vector(1 downto 0) := "00";
		divmmc_en, nemoide_en, plus3e : out std_logic := '0';
		joy         : out std_logic_vector(7 downto 0) := x"00";
		joy_btn     : out std_logic_vector(15 downto 0) := x"0000";
		osd_wr      : out std_logic := '0';
		osd_a       : out std_logic_vector(9 downto 0) := (others => '0');
		osd_d       : out std_logic_vector(15 downto 0) := (others => '0')
	);
end entity;

architecture stub of avr_link is
begin
end architecture;
