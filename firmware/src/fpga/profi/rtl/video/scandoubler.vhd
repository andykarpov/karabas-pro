-------------------------------------------------------------------------------
-- Scandoubler for the Karabas-Pro Profi core
--
-- Doubles the 15.6 kHz picture of the internal video controller to 31.25 kHz
-- VGA. Replaces the VGA_PAL module (originally written for the external ZXKit1
-- board), which recovered the scan from the sync pulses and was clocked by
-- counter bits.
--
-- * One clock (CLK = clk_bus, 28 / 24 MHz) and an input pixel enable
--   (CE = clk_div2, one input pixel per two CLK cycles).
-- * The input line starts at the falling edge of HSYNC_IN; the line number
--   comes from VCNT_IN (paper-relative: 0 is the first paper line), and the
--   number of lines per frame is measured, so all screen modes (Pentagon /
--   Classic, 50 / 60 Hz, Profi) use the same logic.
-- * Each input line is written to one half of a two-line buffer and read
--   twice from the other half at the double rate.
-- * VGA timing uses the proportions of VESA 640x480 (sync 3.8 us, back porch
--   1.9 us, front porch 0.6 us; vertical sync 2 lines, back porch 34,
--   front porch 10), with negative sync polarity. The visible window is
--   centred on the paper area.
-- * EN = '0': no doubling, the input RGB and composite sync pass through.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scandoubler is
	port (
		CLK       : in  std_logic;                     -- 28 / 24 MHz (clk_bus)
		CE        : in  std_logic;                     -- input pixel enable, 14 / 12 MHz
		DS80      : in  std_logic;                     -- 0 = Spectrum, 1 = Profi
		EN        : in  std_logic := '1';              -- 1 = VGA, 0 = pass-through (15 kHz)

		RGB_IN    : in  std_logic_vector(8 downto 0);  -- RRRGGGBBB
		HSYNC_IN  : in  std_logic;                     -- active low
		VSYNC_IN  : in  std_logic;                     -- active low
		VCNT_IN   : in  std_logic_vector(8 downto 0);  -- input line, 0 = first paper line

		RGB_O     : out std_logic_vector(8 downto 0) := (others => '0');
		HSYNC_O   : out std_logic := '1';
		VSYNC_O   : out std_logic := '1'
	);
end entity;

