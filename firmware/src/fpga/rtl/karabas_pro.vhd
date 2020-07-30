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
		enable_diag_rom	 : boolean := false; -- Retroleum diagrom
		enable_turbo 		 : boolean := false -- enable Turbo mode 7MHz
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
	SD_NCS		: out std_logic; -- /CS
	
	-- VGA 
	VGA_R 		: out std_logic_vector(2 downto 0);
	VGA_G 		: out std_logic_vector(2 downto 0);
	VGA_B 		: out std_logic_vector(2 downto 0);
	VGA_HS 		: buffer std_logic;
	VGA_VS 		: buffer std_logic;
		
	-- AVR SPI slave
	AVR_SCK 		: in std_logic;
	AVR_MOSI 	: in std_logic;
	AVR_MISO 	: out std_logic;
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
	PIN_119		: inout std_logic;
	PIN_115		: inout std_logic;
		
	-- UART / ESP8266
	UART_RX 		: in std_logic;
	UART_TX 		: out std_logic;
	UART_CTS 	: out std_logic
	
);
end karabas_pro;

architecture rtl of karabas_pro is

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
signal port_1ffd_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_dffd_reg : std_logic_vector(7 downto 0) := "00000000";
signal port_xx7e_reg : std_logic_vector(7 downto 0) := "00000000";

-- Keyboard
signal kb_do_bus		: std_logic_vector(5 downto 0);
signal kb_reset 		: std_logic := '0';
signal kb_magic 		: std_logic := '0';
signal kb_special 	: std_logic := '0';
signal kb_turbo 		: std_logic := '0';

-- Joy
signal joy_bus 		: std_logic_vector(4 downto 0) := "11111";

-- Mouse
signal ms_x				: std_logic_vector(7 downto 0);
signal ms_y				: std_logic_vector(7 downto 0);
signal ms_z				: std_logic_vector(3 downto 0);
signal ms_b				: std_logic_vector(2 downto 0);

-- Video
signal vid_a_bus		: std_logic_vector(13 downto 0);
signal vid_di_bus		: std_logic_vector(7 downto 0);
signal vid_hsync		: std_logic;
signal vid_vsync		: std_logic;
signal vid_int			: std_logic;
signal vid_attr		: std_logic_vector(7 downto 0);
signal vid_rgb			: std_logic_vector(8 downto 0);
signal vid_rgb_osd 	: std_logic_vector(8 downto 0);
signal vid_invert 	: std_logic;
signal vid_hcnt 		: std_logic_vector(9 downto 0);
signal vid_vcnt 		: std_logic_vector(8 downto 0);

-- Z-Controller
signal zc_do_bus		: std_logic_vector(7 downto 0);
signal zc_rd			: std_logic;
signal zc_wr			: std_logic;
signal zc_cs_n			: std_logic;
signal zc_sclk			: std_logic;
signal zc_mosi			: std_logic;
signal zc_miso			: std_logic;

-- MC146818A
signal mc146818_wr		: std_logic;
signal mc146818_a_bus	: std_logic_vector(5 downto 0);
signal mc146818_do_bus	: std_logic_vector(7 downto 0);
signal mc146818_busy		: std_logic;
signal port_bff7			: std_logic;
signal port_eff7_reg		: std_logic_vector(7 downto 0);

-- Port selectors
signal fd_port 		: std_logic;
signal fd_sel 			: std_logic;
signal cs_xxfe 		: std_logic := '0'; 
signal cs_xxff 		: std_logic := '0';
signal cs_eff7 		: std_logic := '0';
signal cs_dff7 		: std_logic := '0';
signal cs_7ffd 		: std_logic := '0';
signal cs_1ffd 		: std_logic := '0';
signal cs_dffd 		: std_logic := '0';
signal cs_fffd 		: std_logic := '0';
signal cs_xxfd 		: std_logic := '0';
signal cs_xx7e 		: std_logic := '0';

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
signal audio_l			: std_logic_vector(15 downto 0);
signal audio_r			: std_logic_vector(15 downto 0);
signal sound			: std_logic_vector(7 downto 0);

-- AY UART signals
signal ay_bdir 		: std_logic;
signal ay_bc1			: std_logic;
signal ay_port 		: std_logic := '0';

-- Soundrive
signal covox_a			: std_logic_vector(7 downto 0);
signal covox_b			: std_logic_vector(7 downto 0);
signal covox_c			: std_logic_vector(7 downto 0);
signal covox_d			: std_logic_vector(7 downto 0);

