`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    05:20:24 08/15/2016 
// Design Name: 
// Module Name:    switch_mode 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module switch_mode (
   input wire clk,
   input wire [7:0] kbd_status,
   input wire [7:0] kbd_data,
   output reg mode,
   output reg vga,
   output reg memtestf,
   output reg memtests,
   output reg sdtest,
   output reg flashtest,
   output reg mousetest,
   output reg sdramtests,
   output reg hidetextwindow,
   output reg master_reset
   );

   initial begin
      mode = 1'b1;
      vga = 1'b1;
      memtestf = 1'b0;
      memtests = 1'b0;
      sdtest = 1'b0;
      flashtest = 1'b0;
      mousetest = 1'b0;
      sdramtests = 1'b0;
      master_reset = 1'b0;
      hidetextwindow = 1'b0;
   end
   
   always @(posedge clk) begin
      memtestf <= 1'b0;
      memtests <= 1'b0;
      sdtest <= 1'b0;
      flashtest <= 1'b0;
      mousetest <= 1'b0;
      sdramtests <= 1'b0;
      master_reset <= 1'b0;
      hidetextwindow <= 1'b0;

      case (kbd_data)
        8'h1e: begin mode <= 1'b0; vga <= 1'b0; end // 1
        8'h1f: begin mode <= 1'b1; vga <= 1'b0; end // 2
        8'h20: begin mode <= 1'b1; vga <= 1'b1; end // 3
        8'h21: begin memtestf <= 1'b1; end // 4
        8'h22: begin memtests <= 1'b1; end // 5
        8'h23: begin sdramtests <= 1'b1; end // 6
        8'h24: begin sdtest <= 1'b1; end  // 7
        8'h25: begin flashtest <= 1'b1; end // 8
        8'h26: begin mousetest <= 1'b1; end // 9
        8'h4c: if ((kbd_status[0] | kbd_status[4]) & (kbd_status[2] | kbd_status[6])) master_reset <= 1'b1; // ctrl+alt+del
        8'h2c: hidetextwindow <= 1'b1; // space
      endcase

   end
endmodule

