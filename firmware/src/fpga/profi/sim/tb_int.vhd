-- Frame INT of the video controller: rtl/video/video.vhd against the old one (sim/ref, master 8fbc791).
--
-- G_ACK = 0 (CPU at 3.5 MHz): the new video and the old one with TURBO "00" are compared clock by
--   clock on every output (INT, RGB, syncs, video address, attribute), with INTA pulses at random
--   places, also inside the INT.
-- G_ACK = 1 (CPU faster than 3.5 MHz): the INT starts where the old 3.5 MHz one starts, is low as
--   long as it until the first INTA inside it, and is high from the clock after that INTA to the
--   end of the window; the other outputs are the same as the old ones. The length of the old
--   turbo INT (TURBO "10") is reported for comparison.
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity tb_int is
  generic (G_DS80 : integer := 0; G_MODE60 : integer := 0; G_SCR : integer := 0; G_ACK : integer := 0;
           G_FRAMES : integer := 4; G_SEED : integer := 1);
end;
architecture sim of tb_int is
  function b(i : integer) return std_logic is begin if i = 0 then return '0'; else return '1'; end if; end;
  constant DS80 : std_logic := b(G_DS80); constant MODE60 : std_logic := b(G_MODE60);
  constant ACK : std_logic := b(G_ACK);
  constant SCR : std_logic_vector(1 downto 0) := std_logic_vector(to_unsigned(G_SCR, 2));
  function period return time is begin if G_DS80 = 1 then return 41.667 ns; else return 35.714 ns; end if; end;

  signal clk, div2, div4 : std_logic := '0';
  signal reset : std_logic := '1';
  signal inta : std_logic := '1';
  signal vid_rd : std_logic;

  type t_out is record
    int, hs, vs, ff, gx0, cb, paper, blink : std_logic;
    r, g, bl : std_logic_vector(2 downto 0);
    a : std_logic_vector(13 downto 0);
    attr : std_logic_vector(7 downto 0);
    hcnt : std_logic_vector(9 downto 0);
    vcnt : std_logic_vector(8 downto 0);
  end record;
  signal n, o, o10 : t_out;
