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
-- FPGA Test core for Karabas-Pro revF
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2026
------------------------------------------------------------------------------------------------------------------*/

module karabas_pro_top (
    //----------------- GLobal clock ---------
    input wire          CLK_50MHZ,

    //----------------- SRAM -----------------
    output wire [20:0]  SRAM_A,
    inout wire [7:0]    SRAM_D,
    output wire         SRAM_WR_N,

    //----------------- SPI Master for SD
    output wire         SD_CS_N,
    output wire         SD_SCK,     // ASDO pin6
    inout wire          SD_MISO,    // DATA0 (warning! mcu output while configuring )
    output wire         SD_MOSI,    // dedicated SD MOSI
     // DCLK - can not be used! remains only for PS programming!

    //----------------- VGA ------------------
    output wire [2:0]   VGA_R,
    output wire [2:0]   VGA_G,
    output wire [2:0]   VGA_B,
    output wire         VGA_HS,
    output wire         VGA_VS,

    //----------------- Tape In/Out ----------
    input wire          TAPE_IN,
    output wire         TAPE_OUT, // NCSO pin8

    //----------------- I2S DAC --------------
    output wire         DAC_LRCK,
    output wire         DAC_DAT,
    output wire         DAC_BCK,

    //----------------- SPI Slave for MCU ----
    input wire          MCU_CS_N,
    input wire          MCU_SD_CS_N, // tp1 pin25
    input wire          MCU_SCK,
    input wire          MCU_MOSI,
    output wire         MCU_MISO,

    //----------------- CPLD BUS -------------
    input wire         BUS_RESET_N,
    input wire         BUS_CLK,
    input wire         BUS_CLK2,
    input wire [1:0]   BUS_A,
    input  wire [7:0]   BUS_DI,  // SD8-15
    input  wire [7:0]   BUS_DO,  // SD0-7 (should be output?)
    input wire         BUS_DIR,
    input wire          LFDC_STEP
);

// unused signals
assign TAPE_OUT       = 1'b1;
//assign BUS_CLK        = 1'b0;
//assign BUS_CLK2       = 1'b0;
//assign BUS_RESET_N    = 1'b0;
//assign BUS_A          = 2'b00;
//assign BUS_DO         = 8'b0; // todo: conflict ???
//assign BUS_DIR        = 1'b0;

// map MCU SPI with SD SPI
assign MCU_MISO = 
                  (~MCU_CS_N) ? mcu_miso_int :
                  1'b1;

wire mode, vga;
wire [2:0] r_to_vga, g_to_vga, b_to_vga;
wire hsync_to_vga, vsync_to_vga, csync_to_vga;
wire hsync_aux;
wire memtest_init_fast, memtest_init_slow, memtest_progress, memtest_result;
wire sdtest_init, sdtest_progress, sdtest_result;
wire hidetextwindow;

wire [7:0] earcode;
wire [2:0] mousebutton;  // M R L
wire mousetest_init;
wire master_reset;

wire [12:0] joy_l; // -- MXYZ SACB RLDU
wire [11:0] joy_l_md;

wire clk28, clk14, clk7;
wire clocks_ready;

pll pll(
	.inclk0(CLK_50MHZ),
	.c0(clk28),
	.c1(clk14),
	.c2(clk7),
	.locked(clocks_ready)
);

switch_mode teclas (
	.clk(clk7),
	.kbd_status(hid_kb_status),
	.kbd_data(hid_kb_data),
	.mode(mode),
	.vga(vga),
	.memtestf(memtest_init_fast),
	.memtests(memtest_init_slow),
	.sdtest(sdtest_init),
	.mousetest(mousetest_init),
	.hidetextwindow(hidetextwindow),
	.master_reset()
);

ramtest8b test_de_ram (
      .clk(clk14),
      .hold(~clocks_ready),
      .rstf(memtest_init_fast),
      .rsts(memtest_init_slow),
      .sram_a(SRAM_A),
      .sram_d(SRAM_D),
      .sram_we_n(SRAM_WR_N),
      .sram_rd_n(),
      .test_in_progress(memtest_progress),
      .test_result(memtest_result)
   );

