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
-- FPGA firmware for Karabas-Pro revF
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- @author Oleh Starychenko <solegstar@gmail.com>
-- Ukraine, 2021-2025
-------------------------------------------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity karabas_pro_top is
port (
	-- Clock (50MHz)
	CLK_50MHZ	: in std_logic;

	-- SRAM (2MB 2x8bit)
	SRAM_A		: buffer std_logic_vector(20 downto 0);
	SRAM_D		: inout std_logic_vector(7 downto 0);
	SRAM_WR_N	: buffer std_logic;
	
	-- SD
	SD_CS_N		: out std_logic;
	SD_MISO		: inout std_logic;
	SD_MOSI		: out std_logic;
	SD_SCK		: out std_logic;
	
	-- VGA 
	VGA_R 		: out std_logic_vector(2 downto 0);
	VGA_G 		: out std_logic_vector(2 downto 0);
	VGA_B 		: out std_logic_vector(2 downto 0);
	VGA_HS 		: out std_logic;
	VGA_VS 		: out std_logic;
		
	-- RP2040 SPI slave
	MCU_SCK 		: in std_logic;
	MCU_MOSI 	: in std_logic;
	MCU_MISO 	: out std_logic := 'Z';
	MCU_CS_N		: in std_logic;
	MCU_SD_CS_N : in std_logic;
	
	-- Parallel bus for CPLD
	BUS_RESET_N : in std_logic;
	BUS_CLK 	: in std_logic;
	BUS_CLK2 	: in std_logic;
	BUS_DIR 	: in std_logic;	-- OCH: Nemo HDD EBL for CPLD
	BUS_A		: in std_logic_vector(1 downto 0);
	BUS_DI		: in std_logic_vector(7 downto 0) := "ZZZZZZZZ";
	BUS_DO		: in std_logic_vector(7 downto 0);
	
	-- I2S Sound
	DAC_BCK		: out std_logic;
	DAC_LRCK 	: out std_logic;
	DAC_DAT 		: out std_logic;
	
   LFDC_STEP   : in std_logic;
	TAPE_IN 		: in std_logic := '1'; 
	TAPE_OUT 	: out std_logic
);
end karabas_pro_top;

architecture rtl of karabas_pro_top is

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
signal kb_status, kb_dat0, kb_dat1, kb_dat2, kb_dat3, kb_dat4, kb_dat5 : std_logic_vector(7 downto 0);
signal kb_do_bus		: std_logic_vector(5 downto 0);
signal kb_reset 		: std_logic := '0';
signal kb_magic 		: std_logic := '0';
signal kb_special 	: std_logic := '0';
signal kb_turbofdc 	: std_logic := '0';
signal kb_covox_en 	: std_logic := '0';
signal kb_video_15khz: std_logic := '0';
signal kb_video_60hz : std_logic := '0';
signal kb_swap_fdd 	: std_logic := '0';
signal kb_turbo 		: std_logic_vector(1 downto 0) := "00";
signal kb_turbo_old	: std_logic_vector(1 downto 0) := "00";
signal kb_wait 		: std_logic := '0';
signal kb_mode 		: std_logic := '1';
signal joy_mode 		: std_logic_vector(2 downto 0) := "000";
signal kb_loaded 		: std_logic := '0';
signal kb_screen_mode: std_logic_vector(1 downto 0) := "00";
signal kb_psg_mix    : std_logic_vector(2 downto 0) := "000";
signal kb_psg_type   : std_logic := '0';
signal softsw_command : std_logic_vector(15 downto 0);
signal mcu_busy      : std_logic := '0';

-- Joy
signal joystick_md   : std_logic_vector(12 downto 0) := "0000000000000";
signal joy_bus 		: std_logic_vector(7 downto 0) := "00000000";

-- Mouse
signal ms_x				: std_logic_vector(7 downto 0);
signal ms_y				: std_logic_vector(7 downto 0);
signal ms_z				: std_logic_vector(3 downto 0);
signal ms_b				: std_logic_vector(2 downto 0);
signal ms_present 	: std_logic := '1';
signal ms_event		: std_logic := '0';
signal ms_delta_x    : signed(7 downto 0);
signal ms_delta_y    : signed(7 downto 0);

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

--- DivMMC
signal divmmc_en		: std_logic;
signal automap			: std_logic;
--signal detect			: std_logic;
signal port_e3_reg   : std_logic_vector(7 downto 0);
signal mapterm 		: std_logic;
signal map3DXX 		: std_logic; 
signal map1F00 		: std_logic;
signal mapcond 		: std_logic;


-- MC146818A
signal mc146818_wr		: std_logic;
signal mc146818_rd		: std_logic;
signal mc146818_a_bus	: std_logic_vector(7 downto 0);
signal mc146818_do_bus	: std_logic_vector(7 downto 0);
signal mc146818_busy		: std_logic;
signal port_eff7_reg		: std_logic_vector(7 downto 0);

-- Port selectors
signal fd_port 		: std_logic;
signal fd_sel 			: std_logic;
signal cs_xxfe 		: std_logic := '0'; 
signal cs_eff7 		: std_logic := '0';
signal cs_7ffd 		: std_logic := '0';
signal cs_1ffd 		: std_logic := '0';
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
signal hdd_active 		:std_logic;

