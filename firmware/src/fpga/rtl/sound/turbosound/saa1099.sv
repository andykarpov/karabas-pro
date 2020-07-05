`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Miguel Angel Rodriguez Jodar
//
// Create Date:    17:20:11 08/09/2015
// Design Name:    SAM Coupe clone
// Module Name:    saa1099
// Project Name:   SAM Coupe clone
// Target Devices: Spartan 6
// Tool versions:  ISE 12.4
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//
// Synchronous version with fixes for volume and envelope. (Sorgelig)
// 
//
//////////////////////////////////////////////////////////////////////////////////
module saa1099
(
	input        clk_sys,
	input        ce,      // 8 MHz
	input        rst_n,
	input        cs_n,
	input        a0,      // 0=data, 1=address
	input        wr_n,
	input  [7:0] din,
	output [7:0] out_l,
	output [7:0] out_r
);

// DTACK is not implemented. Sorry about that

reg [7:0] amplit0, amplit1, amplit2, amplit3, amplit4, amplit5;
reg [8:0] freq0, freq1, freq2, freq3, freq4, freq5;
reg [7:0] oct10, oct32, oct54;
reg [7:0] freqenable;
reg [7:0] noiseenable;
reg [7:0] noisegen;
reg [7:0] envelope0, envelope1;
reg [7:0] ctrl;  // frequency reset and sound enable for all channels

reg [4:0] addr;  // holds the address of the register to write to
wire      rst = ~rst_n | ctrl[1];

// Write values into internal registers
always @(posedge clk_sys) begin
	reg old_wr;
	old_wr <= wr_n;

	if(~rst_n) begin
		ctrl <= 0;
	end
	else begin
		if(!cs_n & old_wr & !wr_n) begin
			if(a0) addr <= din[4:0];
			else begin
				case (addr)
					'h00: amplit0 <= din;
					'h01: amplit1 <= din;
					'h02: amplit2 <= din;
					'h03: amplit3 <= din;
					'h04: amplit4 <= din;
					'h05: amplit5 <= din;

					'h08: freq0   <= 9'd510 - {1'b0, din};
					'h09: freq1   <= 9'd510 - {1'b0, din};
					'h0A: freq2   <= 9'd510 - {1'b0, din};
					'h0B: freq3   <= 9'd510 - {1'b0, din};
					'h0C: freq4   <= 9'd510 - {1'b0, din};
					'h0D: freq5   <= 9'd510 - {1'b0, din};

					'h10: oct10   <= din;
					'h11: oct32   <= din;
					'h12: oct54   <= din;

					'h14: freqenable <= din;
					'h15: noiseenable<= din;
					'h16: noisegen   <= din;

					'h18: envelope0  <= din;
					'h19: envelope1  <= din;

					'h1C: ctrl       <= din;
				endcase
			end
		end
	end
end

wire gen0_tone;
wire gen1_tone;
wire gen2_tone;
wire gen3_tone;
wire gen4_tone;
wire gen5_tone;

wire pulse_to_noise0, pulse_to_envelope0;
wire pulse_to_noise1, pulse_to_envelope1;

wire noise0, noise1;

wire [3:0] mixout0_l, mixout0_r;
wire [3:0] mixout1_l, mixout1_r;
wire [3:0] mixout2_l, mixout2_r;
wire [3:0] envout0_l, envout0_r;
wire [3:0] mixout3_l, mixout3_r;
wire [3:0] mixout4_l, mixout4_r;
wire [3:0] mixout5_l, mixout5_r;
wire [3:0] envout1_l, envout1_r;

// Frequency and noise generators, top half
saa1099_tone_gen freq_gen0
(
	.*,
	.octave(oct10[2:0]),
	.freq(freq0),
	.out(gen0_tone),
	.pulseout(pulse_to_noise0)
);

saa1099_tone_gen freq_gen1
(
	.*,
	.octave(oct10[6:4]),
	.freq(freq1),
	.out(gen1_tone),
	.pulseout(pulse_to_envelope0)
);

saa1099_tone_gen freq_gen2
(
	.*,
	.octave(oct32[2:0]),
	.freq(freq2),
	.out(gen2_tone),
	.pulseout()
);

saa1099_noise_gen noise_gen0
(
	.*,
	.pulse_from_gen(pulse_to_noise0),
	.noise_freq(noisegen[1:0]),
	.out(noise0)
);


// Frequency and noise generators, bottom half
saa1099_tone_gen freq_gen3
(
	.*,
	.octave(oct32[6:4]),
	.freq(freq3),
	.out(gen3_tone),
	.pulseout(pulse_to_noise1)
);

saa1099_tone_gen freq_gen4
(
	.*,
	.octave(oct54[2:0]),
	.freq(freq4),
	.out(gen4_tone),
	.pulseout(pulse_to_envelope1)
);

saa1099_tone_gen freq_gen5
(
	.*,
	.octave(oct54[6:4]),
	.freq(freq5),
	.out(gen5_tone),
	.pulseout()
);

saa1099_noise_gen noise_gen1
(
	.*,
	.pulse_from_gen(pulse_to_noise1),
	.noise_freq(noisegen[5:4]),
	.out(noise1)
);

// Mixers
sa1099_mixer_and_amplitude mixer0
(
	.env(0),
	.tone(gen0_tone && freqenable[0] && (noisegen[1:0] != 3)),  // if gen0 is being used to generate noise, don't use this channel for tone output
	.noise(noise0 && noiseenable[0]),
	.amplitude_l(amplit0[3:0]),
	.amplitude_r(amplit0[7:4]),
	.out_l(mixout0_l),
	.out_r(mixout0_r)
);

sa1099_mixer_and_amplitude mixer1
(
	.env(0),
	.tone(gen1_tone && freqenable[1] && !envelope0[7]),
	.noise(noise0 && noiseenable[1]),
	.amplitude_l(amplit1[3:0]),
	.amplitude_r(amplit1[7:4]),
	.out_l(mixout1_l),
	.out_r(mixout1_r)
);

// Envelope generators
saa1099_envelope_gen envelope_gen0
(
	.*,
	.envreg(envelope0),
	.write_to_envreg_addr(!cs_n & !wr_n &  a0 & (din[4:0] == 'h18)),
	.write_to_envreg_data(!cs_n & !wr_n & !a0 & (addr == 'h18)),
	.pulse_from_tonegen(pulse_to_envelope0),
	.sound_in_left(amplit2[3:0]),
	.sound_in_right(amplit2[7:4]),
	.sound_out_left(envout0_l),
	.sound_out_right(envout0_r)
);

sa1099_mixer_and_amplitude mixer2
(
	.env(~freqenable[2] & ~noiseenable[2] & envelope0[7]),
	.tone(gen2_tone && freqenable[2]),
	.noise(noise0 && noiseenable[2]),
	.amplitude_l(envout0_l),
	.amplitude_r(envout0_r),
	.out_l(mixout2_l),
	.out_r(mixout2_r)
);

sa1099_mixer_and_amplitude mixer3
(
	.env(0),
	.tone(gen3_tone && freqenable[3] && (noisegen[5:4] != 3)), // if gen3 is being used to generate noise, don't use this channel for tone output
	.noise(noise1 && noiseenable[3]),
	.amplitude_l(amplit3[3:0]),
	.amplitude_r(amplit3[7:4]),
	.out_l(mixout3_l),
	.out_r(mixout3_r)
);

sa1099_mixer_and_amplitude mixer4
(
	.env(0),
	.tone(gen4_tone && freqenable[4] && !envelope1[7]),
	.noise(noise1 && noiseenable[4]),
	.amplitude_l(amplit4[3:0]),
	.amplitude_r(amplit4[7:4]),
	.out_l(mixout4_l),
	.out_r(mixout4_r)
);

saa1099_envelope_gen envelope_gen1
(
	.*,
	.envreg(envelope1),
	.write_to_envreg_addr(!cs_n & !wr_n &  a0 & (din[4:0] == 'h19)),
	.write_to_envreg_data(!cs_n & !wr_n & !a0 & (addr == 'h19)),
	.pulse_from_tonegen(pulse_to_envelope1),
	.sound_in_left(amplit5[3:0]),
	.sound_in_right(amplit5[7:4]),
	.sound_out_left(envout1_l),
	.sound_out_right(envout1_r)
);

sa1099_mixer_and_amplitude mixer5
(
	.env(~freqenable[5] & ~noiseenable[5] & envelope1[7]),
	.tone(gen5_tone && freqenable[5]),
	.noise(noise1 && noiseenable[5]),
	.amplitude_l(envout1_l),
	.amplitude_r(envout1_r),
	.out_l(mixout5_l),
	.out_r(mixout5_r)
);

// Final mix
saa1099_output_mixer outmix_left
(
	.sound_enable(ctrl[0]),
	.i0(mixout0_l),
	.i1(mixout1_l),
	.i2(mixout2_l),
	.i3(mixout3_l),
	.i4(mixout4_l),
	.i5(mixout5_l),
	.o(out_l)
);

saa1099_output_mixer outmix_right
(
	.sound_enable(ctrl[0]),
	.i0(mixout0_r),
	.i1(mixout1_r),
	.i2(mixout2_r),
	.i3(mixout3_r),
	.i4(mixout4_r),
	.i5(mixout5_r),
	.o(out_r)
);

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_tone_gen
(
	input       clk_sys,
	input       ce,
	input       rst,
	input [2:0] octave,
	input [8:0] freq,
	output reg  out,
	output reg  pulseout
);

reg [7:0] fcounter;
always_comb begin
	case (octave)
		0: fcounter = 255;
		1: fcounter = 127;
		2: fcounter = 63;
		3: fcounter = 31;
		4: fcounter = 15;
		5: fcounter = 7;
		6: fcounter = 3;
		7: fcounter = 1;
	endcase
end

reg [8:0] cfinal;
reg [7:0] count;
always @(posedge clk_sys) begin

	pulseout <= 0;
	if(rst) begin
		cfinal <= 0;
		count  <= 0;
		out    <= 0;
	end else if(ce) begin
		if(count == fcounter) begin
			count <= 0;
			if(cfinal == freq) begin
				pulseout <= 1;
				cfinal <= 0;
				out <= ~out;
			end else begin
				cfinal <= cfinal + 1'd1;
			end
		end else begin
			count <= count + 1'd1;
		end
	end
end

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_noise_gen
(
	input        clk_sys,
	input        ce,
	input        rst,
	input        pulse_from_gen,
	input  [1:0] noise_freq,
	output       out
);

reg [10:0] fcounter;
always_comb begin
	case (noise_freq)
		   0: fcounter = 255;
		   1: fcounter = 511;
		   2: fcounter = 1023;
		default: fcounter = 2047;  // actually not used
	endcase
end

reg  [16:0] lfsr;
wire [16:0] new_lfsr = {(lfsr[0] ^ lfsr[2] ^ !lfsr), lfsr[16:1]};
always @(posedge clk_sys) begin
	reg [10:0] count;

	if(rst) begin
		lfsr  <= 0;
		count <= 0;
	end else
	if(ce) begin
		if(count == fcounter) begin
			count <= 0;
			if(noise_freq != 3) lfsr <= new_lfsr;
		end else begin
			count <= count + 1'd1;
		end
	end
	if((noise_freq == 3) & pulse_from_gen) lfsr <= new_lfsr;
end

assign out = lfsr[0];

endmodule

/////////////////////////////////////////////////////////////////////////////////

module sa1099_mixer_and_amplitude
(
	input        env,
	input        tone,
	input        noise,
	input  [3:0] amplitude_l,
	input  [3:0] amplitude_r,
	output [3:0] out_l,
	output [3:0] out_r
);

assign {out_l, out_r} = (tone | noise | env) ? {amplitude_l, amplitude_r} : 8'd0;

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_envelope_gen
(
	input        clk_sys,
	input        rst,
	input  [7:0] envreg,
	input        write_to_envreg_addr,
	input        write_to_envreg_data,
	input        pulse_from_tonegen,
	input  [3:0] sound_in_left,
	input  [3:0] sound_in_right,
	output [3:0] sound_out_left,
	output [3:0] sound_out_right
);

wire [3:0] envelopes[512];
initial begin
	integer i;

	// Generating envelopes
	// 0 0 0 : ______________
	for (i=0;i<64;i=i+1) envelopes[{3'b000,i[5:0]}]  = 0;

	// 0 0 1 : --------------
	for (i=0;i<64;i=i+1) envelopes[{3'b001,i[5:0]}]  = 15;

	// 0 1 0 : \_____________
	for (i=0;i<16;i=i+1)  envelopes[{3'b010,i[5:0]}] = ~i[3:0];
	for (i=16;i<64;i=i+1) envelopes[{3'b010,i[5:0]}] = 0;

	// 0 1 1 : \|\|\|\|\|\|\|\
	for (i=0;i<64;i=i+1) envelopes[{3'b011,i[5:0]}]  = ~i[3:0];

	// 1 0 0 : /\______________
	for (i=0;i<16;i=i+1)  envelopes[{3'b100,i[5:0]}] = i[3:0];
	for (i=16;i<32;i=i+1) envelopes[{3'b100,i[5:0]}] = ~i[3:0];
	for (i=32;i<64;i=i+1) envelopes[{3'b100,i[5:0]}] = 0;

	// 1 0 1 : /\/\/\/\/\/\/\/\
	for (i=0;i<16;i=i+1)  envelopes[{3'b101,i[5:0]}] = i[3:0];
	for (i=16;i<32;i=i+1) envelopes[{3'b101,i[5:0]}] = ~i[3:0];
	for (i=32;i<48;i=i+1) envelopes[{3'b101,i[5:0]}] = i[3:0];
	for (i=48;i<64;i=i+1) envelopes[{3'b101,i[5:0]}] = ~i[3:0];

	// 1 1 0 : /|________________
	for (i=0;i<16;i=i+1)  envelopes[{3'b110,i[5:0]}] = i[3:0];
	for (i=16;i<64;i=i+1) envelopes[{3'b110,i[5:0]}] = 0;

	// 1 1 1 : /|/|/|/|/|/|/|/|/|
	for (i=0;i<64;i=i+1)  envelopes[{3'b111,i[5:0]}] = i[3:0];
end

reg       write_to_address_prev;
wire      write_to_address_edge = (~write_to_address_prev & write_to_envreg_addr);
reg       write_to_data_prev;
wire      write_to_data_edge = (~write_to_data_prev & write_to_envreg_data);
reg [2:0] envshape;
reg       stereoshape;
reg       envclock;
wire      env_enable = envreg[7];
wire      env_resolution = envreg[4];
reg       pending_data;
reg [5:0] envcounter;

wire[5:0] envchk = envcounter | env_resolution;

always @(posedge clk_sys) begin
	if(rst) begin
		envcounter <= 0;
		stereoshape <= 0;
		envshape <= 0;
		envclock <= 0;
		write_to_address_prev <= 0;
		write_to_data_prev <= 0;
		pending_data <= 0;
	end
	else begin
		write_to_address_prev <= write_to_envreg_addr;
		write_to_data_prev <= write_to_envreg_data;
		if(write_to_data_edge) pending_data <= 1;
		if(env_enable) begin
			if(envclock ? write_to_address_edge : pulse_from_tonegen) begin  // pulse from internal or external clock?
				if(envchk == 63)  envcounter <= 32;
					else envcounter <= envcounter + env_resolution + 1'd1;
				if(!envcounter ||
					 (envchk >= 15 && (envshape == 3'b000 || envshape == 3'b010 || envshape == 3'b110)) ||
					 (envchk[3:0] == 15 && (envshape == 3'b001 || envshape == 3'b011 || envshape == 3'b111)) ||
					 (envchk >= 31 && envshape == 3'b100) ||
					 (envchk[4:0] == 31 && envshape == 3'b101)) begin  // find out when to updated buffered values
					if(pending_data) begin  // if we reached one of the designated points (3) or (4) and there is pending data, load it
						envshape <= envreg[3:1];
						stereoshape <= envreg[0];
						envclock <= envreg[5];
						envcounter <= 0;
						pending_data <= 0;
					end
				end
			end
		end
	end
end

wire [3:0] envleft  = envelopes[{envshape,envcounter}];   // take current envelope from envelopes ROM
wire [3:0] envright = (!stereoshape)? envleft : ~envleft; // bit 0 of envreg inverts envelope shape

wire [3:0] temp_out_left, temp_out_right;

saa1099_mul4x4 modulate_left
(
	.a(sound_in_left),
	.b(envleft),
	.o(temp_out_left)
);

saa1099_mul4x4 modulate_right
(
	.a(sound_in_right),
	.b(envright),
	.o(temp_out_right)
);

assign sound_out_left  = env_enable ? temp_out_left  : sound_in_left;
assign sound_out_right = env_enable ? temp_out_right : sound_in_right;

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_mul4x4
(
	input  [3:0] a, // amplitude
	input  [3:0] b, // envelope
	output [3:0] o  // output
);

wire [7:0] res =  (b[0] ? a          : 8'd0)+ 
                  (b[1] ? {  a,1'b0} : 8'd0)+
                  (b[2] ? { a,2'b00} : 8'd0)+
                  (b[3] ? {a,3'b000} : 8'd0);

assign o = res[7:4];

endmodule

/////////////////////////////////////////////////////////////////////////////////

module saa1099_output_mixer
(
	input        sound_enable,
	input  [3:0] i0,
	input  [3:0] i1,
	input  [3:0] i2,
	input  [3:0] i3,
	input  [3:0] i4,
	input  [3:0] i5,
	output [7:0] o
);

wire  [6:0] mix = (sound_enable) ? i0 + i1 + i2 + i3 + i4 + i5 : 7'd0;
wire [15:0] res = (mix[0] ? 16'd682   : 16'd0)+
                  (mix[1] ? 16'd1364  : 16'd0)+
                  (mix[2] ? 16'd2728  : 16'd0)+
                  (mix[3] ? 16'd5456  : 16'd0)+
                  (mix[4] ? 16'd10912 : 16'd0)+
                  (mix[5] ? 16'd21824 : 16'd0)+
                  (mix[6] ? 16'd43648 : 16'd0);

wire [7:0] compressor_table[256] =
'{
	'h00, 'h05, 'h08, 'h0B, 'h0E, 'h10, 'h13, 'h15, 'h18, 'h1A, 'h1C, 'h1E, 'h20, 'h22, 'h24, 'h26,
	'h28, 'h2A, 'h2C, 'h2E, 'h2F, 'h31, 'h33, 'h35, 'h36, 'h38, 'h3A, 'h3B, 'h3D, 'h3F, 'h40, 'h42,
	'h44, 'h45, 'h47, 'h48, 'h4A, 'h4B, 'h4D, 'h4F, 'h50, 'h52, 'h53, 'h55, 'h56, 'h57, 'h59, 'h5A,
	'h5C, 'h5D, 'h5F, 'h60, 'h62, 'h63, 'h64, 'h66, 'h67, 'h69, 'h6A, 'h6B, 'h6D, 'h6E, 'h6F, 'h71,
	'h72, 'h73, 'h75, 'h76, 'h77, 'h79, 'h7A, 'h7B, 'h7D, 'h7E, 'h7F, 'h81, 'h82, 'h83, 'h84, 'h86,
	'h87, 'h88, 'h89, 'h8B, 'h8C, 'h8D, 'h8E, 'h90, 'h91, 'h92, 'h93, 'h95, 'h96, 'h97, 'h98, 'h9A,
	'h9B, 'h9C, 'h9D, 'h9E, 'hA0, 'hA1, 'hA2, 'hA3, 'hA4, 'hA6, 'hA7, 'hA8, 'hA9, 'hAA, 'hAB, 'hAD,
	'hAE, 'hAF, 'hB0, 'hB1, 'hB2, 'hB4, 'hB5, 'hB6, 'hB7, 'hB8, 'hB9, 'hBA, 'hBC, 'hBD, 'hBE, 'hBF,
	'hC0, 'hC1, 'hC2, 'hC4, 'hC5, 'hC6, 'hC7, 'hC8, 'hC9, 'hCA, 'hCB, 'hCC, 'hCE, 'hCF, 'hD0, 'hD1,
	'hD2, 'hD3, 'hD4, 'hD5, 'hD6, 'hD7, 'hD9, 'hDA, 'hDB, 'hDC, 'hDD, 'hDE, 'hDF, 'hE0, 'hE1, 'hE2,
	'hE3, 'hE4, 'hE5, 'hE6, 'hE8, 'hE9, 'hEA, 'hEB, 'hEC, 'hED, 'hEE, 'hEF, 'hF0, 'hF1, 'hF2, 'hF3,
	'hF4, 'hF5, 'hF6, 'hF7, 'hF8, 'hF9, 'hFA, 'hFB, 'hFC, 'hFD, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF,
	'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF,
	'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF,
	'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF,
	'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF, 'hFF
};

assign o = compressor_table[res[15:8]];

endmodule
