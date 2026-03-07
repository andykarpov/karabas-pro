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
-- FPGA NES core for Karabas-Pro revF
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
    input wire          SD_MISO,    // DATA0 (warning! mcu output while configuring )
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

// clock
wire clk, clk_vga;
wire locked;
wire areset;

clock_21mhz clock_21mhz(
	.inclk0(CLK_50MHZ),
	.c0(clk),
	.c1(clk_vga),
	.locked(locked)
);	
assign areset = ~locked;

//---------- MCU ------------

wire [7:0] hid_kb_status, hid_kb_dat0, hid_kb_dat1, hid_kb_dat2, hid_kb_dat3, hid_kb_dat4, hid_kb_dat5;
wire [12:0] joy_l, joy_r;
wire romloader_act, fileloader_reset;
wire [31:0] romloader_addr, fileloader_addr;
wire [7:0] romloader_data, fileloader_data;
wire romloader_wr, fileloader_wr;
wire [15:0] softsw_command, osd_command;
wire mcu_busy;

mcu mcu(
	.CLK(clk),
	.N_RESET(~areset),
	
	.MCU_MOSI(MCU_MOSI),
	.MCU_MISO(MCU_MISO),
	.MCU_SCK(MCU_SCK),
	.MCU_SS(MCU_CS_N),	
	.MCU_SPI_SD2_SS(MCU_SD_CS_N),
	
	.KB_STATUS(hid_kb_status),
	.KB_DAT0(hid_kb_dat0),
	.KB_DAT1(hid_kb_dat1),
	.KB_DAT2(hid_kb_dat2),
	.KB_DAT3(hid_kb_dat3),
	.KB_DAT4(hid_kb_dat4),
	.KB_DAT5(hid_kb_dat5),
	
	.JOY_L(joy_l),
	.JOY_R(joy_r),
	
	.ROMLOADER_ACTIVE(romloader_act),
	.ROMLOAD_ADDR(romloader_addr),
	.ROMLOAD_DATA(romloader_data),
	.ROMLOAD_WR(romloader_wr),
	
	.FILELOAD_RESET(fileloader_reset),
	.FILELOAD_ADDR(fileloader_addr),
	.FILELOAD_DATA(fileloader_data),
	.FILELOAD_WR(fileloader_wr),
	
	.SOFTSW_COMMAND(softsw_command),	
	.OSD_COMMAND(osd_command),
	
	.BUSY(mcu_busy),
	
	.SD2_CS_N(SD_CS_N),
	.SD2_MOSI(SD_MOSI),
	.SD2_MISO(SD_MISO),
	.SD2_SCK(SD_SCK)	
);

//---------- HID Keyboard/Joy parser ------------

wire [7:0] nes_joy_l, nes_joy_r;

hid_parser hid_parser(
	.CLK(clk),
	.RESET(areset),

	.KB_STATUS(hid_kb_status),
	.KB_DAT0(hid_kb_dat0),
	.KB_DAT1(hid_kb_dat1),
	.KB_DAT2(hid_kb_dat2),
	.KB_DAT3(hid_kb_dat3),
	.KB_DAT4(hid_kb_dat4),
	.KB_DAT5(hid_kb_dat5),
	
	.JOY_L(joy_l),
	.JOY_R(joy_r),
	
	.JOY_L_DO(nes_joy_l),
	.JOY_R_DO(nes_joy_r)
);

//---------- Soft switches ------------

wire kb_reset;
wire btn_reset_n;

soft_switches soft_switches(
	.CLK(clk),
	.SOFTSW_COMMAND(softsw_command),
	.RESET(kb_reset)
);

assign btn_reset_n = ~kb_reset & ~mcu_busy;

//---------- DAC ------------

wire [15:0] audio_out_l, audio_out_r;

PCM5102 PCM5102(
	.clk(clk),
	.reset(areset),
	.left(audio_out_l),
	.right(audio_out_r),
	.din(DAC_DAT),
	.bck(DAC_BCK),
	.lrck(DAC_LRCK)
);

//--------- OSD --------------

wire [2:0] video_r, video_g, video_b, osd_r, osd_g, osd_b;
wire video_hsync, video_vsync;

overlay overlay(
	.clk_bus(clk),
	.clk(clk_vga),
	.rgb({video_r[2:0], video_g[2:0], video_b[2:0]}),
	.rgb_o({osd_r[2:0], osd_g[2:0], osd_b[2:0]}),
	.hs(video_hsync),
	.vs(video_vsync),
	.osd_command(osd_command)
);

