`timescale 1ns / 1ps
// rtl/avr/avr_link.v against docs/AVR_LINK_V2.md: every command, the answers at their byte
// positions, packets cut in the middle of a record, back-to-back packets with the minimum CS gap,
// CPU writes into the RTC read back by GET (one entry per GET, also when the AVR reads past its
// end). Run with -DCLK_NS=... -DSCK_NS=... (run_avr_link.sh sweeps 24 / 28 MHz x 1 / 4 / 8 MHz).
`ifndef CLK_NS
`define CLK_NS 35.714
`endif
`ifndef SCK_NS
`define SCK_NS 125.0
`endif

module tb_avr_link;

reg clk = 0;
always #(`CLK_NS / 2) clk = ~clk;

reg sck = 0, mosi = 0, ss = 1, n_reset = 0;
wire miso;
reg [15:8] a = 8'hFF;
wire [5:0] kb;
wire [7:0] ms_x, ms_y, ms_dx, ms_dy;
wire [2:0] ms_btns;
wire [3:0] ms_z;
wire ms_preset, ms_event;
reg [7:0] rtc_a = 0, rtc_di = 0;
wire [7:0] rtc_do;
reg rtc_wr_n = 1;
reg loader_done = 0;
reg led1 = 0, led2 = 0, led1_owr = 0, led2_owr = 0;
wire [2:0] build_a;
reg [7:0] build_q = 0;
wire [9:0] soft_sw;
wire kb_mode, reset, magick, wait_cpu, joy_type, osd_overlay, osd_popup, divmmc_en, nemoide_en, plus3e;
wire [1:0] turbo, screen_mode;
wire [2:0] joy_mode;
wire [7:0] joy;
wire [15:0] joy_btn;
wire osd_wr;
wire [9:0] osd_a;
wire [15:0] osd_d;

