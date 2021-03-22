-------------------------------------------------------------------------------------------------------------------
-- 
-- 
-- #       #######                                                 #                                               
-- #                                                               #                                               
-- #                                                               #                                               
-- ############### ############### ############### ############### ############### ############### ############### 
-- #             #               # #                             # #             #               # #               
-- #             # ############### #               ############### #             # ############### ############### 
-- #             # #             # #               #             # #             # #             #               # 
-- #             # ############### #               ############### ############### ############### ############### 
--                                                                                                                 
--         ####### ####### ####### #######                         ############### ############### ############### 
--                                                                 #             # #               #             # 
--                                                                 ############### #               #             # 
--                                                                 #               #               #             # 
-- https://github.com/andykarpov/karabas-pro                       #               #               ############### 
--
-- Pong FPGA firmware for Karabas-Pro
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- @author Oleh Starychenko <solegstar@gmail.com>
-- Ukraine, 2021
-------------------------------------------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity karabas_pro_pong is
port (
	-- Clock (50MHz)
	CLK_50MHZ	: in std_logic;

	-- SRAM (2MB 2x8bit)
	SRAM_D		: inout std_logic_vector(7 downto 0);
	SRAM_A		: buffer std_logic_vector(20 downto 0);
	SRAM_NWR		: buffer std_logic;
	SRAM_NRD		: buffer std_logic;
	
	-- SPI FLASH (M25P16)
	DATA0			: in std_logic;  -- MISO
	NCSO			: out std_logic; -- /CS 
	DCLK			: out std_logic; -- SCK
	ASDO			: out std_logic; -- MOSI
	
	-- SD/MMC Card
	SD_NCS		: out std_logic; -- /CS
	SD_NDET 		: in std_logic; 	  -- /DET
	
	-- VGA 
	VGA_R 		: out std_logic_vector(2 downto 0);
	VGA_G 		: out std_logic_vector(2 downto 0);
	VGA_B 		: out std_logic_vector(2 downto 0);
	VGA_HS 		: buffer std_logic;
	VGA_VS 		: buffer std_logic;
		
	-- AVR SPI slave
	AVR_SCK 		: in std_logic;
	AVR_MOSI 	: in std_logic;
	AVR_MISO 	: out std_logic := 'Z';
	AVR_NCS		: in std_logic;
	
	-- Parallel bus for CPLD
	NRESET 		: out std_logic;
	CPLD_CLK 	: out std_logic;
	CPLD_CLK2 	: out std_logic;
	SDIR 			: out std_logic;
	SA				: out std_logic_vector(1 downto 0);
	SD				: inout std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	
	-- I2S Sound TDA1543
	SND_BS		: out std_logic;
	SND_WS 		: out std_logic;
	SND_DAT 		: out std_logic;
	
	-- Misc I/O
	PIN_141		: inout std_logic;
	PIN_138 		: inout std_logic;
	PIN_121		: inout std_logic;
	PIN_120		: inout std_logic;
   FDC_STEP    : inout std_logic; -- PIN_119 connected to FDC_STEP for TurboFDC
   SD_MOSI     : inout std_logic; -- PIN_115 connected to SD_S
	
	-- Dip Switches 
	SW3 			: in std_logic_vector(4 downto 1) := "1111";
		
	-- UART / ESP8266
	UART_RX 		: in std_logic;
	UART_TX 		: out std_logic;
	UART_CTS 	: out std_logic
	
);
end karabas_pro_pong;

architecture rtl of karabas_pro_pong is

-- Keyboard
signal kb_l_paddle	: std_logic_vector(2 downto 0);
signal kb_r_paddle	: std_logic_vector(2 downto 0);
signal kb_reset 		: std_logic := '0';
signal kb_scanlines  : std_logic := '0';

-- CLOCK
signal clk_28 			: std_logic := '0';
signal clk_8 			: std_logic := '0';

-- System
signal reset			: std_logic;
signal areset			: std_logic;
signal locked			: std_logic;