//--------- NES --------------

// NES Palette -> RGB332 conversion
reg [14:0] pallut[0:63];
initial $readmemh("nes_palette.txt", pallut);
  
wire [8:0] cycle;
wire [8:0] scanline;
wire [15:0] sample;
wire [5:0] color;
wire [21:0] memory_addr;
wire memory_read_cpu, memory_read_ppu;
wire memory_write;
wire [7:0] memory_din_cpu, memory_din_ppu;
wire [7:0] memory_dout;
wire [31:0] dbgadr;
wire [1:0] dbgctr;

wire joypad_strobe;
wire [1:0] joypad_clock;
reg [7:0] joypad_bits, joypad_bits2;
reg [1:0] last_joypad_clock;

reg [1:0] nes_ce;

// --------------- Loader 

wire [21:0] loader_addr;
wire [7:0] loader_write_data;
wire loader_write;
wire [31:0] mapper_flags;
wire loader_done, loader_fail;

wire loader_reset = fileloader_reset;
  
  GameLoader loader(
    clk, 
    loader_reset, 
	 fileloader_data, 
	 fileloader_wr,
	 loader_addr, 
	 loader_write_data, 
	 loader_write,
	 mapper_flags,
	 loader_done,
	 loader_fail
	);
	
  wire reset_nes = (kb_reset || !loader_done);
  wire run_mem = (nes_ce == 0) && !reset_nes;
  wire run_nes = (nes_ce == 3) && !reset_nes;

  // NES is clocked at every 4th cycle.
  always @(posedge clk)
    nes_ce <= nes_ce + 1;
    
  NES nes(clk, reset_nes, run_nes,
          mapper_flags,
          sample, color,
          joypad_strobe, joypad_clock, {joypad_bits2[0], joypad_bits[0]},
          5'b11111, // sw
          memory_addr,
          memory_read_cpu, memory_din_cpu,
          memory_read_ppu, memory_din_ppu,
          memory_write, memory_dout,
          cycle, scanline,
          dbgadr,
          dbgctr
   );

  // This is the memory controller to access the board's SRAM
  wire ram_busy;
  reg [13:0] debugaddr;
  wire [15:0] debugdata;

  MemoryController  memory( clk,
                            memory_read_cpu && run_mem, 
                            memory_read_ppu && run_mem,
                            memory_write && run_mem || loader_write,
                            loader_write ? loader_addr : memory_addr,
                            loader_write ? loader_write_data : memory_dout,
                            memory_din_cpu, memory_din_ppu, ram_busy,
                            SRAM_WR_N, SRAM_A[18:0], SRAM_D,
                            debugaddr, debugdata);
  assign SRAM_A[20:19] = 2'b00;

  reg ramfail;
  always @(posedge clk) begin
    if (loader_reset)
      ramfail <= 0;
    else
      ramfail <= ram_busy && loader_write || ramfail;
  end
  
  vga vga(
	.I_CLK(clk),
	.I_CLK_VGA(clk_vga),
	.I_COLOR(color),
	.I_HCNT(cycle),
	.I_VCNT(scanline),
	.O_HSYNC(video_hsync),
	.O_VSYNC(video_vsync),
	.O_RED(video_r),
	.O_GREEN(video_g),
	.O_BLUE(video_b),
	.O_HCNT(),
	.O_VCNT(),
	.O_H(),
	.O_BLANK()
  );
  
  always @(posedge clk) begin
	if (joypad_strobe) begin
		joypad_bits <= nes_joy_l;
		joypad_bits2 <= nes_joy_r;
	end
	
	if (!joypad_clock[0] && last_joypad_clock[0]) begin 
		joypad_bits <= {1'b0, joypad_bits[7:1]};
	end
	if (!joypad_clock[1] && last_joypad_clock[1]) begin
		joypad_bits2 <= {1'b0, joypad_bits2[7:1]};
	end
	last_joypad_clock <= joypad_clock;
  end

// assign video
assign VGA_R          = osd_r;
assign VGA_G          = osd_g;
assign VGA_B          = osd_b;
assign VGA_HS         = video_hsync;
assign VGA_VS         = video_vsync;
  
// unused signals
assign TAPE_OUT       = 1'b1;
assign BUS_CLK        = 1'b0;
assign BUS_CLK2       = 1'b0;
assign BUS_RESET_N    = 1'b0;
assign BUS_A          = 2'b00;
//assign BUS_DO         = 8'b0; // set as input :)
assign BUS_DIR        = 1'b0;

endmodule