-- SAA1099
signal saa_wr_n		: std_logic;
signal saa_out_l		: std_logic_vector(7 downto 0);
signal saa_out_r		: std_logic_vector(7 downto 0);

-- CLOCK
signal clk_28 			: std_logic := '0';
signal clk_24 			: std_logic := '0';
signal clk_8			: std_logic := '0';
signal clk_bus			: std_logic := '0';
signal clk_div2		: std_logic := '0';
signal clk_div4		: std_logic := '0';
signal clk_div8		: std_logic := '0';
signal clk_div16		: std_logic := '0';
signal clk_i2s 		: std_logic := '0';
signal vga_clk_x 		: std_logic := '0';
signal vga_clk_2x 	: std_logic := '0';
signal vga_clko_2x 	: std_logic := '0';

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
signal loader_act		: std_logic := '1';
signal loader_reset 	: std_logic := '0';
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
signal palette_en 	: std_logic := '1';

-- Loader
signal loader_ram_di	: std_logic_vector(7 downto 0);
signal loader_ram_do	: std_logic_vector(7 downto 0);
signal loader_ram_a	: std_logic_vector(20 downto 0);
signal loader_ram_wr : std_logic;
signal loader_ram_rd : std_logic;

-- SPI flash / SD
signal flash_ncs 		: std_logic;
signal flash_clk 		: std_logic;
signal flash_do 		: std_logic;
signal sd_clk 			: std_logic;
signal sd_si 			: std_logic;

-- uart 
signal uart_do_bus 	: std_logic_vector(7 downto 0);
signal uart_oe_n 		: std_logic;

-- cpld port
signal cpld_oe_n 		: std_logic := '1';
signal cpld_do 		: std_logic_vector(7 downto 0);

-- test rom 
signal rom_do_bus 	: std_logic_vector(7 downto 0);

-- profi special signals
signal cpm 				: std_logic := '0';
signal worom 			: std_logic := '0';
signal ds80 			: std_logic := '0';
signal scr 				: std_logic := '0';
signal sco 				: std_logic := '0';
signal u25 				: std_logic := '0';
signal rom14 			: std_logic := '0';
signal gx0 				: std_logic := '0';

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

begin

-- PLL
U1: entity work.altpll0
port map (
	inclk0			=> CLK_50MHZ,	--  50.0 MHz
	locked			=> locked,
	c0 				=> clk_28,
	c1 				=> clk_24
	);
	
-- PLL2
U2: entity work.altpll1
port map (
	inclk0			=> CLK_50MHZ,	--  50.0 MHz
	locked 			=> open,
	c0 				=> open, -- 24
	c1 				=> clk_8);
		
-- main clock selector
--U3: entity work.clk_mux
--port map(
--	data0 			=> clk_28,
--	data1 			=> clk_24,
--	sel 				=> ds80,
--	result 			=> clk_bus
--);

U3: entity work.clk_ctrl
port map(
	clkselect 	=> ds80,
	inclk0x 		=> clk_28,
	inclk1x 		=> clk_24,
	outclk 		=> clk_bus
);

-- Zilog Z80A CPU
U4: entity work.T80aw
--generic map (
--	Mode				=> 0,		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
--	T2Write			=> 1,		-- 0 => WR_n active in T3, /=0 => WR_n active in T2
--	IOWait			=> 1 )	-- 0 => Single cycle I/O, 1 => Std I/O cycle

port map (
	RESET_n			=> cpu_reset_n,
	CLK_n				=> clk_bus,
	ENA				=> cpuclk,
	WAIT_n			=> cpu_wait_n,
	INT_n				=> cpu_int_n,
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
	DO					=> cpu_do_bus);
	
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
	ROM_BANK 		=> port_7ffd_reg(4)
);	

-- Video Spectrum/Pentagon
U6: entity work.video
generic map (
	enable_turbo 	=> enable_turbo
)
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
	ATTR_O 			=> vid_attr, 
	A 					=> vid_a_bus,
	
	DS80 				=> ds80,
	PALETTE_EN 		=> palette_en,
	CS7E				=> cs_xx7e,
	PORT7E 			=> port_xx7e_reg,
	PORTFE 			=> port_xxfe_reg,
	BUS_D 			=> cpu_do_bus,
	BUS_A 			=> cpu_a_bus(15 downto 8),
	BUS_WR_N 		=> cpu_wr_n,
	GX0 				=> gx0,
	
	VIDEO_R 			=> vid_rgb(8 downto 6),
	VIDEO_G 			=> vid_rgb(5 downto 3),
	VIDEO_B 			=> vid_rgb(2 downto 0),
	
	HSYNC 			=> vid_hsync,
	VSYNC 			=> vid_vsync,
	CSYNC 			=> open,

	VBUS_MODE 		=> vbus_mode,
	VID_RD 			=> vid_rd,
	
	HCNT 				=> vid_hcnt,
	VCNT 				=> vid_vcnt
);
	
