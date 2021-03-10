library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity fdd_controller is 
port (
	CLK 			: in std_logic;
	CLK8 			: in std_logic;
	NRESET 		: in std_logic := '1';
	
	BUS_DI 		: in std_logic_vector(7 downto 0);
	BUS_DO 		: out std_logic_vector(7 downto 0);
	BUS_A 		: in std_logic_vector(1 downto 0);
	BUS_RD_N 	: in std_logic;
	BUS_WR_N 	: in std_logic;
	csff			: in std_logic := '1';
	FDC_NCS		: in std_logic := '1';
	FDC_STEP		: in std_logic := '0';
	FDD_CHNG		: in std_logic := '0';
	OE_N 			: buffer std_logic := '1';
	
	FDC_NWR		: out std_logic := '1';
	FDC_NRD		: out std_logic := '1';
	FDC_D			: inout std_logic_vector(7 downto 0) := "ZZZZZZZZ";	
	FDC_A			: out std_logic_vector(1 downto 0);
	FDC_SL 		: in std_logic;
	FDC_SR 		: in std_logic;
	FDC_NRESET	: out std_logic := '1';
	FDC_INTRQ	: in std_logic;
	FDC_DRQ		: in std_logic;
	FDC_WF_DE	: in std_logic;
	FDC_WD		: in std_logic;
	FDC_TR43		: in std_logic;
	FDC_NRAWR	: buffer std_logic;
	FDC_RCLK 	: buffer std_logic;
	FDC_CLK		: out std_logic;
	FDC_HLT		: out std_logic;
	FDC_DS0		: out std_logic := '0';
	FDC_DS1		: out std_logic := '0';
	FDC_SIDE		: out std_logic := '0'; 
	FDC_RDATA	: in std_logic;
	FDC_WDATA	: out std_logic
	
);
end fdd_controller;

architecture rtl of fdd_controller is 

-------------DOS-------------
signal pff				:std_logic_vector(7 downto 0);

------------FAPCH-------------
signal f					:std_logic_vector(2 downto 0);
signal f1				:std_logic;
signal f4				:std_logic;
signal f_sel			:std_logic;
signal fa				:std_logic_vector(4 downto 0);
signal rd1				:std_logic;
signal rd2				:std_logic;
signal wdata			:std_logic_vector(3 downto 0);

begin 

	----------------- FAPCH ----------------------------------------------
	process(CLK8, f)
	begin
		if (CLK8'event and CLK8='0') then -- Divider 8->4->1 mc
			f <= f+1;
		end if;
	end process;	

	f4 <= f(0); -- write pre-compensation freq
	
	process(f_sel, FDC_WF_DE, FDC_STEP, FDC_DRQ, NRESET)
	begin
		if FDC_WF_DE = '0' or NRESET = '0' then
			f_sel <= '0'; -- FDC clock (1Mc)				
		elsif FDC_STEP = '1' then
			f_sel <= '1'; -- FDC clock (2Mc)	
		elsif (FDC_DRQ'event and FDC_DRQ='1') then
			f_sel <= '0'; -- FDC clock (1Mc)				
		end if;
	end process;

	process(f_sel, f)
	begin
		if f_sel = '1' then
			FDC_CLK <= f(1); -- FDC clock (2Mc)				
		else
			FDC_CLK <= f(2); -- FDC clock (1Mc)	
		end if;
	end process;
	
	------------------------------ RAWR 125 ms ---------------------------
	process(CLK8, FDC_RDATA,rd1)
	begin
		if (CLK8'event and CLK8='1') then
			rd1 <= FDC_RDATA;
		end if;
	end process;

	process(CLK8,rd1,rd2)
	begin
		if (CLK8'event and CLK8='1') then
			rd2 <= not rd1;
		end if;
	end process;

	FDC_NRAWR <= '0' when FDC_WF_DE='0' and (rd1='1' and rd2='1') else '1'; -- RAWR is assembled, when WF_DE='1' - disallow output

	----------------- FAPCh (calculating RCLK shifts) -------------------
	process(CLK8,FDC_NRAWR,fa)
	begin
	if (CLK8'event and CLK8='1') then
		if FDC_NRAWR = '0' then
			if fa(3 downto 0) < 3 then
			fa(3 downto 0) <= fa(3 downto 0) + 4;
			elsif fa(3 downto 0) < 5 then
			fa(3 downto 0) <= fa(3 downto 0) + 3;
			elsif fa(3 downto 0) < 7 then
			fa(3 downto 0) <= fa(3 downto 0) + 2;
			elsif fa(3 downto 0) = 7 then
			fa(3 downto 0) <= fa(3 downto 0) + 1;
			elsif fa(3 downto 0) > 12 then
			fa(3 downto 0) <= fa(3 downto 0) - 3;
			elsif fa(3 downto 0) > 9 then
			fa(3 downto 0) <= fa(3 downto 0) - 2;
			elsif fa(3 downto 0) > 8 then
			fa(3 downto 0) <= fa(3 downto 0) - 1;
			end if;
			else
			fa <= fa+1;
		end if;
	end if;
	end process;

	FDC_RCLK <= not fa(4) or FDC_WF_DE; -- RCLK disabled if there is no access to the floppy (and the same for RAWR)

	---------------- Write pre-compensation --------------------
	FDC_WDATA <= wdata(3);

	process(f4, FDC_WD, FDC_TR43, FDC_SR, FDC_SL)
	begin
		if (f4'event and f4 = '1') then
			if (FDC_WD = '1') then
				wdata(0) <= FDC_TR43 and FDC_SR;
				wdata(1) <= not ((FDC_TR43 and FDC_SR) or (FDC_TR43 and FDC_SL));
				wdata(2) <= FDC_TR43 and FDC_SL;
				wdata(3) <= '0';
			else
				wdata(3) <= wdata(2);
				wdata(2) <= wdata(1);
				wdata(1) <= wdata(0);
				wdata(0) <= '0';
			end if;
		end if;
	end process;

--	FDC_DS0 <= '1' when pff(1 downto 0) = "00" else '0';
--	FDC_DS1 <= '1' when pff(1 downto 0) = "01" else '0';
	FDC_DS0 <= not (pff(0) xor FDD_CHNG) and not pff(1);
	FDC_DS1 <= (pff(0) xor FDD_CHNG) and not pff(1);

	----------------port ff to WG93------------------------------
	process(CLK,pff,BUS_DI,BUS_WR_N,csff,NRESET)
	begin 
		if NRESET='0' then
			pff(7 downto 0) <= "00000000";
		elsif (CLK'event and CLK='1') then
			if csff='0' and BUS_WR_N='0' then
				pff <= BUS_DI;
			end if;
		end if;
	end process;	

	-- dden <= pff(6); - WG93 pin 37 = GND in schematics
	FDC_SIDE <= not pff(4);
	FDC_HLT <= pff(3);
	FDC_NRESET <= pff(2);
	FDC_NRD <= BUS_RD_N;-- when FDC_NCS = '0' else '1';
	FDC_NWR <= BUS_WR_N;-- when FDC_NCS = '0' else '1';
	FDC_A <= BUS_A(1 downto 0);
	FDC_D <= BUS_DI when BUS_WR_N = '0' else (others => 'Z');
	BUS_DO <= FDC_D when FDC_NCS = '0' and BUS_RD_N = '0' else 
				 FDC_INTRQ & FDC_DRQ & "111111" when csff = '0' and BUS_RD_N = '0' else 
				 "11111111";
	OE_N <= '0' when (csff = '0' or FDC_NCS = '0') and BUS_RD_N = '0' else '1';

end rtl;