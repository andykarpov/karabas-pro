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

    //----------------- SPI Master for Flash / SD
    output wire         SPI_FLASH_CS_N, // NCSO
    output wire         SPI_SD_CS_N,
    output wire         SPI_SCK,        // DCLK
    input wire          SPI_MISO,       // DATA0
    output wire         SPI_FLASH_MOSI, // ASDO
    output wire         SPI_SD_MOSI,    // dedicated SD MOSI

    //----------------- VGA ------------------
    output wire [2:0]   VGA_R,
    output wire [2:0]   VGA_G,
    output wire [2:0]   VGA_B,
    output wire         VGA_HS,
    output wire         VGA_VS,

    //----------------- Misc -----------------
    input wire          TAPE_IN,
    input wire          TP1,

    //----------------- I2S DAC --------------
    output wire         DAC_LRCK,
    output wire         DAC_DAT,
    output wire         DAC_BCK,

    //----------------- SPI Slave for MCU ----
    input wire          MCU_CS_N,
    input wire          MCU_SCK,
    input wire          MCU_MOSI,
    output wire         MCU_MISO,
    
    //----------------- CPLD BUS -------------
    output wire         BUS_RESET_N,
    output wire         BUS_CLK,
    output wire         BUS_CLK2,
    output wire [1:0]   BUS_A,
    input  wire [7:0]   BUS_DI,  // SD8-15
	 output wire [7:0]   BUS_DO,  // SD0-7
    output wire         BUS_DIR,
    input wire          LFDC_STEP
);

// unused signals
assign SPI_FLASH_CS_N = 1'b1;
assign SPI_SD_CS_N    = 1'b1;
assign SPI_SCK        = 1'b0;
assign SPI_FLASH_MOSI = 1'b1;
assign SPI_SD_MOSI    = 1'b1;
assign SRAM_A         = 21'b0;
assign SRAM_D         = 8'bZ;
assign SRAM_WR_N      = 1'b1;
assign BUS_CLK        = 1'b0;
assign BUS_CLK2       = 1'b0;
assign BUS_RESET_N    = 1'b0;
assign BUS_A          = 2'b00;
assign BUS_DO         = 8'b0;
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

// vga mux
assign VGA_R[2:0]     = osd_r[2:0];
assign VGA_G[2:0]     = osd_g[2:0];
assign VGA_B[2:0]     = osd_b[2:0];
assign VGA_HS         = video_hs;
assign VGA_VS         = video_vs;

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
wire mcu_busy;
mcu mcu(
    .clk                (clk_sys),
    .reset              (areset),

    .mcu_mosi           (MCU_MOSI),
    .mcu_miso           (MCU_MISO),
    .mcu_sck            (MCU_SCK),
    .mcu_cs_n           (MCU_CS_N),

    .rtc_a              (8'b0),
    .rtc_di             (8'b0),
    .rtc_cs             (1'b1),
    .rtc_wr_n           (1'b1),

    .uart_tx_data       (8'b0),
    .uart_tx_wr         (1'b0),
    .uart_tx_mode       (2'b00),

    .uart_dll           (8'b0),
    .uart_dlm           (8'b0),
    .uart_dll_wr        (1'b0),
    .uart_dlm_wr        (1'b0),

    .osd_command        (osd_command),

    .debug_addr         (16'd0),
    .debug_data         (16'd0),

    .busy               (mcu_busy)
);

//--------- VGA sync ---------
wire video_hs, video_vs, video_de;
vga_sync vga_sync(
    .clk                (clk_sys),
    .hs                 (video_hs),
    .vs                 (video_vs),
    .de                 (video_de)
);

//--------- OSD --------------
wire [2:0] osd_r, osd_g, osd_b;
overlay #(.DEFAULT(1)) overlay(
    .clk                (clk_sys),
    .rgb                (9'b0),
    .rgb_o              ({osd_r[2:0], osd_g[2:0], osd_b[2:0]}),
    .hs                 (video_hs),
    .vs                 (video_vs),
    .osd_command        (osd_command)
);

endmodule

