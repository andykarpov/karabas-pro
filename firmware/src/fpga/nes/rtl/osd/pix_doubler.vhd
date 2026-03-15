library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity pix_doubler is
	port (
		CLK	: in std_logic;
		LOAD	: in std_logic;
		SHIFT	: in std_logic;
		D		: in std_logic_vector(7 downto 0);
		QUAD 	: in std_logic_vector(1 downto 0) := "00";
		DOUT	: out std_logic
	);
end entity;

architecture rtl of pix_doubler is
	signal shift_8  : std_logic_vector(7 downto 0);
	signal shift_16 : std_logic_vector(15 downto 0);
	signal shift_32 : std_logic_vector(31 downto 0);
	signal cnt : std_logic_vector(3 downto 0);
begin

	process(CLK)
	begin
		if rising_edge(CLK) then
			if LOAD = '1' then 
				
				shift_8 <= D(7 downto 0);
				
				shift_16 <= D(7) & D(7) & 
								D(6) & D(6) & 
								D(5) & D(5) & 
								D(4) & D(4) & 
								D(3) & D(3) & 
								D(2) & D(2) & 
								D(1) & D(1) & 
								D(0) & D(0);
								
				shift_32 <= D(7) & D(7) & D(7) & D(7) & 
								D(6) & D(6) & D(6) & D(6) & 
								D(5) & D(5) & D(5) & D(5) & 
								D(4) & D(4) & D(4) & D(4) & 
								D(3) & D(3) & D(3) & D(3) & 
								D(2) & D(2) & D(2) & D(2) & 
								D(1) & D(1) & D(1) & D(1) & 
								D(0) & D(0) & D(0) & D(0);
								
				cnt <= "0000";				
			elsif SHIFT = '1' then
				shift_8 <= shift_8(6 downto 0) & '0';
				shift_16 <= shift_16(14 downto 0) & '0';
				shift_32 <= shift_32(30 downto 0) & '0';
				cnt <= cnt + 1;
			end if;
		end if;
	end process;
	
	DOUT <= shift_8(7) when QUAD = "00" else -- spectrum normal
			  shift_16(15) when (QUAD = "01" or QUAD = "10") else -- spectrum double size or profi normal
			  shift_32(31) when QUAD = "11" else -- profi double size
			  shift_8(7); -- fallback

end architecture;
