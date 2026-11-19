-- The old avr.vhd (sim/ref/avr_ref.vhd, master 8fbc791) fed with the v1 frames of the AVR host
-- stand (avr_replay.py v1, read from v1.rep in the working directory). At every "M" (a pass of the main loop of the AVR) the core side is
-- written to v1.state when it changed; every write into the OSD video memory (decoded from
-- OSD_COMMAND as overlay.vhd of master did) to v1.osd; at the end the 256 RTC registers.
-- tb_avr_replay_v2.v writes the same lines for the new module (run_avr_link.sh compares them).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_avr_replay_v1 is
	generic (
		SCK_NS : time := 250 ns
	);
end;

architecture sim of tb_avr_replay_v1 is
	signal clk : std_logic := '0';
	signal done : boolean := false;
	signal n_reset : std_logic := '0';
	signal sck, mosi : std_logic := '0';
	signal ss : std_logic := '1';
	signal miso : std_logic;
	signal a : std_logic_vector(15 downto 8) := x"FF";
	signal kb : std_logic_vector(5 downto 0);
	signal ms_x, ms_y : std_logic_vector(7 downto 0);
	signal ms_btns : std_logic_vector(2 downto 0);
	signal ms_z : std_logic_vector(3 downto 0);
	signal ms_preset, ms_event : std_logic;
	signal ms_dx, ms_dy : signed(7 downto 0);
	signal rtc_a : std_logic_vector(7 downto 0) := x"00";
	signal rtc_do : std_logic_vector(7 downto 0);
	signal soft_sw : std_logic_vector(1 to 10);
	signal kb_mode, reset, magick, wait_cpu, joy_type, osd_overlay, osd_popup, divmmc_en, nemoide_en, plus3e : std_logic;
	signal turbo, screen_mode : std_logic_vector(1 downto 0);
	signal joy_mode : std_logic_vector(2 downto 0);
	signal osd_command : std_logic_vector(15 downto 0);
	signal joy : std_logic_vector(7 downto 0);

	function bits(v : std_logic_vector) return std_logic_vector is
		variable r : std_logic_vector(v'length - 1 downto 0) := v;
	begin
		return r;
	end function;
begin
	clk <= not clk after 17.857 ns when not done;

	DUT: entity work.avr_ref port map (
		CLK => clk, CLKEN => '1', N_RESET => n_reset, A => a, KB => kb,
		AVR_MOSI => mosi, AVR_MISO => miso, AVR_SCK => sck, AVR_SS => ss,
		MS_X => ms_x, MS_Y => ms_y, MS_BTNS => ms_btns, MS_Z => ms_z, MS_PRESET => ms_preset,
		MS_EVENT => ms_event, MS_DELTA_X => ms_dx, MS_DELTA_Y => ms_dy,
		RTC_A => rtc_a, RTC_DI => x"00", RTC_DO => rtc_do, RTC_CS => '1', RTC_WR_N => '1',
		LOADER_DONE => '1', LED1 => '0', LED2 => '0', LED1_OWR => '0', LED2_OWR => '0',
		CFG => x"24", SOFT_SW => soft_sw, KB_MODE => kb_mode, KB_SCANCODE => open,
		RESET => reset, TURBO => turbo, MAGICK => magick, WAIT_CPU => wait_cpu,
		JOY_TYPE => joy_type, JOY_MODE => joy_mode, OSD_OVERLAY => osd_overlay, OSD_POPUP => osd_popup,
		OSD_COMMAND => osd_command, MAX_TURBO => "10", SCREEN_MODE => screen_mode,
		DIVMMC_EN => divmmc_en, NEMOIDE_EN => nemoide_en, PLUS3E => plus3e, LOADED => open, JOY => joy);

	-- the OSD writes, decoded as overlay.vhd of master
	osd: process (clk)
		file f : text open write_mode is "v1.osd";
		variable l : line;
		variable last : std_logic_vector(15 downto 0) := (others => '0');
		variable wa : std_logic_vector(9 downto 0) := (others => '0');
		variable chr : std_logic_vector(7 downto 0) := (others => '0');
	begin
		if rising_edge(clk) then
			if osd_command /= last then
				last := osd_command;
				case osd_command(15 downto 8) is
					when x"10" => wa(4 downto 0) := osd_command(4 downto 0);
					when x"11" => wa(9 downto 5) := osd_command(4 downto 0);
					when x"12" => chr := osd_command(7 downto 0);
					when x"13" =>
						write(l, string'("O ")); write(l, to_hstring("00" & wa));
						write(l, string'(" ")); write(l, to_hstring(chr & osd_command(7 downto 0)));
						writeline(f, l);
					when others => null;
				end case;
			end if;
		end if;
	end process;

	main: process
		file rf : text open read_mode is "v1.rep";
		file sf : text open write_mode is "v1.state";
		variable rl, l, s, prev : line;
		variable c : character;
		variable b : std_logic_vector(7 downto 0);
		variable k : integer;
		variable kbs : std_logic_vector(47 downto 0);
		variable ctl : std_logic_vector(19 downto 0);

		procedure xfer(v : std_logic_vector(7 downto 0)) is
		begin
			for i in 7 downto 0 loop
				mosi <= v(i);
				wait for SCK_NS / 2; sck <= '1';
				wait for SCK_NS / 2; sck <= '0';
			end loop;
		end procedure;
	begin
		wait for 200 ns; n_reset <= '1'; wait for 2 us;
		prev := new string'("");
		while not endfile(rf) loop
			readline(rf, rl);
			read(rl, c);
			if c = 'F' then
				ss <= '0'; wait for SCK_NS;
				for i in 0 to 2 loop hread(rl, b); xfer(b); end loop;
				wait for SCK_NS / 2; ss <= '1'; wait for 1 us;
			elsif c = 'M' then
				read(rl, k);
				for i in 1 to 20 loop wait until rising_edge(clk); end loop;
				for r in 0 to 7 loop
					a <= (others => '1'); a(8 + r) <= '0'; wait for 1 ns;
					kbs(r * 6 + 5 downto r * 6) := kb;
				end loop;
				a <= x"FF";
				ctl := "000" & plus3e & nemoide_en & divmmc_en & screen_mode & osd_popup & osd_overlay & joy_mode &
				       joy_type & kb_mode & wait_cpu & magick & turbo & reset;
				write(l, string'("KB=")); write(l, to_hstring(kbs));
				write(l, string'(" SW=")); write(l, to_hstring("00" & bits(soft_sw)));
				write(l, string'(" C=")); write(l, to_hstring(ctl));
				write(l, string'(" J=")); write(l, to_hstring(joy));
				write(l, string'(" MX=")); write(l, to_hstring(ms_x));
				write(l, string'(" MY=")); write(l, to_hstring(ms_y));
				write(l, string'(" MB=")); write(l, to_hstring('0' & ms_btns));
				write(l, string'(" MZ=")); write(l, to_hstring(ms_z));
				write(l, string'(" MP=")); write(l, ms_preset);
				write(l, string'(" ME=")); write(l, ms_event);
				write(l, string'(" DX=")); write(l, to_hstring(std_logic_vector(ms_dx)));
				write(l, string'(" DY=")); write(l, to_hstring(std_logic_vector(ms_dy)));
				if l.all /= prev.all then
					deallocate(prev); prev := new string'(l.all);
					write(s, string'("S ")); write(s, k); write(s, string'(" ")); write(s, l.all);
					writeline(sf, s);
				end if;
				deallocate(l);
			elsif c = 'E' then
				exit;
			end if;
		end loop;
		-- the RTC registers (2-clock read)
		for i in 0 to 255 loop
			rtc_a <= std_logic_vector(to_unsigned(i, 8));
			for j in 1 to 4 loop wait until rising_edge(clk); end loop;
			write(s, string'("R ")); write(s, to_hstring(std_logic_vector(to_unsigned(i, 8))));
			write(s, string'(" ")); write(s, to_hstring(rtc_do)); writeline(sf, s);
		end loop;
		done <= true;
		wait;
	end process;
end architecture;
