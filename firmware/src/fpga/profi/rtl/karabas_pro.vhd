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
-- FPGA firmware for Karabas-Pro
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- @author Oleh Starychenko <solegstar@gmail.com>
-- Ukraine, 2021
-------------------------------------------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity karabas_pro is
	generic (
		enable_zxuno_uart  : boolean := true;  -- uart 1 (enabled by default)
		enable_zxuno_uart2 : boolean := false; -- uart 2 (enabled for ep4ce10)
		enable_saa1099 	 : boolean := false; -- saa1099 (enabled for ep4ce10)
		enable_osd_overlay : boolean := true;  -- osd overlay (enabled by default)
		enable_2port_vram  : boolean := false -- 2port vram (enabled for ep4ce10)
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
	SDIR 			: out std_logic;
	SA				: out std_logic_vector(1 downto 0);
	SD				: inout std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	
	-- I2S Sound TDA1543
	SND_BS		: out std_logic;
	SND_WS 		: out std_logic;
	SND_DAT 		: out std_logic;
	
	-- UART2 (for ep4ce10 / ep4c10)
	PIN_141		: out std_logic; -- uart2 tx
	PIN_138 		: out std_logic; -- uart2 cts
	PIN_25 		: in std_logic;	 -- uart2 rx
	
	-- RAM selector 
	PIN_121		: out std_logic := '0'; -- /ramce1
	PIN_120		: out std_logic := '1'; -- /ramce2
	PIN_7 		: out std_logic := '1'; -- /ramce3
	
   FDC_STEP    : in std_logic; -- PIN_119 connected to FDC_STEP for TurboFDC
   SD_MOSI     : inout std_logic; -- PIN_115 connected to SD_S
	TAPE_IN 		: in std_logic := '1';  -- PIN_24
	TAPE_OUT 	: out std_logic; -- PIN_10
	BUZZER		: out std_logic; -- PIN_86
		
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
signal port_008b_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_018b_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_028b_reg	: std_logic_vector(7 downto 0) := "00000000";

-------------8B_PORT------------------
signal rom0				: std_logic;
signal rom1				: std_logic;
signal rom2				: std_logic;
signal rom3				: std_logic;
signal rom4				: std_logic;
signal rom5				: std_logic;
signal ram0				: std_logic;
signal ram1				: std_logic;
signal ram2				: std_logic;
signal ram3				: std_logic;
signal ram4				: std_logic;
signal ram5				: std_logic;
signal ram6				: std_logic;
signal ram7				: std_logic;
signal onrom			: std_logic;
signal unlock_128		: std_logic;
signal turbo_mode		: std_logic_vector(1 downto 0) := "00";
signal lock_dffd		: std_logic;
signal sound_off		: std_logic;
signal hdd_type		: std_logic;
signal fdc_swap		: std_logic;
signal turbo_fdc_off	: std_logic;
signal hdd_off			: std_logic;

-- Keyboard
signal kb_do_bus		: std_logic_vector(5 downto 0);
signal kb_reset 		: std_logic := '0';
signal kb_magic 		: std_logic := '0';
signal kb_special 	: std_logic := '0';
signal kb_turbo 		: std_logic_vector(1 downto 0) := "00";
signal kb_turbo_old	: std_logic_vector(1 downto 0) := "00";
signal kb_wait 		: std_logic := '0';
signal kb_mode 		: std_logic := '1';
signal joy_type 		: std_logic := '0';
signal kb_loaded 		: std_logic := '0';
signal kb_screen_mode: std_logic_vector(1 downto 0) := "00";

-- Joy
signal joy_bus 		: std_logic_vector(7 downto 0) := "00000000";

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
signal vid_do_bus 	: std_logic_vector(7 downto 0);
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
signal vid_ispaper   : std_logic;
signal vid_scandoubler_enable : std_logic := '1';
signal blink 			: std_logic;

-- OSD overlay
signal osd_overlay 	: std_logic := '0';
signal osd_popup 		: std_logic := '0';
signal osd_command 	: std_logic_vector(15 downto 0);

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
signal cs_008b			: std_logic := '0';
signal cs_018b			: std_logic := '0';
signal cs_028b			: std_logic := '0';

-- Profi HDD ports
signal hdd_profi_ebl_n	:std_logic;
signal hdd_wwc_n			:std_logic; -- Write High byte from Data bus to "Write register"
signal hdd_wwe_n			:std_logic; -- Read High byte from "Write register" to HDD bus
signal hdd_rww_n			:std_logic; -- Selector Low byte Data bus Buffer Direction: 1 - to HDD bus, 0 - to Data bus
signal hdd_rwe_n			:std_logic; -- Read High byte from "Read register" to Data bus
signal hdd_cs3fx_n		:std_logic;

-- Profi FDD ports
signal RT_F2_1			:std_logic;
signal RT_F2_2			:std_logic;
signal RT_F2_3			:std_logic;
signal fdd_cs_pff_n	:std_logic;
signal RT_F1_1			:std_logic;
signal RT_F1_2			:std_logic;
signal RT_F1			:std_logic;
signal P0				:std_logic;
signal fdd_cs_n		:std_logic;

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
--signal ay_bdir 		: std_logic;
--signal ay_bc1			: std_logic;
--signal ay_port 		: std_logic := '0';

-- Covox
signal covox_a			: std_logic_vector(7 downto 0);
signal covox_b			: std_logic_vector(7 downto 0);
signal covox_c			: std_logic_vector(7 downto 0);
signal covox_d			: std_logic_vector(7 downto 0);
signal covox_fb		: std_logic_vector(7 downto 0);

-- Output audio
signal audio_l			: std_logic_vector(15 downto 0);
signal audio_r			: std_logic_vector(15 downto 0);
signal audio_mono		: std_logic_vector(15 downto 0);
signal audio_dac_type: std_logic := '0'; -- 0 = TDA1543, 1 = TDA1543A

-- SAA1099
signal saa_wr_n		: std_logic;
signal saa_out_l		: std_logic_vector(7 downto 0);
signal saa_out_r		: std_logic_vector(7 downto 0);

-- CLOCK
signal clk_112			: std_logic := '0';
signal clk_84 			: std_logic := '0';
signal clk_72 			: std_logic := '0';
signal clk_28 			: std_logic := '0';
signal clk_24 			: std_logic := '0';
signal clk_8			: std_logic := '0';
signal clk_bus			: std_logic := '0';
signal clk_bus_port	: std_logic := '0';
signal clk_div2		: std_logic := '0';
signal clk_div4		: std_logic := '0';
signal clk_div8		: std_logic := '0';
signal clk_div16		: std_logic := '0';
signal clk_i2s 		: std_logic := '0';

signal ena_div2	: std_logic := '0';
signal ena_div4	: std_logic := '0';
signal ena_div8	: std_logic := '0';
signal ena_div16	: std_logic := '0';
--signal ena_div32	: std_logic := '0';
signal ena_cnt		: std_logic_vector(3 downto 0) := "0000";

-- System
signal reset			: std_logic;
signal areset			: std_logic;
--signal locked			: std_logic;
signal locked_tri 	: std_logic := '0';
signal loader_act		: std_logic := '1';
signal loader_reset 	: std_logic := '0';
signal loader_done 	: std_logic := '0';
signal dos_act			: std_logic := '1';
signal clk_cpu			: std_logic;
signal selector		: std_logic_vector(7 downto 0);
signal mux				: std_logic_vector(3 downto 0);
signal speaker 		: std_logic := '0';
signal ram_ext 		: std_logic_vector(4 downto 0) := "00000";
signal ram_do_bus 	: std_logic_vector(7 downto 0);
signal ram_oe_n 		: std_logic := '1';
signal vbus_mode 		: std_logic := '0';
signal vid_rd 			: std_logic := '0';
signal vid_rd2 		: std_logic := '0';
signal ext_rom_bank  : std_logic_vector(1 downto 0) := "00";
signal ext_rom_bank_pq	: std_logic_vector(1 downto 0) := "00";
signal max_turbo 		: std_logic_vector(1 downto 0) := "11";

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

-- ZXUNO regs / UART ports
signal zxuno_regrd : std_logic;
signal zxuno_regwr : std_logic;
signal zxuno_addr : std_logic_vector(7 downto 0);
signal zxuno_regaddr_changed : std_logic;
signal zxuno_addr_oe_n : std_logic;
signal zxuno_addr_to_cpu : std_logic_vector(7 downto 0);
signal zxuno_uart_do_bus 	: std_logic_vector(7 downto 0);
signal zxuno_uart_oe_n 		: std_logic;
signal zxuno_uart2_do_bus 	: std_logic_vector(7 downto 0);
signal zxuno_uart2_oe_n 		: std_logic;
signal uart2_tx : std_logic;
signal uart2_rx : std_logic;
signal uart2_cts : std_logic;

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
signal soft_sw 		: std_logic_vector(1 to 10) := (others => '0');

signal board_reset 	: std_logic := '0'; -- board reset on rombank switch
signal tape_in_out_enable : std_logic := '0'; -- revDS uses SW3 switches as tape in / out
signal tape_in_monitor : std_logic := '0';

-- memory contention
signal count_block 		: std_logic := '0';
signal memory_contention : std_logic := '0';

-- debug 
signal fdd_oe_n 		: std_logic := '1';
signal hdd_oe_n 		: std_logic := '1';
signal port_nreset 	: std_logic := '1';

-- wait signal
signal WAIT_C			:std_logic_vector(1 downto 0);
signal WAIT_IO			:std_logic;
signal WAIT_EN			:std_logic;
signal WAIT_C_STOP	:std_logic;

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
generic (
	UARTDATA : std_logic_vector(7 downto 0) := x"C6";
	UARTSTAT : std_logic_vector(7 downto 0) := x"C7"
);
port (
	clk_bus : in std_logic;
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
	clk_bus: in std_logic;
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
	locked			=> open,
	c0 				=> clk_112
	);
	
-- PLL2
U2: entity work.altpll1
port map (
	inclk0			=> clk_112,
	locked 			=> open,
	c0 				=> clk_84,
	c1 				=> clk_72,
	c2 				=> clk_28,
	c3 				=> clk_24,
	c4 				=> clk_8);
		
-- main clock selector
U3: entity work.clk_ctrl
port map(
	clkselect 	=> ds80,
	inclk0x 		=> clk_28,
	inclk1x 		=> clk_24,
	outclk 		=> clk_bus
);

-- Bus Port clock selector
U4: entity work.clk_ctrl2
port map(
	clkselect 	=> ds80,
	inclk0x 		=> clk_84,
	inclk1x 		=> clk_72,
	outclk 		=> clk_bus_port
);

-- Zilog Z80A CPU
U5: entity work.T80a
port map (
	RESET_n			=> cpu_reset_n,
	CLK_n			=> not clk_cpu,
	CEN			=> '1',
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
	DIN					=> cpu_di_bus,
	DOUT					=> cpu_do_bus
);
	
-- memory manager
U6: entity work.memory 
generic map (
	enable_2port_vram => enable_2port_vram
)
port map ( 
	CLK2X 			=> clk_bus,
	CLKX 				=> clk_div2,
	CLK_CPU 			=> clk_cpu,
	-- cpu signals
	A 					=> cpu_a_bus,
	D 					=> cpu_do_bus,
	N_MREQ 			=> cpu_mreq_n,
	N_IORQ 			=> cpu_iorq_n,
	N_WR 				=> cpu_wr_n,
	N_RD 				=> cpu_rd_n,
	N_M1 				=> cpu_m1_n,
	
	-- config from loader
	RAM_6MB 			=> board_revision(5), -- 5th bit of the CFG is a revE flag with 6MB SRAM
	
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
	N_CE1 			=> PIN_121,
	N_CE2 			=> PIN_120,
	N_CE3				=> PIN_7,
	-- ram out to cpu
	DO 				=> ram_do_bus,
	N_OE 				=> ram_oe_n,	
	-- ram pages
	RAM_BANK 		=> port_7ffd_reg(2 downto 0),
	RAM_EXT 			=> ram_ext, -- seg A3 - seg A5

	-- TRDOS 
	TRDOS 			=> dos_act,	

	-- video
	VA 				=> vid_a_bus,
	VID_PAGE 		=> port_7ffd_reg(3), -- seg A0 - seg A2
	VID_DO 			=> vid_do_bus,
	
	-- sram vram
	VBUS_MODE_O 	=> vbus_mode, 	-- video bus mode: 0 - ram, 1 - vram
	VID_RD_O 		=> vid_rd, 		-- read attribute or pixel	

	-- 2port vram
	VID_RD2 			=> vid_rd2,
	
	DS80 				=> ds80,
	CPM 				=> cpm,
	SCO 				=> sco,
	SCR 				=> scr,
	WOROM 			=> worom,

	-- rom
	ROM_BANK 		=> rom14,
	EXT_ROM_BANK   => ext_rom_bank_pq,
	
	-- contended memory signals
	COUNT_BLOCK		=> count_block,
	CONTENDED 		=> memory_contention
);	

-- Video Spectrum/Pentagon
U7: entity work.video
generic map (
	enable_2port_vram => enable_2port_vram
)
port map (
	CLK 				=> clk_div2, 	-- 14 / 12
	CLK2x 			=> clk_bus, 	-- 28 / 24
	ENA 				=> clk_div4, 	-- 7 / 6
	RESET 			=> reset,	
	BORDER 			=> port_xxfe_reg(7 downto 0),
	DI 				=> vid_do_bus,
	TURBO 			=> turbo_mode,	-- turbo signal for int length
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
	VID_RD2 			=> vid_rd2,	
	HCNT 				=> vid_hcnt,
	VCNT 				=> vid_vcnt,
	ISPAPER 			=> vid_ispaper,
	BLINK 			=> blink,
	SCREEN_MODE    => kb_screen_mode,
	COUNT_BLOCK 	=> count_block
);

-- osd overlay
U8: entity work.overlay
port map (
	CLK 				=> clk_bus,
	CLK2 				=> clk_div2,
	DS80				=> ds80,
	RGB_I 			=> vid_rgb,
	RGB_O 			=> vid_rgb_osd,
	HCNT_I 			=> vid_hcnt,
	VCNT_I 			=> vid_vcnt,
	PAPER_I 			=> vid_ispaper,
	BLINK 			=> blink,

	-- osd overlay
	OSD_OVERLAY		=> osd_overlay,
	OSD_POPUP 		=> osd_popup,
	OSD_COMMAND 	=> osd_command
);

-- Scandoubler	
U9: entity work.vga_pal 
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
U10: entity work.flash
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
U11: entity work.loader
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
U12: entity work.turbosound
port map (
	I_CLK				=> clk_bus,
	I_ENA				=> ena_div16,
	I_ADDR			=> cpu_a_bus,
	I_DATA			=> cpu_do_bus,
	I_WR_N			=> cpu_wr_n,
	I_IORQ_N			=> cpu_iorq_n,
	I_M1_N			=> cpu_m1_n,
	I_RESET_N		=> cpu_reset_n,
	I_BDIR 			=> '1', --ay_bdir,
	I_BC1 			=> '1', --ay_bc1,
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
U13: entity work.covox
port map (
	I_RESET			=> reset,
	I_CLK				=> clk_bus,
	I_CS				=> soft_sw(6),
	I_WR_N			=> cpu_wr_n,
	I_ADDR			=> cpu_a_bus(7 downto 0),
	I_DATA			=> cpu_do_bus,
	I_IORQ_N			=> cpu_iorq_n,
	I_DOS				=> dos_act,
	I_CPM 			=> cpm,
	I_ROM14 			=> rom14,
	O_A				=> covox_a,
	O_B				=> covox_b,
	O_C				=> covox_c,
	O_D				=> covox_d,
	O_FB 				=> covox_fb
);
	 
G_SAA1099: if enable_saa1099 generate
U14: saa1099
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
U15: entity work.avr
port map (
	 CLK 				=> clk_bus,
	 CLKEN 			=> clk_cpu,
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
	 
	 LOADER_DONE   => not loader_act,
	 
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
	 JOY_TYPE 		=> joy_type,
	 OSD_OVERLAY 	=> osd_overlay,
	 OSD_POPUP 		=> osd_popup,
	 OSD_COMMAND	=> osd_command,
	 MAX_TURBO 		=> max_turbo,
	 SCREEN_MODE   => kb_screen_mode,
	 
	 LOADED 			=> kb_loaded,
	 
	 JOY 				=> joy_bus
);
	
-- TDA1543
U16: entity work.tda1543
port map (
	RESET				=> reset,
	CLK_BUS 			=> clk_bus,
	DAC_TYPE 		=> audio_dac_type,
	CS 				=> '1',
	DATA_L 			=> audio_l,
	DATA_R 			=> audio_r,
	BCK 				=> SND_BS,
	WS  				=> SND_WS,
	DATA 				=> SND_DAT
);

-- FDD / HDD controllers
U17: entity work.bus_port
port map (
	CLK 				=> clk_bus_port,
	CLK2 				=> clk_8,
	CLK_BUS 			=> clk_bus,
	CLK_CPU 			=> clk_cpu,
	RESET 			=> reset,
	
	SD 				=> SD,
	SA 				=> SA,
	CPLD_CLK 		=> CPLD_CLK,
	CPLD_CLK2 		=> CPLD_CLK2,
	NRESET 			=> NRESET,

	BUS_A 			=> cpu_a_bus(10 downto 8) & cpu_a_bus(6 downto 5),
	BUS_DI 			=> cpu_do_bus,
	BUS_DO 			=> cpld_do,
	BUS_RD_N 		=> cpu_rd_n,
	BUS_WR_N 		=> cpu_wr_n,
	BUS_HDD_CS_N	=> hdd_profi_ebl_n,
	BUS_WWC			=> hdd_wwc_n,
	BUS_WWE			=> hdd_wwe_n,
	BUS_RWW			=> hdd_rww_n,
	BUS_RWE			=> hdd_rwe_n,
	BUS_CS3FX		=> hdd_cs3fx_n,
	BUS_FDC_STEP	=>	FDC_STEP and turbo_fdc_off,
	BUS_CSFF			=> fdd_cs_pff_n,
	BUS_FDC_NCS		=> fdd_cs_n

);

-- Serial mouse emulation
U20: entity work.serial_mouse
port map(
	CLK 				=> clk_bus,
	CLKEN 			=> clk_cpu,
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
U21: zxunoregs 
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

U22: zxunouart 
port map(
	clk_bus => clk_bus,
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

G_UNO_UART2: if enable_zxuno_uart2 generate
U24: zxunouart 
generic map (
	UARTDATA => x"C8",
	UARTSTAT => x"C9"
)
port map(
	clk_bus => clk_bus,
	ds80 => ds80,
	zxuno_addr => zxuno_addr,
	zxuno_regrd => zxuno_regrd,
	zxuno_regwr => zxuno_regwr,
	din => cpu_do_bus,
	dout => zxuno_uart2_do_bus,
	oe_n => zxuno_uart2_oe_n,
	uart_tx => UART2_TX,
	uart_rx => UART2_RX,
	uart_rts => UART2_CTS
);	
PIN_141		<= uart2_tx;
PIN_138 		<= uart2_cts;
uart2_rx 		<= PIN_25;
end generate G_UNO_UART2;

-- debug
--PIN_141 <= clk_bus;
--PIN_138 <= clk_cpu;

end generate G_UNO_UART;

-- board features
U23: entity work.board 
port map(
	CLK => clk_bus,
	CFG => board_revision,
	
	SOFT_SW1 => soft_sw(1),
	SOFT_SW2 => soft_sw(2),
	SOFT_SW3 => soft_sw(3),
	SOFT_SW4 => soft_sw(4),
	
	AUDIO_DAC_TYPE => audio_dac_type,
	ROM_BANK => ext_rom_bank,
	SCANDOUBLER_EN => vid_scandoubler_enable,
	TAPE_IN_OUT_EN => tape_in_out_enable,
	
	BOARD_RESET => board_reset	
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
--ena_div32 <= ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
	
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
cpu_nmi_n <= '0' when kb_magic = '1' and ((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00") or DS80 = '1') else '1'; -- NMI
cpu_wait_n <= '1';

-- max turbo = 14 MHz for 2 port vram
--G_MAX_TURBO_2PORT: if enable_2port_vram generate 
	max_turbo <= "10";
--end generate G_MAX_TURBO_2PORT;
--
---- max turbo = 7 MHz for sram vram
--G_MAX_TURBO_SRAM: if not enable_2port_vram generate 
--	max_turbo <= "01";
--end generate G_MAX_TURBO_SRAM;

clk_cpu <= '0' when kb_wait = '1' or  (kb_screen_mode = "01" and memory_contention = '1' and DS80 = '0') or WAIT_IO = '0' else 
	clk_bus when turbo_mode = "11" and turbo_mode <= max_turbo else 
	clk_bus and ena_div2 when turbo_mode = "10" and turbo_mode <= max_turbo else 
	clk_bus and ena_div4 when turbo_mode = "01" and turbo_mode <= max_turbo else 
	clk_bus and ena_div8;

-- odnovibrator - po spadu nIORQ otschityvaet 400ns WAIT proca
-- dlja rabotosposobnosti periferii v turbe ili v rezhime 
-- rasshirennogo jekrana pri podkljuchenii tret'ego kvarca XMHz

WAIT_IO <= WAIT_C(1);
WAIT_C_STOP <=WAIT_C(1) and not WAIT_C(0);
WAIT_EN <= reset or not turbo_mode(1);
process (ena_div2, cpu_mreq_n, WAIT_EN, WAIT_C_STOP) 	
	begin					
		if ena_div2'event and ena_div2='0' then
			if WAIT_EN = '1' then	
				WAIT_C <= "11";
			elsif cpu_mreq_n='1' then
				WAIT_C <= "11"; --WAIT MREQ = 0
			elsif WAIT_C_STOP='0' then
				WAIT_C <= WAIT_C + "01"; --COUNT
			elsif WAIT_C_STOP='1' then
				WAIT_C <= WAIT_C; --STOP
			end if;
		end if;
	end process;

-- HDD / SD access
led1_overwrite <= '1';
process (clk_bus, hdd_wwe_n, hdd_rww_n, SD_NCS)
begin
	if rising_edge(clk_bus) then
		if (hdd_wwe_n = '0') or (hdd_rww_n = '0') or (SD_NCS = '0') then
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
SD_MOSI <= sd_si;

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

-- Config PORT X"008B"
cs_008b <='1' when cpu_a_bus(15 downto 0)=X"008B" and cpu_iorq_n='0' and cpu_m1_n = '1' and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) else '0';

rom0 <= port_008b_reg(0);											-- 0 - ROM64Kb PAGE bit 0 Change
rom1 <= port_008b_reg(1);											-- 1 - ROM64Kb PAGE bit 1 Change
rom2 <= port_008b_reg(2);											-- 2 - ROM64Kb PAGE bit 2 Change
rom3 <= port_008b_reg(3);											-- 3 - ROM64Kb PAGE bit 3 Change
rom4 <= port_008b_reg(4); 											-- 4 - ROM64Kb PAGE bit 4 Change
rom5 <= port_008b_reg(5);										 	-- 5 - ROM64Kb PAGE bit 5 Change
onrom <= port_008b_reg(6);											-- 6 - Forced activation of the signal "DOS"
unlock_128 <= port_008b_reg(7);									-- 7 - Unlock 128 ROM page for DOS

-- Config PORT X"018B"
cs_018b <='1' when cpu_a_bus(15 downto 0)=X"018B" and cpu_iorq_n='0' and cpu_m1_n = '1' and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) else '0';

ram0 <= port_018b_reg(0);											-- 0 - RAM PAGE bit 0
ram1 <= port_018b_reg(1); 											-- 1 - RAM PAGE bit 1
ram2 <= port_018b_reg(2);										 	-- 2 - RAM PAGE bit 2
ram3 <= port_018b_reg(3);											-- 3 - RAM PAGE bit 3
ram4 <= port_018b_reg(4);											-- 3 - RAM PAGE bit 4
ram5 <= port_018b_reg(5);											-- 3 - RAM PAGE bit 5
ram6 <= port_018b_reg(6);											-- 3 - RAM PAGE bit 6
ram7 <= port_018b_reg(7);											-- 3 - RAM PAGE bit 7

-- Config PORT X"028B"
cs_028b <='1' when cpu_a_bus(15 downto 0)=X"028B" and cpu_iorq_n='0' and cpu_m1_n = '1' else '0';

hdd_off <= port_028b_reg(0);										-- 0 	- HDD_off
hdd_type <= port_028b_reg(1);										-- 1 	- HDD type Profi/Nemo
turbo_fdc_off <= not port_028b_reg(2) and soft_sw(5);		-- 2 	- TURBO_FDC_off
fdc_swap <= port_028b_reg(3) or soft_sw(10);					-- 3 	- Floppy Disk Drive Selector Change
sound_off <= port_028b_reg(4);									-- 4 	- Sound_off
turbo_mode <= port_028b_reg(6 downto 5);						-- 5,6- Turbo Mode Selector 
lock_dffd <= port_028b_reg(7);								 	-- 7 	- Lock port DFFD

SDIR <= fdc_swap;

ext_rom_bank_pq <= ext_rom_bank when rom0 = '0' else "01";	-- ROMBANK ALT

rom14 <= port_7ffd_reg(4); -- rom bank
cpm 	<= port_dffd_reg(5); -- 1 - блокирует работу контроллера из ПЗУ TR-DOS и включает порты на доступ из ОЗУ (ROM14=0); При ROM14=1 - мод. доступ к расширен. периферии
worom <= port_dffd_reg(4); -- 1 - отключает блокировку порта 7ffd и выключает ПЗУ, помещая на его место ОЗУ из seg 00
ds80 	<= port_dffd_reg(7); -- 0 = seg05 spectrum bitmap, 1 = profi bitmap seg06 & seg 3a & seg 04 & seg 38
scr 	<= port_dffd_reg(6); -- памяти CPU на место seg 02, при этом бит D3 CMR0 должен быть в 1 (#8000-#BFFF)
sco 	<= port_dffd_reg(3); -- Выбор положения окна проецирования сегментов:
									-- 0 - окно номер 1 (#C000-#FFFF)
									-- 1 - окно номер 2 (#4000-#7FFF)

ram_ext <= port_7ffd_reg(7 downto 6) & port_dffd_reg(2 downto 0);

cs_xxfe <= '1' when cpu_iorq_n = '0' and cpu_a_bus(0) = '0' else '0';
cs_xx7e <= '1' when cs_xxfe = '1' and cpu_a_bus(7) = '0' else '0';
cs_eff7 <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"EFF7" else '0';
cs_fffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"FFFD" and fd_port = '1' else '0';
cs_dffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"DFFD" and fd_port = '1' and lock_dffd = '0' else '0';
cs_7ffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"7FFD" and fd_port = '1' else '0';
cs_xxfd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(15) = '0' and cpu_a_bus(1) = '0' else '0';

-- Регистры SPI-FLASH
cs_xxC7 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"C7" and cpm='1' and rom14='1' and ds80='1' else '0';
cs_xx87 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"87" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';
cs_xxA7 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"A7" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';
cs_xxE7 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"E7" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';
cs_xx67 <= '1' when cpu_iorq_n = '0' and cpu_a_bus (7 downto 0) = X"67" and cpm='1' and rom14='1' and ds80='1' and fw_update_mode='1' else '0';

-- регистр AS часов
cs_rtc_as <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and
							((cpu_a_bus(7 downto 0) = X"FF" or cpu_a_bus(7 downto 0) = X"BF") and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0'))) -- расширенная периферия
				     else '0';
--
-- регистр DS часов					  
cs_rtc_ds <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and 
							((cpu_a_bus(7 downto 0) = X"DF" or cpu_a_bus(7 downto 0) = X"9F") and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0'))) -- расширенная периферия
				     else '0';
					  
-- порты #7e - пишутся по фронту /wr
port_xxfe_reg <= cpu_do_bus when cs_xxfe = '1' and (cpu_wr_n'event and cpu_wr_n = '1');

-- порты Profi HDD
hdd_profi_ebl_n	<='0' when (cpu_a_bus(7)='1' and cpu_a_bus(4 downto 0)="01011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) and hdd_off = '0' else '1';	-- ROM14=0 BAS=0 ПЗУ SYS
hdd_wwc_n 	<='0' when (cpu_wr_n='0' and cpu_a_bus(7 downto 0)="11001011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) and hdd_off = '0' else '1'; -- Write High byte from Data bus to "Write register"
hdd_wwe_n 	<='0' when (cpu_wr_n='0' and cpu_a_bus(7 downto 0)="11101011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) and hdd_off = '0' else '1'; -- Read High byte from "Write register" to HDD bus
hdd_rww_n 	<='0' when (cpu_wr_n='1' and cpu_a_bus(7 downto 0)="11001011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) and hdd_off = '0' else '1'; -- Selector Low byte Data bus Buffer Direction: 1 - to HDD bus, 0 - to Data bus
hdd_rwe_n 	<='0' when (cpu_wr_n='1' and cpu_a_bus(7 downto 0)="11101011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) and hdd_off = '0' else '1'; -- Read High byte from "Read register" to Data bus
hdd_cs3fx_n <='0' when (cpu_wr_n='0' and cpu_a_bus(7 downto 0)="10101011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) and hdd_off = '0' else '1';

-- порты Profi FDD
RT_F2_1 <='0' when (cpu_a_bus(7 downto 5)="001" and cpu_a_bus(1 downto 0)="11" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) else '1'; --6D
RT_F2_2 <='0' when cpu_a_bus(7 downto 5)="101" and cpu_a_bus(1 downto 0)="11" and cpu_iorq_n='0' and cpm='1' and dos_act='0' and rom14='0' else '1'; --75
RT_F2_3 <='0' when cpu_a_bus(7 downto 5)="111" and cpu_a_bus(1 downto 0)="11" and cpu_iorq_n='0' and cpm='0' and dos_act='1' and rom14='1' else '1'; --F3 and FB
fdd_cs_pff_n <= RT_F2_1 and RT_F2_2 and RT_F2_3;

RT_F1_1 <= '0' when cpu_a_bus(7)='0' and cpu_a_bus(1 downto 0)="11" and cpu_iorq_n='0' and cpm='1' and dos_act='0' and rom14='0' else '1';
RT_F1_2 <= '0' when cpu_a_bus(7)='0' and cpu_a_bus(1 downto 0)="11" and cpu_iorq_n='0' and cpm='0' and dos_act='1' and rom14='1' else '1';
RT_F1 <= RT_F1_1 and RT_F1_2;
P0 <='0' when (cpu_a_bus(7)='1' and cpu_a_bus(4 downto 0)="00011" and cpu_iorq_n='0') and ((cpm='1' and rom14='1') or (dos_act='1' and rom14='0')) else '1';
fdd_cs_n <= RT_F1 and P0;

------------------VV55------------------------
--RT_F5 <='0' when adress(7)='0' and adress(1 downto 0)="11" and iorq='0' and CPM='1' and dos='1' else '1';		-- CPM=0 & BAS=1 ПЗУ 128 1F-7F
--P1_1 <='0' when adress(7)='1' and adress(4 downto 0)="00111" and iorq='0' and CPM='0' and rom14='1' else '1';	-- CPM=1 & ROM14=1 ПЗУ DOS/ SOS 87-E7
--P1_2 <='0' when adress(7)='1' and adress(4 downto 0)="00111" and iorq='0' and dos='0' and rom14='0' else '1';	-- ROM14=0 BAS=0 ПЗУ SYS 87-E7
--vv55_cs <= RT_F5 and P1_1 and P1_2;

---- Profi RTC
--portAS <= '1' when adress(9)='0' and adress(7)='1' and adress(5)='1' and adress(3 downto 0)=X"F" and iorq='0' and cpm='0' and rom14='1' else '0';
--portDS <= '1' when adress(9)='0' and adress(7)='1' and adress(5)='0' and adress(3 downto 0)=X"F" and iorq='0' and cpm='0' and rom14='1' else '0';

process (reset, areset, clk_bus, cpu_a_bus, dos_act, cs_xxfe, cs_eff7, cs_7ffd, cs_xxfd, port_7ffd_reg, cpu_mreq_n, cpu_m1_n, cpu_wr_n, cpu_do_bus, fd_port, cs_008b, kb_turbo, kb_turbo_old)
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
		port_008b_reg <= (others => '0');
		port_018b_reg <= (others => '0');
		port_028b_reg <= (others => '0');
		dos_act <= '1';
		kb_turbo_old <= "00";
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
			if cs_xxfd = '1' and cpu_wr_n = '0' and (port_7ffd_reg(5) = '0' or port_dffd_reg(4)='1') then -- short #FD
			  port_7ffd_reg(5 downto 0) <= cpu_do_bus(5 downto 0);
			end if;
			
			if cs_7ffd = '1' and cpu_wr_n = '0' and (port_7ffd_reg(5) = '0' or port_dffd_reg(4)='1') then -- short #FD
			  port_7ffd_reg(7 downto 6) <= cpu_do_bus(7 downto 6);
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
			
			-- #008B
			if cs_008b = '1' and cpu_wr_n='0' then
				port_008b_reg <= cpu_do_bus;
			end if;
			
			-- #018B
			if cs_018b = '1' and cpu_wr_n='0' then
				port_018b_reg <= cpu_do_bus;
			end if;

			-- #028B
			if cs_028b = '1' and cpu_wr_n='0' then
				port_028b_reg <= cpu_do_bus;
			elsif kb_turbo /= kb_turbo_old then
				port_028b_reg (6 downto 5) <= kb_turbo (1 downto 0);
				kb_turbo_old <= kb_turbo;
			end if;
			
			-- TR-DOS FLAG
			if (((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 8) = X"3D" and (rom14 = '1' or unlock_128 = '1')) or (cpu_nmi_n = '0'  and DS80 = '0')) and port_dffd_reg(4) = '0') or (onrom = '1') then dos_act <= '1';
			elsif ((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00") or (port_dffd_reg(4) = '1')) then dos_act <= '0'; end if;
				
	end if;
end process;

-------------------------------------------------------------------------------
-- Audio mixer

speaker <= port_xxfe_reg(4);
BUZZER <= speaker;
tape_in_monitor <= TAPE_IN when tape_in_out_enable = '1' else '0';

audio_mono <= 	
				("0000" & speaker & "00000000000") +
				("00000" & tape_in_monitor & "0000000000") +				
				("0000"  & ssg_cn0_a &     "0000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("0000"  & ssg_cn1_a &     "0000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("0000"  & covox_a &       "0000") + 
				("0000"  & covox_b &       "0000") + 
				("0000"  & covox_c &       "0000") + 
				("0000"  & covox_d &       "0000") + 
				("0000"  & covox_fb &      "0000") + 
				("0000"  & saa_out_l &     "0000") + 				
				("0000"  & saa_out_r &     "0000");

audio_l <= "0000000000000000" when loader_act = '1' or kb_wait = '1' or sound_off = '1' else 
				audio_mono when soft_sw(9) = '1' else
				("000" & speaker & "000000000000") + -- ACB: L = A + C/2
				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_a &     "00000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("000"  & ssg_cn1_a &     "00000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("000"  & covox_a &       "00000") + 
				("000"  & covox_b &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_l  &    "00000") when soft_sw(7) = '0' else 
				("000" & speaker & "000000000000") +  -- ABC: L = A + B/2
				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_a &     "00000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("000"  & ssg_cn1_a &     "00000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("000"  & covox_a &       "00000") + 
				("000"  & covox_b &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_l  &    "00000");
				
audio_r <= "0000000000000000" when loader_act = '1' or kb_wait = '1' or sound_off = '1' else 
				audio_mono when soft_sw(9) = '1' else
				("000" & speaker & "000000000000") + -- ACB: R = B + C/2
				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_b &     "00000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("000"  & ssg_cn1_b &     "00000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("000"  & covox_c &       "00000") + 
				("000"  & covox_d &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_r &     "00000") when soft_sw(7) = '0' else
				("000" & speaker & "000000000000") + -- ABC: R = C + B/2
				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_c &     "00000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("000"  & ssg_cn1_c &     "00000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("000"  & covox_c &       "00000") + 
				("000"  & covox_d &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_r &     "00000");
				
-- Tape Out: 1/0 for revDS, open collector output for revA,B,C,D
TAPE_OUT <= port_xxfe_reg(3) when tape_in_out_enable = '1' else '0' when port_xxfe_reg(3) = '0' else 'Z';
				
-- SAA1099
saa_wr_n <= '0' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = X"FF" and dos_act = '0') else '1';

-------------------------------------------------------------------------------
-- Port I/O

mc146818_wr <= '1' when (cs_rtc_ds = '1' and cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_m1_n = '1') else '0';

-- Z-controller spi
zc_spi_start <= '1' when cpu_a_bus(7 downto 0)=X"57" and cpu_iorq_n='0' and cpu_m1_n='1' and loader_act='0' and is_flash_not_sd='0' else '0';
zc_wr_en <= '1' when cpu_a_bus(7 downto 0)=X"57" and cpu_iorq_n='0' and cpu_m1_n='1' and cpu_wr_n='0' and loader_act='0' and is_flash_not_sd='0' else '0';
port77_wr <= '1' when cpu_a_bus(7 downto 0)=X"77" and cpu_iorq_n='0' and cpu_m1_n='1' and cpu_wr_n='0' and loader_act='0' and is_flash_not_sd='0' else '0';

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
	CLC     		=> clk_bus, --clk_cpu,
	MISO    		=> DATA0,
	DO				=> zc_do_bus,
	SCK     		=> zc_sclk,
	MOSI    		=> zc_mosi
);

--ay_port 		<= '1' when cpu_a_bus(1) = '0' and cpu_a_bus(15)='1' and cpu_iorq_n = '0' and fd_port = '1' else '0';
--ay_bdir 		<= '1' when ay_port = '1' and cpu_wr_n = '0' else '0';
--ay_bc1 		<= '1' when ay_port = '1' and cpu_a_bus(14) = '1' and cpu_m1_n = '1' else '0';

-------------------------------------------------------------------------------
-- CPU0 Data bus

process (selector, cpu_a_bus, gx0, serial_ms_do_bus, ram_do_bus, mc146818_do_bus, kb_do_bus, zc_do_bus, ssg_cn0_bus, ssg_cn1_bus, port_7ffd_reg, port_dffd_reg, zxuno_uart_do_bus,
			zxuno_uart2_do_bus, cpld_do, vid_attr, port_eff7_reg, joy_bus, ms_z, ms_b, ms_x, ms_y, zxuno_addr_to_cpu, port_xxC7_reg, flash_rdy, flash_busy, flash_do_bus, port_008b_reg,
			port_018b_reg, port_028b_reg, TAPE_IN)
begin
	case selector is
		when x"00" => cpu_di_bus <= ram_do_bus;
		when x"01" => cpu_di_bus <= mc146818_do_bus;
		when x"02" => cpu_di_bus <= GX0 & TAPE_IN & kb_do_bus;
		when x"03" => cpu_di_bus <= zc_do_bus;
		when x"04" => cpu_di_bus <= "11111100";	
		when x"05" => cpu_di_bus <= joy_bus;
		when x"06" => cpu_di_bus <= ssg_cn0_bus;
		when x"07" => cpu_di_bus <= ssg_cn1_bus;
		when x"08" => cpu_di_bus <= port_dffd_reg;
		when x"09" => cpu_di_bus <= port_7ffd_reg;
		when x"0A" => cpu_di_bus <= ms_z(3 downto 0) & '1' & not(ms_b(2)) & not(ms_b(0)) & not(ms_b(1)); -- D0=right, D1 = left, D2 = middle, D3 = fourth, D4..D7 - wheel
		when x"0B" => cpu_di_bus <= ms_x;
		when x"0C" => cpu_di_bus <= ms_y;
		when x"0D" => cpu_di_bus <= zxuno_uart2_do_bus;
		when x"0E" => cpu_di_bus <= serial_ms_do_bus;
		when x"0F" => cpu_di_bus <= zxuno_addr_to_cpu;
		when x"10" => cpu_di_bus <= zxuno_uart_do_bus;
		when x"11" => cpu_di_bus <= "0000" & port_xxC7_reg(3) & port_xxC7_reg(2) & flash_rdy & flash_busy;
		when x"12" => cpu_di_bus <= flash_do_bus;
		when x"13" => cpu_di_bus <= port_008b_reg;
		when x"14" => cpu_di_bus <= port_018b_reg;
		when x"15" => cpu_di_bus <= port_028b_reg;
		when x"16" => cpu_di_bus <= vid_attr;
		when x"17" => cpu_di_bus <= cpld_do;
		when others => cpu_di_bus <= (others => '1');
	end case;
end process;

selector <= 	
	x"00" when (ram_oe_n = '0') else -- ram / rom
	x"01" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cs_rtc_ds = '1') else -- RTC MC146818A
	x"02" when (cs_xxfe = '1' and cpu_rd_n = '0') else 									-- Keyboard, port #FE
	x"03" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus(7 downto 0) = X"57" and is_flash_not_sd = '0') else 	-- Z-Controller
	x"04" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus(7 downto 0) = X"77" and is_flash_not_sd = '0') else 	-- Z-Controller
	x"05" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus( 7 downto 0) = X"1F" and dos_act = '0' and cpm = '0') else -- Joystick, port #1F
	x"06" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '0') else 			-- TurboSound
	x"07" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '1') else
	x"08" when (cs_dffd = '1' and cpu_rd_n = '0') else										-- port #DFFD
	x"09" when (cs_7ffd = '1' and cpu_rd_n = '0') else										-- port #7FFD
	x"0A" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FADF" and ms_present = '1' and cpm='0') else	-- Mouse0 port key, z
	x"0B" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FBDF" and ms_present = '1' and cpm='0') else	-- Mouse0 port x
	x"0C" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FFDF" and ms_present = '1' and cpm='0') else	-- Mouse0 port y 
	x"0D" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_uart2_oe_n = '0') else -- ZX UNO UART2
	x"0E" when (serial_ms_oe_n = '0') else -- Serial mouse
	x"0F" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_addr_oe_n = '0') else -- ZX UNO Register
	x"10" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_uart_oe_n = '0') else -- ZX UNO UART
	x"11" when (cs_xxC7 = '1' and cpu_rd_n = '0') else
	x"12" when (cs_xxE7 = '1' and cpu_rd_n = '0') else
	x"13" when (cs_008b = '1' and cpu_rd_n = '0') else										-- port #008B
	x"14" when (cs_018b = '1' and cpu_rd_n = '0') else										-- port #018B
	x"15" when (cs_028b = '1' and cpu_rd_n = '0') else										-- port #028B
	x"16" when (vid_pff_cs = '1' and cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"FF") and dos_act='0' and cpm = '0' and ds80 = '0' else -- Port FF select
	x"17" when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' else -- cpld 
	(others => '1');
	
end rtl;
