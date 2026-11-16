-- behavioural models of the Quartus IP used by avr.vhd (rtc ram, spi queue, message rom)
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity rtc is port (data : in std_logic_vector(7 downto 0); rdaddress : in std_logic_vector(7 downto 0); rdclock : in std_logic;
  wraddress : in std_logic_vector(7 downto 0); wrclock : in std_logic := '1'; wren : in std_logic := '0'; q : out std_logic_vector(7 downto 0)); end;
architecture m of rtc is type tm is array (0 to 255) of std_logic_vector(7 downto 0); signal mem : tm := (others => x"00");
  signal ra : std_logic_vector(7 downto 0) := x"00"; begin
  process (wrclock) begin if rising_edge(wrclock) then if wren = '1' then mem(to_integer(unsigned(wraddress))) <= data; end if; end if; end process;
  process (rdclock) begin if rising_edge(rdclock) then ra <= rdaddress; q <= mem(to_integer(unsigned(ra))); end if; end process;
end;

library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity queue is port (data : in std_logic_vector(23 downto 0); rdclk : in std_logic; rdreq : in std_logic; wrclk : in std_logic; wrreq : in std_logic;
  q : out std_logic_vector(23 downto 0); rdempty : out std_logic; rdusedw : out std_logic_vector(8 downto 0); wrfull : out std_logic; wrusedw : out std_logic_vector(8 downto 0)); end;
architecture m of queue is type tm is array (0 to 511) of std_logic_vector(23 downto 0); signal mem : tm; signal wp, rp : unsigned(8 downto 0) := (others => '0');
  signal n : integer range 0 to 512 := 0; begin
  process (wrclk) variable nn : integer; begin if rising_edge(wrclk) then nn := n;
    if wrreq = '1' and n < 512 then mem(to_integer(wp)) <= data; wp <= wp + 1; nn := nn + 1; end if;
    if rdreq = '1' and n > 0 then q <= mem(to_integer(rp)); rp <= rp + 1; nn := nn - 1; end if;
    n <= nn; end if; end process;
  rdempty <= '1' when n = 0 else '0'; wrfull <= '1' when n = 512 else '0';
  wrusedw <= std_logic_vector(to_unsigned(n mod 512, 9)); rdusedw <= std_logic_vector(to_unsigned(n mod 512, 9));
end;

library ieee; use ieee.std_logic_1164.all;
entity message_rom is port (address : in std_logic_vector(2 downto 0); clock : in std_logic := '1'; q : out std_logic_vector(7 downto 0)); end;
architecture m of message_rom is begin process (clock) begin if rising_edge(clock) then q <= x"30"; end if; end process; end;
