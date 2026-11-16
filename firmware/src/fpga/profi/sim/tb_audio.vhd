-- audio_mixer against an integer model (random inputs, extremes, ACB / ABC /
-- mono / mute), and tda1543 decoded like the DAC chips do (I2S for TDA1543,
-- LSB-justified for TDA1543A) against the samples it loaded.
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use ieee.math_real.all;
entity tb_audio is end;
architecture sim of tb_audio is
  type t8 is array (0 to 14) of std_logic_vector(7 downto 0);   -- ssg0 abc, ssg1 abc, covox a b c d fb, saa l r
  signal v : t8 := (others => x"00");
  signal clk, spk, mute, mono, abc : std_logic := '0';
  signal l, r : std_logic_vector(15 downto 0);
  signal done : boolean := false;
  signal mix_done : boolean := false;
  -- DAC
  signal dl, dr : std_logic_vector(15 downto 0) := (others => '0');
  signal dtype : std_logic := '0';
  signal bck, ws, dat : std_logic;
begin
  clk <= not clk after 17.857 ns when not done;
  M: entity work.audio_mixer port map (CLK => clk, MUTE => mute, MONO => mono, ABC => abc, SPEAKER => spk,
    SSG0_A => v(0), SSG0_B => v(1), SSG0_C => v(2), SSG1_A => v(3), SSG1_B => v(4), SSG1_C => v(5),
    COVOX_A => v(6), COVOX_B => v(7), COVOX_C => v(8), COVOX_D => v(9), COVOX_FB => v(10), SAA_L => v(11), SAA_R => v(12),
    AUDIO_L => l, AUDIO_R => r);
  D: entity work.tda1543 port map (RESET => '0', DAC_TYPE => dtype, CLK_BUS => clk, CS => '1',
    DATA_L => dl, DATA_R => dr, BCK => bck, WS => ws, DATA => dat);

  mix: process
    variable s1, s2 : positive := 5; variable x : real;
    function u(s : std_logic_vector) return integer is begin return to_integer(unsigned(s)); end;
    variable el, er, n, bad, maxv, minv : integer := 0;
    variable a0, b0, c0, a1, b1, c1, ca, cb, cc, cd, cf, sl, sr, sp : integer;
    impure function fl2(t : integer) return integer is begin if t >= 0 then return t / 2; else return -((-t + 1) / 2); end if; end;
  begin
    maxv := -100000; minv := 100000;
    for i in 0 to 200000 loop
      wait until rising_edge(clk); wait for 2 ns;
      for k in 0 to 12 loop
        uniform(s1, s2, x);
        if i < 4 then                      -- extremes: all max (i=0,2), all min (i=1,3)
          if i mod 2 = 0 then v(k) <= x"FF"; else v(k) <= x"00"; end if;
        else v(k) <= std_logic_vector(to_unsigned(integer(floor(x * 256.0)) mod 256, 8)); end if;
      end loop;
      uniform(s1, s2, x); if i < 4 then spk <= '1' when i mod 2 = 0 else '0'; elsif x < 0.5 then spk <= '1'; else spk <= '0'; end if;
      uniform(s1, s2, x); mute <= '1' when x < 0.02 else '0';
      uniform(s1, s2, x); mono <= '1' when x < 0.3 else '0';
      uniform(s1, s2, x); abc <= '1' when x < 0.5 else '0';
      if i < 2 then mono <= '0'; mute <= '0'; elsif i < 4 then mono <= '1'; mute <= '0'; end if;
      wait until rising_edge(clk); wait for 2 ns;           -- registered output
      a0 := u(v(0)); b0 := u(v(1)); c0 := u(v(2)); a1 := u(v(3)); b1 := u(v(4)); c1 := u(v(5));
      ca := u(v(6)) - 128; cb := u(v(7)) - 128; cc := u(v(8)) - 128; cd := u(v(9)) - 128; cf := u(v(10)) - 128;
      sl := u(v(11)); sr := u(v(12)); sp := 0; if spk = '1' then sp := 1; end if;
      if mute = '1' then el := 0; er := 0;
      elsif mono = '1' then
        el := fl2(sp * 2048 + 16 * (a0 + b0 + c0 + a1 + b1 + c1 + ca + cb + cc + cd + cf + sl + sr)); er := el;
      elsif abc = '0' then
        el := fl2(sp * 4096 + 32 * (a0 + a1) + 16 * (c0 + c1) + 32 * (ca + cb + cf) + 32 * sl);
        er := fl2(sp * 4096 + 32 * (b0 + b1) + 16 * (c0 + c1) + 32 * (cc + cd + cf) + 32 * sr);
      else
        el := fl2(sp * 4096 + 32 * (a0 + a1) + 16 * (b0 + b1) + 32 * (ca + cb + cf) + 32 * sl);
        er := fl2(sp * 4096 + 32 * (c0 + c1) + 16 * (b0 + b1) + 32 * (cc + cd + cf) + 32 * sr);
      end if;
      n := n + 1;
      if to_integer(signed(l)) /= el or to_integer(signed(r)) /= er then bad := bad + 1;
        if bad < 5 then report "MIX MISMATCH l=" & integer'image(to_integer(signed(l))) & " exp " & integer'image(el); end if; end if;
      if el > maxv then maxv := el; end if; if el < minv then minv := el; end if;
      if i = 0 then report "all max, stereo: L=" & integer'image(to_integer(signed(l))); end if;
      if i = 1 then report "all min, stereo: L=" & integer'image(to_integer(signed(l))); end if;
      if i = 2 then report "all max, mono:   L=" & integer'image(to_integer(signed(l))); end if;
      if i = 3 then report "all min, mono:   L=" & integer'image(to_integer(signed(l))); end if;
    end loop;
    report "mixer: checked " & integer'image(n) & ", mismatches " & integer'image(bad) & ", range " & integer'image(minv) & " .. " & integer'image(maxv);
    mix_done <= true; wait;
  end process;

  -- DAC: inputs change on every clock; the expected word is what the DAC took
  -- when it loaded its shift register (cnt = 0 at the falling edge), decoded from
  -- the serial stream like the chip does
  drive: process
    variable s1, s2 : positive := 9; variable x : real;
  begin
    wait until rising_edge(clk);
    uniform(s1, s2, x); dl <= std_logic_vector(to_unsigned(integer(floor(x * 65536.0)) mod 65536, 16));
    uniform(s1, s2, x); dr <= std_logic_vector(to_unsigned(integer(floor(x * 65536.0)) mod 65536, 16));
  end process;

  dac: process
    alias cnt is <<signal D.cnt : std_logic_vector(5 downto 0)>>;
    alias cnt_clk is <<signal D.cnt_clk : std_logic_vector(1 downto 0)>>;
    type tq is array (0 to 7) of std_logic_vector(15 downto 0);
    variable ql, qr : tq; variable wi, ril, rir : integer := 0;   -- loaded words, FIFO
    variable sh : std_logic_vector(23 downto 0); variable ws_prev : std_logic := '0';
    variable got : std_logic_vector(15 downto 0);
    variable n, bad, frames : integer;
  begin
    for t in 0 to 1 loop
      if t = 0 then dtype <= '0'; else dtype <= '1'; end if;
      n := 0; bad := 0; frames := 0; wi := 0; ril := 0; rir := 0;
      for c in 0 to 400000 loop
        wait on clk, bck;
        if clk'event and clk = '0' and cnt = "000000" and cnt_clk = "00" then      -- the load edge
          ql(wi mod 8) := dl; qr(wi mod 8) := dr; wi := wi + 1;
        end if;
        if bck'event and bck = '1' then
          if ws /= ws_prev and wi > 2 then
            if t = 0 then got := sh(14 downto 0) & dat; else got := sh(15 downto 0); end if;
            if (t = 0 and ws_prev = '0') or (t = 1 and ws_prev = '1') then     -- left word complete
              -- the left word ends inside the frame it was loaded in
              n := n + 1; if got /= ql((wi - 1) mod 8) then bad := bad + 1; end if;
            else
              -- the right word ends at the start of the next frame, after the next load
              n := n + 1; if got /= qr((wi - 2) mod 8) then bad := bad + 1; end if;
            end if;
          elsif ws /= ws_prev then
            -- skip the first, incomplete words
            if (t = 0 and ws_prev = '0') or (t = 1 and ws_prev = '1') then ril := wi - 1; else rir := wi - 1; end if;
          end if;
          sh := sh(22 downto 0) & dat; ws_prev := ws;
        end if;
      end loop;
      if t = 0 then report "DAC TDA1543 (I2S): words checked " & integer'image(n) & ", wrong " & integer'image(bad);
      else report "DAC TDA1543A (LSB-justified): words checked " & integer'image(n) & ", wrong " & integer'image(bad); end if;
    end loop;
    if not mix_done then wait until mix_done; end if;
    done <= true; wait;
  end process;
end;
