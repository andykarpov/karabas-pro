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
port (
	-- Clock (50MHz)
	CLK_50MHZ: in std_logic;

	-- SRAM (2MB 2x8bit)
	SRAM_D	: inout std_logic_vector(7 downto 0);
	SRAM_A	: out std_logic_vector(20 downto 0);
	SRAM_NWR	: out std_logic;
	SRAM_NRD	: out std_logic;
	
	-- SPI FLASH (M25P16)
	DATA0		: in std_logic;  -- MISO
	NCSO		: out std_logic; -- /CS 
	DCLK		: out std_logic; -- SCK
	ASDO		: out std_logic; -- MOSI
	
	-- SD/MMC Card
	SD_NCS		: out std_logic; -- /CS
	
	-- VGA 
	VGA_R 	: out std_logic_vector(2 downto 0);
	VGA_G 	: out std_logic_vector(2 downto 0);
	VGA_B 	: out std_logic_vector(2 downto 0);
	VGA_HS 	: out std_logic;
	VGA_VS 	: out std_logic;
		
	-- AVR SPI slave
	AVR_SCK 	: in std_logic;
	AVR_MOSI : in std_logic;
	AVR_MISO : out std_logic;
	AVR_NCS	: in std_logic;
	
	-- Parallel bus for CPLD
	NRESET 	: out std_logic;
	CPLD_CLK : out std_logic;
	CPLD_CLK2 : out std_logic;
	SDIR 		: out std_logic;
	SA			: out std_logic_vector(1 downto 0);
	SD			: inout std_logic_vector(15 downto 0);
	
	-- I2S Sound TDA1543
	SND_BS	: out std_logic;
	SND_WS 	: out std_logic;
	SND_DAT 	: out std_logic;
	
	-- Misc I/O
	PIN_141	: in std_logic;
	PIN_138 	: in std_logic;
	PIN_121	: in std_logic;
	PIN_120	: in std_logic;
	PIN_119	: in std_logic;
	PIN_115	: in std_logic;
		
	-- UART / ESP8266
	UART_RX 	: in std_logic;
	UART_TX 	: out std_logic;
	UART_CTS : out std_logic
	
);
end karabas_pro;

architecture rtl of karabas_pro is

-- CPU0
signal cpu0_reset_n	: std_logic;
signal cpu0_clk		: std_logic;
signal cpu0_a_bus	: std_logic_vector(15 downto 0);
signal cpu0_do_bus	: std_logic_vector(7 downto 0);
signal cpu0_di_bus	: std_logic_vector(7 downto 0);
signal cpu0_mreq_n	: std_logic;
signal cpu0_iorq_n	: std_logic;
signal cpu0_wr_n	: std_logic;
signal cpu0_rd_n	: std_logic;
signal cpu0_int_n	: std_logic;
signal cpu0_inta_n	: std_logic;
signal cpu0_m1_n	: std_logic;
signal cpu0_rfsh_n	: std_logic;
signal cpu0_ena		: std_logic;
signal cpu0_mult	: std_logic_vector(1 downto 0);
signal cpu0_mem_wr	: std_logic;
signal cpu0_mem_rd	: std_logic;
signal cpu0_nmi_n	: std_logic;
signal cpu0_wait_n : std_logic := '1';

-- Memory
signal ram_a_bus	: std_logic_vector(7 downto 0);

-- Port
signal port_xxfe_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_7ffd_reg	: std_logic_vector(7 downto 0);
signal port_1ffd_reg	: std_logic_vector(7 downto 0);
signal port_dffd_reg : std_logic_vector(7 downto 0);

-- Keyboard
signal kb_do_bus	: std_logic_vector(5 downto 0);
signal kb_reset : std_logic := '0';
signal kb_magic : std_logic := '0';
signal kb_special : std_logic := '0';
signal kb_turbo : std_logic := '0';

-- Joy
signal joy_bus : std_logic_vector(4 downto 0) := "11111";

-- Mouse
signal ms_x		: std_logic_vector(7 downto 0);
signal ms_y		: std_logic_vector(7 downto 0);
signal ms_z		: std_logic_vector(3 downto 0);
signal ms_b		: std_logic_vector(2 downto 0);

-- Video
signal vid_a_bus	: std_logic_vector(13 downto 0);
signal vid_di_bus	: std_logic_vector(7 downto 0);
signal vid_wr		: std_logic;
signal vid_scr		: std_logic;
signal vid_hsync	: std_logic;
signal vid_vsync	: std_logic;
signal vid_int		: std_logic;
signal vid_attr	: std_logic_vector(7 downto 0);
signal vid_rgb		: std_logic_vector(8 downto 0);
signal vid_rgb_osd : std_logic_vector(8 downto 0);
signal vid_border : std_logic_vector(2 downto 0);
signal vid_invert : std_logic;

signal vid_hcnt 	: std_logic_vector(8 downto 0);
signal vid_vcnt 	: std_logic_vector(8 downto 0);

signal vga_blank	: std_logic;

-- Z-Controller
signal zc_do_bus	: std_logic_vector(7 downto 0);
signal zc_rd		: std_logic;
signal zc_wr		: std_logic;
signal zc_cs_n		: std_logic;
signal zc_sclk		: std_logic;
signal zc_mosi		: std_logic;
signal zc_miso		: std_logic;

-- divmmc
signal divmmc_do	: std_logic_vector(7 downto 0);
signal divmmc_amap	: std_logic;
signal divmmc_e3reg	: std_logic_vector(7 downto 0);	
signal divmmc_cs_n	: std_logic;
signal divmmc_sclk	: std_logic;
signal divmmc_mosi	: std_logic;

-- MC146818A
signal mc146818_wr	: std_logic;
signal mc146818_a_bus	: std_logic_vector(5 downto 0);
signal mc146818_do_bus	: std_logic_vector(7 downto 0);
signal mc146818_busy		: std_logic;
signal port_bff7	: std_logic;
signal port_eff7_reg	: std_logic_vector(7 downto 0);
signal fd_port 	: std_logic;
signal fd_sel 		: std_logic;

