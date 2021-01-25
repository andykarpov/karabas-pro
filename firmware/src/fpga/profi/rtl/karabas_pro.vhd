-------------------------------------------------------------------------------
--
-- Karabas-pro v1.0
--
-- Copyright (c) 2020 Andy Karpov
--
-------------------------------------------------------------------------------

--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity karabas_pro is
	generic (
		enable_ay_uart 	   : boolean := false;
		enable_zxuno_uart    : boolean := true;
		enable_esp866_bridge : boolean := false;
		enable_saa1099 	   : boolean := false;
		enable_diag_rom	   : boolean := false -- Retroleum diagrom (blockram based)
	);
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
	SD_NCS		: buffer std_logic; -- /CS
	SD_NDET 		: in std_logic; 	  -- /DET
	
	-- VGA 
	VGA_R 		: out std_logic_vector(2 downto 0);
	VGA_G 		: out std_logic_vector(2 downto 0);
	VGA_B 		: out std_logic_vector(2 downto 0);
	VGA_HS 		: out std_logic;
	VGA_VS 		: out std_logic;
		
	-- AVR SPI slave
	AVR_SCK 		: in std_logic;
	AVR_MOSI 	: in std_logic;
	AVR_MISO 	: out std_logic := 'Z';
	AVR_NCS		: in std_logic;
	
	-- Parallel bus for CPLD
	NRESET 		: out std_logic;
	CPLD_CLK 	: out std_logic;
	CPLD_CLK2 	: out std_logic;
	SDIR 			: in std_logic;
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
	PIN_119		: inout std_logic;
	PIN_115		: inout std_logic;
	
	-- Dip Switches 
	SW3 			: in std_logic_vector(4 downto 1) := "1111";
		
	-- UART / ESP8266
	UART_RX 		: in std_logic;
	UART_TX 		: out std_logic;
	UART_CTS 	: out std_logic
	
);
end karabas_pro;

architecture rtl of karabas_pro is

-- Board revision 
signal board_revision : std_logic_vector(7 downto 0);

-- CPU
signal cpu_reset_n	: std_logic;
signal cpu_clk			: std_logic;
signal cpu_a_bus		: std_logic_vector(15 downto 0);
signal cpu_do_bus		: std_logic_vector(7 downto 0);
signal cpu_di_bus		: std_logic_vector(7 downto 0);
signal cpu_mreq_n		: std_logic;
signal cpu_iorq_n		: std_logic;
signal cpu_wr_n		: std_logic;
signal cpu_rd_n		: std_logic;
signal cpu_int_n		: std_logic;
signal cpu_inta_n		: std_logic;
signal cpu_m1_n		: std_logic;
signal cpu_rfsh_n		: std_logic;
signal cpu_ena			: std_logic;
signal cpu_mult		: std_logic_vector(1 downto 0);
signal cpu_mem_wr		: std_logic;
signal cpu_mem_rd		: std_logic;
signal cpu_nmi_n		: std_logic;
signal cpu_wait_n 	: std_logic := '1';

-- Port
signal port_xxfe_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_7ffd_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_dffd_reg : std_logic_vector(7 downto 0) := "00000000";
signal port_xx7e_reg : std_logic_vector(7 downto 0) := "00000000";
signal port_xx7e_a   : std_logic_vector(15 downto 8) := "00000000";
signal port_xx7e_aprev   : std_logic_vector(15 downto 8) := "00000000";

-- Keyboard
signal kb_do_bus		: std_logic_vector(5 downto 0);
signal kb_reset 		: std_logic := '0';
signal kb_magic 		: std_logic := '0';
signal kb_special 	: std_logic := '0';
signal kb_turbo 		: std_logic := '0';
signal kb_wait 		: std_logic := '0';
signal kb_mode 		: std_logic := '1';
signal kb_loaded 		: std_logic := '0';

-- Joy
signal joy_bus 		: std_logic_vector(4 downto 0) := "11111";

-- Mouse
signal ms_x				: std_logic_vector(7 downto 0);
signal ms_y				: std_logic_vector(7 downto 0);
signal ms_z				: std_logic_vector(3 downto 0);
signal ms_b				: std_logic_vector(2 downto 0);
signal ms_present 	: std_logic := '0';
signal ms_event		: std_logic := '0';
signal ms_delta_x		: signed(7 downto 0);
signal ms_delta_y		: signed(7 downto 0);

-- Video
signal vid_a_bus		: std_logic_vector(13 downto 0);
signal vid_di_bus		: std_logic_vector(7 downto 0);
signal vid_hsync		: std_logic;
signal vid_vsync		: std_logic;
signal vid_int			: std_logic;
signal vid_pff_cs		: std_logic;
signal vid_attr		: std_logic_vector(7 downto 0);
signal vid_rgb			: std_logic_vector(8 downto 0);
signal vid_rgb_osd 	: std_logic_vector(8 downto 0);
signal vid_invert 	: std_logic;
signal vid_hcnt 		: std_logic_vector(9 downto 0);
signal vid_vcnt 		: std_logic_vector(8 downto 0);
signal vid_scandoubler_enable : std_logic := '1';
signal blink 			: std_logic;

-- Z-Controller
signal zc_do_bus		: std_logic_vector(7 downto 0);
signal zc_spi_start	: std_logic;
signal zc_wr_en		: std_logic;
signal port77_wr		: std_logic;

signal zc_cs_n			: std_logic;
signal zc_sclk			: std_logic;
signal zc_mosi			: std_logic;
signal zc_miso			: std_logic;

-- MC146818A
signal mc146818_wr		: std_logic;
signal mc146818_rd		: std_logic;
signal mc146818_a_bus	: std_logic_vector(5 downto 0);
signal mc146818_do_bus	: std_logic_vector(7 downto 0);
signal mc146818_busy		: std_logic;
signal port_eff7_reg		: std_logic_vector(7 downto 0);

-- Port selectors
signal fd_port 		: std_logic;
signal fd_sel 			: std_logic;
signal cs_xxfe 		: std_logic := '0'; 
signal cs_eff7 		: std_logic := '0';
signal cs_7ffd 		: std_logic := '0';
signal cs_dffd 		: std_logic := '0';
signal cs_fffd 		: std_logic := '0';
signal cs_xxfd 		: std_logic := '0';
signal cs_xx7e 		: std_logic := '0';
signal cs_xx87 		: std_logic := '0';
signal cs_xxA7 		: std_logic := '0';
signal cs_xxC7 		: std_logic := '0';
signal cs_xxE7 		: std_logic := '0';
signal cs_xx67 		: std_logic := '0';
signal cs_rtc_ds 		: std_logic := '0';
signal cs_rtc_as 		: std_logic := '0'; 			

