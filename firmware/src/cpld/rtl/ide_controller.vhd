library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity ide_controller is 
port (
	CLK : in std_logic;
	NRESET : in std_logic := '1';
	
	BUS_DI : in std_logic_vector(7 downto 0);
	BUS_DO : out std_logic_vector(7 downto 0);
	BUS_A : in std_logic_vector(15 downto 0);
	BUS_RD_N : in std_logic;
	BUS_WR_N : in std_logic;
	BUS_MREQ_N : in std_logic;
	BUS_IORQ_N : in std_logic;
	BUS_M1_N : in std_logic;

	CPM : in std_logic;
	DOS : in std_logic;
	ROM14 : in std_logic;
	
	OE_N : out std_logic;
	
	IDE_A : out std_logic_vector(2 downto 0);
	IDE_D : inout std_logic_vector(15 downto 0);
	IDE_CS0_N : out std_logic;
	IDE_CS1_N : out std_logic;
	IDE_RD_N : out std_logic;
	IDE_WR_N : out std_logic;
	IDE_RESET_N : out std_logic
	
);
end ide_controller;

architecture rtl of ide_controller is 

--------------------HDD-NEMO/PROFI-----------------------
signal cs3fx		: std_logic;
signal cs_hdd_wr	: std_logic;
signal cs_hdd_rd	: std_logic;
signal hdd_iorqge	: std_logic;
signal profi_ebl	: std_logic;
signal rwe			: std_logic;
signal cs1fx		: std_logic;
signal wwe			: std_logic;
signal wwc			: std_logic;
signal rww			: std_logic;
signal WD_reg_in	: std_logic_vector(15 downto 0);
signal WD_reg_out	: std_logic_vector(15 downto 0);

begin 

-----------------HDD------------------
	-- Profi
wwc 	<='0' when BUS_WR_N='0' and BUS_A(7 downto 0)="11001011" and BUS_IORQ_N='0' and CPM='0' and dos='1' and rom14='1' else '1'; -- Write High byte from Data bus to "Write register"
wwe 	<='0' when BUS_WR_N='0' and BUS_A(7 downto 0)="11101011" and BUS_IORQ_N='0' and CPM='0' and dos='1' and rom14='1' else '1'; -- Read High byte from "Write register" to HDD bus
rww 	<='0' when BUS_WR_N='1' and BUS_A(7 downto 0)="11001011" and BUS_IORQ_N='0' and CPM='0' and dos='1' and rom14='1' else '1'; -- Selector Low byte Data bus Buffer Direction: 1 - to HDD bus, 0 - to Data bus
rwe 	<='0' when BUS_WR_N='1' and BUS_A(7 downto 0)="11101011" and BUS_IORQ_N='0' and CPM='0' and dos='1' and rom14='1' else '1'; -- Read High byte from "Read register" to Data bus
cs3fx <='0' when BUS_WR_N='0' and BUS_A(7 downto 0)="10101011" and BUS_IORQ_N='0' and CPM='0' and dos='1' and rom14='1' else '1';
cs1fx <= rww and wwe; -- Write High byte from HDD bus to "Read register"
cs_hdd_wr <= cs3fx and wwe and wwc;
cs_hdd_rd <= rww and rwe;
profi_ebl <= cs_hdd_wr and cs_hdd_rd;

process (CLK,BUS_A,BUS_WR_N,BUS_RD_N,cs1fx,cs3fx)
begin
	if CLK'event and CLK='1' then
		if profi_ebl = '0' then	
			IDE_A <= BUS_A(10 downto 8);
			IDE_WR_N <=BUS_WR_N;
			IDE_RD_N <=BUS_RD_N;
			IDE_CS0_N <=cs1fx;
			IDE_CS1_N <=cs3fx;
		else
			IDE_A <= (others => '1');
			IDE_WR_N <= '1';
			IDE_RD_N <= '1';
			IDE_CS0_N <= '1';
			IDE_CS1_N <= '1';
		end if;
	end if;
end process;

process (IDE_D, BUS_DI, CLK,cs_hdd_wr,cs_hdd_rd) -- Write low byte Data bus and HDD bus to temp. registers
begin
	if CLK'event and CLK='0' then
		if cs_hdd_wr='0' then
			WD_reg_in (7 downto 0) <= BUS_DI;
		elsif cs_hdd_rd='0' then
			WD_reg_out (7 downto 0) <= IDE_D(7 downto 0);
		end if;
	end if;
end process;

process (CLK, rww, WD_reg_in,cs_hdd_wr)
begin
	if CLK'event and CLK='1' then
		if rww='1' and cs_hdd_wr='0' then
			IDE_D(7 downto 0) <= WD_reg_in (7 downto 0);
		else 
			IDE_D(7 downto 0) <= "ZZZZZZZZ";
		end if;
	end if;
end process;

process (cs1fx, IDE_D)
begin
		if cs1fx'event and cs1fx='1' then
			WD_reg_out (15 downto 8) <= IDE_D(15 downto 8);
		end if;
end process;

process (wwc, BUS_DI)
begin
		if wwc'event and wwc='1' then
			WD_reg_in (15 downto 8) <= BUS_DI;
		end if;
end process;

IDE_D (15 downto 8) <= WD_reg_in (15 downto 8) when wwe='0' else "ZZZZZZZZ";

BUS_DO <= wd_reg_out (7 downto 0) when rww='0' else --and cs_hdd_rd='0' else
			wd_reg_out (15 downto 8) when rwe='0' else "11111111";
	
OE_N <= cs_hdd_rd; --'0' when (rww='0' and cs_hdd_rd='0') or rwe='0' else '1';

IDE_RESET_N <= NRESET;

end rtl;