-- Nemo HDD ports
signal nemoide_en 		: std_logic;
signal cs_nemo_ports		: std_logic;

signal nemo_ebl_n			: std_logic;
signal IOW					: std_logic;
signal WRH 					: std_logic;
signal IOR 					: std_logic;
signal RDH 					: std_logic;
signal nemo_cs0			: std_logic;
signal nemo_cs1			: std_logic;
signal nemo_ior			: std_logic;

-- Profi FDD ports
signal RT_F2_1			: std_logic;
signal RT_F2_2			: std_logic;
signal RT_F2_3			: std_logic;
signal fdd_cs_pff_n	: std_logic;
signal RT_F1_1			: std_logic;
signal RT_F1_2			: std_logic;
signal RT_F1			: std_logic;
signal P0				: std_logic;
signal fdd_cs_n		: std_logic;
signal fdd_cnt			: std_logic_vector(7 downto 0) := x"FF";
signal fdd_wait		: std_logic;

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
signal ena_cnt		: std_logic_vector(3 downto 0) := "0000";

-- System
signal reset			: std_logic;
signal areset			: std_logic;
signal locked 			: std_logic;
signal loader_act		: std_logic := '0';
signal dos_act			: std_logic := '1';
signal clk_cpu			: std_logic;
signal selector		: std_logic_vector(7 downto 0);
signal mux				: std_logic_vector(3 downto 0);
signal speaker 		: std_logic := '0';
signal tape_in_monitor : std_logic := '0';
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
signal loader_ram_a	: std_logic_vector(31 downto 0);
signal loader_ram_wr : std_logic;

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
signal is_flash_not_sd : std_logic := '0';

signal port_xx87_reg : std_logic_vector(7 downto 0);
signal port_xxA7_reg : std_logic_vector(7 downto 0);
signal port_xxC7_reg : std_logic_vector(7 downto 0);
signal port_xxE7_reg : std_logic_vector(7 downto 0);
signal port_xx67_reg : std_logic_vector(7 downto 0);

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
signal zxuno_uart_tx : std_logic;
signal zxuno_uart_cts : std_logic;

-- ZIFI UART 
signal zifi_do_bus : std_logic_vector(7 downto 0);
signal zifi_oe_n   : std_logic := '1';
signal zifi_uart_tx : std_logic;
signal zifi_uart_cts : std_logic;
signal zifi_api_enabled : std_logic;

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

component PCM5102
port (
    clk : in std_logic;
    reset : in std_logic;
    left : in std_logic_vector(15 downto 0);
    right : in std_logic_vector(15 downto 0);
    din : out std_logic;
    bck : out std_logic;
    lrck : out std_logic);
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
	locked 			=> locked,
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
	HALT_n			=> open,
	BUSAK_n			=> open,
	A					=> cpu_a_bus,
	DIN					=> cpu_di_bus,
	DOUT					=> cpu_do_bus
);
	
-- memory manager
U6: entity work.memory 
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
	RAM_6MB 			=> '0', 
	
	-- loader signals
	loader_act 		=> loader_act,
	loader_ram_a 	=> loader_ram_a(20 downto 0),
	loader_ram_do 	=> loader_ram_do,
	loader_ram_wr 	=> loader_ram_wr,
	-- ram 
	MA 				=> SRAM_A,
	MD 				=> SRAM_D,
	N_MRD 			=> open,
	N_MWR 			=> SRAM_WR_N,
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

	DS80 				=> ds80,
	CPM 				=> cpm,
	SCO 				=> sco,
	SCR 				=> scr,
	WOROM 			=> worom,

	-- rom
	ROM_BANK 		=> rom14,      -- 0 B128, 1 B48
	EXT_ROM_BANK   => ext_rom_bank_pq,
	
	-- contended memory signals
	COUNT_BLOCK		=> count_block,
	CONTENDED 		=> memory_contention,
	-- OCH: added to not contend in turbo mode
	TURBO_MODE 		=> turbo_mode,
	
	-- DIVMMC signals
   DIVMMC_EN		=> divmmc_en,
	AUTOMAP			=> automap,
	REG_E3		   => port_e3_reg
);	

-- Video Spectrum/Pentagon
U7: entity work.video
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
	MODE60			=> kb_video_60hz,
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
	ISPAPER 			=> vid_ispaper,
	BLINK 			=> blink,
	SCREEN_MODE    => kb_screen_mode,
	COUNT_BLOCK 	=> count_block
);

-- osd overlay
U8: entity work.overlay
generic map (
	enable_osd_icons => true
)
port map (
	CLK 				=> clk_bus,
	CLK2 				=> clk_div2,
	CLK4 				=> clk_div4,
	DS80				=> ds80,
	RGB_I 			=> vid_rgb,
	RGB_O 			=> vid_rgb_osd,
	HCNT_I 			=> vid_hcnt,
	VCNT_I 			=> vid_vcnt,
	PAPER_I 			=> vid_ispaper,
	BLINK 			=> blink,

	-- icons
	STATUS_FD		=> not(fdd_cs_n) and (not(cpu_rd_n) or not(cpu_wr_n)),
	STATUS_SD 		=> zc_spi_start and zc_wr_en,
	STATUS_CF 		=> hdd_active,
	OSD_ICONS 		=> '1',
	
	-- osd overlay
	OSD_OVERLAY		=> osd_overlay,
	OSD_POPUP 		=> osd_popup,
	OSD_COMMAND 	=> osd_command
);

