library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity osd is
	port (
		CLK		: in std_logic;
		
		RGB_I 	: in std_logic_vector(8 downto 0);
		RGB_O 	: out std_logic_vector(8 downto 0);

		-- debug ports to display
		PORT_1   : in std_logic_vector(7 downto 0);
		PORT_2   : in std_logic_vector(7 downto 0);
		PORT_3   : in std_logic_vector(7 downto 0);
		PORT_4   : in std_logic_vector(7 downto 0);
		
		EN 		: in std_logic;
		
		HCNT_I	: in std_logic_vector(9 downto 0);
		VCNT_I	: in std_logic_vector(8 downto 0)
		);
end entity;

architecture rtl of osd is

	signal hcnt : std_logic_vector(9 downto 0);
	signal vcnt : std_logic_vector(8 downto 0);
	signal rgb  : std_logic_vector(8 downto 0);
	
	signal hpos1 : std_logic_vector(7 downto 0);
	signal hpos2 : std_logic_vector(7 downto 0);
	signal vpos  : std_logic_vector(1 downto 0);
	
begin

	hcnt <= HCNT_I;
	vcnt <= VCNT_I;
	
	hpos1(7) <= '1' when hcnt >= 0 and hcnt < 2 else '0';
	hpos1(6) <= '1' when hcnt >= 4 and hcnt < 6 else '0';
	hpos1(5) <= '1' when hcnt >= 8 and hcnt < 10 else '0';
	hpos1(4) <= '1' when hcnt >= 12 and hcnt < 14 else '0';
	hpos1(3) <= '1' when hcnt >= 16 and hcnt < 18 else '0';
	hpos1(2) <= '1' when hcnt >= 20 and hcnt < 22 else '0';
	hpos1(1) <= '1' when hcnt >= 24 and hcnt < 26 else '0';
	hpos1(0) <= '1' when hcnt >= 28 and hcnt < 30 else '0';

	hpos2(7) <= '1' when hcnt >= 40 and hcnt < 42 else '0';
	hpos2(6) <= '1' when hcnt >= 44 and hcnt < 46 else '0';
	hpos2(5) <= '1' when hcnt >= 48 and hcnt < 50 else '0';
	hpos2(4) <= '1' when hcnt >= 52 and hcnt < 54 else '0';
	hpos2(3) <= '1' when hcnt >= 56 and hcnt < 58 else '0';
	hpos2(2) <= '1' when hcnt >= 60 and hcnt < 62 else '0';
	hpos2(1) <= '1' when hcnt >= 64 and hcnt < 66 else '0';
	hpos2(0) <= '1' when hcnt >= 68 and hcnt < 70 else '0';
	
	vpos(1) <= '1' when vcnt >= 280 and vcnt < 284 else '0';
	vpos(0) <= '1' when vcnt >= 288 and vcnt < 292 else '0';
	
	rgb <= "000111000" when -- green = ON 
		(vpos(1) = '1' and (
			(hpos1(7) = '1' and PORT_1(7) = '1') or 
			(hpos1(6) = '1' and PORT_1(6) = '1') or 
			(hpos1(5) = '1' and PORT_1(5) = '1') or 			
			(hpos1(4) = '1' and PORT_1(4) = '1') or 			
			(hpos1(3) = '1' and PORT_1(3) = '1') or 	
			(hpos1(2) = '1' and PORT_1(2) = '1') or 	
			(hpos1(1) = '1' and PORT_1(1) = '1') or 	
			(hpos1(0) = '1' and PORT_1(0) = '1') or
			
			(hpos2(7) = '1' and PORT_2(7) = '1') or 
			(hpos2(6) = '1' and PORT_2(6) = '1') or 
			(hpos2(5) = '1' and PORT_2(5) = '1') or 			
			(hpos2(4) = '1' and PORT_2(4) = '1') or 			
			(hpos2(3) = '1' and PORT_2(3) = '1') or 	
			(hpos2(2) = '1' and PORT_2(2) = '1') or 	
			(hpos2(1) = '1' and PORT_2(1) = '1') or 	
			(hpos2(0) = '1' and PORT_2(0) = '1') 
			)) 
		or 
		(vpos(0) = '1' and (
			(hpos1(7) = '1' and PORT_3(7) = '1') or 
			(hpos1(6) = '1' and PORT_3(6) = '1') or 
			(hpos1(5) = '1' and PORT_3(5) = '1') or 			
			(hpos1(4) = '1' and PORT_3(4) = '1') or 			
			(hpos1(3) = '1' and PORT_3(3) = '1') or 	
			(hpos1(2) = '1' and PORT_3(2) = '1') or 	
			(hpos1(1) = '1' and PORT_3(1) = '1') or 	
			(hpos1(0) = '1' and PORT_3(0) = '1') or
			
			(hpos2(7) = '1' and PORT_4(7) = '1') or 
			(hpos2(6) = '1' and PORT_4(6) = '1') or 
			(hpos2(5) = '1' and PORT_4(5) = '1') or 			
			(hpos2(4) = '1' and PORT_4(4) = '1') or 			
			(hpos2(3) = '1' and PORT_4(3) = '1') or 	
			(hpos2(2) = '1' and PORT_4(2) = '1') or 	
			(hpos2(1) = '1' and PORT_4(1) = '1') or 	
			(hpos2(0) = '1' and PORT_4(0) = '1') 
		))
	else 
		"111000000" when -- red = OFF
		(vpos(1) = '1' and (
			(hpos1(7) = '1' and PORT_1(7) = '0') or 
			(hpos1(6) = '1' and PORT_1(6) = '0') or 
			(hpos1(5) = '1' and PORT_1(5) = '0') or 			
			(hpos1(4) = '1' and PORT_1(4) = '0') or 			
			(hpos1(3) = '1' and PORT_1(3) = '0') or 	
			(hpos1(2) = '1' and PORT_1(2) = '0') or 	
			(hpos1(1) = '1' and PORT_1(1) = '0') or 	
			(hpos1(0) = '1' and PORT_1(0) = '0') or
			
			(hpos2(7) = '1' and PORT_2(7) = '0') or 
			(hpos2(6) = '1' and PORT_2(6) = '0') or 
			(hpos2(5) = '1' and PORT_2(5) = '0') or 			
			(hpos2(4) = '1' and PORT_2(4) = '0') or 			
			(hpos2(3) = '1' and PORT_2(3) = '0') or 	
			(hpos2(2) = '1' and PORT_2(2) = '0') or 	
			(hpos2(1) = '1' and PORT_2(1) = '0') or 	
			(hpos2(0) = '1' and PORT_2(0) = '0') 		
		)) 
		or 
		(vpos(0) = '1' and (
			(hpos1(7) = '1' and PORT_3(7) = '0') or 
			(hpos1(6) = '1' and PORT_3(6) = '0') or 
			(hpos1(5) = '1' and PORT_3(5) = '0') or 			
			(hpos1(4) = '1' and PORT_3(4) = '0') or 			
			(hpos1(3) = '1' and PORT_3(3) = '0') or 	
			(hpos1(2) = '1' and PORT_3(2) = '0') or 	
			(hpos1(1) = '1' and PORT_3(1) = '0') or 	
			(hpos1(0) = '1' and PORT_3(0) = '0') or
			
			(hpos2(7) = '1' and PORT_4(7) = '0') or 
			(hpos2(6) = '1' and PORT_4(6) = '0') or 
			(hpos2(5) = '1' and PORT_4(5) = '0') or 			
			(hpos2(4) = '1' and PORT_4(4) = '0') or 			
			(hpos2(3) = '1' and PORT_4(3) = '0') or 	
			(hpos2(2) = '1' and PORT_4(2) = '0') or 	
			(hpos2(1) = '1' and PORT_4(1) = '0') or 	
			(hpos2(0) = '1' and PORT_4(0) = '0') 
		))
	else 
		RGB_I(8 downto 0);

	RGB_O <= rgb when EN = '1' else RGB_I;			

end architecture;