`timescale 1ns / 1ps
`default_nettype none

/*-------------------------------------------------------------------------------------------------------------------
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
-- FPGA Profi core for Karabas-Pro revF
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2026
------------------------------------------------------------------------------------------------------------------*/

// TODO:
// 1. refactoring: move cpld module from profi to top level as fdd/hdd signals and zx_bus* (cpu) signals
// 2. flash: implement parallel flash tx/rx via mcu side
// 3. refactoring: translate all vhdl modules to verilog
// 4. new top level for old board revisions
// 5. osd: add icons

module karabas_pro_top (
    //----------------- GLobal clock ---------
    input wire          CLK_50MHZ,

    //----------------- SRAM -----------------
    output wire [20:0]  SRAM_A,
    inout wire [7:0]    SRAM_D,
    output wire         SRAM_WR_N,

    //----------------- SPI Master for SD ---
    output wire         SD_CS_N,
    output wire         SD_SCK,     // ASDO
    inout wire          SD_MISO,    // DATA0
    output wire         SD_MOSI,    // dedicated SD MOSI 
    // DCLK - can not be used! remains only for PS programming!
	 
    //----------------- VGA ------------------
    output wire [2:0]   VGA_R,
    output wire [2:0]   VGA_G,
    output wire [2:0]   VGA_B,
    output wire         VGA_HS,
    output wire         VGA_VS,

    //----------------- Tape -----------------
    input wire          TAPE_IN,
    output wire         TAPE_OUT, // NCSO

    //----------------- I2S DAC --------------
    output wire         DAC_LRCK,
    output wire         DAC_DAT,
    output wire         DAC_BCK,

    //----------------- SPI Slave for MCU ----
    input wire          MCU_CS_N,
    input wire          MCU_SD_CS_N, // pin25
    input wire          MCU_SCK,
    input wire          MCU_MOSI,
    output wire         MCU_MISO,
    
    //----------------- CPLD BUS -------------
    output wire         BUS_RESET_N,
    output wire         BUS_CLK,
    output wire         BUS_CLK2,
    output wire [1:0]   BUS_A,
    input  wire [7:0]   BUS_DI,  // SD8-15
    input wire [7:0]   BUS_DO,  // SD0-7 (output!)
    output wire         BUS_DIR,
    input wire          LFDC_STEP
);

// system clocks
wire clk_bus_port, clk_bus, clk_8;
wire locked, areset;
altpll0 pll1 (
    .inclk0             (CLK_50MHZ),
    .c0                 (clk_bus_port), // 84
    .c1                 (clk_bus), // 28
    .c2                 (clk_8),
    .locked             (locked)
);
assign areset = ~locked;

//---------- DAC ------------
wire [15:0] audio_l, audio_r;
PCM5102 PCM5102(
    .clk                (clk_bus),
    .reset              (areset),
    .left               (audio_l),
    .right              (audio_r),
    .din                (DAC_DAT),
    .bck                (DAC_BCK),
    .lrck               (DAC_LRCK)
);

