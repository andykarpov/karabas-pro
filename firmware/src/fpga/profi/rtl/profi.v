`default_nettype none
/*-----------------------------------------------------------------------------------------------------------------
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
-- Profi ULA
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- @author Oleh Starychenko <solegstar@gmail.com>
-- Ukraine, EU 2021-2025
-------------------------------------------------------------------------------------------------------------------*/

module profi(
    input wire              clk_bus,        // 28/24
    input wire              clk_bus_port,   // 84/72
    input wire              clk_8,
    input wire              areset,

    output wire             sd_sck,
    output wire             sd_cs_n,
    output wire             sd_mosi,
    input  wire             sd_miso,

    output wire [31:0]      flash_a_bus,
    input wire [7:0]        flash_do_bus,
    output wire [7:0]       flash_di_bus,
    output wire             flash_rd_n,
    output wire             flash_wr_n,
    output wire             flash_er_n,
    input wire              flash_busy,
    input wire              flash_ready,

    output wire [20:0]      sram_a,
    inout wire [7:0]        sram_d,
    output wire             sram_rd_n,
    output wire             sram_wr_n,

    input wire              loader_act,
    input wire [31:0]       loader_a,
    input wire [7:0]        loader_d,
    input wire              loader_wr,
    input wire              loader_reset,

    output wire [8:0]       video_rgb,      // 3:3:3
    output wire             video_clk,
    output wire             video_hs,
    output wire             video_vs,
    output wire             video_ds80,     // profi screen (clock 24)
    output wire             icon_sd,
    output wire             icon_cf,
    output wire             icon_fdd,

    output wire             bus_reset_n,
    output wire             bus_clk,
    output wire             bus_clk2,
    input wire [7:0]        bus_di,
    output wire [7:0]       bus_do,
    output wire             bus_sdir,
    output wire [1:0]       bus_a,
    input wire              fdc_step,

    output wire [15:0]      audio_l,
    output wire [15:0]      audio_r,

    output wire             tape_out,
    input wire              tape_in,
    output wire             buzzer,

    output wire [7:0]       uart_tx,
    output wire             uart_tx_req,

    input wire [7:0]        uart_rx,
    input wire              uart_rx_req,

    output wire [7:0]       uart2_tx,
    output wire             uart2_tx_req,

    input wire [7:0]        uart2_rx,
    input wire              uart2_rx_req,

    output wire [7:0]       rtc_a,
    input wire [7:0]        rtc_do_bus,
    output wire [7:0]       rtc_di_bus,
    output wire             rtc_rd_n,
    output wire             rtc_wr_n,

    output wire [15:8]      kb_a_bus,
    input wire [5:0]        kb_do_bus,

    input wire [7:0]        ms_x,
    input wire [7:0]        ms_y,
    input wire [3:0]        ms_z,
    input wire [2:0]        ms_b,
    input wire              ms_present,
    input wire              ms_upd,

    input wire [7:0]        joy_bus,

    input wire              btn_reset,
    input wire [1:0]        btn_rom_bank,
    input wire [2:0]        btn_turbo,
    input wire              btn_nmi,
    input wire              btn_wait,
    input wire              btn_divmmc_en,
    input wire              btn_nemoide_en,
    input wire              btn_ay_mode,
    input wire [1:0]        btn_audio_mix_mode,
    input wire              btn_covox_en,
    input wire              btn_turbofdc,
    input wire              btn_swap_floppy,
    input wire [2:0]        btn_joy_mode,
    input wire [1:0]        btn_screen_mode,
    input wire              btn_60hz
);

// Zilog Z80A CPU
wire [15:0] cpu_a_bus;
wire [7:0] cpu_do_bus;
reg [7:0] cpu_di_bus;
wire cpu_reset_n, cpu_clk, cpu_wait_n, cpu_int_n, cpu_nmi_n, cpu_m1_n, cpu_mreq_n, cpu_iorq_n, cpu_rd_n, cpu_wr_n, cpu_rfsh_n;
T80a cpu(
    .RESET_n                (cpu_reset_n),
    .CLK_n                  (~clk_cpu),
    .CEN                    (1'b1),
    .WAIT_n                 (cpu_wait_n),
    .INT_n                  (cpu_int_n && serial_ms_int),
    .NMI_n                  (cpu_nmi_n),
    .BUSRQ_n                (1'b1),
    .M1_n                   (cpu_m1_n),
    .MREQ_n                 (cpu_mreq_n),
    .IORQ_n                 (cpu_iorq_n),
    .RD_n                   (cpu_rd_n),
    .WR_n                   (cpu_wr_n),
    .RFSH_n                 (cpu_rfsh_n),
    .HALT_n                 (),
    .BUSAK_n                (),
    .A                      (cpu_a_bus),
    .DIN                    (cpu_di_bus),
    .DOUT                   (cpu_do_bus)
);
    
// memory manager
wire [7:0] ram_do_bus;
wire ram_oe_n;
wire [10:0] vid_a_bus;
wire [7:0] vid_do_bus;
wire vbus_mode, vid_rd;
wire count_block, memory_contention;
memory memory( 
    .CLK2X                  (clk_bus),
    .CLKX                   (clk_div2),
    .CLK_CPU                (clk_cpu),

    .A                      (cpu_a_bus),
    .D                      (cpu_do_bus),
    .N_MREQ                 (cpu_mreq_n),
    .N_IORQ                 (cpu_iorq_n),
    .N_WR                   (cpu_wr_n),
    .N_RD                   (cpu_rd_n),
    .N_M1                   (cpu_m1_n),
    
    .RAM_6MB                (1'b0),
    
    .loader_act             (loader_act),
    .loader_ram_a           (loader_a),
    .loader_ram_do          (loader_d),
    .loader_ram_wr          (loader_wr),

    .MA                     (sram_a),
    .MD                     (sram_d),
    .N_MRD                  (sram_rd_n),
    .N_MWR                  (sram_wr_n),

    .DO                     (ram_do_bus),
    .N_OE                   (ram_oe_n),

    .RAM_BANK               (port_7ffd_reg[2:0]),
    .RAM_EXT                (ram_ext), // seg A3 - seg A5

    .TRDOS                  (dos_act),

    .VA                     (vid_a_bus),
    .VID_PAGE               (port_7ffd_reg[3]), // seg A0 - seg A2
    .VID_DO                 (vid_do_bus),
    
    .VBUS_MODE_O            (vbus_mode),     // video bus mode: 0 - ram, 1 - vram
    .VID_RD_O               (vid_rd),         // read attribute or pixel    

    .DS80                   (ds80),
    .CPM                    (cpm),
    .SCO                    (sco),
    .SCR                    (scr),
    .WOROM                  (worom),

    .ROM_BANK               (rom14),      // 0 B128, 1 B48
    .EXT_ROM_BANK           (ext_rom_bank_pq),
    
    // contended memory signals
    .COUNT_BLOCK            (count_block),
    .CONTENDED              (memory_contention),
    // OCH: added to not contend in turbo mode
    .TURBO_MODE             (turbo_mode),
    
    // DIVMMC signals
   .DIVMMC_EN               (btn_divmmc_en),
    .AUTOMAP                (automap),
    .REG_E3                 (port_e3_reg)
);    

// Video Spectrum/Pentagon
wire vid_pff_cs;
wire [7:0] vid_attr;
wire gx0;
wire vid_ispaper;
wire blink;
video video(
    .CLK                    (clk_div2),     // 14 / 12
    .CLK2x                  (clk_bus),     // 28 / 24
    .ENA                    (clk_div4),     // 7 / 6
    .RESET                  (reset),
    .BORDER                 (port_xxfe_reg[7:0]),
    .DI                     (vid_do_bus),
    .TURBO                  (turbo_mode),    // turbo signal for int length
    .INTA                   (cpu_inta_n),
    .INT                    (cpu_int_n),
    .pFF_CS                 (vid_pff_cs), // port FF select
    .ATTR_O                 (vid_attr),  // attribute register output
    .A                      (vid_a_bus),    
    .MODE60                 (btn_60hz),
    .DS80                   (ds80),
    .CS7E                   (cs_xx7e),
    .BUS_A                  (cpu_a_bus[15:8]),
    .BUS_D                  (cpu_do_bus),
    .BUS_WR_N               (cpu_wr_n),
    .GX0                    (gx0),
    .VIDEO_R                (video_rgb[8:6]),
    .VIDEO_G                (video_rgb[5:3]),
    .VIDEO_B                (video_rgb[2:0]),    
    .HSYNC                  (video_hs),
    .VSYNC                  (video_vs),
    .VBUS_MODE              (vbus_mode),
    .VID_RD                 (vid_rd),
//    .HCNT                   (vid_hcnt),
//    .VCNT                   (vid_vcnt),
    .ISPAPER                (vid_ispaper),
    .BLINK                  (blink),
    .SCREEN_MODE            (btn_screen_mode),
    .COUNT_BLOCK            (count_block)
);

assign icon_sd  = zc_spi_start && zc_wr_en;
assign icon_cf  = hdd_active;
assign icon_fdd = ~fdd_cs_n && (~cpu_rd_n || ~cpu_wr_n);
assign video_clk = clk_div2;

wire [7:0] ssg_cn0_a, ssg_cn0_b, ssg_cn0_c, ssg_cn1_a, ssg_cn1_b, ssg_cn1_c;
wire [7:0] ssg_cn0_bus, ssg_cn1_bus;
wire ssg_sel;
turbosound turbosound(
    .I_CLK                  (clk_bus),
    .I_ENA                  (ena_div16),
    .I_ADDR                 (cpu_a_bus),
    .I_DATA                 (cpu_do_bus),
    .I_WR_N                 (cpu_wr_n),
    .I_IORQ_N               (cpu_iorq_n),
    .I_M1_N                 (cpu_m1_n),
    .I_RESET_N              (cpu_reset_n),
    .I_BDIR                 (1'b1), 
    .I_BC1                  (1'b1), 
    .O_SEL                  (ssg_sel),
    .I_MODE                 (btn_ay_mode),
    .O_SSG0_DA              (ssg_cn0_bus),
    .O_SSG0_AUDIO_A         (ssg_cn0_a),
    .O_SSG0_AUDIO_B         (ssg_cn0_b),
    .O_SSG0_AUDIO_C         (ssg_cn0_c),
    .O_SSG1_DA              (ssg_cn1_bus),
    .O_SSG1_AUDIO_A         (ssg_cn1_a),
    .O_SSG1_AUDIO_B         (ssg_cn1_b),
    .O_SSG1_AUDIO_C         (ssg_cn1_c)
);

wire [7:0] covox_a, covox_b, covox_c, covox_d, covox_fb;
covox covox(
    .I_RESET                (reset),
    .I_CLK                  (clk_bus),
    .I_CS                   (btn_covox_en),
    .I_WR_N                 (cpu_wr_n),
    .I_ADDR                 (cpu_a_bus[7:0]),
    .I_DATA                 (cpu_do_bus),
    .I_IORQ_N               (cpu_iorq_n),
    .I_DOS                  (dos_act),
    .I_CPM                  (cpm),
    .I_ROM14                (rom14),
    .O_A                    (covox_a),
    .O_B                    (covox_b),
    .O_C                    (covox_c),
    .O_D                    (covox_d),
    .O_FB                   (covox_fb)
);
     
wire [7:0] saa_l, saa_r;
saa1099 saa1099(
    .clk_sys                (clk_8),
    .ce                     (1'b1),
    .rst_n                  (~reset),
    .cs_n                   (1'b0),
    .a0                     (cpu_a_bus[8]),        // 0=data, 1=address
    .wr_n                   (saa_wr_n),
    .din                    (cpu_do_bus),
    .out_l                  (saa_l),
    .out_r                  (saa_r)
);

audio_mixer audio_mixer(
    .clk                    (clk_bus),
    .mute                   (1'b0),
    .mode                   (btn_audio_mix_mode),
    .speaker                (buzzer),
    .tape_in                (tape_in),
    .ssg0_a                 (ssg_cn0_a),
    .ssg0_b                 (ssg_cn0_b),
    .ssg0_c                 (ssg_cn0_c),
    .ssg1_a                 (ssg_cn1_a),
    .ssg1_b                 (ssg_cn1_b),
    .ssg1_c                 (ssg_cn1_c),
    .covox_a                (covox_a),
    .covox_b                (covox_b),
    .covox_c                (covox_c),
    .covox_d                (covox_d),
    .covox_fb               (covox_fb),
    .saa_l                  (saa_l),
    .saa_r                  (saa_r),
    .gs_l                   (15'b0),
    .gs_r                   (15'b0),
    .fm_l                   (16'b0), // todo
    .fm_r                   (16'b0),
    .fm_ena                 (1'b0),
    .audio_l                (audio_l),
    .audio_r                (audio_r)    
);

// FDD / HDD controllers
wire [7:0] cpld_do;
bus_port bus_port(
    .CLK                    (clk_bus_port),
    .CLK2                   (clk_8),
    .CLK_BUS                (clk_bus),
    .CLK_CPU                (clk_cpu),
    .RESET                  (reset),
    
    .SD                     ({bus_di, bus_do}),
    .SA                     (bus_a),
    .CPLD_CLK               (bus_clk),
    .CPLD_CLK2              (bus_clk2),
    .NRESET                 (~areset),
    // OCH: fix fdd swap
    .FDC_SWAP               (fdc_swap),

    .BUS_A                  ({cpu_a_bus[10:8], cpu_a_bus[6:5]}),
    .BUS_DI                 (cpu_do_bus),
    .BUS_DO                 (cpld_do),
    .BUS_RD_N               (cpu_rd_n),
    .BUS_WR_N               (cpu_wr_n),
    .BUS_HDD_CS_N           (hdd_profi_ebl_n),
    .BUS_WWC                (hdd_wwc_n),
    .BUS_WWE                (hdd_wwe_n),
    .BUS_RWW                (hdd_rww_n),
    .BUS_RWE                (hdd_rwe_n),
    .BUS_CS3FX              (hdd_cs3fx_n),
    .BUS_FDC_STEP           (fdc_step && turbo_fdc_off),
    .BUS_CSFF               (fdd_cs_pff_n),
    .BUS_FDC_NCS            (fdd_cs_n),
    
    // Nemo HDD bus signals
    .BUS_A7                 (cpu_a_bus[7]),
    .BUS_nemo_ebl_n         (nemo_ebl_n), // OCH: also nemo_ebl_n is passed to CPLD via SDIR pin to select NEMOIDE HDD
    .BUS_IOW                (IOW),
    .BUS_WRH                (WRH),
    .BUS_IOR                (IOR),
    .BUS_RDH                (RDH),
    .BUS_nemo_cs0           (nemo_cs0),
    .BUS_nemo_cs1           (nemo_cs1)
);

// Serial mouse emulation
wire [7:0] serial_ms_do_bus;
wire serial_ms_oe_n;
wire serial_ms_int;
serial_mouse serial_mouse(
    .CLK                    (clk_bus),
    .CLKEN                  (clk_cpu),
    .N_RESET                (~reset),
    .A                      (cpu_a_bus),
    .DI                     (cpu_do_bus),
    .WR_N                   (cpu_wr_n),
    .RD_N                   (cpu_rd_n),
    .IORQ_N                 (cpu_iorq_n),
    .M1_N                   (cpu_m1_n),
    .CPM                    (cpm),
    .DOS                    (dos_act),
    .ROM14                  (rom14),
    
    .MS_X                   ($signed(ms_x)),
    .MS_Y                   (-$signed(ms_y)),
    .MS_BTNS                (ms_b),
    .MS_PRESET              (ms_present),
    .MS_EVENT               (ms_upd),
    
    .DO                     (serial_ms_do_bus),
    .INT_N                  (serial_ms_int),
    .OE_N                   (serial_ms_oe_n)
);

// UART (via ZX UNO ports #FC3B / #FD3B)  
wire [7:0] zxuno_addr_to_cpu;
wire zxuno_addr_oe_n;
wire [7:0] zxuno_addr;
wire zxuno_regrd, zxuno_regwr, zxuno_regaddr_changed;
wire [7:0] zxuno_uart_do_bus;
wire zxuno_uart_oe_n;

zxunoregs zxunoregs(
    .clk                    (clk_bus),
    .rst_n                  (~reset),
    .a                      (cpu_a_bus),
    .iorq_n                 (cpu_iorq_n),
    .rd_n                   (cpu_rd_n),
    .wr_n                   (cpu_wr_n),
    .din                    (cpu_do_bus),
    .dout                   (zxuno_addr_to_cpu),
    .oe_n                   (zxuno_addr_oe_n),
    .addr                   (zxuno_addr),
    .read_from_reg          (zxuno_regrd),
    .write_to_reg           (zxuno_regwr),
    .regaddr_changed        (zxuno_regaddr_changed)
);

// uart1 - esp8266 @ 115200
wire uart1_tx_req;
wire [7:0] uart1_tx;
zxunouart_emu #(.UARTDATA(8'hC6), .UARTSTAT(8'hC7)) uart1(
    .clk_bus                (clk_bus),
    .reset                  (areset),
    .zxuno_addr             (zxuno_addr),
    .zxuno_regrd            (zxuno_regrd),
    .zxuno_regwr            (zxuno_regwr),
    .din                    (cpu_do_bus),
    .dout                   (zxuno_uart_do_bus),
    .oe_n                   (zxuno_uart_oe_n),
    
    .uart_tx_req            (uart1_tx_req),
    .uart_tx_data           (uart1_tx),

    .uart_rx_req            (uart_rx_req),
    .uart_rx_data           (uart_rx),
);

// uart2 - usb uart @ 115200
wire [7:0] zxuno_uart2_do_bus;
wire zxuno_uart2_oe_n;
zxunouart_emu #(.UARTDATA(8'hC8), .UARTSTAT(8'hC9)) uart2(
    .clk_bus                (clk_bus),
    .reset                  (areset),
    .zxuno_addr             (zxuno_addr),
    .zxuno_regrd            (zxuno_regrd),
    .zxuno_regwr            (zxuno_regwr),
    .din                    (cpu_do_bus),
    .dout                   (zxuno_uart2_do_bus),
    .oe_n                   (zxuno_uart2_oe_n),
    
    .uart_tx_req            (uart2_tx_req),
    .uart_tx_data           (uart2_tx),

    .uart_rx_req            (uart2_rx_req),
    .uart_rx_data           (uart2_rx),
);

wire [7:0] zifi_do_bus;
wire zifi_oe_n;
wire zifi_api_enabled;
wire zifi_tx_req;
wire [7:0] zifi_tx;
/*zifi_emu zifi(
    .CLK                    (clk_bus),
    .RESET                  (areset),

    .A                      (cpu_a_bus),
    .DI                     (cpu_do_bus),
    .DO                     (zifi_do_bus),
    .IORQ_N                 (cpu_iorq_n),
    .RD_N                   (cpu_rd_n),
    .WR_N                   (cpu_wr_n),
    .ZIFI_OE_N              (zifi_oe_n),
    
    .ENABLED                (zifi_api_enabled),

    .UART_TX_REQ            (zifi_tx_req),
    .UART_TX_DATA           (zifi_tx),
    .UART_RX_REQ            (uart_rx_req),
    .UART_RX_DATA           (uart_rx)
);*/

// mux zxuno uart1 / zifi tx requests
assign uart_tx_req = (zifi_api_enabled) ? zifi_tx_req : uart1_tx_req;
assign uart_tx = (zifi_api_enabled) ? zifi_tx : uart1_tx;

// --------------------------------------------------------------------------------------------

// clocks enables
reg clk_div2;
always @(posedge clk_bus)
    clk_div2 <= ~clk_div2;

reg clk_div4;
always @(posedge clk_div2)
    clk_div4 <= ~clk_div4;

reg clk_div8;
always @(posedge clk_div4)
    clk_div8 <= ~clk_div8;

reg clk_div16;
always @(posedge clk_div8)
    clk_div16 <= ~clk_div16;

reg [3:0] ena_cnt;
always @(negedge clk_bus)
    ena_cnt <= ena_cnt + 1;

wire ena_div2 = ena_cnt[0];
wire ena_div4 = ena_cnt[1] && ena_cnt[0];
wire ena_div8 = ena_cnt[2] && ena_cnt[1] && ena_cnt[0];
wire ena_div16 = ena_cnt[3] && ena_cnt[2] && ena_cnt[1] && ena_cnt[0];

// -------------------------------------------------------------------------------
// Global signals

wire reset = areset || btn_reset || loader_reset || loader_act;
assign cpu_reset_n = ~reset && ~loader_reset; // CPU reset
wire cpu_inta_n = cpu_iorq_n || cpu_m1_n;    // INTA

// 11.07.2013:OCH: implementation of nmi signal for DIVMMC
assign cpu_nmi_n = (btn_nmi && btn_divmmc_en) ? mapcond : 
    (~btn_divmmc_en && btn_nmi && ((~cpu_m1_n && ~cpu_mreq_n && cpu_a_bus[15:14] != 2'b00)) || ds80) ? 1'b0 : 1'b1; 
assign cpu_wait_n = 1'b1;

// max turbo = 14 MHz
wire [1:0] max_turbo = "10";

// OCH: automap = '0' and cs_nemo_ports = '0' - not contend DIVMMC and NEMO ports in CLASSIC screen mode
// OCH: disable turbo in trdos to be sure what all programming delays are original
// 06.09.2023:OCH: fixed turbo mode by adding all condition when it can be enabled, i'm not sure about ds80 = 1 but let it be
wire clk_cpu = (btn_wait || (btn_screen_mode == 2'b01 && memory_contention && ~automap && ~cs_nemo_ports && ~ds80) || ~WAIT_IO) ? 0 : 
    (fdd_wait && turbo_mode == 2'b11 && turbo_mode <= max_turbo) ? clk_bus : 
    (fdd_wait && turbo_mode == 2'b10 && turbo_mode <= max_turbo) ? clk_bus && ena_div2 : 
    (fdd_wait && turbo_mode == 2'b01 && turbo_mode <= max_turbo) ? clk_bus && ena_div4 : 
    clk_bus && ena_div8;

// одновибратор - по спаду /IORQ отсчитывает 400нс вейта проца
// для работы периферии в турбе или в режиме расширенного экрана
reg [1:0] WAIT_C;
wire WAIT_IO = WAIT_C[1];
wire WAIT_C_STOP = WAIT_C[1] && ~WAIT_C[0];
wire WAIT_EN = reset || ~turbo_mode[1];
always @(negedge ena_div2) begin
    if (WAIT_EN)
        WAIT_C <= 2'b11;
    else if (cpu_mreq_n)
        WAIT_C <= 2'b11;
    else if (~WAIT_C_STOP)
        WAIT_C <= WAIT_C + 1;
    else if (WAIT_C_STOP)
        WAIT_C <= WAIT_C;
end

//-------------------------------------------------------------------------------
// SD

wire sd_block = (loader_act || is_flash_not_sd);
assign sd_cs_n = (sd_block) ? 1 : zc_cs_n;
assign sd_sck =  (sd_block) ? 1 : zc_sclk;
assign sd_mosi = (sd_block) ? 1 : zc_mosi;

// Flash
assign flash_rd_n = ~port_xxC7_reg[0];    // бит чтения из SPI-Flash
assign flash_wr_n = ~port_xxC7_reg[1];    // бит записи в SPI-Flash
assign flash_er_n = ~port_xxC7_reg[4];  // бит стирания 64-блока SPI-Flash
wire is_flash_not_sd = port_xxC7_reg[2];    // бит переключения SPI между flash / SD картой
wire fw_update_mode = port_xxC7_reg[3];        // бит разрешения обновления SPI-Flash
assign flash_di_bus = port_xxE7_reg;        // Регистр со значением шины данных на вывод в SPI-Flash
assign flash_a_bus = {8'h00, port_xxA7_reg, port_xx87_reg, port_xx67_reg};    // Шина адреса для SPI-Flash

/*
--Доступен, если бит ROM14=1 (7FFD), бит CPM=1 (DFFD), 80DS=1 (DFFD)
--Порт С7 - статус регистр R/W:
--    На чтение:
--        0 бит - flash_busy (1 - устройство занято, 0 - свободно)
--        1 бит - flash_rdy (1 - данные готовы для чтения, 0 - данные не готовы)
--        3 бит - is_flash_not_sd (1 - flash, 0 - SD)
--        4 бит - fw_update_mode (1 - разрешены операции с флешкой, 0 - запрещены)
--
--    На запись:
--        0 бит - flash_rd (1 - инициациирование режима чтения)
--        1 бит - flash_wr (1 - инициациирование режима записи)
--        3 бит - is_flash_not_sd
--        4 бит - fw_update_mode
--    5 бит - flash_er (1 - инициализирование режима стирания 64к блока)
--
--Доступны, если бит ROM14=1 (7FFD), бит CPM=1 (DFFD), 80DS=1 (DFFD), fw_update_mode=1 (xxC7)
--Порт A7 - старший байт выбора страниц spi-flash /W
--Порт 87 - младший байт выбора страниц spi-flash /W
--Порт 67 - адрес байта в странице /W
--Порт E7 - Порт данных для записи и чтения данных из страницы spi-flash
*/


//-------------------------------------------------------------------------------
// Ports

// #FD port correction
// IN A, (#FD) - read a value from a hardware port 
// OUT (#FD), A - writes the value of the second operand into the port given by the first operand.
wire fd_sel = ((cpu_do_bus[7:4] == 4'b1101 && cpu_do_bus[2:0] == 3'b011) || (cpu_di_bus[7:4] == 4'b1101 && cpu_di_bus[2:0] == 3'b011)) ? 1'b0 : 1'b1;

reg fd_port;
always @(posedge reset, posedge cpu_m1_n)
    if (reset)
        fd_port <= 1'b1;
    else if (cpu_m1_n)
        fd_port <= fd_sel;

// PQ-DOS Config PORT X"008B"
wire cs_008b = (cpu_a_bus[15:0] == 16'h008B && ~cpu_iorq_n && cpu_m1_n && ((cpm && rom14) || (dos_act && ~rom14)));
wire rom0 = port_008b_reg[0];        // 0 - ROM64Kb PAGE bit 0 Change
wire rom1 = port_008b_reg[1];         // 1 - ROM64Kb PAGE bit 1 Change
wire rom2 = port_008b_reg[2];        // 2 - ROM64Kb PAGE bit 2 Change
wire rom3 = port_008b_reg[3];        // 3 - ROM64Kb PAGE bit 3 Change
wire rom4 = port_008b_reg[4];         // 4 - ROM64Kb PAGE bit 4 Change
wire rom5 = port_008b_reg[5];        // 5 - ROM64Kb PAGE bit 5 Change
wire onrom = port_008b_reg[6];        // 6 - Forced activation of the signal "DOS"
wire unlock_128 = port_008b_reg[7];    // 7 - Unlock 128 ROM page for DOS

// PQ-DOS Config PORT X"018B"
wire cs_018b = (cpu_a_bus[15:0] == 16'h018B && ~cpu_iorq_n && cpu_m1_n && ((cpm && rom14) || (dos_act && ~rom14)));
wire ram0 = port_018b_reg[0];        // 0 - RAM PAGE bit 0
wire ram1 = port_018b_reg[1];         // 1 - RAM PAGE bit 1
wire ram2 = port_018b_reg[2];        // 2 - RAM PAGE bit 2
wire ram3 = port_018b_reg[3];        // 3 - RAM PAGE bit 3
wire ram4 = port_018b_reg[4];        // 4 - RAM PAGE bit 4
wire ram5 = port_018b_reg[5];        // 5 - RAM PAGE bit 5
wire ram6 = port_018b_reg[6];        // 6 - RAM PAGE bit 6
wire ram7 = port_018b_reg[7];        // 7 - RAM PAGE bit 7

// PQ-DOS Config PORT X"028B"
wire cs_028b = (cpu_a_bus[15:0] == 16'h028B && ~cpu_iorq_n && cpu_m1_n); 
wire hdd_off = port_028b_reg[0];                        // 0     - HDD_off
wire hdd_type = port_028b_reg[1];                        // 1     - HDD type Profi/Nemo
wire turbo_fdc_off = ~port_028b_reg[2] && btn_turbofdc;    // 2     - TURBO_FDC_off
wire fdc_swap = port_028b_reg[3] || btn_swap_floppy;        // 3     - Floppy Disk Drive Selector Change
wire sound_off = port_028b_reg[4];                        // 4     - Sound_off
wire [1:0] turbo_mode = port_028b_reg[6:5];                    // 5,6- Turbo Mode Selector 
wire lock_dffd = port_028b_reg[7];                        // 7     - Lock port DFFD

// OCH: fdd currently disabled, should be implemented with xFF (TRDOS) port bit swapping
// the SDIR pin now used to select NEMOIDE HDD
//bus_sdir <= fdc_swap;

wire [1:0] ext_rom_bank_pq = (~rom0) ? btn_rom_bank : 2'b01;    // ROMBANK ALT

wire rom14 = port_7ffd_reg[4]; // rom bank
wire cpm = port_dffd_reg[5];   // 1 - блокирует работу контроллера из ПЗУ TR-DOS и включает порты на доступ из ОЗУ (ROM14=0); При ROM14=1 - мод. доступ к расширен. периферии
wire worom = port_dffd_reg[4]; // 1 - отключает блокировку порта 7ffd и выключает ПЗУ, помещая на его место ОЗУ из seg 00
wire ds80 = port_dffd_reg[7];  // 0 = seg05 spectrum bitmap, 1 = profi bitmap seg06 & seg 3a & seg 04 & seg 38
wire scr = port_dffd_reg[6];   // памяти CPU на место seg 02, при этом бит D3 CMR0 должен быть в 1 (#8000-#BFFF)
wire sco = port_dffd_reg[3];   // Выбор положения окна проецирования сегментов:
                               // 0 - окно номер 1 (#C000-#FFFF)
                               // 1 - окно номер 2 (#4000-#7FFF)

assign video_ds80 = ds80;

// Extended memory for 1MB (default) or 6MB boards
wire [4:0] ram_ext = {port_7ffd_reg[6], port_7ffd_reg[7], port_dffd_reg[2:0]};  // pent 512 + profi 1024

// OCH: change decoding of #FE port when Nemo enabled 
wire cs_xxfe = ((~cpu_iorq_n && ~cpu_a_bus[0] && ~btn_nemoide_en) || (~cpu_iorq_n && cpu_a_bus[6:0] == 7'b1111110 && btn_nemoide_en));
wire cs_xx7e = (cs_xxfe && ~cpu_a_bus[7]);
wire cs_eff7 = (~cpu_iorq_n && cpu_m1_n && cpu_a_bus == 16'hEFF7);
wire cs_fffd = (~cpu_iorq_n && cpu_m1_n && cpu_a_bus == 16'hFFFD && fd_port);
wire cs_dffd = (~cpu_iorq_n && cpu_m1_n && cpu_a_bus == 16'hDFFD && fd_port && ~lock_dffd);
wire cs_7ffd = (~cpu_iorq_n && cpu_m1_n && cpu_a_bus == 16'h7FFD && fd_port);
wire cs_1ffd = (~cpu_iorq_n && cpu_m1_n && cpu_a_bus == 16'h1FFD && fd_port);
// OCH: change decoding of #FD port when Nemo enabled
wire cs_xxfd = ((~cpu_iorq_n && cpu_m1_n && ~cpu_a_bus[15]) && 
               ((~cpu_a_bus[1] && ~btn_nemoide_en) || (~cpu_a_bus[7:0] == 8'hFD && btn_nemoide_en)));

// Регистры SPI-FLASH
wire cs_flash = (~cpu_iorq_n && cpm && rom14 && ds80);
wire cs_xxC7 = (cs_flash && cpu_a_bus[7:0] == 8'hC7);
wire cs_xx87 = (cs_flash && cpu_a_bus[7:0] == 8'h87 && fw_update_mode);
wire cs_xxA7 = (cs_flash && cpu_a_bus[7:0] == 8'hA7 && fw_update_mode);
wire cs_xxE7 = (cs_flash && cpu_a_bus[7:0] == 8'hE7 && fw_update_mode);
wire cs_xx67 = (cs_flash && cpu_a_bus[7:0] == 8'h67 && fw_update_mode);

// регистр AS часов
wire cs_rtc_as = (~cpu_iorq_n && cpu_m1_n && ((cpu_a_bus[7:0] == 8'hFF || cpu_a_bus[7:0] == 8'hBF) && ((cpm && rom14)) || (dos_act && ~rom14))); // расширенная периферия

// регистр DS часов                      
wire cs_rtc_ds = (~cpu_iorq_n && cpu_m1_n && ((cpu_a_bus[7:0] == 8'hDF || cpu_a_bus[7:0] == 8'h9F) && ((cpm && rom14)) || (dos_act && ~rom14))); // расширенная периферия

// порты #7e - пишутся по фронту /wr
reg [7:0] port_xxfe_reg;
always @(posedge cpu_wr_n)
    if (cs_xxfe)
        port_xxfe_reg <= cpu_do_bus;

// порты Profi HDD
wire cs_hdd = (((cpm && rom14) || (dos_act && ~rom14)) && ~hdd_off);
wire hdd_profi_ebl_n = ~(cpu_a_bus[7] && cpu_a_bus[4:0] == 5'h0B && ~cpu_iorq_n && cs_hdd); // ROM14=0 BAS=0 ПЗУ SYS
wire hdd_wwc_n = ~(~cpu_wr_n && cpu_a_bus[7:0] == 8'hCB && ~cpu_iorq_n && cs_hdd); // Write High byte from Data bus to "Write register"
wire hdd_wwe_n = ~(~cpu_wr_n && cpu_a_bus[7:0] == 8'hEB && ~cpu_iorq_n && cs_hdd); // Read High byte from "Write register" to HDD bus
wire hdd_rww_n = ~(cpu_wr_n && cpu_a_bus[7:0] == 8'hCB && ~cpu_iorq_n && cs_hdd); // Selector Low byte Data bus Buffer Direction: 1 - to HDD bus, 0 - to Data bus
wire hdd_rwe_n = ~(cpu_wr_n && cpu_a_bus[7:0] == 8'hEB && ~cpu_iorq_n && cs_hdd); // Read High byte from "Read register" to Data bus
wire hdd_cs3fx_n = ~(~cpu_wr_n && cpu_a_bus[7:0] == 8'hAB && ~cpu_iorq_n && cs_hdd);
wire hdd_active = (~(hdd_wwc_n && hdd_wwe_n && hdd_rww_n && hdd_rwe_n) || ~(WRH && IOW && IOR && RDH));

// порты Nemo HDD
/*
--0XF0            ;РЕГИСТР СОСТОЯНИЯ/РЕГИСТР КОМАНД
--0XD0            ;CHS-НОМЕР ГОЛОВЫ И УСТР/LBA АДРЕС 24-27
--0XB0            ;CHS-ЦИЛИНДР 8-15/LBA АДРЕС 16-23
--0X90            ;CHS-ЦИЛИНДР 0-7/LBA АДРЕС 8-15
--0X70            ;CHS-НОМЕР СЕКТОРА/LBA АДРЕС 0-7
--0X50            ;СЧЕТЧИК СЕКТОРОВ
--0X30            ;ПОРТ ОШИБОК/СВОЙСТВ
--0X10            ;ПОРТ ДАННЫХ
--0XC8            ;РЕГИСТР СОСТОЯНИЯ/УПРАВЛЕНИЯ
--0X11            ;СТАРШИЕ 8 БИТ
*/
wire cs_nemo_ports = ((cpu_a_bus[7:0] == 8'hF0 || cpu_a_bus[7:0] == 8'hD0 || cpu_a_bus[7:0] == 8'hB0 || cpu_a_bus[7:0] == 8'h90 || cpu_a_bus[7:0] == 8'h70 || cpu_a_bus[7:0] == 8'h50 || cpu_a_bus[7:0] == 8'h30 || cpu_a_bus[7:0] == 8'h10 || cpu_a_bus[7:0] == 8'hC8 || cpu_a_bus[7:0] == 8'h11) && ~cpu_iorq_n && ~cpm);

wire nemo_ebl_n = ~(cs_nemo_ports && cpu_m1_n && btn_nemoide_en);
wire IOW = ~(cpu_a_bus[2:0] == 3'b000 && cpu_m1_n && ~cpu_iorq_n && ~cpm && ~cpu_wr_n);
wire WRH = ~(cpu_a_bus[2:0] == 3'b001 && cpu_m1_n && ~cpu_iorq_n && ~cpm && ~cpu_wr_n);
wire IOR = ~(cpu_a_bus[2:0] == 3'b000 && cpu_m1_n && ~cpu_iorq_n && ~cpm && ~cpu_rd_n);
wire RDH = ~(cpu_a_bus[2:0] == 3'b001 && cpu_m1_n && ~cpu_iorq_n && ~cpm && ~cpu_rd_n);
wire nemo_cs0 = (~nemo_ebl_n) ? cpu_a_bus[3] : 1'b1;
wire nemo_cs1 = (~nemo_ebl_n) ? cpu_a_bus[4] : 1'b1;
wire nemo_ior = (~nemo_ebl_n) ? IOR : 1'b1;
// OCH:
assign bus_sdir = ~nemo_ebl_n;

// порты Profi FDD
wire RT_F2_1 = ~((cpu_a_bus[7:0] == 8'b001???11 && ~cpu_iorq_n) && ((cpm && rom14) || (dos_act && ~rom14))); // 6D
wire RT_F2_2 = ~(cpu_a_bus[7:0] == 8'b101???11 && ~cpu_iorq_n && cpm && ~dos_act && ~rom14); // 75 
wire RT_F2_3 = ~(cpu_a_bus[7:0] == 8'b111???11 && ~cpu_iorq_n && ~cpm && dos_act && rom14); // F3 and FB
wire fdd_cs_pff_n = (RT_F2_1 && RT_F2_2 && RT_F2_3);
wire RT_F1_1 = ~(cpu_a_bus[7:0] == 8'b0?????11 && ~cpu_iorq_n && cpm && ~dos_act && ~rom14); 
wire RT_F1_2 = ~(cpu_a_bus[7:0] == 8'b0?????11 && ~cpu_iorq_n && ~cpm && dos_act && rom14);
wire RT_F1 = (RT_F1_1 && RT_F1_2);
wire P0 = ~((cpu_a_bus[7:0] == 8'b1??00011 && ~cpu_iorq_n) && ((cpm && rom14) || (dos_act && ~rom14)));
wire fdd_cs_n = (RT_F1 && P0);

reg [7:0] fdd_cnt;
always @(posedge ena_div4, posedge reset)
    if (reset)
        fdd_cnt <= 8'hFF;
    else if (~fdd_cs_n && (~cpu_rd_n || ~cpu_wr_n))
        fdd_cnt <= 8'h00;
    else if (fdd_cnt <= 8'h7F)
        fdd_cnt <= fdd_cnt + 1;
    else 
        fdd_cnt <= 8'hFF;

wire fdd_wait = fdd_cnt[7];

// Ports
reg [7:0] port_eff7_reg, port_7ffd_reg, port_1ffd_reg, port_dffd_reg, port_xxC7_reg, port_xx87_reg, port_xxA7_reg, port_xxE7_reg, port_xx67_reg, port_008b_reg, port_018b_reg, port_028b_reg, port_e3_reg, mc146818_a_bus;
reg dos_act;
reg [1:0] kb_turbo_old;
always @(posedge clk_bus, posedge reset) begin
    if (reset) begin
        port_eff7_reg <= 0;
        port_7ffd_reg <= 0;
        port_1ffd_reg <= 0;
        port_dffd_reg <= 0;
        port_xxC7_reg <= 0;
        port_xx87_reg <= 0;
        port_xxA7_reg <= 0;
        port_xxE7_reg <= 0;
        port_xx67_reg <= 0;
        port_008b_reg <= 0;
        port_018b_reg <= 0;
        port_028b_reg <= 0;
        dos_act <= 1;
        kb_turbo_old <= 2'b00;
        // 06.07.2023:OCH: DIVMMC port added to ZController
        port_e3_reg[5:0] <= 6'h00;
        port_e3_reg[7] <= 1'b0;
    end else begin
        // 06.07.2023:OCH: DIVMMC port E3 added to ZController
        // #xxE3
        // 08.07.2023:OCH: Due to confict with port (E3) of fddcontroller in cpm mode
        // block DIVMMC port E3 when in cpm
        if (~cpu_iorq_n && ~cpu_wr_n && cpu_a_bus[7:0] == 8'hE3 && ~cpm && btn_divmmc_en)
            port_e3_reg <= {cpu_do_bus[7], (port_e3_reg[6] || cpu_do_bus[6]), cpu_do_bus[5:0]};
        
        if (cs_eff7 && ~cpu_wr_n) port_eff7_reg <= cpu_do_bus;
        if (cs_rtc_as && ~cpu_wr_n) mc146818_a_bus <= cpu_do_bus;
        if (cs_dffd && ~cpu_wr_n) port_dffd_reg <= cpu_do_bus;
        if (cs_xxfd && ~cpu_wr_n && (~port_7ffd_reg[5] || port_dffd_reg[4])) port_7ffd_reg[5:0] <= cpu_do_bus[5:0];
        if (cs_7ffd && ~cpu_wr_n && (~port_7ffd_reg[5] || port_dffd_reg[4])) port_7ffd_reg[7:6] <= cpu_do_bus[7:6];
        if (cs_1ffd && ~cpu_wr_n) port_1ffd_reg <= cpu_do_bus;
        if (cs_xxC7 && ~cpu_wr_n) port_xxC7_reg <= cpu_do_bus;
        if (cs_xx87 && ~cpu_wr_n) port_xx87_reg <= cpu_do_bus;
        if (cs_xxA7 && ~cpu_wr_n) port_xxA7_reg <= cpu_do_bus;
        if (cs_xxE7 && ~cpu_wr_n) port_xxE7_reg <= cpu_do_bus;
        if (cs_xx67 && ~cpu_wr_n) port_xx67_reg <= cpu_do_bus;
        if (cs_008b && ~cpu_wr_n) port_008b_reg <= cpu_do_bus;
        if (cs_018b && ~cpu_wr_n) port_018b_reg <= cpu_do_bus;
        if (cs_028b && ~cpu_wr_n) 
            port_028b_reg <= cpu_do_bus;
        else if (btn_turbo != kb_turbo_old) begin
            port_028b_reg[6:5] <= btn_turbo[1:0];
            kb_turbo_old <= btn_turbo;
        end
        if ((((~cpu_m1_n && ~cpu_mreq_n && cpu_a_bus[15:8] == 8'h3D && (rom14 || unlock_128)) || (~cpu_nmi_n && ~ds80)) && ~port_dffd_reg[4]) || onrom) dos_act <= 1'b1;
        else if ((~cpu_m1_n && ~cpu_mreq_n && cpu_a_bus[15:14] != 2'b00) || port_dffd_reg[4]) dos_act <= 1'b0;

    end        
end

// Audio misc
wire speaker = port_xxfe_reg[4];
assign buzzer = speaker;
wire tape_in_monitor = ~tape_in;
assign tape_out = port_xxfe_reg[3];
wire saa_wr_n =~(~cpu_iorq_n && ~cpu_wr_n && cpu_a_bus[7:0] == 8'hFF && ~dos_act);

// Port I/O

wire mc146818_wr = (cs_rtc_ds && ~cpu_iorq_n && ~cpu_wr_n && cpu_m1_n);
assign rtc_rd_n = mc146818_wr;
assign rtc_wr_n = ~mc146818_wr;
assign rtc_di_bus = cpu_do_bus;
assign rtc_a = mc146818_a_bus;

// 06.07.2023:OCH: DIVMMC ports added to ZController
// Z-controller + DIVMMC spi 
wire zc_spi_start = ((cpu_a_bus[7:0] == 8'h57 || (cpu_a_bus[7:0] == 8'hEB && ~cpm && btn_divmmc_en )) && ~cpu_iorq_n && cpu_m1_n && ~loader_act && ~is_flash_not_sd);
wire zc_wr_en = ((cpu_a_bus[7:0] == 8'h57 || (cpu_a_bus[7:0] == 8'hEB && ~cpm && btn_divmmc_en)) && ~cpu_iorq_n && cpu_m1_n && ~cpu_wr_n && ~loader_act && ~is_flash_not_sd);
wire port77_wr = ((cpu_a_bus[7:0] == 8'h77 || (cpu_a_bus[7:0] == 8'hE7 && btn_divmmc_en)) && ~cpu_iorq_n && cpu_m1_n && ~cpu_wr_n && ~loader_act && ~is_flash_not_sd);

reg zc_cs_n;
always @(posedge clk_bus)
begin
    if (loader_act || reset)
        zc_cs_n <= 1;
    else begin
        if (port77_wr) begin
            // 06.07.2023:OCH: DIVMMC uses 0 bit to control zc_cs_n, instead of 1 bit ZController. 
            // Lets check port number and select correct bit
            zc_cs_n <= cpu_do_bus[1];
            // 08.07.2023:OCH: E7 port confict with E7 port of SPI Flash parallel interface so block
            // DIVMMC E7 port when flash loader software active
            if (cpu_a_bus[7:0] == 8'hE7 && btn_rom_bank[1:0] != 2'b10)
                zc_cs_n <= cpu_do_bus[0];
            else
                zc_cs_n <= cpu_do_bus[1];
        end
    end
end

wire [7:0] zc_do_bus;
wire zc_sclk;
wire zc_mosi;
zc_spi zc_spi(
    .DI             (cpu_do_bus),
    .START          (zc_spi_start),
    .WR_EN          (zc_wr_en),
    .CLC            (clk_bus),
    .MISO           (sd_miso),
    .DO             (zc_do_bus),
    .SCK            (zc_sclk),
    .MOSI           (zc_mosi)
);

//------------------------ divmmc-----------------------------
// Engineer:   Mario Prato
// 11.07.2013:OCH: adapted by me
// i take this implementation to correctly and easy make nmi 

reg mapterm, map3DXX, map1F00;
always @*
begin
    if (reset || ~btn_divmmc_en) begin
        mapterm <= 0;
        map3DXX <= 0;
        map1F00 <= 1;
    end else begin
        if (cpu_a_bus[15:0] == 16'h0000 || cpu_a_bus[15:0] == 16'h0008 || cpu_a_bus[15:0] == 16'h0038 || cpu_a_bus[15:0] == 16'h0066 || cpu_a_bus[15:0] == 16'h04c6 || cpu_a_bus[15:0] == 16'h0562)
            mapterm <= 1;
        else
            mapterm <= 0;

        // mappa 3D00 - 3DFF
        if (cpu_a_bus[15:8] == 8'b00111101) 
            map3DXX <= 1; 
        else 
            map3DXX <= 0;

        // 1ff8 - 1fff
        if (cpu_a_bus[15:3]== 13'b0001111111111) 
            map1F00 <= 0;
        else 
            map1F00 <= 1;
    end
end

reg mapcond, automap;
always @(negedge cpu_mreq_n, posedge reset, negedge btn_divmmc_en)
    if (reset || ~btn_divmmc_en) begin
        mapcond <= 0;
        automap <= 0;
    end else if (~cpu_m1_n) begin
        mapcond <= ((mapterm || map3DXX || (mapcond && map1F00)) && btn_divmmc_en);
        automap <= ((mapcond || map3DXX) && btn_divmmc_en);
    end

//-------------------------------------------------------------------------------
// CPU Data bus

always @* begin
    case (selector)
        8'h00: cpu_di_bus <= ram_do_bus;
        8'h01: cpu_di_bus <= rtc_do_bus;
        8'h02: cpu_di_bus <= {gx0, ~tape_in, kb_do_bus};
        8'h03: cpu_di_bus <= zc_do_bus;
        8'h04: cpu_di_bus <= 8'b11111100;
        8'h05: cpu_di_bus <= joy_bus;
        8'h06: cpu_di_bus <= ssg_cn0_bus;
        8'h07: cpu_di_bus <= ssg_cn1_bus;
        8'h08: cpu_di_bus <= port_dffd_reg;
        8'h09: cpu_di_bus <= port_7ffd_reg;
        8'h0A: cpu_di_bus <= {ms_z[3:0], 1'b1, ~ms_b[2], ~ms_b[0], ~ms_b[1]};
        8'h0B: cpu_di_bus <= ms_x;
        8'h0C: cpu_di_bus <= ms_y;
        8'h0D: cpu_di_bus <= zxuno_uart2_do_bus;
        8'h0E: cpu_di_bus <= serial_ms_do_bus;
        8'h0F: cpu_di_bus <= zxuno_addr_to_cpu;
        8'h10: cpu_di_bus <= zxuno_uart_do_bus;
        8'h11: cpu_di_bus <= {4'b0000, port_xxC7_reg[3:2], flash_ready, flash_busy};
        8'h12: cpu_di_bus <= flash_do_bus;
        8'h13: cpu_di_bus <= port_008b_reg;
        8'h14: cpu_di_bus <= port_018b_reg;
        8'h15: cpu_di_bus <= port_028b_reg;
        8'h16: cpu_di_bus <= zifi_do_bus;
        8'h17: cpu_di_bus <= vid_attr;
        8'h18: cpu_di_bus <= cpld_do;
        8'h19: cpu_di_bus <= cpld_do; // nemo
        default: cpu_di_bus <= 8'hFF;
    endcase
end

wire [7:0] selector = 
    (~ram_oe_n) ? 8'h00 : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_m1_n && cs_rtc_ds) ? 8'h01 : 
    (cs_xxfe && ~cpu_rd_n) ? 8'h02 :
    (~nemo_ebl_n && ~cpu_rd_n) ? 8'h19 : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_m1_n && (cpu_a_bus[7:0] == 8'h57 || (cpu_a_bus[7:0] == 8'hEB && ~cpm && btn_divmmc_en)) && ~is_flash_not_sd) ? 8'h03 : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_m1_n && cpu_a_bus[7:0] == 8'h77 && ~is_flash_not_sd) ? 8'h04 : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_m1_n && cpu_a_bus[7:0] == 8'h1F && ~dos_act && ~cpm && btn_joy_mode == 3'b000) ? 8'h05 : 
    (cs_fffd && ~cpu_rd_n && ~ssg_sel) ? 8'h06 : 
    (cs_fffd && ~cpu_rd_n && ssg_sel)  ? 8'h07 : 
    (cs_dffd && ~cpu_rd_n) ? 8'h08 : 
    (cs_7ffd && ~cpu_rd_n) ? 8'h09 : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_a_bus == 16'hFADF && ms_present && ~cpm) ? 8'h0A : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_a_bus == 16'hFBDF && ms_present && ~cpm) ? 8'h0B : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_a_bus == 16'hFFDF && ms_present && ~cpm) ? 8'h0C : 
    (~cpu_iorq_n && ~cpu_rd_n && ~zxuno_uart2_oe_n) ? 8'h0D : 
    (~serial_ms_oe_n) ? 8'h0E : 
    (~cpu_iorq_n && ~cpu_rd_n && ~zxuno_addr_oe_n) ? 8'h0F : 
    (~cpu_iorq_n && ~cpu_rd_n && ~zxuno_uart_oe_n) ? 8'h10 : 
    (cs_xxC7 && ~cpu_rd_n) ? 8'h11 : 
    (cs_xxE7 && ~cpu_rd_n) ? 8'h12 : 
    (cs_008b && ~cpu_rd_n) ? 8'h13 : 
    (cs_018b && ~cpu_rd_n) ? 8'h14 : 
    (cs_028b && ~cpu_rd_n) ? 8'h15 : 
    (~zifi_oe_n) ? 8'h16 : 
    (vid_pff_cs && ~cpu_iorq_n && ~cpu_rd_n && cpu_a_bus[7:0] == 8'hFF && ~dos_act && ~cpm && ~ds80) ? 8'h17 : 
    (~cpu_iorq_n && ~cpu_rd_n && cpu_m1_n) ? 8'h18 : 8'hFF;

endmodule