signal cs_xxfe : std_logic := '0'; 
signal cs_xxff : std_logic := '0';
signal cs_eff7 : std_logic := '0';
signal cs_dff7 : std_logic := '0';
signal cs_7ffd : std_logic := '0';
signal cs_1ffd : std_logic := '0';
signal cs_dffd : std_logic := '0';
signal cs_fffd : std_logic := '0';
signal cs_xxfd : std_logic := '0';

-- SRAM
signal sram_a_bus  : std_logic_vector(20 downto 0);
signal sram_di_bus : std_logic_vector(7 downto 0);
signal sram_do_bus	: std_logic_vector(7 downto 0);
signal sram_wr		: std_logic;
signal sram_rd		: std_logic;

-- TurboSound
signal ssg_sel		: std_logic;
signal ssg_cn0_bus	: std_logic_vector(7 downto 0);
signal ssg_cn0_a	: std_logic_vector(7 downto 0);
signal ssg_cn0_b	: std_logic_vector(7 downto 0);
signal ssg_cn0_c	: std_logic_vector(7 downto 0);
signal ssg_cn1_bus	: std_logic_vector(7 downto 0);
signal ssg_cn1_a	: std_logic_vector(7 downto 0);
signal ssg_cn1_b	: std_logic_vector(7 downto 0);
signal ssg_cn1_c	: std_logic_vector(7 downto 0);
signal audio_l		: std_logic_vector(15 downto 0);
signal audio_r		: std_logic_vector(15 downto 0);
signal sound		: std_logic_vector(7 downto 0);

-- Soundrive
signal covox_a		: std_logic_vector(7 downto 0);
signal covox_b		: std_logic_vector(7 downto 0);
signal covox_c		: std_logic_vector(7 downto 0);
signal covox_d		: std_logic_vector(7 downto 0);

-- SAA1099
signal saa_wr_n		: std_logic;
signal saa_out_l	: std_logic_vector(7 downto 0);
signal saa_out_r	: std_logic_vector(7 downto 0);

-- CLOCK
signal clk_bus		: std_logic;
signal clk_cpld	: std_logic;
signal clk7			: std_logic;
signal clk14		: std_logic;
signal clk_saa 	: std_logic;

------------------------------------

signal ena_14mhz	: std_logic;
signal ena_7mhz		: std_logic;
signal ena_3_5mhz	: std_logic;
signal ena_1_75mhz	: std_logic;
signal ena_0_4375mhz	: std_logic;
signal ena_cnt		: std_logic_vector(5 downto 0);

-- System
signal reset		: std_logic;
signal areset		: std_logic;
signal locked		: std_logic;
signal loader_act	: std_logic := '1';
signal loader_reset : std_logic := '0';
signal dos_act		: std_logic := '1';
signal cpuclk		: std_logic;
signal selector		: std_logic_vector(7 downto 0);
signal mux		: std_logic_vector(3 downto 0);
signal ram_ext : std_logic_vector(3 downto 0) := "0000";
signal ram_ext_lock : std_logic_vector(1 downto 0) := "00";

-- Loader
signal loader_ram_di	: std_logic_vector(7 downto 0);
signal loader_ram_do	: std_logic_vector(7 downto 0);
signal loader_ram_a	: std_logic_vector(20 downto 0);
signal loader_ram_wr : std_logic;
signal loader_ram_rd : std_logic;

-- Host
signal host_ram_di	: std_logic_vector(7 downto 0);
signal host_ram_do	: std_logic_vector(7 downto 0);
signal host_ram_a	: std_logic_vector(20 downto 0);
signal host_ram_wr : std_logic;
signal host_ram_rd : std_logic;
signal host_vga_r : std_logic_vector(2 downto 0);
signal host_vga_g : std_logic_vector(2 downto 0);
signal host_vga_b : std_logic_vector(2 downto 0);
signal host_vga_hs : std_logic;
signal host_vga_vs : std_logic;
signal host_vga_sblank : std_logic;

-- UART 
signal uart_oe_n   : std_logic := '1';
signal uart_do_bus : std_logic_vector(7 downto 0);

-- ZXUNO ports
signal zxuno_regrd : std_logic;
signal zxuno_regwr : std_logic;
signal zxuno_addr : std_logic_vector(7 downto 0);
signal zxuno_regaddr_changed : std_logic;
signal zxuno_addr_oe_n : std_logic;
signal zxuno_addr_to_cpu : std_logic_vector(7 downto 0);

-- DivMMC / Z-Controller mode
signal sd_mode : std_logic := '0'; -- 0 = ZC, 1 = DivMMC

signal loader_ncs : std_logic;
signal loader_clk : std_logic;
signal loader_do : std_logic;
signal sd_clk : std_logic;
signal sd_si : std_logic;

-- ULA
signal rasterint_do_bus: std_logic_vector(7 downto 0);
signal rasterint_oe_n: std_logic;
signal rasterint_enable: std_logic;
signal vretraceint_disable: std_logic;
signal raster_line: std_logic_vector(8 downto 0);
signal raster_int_in_progress: std_logic;
signal cpu_contention : std_logic;
signal access_to_screen: std_logic;
signal tape_in : std_logic := '1';
signal tape_out : std_logic;
signal speaker: std_logic;
signal ioreqbank: std_logic;
signal ula_do_bus : std_logic_vector(7 downto 0);
signal timexcfg_reg : std_logic_vector(7 downto 0);
signal is_port_ff : std_logic := '0';

signal cpld_oe_n : std_logic := '1';
signal cpld_do : std_logic_vector(7 downto 0);
signal rom_a14 : std_logic;

