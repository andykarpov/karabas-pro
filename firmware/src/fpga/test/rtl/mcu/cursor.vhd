-------------------------------------------------------------------------------
-- MCU HID mouse / absolute cursor transformer
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity cursor is
	port
	(
	 CLK			 : in std_logic;
	 RESET 		 : in std_logic;
	 
	 MS_X :    in std_logic_vector(7 downto 0);
	 MS_Y :    in std_logic_vector(7 downto 0);
	 MS_Z :    in std_logic_vector(3 downto 0);
	 MS_B :    in std_logic_vector(2 downto 0);
	 MS_UPD  : in std_logic := '0';

	 OUT_X : out std_logic_vector(7 downto 0);
	 OUT_Y : out std_logic_vector(7 downto 0);
	 OUT_Z : out std_logic_vector(3 downto 0);
	 OUT_B : out std_logic_vector(2 downto 0)
	);
end cursor;

architecture rtl of cursor is

	 -- mouse
	 signal cursorX 			: signed(7 downto 0) := X"7F";
	 signal cursorY 			: signed(7 downto 0) := X"7F";
	 signal deltaX				: signed(8 downto 0);
	 signal deltaY				: signed(8 downto 0);
	 signal deltaZ				: signed(3 downto 0);
	 signal trigger 			: std_logic := '0';
	 signal ms_flag 			: std_logic := '0';

begin 

	process (CLK) 
	begin
			if (rising_edge(CLK)) then
				trigger <= '0';
				-- update mouse only on ms flag changed
				if (ms_flag /= MS_UPD) then 
					deltaX(7 downto 0) <= signed(MS_X(7 downto 0));
					deltaY(7 downto 0) <= -signed(MS_Y(7 downto 0));
					deltaZ(3 downto 0) <= signed(MS_Z(3 downto 0));					
					ms_flag <= MS_UPD;
					trigger <= '1';
				end if;
			end if;
	end process;

	process (CLK)
		variable newX : signed(7 downto 0);
		variable newY : signed(7 downto 0);
	begin
		if rising_edge (CLK) then

			newX := cursorX + deltaX(7 downto 0);
			newY := cursorY + deltaY(7 downto 0);

			if trigger = '1' then
				cursorX <= newX;
				cursorY <= newY;
			end if;
		end if;
	end process;
	
	OUT_X <= std_logic_vector(cursorX);
	OUT_Y <= std_logic_vector(cursorY);
	OUT_Z	<= std_logic_vector(deltaZ);
	OUT_B <= MS_B;

end rtl;