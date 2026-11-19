`timescale 1ns / 1ps
`default_nettype none

/*
 avr_link.v

 The AVR link v2 of Karabas-Pro (docs/AVR_LINK_V2.md): one packet per chip select, T (target),
 C (command), then the payload. The transport is kg_l2_link.v of karabas-go-modules (master
 40184bd, the byte toggle at the falling edge that loads the answer: no bound of clk against
 sck), with one change: the answer to the byte T is the status byte (Go: 0).

 Targets: 00 SYS (POLL, STATUS, INIT, SETVAL), 01 HID (MATRIX, MOUSE, JOY; PS2 ignored), 02 OSD
 (WRITE), 03 RTC (SET, GET). Everything runs on clk (clk_bus); the core side is the same as in
 the old avr.vhd: the keyboard rows, the menu values and controls, the mouse, the Kempston byte,
 the RTC registers (a 256 x 8 RAM, 2-clock read like the old altsyncram) and the OSD video
 memory writes.

 The build id comes from message_rom (outside: an altsyncram with the MIF of the build): build_a
 is set one byte ahead of the STATUS byte that answers it.
*/

module avr_link #(
	parameter CS_FILTER = 3
) (
	input  wire        clk,
	input  wire        n_reset,

	input  wire        avr_sck,
	input  wire        avr_mosi,
	output wire        avr_miso,
	input  wire        avr_ss,

	// keyboard rows for the CPU
	input  wire [15:8] a,
	output wire [5:0]  kb,

	// mouse
	output wire [7:0]  ms_x,
	output wire [7:0]  ms_y,
	output reg  [2:0]  ms_btns = 3'b000,
	output reg  [3:0]  ms_z = 4'b0000,
	output reg         ms_preset = 1'b0,
	output reg         ms_event = 1'b0,
	output reg  [7:0]  ms_delta_x = 8'h00,
	output reg  [7:0]  ms_delta_y = 8'h00,

	// RTC registers (MC146818A) for the CPU
	input  wire [7:0]  rtc_a,
	input  wire [7:0]  rtc_di,
	output reg  [7:0]  rtc_do = 8'h00,
	input  wire        rtc_cs,
	input  wire        rtc_wr_n,

	input  wire        loader_done,
	input  wire        led1,
	input  wire        led2,
	input  wire        led1_owr,
	input  wire        led2_owr,
	input  wire [7:0]  cfg,
	input  wire [1:0]  max_turbo,

	// build id ROM (message_rom)
	output reg  [2:0]  build_a = 3'd0,
	input  wire [7:0]  build_q,

	// menu values and controls (SYS SETVAL)
	output reg  [9:0]  soft_sw = 10'd0, // soft_sw[0] = SW1 ... soft_sw[9] = SW10
	output reg         kb_mode = 1'b0,
	output reg         reset = 1'b0,
	output reg  [1:0]  turbo = 2'b00,
	output reg         magick = 1'b0,
	output reg         wait_cpu = 1'b0,
	output reg         joy_type = 1'b0,
	output reg  [2:0]  joy_mode = 3'b000,
	output reg         osd_overlay = 1'b0,
	output reg         osd_popup = 1'b0,
	output reg  [1:0]  screen_mode = 2'b00,
	output reg         divmmc_en = 1'b0,
	output reg         nemoide_en = 1'b0,
	output reg         plus3e = 1'b0,

	// joystick: the Kempston byte and all buttons
	output wire [7:0]  joy,
	output reg  [15:0] joy_btn = 16'h0000,

	// OSD video memory
	output reg         osd_wr = 1'b0,
	output reg  [9:0]  osd_a = 10'd0,
	output reg  [15:0] osd_d = 16'h0000
);

// ======================================================================== transport