-- osd (debug)
U7: entity work.osd
port map (
	CLK 				=> clk_bus,
	EN 				=> '0',
	RGB_I 			=> vid_rgb,
	RGB_O 			=> vid_rgb_osd,
	HCNT_I 			=> vid_hcnt,
	VCNT_I 			=> vid_vcnt,

	PORT_1 			=> cpld_do,
	PORT_2 			=> port_7ffd_reg,
	PORT_3 			=> cpu_rd_n & cpu_wr_n & cpu_iorq_n & cpu_mreq_n & vbus_mode & vid_rd & SRAM_NRD & SRAM_NWR,
	PORT_4 			=> cpld_oe_n & ds80 & cpm & rom14 & fdd_oe_n & hdd_oe_n & port_nreset & '0' --cpld_do	
);
	
---- Scan doubler
--U8 : entity work.scan_convert
--port map (
--	I_VIDEO			=> vid_rgb_osd,
--	I_HSYNC			=> vid_hsync,
--	I_VSYNC			=> vid_vsync,
--	O_VIDEO(8 downto 6)	=> VGA_R,
--	O_VIDEO(5 downto 3)	=> VGA_G,
--	O_VIDEO(2 downto 0)	=> VGA_B,
--	O_HSYNC			=> VGA_HS,
--	O_VSYNC			=> VGA_VS,
--	MODE				=> ds80,
--	CLK				=> vga_clk_x,
--	CLK2 				=> vga_clk_2x,
--	CLK_x2			=> vga_clko_2x);
	
U8: entity work.vga_pal 
port map (
	RGB_IN 			=> vid_rgb_osd,
	KSI_IN 			=> vid_vsync,
	SSI_IN 			=> vid_hsync,
	CLK 				=> not clk_div2,
	CLK2 				=> not clk_bus,
	DS80				=> ds80,
	
	INVERSE_KSI 	=> '1',
	INVERSE_SSI 	=> '1',
	INVERSE_F 		=> '1',
	
	RGB_O(8 downto 6)	=> VGA_R,
	RGB_O(5 downto 3)	=> VGA_G,
	RGB_O(2 downto 0)	=> VGA_B,
	VSYNC_VGA		=> VGA_VS,
	HSYNC_VGA		=> VGA_HS
);

-- Loader
U9: entity work.loader
port map(
	CLK 				=> clk_bus,
	RESET 			=> areset,

	RAM_A 			=> loader_ram_a,
	RAM_DO 			=> loader_ram_do,
	RAM_WR 			=> loader_ram_wr,
	RAM_RD 			=> loader_ram_rd,

	DATA0				=> DATA0,
	NCSO				=> flash_ncs,
	DCLK				=> flash_clk,
	ASDO				=> flash_do,

	LOADER_ACTIVE 	=> loader_act,
	LOADER_RESET 	=> loader_reset
);	
	
-- Z-Controller
U10: entity work.zcontroller
port map (
	RESET				=> not cpu_reset_n,
	CLK				=> clk_div4,
	A					=> cpu_a_bus(5),
	DI					=> cpu_do_bus,
	DO					=> zc_do_bus,
	RD					=> zc_rd,
	WR					=> zc_wr,
	SDDET				=> '0',
	SDPROT			=> '0',
	CS_n				=> zc_cs_n,
	SCLK				=> zc_sclk,
	MOSI				=> zc_mosi,
	MISO				=> DATA0);
	
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

-- Soundrive
U12: entity work.soundrive
port map (
	I_RESET			=> reset,
	I_CLK				=> clk_bus,
	I_CS				=> '1',
	I_WR_N			=> cpu_wr_n,
	I_ADDR			=> cpu_a_bus(7 downto 0),
	I_DATA			=> cpu_do_bus,
	I_IORQ_N			=> cpu_iorq_n,
	I_DOS				=> dos_act,
	O_COVOX_A		=> covox_a,
	O_COVOX_B		=> covox_b,
	O_COVOX_C		=> covox_c,
	O_COVOX_D		=> covox_d);
	 
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

