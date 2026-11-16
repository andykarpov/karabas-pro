-- avr.vhd RTC handling: a register sent by the AVR is written into the RTC ram
-- once, a CPU write is not overwritten afterwards, and one CPU write sends one
-- CMD_RTC packet to the AVR. The SPI master plays the AVR (mode 0, 24-bit frames).
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity tb_rtc is end;
architecture sim of tb_rtc is
  signal clk : std_logic := '0';
  signal n_reset : std_logic := '0';
  signal sck, mosi : std_logic := '0'; signal ss : std_logic := '1'; signal miso : std_logic;
  signal rtc_a, rtc_di, rtc_do : std_logic_vector(7 downto 0) := x"00";
  signal rtc_wr_n : std_logic := '1';
  signal done : boolean := false;
  signal rtc_pkts : integer := 0;
  signal errors : integer := 0;
  signal joy_mode : std_logic_vector(2 downto 0);
begin
  clk <= not clk after 17.857 ns when not done;
  DUT: entity work.avr port map (CLK => clk, CLKEN => '1', N_RESET => n_reset, A => x"FF",
    AVR_MOSI => mosi, AVR_MISO => miso, AVR_SCK => sck, AVR_SS => ss,
    RTC_A => rtc_a, RTC_DI => rtc_di, RTC_DO => rtc_do, RTC_CS => '1', RTC_WR_N => rtc_wr_n,
    LOADER_DONE => '1', CFG => x"00", JOY_MODE => joy_mode);

  -- packets the FPGA queues for the AVR
  count: process
    alias wr is <<signal DUT.queue_wr_req : std_logic>>;
    alias di is <<signal DUT.queue_di : std_logic_vector(23 downto 0)>>;
  begin
    wait until rising_edge(clk);
    if wr = '1' and di(23 downto 16) = x"FA" then rtc_pkts <= rtc_pkts + 1; end if;
  end process;

  stim: process
    procedure frame(w : std_logic_vector(23 downto 0)) is begin
      ss <= '0'; wait for 1 us;
      for i in 23 downto 0 loop mosi <= w(i); wait for 500 ns; sck <= '1'; wait for 500 ns; sck <= '0'; end loop;
      wait for 1 us; ss <= '1'; wait for 4 us;
    end;
    -- CPU write to an RTC register: the strobe lasts ~600 ns, like an OUT at 3.5 MHz
    procedure cpu_write(a, d : std_logic_vector(7 downto 0)) is begin
      wait until rising_edge(clk); rtc_a <= a; rtc_di <= d; rtc_wr_n <= '0';
      wait for 600 ns; wait until rising_edge(clk); rtc_wr_n <= '1'; wait for 1 us;
    end;
    procedure check(a, expect : std_logic_vector(7 downto 0); what : string) is begin
      rtc_a <= a; for i in 1 to 4 loop wait until rising_edge(clk); end loop;
      if rtc_do = expect then
        report what & ": reg " & to_hstring(a) & " = " & to_hstring(rtc_do) & " ok";
      else
        report what & ": reg " & to_hstring(a) & " = " & to_hstring(rtc_do) & " WRONG, expected " & to_hstring(expect);
        errors <= errors + 1;
      end if;
    end;
    variable p0 : integer;
    constant PKT : std_logic_vector(23 downto 0) := x"FA0855";
  begin
    wait for 200 ns; n_reset <= '1'; wait for 1 us;
    frame(x"FF0000");                       -- CMD_NOPE: avr ready
    frame(x"FA0511");                       -- avr sends reg 05 = 11
    check(x"05", x"11", "avr packet written       ");
    p0 := rtc_pkts;
    cpu_write(x"05", x"22");                -- cpu writes reg 05 = 22
    wait for 2 us;
    report "packets to avr for one cpu write: " & integer'image(rtc_pkts - p0) & " (expected 1)";
    if rtc_pkts - p0 /= 1 then errors <= errors + 1; end if;
    check(x"05", x"22", "cpu write kept           ");
    frame(x"FA0633");                       -- avr sends another register
    check(x"06", x"33", "second avr packet        ");
    check(x"05", x"22", "cpu write still kept     ");
    -- an avr packet that completes in the middle of a cpu write to another register
    rtc_a <= x"07"; rtc_di <= x"44";
    ss <= '0'; wait for 1 us;
    for i in 23 downto 0 loop mosi <= PKT(i); wait for 500 ns; sck <= '1'; wait for 500 ns; sck <= '0'; end loop;
    rtc_wr_n <= '0'; wait for 1 us; ss <= '1'; wait for 600 ns; rtc_wr_n <= '1'; wait for 4 us;
    check(x"07", x"44", "cpu write during packet  ");
    check(x"08", x"55", "packet during cpu write  ");
    wait for 10 ns;
    report "tb_rtc: " & integer'image(errors) & " errors";
    done <= true; wait;
  end process;
end;