component saa1099
port (
	clk_sys		: in std_logic;
	ce		: in std_logic;		--8 MHz
	rst_n		: in std_logic;
	cs_n		: in std_logic;
	a0		: in std_logic;		--0=data, 1=address
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

component rasterint_ctrl 
port (
    clk : in std_logic;
    rst_n : in std_logic;
    zxuno_addr : in std_logic_vector(7 downto 0);
    zxuno_regrd : in std_logic;
    zxuno_regwr : in std_logic;
    din : in std_logic_vector(7 downto 0);
    dout: out std_logic_vector(7 downto 0);
    oe_n : out std_logic;
    rasterint_enable : out std_logic;
    vretraceint_disable : out std_logic;
    raster_line : out std_logic_vector(8 downto 0);
    raster_int_in_progress: in std_logic);
end component;

component pal_sync_generator 
port (
    clk : in std_logic;
    mode : in std_logic_vector(1 downto 0);   -- 00: 48K, 01: 128K, 10: Pentagon, 11: Reserved

    rasterint_enable : in std_logic;
    vretraceint_disable : in std_logic;
    raster_line : in std_logic_vector(8 downto 0);
    raster_int_in_progress: out std_logic;
    csync_option: in std_logic;
    
    hinit48k: in std_logic_vector(8 downto 0);
    vinit48k: in std_logic_vector(8 downto 0);
    hinit128k: in std_logic_vector(8 downto 0);
    vinit128k: in std_logic_vector(8 downto 0);
    hinitpen: in std_logic_vector(8 downto 0);
    vinitpen: in std_logic_vector(8 downto 0);
    
    ri: in std_logic_vector(2 downto 0);
    gi: in std_logic_vector(2 downto 0);
    bi: in std_logic_vector(2 downto 0);
    hcnt: out std_logic_vector(8 downto 0);
    vcnt: out std_logic_vector(8 downto 0);
    ro: out std_logic_vector(2 downto 0);
    go: out std_logic_vector(2 downto 0);
    bo: out std_logic_vector(2 downto 0);
    hsync: out std_logic;
    vsync: out std_logic;
    csync: out std_logic;
    int_n: out std_logic);
end component;

component ula_radas
port (
    clk28: in std_logic;
    clkregs: in std_logic;  -- clock to load registers
    clk14: in std_logic;    -- 14MHz master clock
    clk7: in std_logic;
    cpuclk: in std_logic;
    CPUContention: out std_logic;
    rst_n: in std_logic;  -- reset para volver al modo normal

	 -- CPU
    a : in std_logic_vector(15 downto 0);
    mreq_n : in std_logic;
    iorq_n : in std_logic;
    rd_n : in std_logic;
    wr_n : in std_logic;
    int_n : out std_logic;
    din: in std_logic_vector(7 downto 0);
    dout: out std_logic_vector(7 downto 0);
    rasterint_enable : in std_logic;
    vretraceint_disable : in std_logic;
    raster_line: in std_logic_vector(8 downto 0);
    raster_int_in_progress: out std_logic;
    
	 -- VRAM 
    va: out std_logic_vector(13 downto 0);  -- 16KB videoram
    vramdata: in std_logic_vector(7 downto 0);

    -- ZX-UNO register interface
    zxuno_addr: in std_logic_vector(7 downto 0);
    zxuno_regrd: in std_logic;
    zxuno_regwr: in std_logic;
    regaddr_changed: in std_logic;

    -- I/O ports
    ear: in std_logic;
    kbd: in std_logic_vector(4 downto 0);
    mic: out std_logic;
    spk: out std_logic;
    issue2_keyboard: in std_logic;
    mode: in std_logic_vector(1 downto 0);
    
	 ioreqbank: in std_logic;
    disable_contention: in std_logic;
    access_to_contmem: in std_logic;
    doc_ext_option: out std_logic;
    enable_timexmmu: in std_logic;
    disable_timexscr: in std_logic;
    disable_ulaplus: in std_logic;
    disable_radas: in std_logic;
    csync_option: in std_logic;

    -- Video
    r: out std_logic_vector(2 downto 0);
    g: out std_logic_vector(2 downto 0);
    b: out std_logic_vector(2 downto 0);
    hsync: out std_logic;
    vsync: out std_logic;
    csync: out std_logic;
    y_n: out std_logic;
	 
	 hcnt_o : out std_logic_vector(8 downto 0);
	 vcnt_o : out std_logic_vector(8 downto 0);
	 invert_o : out std_logic;
	 trdos_active : in std_logic;
	 debug: out std_logic_vector(7 downto 0));
end component;

component vga_scandoubler 
port (
	 clkvideo : in std_logic;
	 clkvga: in std_logic;
    enable_scandoubling : in std_logic;
    disable_scaneffect: in std_logic;  -- 1 to disable scanlines
	 ri: in std_logic_vector(2 downto 0);
	 gi: in std_logic_vector(2 downto 0);
	 bi: in std_logic_vector(2 downto 0);
	 hsync_ext_n: in std_logic;
	 vsync_ext_n: in std_logic;
	 csync_ext_n: in std_logic;
	 ro: out std_logic_vector(2 downto 0);
	 go: out std_logic_vector(2 downto 0);
	 bo: out std_logic_vector(2 downto 0);
	 hsync : out std_logic;
	 vsync : out std_logic;
	 blank: out std_logic
   );
end component;

begin

-- PLL
U0: entity work.altpll0
port map (
	inclk0			=> CLK_50MHZ,	--  50.0 MHz
	locked			=> locked,
	c0					=> clk_bus,		--  28.0 MHz
	c1					=> clk7,			--   7.0 MHz
	c2					=> clk14,		--  14.0 MHz
--	c3					=> open,	--  84.0 MHz
	c4					=> open);	-- 140.0 MHz
	
-- PLL2
U00: entity work.altpll1
port map (
	inclk0			=> CLK_50MHZ,	--  50.0 MHz
	locked 			=> open,
	c0					=> clk_cpld,	-- 84.0 MHz (28 x 3)
	c1 				=> clk_saa);	--  8.0 MHz	
	
-- Zilog Z80A CPU
U1: entity work.T80se
generic map (
	Mode		=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	T2Write		=> 1,	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
	IOWait		=> 1 )	-- 0 => Single cycle I/O, 1 => Std I/O cycle

port map (
	RESET_n		=> cpu0_reset_n,
	CLK_n		=> clk_bus,
	ENA		=> cpuclk,
	WAIT_n		=> cpu0_wait_n,
	INT_n		=> cpu0_int_n,
	NMI_n		=> cpu0_nmi_n,
	BUSRQ_n		=> '1',
	M1_n		=> cpu0_m1_n,
	MREQ_n		=> cpu0_mreq_n,
	IORQ_n		=> cpu0_iorq_n,
	RD_n		=> cpu0_rd_n,
	WR_n		=> cpu0_wr_n,
	RFSH_n		=> cpu0_rfsh_n,
	HALT_n		=> open,--cpu_halt_n,
	BUSAK_n		=> open,--cpu_basak_n,
	A		=> cpu0_a_bus,
	DI		=> cpu0_di_bus,
	DO		=> cpu0_do_bus);
	
-- Loader
U2: entity work.loader
port map(
	CLK 				=> clk_bus,
	RESET 			=> areset,

	RAM_A 			=> loader_ram_a,
	RAM_DI 			=> loader_ram_di,
	RAM_DO 			=> loader_ram_do,
	RAM_WR 			=> loader_ram_wr,
	RAM_RD 			=> loader_ram_rd,

	DATA0				=> DATA0,
	NCSO				=> loader_ncs,
	DCLK				=> loader_clk,
	ASDO				=> loader_do,

	LOADER_ACTIVE 	=> loader_act,
	LOADER_RESET 	=> loader_reset
);	
	
-- Video Spectrum/Pentagon
U3: entity work.video
port map (
	CLK				=> clk_bus,
	ENA7				=> ena_7mhz,
	ENA14 			=> ena_14mhz,
	INT				=> cpu0_int_n,
	INTA				=> cpu0_inta_n,
	BORDER			=> vid_border,
	TIMEXCFG 		=> timexcfg_reg,
	TURBO 			=> not(cpu0_mult(0)),
	ATTR_O			=> vid_attr,
	A					=> vid_a_bus,
	DI					=> vid_di_bus,
	BLANK 			=> open,
	RGB				=> vid_rgb,
	HSYNC				=> vid_hsync,
	VSYNC				=> vid_vsync,
	INVERT_O 		=> vid_invert,
	HCNT_O 			=> vid_hcnt,
	VCNT_O			=> vid_vcnt
);
	
U3_1: entity work.osd
port map (
	CLK 	=> clk_bus,
	EN 	=> '1',
	RGB_I => vid_rgb,
	RGB_O => vid_rgb_osd,
	HCNT_I => vid_hcnt,
	VCNT_I => vid_vcnt,
	PORT_1 => port_1ffd_reg,
	PORT_2 => divmmc_e3reg,
	PORT_3 => port_7ffd_reg,
	PORT_4 => timexcfg_reg	
);
	
-- Video memory
U4: entity work.altram1
port map (
	clock_a			=> clk_bus,
	clock_b			=> clk_bus,
	address_a		=> vid_scr & cpu0_a_bus(12 downto 0),
	address_b		=> port_7ffd_reg(3) & vid_a_bus(12 downto 0),
	data_a			=> cpu0_do_bus,
	data_b			=> "11111111",
	q_a				=> open,
	q_b				=> vid_di_bus,
	wren_a			=> vid_wr,
	wren_b			=> '0');
	
-- Z-Controller
U6: entity work.zcontroller
port map (
	RESET				=> not cpu0_reset_n,
	CLK				=> clk_bus,
	A					=> cpu0_a_bus(5),
	DI					=> cpu0_do_bus,
	DO					=> zc_do_bus,
	RD					=> zc_rd,
	WR					=> zc_wr,
	SDDET				=> '0', --SD_NDET,
	SDPROT			=> '0',
	CS_n				=> zc_cs_n,
	SCLK				=> zc_sclk,
	MOSI				=> zc_mosi,
	MISO				=> DATA0);
	
-- divmmc interface
U18: entity work.divmmc
port map (
	CLK		=> clk_bus,
	EN		=> sd_mode,
	RESET		=> not cpu0_reset_n,
	ADDR		=> cpu0_a_bus,
	DI		=> cpu0_do_bus,
	DO		=> divmmc_do,
	WR_N		=> cpu0_wr_n,
	RD_N		=> cpu0_rd_n,
	IORQ_N		=> cpu0_iorq_n,
	MREQ_N		=> cpu0_mreq_n,
	M1_N		=> cpu0_m1_n,
--	I_RFSH_N		=> cpu0_rfsh_n,
	E3REG		=> divmmc_e3reg,
	AMAP		=> divmmc_amap,
	
	CS_N		=> divmmc_cs_n,
	SCLK		=> divmmc_sclk,
	MOSI		=> divmmc_mosi,
	MISO		=> DATA0);
	
-- TurboSound
U7: entity work.turbosound
port map (
	I_CLK		=> clk_bus,
	I_ENA		=> ena_1_75mhz,
	I_ADDR		=> cpu0_a_bus,
	I_DATA		=> cpu0_do_bus,
	I_WR_N		=> cpu0_wr_n,
	I_IORQ_N	=> cpu0_iorq_n,
	I_M1_N		=> cpu0_m1_n,
	I_RESET_N	=> cpu0_reset_n,
	O_SEL		=> ssg_sel,
	-- ssg0
	O_SSG0_DA	=> ssg_cn0_bus,
	O_SSG0_AUDIO_A	=> ssg_cn0_a,
	O_SSG0_AUDIO_B	=> ssg_cn0_b,
	O_SSG0_AUDIO_C	=> ssg_cn0_c,
	-- ssg1
	O_SSG1_DA	=> ssg_cn1_bus,
	O_SSG1_AUDIO_A	=> ssg_cn1_a,
	O_SSG1_AUDIO_B	=> ssg_cn1_b,
	O_SSG1_AUDIO_C	=> ssg_cn1_c);

-- Soundrive
U10: entity work.soundrive
port map (
	I_RESET		=> reset,
	I_CLK		=> clk_bus,
	I_CS		=> '1',
	I_WR_N		=> cpu0_wr_n,
	I_ADDR		=> cpu0_a_bus(7 downto 0),
	I_DATA		=> cpu0_do_bus,
	I_IORQ_N	=> cpu0_iorq_n,
	I_DOS		=> dos_act,
	O_COVOX_A	=> covox_a,
	O_COVOX_B	=> covox_b,
	O_COVOX_C	=> covox_c,
	O_COVOX_D	=> covox_d);
	 
-- Scan doubler
U13 : entity work.scan_convert
port map (
	I_VIDEO			=> vid_rgb_osd,
	I_HSYNC			=> vid_hsync,
	I_VSYNC			=> vid_vsync,
	O_VIDEO(8 downto 6)	=> host_vga_r,
	O_VIDEO(5 downto 3)	=> host_vga_g,
	O_VIDEO(2 downto 0)	=> host_vga_b,
	O_HSYNC			=> host_vga_hs,
	O_VSYNC			=> host_vga_vs,
	O_CMPBLK_N		=> host_vga_sblank,
	CLK				=> clk14,
	CLK_x2			=> clk_bus);
	
--U13: vga_scandoubler 
--port map(
--	clkvideo => clk14,
--	clkvga => clk_bus,
--   enable_scandoubling => '1',
--   disable_scaneffect => '1',  -- 1 to disable scanlines
--	ri => vid_rgb_osd(8 downto 6),
--	gi => vid_rgb_osd(5 downto 3),
--	bi => vid_rgb_osd(2 downto 0),
--	hsync_ext_n => vid_hsync,
--	vsync_ext_n => vid_vsync,
--   csync_ext_n => not (vid_hsync xor vid_vsync),
--	ro => host_vga_r,
--	go => host_vga_g,
--	bo => host_vga_b,
--	hsync => host_vga_hs,
--	vsync => host_vga_vs, 
--	blank => host_vga_sblank
--   );
--	

U15: saa1099
port map(
	clk_sys		=> clk_saa,
	ce		=> '1',			-- 8 MHz
	rst_n		=> not reset,
	cs_n		=> '0',
	a0		=> cpu0_a_bus(8),		-- 0=data, 1=address
	wr_n		=> saa_wr_n,
	din		=> cpu0_do_bus,
	out_l		=> saa_out_l,
	out_r		=> saa_out_r);
	
-- UART (via ZX UNO ports #FC3B / #FD3B) 
U16: zxunoregs 
port map(
	clk => clk_bus, -- todo
	rst_n => cpu0_reset_n,
	a => cpu0_a_bus,
	iorq_n => cpu0_iorq_n,
	rd_n => cpu0_rd_n,
	wr_n => cpu0_wr_n,
	din => cpu0_do_bus,
	dout => zxuno_addr_to_cpu,
	oe_n => zxuno_addr_oe_n,
	addr => zxuno_addr,
	read_from_reg => zxuno_regrd,
	write_to_reg => zxuno_regwr,
	regaddr_changed => zxuno_regaddr_changed);

U17: zxunouart 
port map(
	clk => clk7,
	zxuno_addr => zxuno_addr,
	zxuno_regrd => zxuno_regrd,
	zxuno_regwr => zxuno_regwr,
	din => cpu0_do_bus,
	dout => uart_do_bus,
	oe_n => uart_oe_n,
	uart_tx => UART_TX,
	uart_rx => UART_RX,
	uart_rts => UART_CTS);
	
--U19: rasterint_ctrl
--port map(
--	clk => clk_bus,
--	rst_n => cpu0_reset_n,
--	zxuno_addr => zxuno_addr,
--	zxuno_regrd => zxuno_regrd,
--	zxuno_regwr => zxuno_regwr,
--	din => cpu0_do_bus,
--	dout => rasterint_do_bus,
--	oe_n => rasterint_oe_n,
--	rasterint_enable => rasterint_enable,
--	vretraceint_disable => vretraceint_disable,
--	raster_line => raster_line,
--	raster_int_in_progress => raster_int_in_progress
--);
--
--U20: ula_radas 
--port map(
--	clk28 => clk_bus,
--	clkregs => clk_bus,
--	clk14 => clk14,
--	clk7 => clk7,
--	cpuclk => cpuclk,
--	CPUContention => cpu_contention,
--	rst_n => cpu0_reset_n,
--	
--	a => cpu0_a_bus,
--	mreq_n => cpu0_mreq_n,
--	iorq_n => cpu0_iorq_n,
--	rd_n => cpu0_rd_n,
--	wr_n => cpu0_wr_n,
--	int_n => cpu0_int_n,
--	din => cpu0_do_bus,
--	dout => ula_do_bus,
--	rasterint_enable => rasterint_enable,
--	vretraceint_disable => vretraceint_disable,
--	raster_line => raster_line,
--	raster_int_in_progress => raster_int_in_progress,
--	
--	va => vid_a_bus,
--	vramdata => vid_di_bus,
--	
--	zxuno_addr => zxuno_addr,
--	zxuno_regrd => zxuno_regrd,
--	zxuno_regwr => zxuno_regwr,
--	regaddr_changed => zxuno_regaddr_changed,
--	
--	ear => tape_in,
--	kbd => kb_do_bus,
--	mic => tape_out,
--	spk => speaker,	
--	issue2_keyboard => '0',
--	mode => "10", -- pentagon
--	ioreqbank => ioreqbank,
--	disable_contention => '1',
--	access_to_contmem => '0',
--	doc_ext_option => open,
--	enable_timexmmu => '1', -- ???? need more ext ram somehow mapped (see new_memory.v)
--	disable_timexscr => '0',
--	disable_ulaplus => '0',
--	disable_radas => '0',
--	csync_option => '1', -- todo ?
--	
--	r => vid_rgb(8 downto 6),
--	g => vid_rgb(5 downto 3),
--	b => vid_rgb(2 downto 0),
--	
--	hsync => vid_hsync,
--	vsync => vid_vsync,
--	csync => open,
--	y_n => open,
--	
--	hcnt_o => vid_hcnt,
--	vcnt_o => vid_vcnt,
--	invert_o => vid_invert,
--	trdos_active => dos_act,
--	debug => timexcfg_reg
--);
--
--ioreqbank <= '1' when (cpu0_iorq_n = '0' and (cpu0_wr_n = '0' or cpu0_rd_n = '0') and cs_7ffd = '1') else '0';

	
-------------------------------------------------------------------------------
-- Global signals

process (clk_bus)
begin
	if clk_bus'event and clk_bus = '0' then
		ena_cnt <= ena_cnt + 1;
	end if;
end process;

ena_14mhz <= ena_cnt(0);
ena_7mhz <= ena_cnt(1) and ena_cnt(0);
ena_3_5mhz <= ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_1_75mhz <= ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
ena_0_4375mhz <= ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);

areset <= not locked;					 -- global reset
reset <= areset or kb_reset or not(locked) or loader_reset or loader_act; -- hot reset

sd_mode <= '1' when kb_special = '1' else '0';

cpu0_reset_n <= not(reset) and not(loader_reset);					-- CPU reset
cpu0_inta_n <= cpu0_iorq_n or cpu0_m1_n;	-- INTA
cpu0_nmi_n <= '0' when kb_magic = '1' else '1';				-- NMI

cpu0_wait_n <= '1'; -- WAIT
cpuclk <= clk_bus and cpu0_ena;
cpu0_mult <= '0' & port_1ffd_reg(2); -- turbo switch
process (cpu0_mult, ena_3_5mhz, ena_7mhz, ena_14mhz)
begin
	case cpu0_mult is
		when "00" => cpu0_ena <= ena_7mhz;
		when "01" => cpu0_ena <= ena_3_5mhz;
		when others => null;
	end case;
end process;

-------------------------------------------------------------------------------
-- RAM

host_ram_a <= ram_a_bus & cpu0_a_bus(12 downto 0);
host_ram_di <= cpu0_do_bus;
host_ram_wr <= '1' when cpu0_mreq_n = '0' and cpu0_wr_n = '0' and (mux = "1001" or mux(3 downto 2) = "11" or mux(3 downto 2) = "01" or mux(3 downto 1) = "101" or mux(3 downto 1) = "001") else '0';
host_ram_rd <= not (cpu0_mreq_n or cpu0_rd_n);

-- bridge between loader and host machine
sram_a_bus <= loader_ram_a when loader_act = '1' else host_ram_a;
sram_di_bus <= loader_ram_di when loader_act = '1' else host_ram_di;
loader_ram_do <= sram_do_bus;-- when loader_act = '1' else (others => '1');
host_ram_do <= sram_do_bus;-- when loader_act = '0' else (others => '1');
sram_wr <= loader_ram_wr when loader_act = '1' else host_ram_wr;
sram_rd <= loader_ram_rd when loader_act = '1' else host_ram_rd;

SRAM_A <= sram_a_bus;
SRAM_D <= sram_di_bus when sram_wr = '1' else (others => 'Z');
sram_do_bus <= SRAM_D;
SRAM_NWR <= '0' when sram_wr = '1' else '1';
SRAM_NRD <= '0' when sram_rd = '1' else '1';

-------------------------------------------------------------------------------
-- SD

SD_NCS	<= '1' when loader_act = '1' else zc_cs_n when sd_mode = '0' else divmmc_cs_n;
sd_clk 	<= zc_sclk when sd_mode = '0' else divmmc_sclk;
sd_si 	<= zc_mosi when sd_mode = '0' else divmmc_mosi;

-- share SPI between loader and SD
loader_ncs <= '0' when loader_act = '1' else '1';
DCLK <= loader_clk when loader_act = '1' else sd_clk;
ASDO <= loader_do when loader_act = '1' else sd_si;

-------------------------------------------------------------------------------
-- Ports

-- #FD port correction
-- IN A, (#FD) - read a value from a hardware port 
-- OUT (#FD), A - writes the value of the second operand into the port given by the first operand.
fd_sel <= '0' when (
	(cpu0_do_bus(7 downto 4) = "1101" and cpu0_do_bus(2 downto 0) = "011") or 
	(cpu0_di_bus(7 downto 4) = "1101" and cpu0_di_bus(2 downto 0) = "011")) else '1'; 

-- TODO
process(fd_sel, reset, cpu0_m1_n)
begin
	if reset='1' then
		fd_port <= '1';
	elsif rising_edge(cpu0_m1_n) then 
		fd_port <= fd_sel;
	end if;
end process;

ram_ext_lock <= port_1ffd_reg(1) & port_7ffd_reg(5);
cs_xxfe <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus(0) = '0' else '0';
cs_xxff <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus(7 downto 0) = X"FF" else '0';
cs_eff7 <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus = X"EFF7" else '0';
cs_dff7 <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus = X"DFF7" and port_eff7_reg(7) = '1' else '0';
cs_fffd <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus = X"FFFD" and fd_port = '1' else '0';
cs_1ffd <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus = X"1FFD" and fd_port = '1' else '0';
cs_dffd <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus = X"DFFD" and fd_port = '1' else '0';
cs_7ffd <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus = X"7FFD" else '0';
cs_xxfd <= '1' when cpu0_iorq_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus(15) = '0' and cpu0_a_bus(1) = '0' and fd_port = '0' else '0';


process (reset, areset, clk_bus, cpu0_a_bus, dos_act, cs_xxfe, cs_eff7, cs_dff7, cs_7ffd, cs_1ffd, cs_xxfd, port_7ffd_reg, port_1ffd_reg, cpu0_mreq_n, cpu0_m1_n, cpu0_wr_n, cpu0_do_bus, fd_port, sd_mode)
begin
	if reset = '1' then
		port_eff7_reg <= (others => '0');
		port_7ffd_reg <= (others => '0');
		port_dffd_reg <= (others => '0');
		port_1ffd_reg <= (others => '0');--(7 downto 2) <= (others => '0'); -- skip turbo / memlock bits on reset
		dos_act <= not sd_mode;
		timexcfg_reg <= (others => '0');
		is_port_ff <= '0';
	elsif clk_bus'event and clk_bus = '1' then

		-- #FE
		if cs_xxfe = '1' and cpu0_wr_n = '0' then 
			port_xxfe_reg <= cpu0_do_bus; 
		end if;

		-- #EFF7
		if cs_eff7 = '1' and cpu0_wr_n = '0' then 
			port_eff7_reg <= cpu0_do_bus; 
		end if;
		
		-- #DFF7
		if cs_dff7 = '1' and cpu0_wr_n = '0' then 
			mc146818_a_bus <= cpu0_do_bus(5 downto 0); 
		end if;

		-- #1FFD
		if cs_1ffd = '1' and cpu0_wr_n = '0' then
			port_1ffd_reg <= cpu0_do_bus;
		end if;

		-- #DFFD
		if cs_dffd = '1' and cpu0_wr_n = '0' then
			port_dffd_reg <= cpu0_do_bus;
		end if;
		
		-- #7FFD
		if cs_7ffd = '1' and cpu0_wr_n = '0' and ram_ext_lock /= "11" then
			port_7ffd_reg <= cpu0_do_bus;
		-- #FD
		elsif cs_xxfd = '1' and cpu0_wr_n = '0' and ram_ext_lock /= "11" then -- short #FD
			port_7ffd_reg <= cpu0_do_bus;
		end if;
		
		-- TR-DOS FLAG
		if cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus(15 downto 8) = X"3D" and port_7ffd_reg(4) = '1' then dos_act <= '1';
		elsif cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus(15 downto 14) /= "00" then dos_act <= '0'; end if;
		
		-- port FF / timex CFG
		if (cs_xxff = '1' and cpu0_wr_n = '0' and dos_act = '0') then 
			timexcfg_reg <= cpu0_do_bus;
			is_port_ff <= '1';
		end if;
		
	end if;
end process;

------------------------------------------------------------------------------
-- RAM mux / ext

mux <= ((divmmc_amap or divmmc_e3reg(7)) and sd_mode) & cpu0_a_bus(15 downto 13);
ram_ext <= 
	'0' & port_dffd_reg(2 downto 0) when ram_ext_lock(1) = '0'
	else "0000";

process (mux, port_7ffd_reg, cpu0_a_bus, dos_act, ram_ext, divmmc_e3reg, sd_mode, port_1ffd_reg)
begin
	case mux is
		when "0000" => ram_a_bus <= "11000" & ((not(dos_act) and not(port_1ffd_reg(1))) or sd_mode) & (port_7ffd_reg(4) and not(port_1ffd_reg(1))) & '0';	-- Seg0 ROM 0000-1FFF
		when "0001" => ram_a_bus <= "11000" & ((not(dos_act) and not(port_1ffd_reg(1))) or sd_mode) & (port_7ffd_reg(4) and not(port_1ffd_reg(1))) & '1';	-- Seg0 ROM 2000-3FFF	
		when "1000" => ram_a_bus <= "11001000";	-- ESXDOS ROM 0000-1FFF
		when "1001" => ram_a_bus <= "10" & divmmc_e3reg(5 downto 0);	-- ESXDOS RAM 2000-3FFF		
		when "0010"|"1010" => ram_a_bus <= "00001010";	-- Seg1 RAM 4000-5FFF
		when "0011"|"1011" => ram_a_bus <= "00001011";	-- Seg1 RAM 6000-7FFF
		when "0100"|"1100" => ram_a_bus <= "00000100";	-- Seg2 RAM 8000-9FFF
		when "0101"|"1101" => ram_a_bus <= "00000101";	-- Seg2 RAM A000-BFFF
		when "0110"|"1110" => ram_a_bus <= ram_ext & port_7ffd_reg(2 downto 0) & '0';	-- Seg3 RAM C000-DFFF
		when "0111"|"1111" => ram_a_bus <= ram_ext & port_7ffd_reg(2 downto 0) & '1';	-- Seg3 RAM E000-FFFF		
		when others => null;
	end case;
end process;

--ETH_NCS <= '1';

-------------------------------------------------------------------------------
-- Audio mixer

-- 16bit Delta-Sigma DAC
audio_l <= "0000000000000000" when loader_act = '1' else ("000" & speaker & "000000000000") + ("000" & ssg_cn0_a & "00000") + ("000" & ssg_cn0_b & "00000") + ("000" & ssg_cn1_a & "00000") + ("000" & ssg_cn1_b & "00000") + ("000" & covox_a   & "00000") + ("000" & covox_b   & "00000") + ("000" & saa_out_l & "00000");
audio_r <= "0000000000000000" when loader_act = '1' else ("000" & speaker & "000000000000") + ("000" & ssg_cn0_c & "00000") + ("000" & ssg_cn0_b & "00000") + ("000" & ssg_cn1_c & "00000") + ("000" & ssg_cn1_b & "00000") + ("000" & covox_c   & "00000") + ("000" & covox_d   & "00000") + ("000" & saa_out_r & "00000");

-- SAA1099
saa_wr_n <= '0' when (cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 0) = "11111111" and dos_act = '0') else '1';

-------------------------------------------------------------------------------
-- Port I/O

mc146818_wr 	<= '1' when (port_bff7 = '1' and cpu0_wr_n = '0') else '0';
port_bff7 	<= '1' when (cpu0_iorq_n = '0' and cpu0_a_bus = X"BFF7" and cpu0_m1_n = '1' and port_eff7_reg(7) = '1') else '0';
zc_wr 		<= '1' when (cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 6) = "01" and cpu0_a_bus(4 downto 0) = "10111") else '0';
zc_rd 		<= '1' when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 6) = "01" and cpu0_a_bus(4 downto 0) = "10111") else '0';

