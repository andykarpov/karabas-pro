library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity compressor is
port(
	DI 		: in std_logic_vector(15 downto 0);
	DO 		: out std_logic_vector(15 downto 0) 
);
end compressor;

architecture RTL of compressor is

component compr
port (
	din		: in std_logic_vector(15 downto 0);
	dout		: out std_logic_vector(15 downto 0));
end component;
	
begin

U_COMPR : compr
port map (
	din => DI,
	dout => DO
);
	
end RTL;

