-------------------------------------------------------------------------------
-- MCU Soft switches receiver
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity soft_switches is
	port(
	CLK : in std_logic;	
	SOFTSW_COMMAND : in std_logic_vector(15 downto 0);
	
	RESET : out std_logic
	);
end soft_switches;

architecture rtl of soft_switches is
	signal prev_command : std_logic_vector(15 downto 0) := x"FFFF";
begin 

process (CLK, prev_command, SOFTSW_COMMAND)
begin
	if rising_edge(CLK) then 
		if (prev_command /= SOFTSW_COMMAND) then
			prev_command <= SOFTSW_COMMAND;
			case SOFTSW_COMMAND(15 downto 8) is
				when x"00" => RESET <= SOFTSW_COMMAND(0);	
				when others => null;
			end case;
		end if;
	end if;
end process;

end rtl;