-------------------------------------------------------------------------------
-- CPU0 Data bus

process (selector, host_ram_do, mc146818_do_bus, kb_do_bus, zc_do_bus, ssg_cn0_bus, ssg_cn1_bus, port_7ffd_reg, vid_attr, port_eff7_reg, port_1ffd_reg, joy_bus, ms_z, ms_b, ms_x, ms_y, divmmc_do, zxuno_addr_to_cpu, uart_do_bus, rasterint_do_bus, ula_do_bus)
begin
	case selector is
		when x"00" => cpu0_di_bus <= host_ram_do;
		when x"01" => cpu0_di_bus <= mc146818_do_bus;
		when x"02" => cpu0_di_bus <= "11" & kb_do_bus;
		when x"03" => cpu0_di_bus <= zc_do_bus;
		when x"04" => cpu0_di_bus <= "000" & joy_bus;
		when x"05" => cpu0_di_bus <= ssg_cn0_bus;
		when x"06" => cpu0_di_bus <= ssg_cn1_bus;
		when x"07" => cpu0_di_bus <= port_1ffd_reg;
		when x"08" => cpu0_di_bus <= port_7ffd_reg;
--		when x"09" => cpu0_di_bus <= port_7ffd_reg;
		when x"0A" => cpu0_di_bus <= ms_z(3 downto 0) & '1' & not ms_b(2) & not ms_b(0) & not ms_b(1);
		when x"0B" => cpu0_di_bus <= ms_x;
		when x"0C" => cpu0_di_bus <= not(ms_y);
		when x"0D" => cpu0_di_bus <= divmmc_do;
		when x"0E" => cpu0_di_bus <= zxuno_addr_to_cpu;
		when x"0F" => cpu0_di_bus <= uart_do_bus;
		when x"10" => cpu0_di_bus <= timexcfg_reg;
		when x"11" => cpu0_di_bus <= vid_attr;