-- TurboSound
signal ssg_sel			: std_logic;
signal ssg_cn0_bus	: std_logic_vector(7 downto 0);
signal ssg_cn0_a		: std_logic_vector(7 downto 0);
signal ssg_cn0_b		: std_logic_vector(7 downto 0);
signal ssg_cn0_c		: std_logic_vector(7 downto 0);
signal ssg_cn1_bus	: std_logic_vector(7 downto 0);
signal ssg_cn1_a		: std_logic_vector(7 downto 0);
signal ssg_cn1_b		: std_logic_vector(7 downto 0);
signal ssg_cn1_c		: std_logic_vector(7 downto 0);

-- AY UART signals
signal ay_bdir 		: std_logic;
signal ay_bc1			: std_logic;
signal ay_port 		: std_logic := '0';

-- Covox
signal covox_l			: std_logic_vector(7 downto 0);
signal covox_r			: std_logic_vector(7 downto 0);
signal covox_fb		: std_logic_vector(7 downto 0);

-- Output audio
signal mix_l			: std_logic_vector(15 downto 0);
signal mix_r			: std_logic_vector(15 downto 0);
signal audio_l			: std_logic_vector(15 downto 0);
signal audio_r			: std_logic_vector(15 downto 0);
signal audio_dac_type: std_logic := '0'; -- 0 = TDA1543, 1 = TDA1543A

-- SAA1099
signal saa_wr_n		: std_logic;
signal saa_out_l		: std_logic_vector(7 downto 0);
signal saa_out_r		: std_logic_vector(7 downto 0);

-- CLOCK
signal clk_28 			: std_logic := '0';
signal clk_24 			: std_logic := '0';
signal clk_8			: std_logic := '0';
signal clk_bus			: std_logic := '0';
signal clk_bus_port 	: std_logic := '0';
signal clk_div2		: std_logic := '0';
signal clk_div4		: std_logic := '0';
signal clk_div8		: std_logic := '0';
signal clk_div16		: std_logic := '0';
signal clk_i2s 		: std_logic := '0';

signal ena_div2	: std_logic := '0';
signal ena_div4	: std_logic := '0';
signal ena_div8	: std_logic := '0';
signal ena_div16	: std_logic := '0';
signal ena_div32	: std_logic := '0';
signal ena_cnt		: std_logic_vector(5 downto 0) := "000000";

-- System
signal reset			: std_logic;
signal areset			: std_logic;
signal locked			: std_logic;
signal locked_tri 	: std_logic := '0';
signal loader_act		: std_logic := '1';
signal loader_reset 	: std_logic := '0';
signal loader_done 	: std_logic := '0';
signal dos_act			: std_logic := '1';
signal cpuclk			: std_logic;
signal selector		: std_logic_vector(7 downto 0);
signal mux				: std_logic_vector(3 downto 0);
signal speaker 		: std_logic := '0';
signal ram_ext 		: std_logic_vector(2 downto 0) := "000";
signal ram_do_bus 	: std_logic_vector(7 downto 0);
signal ram_oe_n 		: std_logic := '1';
signal vbus_mode 		: std_logic := '0';
signal vid_rd 			: std_logic := '0';
signal ext_rom_bank  : std_logic_vector(1 downto 0) := "00";

-- Loader
signal loader_ram_di	: std_logic_vector(7 downto 0);
signal loader_ram_do	: std_logic_vector(7 downto 0);
signal loader_ram_a	: std_logic_vector(20 downto 0);
signal loader_ram_wr : std_logic;
signal loader_flash_di : std_logic_vector(7 downto 0);
signal loader_flash_do : std_logic_vector(7 downto 0);
signal loader_flash_a : std_logic_vector(23 downto 0);
signal loader_flash_rd_n : std_logic;
signal loader_flash_wr_n : std_logic;
signal loader_flash_busy : std_logic;
signal loader_flash_rdy : std_logic;

-- Parallel flash interface
signal flash_a_bus: std_logic_vector(23 downto 0);
signal flash_di_bus : std_logic_vector(7 downto 0);
signal flash_do_bus: std_logic_vector(7 downto 0);
signal flash_wr_n : std_logic := '1';
signal flash_rd_n : std_logic := '1';
signal flash_er_n : std_logic := '1';
signal flash_busy : std_logic := '1';
signal flash_rdy : std_logic := '0';
signal fw_update_mode : std_logic := '0';

signal host_flash_a_bus : std_logic_vector(23 downto 0);
signal host_flash_di_bus : std_logic_vector(7 downto 0);
signal host_flash_rd_n : std_logic := '1';
signal host_flash_wr_n : std_logic := '1';
signal host_flash_er_n : std_logic := '1';

signal port_xx87_reg : std_logic_vector(7 downto 0);
signal port_xxA7_reg : std_logic_vector(7 downto 0);
signal port_xxC7_reg : std_logic_vector(7 downto 0);
signal port_xxE7_reg : std_logic_vector(7 downto 0);
signal port_xx67_reg : std_logic_vector(7 downto 0);

-- SD / SPI flash selector
signal is_flash_not_sd : std_logic := '0';

-- SPI flash / SD
signal flash_ncs 		: std_logic;
signal flash_clk 		: std_logic;
signal flash_do 		: std_logic;
signal sd_clk 			: std_logic;
signal sd_si 			: std_logic;

-- AY UART 
signal ay_uart_do_bus 	: std_logic_vector(7 downto 0) := "00000000";
signal ay_uart_oe_n 		: std_logic := '1';

-- ZXUNO regs / UART ports
signal zxuno_regrd : std_logic;
signal zxuno_regwr : std_logic;
signal zxuno_addr : std_logic_vector(7 downto 0);
signal zxuno_regaddr_changed : std_logic;
signal zxuno_addr_oe_n : std_logic;
signal zxuno_addr_to_cpu : std_logic_vector(7 downto 0);
signal zxuno_uart_do_bus 	: std_logic_vector(7 downto 0);
signal zxuno_uart_oe_n 		: std_logic;

-- cpld port
signal cpld_do 		: std_logic_vector(7 downto 0);

-- serial mouse 
signal serial_ms_do_bus : std_logic_vector(7 downto 0);
signal serial_ms_oe_n : std_logic := '1';
signal serial_ms_int : std_logic := '1';

-- test rom 
signal rom_do_bus 	: std_logic_vector(7 downto 0);

-- profi special signals
signal cpm 				: std_logic := '0';
signal worom 			: std_logic := '0';
signal ds80 			: std_logic := '0';
signal scr 				: std_logic := '0';
signal sco 				: std_logic := '0';
signal rom14 			: std_logic := '0';
signal gx0 				: std_logic := '0';

-- avr leds
signal led1				: std_logic := '0';
signal led2				: std_logic := '0';
signal led1_overwrite: std_logic := '0';
signal led2_overwrite: std_logic := '0';

