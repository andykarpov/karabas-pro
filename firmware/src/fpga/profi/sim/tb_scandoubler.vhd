library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
entity tb_scandoubler is
  generic (G_DS80 : integer := 0; G_MODE60 : integer := 0; G_SCR : integer := 0);
end;
architecture sim of tb_scandoubler is
  function b(i : integer) return std_logic is begin if i = 0 then return '0'; else return '1'; end if; end;
  constant DS80 : std_logic := b(G_DS80); constant MODE60 : std_logic := b(G_MODE60);
  constant SCR : std_logic_vector(1 downto 0) := std_logic_vector(to_unsigned(G_SCR, 2));
  function period return time is begin if G_DS80 = 1 then return 41.667 ns; else return 35.714 ns; end if; end;
  signal clk, div2, div4 : std_logic := '0';
  signal reset : std_logic := '1';
  signal vid_r, vid_g, vid_b : std_logic_vector(2 downto 0);
  signal rgb, rgb_vid : std_logic_vector(8 downto 0);
  signal blink : std_logic;
  signal hs, vs, ispaper : std_logic;
  signal vcnt : std_logic_vector(8 downto 0);
  signal hcnt : std_logic_vector(9 downto 0);
  signal vid_rd : std_logic := '0';
  signal o_rgb : std_logic_vector(8 downto 0);
  signal o_hs, o_vs : std_logic;
  signal done : boolean := false;
begin
  clk <= not clk after period/2 when not done;
  process (clk) begin if rising_edge(clk) then div2 <= not div2; if div2 = '0' then div4 <= not div4; end if; end if; end process;
  reset <= '0' after 1 us;

  U_VID: entity work.video port map (
    CLK2X => clk, CLK => div2, ENA => div4, RESET => reset, BORDER => x"01", DI => x"FF",
    TURBO => "00", INTA => '1', MODE60 => MODE60, INT => open, ATTR_O => open, pFF_CS => open, A => open,
    VIDEO_R => vid_r, VIDEO_G => vid_g, VIDEO_B => vid_b, HSYNC => hs, VSYNC => vs,
    DS80 => DS80, CS7E => '0', BUS_A => x"00", BUS_D => x"00", BUS_WR_N => '1', GX0 => open,
    SCREEN_MODE => SCR, COUNT_BLOCK => open, HCNT => hcnt, VCNT => vcnt, ISPAPER => ispaper, BLINK => blink,
    VBUS_MODE => '1', VID_RD => vid_rd);
  rgb_vid <= vid_r & vid_g & vid_b;
  U_OSD: entity work.overlay generic map (enable_osd_icons => true) port map (
    CLK => clk, DIV2 => div2, RGB_I => rgb_vid, RGB_O => rgb, DS80 => DS80,
    HCNT_I => hcnt, VCNT_I => vcnt, PAPER_I => ispaper, BLINK => blink,
    STATUS_SD => '0', STATUS_CF => '0', STATUS_FD => '0', OSD_ICONS => '0',
    OSD_OVERLAY => '0', OSD_POPUP => '0', OSD_COMMAND => x"0000");
  vid_rd <= div4;

  DUT: entity work.scandoubler port map (
    CLK => clk, CE => div2, DS80 => DS80, EN => '1',
    RGB_IN => rgb, HSYNC_IN => hs, VSYNC_IN => vs, VCNT_IN => vcnt,
    RGB_O => o_rgb, HSYNC_O => o_hs, VSYNC_O => o_vs);

  -- measurement on the VGA output
  meas: process
    alias act_s is <<signal DUT.act_d : std_logic>>;
    variable hs_prev, vs_prev : std_logic := '1';
    variable c, line_start_c, hs_low, hperiod, hsw, first_act, last_act, first_pap, last_pap : integer := 0;
    variable paper_rgb : std_logic_vector(8 downto 0);
    variable have_paper : boolean := false;
    variable lines, vs_line, vs_end_line, first_act_line, last_act_line, first_pap_line, last_pap_line, vsw : integer := -1;
    variable frames : integer := 0;
    variable cur : integer := 0;
    type t_line is array (0 to 1023) of std_logic_vector(8 downto 0);
    variable prevl, curl : t_line;
    variable pair_bad, pair_checked : integer := 0;
    variable act_this_line : boolean;
    variable fa, la, fp, lp : integer;
    variable s : line;
  begin
    -- reference paper colour from the input
    -- reference paper colour: the input RGB deep inside the paper area
    loop wait until rising_edge(clk); exit when ispaper = '1' and reset = '0'; end loop;
    for i in 1 to 200 loop wait until rising_edge(clk); end loop;
    paper_rgb := rgb;
    report "paper rgb = " & to_hstring(paper_rgb);
    loop
      wait until rising_edge(clk);
      c := c + 1;
      if o_hs = '0' and hs_prev = '1' then
        -- new VGA line starts at hsync falling edge
        hperiod := c - line_start_c; line_start_c := c;
        if fa >= 0 and frames = 3 then
          if act_this_line then
            if first_act_line < 0 then first_act_line := lines; end if;
            last_act_line := lines;
            first_act := fa; last_act := la;
          end if;
          if fp >= 0 then
            if first_pap_line < 0 then first_pap_line := lines; end if;
            last_pap_line := lines; first_pap := fp; last_pap := lp;
          end if;
          -- doubling check: lines 2k and 2k+1 after vsync must match
          if lines mod 2 = 1 then
            pair_checked := pair_checked + 1;
            for i in 0 to hperiod - 1 loop if prevl(i) /= curl(i) then pair_bad := pair_bad + 1; exit; end if; end loop;
          end if;
        end if;
        prevl := curl; cur := 0; fa := -1; la := -1; fp := -1; lp := -1; act_this_line := false;
        lines := lines + 1;
      end if;
      if o_hs = '1' and hs_prev = '0' then hsw := c - line_start_c; end if;
      hs_prev := o_hs;
      if cur <= 1023 then curl(cur) := o_rgb; end if;
      -- active area = clocks where the scandoubler is not blanking (stage 2 output)
      if act_s = '1' then
        act_this_line := true;
        if fa < 0 then fa := cur; end if; la := cur;
      end if;
      if o_rgb = paper_rgb then if fp < 0 then fp := cur; end if; lp := cur; end if;
      cur := cur + 1;
      if o_vs = '0' and vs_prev = '1' then
        if frames = 3 then
          write(s, string'("line period=") & integer'image(hperiod) & " hsync=" & integer'image(hsw) &
            " | act x " & integer'image(first_act) & ".." & integer'image(last_act) &
            " paper x " & integer'image(first_pap) & ".." & integer'image(last_pap) &
            " | lines/frame=" & integer'image(lines) & " vsync=" & integer'image(vsw) &
            " act lines " & integer'image(first_act_line) & ".." & integer'image(last_act_line) &
            " paper lines " & integer'image(first_pap_line) & ".." & integer'image(last_pap_line) &
            " | pairs bad " & integer'image(pair_bad) & "/" & integer'image(pair_checked));
          report s.all; deallocate(s);
          done <= true; wait;
        end if;
        frames := frames + 1; lines := 0;
        first_act_line := -1; last_act_line := -1; first_pap_line := -1; last_pap_line := -1;
      end if;
      if o_vs = '1' and vs_prev = '0' then vsw := lines; end if;
      vs_prev := o_vs;
    end loop;
  end process;
end;