-- osd_overlay / osd_popup signals from osd_command
process (clk_bus) 
begin
	if rising_edge(clk_bus) then 
		case (osd_command(15 downto 8)) is
			when x"01" => osd_overlay <= osd_command(0);
			when x"02" => osd_popup <= osd_command(0);
			when others => null;
		end case;
	end if;
end process;

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

-- TurboSound
U10: entity work.turbosound
port map (
	I_CLK				=> clk_bus,
	I_ENA				=> ena_div16,
	I_ADDR			=> cpu_a_bus,
	I_DATA			=> cpu_do_bus,
	I_WR_N			=> cpu_wr_n,
	I_IORQ_N			=> cpu_iorq_n,
	I_M1_N			=> cpu_m1_n,
	I_RESET_N		=> cpu_reset_n,
	I_BDIR 			=> '1', 
	I_BC1 			=> '1', 
	O_SEL				=> ssg_sel,
	I_MODE 			=> kb_psg_type,
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
U11: entity work.covox
port map (
	I_RESET			=> reset,
	I_CLK				=> clk_bus,
	I_CS				=> kb_covox_en,
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
	 
U12: saa1099
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

-- MCU Keyboard / mouse / rtc
U13: entity work.mcu 
port map(
	CLK 				=> clk_bus,
   RESET				=> areset,

   MCU_MOSI			=> MCU_MOSI,
   MCU_MISO			=> MCU_MISO,
   MCU_SCK			=> MCU_SCK,
   MCU_CS_N			=> MCU_CS_N,
     
   MS_X				=> ms_x,
   MS_Y				=> ms_y,
   MS_Z				=> ms_z,
   MS_B				=> ms_b,
   MS_UPD			=> ms_event,
     
   KB_STATUS		=> kb_status,
   KB_DAT0			=> kb_dat0,
   KB_DAT1			=> kb_dat1,
   KB_DAT2			=> kb_dat2,
   KB_DAT3			=> kb_dat3,
   KB_DAT4			=> kb_dat4,
   KB_DAT5			=> kb_dat5,
     
   KB_SCANCODE		=> open, --kb_scancode,
   KB_SCANCODE_UPD => open, --kb_scancode_upd,

   JOYSTICK			=> joystick_md,

   RTC_A 			=> mc146818_a_bus,
   RTC_DI			=> cpu_do_bus,
   RTC_DO			=> mc146818_do_bus,
   RTC_CS			=> '1',
   RTC_WR_N			=> not mc146818_wr,

   usb_uart_rx_data => open, --usb_uart_rx_data,
   usb_uart_rx_idx  => open, --usb_uart_rx_idx,
   usb_uart_tx_data => (others => '0'), --usb_uart_tx_data,
   usb_uart_tx_wr   => '0', --usb_uart_tx_wr,
   usb_uart_tx_mode => '0', --usb_uart_tx_mode,

   usb_uart_dll     => (others => '0'), --usb_uart_dll,
   usb_uart_dlm     => (others => '0'), --usb_uart_dlm,
   usb_uart_dll_wr  => '0', --usb_uart_dll_wr,
   usb_uart_dlm_wr  => '0', --usb_uart_dlm_wr,
	 
   esp_uart_rx_data => open, --esp_uart_rx_data,
   esp_uart_rx_idx  => open, --esp_uart_rx_idx,
   esp_uart_tx_data => (others => '0'), --esp_uart_tx_data,
   esp_uart_tx_wr   => '0', --esp_uart_tx_wr,

   softsw_command   => softsw_command,
   osd_command      => osd_command,

   romloader_active => loader_act,
   romload_addr     => loader_ram_a,
   romload_data     => loader_ram_do,
   romload_wr       => loader_ram_wr,
     
   flash_a          => (others => '0'), --flash_a_bus,
   flash_do         => open, --flash_do_bus,
   flash_di         => (others => '0'), --flash_di_bus,
   flash_rd_n       => '1', --flash_rd_n,
   flash_wr_n       => '1', --flash_wr_n,
   flash_er_n       => '1', --flash_er_n,
   flash_busy       => open, --flash_busy,
   flash_ready      => open, --flash_ready, 
     
   debug_addr       => (others => '0'),
   debug_data       => (others => '0'),

   busy             => mcu_busy
);

U14: entity work.soft_switches
port map(
    CLK => clk_bus,
    SOFTSW_COMMAND => softsw_command,
     
    ROM_BANK => ext_rom_bank,
    TURBOFDC => kb_turbofdc,
    COVOX_EN => kb_covox_en,
    PSG_MIX  => kb_psg_mix,
    PSG_TYPE => kb_psg_type,
    VIDEO_15KHZ => kb_video_15khz,
    VIDEO_60HZ  => kb_video_60hz,
    TURBO       => kb_turbo,
    SWAP_FDD    => kb_swap_fdd,
    VIDEO_MODE  => kb_screen_mode,
    JOY_TYPE    => joy_mode,
    DIVMMC_EN   => divmmc_en,
    NEMOIDE_EN  => nemoide_en,
    KEYBOARD_TYPE => kb_mode,
    PAUSE         => kb_wait,
    NMI           => kb_magic,
    RESET         => kb_reset
);

vid_scandoubler_enable <= not kb_video_15khz;

U15: entity work.hid_parser
generic map(
	NUM_KEYS => 6
)
port map(
	CLK			=> clk_bus,
   RESET       => areset,
   KB_STATUS   => kb_status,
   KB_DAT0     => kb_dat0,
   KB_DAT1     => kb_dat1,
   KB_DAT2     => kb_dat2,
   KB_DAT3     => kb_dat3,
   KB_DAT4     => kb_dat4,
   KB_DAT5     => kb_dat5,
     
   KB_SCANCODE => (others => '0'), --kb_scancode,
   KB_SCANCODE_UPD => '0', --kb_scancode_upd,
     
   JOY_TYPE_L  => joy_mode,
   JOY_TYPE_R  => "000",
   JOY_L       => joystick_md,
   JOY_R       => "0000000000000",
     
   A           => cpu_a_bus(15 downto 8),
   KB_TYPE     => kb_mode,
   JOY_DO      => joy_bus,
   KB_DO       => kb_do_bus,

	-- todo: mapping keyboard scancodes to the rtc registers
   RTC_A       => mc146818_a_bus,
   RTC_DI      => cpu_do_bus,
   RTC_DO_IN   => mc146818_do_bus,
   RTC_DO_OUT  => open,
   RTC_WR      => '0',
   RTC_RD      => '0'
);
	
-- DAC
U16: PCM5102
port map(
    clk => clk_bus,
    reset => areset,
    left => audio_l,
    right => audio_r,
    din => DAC_DAT,
    bck => DAC_BCK,
    lrck => DAC_LRCK
);

-- FDD / HDD controllers
U17: entity work.bus_port
port map (
	CLK 				=> clk_bus_port,
	CLK2 				=> clk_8,
	CLK_BUS 			=> clk_bus,
	CLK_CPU 			=> clk_cpu,
	RESET 			=> reset,
	
	SD_DI => open, --BUS_DO,
	SD_DO => BUS_DI,
	SA 				=> open, --BUS_A,
	CPLD_CLK 		=> open, --BUS_CLK,
	CPLD_CLK2 		=> open, --BUS_CLK2,
	NRESET 			=> open, --BUS_RESET_N,
	-- OCH: fix fdd swap
	FDC_SWAP			=> fdc_swap,

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
	BUS_FDC_STEP	=>	LFDC_STEP and turbo_fdc_off,
	BUS_CSFF			=> fdd_cs_pff_n,
	BUS_FDC_NCS		=> fdd_cs_n,
	
	-- Nemo HDD bus signals
	BUS_A7				=> cpu_a_bus(7),
	BUS_nemo_ebl_n		=> nemo_ebl_n, -- OCH: also nemo_ebl_n is passed to CPLD via SDIR pin to select NEMOIDE HDD
	BUS_IOW				=> IOW,
	BUS_WRH 				=> WRH,
	BUS_IOR 				=> IOR,
	BUS_RDH 				=> RDH,
	BUS_nemo_cs0		=> nemo_cs0,
	BUS_nemo_cs1		=> nemo_cs1
);

-- Serial mouse emulation
U18: entity work.serial_mouse
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

ms_delta_x <= signed(ms_x);
ms_delta_y <= signed(ms_y);

-- todo: zifi_emu, zxuno_emu

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
	
-------------------------------------------------------------------------------
-- Global signals

areset <= not locked;
reset <= areset or kb_reset or loader_act; -- hot reset

cpu_reset_n <= not(reset); -- CPU reset
cpu_inta_n <= cpu_iorq_n or cpu_m1_n;	-- INTA

-- 11.07.2013:OCH: implementation of nmi signal for DIVMMC
cpu_nmi_n <= mapcond when kb_magic = '1' and divmmc_en = '1' else 
	'0' when divmmc_en = '0' and kb_magic = '1' and ((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00") or DS80 = '1') else 
	'1';
cpu_wait_n <= '1';

-- max turbo = 14 MHz
max_turbo <= "10";

--OCH: automap = '0' and cs_nemo_ports = '0' - not contend DIVMMC and NEMO ports in CLASSIC screen mode
clk_cpu <= '0' when kb_wait = '1' or  (kb_screen_mode = "01" and memory_contention = '1' and automap = '0' and cs_nemo_ports = '0' and DS80 = '0') or WAIT_IO = '0' else 
	clk_bus when fdd_wait='1' and turbo_mode = "11" and turbo_mode <= max_turbo else 
	-- OCH: disable turbo in trdos to be sure what all programming delays are original
	-- 06.09.2023:OCH: fixed turbo mode by adding all condition when it can be enabled, i'm not sure about ds80 = 1 but let it be
	clk_bus and ena_div2 when fdd_wait='1' and turbo_mode = "10" and turbo_mode <= max_turbo else 
	clk_bus and ena_div4 when fdd_wait='1' and turbo_mode = "01" and turbo_mode <= max_turbo else 
	clk_bus and ena_div8;

-- одновибратор - по спаду /IORQ отсчитывает 400нс вейта проца 
-- для работы периферии в турбе или в режиме расширенного экрана 

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

-------------------------------------------------------------------------------
-- SD

SD_CS_N	<= '1' when loader_act = '1' else zc_cs_n;
SD_SCK 	<= '1' when loader_act = '1' else zc_sclk;
SD_MOSI 	<= '1' when loader_act = '1' else zc_mosi;

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
turbo_fdc_off <= not port_028b_reg(2) and kb_turbofdc;	-- 2 	- TURBO_FDC_off
fdc_swap <= port_028b_reg(3) or kb_swap_fdd;					-- 3 	- Floppy Disk Drive Selector Change
sound_off <= port_028b_reg(4);									-- 4 	- Sound_off
turbo_mode <= port_028b_reg(6 downto 5);						-- 5,6- Turbo Mode Selector 
lock_dffd <= port_028b_reg(7);								 	-- 7 	- Lock port DFFD

-- OCH: fdd currently disabled, should be implemented with xFF (TRDOS) port bit swapping
-- the SDIR pin now used to select NEMOIDE HDD
--SDIR <= fdc_swap;

ext_rom_bank_pq <= ext_rom_bank when rom0 = '0' else "01";	-- ROMBANK ALT

rom14 <= port_7ffd_reg(4); -- rom bank
cpm 	<= port_dffd_reg(5); -- 1 - блокирует работу контроллера из ПЗУ TR-DOS и включает порты на доступ из ОЗУ (ROM14=0); При ROM14=1 - мод. доступ к расширен. периферии
worom <= port_dffd_reg(4); -- 1 - отключает блокировку порта 7ffd и выключает ПЗУ, помещая на его место ОЗУ из seg 00
ds80 	<= port_dffd_reg(7); -- 0 = seg05 spectrum bitmap, 1 = profi bitmap seg06 & seg 3a & seg 04 & seg 38
scr 	<= port_dffd_reg(6); -- памяти CPU на место seg 02, при этом бит D3 CMR0 должен быть в 1 (#8000-#BFFF)
sco 	<= port_dffd_reg(3); -- Выбор положения окна проецирования сегментов:
									-- 0 - окно номер 1 (#C000-#FFFF)
									-- 1 - окно номер 2 (#4000-#7FFF)

-- Extended memory for 1MB (default) or 6MB boards
--ram_ext <= port_1ffd_reg(7) & port_1ffd_reg(4) & port_dffd_reg(2 downto 0); -- kay512+ profi 1024
ram_ext <= port_7ffd_reg(6) & port_7ffd_reg(7) & port_dffd_reg(2 downto 0); -- pent 512 + profi 1024

-- OCH: change decoding of #FE port when Nemo enabled  
cs_xxfe <= '1' when (cpu_iorq_n = '0' and cpu_a_bus(0) = '0' and nemoide_en = '0') or 
						  (cpu_iorq_n = '0' and cpu_a_bus(6 downto 0) = "1111110" and nemoide_en = '1') else '0';
cs_xx7e <= '1' when cs_xxfe = '1' and cpu_a_bus(7) = '0' else '0';
cs_eff7 <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"EFF7" else '0';
cs_fffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"FFFD" and fd_port = '1' else '0';
cs_dffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"DFFD" and fd_port = '1' and lock_dffd = '0' else '0';
cs_7ffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"7FFD" and fd_port = '1' else '0';
cs_1ffd <= '1' when cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus = X"1FFD" and fd_port = '1' else '0';
-- OCH: change decoding of #FD port when Nemo enabled
cs_xxfd <= '1' when (cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(15) = '0' and cpu_a_bus(1) = '0' and nemoide_en = '0') or
						  (cpu_iorq_n = '0' and cpu_m1_n = '1' and cpu_a_bus(15) = '0' and cpu_a_bus(7 downto 0) = x"FD" and nemoide_en = '1') else '0';
						  
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
hdd_active <= not(hdd_wwc_n and hdd_wwe_n and hdd_rww_n and hdd_rwe_n) or not(WRH and IOW and IOR and RDH);

-- порты Nemo HDD

--0XF0			;РЕГИСТР СОСТОЯНИЯ/РЕГИСТР КОМАНД
--0XD0			;CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
--0XB0			;CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
--0X90			;CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
--0X70			;CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
--0X50			;СЧЕТЧИК СЕКТОРОВ
--0X30			;ПОРТ ОШИБОК/СВОЙСТВ
--0X10			;ПОРТ ДАННЫХ
--0XC8			;РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
--0X11			;СТАРШИЕ 8 БИТ

cs_nemo_ports <= '1' when (cpu_a_bus(7 downto 0) = x"F0" or 
									cpu_a_bus(7 downto 0) = x"D0" or 
									cpu_a_bus(7 downto 0) = x"B0" or 
									cpu_a_bus(7 downto 0) = x"90" or 
									cpu_a_bus(7 downto 0) = x"70" or 
									cpu_a_bus(7 downto 0) = x"50" or 
									cpu_a_bus(7 downto 0) = x"30" or 
									cpu_a_bus(7 downto 0) = x"10" or 
									cpu_a_bus(7 downto 0) = x"C8" or 
									cpu_a_bus(7 downto 0) = x"11") and cpu_iorq_n = '0' and cpm = '0' else '0'; 

nemo_ebl_n <= '0' when cs_nemo_ports = '1' and cpu_m1_n='1' and nemoide_en = '1' else '1';
IOW <='0' when cpu_a_bus(2 downto 0)="000" and cpu_m1_n='1' and cpu_iorq_n='0' and cpm='0' and cpu_wr_n='0' else '1';
WRH <='0' when cpu_a_bus(2 downto 0)="001" and cpu_m1_n='1' and cpu_iorq_n='0' and cpm='0' and cpu_wr_n='0' else '1';
IOR <='0' when cpu_a_bus(2 downto 0)="000" and cpu_m1_n='1' and cpu_iorq_n='0' and cpm='0' and cpu_rd_n='0' else '1';
RDH <='0' when cpu_a_bus(2 downto 0)="001" and cpu_m1_n='1' and cpu_iorq_n='0' and cpm='0' and cpu_rd_n='0' else '1';
nemo_cs0<= cpu_a_bus(3) when nemo_ebl_n='0' else '1';
nemo_cs1<= cpu_a_bus(4) when nemo_ebl_n='0' else '1';
nemo_ior<= ior when nemo_ebl_n='0' else '1';
-- OCH:
--BUS_DIR <= not nemo_ebl_n;

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

process (ena_div4, reset)
begin
	if reset='1' then
		fdd_cnt <= x"FF";
	elsif ena_div4'event and ena_div4='1' then
		if fdd_cs_n='0' and ((cpu_rd_n='0') or (cpu_wr_n='0')) then
			fdd_cnt <= x"00";
		elsif fdd_cnt <= x"7F" then
			fdd_cnt <= fdd_cnt + 1;
		else
			fdd_cnt <= x"FF";
		end if;
	end if;
end process;

fdd_wait <= fdd_cnt(7);

-- Ports
process (reset, areset, clk_bus, cpu_a_bus, dos_act, cs_xxfe, cs_eff7, cs_7ffd, cs_xxfd, port_7ffd_reg, port_1ffd_reg, cpu_mreq_n, cpu_m1_n, cpu_wr_n, cpu_do_bus, fd_port, cs_008b, kb_turbo, kb_turbo_old)
begin
	if reset = '1' then
		port_eff7_reg <= (others => '0');
		port_7ffd_reg <= (others => '0');
		port_1ffd_reg <= (others => '0');
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
--- 06.07.2023:OCH: DIVMMC port added to ZController
		port_e3_reg(5 downto 0) <= (others => '0');
		port_e3_reg(7) <= '0';
		
	elsif clk_bus'event and clk_bus = '1' then
--- 06.07.2023:OCH: DIVMMC port E3 added to ZController
			-- #xxE3
--- 08.07.2023:OCH: Due to confict with port (E3) of fddcontroller in cpm mode
--- block DIVMMC port E3 when in cpm
			if (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = X"E3" and cpm = '0' and divmmc_en = '1') then	
				port_e3_reg <=cpu_do_bus(7) & (port_e3_reg(6) or cpu_do_bus(6)) & cpu_do_bus(5 downto 0);
			end if;		
			
			-- #EFF7
			if cs_eff7 = '1' and cpu_wr_n = '0' then 
				port_eff7_reg <= cpu_do_bus; 
			end if;
			
			-- profi RTC #BF / #FF
			if cs_rtc_as = '1' and cpu_wr_n = '0' then 
				mc146818_a_bus <= cpu_do_bus(7 downto 0); 
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
			
			-- #1FFD
			if cs_1ffd = '1' and cpu_wr_n = '0' then -- #1FFD
			  port_1ffd_reg <= cpu_do_bus;
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
			if (((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 8) = X"3D" and (rom14 = '1' or unlock_128 = '1')) or 
			(cpu_nmi_n = '0'  and DS80 = '0')) and port_dffd_reg(4) = '0') or (onrom = '1') then dos_act <= '1';
			elsif ((cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus(15 downto 14) /= "00") or (port_dffd_reg(4) = '1')) then dos_act <= '0'; end if;
				
	end if;
end process;

-------------------------------------------------------------------------------
-- Audio mixer

speaker <= port_xxfe_reg(4);
--BUZZER <= speaker;
tape_in_monitor <= not(TAPE_IN);

audio_mono <= 	
				("0000" & speaker & "00000000000") +
--				("00000" & tape_in_monitor & "0000000000") +				
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
				audio_mono when kb_psg_mix(1) = '1' else
				("000" & speaker & "000000000000") + -- ACB: L = A + C/2
--				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_a &     "00000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("000"  & ssg_cn1_a &     "00000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("000"  & covox_a &       "00000") + 
				("000"  & covox_b &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_l  &    "00000") when kb_psg_mix(0) = '0' else 
				("000" & speaker & "000000000000") +  -- ABC: L = A + B/2
--				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_a &     "00000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("000"  & ssg_cn1_a &     "00000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("000"  & covox_a &       "00000") + 
				("000"  & covox_b &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_l  &    "00000");
				
audio_r <= "0000000000000000" when loader_act = '1' or kb_wait = '1' or sound_off = '1' else 
				audio_mono when kb_psg_mix(1) = '1' else
				("000" & speaker & "000000000000") + -- ACB: R = B + C/2
--				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_b &     "00000") + 
				("0000"  & ssg_cn0_c &     "0000") + 
				("000"  & ssg_cn1_b &     "00000") + 
				("0000"  & ssg_cn1_c &     "0000") + 
				("000"  & covox_c &       "00000") + 
				("000"  & covox_d &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_r &     "00000") when kb_psg_mix(0) = '0' else
				("000" & speaker & "000000000000") + -- ABC: R = C + B/2
--				("00000" & tape_in_monitor & "0000000000") +	
				("000"  & ssg_cn0_c &     "00000") + 
				("0000"  & ssg_cn0_b &     "0000") + 
				("000"  & ssg_cn1_c &     "00000") + 
				("0000"  & ssg_cn1_b &     "0000") + 
				("000"  & covox_c &       "00000") + 
				("000"  & covox_d &       "00000") + 
				("000"  & covox_fb &      "00000") + 
				("000"  & saa_out_r &     "00000");
				
-- Tape Out
TAPE_OUT <= port_xxfe_reg(3);
				
-- SAA1099
saa_wr_n <= '0' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = X"FF" and dos_act = '0') else '1';

---------------------------------------------------------------------------------
-- Port I/O

mc146818_wr <= '1' when (cs_rtc_ds = '1' and cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_m1_n = '1') else '0';


--- 06.07.2023:OCH: DIVMMC ports added to ZController
-- Z-controller + DIVMMC spi 
zc_spi_start <= '1' when (cpu_a_bus(7 downto 0) = X"57" or (cpu_a_bus(7 downto 0) = X"EB" and cpm = '0' and divmmc_en = '1')) and cpu_iorq_n='0' and cpu_m1_n='1' and loader_act='0' and is_flash_not_sd='0' else '0';
zc_wr_en <= '1' when (cpu_a_bus(7 downto 0) = X"57" or (cpu_a_bus(7 downto 0) = X"EB" and cpm = '0' and divmmc_en = '1')) and cpu_iorq_n='0' and cpu_m1_n='1' and cpu_wr_n='0' and loader_act='0' and is_flash_not_sd='0' else '0';
port77_wr <= '1' when (cpu_a_bus(7 downto 0) = X"77" or (cpu_a_bus(7 downto 0) = X"E7" and divmmc_en = '1')) and cpu_iorq_n='0' and cpu_m1_n='1' and cpu_wr_n='0' and loader_act='0' and is_flash_not_sd='0' else '0';

process (port77_wr, loader_act, reset, clk_bus)
	begin
		if loader_act='1' or reset='1' then
			zc_cs_n <= '1';
		elsif clk_bus'event and clk_bus='1' then
--- 06.07.2023:OCH: DIVMMC uses 0 bit to control zc_cs_n, instead of 1 bit ZController. 
--- Lets check port number and select correct bit
--			if port77_wr='1' then
--				zc_cs_n <= cpu_do_bus(1);
--			end if;
			if port77_wr='1' then
--- 08.07.2023:OCH: E7 port confict with E7 port of SPI Flash parallel interface so block
--- DIVMMC E7 port when flash loader software active   
				if cpu_a_bus(7 downto 0) = X"E7" and ext_rom_bank(1 downto 0) /= "10" then
					zc_cs_n <= cpu_do_bus(0);
				else
					zc_cs_n <= cpu_do_bus(1);
				end if;
			end if;
		end if;
end process;

U_ZC_SPI: entity work.zc_spi     -- SD
port map(
	DI				=> cpu_do_bus,
	START			=> zc_spi_start,
	WR_EN			=> zc_wr_en,
	CLC     		=> clk_bus, --clk_cpu,
	MISO    		=> SD_MISO,
	DO				=> zc_do_bus,
	SCK     		=> zc_sclk,
	MOSI    		=> zc_mosi
);

------------------------ divmmc-----------------------------
-- Engineer:   Mario Prato
-- 11.07.2013:OCH: adapted by me
-- i take this implementation to correctly and easy make nmi 

process (reset, divmmc_en, cpu_a_bus)
begin
	if reset = '1' or divmmc_en = '0' then 
		mapterm <= '0';
		map3DXX <= '0';
		map1F00 <= '1';
	else
		 if cpu_a_bus(15 downto 0) = x"0000"   or 
									 cpu_a_bus(15 downto 0) = x"0008"   or 
									 cpu_a_bus(15 downto 0) = x"0038"   or 
									 cpu_a_bus(15 downto 0) = x"0066"   or 
									 cpu_a_bus(15 downto 0) = x"04c6"   or 
									 cpu_a_bus(15 downto 0) = x"0562" then 
			mapterm <= '1';
		else 
			mapterm <= '0';
		end if;	

		-- mappa 3D00 - 3DFF
		if cpu_a_bus(15 downto 8) = "00111101" then 
			map3DXX <= '1'; 
		else 
			map3DXX <= '0';
		end if; 

		-- 1ff8 - 1fff
		if cpu_a_bus(15 downto 3) =   "0001111111111" then 
			map1F00 <= '0';
		else 
			map1F00 <= '1';
		end if; 
	end if;
end process;

process(reset, divmmc_en, cpu_mreq_n, cpu_m1_n, mapcond, mapterm, map3DXX, map1F00, automap)
begin
	if reset = '1' or divmmc_en = '0' then 
		mapcond <= '0';
		automap <= '0';
   elsif falling_edge(cpu_mreq_n) then
		   if cpu_m1_n = '0' then
				 mapcond <= (mapterm or map3DXX or (mapcond and map1F00)) and divmmc_en;
				 automap <= (mapcond or map3DXX) and divmmc_en;
		  end if;
	end if;	  
end process; 

-------------------------------------------------------------------------------
-- CPU Data bus

process (selector, cpu_a_bus, gx0, serial_ms_do_bus, ram_do_bus, mc146818_do_bus, kb_do_bus, zc_do_bus, ssg_cn0_bus, ssg_cn1_bus, port_7ffd_reg, port_dffd_reg, zxuno_uart_do_bus,
			zxuno_uart2_do_bus, cpld_do, vid_attr, port_eff7_reg, joy_bus, ms_z, ms_b, ms_x, ms_y, zxuno_addr_to_cpu, port_xxC7_reg, flash_rdy, flash_busy, flash_do_bus, port_008b_reg,
			port_018b_reg, port_028b_reg, TAPE_IN)
begin
	case selector is
		when x"00" => cpu_di_bus <= ram_do_bus;
		when x"01" => cpu_di_bus <= mc146818_do_bus;
		when x"02" => cpu_di_bus <= GX0 & not(TAPE_IN) & kb_do_bus;
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
		when x"16" => cpu_di_bus <= zifi_do_bus;
		when x"17" => cpu_di_bus <= vid_attr;
		when x"18" => cpu_di_bus <= cpld_do;
		when x"19" => cpu_di_bus <= cpld_do; -- nemo
		when others => cpu_di_bus <= (others => '1');
	end case;
end process;

selector <= 	
	x"00" when (ram_oe_n = '0') else -- ram / rom
	x"01" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cs_rtc_ds = '1') else -- RTC MC146818A
	x"02" when (cs_xxfe = '1' and cpu_rd_n = '0') else 									-- Keyboard, port #FE
	x"19" when (nemo_ebl_n = '0' and cpu_rd_n = '0') else									-- nemo
 	x"03" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and (cpu_a_bus(7 downto 0) = X"57" or (cpu_a_bus(7 downto 0) = X"EB" and cpm = '0' and divmmc_en = '1')) and is_flash_not_sd = '0') else 	-- Z-Controller + DivMMC
	x"04" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus(7 downto 0) = X"77" and is_flash_not_sd = '0') else 	-- Z-Controller
	x"05" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' and cpu_a_bus( 7 downto 0) = X"1F" and dos_act = '0' and cpm = '0' and joy_mode = "000") else -- Joystick, port #1F
	x"06" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '0') else 			-- TurboSound
	x"07" when (cs_fffd = '1' and cpu_rd_n = '0' and ssg_sel = '1') else
	x"08" when (cs_dffd = '1' and cpu_rd_n = '0') else										-- port #DFFD
	x"09" when (cs_7ffd = '1' and cpu_rd_n = '0') else										-- port #7FFD
	x"0A" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FADF" and ms_present = '1' and cpm='0') else	-- Mouse0 port key, z
	x"0B" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FBDF" and ms_present = '1' and cpm='0') else	-- Mouse0 port x
	x"0C" when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"FFDF" and ms_present = '1' and cpm='0') else	-- Mouse0 port y 
--	x"0D" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_uart2_oe_n = '0') else -- ZX UNO UART2
	x"0E" when (serial_ms_oe_n = '0') else -- Serial mouse
--	x"0F" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_addr_oe_n = '0') else -- ZX UNO Register
--	x"10" when (enable_zxuno_uart and cpu_iorq_n = '0' and cpu_rd_n = '0' and zxuno_uart_oe_n = '0') else -- ZX UNO UART
	x"11" when (cs_xxC7 = '1' and cpu_rd_n = '0') else
	x"12" when (cs_xxE7 = '1' and cpu_rd_n = '0') else
	x"13" when (cs_008b = '1' and cpu_rd_n = '0') else										-- port #008B
	x"14" when (cs_018b = '1' and cpu_rd_n = '0') else										-- port #018B
	x"15" when (cs_028b = '1' and cpu_rd_n = '0') else										-- port #028B
--	x"16" when zifi_oe_n = '0' else  -- zifi
	x"17" when (vid_pff_cs = '1' and cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"FF") and dos_act='0' and cpm = '0' and ds80 = '0' else -- Port FF select
	x"18" when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_m1_n = '1' else -- cpld 
	(others => '1');
	
end rtl;