-- avr soft switches (Menu+F1 .. Menu+F8)
signal soft_sw 		: std_logic_vector(1 to 8) := (others => '0');

signal board_reset 	: std_logic := '0'; -- board reset on rombank switch

-- debug 
signal fdd_oe_n 		: std_logic := '1';
signal hdd_oe_n 		: std_logic := '1';
signal port_nreset 	: std_logic := '1';

component saa1099
port (
	clk_sys	: in std_logic;
	ce			: in std_logic;		--8 MHz
	rst_n		: in std_logic;
	cs_n		: in std_logic;
	a0			: in std_logic;		--0=data, 1=address
	wr_n		: in std_logic;
	din		: in std_logic_vector(7 downto 0);
	out_l		: out std_logic_vector(7 downto 0);
	out_r		: out std_logic_vector(7 downto 0));
end component;

component zxunoregs
port (
	clk: in std_logic;
	rst_n : in std_logic;
	a : in std_logic_vector(15 downto 0);
	iorq_n : in std_logic;
	rd_n : in std_logic;
	wr_n : in std_logic;
	din : in std_logic_vector(7 downto 0);
	dout : out std_logic_vector(7 downto 0);
	oe_n : out std_logic;
	addr : out std_logic_vector(7 downto 0);
	read_from_reg: out std_logic;
	write_to_reg: out std_logic;
	regaddr_changed: out std_logic);
end component;

component zxunouart
port (
	clk : in std_logic;
	ds80 : in std_logic;
	zxuno_addr : in std_logic_vector(7 downto 0);
	zxuno_regrd : in std_logic;
	zxuno_regwr : in std_logic;
	din : in std_logic_vector(7 downto 0);
	dout : out std_logic_vector(7 downto 0);
	oe_n : out std_logic;
	uart_tx : out std_logic;
	uart_rx : in std_logic;
	uart_rts : out std_logic);
end component;

component uart 
port ( 
	clk: in std_logic;
	txdata: in std_logic_vector(7 downto 0);
	txbegin: in std_logic;
	txbusy : out std_logic;
	rxdata : out std_logic_vector(7 downto 0);
	rxrecv : out std_logic;
	data_read : in std_logic;
	rx : in std_logic;
	tx : out std_logic;
	rts: out std_logic);
end component;

begin

-- PLL1
U1: entity work.altpll0
port map (
	inclk0			=> CLK_50MHZ,
	locked			=> locked,
	c0 				=> clk_28,
	c1 				=> clk_24,
	c2 				=> clk_bus_port
	);
	
-- PLL2
U2: entity work.altpll1
port map (
	inclk0			=> clk_24,
	locked 			=> open,
	c0 				=> clk_8);
		
-- main clock selector
U3: entity work.clk_ctrl
port map(
	clkselect 	=> ds80,
	inclk0x 		=> clk_28,
	inclk1x 		=> clk_24,
	outclk 		=> clk_bus
);

-- Zilog Z80A CPU
U4: entity work.T80aw
port map (
	RESET_n			=> cpu_reset_n,
	CLK_n				=> clk_bus,
	ENA				=> cpuclk,
	WAIT_n			=> cpu_wait_n,
	INT_n				=> cpu_int_n and serial_ms_int,
	NMI_n				=> cpu_nmi_n,
	BUSRQ_n			=> '1',
	M1_n				=> cpu_m1_n,
	MREQ_n			=> cpu_mreq_n,
	IORQ_n			=> cpu_iorq_n,
	RD_n				=> cpu_rd_n,
	WR_n				=> cpu_wr_n,
	RFSH_n			=> cpu_rfsh_n,
	HALT_n			=> open,--cpu_halt_n,
	BUSAK_n			=> open,--cpu_basak_n,
	A					=> cpu_a_bus,
	DI					=> cpu_di_bus,
	DO					=> cpu_do_bus
);
	
-- memory manager
U5: entity work.memory 
port map ( 
	CLK2X 			=> clk_bus,
	CLKX 				=> clk_div2,
	CLK_CPU 			=> cpuclk,
	-- cpu signals
	A 					=> cpu_a_bus,
	D 					=> cpu_do_bus,
	N_MREQ 			=> cpu_mreq_n,
	N_IORQ 			=> cpu_iorq_n,
	N_WR 				=> cpu_wr_n,
	N_RD 				=> cpu_rd_n,
	N_M1 				=> cpu_m1_n,
	-- loader signals
	loader_act 		=> loader_act,
	loader_ram_a 	=> loader_ram_a,
	loader_ram_do 	=> loader_ram_do,
	loader_ram_wr 	=> loader_ram_wr,
	-- ram 
	MA 				=> SRAM_A,
	MD 				=> SRAM_D,
	N_MRD 			=> SRAM_NRD,
	N_MWR 			=> SRAM_NWR,
	-- ram out to cpu
	DO 				=> ram_do_bus,
	N_OE 				=> ram_oe_n,	
	-- ram pages
	RAM_BANK 		=> port_7ffd_reg(2 downto 0),
	RAM_EXT 			=> ram_ext, -- seg A3 - seg A5
	-- video
	VA 				=> vid_a_bus,
	VID_PAGE 		=> port_7ffd_reg(3), -- seg A0 - seg A2
	DS80 				=> ds80,
	CPM 				=> cpm,
	SCO 				=> sco,
	SCR 				=> scr,
	WOROM 			=> worom,
	-- video bus control signals
	VBUS_MODE_O 	=> vbus_mode, 	-- video bus mode: 0 - ram, 1 - vram
	VID_RD_O 		=> vid_rd, 		-- read attribute or pixel	
	-- TRDOS 
	TRDOS 			=> dos_act,	
	-- rom
	ROM_BANK 		=> rom14,
	EXT_ROM_BANK   => ext_rom_bank
);	

-- Video Spectrum/Pentagon
U6: entity work.video
port map (
	CLK 				=> clk_div2, 	-- 14 / 12
	CLK2x 			=> clk_bus, 	-- 28 / 24
	ENA 				=> clk_div4, 	-- 7 / 6
	RESET 			=> reset,	
	BORDER 			=> port_xxfe_reg(3 downto 0),
	DI 				=> SRAM_D,
	TURBO 			=> '0',
	INTA 				=> cpu_inta_n,
	INT 				=> cpu_int_n,
	pFF_CS			=> vid_pff_cs, -- port FF select
	ATTR_O 			=> vid_attr,  -- attribute register output
	A 					=> vid_a_bus,	
	MODE60			=> soft_sw(2),
	DS80 				=> ds80,
	CS7E				=> cs_xx7e,
	BUS_A 			=> cpu_a_bus(15 downto 8),
	BUS_D 			=> cpu_do_bus,
	BUS_WR_N 		=> cpu_wr_n,
	GX0 				=> gx0,	
	VIDEO_R 			=> vid_rgb(8 downto 6),
	VIDEO_G 			=> vid_rgb(5 downto 3),
	VIDEO_B 			=> vid_rgb(2 downto 0),	
	HSYNC 			=> vid_hsync,
	VSYNC 			=> vid_vsync,
	VBUS_MODE 		=> vbus_mode,
	VID_RD 			=> vid_rd,	
	HCNT 				=> vid_hcnt,
	VCNT 				=> vid_vcnt,
	BLINK 			=> blink
);