--		when x"12" => cpu0_di_bus <= rasterint_do_bus;
		when x"13" => cpu0_di_bus <= cpld_do;
--		when x"FF" => cpu0_di_bus <= ula_do_bus;
		when others => cpu0_di_bus <= x"FF";
	end case;
end process;

selector <= 
			x"00" when (cpu0_mreq_n = '0' and cpu0_rd_n = '0') else 																									-- SDRAM
			x"01" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_m1_n = '1' and port_bff7 = '1' and port_eff7_reg(7) = '1') else 									-- MC146818A
			x"02" when (cs_xxfe = '1' and cpu0_rd_n = '0') else 													-- Keyboard, port #FE
			x"03" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus( 7 downto 6) = "01" and cpu0_a_bus(4 downto 0) = "10111") and sd_mode = '0' else 	-- Z-Controller
			x"04" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_m1_n = '1' and cpu0_a_bus( 7 downto 0) = X"1F" and dos_act = '0') else 							-- Joystick, port #1F
			x"05" when (cs_fffd = '1' and cpu0_rd_n = '0' and ssg_sel = '0') else -- TurboSound
			x"06" when (cs_fffd = '1' and cpu0_rd_n = '0' and ssg_sel = '1') else
			x"07" when (cs_1ffd = '1' and cpu0_rd_n = '0') else										-- port #1FFD
			x"08" when (cs_7ffd = '1' and cpu0_rd_n = '0') else										-- port #7FFD
