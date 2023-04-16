library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dram2sram is
	port(
		CLK			: in std_logic;
        C0          : in std_logic;
        C1          : in std_logic;
        C2          : in std_logic;
        C3          : in std_logic;
        REQ         : in std_logic;
        RNW         : in std_logic;
        ADDR        : in std_logic_vector(20 downto 0);
        DI          : in std_logic_vector(15 downto 0);
        BSEL        : in std_logic_vector(1 downto 0); -- bsel[0] - wrdata[7:0], bsel[1] - wrdata[15:8]
        DO          : out std_logic_vector(15 downto 0);        
        
        RAM_A       : out std_logic_vector(21 downto 0);
        RAM_DI      : out std_logic_vector(7 downto 0);
        RAM_DO      : in std_logic_vector(7 downto 0);
        RAM_NWR     : buffer std_logic;
        RAM_NRD     : out std_logic
);
end dram2sram;

architecture rtl of dram2sram is

signal int_sram_nwr : std_logic;
signal sram_wrdata  : std_logic_vector(7 downto 0);

begin

	process (CLK, REQ, RNW, C3, C0)
	begin 
        if rising_edge(CLK) then
				-- address
            if (C3 = '1') then 
                RAM_A <= '0' & ADDR;
            elsif (C0 = '1') then 
                RAM_A <= '1' & ADDR;
            end if;

            -- read data
            if (C0 = '1') then 
                DO(7 downto 0) <= RAM_DO;
            elsif (C1 = '1') then
                DO(15 downto 8) <= RAM_DO; 
            end if;

            -- write data
            if (C3 = '1') then
                sram_wrdata <= DI(7 downto 0);
            elsif (C0 = '1') then
                sram_wrdata <= DI(15 downto 8);
            end if;

            -- write enable
            if (C3 = '1') then
                if (RNW = '1' or BSEL(0) = '0') then 
                    RAM_NWR <= REQ;
                else 
                    RAM_NWR <= '1';
                end if;
                if (RNW = '1' or BSEL(1) = '0') then 
                    int_sram_nwr <= REQ;
                else 
                    int_sram_nwr <= '1';
                end if;
            elsif (C0 = '1') then 
                RAM_NWR <= int_sram_nwr;
            elsif (C1 = '1') then 
                RAM_NWR <= '1';
            end if;
        end if;		
	end process;
	
	RAM_DI  <= sram_wrdata;
    RAM_NRD <= not(RAM_NWR);

end rtl;