-- osd (debug)
U7: entity work.osd
port map (
	CLK 				=> clk_bus,
	CLK2 				=> clk_div2,
	DS80				=> ds80,
	RGB_I 			=> vid_rgb,
	RGB_O 			=> vid_rgb_osd,
	HCNT_I 			=> vid_hcnt,
	VCNT_I 			=> vid_vcnt,
	BLINK 			=> blink,

	LOADED 			=> kb_loaded,
	
	-- sensors
	TURBO 			=> kb_turbo,
	SCANDOUBLER_EN => vid_scandoubler_enable,
	MODE60 			=> soft_sw(2),
	ROM_BANK 		=> ext_rom_bank,
	KB_MODE 			=> kb_mode,
	KB_WAIT 			=> kb_wait,
	SSG_MODE 		=> soft_sw(8),
	SSG_STEREO 		=> soft_sw(7)
);

-- Scandoubler	
U8: entity work.vga_pal 
port map (
	RGB_IN 			=> vid_rgb_osd,
	KSI_IN 			=> vid_vsync,
	SSI_IN 			=> vid_hsync,
	CLK 				=> clk_div2,
	CLK2 				=> clk_bus,
	EN 				=> vid_scandoubler_enable,
	DS80				=> ds80,		
	RGB_O(8 downto 6)	=> VGA_R,
	RGB_O(5 downto 3)	=> VGA_G,
	RGB_O(2 downto 0)	=> VGA_B,
	VSYNC_VGA		=> VGA_VS,
	HSYNC_VGA		=> VGA_HS
);

-- SPI flash parallel interface
U9: entity work.flash
port map(
	CLK 				=> clk_bus,
	RESET 			=> areset,
	
	A 					=> flash_a_bus,
	DI 				=> flash_di_bus,
	DO 				=> flash_do_bus,
	WR_N 				=> flash_wr_n,
	RD_N 				=> flash_rd_n,
	ER_N 				=> flash_er_n,

	DATA0				=> DATA0,
	NCSO				=> flash_ncs,
	DCLK				=> flash_clk,
	ASDO				=> flash_do,

	BUSY 				=> flash_busy,
	DATA_READY 		=> flash_rdy
);

-- Loader
U10: entity work.loader
port map(
	CLK 				=> clk_bus,
	RESET 			=> areset,
	
	RAM_A 			=> loader_ram_a,
	RAM_DO 			=> loader_ram_do,
	RAM_WR 			=> loader_ram_wr,
	
	CFG 				=> board_revision,

	FLASH_A 			=> loader_flash_a,
	FLASH_DO 		=> flash_do_bus,
	FLASH_RD_N 		=> loader_flash_rd_n,	
	FLASH_BUSY 		=> flash_busy,
	FLASH_READY 	=> flash_rdy,
	
	LOADER_ACTIVE 	=> loader_act,
	LOADER_RESET 	=> loader_reset
);	
		
-- TurboSound
U11: entity work.turbosound
port map (
	I_CLK				=> clk_bus,
	I_ENA				=> ena_div16,
	I_ADDR			=> cpu_a_bus,
	I_DATA			=> cpu_do_bus,
	I_WR_N			=> cpu_wr_n,
	I_IORQ_N			=> cpu_iorq_n,
	I_M1_N			=> cpu_m1_n,
	I_RESET_N		=> cpu_reset_n,
	O_SEL				=> ssg_sel,
	I_MODE 			=> soft_sw(8),
	-- ssg0
	O_SSG0_DA		=> ssg_cn0_bus,
	O_SSG0_AUDIO_A	=> ssg_cn0_a,
	O_SSG0_AUDIO_B	=> ssg_cn0_b,
	O_SSG0_AUDIO_C	=> ssg_cn0_c,
	-- ssg1
	O_SSG1_DA		=> ssg_cn1_bus,
	O_SSG1_AUDIO_A	=> ssg_cn1_a,
	O_SSG1_AUDIO_B	=> ssg_cn1_b,
	O_SSG1_AUDIO_C	=> ssg_cn1_c);

-- Covox
U12: entity work.covox
port map (
	I_RESET			=> reset,
	I_CLK				=> clk_bus,
	I_CS				=> '1',
	I_WR_N			=> cpu_wr_n,
	I_ADDR			=> cpu_a_bus(7 downto 0),
	I_DATA			=> cpu_do_bus,
	I_IORQ_N			=> cpu_iorq_n,
	I_DOS				=> dos_act,
	I_CPM 			=> cpm,
	I_ROM14 			=> rom14,
	O_LEFT			=> covox_l,
	O_RIGHT			=> covox_r,
	O_FB 				=> covox_fb
);
	 
G_SAA1099: if enable_saa1099 generate
U13: saa1099
port map(
	clk_sys			=> clk_8,
	ce					=> '1',
	rst_n				=> not reset,
	cs_n				=> '0',
	a0					=> cpu_a_bus(8),		-- 0=data, 1=address
	wr_n				=> saa_wr_n,
	din				=> cpu_do_bus,
	out_l				=> saa_out_l,
	out_r				=> saa_out_r);
end generate G_SAA1099;

-- AVR Keyboard / mouse / rtc
U14: entity work.avr
port map (
	 CLK 				=> clk_bus,
	 CLKEN 			=> cpuclk,
	 N_RESET 		=> not areset,
    A       		=> cpu_a_bus(15 downto 8),
    KB				=> kb_do_bus,
    AVR_MOSI		=> AVR_MOSI,
    AVR_MISO		=> AVR_MISO,
    AVR_SCK			=> AVR_SCK,
	 AVR_SS 			=> AVR_NCS,
	 
	 MS_X 			=> ms_x,
	 MS_Y 			=> ms_y,
	 MS_BTNS 		=> ms_b,
	 MS_Z 			=> ms_z,
	 MS_PRESET 		=> ms_present,
	 MS_EVENT 		=> ms_event,
	 MS_DELTA_X 	=> ms_delta_x,
	 MS_DELTA_Y 	=> ms_delta_y,
	 
	 RTC_A 			=> mc146818_a_bus,
	 RTC_DI 			=>	cpu_do_bus,
	 RTC_DO 			=>	mc146818_do_bus,
	 RTC_CS 			=> '1',
	 RTC_WR_N 		=> not mc146818_wr,
	 
	 INIT 			=> loader_reset,
	 
	 LED1 			=> led1,
	 LED2				=> led2,
	 LED1_OWR 		=> led1_overwrite,
	 LED2_OWR 		=> led2_overwrite,
	 
	 CFG 				=> board_revision,
	 
	 SOFT_SW 		=> soft_sw,
	 
	 KB_MODE 		=> kb_mode,
	 
	 KB_SCANCODE 	=> open, 

	 RESET 			=> kb_reset,
	 TURBO 			=> kb_turbo,
	 MAGICK 			=> kb_magic,
	 WAIT_CPU 		=> kb_wait,
	 
	 LOADED 			=> kb_loaded,
	 
	 JOY 				=> joy_bus
);
	
