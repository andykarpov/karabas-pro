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
-- FPGA Boot menu core for Karabas-Pro revF
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2025
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
    output wire         BUS_RESET_N,
    output wire         BUS_CLK,
    output wire         BUS_CLK2,
    output wire [1:0]   BUS_A,
    input  wire [7:0]   BUS_DI,  // SD8-15
    input  wire [7:0]   BUS_DO,  // SD0-7
    output wire         BUS_DIR,
    input wire          LFDC_STEP
);

// unused signals
assign TAPE_OUT       = 1'b1;
assign SRAM_A         = 21'b0;
assign SRAM_D         = 8'bZ;
assign SRAM_WR_N      = 1'b1;
assign BUS_CLK        = 1'b0;
assign BUS_CLK2       = 1'b0;
assign BUS_RESET_N    = 1'b0;
assign BUS_A          = 2'b00;
//assign BUS_DO         = 8'b0; // todo: conflict ???
assign BUS_DIR        = 1'b0;

// system clocks
wire clk_sys;
wire locked, areset;

pll pll (
    .inclk0             (CLK_50MHZ),
    .c0                 (clk_sys), // 40 MHz
    .locked             (locked)
);
assign areset = ~locked;

//---------- DAC ------------
wire [15:0] audio_out_l, audio_out_r;
PCM5102 PCM5102(
    .clk                (clk_sys),
    .reset              (areset),
    .left               (audio_out_l),
    .right              (audio_out_r),
    .din                (DAC_DAT),
    .bck                (DAC_BCK),
    .lrck               (DAC_LRCK)
);

//---------- MCU ------------
wire [15:0] osd_command;
wire mcu_miso_int;
mcu mcu(
    .clk                (clk_sys),
    .mcu_mosi           (MCU_MOSI),
    .mcu_miso           (mcu_miso_int),
    .mcu_sck            (MCU_SCK),
    .mcu_cs_n           (MCU_CS_N),
    .osd_command        (osd_command),
	 .busy               ()
);

//--------- VGA sync ---------
wire video_hs, video_vs, video_de;
wire [11:0] h, v;
vga_sync vga_sync(
    .clk                (clk_sys),
    .hs                 (video_hs),
    .vs                 (video_vs),
	 .de						(video_de),
    .h                  (h),
    .v                  (v)
);

//--------- OSD --------------
wire [2:0] osd_r, osd_g, osd_b;
overlay #(.DEFAULT(1), .H_OFFSET(172), .V_OFFSET(60)) overlay(
    .clk                (clk_sys),
    .rgb                (rgb),
    .rgb_o              ({osd_r[2:0], osd_g[2:0], osd_b[2:0]}),
    .hs                 (video_hs),
    .vs                 (video_vs),
    .osd_command        (osd_command)
);

// test pattern (color bars)
reg [8:0] rgb = 0;
always @(posedge clk_sys)
	if (video_de)
		if (h < 100) rgb <= 9'b111111111;
		else if (h < 200) rgb <= 9'b111111000;
		else if (h < 300) rgb <= 9'b000111111;
		else if (h < 400) rgb <= 9'b000111000;
		else if (h < 500) rgb <= 9'b111000111;
		else if (h < 600) rgb <= 9'b111000000;
		else if (h < 700) rgb <= 9'b000000111;
		else if (h < 800) rgb <= 9'b000000000;
		else rgb <= 9'b000000000;
	else rgb <= 9'b000000000;
	
// vga mux
assign VGA_R[2:0]     = osd_r[2:0];
assign VGA_G[2:0]     = osd_g[2:0];
assign VGA_B[2:0]     = osd_b[2:0];
assign VGA_HS         = video_hs;
assign VGA_VS         = video_vs;

// map MCU SPI with SD SPI
assign SD_SCK = MCU_SCK;
assign SD_CS_N = MCU_SD_CS_N;
assign SD_MOSI = MCU_MOSI;
assign MCU_MISO = (~MCU_SD_CS_N) ? SD_MISO :
                  (~MCU_CS_N) ? mcu_miso_int :
                  1'b1;

endmodule