-------------------------------------------------------------------------------
-- AVR Keyboard / mouse / rtc

U14: entity work.cpld_kbd
port map (
	 CLK 				=> clk_bus,
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
	 
	 RTC_A 			=> mc146818_a_bus,
	 RTC_DI 			=>	cpu_do_bus,
	 RTC_DO 			=>	mc146818_do_bus,
	 RTC_WR_N 		=> not mc146818_wr,

	 RESET 			=> kb_reset,
	 TURBO 			=> kb_turbo,
	 MAGICK 			=> kb_magic,
	 
	 JOY 				=> joy_bus
);
	
-------------------------------------------------------------------------------
-- I2S sound

U15: entity work.tda1543
port map (
	RESET				=> reset,
	CLK 				=> clk_8,
	CS 				=> '1',
	DATA_L 			=> audio_l,
	DATA_R 			=> audio_r,
	BCK 				=> SND_BS,
	WS  				=> SND_WS,
	DATA 				=> SND_DAT
);

-------------------------------------------------------------------------------
-- FDD / HDD controllers

U16: entity work.bus_port
port map (
	CLK 				=> clk_bus,
	CLK2 				=> clk_8,
	CLK_BUS 			=> clk_bus,
	CLK_CPU 			=> cpuclk,
	RESET 			=> reset,
	
	SD 				=> SD,
	SA 				=> SA,
	SDIR 				=> SDIR,
	CPLD_CLK 		=> CPLD_CLK,
	CPLD_CLK2 		=> CPLD_CLK2,
	NRESET 			=> NRESET,

	BUS_A 			=> cpu_a_bus,
	BUS_DI 			=> cpu_do_bus,
	BUS_DO 			=> cpld_do,
	OE_N 				=> cpld_oe_n,
	BUS_RD_N 		=> cpu_rd_n,
	BUS_WR_N 		=> cpu_wr_n,
	BUS_MREQ_N 		=> cpu_mreq_n,
	BUS_IORQ_N 		=> cpu_iorq_n,
	BUS_M1_N 		=> cpu_m1_n,
	BUS_CPM 			=> cpm,
	BUS_DOS 			=> dos_act,
	BUS_ROM14 		=> rom14,
	
	FDD_OE_N 		=> fdd_oe_n,
	HDD_OE_N 		=> hdd_oe_n,
	PORT_NRESET 	=> port_nreset
);

-- UART (via AY port A)
U17: entity work.ay_uart 
port map(
	CLK_I 			=> clk_bus,
	RESET_I 			=> reset,
	EN_I 				=> clk_div16,
	BDIR_I 			=> ay_bdir,
	BC_I 				=> ay_bc1,			
	CS_I 				=> ay_port,
	DATA_I 			=> cpu_do_bus,
	DATA_O 			=> uart_do_bus,
	OE_N 				=> uart_oe_n,
	UART_TX 			=> UART_TX,
	UART_RX 			=> UART_RX,
	UART_RTS 		=> UART_CTS
);

U18: entity work.altrom0
port map(
	clock => clk_bus,
	address => cpu_a_bus(13 downto 0),
	q => rom_do_bus
);
	
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

vga_clk_x 	<= clk_div4 when ds80 = '0' else clk_div2; -- 7/12
vga_clk_2x 	<= clk_div2 when ds80 = '0' else clk_bus;	 -- 14/24
vga_clko_2x <= clk_div2 when ds80 = '0' else clk_28;   -- 14/28
	
-------------------------------------------------------------------------------
-- Global signals

areset <= not locked or kb_magic; -- global reset
reset <= areset or kb_reset or not(locked) or loader_reset or loader_act; -- hot reset

cpu_reset_n <= not(reset) and not(loader_reset); -- CPU reset
cpu_inta_n <= cpu_iorq_n or cpu_m1_n;	-- INTA
cpu_nmi_n <= '0' when kb_magic = '1' else '1'; -- NMI
cpu_wait_n <= '1'; -- WAIT
cpuclk <= clk_bus and ena_div8;

-------------------------------------------------------------------------------
-- SD

SD_NCS	<= '1' when loader_act = '1' else zc_cs_n;
sd_clk 	<= zc_sclk;
sd_si 	<= zc_mosi;

-- share SPI between flash and SD
DCLK <= flash_clk when loader_act = '1' else sd_clk;
ASDO <= flash_do when loader_act = '1' else sd_si;
NCSO <= flash_ncs;