-- TDA1543
U15: entity work.tda1543
port map (
	RESET				=> reset,
	CLK 				=> clk_8,
	DAC_TYPE 		=> audio_dac_type,
	CS 				=> '1',
	DATA_L 			=> audio_l,
	DATA_R 			=> audio_r,
	BCK 				=> SND_BS,
	WS  				=> SND_WS,
	DATA 				=> SND_DAT
);

-- FDD / HDD controllers
U16: entity work.bus_port
port map (
	CLK 				=> clk_bus_port,
	CLK2 				=> clk_8,
	CLK_BUS 			=> clk_bus,
	CLK_CPU 			=> cpuclk,
	RESET 			=> reset,
	
	SD 				=> SD,
	SA 				=> SA,
	CPLD_CLK 		=> CPLD_CLK,
	CPLD_CLK2 		=> CPLD_CLK2,
	NRESET 			=> NRESET,

	BUS_A 			=> cpu_a_bus,
	BUS_DI 			=> cpu_do_bus,
	BUS_DO 			=> cpld_do,
	BUS_RD_N 		=> cpu_rd_n,
	BUS_WR_N 		=> cpu_wr_n,
	BUS_MREQ_N 		=> cpu_mreq_n,
	BUS_IORQ_N 		=> cpu_iorq_n,
	BUS_M1_N 		=> cpu_m1_n,
	BUS_CPM 			=> cpm,
	BUS_DOS 			=> dos_act,
	BUS_ROM14 		=> rom14	
);

-- UART (via AY port A)
G_AY_UART: if enable_ay_uart generate
U17: entity work.ay_uart 
port map(
	CLK_I 			=> clk_bus,
	RESET_I 			=> reset,
	EN_I 				=> clk_div16,
	BDIR_I 			=> ay_bdir,
	BC_I 				=> ay_bc1,			
	CS_I 				=> ay_port,
	DATA_I 			=> cpu_do_bus,
	DATA_O 			=> ay_uart_do_bus,
	OE_N 				=> ay_uart_oe_n,
	UART_TX 			=> UART_TX,
	UART_RX 			=> UART_RX,
	UART_RTS 		=> UART_CTS
);
end generate G_AY_UART;

-- Diag ROM
U18: entity work.altrom0
port map(
	clock => clk_bus,
	address => cpu_a_bus(13 downto 0),
	q => rom_do_bus
);

-- Serial mouse emulation
U19: entity work.serial_mouse
port map(
	CLK 				=> clk_bus,
	CLKEN 			=> cpuclk,
	N_RESET 			=> not(reset),
	A 					=> cpu_a_bus,
	DI					=> cpu_do_bus,
	WR_N 				=> cpu_wr_n,
	RD_N 				=> cpu_rd_n,
	IORQ_N 			=> cpu_iorq_n,
	M1_N 				=> cpu_m1_n,
	CPM 				=> cpm,
	DOS 				=> dos_act,
	ROM14 			=> rom14,
	
	MS_X 				=> ms_delta_x,
	MS_Y				=> -ms_delta_y,
	MS_BTNS 			=> ms_b,
	MS_PRESET 		=> ms_present,
	MS_EVENT 		=> ms_event,
	
	DO 				=> serial_ms_do_bus,
	INT_N 			=> serial_ms_int,
	OE_N 				=> serial_ms_oe_n
);

