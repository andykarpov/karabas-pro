`timescale 1ns / 1ps
`default_nettype none

//    This file is part of the ZXUNO Spectrum core. 
//    Creation date is 17:57:54 2015-09-11 by Miguel Angel Rodriguez Jodar
//    (c)2014-2020 ZXUNO association.
//    ZXUNO official repository: http://svn.zxuno.com/svn/zxuno
//    Username: guest   Password: zxuno
//    Github repository for this core: https://github.com/mcleod-ideafix/zxuno_spectrum_core
//
//    ZXUNO Spectrum core is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    ZXUNO Spectrum core is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with the ZXUNO Spectrum core.  If not, see <https://www.gnu.org/licenses/>.
//
//    Any distributed copy of this file must keep this notice intact.

module vga_scandoubler (
  input wire clk,
  input wire clk28en,
  input wire clk14en,
  input wire enable_scandoubling,
  input wire disable_scaneffect,  // 1 to disable scanlines
  input wire [8:0] rgbi,
  input wire hsync_ext_n,
  input wire vsync_ext_n,
  input wire csync_ext_n,
  output reg [8:0] rgbo,
  output reg hsync,
  output reg vsync
  );
 
  parameter [31:0] CLKVIDEO = 12000;
  
  // http://www.epanorama.net/faq/vga2rgb/calc.html
  // SVGA 800x600
  // HSYNC = 3.36us  VSYNC = 114.32us  
  
  parameter [63:0] HSYNC_COUNT = (CLKVIDEO * 3360 * 2)/1000000;
  parameter [63:0] VSYNC_COUNT = (CLKVIDEO * 114320 * 2)/1000000;
  
	// ------------------------------------------------------------------
 
  reg [10:0] addrvideo = 11'd0, addrvga = 11'b00000000000;
  reg [9:0] totalhor = 10'd0;

  wire [8:0] rgbout;
  // Dual-port memory that stores information from two scans 
  // Each scan can be up to 1024 points, including the blank
  vgascanline_dport memscan (
    .clk(clk),
	 .clk28en(clk28en),
    .addrwrite(addrvideo),
    .addrread(addrvga),
    .we(clk14en),
    .din(rgbi),
    .dout(rgbout)
  );

  // Generate scanlines:
  reg scaneffect = 1'b0;
  wire [8:0] rgbout_dimmed;
  color_dimmed apply_to_red   (rgbout[8:6], rgbout_dimmed[8:6]);
  color_dimmed apply_to_green (rgbout[5:3], rgbout_dimmed[5:3]);
  color_dimmed apply_to_blue  (rgbout[2:0], rgbout_dimmed[2:0]);
  wire [8:0] rgbo_vga = (scaneffect | disable_scaneffect)? rgbout : rgbout_dimmed;
  
	// I alternately write to one half or the other of the scan buffer. 
	// I switch halves every time I find a horizontal sync pulse. 
	// In "totalhor" I measure the number of clock cycles in a scan
  reg hsync_ext_n_prev = 1'b1;
  always @(posedge clk) begin
    if (clk28en == 1'b1 && clk14en == 1'b1) begin
      hsync_ext_n_prev <= hsync_ext_n;
      if (hsync_ext_n == 1'b0 && hsync_ext_n_prev == 1'b1) begin
        totalhor <= addrvideo[9:0];
        addrvideo <= {~addrvideo[10],10'b0000000000};
      end
      else
        addrvideo <= addrvideo + 11'd1;
    end
  end
 
	// Scan the scanbuffer at twice the speed, generating addresses for the scanbuffer. 
	// Each time the original video finishes a line, It switch to the other half of the buffer. 
	// When It finish scanning but I'm not yet at a horizontal delay, I simply scan the buffer again 
	// from the same starting point.
   // Each time I finish scanning the buffer, I toggle "scaneffect," which I then use to display the pixels 
	// at their nominal brightness, or with their brightness reduced for a cool scanline effect on VGA. 
  reg hsync_ext_n_prev2 = 1'b1;
  always @(posedge clk) begin
	 if (clk28en == 1'b1) begin
      hsync_ext_n_prev2 <= hsync_ext_n;
      if (addrvga[9:0] == totalhor && hsync_ext_n == 1'b1 && hsync_ext_n_prev2 == 1'b1) begin
         addrvga <= {addrvga[10], 10'b000000000};
         scaneffect <= ~scaneffect;
      end
      else if (hsync_ext_n == 1'b0 && hsync_ext_n_prev2 == 1'b1 /*&& addrvga[9] == 1'b0*/) begin
        addrvga <= {addrvideo[10],10'b000000000};
        scaneffect <= ~scaneffect;
      end
      else
        addrvga <= addrvga + 11'd1;
	 end
  end

  // The VGA HSYNC is low only during HSYNC_COUNT cycles from the start of a scanline front
  reg hsync_vga, vsync_vga;
    
  always @* begin
    if (addrvga[9:0] < HSYNC_COUNT[9:0])
       hsync_vga = 1'b0;
    else
       hsync_vga = 1'b1;
  end
 
  // The VSYNC of the VGA is low only during VSYNC_COUNT cycles starting from the 
  // falling edge of the original vertical sync signal
  reg [15:0] cntvsync = 16'hFFFF;
  initial vsync_vga = 1'b1;
  always @(posedge clk) begin
	 if (clk28en == 1'b1) begin
      if (vsync_ext_n == 1'b0) begin
        if (cntvsync == 16'hFFFF) begin
          cntvsync <= 16'd0;
          vsync_vga <= 1'b0;
        end
        else if (cntvsync != 16'hFFFE) begin
          if (cntvsync == VSYNC_COUNT[15:0]) begin
            vsync_vga <= 1'b1;
            cntvsync <= 16'hFFFE;
          end
          else
            cntvsync <= cntvsync + 16'd1;
        end
      end
      else if (vsync_ext_n == 1'b1)
        cntvsync <= 16'hFFFF;
	 end
  end
  
  always @* begin
    if (enable_scandoubling == 1'b0) begin // 15kHz output
      rgbo = rgbi;
      hsync = csync_ext_n;
      vsync = 1'b1;
    end
    else begin  // VGA output
      rgbo = rgbo_vga;
      hsync = hsync_vga;
      vsync = vsync_vga;
    end
  end
  
endmodule

// A dual-port memory: one port for reading, and one for writing.
// It has 2048 addresses: 1024 are used to save a scan, and another 1024 for the next scan.
module vgascanline_dport (
 input wire clk,
 input wire clk28en,
 input wire [10:0] addrwrite,
 input wire [10:0] addrread,
 input wire we,
 input wire [8:0] din,
 output reg [8:0] dout
 );
 
 reg [8:0] scan[0:2047]; // two scanlines
 always @(posedge clk) begin
	if (clk28en == 1'b1) begin
	  dout <= scan[addrread];
	  if (we == 1'b1)
		scan[addrwrite] <= din;
	end
 end
endmodule

module color_dimmed (
    input wire [2:0] in,
    output reg [2:0] out // out is scaled to roughly 70% of in
    );
    
    always @* begin  // a LUT
        case (in)  
            3'd0 : out = 3'd0;
            3'd1 : out = 3'd1;
            3'd2 : out = 3'd1;
            3'd3 : out = 3'd2;
            3'd4 : out = 3'd3;
            3'd5 : out = 3'd3;
            3'd6 : out = 3'd4;
            3'd7 : out = 3'd5;
            default: out = 3'd0;
        endcase
    end
endmodule
        