-------------------------------------------------------------------------------
-- Ports

-- #FD port correction
-- IN A, (#FD) - read a value from a hardware port 
-- OUT (#FD), A - writes the value of the second operand into the port given by the first operand.
fd_sel <= '0' when (
	(cpu_do_bus(7 downto 4) = "1101" and cpu_do_bus(2 downto 0) = "011") or 
	(cpu_di_bus(7 downto 4) = "1101" and cpu_di_bus(2 downto 0) = "011")) else '1'; 

-- TODO
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

cs_xxfe <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(0) = '0' else '0';
--cs_xxfe <= '1' when cpu_iorq_n = '0' and cpu_a_bus(0) = '0' else '0';
cs_xxff <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(7 downto 0) = X"FF" else '0';
cs_eff7 <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"EFF7" else '0';
cs_dff7 <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"DFF7" and port_eff7_reg(7) = '1' else '0';
cs_fffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"FFFD" and fd_port = '1' else '0';
cs_1ffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"1FFD" and fd_port = '1' else '0';
cs_dffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"DFFD" and fd_port = '1' else '0';
cs_7ffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"7FFD" else '0';
cs_xxfd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(15) = '0' and cpu_a_bus(1) = '0' and fd_port = '0' else '0';
cs_xx7e <= '1' when cs_xxfe = '1' and cpu_a_bus(7) = '0' and port_dffd_reg(7) = '1' else '0';

process (reset, areset, clk_bus, cpu_a_bus, dos_act, cs_xxfe, cs_eff7, cs_dff7, cs_7ffd, cs_1ffd, cs_xxfd, port_7ffd_reg, port_1ffd_reg, cpu_mreq_n, cpu_m1_n, cpu_wr_n, cpu_do_bus, fd_port)
begin
	if reset = '1' then
		u25 <= '1';
		port_eff7_reg <= (others => '0');
		port_7ffd_reg <= (others => '0');
		port_dffd_reg <= (others => '0');
		port_1ffd_reg <= (others => '0');
		dos_act <= '1';
	elsif clk_bus'event and clk_bus = '1' then

		if ena_div2 = '1' and ena_div4 = '1' then -- захват портов при 7МГц ena
	
			if cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(15)='0' and cpu_a_bus(1) = '0' and port_dffd_reg(5) = '0' then 
				u25 <= cpu_do_bus(4);
			end if;
		
			-- #FE
			if cs_xxfe = '1' and cpu_wr_n = '0' then 
				port_xxfe_reg <= cpu_do_bus; 
			end if;
			
			-- #7E
			if cs_xx7e = '1' and cpu_wr_n = '0' then 
				port_xx7e_reg <= cpu_do_bus;
			end if;

			-- #EFF7
			if cs_eff7 = '1' and cpu_wr_n = '0' then 
				port_eff7_reg <= cpu_do_bus; 
			end if;
			
			-- #DFF7
			if cs_dff7 = '1' and cpu_wr_n = '0' then 
				mc146818_a_bus <= cpu_do_bus(5 downto 0); 
			end if;

			-- #1FFD
			if cs_1ffd = '1' and cpu_wr_n = '0' then
				port_1ffd_reg <= cpu_do_bus;
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
			
			if port_dffd_reg(5) = '1' then u25 <= '0'; end if;
			
			-- TR-DOS FLAG
			if cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 8) = X"3D" and u25 = '1' and port_dffd_reg(5) = '0' then dos_act <= '1';
			elsif ((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00") or (port_dffd_reg(5) = '1')) then dos_act <= '0'; end if;
			
		end if;
				
	end if;
end process;

-------------------------------------------------------------------------------
-- Audio mixer

speaker <= port_xxfe_reg(4);
audio_l <= "0000000000000000" when loader_act = '1' else ("000" & speaker & "000000000000") + ("000" & ssg_cn0_a & "00000") + ("000" & ssg_cn0_b & "00000") + ("000" & ssg_cn1_a & "00000") + ("000" & ssg_cn1_b & "00000") + ("000" & covox_a   & "00000") + ("000" & covox_b   & "00000") + ("000" & saa_out_l & "00000");
audio_r <= "0000000000000000" when loader_act = '1' else ("000" & speaker & "000000000000") + ("000" & ssg_cn0_c & "00000") + ("000" & ssg_cn0_b & "00000") + ("000" & ssg_cn1_c & "00000") + ("000" & ssg_cn1_b & "00000") + ("000" & covox_c   & "00000") + ("000" & covox_d   & "00000") + ("000" & saa_out_r & "00000");

-- SAA1099
saa_wr_n <= '0' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = "11111111" and dos_act = '0') else '1';

-------------------------------------------------------------------------------
-- Port I/O

mc146818_wr <= '1' when (port_bff7 = '1' and cpu_wr_n = '0') else '0';
port_bff7 	<= '1' when (cpu_iorq_n = '0' and cpu_a_bus = X"BFF7" and cpu_m1_n = '1' and port_eff7_reg(7) = '1') else '0';
zc_wr 		<= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else '0';
zc_rd 		<= '1' when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else '0';

ay_port 		<= '1' when cpu_a_bus(7 downto 0) = x"FD" and cpu_a_bus(15)='1' and fd_port = '1' else '0';
ay_bdir 		<= '1' when ay_port = '1' and cpu_iorq_n = '0' and cpu_wr_n = '0' else '0';
ay_bc1 		<= '1' when ay_port = '1' and cpu_a_bus(14) = '1' and cpu_iorq_n = '0' and (cpu_wr_n='0' or cpu_rd_n='0') else '0';

-------------------------------------------------------------------------------
-- CPU0 Data bus

process (selector, ram_do_bus, mc146818_do_bus, kb_do_bus, zc_do_bus, ssg_cn0_bus, ssg_cn1_bus, port_7ffd_reg, port_dffd_reg, uart_do_bus, cpld_do, vid_attr, port_eff7_reg, port_1ffd_reg, joy_bus, ms_z, ms_b, ms_x, ms_y)
begin
	case selector is
		when x"00" => 
			if (cpu_a_bus(15 downto 14) = "00" and enable_diag_rom) then 
				cpu_di_bus <= rom_do_bus;
			else
				cpu_di_bus <= ram_do_bus;
			end if;	
--		when x"01" => cpu_di_bus <= mc146818_do_bus;
		when x"02" => cpu_di_bus <= GX0 & "1" & kb_do_bus;
		when x"03" => cpu_di_bus <= zc_do_bus;
		when x"04" => cpu_di_bus <= "000" & joy_bus;
		when x"05" => cpu_di_bus <= ssg_cn0_bus;
		when x"06" => cpu_di_bus <= ssg_cn1_bus;
		when x"07" => cpu_di_bus <= port_dffd_reg;
		when x"08" => cpu_di_bus <= port_7ffd_reg;
		when x"09" => cpu_di_bus <= ms_z(3 downto 0) & '1' & not ms_b(2) & not ms_b(0) & not ms_b(1);
		when x"0A" => cpu_di_bus <= ms_x;
		when x"0B" => cpu_di_bus <= ms_y;
		when x"0C" => cpu_di_bus <= uart_do_bus;
--		when x"0D" => cpu_di_bus <= vid_attr;
		when others => cpu_di_bus <= cpld_do;
	end case;
end process;

selector <= 
	x"00" when (ram_oe_n = '0') else -- ram / rom
--	x"01" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and port_bff7 = '1' and port_eff7_reg(7) = '1') else -- MC146818A
	x"02" when (cs_xxfe = '1' and cpu_rd_n = '0') else 									-- Keyboard, port #FE
	x"03" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus( 7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111" and cpm='0') else 	-- Z-Controller
	x"04" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus( 7 downto 0) = X"1F" and dos_act = '0' and cpm = '0') else -- Joystick, port #1F
	x"05" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '0') else 			-- TurboSound
	x"06" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '1') else
	x"07" when (cs_dffd = '1' and cpu_rd_n = '0') else										-- port #DFFD
	x"08" when (cs_7ffd = '1' and cpu_rd_n = '0') else										-- port #7FFD
	x"09" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FADF") else	-- Mouse0 port key, z
	x"0A" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FBDF") else	-- Mouse0 port x
	x"0B" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FFDF") else	-- Mouse0 port y 
	x"0C" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and uart_oe_n = '0') else 																-- AY UART
--	x"0D" when (cs_xxff = '1' and cpu_rd_n = '0' and dos_act = '0' and cpm = '0') else 			-- port #FF
	(others => '1');
	
-- debug 
--PIN_141 <= cpuclk;
--PIN_138 <= clk_bus;
--PIN_121 <= reset;
--PIN_120 <= areset;
--PIN_119 <= VGA_HS;
--PIN_115 <= VGA_VS;
palette_en <= not kb_turbo;
	
end rtl;
