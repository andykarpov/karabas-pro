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

	-- profi hdd signals
	signal profi_ebl : std_logic;
	signal wwc : std_logic;
	signal wwe : std_logic;
	signal rww : std_logic;
	signal rwe : std_logic;
	signal cs3fx : std_logic;
	signal cs1fx : std_logic;

	-- nemo hdd signals
	signal nemo_ebl : std_logic;
	signal iow : std_logic;
	signal wrh : std_logic;
	signal ior : std_logic;
	signal rdh : std_logic;
	signal nemo_cs0 : std_logic;
	signal nemo_cs1 : std_logic;
	signal nemo_ior : std_logic;

	-- hdd signals for latches / registers
	signal hdd_rh_oe : std_logic;
	signal hdd_rh_c : std_logic;
	signal hdd_wh_oe : std_logic;
	signal hdd_wh_c : std_logic;
	signal hdd_rwl_t : std_logic;
	signal hdd_iorqge : std_logic;
	
	-- hdd read / write registers
	signal hdd_rh_reg : std_logic_vector(7 downto 0);
	signal hdd_wh_reg : std_logic_vector(7 downto 0);
begin 
	-- Profi
	profi_ebl <='1' when BUS_A(7)='1' and BUS_A(4 downto 0)="01011" and BUS_IORQ_N='0' and CPM='0' and DOS='1' and ROM14='1' else '0';
	wwc <='0' when BUS_WR_N='0' and BUS_A(7 downto 0)="11001011" and BUS_IORQ_N='0' and CPM='0' and DOS='1' and ROM14='1' else '1';
	wwe <='0' when BUS_WR_N='0' and BUS_A(7 downto 0)="11101011" and BUS_IORQ_N='0' and CPM='0' and DOS='1' and ROM14='1' else '1';
	rww <='0' when BUS_WR_N='1' and BUS_A(7 downto 0)="11001011" and BUS_IORQ_N='0' and CPM='0' and DOS='1' and ROM14='1' else '1';
	rwe <='0' when BUS_WR_N='1' and BUS_A(7 downto 0)="11101011" and BUS_IORQ_N='0' and CPM='0' and DOS='1' and ROM14='1' else '1';
	cs3fx <='0' when BUS_WR_N='0' and BUS_A(7 downto 0)="10101011" and BUS_IORQ_N='0' and CPM='0' and DOS='1' and ROM14='1' else '1';
	cs1fx <= rww and wwe;

	-- Nemo
	nemo_ebl <= '1' when BUS_A(2 downto 1)="00" and BUS_M1_N='1' and BUS_IORQ_N='0' and CPM='1' else '0';
	iow <='0' when BUS_A(2 downto 0)="000" and BUS_M1_N='1' and BUS_IORQ_N='0' and CPM='1' and BUS_RD_N='1' and BUS_WR_N='0' else '1';
	wrh <='0' when BUS_A(2 downto 0)="001" and BUS_M1_N='1' and BUS_IORQ_N='0' and CPM='1' and BUS_RD_N='1' and BUS_WR_N='0' else '1';
	ior <='0' when BUS_A(2 downto 0)="000" and BUS_M1_N='1' and BUS_IORQ_N='0' and CPM='1' and BUS_RD_N='0' and BUS_WR_N='1' else '1';
	rdh <='0' when BUS_A(2 downto 0)="001" and BUS_M1_N='1' and BUS_IORQ_N='0' and CPM='1' and BUS_RD_N='0' and BUS_WR_N='1' else '1';
	nemo_cs0 <= BUS_A(3) when nemo_ebl='1' else '1';
	nemo_cs1 <= BUS_A(4) when nemo_ebl='1' else '1';
	nemo_ior <= ior when nemo_ebl='1' else '1';
	
	process (CLK,BUS_A,BUS_WR_N,BUS_RD_N,cs1fx,cs3fx,rwe,wwe,wwc,rww,iow,nemo_ior,nemo_cs0,nemo_cs1,rdh,ior,wrh,nemo_ebl,profi_ebl)
	begin
		if CLK'event and CLK='0' then
		 if profi_ebl = '1' then		
			IDE_A <= BUS_A(10 downto 8);
			IDE_WR_N <= BUS_WR_N;
			IDE_RD_N <= BUS_RD_N;
			IDE_CS0_N <= cs1fx; -- Profi HDD Controller
			IDE_CS1_N <= cs3fx;
			hdd_rh_oe <=rwe;
			hdd_rh_c <=cs1fx;
			hdd_wh_oe <=wwe;
			hdd_wh_c <=wwc;
			hdd_rwl_t <=rww;
			hdd_iorqge<= '0';
		 else 
			IDE_A <= BUS_A(7 downto 5);
			IDE_WR_N <= iow;
			IDE_RD_N <= nemo_ior;
			IDE_CS0_N <= nemo_cs0; -- Nemo HDD Controller
			IDE_CS1_N <= nemo_cs1;
			hdd_rh_oe <= rdh;
			hdd_rh_c <= ior;
			hdd_wh_oe <= iow;
			hdd_wh_c <= wrh;
			hdd_rwl_t <= ior;
			hdd_iorqge <= nemo_ebl;
		 end if;
		 IDE_RESET_N <= NRESET;
		end if;
	end process;
	
	-- read high byte register
	process (hdd_rh_c)
	begin 
		if rising_edge(hdd_rh_c) then 
			if hdd_rh_oe = '0' then 
				--BUS_DO <= hdd_rh_reg;
			else 
				hdd_rh_reg <= IDE_D(15 downto 8);
			end if;
		end if;
	end process;
	
	-- write high byte register
	process (hdd_wh_c)
	begin 
		if rising_edge(hdd_wh_c) then 
			if hdd_wh_oe = '0' then 
				IDE_D(15 downto 8) <= hdd_wh_reg;
			else 
				hdd_wh_reg <= BUS_DI;
			end if;
		end if;
	end process;

	-- write a lower byte
	IDE_D(7 downto 0) <= BUS_DI when hdd_rwl_t = '1' else (others => 'Z');

	-- read a lower byte
	BUS_DO <= 
		hdd_rh_reg when hdd_rh_oe = '0' else
		IDE_D(7 downto 0) when hdd_rwl_t = '0' else 
		(others => 'Z');
	
	OE_N <= '0' when hdd_rwl_t = '0' or hdd_rh_oe = '0' else '1';

end rtl;