--			x"09" when (cs_xxfd = '1' and cpu0_rd_n = '0') else 									-- port #FD
    		x"0A" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus = X"FADF") else										-- Mouse0 port key, z
		   x"0B" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus = X"FBDF") else										-- Mouse0 port x
		   x"0C" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus = X"FFDF") else										-- Mouse0 port y 
			x"0D" when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus( 7 downto 0) = X"EB" and sd_mode = '1') else -- DivMMC
			x"0E" when zxuno_addr_oe_n = '0' else -- ZX UNO address 
			x"0F" when uart_oe_n = '0' else -- UART
			x"10" when (cs_xxff = '1' and cpu0_rd_n = '0' and is_port_ff = '1' and dos_act = '0') else 		-- port #FF (Timex)
			x"11" when (cs_xxff = '1' and cpu0_rd_n = '0' and is_port_ff = '0') else 		-- port #FF (normal)
--		   x"12" when rasterint_oe_n = '0' else -- raster interrupt
			x"13" when cpld_oe_n = '0' else -- FDD / HDD controllers
			(others => '1');

-------------------------------------------------------------------------------
-- Video

--vid_wr	<= '1' when cpu0_mreq_n = '0' and cpu0_wr_n = '0' and ((ram_a_bus = "000000001010") or (ram_a_bus = "000000001110")) else '0'; 
vid_wr <= '1' when cpu0_mreq_n = '0' and cpu0_wr_n = '0' and host_ram_a(20 downto 16) = 1 and host_ram_a(14) = '1' else '0';
vid_scr	<= '1' when (ram_a_bus = "000000001110") else '0';

