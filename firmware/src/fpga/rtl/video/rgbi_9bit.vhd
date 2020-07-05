-------------------------------------------------------------------[16.07.2019]
-- RGBI to 3:3:3 converter
-------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity rgbi_9bit is
	port (
		I_RED		: in std_logic;
		I_GREEN	: in std_logic;
		I_BLUE	: in std_logic;
		I_BRIGHT : in std_logic;
		O_RGB		: out std_logic_vector(8 downto 0)	-- RRRGGGBBB
	);
end entity;

architecture rtl of rgbi_9bit is

signal rgbi: std_logic_vector(3 downto 0);

begin

	rgbi <= I_BRIGHT & I_RED & I_GREEN & I_BLUE;

	process(rgbi)
	begin
		case rgbi(3 downto 0) is
			when "0000" | "1000" => O_RGB <= "000000000";
			when "0001" => O_RGB <= "000000101";
			when "0010" => O_RGB <= "000101000";
			when "0011" => O_RGB <= "000101101";
			when "0100" => O_RGB <= "101000000";
			when "0101" => O_RGB <= "101000101";
			when "0110" => O_RGB <= "101101000";
			when "0111" => O_RGB <= "101101101";
			when "1001" => O_RGB <= "000000111";
			when "1010" => O_RGB <= "000111000";
			when "1011" => O_RGB <= "000111111";
			when "1100" => O_RGB <= "111000000";
			when "1101" => O_RGB <= "111000111";
			when "1110" => O_RGB <= "111111000";
			when "1111" => O_RGB <= "111111111";
			when others => O_RGB <= "000000000";
		end case;
	end process;

end architecture;