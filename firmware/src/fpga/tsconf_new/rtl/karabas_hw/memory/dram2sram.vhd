library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dram2sram is
	port(
		  CLK			  : in std_logic;
		  CLK2X		  : in std_logic;
        C0          : in std_logic;
        C1          : in std_logic;
        C2          : in std_logic;
        C3          : in std_logic;
		  
		  -- dram ctl
        REQ         : in std_logic;
        RNW         : in std_logic;
        ADDR        : in std_logic_vector(21 downto 0);
        DI          : in std_logic_vector(15 downto 0);
        BSEL        : in std_logic_vector(1 downto 0); -- bsel[0] - wrdata[7:0], bsel[1] - wrdata[15:8]
        DO          : buffer std_logic_vector(15 downto 0);        
		  
		  -- ram to ic
        RAM_A       : buffer std_logic_vector(22 downto 0);
        RAM_DO      : buffer std_logic_vector(7 downto 0);
        RAM_DI      : in std_logic_vector(7 downto 0);
        RAM_NWR     : buffer std_logic;
        RAM_NRD     : buffer std_logic		  
);
end dram2sram;

architecture rtl of dram2sram is

signal sram_wrdata  : std_logic_vector(7 downto 0);
signal sram_rddata  : std_logic_vector(15 downto 0);
signal int_nwr : std_logic := '1';

begin

	RAM_NRD <= '0'; -- always read!

	-- address
	process (CLK, C3, C0)
	begin 
		if rising_edge(CLK) then 
			if (C3 = '1') then 
				RAM_A <= ADDR & '0';
			elsif (C0 = '1') then 
				RAM_A <= std_logic_vector(unsigned(RAM_A) + 1);
			end if;
		end if;
	end process;

	
	-- read data
	process (CLK, C0, C1)
	begin 
		if rising_edge(CLK) then
			if (C0 = '1') then
				sram_rddata(7 downto 0) <= RAM_DI; 
			elsif (C1 = '1') then
				sram_rddata(15 downto 8) <= RAM_DI;
			end if;
		end if;
	end process;
	
	-- write data 
	process (CLK, C3, C0)
	begin 
		if rising_edge(CLK) then 
			if (C3 = '1') then
				sram_wrdata <= DI(7 downto 0);
			elsif (C0 = '1') then 
				sram_wrdata <= DI(15 downto 8);
			end if;
		end if;
	end process;
	
	
	-- we control
	process (CLK, C3, C0, C1)
	begin 
		if rising_edge(CLK) then 
				if (C3 = '1') then
					if (REQ = '1') then
						if (RNW = '0' and BSEL(0) = '1') then 
							RAM_NWR <= '0';
						else 
							RAM_NWR <= '1';
						end if;
						if (RNW = '0' and BSEL(1) = '1') then 
							int_nwr <= '0';
						else 
							int_nwr <= '1';
						end if;
					else 
						RAM_NWR <= '1';
						int_nwr <= '1';
					end if;
				elsif (C0 = '1') then 
					RAM_NWR <= int_nwr;
				elsif (C1 = '1') then 
					RAM_NWR <= '1';
				end if;
		end if;
	end process;	
	
	RAM_DO  <= sram_wrdata when RAM_NWR = '0' else RAM_DO;
	DO <= sram_rddata;

end rtl;
