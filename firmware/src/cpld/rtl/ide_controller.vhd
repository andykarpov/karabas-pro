library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- OCH: info taken from solegstar's profi extender
-- hdd			  Profi		  Nemo
   ----------- ----------- ---------
-- hdd_a0      adress(8)   adress(5)
-- hdd_a1      adress(9)   adress(6)
-- hdd_a2      adress(10)  adress(7)
-- hdd_wr      wr          iow
-- hdd_rd      rd          nemo_ior
-- hdd_cs0     cs1fx       nemo_cs0
-- hdd_cs1     cs3fx       nemo_cs1
-- hdd_rh_oe   rwe         rdh
-- hdd_rh_c    cs1fx       ior
-- hdd_wh_oe   wwe         iow
-- hdd_wh_c    wwc         wrh
-- hdd_rwl_t   rww         ior
-- hdd_iorqge  '0'         nemo_ebl -- used in another way OCH:
   ----------- ----------- ---------


entity ide_controller is 
port (
	CLK 			: in std_logic;
	NRESET 		: in std_logic := '1';
	
	BUS_DI 		: in std_logic_vector(7 downto 0);
	BUS_DO 		: out std_logic_vector(7 downto 0);
	BUS_A			: in std_logic_vector(2 downto 0);
	BUS_RD_N 	: in std_logic;
	BUS_WR_N 	: in std_logic;
	cs3fx			: in std_logic;
	profi_ebl	: in std_logic;
	wwc			: in std_logic;
	wwe			: in std_logic;
	rwe			: in std_logic;
	rww			: in std_logic;

	OE_N 			: out std_logic;
	
	IDE_A 		: out std_logic_vector(2 downto 0);
	IDE_D 		: inout std_logic_vector(15 downto 0);
	IDE_CS0_N 	: out std_logic;
	IDE_CS1_N 	: out std_logic;
	IDE_RD_N 	: out std_logic;
	IDE_WR_N 	: out std_logic;
	IDE_RESET_N : out std_logic;
	
	fromFPGA_NEMO_EBL : in std_logic;
	
	BUS_nemo_cs1: in std_logic;
	BUS_nemo_cs0: in std_logic
);
end ide_controller;

architecture rtl of ide_controller is 

--------------------HDD-NEMO/PROFI-----------------------

signal cs_hdd_wr	: std_logic;
signal cs_hdd_rd	: std_logic;
signal cs1fx		: std_logic;
signal wd_reg_in	: std_logic_vector(15 downto 0);
signal wd_reg_out	: std_logic_vector(15 downto 0);

signal cnt      : std_logic_vector(7 downto 0);

begin 

-----------------HDD------------------
	-- Profi
cs1fx <= rww and wwe when fromFPGA_NEMO_EBL = '0' else rww; -- Write High byte from HDD bus to "Read register" - profi ; in nemo mode rww=IOR  -- OK
cs_hdd_wr <= cs3fx and wwe and wwc;
cs_hdd_rd <= rww and rwe; -- IOR and RDH (0 active) OK

process (CLK,BUS_A,BUS_WR_N,BUS_RD_N,cs1fx,cs3fx,NRESET,profi_ebl)
begin
  if NRESET = '0' then
    IDE_WR_N <='1';
    IDE_RD_N <='1';
    IDE_CS0_N <='1';
    IDE_CS1_N <='1';
    IDE_A <= "000";
    cnt <= "00000000";
  elsif CLK'event and CLK='0' then
    if profi_ebl = '0' and cnt (7) = '0' then -- in nemo mode profi_ebl = nemo_ebl
      IDE_A <= BUS_A(2 downto 0);
      if (cnt > 2 and cnt < 72) then
			if fromFPGA_NEMO_EBL = '0' then --profi
			  IDE_CS0_N <=cs1fx;
			  IDE_CS1_N <=cs3fx;
			else								 --nemo
			  IDE_CS0_N <=BUS_nemo_cs0; 
			  IDE_CS1_N <=BUS_nemo_cs1;
			end if; 
      else
        IDE_CS0_N <='1';
        IDE_CS1_N <='1';
      end if;
      if (cnt > 8 and cnt < 31) then
			if fromFPGA_NEMO_EBL = '0' then  --profi
				IDE_WR_N <=BUS_WR_N;
				IDE_RD_N <=BUS_RD_N;
			else								 --nemo
				IDE_WR_N <=wwe; -- IOW 
				IDE_RD_N <=rww; -- IOR
			end if;
      else
          IDE_WR_N <='1';
          IDE_RD_N <='1';      
      end if;
      cnt <= cnt + 1;
    else
      IDE_WR_N <='1';
      IDE_RD_N <='1';
      IDE_CS0_N <='1';
      IDE_CS1_N <='1';
      IDE_A <= "000";
      cnt <= "00000000";
    end if;
  end if;
end process;

--process (IDE_D, BUS_DI, CLK,cs_hdd_wr,cs_hdd_rd) -- Write low byte Data bus and HDD bus to temp. registers
--begin
--	if CLK'event and CLK='0' then
--		if cs_hdd_wr='0' then
--			wd_reg_in (7 downto 0) <= BUS_DI;
----		elsif cs_hdd_rd='0' then
----			wd_reg_out (7 downto 0) <= IDE_D(7 downto 0);
--		end if;
--	end if;
--end process;

process (CLK, rww, wd_reg_in,cs_hdd_wr,NRESET,profi_ebl)
begin
	if NRESET = '0' then
		IDE_D(7 downto 0) <= "11111111";	
	elsif CLK'event and CLK='1' then
		if (rww='1' and cs_hdd_wr='0' and fromFPGA_NEMO_EBL='0') or (rww='1' and fromFPGA_NEMO_EBL= '1') then
			IDE_D(7 downto 0) <= BUS_DI; -- rww=IOR fromFPGA_NEMO_EBL=1 in nemo mode low byte writen to HDD when --OK
		else 
			IDE_D(7 downto 0) <= "ZZZZZZZZ";
		end if;
	end if;
end process;

process (cs1fx, IDE_D)
begin
		if cs1fx'event and cs1fx='1' then -- cs1fx <= rww and wwe when fromFPGA_NEMO_EBL = '0' else IOR -- OK
			wd_reg_out (15 downto 8) <= IDE_D(15 downto 8);
		end if;
end process;

process (wwc, BUS_DI)
begin
		if wwc'event and wwc='1' then   -- wwc=WRH write high byte to latch from z80 -- OK
			wd_reg_in (15 downto 8) <= BUS_DI;
		end if;
end process;

IDE_D (15 downto 8) <= wd_reg_in (15 downto 8) when wwe='0' else "ZZZZZZZZ"; -- wwe=IOW write to high byte HDD from latch -- OK

BUS_DO <= IDE_D(7 downto 0) when rww='0' else -- rww=IOR - read low byte from HDD -- OK
			wd_reg_out (15 downto 8) when rwe='0' else "11111111"; -- rwe=RDH - read high byte from HDD -- OK
	
OE_N <= cs_hdd_rd; --OCH OK

IDE_RESET_N <= NRESET;

end rtl;