-- UART (via ZX UNO ports #FC3B / #FD3B) 	
G_UNO_UART: if enable_zxuno_uart generate
U20: zxunoregs 
port map(
	clk => clk_bus,
	rst_n => not(reset),
	a => cpu_a_bus,
	iorq_n => cpu_iorq_n,
	rd_n => cpu_rd_n,
	wr_n => cpu_wr_n,
	din => cpu_do_bus,
	dout => zxuno_addr_to_cpu,
	oe_n => zxuno_addr_oe_n,
	addr => zxuno_addr,
	read_from_reg => zxuno_regrd,
	write_to_reg => zxuno_regwr,
	regaddr_changed => zxuno_regaddr_changed
);

U21: zxunouart 
port map(
	clk => clk_div4, -- 7 or 6 mhz
	ds80 => ds80,
	zxuno_addr => zxuno_addr,
	zxuno_regrd => zxuno_regrd,
	zxuno_regwr => zxuno_regwr,
	din => cpu_do_bus,
	dout => zxuno_uart_do_bus,
	oe_n => zxuno_uart_oe_n,
	uart_tx => UART_TX,
	uart_rx => UART_RX,
	uart_rts => UART_CTS
);	
end generate G_UNO_UART;

-- ESP8266 UART bridge on pin header
G_ESP8266_BRIDGE: if enable_esp866_bridge generate
	UART_TX <= PIN_141;
	PIN_121 <= UART_RX;
	UART_CTS <= PIN_138;
end generate G_ESP8266_BRIDGE;

-- board features
U22: entity work.board 
port map(
	CLK => clk_bus,
	CFG => board_revision,
	SW3 => SW3,
	SOFT_SW1 => soft_sw(1),
	SOFT_SW2 => soft_sw(2),
	SOFT_SW3 => soft_sw(3),
	SOFT_SW4 => soft_sw(4),
	
	AUDIO_DAC_TYPE => audio_dac_type,
	ROM_BANK => ext_rom_bank,
	SCANDOUBLER_EN => vid_scandoubler_enable,
	BOARD_RESET => board_reset	
);

--U23 : entity work.compressor
--port map(
--	DI => mix_l,
--	DO => audio_l
--);
--
--U24 : entity work.compressor
--port map(
--	DI => mix_r,
--	DO => audio_r
--);
	
-- swap audio channels
audio_l <= mix_r;
audio_r <= mix_l;
	
-------------------------------------------------------------------------------
-- clocks

process (clk_bus)
begin 
	if (clk_bus'event and clk_bus = '1') then 
		clk_div2 <= not(clk_div2);
	end if;
end process;

process (clk_div2)
begin 
	if (clk_div2'event and clk_div2 = '1') then 
		clk_div4 <= not(clk_div4);
	end if;
end process;

process (clk_div4)
begin 
	if (clk_div4'event and clk_div4 = '1') then 
		clk_div8 <= not(clk_div8);
	end if;
end process;

process (clk_div8)
begin 
	if (clk_div8'event and clk_div8 = '1') then 
		clk_div16 <= not(clk_div16);
	end if;
end process;

process (clk_bus)
begin
	if clk_bus'event and clk_bus = '0' then
		ena_cnt <= ena_cnt + 1;
	end if;
end process;

ena_div2 <= ena_cnt(0);
ena_div4 <= ena_cnt(1) and ena_cnt(0);
ena_div8 <= ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_div16 <= ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_div32 <= ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
	
-------------------------------------------------------------------------------
-- Global signals

process(clk_bus)
begin
	if rising_edge(clk_bus) then
		if (locked_tri = '0') then 
			locked_tri <= '1';
			areset <= '1';
		else 
			areset <= '0';
		end if;			
	end if;
end process;

--areset <= not locked; -- global reset
reset <= areset or kb_reset or loader_reset or loader_act or board_reset; -- hot reset

cpu_reset_n <= not(reset) and not(loader_reset); -- CPU reset
cpu_inta_n <= cpu_iorq_n or cpu_m1_n;	-- INTA
cpu_nmi_n <= '0' when kb_magic = '1' else '1'; -- NMI
--cpu_wait_n <= '0' when kb_wait = '1' else '1'; -- WAIT
cpu_wait_n <= '1';
cpuclk <= '0' when kb_wait = '1' else clk_bus and ena_div8 when kb_turbo = '1' else clk_bus and ena_div4; -- 3.5 / 7 MHz

-- HDD / SD access
led1_overwrite <= '1';
process (clk_bus, SDIR, SD_NCS)
begin
	if rising_edge(clk_bus) then
		if SDIR = '1' or SD_NCS = '0' then
			led1 <= '1';
		else 
			led1 <= '0';
		end if;
	end if;
end process;

-- POWER UP / wait (blink)
led2_overwrite <= '1';
process (clk_bus, loader_act, blink, kb_wait)
begin
	if rising_edge(clk_bus) then
		if loader_act = '1' then 
			led2 <= '0';
		elsif kb_wait = '1' then 
			led2 <= blink;
		else 
			led2 <= '1';
		end if;
	end if;
end process;

-------------------------------------------------------------------------------
-- SD

SD_NCS	<= '1' when loader_act = '1' or is_flash_not_sd = '1' else zc_cs_n;
sd_clk 	<= '1' when loader_act = '1' or is_flash_not_sd = '1' else zc_sclk;
sd_si 	<= '1' when loader_act = '1' or is_flash_not_sd = '1' else zc_mosi;

-- share SPI between flash and SD
DCLK <= flash_clk when loader_act = '1' or is_flash_not_sd = '1' else sd_clk;
ASDO <= flash_do when loader_act = '1' or is_flash_not_sd = '1' else sd_si;
NCSO <= flash_ncs when loader_act = '1' or is_flash_not_sd = '1' else '1';
PIN_115 <= sd_si;

-- share flash between loader and host
flash_a_bus <= loader_flash_a when loader_act = '1' else host_flash_a_bus;
flash_di_bus <= "00000000" when loader_act = '1' else host_flash_di_bus;
flash_wr_n <= '1' when loader_act = '1' else host_flash_wr_n;
flash_rd_n <= loader_flash_rd_n when loader_act = '1' else host_flash_rd_n;
flash_er_n <= '1' when loader_act = '1' else host_flash_er_n;

host_flash_rd_n <= not port_xxC7_reg(0);	-- бит чтения из SPI-Flash
host_flash_wr_n <= not port_xxC7_reg(1);	-- бит записи в SPI-Flash
host_flash_er_n <= not port_xxC7_reg(4);  -- бит стирания 64-блока SPI-Flash
is_flash_not_sd <= port_xxC7_reg(2);		-- бит переключения SPI между flash / SD картой
fw_update_mode <= port_xxC7_reg (3);		-- бит разрешения обновления SPI-Flash
host_flash_di_bus <= port_xxE7_reg;			-- Регистр со значением шины данных на вывод в SPI-Flash
host_flash_a_bus <= port_xxA7_reg & port_xx87_reg & port_xx67_reg;	-- Шина адреса для SPI-Flash

--Доступен, если бит ROM14=1 (7FFD), бит CPM=1 (DFFD), 80DS=1 (DFFD)
--Порт С7 - статус регистр R/W:
--	На чтение:
--		0 бит - flash_busy (1 - устройство занято, 0 - свободно)
--		1 бит - flash_rdy (1 - данные готовы для чтения, 0 - данные не готовы)
--		3 бит - is_flash_not_sd (1 - flash, 0 - SD)
--		4 бит - fw_update_mode (1 - разрешены операции с флешкой, 0 - запрещены)
--
--	На запись:
--		0 бит - flash_rd (1 - инициациирование режима чтения)
--		1 бит - flash_wr (1 - инициациирование режима записи)
--		3 бит - is_flash_not_sd
--		4 бит - fw_update_mode
--    5 бит - flash_er (1 - инициализирование режима стирания 64к блока)
--
--Доступны, если бит ROM14=1 (7FFD), бит CPM=1 (DFFD), 80DS=1 (DFFD), fw_update_mode=1 (xxC7)
--Порт 87 - младший байт выбора страниц spi-flash /W
--Порт A7 - старший байт выбора страниц spi-flash /W
--Порт E7 - Порт данных для записи и чтения данных из страницы spi-flash
--Порт 67 - адрес байта в странице /W


-------------------------------------------------------------------------------
-- Ports

-- #FD port correction
-- IN A, (#FD) - read a value from a hardware port 
-- OUT (#FD), A - writes the value of the second operand into the port given by the first operand.
fd_sel <= '0' when (
	(cpu_do_bus(7 downto 4) = "1101" and cpu_do_bus(2 downto 0) = "011") or 
	(cpu_di_bus(7 downto 4) = "1101" and cpu_di_bus(2 downto 0) = "011")) else '1'; 

process(fd_sel, reset, cpu_m1_n)
begin
	if reset='1' then
		fd_port <= '1';
	elsif rising_edge(cpu_m1_n) then 
		fd_port <= fd_sel;
	end if;
end process;

rom14 <= port_7ffd_reg(4); -- rom bank
cpm 	<= port_dffd_reg(5); -- 1 - блокирует работу контроллера из ПЗУ TR-DOS и включает порты на доступ из ОЗУ (ROM14=0); При ROM14=1 - мод. доступ к расширен. периферии
worom <= port_dffd_reg(4); -- 1 - отключает блокировку порта 7ffd и выключает ПЗУ, помещая на его место ОЗУ из seg 00
ds80 	<= port_dffd_reg(7); -- 0 = seg05 spectrum bitmap, 1 = profi bitmap seg06 & seg 3a & seg 04 & seg 38
scr 	<= port_dffd_reg(6); -- памяти CPU на место seg 02, при этом бит D3 CMR0 должен быть в 1 (#8000-#BFFF)
sco 	<= port_dffd_reg(3); -- Выбор положения окна проецирования сегментов:
									-- 0 - окно номер 1 (#C000-#FFFF)
									-- 1 - окно номер 2 (#4000-#7FFF)

ram_ext <= port_dffd_reg(2 downto 0);

cs_xxfe <= '1' when cpu_iorq_n = '0' and cpu_a_bus(0) = '0' else '0';
cs_xx7e <= '1' when cs_xxfe = '1' and cpu_a_bus(7) = '0' else '0';
cs_eff7 <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"EFF7" else '0';
cs_fffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"FFFD" and fd_port = '1' else '0';
cs_dffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"DFFD" and fd_port = '1' else '0';
cs_7ffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"7FFD" else '0';
cs_xxfd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(15) = '0' and cpu_a_bus(1) = '0' and fd_port = '0' else '0';

-- Регистры SPI-FLASH
cs_xxC7 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"C7" and cpm='1' and rom14='1' and ds80='1' else '0';
cs_xx87 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"87" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';
cs_xxA7 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"A7" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';
cs_xxE7 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"E7" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';
cs_xx67 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"67" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';

-- регистр AS часов
cs_rtc_as <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and
							((cpu_a_bus(7 downto 0) = X"FF" or cpu_a_bus(7 downto 0) = X"BF") and cpm='1' and rom14='1' and dos_act='0') -- расширенная периферия
				     else '0';
--
-- регистр DS часов					  
cs_rtc_ds <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and 
							((cpu_a_bus(7 downto 0) = X"DF" or cpu_a_bus(7 downto 0) = X"9F") and cpm='1' and rom14='1' and dos_act='0') -- расширенная периферия
				     else '0';
					  
-- порты #7e - пишутся по фронту /wr
port_xxfe_reg <= cpu_do_bus when cs_xxfe = '1' and (cpu_wr_n'event and cpu_wr_n = '1');

process (reset, areset, clk_bus, cpu_a_bus, dos_act, cs_xxfe, cs_eff7, cs_7ffd, cs_xxfd, port_7ffd_reg, cpu_mreq_n, cpu_m1_n, cpu_wr_n, cpu_do_bus, fd_port)
begin
	if reset = '1' then
		port_eff7_reg <= (others => '0');
		port_7ffd_reg <= (others => '0');
		port_dffd_reg <= (others => '0');
		port_xxC7_reg <= (others => '0');
		port_xx87_reg <= (others => '0');
		port_xxA7_reg <= (others => '0');
		port_xxE7_reg <= (others => '0');
		port_xx67_reg <= (others => '0');
		dos_act <= '1';
	elsif clk_bus'event and clk_bus = '1' then

			-- #EFF7
			if cs_eff7 = '1' and cpu_wr_n = '0' then 
				port_eff7_reg <= cpu_do_bus; 
			end if;
			
			-- profi RTC #BF / #FF
			if cs_rtc_as = '1' and cpu_wr_n = '0' then 
				mc146818_a_bus <= cpu_do_bus(5 downto 0); 
			end if;

			-- #DFFD
			if cs_dffd = '1' and cpu_wr_n = '0' then
				port_dffd_reg <= cpu_do_bus;
			end if;
			
			-- #7FFD
			if cs_7ffd = '1' and cpu_wr_n = '0' and (port_7ffd_reg(5) = '0' or port_dffd_reg(4)='1') then
				port_7ffd_reg <= cpu_do_bus;
			-- #FD
			elsif cs_xxfd = '1' and cpu_wr_n = '0' and (port_7ffd_reg(5) = '0' or port_dffd_reg(4)='1') then -- short #FD
				port_7ffd_reg <= cpu_do_bus;
			end if;
			
			-- #xxC7
			if cs_xxC7 = '1' and cpu_wr_n = '0' then
				port_xxC7_reg <= cpu_do_bus;
			end if;

			-- #xx87
			if cs_xx87 = '1' and cpu_wr_n = '0' then
				port_xx87_reg <= cpu_do_bus;
			end if;

			-- #xxA7
			if cs_xxA7 = '1' and cpu_wr_n = '0' then
				port_xxA7_reg <= cpu_do_bus;
			end if;

			-- #xxE7
			if cs_xxE7 = '1' and cpu_wr_n = '0' then
				port_xxE7_reg <= cpu_do_bus;
			end if;

			-- #xx67
			if cs_xx67 = '1' and cpu_wr_n = '0' then
				port_xx67_reg <= cpu_do_bus;
			end if;
			
			-- TR-DOS FLAG
			if cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 8) = X"3D" and rom14 = '1' and port_dffd_reg(5) = '0' then dos_act <= '1';
			elsif ((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00") or (port_dffd_reg(5) = '1')) then dos_act <= '0'; end if;
				
	end if;
end process;

-------------------------------------------------------------------------------
-- Audio mixer

speaker <= port_xxfe_reg(4);

mix_l <= "0000000000000000" when loader_act = '1' or cpu_wait_n = '0' else 
				("000" & speaker & "000000000000") + -- ACB: L = A + C/2
				("000"  & ssg_cn0_a &     "00000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("000"  & ssg_cn1_a &     "00000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("00" & covox_l & covox_l(7 downto 4) & "00") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_l  &    "00000") when soft_sw(7) = '0' else 
				("000" & speaker & "000000000000") +  -- ABC: L = A + B/2
				("000"  & ssg_cn0_a &     "00000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("000"  & ssg_cn1_a &     "00000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("00" & covox_l & covox_l(7 downto 4) & "00") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_l  &    "00000");
				
mix_r <= "0000000000000000" when loader_act = '1' or cpu_wait_n = '0' else 
				("000" & speaker & "000000000000") + -- ACB: R = B + C/2
				("000"  & ssg_cn0_b &     "00000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("000"  & ssg_cn1_b &     "00000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("00" & covox_r & covox_r(7 downto 4) & "00") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_r &     "00000") when soft_sw(7) = '0' else
				("000" & speaker & "000000000000") + -- ABC: R = C + B/2
				("000"  & ssg_cn0_c &     "00000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("000"  & ssg_cn1_c &     "00000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("00" & covox_r & covox_r(7 downto 4) & "00") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_r &     "00000");
				
-- SAA1099
saa_wr_n <= '0' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = "11111111" and dos_act = '0') else '1';

-------------------------------------------------------------------------------
-- Port I/O

mc146818_wr <= '1' when (cs_rtc_ds = '1' and cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_m1_n = '1') else '0';

-- Z-controller spi
zc_spi_start <= '1' when cpu_a_bus(7 downto 0)=X"57" and cpu_iorq_n='0' and cpu_m1_n='1' and cpm='0' and loader_act='0' and is_flash_not_sd='0' else '0';
zc_wr_en <= '1' when cpu_a_bus(7 downto 0)=X"57" and cpu_iorq_n='0' and cpu_m1_n='1' and cpu_wr_n='0' and cpm='0' and loader_act='0' and is_flash_not_sd='0' else '0';
port77_wr <= '1' when cpu_a_bus(7 downto 0)=X"77" and cpu_iorq_n='0' and cpu_m1_n='1' and cpu_wr_n='0' and cpm='0' and loader_act='0' and is_flash_not_sd='0' else '0';

process (port77_wr, loader_act, reset, clk_bus)
	begin
		if loader_act='1' or reset='1' then
			zc_cs_n <= '1';
		elsif clk_bus'event and clk_bus='1' then
			if port77_wr='1' then
				zc_cs_n <= cpu_do_bus(1);
			end if;
		end if;
end process;

U_ZC_SPI: entity work.zc_spi     -- SD
port map(
	DI				=> cpu_do_bus,
	START			=> zc_spi_start,
	WR_EN			=> zc_wr_en,
	CLC     		=> clk_bus, --cpuclk,
	MISO    		=> DATA0,
	DO				=> zc_do_bus,
	SCK     		=> zc_sclk,
	MOSI    		=> zc_mosi
);

ay_port 		<= '1' when cpu_a_bus(7 downto 0) = x"FD" and cpu_a_bus(15)='1' and fd_port = '1' else '0';
ay_bdir 		<= '1' when ay_port = '1' and cpu_iorq_n = '0' and cpu_wr_n = '0' else '0';
ay_bc1 		<= '1' when ay_port = '1' and cpu_a_bus(14) = '1' and cpu_iorq_n = '0' and (cpu_wr_n='0' or cpu_rd_n='0') else '0';

-------------------------------------------------------------------------------
-- CPU0 Data bus

process (selector, cpu_a_bus, gx0, serial_ms_do_bus, ram_do_bus, mc146818_do_bus, kb_do_bus, zc_do_bus, ssg_cn0_bus, ssg_cn1_bus, port_7ffd_reg, port_dffd_reg, ay_uart_do_bus, zxuno_uart_do_bus, cpld_do, vid_attr, port_eff7_reg, joy_bus, ms_z, ms_b, ms_x, ms_y, zxuno_addr_to_cpu, port_xxC7_reg, flash_rdy, flash_busy, flash_do_bus)
begin
	case selector is
		when x"00" => 
			if (cpu_a_bus(15 downto 14) = "00" and enable_diag_rom) then 
				cpu_di_bus <= rom_do_bus;
			else
				cpu_di_bus <= ram_do_bus;
			end if;	
		when x"01" => cpu_di_bus <= mc146818_do_bus;
		when x"02" => cpu_di_bus <= GX0 & "1" & kb_do_bus;
		when x"03" => cpu_di_bus <= zc_do_bus;
		when x"04" => cpu_di_bus <= "11111100";		
		when x"05" => cpu_di_bus <= "000" & joy_bus;
		when x"06" => cpu_di_bus <= ssg_cn0_bus;
		when x"07" => cpu_di_bus <= ssg_cn1_bus;
		when x"08" => cpu_di_bus <= port_dffd_reg;
		when x"09" => cpu_di_bus <= port_7ffd_reg;
		when x"0A" => cpu_di_bus <= ms_z(3 downto 0) & '1' & not(ms_b(2)) & not(ms_b(0)) & not(ms_b(1)); -- D0=right, D1 = left, D2 = middle, D3 = fourth, D4..D7 - wheel
		when x"0B" => cpu_di_bus <= ms_x;
		when x"0C" => cpu_di_bus <= ms_y;
		when x"0D" => cpu_di_bus <= ay_uart_do_bus;
		when x"0E" => cpu_di_bus <= serial_ms_do_bus;
		when x"0F" => cpu_di_bus <= zxuno_addr_to_cpu;
		when x"10" => cpu_di_bus <= zxuno_uart_do_bus;
		when x"11" => cpu_di_bus <= "0000" & port_xxC7_reg(3) & port_xxC7_reg(2) & flash_rdy & flash_busy;
		when x"12" => cpu_di_bus <= flash_do_bus;
		when x"13" => cpu_di_bus <= vid_attr;
		when others => cpu_di_bus <= cpld_do;
	end case;
end process;

selector <= 	
	x"00" when (ram_oe_n = '0') else -- ram / rom
	x"01" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cs_rtc_ds = '1') else -- RTC MC146818A
	x"02" when (cs_xxfe = '1' and cpu_rd_n = '0') else 									-- Keyboard, port #FE
	x"03" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus(7 downto 0) = X"57" and cpm='0' and is_flash_not_sd = '0') else 	-- Z-Controller
	x"04" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus(7 downto 0) = X"77" and cpm='0' and is_flash_not_sd = '0') else 	-- Z-Controller
	x"05" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus( 7 downto 0) = X"1F" and dos_act = '0' and cpm = '0') else -- Joystick, port #1F
	x"06" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '0') else 			-- TurboSound
	x"07" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '1') else
	x"08" when (cs_dffd = '1' and cpu_rd_n = '0') else										-- port #DFFD
	x"09" when (cs_7ffd = '1' and cpu_rd_n = '0') else										-- port #7FFD
	x"0A" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FADF" and ms_present = '1' and cpm='0') else	-- Mouse0 port key, z
	x"0B" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FBDF" and ms_present = '1' and cpm='0') else	-- Mouse0 port x
	x"0C" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FFDF" and ms_present = '1' and cpm='0') else	-- Mouse0 port y 																
	x"0D" when (enable_ay_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and ay_uart_oe_n = '0') else -- AY UART
	x"0E" when (serial_ms_oe_n = '0') else -- Serial mouse
	x"0F" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_addr_oe_n = '0') else -- ZX UNO Register
	x"10" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_uart_oe_n = '0') else -- ZX UNO UART
	x"11" when (cs_xxC7 = '1' and cpu_rd_n = '0') else
	x"12" when (cs_xxE7 = '1' and cpu_rd_n = '0') else
	x"13" when (vid_pff_cs = '1' and cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"FF") and dos_act='0' else -- Port FF select
	(others => '1');
	
-- debug 
--	PIN_141 <= cpu_int_n;
--	PIN_138 <= VGA_R(2);
--	PIN_121 <= VGA_G(2);
--	PIN_120 <= VGA_B(2);
--	PIN_119 <= VGA_VS;
--	PIN_115 <= VGA_HS;

-- PIN_138 <= locked;
-- PIN_120 <= clk_bus;
-- PIN_141 <= areset;
	
end rtl;