sdtest test_slot_sd (
	.clk(clk7),
	.rst(sdtest_init),
	.spi_clk(SD_SCK),
	.spi_di(SD_MOSI),
	.spi_do(SD_MISO),
	.spi_cs(SD_CS_N),
	.test_in_progress(sdtest_progress),
	.test_result(sdtest_result)
);

eartest test_ear (
	.clk(clk7),
	.ear(~TAPE_IN),
	.vs(vsync_to_vga),
	.code(earcode)
);

assign mousebutton = ms_b;

updater mensajes (
  .clk(clk7),
  .mode(mode),
  .vga(vga),
  .memtest_progress(memtest_progress),
  .memtest_result(memtest_result),
  .joystick1(8'b00000000),
  .joy1md(joy_l_md), // -- MXYZ SACB RLDU  Negative Logic
  .earcode(earcode),
  .sdtest_progress(sdtest_progress),
  .sdtest_result(sdtest_result),
  .mousebutton(mousebutton),
  .hidetextwindow(hidetextwindow),
  .r(r_to_vga),
  .g(g_to_vga),
  .b(b_to_vga),
  .hsync(hsync_to_vga),
  .vsync(vsync_to_vga),
  .csync(csync_to_vga)
  );

vga_scandoubler #(.CLKVIDEO(7000)) modo_vga (
	.clkvideo(clk7),
	.clkvga(clk14),
	.enable_scandoubling(vga),
	.disable_scaneffect(1'b1),
	.ri(r_to_vga),
	.gi(g_to_vga),
	.bi(b_to_vga),
	.hsync_ext_n(hsync_to_vga),
	.vsync_ext_n(vsync_to_vga),
	.csync_ext_n(csync_to_vga),
	.ro(VGA_R),
	.go(VGA_G),
	.bo(VGA_B),
	.hsync(VGA_HS),
	.vsync(VGA_VS)
);

audio_test audio (
	.clk(clk14),
	.left(audio_out_l),
	.right(audio_out_r),
	.led()
);

//---------- MCU ------------

wire [2:0] ms_b;
wire [7:0] hid_kb_status, hid_kb_data;
wire [15:0] softsw_command;
wire mcu_busy;
wire mcu_miso_int;

mcu mcu(
	.CLK(clk14),
	.N_RESET(~clocks_ready),	
	.MCU_MOSI(MCU_MOSI),
	.MCU_MISO(mcu_miso_int),
	.MCU_SCK(MCU_SCK),
	.MCU_SS(MCU_CS_N),
	.MS_X(),
	.MS_Y(),
	.MS_Z(),
	.MS_B(ms_b),
	.MS_UPD(),
	.KB_STATUS(hid_kb_status),
	.KB_DAT0(hid_kb_data),
	.KB_DAT1(),
	.KB_DAT2(),
	.KB_DAT3(),
	.KB_DAT4(),
	.KB_DAT5(),
	.JOY_L(joy_l),
	.ROMLOADER_ACTIVE(),
	.ROMLOAD_ADDR(),
	.ROMLOAD_DATA(),
	.ROMLOAD_WR(),
	.SOFTSW_COMMAND(softsw_command),	
	.OSD_COMMAND(),
	.BUSY(mcu_busy)
);

// -- MZYX CBAS RLDU O Positive Logic
// -- MXYZ SACB RLDU   Negative Logic
assign joy_l_md = {joy_l[12], joy_l[9], joy_l[10], joy_l[11], joy_l[5], joy_l[6], joy_l[8], joy_l[7], joy_l[4:1]}; 

//---------- Soft switches ------------

wire kb_reset;

soft_switches soft_switches(
	.CLK(clk14),
	.SOFTSW_COMMAND(softsw_command),
	.RESET(kb_reset)
);

assign master_reset = kb_reset | mcu_busy;


//---------- DAC ------------

wire [15:0] audio_out_l, audio_out_r;

PCM5102 PCM5102(
	.clk(clk14),
	.left(audio_out_l),
	.right(audio_out_r),
	.din(DAC_DAT),
	.bck(DAC_BCK),
	.lrck(DAC_LRCK)
);						
						
endmodule

