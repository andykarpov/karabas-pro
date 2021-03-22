// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Radio-86RK home computer
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Adopted to Karabas-Pro board: Andy Karpov (c) 2020

module karabas_pro_rk86(
	input				CLK_50MHZ,

	inout[7:0] 		SRAM_D,
	output[20:0] 	SRAM_A,
	output 			SRAM_NWR,
	output 			SRAM_NRD,
	
	input 			DATA0,
	output 			NCSO,
	output 			DCLK,
	output 			ASDO,
	output 			SD_NCS,
	
	output[2:0] 	VGA_R,
	output[2:0] 	VGA_G,
	output[2:0] 	VGA_B,

	output	 		VGA_HS,
	output 			VGA_VS,
		
	input 			AVR_SCK,
	input 			AVR_MOSI,
	output 			AVR_MISO,
	input 			AVR_NCS,
	
	output 			NRESET,
	output 			CPLD_CLK,
	output 			CPLD_CLK2,
	input 			SDIR,
	output[1:0] 	SA,
	inout[15:0] 	SD,
	
	output 			SND_BS,
	output 			SND_WS,
	output 			SND_DAT,
	
	output 			PIN_141,
	output 			PIN_138,
	output 			PIN_121,
	output 			PIN_120,
	inout 			FDC_STEP, // -- PIN_119 connected to FDC_STEP for TurboFDC
	inout 			SD_MOSI,  // -- PIN_115 connected to SD_S	
	
	input[4:1]		SW3,
		
	input 			UART_RX,
	output 			UART_TX,
	output 			UART_CTS
);

assign UART_TX = 0;
assign UART_CTS = 0;
assign NRESET = 1;
assign CPLD_CLK = 0;
assign CPLD_CLK2 = 0;

////////////////////   RESET   ////////////////////
reg[3:0] reset_cnt;
reg reset_n;
wire reset = ~reset_n;
wire kb_reset;

