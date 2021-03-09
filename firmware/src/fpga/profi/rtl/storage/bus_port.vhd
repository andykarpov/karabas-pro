library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity bus_port is
	port (

	-- global clocks
	CLK 		: in std_logic;
	CLK2		: in std_logic;
	CLK_BUS 	: in std_logic;
	CLK_CPU 	: in std_logic;
	RESET 	: in std_logic;
	 
	-- physical interface with CPLD
	SD 			: inout std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	SA 			: out std_logic_vector(1 downto 0);
--	SDIR : out std_logic;
	CPLD_CLK 	: out std_logic;
	CPLD_CLK2	: out std_logic;
	NRESET 		: out std_logic;

	-- zx bus signals to rx/tx from/to the CPLD controller
	BUS_A 		: in std_logic_vector(4 downto 0);
	BUS_DI 		: in std_logic_vector(7 downto 0);
	BUS_DO 		: out std_logic_vector(7 downto 0);
	BUS_RD_N 	: in std_logic;
	BUS_WR_N 	: in std_logic;
	BUS_HDD_CS_N 		: in std_logic;
	BUS_WWC 		: in std_logic;
	BUS_WWE 		: in std_logic;
	BUS_RWW 		: in std_logic;
	BUS_RWE 		: in std_logic;
	BUS_CS3FX 	: in std_logic;
	BUS_FDC_STEP: in std_logic;
	BUS_CSFF 	: in std_logic;
	BUS_FDC_NCS : in std_logic		
	);
    end bus_port;
architecture RTL of bus_port is

signal cnt			: std_logic_vector(1 downto 0) := "00";
signal prev_clk_cpu : std_logic := '0';
signal bus_a_reg	: std_logic_vector(15 downto 0);
signal bus_d_reg	: std_logic_vector(7 downto 0);

begin
	
	CPLD_CLK <= CLK;
	CPLD_CLK2 <= CLK2;
	NRESET <= not reset;
	SA <= cnt;	
	BUS_DO <= SD(15 downto 8);

	process (CLK_CPU, BUS_HDD_CS_N, BUS_FDC_NCS, BUS_CSFF, BUS_CS3FX, BUS_RWE, BUS_RWW, BUS_WWE, BUS_WWC, BUS_FDC_STEP, BUS_RD_N, BUS_WR_N, bus_a, bus_di)
	begin 
		if CLK_CPU'event and CLK_CPU = '1' then 
				bus_a_reg <= BUS_HDD_CS_N & BUS_FDC_NCS & BUS_CSFF & BUS_CS3FX & BUS_RWE & BUS_RWW & BUS_WWE & BUS_WWC & BUS_FDC_STEP & BUS_RD_N & BUS_WR_N & bus_a;
				bus_d_reg <= bus_di;
		end if;
	end process;

	process (CLK, cnt, CLK_CPU, prev_clk_cpu)
	begin 
		if CLK'event and CLK = '1' then
			prev_clk_cpu <= CLK_CPU;
			if prev_clk_cpu = '0' and CLK_CPU = '1' then 
				cnt <= "11";
			else
				cnt <= cnt + 1;
			end if;
		end if;
	end process;

	UMUX: entity work.bus_mux
	port map(
		data0x => bus_a_reg(15 downto 8),
		data1x => bus_a_reg(7 downto 0),
		data2x => bus_d_reg,
		data3x => "11111111",
		sel => cnt,
		result => SD(7 downto 0)
	);

end RTL;

