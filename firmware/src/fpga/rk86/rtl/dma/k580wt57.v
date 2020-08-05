// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of K580WT57 DMA controller
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// 
// Design File: k580wt57.v
//
// Warning: This realization is not fully operational.

module k580wt57(
	input clk,
	input ce,
	input reset,
	input[3:0] iaddr,
	input[7:0] idata,
	input[3:0] drq,
	input iwe_n,
	input ird_n,
	input hlda,
	output hrq,
	output reg[3:0] dack,
	output[7:0] odata,
	output[15:0] oaddr,
	output owe_n,
	output ord_n,
	output oiowe_n,
	output oiord_n );

parameter ST_IDLE = 3'b000;
parameter ST_WAIT = 3'b001;
parameter ST_T1   = 3'b010;
parameter ST_T2   = 3'b011;
parameter ST_T3   = 3'b100;
parameter ST_T4   = 3'b101;
parameter ST_T5   = 3'b110;
parameter ST_T6   = 3'b111;

reg[2:0] state;
reg[1:0] channel;
reg[7:0] mode;
reg[4:0] chstate;
reg[15:0] chaddr[3:0];
reg[15:0] chtcnt[3:0];
reg ff,exiwe_n;

assign hrq = state!=ST_IDLE;
assign odata = {3'b0,chstate};
assign oaddr = chaddr[channel];
assign owe_n = chtcnt[channel][14]==0 || state!=ST_T2;
assign ord_n = chtcnt[channel][15]==0 || (state!=ST_T1 && state!=ST_T2);
assign oiowe_n = chtcnt[channel][15]==0 || state!=ST_T2;
assign oiord_n = chtcnt[channel][14]==0 || (state!=ST_T1 && state!=ST_T2);

wire[3:0] mdrq = drq & mode[3:0];

always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= 0; ff <= 0; mode <= 0; exiwe_n <= 1'b1;
		chstate <= 0; dack <= 0;
	end else begin
		exiwe_n <= iwe_n;
		if (iwe_n && ~exiwe_n) begin
			ff <= ~(ff|iaddr[3]);
			if (ff) begin
				if(iaddr==4'b0000) chaddr[0][15:8] <= idata;
				if(iaddr==4'b0001) chtcnt[0][15:8] <= idata;
				if(iaddr==4'b0010) chaddr[1][15:8] <= idata;
				if(iaddr==4'b0011) chtcnt[1][15:8] <= idata;
				if(iaddr==4'b0100) chaddr[2][15:8] <= idata;
				if(iaddr==4'b0101) chtcnt[2][15:8] <= idata;
				if(iaddr==4'b0110 || (iaddr==4'b0100 && mode[7]==1'b1)) chaddr[3][15:8] <= idata;
				if(iaddr==4'b0111 || (iaddr==4'b0101 && mode[7]==1'b1)) chtcnt[3][15:8] <= idata;
			end else begin
				if(iaddr==4'b0000) chaddr[0][7:0] <= idata;
				if(iaddr==4'b0001) chtcnt[0][7:0] <= idata;
				if(iaddr==4'b0010) chaddr[1][7:0] <= idata;
				if(iaddr==4'b0011) chtcnt[1][7:0] <= idata;
				if(iaddr==4'b0100) chaddr[2][7:0] <= idata;
				if(iaddr==4'b0101) chtcnt[2][7:0] <= idata;
				if(iaddr==4'b0110 || (iaddr==4'b0100 && mode[7]==1'b1)) chaddr[3][7:0] <= idata;
				if(iaddr==4'b0111 || (iaddr==4'b0101 && mode[7]==1'b1)) chtcnt[3][7:0] <= idata;
			end
			if (iaddr[3]) mode <= idata;
		end
		if (ce) begin
			case (state)
			ST_IDLE: begin
				if (|mdrq) state <= ST_WAIT;
			end
			ST_WAIT: begin
				if (hlda) state <= ST_T1;
				casex (mdrq[3:1])
				3'b1xx: channel <= 2'b11;
				3'b01x: channel <= 2'b10;
				3'b001: channel <= 2'b01;
				3'b000: channel <= 2'b00;
				endcase
			end
			ST_T1: begin
				state <= ST_T2;
				dack[channel] <= 1'b1;
			end
			ST_T2: begin
				if (mdrq[channel]==0) begin
					dack[channel] <= 0;
					if (chtcnt[channel][13:0]==0) begin
						chstate[channel] <= 1'b1;
						if (mode[7]==1'b1 && channel==2'b10) begin
							chaddr[channel] <= chaddr[2'b11];
							chtcnt[channel][13:0] <= chtcnt[2'b11][13:0];
						end
					end else begin
						chaddr[channel] <= chaddr[channel]+1'b1;
						chtcnt[channel][13:0] <= chtcnt[channel][13:0]+14'h3FFF;
					end
					state <= ST_T3;
				end
			end
			ST_T3: begin
				state <= |mdrq ? ST_WAIT : ST_IDLE;
			end
			endcase
		end
	end
end

endmodule