always @(posedge CLK_50MHZ) begin
	if (~kb_reset && reset_cnt==4'd14)
		reset_n <= 1'b1;
	else begin
		reset_n <= 1'b0;
		reset_cnt <= reset_cnt+4'd1;
	end
end

////////////////////   STEP & GO   ////////////////////
reg		stepkey;
reg		onestep;

always @(posedge CLK_50MHZ) begin
//	stepkey <= KEY[1];
//	onestep <= stepkey & ~KEY[1];
end

////////////////////   MEM   ////////////////////

wire[7:0] rom_o;

assign SRAM_NRD = (vid_rd ? 1'b0 : (~cpu_rd)|addrbus[15]);
assign SRAM_NWR = (vid_rd? 1'b1 : cpu_wr_n|addrbus[15]);
assign SRAM_A[20:0] = (vid_rd ? {6'b000000,vid_addr[14:0]} : {6'b000000,addrbus[14:0]});
assign SRAM_D[7:0] = (!SRAM_NWR ? cpu_o : 8'bz);
wire[7:0] mem_o = SRAM_D[7:0];

biossd rom(.address({addrbus[11]|startup,addrbus[10:0]}), .clock(CLK_50MHZ), .q(rom_o));

////////////////////   CPU   ////////////////////
wire[15:0] addrbus;
wire[7:0] cpu_o;
wire cpu_sync;
wire cpu_rd;
wire cpu_wr_n;
wire cpu_int;
wire cpu_inta_n;
wire inte;
reg[7:0] cpu_i;
reg startup;

always @(*)
	casex (addrbus[15:13])
	3'b0xx: cpu_i = startup ? rom_o : mem_o;
	3'b100: cpu_i = ppa1_o;
	3'b101: cpu_i = sd_o;
	3'b110: cpu_i = crt_o;
	3'b111: cpu_i = rom_o;
	endcase

wire ppa1_we_n = addrbus[15:13]!=3'b100|cpu_wr_n;
wire ppa2_we_n = addrbus[15:13]!=3'b101|cpu_wr_n;
wire crt_we_n  = addrbus[15:13]!=3'b110|cpu_wr_n;
wire crt_rd_n  = addrbus[15:13]!=3'b110|~cpu_rd;
wire dma_we_n  = addrbus[15:13]!=3'b111|cpu_wr_n;

reg[4:0] cpu_cnt;
reg cpu_ce2;
reg[10:0] hldareg;
wire cpu_ce = cpu_ce2;
always @(posedge CLK_50MHZ) begin
	if(reset) begin cpu_cnt<=0; cpu_ce2<=0; hldareg=11'd0; end
	else
   if((hldareg[10:9]==2'b01)&&((cpu_rd==1)||(cpu_wr_n==0))) begin cpu_cnt<=0; cpu_ce2<=1; end
	else
	if(cpu_cnt<27) begin cpu_cnt <= cpu_cnt + 5'd1; cpu_ce2<=0; end
	else begin cpu_cnt<=0; cpu_ce2<=~hlda; end
	hldareg<={hldareg[9:0],hlda};
	startup <= reset|(startup&~addrbus[15]);
end

k580wm80a CPU(.clk(CLK_50MHZ), .ce(cpu_ce), .reset(reset),
	.idata(cpu_i), .addr(addrbus), .sync(cpu_sync), .rd(cpu_rd), .wr_n(cpu_wr_n),
	.intr(cpu_int), .inta_n(cpu_inta_n), .odata(cpu_o), .inte_o(inte));

////////////////////   VIDEO   ////////////////////
wire[7:0] crt_o;
wire[3:0] vid_line;
wire[6:0] vid_char;
wire[15:0] vid_addr;
wire[3:0] dma_dack;
wire[7:0] dma_o;
wire[1:0] vid_lattr;
wire[1:0] vid_gattr;
wire vid_cce,vid_drq,vid_irq,hlda;
wire vid_lten,vid_vsp,vid_rvv,vid_hilight;
wire dma_owe_n,dma_ord_n,dma_oiowe_n,dma_oiord_n;
wire vid_hr, vid_vr;

wire vid_rd = ~dma_oiord_n;

k580wt57 dma(.clk(CLK_50MHZ), .ce(vid_cce), .reset(reset),
	.iaddr(addrbus[3:0]), .idata(cpu_o), .drq({1'b0,vid_drq,2'b00}), .iwe_n(dma_we_n), .ird_n(1'b1),
	.hlda(hlda), .hrq(hlda), .dack(dma_dack), .odata(dma_o), .oaddr(vid_addr),
	.owe_n(dma_owe_n), .ord_n(dma_ord_n), .oiowe_n(dma_oiowe_n), .oiord_n(dma_oiord_n) );

k580wg75 crt(.clk(CLK_50MHZ), .ce(vid_cce),
	.iaddr(addrbus[0]), .idata(cpu_o), .iwe_n(crt_we_n), .ird_n(crt_rd_n),
	.vrtc(vid_vr), .hrtc(vid_hr), .dack(dma_dack[2]), .ichar(mem_o), .drq(vid_drq), .irq(vid_irq),
	.odata(crt_o), .oline(vid_line), .ochar(vid_char), .lten(vid_lten), .vsp(vid_vsp),
	.rvv(vid_rvv), .hilight(vid_hilight), .lattr(vid_lattr), .gattr(vid_gattr) );
	
rk_video vid(.clk(CLK_50MHZ), 
	.hr(VGA_HS), .vr(VGA_VS), 
	.r(VGA_R), .g(VGA_G), .b(VGA_B),
	.hr_wg75(vid_hr), .vr_wg75(vid_vr), .cce(vid_cce),
	.lline(vid_line), .ichar(vid_char),
	.vsp(vid_vsp), .lten(vid_lten), .rvv(vid_rvv) 
);

////////////////////   KBD   ////////////////////
wire[7:0] kbd_o;
wire[2:0] kbd_shift;

cpld_kbd kbd(.CLK(CLK_50MHZ), .N_RESET(~reset), .AVR_MOSI(AVR_MOSI), .AVR_MISO(AVR_MISO), .AVR_SCK(AVR_SCK), .AVR_SS(AVR_SS), .CFG(board_revision),
	.RESET(kb_reset), .I_ADDR(ppa1_a), .o_data(kbd_o), .o_shift(kbd_shift));

////////////////////   SYS PPA   ////////////////////
wire[7:0] ppa1_o;
wire[7:0] ppa1_a;
wire[7:0] ppa1_b;
wire[7:0] ppa1_c;

k580ww55 ppa1(.clk(CLK_50MHZ), .reset(reset), .addr(addrbus[1:0]), .we_n(ppa1_we_n),
	.idata(cpu_o), .odata(ppa1_o), .ipa(ppa1_a), .opa(ppa1_a),
	.ipb(kbd_o), .opb(ppa1_b), .ipc({kbd_shift,tapein,ppa1_c[3:0]}), .opc(ppa1_c));

////////////////////   SOUND   ////////////////////
reg tapein;

wire clk_8;
wire locked;

altpll0 clock(
	.inclk0(CLK_50MHZ),
	.locked(locked),
	.c0(clk_8)
);

tda1543 sound(
	.RESET(reset),
	.CLK(clk_8),
	.DAC_TYPE(audio_dac_type),
	.CS(1'b1),
	.DATA_L(audio_l),
	.DATA_R(audio_r),
	.BCK(SND_BS),
	.WS(SND_WS),
	.DATA(SND_DAT)
);

loader ldr(
	.CLK(CLK_50MHZ),
	.RESET(reset),
	.CFG(board_revision),
	.DATA0(DATA0),
	.NCSO(NCSO),
	.DCLK(loader_dclk),
	.ASDO(loader_asdo),
	.BUSY(loader_act)
);

wire loader_act;
wire loader_asdo;
wire loader_dclk;

reg[7:0] board_revision = {8'b00000000};
reg enable_switches = 1'b1;
reg dac_type = 1'b0;

always @(*) begin 
   casex (board_revision[7:0])
	8'b00000000: begin enable_switches <= 1'b0; dac_type <= 1'b0; end
	8'b00000001: begin enable_switches <= 1'b0; dac_type <= 1'b1; end
	8'b00000010: begin enable_switches <= 1'b1; dac_type <= 1'b0; end
	endcase
end

wire audio_dac_type = dac_type;

wire[15:0] audio_l = {3'b000,ppa1_c[0]^inte,12'b0000000000000};
wire[15:0] audio_r = {3'b000,ppa1_c[0]^inte,12'b0000000000000};

////////////////////   SD CARD   ////////////////////
reg sdcs;
reg sdclk;
reg sdcmd;
reg[6:0] sddata;
wire[7:0] sd_o = {sddata, DATA0};

assign SD_NCS = (loader_act) ? 1'b1 : ~sdcs;
assign ASDO = (loader_act) ? loader_asdo : 1'b1;
assign DCLK = (loader_act) ? loader_dclk : sdclk;
assign SD_MOSI = sdcmd;

always @(posedge CLK_50MHZ or posedge reset) begin
	if (reset) begin
		sdcs <= 1'b0;
		sdclk <= 1'b0;
		sdcmd <= 1'h1;
	end else begin
		if (addrbus[0]==1'b0 && ~ppa2_we_n) sdcs <= cpu_o[0];
		if (addrbus[0]==1'b1 && ~ppa2_we_n) begin
			if (sdclk) sddata <= {sddata[5:0],DATA0};
			sdcmd <= cpu_o[7];
			sdclk <= 1'b0;
		end
		if (cpu_rd) sdclk <= 1'b1;
	end
end

endmodule