vga_r <= host_vga_r;
vga_g <= host_vga_g;
vga_b <= host_vga_b;
vga_hs <= host_vga_hs;
vga_vs <= host_vga_vs;

vid_border <= port_xxfe_reg(2 downto 0);

-------------------------------------------------------------------------------
-- AVR Keyboard / mouse / rtc

U21: entity work.cpld_kbd
	port map
	(
	 CLK 		=> clk_bus,
	 N_RESET => not areset,
	 N_CS		=> '1',
    A       => cpu0_a_bus(15 downto 8),
    KB		=> kb_do_bus,
    AVR_MOSI=> AVR_MOSI,
    AVR_MISO=> AVR_MISO,
    AVR_SCK => AVR_SCK,
	 AVR_SS 	=> AVR_NCS,
	 
	 MS_X 	=> ms_x,
	 MS_Y 	=> ms_y,
	 MS_BTNS => ms_b,
	 MS_Z 	=> ms_z,
	 
	 RTC_A 	=> mc146818_a_bus,
	 RTC_DI 	=>	cpu0_do_bus,
	 RTC_DO 	=>	mc146818_do_bus,
	 RTC_WR_N => not mc146818_wr,

	 RESET => kb_reset,
	 TURBO => kb_turbo,
	 MAGICK => kb_magic,
	 
	 JOY => joy_bus
	);
	