-- Sound 
signal speaker 		: std_logic;
signal audio_l 		: std_logic_vector(15 downto 0);
signal audio_r 		: std_logic_vector(15 downto 0);

-- Game 
signal pix_div 		: std_logic_vector(3 downto 0) := "0000";
signal dummyclk 		: std_logic := '0';
signal pixtick 		: std_logic;

signal l_human 		: std_logic := '0';
signal l_move 			: std_logic_vector(1 downto 0) := "00";
signal r_human 		: std_logic := '0';
signal r_move 			: std_logic_vector(1 downto 0) := "00";

signal prev_vsync 	: std_logic := '1';

signal hsync 			: std_logic;
signal vsync 			: std_logic;
signal csync 			: std_logic;
signal ball 			: std_logic;
signal left_bat 		: std_logic;
signal right_bat 		: std_logic;
signal field_and_score : std_logic;
signal sound 			: std_logic;
signal sel 				: std_logic_vector(3 downto 0) := "0000";
signal rgb 				: std_logic_vector(8 downto 0) := "000000000";

-- Board revision 
signal board_revision 	: std_logic_vector(7 downto 0);
signal enable_switches 	: std_logic := '1'; -- rev.C has SW3 with 4 dip switches
signal dac_type 			: std_logic := '0'; -- 0 - TDA1543, 1 - TDA1543A (only has effect when enable_switches = false)
signal audio_dac_type 	: std_logic := '0';

component altpll0 
port (
	inclk0 				: in std_logic;
	locked 				: out std_logic;
	c0 					: out std_logic;
	c1 					: out std_logic
);
end component;

component tennis
port (
	glb_clk				: in std_logic;
	pixtick				: in std_logic;
	reset					: in std_logic;
	lbat_human			: in std_logic;
	lbat_move			: in std_logic_vector(8 downto 0);
	rbat_human			: in std_logic;
	rbat_move			: in std_logic_vector(8 downto 0);
	tv_mode 				: in std_logic;
	scanlines 			: in std_logic;
	
	hsync					: out std_logic;
	vsync					: out std_logic;
	csync					: out std_logic;
	
	ball					: out std_logic;
	left_bat				: out std_logic;
	right_bat			: out std_logic;
	field_and_score 	: out std_logic;
	sound 				: out std_logic);
end component;

begin

-------------------------------------------------------------------------------
-- PLL

U1: altpll0
port map (
	inclk0			=> CLK_50MHZ,	--  50.0 MHz
	locked			=> locked,
	c0 				=> clk_28,
	c1 				=> clk_8);

-------------------------------------------------------------------------------	
-- Loader

U2: entity work.loader
port map(
	CLK 				=> clk_28,
	RESET 			=> areset,
	CFG 				=> board_revision,
	DATA0				=> DATA0,
	NCSO				=> NCSO,
	DCLK				=> DCLK,
	ASDO				=> ASDO
);	
	
-------------------------------------------------------------------------------
-- AVR keyboard

U3: entity work.cpld_kbd
port map (
	 CLK 				=> clk_28,
	 N_RESET 		=> not areset,

    AVR_MOSI		=> AVR_MOSI,
    AVR_MISO		=> AVR_MISO,
    AVR_SCK			=> AVR_SCK,
	 AVR_SS 			=> AVR_NCS,
	 
	 CFG 				=> board_revision,
	 
	 RESET 			=> kb_reset,
	 SCANLINES 		=> kb_scanlines,
	 
	 L_PADDLE 		=> kb_l_paddle,
	 R_PADDLE 		=> kb_r_paddle);

-------------------------------------------------------------------------------
-- i2s sound

U4: entity work.tda1543
port map (
	RESET				=> reset,
	CLK 				=> clk_8,
	DAC_TYPE			=> audio_dac_type,
	CS 				=> '1',
	DATA_L 			=> audio_l,
	DATA_R 			=> audio_r,
	BCK 				=> SND_BS,
	WS  				=> SND_WS,
	DATA 				=> SND_DAT);

