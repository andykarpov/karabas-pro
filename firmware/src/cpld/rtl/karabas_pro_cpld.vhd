library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity karabas_pro_cpld is 
port (
	-- Master clock
	CLK : in std_logic;
	CLK2: in std_logic;
	
	-- FPGA interface signals
	NRESET : in std_logic;
	SA: in std_logic_vector(1 downto 0);
	SDIR: in std_logic;
	SD: inout std_logic_vector(15 downto 0);

	-- BDI signals
	FDC_NWR: out std_logic;
	FDC_NRD: out std_logic;
	FDC_D: inout std_logic_vector(7 downto 0);	
	FDC_NCS: out std_logic;
	FDC_A: out std_logic_vector(1 downto 0);
	FDC_SL : in std_logic;
	FDC_SR : in std_logic;
	FDC_NRESET: out std_logic;
	FDC_INTRQ: in std_logic;
	FDC_DRQ: in std_logic;
	FDC_WF_DE: in std_logic;
	FDC_WD: in std_logic;
	FDC_TR43: in std_logic;
	FDC_NRAWR: out std_logic;
	FDC_RCLK : out std_logic;
	FDC_CLK: out std_logic;
	FDC_HLT: out std_logic;
	FDC_DS0: out std_logic;
	FDC_DS1: out std_logic;
	FDC_SIDE: out std_logic;
	FDC_RDATA: in std_logic;
	FDC_WDATA: out std_logic;
	
	-- HDD signals
	HDD_D: inout std_logic_vector(15 downto 0);
	HDD_A: out std_logic_vector(2 downto 0);
	HDD_NCS0: out std_logic;
	HDD_NCS1: out std_logic;
	HDD_NWR: out std_logic;
	HDD_NRD: out std_logic;
	HDD_NRESET: out std_logic
);
end karabas_pro_cpld;

architecture rtl of karabas_pro_cpld is 

--signal rx_buf_a: std_logic_vector(15 downto 0);
--signal rx_buf_d: std_logic_vector(7 downto 0);
signal rx_buf: std_logic_vector(7 downto 0);
--signal rx_valid : std_logic := '0';

signal clk_bus : std_logic;

signal bus_a : std_logic_vector(15 downto 0);
signal bus_di: std_logic_vector(7 downto 0);
signal bus_do: std_logic_vector(7 downto 0);
signal bus_wr_n : std_logic := '1';
signal bus_rd_n : std_logic := '1';
signal bus_mreq_n : std_logic := '1';
signal bus_iorq_n : std_logic := '1';
signal bus_m1_n : std_logic := '1';
signal bus_nmi_n : std_logic := '1';
signal bus_wait_n : std_logic := '1';
signal bus_cpm : std_logic;
signal bus_dos : std_logic;
signal bus_rom14 : std_logic;
signal oe_n : std_logic := '1';
signal ide_oe_n : std_logic := '1';
signal fdd_oe_n : std_logic := '1';
signal fdd_bus_do : std_logic_vector(7 downto 0);
signal ide_bus_do : std_logic_vector(7 downto 0);

begin 

	clk_bus <= SDIR;
	SD(15 downto 8) <= bus_do;
	
	-- rx
	process (CLK, SA, clk_bus)
	begin 
		if falling_edge(CLK) then
		--if clk_bus = '0' then
		case SA is 
			when "00" => 
				rx_buf <= SD(7 downto 0); -- rx
			when "01" => 
				bus_a(15 downto 8) <= rx_buf;
				bus_a(7 downto 0) <= SD(7 downto 0);
			when "10" =>
				bus_di <= SD(7 downto 0);
			when "11" =>
				bus_rd_n <= SD(7); -- rx
				bus_wr_n <= SD(6);
				bus_mreq_n <= SD(5);
				bus_iorq_n <= SD(4);
				bus_m1_n <= SD(3);
				bus_cpm <= not SD(2);
				bus_dos <= not SD(1);
				bus_rom14 <= SD(0);
			when others => null;
		end case;
		--end if;
		end if;
	end process;
	
	U1: entity work.ide_controller 
	port map (
		CLK => clk,
		NRESET => NRESET,
		
		CPM => bus_cpm,
		DOS => bus_dos,
		ROM14 => bus_rom14,
		
		BUS_DI => bus_di,
		BUS_DO => ide_bus_do,
		BUS_A => bus_a,
		BUS_RD_N => bus_rd_n,
		BUS_WR_N => bus_wr_n,
		BUS_MREQ_N => bus_mreq_n,
		BUS_IORQ_N => bus_iorq_n,
		BUS_M1_N => bus_m1_n,
		OE_N => ide_oe_n,
		
		IDE_A => HDD_A,
		IDE_D => HDD_D,
		IDE_CS0_N => HDD_NCS0,
		IDE_CS1_N => HDD_NCS1,
		IDE_RD_N => HDD_NRD,
		IDE_WR_N => HDD_NWR,
		IDE_RESET_N => HDD_NRESET
	);
	
	U2: entity work.fdd_controller
	port map (
		CLK => CLK,
		CLK8 => CLK2,
		NRESET => NRESET,
		
		CPM => bus_cpm,
		DOS => bus_dos,
		ROM14 => bus_rom14,
		
		BUS_DI => bus_di,
		BUS_DO => fdd_bus_do,
		BUS_A => bus_a,
		BUS_RD_N => bus_rd_n,
		BUS_WR_N => bus_wr_n,
		BUS_MREQ_N => bus_mreq_n,
		BUS_IORQ_N => bus_iorq_n,
		BUS_M1_N => bus_m1_n,

		OE_N => fdd_oe_n,
		
		FDC_NWR => FDC_NWR,
		FDC_NRD => FDC_NRD,
		FDC_D => FDC_D,	
		FDC_NCS => FDC_NCS,
		FDC_A => FDC_A,
		FDC_SL => FDC_SL,
		FDC_SR => FDC_SR,
		FDC_NRESET => FDC_NRESET,
		FDC_INTRQ => FDC_INTRQ,
		FDC_DRQ => FDC_DRQ,
		FDC_WF_DE => FDC_WF_DE,
		FDC_WD => FDC_WD,
		FDC_TR43 => FDC_TR43,
		FDC_NRAWR => FDC_NRAWR,
		FDC_RCLK => FDC_RCLK,
		FDC_CLK => FDC_CLK,
		FDC_HLT => FDC_HLT,
		FDC_DS0 => FDC_DS0,
		FDC_DS1 => FDC_DS1,
		FDC_SIDE => FDC_SIDE,
		FDC_RDATA => FDC_RDATA,
		FDC_WDATA => FDC_WDATA
	);
	
bus_do <= fdd_bus_do when fdd_oe_n = '0' else 
			 ide_bus_do when ide_oe_n = '0' else 
			"11111111";
oe_n <= '0' when ide_oe_n = '0' or fdd_oe_n = '0' else '1';

--bus_do <= fdd_bus_do;
--oe_n <= fdd_oe_n;

end rtl;
