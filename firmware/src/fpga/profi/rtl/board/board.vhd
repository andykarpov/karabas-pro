-------------------------------------------------------------------------------
-- Board revision
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

entity board is
port (
	CLK 				: in std_logic;
	CFG 				: in std_logic_vector(7 downto 0);

	SOFT_SW1			: in std_logic;
	SOFT_SW2 		: in std_logic;
	SOFT_SW3			: in std_logic;
	SOFT_SW4 		: in std_logic;
	
	AUDIO_DAC_TYPE : out std_logic := '0';
	ROM_BANK 		: buffer std_logic_vector(1 downto 0) := "00";
	SCANDOUBLER_EN : out std_logic := '1';
	BOARD_RESET 	: out std_logic := '0'
);
end board;

architecture rtl of board is

signal dac_type 			: std_logic := '0'; -- 0 = TDA1543, 1 = TDA1543A
signal old_rom_bank		: std_logic_vector(1 downto 0) := "00";
signal reset_cnt			: std_logic_vector(4 downto 0) := "10000";

begin

-- switchable by SOFT_SW1
SCANDOUBLER_EN <= not(SOFT_SW1); 

-- tda1543 / tda1543a
AUDIO_DAC_TYPE <= dac_type; 

-- switchable by soft switches Menu+F3, Menu+F4
ROM_BANK <= soft_sw4 & soft_sw3;  

process(CFG)
begin 
	case CFG is 
		when x"00" => -- revA with TDA1543 
			dac_type <= '0';
		when x"01" => -- revA with TDA1543A
			dac_type <= '1';
		when others =>
			dac_type <= '0';
	end case;
end process;

process (CLK, old_rom_bank, ROM_BANK, reset_cnt)
begin
	if CLK'event and CLK = '1' then
		if (old_rom_bank /= ROM_BANK) then 
			old_rom_bank <= ROM_BANK;
			reset_cnt <= "00000";
		end if;
		if (reset_cnt /= "10000") then 
			reset_cnt <= reset_cnt + 1;
		end if;
	end if;
end process;

BOARD_RESET <= reset_cnt(3);

end rtl;