-------------------------------------------------------------------------------
-- game logic

U5: tennis 
port map (
	glb_clk 			=> clk_28,
	pixtick 			=> pixtick,
	reset 			=> reset,
	lbat_human 		=> l_human,
	lbat_move 		=> l_move(1) & l_move(1) & l_move(1) & l_move(1) & l_move(1) & l_move(1) & l_move(0) & "00",
	rbat_human 		=> r_human,
	rbat_move 		=> r_move(1) & r_move(1) & r_move(1) & r_move(1) & r_move(1) & r_move(1) & r_move(0) & "00",
	tv_mode 			=> '0',
	scanlines 		=> kb_scanlines,
	hsync 			=> hsync, 
	vsync 			=> vsync,
	csync 			=> open,
	ball 				=> ball,
	left_bat 		=> left_bat,
	right_bat 		=> right_bat,
	field_and_score => field_and_score,
	sound 			=> sound);
	
-------------------------------------------------------------------------------
-- Global signals

areset <= not locked; -- global reset
reset <= areset or kb_reset; -- hot reset

-------------------------------------------------------------------------------
-- Disabled hw

SD_NCS	<= '1'; 
SRAM_NWR <= '1';
SRAM_NRD <= '1';
CPLD_CLK <= '0';
CPLD_CLK2 <='0';	
SA <= "00";

-------------------------------------------------------------------------------
-- Audio mixer

audio_l <= "0000000000000000" when reset = '1' else ("000" & speaker & "000000000000");
audio_r <= "0000000000000000" when reset = '1' else ("000" & speaker & "000000000000");

-------------------------------------------------------------------------------
-- Board revision / DAC type

process(board_revision)
begin 
	case board_revision is 
		when x"00" => -- revA with TDA1543 
			dac_type <= '0';
		when x"01" => -- revA with TDA1543A
			dac_type <= '1';
		when others => --revC with DIP switches
			dac_type <= '0';
	end case;
end process;

audio_dac_type <= dac_type;

-------------------------------------------------------------------------------
-- Game

process (clk_28)
begin 
	if rising_edge(clk_28) then 
		if pixtick = '1' then 
			pix_div <= "0000";
			dummyclk <= not dummyclk;
		else 
			pix_div <= pix_div + 1;
		end if;
	end if;
end process;

pixtick <= '1' when  pix_div="0100" else '0';
sel <= ball & left_bat & right_bat & field_and_score;

process (clk_28)
begin 
	if rising_edge(clk_28) then 
		if pixtick = '1' then 
			case sel is 
				when "1000" => rgb <= "111111111";
				when "0100" => rgb <= "000111111";
				when "0010" => rgb <= "111111000";
				when "0001" => rgb <= "000011000";
				when others => rgb <= "000000000";
			end case;
			VGA_HS <= hsync;
			VGA_VS <= vsync;
			speaker <= sound;
		end if;
	end if;
end process;

VGA_R <= rgb(8 downto 6);
VGA_G <= rgb(5 downto 3);
VGA_B <= rgb(2 downto 0);

process (clk_28, reset)
begin 
	if reset = '1' then 
		l_human <= '0';
		l_move <= (others => '0');
	elsif rising_edge(clk_28) then 
		if (kb_l_paddle(2)='1' or kb_l_paddle(1) = '1') then 
			l_human <= '1';
		end if;
		l_move <= (not(kb_l_paddle(2)) and kb_l_paddle(1)) & (kb_l_paddle(2) xor kb_l_paddle(1));
	end if;
end process;

process (clk_28, reset)
begin 
	if reset = '1' then 
		r_human <= '0';
		r_move <= (others => '0');
	elsif rising_edge(clk_28) then 
		if (kb_r_paddle(2)='1' or kb_r_paddle(1) = '1') then 
			r_human <= '1';
		end if;
		r_move <= (not(kb_r_paddle(2)) and kb_r_paddle(1)) & (kb_r_paddle(2) xor kb_r_paddle(1));
	end if;
end process;
	
end rtl;
