// ====================================================================
//                Radio-86RK FPGA REPLICA
//
//            Copyright (C) 2011 Dmitry Tselikov
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Radio-86RK video output
//
// Author: Dmitry Tselikov   http://bashkiria-2m.narod.ru/
// Modified by: Andy Karpov <andy.karpov@gmail.com> for Karabas-pro board
// 
// Design File: rk_video.v
//

module rk_video(
	input clk,
	output hr,
	output vr,
	output hr_wg75,
	output vr_wg75,
	output cce,
	output [2:0] r,
	output [2:0] g,
	output [2:0] b,
	input[3:0] lline,
	input[6:0] ichar,
	input vsp,
	input lten,
	input rvv
);

// rk related
reg[1:0] state;
reg[10:0] h_cnt;
reg[10:0] v_cnt;
reg[10:0] v_cnt2;
reg[1:0] v_cnt_line;
reg[2:0] d_cnt;
reg[5:0] data;
wire[7:0] fdata;

// framebuffer 408x300 (384x250 + gaps)
reg[17:0] address_in;
reg[17:0] address_out;
reg data_in;
wire data_out;

rambuffer framebuf(
	.address_a(address_in),
	.address_b(address_out),
	.clock(clk),
	.data_a(data_in),
	.data_b(),
	.wren_a(1'b1),
	.wren_b(1'b0),
	.q_a(),
	.q_b(data_out)
);

assign hr_wg75 = h_cnt >= 10'd468 && h_cnt < 10'd516 ? 1'b0 : 1'b1; // wg75 hsync 
assign vr_wg75 = v_cnt >= 10'd600 && v_cnt < 10'd620 ? 1'b0 : 1'b1; // wg75 vsync 
assign cce = d_cnt==3'b000 && state == 2'b01; // wg75 chip enable signal 

font from(.address({ichar[6:0],lline[2:0]}), .clock(clk), .q(fdata));

always @(posedge clk)
begin

	// 3x divider to get 16MHz clock from 48MHz
	casex (state)
	2'b00: state <= 2'b01;
	2'b01: state <= 2'b10;
	2'b1x: state <= 2'b00;
	endcase

	if (state == 2'b00)
	begin
		if (d_cnt==3'b101) 
			data <= lten ? 6'h3F : vsp ? 6'b0 : fdata[5:0]^{6{rvv}};
		else
			data <= {data[4:0],1'b0};
			
		// write visible data to framebuffer
		if (h_cnt >= 60 && h_cnt < 468 && v_cnt2 >= 0 && v_cnt2 < 300 && v_cnt_line == 2'b00)
		begin
			address_in <= h_cnt - 60 + (10'd408*(v_cnt2 - 0));
			data_in <= data[5];
			//data_in <= 1'b1; // test white screen
		end
					
		if (h_cnt+1'b1 == 10'd516) // 516 - end of line
		begin
			h_cnt <= 0; 
			d_cnt <= 0;
			if (v_cnt+1'b1 == 10'd620 ) // 310 - end of frame
			begin
				v_cnt <= 0;
				v_cnt2 <= 0;
			end
			else begin 
				v_cnt <= v_cnt+1'b1;
				casex (v_cnt_line)
					2'b00: v_cnt_line <= 2'b01;
					2'b01: v_cnt_line <= 2'b00;
					2'b1x: v_cnt_line <= 2'b00;
				endcase
				if (v_cnt_line == 2'b00)
					v_cnt2 <= v_cnt2+1'b1;
			end
		end 
		else 
		begin
			h_cnt <= h_cnt+1'b1;
			if (d_cnt+1'b1 == 3'b110) // end of char
				d_cnt <= 0;
			else
				d_cnt <= d_cnt+1'b1;
		end
	end
end

// vga sync generator

wire[10:0] CounterX;
wire[10:0] CounterY;
wire inDisplay;

hvsync_generator vgasync(
	.clk(clk),
	.vga_h_sync(hr),
	.vga_v_sync(vr),
	.inDisplayArea(inDisplay),
	.CounterX(CounterX),
	.CounterY(CounterY)
);

// vga signal generator

reg[1:0] pixel_state;
reg[1:0] line_state;
reg[10:0] pixel_cnt;
reg[10:0] line_cnt;

assign r = data_out && inDisplay ? 3'b100 : 3'b0;
assign g = data_out && inDisplay ? 3'b100 : 3'b0;
assign b = data_out && inDisplay ? 3'b100 : 3'b0;

always @(posedge clk)
begin

	if (CounterX >= 0 && CounterX < 816 && CounterY >= 0 && CounterY < 600) // doubledot visible area
	begin

		casex (pixel_state)
		2'b00: pixel_state <= 2'b01;
		2'b01: pixel_state <= 2'b00;
		endcase

		address_out <= pixel_cnt + (line_cnt*408);
		
		if (pixel_state == 2'b01)
			pixel_cnt <= pixel_cnt + 1;

		if (CounterX+1 == 816) 
		begin
			pixel_cnt <= 0;
			casex (line_state)
			2'b00: line_state <= 2'b01;
			2'b01: line_state <= 2'b00;
			endcase
			if (line_state == 2'b01)
				line_cnt <= line_cnt + 1;
		end
						
		if (CounterY+1 == 600)
		begin
			line_cnt <= 0;
			pixel_cnt <= 0;
			line_state <= 0;
		end
	end
end

endmodule
