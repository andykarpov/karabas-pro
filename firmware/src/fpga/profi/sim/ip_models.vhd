-- Behavioural simulation models of the Quartus IP used by the OSD overlay
-- (rom_font1, screen1, rom_font2). ROM contents are loaded from font.txt and
-- icons.txt, produced by mkroms.py from rtl/video/font.hex and icons.mif.
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
package romload is
  type t8 is array (0 to 2047) of std_logic_vector(7 downto 0);
  type t1 is array (0 to 2047) of std_logic;
  impure function load8(f : string) return t8;
  impure function load1(f : string) return t1;
end;
package body romload is
  impure function load8(f : string) return t8 is
    file fh : text open read_mode is f; variable l : line; variable v : std_logic_vector(7 downto 0); variable r : t8;
  begin for i in r'range loop readline(fh, l); hread(l, v); r(i) := v; end loop; return r; end;
  impure function load1(f : string) return t1 is
    file fh : text open read_mode is f; variable l : line; variable v : integer; variable r : t1;
  begin for i in r'range loop readline(fh, l); read(l, v); if v = 0 then r(i) := '0'; else r(i) := '1'; end if; end loop; return r; end;
end;

library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use work.romload.all;
entity rom_font1 is port (address : in std_logic_vector(10 downto 0); clken : in std_logic; clock : in std_logic; q : out std_logic_vector(7 downto 0)); end;
architecture m of rom_font1 is constant rom : t8 := load8("font.txt"); signal a : std_logic_vector(10 downto 0) := (others => '0'); begin
  process (clock) begin if rising_edge(clock) then if clken = '1' then q <= rom(to_integer(unsigned(a))); a <= address; end if; end if; end process;
end;

library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity screen1 is port (data : in std_logic_vector(15 downto 0); rdaddress : in std_logic_vector(9 downto 0); rdclken : in std_logic; rdclock : in std_logic;
  wraddress : in std_logic_vector(9 downto 0); wrclock : in std_logic; wren : in std_logic; q : out std_logic_vector(15 downto 0)); end;
architecture m of screen1 is type tm is array (0 to 1023) of std_logic_vector(15 downto 0); signal mem : tm := (others => (others => '0'));
  signal ra : std_logic_vector(9 downto 0) := (others => '0'); begin
  process (wrclock) begin if rising_edge(wrclock) then if wren = '1' then mem(to_integer(unsigned(wraddress))) <= data; end if; end if; end process;
  process (rdclock) begin if rising_edge(rdclock) then if rdclken = '1' then ra <= rdaddress; end if; end if; end process;
  q <= mem(to_integer(unsigned(ra)));
end;

library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use work.romload.all;
entity rom_font2 is port (address : in std_logic_vector(10 downto 0); clock : in std_logic; q : out std_logic_vector(0 downto 0)); end;
architecture m of rom_font2 is constant rom : t1 := load1("icons.txt"); signal a : std_logic_vector(10 downto 0) := (others => '0'); begin
  process (clock) begin if rising_edge(clock) then q(0) <= rom(to_integer(unsigned(a))); a <= address; end if; end process;
end;