architecture rtl of scandoubler is

	-- Horizontal timing in CLK cycles (= input pixels, a VGA line is one input
	-- line long at the double rate). Paper is 512 input pixels in both modes
	-- (256 Spectrum pixels at 7 MHz, 512 Profi pixels at 12 MHz).
	--   line   = paper + 2 * border + front + sync + back
	--   Spectrum: 896 @ 28 MHz = 512 + 2*103 + 18 + 107 + 53 (32.0 us)
	--   Profi:    768 @ 24 MHz = 512 + 2*51  + 15 +  92 + 47 (32.0 us)
	-- PAPER_x is where the first paper pixel sits after the start of HSYNC_IN
	-- (measured in simulation with the video controller and the OSD overlay,
	-- whose registered output adds one pixel).
	constant SPEC_LINE   : natural := 896;
	constant SPEC_PAPER  : natural := 260;
	constant SPEC_BORDER : natural := 103;
	constant SPEC_FRONT  : natural := 18;
	constant SPEC_SYNC   : natural := 107;

	constant PROF_LINE   : natural := 768;
	constant PROF_PAPER  : natural := 187;
	constant PROF_BORDER : natural := 51;
	constant PROF_FRONT  : natural := 15;
	constant PROF_SYNC   : natural := 92;

	constant PAPER_W     : natural := 512;

	-- Vertical timing in VGA lines (two per input line). With N input lines
	-- per frame and P paper lines, the frame is 2N lines:
	--   visible = 2N - 46, front porch 10, sync 2, back porch 34,
	-- and the visible window is centred on the 2P paper lines.
	constant SPEC_PAPER_V : natural := 192;
	constant PROF_PAPER_V : natural := 240;

	-- the same windows as positions of the buffer read counter h (0 = start of
	-- HSYNC_IN), computed at elaboration so the logic only compares h with
	-- constants. The active part never wraps around the end of the line, the
	-- sync does (it starts in the line's tail and ends in the next line).
	constant SPEC_ACT_START  : natural := SPEC_PAPER - SPEC_BORDER;
	constant SPEC_ACT_END    : natural := SPEC_PAPER + PAPER_W + SPEC_BORDER;
	constant SPEC_SYNC_START : natural := SPEC_ACT_END + SPEC_FRONT;
	constant SPEC_SYNC_END   : natural := SPEC_SYNC_START + SPEC_SYNC - SPEC_LINE;
	constant PROF_ACT_START  : natural := PROF_PAPER - PROF_BORDER;
	constant PROF_ACT_END    : natural := PROF_PAPER + PAPER_W + PROF_BORDER;
	constant PROF_SYNC_START : natural := PROF_ACT_END + PROF_FRONT;
	constant PROF_SYNC_END   : natural := PROF_SYNC_START + PROF_SYNC - PROF_LINE;

	-- line buffer: two lines of 1024 pixels
	type t_ram is array (0 to 2047) of std_logic_vector(8 downto 0);
	signal ram          : t_ram;
	signal ram_q        : std_logic_vector(8 downto 0) := (others => '0');

	-- input side
	signal hs_d         : std_logic := '1';
	signal in_h         : unsigned(9 downto 0) := (others => '0');
	signal bank         : std_logic := '0';
	signal line_start   : std_logic;
	signal wr_h         : unsigned(9 downto 0);
	signal wr_bank      : std_logic;
	signal vl_cur       : unsigned(8 downto 0) := (others => '0');
	signal vl_prev      : unsigned(8 downto 0) := (others => '0');
	signal np           : unsigned(9 downto 0) := to_unsigned(320 + 192, 10); -- N + P

	-- output side
	signal h            : unsigned(9 downto 0) := (others => '0');
	signal half         : std_logic := '0';
	signal d            : signed(10 downto 0);

	signal h_last       : std_logic;
	signal h_act        : std_logic;
	signal h_sync       : std_logic;
	signal h_sync_start : std_logic;
	signal v_act        : std_logic;
	signal v_sync_next  : std_logic;

	signal act_d        : std_logic := '0';
	signal hs_o_d       : std_logic := '1';
	signal vs_l         : std_logic := '1';

	function c(v : natural) return unsigned is begin return to_unsigned(v, 10); end;

begin

	---------------------------------------------------------------------------
	-- input: write each input line into one half of the buffer

	line_start <= '1' when CE = '1' and HSYNC_IN = '0' and hs_d = '1' else '0';
	wr_h       <= (others => '0') when line_start = '1' else in_h + 1;
	wr_bank    <= not bank when line_start = '1' else bank;

	process (CLK)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				hs_d <= HSYNC_IN;
				in_h <= wr_h;
				bank <= wr_bank;
				ram(to_integer(unsigned'(wr_bank & wr_h))) <= RGB_IN;
				if line_start = '1' then
					vl_prev <= vl_cur;
					vl_cur  <= unsigned(VCNT_IN);
					-- first line of a frame: the previous one was line N - 1
					if unsigned(VCNT_IN) = 0 then
						if DS80 = '1' then
							np <= ('0' & vl_cur) + (PROF_PAPER_V + 1);
						else
							np <= ('0' & vl_cur) + (SPEC_PAPER_V + 1);
						end if;
					end if;
				end if;
			end if;
			-- read the other half (the previous input line)
			ram_q <= ram(to_integer(unsigned'((not bank) & h)));
		end if;
	end process;

	---------------------------------------------------------------------------
	-- output: two VGA lines per input line

	h_last <= '1' when (DS80 = '1' and h = c(PROF_LINE - 1)) or (DS80 = '0' and h = c(SPEC_LINE - 1)) else '0';

	process (CLK)
	begin
		if rising_edge(CLK) then
			if line_start = '1' then
				h    <= (others => '0');
				half <= '0';
			elsif h_last = '1' then
				h    <= (others => '0');
				half <= '1';
			else
				h    <= h + 1;
			end if;
		end if;
	end process;

	h_act <= '1' when (DS80 = '1' and h >= c(PROF_ACT_START) and h < c(PROF_ACT_END)) or
	                  (DS80 = '0' and h >= c(SPEC_ACT_START) and h < c(SPEC_ACT_END)) else '0';
	h_sync <= '1' when (DS80 = '1' and (h >= c(PROF_SYNC_START) or h < c(PROF_SYNC_END))) or
	                   (DS80 = '0' and (h >= c(SPEC_SYNC_START) or h < c(SPEC_SYNC_END))) else '0';
	h_sync_start <= '1' when (DS80 = '1' and h = c(PROF_SYNC_START)) or (DS80 = '0' and h = c(SPEC_SYNC_START)) else '0';

	-- d: VGA line (2 * input line + half, 0 = first paper line) minus N + P.
	-- With 2N lines per frame and 2P paper lines:
	--   visible     d < -24 or d >= 22  (2N - 46 lines, centred on the paper)
	--   front porch -24 .. -15, sync -14 .. -13, back porch 34 lines.
	-- The vertical sync is latched at the start of the horizontal sync that
	-- begins the next VGA line, so it is tested one line early (-15 .. -14).
	d <= signed('0' & vl_prev & half) - signed('0' & np);
	v_act       <= '1' when d < -24 or d >= 22 else '0';
	v_sync_next <= '1' when d >= -15 and d < -13 else '0';

	process (CLK)
	begin
		if rising_edge(CLK) then
			-- stage 1: aligned with ram_q
			act_d  <= h_act and v_act;
			hs_o_d <= not h_sync;
			if h_sync_start = '1' then
				vs_l <= not v_sync_next;
			end if;

			-- stage 2: outputs
			if EN = '1' then
				if act_d = '1' then
					RGB_O <= ram_q;
				else
					RGB_O <= (others => '0');
				end if;
				HSYNC_O <= hs_o_d;
				VSYNC_O <= vs_l;
			else
				RGB_O   <= RGB_IN;
				HSYNC_O <= HSYNC_IN xor (not VSYNC_IN);
				VSYNC_O <= '1';
			end if;
		end if;
	end process;

end architecture;
