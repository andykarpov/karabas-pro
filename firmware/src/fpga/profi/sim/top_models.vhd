-- Behavioural models of the Quartus IP and Verilog blocks of the Profi top level
-- for a whole-core GHDL run (karabas_pro.vhd with the real RTL around them).
library ieee; use ieee.std_logic_1164.all;
entity altpll0 is port (inclk0 : in std_logic := '0'; c0 : out std_logic; locked : out std_logic); end;
architecture m of altpll0 is begin c0 <= '0'; locked <= '1'; end;

-- 84 / 28 MHz and 72 / 24 MHz, edge aligned like the PLL outputs; 8 MHz free running
library ieee; use ieee.std_logic_1164.all;
entity altpll1 is port (inclk0 : in std_logic := '0'; c0, c1, c2, c3, c4 : out std_logic; locked : out std_logic); end;
architecture m of altpll1 is
  signal k84, k72, k8 : std_logic := '0'; signal k28, k24 : std_logic := '0';
begin
  k84 <= not k84 after 5952 ps;
  k72 <= not k72 after 6944 ps;
  k8 <= not k8 after 62500 ps;
  process (k84) variable n : natural := 0; begin
    if n = 0 then k28 <= not k28; end if; n := (n + 1) mod 3; end process;
  process (k72) variable n : natural := 0; begin
    if n = 0 then k24 <= not k24; end if; n := (n + 1) mod 3; end process;
  c0 <= k84; c1 <= k72; c2 <= k28; c3 <= k24; c4 <= k8; locked <= '1';
end;

library ieee; use ieee.std_logic_1164.all;
entity clk_ctrl is port (clkselect : in std_logic := '0'; inclk0x, inclk1x : in std_logic; outclk : out std_logic); end;
architecture m of clk_ctrl is begin outclk <= inclk0x when clkselect = '0' else inclk1x; end;

library ieee; use ieee.std_logic_1164.all;
entity clk_ctrl2 is port (clkselect : in std_logic := '0'; inclk0x, inclk1x : in std_logic; outclk : out std_logic); end;
architecture m of clk_ctrl2 is begin outclk <= inclk0x when clkselect = '0' else inclk1x; end;

library ieee; use ieee.std_logic_1164.all;
entity mmux is port (data0x, data1x, data2x, data3x : in std_logic_vector(7 downto 0); sel : in std_logic_vector(1 downto 0); result : out std_logic_vector(7 downto 0)); end;
architecture m of mmux is begin
  with sel select result <= data0x when "00", data1x when "01", data2x when "10", data3x when others; end;

library ieee; use ieee.std_logic_1164.all;
entity bus_mux is port (data0x, data1x, data2x, data3x : in std_logic_vector(7 downto 0); sel : in std_logic_vector(1 downto 0); result : out std_logic_vector(7 downto 0)); end;
architecture m of bus_mux is begin
  with sel select result <= data0x when "00", data1x when "01", data2x when "10", data3x when others; end;

-- the AY / YM (Verilog) is silent here; reads return #FF
library ieee; use ieee.std_logic_1164.all;
entity ym2149 is port (CLK, CE, RESET, BDIR, BC : in std_logic; DI : in std_logic_vector(7 downto 0); DO : out std_logic_vector(7 downto 0);
  CHANNEL_A, CHANNEL_B, CHANNEL_C : out std_logic_vector(7 downto 0); SEL, MODE : in std_logic; ACTIVE : out std_logic_vector(5 downto 0);
  A8 : in std_logic; IOA_in : in std_logic_vector(7 downto 0); IOA_out : out std_logic_vector(7 downto 0);
  IOB_in : in std_logic_vector(7 downto 0); IOB_out : out std_logic_vector(7 downto 0)); end;
architecture m of ym2149 is begin
  DO <= x"FF"; CHANNEL_A <= x"00"; CHANNEL_B <= x"00"; CHANNEL_C <= x"00"; ACTIVE <= "000000"; IOA_out <= x"FF"; IOB_out <= x"FF"; end;

-- loader: the bench preloads the SRAM model with the ROM images, so this one
-- only holds LOADER_ACTIVE for a while and then pulses LOADER_RESET like the real one
library ieee; use ieee.std_logic_1164.all;
entity loader is port (CLK, RESET : in std_logic; RAM_A : out std_logic_vector(20 downto 0); RAM_DO : out std_logic_vector(7 downto 0); RAM_WR : out std_logic;
  CFG : out std_logic_vector(7 downto 0); FLASH_A : out std_logic_vector(23 downto 0); FLASH_DO : in std_logic_vector(7 downto 0);
  FLASH_RD_N : out std_logic; FLASH_BUSY, FLASH_READY : in std_logic; LOADER_ACTIVE, LOADER_RESET : out std_logic); end;
architecture m of loader is
  signal n : natural := 0;
begin
  RAM_A <= (others => '0'); RAM_DO <= x"00"; RAM_WR <= '0'; CFG <= x"00"; FLASH_A <= (others => '0'); FLASH_RD_N <= '1';
  process (CLK, RESET) begin
    if RESET = '1' then n <= 0;
    elsif rising_edge(CLK) then if n < 200 then n <= n + 1; end if; end if;
  end process;
  LOADER_ACTIVE <= '1' when n < 100 else '0';
  LOADER_RESET <= '1' when n >= 104 and n < 108 else '0';
end;

-- ZiFi is generated off in this bench (enable_zifi_uart = false); the entity is
-- only here so that the top level analyses
library ieee; use ieee.std_logic_1164.all;
entity zifi is port (CLK, RESET, DS80 : in std_logic; A : in std_logic_vector(15 downto 0); DI : in std_logic_vector(7 downto 0);
  DO : out std_logic_vector(7 downto 0); IORQ_N, RD_N, WR_N : in std_logic; ZIFI_OE_N, ENABLED, ZF_UART2 : out std_logic;
  UART_RX : in std_logic; UART_TX, UART_CTS : out std_logic); end;
architecture m of zifi is begin DO <= x"FF"; ZIFI_OE_N <= '1'; ENABLED <= '0'; ZF_UART2 <= '0'; UART_TX <= '1'; UART_CTS <= '0'; end;
