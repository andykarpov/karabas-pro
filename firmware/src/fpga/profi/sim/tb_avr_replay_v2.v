`timescale 1ns / 1ps
// rtl/avr/avr_link.v fed with the v2 packets of the AVR host stand (avr_replay.py v2); the same
// lines as tb_avr_replay_v1.vhd writes for the old avr.vhd: the core side at every "M" when it
// changed, every write into the OSD video memory, the 256 RTC registers at the end.
// +REPLAY=, +STATE=, +OSD= name the files; -DSCK_NS sets the SPI clock (default 125 ns, 8 MHz).
`ifndef SCK_NS
`define SCK_NS 125.0
`endif

module tb_avr_replay_v2;

reg clk = 0;
always #17.857 clk = ~clk;

reg sck = 0, mosi = 0, ss = 1, n_reset = 0;
wire miso;
reg [15:8] a = 8'hFF;
wire [5:0] kb;
wire [7:0] ms_x, ms_y, ms_dx, ms_dy;
wire [2:0] ms_btns;
wire [3:0] ms_z;
wire ms_preset, ms_event;
reg [7:0] rtc_a = 0;
wire [7:0] rtc_do;
wire [2:0] build_a;
reg [7:0] build_q = 8'h30;
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
	.rtc_a(rtc_a), .rtc_di(8'h00), .rtc_do(rtc_do), .rtc_cs(1'b1), .rtc_wr_n(1'b1),
	.loader_done(1'b1), .led1(1'b0), .led2(1'b0), .led1_owr(1'b0), .led2_owr(1'b0),
	.cfg(8'h24), .max_turbo(2'b10),
	.build_a(build_a), .build_q(build_q),
	.soft_sw(soft_sw), .kb_mode(kb_mode), .reset(reset), .turbo(turbo), .magick(magick), .wait_cpu(wait_cpu),
	.joy_type(joy_type), .joy_mode(joy_mode), .osd_overlay(osd_overlay), .osd_popup(osd_popup),
	.screen_mode(screen_mode), .divmmc_en(divmmc_en), .nemoide_en(nemoide_en), .plus3e(plus3e),
	.joy(joy), .joy_btn(joy_btn),
	.osd_wr(osd_wr), .osd_a(osd_a), .osd_d(osd_d)
);

integer of, sf, rf;
reg [1023:0] fname;

always @(posedge clk)
	if (osd_wr) $fdisplay(of, "O %03X %04X", {2'b00, osd_a}, osd_d);

task xfer(input [7:0] b);
	integer i;
	begin
		for (i = 7; i >= 0; i = i - 1) begin
			mosi = b[i];
			#(`SCK_NS / 2) sck = 1;
			#(`SCK_NS / 2) sck = 0;
		end
	end
endtask

reg [8*512-1:0] line_s, prev_s;
reg [47:0] kbs;
reg [19:0] ctl;
integer r, i, n, k, b, code;
reg [7:0] ch;

initial begin
	if (!$value$plusargs("REPLAY=%s", fname)) fname = "v2.rep";
	rf = $fopen(fname, "r");
	if (!$value$plusargs("STATE=%s", fname)) fname = "v2.state";
	sf = $fopen(fname, "w");
	if (!$value$plusargs("OSD=%s", fname)) fname = "v2.osd";
	of = $fopen(fname, "w");
	prev_s = 0;
	#200 n_reset = 1;
	#2000;
	while (!$feof(rf)) begin
		code = $fscanf(rf, " %c", ch);
		if (code != 1) ch = "E";
		if (ch == "P") begin
			code = $fscanf(rf, "%d", n);
			ss = 0; #(`SCK_NS);
			for (i = 0; i < n; i = i + 1) begin
				code = $fscanf(rf, "%h", b);
				xfer(b[7:0]);
			end
			#(`SCK_NS / 2) ss = 1; #1000;
		end
		else if (ch == "M") begin
			code = $fscanf(rf, "%d", k);
			repeat (20) @(posedge clk);
			for (r = 0; r < 8; r = r + 1) begin
				a = 8'hFF; a[8 + r] = 1'b0; #1;
				kbs[r * 6 +: 6] = kb;
			end
			a = 8'hFF;
			ctl = { plus3e, nemoide_en, divmmc_en, screen_mode, osd_popup, osd_overlay, joy_mode,
			        joy_type, kb_mode, wait_cpu, magick, turbo, reset };
			// soft_sw[0] is SW1: print SW1..SW10 as SOFT_SW(1 to 10) of avr.vhd
			$sformat(line_s, "KB=%012X SW=%03X C=%05X J=%02X MX=%02X MY=%02X MB=%01X MZ=%01X MP=%01b ME=%01b DX=%02X DY=%02X",
				kbs, { soft_sw[0], soft_sw[1], soft_sw[2], soft_sw[3], soft_sw[4], soft_sw[5], soft_sw[6],
				soft_sw[7], soft_sw[8], soft_sw[9] }, ctl, joy, ms_x, ms_y, {1'b0, ms_btns}, ms_z,
				ms_preset, ms_event, ms_dx, ms_dy);
			if (line_s != prev_s) begin
				prev_s = line_s;
				$fdisplay(sf, "S %0d %0s", k, line_s);
			end
		end
		else if (ch == "E") begin
			for (i = 0; i < 256; i = i + 1) begin
				rtc_a = i;
				repeat (4) @(posedge clk);
				$fdisplay(sf, "R %02X %02X", i[7:0], rtc_do);
			end
			$fclose(sf); $fclose(of);
			$finish;
		end
	end
	$display("tb_avr_replay_v2: no E line");
	$finish;
end

endmodule
