// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Radio-86RK keyboard
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// Modified by: Andy Karpov  <andy.karpov@gmail.com>
// Added PS2Controller with debouncer and error checking
// 
// Design File: rk_kbd.v
//

module rk_kbd(
	input clk,
	input reset,
	input[16:0] scancode,
	input scancode_ready,
	input[7:0] addr,
	output reg[7:0] odata,
	output[2:0] shift);

reg[2:0] shifts;
assign shift = shifts[2:0];
	
reg[7:0] keymatrix[7:0]; // multi-dimensional array of key matrix 
                                                                                                                                                                          
always @(addr,keymatrix) begin                                                                                                                                             
        odata =                                                                                                                                                           
                (keymatrix[0] & {8{addr[0]}})|                                                                                                                             
                (keymatrix[1] & {8{addr[1]}})|                                                                                                                             
                (keymatrix[2] & {8{addr[2]}})|                                                                                                                             
                (keymatrix[3] & {8{addr[3]}})|                                                                                                                             
                (keymatrix[4] & {8{addr[4]}})|                                                                                                                             
                (keymatrix[5] & {8{addr[5]}})|                                                                                                                             
                (keymatrix[6] & {8{addr[6]}})|                                                                                                                             
                (keymatrix[7] & {8{addr[7]}});                                                                                                                             
end

reg[2:0] c;
reg[3:0] r;

always @(*) begin
	case (scancode[15:0])
	16'h016C: {c,r} = 7'h00; // 7 home
	16'h017D: {c,r} = 7'h10; // 9 pgup
	16'h0076: {c,r} = 7'h20; // esc
	16'h0005: {c,r} = 7'h30; // F1
	16'h0006: {c,r} = 7'h40; // F2
	16'h0004: {c,r} = 7'h50; // F3
	16'h000C: {c,r} = 7'h60; // F4
	16'h0003: {c,r} = 7'h70; // F5

	16'h000D: {c,r} = 7'h01; // tab
	16'h0171: {c,r} = 7'h11; // . del
	16'h005A: {c,r} = 7'h21; // enter
	16'h0066: {c,r} = 7'h31; // bksp
	16'h016B: {c,r} = 7'h41; // 4 left
	16'h0175: {c,r} = 7'h51; // 8 up
	16'h0174: {c,r} = 7'h61; // 6 right
	16'h0172: {c,r} = 7'h71; // 2 down

	16'h0045: {c,r} = 7'h02; // 0
	16'h0016: {c,r} = 7'h12; // 1
	16'h001E: {c,r} = 7'h22; // 2
	16'h0026: {c,r} = 7'h32; // 3
	16'h0025: {c,r} = 7'h42; // 4
	16'h002E: {c,r} = 7'h52; // 5
	16'h0036: {c,r} = 7'h62; // 6
	16'h003D: {c,r} = 7'h72; // 7

	16'h003E: {c,r} = 7'h03; // 8
	16'h0046: {c,r} = 7'h13; // 9
	16'h0055: {c,r} = 7'h23; // =
	16'h000E: {c,r} = 7'h33; // `
	16'h0041: {c,r} = 7'h43; // ,
	16'h004E: {c,r} = 7'h53; // -
	16'h0049: {c,r} = 7'h63; // .
	16'h004A: {c,r} = 7'h73; // gray/ + /

	16'h004C: {c,r} = 7'h04; // ;
	16'h001C: {c,r} = 7'h14; // A
	16'h0032: {c,r} = 7'h24; // B
	16'h0021: {c,r} = 7'h34; // C
	16'h0023: {c,r} = 7'h44; // D
	16'h0024: {c,r} = 7'h54; // E
	16'h002B: {c,r} = 7'h64; // F
	16'h0034: {c,r} = 7'h74; // G

	16'h0033: {c,r} = 7'h05; // H
	16'h0043: {c,r} = 7'h15; // I
	16'h003B: {c,r} = 7'h25; // J
	16'h0042: {c,r} = 7'h35; // K
	16'h004B: {c,r} = 7'h45; // L
	16'h003A: {c,r} = 7'h55; // M
	16'h0031: {c,r} = 7'h65; // N
	16'h0044: {c,r} = 7'h75; // O

	16'h004D: {c,r} = 7'h06; // P
	16'h0015: {c,r} = 7'h16; // Q
	16'h002D: {c,r} = 7'h26; // R
	16'h001B: {c,r} = 7'h36; // S
	16'h002C: {c,r} = 7'h46; // T
	16'h003C: {c,r} = 7'h56; // U
	16'h002A: {c,r} = 7'h66; // V
	16'h001D: {c,r} = 7'h76; // W

	16'h0022: {c,r} = 7'h07; // X
	16'h0035: {c,r} = 7'h17; // Y
	16'h001A: {c,r} = 7'h27; // Z
	16'h0054: {c,r} = 7'h37; // [
	16'h0052: {c,r} = 7'h47; // '
	16'h005B: {c,r} = 7'h57; // ]
	16'h005D: {c,r} = 7'h67; // \!
	16'h0029: {c,r} = 7'h77; // space

	16'h0012: {c,r} = 7'h08; // lshift
	16'h0059: {c,r} = 7'h08; // rshift
	16'h0014: {c,r} = 7'h18; // lctrl
	16'h0114: {c,r} = 7'h18; // rctrl
	16'h0011: {c,r} = 7'h28; // lalt

	16'h000B: {c,r} = 7'h50; // F6
	16'h0083: {c,r} = 7'h70; // F7
	16'h000A: {c,r} = 7'h12; // F8
	16'h0001: {c,r} = 7'h33; // F9
	16'h0007: {c,r} = 7'h56; // F12 - stop
	16'h007C: {c,r} = 7'h46; // gray*
	16'h007B: {c,r} = 7'h66; // gray-
	16'h0078: {c,r} = 7'h67; // F11 - rus
	16'h0073: {c,r} = 7'h28; // 5 center
	16'h017A: {c,r} = 7'h48; // 3 pgdn
	16'h0169: {c,r} = 7'h68; // 1 end
	16'h0170: {c,r} = 7'h78; // 0 ins
	default: {c,r} = 7'h7F;
	endcase
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		keymatrix[0] <= 0;
		keymatrix[1] <= 0;
		keymatrix[2] <= 0;
		keymatrix[3] <= 0;
		keymatrix[4] <= 0;
		keymatrix[5] <= 0;
		keymatrix[6] <= 0;
		keymatrix[7] <= 0;
		shifts[2:0] <= 3'b0;
	end else begin
		if(r!=4'hF && scancode_ready) keymatrix[r][c] <= ~scancode[16]; // is_up
		if (scancode_ready)
		begin
			case (scancode[15:0])
			16'h0012: shifts[0] = ~scancode[16]; // lshift
			16'h0059: shifts[0] = ~scancode[16]; // rshift
			16'h0014: shifts[1] = ~scancode[16]; // lctrl
			16'h0114: shifts[1] = ~scancode[16]; // rctrl
			16'h0011: shifts[2] = ~scancode[16]; // lalt
			endcase
		end
	end
end



endmodule