begin
  clk <= not clk after period/2;
  process (clk) begin if rising_edge(clk) then div2 <= not div2; if div2 = '0' then div4 <= not div4; end if; end if; end process;
  reset <= '0' after 1 us;
  vid_rd <= div4;

  DUT: entity work.video port map (
    CLK2X => clk, CLK => div2, ENA => div4, RESET => reset, BORDER => x"05", DI => x"A5",
    INT_ACK => ACK, INTA => inta, MODE60 => MODE60, INT => n.int, ATTR_O => n.attr, pFF_CS => n.ff, A => n.a,
    VIDEO_R => n.r, VIDEO_G => n.g, VIDEO_B => n.bl, HSYNC => n.hs, VSYNC => n.vs,
    DS80 => DS80, CS7E => '0', BUS_A => x"00", BUS_D => x"00", BUS_WR_N => '1', GX0 => n.gx0,
    SCREEN_MODE => SCR, COUNT_BLOCK => n.cb, HCNT => n.hcnt, VCNT => n.vcnt, ISPAPER => n.paper, BLINK => n.blink,
    VBUS_MODE => '1', VID_RD => vid_rd);

  REF: entity work.video_ref port map (
    CLK2X => clk, CLK => div2, ENA => div4, RESET => reset, BORDER => x"05", DI => x"A5",
    TURBO => "00", INTA => inta, MODE60 => MODE60, INT => o.int, ATTR_O => o.attr, pFF_CS => o.ff, A => o.a,
    VIDEO_R => o.r, VIDEO_G => o.g, VIDEO_B => o.bl, HSYNC => o.hs, VSYNC => o.vs,
    DS80 => DS80, CS7E => '0', BUS_A => x"00", BUS_D => x"00", BUS_WR_N => '1', GX0 => o.gx0,
    SCREEN_MODE => SCR, COUNT_BLOCK => o.cb, HCNT => o.hcnt, VCNT => o.vcnt, ISPAPER => o.paper, BLINK => o.blink,
    VBUS_MODE => '1', VID_RD => vid_rd);

  -- the old turbo 4x INT, only measured
  REF10: entity work.video_ref port map (
    CLK2X => clk, CLK => div2, ENA => div4, RESET => reset, BORDER => x"05", DI => x"A5",
    TURBO => "10", INTA => inta, MODE60 => MODE60, INT => o10.int, ATTR_O => o10.attr, pFF_CS => o10.ff, A => o10.a,
    VIDEO_R => o10.r, VIDEO_G => o10.g, VIDEO_B => o10.bl, HSYNC => o10.hs, VSYNC => o10.vs,
    DS80 => DS80, CS7E => '0', BUS_A => x"00", BUS_D => x"00", BUS_WR_N => '1', GX0 => o10.gx0,
    SCREEN_MODE => SCR, COUNT_BLOCK => o10.cb, HCNT => o10.hcnt, VCNT => o10.vcnt, ISPAPER => o10.paper, BLINK => o10.blink,
    VBUS_MODE => '1', VID_RD => vid_rd);

  -- INTA: inside every second INT window at a random place, never inside the others, and a few
  -- random pulses between the windows
  stim: process
    variable seed : unsigned(31 downto 0) := to_unsigned(G_SEED * 7919 + 12345, 32);
    impure function rnd(m : integer) return integer is
    begin
      seed := resize(seed * to_unsigned(1664525, 32) + to_unsigned(1013904223, 32), 32);
      return to_integer(seed(30 downto 8)) mod m;
    end function;
    procedure pulse is
    begin
      inta <= '0';
      for i in 1 to 2 + rnd(6) loop wait until rising_edge(clk); end loop;
      inta <= '1';
    end procedure;
    variable k : integer := 0;
  begin
    wait until reset = '0';
    loop
      wait until rising_edge(clk) and o.int = '0';
      k := k + 1;
      if k mod 2 = 1 then
        for i in 1 to rnd(210) loop wait until rising_edge(clk); end loop;
        pulse;
      end if;
      wait until rising_edge(clk) and o.int = '1';
      for j in 1 to 3 loop
        for i in 1 to 20 + rnd(3000) loop wait until rising_edge(clk); end loop;
        pulse;
      end loop;
    end loop;
  end process;

  chk: process
    variable errs, frames, acked_n, plain_n, int_starts : integer := 0;
    variable len_new, len_old, len_old10 : integer := 0;
    variable max_new, max_old, max_old10 : integer := 0;
    variable acked, seen_inta : boolean := false;
    variable exp_int : std_logic;
    variable prev_old, prev_new : std_logic := '1';
    procedure err(s : string) is
    begin
      if errs < 10 then report "ERROR: " & s & " at " & time'image(now) severity error; end if;
      errs := errs + 1;
    end procedure;
  begin
    wait until reset = '0';
    -- the INT registers have no reset value: start where the old one is defined
    wait until rising_edge(clk) and o.int = '1';
    while frames < G_FRAMES loop
      wait until rising_edge(clk);
      -- everything but the INT is the old controller
      if n.r /= o.r or n.g /= o.g or n.bl /= o.bl or n.hs /= o.hs or n.vs /= o.vs or n.a /= o.a or
         n.attr /= o.attr or n.ff /= o.ff or n.gx0 /= o.gx0 or n.cb /= o.cb or n.hcnt /= o.hcnt or
         n.vcnt /= o.vcnt or n.paper /= o.paper or n.blink /= o.blink then
        err("video outputs differ");
      end if;
      -- the expected INT: the old 3.5 MHz one, high again from the clock after an INTA in it
      if o.int = '1' then
        exp_int := '1';
      elsif ACK = '1' and acked then
        exp_int := '1';
      else
        exp_int := '0';
      end if;
      if n.int /= exp_int then err("INT " & std_logic'image(n.int) & ", expected " & std_logic'image(exp_int)); end if;
      -- the acknowledge seen at this edge counts from the next clock (the register of video.vhd)
      if o.int = '1' then
        acked := false;
      elsif inta = '0' then
        acked := true; seen_inta := true;
      end if;
      -- lengths of the INT pulses
      if o.int = '0' then len_old := len_old + 1; end if;
      if n.int = '0' then len_new := len_new + 1; end if;
      if o10.int = '0' then len_old10 := len_old10 + 1; end if;
      if n.int = '0' and prev_new = '1' then int_starts := int_starts + 1; end if;
      if o.int = '1' and prev_old = '0' then
        -- end of a window
        frames := frames + 1;
        if seen_inta then acked_n := acked_n + 1; else plain_n := plain_n + 1; end if;
        if len_new > max_new then max_new := len_new; end if;
        if len_old > max_old then max_old := len_old; end if;
        if len_old10 > max_old10 then max_old10 := len_old10; end if;
        if int_starts /= frames then err("INT started " & integer'image(int_starts) & " times in " & integer'image(frames) & " windows"); end if;
        len_new := 0; len_old := 0; len_old10 := 0; seen_inta := false;
      end if;
      prev_old := o.int; prev_new := n.int;
    end loop;
    report "tb_int ds80=" & integer'image(G_DS80) & " mode60=" & integer'image(G_MODE60) &
      " scr=" & integer'image(G_SCR) & " ack=" & integer'image(G_ACK) &
      ": INT old 3.5 MHz " & integer'image(max_old) & " clk, old turbo 4x " & integer'image(max_old10) &
      " clk, new longest " & integer'image(max_new) & " clk; windows with INTA " & integer'image(acked_n) &
      ", without " & integer'image(plain_n) & "; " & integer'image(errs) & " errors";
    if acked_n = 0 or plain_n = 0 then report "ERROR: the stimulus did not cover both kinds of windows" severity error; end if;
    std.env.finish;
  end process;
end;
