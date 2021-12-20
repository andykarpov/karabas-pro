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
	ROM_BANK 		: in std_logic_vector(1 downto 0) := "00";
	
	AUDIO_DAC_TYPE : out std_logic := '0';
	SCANDOUBLER_EN : out std_logic := '1';
	TAPE_IN_OUT_EN : out std_logic := '0';
	BOARD_RESET 	: out std_logic := '0'
);
end board;

architecture rtl of board is

signal old_rom_bank		: std_logic_vector(1 downto 0) := "00";
signal reset_cnt			: std_logic_vector(4 downto 0) := "10000";

begin

SCANDOUBLER_EN <= not(SOFT_SW1); 
AUDIO_DAC_TYPE <= CFG(0);
TAPE_IN_OUT_EN <= CFG(2);

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