wire cs_n = avr_ss;
wire cs_n_f;
generate
	if (CS_FILTER > 0) begin : csf
		reg [CS_FILTER-1:0] cs_sync = {CS_FILTER{1'b1}};
		wire [CS_FILTER:0] cs_next = { cs_sync, cs_n };
		always @(posedge clk)
			cs_sync <= cs_next[CS_FILTER-1:0];
		assign cs_n_f = cs_n & (&cs_sync);
	end
	else begin : nocsf
		assign cs_n_f = cs_n;
	end
endgenerate

reg [7:0] di = 8'h00; // the answer for the next byte

// sck domain: bits on the rising edge; the falling edge after the last bit of a byte loads di
// and toggles byte_tgl, the other falling edges shift
reg [2:0] bitcnt = 3'd0;
always @(posedge avr_sck or posedge cs_n_f)
	if (cs_n_f)
		bitcnt <= 3'd0;
	else
		bitcnt <= bitcnt + 3'd1;

reg [7:0] txsh = 8'h00;
reg first = 1'b1;
always @(negedge avr_sck or posedge cs_n_f)
	if (cs_n_f) begin
		txsh <= 8'h00;
		first <= 1'b1;
	end
	else if (bitcnt == 3'd0 && !first)
		txsh <= di;
	else begin
		txsh <= { txsh[6:0], 1'b0 };
		first <= 1'b0;
	end

reg byte_tgl = 1'b0;
always @(negedge avr_sck)
	if (!cs_n_f && bitcnt == 3'd0 && !first)
		byte_tgl <= ~byte_tgl;

assign avr_miso = cs_n_f ? 1'bz : txsh[7];

reg [6:0] shreg = 7'd0;
reg [7:0] byte_hold = 8'd0;
always @(posedge avr_sck)
	if (!cs_n_f) begin
		shreg <= { shreg[5:0], avr_mosi };
		if (bitcnt == 3'd7)
			byte_hold <= { shreg, avr_mosi };
	end

// clk domain
reg [2:0] tgl_s = 3'd0;
always @(posedge clk)
	tgl_s <= { tgl_s[1:0], byte_tgl };
wire byte_in = tgl_s[2] != tgl_s[1];

// a packet ends when CS has been high for 8 clocks after its last byte
reg [1:0] cs_s = 2'b11;
reg [3:0] high = 4'd0;
always @(posedge clk) begin
	cs_s <= { cs_s[0], cs_n_f };
	if (!cs_s[1])
		high <= 4'd0;
	else if (!high[3])
		high <= high + 1'b1;
end
wire idle = high[3];

reg [10:0] pos = 11'd0; // the next byte of the packet: 0 target, 1 command, 2.. payload
reg [7:0] tgt = 8'hFF;
reg [7:0] cmd_r = 8'h00;

wire        start = byte_in && pos == 11'd1;
wire [7:0]  cmd = start ? byte_hold : cmd_r;
wire        stb = byte_in && pos >= 11'd2;
wire [9:0]  n = pos[9:0] - 10'd2;
wire [7:0]  d = byte_hold;
wire        rq = byte_in && pos != 11'd0;   // the answer for payload position rq_m
wire [9:0]  rq_m = pos[9:0];
wire [7:0]  q;
wire [7:0]  status;

always @(posedge clk) begin
	if (byte_in) begin
		if (pos != 11'h7FF)
			pos <= pos + 1'b1;
		if (pos == 11'd0)
			tgt <= byte_hold;
		if (start)
			cmd_r <= byte_hold;
		di <= (pos == 11'd0) ? 8'h00 : q;
	end
	else if (idle) begin
		pos <= 11'd0;
		tgt <= 8'hFF;
		di <= status; // the answer to the byte C of the next packet
	end
end

// record phase of the payload (SETVAL pairs, JOY triples, OSD pairs)
reg [1:0] ph = 2'd0;
always @(posedge clk)
	if (start)
		ph <= 2'd0;
	else if (stb)
		ph <= (tgt == 8'h01 && cmd_r == 8'h03) ? ((ph == 2'd2) ? 2'd0 : ph + 2'd1) : { 1'b0, ~ph[0] };

wire t_sys = tgt == 8'h00;
wire t_hid = tgt == 8'h01;
wire t_osd = tgt == 8'h02;
wire t_rtc = tgt == 8'h03;

// ======================================================================== SYS

reg init_req = 1'b1;
always @(posedge clk or negedge n_reset)
	if (!n_reset)
		init_req <= 1'b1;
	else if (start && t_sys && cmd == 8'h02)
		init_req <= 1'b0;

reg [7:0] sv_idx = 8'h00;
reg [1:0] rombank = 2'b00;
always @(posedge clk)
	if (stb && t_sys && cmd_r == 8'h03) begin
		if (!ph[0])
			sv_idx <= d;
		else
			case (sv_idx)
				8'h00: if (d == 8'd4) plus3e <= 1'b1;
				       else begin plus3e <= 1'b0; soft_sw[2] <= d[0]; soft_sw[3] <= d[1]; end
				8'h01: soft_sw[4] <= d[0];
				8'h02: soft_sw[5] <= d[0];
				8'h03: begin soft_sw[6] <= d[0]; soft_sw[8] <= d[1]; end
				8'h04: soft_sw[7] <= d[0];
				8'h05: soft_sw[0] <= d[0];
				8'h06: soft_sw[1] <= d[0];
				8'h07: turbo <= d[1:0];
				8'h08: soft_sw[9] <= d[0];
				8'h09: joy_type <= d[0];
				8'h0A: joy_mode <= d[2:0];
				8'h0B: screen_mode <= d[1:0];
				8'h0C: divmmc_en <= d[0];
				8'h0D: nemoide_en <= d[0];
				8'h0E: kb_mode <= d[0];
				8'h0F: wait_cpu <= d[0];
				8'h10: reset <= d[0];
				8'h11: magick <= d[0];
				8'h12: begin osd_overlay <= d[0]; osd_popup <= d[1]; end
				default: ;
			endcase
	end

// ======================================================================== HID

reg [39:0] kb_tmp = 40'd0;
reg [40:0] kb_data = 41'd0;
reg [7:0] m_x = 8'h00, m_y = 8'h00;
reg [7:0] cur_x = 8'h7F, cur_y = 8'h7F;
reg [7:0] j_lo = 8'h00;
reg [7:0] j_port = 8'h00;

always @(posedge clk)
	if (stb && t_hid) begin
		case (cmd_r)
			8'h01: // MATRIX
				case (n)
					10'd0: kb_tmp[7:0] <= d;
					10'd1: kb_tmp[15:8] <= d;
					10'd2: kb_tmp[23:16] <= d;
					10'd3: kb_tmp[31:24] <= d;
					10'd4: kb_tmp[39:32] <= d;
					10'd5: kb_data <= { d[0], kb_tmp };
					default: ;
				endcase
			8'h02: // MOUSE
				case (n)
					10'd0: m_x <= d;
					10'd1: m_y <= d;
					10'd2: begin
						ms_z <= d[3:0];
						ms_btns <= d[6:4];
						ms_delta_x <= m_x;
						ms_delta_y <= m_y;
						cur_x <= cur_x + m_x;
						cur_y <= cur_y + m_y;
						ms_preset <= 1'b1;
						ms_event <= ~ms_event;
					end
					default: ;
				endcase
			8'h03: // JOY: (port, lo, hi) x n
				case (ph)
					2'd0: j_port <= d;
					2'd1: j_lo <= d;
					default: if (j_port == 8'h00) joy_btn <= { d, j_lo };
				endcase
			default: ;
		endcase
	end

assign ms_x = cur_x;
assign ms_y = cur_y;

// Kempston: 0 right, 1 left, 2 down, 3 up, 4 B (fire), 5 C (fire 2), 6 A, 7 Start
assign joy = { joy_btn[5], joy_btn[6], joy_btn[8], joy_btn[7], joy_btn[1], joy_btn[2], joy_btn[3], joy_btn[4] };

// the keyboard rows: a low address line selects a row, a pressed key reads 0
genvar r;
generate
	for (r = 0; r < 5; r = r + 1) begin : rows
		assign kb[r] = ~|(kb_data[r*8 +: 8] & ~a[15:8]);
	end
endgenerate
assign kb[5] = ~kb_data[40];

// ======================================================================== OSD

// a run may be longer than the 1024 positions of n (a whole screen is 4 + 832 x 2 bytes): the
// two address bytes are counted by osd_hdr, the cells by ph
reg [9:0] osd_wa = 10'd0;
reg [7:0] osd_chr = 8'h00;
reg [1:0] osd_hdr = 2'd0;
always @(posedge clk) begin
	osd_wr <= 1'b0;
	if (start)
		osd_hdr <= 2'd0;
	if (stb && t_osd && cmd_r == 8'h01) begin
		if (osd_hdr != 2'd2)
			osd_hdr <= osd_hdr + 2'd1;
		if (osd_hdr == 2'd0)
			osd_wa[7:0] <= d;
		else if (osd_hdr == 2'd1)
			osd_wa[9:8] <= d[1:0];
		else if (!ph[0])
			osd_chr <= d;
		else begin
			osd_wr <= 1'b1;
			osd_a <= osd_wa;
			osd_d <= { osd_chr, d };
			osd_wa <= osd_wa + 10'd1;
		end
	end
end

// ======================================================================== RTC

// registers: the CPU writes first, a byte of RTC SET waits for a free clock
reg [7:0] rtc_mem [0:255];
reg [7:0] rtc_q1 = 8'h00;
reg [7:0] rtc_wa = 8'h00;
reg       av_pend = 1'b0;
reg [7:0] av_a = 8'h00, av_d = 8'h00;
wire      cpu_wr = !init_req && !rtc_wr_n && rtc_cs;
reg       ram_we;
reg [7:0] ram_a, ram_d;

always @(*) begin
	ram_we = 1'b0; ram_a = av_a; ram_d = av_d;
	if (cpu_wr) begin
		ram_we = 1'b1; ram_a = rtc_a; ram_d = rtc_di;
	end
	else if (av_pend) begin
		ram_we = 1'b1;
	end
end

always @(posedge clk) begin
	if (ram_we)
		rtc_mem[ram_a] <= ram_d;
	rtc_q1 <= rtc_mem[rtc_a];
	rtc_do <= rtc_q1;
end

always @(posedge clk) begin
	if (!cpu_wr && av_pend)
		av_pend <= 1'b0;
	if (stb && t_rtc && cmd_r == 8'h01) begin
		if (n == 10'd0)
			rtc_wa <= d;
		else begin
			av_pend <= 1'b1;
			av_a <= rtc_wa;
			av_d <= d;
			rtc_wa <= rtc_wa + 8'd1;
		end
	end
end

// FIFO of the CPU writes for RTC GET: 256 x 16 in block RAM, one entry per write strobe
reg [15:0] fifo_mem [0:255];
reg [15:0] fifo_head = 16'h0000;
reg [7:0]  f_wr = 8'd0, f_rd = 8'd0;
reg [8:0]  f_cnt = 9'd0;
reg        cpu_wr_d = 1'b0;
reg [1:0]  f_ne = 2'b00;
wire       f_push = cpu_wr && !cpu_wr_d && !f_cnt[8];
reg        get_ok = 1'b0;
// the entry goes when its value byte has gone to the AVR (the 5th byte of the packet ends), so a
// packet cut before that keeps it
wire       f_pop = stb && t_rtc && cmd_r == 8'h02 && n == 10'd2 && get_ok;

always @(posedge clk) begin
	cpu_wr_d <= cpu_wr;
	if (f_push) begin
		fifo_mem[f_wr] <= { rtc_a, rtc_di };
		f_wr <= f_wr + 8'd1;
	end
	fifo_head <= fifo_mem[f_rd];
	if (f_pop)
		f_rd <= f_rd + 8'd1;
	f_cnt <= f_cnt + (f_push ? 9'd1 : 9'd0) - (f_pop ? 9'd1 : 9'd0);
	// an entry is readable once fifo_head has had two clocks to follow f_rd / the write
	f_ne <= { f_ne[0], f_cnt != 9'd0 };
	if (rq && t_rtc && cmd == 8'h02 && rq_m == 10'd1)
		get_ok <= f_ne[1] && f_cnt != 9'd0;
end
wire rtc_pend = f_ne[1] && f_cnt != 9'd0;

// ======================================================================== answers

reg led1_r = 1'b0, led2_r = 1'b0, led1_owr_r = 1'b0, led2_owr_r = 1'b0;
always @(posedge clk) begin
	led1_r <= led1; led2_r <= led2; led1_owr_r <= led1_owr; led2_owr_r <= led2_owr;
end
assign status = { led2_owr_r, led1_owr_r, led2_r, led1_r, 2'b00, rtc_pend, init_req };

// build id: build_a for the next STATUS byte (payload 5..12 = build 0..7)
always @(posedge clk)
	if (rq)
		build_a <= rq_m[2:0] - 3'd4;

reg [7:0] q_r;
always @(*) begin
	q_r = 8'h00;
	if (t_sys && cmd == 8'h01 && loader_done)
		case (rq_m)
			10'd1: q_r = 8'h4B; // 'K'
			10'd2: q_r = 8'h50; // 'P'
			10'd3: q_r = 8'h02;
			10'd4: q_r = { max_turbo, cfg[5:0] };
			10'd5, 10'd6, 10'd7, 10'd8, 10'd9, 10'd10, 10'd11, 10'd12: q_r = build_q;
			default: ;
		endcase
	else if (t_rtc && cmd == 8'h02)
		case (rq_m)
			10'd1: q_r = (f_ne[1] && f_cnt != 9'd0) ? fifo_head[15:8] : 8'h00;
			10'd2: q_r = get_ok ? fifo_head[7:0] : 8'h00;
			default: ;
		endcase
end
assign q = q_r;

endmodule

`default_nettype wire
