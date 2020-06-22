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

signal fdc_do: std_logic := '0';
signal hdd_do: std_logic := '0'; 

begin 

	process (CLK, SD, SA, SDIR, NRESET)
	begin
		if (NRESET = '0') then

			fdc_do <= '0';
			hdd_do <= '0';
			
			FDC_NRESET <= '0';
			FDC_NWR <= '1';
			FDC_NRD <= '1';
			FDC_NCS <= '1';
			
			HDD_NRESET <= '0';
			HDD_NCS0 <= '1';
			HDD_NCS1 <= '1';
			HDD_NWR <= '1';
			HDD_NRD <= '1';
			
		elsif (rising_edge(CLK)) then

				if (SDIR = '1') then -- write from CPLD to FPGA
					case SA is
						when "00" => SD <= FDC_D & FDC_SL & FDC_SR & FDC_INTRQ & FDC_DRQ & FDC_WF_DE & FDC_WD & FDC_TR43 & FDC_RDATA;
						when "01" => SD <= HDD_D;
						when others => null;
					end case;
				else
					case SA is -- read from FPGA to CPLD
						when "00" => 
							fdc_do <= SD(15); 
							hdd_do <= SD(14);
							FDC_NWR <= SD(13);
							FDC_NCS <= SD(12);
							FDC_NRD <= SD(11);
							FDC_A(1 downto 0) <= SD(10 downto 9);
							FDC_NRESET <= SD(8);
							FDC_NRAWR <= SD(7);
							FDC_RCLK <= SD(6);
							FDC_CLK <= SD(5);
							FDC_HLT <= SD(4);
							FDC_DS0 <= SD(3);
							FDC_DS1 <= SD(2);
							FDC_SIDE <= SD(1);
							FDC_WDATA <= SD(0);
						when "01" => 
							if (fdc_do = '1') then
								FDC_D <= SD(15 downto 8);
							else
								FDC_D <= (others => 'Z');
							end if;
							HDD_NRESET <= SD(7);
							HDD_A <= SD(6 downto 4);
							HDD_NCS0 <= SD(3);
							HDD_NCS1 <= SD(2);
							HDD_NWR <= SD(1);
							HDD_NRD <= SD(0);
						when "10" => 
							if (hdd_do = '1') then
								HDD_D <= SD;
							else
								HDD_D <= (others => 'Z');
							end if;
						when others => null;
					end case;
				end if;
		end if;
	end process;

end rtl;