avr_link dut (
	.clk(clk), .n_reset(n_reset),
	.avr_sck(sck), .avr_mosi(mosi), .avr_miso(miso), .avr_ss(ss),
	.a(a), .kb(kb),
	.ms_x(ms_x), .ms_y(ms_y), .ms_btns(ms_btns), .ms_z(ms_z), .ms_preset(ms_preset), .ms_event(ms_event),
	.ms_delta_x(ms_dx), .ms_delta_y(ms_dy),
	.rtc_a(rtc_a), .rtc_di(rtc_di), .rtc_do(rtc_do), .rtc_cs(1'b1), .rtc_wr_n(rtc_wr_n),
	.loader_done(loader_done), .led1(led1), .led2(led2), .led1_owr(led1_owr), .led2_owr(led2_owr),
	.cfg(8'h24), .max_turbo(2'b10),
	.build_a(build_a), .build_q(build_q),
	.soft_sw(soft_sw), .kb_mode(kb_mode), .reset(reset), .turbo(turbo), .magick(magick), .wait_cpu(wait_cpu),
	.joy_type(joy_type), .joy_mode(joy_mode), .osd_overlay(osd_overlay), .osd_popup(osd_popup),
	.screen_mode(screen_mode), .divmmc_en(divmmc_en), .nemoide_en(nemoide_en), .plus3e(plus3e),
	.joy(joy), .joy_btn(joy_btn),
	.osd_wr(osd_wr), .osd_a(osd_a), .osd_d(osd_d)
);

// message_rom: address registered, output a clock later
reg [7:0] rom [0:7];
reg [2:0] rom_a = 0;
initial begin
	rom[0] = "2"; rom[1] = "6"; rom[2] = "1"; rom[3] = "1"; rom[4] = "1"; rom[5] = "9"; rom[6] = "0"; rom[7] = "7";
end
always @(posedge clk) begin rom_a <= build_a; build_q <= rom[rom_a]; end

integer errors = 0;
task check(input [255:0] what, input [31:0] got, input [31:0] exp);
	if (got !== exp) begin
		errors = errors + 1;
		if (errors < 20) $display("ERROR %0s: got %h, expected %h at %0t", what, got, exp, $time);
	end
endtask

// SPI master, mode 0
reg [7:0] rx [0:2047];
integer nrx;
task xfer(input [7:0] b, output [7:0] r);
	integer i;
	begin
		for (i = 7; i >= 0; i = i - 1) begin
			mosi = b[i];
			#(`SCK_NS / 2) sck = 1; r[i] = miso;
			#(`SCK_NS / 2) sck = 0;
		end
	end
endtask

reg [7:0] tx [0:2047];
reg [7:0] r;
// one packet of n bytes of tx; the answers in rx
task packet(input integer nb);
	integer i;
	begin
		ss = 0; #(`SCK_NS);
		for (i = 0; i < nb; i = i + 1) begin
			xfer(tx[i], r); rx[i] = r;
			#(`SCK_NS / 4); // a small gap between bytes, as the AVR has
		end
		#(`SCK_NS / 2) ss = 1;
		#1000; // 1 us: the minimum gap of the spec
	end
endtask

task sys_poll; begin tx[0] = 0; tx[1] = 0; packet(2); end endtask

task setval(input [7:0] i, input [7:0] v);
	begin tx[0] = 0; tx[1] = 3; tx[2] = i; tx[3] = v; packet(4); end
endtask

task wait_clk(input integer k); repeat (k) @(posedge clk); endtask

integer i, k, osd_n;
reg [9:0] osd_log_a [0:15];
reg [15:0] osd_log_d [0:15];
always @(posedge clk) if (osd_wr) begin
	if (osd_n < 16) begin osd_log_a[osd_n] = osd_a; osd_log_d[osd_n] = osd_d; end
	osd_n = osd_n + 1;
end

task cpu_rtc_write(input [7:0] ad, input [7:0] dd);
	begin
		@(posedge clk); rtc_a = ad; rtc_di = dd; rtc_wr_n = 0;
		wait_clk(4); rtc_wr_n = 1;
		wait_clk(2);
	end
endtask

initial begin
	osd_n = 0;
	#200 n_reset = 1;
	#2000;

	// ---- status: INIT_REQ after reset, LEDs, bytes 2 and 3 are 0
	led1 = 1; led2_owr = 1; wait_clk(4);
	sys_poll;
	check("poll byte 0", rx[0], 8'h00);
	check("status after reset", rx[1], 8'h91);
	led1 = 0; led2_owr = 0; led2 = 1; led1_owr = 1; wait_clk(4);
	sys_poll;
	check("status leds", rx[1], 8'h61);

	// ---- STATUS before the loader is done: zeros
	tx[0] = 0; tx[1] = 1; for (i = 2; i < 16; i = i + 1) tx[i] = 0;
	packet(16);
	for (i = 3; i < 16; i = i + 1) check("STATUS before loader", rx[i], 0);
	loader_done = 1;
	packet(16); // 3 bytes past the end
	check("STATUS K", rx[3], "K"); check("STATUS P", rx[4], "P"); check("STATUS ver", rx[5], 2);
	check("STATUS cfg", rx[6], 8'hA4);
	for (i = 0; i < 8; i = i + 1) check("STATUS build", rx[7 + i], rom[i]);
	check("STATUS past end", rx[15], 0);

	// ---- INIT clears INIT_REQ
	tx[0] = 0; tx[1] = 2; packet(2);
	led2 = 0; led1_owr = 0;
	wait_clk(4); sys_poll;
	check("status after INIT", rx[1], 8'h00);

	// ---- SETVAL: every index, several pairs in one packet, a cut pair
	setval(8'h00, 2); check("rombank 2 sw3", soft_sw[2], 0); check("rombank 2 sw4", soft_sw[3], 1); check("plus3e 0", plus3e, 0);
	setval(8'h00, 4); check("rombank 4 keeps sw4", soft_sw[3], 1); check("plus3e 1", plus3e, 1);
	setval(8'h00, 1); check("rombank 1", {plus3e, soft_sw[3], soft_sw[2]}, 3'b001);
	tx[0] = 0; tx[1] = 3;
	tx[2] = 8'h01; tx[3] = 1; tx[4] = 8'h02; tx[5] = 1; tx[6] = 8'h03; tx[7] = 2; tx[8] = 8'h04; tx[9] = 1;
	tx[10] = 8'h05; tx[11] = 1; tx[12] = 8'h06; tx[13] = 1; tx[14] = 8'h07; tx[15] = 3; tx[16] = 8'h08; tx[17] = 1;
	tx[18] = 8'h09; tx[19] = 1; tx[20] = 8'h0A; tx[21] = 4; tx[22] = 8'h0B; tx[23] = 1; tx[24] = 8'h0C; tx[25] = 1;
	tx[26] = 8'h0D; tx[27] = 1; tx[28] = 8'h0E; tx[29] = 1; tx[30] = 8'h0F; tx[31] = 1; tx[32] = 8'h10; tx[33] = 1;
	tx[34] = 8'h11; tx[35] = 1; tx[36] = 8'h12; tx[37] = 2; tx[38] = 8'h77; tx[39] = 1;
	tx[40] = 8'h0B; // cut: an index without its value
	packet(41);
	check("soft_sw", soft_sw, 10'b1110110111); // SW10 SW9 SW8 . SW6 SW5 . SW3 SW2 SW1
	check("turbo", turbo, 3); check("joy_type", joy_type, 1); check("joy_mode", joy_mode, 4);
	check("screen", screen_mode, 1); check("divmmc", divmmc_en, 1); check("nemoide", nemoide_en, 1);
	check("kb_mode", kb_mode, 1); check("wait", wait_cpu, 1); check("reset", reset, 1); check("magick", magick, 1);
	check("osd", {osd_popup, osd_overlay}, 2'b10);
	setval(8'h03, 1); check("psg mix 1", {soft_sw[8], soft_sw[6]}, 2'b01);
	setval(8'h12, 1); check("osd menu", {osd_popup, osd_overlay}, 2'b01);
	setval(8'h10, 0); setval(8'h11, 0); setval(8'h0F, 0);
	check("controls off", {reset, magick, wait_cpu}, 0);
	tx[0] = 0; tx[1] = 3; tx[2] = 8'h0B; packet(3); // only the index
	check("cut pair keeps screen", screen_mode, 1);

	// ---- MATRIX and the keyboard rows; a cut MATRIX changes nothing
	tx[0] = 1; tx[1] = 1; tx[2] = 8'h01; tx[3] = 8'h80; tx[4] = 8'h00; tx[5] = 8'h00; tx[6] = 8'h10; tx[7] = 8'h01;
	packet(8);
	a = 8'hFE; #1 check("row A8", kb, 6'b011110); // CS (bit 0 of byte 0), and the 5th bit
	a = 8'h7F; #1 check("row A15", kb, 6'b011101); // byte 1 bit 7 = key 15 (SS)
	a = 8'hEF; #1 check("row A12", kb, 6'b001111); // byte 4 bit 4 = key 36
	a = 8'h00; #1 check("all rows", kb, 6'b001100);
	tx[0] = 1; tx[1] = 1; tx[2] = 0; tx[3] = 0; tx[4] = 0; tx[5] = 0; tx[6] = 0; packet(7);
	a = 8'h00; #1 check("cut MATRIX", kb, 6'b001100);
	tx[7] = 0; packet(8);
	#1 check("MATRIX cleared", kb, 6'b111111);
	a = 8'hFF;

	// ---- MOUSE
	k = ms_event;
	tx[0] = 1; tx[1] = 2; tx[2] = 8'd5; tx[3] = 8'hFD; tx[4] = 8'h53; packet(5);
	check("ms x", ms_x, 8'h84); check("ms y", ms_y, 8'h7C); check("ms btns", ms_btns, 3'b101); check("ms z", ms_z, 4'h3);
	check("ms dx", ms_dx, 5); check("ms present", ms_preset, 1); check("ms event", ms_event, {31'd0, ~k[0]});
	tx[2] = 8'd1; tx[3] = 8'd1; tx[4] = 0; packet(5);
	check("ms x 2", ms_x, 8'h85); check("ms event 2", ms_event, {31'd0, k[0]});
	packet(4); check("cut MOUSE", ms_x, 8'h85);

	// ---- JOY: port 0, port 1 (ignored), a cut record
	tx[0] = 1; tx[1] = 3; tx[2] = 0; tx[3] = 8'hE2; tx[4] = 8'h01; tx[5] = 1; tx[6] = 8'hFF; tx[7] = 8'hFF;
	tx[8] = 0; tx[9] = 8'h00;
	packet(10);
	check("joy_btn", joy_btn, 16'h01E2);
	check("kempston", joy, 8'b11111000); // start, A, C, B, up
	tx[0] = 1; tx[1] = 3; tx[2] = 0; tx[3] = 8'h10; tx[4] = 0; packet(5);
	check("kempston right", joy, 8'h01);
	tx[0] = 1; tx[1] = 3; tx[2] = 0; tx[3] = 8'h80; tx[4] = 0; packet(5);
	check("kempston B = fire", joy, 8'h10);
	tx[0] = 1; tx[1] = 3; tx[2] = 0; tx[3] = 8'h00; tx[4] = 8'h01; packet(5);
	check("kempston C = fire 2", joy, 8'h20);

	// ---- OSD WRITE: three cells from (31, 25) and over the end of the memory
	osd_n = 0;
	tx[0] = 2; tx[1] = 1; tx[2] = 8'h3F; tx[3] = 8'h03; tx[4] = "A"; tx[5] = 8'h70; tx[6] = "B"; tx[7] = 8'h07;
	tx[8] = "C";
	packet(9); // the last cell is cut
	check("osd writes", osd_n, 2);
	check("osd a0", osd_log_a[0], 10'h33F); check("osd d0", osd_log_d[0], {8'h41, 8'h70});
	check("osd a1", osd_log_a[1], 10'h340); check("osd d1", osd_log_d[1], {8'h42, 8'h07});
	osd_n = 0;
	tx[2] = 8'hFF; tx[3] = 8'h03; tx[4] = "x"; tx[5] = 1; tx[6] = "y"; tx[7] = 2; packet(8);
	check("osd wrap", osd_log_a[1], 10'h000);

	// ---- OSD WRITE of a whole screen and more: 4 + 1000 x 2 bytes (past the 1024 positions of n)
	osd_n = 0;
	tx[0] = 2; tx[1] = 1; tx[2] = 8'h00; tx[3] = 8'h00;
	for (i = 0; i < 1000; i = i + 1) begin tx[4 + 2 * i] = i[7:0] ^ 8'hA5; tx[5 + 2 * i] = 8'h5A; end
	packet(2004);
	check("long run writes", osd_n, 1000);
	check("long run cell 15", osd_log_a[15], 10'd15);
	check("long run last", dut.osd_a, 10'd999);
	check("long run data", dut.osd_d, { 8'd231 ^ 8'hA5, 8'h5A }); // 999 & 255

	// ---- RTC SET and the CPU reading the registers (2 clocks)
	tx[0] = 3; tx[1] = 1; tx[2] = 8'hFE; tx[3] = 8'h11; tx[4] = 8'h22; tx[5] = 8'h33; packet(6);
	@(posedge clk) rtc_a = 8'hFE; wait_clk(3); check("rtc FE", rtc_do, 8'h11);
	@(posedge clk) rtc_a = 8'hFF; wait_clk(3); check("rtc FF", rtc_do, 8'h22);
	@(posedge clk) rtc_a = 8'h00; wait_clk(3); check("rtc 00 wraps", rtc_do, 8'h33);
	@(posedge clk) rtc_a = 8'h05; wait_clk(1); check("rtc latency", rtc_do, 8'h33); wait_clk(2);

	// ---- CPU writes: status bit 1, GET one entry per packet, reading past the end
	cpu_rtc_write(8'h0B, 8'h86); cpu_rtc_write(8'h20, 8'h5A); cpu_rtc_write(8'h21, 8'hA5);
	@(posedge clk) rtc_a = 8'h20; wait_clk(3); check("cpu wrote ram", rtc_do, 8'h5A);
	sys_poll; check("rtc pending", rx[1], 8'h02);
	tx[0] = 3; tx[1] = 2; tx[2] = 0; tx[3] = 0; tx[4] = 0; tx[5] = 0; tx[6] = 0;
	packet(7); // 2 bytes past the end
	check("get reg", rx[3], 8'h0B); check("get val", rx[4], 8'h86); check("get past", rx[5], 0);
	sys_poll; check("still pending", rx[1], 8'h02);
	tx[0] = 3; tx[1] = 2; tx[2] = 0; tx[3] = 0; tx[4] = 0;
	packet(5); check("get 2 reg", rx[3], 8'h20); check("get 2 val", rx[4], 8'h5A);
	packet(3); // cut before the register byte: the entry stays
	packet(4); // cut after the register byte, before the value: the entry stays
	check("cut get reg", rx[3], 8'h21);
	packet(5); check("get 3 reg", rx[3], 8'h21); check("get 3 val", rx[4], 8'hA5);
	sys_poll; check("fifo empty", rx[1], 8'h00);
	tx[0] = 3; tx[1] = 2; tx[2] = 0; tx[3] = 0; tx[4] = 0;
	packet(5); check("get empty", {rx[3], rx[4]}, 16'h0000);

	// ---- back-to-back packets with the minimum gap
	for (i = 0; i < 20; i = i + 1) begin
		tx[0] = 0; tx[1] = 3; tx[2] = 8'h07; tx[3] = i & 3; packet(4);
		check("back to back", turbo, i & 3);
	end

	// ---- unknown target and command
	tx[0] = 8'h55; tx[1] = 8'h01; tx[2] = 1; tx[3] = 2; packet(4);
	tx[0] = 0; tx[1] = 8'h44; tx[2] = 8'h07; tx[3] = 0; packet(4);
	check("unknown ignored", turbo, 3);
	sys_poll; check("status at the end", rx[1], 8'h00);

	$display("tb_avr_link clk %0.3f ns sck %0.1f ns: %0d errors", `CLK_NS, `SCK_NS, errors);
	$finish;
end

endmodule
