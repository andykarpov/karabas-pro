-------------------------------------------------------------------------------
-- Board revision
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity board is
port (
	CFG 				: in std_logic_vector(7 downto 0);
	SW3				: in std_logic_vector(4 downto 1) := "1111";
	SOFT_SW1			: in std_logic;
	SOFT_SW2 		: in std_logic;
	SOFT_SW3			: in std_logic;
	SOFT_SW4 		: in std_logic;
	
	AUDIO_DAC_TYPE : out std_logic := '0';
	ROM_BANK 		: out std_logic_vector(1 downto 0) := "00";
	SCANDOUBLER_EN : out std_logic := '1'
);
end board;

architecture rtl of board is

signal enable_switches : std_logic := '1'; -- revC feature
signal dac_type : std_logic := '0'; -- 0 = TDA1543, 1 = TDA1543A

begin

-- switchable by SOFT_SW1 for older revisions and by SW3(1) for a newer ones	
SCANDOUBLER_EN <= '0' when enable_switches='1' and SW3(1) = '0' else not(SOFT_SW1); 

-- default is dac_type for older revisions and switchable by SW3(2) for a newer ones
AUDIO_DAC_TYPE <= '0' when ((enable_switches='1' and SW3(2) = '1') or (enable_switches='0' and dac_type = '0')) else '1'; 

-- SW3 and SW4 switches a 4 external rom banks for a newer revisions, otherwise - by soft switches Menu+F3, Menu+F4
ROM_BANK <= not SW3(4 downto 3) when enable_switches='1' else soft_sw4 & soft_sw3;  

process(CFG)
begin 
	case CFG is 
		when x"00" => -- revA with TDA1543 
			enable_switches <= '0';
			dac_type <= '0';
		when x"01" => -- revA with TDA1543A
			enable_switches <= '0';
			dac_type <= '1';
		when others => --revC with DIP switches
			enable_switches <= '1';
			dac_type <= '0';
	end case;
end process;

end rtl;