//---------- MCU ------------
wire [15:0] osd_command, softsw_command;
wire mcu_busy;
wire [7:0] ms_x, ms_y;
wire [3:0] ms_z;
wire [2:0] ms_b;
wire ms_upd;
wire ms_present = 1'b1;
wire [7:0] kb_status, kb_dat0, kb_dat1, kb_dat2, kb_dat3, kb_dat4, kb_dat5;
wire [7:0] kb_scancode;
wire kb_scancode_upd;
wire [12:0] joystick;
wire romloader_active, romloader_wr;
wire [31:0] romloader_addr;
wire [7:0] romloader_data;
mcu mcu(
    .clk                (clk_bus),
    .reset              (areset),

    .mcu_mosi           (MCU_MOSI),
    .mcu_miso           (MCU_MISO),
    .mcu_sck            (MCU_SCK),
    .mcu_cs_n           (MCU_CS_N),
     
    .ms_x               (ms_x),
    .ms_y               (ms_y),
    .ms_z               (ms_z),
    .ms_b               (ms_b),
    .ms_upd             (ms_upd),
     
    .kb_status          (kb_status),
    .kb_dat0            (kb_dat0),
    .kb_dat1            (kb_dat1),
    .kb_dat2            (kb_dat2),
    .kb_dat3            (kb_dat3),
    .kb_dat4            (kb_dat4),
    .kb_dat5            (kb_dat5),
     
    .kb_scancode        (kb_scancode),
    .kb_scancode_upd    (kb_scancode_upd),

    .joystick           (joystick),

    .rtc_a              (rtc_a),
    .rtc_di             (rtc_di),
    .rtc_do             (rtc_do),
    .rtc_cs             (1'b1),
    .rtc_wr_n           (rtc_wr_n),

    .usb_uart_rx_data   (usb_uart_rx_data),
    .usb_uart_rx_idx    (usb_uart_rx_idx),
    .usb_uart_tx_data   (usb_uart_tx_data),
    .usb_uart_tx_wr     (usb_uart_tx_wr),
    .usb_uart_tx_mode   (usb_uart_tx_mode),

    .usb_uart_dll       (usb_uart_dll),
    .usb_uart_dlm       (usb_uart_dlm),
    .usb_uart_dll_wr    (usb_uart_dll_wr),
    .usb_uart_dlm_wr    (usb_uart_dlm_wr),
	 
    .esp_uart_rx_data   (esp_uart_rx_data),
    .esp_uart_rx_idx    (esp_uart_rx_idx),
    .esp_uart_tx_data   (esp_uart_tx_data),
    .esp_uart_tx_wr     (esp_uart_tx_wr),

    .softsw_command     (softsw_command),
    .osd_command        (osd_command),

    .romloader_active   (romloader_active),
    .romloader_addr     (romloader_addr),
    .romloader_data     (romloader_data),
    .romloader_wr       (romloader_wr),
     
    .flash_a_bus        (flash_a_bus),
    .flash_do_bus       (flash_do_bus),
    .flash_di_bus       (flash_di_bus),
    .flash_rd_n         (flash_rd_n),
    .flash_wr_n         (flash_wr_n),
    .flash_er_n         (flash_er_n),
    .flash_busy         (flash_busy),
    .flash_ready        (flash_ready), 
     
    .debug_addr         (16'd0),
    .debug_data         (16'd0),

    .busy               (mcu_busy)
);

//--------- soft switches ----
wire kb_reset, kb_magic, kb_wait, kb_covox_en, kb_nemoide_en, kb_psg_type, kb_turbofdc, kb_swap_fdd, kb_video_15khz, kb_type;
wire [2:0] kb_joy_mode;
wire [1:0] kb_turbo;
wire [1:0] kb_rom_bank;
wire [1:0] kb_psg_mix;

soft_switches soft_switches(
    .clk                (clk_bus),
    .softsw_command     (softsw_command),
    .rom_bank           (kb_rom_bank),
    .turbofdc           (kb_turbofdc),
    .covox_en           (kb_covox_en),
    .psg_mix            (kb_psg_mix),
    .psg_type           (kb_psg_type),
    .video_15khz        (kb_video_15khz),
    .turbo              (kb_turbo),
    .swap_fdd           (kb_swap_fdd),
    .joy_type           (kb_joy_mode),
    .nemoide_en         (kb_nemoide_en),
    .keyboard_type      (kb_type),
    .pause              (kb_wait),
    .nmi                (kb_magic),
    .reset              (kb_reset)
);

//--------- hid parser -------
wire [7:0] rtc_do_mapped;
hid_parser #(.NUM_KEYS(5)) hid_parser (
    .clk                (clk_bus),
    .reset              (areset),
    .kb_status          (kb_status),
    .kb_dat0            (kb_dat0),
    .kb_dat1            (kb_dat1),
    .kb_dat2            (kb_dat2),
    .kb_dat3            (kb_dat3),
    .kb_dat4            (kb_dat4),
    .kb_dat5            (kb_dat5),
     
    .kb_scancode        (kb_scancode),
    .kb_scancode_upd    (kb_scancode_upd),
     
    .joy_type_l         (kb_joy_mode),
    .joy_type_r         (3'b000),
    .joy_l              (joystick),
    .joy_r              (13'b0000000000000),
     
    .a                  (kb_a_bus),
    .kb_type            (kb_type),

    .joy_do             (joy_bus),
    .kb_do              (kb_do_bus),
     
    .rtc_a              (rtc_a),
    .rtc_di             (rtc_di),
    .rtc_do_in          (rtc_do),
    .rtc_do_out         (rtc_do_mapped),
    .rtc_wr             (~rtc_wr_n),
    .rtc_rd             (~rtc_rd_n)
);

//--------- OSD --------------
wire [8:0] osd_rgb;
overlay #(.DEFAULT(0), .H_OFFSET(32), .V_OFFSET(60)) overlay(
    .clk_bus            (clk_bus),
    .clk                (video_clk), // 7/14
    .ds80               (ds80),
    .rgb                (video_rgb),
    .hs                 (video_hs),
    .vs                 (video_vs),
    .rgb_o              (osd_rgb),
    .osd_command        (osd_command),
    .icon_cf            (icon_cf),
    .icon_sd            (icon_sd),
    .icon_fdd           (icon_fdd)
);

//--------- scandouber -------
wire video_clk;
vga_scandoubler #(.CLKVIDEO(14000)) scandoubler(
    .clk                (clk_bus),
	 .clk28en            (1'b1),
	 .clk14en				(video_clk),

	 .enable_scandoubling(~kb_video_15khz),
	 .disable_scaneffect (1'b1),

	 .rgbi               (osd_rgb),
	 .hsync_ext_n			(video_hs),
	 .vsync_ext_n			(video_vs),
	 .csync_ext_n			(video_cs),

	 .rgbo               ({VGA_R[2:0], VGA_G[2:0], VGA_B[2:0]}),
	 .hsync              (VGA_HS),
	 .vsync              (VGA_VS)
);

//-------- Profi -------------

wire ds80;
wire [31:0] flash_a_bus;
wire [7:0] flash_di_bus, flash_do_bus;
wire flash_rd_n, flash_wr_n, flash_er_n, flash_busy, flash_ready;

wire [8:0] video_rgb;
wire video_hs, video_vs, video_cs;
wire icon_sd, icon_cf, icon_fdd;

wire [7:0] usb_uart_rx_data, usb_uart_rx_idx, usb_uart_tx_data;
wire [7:0] esp_uart_rx_data, esp_uart_rx_idx, esp_uart_tx_data;
wire [7:0] usb_uart_dll, usb_uart_dlm;
wire usb_uart_tx_wr, usb_uart_tx_mode, usb_uart_dll_wr, usb_uart_dlm_wr, esp_uart_tx_wr;

wire [7:0] rtc_a, rtc_di, rtc_do;
wire rtc_wr_n, rtc_rd_n;

wire [15:8] kb_a_bus;
wire [7:0] kb_do_bus;
wire [7:0] joy_bus;

profi profi(
    .clk_bus            (clk_bus), // 28
    .clk_bus_port       (clk_bus_port), // 84
    .clk_8              (clk_8),
    .areset             (areset),

    .sd_sck             (SD_SCK),
    .sd_cs_n            (SD_CS_N),
    .sd_mosi            (SD_MOSI),
    .sd_miso            (SD_MISO),

    .flash_a_bus        (flash_a_bus),
    .flash_do_bus       (flash_do_bus),
    .flash_di_bus       (flash_di_bus),
    .flash_rd_n         (flash_rd_n),
    .flash_wr_n         (flash_wr_n),
    .flash_er_n         (flash_er_n),
    .flash_busy         (flash_busy),
    .flash_ready        (flash_ready),

    .sram_a             (SRAM_A),
    .sram_d             (SRAM_D),
    .sram_rd_n          (),
    .sram_wr_n          (SRAM_WR_N),

    .loader_act         (romloader_active),
    .loader_a           (romloader_addr),
    .loader_d           (romloader_data),
    .loader_wr          (romloader_wr),
    .loader_reset       (mcu_busy),

    .video_rgb          (video_rgb), // 3:3:3
    .video_clk          (video_clk),
    .video_hs           (video_hs),
    .video_vs           (video_vs),
    .video_cs           (video_cs),
    .video_ds80         (ds80),
    .icon_sd            (icon_sd),
    .icon_cf            (icon_cf),
    .icon_fdd           (icon_fdd),

    .bus_reset_n        (BUS_RESET_N), // todo: move bus module outside profi module as zx_bus* + hdd/fdd signals
    .bus_clk            (BUS_CLK),
    .bus_clk2           (BUS_CLK2),
    .bus_di             (BUS_DI),
//    .bus_do             (BUS_DO), // todo: disabled temporary
    .bus_sdir           (BUS_DIR),
    .bus_a              (BUS_A),
    .fdc_step           (LFDC_STEP),

    .audio_l            (audio_l),
    .audio_r            (audio_r),

    .tape_out           (TAPE_OUT),
    .tape_in            (TAPE_IN),
    .buzzer             (),

    .usb_uart_rx_data   (usb_uart_rx_data),
    .usb_uart_rx_idx    (usb_uart_rx_idx),
    .usb_uart_tx_data   (usb_uart_tx_data),
    .usb_uart_tx_wr     (usb_uart_tx_wr),
    .usb_uart_tx_mode   (usb_uart_tx_mode),

    .usb_uart_dll       (usb_uart_dll),
    .usb_uart_dlm       (usb_uart_dlm),
    .usb_uart_dll_wr    (usb_uart_dll_wr),
    .usb_uart_dlm_wr    (usb_uart_dlm_wr),
	 
    .esp_uart_rx_data   (esp_uart_rx_data),
    .esp_uart_rx_idx    (esp_uart_rx_idx),
    .esp_uart_tx_data   (esp_uart_tx_data),
    .esp_uart_tx_wr     (esp_uart_tx_wr),	  

    .rtc_a              (rtc_a),
    .rtc_do_bus         (rtc_do_mapped),
    .rtc_di_bus         (rtc_di),
    .rtc_rd_n           (rtc_rd_n),
    .rtc_wr_n           (rtc_wr_n),

    .kb_a_bus           (kb_a_bus),
    .kb_do_bus          (kb_do_bus),

    .ms_x               (ms_x),
    .ms_y               (ms_y),
    .ms_z               (ms_z),
    .ms_b               (ms_b),
    .ms_present         (ms_present),
    .ms_upd             (ms_upd),

    .joy_bus            (joy_bus),

    .btn_reset          (kb_reset),
    .btn_rom_bank       (kb_rom_bank),
    .btn_turbo          (kb_turbo),
    .btn_nmi            (kb_magic),
    .btn_wait           (kb_wait),
    .btn_nemoide_en     (kb_nemoide_en),
    .btn_ay_mode        (kb_psg_type),
    .btn_audio_mix_mode (kb_psg_mix),
    .btn_covox_en       (kb_covox_en),
    .btn_turbofdc       (kb_turbofdc),
    .btn_swap_floppy    (kb_swap_fdd),
    .btn_joy_mode       (kb_joy_mode)
);

endmodule