-------------------------------------------------------------------------------
-- I2S sound

U22: entity work.tda1543
	port map (
		RESET	=> reset,
		CLK => clk_bus,
		CS => '1',
      DATA_L => audio_l,
      DATA_R => audio_r,
		BCK => SND_BS,
		WS  => SND_WS,
      DATA => SND_DAT
	);

-------------------------------------------------------------------------------
-- FDD / HDD controllers

U23: entity work.bus_port
	port map (

	CLK => clk_cpld,
	CLK2 => clk_saa,
	
	SD => SD,
	SA => SA,
	SDIR => SDIR,
	CPLD_CLK => CPLD_CLK,
	CPLD_CLK2 => CPLD_CLK2,

	BUS_A => cpu0_a_bus,
	BUS_DI => cpu0_do_bus,
	BUS_DO => cpld_do,
	OE_N => cpld_oe_n,
	BUS_RD_N => cpu0_rd_n,
	BUS_WR_N => cpu0_wr_n,
	BUS_MREQ_N => cpu0_mreq_n,
	BUS_IORQ_N => cpu0_iorq_n,
	BUS_M1_N => cpu0_m1_n,
	BUS_CPM => '0', -- todo
	BUS_DOS => dos_act,
	BUS_ROM14 => rom_a14
);

rom_a14 <= '1' when ram_a_bus(6) = '1' and ram_a_bus(0) = '1' else '0'; -- todo: doublecheck

--

end rtl;
