-- The whole Profi core (karabas_pro.vhd: T80, memory, ports, video, AVR link)
-- runs from power-on with the ROM bank +3e selected (PLUS3E forced on the AVR
-- flag). The SRAM model holds the +3e ROM at #150000, as the loader leaves it;
-- top_models.vhd replaces the PLLs, clock muxes, the Verilog AY and the loader.
-- Every millisecond the bench reports #7FFD, #1FFD and the CPU address; at the
-- end the screen of banks 5 and 7 is written to screen5.txt / screen7.txt
-- (render_screen.py makes a PNG). TURBO = "10" runs the CPU at 14 MHz.
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
entity tb_boot is generic (RUN_MS : natural := 10; TURBO : std_logic_vector(1 downto 0) := "00"; PLUS3E : std_logic := '1'); end;
architecture sim of tb_boot is
  signal clk50 : std_logic := '0';
  signal sram_d : std_logic_vector(7 downto 0) := (others => 'Z');
  signal sram_a : std_logic_vector(20 downto 0);
  signal sram_nwr, sram_nrd, ce1, ce2, ce3 : std_logic;
  signal sd : std_logic_vector(15 downto 0);
  signal sd_mosi : std_logic := 'Z';
  signal done : boolean := false;
  type mem_t is array (0 to 2 ** 21 - 1) of std_logic_vector(7 downto 0);
begin
  clk50 <= not clk50 after 10 ns when not done;
  sd(15 downto 8) <= x"FF"; sd(7 downto 0) <= (others => 'Z');

  dut: entity work.karabas_pro
    generic map (enable_zxuno_uart => false, enable_zxuno_uart2 => false, enable_zifi_uart => false,
                 enable_saa1099 => false, enable_osd_icons => false, enable_plus3e => true)
    port map (CLK_50MHZ => clk50, SRAM_D => sram_d, SRAM_A => sram_a, SRAM_NWR => sram_nwr, SRAM_NRD => sram_nrd,
      DATA0 => '1', NCSO => open, DCLK => open, ASDO => open, SD_NCS => open, SD_NDET => '0',
      VGA_R => open, VGA_G => open, VGA_B => open, VGA_HS => open, VGA_VS => open,
      AVR_SCK => '0', AVR_MOSI => '0', AVR_MISO => open, AVR_NCS => '1',
      NRESET => open, CPLD_CLK => open, CPLD_CLK2 => open, SDIR => open, SA => open, SD => sd,
      SND_BS => open, SND_WS => open, SND_DAT => open, PIN_141 => open, PIN_138 => open, PIN_25 => '1',
      PIN_121 => ce1, PIN_120 => ce2, PIN_7 => ce3, FDC_STEP => '0', SD_MOSI => sd_mosi,
      TAPE_IN => '1', TAPE_OUT => open, BUZZER => open, UART_RX => '1', UART_TX => open, UART_CTS => open);

  force_p3: process begin
    <<signal .tb_boot.dut.plus3e_avr : std_logic>> <= force PLUS3E;
    <<signal .tb_boot.dut.kb_turbo : std_logic_vector(1 downto 0)>> <= force TURBO;
    wait;
  end process;

  sram: process (sram_a, sram_nrd, sram_nwr, sram_d, ce1, done)
    variable mem : mem_t := (others => x"00");
    variable loaded : boolean := false;
    variable wa : natural; variable wd : std_logic_vector(7 downto 0);
    file fh : text; variable l : line; variable v : std_logic_vector(7 downto 0);
    procedure dump(name : string; base : natural) is
      file fo : text open write_mode is name; variable lo : line;
    begin
      for i in 0 to 6911 loop hwrite(lo, mem(base + i)); writeline(fo, lo); end loop;
    end;
  begin
    if not loaded then
      file_open(fh, "plus3e.txt", read_mode);
      for i in 0 to 65535 loop readline(fh, l); hread(l, v); mem(16#150000# + i) := v; end loop;
      file_close(fh);
      loaded := true;
    end if;
    if sram_nwr = '0' and ce1 = '0' then
      wa := to_integer(unsigned(sram_a)); wd := sram_d;
    end if;
    if rising_edge(sram_nwr) then mem(wa) := wd; end if;
    if sram_nrd = '0' and ce1 = '0' and sram_nwr = '1' then
      sram_d <= mem(to_integer(unsigned(sram_a))) after 10 ns;
    else
      sram_d <= (others => 'Z') after 2 ns;
    end if;
    if done then dump("screen5.txt", 16#14000#); dump("screen7.txt", 16#1C000#); end if;
  end process;


  mon: process
    alias p7 is <<signal .tb_boot.dut.port_7ffd_reg : std_logic_vector(7 downto 0)>>;
    alias p1 is <<signal .tb_boot.dut.port_1ffd_reg : std_logic_vector(7 downto 0)>>;
    alias a is <<signal .tb_boot.dut.cpu_a_bus : std_logic_vector(15 downto 0)>>;
  begin
    for t in 1 to RUN_MS loop
      wait for 1 ms;
      report "t=" & integer'image(t) & " ms  7FFD=" & to_hstring(p7) & " 1FFD=" & to_hstring(p1) & " A=" & to_hstring(a);
    end loop;
    done <= true; wait for 1 ns;
    std.env.finish;
  end process;
end;
