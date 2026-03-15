`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: emax73
// 
// Create Date:    17:30:25 10/18/2021 
// Design Name: 
// Module Name:    joystick 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Sega MD 6-buttons pads module
//
// Dependencies: 
//
// Revision:
// Revision 1.0 - Release
// Additional Comments: 
// License: GPLv3
//
//////////////////////////////////////////////////////////////////////////////////
module joystick(
		input wire clk,
		input wire joyp1_i,
		input wire joyp2_i,
		input wire joyp3_i,
		input wire joyp4_i,
		input wire joyp6_i,
		output wire joyp7_o,
		input wire joyp9_i,
		output wire [11:0] joyOut // MXYZ SACB UDLR  1 - On 0 - off
		//output wire [8:0] test 
	 );
	 
	 parameter CLK_MHZ = 16'd84;

	reg [15:0] cnt;
	reg joyClk;

	always @(posedge clk)
	begin
		if (cnt < (16'd3 * CLK_MHZ))
			cnt <= cnt + 16'd1;
		else
		begin
			joyClk <= !joyClk;
			cnt <= 16'd0;
		end	
	end
	
	reg [15:0] state;
	always @(posedge joyClk)
	begin
		if (state < 16'd1500)
			state <= state + 16'd1;
		else
			state <= 16'd0;
	end
	
	reg btUp, btDown, btLeft, btRight, btA, btB, btC, btStart, btX, btY, btZ, btMode; 

	reg select;
	reg phaseUDLR, phaseAS, phase0000, phaseXYZ;
	always @(*)
	begin
		select = 1'b1;
		phaseUDLR = 1'b0;
		phaseAS = 1'b0;
		phase0000 = 1'b0;
		phaseXYZ = 1'b0;
		case (state)
			16'd0:
				select = 1'b1;
			16'd4:
			begin
				select = 1'b1;
				phaseUDLR = 1'b1;
			end
			16'd5:
			begin
				select = 1'b0;
				phaseAS = 1'b1;
			end
			16'd6:
				select = 1'b1;
			16'd7:
				select = 1'b0;
			16'd8:
				select = 1'b1;
			16'd9:
			begin
				select = 1'b0;
				phase0000 = 1'b1;
			end
			16'd10:
			begin
				select = 1'b1;
				phaseXYZ = 1'b1;
			end
			16'd11:
				select = 1'b0;
			16'd12:
				select = 1'b1;
		endcase
	end
	
	reg xyzEnabled;
	
	always @(negedge joyClk)
	begin
			if (phaseUDLR) 
			begin
				btUp = !joyp1_i;
				btDown = !joyp2_i;
				btLeft = !joyp3_i;
				btRight = !joyp4_i;
				btB = !joyp6_i;
				btC = !joyp9_i;
			end
			if (phaseAS)
			begin
				if (!(joyp3_i || joyp4_i))
				begin		
					btA = !joyp6_i;
					btStart = !joyp9_i;
				end
				else
				begin
					btA = 1'b0;
					btStart = 1'b0;
				end
			end
			if (phase0000)
				if (!(joyp1_i || joyp2_i || joyp3_i || joyp4_i))
					xyzEnabled = 1'b1;
				else
					xyzEnabled = 1'b0;
			if (phaseXYZ)
			begin
				if (xyzEnabled)
				begin
					btZ = !joyp1_i;
					btY = !joyp2_i;
					btX = !joyp3_i;
					btMode = !joyp4_i;
				end
				else 
				begin
					btZ = 1'b0;
					btY = 1'b0;
					btX = 1'b0;
					btMode = 1'b0;
				end
			end
	end

	assign joyp7_o = select;
		
	// MXYZ SACB UDLR  1 - On 0 - off
	assign joyOut = {btMode, btX, btY, btZ, btStart, btA, btC, btB, btUp, btDown, btLeft, btRight};

	/*assign test[0] = joyOut[0];
	assign test[1] = joyOut[8];
	assign test[2] = joyOut[9];
	assign test[3] = joyOut[10];
	assign test[4] = joyOut[4];
	assign test[5] = joyOut[5];
	assign test[6] = joyOut[6];
	assign test[7] = joyOut[7];

	assign test[8] = select;*/
endmodule
