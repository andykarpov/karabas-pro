// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of K580WG75 CRT controller
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Design File: k580wg75.v
//
// Warning: This realization is not fully operational.

module k580wg75(
	input clk,
	input ce,
	input iaddr,
	input[7:0] idata,
	input iwe_n,
	input ird_n,
	input vrtc,
	input hrtc,
	input dack,
	input[7:0] ichar,
	output reg drq,
	output reg irq,
	output[7:0] odata,
	output[3:0] oline,
	output reg[6:0] ochar,
	output lten,
	output vsp,
	output rvv,
	output hilight,
	output[1:0] lattr,
	output[1:0] gattr );

reg[7:0] init0;
reg[7:0] init1;
reg[7:0] init2;
reg[7:0] init3;
reg enable,inte,dmae;
reg[2:0] dmadelay;
reg[1:0] dmalen;
reg[6:0] curx;
reg[5:0] cury;

wire[6:0] maxx = init0[6:0];
wire[5:0] maxy = init1[5:0];
wire[3:0] underline  = init2[7:4];
wire[3:0] charheight = init2[3:0];
wire linemode = init3[7];
wire fillattr = init3[6]; // 0 - transparent, 1 - normal fill
wire curblink = init3[5]; // 0 - blink
wire curtype  = init3[4]; // 0 - block, 1 - underline

reg[4:0] chline;
reg[5:0] attr;
reg[5:0] exattr;
reg[3:0] iposf;
reg[3:0] oposf;
reg[6:0] ipos;
reg[7:0] opos;
reg[5:0] ypos;
reg[4:0] frame;
reg lineff,exwe_n,exrd_n,exvrtc,exhrtc,err,vspfe;
reg[6:0] fifo0[15:0];
reg[6:0] fifo1[15:0];
reg[7:0] buf0[79:0];
reg[7:0] buf1[79:0];
reg[2:0] pstate;
reg istate;

wire vcur = opos=={1'b0,curx} && ypos==cury && (frame[3]|curblink);
wire[7:0] obuf = lineff ? buf0[opos] : buf1[opos];

assign odata = {1'b0,inte,irq,1'b0,err,enable,2'b0};
assign oline = linemode==0 ? chline[4:1] : chline[4:1]==0 ? charheight : chline[4:1]+4'b1111;
assign lten = ((attr[5] || (curtype && vcur)) && chline[4:1]==underline);
assign vsp = (attr[1] && frame[4]) || (underline[3]==1'b1 && (chline[4:1]==0||chline[4:1]==charheight)) || !enable || vspfe || ypos==0;
assign rvv = attr[4] ^ (curtype==0 && vcur && chline[4:1]<=underline);
assign gattr = attr[3:2];
assign hilight = attr[0];

always @(posedge clk) begin
	exwe_n <= iwe_n; exrd_n <= ird_n;
	if (ird_n & ~exrd_n) begin
		irq <= 0; err <= 0;
	end
	if (iwe_n & ~exwe_n) begin
		if (iaddr) begin
			case (idata[7:5])
			3'b000: {enable,inte,pstate} <= 5'b00001;
			3'b001: {enable,inte,dmadelay,dmalen} <= {2'b11,idata[4:0]};
			3'b010: enable <= 0;
			3'b011: pstate <= 3'b101;
			3'b100: pstate <= 3'b101;
			3'b101: inte <= 1'b1;
			3'b110: inte <= 1'b0;
			3'b111: enable <= 0; // to do
			endcase
		end else begin
			case (pstate)
			3'b001: {init0,pstate} <= {idata,3'b010};
			3'b010: {init1,pstate} <= {idata,3'b011};
			3'b011: {init2,pstate} <= {idata,3'b100};
			3'b100: {init3,pstate} <= {idata,3'b000};
			3'b101: {curx,pstate} <= {idata[6:0]+1'b1,3'b110};
			3'b110: {cury,pstate} <= {idata[5:0]+1'b1,3'b000};
			default: {err,pstate} <= 4'b1000;
			endcase
		end
	end
	if (ce) begin
		exvrtc <= vrtc; exhrtc <= hrtc;
		if (exvrtc & ~vrtc) begin
			chline <= 0; ypos <= 0; dmae <= 1'b1; vspfe <= 0;
			iposf <= 0; ipos <= 0; oposf <= 0; opos <= 0;
			attr <= 0; exattr <= 0; frame <= frame + 1'b1;
		end else
		if (exhrtc & ~hrtc) begin
			if (chline=={charheight,1'b1}) begin
				chline <= 0; lineff <= ~lineff;
				exattr <= attr; iposf <= 0; ipos <= 0;
				ypos <= ypos + 1'b1;
				if (ypos==maxy) irq <= 1'b1;
			end else begin
				chline <= chline + 1'b1;
				attr <= exattr;
			end
			oposf <= 0; opos <= {2'b0,maxx[6:1]}+8'hD0;
		end else if (ypos!=0) begin
			if (obuf[7:2]==6'b111100) begin
				if (obuf[1]) vspfe <= 1'b1;
			end else
				opos <= opos + 1'b1;
			if (opos > maxx)
				ochar <= 0;
			else begin
				casex (obuf[7:6])
				2'b0x: ochar <= obuf[6:0];
				2'b10: begin
					if (fillattr) begin
						ochar <= 0;
					end else begin
						ochar <= lineff ? fifo0[oposf] : fifo1[oposf];
						oposf <= oposf + 1'b1;
					end
					attr <= obuf[5:0];
				end
				2'b11: ochar <= 0;
				endcase
			end
		end
		if (dack && drq) begin
			drq <= 0;
			case (istate)
			1'b0: begin
				if (ichar[7:4]==4'b1111 && ichar[0]==1'b1) begin
					ipos <= 7'h7F;
					if (ichar[1]==1'b1) dmae <= 0;
				end else begin
					ipos <= ipos + 1'b1;
				end
				istate <= ichar[7:6]==2'b10 ? ~fillattr : 1'b0;
			end
			1'b1: begin
				iposf <= iposf + 1'b1;
				istate <= 0;
			end
			endcase
			case ({istate,lineff})
			2'b00: buf0[ipos] <= ichar;
			2'b01: buf1[ipos] <= ichar;
			2'b10: fifo0[iposf] <= ichar[6:0];
			2'b11: fifo1[iposf] <= ichar[6:0];
			endcase
		end else begin
			drq <= ipos > maxx || ypos > maxy ? 1'b0 : dmae&enable;
		end
	end
end

endmodule
