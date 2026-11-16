-------------------------------------------------------------------------------
-- memory.vhd in the +3e mode (PLUS3E = '1') against the ZX Spectrum +3 memory
-- map: random #1FFD / #7FFD values and addresses, every CPU access checked.
--
--   #1FFD(0) = 0: 0000 ROM (#1FFD(2) & #7FFD(4)), 4000 bank 5, 8000 bank 2,
--                 C000 #7FFD(2..0); the ROM is read from SRAM #150000
--   #1FFD(0) = 1: RAM everywhere, #1FFD(2..1) selects 0-1-2-3, 4-5-6-7,
--                 4-5-6-3 or 4-7-6-3
--
-- Ends with "tb_plus3e: N accesses, M errors".
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_plus3e is end;

architecture sim of tb_plus3e is
	signal clk2x, clkx, clk_cpu, cpu_ce : std_logic := '0';
	signal done : boolean := false;
	signal A : std_logic_vector(15 downto 0) := (others => '0');
	signal n_mreq, n_rd, n_wr : std_logic := '1';
	signal ram_6mb : std_logic := '0';
	signal ma : std_logic_vector(20 downto 0);
	signal md : std_logic_vector(7 downto 0) := (others => 'Z');
	signal n_mrd, n_mwr, n_ce1, n_ce2, n_ce3, n_oe, vbus_mode : std_logic;
	signal ram_bank : std_logic_vector(2 downto 0) := "000";
	signal rom14, p3_rom2, p3_allram : std_logic := '0';
	signal p3_ramcfg : std_logic_vector(1 downto 0) := "00";
	signal cnt : unsigned(1 downto 0) := "00";

	type page_table is array (0 to 3, 0 to 3) of natural;
	constant ALLRAM : page_table := ((0, 1, 2, 3), (4, 5, 6, 7), (4, 5, 6, 3), (4, 7, 6, 3));
begin
	clk2x <= not clk2x after 17.857 ns when not done;
	-- clk_div2 and a CPU clock enable at every 4th clk2x edge, as in the top level
	process (clk2x) begin
		if rising_edge(clk2x) then
			cnt <= cnt + 1;
			clkx <= not cnt(0);
		end if;
	end process;
	cpu_ce <= '1' when cnt = "11" else '0';
	clk_cpu <= clk2x and cpu_ce;

	-- SRAM stays high impedance: the bench checks addresses and selects only
	md <= (others => 'Z');

	dut: entity work.memory port map (
		CLK2X => clk2x, CLKX => clkx, CLK_CPU => clk_cpu, CPU_CE => cpu_ce,
		A => A, D => x"00", N_MREQ => n_mreq, N_IORQ => '1', N_WR => n_wr, N_RD => n_rd, N_M1 => '1',
		RAM_6MB => ram_6mb,
		loader_act => '0', loader_ram_a => (others => '0'), loader_ram_do => x"00", loader_ram_wr => '0',
		DO => open, N_OE => n_oe,
		MA => ma, MD => md, N_MRD => n_mrd, N_MWR => n_mwr,
		N_CE1 => n_ce1, N_CE2 => n_ce2, N_CE3 => n_ce3,
		RAM_BANK => ram_bank, RAM_EXT => "00000", TRDOS => '0',
		VA => (others => '0'), VID_PAGE => '0', VID_DO => open,
		VBUS_MODE_O => vbus_mode, VID_RD_O => open,
		DS80 => '0', CPM => '0', SCO => '0', SCR => '0', WOROM => '0',
		ROM_BANK => rom14, EXT_ROM_BANK => "10",
		PLUS3E => '1', P3_ROM => p3_rom2 & rom14, P3_ALLRAM => p3_allram, P3_RAMCFG => p3_ramcfg,
		COUNT_BLOCK => '0', CONTENDED => open,
		DIVMMC_EN => '0', AUTOMAP => '0', REG_E3 => x"00",
		TURBO_MODE => "00");

	stim: process
		variable s1, s2 : positive := 7;
		variable x : real;
		variable n, bad, nrom, nallram : natural := 0;
		variable seg : natural;
		variable exp_hi : std_logic_vector(6 downto 0);
		variable exp_rom : boolean;
		variable cfg : std_logic_vector(2 downto 0);
		impure function rnd(bits : natural) return std_logic_vector is
		begin
			uniform(s1, s2, x);
			return std_logic_vector(to_unsigned(natural(floor(x * real(2 ** bits))), bits));
		end;
	begin
		for i in 1 to 50000 loop
			-- idle bus, then one CPU access held for four clk2x periods (the
			-- memory controller grants the bus on a new request only)
			n_mreq <= '1'; n_rd <= '1'; n_wr <= '1';
			for k in 1 to 4 loop wait until falling_edge(clk2x); end loop;
			cfg := rnd(3);                       -- #1FFD(2 downto 0)
			p3_allram <= cfg(0);
			p3_ramcfg <= cfg(2 downto 1);
			p3_rom2 <= cfg(2);
			rom14 <= rnd(1)(0);
			ram_bank <= rnd(3);
			ram_6mb <= rnd(1)(0);
			A <= rnd(16);
			n_mreq <= '0';
			if rnd(1) = "1" then n_rd <= '0'; n_wr <= '1'; else n_rd <= '1'; n_wr <= '0'; end if;
			for k in 1 to 4 loop
			wait until falling_edge(clk2x);
			wait for 8 ns;
			if vbus_mode = '0' then
				n := n + 1;
				seg := to_integer(unsigned(A(15 downto 14)));
				exp_rom := false;
				if p3_allram = '1' then
					exp_hi := std_logic_vector(to_unsigned(ALLRAM(to_integer(unsigned(p3_ramcfg)), seg), 7));
					nallram := nallram + 1;
				else
					case seg is
						when 0 => exp_hi := "10101" & p3_rom2 & rom14; exp_rom := true; nrom := nrom + 1;
						when 1 => exp_hi := "0000101";
						when 2 => exp_hi := "0000010";
						when others => exp_hi := "0000" & ram_bank;
					end case;
				end if;
				if ma(20 downto 14) /= exp_hi or ma(13 downto 0) /= A(13 downto 0) then
					bad := bad + 1;
					if bad <= 10 then
						report "A=" & to_hstring(A) & " 1FFD=" & to_string(cfg) & " 7FFD(4)=" & std_logic'image(rom14)
							& " bank=" & to_string(ram_bank) & ": MA(20..14)=" & to_string(ma(20 downto 14))
							& ", expected " & to_string(exp_hi) severity warning;
					end if;
				end if;
				-- ROM writes never reach the SRAM; RAM is written in all four segments in the special mode
				if exp_rom and n_wr = '0' and n_mwr = '0' then
					bad := bad + 1;
					report "write to ROM at " & to_hstring(A) severity warning;
				end if;
				-- 6 MB board: ROM in chip 3, these RAM pages in chip 1
				if ram_6mb = '1' and ((exp_rom and not (n_ce1 = '1' and n_ce3 = '0')) or
				                      (not exp_rom and not (n_ce1 = '0' and n_ce3 = '1'))) then
					bad := bad + 1;
					report "chip select wrong at " & to_hstring(A) severity warning;
				end if;
			end if;
			end loop;
		end loop;
		report "tb_plus3e: " & integer'image(n) & " accesses (" & integer'image(nrom) & " ROM, "
			& integer'image(nallram) & " special paging), " & integer'image(bad) & " errors";
		done <= true;
		wait;
	end process;
end;
